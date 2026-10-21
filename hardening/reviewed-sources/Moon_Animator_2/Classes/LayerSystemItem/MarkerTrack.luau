local _g = _G.MoonGlobal; _g.req("Track")
local MarkerTrack = super:new()

function MarkerTrack:new(LayerSystem, ItemObject, hierLevel)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.ListComponent.Label.Text = "Events"
	end

	return ctor
end

function MarkerTrack:set_select(value)
	super.set_select(self, value)
	local middle_color = value and "highlight" or "third"
	self.TrackItems:Iterate(function(mk)
		mk:SetItemPaint(mk.UI.BG_Middle.Line, {BackgroundColor3 = middle_color})
		mk:SetItemPaint(mk.UI.Start, {BackgroundColor3 = middle_color})
		mk:SetItemPaint(mk.UI.End, {BackgroundColor3 = middle_color})
	end)
end

-- Restricted event programs are data, never Luau. The only capabilities below
-- are four fixed sound/particle methods on explicitly approved scene instances.
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local MAX_SOURCE = 4096
local MAX_ACTIONS = 16
local MAX_SEGMENTS = 8
local MAX_SEGMENT_BYTES = 128
local MAX_PROGRAM_PARTICLES = 256
local MAX_PLAY_PARTICLES = 2048
local MAX_SOUNDS = 8
local MAX_EMITTERS = 16
local MAX_GRANTS = 128
local MAX_HANDLERS = 16
local MAX_CHILDREN = 256
local MAX_ANCESTORS = 64
local MAX_TIMELINE_FRAMES = 1000000
local MAX_UPDATE_FRAMES = 4096
local ATTEMPT_RATE = 16
local ACTION_RATE = 32
local PARTICLE_RATE = 256

-- Neither map is exported or serialized. Imported marker data cannot create a
-- grant. Limits also bound entries whose surrounding project remains reachable.
local grants = setmetatable({}, {__mode = "k"})
local handlerStates = setmetatable({}, {__mode = "k"})

local function fail(message)
	error(message, 0)
end

local function sizeOf(map)
	local count = 0
	for _ in pairs(map) do count += 1 end
	return count
end

-- JSONDecode represents [] and {} as empty tables. A bounded structural scan
-- preserves that distinction and rejects duplicate/escaped schema keys before
-- the engine decodes strings and numbers. It does not evaluate source text.
local function scanJSON(text)
	local pos, length, nodes = 1, #text, 0
	local parseValue
	local function whitespace()
		while pos <= length and text:sub(pos, pos):find("[ \t\r\n]") do pos += 1 end
	end
	local function readString(isKey)
		if text:sub(pos, pos) ~= '"' then fail("Expected a JSON string.") end
		local start = pos + 1
		pos += 1
		while pos <= length do
			local byte = text:byte(pos)
			if byte == 34 then
				local result = text:sub(start, pos - 1)
				pos += 1
				return result
			elseif byte == 92 then
				if isKey then fail("Use literal JSON field names without escapes.") end
				pos += 2
			elseif byte < 32 then
				fail("Control character in JSON string.")
			else
				pos += 1
			end
		end
		fail("Unterminated JSON string.")
	end
	parseValue = function(depth)
		if depth > 12 then fail("JSON nesting is too deep.") end
		nodes += 1
		if nodes > 512 then fail("Too many JSON values.") end
		whitespace()
		local first = text:sub(pos, pos)
		if first == "{" then
			pos += 1
			local shape = {kind = "object", fields = {}}
			whitespace()
			if text:sub(pos, pos) == "}" then pos += 1 return shape end
			while true do
				whitespace()
				local key = readString(true)
				if shape.fields[key] ~= nil then fail("Duplicate JSON field.") end
				whitespace()
				if text:sub(pos, pos) ~= ":" then fail("Expected ':' after JSON field.") end
				pos += 1
				shape.fields[key] = parseValue(depth + 1)
				whitespace()
				local separator = text:sub(pos, pos)
				pos += 1
				if separator == "}" then return shape end
				if separator ~= "," then fail("Expected ',' or '}' in JSON object.") end
			end
		elseif first == "[" then
			pos += 1
			local shape = {kind = "array", values = {}, count = 0}
			whitespace()
			if text:sub(pos, pos) == "]" then pos += 1 return shape end
			while true do
				shape.count += 1
				if shape.count > 256 then fail("JSON array is too large.") end
				shape.values[shape.count] = parseValue(depth + 1)
				whitespace()
				local separator = text:sub(pos, pos)
				pos += 1
				if separator == "]" then return shape end
				if separator ~= "," then fail("Expected ',' or ']' in JSON array.") end
			end
		elseif first == '"' then
			readString(false)
			return {kind = "value"}
		else
			local start = pos
			while pos <= length and not text:sub(pos, pos):find("[ \t\r\n,%]%}]") do pos += 1 end
			if start == pos then fail("Missing JSON value.") end
			return {kind = "value"}
		end
	end
	local result = parseValue(0)
	whitespace()
	if pos <= length then fail("Unexpected text after JSON program.") end
	return result
end

local function objectFields(value, shape, allowed)
	if type(value) ~= "table" or shape.kind ~= "object" then fail("Expected a JSON object.") end
	for key in pairs(shape.fields) do
		if not allowed[key] then fail("Unknown field: " .. key:sub(1, 40)) end
	end
	for key in pairs(value) do
		if not allowed[key] or not shape.fields[key] then fail("Unexpected decoded JSON field.") end
	end
end

local function arrayLength(value, shape, maximum)
	if type(value) ~= "table" or not shape or shape.kind ~= "array" then fail("Expected a JSON array.") end
	local count = shape.count
	if count > maximum then fail("JSON array exceeds the permitted length.") end
	for key in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
			fail("Expected a dense JSON array.")
		end
	end
	for index = 1, count do
		if value[index] == nil then fail("Null or missing array entry.") end
	end
	return count
end

local function parseCommands(text)
	if type(text) ~= "string" then return nil, "Event commands must be text." end
	if #text > MAX_SOURCE then return nil, "Each event program is limited to 4096 bytes." end
	if not text:find("%S") then return {actions = {}, particles = 0} end
	local success, result = pcall(function()
		local shape = scanJSON(text)
		local decoded = HttpService:JSONDecode(text)
		objectFields(decoded, shape, {version = true, actions = true})
		if decoded.version ~= 1 or not shape.fields.version then fail("Expected event program version 1.") end
		local count = arrayLength(decoded.actions, shape.fields.actions, MAX_ACTIONS)
		local actions, particles = {}, 0
		for index = 1, count do
			local action, actionShape = decoded.actions[index], shape.fields.actions.values[index]
			if type(action) ~= "table" then fail("Each action must be a JSON object.") end
			local emit = action.op == "particle.emit"
			objectFields(action, actionShape, emit and {op = true, target = true, count = true} or {op = true, target = true})
			if action.op ~= "sound.play" and action.op ~= "sound.stop"
				and action.op ~= "particle.emit" and action.op ~= "particle.clear" then
				fail("Allowed operations: sound.play, sound.stop, particle.emit, particle.clear.")
			end
			local segments = arrayLength(action.target, actionShape.fields.target, MAX_SEGMENTS)
			local target = {}
			for segmentIndex = 1, segments do
				local segment = action.target[segmentIndex]
				if type(segment) ~= "string" or #segment == 0 or #segment > MAX_SEGMENT_BYTES
					or segment == "." or segment == ".." or segment == "Parent"
					or segment:find("[/\\%c]") then
					fail("Targets require up to 8 literal child names; traversal and control characters are forbidden.")
				end
				target[segmentIndex] = segment
			end
			local amount = nil
			if emit then
				amount = action.count
				if type(amount) ~= "number" or amount ~= amount or amount < 1 or amount > 100 or amount % 1 ~= 0 then
					fail("Particle count must be a finite integer from 1 to 100.")
				end
				particles += amount
				if particles > MAX_PROGRAM_PARTICLES then fail("A program may emit at most 256 particles.") end
			end
			actions[index] = {op = action.op, target = target, count = amount}
		end
		return {actions = actions, particles = particles}
	end)
	if not success then return nil, tostring(result):sub(1, 240) end
	return result
end

function MarkerTrack.ValidateCommands(text)
	local program, message = parseCommands(text)
	return program ~= nil, message
end

local function rootFor(track)
	local root = track.ItemObject and track.ItemObject.Path and track.ItemObject.Path:GetItem()
	if typeof(root) ~= "Instance" or root == Workspace
		or not (root:IsA("Model") or root:IsA("BasePart") or root:IsA("Attachment")
			or root:IsA("Sound") or root:IsA("ParticleEmitter"))
		or not root:IsDescendantOf(Workspace) then
		fail("Event targets require an allowed scene item inside Workspace.")
	end
	return root
end

local function ancestry(root)
	local chain = {}
	local current = root
	while current ~= Workspace do
		if not current or #chain >= MAX_ANCESTORS then fail("Invalid or excessively deep scene ancestry.") end
		table.insert(chain, current)
		current = current.Parent
	end
	return chain
end

local function resolve(root, action)
	local current, chain = root, {root}
	for _, name in ipairs(action.target) do
		local children = current:GetChildren()
		if #children > MAX_CHILDREN then fail("A target path passes through too many children.") end
		local found = nil
		for _, child in ipairs(children) do
			if child.Name == name then
				if found then fail("A target name is ambiguous; child names must be unique.") end
				found = child
			end
		end
		if not found then fail("An approved target path is missing.") end
		current = found
		table.insert(chain, current)
	end
	if (action.op == "sound.play" or action.op == "sound.stop") and not current:IsA("Sound") then
		fail("Sound operations require a Sound target.")
	elseif (action.op == "particle.emit" or action.op == "particle.clear") and not current:IsA("ParticleEmitter") then
		fail("Particle operations require a ParticleEmitter target.")
	end
	return current, chain
end

local function resolveProgram(root, program)
	local result = {actions = {}, particles = program.particles}
	for index, action in ipairs(program.actions) do
		local target, chain = resolve(root, action)
		result.actions[index] = {op = action.op, target = action.target, count = action.count,
			instance = target, chain = chain}
	end
	return result
end

local function sameChain(left, right)
	if #left ~= #right then return false end
	for index, value in ipairs(left) do
		if value ~= right[index] then return false end
	end
	return true
end

local function disconnectRecord(record)
	if record.ended then record.ended:Disconnect() end
	if record.stopped then record.stopped:Disconnect() end
end

local function cleanup(state, owner, marker)
	for sound, record in pairs(state.sounds) do
		if (not owner or record.owner == owner) and (not marker or record.marker == marker) then
			state.sounds[sound] = nil
			disconnectRecord(record)
			pcall(function() sound:Stop() end)
		end
	end
	for emitter, record in pairs(state.emitters) do
		if (not owner or record.owner == owner) and (not marker or record.marker == marker) then
			state.emitters[emitter] = nil
			pcall(function() emitter:Clear() end)
		end
	end
end

local function cleanupOwner(owner, marker)
	for _, state in pairs(handlerStates) do cleanup(state, owner, marker) end
end

function MarkerTrack:RevokeMarkerCommands(marker)
	local grant = grants[marker]
	if grant and grant.owner == self then grants[marker] = nil end
	cleanupOwner(self, marker)
end

function MarkerTrack:ApproveMarkerCommands(marker)
	self:RevokeMarkerCommands(marker)
	local success, result = pcall(function()
		if type(marker) ~= "table" or marker.ParentTrack ~= self
			or not self.TrackItems:Contains(marker) then fail("Marker does not belong to this track.") end
		if sizeOf(grants) >= MAX_GRANTS then fail("At most 128 markers may be approved in this session.") end
		local beginProgram, beginError = parseCommands(marker.codeBegin)
		if not beginProgram then fail("On Begin: " .. beginError) end
		local endProgram, endError = parseCommands(marker.codeEnd)
		if not endProgram then fail("On End: " .. endError) end
		local root = rootFor(self)
		return {owner = self, root = root, rootChain = ancestry(root),
			handler = self.LayerSystem.PlaybackHandler,
			beginSource = marker.codeBegin, endSource = marker.codeEnd,
			beginProgram = resolveProgram(root, beginProgram), endProgram = resolveProgram(root, endProgram)}
	end)
	if not success then return false, tostring(result):sub(1, 240) end
	grants[marker] = result
	return true
end

local function validGrant(track, marker)
	local grant = grants[marker]
	if not grant or grant.owner ~= track then return nil, "This marker has no session approval." end
	local success, message = pcall(function()
		if marker.ParentTrack ~= track or not track.TrackItems:Contains(marker)
			or marker.codeBegin ~= grant.beginSource or marker.codeEnd ~= grant.endSource
			or track.LayerSystem.PlaybackHandler ~= grant.handler then fail("Marker commands or ownership changed; approve again.") end
		local root = rootFor(track)
		if root ~= grant.root or not sameChain(ancestry(root), grant.rootChain) then fail("The approved scene item moved or changed.") end
		for _, program in ipairs({grant.beginProgram, grant.endProgram}) do
			for _, action in ipairs(program.actions) do
				local target, chain = resolve(root, action)
				if target ~= action.instance or not sameChain(chain, action.chain) then
					fail("An approved target moved or was replaced; approve again.")
				end
			end
		end
	end)
	if not success then
		track:RevokeMarkerCommands(marker)
		return nil, tostring(message):sub(1, 240)
	end
	return grant
end

function MarkerTrack:IsMarkerApproved(marker)
	return validGrant(self, marker) ~= nil
end

local function stateFor(handler)
	local state = handlerStates[handler]
	if not state then
		if sizeOf(handlerStates) >= MAX_HANDLERS then return nil, "Too many active event contexts." end
		state = {time = os.clock(), attempts = ATTEMPT_RATE, actions = ACTION_RATE,
			particles = PARTICLE_RATE, playParticles = 0, sounds = {}, emitters = {}, lastWarning = -math.huge}
		handlerStates[handler] = state
	end
	local now = os.clock()
	local elapsed = math.max(0, now - state.time)
	state.time = math.max(now, state.time)
	state.attempts = math.min(ATTEMPT_RATE, state.attempts + elapsed * ATTEMPT_RATE)
	state.actions = math.min(ACTION_RATE, state.actions + elapsed * ACTION_RATE)
	state.particles = math.min(PARTICLE_RATE, state.particles + elapsed * PARTICLE_RATE)
	return state
end

local function report(state, message)
	local now = os.clock()
	if state and now - state.lastWarning >= 1 then
		state.lastWarning = now
		warn("[Moon Animator] Event commands skipped: " .. tostring(message):sub(1, 240))
	end
end

local function pruneSounds(state)
	for sound, record in pairs(state.sounds) do
		local success, playing = pcall(function() return sound.IsPlaying end)
		if not success or not playing then
			state.sounds[sound] = nil
			disconnectRecord(record)
		end
	end
end

local function preflightEffects(state, owner, program)
	pruneSounds(state)
	local sounds, emitters, stopped, skipStops = {}, {}, {}, {}
	for item, record in pairs(state.sounds) do sounds[item] = record.owner end
	for item, record in pairs(state.emitters) do emitters[item] = record.owner end
	local soundCount, emitterCount = sizeOf(sounds), sizeOf(emitters)
	for index, action in ipairs(program.actions) do
		local target = action.instance
		if action.op == "sound.play" then
			if sounds[target] and sounds[target] ~= owner then fail("This sound belongs to another event track.") end
			if not sounds[target] then
				if not stopped[target] and target.IsPlaying then fail("A pre-existing playing sound cannot be taken over.") end
				sounds[target] = owner
				soundCount += 1
				if soundCount > MAX_SOUNDS then fail("At most 8 event sounds may play at once.") end
			end
		elseif action.op == "sound.stop" then
			if sounds[target] == owner then
				sounds[target] = nil
				soundCount -= 1
			elseif sounds[target] or (not stopped[target] and target.IsPlaying) then
				fail("Only sounds started by this event track may be stopped.")
			else
				-- A naturally completed sound makes an end-stop a harmless no-op.
				skipStops[index] = true
			end
			stopped[target] = true
		else
			if emitters[target] and emitters[target] ~= owner then fail("This emitter belongs to another event track.") end
			if not emitters[target] then
				emitters[target] = owner
				emitterCount += 1
				if emitterCount > MAX_EMITTERS then fail("At most 16 emitters may be touched during a play session.") end
			end
		end
	end
	if #program.actions > state.actions or program.particles > state.particles
		or state.playParticles + program.particles > MAX_PLAY_PARTICLES then
		fail("The shared event action or particle budget is exhausted.")
	end
	return skipStops
end

local function rememberSound(state, sound, owner, marker)
	local record = state.sounds[sound]
	if record then record.marker = marker return end
	record = {owner = owner, marker = marker}
	state.sounds[sound] = record
	local function finished()
		if state.sounds[sound] == record then state.sounds[sound] = nil end
		disconnectRecord(record)
	end
	record.ended = sound.Ended:Connect(finished)
	record.stopped = sound.Stopped:Connect(finished)
end

function MarkerTrack:_ExecuteCommands(marker, phase)
	local source = phase == "begin" and marker.codeBegin or marker.codeEnd
	local existingGrant = grants[marker]
	if existingGrant and existingGrant.owner == self
		and (marker.codeBegin ~= existingGrant.beginSource or marker.codeEnd ~= existingGrant.endSource) then
		-- Source invalidation is cheap and must clean active effects even when the
		-- next boundary is empty or the shared attempt bucket is exhausted.
		self:RevokeMarkerCommands(marker)
		return false, "Marker commands changed; approve again."
	end
	if type(source) == "string" and #source <= MAX_SOURCE and not source:find("%S") then
		if not existingGrant or existingGrant.owner ~= self then return true end
		-- Approved blank boundaries still validate the opposite program's targets,
		-- but only after the same attempt throttle as nonempty programs.
	end
	local handler = self.LayerSystem.PlaybackHandler
	if not handler.Playing or not self.Enabled then return false, "Playback is inactive." end
	local state, stateError = stateFor(handler)
	if not state then return false, stateError end
	if state.attempts < 1 then report(state, "The shared event attempt budget is exhausted.") return false end
	state.attempts -= 1
	local grant, grantError = validGrant(self, marker)
	if not grant then report(state, grantError) return false, grantError end
	local program = phase == "begin" and grant.beginProgram or grant.endProgram
	local success, skipStops = pcall(preflightEffects, state, self, program)
	if not success then report(state, skipStops) return false, tostring(skipStops) end
	state.actions -= #program.actions
	state.particles -= program.particles
	state.playParticles += program.particles
	-- Every action, scope, ownership check and budget passes before the first
	-- effect. Engine failures are caught and this marker's owned effects cleaned.
	local message
	success, message = pcall(function()
		for index, action in ipairs(program.actions) do
			local target = action.instance
			if action.op == "sound.play" then
				rememberSound(state, target, self, marker)
				target:Play()
			elseif action.op == "sound.stop" then
				if not skipStops[index] then
					local record = state.sounds[target]
					state.sounds[target] = nil
					if record then disconnectRecord(record) end
					target:Stop()
				end
			elseif action.op == "particle.emit" then
				state.emitters[target] = {owner = self, marker = marker}
				target:Emit(action.count)
			elseif action.op == "particle.clear" then
				state.emitters[target] = {owner = self, marker = marker}
				target:Clear()
			end
		end
	end)
	if not success then self:RevokeMarkerCommands(marker) report(state, message) return false, tostring(message) end
	return true
end

function MarkerTrack.StopSafeEffects(playbackHandler)
	local state = handlerStates[playbackHandler]
	if state then
		cleanup(state)
		state.playParticles = 0
		-- Keep monotonic token buckets: repeated Stop/Play cannot refill a burst.
	end
end

local function revokeTrack(track)
	for marker, grant in pairs(grants) do
		if grant.owner == track then grants[marker] = nil end
	end
	cleanupOwner(track)
end

function MarkerTrack:_RunCodeAt(frm_pos)
	local TargetMarker = self.TrackItemPositions[frm_pos]

	if TargetMarker then
		if TargetMarker.frm_pos == frm_pos then
			self:_ExecuteCommands(TargetMarker, "begin")
		end
		if TargetMarker.frm_pos + TargetMarker.width == frm_pos then
			self:_ExecuteCommands(TargetMarker, "end")
		end
	end
end

function MarkerTrack:_Update(frm_pos)
	if not self.LayerSystem.PlaybackHandler.Playing then return end
	local length = self.LayerSystem.length
	local function frameNumber(value, minimum)
		return type(value) == "number" and value == value and value >= minimum
			and value <= MAX_TIMELINE_FRAMES and value % 1 == 0
	end
	local valid = frameNumber(length, 0) and frameNumber(frm_pos, 0)
		and frameNumber(self.LastUpdate, -1) and frm_pos <= length and self.LastUpdate <= length
	local scanned = 0
	if valid then
		scanned = frm_pos < self.LastUpdate and (length - self.LastUpdate + frm_pos + 1)
			or (frm_pos - self.LastUpdate)
	end
	if not valid or scanned > MAX_UPDATE_FRAMES then
		self.LastUpdate = frameNumber(frm_pos, 0) and frm_pos or -1
		cleanupOwner(self)
		local state = stateFor(self.LayerSystem.PlaybackHandler)
		report(state, "Event preview skipped: invalid timeline values or more than 4096 crossed frames in one update.")
		return
	end

	if frm_pos < self.LastUpdate then
		for pos = self.LastUpdate + 1, length, 1 do
			self:_RunCodeAt(pos)
		end
		self.LastUpdate = -1
	end
	for pos = self.LastUpdate + 1, frm_pos do
		self:_RunCodeAt(pos)
	end

	self.LastUpdate = frm_pos
end

function MarkerTrack:Destroy()
	revokeTrack(self)
	super.Destroy(self)
end

function MarkerTrack:SetEnabled(value, inputted)
	if not value then revokeTrack(self) end
	self.LastUpdate = self.LayerSystem.SliderFrame - 1
	super.SetEnabled(self, value, inputted)
	
	self.LayerSystem.PlaybackHandler.ActiveTracks[tostring(self)] = value and self or nil
end

do
	function MarkerTrack:ResizeMarker(Marker, width)
		for ind = Marker.frm_pos, Marker.frm_pos + Marker.width do
			self.TrackItemPositions[ind] = nil
		end

		Marker.width = width
		Marker:_Size()

		for ind = Marker.frm_pos, Marker.frm_pos + width do
			assert(self.TrackItemPositions[ind] == nil, "Marker collision.")
			self.TrackItemPositions[ind] = Marker
		end
	end

	function MarkerTrack:MoveMarker(Marker, frm_pos)
		assert(self.TrackItems:Contains(Marker), "Marker is not in MarkerTrack.")
		super.MoveTrackItem(self, Marker, frm_pos)
		return Marker
	end

	function MarkerTrack:AddMarker(Marker, overwrite)
		assert(Marker.ParentTrack == nil, "Marker already is parented to a MarkerTrack.")
		super.AddTrackItem(self, Marker, overwrite)
		if self.selected then
			Marker:SetItemPaint(Marker.UI.BG_Middle.Line, {BackgroundColor3 = "highlight"})
			Marker:SetItemPaint(Marker.UI.Start, {BackgroundColor3 = "highlight"})
			Marker:SetItemPaint(Marker.UI.End, {BackgroundColor3 = "highlight"})
		end
		return Marker
	end

	function MarkerTrack:RemoveMarker(Marker)
		assert(Marker.ParentTrack == self, "Marker does not exist in MarkerTrack.")
		self:RevokeMarkerCommands(Marker)
		super.RemoveTrackItem(self, Marker)
		return Marker
	end
end

return MarkerTrack

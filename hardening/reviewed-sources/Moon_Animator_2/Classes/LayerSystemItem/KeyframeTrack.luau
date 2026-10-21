local _g = _G.MoonGlobal; _g.req("Track", "Keyframe", "Ease")
local KeyframeTrack = super:new()

function KeyframeTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.Path = Path
		ctor.PropertyData = PropertyData
		ctor.Target = nil
		ctor.property = nil
		ctor.tweenFunction = _g.ItemTable.PropertyTypes[PropertyData[2]]
		ctor.value = nil
		ctor.defaultValue = nil
		ctor.lastValue = nil
		ctor.lastFrame = 0
		ctor.previous_value = nil
		ctor.BufferMap = {}
		ctor.KeyframeMap = {}
		ctor.MinBuffer = nil
		ctor.MaxBuffer = nil
		ctor.UpdateLast = false
		ctor.handle_clicked = _g.BLANK_FUNC
		
		if PropertyData.Holder then
			ctor.Target = _g.ItemTable.PropertyTypeHolders[PropertyData[2]]:Clone(); ctor.Target.Parent = _g.new_ui
			ctor.ListComponent.Label.Text = PropertyData[1]
			ctor.property = "Value"
			ctor.UpdateLast = PropertyData[1] ~= "CFrame"
		else
			ctor.Target = ctor.Path:GetItem()
			ctor.ListComponent.Label.Text = PropertyData[1]
			ctor.property = PropertyData[1]
		end
	end

	return ctor
end

function KeyframeTrack:init_values()
	self.value = (self.defaultValue ~= nil) and self.defaultValue or self:get_prop()
	self.defaultValue = self.value
	self.lastValue = self.value
end

function KeyframeTrack:set_select(value)
	super.set_select(self, value)
	self.TrackItems:Iterate(function(kf)
		local middle_color = value and "highlight" or (kf.ease_colored and "main" or ((kf.is_constant or kf.is_linear) and "main" or "third"))
		if kf.group then
			kf:SetItemPaint(kf.UI.BG_Middle.Line, {BackgroundColor3 = middle_color})
			kf:SetItemPaint(kf.UI.Start, {BackgroundColor3 = middle_color})
			kf:SetItemPaint(kf.UI.End, {BackgroundColor3 = middle_color})
		else
			kf:SetItemPaint(kf.UI.Middle, {BackgroundColor3 = middle_color})
		end
	end)
end

function KeyframeTrack:update_value(frm_pos)
	if not self.Enabled then
		self.value = self.defaultValue
	elseif frm_pos >= self.lastFrame then
		self.value = self.lastValue
	elseif self.BufferMap[frm_pos] ~= nil then
		self.value = self.BufferMap[frm_pos]
	else
		assert(false, "Buffer missing.")
	end
	if self.value == _g.NIL_VALUE then
		self.value = nil
	end
end

function KeyframeTrack:_Update(frm_pos)
	self:update_value(frm_pos)
	
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	self.Target[self.property] = self.value
end

function KeyframeTrack:get_prop()
	return self.Target[self.property]
end

function KeyframeTrack:set_prop(value)
	self.Target[self.property] = value
end

function KeyframeTrack:Destroy()
	if self.PropertyData.Holder then
		self.Target:Destroy()
	end
	local saveLS = self.LayerSystem
	local saveTS = tostring(self)
	super.Destroy(self)
	saveLS.PlaybackHandler.InvalidKeyframeTracks[saveTS] = nil
end

function KeyframeTrack:SetEnabled(value, inputted)
	super.SetEnabled(self, value, inputted)
	
	self.LayerSystem.PlaybackHandler.ActiveTracks[tostring(self)] = value and self or nil
	if inputted then
		self:_Update(self.LayerSystem.SliderFrame)
	end
end

function KeyframeTrack:TargetValueIterator(StartKeyframe, EndKeyframe)
	local CurrentKeyframe = StartKeyframe
	if CurrentKeyframe == nil or CurrentKeyframe == "begin" then
		if self.TrackItems.Objects[1] then
			CurrentKeyframe = self.TrackItems.Objects[1].frm_pos == 0 and self.TrackItems.Objects[1] or 0
		else
			CurrentKeyframe = 0
		end
	end

	local ind
	local TargetPos
	local Values
	local Eases

	local NextKeyframe = function(ini)
		if ini then
			CurrentKeyframe = ini
		else
			if CurrentKeyframe ~= 0 then
				CurrentKeyframe = self:GetNextTrackItem(CurrentKeyframe)
			else
				CurrentKeyframe = self.TrackItems.Objects[1]
			end
		end

		ind = 1
		TargetPos = {}
		Values = CurrentKeyframe and {} or nil
		Eases = {}

		if Values ~= nil and CurrentKeyframe ~= 0 then
			CurrentKeyframe:IterateTargetValues(function(pos, value, ease)
				table.insert(TargetPos, pos)
				table.insert(Values, value)
				table.insert(Eases, ease)
			end)
		end
	end

	NextKeyframe(CurrentKeyframe)

	return function()
		local retPos, retValue, retEase

		if CurrentKeyframe == nil then
			return nil, nil, nil, nil
		elseif CurrentKeyframe == 0 then
			retPos, retValue, retEase = 0, self.defaultValue ~= nil and self.defaultValue or _g.NIL_VALUE, Ease.LINEAR()
			NextKeyframe()
		else
			retPos, retValue, retEase = TargetPos[ind] + CurrentKeyframe.frm_pos, Values[ind], Eases[ind]
			ind = ind + 1
			if Values[ind] == nil then
				if CurrentKeyframe == EndKeyframe then
					CurrentKeyframe = nil
				else
					NextKeyframe()
				end
			end
		end

		return retPos, retValue, retEase
	end
end

do
	function KeyframeTrack:MoveKeyframe(Keyframe, frm_pos)
		assert(self.TrackItems:Contains(Keyframe), "Keyframe is not in KeyframeTrack.")
		self:RemoveKeyframe(Keyframe)
		Keyframe.frm_pos = frm_pos
		self:AddKeyframe(Keyframe)
		return Keyframe
	end

	function KeyframeTrack:AddKeyframe(Keyframe, overwrite)
		assert(Keyframe.ParentTrack == nil, "Keyframe already is parented to a KeyframeTrack.")
		super.AddTrackItem(self, Keyframe, overwrite)
		
		self:InvalidateBuffer(Keyframe)
		if self.selected then
			if Keyframe.group then
				Keyframe:SetItemPaint(Keyframe.UI.BG_Middle.Line, {BackgroundColor3 = "highlight"})
				Keyframe:SetItemPaint(Keyframe.UI.Start, {BackgroundColor3 = "highlight"})
				Keyframe:SetItemPaint(Keyframe.UI.End, {BackgroundColor3 = "highlight"})
			else
				Keyframe:SetItemPaint(Keyframe.UI.Middle, {BackgroundColor3 = "highlight"})
			end
		end
		
		self.LayerSystem.KeyframeCount = self.LayerSystem.KeyframeCount + Keyframe.value_count
		self.ItemObject:add_pose(Keyframe.frm_pos)
		
		return Keyframe
	end

	function KeyframeTrack:RemoveKeyframe(Keyframe)
		assert(Keyframe.ParentTrack == self, "Keyframe does not exist in KeyframeTrack.")
		
		if self.TrackItems.size == 1 then
			self.MinBuffer = nil
			self.MaxBuffer = nil
			self.lastFrame = 0
			self.lastValue = self.defaultValue
		else
			if self.MaxBuffer == Keyframe then
				self.MaxBuffer = self:GetPreviousTrackItem(Keyframe)
			end
			local oldMax = self.MaxBuffer
			self:InvalidateBuffer(Keyframe)
			if self.MaxBuffer == Keyframe then
				self.MaxBuffer = oldMax
			end
			if self.lastFrame == Keyframe.frm_pos + Keyframe.width then
				local prev = self:GetPreviousTrackItem(Keyframe)
				self.lastFrame = prev.frm_pos + prev.width
				self.lastValue = prev.TargetValues[prev.width]
			end
		end
		
		for pos, _ in pairs(Keyframe.TargetValues) do
			self.KeyframeMap[Keyframe.frm_pos + pos] = nil
		end
		self.LayerSystem.KeyframeCount = self.LayerSystem.KeyframeCount - Keyframe.value_count
		self.ItemObject:remove_pose(Keyframe.frm_pos)

		return super.RemoveTrackItem(self, Keyframe)
	end
end

function KeyframeTrack:InvalidateBuffer(Keyframe)
	local PrevTI = self:GetPreviousTrackItem(Keyframe)
	local NextTI = self:GetNextTrackItem(Keyframe)

	if PrevTI == nil then
		PrevTI = "begin"
	end
	if NextTI == nil then
		NextTI = Keyframe
		self.lastFrame = Keyframe.frm_pos + Keyframe.width
		self.lastValue = Keyframe.TargetValues[Keyframe.width]
	end

	if self.MinBuffer ~= "begin" and (self.MinBuffer == nil or PrevTI == "begin" or self.MinBuffer.frm_pos > PrevTI.frm_pos) then
		self.MinBuffer = PrevTI
	end
	if self.MaxBuffer == nil or self.MaxBuffer.frm_pos < NextTI.frm_pos then
		self.MaxBuffer = NextTI
	end
	
	for pos, val in pairs(Keyframe.TargetValues) do
		self.KeyframeMap[Keyframe.frm_pos + pos] = val
	end

	self.LayerSystem.PlaybackHandler.InvalidKeyframeTracks[tostring(self)] = self
end

function KeyframeTrack:Buffer()
	assert(not ((self.MinBuffer == nil and not self.MaxBuffer == nil) or (not self.MinBuffer == nil and self.MaxBuffer == nil)), "Buffer variable error.")

	if self.TrackItems.size == 0 then
		self.BufferMap = {}
		self.MinBuffer = nil
		self.MaxBuffer = nil
		self:_Update(self.LayerSystem.SliderFrame)
		return
	end

	local startPos, startValue, startEase

	for pos, value, ease in self:TargetValueIterator(self.MinBuffer, self.MaxBuffer) do
		if startPos == nil then
			startPos = pos
			startValue = value
			startEase = ease
			self.BufferMap[startPos] = startValue
		else
			local dist = pos - startPos
			assert(dist > 0, "Keyframes placed on top of each other.")
			
			for bufferPos = startPos, pos, 1 do
				self.BufferMap[bufferPos] = self.tweenFunction(startValue, value, startEase._func((bufferPos - startPos) / dist), self.defaultValue)
			end

			startPos = pos
			startValue = value
			startEase = ease
		end
	end
	
	if self.BufferMap[0] == nil then
		self.BufferMap[0] = self.defaultValue
		local to_val = self.BufferMap[startPos]
		for bufferPos = 1, startPos - 1, 1 do
			self.BufferMap[bufferPos] = self.tweenFunction(self.BufferMap[0], to_val, bufferPos / startPos, self.defaultValue)
		end
	end

	self.MinBuffer = nil
	self.MaxBuffer = nil
	
	self:_Update(self.LayerSystem.SliderFrame)

	self.LayerSystem.PlaybackHandler.InvalidKeyframeTracks[tostring(self)] = nil
end

return KeyframeTrack

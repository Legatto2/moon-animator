local _g = _G.MoonGlobal; _g.req("Object")
local PlaybackHandler = super:new()
local EventTrack = require(_g.class.MarkerTrack)

function PlaybackHandler:new(LayerSystem)
	local ctor = super:new(LayerSystem)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.LayerSystem = LayerSystem
		ctor.Playing = false
		ctor.Loop = false
		ctor.temp_play = false
		ctor.full_playback = false

		ctor.ActiveTracks = {}
		ctor.InvalidKeyframeTracks = {}
		ctor.lastFramePosition = nil
		ctor.ContinuousPosition = 0
		ctor.PlayArea = LayerSystem.Scalable.PlayArea
		ctor.PlayAreaBar = LayerSystem.Timeline.BottomSec.PlayArea.Bar
		ctor.PlayArea_Start = 0
		ctor.PlayArea_End = _g.DEFAULT_FRAMES
		ctor.PlayAreaMiddleCallback = nil
		
		_g.GuiLib:AddInput(ctor.PlayArea.Middle, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = PlaybackHandler._PlayAreaTopDragBegin, func_changed = PlaybackHandler._PlayAreaTopChanged, func_ended = PlaybackHandler._PlayAreaTopDragEnd,
		}})
		_g.GuiLib:AddInput(ctor.PlayArea.Middle.StartFrame.Start, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = PlaybackHandler._PlayAreaTopDragBegin, func_changed = PlaybackHandler._PlayAreaTopChanged, func_ended = PlaybackHandler._PlayAreaTopDragEnd,
		}})
		_g.GuiLib:AddInput(ctor.PlayArea.Middle.EndFrame.End, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = PlaybackHandler._PlayAreaTopDragBegin, func_changed = PlaybackHandler._PlayAreaTopChanged, func_ended = PlaybackHandler._PlayAreaTopDragEnd,
		}})

		_g.GuiLib:AddInput(ctor.PlayAreaBar.Middle, {drag = {
			caller_obj = ctor,
			func_start = PlaybackHandler._PlayAreaDragBegin, func_changed = PlaybackHandler._PlayAreaChanged, func_ended = PlaybackHandler._PlayAreaDragEnd,
		}})
		_g.GuiLib:AddInput(ctor.PlayAreaBar.Start, {drag = {
			caller_obj = ctor,
			func_start = PlaybackHandler._PlayAreaDragBegin, func_changed = PlaybackHandler._PlayAreaChanged, func_ended = PlaybackHandler._PlayAreaDragEnd,
		}})
		_g.GuiLib:AddInput(ctor.PlayAreaBar.End, {drag = {
			caller_obj = ctor,
			func_start = PlaybackHandler._PlayAreaDragBegin, func_changed = PlaybackHandler._PlayAreaChanged, func_ended = PlaybackHandler._PlayAreaDragEnd,
		}})
		
		_g.GuiLib:AddInput(LayerSystem.Timeline.BottomSec, {down = {
			mouse_but = Enum.UserInputType.MouseButton3, func = function() ctor.PlayAreaMiddleCallback() end
		}})
		
		ctor:AddPaintedItem(ctor.PlayArea.Middle, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.PlayArea.Middle.StartFrame.Start.Frame, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.PlayArea.Middle.StartFrame.Start.Frame.UIStroke, {Color = "highlight"})
		ctor:AddPaintedItem(ctor.PlayArea.Middle.EndFrame.End.Frame, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.PlayArea.Middle.EndFrame.End.Frame.UIStroke, {Color = "highlight"})
		ctor:AddPaintedItem(ctor.PlayAreaBar, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.PlayAreaBar.Start.Frame, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.PlayAreaBar.End.Frame, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.PlayAreaBar.Parent.Past.Frame, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.PlayAreaBar.Parent.Future.Frame, {BackgroundColor3 = "highlight"})
		
		_G.set_play = ctor
	end

	return ctor
end

do
	function PlaybackHandler:SetPlayArea(pa_start, pa_end)
		local length = self.LayerSystem.length
		assert(pa_start <= pa_end and pa_start >= 0 and pa_end <= length, "Invalid Play Area range.")
		pa_start = math.floor(pa_start + 0.5); pa_end = math.floor(pa_end + 0.5)
		local diff = pa_end - pa_start; local per = diff / length

		self.PlayArea_Start = pa_start; self.PlayArea_End = pa_end

		self.PlayArea.Size = self.PlayArea.Size + UDim2.new(-self.PlayArea.Size.X.Scale + per, 0, 0, 0)
		self.PlayArea.Position = self.PlayArea.Position + UDim2.new(-self.PlayArea.Position.X.Scale + (pa_start / length), 0, 0, 0)
		
		self.PlayAreaBar.Size = self.PlayAreaBar.Size + UDim2.new(-self.PlayAreaBar.Size.X.Scale + per, 0, 0, 0)
		self.PlayAreaBar.Position = self.PlayAreaBar.Position + UDim2.new(-self.PlayAreaBar.Position.X.Scale + (pa_start / length), 0, 0, 0)

		self.PlayAreaBar.Middle.Visible = (pa_end - pa_start) ~= length
	end

	local state
	local STATE_TBL = {["Start"] = 0, ["End"] = 1, ["Middle"] = 2}
	local bar_length
	local bar_bound
	local ini_drag_pos
	local ini_frm_pos
	local has_offset
	local frames_per_pixel
	
	function PlaybackHandler:_PlayAreaTopDragBegin(but, ini_pos)
		state = STATE_TBL[but.Name]
		has_offset = nil

		if state == 2 then
			bar_length = self.PlayArea_End - self.PlayArea_Start; has_offset = bar_length
			bar_bound = self.LayerSystem.length - bar_length
			ini_drag_pos = (self.PlayArea.Middle.StartFrame.AbsolutePosition.X + 1) + (self.PlayArea.Middle.StartFrame.Size.X.Offset / 2) - ini_pos.X
		else
			ini_drag_pos = (but.AbsolutePosition.X + (state == 0 and 1 or -1)) + (but.Size.X.Offset / 2) - ini_pos.X
		end
		ini_frm_pos = state == 2 and self.PlayArea_Start or self["PlayArea_"..but.Name]

		self:Stop()
		self.LayerSystem:SetupTickFrameCoords(ini_frm_pos, ini_drag_pos)
		self.LayerSystem:MoveTickActive(true, ini_frm_pos, has_offset)
		self.LayerSystem:ConnectScrollBounds(true, "h")
	end

	function PlaybackHandler:_PlayAreaTopChanged(but, changed)
		local frm_pos
		if state == 0 then
			frm_pos = math.clamp(self.LayerSystem:GetFrameAtMousePosition(ini_drag_pos), 0, self.PlayArea_End)
			if frm_pos ~= self.PlayArea_Start then
				self:SetPlayArea(frm_pos, self.PlayArea_End)
			end
		elseif state == 1 then
			frm_pos = math.clamp(self.LayerSystem:GetFrameAtMousePosition(ini_drag_pos), self.PlayArea_Start, self.LayerSystem.length)
			if frm_pos ~= self.PlayArea_End then
				self:SetPlayArea(self.PlayArea_Start, frm_pos)
			end
		elseif state == 2 then
			frm_pos = math.clamp(self.LayerSystem:GetFrameAtMousePosition(ini_drag_pos), 0, bar_bound)
			if frm_pos ~= self.PlayArea_Start then
				self:SetPlayArea(frm_pos, frm_pos + bar_length)
			end
		end
		self.LayerSystem:UpdateMoveTick(frm_pos, has_offset)
	end

	function PlaybackHandler:_PlayAreaTopDragEnd(but)
		self.LayerSystem:ConnectScrollBounds(false)
		self.LayerSystem:MoveTickActive(false)
	end

	function PlaybackHandler:_PlayAreaDragBegin(but, ini_pos)
		state = STATE_TBL[but.Name]
		has_offset = nil
		frames_per_pixel = self.LayerSystem.length / self.PlayAreaBar.Parent.AbsoluteSize.X

		if state == 2 then
			bar_length = self.PlayArea_End - self.PlayArea_Start; has_offset = bar_length
			bar_bound = self.LayerSystem.length - bar_length
			ini_drag_pos = (self.PlayAreaBar.Start.AbsolutePosition.X + 1) + (self.PlayAreaBar.Start.Size.X.Offset / 2) - ini_pos.X
		else
			ini_drag_pos = (but.AbsolutePosition.X + (state == 0 and 1 or -1)) + (but.Size.X.Offset / 2) - ini_pos.X
		end
		ini_frm_pos = state == 2 and self.PlayArea_Start or self["PlayArea_"..but.Name]

		self:Stop()
		self.LayerSystem:SetupTickFrameCoords(ini_frm_pos, ini_drag_pos)
		self.LayerSystem:MoveTickActive(true, ini_frm_pos, has_offset)
	end

	function PlaybackHandler:_PlayAreaChanged(but, changed)
		local frm_pos = math.floor(ini_frm_pos + frames_per_pixel * changed.X)
		if state == 0 then
			frm_pos = math.clamp(frm_pos, 0, self.PlayArea_End)
			if frm_pos ~= self.PlayArea_Start then
				self:SetPlayArea(frm_pos, self.PlayArea_End)
			end
		elseif state == 1 then
			frm_pos = math.clamp(frm_pos, self.PlayArea_Start, self.LayerSystem.length)
			if frm_pos ~= self.PlayArea_End then
				self:SetPlayArea(self.PlayArea_Start, frm_pos)
			end
		elseif state == 2 then
			frm_pos = math.clamp(frm_pos, 0, bar_bound)
			if frm_pos ~= self.PlayArea_Start then
				self:SetPlayArea(frm_pos, frm_pos + bar_length)
			end
		end
		self.LayerSystem:UpdateMoveTick(frm_pos, has_offset)
	end

	function PlaybackHandler:_PlayAreaDragEnd(but)
		self.LayerSystem:MoveTickActive(false)
	end
end

function PlaybackHandler:SetLoop(value)
	self.Loop = value
	local col = value and "main" or "third"
	
	self:SetItemPaint(self.LayerSystem.LoopToggle.Bottom.Frame.UIStroke, {Color = col})
	self:SetItemPaint(self.LayerSystem.LoopToggle.Top.Frame.UIStroke, {Color = col})
	self:SetItemPaint(self.LayerSystem.LoopToggle.BottomCircle, {BackgroundColor3 = col})
	self:SetItemPaint(self.LayerSystem.LoopToggle.TopCircle, {BackgroundColor3 = col})
	
	self.LayerSystem.LoopToggle.Off.Visible = not value
	self.LayerSystem.LoopToggle.OffHover.Visible = not value
	
	if self.Playing then
		self:Stop()
		self:Play()
	end
end

function PlaybackHandler:BufferKeyframeTracks()
	local KeyframeTracks = {}
	for _, KeyframeTrack in pairs(self.InvalidKeyframeTracks) do
		table.insert(KeyframeTracks, KeyframeTrack)
	end
	for _, KeyframeTrack in pairs(KeyframeTracks) do
		KeyframeTrack:Buffer()
	end
	if self.LayerSystem.after_buffer then
		self.LayerSystem:SetSliderFrame(self.LayerSystem.after_buffer)
		self.LayerSystem.after_buffer = nil
	end
	self.LayerSystem:update_kf_count(self.LayerSystem.KeyframeCount)
end

function PlaybackHandler:UpdateTracks()
	local LastTracks = {}
	for _, Track in pairs(self.ActiveTracks) do
		if Track.UpdateLast then
			table.insert(LastTracks, Track)
		else
			Track:_Update(self.LayerSystem.SliderFrame)
		end
	end
	for _, Track in pairs(LastTracks) do
		Track:_Update(self.LayerSystem.SliderFrame)
	end
end

do
	local stop_cmd
	local play_start
	local playarea_range
	local scroll_playing_pos

	function PlaybackHandler:_PlayTickLoop(step, frm_step)
		scroll_playing_pos = (scroll_playing_pos + step * self.LayerSystem.FPS) % playarea_range
		self.LayerSystem:SetSliderFrame(play_start + scroll_playing_pos * frm_step)
	end

	function PlaybackHandler:_PlayTickStop(step, frm_step)
		scroll_playing_pos = scroll_playing_pos + step * self.LayerSystem.FPS
		if scroll_playing_pos <= 0 then
			scroll_playing_pos = 0
			stop_cmd = true
		elseif scroll_playing_pos >= playarea_range then
			scroll_playing_pos = playarea_range
			stop_cmd = true
		end
		self.LayerSystem:SetSliderFrame(play_start + scroll_playing_pos * frm_step)
		if stop_cmd then
			if not self.temp_play and (_g.Input.KeysDown["Space"] ~= nil or _g.Input.KeysDown["KeypadEnter"] ~= nil) then
				scroll_playing_pos = 0
				stop_cmd = false
			else
				self:Stop()
			end
		end
	end

	function PlaybackHandler:Play(frm_step, temp_play)
		if frm_step == nil then frm_step = 1 end

		if self.Playing then 
			self:Stop()
		end
		
		local last_kf_pos = self.LayerSystem.LayerHandler:GetLastKeyframePosition()		
		local end_frame = self.PlayArea_End < last_kf_pos and self.PlayArea_End or last_kf_pos

		stop_cmd = false
		if not temp_play then
			self.temp_play = false
			self.full_playback = end_frame == last_kf_pos and self.PlayArea_Start == 0
			
			if self.PlayArea_Start >= end_frame then
				self.LayerSystem:SetSliderFrame(self.PlayArea_Start)
				return
			end

			if frm_step > 0 and (self.LayerSystem.SliderFrame >= end_frame or self.LayerSystem.SliderFrame < self.PlayArea_Start) then
				self.LayerSystem:SetSliderFrame(self.PlayArea_Start)
			elseif frm_step < 0 and (self.LayerSystem.SliderFrame <= self.PlayArea_Start or self.LayerSystem.SliderFrame > end_frame) then
				self.LayerSystem:SetSliderFrame(end_frame)
			end

			play_start = self.PlayArea_Start
			playarea_range = end_frame - self.PlayArea_Start
			scroll_playing_pos = self.LayerSystem.SliderFrame - self.PlayArea_Start

			if self.Loop then
				_g.run_serv:BindToRenderStep("P_"..tostring(self), Enum.RenderPriority.Camera.Value - 1, function(step) PlaybackHandler._PlayTickLoop(self, step, frm_step) end)
			else
				_g.run_serv:BindToRenderStep("P_"..tostring(self), Enum.RenderPriority.Camera.Value - 1, function(step) PlaybackHandler._PlayTickStop(self, step, frm_step) end)
			end
			
			for _, Track in pairs(self.ActiveTracks) do
				Track.LastUpdate = self.LayerSystem.SliderFrame - 1
			end
			self:UpdateTracks()
		else
			self.temp_play = true
			self.full_playback = false
			
			play_start = self.LayerSystem.SliderFrame
			playarea_range = math.abs(temp_play - self.LayerSystem.SliderFrame)
			scroll_playing_pos = 0

			_g.run_serv:BindToRenderStep("P_"..tostring(self), Enum.RenderPriority.Camera.Value - 1, function(step) PlaybackHandler._PlayTickStop(self, step, frm_step) end)
		end
		
		self.LayerSystem.AddPose.Visible = false
		self.Playing = true
	end

	function PlaybackHandler:Stop()
		-- Also clean an idle handler: closing a file or stopping twice is harmless.
		EventTrack.StopSafeEffects(self)
		if not self.Playing then return end

		self.Playing = false
		self.LayerSystem.AddPose.Visible = true
		pcall(function() _g.run_serv:UnbindFromRenderStep("P_"..tostring(self)) end)
		self.LayerSystem:refresh_on_pose()
	end

	function PlaybackHandler:TogglePlayback(frm_step)
		if self.Playing then
			self:Stop()
		else
			self:Play(frm_step)
		end
	end
end

return PlaybackHandler

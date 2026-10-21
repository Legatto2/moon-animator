local _g = _G.MoonGlobal
------------------------------------------------------------
	local Ease = require(_g.class.Ease)
	local LayerSystem
	local SelectionHandler

	local GetEase

	local TargetKeyframes
	local FrameRange

	local WindowData = _g.WindowData:new("Edit Keyframes", script.Contents)
	WindowData.resize = true

	local Win  = _g.Window:new(script.Name, WindowData)

	Button:new(Win.g_e.Confirm)

	Button:new(Win.g_e.ValueMode)

	SelectGrid:new(Win.g_e.EaseType, "Linear", nil); local EaseType = Win.g_e.EaseType
	SelectGrid:new(Win.g_e.Direction, "In", nil); local Direction = Win.g_e.Direction; Direction:SetEnabled(false)
	InputList:new(Win.g_e.Parameters); local Parameters = Win.g_e.Parameters

	Graph:new(Win.g_e.Graph, function(x) return x end); local Graph = Win.g_e.Graph
------------------------------------------------------------
do
	ValueMode.OnClick = function()
		_g.Toggles.SetToggleValue("EaseWindow", false)
	end
	
	function GetCurrentEase()
		local params = {}
		if Direction.Enabled then
			params.Direction = Direction.Value
		end
		for _, list_item in pairs(Parameters._list) do
			if list_item.current ~= list_item.default then
				params[list_item.name] = list_item.current
			end
		end
		return Ease:new(EaseType.Value, params)
	end

	function UpdateGraphSlider()
		if FrameRange.Round and LayerSystem.SliderFrame >= FrameRange.Min and LayerSystem.SliderFrame <= FrameRange.Max then
			Graph:SetSliderPercent((LayerSystem.SliderFrame - FrameRange.Min) / (FrameRange.Max - FrameRange.Min))
		else
			Graph:SetSliderPercent(nil)
		end
	end

	Win.OnOpen = function()
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if not SelectionHandler.TrackItemTypeMap["Keyframe"] then return false end

		TargetKeyframes = {}
		FrameRange = {}

		GetEase = nil
		local GetPropertyData
		local GetValue
		local IsDiscrete = false

		SelectionHandler.SelectedTrackItems:Iterate(function(Keyframe)
			if FrameRange.Min == nil or Keyframe.frm_pos + Keyframe.width < FrameRange.Min then
				FrameRange.Min = Keyframe.frm_pos + Keyframe.width
				
				local NextKeyframe = Keyframe.ParentTrack:GetNextTrackItem(Keyframe)
				FrameRange.Max = NextKeyframe and NextKeyframe.frm_pos or 0
			end

			if GetEase == nil then
				GetEase = Keyframe:GetEase()
			elseif GetEase and not GetEase:Equals(Keyframe:GetEase()) then
				GetEase = false
			end

			if Keyframe.group then
				GetPropertyData = false
			elseif GetPropertyData == nil  then
				GetPropertyData = Keyframe.ParentTrack.PropertyData
				GetValue = Keyframe:GetTargetValue()
			elseif GetPropertyData and Keyframe.ParentTrack.PropertyData[2] ~= GetPropertyData[2] then
				GetPropertyData = false
			elseif GetPropertyData then
				if GetValue ~= nil and Keyframe:GetTargetValue() ~= GetValue then
					GetValue = nil
				end
			end

			if _g.objIsType(Keyframe.ParentTrack, "DiscreteKeyframeTrack") then
				IsDiscrete = true
			end

			table.insert(TargetKeyframes, {Keyframe, Keyframe:GetEase():Tableize(), Keyframe:GetTargetValue()})
		end, "Keyframe")

		if FrameRange.Max - FrameRange.Min > 0 then
			FrameRange.Round = 1 / (FrameRange.Max - FrameRange.Min)
		end

		EaseType:Set(nil, true)
		if GetEase then
			GetEase = GetEase:Tableize()
			
			EaseType:Set(GetEase.ease_type, true)
			if GetEase.params then
				if GetEase.params.Direction then
					Direction:Set(GetEase.params.Direction, true)
				end
			end
		end

		Graph:DrawLine(Graph.Func)
		Graph:SetSliderPercent(nil)
		_g.run_serv:BindToRenderStep("GraphSlider_"..tostring(Win), Enum.RenderPriority.Camera.Value - 1, UpdateGraphSlider)

		EaseType:SetEnabled(not IsDiscrete)

		return true
	end
	
	Win.OnClose = function(save)
		pcall(function() _g.run_serv:UnbindFromRenderStep("GraphSlider_"..tostring(Win)) end)
		if LayerSystem.PlaybackHandler.Playing then
			LayerSystem.PlaybackHandler:Stop()
		end

		for _, tbl in pairs(TargetKeyframes) do
			tbl[1]:SetEase(Ease.Detableize(tbl[2]))
			tbl[1]:SetTargetValue(tbl[3])
			tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
		end
		LayerSystem.PlaybackHandler:BufferKeyframeTracks()

		if save then
			local data = {TargetKeyframes = {}}
			for _, tbl in pairs(TargetKeyframes) do
				table.insert(data.TargetKeyframes, tbl[1])
			end

			if EaseType.Enabled and EaseType.Value then
				local new_ease = GetCurrentEase()

				local ease_differ = false
				for _, Keyframe in pairs(data.TargetKeyframes) do
					if not Keyframe:GetEase():Equals(new_ease) then
						ease_differ = true
						break
					end
				end
				if ease_differ then
					data.ease = new_ease:Tableize()
				end
				
				new_ease:Destroy()
			end

			if data.ease then
				_g.Windows.MoonAnimator.DoCompositeAction("EditKeyframes", data)
			end
		end

		return true
	end

	Direction._changed = function()
		local get_ease = GetCurrentEase()
		Graph:DrawLine(get_ease._func)
		get_ease:Destroy()

		for _, tbl in pairs(TargetKeyframes) do
			tbl[1]:SetEase(GetCurrentEase())
			tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
		end
		LayerSystem.PlaybackHandler:BufferKeyframeTracks()
	end

	Parameters._changed = Direction._changed

	EaseType._changed = function(value)
		local EaseData = value and Ease.EASE_DATA[value] or nil

		if EaseData and EaseData.Params then
			Direction:SetEnabled(EaseData.Params.Direction)

			local param_list = {}
			for param_name, _ in pairs(EaseData.Params) do
				if param_name ~= "Direction" then
					local new_list_item = _g.deepcopy(Ease.PARAM_DATA[param_name])
					if GetEase and GetEase.params and GetEase.params[param_name] then
						new_list_item.current = GetEase.params[param_name]
					end
					if new_list_item.frame_relative then
						new_list_item.frame_relative = FrameRange.Round and FrameRange.Max - FrameRange.Min or nil
					end
					table.insert(param_list, new_list_item)
				end
			end

			Parameters:SetList(param_list)
			Parameters:SetEnabled(#param_list > 0)
		else
			Direction:SetEnabled(false)
			Parameters:SetList({})
			Parameters:SetEnabled(false)
		end

		if value then
			Direction._changed()
		else
			Graph:DrawLine(function() return 0 end)
		end
	end

	local begin_pos
	local max_size

	_g.GuiLib:AddInput(Graph.UI.Slider.Drag, {drag = {
		caller_obj = Graph, render_loop = true,
		func_start = function(_, obj)
			if FrameRange.Round == nil then return false end
			begin_pos = _g.Mouse.X - Graph.UI.AbsolutePosition.X
			max_size = Graph.UI.AbsoluteSize.X
			if LayerSystem.PlaybackHandler.Playing then
				LayerSystem.PlaybackHandler:Stop()
			end
		end, 
		func_changed = function(_, obj, changed)
			if FrameRange.Round == nil then return false end
			local per = _g.round((begin_pos + changed.X) / max_size, FrameRange.Round)
			LayerSystem:SetSliderFrame(FrameRange.Min + math.floor((FrameRange.Max - FrameRange.Min) * per))
		end,
	}})

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end
------------------------------------------------------------
do
	_g.Input:BindAction(Win, "PreviewEase", function()
		if FrameRange.Round then
			if LayerSystem.PlaybackHandler.Playing then
				LayerSystem.PlaybackHandler:Stop()
			end
			LayerSystem:SetSliderFrame(FrameRange.Min)
			LayerSystem.PlaybackHandler:Play(1, FrameRange.Max)
		end
	end, {"Space"}, false)
end

return Win

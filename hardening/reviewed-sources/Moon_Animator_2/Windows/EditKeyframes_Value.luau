local _g = _G.MoonGlobal
------------------------------------------------------------
	local Ease = require(_g.class.Ease)
	local LayerSystem
	local SelectionHandler

	local TargetKeyframes
	local FrameRange

	local ValueInput
	local ValueType

	local CurrentEase

	local is_cf
	local value_differ
	local kf_values_unique

	local sizes = {
		default = {208,172},
		CFrame = {225,244},
		Instance = {208,188},
		boolean = {208,170},
		Vector3 = {242,172},
		string = {242,186},
	}

	local Win = _g.Window:new(script.Name, _g.WindowData:new("Edit Keyframes", script.Contents))
	Win.ValueChanged = function(value, relative)
		if value ~= nil then
			LayerSystem:SetSliderFrame(FrameRange.Min)
			for _, tbl in pairs(TargetKeyframes) do
				if relative and _g.objIsType(tbl[1].ParentTrack, "RigKeyframeTrack") then
					local joint = tbl[1].ParentTrack.Target
					if joint.ClassName == "Motor6D" then
						if relative == 2 then
							tbl[1]:SetTargetValue(value:ToObjectSpace(joint.Part0:GetRenderCFrame()) * joint.C0)
						elseif relative == 1 then
							local new_cf = CFrame.new(value.p) * CFrame.Angles(tbl[1].ParentTrack.Target.Part1:GetRenderCFrame():ToEulerAngles())
							tbl[1]:SetTargetValue(new_cf:ToObjectSpace(joint.Part0:GetRenderCFrame()) * joint.C0)
						elseif relative == 0 then
							local new_cf = CFrame.new(tbl[1].ParentTrack.Target.Part1:GetRenderCFrame().p) * CFrame.Angles(value:ToEulerAngles())
							tbl[1]:SetTargetValue(new_cf:ToObjectSpace(joint.Part0:GetRenderCFrame()) * joint.C0)
						end
					else
						tbl[1]:SetTargetValue(CFrame.new())
					end
					value_differ = true
					kf_values_unique = true
					p_CFrame:Set(tbl[1]:GetTargetValue())
				else
					tbl[1]:SetTargetValue(value)
					value_differ = value
				end
				tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
			end
			LayerSystem.PlaybackHandler:BufferKeyframeTracks()
		end
	end

	Button:new(Win.g_e.Confirm)

	EaseInput:new(Win.g_e.EaseInput, nil, nil)
	Button:new(Win.g_e.EaseMode)

	NumberInput:new(Win.g_e.p_number, nil, Win.ValueChanged)
	TextInput:new(Win.g_e.p_string, nil, Win.ValueChanged)
	InstanceInput:new(Win.g_e.p_Instance, _g.NIL_VALUE, Win.ValueChanged)
	Check:new(Win.g_e.p_boolean, false, Win.ValueChanged)
	ListInput:new(Win.g_e.p_EnumItem, nil, Win.ValueChanged, {})
	CFrameInput:new(Win.g_e.p_CFrame, nil, Win.ValueChanged)
	ColorInput:new(Win.g_e.p_Color3, nil, Win.ValueChanged, Win)
	VectorInput:new(Win.g_e.p_Vector2, nil, Win.ValueChanged, true)
	VectorInput:new(Win.g_e.p_Vector3, nil, Win.ValueChanged)
	ColorInput:new(Win.g_e.p_ColorSequence, nil, function(value) Win.ValueChanged(ColorSequence.new(value)) end, Win)
	NumberInput:new(Win.g_e.p_NumberSequence, nil, function(value) Win.ValueChanged(NumberSequence.new(value)) end)
	NumberInput:new(Win.g_e.p_NumberRange, nil, function(value) Win.ValueChanged(NumberRange.new(value, value)) end)
------------------------------------------------------------
do
	EaseMode.OnClick = function()
		_g.Toggles.SetToggleValue("EaseWindow", true)
	end

	Win.OnOpen = function()
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if not SelectionHandler.TrackItemTypeMap["Keyframe"] then return false end

		TargetKeyframes = {}
		FrameRange = {}

		local GetEase
		local GetPropertyData
		local GetValue
		local IsDiscrete = false
		
		is_cf = false
		value_differ = nil
		kf_values_unique = false

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
		
		if GetEase then
			GetEase = GetEase:Tableize()
			if GetEase.params and GetEase.params.Direction then
				EaseInput.LastDir = GetEase.params.Direction
			end
			EaseInput:Set(GetEase)
		else
			EaseInput:Set(nil)
		end

		EaseInput:SetEnabled(not IsDiscrete)

		if GetPropertyData == false then
			ValueInput = nil
			ValueType = nil
			Win:SetSize(sizes.default[1], sizes.default[2])
		else
			ValueType = GetPropertyData[2]
			ValueInput = Win.g_e["p_"..ValueType]
			ValueInput.UI.Visible = true
			
			local window_size = sizes[ValueType] and sizes[ValueType] or sizes.default
			Win:SetSize(window_size[1], window_size[2])

			if ValueType == "number" then
				ValueInput.Inc = GetPropertyData.Inc and GetPropertyData.Inc or 1
			end
			
			if GetValue == nil then
				ValueInput:Set(GetValue)
			elseif ValueType == "EnumItem" then
				local target_enum = GetPropertyData.SpecialEnum and Enum[GetPropertyData.SpecialEnum] or Enum[GetPropertyData[1]]
				local enum_vals = {}
				for _, enum in pairs(target_enum:GetEnumItems()) do
					table.insert(enum_vals, {enum.Name, enum})
				end
				ValueInput:SetList(enum_vals)
				ValueInput:Set(GetValue.Name)
			elseif ValueType == "ColorSequence" or ValueType == "NumberSequence" then
				ValueInput:Set(GetValue.Keypoints[1].Value)
			elseif ValueType == "NumberRange" then
				ValueInput:Set(GetValue.Min)
			else
				ValueInput:Set(GetValue)
			end
			is_cf = ValueType == "CFrame"
		end

		return true
	end
	Win.OnClose = function(save)
		if LayerSystem.PlaybackHandler.Playing then
			LayerSystem.PlaybackHandler:Stop()
		end

		if ValueInput then
			ValueInput.UI.Visible = false
		end

		if save then
			local data = {TargetKeyframes = {}}
			
			for _, tbl in pairs(TargetKeyframes) do
				table.insert(data.TargetKeyframes, tbl[1])
			end

			if CurrentEase then
				data.ease = CurrentEase
				CurrentEase = nil
			end
			
			if value_differ ~= nil then
				if kf_values_unique then
					data.TargetValues = {}
					for _, kf in pairs(data.TargetKeyframes) do
						table.insert(data.TargetValues, kf:GetTargetValue())
					end
				else
					data.TargetValues = value_differ
				end
			end

			if data.ease or data.TargetValues ~= nil then
				for _, tbl in pairs(TargetKeyframes) do
					tbl[1]:SetEase(Ease.Detableize(tbl[2]))
					tbl[1]:SetTargetValue(tbl[3])
					tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
				end
				LayerSystem.PlaybackHandler:BufferKeyframeTracks()
				_g.Windows.MoonAnimator.DoCompositeAction("EditKeyframes", data)
			end
		else
			if CurrentEase then
				CurrentEase = nil
			end
			
			for _, tbl in pairs(TargetKeyframes) do
				tbl[1]:SetEase(Ease.Detableize(tbl[2]))
				tbl[1]:SetTargetValue(tbl[3])
				tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
			end
			LayerSystem.PlaybackHandler:BufferKeyframeTracks()
		end

		return true
	end
	
	function GetCurrentEase()
		CurrentEase = EaseInput.Value
		for _, tbl in pairs(TargetKeyframes) do
			tbl[1]:SetEase(Ease.Detableize(CurrentEase))
			tbl[1].ParentTrack:InvalidateBuffer(tbl[1])
		end
		LayerSystem.PlaybackHandler:BufferKeyframeTracks()
	end

	EaseInput._changed = function()
		GetCurrentEase()
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end
------------------------------------------------------------
do
	_g.Input:BindAction(Win, "PreviewValue", function()
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

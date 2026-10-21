local _g = _G.MoonGlobal
------------------------------------------------------------
	local SelectionHandler

	local TrackData = {}
	local CurrentPropertyType
	local IsDiscrete

	local TargetTrackItems = {}

	local sizes = {
		default = {188,218},
		none = {152,194},
		string = {205,218},
		number = {205,240},
		boolean = {152,218},
		Color3 = {159,218},
		Vector3 = {242,218},
		CFrame = {225,266},
	}

	local Win = _g.Window:new(script.Name, _g.WindowData:new("Fill Frames", script.Contents))
	local ParameterFrame = Win.Contents.Section.Section.Property

	Button:new(Win.g_e.Confirm)

	TimeInput:new(Win.g_e.Interval, 0, nil); Interval:Set(2)
	EaseInput:new(Win.g_e.EaseInput, nil, nil)
	Check:new(Win.g_e.Wiggle, false)

	NumberInput:new(Win.g_e.number_Mag, 1, nil); Check:new(Win.g_e.MinZero, false)
	NumberInput:new(Win.g_e.string_Mag, 8, nil, {0, 127, 1, true})
	NumberInput:new(Win.g_e.boolean_Prob, 0.5, nil, {0, 1, 0.1})
	VectorInput:new(Win.g_e.Vector3_Mag, Vector3.new(1, 1, 1), nil)
	VectorInput:new(Win.g_e.Vector2_Mag, Vector2.new(1, 1), nil, true)
	ColorInput:new(Win.g_e.Color3_Mag, Color3.fromRGB(16, 16, 16), nil, Win)
	CFrameInput:new(Win.g_e.CFrame_Mag, CFrame.new() * CFrame.Angles(math.rad(2), math.rad(2), math.rad(2)), nil)
	CFrame_Mag.CopyAngle.UI.Visible = false; CFrame_Mag.CopyPos.UI.Visible = false; CFrame_Mag.CopyBoth.UI.Visible = false
------------------------------------------------------------
do
	function ClearBuffers()
		TrackData = {}
		CurrentPropertyType = nil

		TargetTrackItems = {}

		for _, obj in pairs(ParameterFrame:GetChildren()) do
			obj.Visible = false
		end
	end
	ClearBuffers()
	
	Wiggle._changed = function(value)
		number_Mag:SetEnabled(value); MinZero:SetEnabled(value)
		string_Mag:SetEnabled(value)
		boolean_Prob:SetEnabled(value)
		Vector3_Mag:SetEnabled(value)
		Vector2_Mag:SetEnabled(value)
		Color3_Mag:SetEnabled(value)
		CFrame_Mag:SetEnabled(value)
	end
	Wiggle:Set(false, true)

	Win.OnOpen = function()
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if SelectionHandler.SelectedTrackItems.size == 0 then return false end

		TrackData, TargetTrackItems, CurrentPropertyType = SelectionHandler:GetFromToSelectionData(false, "Keyframe")
		if #TargetTrackItems == 0 then 
			ClearBuffers()
			return false 
		end
		
		for _, track in pairs(TrackData) do track = track.Track
			if _g.objIsType(track, "DiscreteKeyframeTrack") then
				IsDiscrete = true
				break
			end
		end
		
		EaseInput:SetEnabled(not IsDiscrete)

		local minDiff
		for _, tbl in pairs(TrackData) do
			if tbl.From ~= tbl.To then
				local diff = tbl.To.frm_pos - (tbl.From.frm_pos + tbl.From.width)
				if minDiff == nil or diff < minDiff then
					minDiff = diff
				end
			end
		end

		if minDiff == nil then
			ClearBuffers()
			return false 
		end

		if minDiff == 1 then
			Interval.Min = 0
			Interval.Max = 0
		else
			Interval.Min = 1
			Interval.Max = minDiff - 1
		end
		Interval:Set(Interval.Value)
		
		local ui_name = CurrentPropertyType
		if CurrentPropertyType == "NumberSequence" or CurrentPropertyType == "NumberRange" then
			ui_name = "number"
		elseif CurrentPropertyType == "ColorSequence" then
			ui_name = "Color3"
		end
		
		if not CurrentPropertyType or ParameterFrame:FindFirstChild("p_"..ui_name) == nil or minDiff == 1 then
			Win:SetSize(sizes.none[1], sizes.none[2])
			Wiggle:SetEnabled(false)
		else
			ParameterFrame["p_"..ui_name].Visible = true

			local window_size = sizes[ui_name] and sizes[ui_name] or sizes.default
			Win:SetSize(window_size[1], window_size[2])
			Wiggle:SetEnabled(true)
		end
		return true
	end

	Win.OnClose = function(save)
		if save then
			local parameterTable = (Wiggle.Enabled and Wiggle.Value) and {
				number_Mag = number_Mag.Value, MinZero = MinZero.Value,
				string_Mag = string_Mag.Value,
				boolean_Prob = boolean_Prob.Value,
				Vector3_Mag = Vector3_Mag.Value,
				Vector2_Mag = Vector2_Mag.Value,
				Color3_Mag = Color3_Mag.Value,
				CFrame_Mag = CFrame_Mag,
			} or nil
			_g.Windows.MoonAnimator.DoCompositeAction("FillFrames", {TrackData = TrackData, Interval = Interval.Value, PropertyType = CurrentPropertyType, Params = parameterTable, Ease = EaseInput.Value})
		end
		ClearBuffers()
		return true
	end
	
	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

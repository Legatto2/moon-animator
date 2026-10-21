local _g = _G.MoonGlobal
------------------------------------------------------------
	local LayerSystem

	local OldPriority
	local OldLength
	local OldFPS
	local OldFileName

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Animation Settings", script.Contents))

	ListInput:new(Win.g_e.Priority, "Action", nil, 
	{{"Action", "Action"}, {"Movement", "Movement"}, {"Idle", "Idle"}, {"Core", "Core"}, {"Action4", "Action4"}, {"Action3", "Action3"}, {"Action2", "Action2"}})
	TimeInput:new(Win.g_e.Time, _g.DEFAULT_FRAMES, nil)
	NumberInput:new(Win.g_e.FPS, _g.DEFAULT_FPS, nil, {1, 999, 1})
	Check:new(Win.g_e.StretchFPS, true, nil)
	TextInput:new(Win.g_e.FileName, "", nil)

	Button:new(Win.g_e.Confirm)

	Win.FocusedTextBox = FileName.UI.Frame.Input
------------------------------------------------------------
do
	FPS._changed = function(value)
		if value ~= OldFPS then
			StretchFPS:SetEnabled(true)
			Time.set_fps = value
		else
			StretchFPS:SetEnabled(false)
			Time.set_fps = nil
		end
		Time:Set(Time.Value)
	end

	Win.OnOpen = function()
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		
		local last = LayerSystem.LayerHandler:GetLastKeyframePosition()
		if last < LayerSystem.FPS then
			last = LayerSystem.FPS
		end
		
		OldPriority = LayerSystem.ExportPriority
		OldLength = LayerSystem.length
		OldFPS = LayerSystem.FPS
		OldFileName = LayerSystem.CurrentFile.Name
		
		Priority:Set(OldPriority)
		Time.Min = last; Time.set_fps = OldFPS; Time:Set(OldLength)
		FPS:Set(OldFPS)
		FileName:Set(OldFileName)
		
		StretchFPS:SetEnabled(false)

		return true
	end
	Win.OnClose = function(save)
		if save then
			local data = {}

			if Priority.Value ~= OldPriority then
				data.Priority = Priority.Value
			end
			if Time.Value ~= OldLength then
				data.length = Time.Value
			end
			if FPS.Value ~= OldFPS then
				data.FPS = FPS.Value
				data.StretchFPS = StretchFPS.Value
			end
			if FileName.Value ~= OldFileName then
				data.FileName = FileName.Value 
			end

			if next(data) then
				_g.Windows.MoonAnimator.DoCompositeAction("EditAnimationSettings", data)
				if data.FileName then
					_g.Windows.MoonAnimator:SaveFile()
				end
			end
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

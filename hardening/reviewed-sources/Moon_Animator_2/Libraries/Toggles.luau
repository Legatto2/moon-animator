local _g = _G.MoonGlobal
local Toggles = {}

------------------------------------------------------------
	local ToggleStorage = {}
------------------------------------------------------------
do
	Toggles.CreateToggle = function(toggleName, data)
		assert(data.Default ~= nil, "New Toggle does not have a default value.")

		ToggleStorage[toggleName] = data
		if data.Temp == nil then
			local get = _g.plugin:GetSetting("MoonAnimator2_Toggle_"..toggleName)
			if get == nil then
				data.Value = data.Default
				_g.plugin:SetSetting("MoonAnimator2_Toggle_"..toggleName, data.Value)
			else
				data.Value = get
			end
		else
			data.Value = data.Default
		end
		
		if _g.AllMenuItems[toggleName] then
			_g.AllMenuItems[toggleName]:set_check(_g.Toggles.GetToggleValue(toggleName))
		end
	end
end
------------------------------------------------------------
do
	Toggles.SetToggleChanged = function(toggleName, changedFunc)
		assert(ToggleStorage[toggleName] ~= nil, "Toggle '"..toggleName.."' does not exist.")
		ToggleStorage[toggleName]._changed = changedFunc
		changedFunc(Toggles.GetToggleValue(toggleName))
	end

	Toggles.GetToggleValue = function(toggleName)
		assert(ToggleStorage[toggleName] ~= nil, "Toggle '"..toggleName.."' does not exist.")
		return ToggleStorage[toggleName].Value
	end
	Toggles.SetToggleValue = function(toggleName, value)
		assert(ToggleStorage[toggleName] ~= nil, "Toggle '"..toggleName.."' does not exist.")

		ToggleStorage[toggleName].Value = value
		if ToggleStorage[toggleName].Temp == nil then
			_g.plugin:SetSetting("MoonAnimator2_Toggle_"..toggleName, value)
		end
		
		if _g.AllMenuItems and _g.AllMenuItems[toggleName] then
			_g.AllMenuItems[toggleName]:set_check(value)
		end
		if ToggleStorage[toggleName]._changed then
			ToggleStorage[toggleName]._changed(value)
		end
	end
	Toggles.FlipToggleValue = function(toggleName)
		Toggles.SetToggleValue(toggleName, not Toggles.GetToggleValue(toggleName))
	end
end

return Toggles

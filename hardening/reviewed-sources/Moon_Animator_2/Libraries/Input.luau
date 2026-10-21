local _g = _G.MoonGlobal
local Input = {}

------------------------------------------------------------
	Input.KeysDown = {}; local KeysDown = Input.KeysDown
	Input.Actions = {}; local Actions = Input.Actions

	Input.ctrl_hook = _g.BLANK_FUNC

	local Binds = {}

	local holdTimeSeconds = 0.25
------------------------------------------------------------
do
	function Input:ModifierHeld()
		return (Input:ControlHeld() or Input:ShiftHeld() or Input:AltHeld())
	end
	
	function Input:ControlHeld()
		return (KeysDown[Enum.KeyCode.LeftControl.Name] ~= nil or KeysDown[Enum.KeyCode.RightControl.Name] ~= nil)
	end

	function Input:ShiftHeld()
		return (KeysDown[Enum.KeyCode.LeftShift.Name] ~= nil or KeysDown[Enum.KeyCode.RightShift.Name] ~= nil)
	end

	function Input:AltHeld()
		return (KeysDown[Enum.KeyCode.LeftAlt.Name] ~= nil or KeysDown[Enum.KeyCode.RightAlt.Name] ~= nil)
	end
end
------------------------------------------------------------
do
	local replaceControlNames = {
		KeypadZero 	= "0",
		KeypadOne 	= "1",
		KeypadTwo 	= "2",
		KeypadThree = "3",
		KeypadFour 	= "4",
		KeypadFive 	= "5",
		KeypadSix 	= "6",
		KeypadSeven = "7",
		KeypadEight = "8",
		KeypadNine 	= "9",
		
		Zero 	= "0",
		One 	= "1",
		Two 	= "2",
		Three = "3",
		Four 	= "4",
		Five 	= "5",
		Six 	= "6",
		Seven = "7",
		Eight = "8",
		Nine 	= "9",
		
		KeypadDivide 	= "/",
		KeypadMinus 	= "-",
		KeypadMultiply 	= "*",
		KeypadPlus 		= '<font size="16">+</font>',
		
		KeypadEnter 	= "Enter",
		KeypadPeriod 	= ".",
		
		Slash = "/",
		BackSlash = "\\",
		Equals = "=",
		Minus = "-",
		Backquote = "`",
		Quote = "'",
	}

	Input.EncodeControl = function(input)
		local strKey = ""

		if (input.KeyCode.Name ~= "LeftAlt" and KeysDown[Enum.KeyCode.LeftAlt.Name]) or (input.KeyCode.Name ~= "RightAlt" and KeysDown[Enum.KeyCode.RightAlt.Name]) then
			strKey = "ALT_"
		end
		if (input.KeyCode.Name ~= "LeftShift" and KeysDown[Enum.KeyCode.LeftShift.Name]) or (input.KeyCode.Name ~= "RightShift" and KeysDown[Enum.KeyCode.RightShift.Name])  then
			strKey = strKey.."SHIFT_"
		end
		if (input.KeyCode.Name ~= "LeftControl" and KeysDown[Enum.KeyCode.LeftControl.Name]) or (input.KeyCode.Name ~= "RightControl" and KeysDown[Enum.KeyCode.RightControl.Name]) then
			strKey = strKey.."CTRL_"
		end
		strKey = strKey..input.KeyCode.Name

		return strKey
	end

	Input.PrettyFormat = function(keys)
		local strKey = ""

		if type(keys) == "string" then
			keys = {keys}
		end
		for i = 1, #keys do
			local getKey = keys[i]
			local replace = replaceControlNames[getKey]
			
			if strKey ~= "" then
				strKey = strKey.." / "
			end
			if string.find(getKey, "ALT_") then
				getKey = string.gsub(getKey, "ALT_", "")
				strKey = strKey..'Alt<font size="16">+</font>'
			end
			if string.find(getKey, "SHIFT_")  then
				getKey = string.gsub(getKey, "SHIFT_", "")
				strKey = strKey..'Shift<font size="16">+</font>'
			end
			if string.find(getKey, "CTRL_")  then
				getKey = string.gsub(getKey, "CTRL_", "")
				strKey = strKey..'Ctrl<font size="16">+</font>'
			end
			strKey = strKey..(replace and replace or getKey)
		end

		return strKey
	end
end
------------------------------------------------------------
do
	function Input:BindAction(Window, name, func, keys, disabled, release)
		assert(Actions[name] == nil, "Action '"..name.."' already exists.")

		Actions[name] = {
			name = name,
			Window = Window,
			func = func,
			keys = keys,
			defaultKeys = keys,
			disabled = disabled,
			release = release,
		}

		self:SetActionControls(name, Actions[name].defaultKeys)
		self:SetActionDisabled(name, disabled)
	end

	function Input:SetActionControls(name, keys)
		assert(Actions[name] ~= nil, "Action does not exist.")
		local action_data = Actions[name]

		for _, key in pairs(action_data.keys) do
			Binds[action_data.Window.name.."_"..key] = nil
		end
		action_data.keys = keys
		for _, key in pairs(action_data.keys) do
			Binds[action_data.Window.name.."_"..key] = Actions[name]
		end

		if _g.AllMenuItems[name] then
			_g.AllMenuItems[name]:_SetControl(keys)
		end
	end

	function Input:SetActionDisabled(name, value)
		assert(Actions[name] ~= nil, "Action '"..name.."' does not exist.")

		Actions[name].disabled = value
		if _g.AllMenuItems and _g.AllMenuItems[name] then
			_g.AllMenuItems[name]:_SetDisabled(value)
		end
	end

	function Input:DoAction(name, args)
		assert(Actions[name] ~= nil, "Action '"..name.."' does not exist.")

		local action = Actions[name]
		if not action.disabled and (action.Window == nil or (action.Window.Visible and action.Window.ChildModal == nil and action.Window.Focused)) then
			action.func(args)
		end
	end
end
------------------------------------------------------------
do
	Input.SimulateInput = function(keycode, began)
		local fake_input = {UserInputType = Enum.UserInputType.Keyboard, KeyCode = keycode}
		if began then
			InputBegan(fake_input)
		else
			InputEnded(fake_input)
		end
	end

	local MOD_KEYS = {LeftControl = true, RightControl = true, LeftShift = true, RightShift = true, LeftAlt = true, RightAlt = true}
	function Input:ClearInput()
		for ind, _ in pairs(self.KeysDown) do
			if not MOD_KEYS[ind] then
				Input.SimulateInput(Enum.KeyCode[ind], false)
			end
		end
	end
	
	function InputBegan(input, proc)
		local textbox = _g.input_serv:GetFocusedTextBox()
		if textbox then
			if (input.KeyCode == Enum.KeyCode.Return and proc) and (_g.CurrentWindowFocused == nil or (_g.CurrentWindowFocused and _g.CurrentWindowFocused.FocusedTextBox == nil)) then
				return
			end
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local code = input.KeyCode
			KeysDown[code.Name] = 0
			if code == Enum.KeyCode.LeftControl or code == Enum.KeyCode.RightControl then
				Input.ctrl_hook(true)
			end
			if _g.CurrentWindowFocused == nil or _g.GuiLib.drag_data.started or _g.ReleaseHandlesCon then 
				return
			end
			
			local GetBind = Binds[_g.CurrentWindowFocused.name.."_"..Input.EncodeControl(input)]
			if GetBind then
				Input:DoAction(GetBind.name)
			end
		end
	end
	_g.input_serv.InputBegan:Connect(InputBegan)
	
	function InputEnded(input, proc)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local code = input.KeyCode
			local was_held = KeysDown[code.Name] == -1
			KeysDown[code.Name] = nil
			if code == Enum.KeyCode.LeftControl or code == Enum.KeyCode.RightControl then
				Input.ctrl_hook(false)
			end
			if _g.CurrentWindowFocused == nil or _g.GuiLib.drag_data.started or _g.ReleaseHandlesCon then
				return
			end

			local GetBind = Binds[_g.CurrentWindowFocused.name.."_"..Input.EncodeControl(input).."*"]
			if GetBind and GetBind.release and was_held then
				GetBind.release()
			end
		end
	end
	_g.input_serv.InputEnded:Connect(InputEnded)
		
	function InputHeld(strKey)
		if _g.CurrentWindowFocused == nil or _g.GuiLib.drag_data.started or _g.ReleaseHandlesCon then
			return
		end

		local GetBind = Binds[_g.CurrentWindowFocused.name.."_"..strKey.."*"]
		if GetBind then
			Input:DoAction(GetBind.name)
		end
	end
	
	function InputClearKeys()
		KeysDown.LeftAlt = nil
		KeysDown.LeftShift = nil
		KeysDown.LeftControl = nil
	end
	_g.input_serv.WindowFocusReleased:Connect(InputClearKeys)
end
------------------------------------------------------------
do
	_g.run_serv.RenderStepped:Connect(function(step)
		for ind, val in pairs(Input.KeysDown) do
			if Input.KeysDown[ind] then

				if val + step > holdTimeSeconds then
					InputHeld(ind)
					Input.KeysDown[ind] = -1
				elseif Input.KeysDown[ind] >= 0 then
					Input.KeysDown[ind] = val + step
				end

			end
		end
	end)
end

return Input

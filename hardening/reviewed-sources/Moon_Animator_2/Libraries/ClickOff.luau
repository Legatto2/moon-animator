local _g = _G.MoonGlobal
local ClickOff = {}

------------------------------------------------------------
	ClickOff.CurrentGroup = nil
	local CurrentFunc = nil
	local CurrentUI = {}

	local _clicked
	local _clickedEvent = nil

	local WindowFocusCon
	local WindowFocusRelCon
------------------------------------------------------------
do
	function ClickOff._Off()
		assert(ClickOff.CurrentGroup ~= nil, "Clicked off nothing...")

		WindowFocusCon:Disconnect()
		WindowFocusCon = nil
		WindowFocusRelCon:Disconnect()
		WindowFocusRelCon = nil

		ClickOff.CurrentGroup = nil
		CurrentFunc()
		CurrentUI = {}

		_clickedEvent:Disconnect()
	end

	function ClickOff.CheckInBounds(posX, posY)
		local topMost = false
		for _, UI in pairs(CurrentUI) do
			if UI.Visible and posX >= UI.AbsolutePosition.X and posY >= UI.AbsolutePosition.Y then
				if posX <= UI.AbsolutePosition.X + UI.AbsoluteSize.X and posY <= UI.AbsolutePosition.Y + UI.AbsoluteSize.Y then
					topMost = UI
				end
			end
		end
		return topMost
	end

	function ClickOff.RegisterUI(UI, groupName, func)
		assert(UI ~= nil, "UI is nil.")
		if groupName == nil and ClickOff.CurrentGroup == nil then
			assert(false, "No ClickOff group name given.")
		end
		
		if groupName ~= nil and ClickOff.CurrentGroup ~= nil and ClickOff.CurrentGroup ~= groupName then
			ClickOff._Off()
		end

		if ClickOff.CurrentGroup == nil then
			ClickOff.CurrentGroup = groupName
			CurrentFunc = func

			WindowFocusCon = _g.input_serv.WindowFocused:Connect(function()
				ClickOff._Off()
			end)
			WindowFocusRelCon = _g.input_serv.WindowFocusReleased:Connect(function()
				ClickOff._Off()
			end)
		end
		table.insert(CurrentUI, UI)

		_clickedEvent = _g.input_serv.InputBegan:Connect(_clicked)
	end
end
------------------------------------------------------------
do
	_clicked = function(input, proc)
		if ClickOff.CurrentGroup ~= nil and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local inBounds = ClickOff.CheckInBounds(input.Position.X, input.Position.Y)

			if not inBounds then
				ClickOff._Off()
			end
		end
	end
end

return ClickOff

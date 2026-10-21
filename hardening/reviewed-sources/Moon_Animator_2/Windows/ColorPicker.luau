local _g = _G.MoonGlobal
------------------------------------------------------------
	local ColorInput
	local OldColor

	local WindowData = _g.WindowData:new("Color Picker", script.Contents)

	local Win  = _g.Window:new(script.Name, WindowData)

	local hsv = {}
	NumberInput:new(Win.g_e.H, 0, nil, {0, 359, 1, true}); hsv.H = Win.g_e.H
	NumberInput:new(Win.g_e.S, 255, nil, {0, 255, 1, true}); hsv.S = Win.g_e.S
	NumberInput:new(Win.g_e.V, 255, nil, {0, 255, 1, true}); hsv.V = Win.g_e.V

	local rgb = {}
	NumberInput:new(Win.g_e.R, 255, nil, {0, 255, 1, true}); rgb.R = Win.g_e.R
	NumberInput:new(Win.g_e.G, 0, nil, {0, 255, 1, true}); rgb.G = Win.g_e.G
	NumberInput:new(Win.g_e.B, 0, nil, {0, 255, 1, true}); rgb.B = Win.g_e.B

	local hex
	TextInput:new(Win.g_e.Hex, "ff0000", nil, 6); hex = Win.g_e.Hex

	Button:new(Win.g_e.Confirm)

	Win:AddPaintedItem(Win.Contents.Section.HueSatFrame, {BorderColor3 = "third"})
	Win:AddPaintedItem(Win.Contents.Section.ValueFrame, {BorderColor3 = "third"})
	Win:AddPaintedItem(Win.Contents.Section.ValueFrame.Slider, {BackgroundColor3 = "main"})
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		ColorInput = args.ColorInput
		OldColor = ColorInput.Value

		UpdateColor(OldColor)

		return true
	end
	
	Win.OnClose = function(save)
		if not save then
			ColorInput:Set(OldColor, true)
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end

	function UpdateColor(color, saveHSV)
		if color == nil then color = Color3.new(0, 0, 0) end

		rgb.R:Set(color.r * 255 + 0.5)
		rgb.G:Set(color.g * 255 + 0.5)
		rgb.B:Set(color.b * 255 + 0.5)

		local h, s, v = color:ToHSV()
		if not saveHSV then
			hsv.H:Set(h * 359 + 0.5)
			hsv.S:Set(s * 255 + 0.5)
			hsv.V:Set(v * 255 + 0.5)
		end
		
		Win.Contents.Section.HueSatFrame.Target.Position = UDim2.new(1 - hsv.H.Value / 359, 0, 1 - hsv.S.Value / 255, 0)
		Win.Contents.Section.HueSatFrame.HueSatImg.ImageTransparency = 1 - hsv.V.Value / 255
		Win.Contents.Section.ValueFrame.Slider.Position = UDim2.new(1, 1, 1, -1):Lerp(UDim2.new(1, 1, 0, 0), hsv.V.Value / 255)

		Win.Contents.Section.ColorFrame.BackgroundColor3 = color
		Win.Contents.Section.ValueFrame.ValueImg.ImageColor3 = Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, 1)

		hex:Set(string.format("%02x", rgb.R.Value)..string.format("%02x", rgb.G.Value)..string.format("%02x", rgb.B.Value))
		ColorInput:Set(color, true)
	end

	local iniValue
	function Win:ValueSliderDragBegin(ui)
		iniValue = hsv.V.Value
	end
	function Win:ValueSliderDragChanged(ui, changed)
		hsv.V:Set(math.clamp(iniValue - changed.Y, 0, 255))
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	_g.GuiLib:AddInput(Win.Contents.Section.ValueFrame.Slider, {
		drag = {
			caller_obj = Win, func_start = Win.ValueSliderDragBegin, func_changed = Win.ValueSliderDragChanged,
		},
	})
	
	function Win:ValueImgDragBegin(ui)
		iniValue = math.clamp(255 - math.floor(_g.Mouse.Y - Win.Contents.Section.ValueFrame.ValueImg.AbsolutePosition.Y), 0, 255)

		hsv.V:Set(iniValue)
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	function Win:ValueImgDragChanged(ui, changed)
		hsv.V:Set(math.clamp(iniValue - changed.Y, 0, 255))
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	_g.GuiLib:AddInput(Win.Contents.Section.ValueFrame.ValueImg, {
		down = {
			caller_obj = Win, func = Win.ValueImgDragBegin, 
		},
		drag = {
			caller_obj = Win, func_start = Win.ValueImgDragBegin, func_changed = Win.ValueImgDragChanged,
		},
	})

	local iniHue
	local iniSat
	function Win:HueSatDragBegin(ui)
		iniHue = math.clamp(359 - math.floor(_g.Mouse.X - Win.Contents.Section.HueSatFrame.HueSatImg.AbsolutePosition.X), 0, 359)
		iniSat = math.clamp(255 - math.floor(_g.Mouse.Y - Win.Contents.Section.HueSatFrame.HueSatImg.AbsolutePosition.Y), 0, 255)

		hsv.H:Set(iniHue)
		hsv.S:Set(iniSat)
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	function Win:HueSatDragChanged(ui, changed)
		hsv.H:Set(math.clamp(iniHue - changed.X, 0, 359))
		hsv.S:Set(math.clamp(iniSat - changed.Y, 0, 255))
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	_g.GuiLib:AddInput(Win.Contents.Section.HueSatFrame.HueSatImg, {
		down = {
			caller_obj = Win, func = Win.HueSatDragBegin, 
		},
		drag = {
			caller_obj = Win, func_start = Win.HueSatDragBegin, func_changed = Win.HueSatDragChanged,
		},
	})
	
	hsv.H._changed = function(value)
		UpdateColor(Color3.fromHSV(value / 359, hsv.S.Value / 255, hsv.V.Value / 255), true)
	end
	hsv.S._changed = function(value)
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, value / 255, hsv.V.Value / 255), true)
	end
	hsv.V._changed = function(value)
		UpdateColor(Color3.fromHSV(hsv.H.Value / 359, hsv.S.Value / 255, value / 255), true)
	end

	rgb.R._changed = function(value)
		UpdateColor(Color3.fromRGB(value, rgb.G.Value, rgb.B.Value))
	end
	rgb.G._changed = function(value)
		UpdateColor(Color3.fromRGB(rgb.R.Value, value, rgb.B.Value))
	end
	rgb.B._changed = function(value)
		UpdateColor(Color3.fromRGB(rgb.R.Value, rgb.G.Value, value))
	end

	hex._changed = function(value)
		local r, g, b = _g.hex2rgb(value)

		if r and g and b then
			UpdateColor(Color3.fromRGB(r, g, b))
		else
			UpdateColor(Color3.fromRGB(rgb.R.Value, rgb.G.Value, rgb.B.Value))
		end
	end
end

return Win

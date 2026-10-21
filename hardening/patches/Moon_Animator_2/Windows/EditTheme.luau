local _g = _G.MoonGlobal
------------------------------------------------------------
	local http = game:GetService("HttpService")
	local moon_bg
	local OldTheme
	
	local WindowData = _g.WindowData:new("Edit Theme", script.Contents)
	local Win  = _g.Window:new(script.Name, WindowData)
	
	Tabs:new(Win.g_e.Tabs, "Color")

	ListInput:new(Win.g_e.TargetColor, "main", nil, _g.Themer.ColorList)
	ColorInput:new(Win.g_e.Color, Color3.new(0, 0, 0), nil, Win)
	Button:new(Win.g_e.Export)
	TextInput:new(Win.g_e.Import, "", nil)

	TextInput:new(Win.g_e.ImageId, "", nil)
	ListInput:new(Win.g_e.BGScaling, "Crop", nil, {{"Crop", "Crop"}, {"Fit", "Fit"}, {"Stretch", "Stretch"}})
	ListInput:new(Win.g_e.Resize, "Default", nil, {{"Default", "Default"}, {"Pixelated", "Pixelated"}})
	Win.g_e.Opacity   = NumberInput:new(Win.g_e.Opacity, 1, nil, {0, 1, 0.05})

	Button:new(Win.g_e.Save)
------------------------------------------------------------
do
	ImageId._changed = function(value)
		if tonumber(value) then
			ImageId:Set("rbxassetid://"..value)
		end
		moon_bg.Image = ImageId.Value
	end
	BGScaling._changed = function(value)
		moon_bg.ScaleType = Enum.ScaleType[value]
	end
	Resize._changed = function(value)
		moon_bg.ResampleMode = Enum.ResamplerMode[value]
	end
	Opacity._changed = function(value)
		moon_bg.ImageTransparency = 1 - value
	end

	function EncodeTheme()
		local builtTheme = {}

		for colorName, color in pairs(_g.Themer._Theme) do
			if string.sub(colorName, 1, 1) == "_" then
			else
				builtTheme[colorName] = {math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5)}
			end
		end

		if moon_bg.Image ~= "" then
			builtTheme._bgOuter = {moon_bg.Image, moon_bg.ScaleType.Name, 1 - moon_bg.ImageTransparency, moon_bg.ResampleMode.Name}
		end

		return builtTheme
	end

	Win.OnOpen = function()
		moon_bg = _g.Windows.MoonAnimator.GetBackground()
		
		TargetColor:Set("main", true)
		Import:Set("")
		ImageId:Set(moon_bg.Image)
		BGScaling:Set(moon_bg.ScaleType.Name)
		Resize:Set(moon_bg.ResampleMode.Name)

		OldTheme = EncodeTheme()
		
		return true
	end

	Win.OnClose = function(save)
		if save then
			local NewTheme = EncodeTheme()
			_g.Themer:SetTheme(NewTheme)
			_g.plugin:SetSetting(_g.theme_key, NewTheme)
		else
			_g.Themer:SetTheme(OldTheme)
		end

		return true
	end

	TargetColor._changed = function(value)
		Color:Set(_g.Themer._Theme[value])
	end

	Color._changed = function(value)
		_g.Themer._Theme[TargetColor.Value] = value
		_g.Themer:_paintAll(true)
	end

	Import._changed = function(value)
		local json = nil
		local succ, err = pcall(function() json = http:JSONDecode(value) end)

		if type(json) ~= "table" then
			Import:Set("failed...")
		else
			local applied, themeError = _g.Themer:SetTheme(json)
			if not applied then
				Import:Set(themeError or "invalid theme")
				return
			end

			Color:Set(_g.Themer._Theme[TargetColor.Value])

			Import:Set("theme applied")
		end
	end

	Win.g_e.Export.OnClick = function()
		print(http:JSONEncode(EncodeTheme()))
		Import:Set("theme outputted")
	end

	Win.g_e.Save.OnClick = function()
		Win:Close(true)
	end
end

return Win

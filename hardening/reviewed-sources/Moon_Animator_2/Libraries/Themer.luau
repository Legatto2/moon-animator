local _g = _G.MoonGlobal
local Themer = {}

------------------------------------------------------------
	local tween = game:GetService("TweenService")

	Themer._PaintMap = {}
	Themer._PaintedItemMap  = {}

	Themer._BuiltInThemes = {
		Default 	= {main = {246,142,31},  second = {172,99,21},   third = {123,71,15},  highlight = {52,144,174}, bg = {18,22,28}, text = {245,245,245}, _bgOuter = {"","Crop",1,"Default"}},
		Dark 	   	= {main = {178,187,193}, second = {108,113,117}, third = {70,74,76},   highlight = {174,102,66}, bg = {33,33,33}, text = {240,240,240}},
		Lunar 		= {main = {52,161,218},  second = {52,144,174},  third = {33,76,111},  highlight = {174,115,52}, bg = {18,22,61}, text = {245,245,245}, _bgOuter = {"rbxassetid://11869805803","Fit",1,"Pixelated"}},
		Subspace	= {main = {193,135,255}, second = {115,44,191},  third = {76,30,127},  highlight = {159,160,0},  bg = {12,0,36},  text = {225,219,244}},

		-- Optional palettes from catppuccin/moon-animator-2, commit
		-- 7541ad7e017c3447cf53f0c4b79ee2963fe7528b (MIT).
		-- License: optional-themes/catppuccin/LICENSE. Default remains unchanged.
		["Catppuccin Latte"] = {main = {124,127,147}, second = {156,160,176}, third = {140,143,161}, highlight = {30,102,245}, bg = {239,241,245}, text = {76,79,105}},
		["Catppuccin Frappe"] = {main = {148,156,187}, second = {115,121,148}, third = {131,139,167}, highlight = {140,170,238}, bg = {48,52,70}, text = {198,208,245}},
		["Catppuccin Macchiato"] = {main = {147,154,183}, second = {110,115,141}, third = {128,135,162}, highlight = {138,173,244}, bg = {36,39,58}, text = {202,211,245}},
		["Catppuccin Mocha"] = {main = {147,153,178}, second = {108,112,134}, third = {127,132,156}, highlight = {137,180,250}, bg = {30,30,46}, text = {205,214,244}},
	
		Taiga 	    = {main = {139,199,194}, second = {20,118,109},  third = {0,72,67},    highlight = {107,68,35},  bg = {0,19,15},  text = {232,247,250}},
		Blush 	    = {main = {255,122,146}, second = {169,80,95},   third = {118,56,66},  highlight = {213,36,107}, bg = {28,18,21}, text = {252,235,241}},
		Blonde 	    = {main = {255,144,95},  second = {184,103,68},  third = {127,72,47},  highlight = {29,109,157}, bg = {28,22,18}, text = {255,241,235}},	
		Wheat 	    = {main = {255,194,95},  second = {184,139,68},  third = {127,96,47},  highlight = {98,143,64},  bg = {28,24,18}, text = {255,247,235}},
		Gaia  		= {main = {128,184,129}, second = {62,111,63},   third = {29,77,30},   highlight = {0,131,139},  bg = {26,21,17}, text = {209,229,210}},
		Ares 	    = {main = {196,78,78},   second = {161,54,54},   third = {102,34,34},  highlight = {200,143,0},  bg = {28,18,18}, text = {227,226,225}},
		Aqua  = {main = {128,168,184}, second = {62,96,111},   third = {29,61,77},   highlight = {0,150,123},  bg = {18,19,28}, text = {209,226,229}},
		Energy 	    = {main = {227,227,0},   second = {191,169,0},   third = {127,113,0},  highlight = {27,170,0},   bg = {37,37,37}, text = {246,245,230}},
		Digital     = {main = {88,204,88},   second = {49,146,49},   third = {31,93,31},   highlight = {170,130,0},  bg = {32,32,32}, text = {218,243,218}},
		Fuchsia 	= {main = {255,135,251}, second = {191,44,187},  third = {127,30,124}, highlight = {0,124,127},  bg = {36,0,35},  text = {244,219,243}},
	}

	Themer.ThemeList = {
		"Taiga", "Blush", "Blonde", "Wheat", "Gaia", "Ares", "Aqua", "Energy", "Digital", "Fuchsia",
		"~",
		"Default", "Dark", "Lunar", "Subspace",
		"Catppuccin Latte", "Catppuccin Frappe", "Catppuccin Macchiato", "Catppuccin Mocha",
	}

	Themer.ColorList = {{"main", "main"}, {"second", "second"}, {"third", "third"}, {"highlight", "highlight"}, {"bg", "bg"}, {"text", "text"}}

	Themer._Theme = {}
	for paintName, paint in pairs(Themer._BuiltInThemes.Default) do
		if string.sub(paintName, 1, 1) == "_" then
			Themer._Theme[paintName] = {paint[1], paint[2], paint[3], paint[4]}
		else
			Themer._Theme[paintName] = Color3.fromRGB(paint[1], paint[2], paint[3])
		end
	end

	Themer._TweenMap = {}
	Themer.QUICK_TWEEN = 0.06

	Themer.theme_changed = {}
------------------------------------------------------------
do
	function Themer:QuickTween(obj, tweenTime, propMap, slow_start)
		local getId = obj:GetDebugId(8)
		
		if obj:IsDescendantOf(game) and tweenTime and tweenTime > 0 then
			self._TweenMap[getId] = {tween:Create(obj, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, slow_start == nil and Enum.EasingDirection.Out or Enum.EasingDirection.In), propMap), propMap}
			self._TweenMap[getId][1]:Play()
		else
			if self._TweenMap[getId] and self._TweenMap[getId][1].PlaybackState == Enum.PlaybackState.Playing then
				self._TweenMap[getId][1]:Cancel()
			end
			for prop, val in pairs(propMap) do
				obj[prop] = val
			end
		end
	end

	local uiGetT = {
		Frame = function(...) end,
		TextBox = function(map, ui, givenValue)
			map["TextTransparency"] = givenValue and givenValue or ui.TextTransparency
			map["TextStrokeTransparency"] = givenValue and givenValue or ui.TextStrokeTransparency
		end,
		ImageButton = function(map, ui, givenValue)
			map["ImageTransparency"] = givenValue and givenValue or ui.ImageTransparency
		end,
		SelectionBox = function(map, ui, givenValue)
			map["SurfaceTransparency"] = givenValue and givenValue or ui.SurfaceTransparency
		end,
		ScrollingFrame = function(map, ui, givenValue)
			map["ScrollBarImageTransparency"] = givenValue and givenValue or ui.ScrollBarImageTransparency
		end,
	}
	uiGetT.TextButton = uiGetT.TextBox
	uiGetT.TextLabel = uiGetT.TextBox
	uiGetT.ImageLabel = uiGetT.ImageButton
	uiGetT.ViewportFrame = uiGetT.ImageButton
	uiGetT.SelectionSphere = uiGetT.SelectionBox

	function Themer.GetTransparencyPropertyMap(ui, givenValue)
		local map = {BackgroundTransparency = givenValue and givenValue or ui.BackgroundTransparency}
		uiGetT[ui.ClassName](map, ui, givenValue)
		return map
	end

	local uiSetT = {
		Frame = function(...) end,
		TextBox = function(ui, value)
			ui.TextTransparency = value
			ui.TextStrokeTransparency = value
		end,
		ImageButton = function(ui, value)
			ui.ImageTransparency = value
		end,
		SelectionBox = function(ui, value)
			ui.SurfaceTransparency = value
		end,
		ScrollingFrame = function(ui, value)
			ui.ScrollBarImageTransparency = value
		end,
	}
	uiSetT.TextButton = uiSetT.TextBox
	uiSetT.TextLabel = uiSetT.TextBox
	uiSetT.ImageLabel = uiSetT.ImageButton
	uiSetT.ViewportFrame = uiSetT.ImageButton
	uiSetT.SelectionSphere = uiSetT.SelectionBox

	function Themer.SetUITransparency(ui, value)
		ui.BackgroundTransparency = value
		uiSetT[ui.ClassName](ui, value)
	end
end
------------------------------------------------------------
do
	function Themer:_paint(obj, paintData, tweenTime)
		if tweenTime == 0 then
			tweenTime = nil
		end
		for prop, paintName in pairs(paintData) do
			self:QuickTween(obj, tweenTime, {[prop] = self._Theme[paintName]})
		end
	end

	function Themer:AddPaintedItem(obj, paintData)
		local getId = obj:GetDebugId(8)
		assert(self._PaintMap[getId] == nil, "Object already exists in the Themer system.")

		self._PaintMap[getId] = paintData
		self._PaintedItemMap[getId]  = obj
		self:_paint(obj, paintData)
	end
	function Themer:RemovePaintedItem(obj)
		local getId = obj:GetDebugId(8)
		assert(self._PaintMap[getId] ~= nil, "Object does not exist in the Themer system.")

		if self._TweenMap[getId] then
			self._TweenMap[getId][1]:Cancel()
			for prop, val in pairs(self._TweenMap[getId][2]) do
				obj[prop] = val
			end
			self._TweenMap[getId] = nil
		end
		self._PaintMap[getId] = nil
		self._PaintedItemMap[getId]  = nil
	end

	function Themer:SetItemPaint(obj, newPaintData, tweenTime)
		local getId = obj:GetDebugId(8)
		assert(self._PaintMap[getId] ~= nil, "Object does not exist in the Themer system.")

		local getItemPaintData = self._PaintMap[getId]
		for prop, paintName in pairs(newPaintData) do
			if getItemPaintData[prop] then
				getItemPaintData[prop] = paintName
			end
		end
		self:_paint(obj, getItemPaintData, tweenTime)
	end
end
------------------------------------------------------------
do
	local backgroundScaleTypes = {Stretch = true, Slice = true, Tile = true, Fit = true, Crop = true}
	local backgroundResamplerModes = {Default = true, Pixelated = true}

	local function isNumberInRange(value, minimum, maximum)
		-- These comparisons also reject NaN and infinities.
		return type(value) == "number" and value >= minimum and value <= maximum
	end

	local function isArray(value, maximumLength)
		if type(value) ~= "table" then return false end
		for index in pairs(value) do
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > maximumLength then
				return false
			end
		end
		return true
	end

	function Themer:_paintAll(noTween)
		for itemId, paintData in pairs(self._PaintMap) do
			self:_paint(self._PaintedItemMap[itemId],  paintData, noTween and 0 or 0.4)
		end
	end

	function Themer:SetTheme(newTheme)
		if newTheme == nil then
			newTheme = _g.Themer._BuiltInThemes.Default
		elseif type(newTheme) == "string" then
			newTheme = _g.Themer._BuiltInThemes[newTheme]
			if newTheme == nil then return false, "Unknown built-in theme." end
		end
		if type(newTheme) ~= "table" then return false, "Theme must be a table." end
		
		local no_tween = newTheme == _g.Themer._BuiltInThemes.Default or newTheme == _g.Themer._BuiltInThemes.Dark or newTheme == _g.Themer._BuiltInThemes.Lunar or newTheme == _g.Themer._BuiltInThemes.Subspace

		-- Stage every value before changing colors or notifying the UI. A malformed
		-- import must not leave the current theme partially changed.
		local pendingTheme = {}
		for paintName, paint in pairs(newTheme) do
			if paintName == "locked" then paintName = "highlight" end
			if type(paintName) ~= "string" or self._BuiltInThemes.Default[paintName] == nil then
				return false, "Unknown theme field."
			end
			if paintName == "_bgOuter" then
				if not isArray(paint, 4) or type(paint[1]) ~= "string"
					or type(paint[2]) ~= "string" or not backgroundScaleTypes[paint[2]]
					or not isNumberInRange(paint[3], 0, 1)
					or (paint[4] ~= nil and (type(paint[4]) ~= "string" or not backgroundResamplerModes[paint[4]])) then
					return false, "Invalid background settings."
				end
				pendingTheme[paintName] = {paint[1], paint[2], paint[3], paint[4]}
			else
				if not isArray(paint, 3) or not isNumberInRange(paint[1], 0, 255)
					or not isNumberInRange(paint[2], 0, 255) or not isNumberInRange(paint[3], 0, 255) then
					return false, "Invalid RGB color: " .. paintName .. "."
				end
				pendingTheme[paintName] = Color3.fromRGB(paint[1], paint[2], paint[3])
			end
		end
		if next(pendingTheme) == nil then return false, "Theme has no colors or background." end

		_g.Mouse.Icon = ""
		for paintName, paint in pairs(pendingTheme) do
			self._Theme[paintName] = paint
		end
		self:_paintAll(no_tween)
		for _, f in pairs(self.theme_changed) do
			f(newTheme, no_tween)
		end
		return true
	end
	
end

return Themer

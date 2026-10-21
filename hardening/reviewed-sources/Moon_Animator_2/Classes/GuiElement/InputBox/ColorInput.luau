local _g = _G.MoonGlobal; _g.req("InputBox")
local ColorInput = super:new()

function ColorInput:new(UI, default, changed, Window)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		UI.Frame.Input.Text = ColorInput.Process(ctor, default)
		
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() ColorInput.Set(ctor, UI.Frame.Input.Text, true) end
		}})
		_g.GuiLib:AddInput(UI.ColorDisplay, {click = {func = function()
			Window:OpenModal(_g.Windows.ColorPicker, {ColorInput = ctor})
		end}})
	end

	return ctor
end

function ColorInput:Process(input)
	if input == nil then
		self.Value = nil
		self.UI.ColorDisplay.BackgroundColor3 = Color3.new(0, 0, 0)
		return "-"
	end

	if typeof(input) == "Color3" then
		self.Value = input
		self.UI.ColorDisplay.BackgroundColor3 = self.Value
	else
		local r, g, b = _g.hex2rgb(input)
		if r and g and b then
			self.Value = Color3.fromRGB(r, g, b)
			self.UI.ColorDisplay.BackgroundColor3 = self.Value
		else
			local vals = _g.csvToNumberTable(input)
			local r, g, b = vals[1], vals[2], vals[3]
			if r and g and b then
				r, g, b = math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)
				self.Value = Color3.fromRGB(r, g, b)
				self.UI.ColorDisplay.BackgroundColor3 = self.Value
			else
				self.UI.ColorDisplay.BackgroundColor3 = self.Value
			end
		end
	end

	return math.floor(self.Value.r * 255)..", "..math.floor(self.Value.g * 255)..", "..math.floor(self.Value.b * 255)
end

return ColorInput

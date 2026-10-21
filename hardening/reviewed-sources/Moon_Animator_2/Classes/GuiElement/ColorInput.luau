local _g = _G.MoonGlobal; _g.req("GuiElement")
local ColorInput = super:new()

function ColorInput:new(UI, default, changed)
	local ctor = super:new(UI and UI or nil)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed

		ctor.Value = default

		UI.ColorDisplay.BackgroundColor3 = default ~= nil and default or Color3.new(0, 0, 0)
		UI.Frame.Input.Text = default ~= nil and math.floor(default.r * 255)..", "..math.floor(default.g * 255)..", "..math.floor(default.b * 255) or "< varied >"

		UI.Frame.Input.FocusLost:connect(function() ColorInput.SetColor(ctor, UI.Frame.Input.Text, true) end)
	end

	return ctor
end

function hex2rgb(hex)
	if #hex < 6 then return end
	
	hex = hex:gsub("#","")
	return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end
function str2rgb(str)
	str = str:gsub("%s+", "")
	local vals = {}
	local get,_ = string.find(str, ",")

	while #str > 0 and get do
		local getNum = tonumber(string.sub(str, 1, get - 1))
			if getNum == nil then return nil end
			if getNum > 255 then getNum = 255 end
			if getNum < 0 then getNum = 0 end
			
		table.insert(vals, getNum)
		str = string.sub(str, get + 1)
		get = string.find(str, ",")
		if get == nil then
			get = #str + 1
		end
	end

	return vals[1], vals[2], vals[3]
end

function ColorInput:SetColor(text, clicked)
	if text == nil then
		self.Value = nil
		self.UI.ColorDisplay.BackgroundColor3 = Color3.new(0, 0, 0)
		self.UI.Frame.Input.Text = "< varied >"
		return
	end

	local r, g, b = hex2rgb(text)
	if r and g and b then
		self.Value = Color3.fromRGB(r, g, b)
		self.UI.ColorDisplay.BackgroundColor3 = self.Value
	else
		r, g, b = str2rgb(text)
		if r and g and b then
			self.Value = Color3.fromRGB(r, g, b)
			self.UI.ColorDisplay.BackgroundColor3 = self.Value
		else
			self.UI.ColorDisplay.BackgroundColor3 = self.Value
		end
	end
	self.UI.Frame.Input.Text = math.floor(self.Value.r * 255)..", "..math.floor(self.Value.g * 255)..", "..math.floor(self.Value.b * 255)

	if clicked and self._changed then
		self._changed(value)
	end
end

return ColorInput

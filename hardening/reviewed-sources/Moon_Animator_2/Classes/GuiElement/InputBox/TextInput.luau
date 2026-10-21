local _g = _G.MoonGlobal; _g.req("InputBox")
local TextInput = super:new()

function TextInput:new(UI, default, changed, MaxLength)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		if MaxLength == nil then
			ctor.MaxLength = math.huge
		else
			ctor.MaxLength = MaxLength
		end
		ctor.TrimWhitespace = false

		UI.Frame.Input.Text = TextInput.Process(ctor, default)
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() TextInput.Set(ctor, UI.Frame.Input.Text, true) end
		}})
	end

	return ctor
end

function TextInput:Process(input)
	if input == nil then
		self.Value = nil
		return "-"
	end

	input = tostring(input)
	self.Value = #input <= self.MaxLength and input or string.sub(input, 1, self.MaxLength)
	if self.TrimWhitespace then
		self.Value = self.Value:gsub("^%s*(.-)%s*$", "%1")
	end
	return self.Value
end

return TextInput

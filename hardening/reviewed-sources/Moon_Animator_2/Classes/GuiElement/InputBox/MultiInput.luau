local _g = _G.MoonGlobal; _g.req("InputBox")
local MultiInput = super:new()

function MultiInput:new(UI, default, changed)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		UI.Frame.Input.Text = MultiInput.Process(ctor, default)
		UI.Frame.Input.FocusLost:Connect(function() MultiInput.Set(ctor, UI.Frame.Input.Text, true) end)
	end

	return ctor
end

function MultiInput:Process(input)
	if input == nil then
		self.Value = nil
		return "-"
	end

	self.Value = tostring(input)
	self.Value = self.Value:gsub("^%s*(.-)%s*$", "%1")
	return self.Value
end

return MultiInput

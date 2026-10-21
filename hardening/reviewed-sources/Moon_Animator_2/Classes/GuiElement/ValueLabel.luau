local _g = _G.MoonGlobal; _g.req("GuiElement")
local ValueLabel = super:new()

function ValueLabel:new(UI, default, noNil)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.noNil = noNil
		ctor.Value = nil
		
		ValueLabel.Set(ctor, default)

		ctor:AddPaintedItem(UI, {TextColor3 = "main"})
		ctor:AddPaintedItem(UI.Label, {TextColor3 = "main"})
	end

	return ctor
end

function ValueLabel:Set(value)
	if type(value) == "table" then
		self.UI.Label.Text = "< varied >"
	else
		self.UI.Label.Text = value ~= nil and tostring(value) or (self.noNil and "< varied >" or "< none >")
	end
	self.UI.Label.Size = UDim2.new(0, 15*#self.UI.Label.Text, 1, 0)

	self.Value = value
end

return ValueLabel

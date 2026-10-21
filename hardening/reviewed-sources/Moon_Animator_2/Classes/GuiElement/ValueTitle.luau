local _g = _G.MoonGlobal; _g.req("GuiElement")
local ValueTitle = super:new()

function ValueTitle:new(UI, default)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.Value = nil
		
		ValueTitle.Set(ctor, default)

		ctor:AddPaintedItem(UI.Decor, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Label, {TextColor3 = "main"})
		ctor:AddPaintedItem(UI.ValueLabel, {TextColor3 = "main"})
	end

	return ctor
end

function ValueTitle:Set(value)
	self.UI.ValueLabel.Text = value == nil and "< varied >" or tostring(value)
	self.Value = value
end

return ValueTitle

local _g = _G.MoonGlobal; _g.req("Object")
local GuiElement = super:new()

function GuiElement:new(UI)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.UI = UI
		
		getfenv(0)[UI.Name] = ctor
		getfenv(0).Win.g_e[UI.Name] = ctor
	end

	return ctor
end

return GuiElement

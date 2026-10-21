local _g = _G.MoonGlobal; _g.req("Object")
local WindowData = super:new()

function WindowData:new(title, Contents)
	local ctor = super:new(title)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if title then
		ctor.title = title
		ctor.img = nil
		ctor.Buttons = {SmallClose = nil, Close = true, Hide = nil, Max = nil}
		ctor.Contents = Contents
		ctor.MenuBar = nil
		ctor.IsPalette = false
		ctor.NeedsMouse = false
	end

	return ctor
end

return WindowData

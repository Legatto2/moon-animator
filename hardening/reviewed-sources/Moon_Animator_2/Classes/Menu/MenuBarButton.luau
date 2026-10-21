local _g = _G.MoonGlobal; _g.req("Object")
local MenuBarButton = super:new(); local t_s = game:GetService("TextService")

function MenuBarButton:new(name, MenuBar, ButtonLabel)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		assert(MenuBar ~= nil, "Target MenuBar is nil.")

		ctor.name = name
		ctor.MenuBar = MenuBar
		ctor.UI = _g.new_ui.MenuBar.MainButton:Clone()
		ctor.main_color = name:sub(1,2) ~= "h_" and "main" or "highlight"
		
		ctor.UI.Label.Text = ButtonLabel
		local font_size = _g.GetTextSize(ctor.UI.Label)
		ctor.UI.Size = UDim2.new(0, font_size + 15, 1, -2)

		MenuBar:_AddButton(ctor)

		_g.GuiLib:AddInput(ctor.UI, {hover = {caller_obj = ctor, func_start = MenuBarButton._HoverBegan, func_ended = MenuBarButton._HoverEnded}})

		ctor:AddPaintedItem(ctor.UI.Label, {TextColor3 = ctor.main_color})
		ctor:AddPaintedItem(ctor.UI.Hover, {BackgroundColor3 = ctor.main_color})
		ctor:AddPaintedItem(ctor.UI.Hover.UIStroke, {Color = ctor.main_color})
	end

	return ctor
end

function MenuBarButton:Destroy()
	super.Destroy(self)
end

function MenuBarButton:_HoverBegan(UI)
	if not self.MenuBar.Enabled then return end

	self.UI.Hover.Visible = true

	if self.MenuBar.ActiveMenuBarButton ~= nil and self.MenuBar.ActiveMenuBarButton ~= self then
		_g.ClickOff._Off()
		self.MenuBar:_Open(self)
	end
end

function MenuBarButton:_HoverEnded(UI)
	if self.MenuBar.ActiveMenuBarButton == self then self:_HoverBegan() return end
	
	self.UI.Hover.Visible = false
end

return MenuBarButton

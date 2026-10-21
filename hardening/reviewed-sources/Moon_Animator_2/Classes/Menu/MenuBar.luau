local _g = _G.MoonGlobal; _g.req("Object", "ObjectGroup", "MenuBarButton", "Menu", "MenuItem")
local MenuBar = super:new()

function MenuBar:new(name)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		ctor._MenuBarButtons = ObjectGroup:new("_MenuBarButtons: "..tostring(ctor))
		ctor._curOrder = 0
		ctor.name = name
		ctor.Window = nil
		ctor.UI = _g.new_ui.MenuBar.MenuBar:Clone()
		ctor.ActiveMenuBarButton = nil
		ctor.Enabled = true
		
		ctor:AddPaintedItem(ctor.UI, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.UI.BG, {BackgroundColor3 = "bg"})
	end

	return ctor
end

function MenuBar.MenuBarFactory(name, data)
	local mb = MenuBar:new(name)

	while (#data > 0) do
		local button = table.remove(data, 1)
		MenuBarButton:new(button[1], mb, button[2])
	end

	local function ScanMenus(tbl)
		for menuName, menuItems in pairs(tbl) do
			local newMenu = Menu:new(menuName)

			while (#menuItems > 0) do
				local item = table.remove(menuItems, 1)
				if item == "~" then
					newMenu:AddDivider()
				else
					MenuItem:new(item[1], newMenu, item[2], item.extra)
				end
			end

			ScanMenus(menuItems)
		end
	end
	ScanMenus(data)

	return mb
end

function MenuBar:Destroy()
	super.Destroy(self)
end

function MenuBar:_MenuBarButtonClick(MenuBarButton)
	if _g.AllMenus and _g.AllMenus[MenuBarButton.name] then
		if self.ActiveMenuBarButton == MenuBarButton then
			local save = self.ActiveMenuBarButton
			_g.ClickOff._Off()
			save:_HoverBegan(save.UI)
		else
			self:_Open(MenuBarButton)
		end
	end
end

function MenuBar:_AddButton(MenuBarButton)
	self._curOrder = self._curOrder + 1

	self._MenuBarButtons:Add(MenuBarButton)
	MenuBarButton.UI.LayoutOrder = self._curOrder
	MenuBarButton.UI.Parent = self.UI.Buttons

	_g.GuiLib:AddInput(MenuBarButton.UI, {down = {func = function() MenuBar._MenuBarButtonClick(self, MenuBarButton) end}})
end

function MenuBar:_Open(MenuBarButton)
	if not self.Enabled then self:Close() return end
	if _g.AllMenus == nil or _g.AllMenus[MenuBarButton.name] == nil then return end

	if self.ActiveMenuBarButton then
		_g.ClickOff._Off()
	end
	self.ActiveMenuBarButton = MenuBarButton

	local TargetMenu = _g.AllMenus[MenuBarButton.name]
	local closeFunc = function()
		local save = self.ActiveMenuBarButton
		TargetMenu:Close()
		self.ActiveMenuBarButton = nil
		save:_HoverEnded(save.UI)
	end

	_g.ClickOff.RegisterUI(MenuBarButton.UI, tostring(self), closeFunc)
	TargetMenu:size(self.Window.Contents.Parent.Parent)
	
	local xPos = MenuBarButton.UI.AbsolutePosition.X
		if xPos + TargetMenu.UI.Size.X.Offset + 1 > workspace.CurrentCamera.ViewportSize.X then
			xPos = xPos - ((xPos + TargetMenu.UI.Size.X.Offset + 1) - workspace.CurrentCamera.ViewportSize.X)
		elseif xPos <= 0 then
			xPos = 1
		end
	local yPos = MenuBarButton.UI.AbsolutePosition.Y + self.UI.Size.Y.Offset - 4
		if yPos + TargetMenu.UI.Size.Y.Offset + 1 > workspace.CurrentCamera.ViewportSize.Y then
			yPos = MenuBarButton.UI.AbsolutePosition.Y - TargetMenu.UI.Size.Y.Offset - 1
		end
	
	TargetMenu:Show(Vector2.new(xPos, yPos), self.Window.Contents.Parent.Parent)
end

function MenuBar:Close()
	if self.ActiveMenuBarButton then
		_g.ClickOff._Off()
	end
end

function MenuBar:SetEnabled(value, noTween)
	local tween_time = noTween and 0 or _g.Themer.QUICK_TWEEN
	
	self.Enabled = value
	self:SetItemPaint(self.UI, {BackgroundColor3 = value and "second" or "third"}, tween_time)

	if not value then
		self:Close()
	end
	self._MenuBarButtons:Iterate(function(MenuBarButton)
		MenuBarButton:_HoverEnded()
		MenuBarButton:SetItemPaint(MenuBarButton.UI.Label, value and {TextColor3 = MenuBarButton.main_color} or {TextColor3 = "third"}, tween_time)
	end)
end

return MenuBar

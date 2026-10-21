local _g = _G.MoonGlobal; _g.req("Object", "ObjectGroup")
local Menu = super:new(); local tween = game:GetService("TweenService")

_g.AllMenus = {}

function Menu:new(name)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		ctor._MenuItems = ObjectGroup:new("_MenuItems: "..tostring(ctor))
		ctor._curOrder = 0
		ctor.name = name
		ctor.UI = _g.new_ui.Menu.Menu:Clone()
		ctor.ActiveMenuItem = nil

		ctor.UI.Visible = true

		if _g.AllMenuItems and _g.AllMenuItems[name] then
			_g.AllMenuItems[name]:_AddMoreFrame()
		end

		ctor:AddPaintedItem(ctor.UI.Folder.BG, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(ctor.UI.Folder.BG.UIStroke, {Color = "main"})
		
		_g.AllMenus[name] = ctor
	end

	return ctor
end

function Menu:Destroy()
	_g.AllMenus[self.name] = nil
	super.Destroy(self)
end

function Menu:_MenuItemClick(MenuItem)
	if MenuItem.Disabled then return end
	
	if _g.AllMenus and _g.AllMenus[MenuItem.name] then
		local TargetMenu = _g.AllMenus[MenuItem.name]

		if self.ActiveMenuItem == MenuItem then
			TargetMenu:Close()
			self.ActiveMenuItem = nil
		else
			if self.ActiveMenuItem then
				local save = self.ActiveMenuItem
				_g.AllMenus[save.name]:Close()
				self.ActiveMenuItem = nil
				save:_HoverEnded(save.UI)
			end
			self.ActiveMenuItem = MenuItem
			
			TargetMenu:size(self.UI.Parent)
			
			local abs_pos = MenuItem.middle_ui.AbsolutePosition
			local abs_size =  MenuItem.middle_ui.AbsoluteSize
			local target_size = TargetMenu.UI.AbsoluteSize
			
			local xPos = abs_pos.X + abs_size.X + 4
			if xPos + target_size.X + 1 > workspace.CurrentCamera.ViewportSize.X then
				xPos = abs_pos.X - target_size.X - 4
			end
			local yPos = abs_pos.Y - 8
			if yPos + target_size.Y + 1 > workspace.CurrentCamera.ViewportSize.Y then
				yPos = abs_pos.Y - target_size.Y + 2 + 20
			end
			
			TargetMenu:Show(Vector2.new(xPos, yPos), self.UI.Parent)
		end
	elseif MenuItem.check_frame then
		if not MenuItem.NoClickOff then
			_g.ClickOff._Off()
			MenuItem:_HoverEnded(MenuItem.UI)
		end

		_g.Toggles.FlipToggleValue(MenuItem.name)
		MenuItem:set_check(_g.Toggles.GetToggleValue(MenuItem.name))
	else
		if _g.Input and _g.Input.Actions and _g.Input.Actions[MenuItem.name] then
			if not MenuItem.NoClickOff then
				_g.ClickOff._Off()
				MenuItem:_HoverEnded(MenuItem.UI)
			end
			
			_g.Input:DoAction(MenuItem.name)
		end
	end
end

function Menu:_AddMenuItem(MenuItem)
	self._curOrder = self._curOrder + 1

	self._MenuItems:Add(MenuItem)
	
	MenuItem.left_ui.LayoutOrder = self._curOrder
	MenuItem.left_ui.Parent = self.UI.Left
	
	MenuItem.middle_ui.LayoutOrder = self._curOrder
	MenuItem.middle_ui.Parent = self.UI.Folder.Middle
	
	MenuItem.right_ui.LayoutOrder = self._curOrder
	MenuItem.right_ui.Parent = self.UI.Right

	_g.GuiLib:AddInput(MenuItem.middle_ui.Input, {click = {func = function() Menu._MenuItemClick(self, MenuItem) end}})
end

function Menu:AddDivider()
	self._curOrder = self._curOrder + 1

	local newDiv = _g.new_ui.Menu.Divider:Clone()
	newDiv.LayoutOrder = self._curOrder
	newDiv.Parent = self.UI.Right
	newDiv:Clone().Parent = self.UI.Left
	
	local middle = _g.new_ui.Menu.Line:Clone()
	middle.LayoutOrder = self._curOrder
	middle.Parent = self.UI.Folder.Middle

	self:AddPaintedItem(middle.Frame, {BackgroundColor3 = "second"})
end

function Menu:size(parent)
	if self.sized then return end
	self.sized = true
	
	self.UI.Position = UDim2.new(10, 0, 10, 0)
	self.UI.Visible = false
	self.UI.Parent = parent
	
	local abs_left = self.UI.Left.AbsoluteSize
	local abs_right = self.UI.Right.AbsoluteSize
	self.UI.Size = UDim2.new(0, abs_left.X + abs_right.X, 0, abs_left.Y)
end

function Menu:Show(vec2pos, parent)
	_g.ClickOff.RegisterUI(self.UI)
	
	self.UI.Position = UDim2.new(0, vec2pos.X, 0, vec2pos.Y)
	self.UI.Visible = false
	self.UI.Parent = parent
	
	task.delay(0, function()
		self.UI.Visible = true
	end)
end

function Menu:Close()
	if self.ActiveMenuItem then
		local save = self.ActiveMenuItem
		_g.AllMenus[save.name]:Close()
		self.ActiveMenuItem = nil
		save:_HoverEnded(save.UI)
	end
	self.UI.Parent = nil
end

return Menu

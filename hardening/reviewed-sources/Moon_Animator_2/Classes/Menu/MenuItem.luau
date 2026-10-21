local _g = _G.MoonGlobal; _g.req("Object")
local MenuItem = super:new()

function MenuItem:new(name, Menu, ItemLabel, extra)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		assert(Menu ~= nil, "Target Menu is nil.")

		ctor.name = name
		ctor.Menu = Menu
		ctor.left_ui = _g.new_ui.Menu.Left:Clone()
		ctor.middle_ui = _g.new_ui.Menu.Middle:Clone()
		ctor.right_ui = _g.new_ui.Menu.Right:Clone()
		ctor.Disabled = false
		ctor.NoClickOff = extra and extra.NoClickOff or false
		
		local item_frame = _g.new_ui.Menu.ItemFrame:Clone(); ctor.item_frame = item_frame
		item_frame.Label.Text = ItemLabel
		item_frame.Parent = ctor.left_ui
		ctor:AddPaintedItem(item_frame.Label, {TextColor3 = "main"})
		
		ctor:AddPaintedItem(ctor.middle_ui.Hover, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.middle_ui.Hover.UIStroke, {Color = "highlight"})

		Menu:_AddMenuItem(ctor)
	
		if _g.AllMenus and _g.AllMenus[name] then
			ctor:_AddMoreFrame()
		else
			if extra and extra.IsToggle then
				local check_frame = _g.new_ui.Menu.CheckFrame:Clone(); ctor.check_frame = check_frame
				check_frame.Parent = ctor.left_ui
				ctor:AddPaintedItem(check_frame.Frame, {BackgroundColor3 = "bg"})
				ctor:AddPaintedItem(check_frame.Frame.UIStroke, {Color = "main"})
			end
			if extra and extra.Price then
				MenuItem._SetPrice(ctor, "4.99")
				if _g.Themer.theme_buttons[ItemLabel] == nil then
					_g.Themer.theme_buttons[ItemLabel] = {}
				end
				table.insert(_g.Themer.theme_buttons[ItemLabel], ctor)
			end
			if _g.Input and _g.Input.Actions and _g.Input.Actions[name] then
				MenuItem._SetControl(ctor, _g.Input.Actions[name].keys)
				MenuItem._SetDisabled(ctor, _g.Input.Actions[name].disabled)
			end
		end

		_g.GuiLib:AddInput(ctor.middle_ui.Input, {hover = {caller_obj = ctor, func_start = MenuItem._HoverBegan, func_ended = MenuItem._HoverEnded}})

		_g.AllMenuItems[name] = ctor
	end

	return ctor
end

function MenuItem:Destroy()
	_g.AllMenuItems[self.name] = nil
	super.Destroy(self)
end

function MenuItem:set_check(value)
	self.check_frame.Frame.UIStroke.Thickness = value and 2 or 0
	self:SetItemPaint(self.check_frame.Frame, {BackgroundColor3 = value and "bg" or "third"})
end

function MenuItem:_HoverBegan(UI)
	self.middle_ui.Hover.Visible = true

	if self.Menu.ActiveMenuItem ~= nil and self.Menu.ActiveMenuItem ~= self then
		local save = self.Menu.ActiveMenuItem
		_g.AllMenus[save.name]:Close()
		self.Menu.ActiveMenuItem = nil
		save:_HoverEnded()
	end
end

function MenuItem:_HoverEnded(UI)
	if self.Menu.ActiveMenuItem == self then self:_HoverBegan() return end
	self.middle_ui.Hover.Visible = false
end

function MenuItem:_SetPrice(price)
	local price_frame = _g.new_ui.Menu.PriceFrame:Clone(); self.price_frame = price_frame
	price_frame.Label.Text = tostring(price)
	price_frame.Parent = self.right_ui
	
	self:AddPaintedItem(price_frame.Icon, {TextColor3 = "main"})
	self:AddPaintedItem(price_frame.Label, {TextColor3 = "main"})
	
	self:RemovePaintedItem(self.item_frame.Label)
	self:RemovePaintedItem(self.middle_ui.Hover)
	self:RemovePaintedItem(self.middle_ui.Hover.UIStroke)
	
	local theme = _g.Themer._BuiltInThemes[self.item_frame.Label.Text]
	self.item_frame.Label.TextColor3 = Color3.fromRGB(table.unpack(theme.main))
	price_frame.Frame1.Frame.BackgroundColor3 = Color3.fromRGB(table.unpack(theme.main))
	price_frame.Frame2.Frame.BackgroundColor3 = Color3.fromRGB(table.unpack(theme.second))
	price_frame.Frame3.Frame.BackgroundColor3 = Color3.fromRGB(table.unpack(theme.third))
	
	self.middle_ui.Hover.BackgroundColor3 = Color3.fromRGB(table.unpack(theme.highlight))
	self.middle_ui.Hover.UIStroke.Color = Color3.fromRGB(table.unpack(theme.highlight))
end

function MenuItem:_SetControl(keys)
	if keys == nil then keys = {} end
	
	if #keys > 0 then
		local control_frame = _g.new_ui.Menu.ControlFrame:Clone(); self.control_frame = control_frame
		control_frame.Label.Text = _g.Input.PrettyFormat(keys[1])
		control_frame.Parent = self.right_ui
		self:AddPaintedItem(control_frame.Label, {TextColor3 = self.Disabled and "third" or "main"})
	end
end

function MenuItem:_AddMoreFrame()
	if not self.more_frame then
		local more_frame = _g.new_ui.Menu.MoreFrame:Clone(); self.more_frame = more_frame
		more_frame.Parent = self.right_ui
		self:AddPaintedItem(more_frame.Arrow, {TextColor3 = self.Disabled and "third" or "second"})
	end
end

function MenuItem:_SetDisabled(value)
	self.Disabled = value
	
	local color = value and "third" or "main"
	
	if not self.price_frame then
		self:SetItemPaint(self.item_frame.Label, {TextColor3 = color})
	end
	if self.more_frame then
		self:SetItemPaint(self.more_frame.Arrow, {TextColor3 = value and "third" or "second"})
	end
	if self.control_frame then
		self:SetItemPaint(self.control_frame.Label, {TextColor3 = color})
	end
end

return MenuItem

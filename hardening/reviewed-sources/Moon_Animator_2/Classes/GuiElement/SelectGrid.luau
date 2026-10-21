local _g = _G.MoonGlobal; _g.req("GuiElement", "Ease")
local SelectGrid = super:new()

local tween_time = 2 * _g.Themer.QUICK_TWEEN

function SelectGrid:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor._buttons = {}
		ctor.select_frame = UI.Grid.Select; ctor.select_frame.Parent = nil
		ctor.Enabled = nil
		ctor.Value = nil
		ctor.no_select_color = {}
		
		ctor.select_frame.BackgroundTransparency = 1
		ctor.select_frame.UIStroke.Transparency = 1

		for _, but in pairs(UI:GetDescendants()) do
			if but.ClassName == "ImageButton" then
				table.insert(ctor._buttons, but)
				ctor:AddPaintedItem(but.Label, {TextColor3 = "main"})
				local new_select = ctor.select_frame:Clone(); new_select.Parent = but
				if Ease.EASE_DATA[but.Name] == nil then
					table.insert(ctor.no_select_color, new_select)
					ctor:AddPaintedItem(new_select, {BackgroundColor3 = "highlight"})
					ctor:AddPaintedItem(new_select.UIStroke, {Color = "highlight"})
				else
					new_select.BackgroundColor3 = Ease.EASE_DATA[but.Name].Color
					new_select.UIStroke.Color = Ease.EASE_DATA[but.Name].Color
				end
				_g.GuiLib:AddInput(but, {down = {func = function()
					if not ctor.Enabled then return end
					SelectGrid.Set(ctor, but.Name, true)
				end}})
			elseif but.Name == "Decor" then
				ctor:AddPaintedItem(but, {BackgroundColor3 = "second"})
			end
		end
		
		

		ctor:AddPaintedItem(UI.Title.TitleLine, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Title.Label, {TextColor3 = "main"})

		SelectGrid.Set(ctor, default)
		SelectGrid.SetEnabled(ctor, true)
	end

	return ctor
end

function SelectGrid:SetEnabled(value)
	if self.Enabled == value then return end
	self.Enabled = value

	local col = value and "main" or "third"
	for _, but in pairs(self._buttons) do
		self:SetItemPaint(but.Label, {TextColor3 = col}, tween_time)
	end
	
	for _, select_frame in pairs(self.no_select_color) do
		self:SetItemPaint(select_frame, {BackgroundColor3 = value and "highlight" or "third"}, tween_time)
		self:SetItemPaint(select_frame.UIStroke, {Color = value and "highlight" or "third"}, tween_time)
	end

	self:SetItemPaint(self.UI.Title.TitleLine, {BackgroundColor3 = col}, tween_time)
	self:SetItemPaint(self.UI.Title.Label, {TextColor3 = col}, tween_time)
end

function SelectGrid:Set(value, clicked)
	if self.Value == value then return end

	local found_but
	for _, but in pairs(self._buttons) do
		if but.Name == value then
			found_but = but
			_g.Themer:QuickTween(but.Select, tween_time, {BackgroundTransparency = 0.9})
			_g.Themer:QuickTween(but.Select.UIStroke, tween_time, {Transparency = 0})
		elseif but.Name == self.Value then
			_g.Themer:QuickTween(but.Select, tween_time, {BackgroundTransparency = 1})
			_g.Themer:QuickTween(but.Select.UIStroke, tween_time, {Transparency = 1})
		end
	end

	if not found_but then value = nil end
	self.Value = value

	if clicked and self._changed then
		self._changed(value)
	end
end

return SelectGrid

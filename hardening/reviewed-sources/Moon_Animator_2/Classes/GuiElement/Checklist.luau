local _g = _G.MoonGlobal; _g.req("GuiElement", "MoonScroll")
local Checklist = super:new()

function Checklist:new(UI, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.item_ui = UI.List.View.Canvas.ChecklistItem; ctor.item_ui.Parent = nil
		ctor.all_items = {}
		ctor.List = {}
		ctor.ScrollList = MoonScroll:new(UI.List, ctor.item_ui.Size.Y.Offset)
		ctor.count = 0
		ctor.last_shift = nil

		ctor:AddPaintedItem(UI.BorderLabel.Background, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.BorderLabel.Background.UIStroke, {Color = "second"})
		ctor:AddPaintedItem(UI.BorderLabel.LabelFrame, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.BorderLabel.LabelFrame.Label, {TextColor3 = "main"})
	end

	return ctor
end

function Checklist:new_item()
	local item = self.item_ui:Clone()
	self:AddPaintedItem(item.Label, {TextColor3 = "main"})
	self:AddPaintedItem(item.Frame, {BackgroundColor3 = "third"})
	self:AddPaintedItem(item.Frame.UIStroke, {Color = "main"})
	return item
end

function Checklist:remove_item(item)
	self:RemovePaintedItem(item.Label)
	self:RemovePaintedItem(item.Frame)
	self:RemovePaintedItem(item.Frame.UIStroke)
	item:Destroy()
end

function Checklist:set_item_check(item, value)
	self:SetItemPaint(item.Frame, {BackgroundColor3 = value and "bg" or "third"})
	item.Frame.UIStroke.Thickness = value and 2 or 0
	return value
end
function Checklist:get_item_check(item)
	return item.Frame.UIStroke.Thickness == 2
end
function Checklist:toggle_item_check(item)
	return self:set_item_check(item, item.Frame.UIStroke.Thickness ~= 2)
end

function Checklist:set_item_highlight(item, value)
	self:SetItemPaint(item.Label, {TextColor3 = value and "third" or "main"})
	self:SetItemPaint(item.Frame.UIStroke, {Color = value and "third" or "main"})
	item.SliceScale = value and 0 or 1
end

function Checklist:SetList(List)
	self.last_shift = nil
	for _, item in pairs(self.ScrollList.Canvas:GetChildren()) do
		if item.ClassName == self.item_ui.ClassName then
			self:remove_item(item)
		end
	end
	self.all_items = {}

	local count = 0
	for _, ChecklistItem in pairs(List) do
		count = count + 1

		local NewItem = self:new_item()
		NewItem.Name = ChecklistItem.Id and tostring(ChecklistItem.Id) or ChecklistItem.Label
		NewItem.LayoutOrder = count
		NewItem.Label.Text = ChecklistItem.Label
		self:set_item_check(NewItem, ChecklistItem.Checked)
		self:set_item_highlight(NewItem, ChecklistItem.Locked)
		NewItem.Parent = self.ScrollList.Canvas
		
		table.insert(self.all_items, NewItem)
		self.all_items[NewItem.Name] = NewItem

		if not ChecklistItem.Locked then
			_g.GuiLib:AddInput(NewItem, {down = {func = function() 
				local sel = false
				if self.last_shift == nil then
					self.last_shift = NewItem
				elseif self.last_shift then
					if _g.Input.ShiftHeld() then
						local last_ind = self.last_shift.LayoutOrder
						local cur_ind = NewItem.LayoutOrder
						if last_ind ~= cur_ind then
							sel = math.sign(cur_ind - last_ind)
							for i = last_ind + sel, cur_ind, sel do
								local target_item = self.all_items[i]
								if target_item.SliceScale ~= 0 then
									self._changed(target_item.Name, self:toggle_item_check(target_item))
								end
							end
						end
					else
						self.last_shift = NewItem
					end
				end
				if not sel then
					self._changed(NewItem.Name, self:toggle_item_check(NewItem))
				end
			end}})
		end
	end
	self.count = count
	self.ScrollList:SetLineCount(count)
	self.List = List
end

function Checklist:SelectAll()
	for i = 1, #self.all_items do
		local ItemGui = self.all_items[i]
		self:set_item_check(ItemGui, true)
	end
	self._changed(nil, true)
end
function Checklist:SelectNone()
	for i = 1, #self.all_items do
		local ItemGui = self.all_items[i]
		self:set_item_check(ItemGui, false)
	end
	self._changed(nil, false)
end

function Checklist:SetChecked(Id, value, scrollTo)
	local get_item = self.all_items[Id]
	self:set_item_check(get_item, value)
	if scrollTo then
		self.ScrollList:SetLineNumber(get_item.LayoutOrder)
	end 
end

function Checklist:GetAllChecked()
	local ids = {}
	for i = 1, #self.all_items do
		local ItemGui = self.all_items[i]
		if self:get_item_check(ItemGui) then
			table.insert(ids, ItemGui.Name)
		end
	end
	return ids
end

function Checklist:GetAllUnchecked()
	local ids = {}
	for i = 1, #self.all_items do
		local ItemGui = self.all_items[i]
		if not self:get_item_check(ItemGui) then
			table.insert(ids, ItemGui.Name)
		end
	end
	return ids
end

return Checklist

local _g = _G.MoonGlobal; _g.req("GuiElement", "MoonScroll", "Button")
local KeyValueList = super:new()

function KeyValueList:new(UI, List, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor.List = List and List or {}
		ctor.ListTemplate = UI.List.View.Canvas.Item; ctor.ListTemplate.Parent = nil
		ctor.ScrollList = MoonScroll:new(UI.List, ctor.ListTemplate.Size.Y.Offset - 1)
		ctor.count = 0

		KeyValueList.SetList(ctor, ctor.List)
		Button:new(UI.Add).OnClick = function()
			KeyValueList.AddListItem(ctor)
			if ctor._changed then
				ctor._changed()
			end
		end

		ctor:AddPaintedItem(UI.NoEntries, {TextColor3 = "third"})
	end

	return ctor
end

function KeyValueList:_PaintListItem(listItem)
	self:AddPaintedItem(listItem.RemoveItem.Frame.H, {BackgroundColor3 = "highlight"})
	self:AddPaintedItem(listItem.RemoveItem.Frame.V, {BackgroundColor3 = "highlight"})
	self:AddPaintedItem(listItem.BG.UIStroke, {Color = "second"})
	self:AddPaintedItem(listItem.Frame, {BackgroundColor3 = "second"})
	self:AddPaintedItem(listItem.KeyInput,   {TextColor3 = "main"})
	self:AddPaintedItem(listItem.ValueFrame.ValueInput, {TextColor3 = "main"})
end

function KeyValueList:_DestroyListItem(listItem)
	self:RemovePaintedItem(listItem.RemoveItem.Frame.H)
	self:RemovePaintedItem(listItem.RemoveItem.Frame.V)
	self:RemovePaintedItem(listItem.BG.UIStroke)
	self:RemovePaintedItem(listItem.Frame)
	self:RemovePaintedItem(listItem.KeyInput)
	self:RemovePaintedItem(listItem.ValueFrame.ValueInput)
	listItem:Destroy()
end

function nice_select(gui)
	gui:SetAttribute("select_all", false)
	gui.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not gui:GetAttribute("select_all") and gui:IsFocused() and gui.SelectionStart == -1 then
			gui:SetAttribute("select_all", true)
			gui.SelectionStart = 1
			gui.CursorPosition = #gui.Text + 1
		end
	end)
end

function KeyValueList:AddListItem(newListTbl)
	if newListTbl == nil then
		newListTbl = {"EventName", "0"}
	end
	table.insert(self.List, newListTbl)

	self.count = self.count + 1
	self.ScrollList:SetLineCount(self.count)
	self.ScrollList.Canvas.Size = self.ScrollList.Canvas.Size + UDim2.new(0, 0, 0, 1)

	local newListItem = self.ListTemplate:Clone()
	newListItem.KeyInput.Text = newListTbl[1]
	newListItem.ValueFrame.ValueInput.Text = tostring(newListTbl[2])
	newListItem.LayoutOrder = self.count
	newListItem.Parent = self.ScrollList.Canvas
	self:_PaintListItem(newListItem)

	newListTbl.UI = newListItem
	
	_g.GuiLib:AddInput(newListItem.RemoveItem, {click = {func = function()
		self:RemoveListItem(newListTbl)
		if self._changed then
			self._changed()
		end
	end}})

	_g.GuiLib:AddInput(newListItem.KeyInput, {focus_lost = {
		func = function()
			newListItem.KeyInput:SetAttribute("select_all", false)
			newListTbl[1] = newListItem.KeyInput.Text
			if self._changed then
				self._changed()
			end
		end
	}})
	nice_select(newListItem.KeyInput)

	_g.GuiLib:AddInput(newListItem.ValueFrame.ValueInput, {focus_lost = {
		func = function()
			newListItem.ValueFrame.ValueInput:SetAttribute("select_all", false)
			newListTbl[2] = newListItem.ValueFrame.ValueInput.Text
			if self._changed then
				self._changed()
			end
		end
	}})
	nice_select(newListItem.ValueFrame.ValueInput)
	
	self.UI.NoEntries.Visible = false
end

function KeyValueList:RemoveListItem(listTbl)
	local found
	for ind, tbl in pairs(self.List) do
		if tbl == listTbl then
			found = ind
		elseif found then
			tbl.UI.LayoutOrder = ind - 1
		end
	end

	if found == nil then assert(false, "List Item not in List.") end

	self:_DestroyListItem(self.List[found].UI)

	self.count = self.count - 1
	self.ScrollList:SetLineCount(self.count)
	self.ScrollList.Canvas.Size = self.ScrollList.Canvas.Size + UDim2.new(0, 0, 0, 1)

	table.remove(self.List, found)
	self.UI.NoEntries.Visible = self.count == 0
end

function KeyValueList:SetList(newList)
	if newList == nil then
		newList = {}
	end

	for _, listTbl in pairs(self.List) do
		self:_DestroyListItem(listTbl.UI)
	end
	self.List = {}
	self.count = 0
	self.ScrollList:SetLineCount(0)
	
	for _, listTbl in pairs(newList) do
		self:AddListItem(listTbl)
	end

	self.UI.NoEntries.Visible = self.count == 0
end

return KeyValueList

local _g = _G.MoonGlobal; _g.req("Object")
local LayerSystemItem = super:new()

function LayerSystemItem:new(LayerSystem, ItemObject, hierLevel, ListComponent, TimelineComponent, height)
	local ctor = super:new(LayerSystem)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.LayerSystem = LayerSystem
		ctor.ItemObject = ItemObject
		
		ctor.hierLevel = hierLevel
		ctor.height = height
		ctor.collapsed = false
		ctor.hidden = false
		ctor.ParentContainer = nil
		ctor.ListComponent = ListComponent
		ctor.LCParent = nil
		ctor.TimelineComponent = TimelineComponent
		ctor.TCParent = nil
		
		_g.new_ui.LayerSystemItem.TrackButtons.Arrow:Clone().Parent = ctor.ListComponent
		
		_g.GuiLib:AddInput(ListComponent.Arrow, {click = {func = function() 
			ctor:Collapse()
			if not ctor.collapsed then
				ctor.LayerSystem.LayerHandler:SetActiveItemObject(ctor.ItemObject)
			end
		end}})

		ListComponent.Arrow.Position = ListComponent.Arrow.Position + UDim2.new(0, -3 + 4 * (hierLevel + 1), 0, 0)
		ListComponent.Label.Position = ListComponent.Label.Position + UDim2.new(0, -4 + 4 * (hierLevel + 1), 0, 0)

		ctor:AddPaintedItem(ctor.ListComponent.Label, {TextColor3 = "text"})
		ctor:AddPaintedItem(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = "second"})
	end

	return ctor
end

function LayerSystemItem:Destroy()
	if self.ParentContainer then
		self.ParentContainer:Remove(self)
	end
	super.Destroy(self)
end

function LayerSystemItem:GetItemsBelow(recursive)
	assert(self.ParentContainer ~= nil, "LayerSystemItem not parented in a LSIContainer.")

	local ret = {}

	local objs = self.ParentContainer.Objects
	local index = self.ParentContainer:IndexOf(self)
	for iter = index + 1, #objs, 1 do
		if objs[iter].hierLevel and ((not recursive and objs[iter].hierLevel == self.hierLevel + 1) or (recursive and objs[iter].hierLevel > self.hierLevel)) then
			table.insert(ret, objs[iter])
		elseif not objs[iter].hierLevel or objs[iter].hierLevel <= self.hierLevel then
			break
		end
	end

	return ret
end

function LayerSystemItem:Collapse(value)
	if value == nil then
		value = not self.collapsed
	end
	if self.collapsed == value then return end

	local colList = {}
	local itemStack = self:GetItemsBelow()

	while (#itemStack > 0) do
		local topItem = table.remove(itemStack, 1)
		table.insert(colList, topItem)

		if not topItem.collapsed then
			local moreBelow = topItem:GetItemsBelow()
			for _, item in pairs(moreBelow) do
				table.insert(itemStack, 1, item)
			end
		end
	end

	if #colList > 0 then
		local totalSize = 0
		for _, item in pairs(colList) do
			item.hidden = value
			if value then
				item.LCParent = item.ListComponent.Parent; 	   item.ListComponent.Parent = nil
				item.TCParent = item.TimelineComponent.Parent; item.TimelineComponent.Parent = nil
			else
				item.ListComponent.Parent = item.LCParent
				item.TimelineComponent.Parent = item.TCParent
			end
			totalSize = totalSize + (value and -item.height or item.height)
		end
		self.ParentContainer:_ChangeHeight(totalSize)

		self.collapsed = value
		
		self.ListComponent.Arrow.ArrowRight.Visible = value
		self.ListComponent.Arrow.ArrowDown.Visible = not value
	end
end

return LayerSystemItem

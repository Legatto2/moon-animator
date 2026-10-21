local _g = _G.MoonGlobal; _g.req("ObjectGroup")
local LSIContainer = super:new()

function LSIContainer:new(name, canvasList, canvasTimeline)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		ctor.ListComponent = nil
		ctor.TimelineComponent = nil
		ctor.height = 0
		ctor.ParentContainer = nil

		ctor.LayerHandler = nil
		ctor.ItemObject = nil

		if canvasList == nil then
			local frame = Instance.new("Frame")
				local layout = Instance.new("UIListLayout")
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = frame 
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 0, 0, 0)

			ctor.ListComponent = frame
			ctor.TimelineComponent = frame:Clone()
		else
			ctor.ListComponent = canvasList
			ctor.TimelineComponent = canvasTimeline
		end
	end

	return ctor
end

function LSIContainer:_ChangeHeight(delta)
	local CurrentContainer = self
	repeat
		CurrentContainer.height = CurrentContainer.height + delta
		if CurrentContainer.LayerHandler then
			CurrentContainer.LayerHandler:_SetCanvasSize(CurrentContainer.ListComponent.Size + UDim2.new(0, 0, 0, delta))
			break
		else
			CurrentContainer.ListComponent.Size = CurrentContainer.ListComponent.Size + UDim2.new(0, 0, 0, delta)
			CurrentContainer.TimelineComponent.Size = CurrentContainer.TimelineComponent.Size + UDim2.new(0, 0, 0, delta)
		end
		CurrentContainer = CurrentContainer.ParentContainer
	until CurrentContainer == nil
end

function LSIContainer:Insert(Object, index)
	assert(not self:Contains(Object))
	assert(Object.ListComponent, "Object is not a LayerSystemItem or a LSIContainer.")

	for i = index, self.size, 1 do
		local Target = self.Objects[i]
		Target.ListComponent.LayoutOrder = i + 1
		Target.TimelineComponent.LayoutOrder = i + 1
	end

	super.Insert(self, Object, index)
	Object.ParentContainer = self

	if Object.ListComponent.Visible then
		self:_ChangeHeight(Object.ListComponent.Size.Y.Offset)
	end
	Object.ListComponent.Parent = self.ListComponent
	Object.ListComponent.LayoutOrder = index
	Object.TimelineComponent.Parent = self.TimelineComponent
	Object.TimelineComponent.LayoutOrder = index
end

function LSIContainer:Remove(Object)
	assert(self:Contains(Object))

	if Object.ListComponent.Visible then
		self:_ChangeHeight(-Object.ListComponent.Size.Y.Offset)
	end

	local layoutOrder = Object.ListComponent.LayoutOrder

	Object.ListComponent.Parent = nil
	Object.TimelineComponent.Parent = nil
	super.Remove(self, Object)
	Object.ParentContainer = nil

	for i = layoutOrder, self.size, 1 do
		self.Objects[i].ListComponent.LayoutOrder = i
		self.Objects[i].TimelineComponent.LayoutOrder = i
	end
end

return LSIContainer

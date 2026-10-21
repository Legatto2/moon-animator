local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local RigKeyframeTrack = super:new()

function RigKeyframeTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.HandleHidden = false
		ctor.Attached = {}
		
		_g.new_ui.LayerSystemItem.TrackButtons.HandleVisible:Clone().Parent = ctor.ListComponent
		
		ctor:AddPaintedItem(ctor.ListComponent.HandleVisible.Top.Frame, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.HandleVisible.Bottom.Frame, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.HandleVisible.Circle, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.HandleVisible.Circle.UIStroke, {Color = "bg"})
		ctor:AddPaintedItem(ctor.ListComponent.HandleVisible.Off, {TextColor3 = "main"})
		
		ctor.ListComponent.HandleVisible.Visible = true
		
		_g.GuiLib:AddInput(ctor.ListComponent.HandleVisible, {
			click = {func = function() 
				ctor:SetHandleHidden(not ctor.HandleHidden)
			end},
			down = {func = function()
				ctor:SetHandleHidden(not ctor.HandleHidden, true)
			end, mouse_but = Enum.UserInputType.MouseButton3}
		})

	end

	return ctor
end

function RigKeyframeTrack:Destroy()
	super.Destroy(self)
end

function RigKeyframeTrack:set_select(value)
	super.set_select(self, value)
	
	if value then
		self:SetItemPaint(self.ListComponent.HandleVisible.Top.Frame, {BackgroundColor3 = "highlight"})
		self:SetItemPaint(self.ListComponent.HandleVisible.Bottom.Frame, {BackgroundColor3 = "highlight"})
		self:SetItemPaint(self.ListComponent.HandleVisible.Circle, {BackgroundColor3 = "highlight"})
		self:SetItemPaint(self.ListComponent.HandleVisible.Off, {TextColor3 = "highlight"})
	else
		local col = self.HandleHidden and "third" or "second"
		self:SetItemPaint(self.ListComponent.HandleVisible.Top.Frame, {BackgroundColor3 = col})
		self:SetItemPaint(self.ListComponent.HandleVisible.Bottom.Frame, {BackgroundColor3 = col})
		self:SetItemPaint(self.ListComponent.HandleVisible.Circle, {BackgroundColor3 = col})
		self:SetItemPaint(self.ListComponent.HandleVisible.Off, {TextColor3 = "main"})
	end
end

function RigKeyframeTrack:SetHandleHidden(value, all)
	self.HandleHidden = value
	if not self.selected then
		local col = value and "third" or "second"
		self:SetItemPaint(self.ListComponent.HandleVisible.Top.Frame, {BackgroundColor3 = col})
		self:SetItemPaint(self.ListComponent.HandleVisible.Bottom.Frame, {BackgroundColor3 = col})
		self:SetItemPaint(self.ListComponent.HandleVisible.Circle, {BackgroundColor3 = col})
	end
	self.ListComponent.HandleVisible.Off.Visible = value
end

return RigKeyframeTrack

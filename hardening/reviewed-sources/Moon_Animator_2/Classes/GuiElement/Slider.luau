local _g = _G.MoonGlobal; _g.req("GuiElement")
local Slider = super:new()

function Slider:new(UI, default, vertical, changed, ended)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor._ended = ended
		ctor._dir = vertical
		ctor._dirAxis = vertical and "Y" or "X"
		
		Slider.Set(ctor, default)
		
		_g.GuiLib:AddInput(UI.Button, {drag = {
			caller_obj = ctor,
			func_start = Slider._DragBegin, func_changed = Slider._DragChanged, func_ended = Slider._DragEnded,
		}})
		
		ctor:AddPaintedItem(UI, {BackgroundColor3 = "third"})
		ctor:AddPaintedItem(UI.Button, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(UI.Parent.Minus.H, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Parent.Plus.H, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Parent.Plus.V, {BackgroundColor3 = "main"})
	end

	return ctor
end

do
	local iniDragPosition = nil

	function Slider:_DragBegin(but)
		iniDragPosition = but.Position
		self:_DragChanged(but, {X = 0, Y = 0})
	end
	function Slider:_DragChanged(but, changed)
		local calcPos = iniDragPosition[self._dirAxis].Scale - math.clamp(iniDragPosition[self._dirAxis].Scale + (changed[self._dirAxis] / self.UI.Size[self._dirAxis].Offset), 0, 1)
		but.Position = self._dir and iniDragPosition - UDim2.new(0, 0, calcPos, 0) or iniDragPosition - UDim2.new(calcPos, 0, 0, 0)

		if self._changed then
			self._changed(but.Position[self._dirAxis].Scale)
		end
	end
	function Slider:_DragEnded(but)
		self.Value = but.Position[self._dirAxis].Scale
		if self._ended then
			self._ended(self.Value)
		end
	end
end

function Slider:Set(value)
	self.Value = math.clamp(value, 0, 1)
	self.UI.Button.Position = self._dir and self.UI.Button.Position + UDim2.new(0, 0, -self.UI.Button.Position.Y.Scale + self.Value, 0) 
	or self.UI.Button.Position + UDim2.new(-self.UI.Button.Position.X.Scale + self.Value, 0, 0, 0)
end

return Slider

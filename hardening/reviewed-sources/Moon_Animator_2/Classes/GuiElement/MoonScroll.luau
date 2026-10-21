local _g = _G.MoonGlobal; _g.req("GuiElement")
local MoonScroll = super:new()

function MoonScroll:new(UI, line_height)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.line_height = line_height
		ctor.Canvas = UI.View.Canvas
		ctor.linked_canvases = {}

		UI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			MoonScroll.SetCanvasPosition(ctor, -ctor.Canvas.Position.Y.Offset)
		end)
		
		_g.GuiLib:AddInput(ctor.UI.View, {scroll = {
			func = function(dir)
				local clickoff_check = _g.ClickOff.CheckInBounds(_g.Mouse.X, _g.Mouse.Y)
				if clickoff_check and not ctor.UI.View:IsDescendantOf(clickoff_check) then return end
				MoonScroll.SetLineNumber(ctor, MoonScroll.GetLineNumber(ctor) + -dir)
			end,
		}})
		MoonScroll.SetLineNumber(ctor, 1)

		_g.GuiLib:AddInput(UI.ScrollbarFrame.Scrollbar, {drag = {
			caller_obj = ctor,
			func_start = MoonScroll._ScrollbarDragBegin, func_changed = MoonScroll._ScrollbarDragChanged, func_ended = MoonScroll._ScrollbarDragEnd,
		}})
		
		ctor:AddPaintedItem(UI.ScrollbarFrame, {BackgroundColor3 = "bg"})
		if UI.ScrollbarFrame.Scrollbar:FindFirstChild("Frame") then
			ctor:AddPaintedItem(UI.ScrollbarFrame.Scrollbar.Frame, {BackgroundColor3 = "third"})
		else
			ctor:AddPaintedItem(UI.ScrollbarFrame.Scrollbar, {BackgroundColor3 = "third"})
		end
		for _, frame in pairs(UI.ScrollbarFrame.Scrollbar:GetChildren()) do
			if frame.Name == "Decor" then
				ctor:AddPaintedItem(frame, {BackgroundColor3 = "second"})
			end
		end
		ctor:AddPaintedItem(UI, {BackgroundColor3 = "bg", BorderColor3 = "second"})
	end

	return ctor
end

local iniDragPosition

function MoonScroll:_ScrollbarDragBegin(Scrollbar, ini_pos)
	iniDragPosition = Scrollbar.Position.Y.Scale
end

function MoonScroll:_ScrollbarDragChanged(Scrollbar, changed)
	local scrollScrollbarPos = math.clamp(iniDragPosition + (changed.Y / Scrollbar.Parent.AbsoluteSize.Y), 0, 1 - Scrollbar.Size.Y.Scale)
	Scrollbar.Position = UDim2.new(0, 0, scrollScrollbarPos, 0)

	scrollScrollbarPos = (1 - Scrollbar.Size.Y.Scale) > 0 and scrollScrollbarPos / (1 - Scrollbar.Size.Y.Scale) or 0
	self:SetCanvasPositionPercent(scrollScrollbarPos)
end

function MoonScroll:_ScrollbarDragEnd(Scrollbar)
	
end

function MoonScroll:SetCanvasSize(y_size)
	self.Canvas.Size = UDim2.new(1, 0, 0, y_size)
	self:SetCanvasPosition(-self.Canvas.Position.Y.Offset)
end

function MoonScroll:GetCanvasSize()
	return self.Canvas.Size.Y.Offset
end

function MoonScroll:GetCanvasLines()
	return math.floor(self.Canvas.Size.Y.Offset / self.line_height)
end

function MoonScroll:SetLineCount(num_lines)
	self:SetCanvasSize(num_lines * self.line_height)
end

function MoonScroll:GetMaxCanvasPosition()
	return math.clamp(self.Canvas.Size.Y.Offset - self.UI.View.AbsoluteSize.Y, 0, math.huge)
end

function MoonScroll:SetCanvasPosition(y_pos)
	local canvas_size = self.Canvas.Size.Y.Offset
	local view_size = self.UI.View.AbsoluteSize.Y
	local view_position = self.UI.View.AbsolutePosition.Y

	if view_position + canvas_size + -y_pos < view_position + view_size then
		y_pos = math.clamp(canvas_size - view_size, 0, math.huge)
	end
	if view_position + -y_pos > view_position then
		y_pos = 0
	end

	self.Canvas.Position = UDim2.new(0, 0, 0, -y_pos)

	if canvas_size <= view_size then
		self.UI.ScrollbarFrame.Scrollbar.Size = UDim2.new(1, 0, 1, 0)
		self.UI.ScrollbarFrame.Scrollbar.Position = UDim2.new(0, 0, 0, 0)
	else
		local scrollBarSize = math.clamp(view_size / (canvas_size + 1), 0.05, 1)
		self.UI.ScrollbarFrame.Scrollbar.Size = UDim2.new(1, 0, scrollBarSize, 0)
		local per = y_pos / math.clamp(canvas_size - view_size, 0, math.huge)
		self.UI.ScrollbarFrame.Scrollbar.Position = UDim2.new(0, 0, per * (1 - (self.UI.ScrollbarFrame.Scrollbar.AbsoluteSize.Y / self.UI.ScrollbarFrame.AbsoluteSize.Y)), 0)
	end
end

function MoonScroll:SetCanvasPositionPercent(per)
	self:SetCanvasPosition((self.Canvas.Size.Y.Offset - self.UI.View.AbsoluteSize.Y) * per)
end

function MoonScroll:GetCanvasPosition()
	return -self.Canvas.Position.Y.Offset
end

function MoonScroll:SetLineNumber(num)
	self:SetCanvasPosition((num - 1) * self.line_height)
end

function MoonScroll:GetLineNumber()
	return math.floor(-self.Canvas.Position.Y.Offset / self.line_height) + 1
end

return MoonScroll

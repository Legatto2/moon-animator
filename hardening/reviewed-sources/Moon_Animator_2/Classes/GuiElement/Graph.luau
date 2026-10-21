local _g = _G.MoonGlobal; _g.req("GuiElement")
local Graph = super:new()

local tween_time = 2 * _g.Themer.QUICK_TWEEN

function Graph:new(UI, default)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.Func = default
		ctor.slider_per = nil
		ctor.Line = UI.Screen.Line
		ctor.Slider = UI.Slider
		ctor.Point = UI.Screen.Point

		Graph.DrawLine(ctor, ctor.Func)
		UI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			Graph.DrawLine(ctor, ctor.Func, true)
		end)
		
		ctor:AddPaintedItem(UI.Frame, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.Screen.Point, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Screen.X, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(UI.Screen.X_Top, {BackgroundColor3 = "third"})
		ctor:AddPaintedItem(UI.Screen.Y, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(UI.Screen.ConstantJump, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(UI.Slider.TimeInd, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Slider.TimeInd.Extendo, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Slider.TimeInd.Extendo2, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Slider.TimeInd.Label, {TextColor3 = "main"})
	end

	return ctor
end

function Graph:DrawLine(func, noTween)
	self.Func = func

	if func == _g.EasingFunctions.Constant then
		func = function()
			return 0
		end
		self.UI.Screen.ConstantJump.Visible = true
	else
		self.UI.Screen.ConstantJump.Visible = false
	end

	local full_x = self.Line.AbsoluteSize.X
	local full_y = self.Line.AbsoluteSize.Y

	local step = math.floor(full_x / 2)
	local prev_point = Vector2.new(0, func(0) * full_y)

	if step > 500 then
		noTween = true
	end
	
	for i = 1, step do
		local eval = func(i/step)
		local next_point = Vector2.new(i/step * full_x, eval * full_y)
		
		local seg_size = math.sqrt((next_point.Y - prev_point.Y) ^ 2 + (next_point.X - prev_point.X)^2)
		local seg_rot_center = math.atan2((next_point.Y - prev_point.Y), (next_point.X - prev_point.X))

		local act_point = Vector2.new((prev_point.X + (seg_size / 2)) + (seg_size / 2)*math.cos(seg_rot_center + math.pi), prev_point.Y + (seg_size / 2)*math.sin(seg_rot_center + math.pi))
		local corrected_pos = prev_point - (act_point - prev_point)
		
		if self.Line:FindFirstChild(tostring(i)) then
			local seg = self.Line:FindFirstChild(tostring(i))
			_g.Themer:QuickTween(seg, noTween and 0 or tween_time, {
				Size = UDim2.new(seg_size / full_x, 0, 0, 1), 
				Rotation = -math.deg(seg_rot_center), 
				Position = UDim2.new(corrected_pos.X / full_x, 0, 1 - corrected_pos.Y / full_y, 0),
			})
		else
			local newSeg = Instance.new("Frame")
			newSeg.Size = UDim2.new(seg_size / full_x, 0, 0, 1) 
			newSeg.Rotation = -math.deg(seg_rot_center)
			newSeg.Position = UDim2.new(corrected_pos.X / full_x, 0, 1 - corrected_pos.Y / full_y, 0)
			self:AddPaintedItem(newSeg, {BackgroundColor3 = "highlight"})

			newSeg.Name = tostring(i)
			newSeg.ZIndex = 5
			newSeg.AnchorPoint = Vector2.new(0, 1)
			newSeg.BorderSizePixel = 0
			newSeg.Parent = self.Line
		end
		
		prev_point = next_point
	end

	if self.Line:FindFirstChild(tostring(step + 1)) then
		for _, seg in pairs(self.Line:GetChildren()) do
			if tonumber(seg.Name) > step then
				self:RemovePaintedItem(seg)
				seg:Destroy()
			end
		end
	end

	self:SetSliderPercent(self.slider_per)
end

function Graph:SetSliderPercent(percent)
	if percent == nil then 
		self.slider_per = nil 
		self.Slider.TimeInd.Visible = false 
		self.Point.Visible = false 
		return
	elseif self.slider_per == nil then
		self.Slider.TimeInd.Visible = true 
		self.Point.Visible = true 
	end

	if percent > 1 then
		percent = 1
	elseif percent < 0 then
		percent = 0
	end
	self.slider_per = percent

	local eval = self.Func(percent)
	self.Slider.TimeInd.Visible = true
	self.Slider.TimeInd.Position = UDim2.new(percent, 0, 1, 0)
	self.Point.Position = UDim2.new(percent, -2, 1 - eval, -3)
	self.Slider.TimeInd.Label.Text = math.floor(eval * 100 + 0.5).."%"
end

return Graph

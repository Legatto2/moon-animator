local _g = _G.MoonGlobal; _g.req("GuiElement")
local Check = super:new()

function Check:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor.Value = default
		ctor.Enabled = true

		UI.LabelArea.Size = UDim2.new(0, _g.GetTextSize(UI.LabelArea.Label), 1, 0)
		Check.Set(ctor, default)

		local setter = function() if not ctor.Enabled then return end Check.Set(ctor, not ctor.Value, true) end
		_g.GuiLib:AddInput(UI, {click = {func = setter}})
		_g.GuiLib:AddInput(UI.LabelArea, {click = {func = setter}})

		ctor:AddPaintedItem(UI.BG_Check, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.BG_Check.Frame, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.BG_Uncheck.UIStroke, {Color = "second"})
		ctor:AddPaintedItem(UI.None, {BackgroundColor3 = "third"})
		ctor:AddPaintedItem(UI.LabelArea.Label, {TextColor3 = "main"})
	end

	return ctor
end

function Check:SetEnabled(val)
	self.Enabled = val
	
	self:SetItemPaint(self.UI.BG_Uncheck.UIStroke, {Color = val and "second" or "third"}, _g.Themer.QUICK_TWEEN)
	self:SetItemPaint(self.UI.BG_Check, {BackgroundColor3 = val and "main" or "third"}, _g.Themer.QUICK_TWEEN)
	self:SetItemPaint(self.UI.LabelArea.Label, {TextColor3 = val and "main" or "third"}, _g.Themer.QUICK_TWEEN)
	
	self:Set(self.Value)
end

function Check:Set(value, clicked)
	if value == nil then
		self.UI.None.Visible = true
		self.UI.BG_Check.Visible = false
		self.UI.BG_Uncheck.Visible = true
	else
		self.UI.None.Visible = false
		self.UI.BG_Check.Visible = value
		self.UI.BG_Uncheck.Visible = not value
	end
	self.Value = value

	if clicked and self._changed then
		self._changed(value)
	end
end

return Check

local _g = _G.MoonGlobal; _g.req("GuiElement")
local Button = super:new()

function Button:new(UI)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.OnClick = nil
		ctor.highlight = false

		ctor:AddPaintedItem(UI.BG, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.BG.UIStroke, {Color = "second"})
		ctor:AddPaintedItem(UI.Label, {TextColor3 = "main"})
		
		_g.GuiLib:AddInput(UI, {
			click = {func = function()
				if ctor.OnClick and UI.AutoButtonColor then
					ctor.OnClick()
				end
			end}, 
			hover = {
				caller_obj = ctor,
				func_start = function()
					self:SetItemPaint(UI.BG.UIStroke, {Color = UI.AutoButtonColor and "main" or "third"}, _g.Themer.QUICK_TWEEN)
				end,
				func_ended = function()
					self:SetItemPaint(UI.BG.UIStroke, {Color = UI.AutoButtonColor and (ctor.highlight and "highlight" or "second") or "third"}, _g.Themer.QUICK_TWEEN)
				end
			},
		})

		Button.SetActive(ctor, true)
	end

	return ctor
end

function Button:set_highlight(value)
	self.highlight = value
	self:SetItemPaint(self.UI.BG.UIStroke, {Color = self.UI.AutoButtonColor and (self.highlight and "highlight" or "second") or "third"}, _g.Themer.QUICK_TWEEN)
	self:SetItemPaint(self.UI.Label, {TextColor3 = self.UI.AutoButtonColor and (self.highlight and "highlight" or "main") or "third"}, _g.Themer.QUICK_TWEEN)
end

function Button:SetActive(value)
	if self.UI.AutoButtonColor == value then return end
	self.UI.AutoButtonColor = value
	self:SetItemPaint(self.UI.BG.UIStroke, {Color = value and (self.highlight and "highlight" or "second") or "third"}, _g.Themer.QUICK_TWEEN)
	self:SetItemPaint(self.UI.Label, {TextColor3 = value and (self.highlight and "highlight" or "main") or "third"}, _g.Themer.QUICK_TWEEN)
end

return Button

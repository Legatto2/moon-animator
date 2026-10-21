local _g = _G.MoonGlobal; _g.req("GuiElement")
local InputBox = super:new()

function InputBox:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.Value = default
		ctor.Enabled = true

		ctor.OldText = "-"
		
		if UI.ClassName == "TextLabel" then
			ctor.label = UI
			local font = _g.GetTextSize(UI)
			UI.Size = UDim2.new(0, font + 4, 0, 8)
			ctor:AddPaintedItem(UI, {TextColor3 = "main"})
		end
		ctor:AddPaintedItem(UI.Frame.BG, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.Frame.BG.UIStroke, {Color = "second"})
		ctor:AddPaintedItem(UI.Frame.Input, {TextColor3 = "text"})
	end

	return ctor
end

function InputBox:Process(input)
	self.Value = input
	return input
end

function InputBox:SetEnabled(value)
	self.Enabled = value
	self:SetItemPaint(self.UI.Frame.BG.UIStroke, {Color = value and "second" or "third"}, _g.Themer.QUICK_TWEEN)
	if self.label then
		self:SetItemPaint(self.label, {TextColor3 = value and "main" or "third"}, _g.Themer.QUICK_TWEEN)
	end
end

function InputBox:Set(input, inputted)
	if inputted and not self.Enabled then
		self.UI.Frame.Input.Text = self.OldText
		return
	end
	local process = self:Process(input)
	if type(process) == "number" then
		process = _g.format_number(process)
	end
	self.UI.Frame.Input.Text = process ~= nil and process or "-"
	self.OldText = self.UI.Frame.Input.Text

	if inputted then
		self._changed(self.Value)
	end
end

return InputBox

local _g = _G.MoonGlobal; _g.req("GuiElement")
local InputList = super:new()

local tween_time = 2 * _g.Themer.QUICK_TWEEN

function InputList:new(UI, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.Enabled = nil
		ctor._changed = changed
		ctor._list = {}
		ctor._item = UI.Inputs.InputItem; ctor._item.Parent = nil

		ctor:AddPaintedItem(UI.Title.Decor, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(UI.Title.Label, {TextColor3 = "main"})

		InputList.SetEnabled(ctor, false)
	end

	return ctor
end

function InputList:SetEnabled(value)
	if self.Enabled == value then return end
	self.Enabled = value

	local col = value and "main" or "third"
	self:SetItemPaint(self.UI.Title.Decor, {BackgroundColor3 = col}, tween_time)
	self:SetItemPaint(self.UI.Title.Label, {TextColor3 = col}, tween_time)

	for _, frame in pairs(self.UI.Inputs:GetChildren()) do
		if frame.ClassName == self._item.ClassName then
			self:SetItemPaint(frame.Frame.BG.UIStroke, {Color = value and "second" or "third"}, tween_time)
			self:SetItemPaint(frame.Label, {TextColor3 = col}, tween_time)
			self:SetItemPaint(frame.Default, {BackgroundColor3 = value and "second" or "third"}, tween_time)
			frame.Frame.Input.TextEditable = value
		end
	end
end

function InputList:GetValueDictionary()
	local dict = {}
	for _, tbl in pairs(self._list) do
		dict[tbl.name] = tbl.current
	end
	return dict
end

function InputList:SetList(list)
	for _, frame in pairs(self.UI.Inputs:GetChildren()) do
		if frame.ClassName == self._item.ClassName then
			self:RemovePaintedItem(frame.Frame.BG)
			self:RemovePaintedItem(frame.Frame.BG.UIStroke)
			self:RemovePaintedItem(frame.Label)
			self:RemovePaintedItem(frame.Default)
			frame:Destroy()
		end
	end

	local max_size = 0

	for _, tbl in pairs(list) do
		local new_item = self._item:Clone()
		new_item.Label.Text = tbl.name..":"
		new_item.Frame.Input.Text = _g.format_number(tbl.default)
		new_item.Frame.Input.TextEditable = self.Enabled
		
		local label_size = _g.GetTextSize(new_item.Label)
		if label_size > max_size then
			max_size = label_size
		end

		if tbl.current == nil then
			tbl.current = tbl.default
		end

		local set_value

		if tbl.input_type == "number" then
			set_value = function(value)
				tbl.current = _g.round(value, 0.00001)
				new_item.Frame.Input.Text = _g.format_number(tbl.current)
				if tbl.frame_relative then
					new_item.Frame.Input.Text = new_item.Frame.Input.Text.." [".._g.format_number(_g.round(tbl.frame_relative * tbl.current, 0.01)).."f]"
				end
				if self._changed then
					self._changed(tbl)
				end
			end
			_g.GuiLib:AddInput(new_item.Frame.Input, {
				scroll = {
					func = function(dir)
						if not self.Enabled or _g.input_serv:GetFocusedTextBox() == new_item.Frame.Input then return end
						set_value(tbl.current + tbl.inc * dir)
					end,
				},
				focus_lost = {
					func = function()
						local get_text = new_item.Frame.Input.Text

						local new_input
						if string.sub(get_text, #get_text) == "f" and tbl.frame_relative then
							new_input = tonumber(string.sub(get_text, 1, #get_text - 1))
							if new_input then
								new_input = new_input / tbl.frame_relative
							end
						else
							new_input = tonumber(get_text)
						end

						if new_input == nil then
							new_input = tbl.current
						end
						set_value(new_input)
					end
				}
			})
		end

		set_value(tbl.current)
		_g.GuiLib:AddInput(new_item.Default, {click = {func = function()
			set_value(tbl.default)
		end}})
		
		self:AddPaintedItem(new_item.Frame.BG, {BackgroundColor3 = "bg"})
		self:AddPaintedItem(new_item.Frame.BG.UIStroke, {Color = self.Enabled and "second" or "third"})
		self:AddPaintedItem(new_item.Label, {TextColor3 = self.Enabled and "main" or "third"})
		self:AddPaintedItem(new_item.Default, {BackgroundColor3 = self.Enabled and "second" or "third"})

		new_item.Parent = self.UI.Inputs
	end

	for _, frame in pairs(self.UI.Inputs:GetChildren()) do
		if frame.ClassName == self._item.ClassName then
			local label_size = _g.GetTextSize(frame.Label)
			frame.Frame.Size = UDim2.new(1, -(max_size) - 4 - 20, 1, 0)
			frame.Label.Position = frame.Label.Position + UDim2.new(0, max_size - label_size, 0, 0)
		end
	end

	self._list = list
end

return InputList

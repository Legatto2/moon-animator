local _g = _G.MoonGlobal; _g.req("InputBox", "MoonScroll")
local ListInput = super:new()

ListInput.MAX_ITEMS = 6

function ListInput:new(UI, default, changed, Options)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._options = Options
		ctor._ItemTemplate = _g.new_ui.ListItem
		ctor.ScrollList = MoonScroll:new(UI.List, ctor._ItemTemplate.Size.Y.Offset)
		ctor.CurrentId = nil

		ListInput.SetList(ctor, Options)
		ListInput.Set(ctor, default, false)

		ctor:AddPaintedItem(UI.List.UIStroke, {Color = "second"})
		ctor:AddPaintedItem(UI.Frame.DownArrow.Arrow, {TextColor3 = "text"})
		
		_g.GuiLib:AddInput(UI.Frame, {
			click = {
				func = function()
					if #ctor._options == 0 or not ctor.Enabled then ctor.ScrollList.UI.Visible = false return end
					if ctor.ScrollList.UI.Visible then
						_g.ClickOff._Off()
					else
						ctor.ScrollList.UI.Visible = true
						_g.ClickOff.RegisterUI(UI.Frame, tostring(ctor), function() ctor.ScrollList.UI.Visible = false end)
						_g.ClickOff.RegisterUI(ctor.ScrollList.UI, tostring(ctor), function() ctor.ScrollList.UI.Visible = false end)
					end
				end,
			},
			scroll = {
				func = function(dir)
					if _g.ClickOff.CurrentGroup == nil then
						for ind, opt in pairs(ctor._options) do
							if ctor.Value == nil then ctor.Value = ctor._options[#ctor._options][2] end
							if ctor.Value == opt[2] then
								local targetInd = ind - dir
								if targetInd <= 0 then
									targetInd = #ctor._options
								elseif targetInd > #ctor._options then
									targetInd = 1
								end
								ListInput.Set(ctor, ctor._options[targetInd][1], true)
								break
							end
						end
					end
				end,
			},
		})
	end

	return ctor
end

function ListInput:SetEnabled(value)
	super.SetEnabled(self, value)
	self:SetItemPaint(self.UI.List.UIStroke, {Color = value and "second" or "third"})
end

function ListInput:Process(input)
	for _, opt in pairs(self._options) do
		if opt[1] == input then
			self.CurrentId = opt[1]
			self.Value = opt[2]
			return self.ScrollList.Canvas["_"..tostring(opt[1])].Label.Text
		end
	end
	self.CurrentId = nil
	self.Value = nil
	return nil
end

function ListInput:SetList(Options)
	if self.ScrollList.UI.Visible then
		_g.ClickOff._Off()
	end
	self._options = Options

	for _, ItemGui in pairs(self.ScrollList.Canvas:GetChildren()) do
		if ItemGui.ClassName == self._ItemTemplate.ClassName then
			self:RemovePaintedItem(ItemGui)
			self:RemovePaintedItem(ItemGui.Label)
			ItemGui:Destroy()
		end
	end

	local count = 0
	for num, opt in pairs(self._options) do
		local NewItem = self._ItemTemplate:Clone()
		NewItem.Name = "_"..tostring(opt[1])
		NewItem.LayoutOrder = num
		NewItem.Label.Text = typeof(opt[2]) == "EnumItem" and opt[2].Name or tostring(opt[2])
		NewItem.Parent = self.ScrollList.Canvas
		_g.GuiLib:AddInput(NewItem, {click = {func = function() 
			self:Set(opt[1], true) 
			_g.ClickOff._Off() 
		end}})
		count = count + 1

		self:AddPaintedItem(NewItem, {BackgroundColor3 = "bg"})
		self:AddPaintedItem(NewItem.Label, {TextColor3 = "text"})
	end

	self.ScrollList.UI.Size = UDim2.new(0, self.UI.Frame.Size.X.Offset - 2, 0, count > ListInput.MAX_ITEMS and 18 * ListInput.MAX_ITEMS or 18 * count)
	self.ScrollList:SetLineCount(count)
	self:Set(nil, false)
end

return ListInput

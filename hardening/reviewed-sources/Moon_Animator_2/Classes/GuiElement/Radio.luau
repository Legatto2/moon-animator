local _g = _G.MoonGlobal; _g.req("GuiElement")
local Radio = super:new()

function Radio:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._options = {}
		ctor._changed = changed
		ctor.Value = nil

		for _, but in pairs(UI:GetChildren()) do
			if but.ClassName == "ImageButton" then
				ctor._options[but.Name] = but
				but.LabelArea.Size = UDim2.new(0, 6*#but.LabelArea.Label.Text, 1, 0)

				local setter = function() Radio.Set(ctor, but.Name, true) end
				_g.GuiLib:AddInput(but, {click = {func = setter}})
				_g.GuiLib:AddInput(but.LabelArea, {click = {func = setter}})

				ctor:AddPaintedItem(but.BG_Off.UIStroke, {Color = "second"})
				ctor:AddPaintedItem(but.BG_On, {BackgroundColor3 = "main"})
				ctor:AddPaintedItem(but.LabelArea.Label, {TextColor3 = "main"})
			end
		end

		Radio.Set(ctor, default)
	end

	return ctor
end

function Radio:Set(value, clicked)
	if self.Value == value then return end

	for nm, but in pairs(self._options) do
		but.BG_Off.Visible = not (nm == value)
		but.BG_On.Visible = (nm == value)
	end
	self.Value = value

	if clicked and self._changed then
		self._changed(value)
	end
end

return Radio

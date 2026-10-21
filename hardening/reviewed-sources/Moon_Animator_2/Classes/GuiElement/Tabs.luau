local _g = _G.MoonGlobal; _g.req("GuiElement")
local Tabs = super:new()

function Tabs:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._tabs = {}
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.CurrentTab = nil

		for _, but in pairs(UI.Tabs:GetChildren()) do
			if but.ClassName == "ImageButton" then
				ctor._tabs[but.Name] = but
				
				_g.GuiLib:AddInput(but, {click = {func = function() Tabs.ShowTab(ctor, but.Name, true) end}})
				ctor:AddPaintedItem(but.SelectedInd, {BackgroundColor3 = "main"})
				ctor:AddPaintedItem(but.Label, {TextColor3 = "main"})
			end
		end
		Tabs.ShowTab(ctor, default)
	end

	return ctor
end

function Tabs:ShowTab(tabName, clicked)
	if self.CurrentTab == tabName then return end

	for nm, tab in pairs(self._tabs) do
		local comp = nm == tabName
		self.UI[nm].Visible = comp
		tab.SelectedInd.BackgroundTransparency = comp and 0 or 1
	end
	self.CurrentTab = tabName

	if clicked then
		self._changed(tabName)
	end
end

return Tabs

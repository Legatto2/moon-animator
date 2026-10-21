local _g = _G.MoonGlobal; _g.req("LayerSystemItem")
local Divider = super:new()

function Divider:new(LayerSystem, ItemObject, hierLevel, divLabel)
	local ui_store = _g.new_ui.LayerSystemItem.Divider
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, ui_store.List:Clone(), ui_store.Timeline:Clone(), ui_store.List.Size.Y.Offset)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.handle_visible = nil
		
		Divider.SetLabel(ctor, divLabel)
		
		ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = "highlight"})
		ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = "highlight"})
		
		_g.GuiLib:AddInput(ctor.ListComponent.Hover, {hover = {caller_obj = ctor,
			func_start = function()
				ctor:SetItemPaint(ctor.ListComponent.Label, {TextColor3 = "highlight"})
				if ctor.handle_visible then
					ctor:SetItemPaint(ctor.handle_visible.Top.Frame, {BackgroundColor3 = "highlight"})
					ctor:SetItemPaint(ctor.handle_visible.Bottom.Frame, {BackgroundColor3 = "highlight"})
					ctor:SetItemPaint(ctor.handle_visible.Circle, {BackgroundColor3 = "highlight"})
				end
			end,
			func_ended = function()
				ctor:SetItemPaint(ctor.ListComponent.Label, {TextColor3 = "text"})
				if ctor.handle_visible then
					ctor:SetItemPaint(ctor.handle_visible.Top.Frame, {BackgroundColor3 = "main"})
					ctor:SetItemPaint(ctor.handle_visible.Bottom.Frame, {BackgroundColor3 = "main"})
					ctor:SetItemPaint(ctor.handle_visible.Circle, {BackgroundColor3 = "main"})
				end
			end,
		}})
	end

	return ctor
end

function Divider:SetLabel(divLabel)
	self.divLabel = divLabel
	self.ListComponent.Label.Text = divLabel
end

return Divider

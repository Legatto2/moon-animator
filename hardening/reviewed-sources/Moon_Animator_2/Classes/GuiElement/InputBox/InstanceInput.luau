local _g = _G.MoonGlobal; _g.req("GuiElement", "ValueLabel", "Button")
local InstanceInput = super:new()

function InstanceInput:new(UI, default, changed)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor.Value = default
		ctor.Enabled = true
		ctor.val_label = ValueLabel:new(UI.Current)
		ctor.set_but = Button:new(UI.Set)
		
		ctor.val_label:Set(InstanceInput.Process(ctor, default))

		ctor.set_but.OnClick = function()
			local target = _g.first_sel()
			if target == nil then target = _g.NIL_VALUE end
			InstanceInput.Set(ctor, target, true)
		end
	end

	return ctor
end

function InstanceInput:SetEnabled(val)
	self.Enabled = val
	self.set_but:SetEnabled(val)
end

function InstanceInput:Set(input, inputted)
	if inputted and not self.Enabled then
		return
	end
	self.val_label:Set(self:Process(input))
	if inputted then
		self._changed(self.Value)
	end
end

function InstanceInput:Process(input)
	if input == nil then
		self.Value = nil
		return "< varied >"
	end
	self.Value = input
	return input ~= _g.NIL_VALUE and tostring(input) or "< nil >"
end

return InstanceInput

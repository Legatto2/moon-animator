local _g = _G.MoonGlobal; _g.req("GuiElement", "ListInput", "Ease")
local EaseInput = super:new()

function EaseInput:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.Value = {_tblType = "Ease", ease_type = "Linear"}
		ctor.Enabled = true
		ctor.LastDir = "In"
		ctor.has_dir = false
		
		ctor.Style = ListInput:new(UI.StyleInput, nil, nil, Ease.EASE_LIST)
		ctor.Dir = ListInput:new(UI.DirInput, nil, nil, Ease.DIR_LIST)
		
		ctor.Style._changed = function()
			ctor:refresh_dir(ctor.Style.CurrentId)
			ctor:refresh_value(true)
		end
		
		ctor.Dir._changed = function(value)
			ctor.LastDir = value
			ctor:refresh_value(true)
		end
		
		EaseInput.Set(ctor, ctor.Value)
	end

	return ctor
end

function EaseInput:refresh_value(inputted)
	local params = {}
	if self.Dir.Enabled then
		params.Direction = self.Dir.Value
	end
	self:Set({_tblType = "Ease", ease_type = self.Style.CurrentId, params = params}, inputted)
end

function EaseInput:refresh_dir(ease_type)
	if ease_type then
		local ease_data = Ease.EASE_DATA[ease_type]
		if ease_data.Params == nil or ease_data.Params.Direction == nil then
			self.Dir:Set(nil)
			self.Dir:SetEnabled(false)
			self.has_dir = false
		elseif ease_data.Params.Direction then
			self.Dir:Set(self.LastDir)
			self.Dir:SetEnabled(true)
			self.has_dir = true
		end
	else
		self.Dir:Set(nil)
		self.Dir:SetEnabled(false)
		self.has_dir = false
	end
end

function EaseInput:SetEnabled(value)
	self.Enabled = value
	self.Style:SetEnabled(value)
	self.Dir:SetEnabled(self.has_dir)
end

function EaseInput:Process(input)
	if input == nil then
		self.Value = nil
		return nil
	end
	self.Value = input
	return self.Value
end

function EaseInput:Set(input, inputted)
	local process = self:Process(input)

	if process == nil then
		self.Style:Set(nil)
		self:refresh_dir()
	else
		self.Style:Set(input.ease_type)
		self:refresh_dir(self.Style.CurrentId)
		if self.Dir.Enabled then
			if input.params and input.params.Direction then
				self.Dir:Set(input.params.Direction)
			else
				self.Dir:Set(self.LastDir)
			end
		end
	end

	if inputted then
		self._changed(self.Value)
	end
end

return EaseInput

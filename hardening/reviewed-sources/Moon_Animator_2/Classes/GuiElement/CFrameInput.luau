local _g = _G.MoonGlobal; _g.req("GuiElement", "AngleInput", "NumberInput", "Button")
local CFrameInput = super:new()

function CFrameInput:new(UI, default, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.Value = default
		ctor.Enabled = true
		
		ctor.X = NumberInput:new(UI.X, 0, function() ctor:value_changed(ctor.X) end)
		ctor.Y = NumberInput:new(UI.Y, 0, function() ctor:value_changed(ctor.Y) end)
		ctor.Z = NumberInput:new(UI.Z, 0, function() ctor:value_changed(ctor.Z) end)
		ctor.AngleX = AngleInput:new(UI.AngleX, 0, function() ctor:value_changed(ctor.AngleX) end)
		ctor.AngleY = AngleInput:new(UI.AngleY, 0, function() ctor:value_changed(ctor.AngleY) end)
		ctor.AngleZ = AngleInput:new(UI.AngleZ, 0, function() ctor:value_changed(ctor.AngleZ) end)
		
		ctor.CopyAngle = Button:new(UI.CopyAngle)
		ctor.CopyAngle.OnClick = function()
			local get_sel = _g.first_sel(); if get_sel and get_sel.ClassName == "Model" then get_sel = get_sel.PrimaryPart end
			if ctor.Value and get_sel and get_sel:IsA("BasePart") then
				local target_cf = CFrame.new(ctor.Value.p) * CFrame.Angles(get_sel:GetRenderCFrame():ToEulerAngles())
				ctor:Set(target_cf, true, 0)
			end
		end
		
		ctor.CopyPos = Button:new(UI.CopyPos)
		ctor.CopyPos.OnClick = function()
			local get_sel = _g.first_sel(); if get_sel and get_sel.ClassName == "Model" then get_sel = get_sel.PrimaryPart end
			if ctor.Value and get_sel and get_sel:IsA("BasePart") then
				local target_cf = CFrame.new(get_sel:GetRenderCFrame().p) * CFrame.Angles(ctor.Value:ToEulerAngles())
				ctor:Set(target_cf, true, 1)
			end
		end
		
		ctor.CopyBoth = Button:new(UI.CopyBoth)
		ctor.CopyBoth.OnClick = function()
			local get_sel = _g.first_sel(); if get_sel and get_sel.ClassName == "Model" then get_sel = get_sel.PrimaryPart end
			if get_sel and get_sel:IsA("BasePart") then
				local target_cf = get_sel:GetRenderCFrame() 
				ctor:Set(target_cf, true, 2)
			end
		end

		CFrameInput.Set(ctor, ctor.Value)
	end

	return ctor
end

function CFrameInput:SetEnabled(value)
	self.Enabled = value
	
	self.X:SetEnabled(value)
	self.Y:SetEnabled(value)
	self.Z:SetEnabled(value)
	self.AngleX:SetEnabled(value)
	self.AngleY:SetEnabled(value)
	self.AngleZ:SetEnabled(value)
	self.CopyAngle:SetActive(value)
	self.CopyPos:SetActive(value)
	self.CopyBoth:SetActive(value)
end

function CFrameInput:value_changed(ele)
	local prev_val = ele.Value
	if self.Value == nil then self:Set(CFrame.new()) ele:Set(prev_val) end
	self:Set(CFrame.new(self.X.Value, self.Y.Value, self.Z.Value) * CFrame.fromEulerAngles(math.rad(self.AngleX.Value), math.rad(self.AngleY.Value), math.rad(self.AngleZ.Value)), true)
end

function CFrameInput:Process(input)
	if input == nil then
		self.Value = nil
		return nil
	end
	if typeof(input) == "CFrame" then
		self.Value = input
	end
	return self.Value
end

function CFrameInput:Set(input, inputted, relative)
	local process = self:Process(input)

	if process == nil then
		self.X:Set(nil); self.Y:Set(nil); self.Z:Set(nil)
		self.AngleX:Set(nil); self.AngleY:Set(nil); self.AngleZ:Set(nil)
	else
		local pos = self.Value.p
		local a_x, a_y, a_z = self.Value:ToEulerAngles()
		
		self.X:Set(pos.X); self.Y:Set(pos.Y); self.Z:Set(pos.Z)
		self.AngleX:Set(math.deg(a_x)); self.AngleY:Set(math.deg(a_y)); self.AngleZ:Set(math.deg(a_z))
	end

	if inputted then
		self._changed(self.Value, relative)
	end
end

return CFrameInput

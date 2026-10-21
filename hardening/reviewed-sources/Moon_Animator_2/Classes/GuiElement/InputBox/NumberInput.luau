local _g = _G.MoonGlobal; _g.req("InputBox")
local NumberInput = super:new()

function NumberInput:new(UI, default, changed, Bounds)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		if Bounds == nil then
			ctor.Min = -math.huge
			ctor.Max = math.huge
			ctor.Inc = 1
			ctor.is_int = false
		else
			ctor.Min = Bounds[1]
			ctor.Max = Bounds[2]
			ctor.Inc = Bounds[3]
			ctor.is_int = Bounds[4]
		end

		UI.Frame.Input.Text = NumberInput.Process(ctor, default)
		
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() NumberInput.Set(ctor, UI.Frame.Input.Text, true) end
		}})
		_g.GuiLib:AddInput(UI.Frame, {scroll = {
			func = function(dir)
				if ctor.Enabled and _g.ClickOff.CurrentGroup == nil and ctor.Value ~= nil and not UI.Frame.Input:IsFocused() then
					local act_inc = _g.Input:ShiftHeld() and ctor.Inc / 5 or ctor.Inc
					NumberInput.Set(ctor, ctor.Value + dir * act_inc, true)
				end
			end,
		}})
	end

	return ctor
end

function NumberInput:Process(input)
	if input == nil then
		self.Value = nil
		return "-"
	end
	if tonumber(input) == nil then return self.Value end

	self.Value = _g.round(math.clamp(tonumber(input), self.Min, self.Max), 0.000001)
	if self.is_int then self.Value = math.floor(self.Value) end
	return self.Value
end

return NumberInput

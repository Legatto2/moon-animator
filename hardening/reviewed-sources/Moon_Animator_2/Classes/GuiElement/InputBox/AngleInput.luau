local _g = _G.MoonGlobal; _g.req("InputBox")
local AngleInput = super:new()

function AngleInput:new(UI, default, changed)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		UI.Frame.Input.Text = AngleInput.Process(ctor, default)
		
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() AngleInput.Set(ctor, UI.Frame.Input.Text, true) end
		}})
		_g.GuiLib:AddInput(UI.Frame, {scroll = {
			func = function(dir)
				if _g.ClickOff.CurrentGroup == nil and ctor.Value ~= nil and not UI.Frame.Input:IsFocused() then
					AngleInput.Set(ctor, ctor.Value + dir, true)
				end
			end,
		}})
	end

	return ctor
end

function AngleInput:Process(input)
	if input == nil then
		self.Value = nil
		return nil
	end
	if tonumber(input) == nil then return self.Value end

	local getNum = tonumber(input)
	local neg = getNum < 0 and -1 or 1
	getNum = math.abs(getNum)
	getNum = (getNum - 360 * math.floor(getNum/360)) * neg
	self.Value = getNum

	return getNum
end

return AngleInput

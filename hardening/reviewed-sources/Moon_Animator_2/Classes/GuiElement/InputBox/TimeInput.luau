local _g = _G.MoonGlobal; _g.req("InputBox")
local TimeInput = super:new()

function TimeInput:new(UI, default, changed, Bounds)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		if Bounds == nil then
			ctor.Min = 1
			ctor.Max = _g.MAX_FRAMES
			ctor.Inc = 1
		else
			ctor.Min = Bounds[1]
			ctor.Max = Bounds[2]
			ctor.Inc = Bounds[3]
		end
		ctor.set_fps = nil

		UI.Frame.Input.Text = TimeInput.Process(ctor, default)
		
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() 
				local getNum = tonumber(UI.Frame.Input.Text)
				if getNum then
					getNum = _g.TimeConvert(tonumber(UI.Frame.Input.Text), "s", "f", ctor:get_fps())
				elseif getNum == nil then
					local len = #UI.Frame.Input.Text
					if string.find(UI.Frame.Input.Text, ":") then
						getNum = _g.TimeConvert(UI.Frame.Input.Text, "t", "f", ctor:get_fps())
					elseif string.sub(UI.Frame.Input.Text, len, len) == "f" then
						getNum = tonumber(string.sub(UI.Frame.Input.Text, 1, len - 1))
					end
				end
				TimeInput.Set(ctor, getNum and getNum or ctor.Value, true) 
			end
		}})
		_g.GuiLib:AddInput(UI.Frame, {scroll = {
			func = function(dir)
				if _g.ClickOff.CurrentGroup == nil and ctor.Value ~= nil and not UI.Frame.Input:IsFocused() then
					TimeInput.Set(ctor, ctor.Value + dir * ctor.Inc, true)
				end
			end,
		}})
	end

	return ctor
end

function TimeInput:get_fps()
	return self.set_fps == nil and _g.current_fps or self.set_fps
end

function TimeInput:Process(input)
	if input == nil then
		self.Value = nil
		return nil
	end

	local getNum = tonumber(input)
	if getNum == nil and string.find(input, ":") then
		getNum = _g.TimeConvert(input, "t", "f", self:get_fps())
	end
	if getNum == nil then
		return self.Value
	end

	self.Value = math.clamp(getNum, self.Min, self.Max)
	return _g.TimeConvert(self.Value, "f", "t", self:get_fps())
end

return TimeInput

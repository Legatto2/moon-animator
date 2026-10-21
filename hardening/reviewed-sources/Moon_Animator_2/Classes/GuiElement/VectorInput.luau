local _g = _G.MoonGlobal; _g.req("InputBox")
local VectorInput = super:new()

function VectorInput:new(UI, default, changed, vec2)
	local ctor = super:new(UI, default, changed)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.vec2 = vec2
		ctor.Value = default
		
		_g.GuiLib:AddInput(UI.Frame.Input, {focus_lost = {
			func = function() 
				VectorInput.Set(ctor, UI.Frame.Input.Text, true) 
			end
		}})

		VectorInput.Set(ctor, default)
	end

	return ctor
end

function VectorInput:Process(input, sec)
	if input == nil then
		self.Value = nil
		return "-"
	end

	if (not self.vec2 and typeof(input) == "Vector3") or (self.vec2 and typeof(input) == "Vector2") then
		self.Value = input
	else
		local vals = _g.csvToNumberTable(input)
		local x, y, z = vals[1], vals[2], vals[3]
		if not self.vec2 then
			if x and y and z then
				self.Value = Vector3.new(x, y, z)
			end
		else
			if x and y then
				self.Value = Vector2.new(x, y)
			end
		end
	end
	
	if not self.vec2 then
		return _g.format_number(self.Value.X)..", ".._g.format_number(self.Value.Y)..", ".._g.format_number(self.Value.Z)
	else
		return _g.format_number(self.Value.X)..", ".._g.format_number(self.Value.Y)
	end
end

return VectorInput

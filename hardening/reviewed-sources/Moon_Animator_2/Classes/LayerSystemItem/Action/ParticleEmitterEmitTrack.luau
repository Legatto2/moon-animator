local _g = _G.MoonGlobal; _g.req("ActionTrack")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		local e_c = ctor.Target:GetAttribute("EmitCount")
		if e_c then
			ctor.defaultValue = e_c
		else
			ctor.defaultValue = 0
		end
		ctor.func = function(value)
			if value > 0 then
				ctor.Target:Emit(value)
			end
		end
	end

	return ctor
end

return Track

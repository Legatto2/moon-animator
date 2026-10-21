local _g = _G.MoonGlobal; _g.req("ActionTrack")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.defaultValue = ctor.Target.ClassName == "MeshPart" and ctor.Target.TextureID or ""
		ctor.func = function(value)
			if ctor.Target.ClassName == "MeshPart" then
				ctor.Target.TextureID = value
			end
		end
	end

	return ctor
end

return Track

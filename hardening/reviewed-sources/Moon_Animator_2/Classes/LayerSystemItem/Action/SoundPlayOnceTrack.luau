local _g = _G.MoonGlobal; _g.req("ActionTrack"); local debris = game:GetService("Debris")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.func = function(value)
			if value then
				local clone = ctor.Target:Clone(); clone.Parent = ctor.Target.Parent; clone.PlayOnRemove = true
				clone:Destroy()
			end
		end
	end

	return ctor
end

return Track

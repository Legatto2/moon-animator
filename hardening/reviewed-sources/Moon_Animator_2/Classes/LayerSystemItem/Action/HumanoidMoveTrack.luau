local _g = _G.MoonGlobal; _g.req("ActionTrack")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		if ctor.Target.Parent and ctor.Target.Parent.ClassName == "Model" and ctor.Target.Parent.PrimaryPart then
			ctor.defaultValue = ctor.Target.Parent.PrimaryPart.CFrame.lookVector
		else
			ctor.defaultValue = Vector3.new(0, 0, 0)
		end
		ctor.func = function(value)
			ctor.Target:Move(value)
		end
	end

	return ctor
end

return Track

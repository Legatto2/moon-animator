local _g = _G.MoonGlobal; _g.req("KeyframeTrack", "Path", "Ease")
local DiscreteKeyframeTrack = super:new()

function DiscreteKeyframeTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		
	end

	return ctor
end

function DiscreteKeyframeTrack:AddKeyframe(Keyframe, overwrite)
	Keyframe:SetEase(Ease.CONSTANT())
	super.AddKeyframe(self, Keyframe, overwrite)
end

return DiscreteKeyframeTrack

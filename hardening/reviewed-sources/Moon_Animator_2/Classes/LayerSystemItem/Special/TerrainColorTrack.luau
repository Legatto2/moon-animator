local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local TerrainColorTrack = super:new()

function TerrainColorTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.terrain_mc = PropertyData[1]:sub(4)
	end

	return ctor
end

function TerrainColorTrack:_Update(frm_pos)
	self:update_value(frm_pos)

	if self.value == self.previous_value then return end
	self.previous_value = self.value

	self.Target:SetMaterialColor(self.terrain_mc, self.value)
end

function TerrainColorTrack:get_prop()
	return self.Target:GetMaterialColor(self.terrain_mc)
end

function TerrainColorTrack:set_prop(value)
	self.Target:SetMaterialColor(self.terrain_mc, value)
end

return TerrainColorTrack

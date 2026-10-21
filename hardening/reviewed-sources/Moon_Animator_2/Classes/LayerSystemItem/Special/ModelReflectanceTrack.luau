local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local ModelReflectanceTrack = super:new()

function ModelReflectanceTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.model_obj = Path:GetItem()
		ctor.defaultValue = 0
	end

	return ctor
end

function ModelReflectanceTrack:get_prop()
	return self.value
end

function ModelReflectanceTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	for _, tbl in pairs(self.ItemObject.model_reflectance) do
		tbl[1].Reflectance = tbl[2] + tbl[3] * self.value
	end
	
	self.Target.Value = self.value
end

return ModelReflectanceTrack

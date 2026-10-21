local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local ModelScaleTrack = super:new()

function ModelScaleTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.model_obj = Path:GetItem()
		ctor.defaultValue = 1
	end

	return ctor
end

function ModelScaleTrack:get_prop()
	return self.value
end

function ModelScaleTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	for _, tbl in pairs(self.ItemObject.mesh_size) do
		tbl[1].Scale = tbl[2] * self.value
		tbl[1].Offset = tbl[3] * self.value
	end
	for _, tbl in pairs(self.ItemObject.joint_size) do
		tbl[1].C0 = (tbl[2] - tbl[2].p) + tbl[2].p * self.value
		tbl[1].C1 = (tbl[3] - tbl[3].p) + tbl[3].p * self.value
	end
	for _, tbl in pairs(self.ItemObject.model_size) do
		tbl[1].Size = tbl[2] * self.value
		tbl[1].CFrame = self.model_obj.PrimaryPart.CFrame:ToWorldSpace((tbl[3] - tbl[3].p) + tbl[3].p * self.value)
	end
	for _, tbl in pairs(self.ItemObject.bone_size) do
		tbl[1].CFrame = (tbl[2] - tbl[2].p) + tbl[2].p * self.value
	end
	
	self.Target.Value = self.value
end

return ModelScaleTrack

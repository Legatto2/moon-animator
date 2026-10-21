local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.defaultValue = ctor.ItemObject.model_color[1][2]
	end

	return ctor
end

function Track:get_prop()
	return self.value
end

function Track:Destroy()
	for _, tbl in pairs(self.ItemObject.model_color) do
		tbl[1].Color = tbl[2]
	end
	super.Destroy(self)
end

function Track:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	for _, tbl in pairs(self.ItemObject.model_color) do
		tbl[1].Color = self.value
	end
end

return Track

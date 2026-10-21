local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local ModelCFrameTrack = super:new()

function ModelCFrameTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.model_obj = Path:GetItem()
		ctor.defaultValue = Path.Item.PrimaryPart.CFrame
		ctor.part = Path.Item.PrimaryPart; ctor.ratio = 4; ctor.resize = true

		_g.PartHandles.AddPart(ctor, "third")
	end

	return ctor
end

function ModelCFrameTrack:make_onion(parent)
	if not self.GhostPart then
		self.GhostPart = {}
		for _, part in pairs(self.ItemObject.model_size) do part = part[1]
			table.insert(self.GhostPart, _g.ghost_part(part, parent))
		end
	end
end

function ModelCFrameTrack:clear_onion(parent)
	if self.GhostPart then
		for _, part in pairs(self.GhostPart) do
			pcall(function() part:Destroy() end)
		end
		self.GhostPart = nil
	end
end

function ModelCFrameTrack:set_select(value)
	super.set_select(self, value)
	_g.PartHandles.SetSelect(self, value)
end

function ModelCFrameTrack:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	_g.PartHandles.RemovePart(self)
	super.Destroy(self)
end

function ModelCFrameTrack:get_prop()
	return self.Path.Item.PrimaryPart.CFrame
end

function ModelCFrameTrack:set_prop(value)
	self.model_obj:PivotTo(value)
	self.Target.Value = value
end

function ModelCFrameTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	self.model_obj:PivotTo(self.value)
	self.Target.Value = self.value
end

return ModelCFrameTrack

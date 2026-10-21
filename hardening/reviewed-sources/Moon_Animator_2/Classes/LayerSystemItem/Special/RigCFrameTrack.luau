local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local RigCFrameTrack = super:new()

function RigCFrameTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.model_obj = Path:GetItem()
		ctor.defaultValue = Path.Item.PrimaryPart.CFrame
		ctor.part = Path.Item.PrimaryPart; ctor.ratio = 4

		_g.PartHandles.AddPart(ctor, "third")
	end

	return ctor
end

function RigCFrameTrack:make_onion(parent)
	if self.GhostPart then
		local check_highlight = pcall(function() local prop = self.GhostPart.Name end)
		if not check_highlight then
			self.GhostPart = nil
		end
	end
	if not self.GhostPart then
		self.GhostPart = _g.ghost_part(self.part, parent)
	end
end

function RigCFrameTrack:clear_onion(parent)
	if self.GhostPart then
		local check_highlight = pcall(function() local prop = self.GhostPart.Name end)
		if not check_highlight then
			self.GhostPart = nil
		end
	end
	if self.GhostPart then
		self.GhostPart:Destroy()
		self.GhostPart = nil
	end
end

function RigCFrameTrack:set_select(value)
	super.set_select(self, value)
	_g.PartHandles.SetSelect(self, value)
end

function RigCFrameTrack:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	_g.PartHandles.RemovePart(self)
	super.Destroy(self)
end

function RigCFrameTrack:get_prop()
	return self.Path.Item.PrimaryPart.CFrame
end

function RigCFrameTrack:set_prop(value)
	self.model_obj.PrimaryPart.CFrame = value
	self.Target.Value = value
end

function RigCFrameTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	self.model_obj.PrimaryPart.CFrame = self.value
	self.Target.Value = self.value
end

return RigCFrameTrack

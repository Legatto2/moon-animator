local _g = _G.MoonGlobal; _g.req("DiscreteKeyframeTrack", "Path")
local AttachToPartTrack = super:new()

function AttachToPartTrack:new(LayerSystem, ItemObject, hierLevel)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, LayerSystem and Path:new(workspace.CurrentCamera) or nil, {"AttachToPart", "Instance", Holder = true})
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.active = false
	end

	return ctor
end

function AttachToPartTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if not self.Enabled then self.active = false return end
	if self.ItemObject.PropertyMap["LookAtPart"] and self.ItemObject.PropertyMap["LookAtPart"].active then return end
	
	if self.value ~= nil and self.value:IsA("BasePart") then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CFrame = self.value.CFrame
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		self.active = true
	else
		self.active = false
	end
	
	self.Target[self.property] = self.value
end

return AttachToPartTrack

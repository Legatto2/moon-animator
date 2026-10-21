local _g = _G.MoonGlobal; _g.req("KeyframeTrack", "Path")
local CameraCFrameTrack = super:new()

function CameraCFrameTrack:new(LayerSystem, ItemObject, hierLevel)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, LayerSystem and Path:new(workspace.CurrentCamera) or nil, {"CFrame", "CFrame"})
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		
	end

	return ctor
end

function CameraCFrameTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if not self.Enabled then return end
	if self.ItemObject.PropertyMap["AttachToPart"] and self.ItemObject.PropertyMap["AttachToPart"].active then return end
	if self.ItemObject.PropertyMap["LookAtPart"] and self.ItemObject.PropertyMap["LookAtPart"].active then return end

	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CFrame = self.value
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

return CameraCFrameTrack

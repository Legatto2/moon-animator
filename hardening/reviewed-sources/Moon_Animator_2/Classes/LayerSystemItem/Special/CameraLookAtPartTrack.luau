local _g = _G.MoonGlobal; _g.req("DiscreteKeyframeTrack", "Path")
local LookAtPartTrack = super:new()

function LookAtPartTrack:new(LayerSystem, ItemObject, hierLevel)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, LayerSystem and Path:new(workspace.CurrentCamera) or nil, {"LookAtPart", "Instance", Holder = true})
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.active = false
	end

	return ctor
end

function LookAtPartTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value ~= nil and self.value:IsA("BasePart") then
		local attach_part
		local pivot_cf
		if self.ItemObject.PropertyMap["AttachToPart"] then
			attach_part = self.ItemObject.PropertyMap["AttachToPart"].value
		end
		if self.ItemObject.PropertyMap["CFrame"] then
			pivot_cf = self.ItemObject.PropertyMap["CFrame"].value
		end
		if attach_part then
			self.active = true
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.CFrame = CFrame.new(attach_part.Position, self.value.Position)
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		elseif pivot_cf then
			self.active = true
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.CFrame = CFrame.new(pivot_cf.p, self.value.Position)
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		else
			self.active = false
		end
	else
		self.active = false
	end
	self.Target[self.property] = self.value
end

return LookAtPartTrack

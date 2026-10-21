-- Copyright © 2023 Kojocrash

local super = require(script.Parent.Gizmos)
local PositionGizmo = require(script.PositionGizmo)
local PositionGizmos = setmetatable({}, {__index = super})

local GizmoData = {
	{"+X", "RightVector"},  {"+Y", "UpVector"},  {"+Z", "-LookVector"},
	{"-X", "-RightVector"}, {"-Y", "-UpVector"}, {"-Z", "LookVector"}	
}

function PositionGizmos:new(Target: BasePart | CFrame)
	local self = setmetatable(super:new(Target, script.PositionAxises:Clone()), {__index = PositionGizmos})
	self.canScaleWhileDragging = true
	
	for _, data in ipairs(GizmoData) do
		local name, axisDirection = unpack(data)
		local gizmo = PositionGizmo:new(self.model[name], axisDirection, self.origin, 1)
		self:RegisterGizmo(gizmo)
	end
	
	return self
end

function PositionGizmos:Redraw()
	if self.TargetPart then
		local scale = 1.5
		self.model.Origin.Sphere.Radius = 0
		
		local part_size = self.TargetPart.Size / 2
		
		for i = 1, #self.gizmos do
			local gizmo = self.gizmos[i]
			gizmo.obj.Size = gizmo.obj:GetAttribute("DefaultSize") * scale
			gizmo.obj.Attachment.CFrame = gizmo.obj.Attachment.CFrame.Rotation + Vector3.new(0, 0, 0.75 * scale + gizmo.obj.Size.Z/2) 

			for j = 1, #gizmo.adornments do
				local adornment = gizmo.adornments[j]
				if adornment.Name == "Arrow" then
					adornment.Height = adornment:GetAttribute("DefaultHeight") * scale
					adornment.Radius = adornment:GetAttribute("DefaultRadius") * scale
					adornment.CFrame = CFrame.new(0, 0, adornment.Height - gizmo.obj.Size.Z/2) - Vector3.new(0, 0, -0.5 + part_size[gizmo.axis_str])
				elseif adornment.Name == "Handle" then
					adornment.Height = adornment:GetAttribute("DefaultHeight") * scale
					adornment.Radius = adornment:GetAttribute("DefaultRadius") * scale
					adornment.CFrame = CFrame.new(0, 0, (gizmo.obj.Size.Z - adornment.Height)/2) - Vector3.new(0, 0, -0.5 + part_size[gizmo.axis_str])
				elseif adornment.Name == "BoxHandle" then
					adornment.Size = gizmo.obj.Size
				end
			end
		end
	else
		local scale = self._scale
		self.model.Origin.Sphere.Radius = 0.1
		for i = 1, #self.gizmos do
			local gizmo = self.gizmos[i]
			gizmo.obj.Size = gizmo.obj:GetAttribute("DefaultSize") * scale
			gizmo.obj.Attachment.CFrame = gizmo.obj.Attachment.CFrame.Rotation + Vector3.new(0, 0, 0.75 * scale + gizmo.obj.Size.Z/2) 

			for j = 1, #gizmo.adornments do
				local adornment = gizmo.adornments[j]
				if adornment.Name == "Arrow" then
					adornment.Height = adornment:GetAttribute("DefaultHeight") * scale
					adornment.Radius = adornment:GetAttribute("DefaultRadius") * scale
					adornment.CFrame = CFrame.new(0, 0, adornment.Height - gizmo.obj.Size.Z/2)
				elseif adornment.Name == "Handle" then
					adornment.Height = adornment:GetAttribute("DefaultHeight") * scale
					adornment.Radius = adornment:GetAttribute("DefaultRadius") * scale
					adornment.CFrame = CFrame.new(0, 0, (gizmo.obj.Size.Z - adornment.Height)/2)
				elseif adornment.Name == "BoxHandle" then
					adornment.Size = gizmo.obj.Size
				end
			end
		end
	end
end

function PositionGizmos:HoverInit(gizmo)
	self.MouseEnter:Fire(gizmo.axis, gizmo:GetDirection())
end

function PositionGizmos:HoverEnd(gizmo)
	self.MouseLeave:Fire(gizmo.axis, gizmo:GetDirection())
end

function PositionGizmos:DragInit()
	local gizmo = self.dragging
	gizmo._initOrigin = gizmo:GetOrigin()
	gizmo._initScalar = gizmo:GetScalarOnAxis()
	self.MouseButton1Down:Fire(gizmo.axis, gizmo:GetDirection())
end

function PositionGizmos:DragUpdate()
	local gizmo = self.dragging
	local delta = gizmo:GetDelta()
	if self.increment ~= 0 and self.increment ~= nil then
		delta = math.floor(math.abs(delta) / self.increment) * math.sign(delta) * self.increment
	end
	local onThreadsFinish = self.MouseDrag:Fire(gizmo.axis, delta, gizmo:GetDirection())
	onThreadsFinish(function()
		self:Update()
	end)
end

function PositionGizmos:DragEnd()
	local gizmo = self.dragging
	self.MouseButton1Up:Fire(gizmo.axis, gizmo:GetDirection())
end

return PositionGizmos
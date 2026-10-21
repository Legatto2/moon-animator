-- Copyright © 2023 Kojocrash

local super = require(script.Parent.Gizmos)
local RotationGizmo = require(script.RotationGizmo)
local RotationGizmos = setmetatable({}, {__index = super})
local TWO_PI = 2 * math.pi

local GizmoData = {{"X", "RightVector", 1}, {"Y", "UpVector", 2}, {"Z", "-LookVector", 3}}

function RotationGizmos:new(Target: BasePart | CFrame)
	local self = setmetatable(super:new(Target, script.RotationalAxises:Clone()), {__index = RotationGizmos})
	self.canMoveWhileDragging = false
	self.Revolutions = false
	--self.extraVisuals = {}
	
	for _, data in ipairs(GizmoData) do
		local name, direction, priority = unpack(data)
		local gizmo = RotationGizmo:new(self.model[name], direction, self.origin, priority)
		self:RegisterGizmo(gizmo)
	end
	
	return self
end

function RotationGizmos:Redraw()
	local scale
	if self.TargetPart then
		scale = math.max(1, math.max(self.TargetPart.Size.X, self.TargetPart.Size.Y, self.TargetPart.Size.Z)) + 4.4
		local inner_scale = (scale - 1.4) / 5; scale = scale / 5
		
		self.model.Origin.Sphere.Radius = 0
		self.model.Sphere.Size = Vector3.new(5*scale,5*scale,5*scale)
		for i = 1, #self.gizmos do
			local gizmo = self.gizmos[i]
			gizmo.obj.Size = gizmo.obj:GetAttribute("DefaultSize") * scale
			gizmo.adornments[1].Height = gizmo.adornments[1]:GetAttribute("DefaultHeight") * scale
			gizmo.adornments[1].Radius = gizmo.adornments[1]:GetAttribute("DefaultRadius") * scale
			gizmo.adornments[1].InnerRadius = gizmo.adornments[1].Radius - 0.05

			gizmo.obj.Sphere1.CFrame = CFrame.new(gizmo.obj.Sphere1:GetAttribute("DefaultPos") * inner_scale)
			gizmo.obj.Sphere2.CFrame = CFrame.new(gizmo.obj.Sphere2:GetAttribute("DefaultPos") * inner_scale)

			gizmo.obj.Parent[gizmo.obj.Name.."_Sphere1"].Size = Vector3.new(1,1,1)
			gizmo.obj.Parent[gizmo.obj.Name.."_Sphere2"].Size = Vector3.new(1,1,1)

			gizmo.sphere1_hand.Radius = 0.5
			gizmo.sphere2_hand.Radius = 0.5
		end
	else
		scale = self._scale
		
		self.model.Origin.Sphere.Radius = 0.1
		self.model.Sphere.Size = Vector3.new(5*scale,5*scale,5*scale)
		for i = 1, #self.gizmos do
			local gizmo = self.gizmos[i]
			gizmo.obj.Size = gizmo.obj:GetAttribute("DefaultSize") * scale
			gizmo.adornments[1].Height = gizmo.adornments[1]:GetAttribute("DefaultHeight") * scale
			gizmo.adornments[1].Radius = gizmo.adornments[1]:GetAttribute("DefaultRadius") * scale
			gizmo.adornments[1].InnerRadius = gizmo.adornments[1]:GetAttribute("DefaultInnerRadius") * scale

			gizmo.obj.Sphere1.CFrame = CFrame.new(gizmo.obj.Sphere1:GetAttribute("DefaultPos") * scale)
			gizmo.obj.Sphere2.CFrame = CFrame.new(gizmo.obj.Sphere2:GetAttribute("DefaultPos") * scale)

			gizmo.obj.Parent[gizmo.obj.Name.."_Sphere1"].Size = Vector3.new(scale,scale,scale)
			gizmo.obj.Parent[gizmo.obj.Name.."_Sphere2"].Size = Vector3.new(scale,scale,scale)

			gizmo.sphere1_hand.Radius = scale / 2
			gizmo.sphere2_hand.Radius = scale / 2
		end
	end

	--[[if self.dragging then
		local Ring = self.dragging.adornments[1]
		
		self.LineA.Height = Ring.InnerRadius
		self.LineA.Radius = (Ring.Height * self.LineA:GetAttribute("Thickness")) / 2
		pointLineAt(self.LineA, self.dragging._initPoint)
		
		self.LineB.Height = Ring.InnerRadius
		self.LineB.Radius = (Ring.Height * self.LineB:GetAttribute("Thickness")) / 2
		if self._mousePosOnPlane then pointLineAt(self.LineB, self._mousePosOnPlane) end
		
		self.Fill.Height = Ring.Height
		self.Fill.Radius = Ring.InnerRadius
	end]]
end

function RotationGizmos:HoverInit(gizmo)
	self.MouseEnter:Fire(gizmo.axis, gizmo:GetPlaneNormal())
end

function RotationGizmos:HoverEnd(gizmo)
	self.MouseLeave:Fire(gizmo.axis, gizmo:GetPlaneNormal())
end

function createLine(gizmo, thickness)
	local Ring = gizmo.adornments[1]
	
	local Line = Instance.new("CylinderHandleAdornment", gizmo.obj)
	Line:SetAttribute("Thickness", thickness)
	Line.AlwaysOnTop = true
	Line.ZIndex = Ring.ZIndex + 2
	Line.Color3 = Ring.Color3
	Line.Transparency = 0.8
	Line.Height = Ring.InnerRadius
	Line.Radius = (Ring.Height * thickness) / 2
	Line.Adornee = gizmo.obj
	
	return Line
end

function pointLineAt(Line: CylinderHandleAdornment, Point: Vector3)
	Line.CFrame = Line.Adornee.CFrame:ToObjectSpace(CFrame.new(Line.Adornee.Position, Point)) * CFrame.new(0, 0, -Line.Height/2)
end

function RotationGizmos:DragInit()
	local gizmo = self.dragging
	gizmo._initPoint = gizmo:GetMousePositionOnPlane()
	gizmo.prevAngle = 0
	gizmo.angle = 0
	
	for i = 1, #self.gizmos do
		gizmo.sphere1_hand.Visible = false
		gizmo.sphere2_hand.Visible = false
	end
	
	-- TODO: allow to be scalable easily (redraw function OR pointLineAt recalculates size and everthin)
	--[[self.LineA = createLine(gizmo, 0.4)
	self.LineA.Name = "LineA"
	pointLineAt(self.LineA, gizmo._initPoint)
	
	self.LineB = createLine(gizmo, 1)
	self.LineB.Name = "LineB"
	self.LineB.Visible = false
	
	-- TODO: fix fill visual (roblox makes their fill radius = avg(Radius, InnerRadius))
	local Ring = gizmo.adornments[1]
	
	self.Fill = Instance.new("CylinderHandleAdornment", gizmo.obj)
	self.Fill.Name = "Fill"
	self.Fill.Color3 = Color3.new(1, 1, 1)
	self.Fill.Transparency = 0.9
	self.Fill.Angle = 0
	self.Fill.Visible = false
	self.Fill.AlwaysOnTop = true
	self.Fill.Height = Ring.Height
	self.Fill.Radius = Ring.InnerRadius
	self.Fill.ZIndex = 0
	self.Fill.Adornee = gizmo.obj
	
	table.insert(self.extraVisuals, self.LineA)
	table.insert(self.extraVisuals, self.LineB)
	table.insert(self.extraVisuals, self.Fill)]]
	
	self.MouseButton1Down:Fire(gizmo.axis, gizmo:GetPlaneNormal())
end

function RotationGizmos:DragUpdate()
	local gizmo = self.dragging
	local mousePosOnPlane = gizmo:GetMousePositionOnPlane()
	local angle = gizmo:GetAngle(mousePosOnPlane)
	
	if not self.Revolutions then
		angle = math.sign(angle) * (math.abs(angle) % TWO_PI)
		gizmo.angle = angle
	end
	
	if self.increment ~= 0 and self.increment ~= nil then
		angle = math.floor(math.abs(angle) / self.increment) * math.sign(angle) * self.increment
	end

	-- Update Fill
	--[[local fillAngle = math.abs(angle) % TWO_PI
	local lookVector = gizmo:GetPlaneNormal()
	local rightVector = (gizmo._initPoint - gizmo.obj.Position).Unit
	local upVector = rightVector:Cross(lookVector)
	
	local cfA = CFrame.fromMatrix(gizmo.obj.Position, rightVector, upVector, lookVector)
	local cfB = cfA * CFrame.Angles(0, 0, -angle)
	
	local fillRefCF =  angle < 0 and cfA or cfB
	self.Fill.CFrame = gizmo.obj.CFrame:ToObjectSpace(fillRefCF)
	self.Fill.Angle = math.deg(fillAngle)
	
	-- Update Line
	local mousePosOnPlaneWithIncrements = cfB.Position + cfB.RightVector
	pointLineAt(self.LineB, mousePosOnPlaneWithIncrements)
	self._mousePosOnPlane = mousePosOnPlaneWithIncrements
	
	-- Visibility
	if not self.LineB.Visible then 
		self.LineB.Visible = true
		self.Fill.Visible = true
	end]]

	self.MouseDrag:Fire(gizmo.axis, angle, gizmo:GetPlaneNormal())
end

function RotationGizmos:DragEnd()
	local gizmo = self.dragging
	
	for i = 1, #self.gizmos do
		gizmo.sphere1_hand.Visible = true
		gizmo.sphere2_hand.Visible = true
	end
	
	-- Cleanup
	--[[self.Fill = nil
	self.LineB = nil
	self.LineA = nil
	self._mousePosOnPlane = nil
	
	for i = #self.extraVisuals, 1, -1 do
		self.extraVisuals[i]:Destroy()
		table.remove(self.extraVisuals, i)
	end]]
	
	self.MouseButton1Up:Fire(gizmo.axis, gizmo:GetPlaneNormal())
end

return RotationGizmos
-- Copyright © 2023 Kojocrash

local super = require(script.Parent.Parent.Gizmo)
local RotationGizmo = setmetatable({}, {__index = super})
local TWO_PI = 2 * math.pi

function RotationGizmo:new(GizmoObj: BasePart, PlaneNormalDirection: string, Origin: Instance | CFrame, priority: number)
	local self = setmetatable(super:new(GizmoObj, Origin, priority), {__index = RotationGizmo})
	self._PlaneNormalDirection, self._PlaneNormalDirectionSign = super.parseDirection(PlaneNormalDirection)
	self._initPoint = Vector3.zero
	self.axis = Enum.Axis[self.obj.Name]
	self.prevAngle = 0
	self.angle = 0
	
	GizmoObj.Sphere1:SetAttribute("DefaultPos", GizmoObj.Sphere1.CFrame.p)
	GizmoObj.Sphere2:SetAttribute("DefaultPos", GizmoObj.Sphere2.CFrame.p)
	
	self.sphere1 = GizmoObj.Parent[GizmoObj.Name.."_Sphere1"]
	self.sphere1_hand = self.sphere1.Sphere
	table.insert(self.adornments, self.sphere1_hand)
	self.sphere1_hand.Parent = super.GizmosFolder
	
	self.sphere2 = GizmoObj.Parent[GizmoObj.Name.."_Sphere2"]
	self.sphere2_hand = self.sphere2.Sphere
	table.insert(self.adornments, self.sphere2_hand)
	self.sphere2_hand.Parent = super.GizmosFolder
	
	for _, adornment in ipairs(GizmoObj:GetChildren()) do
		if adornment:IsA("HandleAdornment") then
			adornment.Parent = super.GizmosFolder
			table.insert(self.adornments, adornment)
		end
	end
	
	return self
end

function RotationGizmo:GetPlaneNormal(): Vector3
	return self:GetOrigin()[self._PlaneNormalDirection] * self._PlaneNormalDirectionSign
end

function RotationGizmo:ClosestPointOnPlane(point)
	local planeOrigin = self:GetOrigin().Position
	local planeNormal = self:GetPlaneNormal()

	local distanceFromPlane = planeNormal:Dot(point - planeOrigin)
	local closestPointOnPlane = point - distanceFromPlane * planeNormal
	return closestPointOnPlane
end

function RotationGizmo:GetPointOnPlane(PointPos: Vector3, PointDirection: Vector3): Vector3
	local PointOnPlane = self:GetOrigin().Position
	local PlaneNormal = self:GetPlaneNormal()

	local miniProjection = PlaneNormal:Dot(PointDirection)
	local bigProjection = PlaneNormal:Dot(PointOnPlane - PointPos)
	local scalar = bigProjection / miniProjection
	local intersection = PointPos + PointDirection * scalar

	local inverted = PlaneNormal:Dot(PointPos - PointOnPlane) < 0
	local projection = inverted and -miniProjection or miniProjection
	
	if projection >= 0 then return self:ClosestPointOnPlane(PointPos + PointDirection * 750) end
	return intersection
end

function getDeltaAngle(x, y)
	local a = (x - y) % TWO_PI
	local b = (y - x) % TWO_PI
	return a <= b and -a or b
end

function RotationGizmo:GetAngle(mousePositionOnPlane: Vector3?)
	local angle = self:_GetAngle(mousePositionOnPlane)
	local deltaAngle = getDeltaAngle(self.prevAngle, angle)
	if deltaAngle ~= deltaAngle then deltaAngle = 0 end
	self.angle += deltaAngle
	self.prevAngle = angle
	return self.angle 
end

function RotationGizmo:_GetAngle(mousePositionOnPlane: Vector3?)
	local PointA = self._initPoint
	local PointB = mousePositionOnPlane or self:GetMousePositionOnPlane()
	local OriginPointOnPlane = self:GetOrigin().Position
	local PlaneNormal = self:GetPlaneNormal()
	
	local vA = (PointA - OriginPointOnPlane).Unit
	local vB = (PointB - OriginPointOnPlane).Unit
	local ang = math.acos(vA:Dot(vB))

	local vC = PlaneNormal:Cross(vA)
	ang = vB:Dot(vC) >= 0 and ang or TWO_PI - ang
	
	return ang
end

return RotationGizmo
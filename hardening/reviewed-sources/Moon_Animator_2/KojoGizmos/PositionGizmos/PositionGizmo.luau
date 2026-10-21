-- Copyright © 2023 Kojocrash
local super = require(script.Parent.Parent.Gizmo)
local PositionGizmo = setmetatable({}, {__index = super})

local AxisToFace = {
	["+X"] = "Right", ["+Y"] = "Top",    ["+Z"] = "Back",
	["-X"] = "Left",  ["-Y"] = "Bottom", ["-Z"] = "Front"
}

function PositionGizmo:new(GizmoObj: BasePart, Axis: string, Origin: Instance | CFrame, priority: number)
	local self = setmetatable(super:new(GizmoObj, Origin, priority), {__index = PositionGizmo})
	self.axis = Enum.NormalId[AxisToFace[self.obj.Name]]
	self._AxisDirection, self._AxisDirectionSign = super.parseDirection(Axis)
	self._initOrigin = CFrame.identity
	self._initScalar = 0
	self.axis_str = GizmoObj.Name:sub(2)
	
	return self
end

function PositionGizmo:GetDirection(): Vector3
	return self:GetOrigin()[self._AxisDirection] * self._AxisDirectionSign
end

function PositionGizmo:GetPointOnPlane(PointPos: Vector3, PointDirection: Vector3, lookDirection: Vector3?): Vector3
	local PlaneOriginCF = self:GetOrigin()
	local PlaneOrigin = PlaneOriginCF.Position
	local PlaneNormal;
	local maxDot = -7000
	
	for _, vectorDirection in ipairs({"LookVector", "RightVector", "UpVector"}) do
		if vectorDirection ~= self._AxisDirection then
			local axisVector = PlaneOriginCF[vectorDirection]
			local axisDot = axisVector:Dot(-(lookDirection or PointDirection))

			local inverted = axisVector:Dot(PointPos - PlaneOrigin) < 0
			if inverted then
				axisVector *= -1
				axisDot *= -1
			end

			if axisDot > maxDot then
				PlaneNormal = axisDot >= 0 and axisVector or -axisVector
				maxDot = axisDot
			end
			
			--[[
			local axisVector = PlaneOriginCF[vectorDirection]
			local axisDot = axisVector:Dot(-PointDirection) -- axisVector:Dot(-(PointDirection - (workspace.CurrentCamera.CFrame.Position - PlaneOrigin).Unit).Unit)
			local absDot = math.abs(axisDot)
			
			if absDot > maxDot then
				PlaneNormal = axisDot >= 0 and axisVector or -axisVector
				maxDot = absDot
			end
			]]
		end
	end

	local miniProjection = PlaneNormal:Dot(PointDirection)
	if miniProjection >= 0 then return PointPos + PointDirection * 750 end

	local bigProjection = PlaneNormal:Dot(PlaneOrigin - PointPos)
	local scalar = bigProjection / miniProjection
	local intersection = PointPos + PointDirection * scalar

	return intersection
end

function PositionGizmo:GetScalarOnAxis(mousePositionOnPlane: Vector3?)
	local intersectionOnPlane = mousePositionOnPlane or self:GetMousePositionOnPlane()
	local origin = self._initOrigin.Position
	local axis = self:GetDirection()
	
	return axis:Dot(intersectionOnPlane - origin)
end

function PositionGizmo:GetDelta(mousePositionOnPlane: Vector3?)
	return self:GetScalarOnAxis(mousePositionOnPlane) - self._initScalar
end

return PositionGizmo
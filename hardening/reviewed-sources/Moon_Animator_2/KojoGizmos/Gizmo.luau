-- Copyright © 2023 Kojocrash

local Gizmo = {}
Gizmo.__index = Gizmo

local UIS = game:GetService("UserInputService")
Gizmo.GizmosFolder = game.CoreGui:FindFirstChild("KojoGizmos") or Instance.new("Folder", game.CoreGui)
Gizmo.GizmosFolder.Name = "KojoGizmos"

function Gizmo.parseDirection(direction)
	local sign = direction:sub(1, 1) == "-" and -1 or 1
	direction = sign == 1 and direction or direction:sub(2)
	return direction, sign
end

function Gizmo:new(GizmoObj: BasePart, Origin: Instance | CFrame, priority: number)
	local self = setmetatable({}, Gizmo)
	self.obj = GizmoObj
	self.origin = Origin
	self.priority = priority or 0
	self.adornments = {}
	
	for _, adornment in ipairs(GizmoObj:GetChildren()) do
		if adornment:IsA("HandleAdornment") then
			adornment.Parent = Gizmo.GizmosFolder
			table.insert(self.adornments, adornment)
		end
	end
	
	return self
end

function Gizmo:SetOrigin(origin: Instance | CFrame)
	self.origin = origin
end

function Gizmo:GetOrigin(): CFrame
	return typeof(self.origin) == "Instance" and self.origin.CFrame or self.origin
end

function Gizmo:GetPointOnPlane(PointPos: Vector3, PointDirection: Vector3): Vector3
	-- implemented in subclasses
end

function Gizmo:GetMousePositionOnPlane(): Vector3
	local mousePos = UIS:GetMouseLocation()
	local unitRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y, 0)
	return self:GetPointOnPlane(unitRay.Origin, unitRay.Direction, workspace.CurrentCamera.CFrame.LookVector)
end

return Gizmo
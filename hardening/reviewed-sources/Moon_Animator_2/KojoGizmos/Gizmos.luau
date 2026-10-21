-- Copyright © 2023 Kojocrash

local Gizmos = {}
local Gizmo = require(script.Parent.Gizmo)
local Signal = require(script.Parent.Signal)
local UIS = game:GetService("UserInputService")
local Mouse = _G.MoonGlobal.Mouse
Gizmos.__index = Gizmos

AllGizmos = {}

-- TODO: scaling (y = m(x - x1) + y1)
function Gizmos:new(Target: BasePart | CFrame, GizmosModel: Model)
	local self = setmetatable({}, {__index = Gizmos})
	self.model = GizmosModel
	self.origin = GizmosModel.PrimaryPart
	self.gizmos = {}
	self.increment = 0
	self.dragging = nil -- TODO: if active set to false while dragging, gizmo appropriately
	self.hovering = nil
	self.target = Target
	self._hoverlist = {}
	self._active = false
	self._global = false
	self._onNextRender = nil
	
	self.TargetPart = nil
	
	self.defaultScale = 1
	self.defaultCamDist = 10
	self.defaultCamFOV = 70
	self.sensitivity = 1 		-- [0, 1]
	self.minScale = -1
	self.maxScale = -1
	self.canScaleWhileDragging = false
	self.canMoveWhileDragging = true
	
	self._scale = self.defaultScale
	self._prevCamDist = 0
	self._prevCamFov = 0
	self._camDist = 0
	
	self.MouseButton1Down = Signal.new()
	self.MouseButton1Up = Signal.new()
	self.MouseDrag = Signal.new()
	self.MouseEnter = Signal.new()
	self.MouseLeave = Signal.new()
	
	local parts = {}
	for _, v in pairs(self.model:GetDescendants()) do
		if v.Parent == self.model and v ~= self.origin then
			table.insert(parts, v)
		end
		
		local v: Instance = v
		if v:IsA("BasePart") then
			v:SetAttribute("DefaultSize", v.Size)
		elseif v:IsA("HandleAdornment") then
			v:SetAttribute("DefaultColor", v.Color3)
			v:SetAttribute("DefaultTransparency", v.Transparency)
			
			local isCylinder = v:IsA("CylinderHandleAdornment")
			local isCone = v:IsA("ConeHandleAdornment")
			
			if isCylinder or isCone then
				v:SetAttribute("DefaultHeight", v.Height)
				v:SetAttribute("DefaultRadius", v.Radius)
				
				if isCylinder then
					v:SetAttribute("DefaultInnerRadius", v.InnerRadius)
				end
			end
		end
	end
	
	table.insert(AllGizmos, self)
	return self
end

function Gizmos:RegisterGizmo(gizmo)
	for _, adornment in ipairs(gizmo.adornments) do
		if adornment.Name ~= "Circle" then
			adornment.MouseEnter:Connect(function() self:_HoverEvent(gizmo, true)  end)
			adornment.MouseLeave:Connect(function() self:_HoverEvent(gizmo, false) end)
			adornment.Visible = self._active
		end
	end
	
	table.insert(self.gizmos, gizmo)	
end

function Gizmos:Update(optional_new_target: BasePart? | CFrame?)
	if self._onNextRender then
		self._onNextRender()
		self._onNextRender = nil
	end
	
	if self.target and (self.canMoveWhileDragging or self.dragging == nil) then
		if optional_new_target then self.target = optional_new_target end
		self.model:SetPrimaryPartCFrame(self:GetTarget())
	elseif self.target == nil and self._active then
		self:SetActive(false)
	end
	
	if self.dragging and not self.canScaleWhileDragging then 
		return;
	end
	
	
	self._camDist = (workspace.CurrentCamera.CFrame.Position - self.origin.Position).Magnitude
	self._camFov = workspace.CurrentCamera.FieldOfView
	
	if self._camDist ~= self._prevCamDist or self._camFov ~= self._prevCamFov then
		local slope = self.defaultScale / self.defaultCamDist * self.sensitivity
		local scale = slope * (self._camDist - self.defaultCamDist) + self.defaultScale
		scale = self.minScale < 0 and scale or math.max(self.minScale, scale)
		scale = self.maxScale < 0 and scale or math.min(self.maxScale, scale)
		--scale = scale * (self._camFov / self.defaultCamFOV)
		
		self._scale = scale
		self._prevCamDist = self._camDist
		self._prevCamFov = self._camFov
		
		self:Redraw()
	end
end

function Gizmos:Redraw()
	-- implemented in subclasses
end

function Gizmos:_HoverEvent(gizmo, isHovering)
	if isHovering then
		local i = 1

		for n = 1, #self._hoverlist do
			if gizmo.priority >= self._hoverlist[n].priority then
				i = n
				break
			end
		end

		table.insert(self._hoverlist, i, gizmo)
	else
		local i = table.find(self._hoverlist, gizmo)
		if i then table.remove(self._hoverlist, i) end		
	end
	
	local prev = self.hovering
	self.hovering = self._hoverlist[1]
	
	-- Change Visuals to reflect hover
	if self.hovering ~= prev then
		if prev then self:HoverEnd(prev) end
		if prev and self.dragging ~= prev then
			for _, adornment in ipairs(prev.adornments) do
				if adornment.Name ~= "BoxHandle" then
					adornment.Color3 = adornment:GetAttribute("DefaultColor")
					adornment.Transparency = adornment:GetAttribute("DefaultTransparency")
				end
			end
		end

		if self.hovering then
			self:HoverInit(self.hovering)
			for _, adornment in ipairs(self.hovering.adornments) do
				if adornment.Name ~= "BoxHandle" then
					adornment.Color3 = self.hovering.obj.HoverColor.Value
					if adornment.Name == "Circle" then
						adornment.Transparency = 0.4
					else
						adornment.Transparency = self.model.HoverTransparency.Value
					end
				end
			end
		end
	end
end

function Gizmos:_UpdateHoverVisuals()
	for _, gizmo in ipairs(self.gizmos) do
		if self.hovering == gizmo then
			for _, adornment in ipairs(gizmo.adornments) do
				if adornment.Name ~= "BoxHandle" then
					adornment.Color3 = gizmo.obj.HoverColor.Value
					if adornment.Name == "Circle" then
						adornment.Transparency = 0.4
					else
						adornment.Transparency = self.model.HoverTransparency.Value
					end
				end
				
			end
		else
			for _, adornment in ipairs(gizmo.adornments) do
				if adornment.Name ~= "BoxHandle" then
					adornment.Color3 = adornment:GetAttribute("DefaultColor")
					adornment.Transparency = adornment:GetAttribute("DefaultTransparency")
				end
			end
		end
	end
end

function Gizmos:GetTarget()
	if self.target == nil then return self:SetActive(false) end
	local cf = typeof(self.target) == "CFrame" and self.target or self.target.CFrame
	cf = self._global and CFrame.new(cf.Position) or cf
	return cf
end

function Gizmos:SetActive(isActive)
	self._active = isActive == nil and true or isActive
	self.model.Parent = self._active and workspace.CurrentCamera or nil
	
	for i = 1, #self.gizmos do
		local gizmo = self.gizmos[i]
		for j = 1, #gizmo.adornments do
			gizmo.adornments[j].Visible = self._active
		end
	end
end

function Gizmos:SetGlobal(isGlobal)
	isGlobal = isGlobal == nil and true or isGlobal
	if self._global ~= isGlobal then
		self._global = isGlobal
		
		if self._active then
			self:Update()
		end
	end
end

function Gizmos:HoverInit()
	-- implemented in subclass
end

function Gizmos:HoverEnd()
	-- implemented in subclass
end

function Gizmos:DragInit()
	-- implemented in subclass
end

function Gizmos:DragUpdate()
	-- implemented in subclass
end

function Gizmos:DragEnd()
	-- implemented in subclass
end

function mouseBegan()
	for _, gizmos in ipairs(AllGizmos) do
		if gizmos._active and gizmos.dragging == nil and gizmos.hovering then
			gizmos.dragging = gizmos.hovering
			gizmos:DragInit()

			for _, h in ipairs(gizmos.gizmos) do
				if h ~= gizmos.dragging then
					for _, adornment in ipairs(h.adornments) do
						adornment.Visible = false
					end
				end
			end
		end
	end
end

function mouseEnded()
	for _, gizmos in ipairs(AllGizmos) do
		if gizmos.dragging then
			gizmos:DragEnd()
			gizmos.dragging = nil
			gizmos:_UpdateHoverVisuals()

			gizmos._onNextRender = function()
				-- Reset Visibility first to fix ZOrder
				for _, h in ipairs(gizmos.gizmos) do
					for _, adornment in ipairs(h.adornments) do
						adornment.Visible = false
					end
				end

				for _, h in ipairs(gizmos.gizmos) do
					for _, adornment in ipairs(h.adornments) do
						adornment.Visible = true
					end
				end
			end
		end
	end
end

function updateAll()
	for _, gizmos in ipairs(AllGizmos) do
		gizmos:Update()
	end
end

function mouseMoved()
	for _, gizmos in ipairs(AllGizmos) do
		if gizmos.dragging then
			gizmos:DragUpdate()
		end
	end
end

local connections = {}

function Gizmos:Activate()
	if #connections > 0 then return end
	table.insert(connections, UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseBegan()
		end
	end))
	table.insert(connections, UIS.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseEnded()
		end
	end))
	table.insert(connections, UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			mouseMoved()
		end
	end))
	table.insert(connections, workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(mouseMoved))
	table.insert(connections, workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(updateAll))
end

function Gizmos:Deactivate()
	local len = #connections
	if len == 0 then return end
	for i = len, 1, -1 do
		table.remove(connections, i):Disconnect()
	end
	mouseEnded()
end

return Gizmos

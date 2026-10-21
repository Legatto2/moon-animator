local _g = _G.MoonGlobal; _g.req("RigKeyframeTrack", "Path")
local BoneTrack = super:new()

local DEFAULT_SIZE = _g.new_ui.Handles.Bone.Size

local BoneSelect = {}

local cones_shown = true
local spheres_shown = true

local function pos_bone(bone, ini_cf, target_cf, top_part, end_bone)
	local diff = target_cf.p - ini_cf.p
	local mag, dir = (diff).magnitude, (diff).unit
	local new_dia = mag / 10
	local scaled_dia = new_dia * _g.bone_handle_size
	
	bone.ConeSmall.Radius = scaled_dia
	bone.ConeSmall.Height = new_dia
	
	bone.ConeSmallSelect.Radius = scaled_dia
	bone.ConeSmallSelect.Height = new_dia
	
	bone.ConeBig.Radius = scaled_dia
	bone.ConeBig.Height = mag - new_dia
	
	bone.ConeBigSelect.Radius = scaled_dia
	bone.ConeBigSelect.Height = mag - new_dia
	
	if top_part then
		top_part.Size = Vector3.new(scaled_dia, scaled_dia, scaled_dia)
		top_part.CFrame = target_cf
		top_part.Handle.Radius = scaled_dia / 2
		top_part.Select.Radius = scaled_dia / 2
	end
	
	bone.Size = DEFAULT_SIZE * mag * Vector3.new(_g.bone_handle_size, _g.bone_handle_size, 1)
	bone.CFrame = CFrame.new(ini_cf.p + (mag / 2) * dir, target_cf.p)
	
	if end_bone then
		local rad = scaled_dia / 2
		local height = scaled_dia * 5
		
		end_bone.ConeSmall.Radius = rad
		end_bone.ConeSmall.Height = height / 10
		
		end_bone.ConeSmallSelect.Radius = rad
		end_bone.ConeSmallSelect.Height = height / 10

		end_bone.ConeBig.Radius = rad
		end_bone.ConeBig.Height = height - (height / 10)
		
		end_bone.ConeBigSelect.Radius = rad
		end_bone.ConeBigSelect.Height = height - (height / 10)
		
		end_bone.Size = Vector3.new(scaled_dia, scaled_dia, height)
		end_bone.CFrame = CFrame.new(target_cf.p + (scaled_dia * 2 + rad) * target_cf.UpVector, target_cf.p + (mag / 2) * target_cf.UpVector)
	end
end

_g.run_serv:BindToRenderStep("MoonAnimator2_BoneSelect", 100, function()
	if _g.MouseFilter.Parent == nil then return end
	
	if cones_shown ~= _g.show_bone_cones then
		cones_shown = _g.show_bone_cones
		for _, track in pairs(BoneSelect) do
			for ind, bone in pairs(track.attached_bones) do
				bone.ConeSmall.Visible = cones_shown
				bone.ConeBig.Visible = cones_shown
			end
			if track.end_bone then
				track.end_bone.ConeSmall.Visible = cones_shown
				track.end_bone.ConeBig.Visible = cones_shown
			end
		end
	end
	if spheres_shown ~= _g.show_bone_spheres then
		spheres_shown = _g.show_bone_spheres
		for _, track in pairs(BoneSelect) do
			if track.top_part then
				track.top_part.Handle.Visible = spheres_shown
			end
		end
	end
	
	for _, track in pairs(BoneSelect) do
		local ini_cf = track.Target.TransformedWorldCFrame
		for ind, bone in pairs(track.attached_bones) do
			local get_track = track.Attached[ind]
			pos_bone(bone, ini_cf, get_track.Target.TransformedWorldCFrame, get_track.top_part, get_track.end_bone)
		end
	end
end)

function BoneTrack:new(LayerSystem, ItemObject, hierLevel, Bone)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, LayerSystem and Path:new(Bone) or nil, {"Transform", "CFrame"})
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.attached_bones = {}
		ctor.top_part = nil
		ctor.end_bone = nil
		
		ctor.ListComponent.Label.Text = Bone.Name
		
		BoneSelect[tostring(ctor)] = ctor
		BoneTrack.SetHandleHidden(ctor, false)
	end

	return ctor
end

function BoneTrack:make_onion(parent)
	if not self.GhostPart then
		self.GhostPart = {}
		if self.top_part then table.insert(self.GhostPart, _g.ghost_part(self.top_part, parent)) end
		for _, bone in pairs(self.attached_bones) do
			table.insert(self.GhostPart, _g.ghost_part(bone, parent))
		end
		if self.end_bone then table.insert(self.GhostPart, _g.ghost_part(self.end_bone, parent)) end
	end
end

function BoneTrack:clear_onion()
	if self.GhostPart then
		for _, part in pairs(self.GhostPart) do
			pcall(function() part:Destroy() end)
		end
		self.GhostPart = nil
	end
end

function BoneTrack:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	BoneSelect[tostring(self)] = nil
	if self.top_part then
		self.top_part:Destroy()
	end
	if self.end_bone then
		self.end_bone:Destroy()
	end
	for _, bone in pairs(self.attached_bones) do
		bone:Destroy()
	end
	self.attached_bones = {}
	super.Destroy(self)
end

function BoneTrack:set_select(value)
	super.set_select(self, value)
	if self.top_part then
		self.top_part.Handle.Transparency = value and 1 or 0
		self.top_part.Select.Visible = value
	end
	for _, bone in pairs(self.attached_bones) do
		bone.ConeSmall.Transparency = value and 1 or 0.2
		bone.ConeBig.Transparency = value and 1 or 0.6
		
		bone.ConeSmallSelect.Visible = value
		bone.ConeBigSelect.Visible = value
	end
	if self.end_bone then
		self.end_bone.ConeSmall.Transparency = value and 1 or 0.2
		self.end_bone.ConeBig.Transparency = value and 1 or 0.6
		
		self.end_bone.ConeSmallSelect.Visible = value
		self.end_bone.ConeBigSelect.Visible = value
	end
end

function BoneTrack:update_attached()
	local function create_bone(is_end)
		local bone = _g.new_ui.Handles.Bone:Clone()
		local top_part
		local hier = self.hierLevel + (is_end and 1 or 0)

		bone.ConeSmall.Adornee = bone
		bone.ConeSmall.ZIndex = hier
		bone.ConeSmall.Visible = cones_shown
		self:AddPaintedItem(bone.ConeSmall, {Color3 = "highlight"})
		
		bone.ConeSmallSelect.Adornee = bone
		bone.ConeSmallSelect.ZIndex = hier
		self:AddPaintedItem(bone.ConeSmallSelect, {Color3 = "second"})
		
		bone.ConeBig.Adornee = bone
		bone.ConeBig.ZIndex = hier
		bone.ConeBig.Visible = cones_shown
		self:AddPaintedItem(bone.ConeBig, {Color3 = "highlight"})
		
		bone.ConeBigSelect.Adornee = bone
		bone.ConeBigSelect.ZIndex = hier
		self:AddPaintedItem(bone.ConeBigSelect, {Color3 = "second"})
		
		if not is_end then
			top_part = _g.new_ui.Handles.Sphere:Clone()
			
			top_part.Handle.Adornee = top_part
			top_part.Handle.ZIndex = hier + 1
			top_part.Handle.Visible = spheres_shown
			self:AddPaintedItem(top_part.Handle, {Color3 = "highlight"})
			
			top_part.Select.Adornee = top_part
			top_part.Select.ZIndex = hier + 1
			self:AddPaintedItem(top_part.Select, {Color3 = "second"})
		end

		return bone, top_part
	end
	
	for _, bt in pairs(self.Attached) do
		local new_bone, top_part = create_bone()
		table.insert(self.attached_bones, new_bone)
		
		new_bone.PartClicked.Event:Connect(function() self.handle_clicked() end)
		top_part.PartClicked.Event:Connect(function() bt.handle_clicked() end)
		
		new_bone.Parent = _g.MouseFilter
		bt.top_part = top_part
		bt.top_part.Parent = _g.MouseFilter
		
		if #bt.Attached == 0 then
			bt.end_bone = create_bone(true)
			bt.end_bone.PartClicked.Event:Connect(function() bt.handle_clicked() end)
			bt.end_bone.Parent = _g.MouseFilter
		end
	end
	self:set_select(false)
end

function BoneTrack:SetHandleHidden(value, all)
	super.SetHandleHidden(self, value, all)
	if value then
		if self.top_part then
			self.top_part.Parent = nil
		end
		for _, bone in pairs(self.attached_bones) do
			bone.Parent = nil
		end
		if self.end_bone then
			self.end_bone.Parent = nil
		end
	else
		if self.top_part then
			self.top_part.Parent = _g.MouseFilter
		end
		for _, bone in pairs(self.attached_bones) do
			bone.Parent = _g.MouseFilter
		end
		if self.end_bone then
			self.end_bone.Parent = _g.MouseFilter
		end
	end

	if all then
		self.ItemObject.RigContainer:Iterate(function(track)
			if track ~= self then
				track:SetHandleHidden(not track.HandleHidden)
			end
		end, "BoneTrack")
	end
end

return BoneTrack

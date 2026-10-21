local _g = _G.MoonGlobal; _g.req("Object", "Marker", "Keyframe", "Path", "LSIContainer", "ObjectLabel", "KeyframeTrack", "MarkerTrack", "DiscreteKeyframeTrack", "RigKeyframeTrack", "MotorTrack", "BoneTrack", "Divider")
local ItemObject = super:new()

function ItemObject:new(LayerSystem, Item)
	local ctor = super:new(LayerSystem)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.LayerSystem = LayerSystem
		ctor.Path = Path:new(Item)
		ctor.Errored = false
		ctor.item_prop_list = _g.ItemTable.Items[ctor.Path.ItemType]
		ctor.PoseMap = {}
		ctor.active = false
		
		if Item.ClassName == "Model" then
			ctor.model_ref_pos = Item.PrimaryPart.CFrame
			ctor.model_color = {}
			ctor.model_transparency = {}
			ctor.model_reflectance = {}
			ctor.model_size = {}
			ctor.bone_size = {}
			ctor.joint_size = {}
			ctor.mesh_size = {}
			for _, obj in pairs(Item:GetDescendants()) do
				if obj:IsA("BasePart") then
					table.insert(ctor.model_color, {obj, obj.Color})
					table.insert(ctor.model_transparency, obj)
					table.insert(ctor.model_reflectance, {obj, obj.Reflectance, 1 - obj.Reflectance})
					table.insert(ctor.model_size, {obj, obj.Size, ctor.model_ref_pos:ToObjectSpace(obj.CFrame)})
				elseif obj.ClassName == "Decal" then
					table.insert(ctor.model_transparency, obj)	
				elseif obj.ClassName == "Bone" then
					table.insert(ctor.bone_size, {obj, obj.CFrame})
				elseif obj:IsA("JointInstance") then
					table.insert(ctor.joint_size, {obj, obj.C0, obj.C1})
				elseif obj:IsA("SpecialMesh") and obj.MeshType == Enum.MeshType.FileMesh then
					table.insert(ctor.mesh_size, {obj, obj.Scale, obj.Offset})
				end
			end
		end

		ctor.MainContainer = LSIContainer:new(ctor.Path.ItemType.."_"..ctor.Path.Item.Name)
		ctor.EnabledTracks = 0
		ctor.ObjectLabel = nil
		ctor.MarkerTrack = nil

		ctor.PropertyContainer = nil
		ctor.PropertyMap = {}
		ctor.PropertyDivider = nil

		ctor.RigContainer = nil
		ctor.RigMap = {}
		ctor.RigDivider = nil
		ctor.OnionSkin = nil

		ctor.MainContainer.ItemObject = ctor
		ctor.ObjectLabel = ObjectLabel:new(LayerSystem, ctor)
		ctor.MainContainer:Add(ctor.ObjectLabel)
		
		_g.GuiLib:AddInput(ctor.ObjectLabel.ListComponent, {down = {func = function() 
			if ctor.LayerSystem.LayerHandler.ActiveItemObject == ctor then
				game.Selection:Set({ctor.Path:GetItem()})
			else
				ctor.LayerSystem.LayerHandler:SetActiveItemObject(ctor)
			end
		end}})
		_g.GuiLib:AddInput(ctor.ObjectLabel.ListComponent.AllTracksEnable, {click = {func = function() 
			ctor.LayerSystem.LayerHandler:SetActiveItemObject(ctor) 
			ItemObject.ToggleTracks(ctor) 
		end}})
	end

	return ctor
end

local SpecTracks = {}; for _, spec in pairs(_g.spec_c:GetChildren()) do SpecTracks[spec.Name] = require(spec) end
local ActionTracks = {}; for _, act in pairs(_g.act_c:GetChildren()) do ActionTracks[act.Name] = require(act) end

function ItemObject.ItemFactory(LayerSystem, Item, PropList, MarkerTrack)
	assert(LayerSystem ~= nil, "LayerSystem is nil.")

	local NewObject = ItemObject:new(LayerSystem, Item)

	for _, prop in pairs(PropList) do
		if prop == "Rig" then
			NewObject:AddRig()
		else
			NewObject:AddProperty(prop)
		end
	end
	if MarkerTrack then
		NewObject:AddEventTrack()
	end

	return NewObject
end

function ItemObject.Deserialize(LayerSystem, itemObjData, itemObjFolder)
	local GetPath, err = Path.Deserialize(itemObjData.Path)
	if not GetPath then return false, err end
	
	local props = {}
	for _, data_folder in pairs(itemObjFolder:GetChildren()) do
		if data_folder.ClassName == "Folder" and data_folder.Name ~= "MarkerTrack" then
			table.insert(props, data_folder.Name)
		end
	end

	local ItemObj = ItemObject.ItemFactory(LayerSystem, GetPath.Item, props, itemObjFolder:FindFirstChild("MarkerTrack") ~= nil)
	local collapse = {}

	for _, data_folder in pairs(itemObjFolder:GetChildren()) do
		if data_folder.ClassName == "Folder" then
			if data_folder.Name == "Rig" and ItemObj.RigContainer then
				if data_folder:FindFirstChild("_joint") then
					for _, joint_folder in pairs(data_folder:GetChildren()) do
						if joint_folder:FindFirstChild("_hier") and ItemObj.RigMap[joint_folder._hier.Value] then
							local kf_track = ItemObj.RigMap[joint_folder._hier.Value]
							for _, kf_folder in pairs(joint_folder._keyframes:GetChildren()) do
								local kf, err = Keyframe.Deserialize(kf_folder)
								if kf then
									kf_track:AddKeyframe(kf, true)
								end
							end
							if joint_folder:FindFirstChild("_collapsed") then
								table.insert(collapse, kf_track)
							end
							if joint_folder:FindFirstChild("_highlight") then
								kf_track:SetHandleHidden(true)
							end
							if joint_folder:FindFirstChild("default") then
								kf_track.defaultValue = _g.ItemTable.GetValue(joint_folder.default)
							end
						end
					end
				else
					for _, jointFolder in pairs(data_folder:GetChildren()) do
						if jointFolder.ClassName == "Folder" then
							if ItemObj.RigMap[jointFolder.Name] then
								for _, kfFolder in pairs(jointFolder:GetChildren()) do
									local getKf, err = Keyframe.Deserialize(kfFolder)
									if getKf then
										ItemObj.RigMap[jointFolder.Name]:AddKeyframe(getKf, true)
									end
								end
								if jointFolder:FindFirstChild("_collapsed") then
									table.insert(collapse, ItemObj.RigMap[jointFolder.Name])
								end
								if jointFolder:FindFirstChild("_highlight") then
									ItemObj.RigMap[jointFolder.Name]:SetHandleHidden(true)
								end
							end
						end
					end
				end
			elseif data_folder.Name == "MarkerTrack" then
				for _, markerFolder in pairs(data_folder:GetChildren()) do
					if markerFolder.ClassName == "Folder" then

						local getMarker, err = Marker.Deserialize(markerFolder)
						if getMarker then
							ItemObj.MarkerTrack:AddMarker(getMarker, true)
						end

					end
				end
			elseif ItemObj.PropertyMap[data_folder.Name] then
				if data_folder:FindFirstChild("default") then
					ItemObj.PropertyMap[data_folder.Name].defaultValue = _g.ItemTable.GetValue(data_folder.default)
				end
				for _, kfFolder in pairs(data_folder:GetChildren()) do
					if data_folder.ClassName == "Folder" then

						local getKf, err = Keyframe.Deserialize(kfFolder)
						if getKf then
							ItemObj.PropertyMap[data_folder.Name]:AddKeyframe(getKf, true)
						end

					end
				end
			end
		end
	end
	
	if itemObjFolder:FindFirstChild("_RigContainer_collapsed") then
		table.insert(collapse, ItemObj.RigDivider)
	end
	if itemObjFolder:FindFirstChild("_PropertyContainer_collapsed") then
		table.insert(collapse, ItemObj.PropertyDivider)
	end

	LayerSystem.PlaybackHandler:BufferKeyframeTracks()
	
	return ItemObj, nil, collapse
end

function ItemObject:add_pose(frm_pos)
	local tbl = self.PoseMap[frm_pos]
	if tbl == nil then
		self.PoseMap[frm_pos] = {0, ui = nil}; tbl = self.PoseMap[frm_pos]
		tbl.frm_pos = frm_pos
		if self.active then
			self.LayerSystem.LayerHandler:add_pose(tbl)
		end
	end
	tbl[1] = tbl[1] + 1
end

function ItemObject:remove_pose(frm_pos)
	local tbl = self.PoseMap[frm_pos]
	tbl[1] = tbl[1] - 1
	if tbl[1] == 0 then
		self.PoseMap[frm_pos] = nil
		if tbl.ui then
			self.LayerSystem.LayerHandler:remove_pose(tbl)
		end
	end
end

function ItemObject:Destroy()
	if self.LayerSystem.LayerHandler.LayerContainer:Contains(self.MainContainer) then
		assert(false, "ItemObject is in a LayerHandler.")
	end
	
	if self.OnionSkin then
		self:ClearOnionSkin()
	end

	if self.RigContainer then
		self:RemoveRig()
	end

	self.MainContainer:Iterate(function(LayerSystemItem)
		if not _g.objIsType(LayerSystemItem, "ObjectLabel") then
			LayerSystemItem:Destroy()
		end
	end)
	self.ObjectLabel:Destroy()
	self.MainContainer:Destroy()
	super.Destroy(self)
end

function ItemObject:Serialize()
	local itemObjData = {}
	local itemObjFolder = Instance.new("Folder")

	if self.RigContainer and self.RigContainer.Objects[1].collapsed then
		local colVal = Instance.new("IntValue", itemObjFolder)
		colVal.Name = "_RigContainer_collapsed"
	end
	if self.PropertyContainer and self.PropertyContainer.Objects[1].collapsed then
		local colVal = Instance.new("IntValue", itemObjFolder)
		colVal.Name = "_PropertyContainer_collapsed"
	end

	itemObjData.Path = self.Path:Serialize()

	for prop, KeyframeTrack	in pairs(self.PropertyMap) do
		local kfTrack = Instance.new("Folder", itemObjFolder)
		kfTrack.Name = prop
		if KeyframeTrack.defaultValue ~= nil then
			_g.ItemTable.StoreValue("default", KeyframeTrack.defaultValue, kfTrack)
		end
		KeyframeTrack.TrackItems:Iterate(function(Keyframe)
			Keyframe:Serialize().Parent = kfTrack
		end)
	end

	if self.RigContainer then
		local rigFolder = Instance.new("Folder", itemObjFolder)
		rigFolder.Name = "Rig"

		for joint, KeyframeTrack in pairs(self.RigMap) do
			if KeyframeTrack.TrackItems.size > 0 or KeyframeTrack.HandleHidden or KeyframeTrack.collapsed then
				local joint_folder = Instance.new("Folder", rigFolder); joint_folder.Name = "_joint"

				local kf_folder = Instance.new("Folder", joint_folder); kf_folder.Name = "_keyframes"
				KeyframeTrack.TrackItems:Iterate(function(Keyframe)
					Keyframe:Serialize().Parent = kf_folder
				end)
				
				local path_val = Instance.new("StringValue", joint_folder); path_val.Name = "_hier"
				path_val.Value = joint
				
				if KeyframeTrack.defaultValue ~= nil then
					_g.ItemTable.StoreValue("default", KeyframeTrack.defaultValue, joint_folder)
				end
				if KeyframeTrack.collapsed then
					local colVal = Instance.new("IntValue", joint_folder)
					colVal.Name = "_collapsed"
				end
				if KeyframeTrack.HandleHidden then
					local lockVal = Instance.new("IntValue", joint_folder)
					lockVal.Name = "_highlight"
				end
			end
		end
	end

	if self.MarkerTrack then
		local markerFolder = Instance.new("Folder", itemObjFolder)
		markerFolder.Name = "MarkerTrack"
		self.MarkerTrack.TrackItems:Iterate(function(Marker)
			Marker:Serialize().Parent = markerFolder
		end)
	end

	return itemObjData, itemObjFolder
end

function ItemObject:ToggleTracks()
	local Disable = true

	self.MainContainer:Iterate(function(Track)
		if Track.Enabled then
			Disable = false
			return false
		end
	end, "Track")

	self.MainContainer:Iterate(function(Track)
		Track:SetEnabled(Disable, true)
	end, "Track")
end

function ItemObject:_UISetActive(value)
	self.active = value
	self.ObjectLabel:SetItemPaint(self.ObjectLabel.ListComponent.BG, {BackgroundColor3 = value and "highlight" or "second"}, _g.Themer.QUICK_TWEEN)
	self.ObjectLabel:SetItemPaint(self.ObjectLabel.ListComponent.BG.Corner, {BackgroundColor3 = value and "highlight" or "second"}, _g.Themer.QUICK_TWEEN)
end

do
	function ItemObject:AddProperty(property)
		assert(self.PropertyMap[property] == nil, property.." already exists.")

		if self.ObjectLabel.collapsed then
			self.ObjectLabel:Collapse(false)
		end
		if self.PropertyDivider and self.PropertyDivider.collapsed then
			self.PropertyDivider:Collapse(false)
		end

		if self.PropertyContainer == nil then
			self.PropertyContainer = LSIContainer:new("Properties")
			self.MainContainer:Insert(self.PropertyContainer, self.MarkerTrack and 3 or 2)

			self.PropertyDivider = Divider:new(self.LayerSystem, self, 0, "Properties")
			self.PropertyContainer:Add(self.PropertyDivider)
			self.LayerSystem.SelectionHandler:RegisterDivider(self.PropertyDivider)
		end

		local PropertyData = _g.ItemTable.Items[self.Path.ItemType][property]
		if SpecTracks[self.Path.ItemType..property.."Track"] then
			self.PropertyMap[property] = SpecTracks[self.Path.ItemType..property.."Track"]:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		elseif self.Path.ItemType == "Rig" and SpecTracks["Model"..property.."Track"] then
			self.PropertyMap[property] = SpecTracks["Model"..property.."Track"]:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		elseif ActionTracks[self.Path.ItemType..property.."Track"] then
			self.PropertyMap[property] = ActionTracks[self.Path.ItemType..property.."Track"]:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		elseif self.Path.ItemType == "Terrain" and PropertyData[1]:sub(1,3) == "MC_" then
			self.PropertyMap[property] = SpecTracks.TerrainColorTrack:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		elseif _g.ItemTable.PropertyTypes[PropertyData[2]] == _g.ItemTable.TweenFunctions.Discrete then
			self.PropertyMap[property] = DiscreteKeyframeTrack:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		else
			self.PropertyMap[property] = KeyframeTrack:new(self.LayerSystem, self, 1, self.Path, PropertyData)
		end
		
		self.PropertyMap[property]:init_values()
		self.PropertyMap[property].name = property

		local target_index = #self.PropertyContainer.Objects + 1
		local list_index = self.item_prop_list[property].index
		
		for ind, track in pairs(self.PropertyContainer.Objects) do
			if track.name and self.item_prop_list[track.name].index > list_index then
				target_index = ind
				break
			end
		end
		
		self.PropertyContainer:Insert(self.PropertyMap[property], target_index)
		self.LayerSystem.SelectionHandler:RegisterTrack(self.PropertyMap[property])
	end

	function ItemObject:RemoveProperty(property)
		assert(self.PropertyMap[property])

		if self.ObjectLabel.collapsed then
			self.ObjectLabel:Collapse(false)
		end
		if self.PropertyDivider and self.PropertyDivider.collapsed then
			self.PropertyDivider:Collapse(false)
		end

		self.PropertyContainer:Remove(self.PropertyMap[property])
		self.PropertyMap[property]:Destroy()
		self.PropertyMap[property] = nil

		if self.PropertyContainer.size == 1 then
			self.PropertyContainer:Remove(self.PropertyDivider)
			self.PropertyDivider = nil

			self.MainContainer:Remove(self.PropertyContainer)
			self.PropertyContainer = nil
		end
	end
end

function ItemObject:ApplyOnionSkin()
	if self.OnionSkin == nil then return end
	
	local check_highlight = pcall(function() local prop = self.OnionSkin.Name end)
	if not check_highlight or self.OnionSkin.Parent == nil then
		self:ClearOnionSkin()
		return
	end
	
	self.MainContainer:Iterate(function(Track)
		if Track.GhostPart then
			if _g.objIsType(Track, "MotorTrack") then
				self.LayerSystem.SelectionHandler:_SelectTrack(Track)
				Track.Target.C1 = Track.GhostPart:GetRenderCFrame():ToObjectSpace(Track.Target.Part0.CFrame) * Track.Target.C0
			end
		end
	end, "Track")
end

function ItemObject:ClearOnionSkin()
	self.MainContainer:Iterate(function(Track)
		if Track.clear_onion then
			Track:clear_onion()
		end
	end, "Track")
	
	self.OnionSkin:Destroy()
	self.OnionSkin = nil
	
	for _, tbl in pairs(self.highlight_map) do
		tbl[1].Locked = tbl[2]
	end
	self.highlight_map = nil
end

function ItemObject:ToggleOnionSkin()
	if self.OnionSkin then
		local check_highlight = pcall(function() local prop = self.OnionSkin.Name end)
		if not check_highlight or self.OnionSkin.Parent == nil then
			self:ClearOnionSkin()
		end
	end
	
	local gather_tracks = {}
	local all_enabled = true

	self.MainContainer:Iterate(function(Track)
		if not Track.HandleHidden and Track.make_onion then
			table.insert(gather_tracks, Track)
			if not Track.GhostPart then
				all_enabled = false
			end
		end
	end, "Track")
	
	if #gather_tracks > 0 then
		if self.OnionSkin == nil then
			self.OnionSkin = Instance.new("Folder"); self.OnionSkin.Name = "!MoonAnimator2OnionSkin"
			self.highlight_map = {}
			for _, part in pairs(self.Path:GetItem():GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(self.highlight_map, {part, part.Locked})
					part.Locked = true
				end
			end
		end

		if all_enabled then
			for _, track in pairs(gather_tracks) do
				track:clear_onion()
			end
		else
			for _, track in pairs(gather_tracks) do
				track:make_onion(self.OnionSkin)
			end
		end

		if #self.OnionSkin:GetChildren() == 0 then
			self:ClearOnionSkin()
		elseif self.OnionSkin.Parent == nil then
			self.OnionSkin.Parent = workspace
		end
	end
end

function ItemObject:ToggleHandles()
	local allTracks = {}
	local all_hidden = true
	self.RigContainer:Iterate(function(RigKeyframeTrack)
		table.insert(allTracks, RigKeyframeTrack)
		if RigKeyframeTrack.HandleHidden == false then
			all_hidden = false
		end
	end, "RigKeyframeTrack")
	for _, RigKeyframeTrack in pairs(allTracks) do
		RigKeyframeTrack:SetHandleHidden(not all_hidden)
	end
	self.LayerSystem.LayerHandler:SetActiveItemObject(self)
end

function ItemObject:AddRig()
	assert(self.RigContainer == nil)

	local RigHier = _g.RigHierarchy(self.Path.Item)
	if #RigHier > 0 then
		if self.ObjectLabel.collapsed then
			self.ObjectLabel:Collapse(false)
		end

		if self.RigContainer == nil then
			self.RigContainer = LSIContainer:new("Rig")
			self.MainContainer:Add(self.RigContainer)

			self.RigMap = {}

			self.RigDivider = Divider:new(self.LayerSystem, self, 0, "Rig")
			local hv = _g.new_ui.LayerSystemItem.TrackButtons.HandleVisible:Clone(); hv.Parent = self.RigDivider.ListComponent
			
			_g.GuiLib:AddInput(hv, {click = {func = function() 
				self:ToggleHandles()
			end}})
			
			self:AddPaintedItem(hv.Top.Frame, {BackgroundColor3 = "main"})
			self:AddPaintedItem(hv.Bottom.Frame, {BackgroundColor3 = "main"})
			self:AddPaintedItem(hv.Circle, {BackgroundColor3 = "main"})
			self:AddPaintedItem(hv.Circle.UIStroke, {Color = "bg"})
			
			self.RigDivider.handle_visible = hv

			self.RigContainer:Add(self.RigDivider)
			self.LayerSystem.SelectionHandler:RegisterDivider(self.RigDivider)

			if self.LayerSystem.LayerHandler.ActiveItemObject == self then
				self.LayerSystem.LayerHandler:SetActiveItemObject(nil)
				self.LayerSystem.LayerHandler:SetActiveItemObject(self)
			end
		end
		
		local jointStack = {}
		for _, tbl in pairs(RigHier) do
			table.insert(jointStack, 1, tbl)
		end

		while (#jointStack > 0) do
			local pop = table.remove(jointStack, 1)

			if self.RigMap[pop.Path] then
				self.RigContainer:Remove(self.RigMap[pop.Path])
				self.RigMap[pop.Path]:Destroy()
			end
			
			local KT
			if pop.Joint.ClassName == "Motor6D" then
				KT = MotorTrack:new(self.LayerSystem, self, pop.Depth, pop.Joint)
				KT:init_values()
			elseif pop.Joint.ClassName == "Bone" then
				KT = BoneTrack:new(self.LayerSystem, self, pop.Depth, pop.Joint)
				KT:init_values()
			end
			KT.name = pop.Path
			KT.path_tbl = _g.deepcopy(pop.path_tbl)
			pop.KT = KT

			self.RigContainer:Add(KT)
			self.RigMap[KT.name] = KT
			
			for _, tbl in pairs(pop.Attached) do
				table.insert(jointStack, 1, tbl)
			end
		end
		
		for _, tbl in pairs(RigHier) do
			table.insert(jointStack, 1, tbl)
		end
		while (#jointStack > 0) do
			local pop = table.remove(jointStack, 1)
			if pop.Parent then
				table.insert(pop.Parent.KT.Attached, pop.KT)
			end
			for _, tbl in pairs(pop.Attached) do
				table.insert(jointStack, 1, tbl)
			end
		end
		
		self.RigContainer:Iterate(function(BoneTrack)
			BoneTrack:update_attached()
		end, "BoneTrack")
		
		self.RigContainer:Iterate(function(RigKeyframeTrack)
			self.LayerSystem.SelectionHandler:RegisterTrack(RigKeyframeTrack)
		end, "RigKeyframeTrack")
	end
end

function ItemObject:RemoveRig()
	assert(self.RigContainer)

	if self.OnionSkin then
		self:ClearOnionSkin()
	end

	if self.ObjectLabel.collapsed then
		self.ObjectLabel:Collapse(false)
	end

	self.RigContainer:Iterate(function(LayerSystemItem)
		LayerSystemItem:Destroy()
	end)
	self.MainContainer:Remove(self.RigContainer)
	self.RigContainer:Destroy()

	self.RigContainer = nil
	self.RigMap = {}
	self.RigDivider = nil

	if self.LayerSystem.LayerHandler.ActiveItemObject == self then
		self.LayerSystem.LayerHandler:SetActiveItemObject(nil)
		self.LayerSystem.LayerHandler:SetActiveItemObject(self)
	end
end

function ItemObject:AddEventTrack()
	assert(self.MarkerTrack == nil)
	
	if self.ObjectLabel.collapsed then
		self.ObjectLabel:Collapse(false)
	end

	self.MarkerTrack = MarkerTrack:new(self.LayerSystem, self, 0)

	self.MainContainer:Insert(self.MarkerTrack, 2)
	self.LayerSystem.SelectionHandler:RegisterTrack(self.MarkerTrack)
end

function ItemObject:RemoveEventTrack()
	assert(self.MarkerTrack)
	
	if self.ObjectLabel.collapsed then
		self.ObjectLabel:Collapse(false)
	end

	self.MarkerTrack:Destroy()
	self.MarkerTrack = nil
end

return ItemObject

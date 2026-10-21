local _g = _G.MoonGlobal; _g.req("Object", "ItemObject", "LSIContainer", "TrackItem")
local LayerHandler = super:new()

function LayerHandler:new(LayerSystem)
	local ctor = super:new(LayerSystem)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.LayerSystem = LayerSystem
		ctor.ActiveItemObject = nil
		
		ctor.PoseFrame = LayerSystem.Scalable.Poses
		ctor.PoseTemplate = ctor.PoseFrame.Frame; ctor.PoseTemplate.Parent = nil

		ctor.MoveItemCallback = nil
		ctor.EditItemCallback = nil
		ctor.ActiveItemObjectChanged = nil

		ctor.LayerContainer = LSIContainer:new("LayerHandler: "..tostring(LayerSystem), LayerSystem.LayerScroll.Canvas, LayerSystem.Layers)
		ctor.LayerSystemItems = {}
		ctor.ItemMap = {}

		ctor.LayerContainer.LayerHandler = ctor
	end

	return ctor
end

function LayerHandler:refresh_poseframe(old_io)
	if old_io then
		for _, tbl in pairs(old_io.PoseMap) do
			self:remove_pose(tbl)
		end
	end
	if self.ActiveItemObject then
		for _, tbl in pairs(self.ActiveItemObject.PoseMap) do
			self:add_pose(tbl)
		end
	end
end

local get_ti

function LayerHandler:add_pose(tbl)
	tbl.ui = self.PoseTemplate:Clone()
	self:AddPaintedItem(tbl.ui.Frame, {BackgroundColor3 = "highlight"}); self:AddPaintedItem(tbl.ui.Frame.UIStroke, {Color = "highlight"})
	tbl.ui.Position = tbl.ui.Position + UDim2.new(tbl.frm_pos / self.LayerSystem.length, 0, 0, 0)
	tbl.ui.Parent = self.PoseFrame
	
	_g.GuiLib:AddInput(tbl.ui, {drag = {
		caller_obj = self, render_loop = true,
		func_start = function(obj, ui)
			get_ti = {}
			self.ActiveItemObject.MainContainer:Iterate(function(kf_track)
				local find = kf_track.TrackItemPositions[tbl.frm_pos]
				if find and find.frm_pos == tbl.frm_pos then
					table.insert(get_ti, find)
				end
			end, "KeyframeTrack")
			self.LayerSystem.SelectionHandler:SetTrackItemSelection(get_ti)
			get_ti[1].pose_ui = tbl.ui
			TrackItem._TrackItemDragBegin(get_ti[1], get_ti[1].UI, true)
		end, 
		func_changed = function(obj, ui, changed)  
			TrackItem._TrackItemDragChanged(get_ti[1], get_ti[1].UI, changed)
		end, 
		func_ended = function(obj, ui)  
			TrackItem._TrackItemDragEnd(get_ti[1], get_ti[1].UI)
			get_ti[1].pose_ui = nil
		end,
	}})
	
	if not self.LayerSystem.is_on_pose and self.LayerSystem.SliderFrame == tbl.frm_pos then
		self.LayerSystem:refresh_on_pose()
	end
end

function LayerHandler:remove_pose(tbl)
	if self.LayerSystem.is_on_pose and self.LayerSystem.SliderFrame == tbl.frm_pos then
		self.LayerSystem:refresh_on_pose()
	end
	self:RemovePaintedItem(tbl.ui.Frame); self:RemovePaintedItem(tbl.ui.Frame.UIStroke)
	tbl.ui:Destroy()
	tbl.ui = nil
end

function LayerHandler:SetActiveItemObject(ItemObject)
	if self.ActiveItemObject == ItemObject then return end 
	
	local old_io = self.ActiveItemObject
	if old_io then
		old_io:_UISetActive(false)
		self.ActiveItemObject = nil
	end
	if ItemObject then
		ItemObject:_UISetActive(true)
		self.ActiveItemObject = ItemObject
	end
	
	self:refresh_poseframe(old_io)
	if self.ActiveItemObjectChanged then
		self.ActiveItemObjectChanged(ItemObject)
	end
end

function LayerHandler:_SetCanvasSize(size)
	self.LayerSystem.LayerScroll:SetCanvasSize(size.Y.Offset)
	self.LayerSystem.Layers.CanvasSize = size + UDim2.new(0, -30, 0, 0)
	self.LayerSystem.Scalable.SelectionBox.CanvasSize = size
end

function LayerHandler:_GetAllLayerSystemItems()
	local count = 0
	self.LayerSystemItems = {}
	self.LayerContainer:Iterate(function(LayerSystemItem)
		count = count + 1
		table.insert(self.LayerSystemItems, LayerSystemItem)
		self.LayerSystemItems[tostring(LayerSystemItem)] = count
	end)
end

function LayerHandler:GlobalIndexOf(LSI)
	return self.LayerSystemItems[tostring(LSI)]
end

function LayerHandler:ScrollToLSI(LSI, is_rig_track)
	local item_obj = LSI.ItemObject
	if LSI.hidden then
		if is_rig_track and item_obj.RigContainer then
			local get_ind = item_obj.RigContainer:IndexOf(LSI)
			LSI = item_obj.ObjectLabel
			for i = get_ind - 1, 1, -1 do
				local track = item_obj.RigContainer.Objects[i]
				if not track.hidden then
					LSI = track
					break
				end
			end
		else
			LSI = LSI.ItemObject.ObjectLabel
		end
	end
	
	local absPos = self.LayerSystem.LayerScroll.UI.AbsolutePosition.Y
	local absSize = self.LayerSystem.LayerScroll.UI.AbsoluteSize.Y

	local lsi_pos = LSI.ListComponent.AbsolutePosition.Y

	if lsi_pos < absPos then
		self.LayerSystem.LayerScroll:SetCanvasPosition(self.LayerSystem.LayerScroll:GetCanvasPosition() - (absPos - lsi_pos))
	elseif lsi_pos + LSI.ListComponent.Size.Y.Offset > absPos + absSize then
		self.LayerSystem.LayerScroll:SetCanvasPosition(self.LayerSystem.LayerScroll:GetCanvasPosition() + (lsi_pos + LSI.ListComponent.Size.Y.Offset) - (absPos + absSize))
	end
end

do
	function LayerHandler:GetLastKeyframePosition()
		local max = 0

		self.LayerContainer:Iterate(function(Track)
			if Track.Enabled then
				local getLast = Track:GetLastTrackItem()
				getLast = getLast.frm_pos + getLast.width
				if getLast and (max == nil or max < getLast) then
					max = getLast
				end
			end
		end, "Track")

		return max
	end
end

do
	function LayerHandler:InsertItemObject(ItemObject, index)
		if ItemObject.Path:GetItem() == nil then return false end
		assert(self.ItemMap[ItemObject.Path.Item:GetDebugId(8)] == nil, "Item already exists in Layer Handler.")

		self.LayerContainer:Insert(ItemObject.MainContainer, index)
		self.ItemMap[ItemObject.Path.Item:GetDebugId(8)] = ItemObject

		_g.GuiLib:AddInput(ItemObject.ObjectLabel.ListComponent, {drag = {
			caller_obj = self, render_loop = true, pixel_delay = {"Y", 10},
			func_start = LayerHandler._GroupDragBegin, func_changed = LayerHandler._GroupDragChanged, func_ended = LayerHandler._GroupDragEnded,
		}})
		
		_g.GuiLib:AddInput(ItemObject.ObjectLabel.ListComponent.Edit, {click = {func = function() 
			if self.EditItemCallback then
				self.EditItemCallback(ItemObject)
			end
		end}})

		self:_GetAllLayerSystemItems()

		if self.ActiveItemObject == nil then
			self:SetActiveItemObject(ItemObject)
		end
	end

	function LayerHandler:AddItemObject(ItemObject)
		self:InsertItemObject(ItemObject, 1)
	end

	function LayerHandler:RemoveItemObject(ItemObject)
		if ItemObject.Path:GetItem() then
			assert(self.ItemMap[ItemObject.Path.Item:GetDebugId(8)] ~= nil, "Item does not exist in Layer Handler.")
			self.ItemMap[ItemObject.Path.Item:GetDebugId(8)] = nil
		end
		local reset_active
		if self.ActiveItemObject == ItemObject then
			reset_active = true
			self:SetActiveItemObject(nil)
		end
		self.LayerContainer:Remove(ItemObject.MainContainer)
		ItemObject:Destroy()
		self:_GetAllLayerSystemItems()
		if reset_active then
			local first_io = self.LayerContainer.Objects[1]
			self:SetActiveItemObject(first_io and first_io.ItemObject or nil)
		end
	end
end

do
	function LayerHandler:MoveItemObject(fromIndex, toIndex)
		self.LayerContainer:Move(self.LayerContainer.Objects[fromIndex], toIndex)
		self:_GetAllLayerSystemItems()
	end

	do
		local iniCanvasPosition
		local iniMousePosition

		local newPos
		local from
		local to
		local allPos

		function LayerHandler:_GroupDragBegin(DragButton, ini_pos)
			iniCanvasPosition = self.LayerSystem.LayerScroll:GetCanvasPosition()
			iniMousePosition = ini_pos.Y

			newPos = iniMousePosition
			allPos = {}

			for ind, Group in pairs(self.LayerContainer.Objects) do
				local but = Group.Objects[1].ListComponent
				if but == DragButton then
					from = ind
					to = ind
				end
				table.insert(allPos, but.AbsolutePosition.Y - self.LayerSystem.UI.AbsolutePosition.Y)
			end

			self.LayerSystem.MoveLine.Position = UDim2.new(0, 0, 0, allPos[from] + 8)
			self.LayerSystem.MoveLine.Visible = true

			self.LayerSystem:ConnectScrollBounds(true, "v")
		end
		function LayerHandler:_GroupDragChanged(DragButton, changed)
			newPos = (iniMousePosition + changed.Y) - self.LayerSystem.UI.AbsolutePosition.Y + (self.LayerSystem.LayerScroll:GetCanvasPosition() - iniCanvasPosition)

			local newTo = 1
			for i = 2, #allPos do
				if newPos >= allPos[i] and (i == #allPos or newPos <= allPos[i + 1]) then
					newTo = i
					break
				end
			end
			self.LayerSystem.MoveLine.Position = UDim2.new(0, 0, 0, allPos[newTo] - (self.LayerSystem.LayerScroll:GetCanvasPosition() - iniCanvasPosition) + 8)
			to = newTo
		end
		function LayerHandler:_GroupDragEnded(DragButton)
			if self.MoveItemCallback and from ~= to  then
				self.MoveItemCallback(from, to)
			end
			self.LayerSystem.MoveLine.Visible = false
			self.LayerSystem:ConnectScrollBounds(false)
		end
	end
end

return LayerHandler

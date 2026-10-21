local _g = _G.MoonGlobal; _g.req("Object", "ObjectGroup")
local SelectionHandler = super:new()

function SelectionHandler:new(LayerSystem)
	local ctor = super:new(LayerSystem)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.LayerSystem = LayerSystem
		ctor.TrackItemTypeMap = {}
		ctor.TrackTypeMap = {}
		
		ctor.TrackItemDCCallback = _g.BLANK_FUNC
		ctor.TrackDCCallback = _g.BLANK_FUNC
		ctor.MoveTrackItemCallback = _g.BLANK_FUNC
		
		ctor.TrackItemSelectionChanged = nil
		ctor.TrackSelectionChanged = nil

		ctor.LastShiftSelectTrack = nil
		
		ctor.SelectedTracks = ObjectGroup:new("SelectedTracks: "..tostring(LayerSystem))
		ctor.SelectedTrackItems = ObjectGroup:new("SelectedTrackItems: "..tostring(LayerSystem))
		ctor.SelectionBoxArea = LayerSystem.Scalable.SelectionBox.SelectionBoxArea

		_g.GuiLib:AddInput(ctor.SelectionBoxArea, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = SelectionHandler._SelectBoxBegin, func_changed = SelectionHandler._SelectBoxChanged, func_ended = SelectionHandler._SelectBoxEnd,
		}})
		
		ctor:AddPaintedItem(ctor.SelectionBoxArea.SelBox, {BackgroundColor3 = "highlight"})
		for _, line in pairs(ctor.SelectionBoxArea.SelBox:GetChildren()) do
			ctor:AddPaintedItem(line, {BackgroundColor3 = "highlight"})
		end
	end

	return ctor
end

function SelectionHandler:SelectAll()
	self.LayerSystem.LayerHandler.LayerContainer:Iterate(function(Track)
		Track.TrackItems:Iterate(function(TrackItem)
			self:_SelectTrackItem(TrackItem)
		end)
	end, "Track")
end

function SelectionHandler:DeselectAll()
	self:_DeselectAllTracks()
end

function SelectionHandler:GetFromToSelectionData(all_between, ti_filter)
	local TrackData = {}
	local TargetTrackItems = {}
	local PropertyType = nil

	local IniFrmPos
	local LastFrmPos

	self.SelectedTrackItems:Iterate(function(TrackItem)
		if TrackData[tostring(TrackItem.ParentTrack)] == nil then
			TrackData[tostring(TrackItem.ParentTrack)] = {Track = TrackItem.ParentTrack}
		end

		local ParentTrack = TrackItem.ParentTrack
		local targetTbl = TrackData[tostring(ParentTrack)]

		if targetTbl.From == nil or (TrackItem.frm_pos < targetTbl.From.frm_pos) then
			targetTbl.From = TrackItem
		end
		if targetTbl.To == nil or (TrackItem.frm_pos > targetTbl.To.frm_pos) then
			targetTbl.To = TrackItem
		end

		if IniFrmPos == nil or targetTbl.From.frm_pos < IniFrmPos then
			IniFrmPos = targetTbl.From.frm_pos
		end
		if LastFrmPos == nil or targetTbl.From.frm_pos + targetTbl.From.width > LastFrmPos then
			LastFrmPos = targetTbl.From.frm_pos + targetTbl.From.width
		end
		if targetTbl.To.frm_pos + targetTbl.To.width > LastFrmPos then
			LastFrmPos = targetTbl.To.frm_pos + targetTbl.To.width
		end

		if _g.objIsType(TrackItem, "Keyframe") then
			if PropertyType == nil then
				PropertyType = ParentTrack.PropertyData[2]
			elseif PropertyType and PropertyType ~= ParentTrack.PropertyData[2] then
				PropertyType = false
			end
		end
	end, ti_filter)

	for _, tbl in pairs(TrackData) do
		if tbl.From ~= tbl.To then
			table.insert(TargetTrackItems, tbl.From)
			if all_between then
				local cur = tbl.Track:GetNextTrackItem(tbl.From)
				while cur ~= tbl.To do
					table.insert(TargetTrackItems, cur)
					cur = tbl.Track:GetNextTrackItem(cur)
				end
			end
			table.insert(TargetTrackItems, tbl.To)
		else
			table.insert(TargetTrackItems, tbl.From)
		end
	end

	return TrackData, TargetTrackItems, PropertyType, IniFrmPos, LastFrmPos
end

do
	function SelectionHandler:RegisterTrackItem(TrackItem)
		if not TrackItem._reg then
			TrackItem._reg = true
			TrackItem.LayerSystem = self.LayerSystem
			TrackItem.SelectionHandler = self
			TrackItem.SelectedTrackItems = self.SelectedTrackItems
		end
	end

	do
		local iniSelAreaPos
		local iniMouseX
		local iniMouseY

		function SelectionHandler:_SelectBoxBegin(SelectBoxArea, ini_pos)
			iniSelAreaPos = self.SelectionBoxArea.AbsolutePosition
			iniMouseX = ini_pos.X - iniSelAreaPos.X
			iniMouseY = ini_pos.Y - iniSelAreaPos.Y

			self.SelectionBoxArea.SelBox.Position = UDim2.new(0, iniMouseX, 0, iniMouseY)
			self.SelectionBoxArea.SelBox.Visible = true

			self.LayerSystem:ConnectScrollBounds(true)
		end

		function SelectionHandler:_SelectBoxChanged(SelectBoxArea, changed)
			if iniSelAreaPos == nil then return end
			self.SelectionBoxArea.SelBox.Size = UDim2.new(0, changed.X + (iniSelAreaPos.X - self.SelectionBoxArea.AbsolutePosition.X), 0, changed.Y + (iniSelAreaPos.Y - self.SelectionBoxArea.AbsolutePosition.Y))
		end

		function SelectionHandler:_SelectBoxEnd(SelectBoxArea)
			if iniSelAreaPos == nil then return end
			
			local abs_pos = self.SelectionBoxArea.SelBox.AbsolutePosition

			local upper = math.min(abs_pos.Y, abs_pos.Y + self.SelectionBoxArea.SelBox.Size.Y.Offset)
			local lower = math.max(abs_pos.Y, abs_pos.Y + self.SelectionBoxArea.SelBox.Size.Y.Offset)

			local left  = math.min(abs_pos.X, abs_pos.X + self.SelectionBoxArea.SelBox.Size.X.Offset)
			local right = math.max(abs_pos.X, abs_pos.X + self.SelectionBoxArea.SelBox.Size.X.Offset)

			if lower - upper > 6 and right - left > 6 then
				local ti = {}
				self.LayerSystem.LayerHandler.LayerContainer:Iterate(function(Track)
					if not Track.hidden then
						local pos = math.floor(Track.TimelineComponent.AbsolutePosition.Y + Track.TimelineComponent.Size.Y.Offset / 2)
						if pos >= upper and pos <= lower then
							Track.TrackItems:Iterate(function(TrackItem)
								pos = math.floor(TrackItem.UI.AbsolutePosition.X + TrackItem.UI.Size.X.Offset / 2)
								if pos >= left and pos <= right then
									table.insert(ti, TrackItem)
								end
							end)
						end
					end
				end, "Track")

				if _g.Input:ControlHeld() then
					for _, TrackItem in pairs(ti) do
						self:_DeselectTrackItem(TrackItem)
					end
				else
					if not _g.Input:ShiftHeld() then
						self:_DeselectAllTracks()
					end
					for _, TrackItem in pairs(ti) do
						self:_SelectTrackItem(TrackItem)
					end
				end
			else
				if not _g.Input:ShiftHeld() then
					self:_DeselectAllTracks()
				end
			end

			self.SelectionBoxArea.SelBox.Visible = false
			self.SelectionBoxArea.SelBox.Size = UDim2.new(0, 0, 0, 0)

			self.LayerSystem:ConnectScrollBounds(false)
			iniSelAreaPos = nil
		end
	end

	do
		function SelectionHandler:SetTrackItemSelection(TrackItems)
			self:_DeselectAllTrackItems()
			for _, TrackItem in pairs(TrackItems) do
				self:_SelectTrackItem(TrackItem)
			end
		end

		function SelectionHandler:AddTrackItemSelection(TrackItems)
			for _, TrackItem in pairs(TrackItems) do
				self:_SelectTrackItem(TrackItem)
			end
		end

		function SelectionHandler:_TrackItemClicked(TrackItem)
			local was_selected = TrackItem.selected
			if not _g.Input:ShiftHeld() then
				self:_DeselectAllTrackItems()
			end

			local sel = {}
			if _g.Input:ControlHeld() then
				local slider_pos = self.LayerSystem.SliderFrame
				local sel_left = TrackItem.frm_pos < slider_pos
				TrackItem.ParentTrack.ItemObject.MainContainer:Iterate(function(KeyframeTrack)
					KeyframeTrack.TrackItems:Iterate(function(Keyframe)
						if sel_left and Keyframe.frm_pos <= slider_pos then
							table.insert(sel, Keyframe)
						elseif not sel_left and Keyframe.frm_pos >= slider_pos then
							table.insert(sel, Keyframe)
						end
					end)
				end, "KeyframeTrack")
			elseif _g.Input:AltHeld() then
				TrackItem.ParentTrack.ItemObject.MainContainer:Iterate(function(KeyframeTrack)
					if KeyframeTrack.TrackItemPositions[TrackItem.frm_pos] and KeyframeTrack.TrackItemPositions[TrackItem.frm_pos].frm_pos == TrackItem.frm_pos then
						table.insert(sel, KeyframeTrack.TrackItemPositions[TrackItem.frm_pos])
					end
				end, "KeyframeTrack")
			else
				table.insert(sel, TrackItem)
			end

			for _, TrackItem in pairs(sel) do
				if self.SelectedTrackItems:Contains(TrackItem) then
					self:_DeselectTrackItem(TrackItem)
				else
					self:_SelectTrackItem(TrackItem)
				end
			end
			if TrackItem.selected and was_selected and self.SelectedTrackItems.size == 1 then
				self.TrackItemDCCallback(TrackItem)
			end
		end

		function SelectionHandler:_SelectTrackItem(TrackItem)
			if self.SelectedTrackItems:Contains(TrackItem) then return end
			self.SelectedTrackItems:Add(TrackItem)
			if self.TrackItemTypeMap[TrackItem.type[1]] == nil then
				self.TrackItemTypeMap[TrackItem.type[1]] = 1
			else
				self.TrackItemTypeMap[TrackItem.type[1]] = self.TrackItemTypeMap[TrackItem.type[1]] + 1
			end
			TrackItem:_SetSelect(true)
			if self.TrackItemSelectionChanged then
				self.TrackItemSelectionChanged(TrackItem, true, self.SelectedTrackItems)
			end
			TrackItem.ParentTrack.TrackItemSelectCount = TrackItem.ParentTrack.TrackItemSelectCount + 1
			self:_SelectTrack(TrackItem.ParentTrack)
		end
		function SelectionHandler:_DeselectTrackItem(TrackItem)
			if not self.SelectedTrackItems:Contains(TrackItem) then return end
			self.SelectedTrackItems:Remove(TrackItem)
			if self.TrackItemTypeMap[TrackItem.type[1]] == 1 then
				self.TrackItemTypeMap[TrackItem.type[1]] = nil
			else
				self.TrackItemTypeMap[TrackItem.type[1]] = self.TrackItemTypeMap[TrackItem.type[1]] - 1
			end
			TrackItem:_SetSelect(false)
			if self.TrackItemSelectionChanged then
				self.TrackItemSelectionChanged(TrackItem, false, self.SelectedTrackItems)
			end
			TrackItem.ParentTrack.TrackItemSelectCount = TrackItem.ParentTrack.TrackItemSelectCount - 1
			if TrackItem.ParentTrack.TrackItemSelectCount == 0 then
				self:_DeselectTrack(TrackItem.ParentTrack)
			end
		end
		function SelectionHandler:_DeselectAllTrackItems()
			while self.SelectedTrackItems.size > 0 do
				self:_DeselectTrackItem(self.SelectedTrackItems.Objects[#self.SelectedTrackItems.Objects])
			end
		end
	end
end

do
	function SelectionHandler:RegisterTrack(Track)
		_g.GuiLib:AddInput(Track.ListComponent, {down = {func = function() self:_TrackClicked(Track) end}})
		
		Track.handle_clicked = function()
			self:_TrackClicked(Track)
			self.LayerSystem.LayerHandler:ScrollToLSI(Track, true)
		end
	end

	function SelectionHandler:RegisterDivider(Divider)
		assert(Divider.ParentContainer ~= nil, "Divider not parented in a LSIContainer.")
		_g.GuiLib:AddInput(Divider.ListComponent, {down = {func = function()
			local allSelect = true
			local Tracks = {}

			Divider.ParentContainer:Iterate(function(Track)
				table.insert(Tracks, Track)
				if not self.SelectedTracks:Contains(Track) then
					allSelect = false
				end
			end, "Track")

			if not allSelect then
				if not _g.Input:ControlHeld() and not _g.Input:ShiftHeld() then
					self:_DeselectAllTracks()
				end
				for _, Track in pairs(Tracks) do
					self:_SelectTrack(Track)
				end
			else
				self.TrackDCCallback()
			end
		end}})
	end

	do
		function SelectionHandler:_TrackClicked(Track)
			if self.SelectedTracks:Contains(Track) then
				if self.SelectedTracks.size == 1 then
					self.TrackDCCallback()
				else
					if not _g.Input:ControlHeld() then
						self:_DeselectAllTracks()
						self:_SelectTrack(Track)
					else
						self:_DeselectTrack(Track)
					end
				end
			else
				if _g.Input:ShiftHeld() and self.SelectedTracks.size > 0 then
					if self.LastShiftSelectTrack == nil then
						self.LastShiftSelectTrack = self.SelectedTracks.Objects[1]
					end
					local from = self.LayerSystem.LayerHandler:GlobalIndexOf(self.LastShiftSelectTrack)
					local to = self.LayerSystem.LayerHandler:GlobalIndexOf(Track)
					for i = from, to, math.sign(to - from) do
						local TargetTrack = self.LayerSystem.LayerHandler.LayerSystemItems[i]
						if _g.objIsType(TargetTrack, "Track") and TargetTrack.hidden == false then
							self:_SelectTrack(TargetTrack)
						end
					end
				else
					if not _g.Input:ControlHeld() then
						self:_DeselectAllTracks()
					end
					self:_SelectTrack(Track)
					self.LastShiftSelectTrack = Track
				end
			end
		end

		function SelectionHandler:_SelectTrack(Track)
			if self.SelectedTracks:Contains(Track) then return end
			self.SelectedTracks:Add(Track)
			
			Track:set_select(true)
			
			local TrackType = _g.objIsType(Track, "KeyframeTrack") and "KeyframeTrack" or Track.type[1]
			if self.TrackTypeMap[TrackType] == nil then
				self.TrackTypeMap[TrackType] = 1
			else
				self.TrackTypeMap[TrackType] = self.TrackTypeMap[TrackType] + 1
			end

			if self.TrackSelectionChanged then
				self.TrackSelectionChanged(Track, true, self.SelectedTracks)
			end
			if self.SelectedTracks.size == 1 then
				self.LayerSystem.LayerHandler:SetActiveItemObject(Track.ItemObject)
			end
		end
		function SelectionHandler:_DeselectTrack(Track)
			if not self.SelectedTracks:Contains(Track) then return end

			if self.LastShiftSelectTrack == Track then
				self.LastShiftSelectTrack = nil
			end

			if Track.TrackItemSelectCount > 0 then
				local SelectedTrackItemsInTrack = {}
				self.SelectedTrackItems:Iterate(function(TrackItem)
					if TrackItem.ParentTrack == Track then
						table.insert(SelectedTrackItemsInTrack, TrackItem)
					end
				end)
				if #SelectedTrackItemsInTrack > 0 then
					for _, TrackItem in pairs(SelectedTrackItemsInTrack) do
						self:_DeselectTrackItem(TrackItem)
					end
					return
				end
			end
			
			self.SelectedTracks:Remove(Track)
			Track:set_select(false)

			local TrackType = _g.objIsType(Track, "KeyframeTrack") and "KeyframeTrack" or Track.type[1]
			if self.TrackTypeMap[TrackType] == 1 then
				self.TrackTypeMap[TrackType] = nil
			else
				self.TrackTypeMap[TrackType] = self.TrackTypeMap[TrackType] - 1
			end
			
			if self.TrackSelectionChanged then
				self.TrackSelectionChanged(Track, false, self.SelectedTracks)
			end
		end
		function SelectionHandler:_DeselectAllTracks()
			while self.SelectedTracks.size > 0 do
				self:_DeselectTrack(self.SelectedTracks.Objects[#self.SelectedTracks.Objects])
			end
		end
	end
end


return SelectionHandler

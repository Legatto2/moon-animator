local _g = _G.MoonGlobal; _g.req("LayerSystemItem", "ObjectGroup")
local Track = super:new()

function Track:new(LayerSystem, ItemObject, hierLevel)
	local ui_store = _g.new_ui.LayerSystemItem.Track
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, ui_store.List:Clone(), ui_store.Timeline:Clone(), ui_store.List.Size.Y.Offset)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.name = nil
		ctor.TrackItemSelectCount = 0
		ctor.Enabled = false
		ctor.UpdateLast = false
		ctor.selected = false
		ctor.LastUpdate = 0

		ctor.TrackItems = ObjectGroup:new("TrackItems: "..tostring(ctor))
		ctor.TrackItemPositions = {}
		ctor.HandleTarget = nil
		
		_g.new_ui.LayerSystemItem.TrackButtons.TrackEnable:Clone().Parent = ctor.ListComponent
		
		_g.GuiLib:AddInput(ctor.ListComponent.TrackEnable, {click = {func = function() 
			ctor:SetEnabled(not ctor.Enabled, true)
		end}})

		ctor:AddPaintedItem(ctor.ListComponent.TrackEnable.Open.UIStroke, {Color = "main"})
		ctor:AddPaintedItem(ctor.ListComponent.TrackEnable.Closed, {BackgroundColor3 = "main"})
		ctor:AddPaintedItem(ctor.ListComponent.NotActive, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.Line, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.TimelineComponent.Middle.Start, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.TimelineComponent.Middle.Line, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.TimelineComponent.Middle.End, {BackgroundColor3 = "second"})
		
		local tween_time = _g.Themer.QUICK_TWEEN
		
		_g.GuiLib:AddInput(ctor.ListComponent.Hover, {hover = {caller_obj = ctor,
			func_start = function()
				local target_main = ctor.selected and "highlight" or "main"
				
				ctor:SetItemPaint(ctor.ListComponent.TrackEnable.Open.UIStroke, {Color = "highlight"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.TrackEnable.Closed, {BackgroundColor3 = "highlight"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.NotActive, {BackgroundColor3 = "highlight"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Line, {BackgroundColor3 = "highlight"}, tween_time)
				
				ctor:SetItemPaint(ctor.ListComponent.Label, {TextColor3 = target_main}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = target_main}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = target_main}, tween_time)
			end,
			func_ended = function()
				local target_main = ctor.selected and "highlight" or "main"
				local target_second = ctor.selected and "highlight" or "second"
				
				ctor:SetItemPaint(ctor.ListComponent.TrackEnable.Open.UIStroke, {Color = target_main}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.TrackEnable.Closed, {BackgroundColor3 = target_main}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.NotActive, {BackgroundColor3 = target_second}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Line, {BackgroundColor3 = target_second}, tween_time)
				
				ctor:SetItemPaint(ctor.ListComponent.Label, {TextColor3 = ctor.selected and "highlight" or "text"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = target_second}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = target_second}, tween_time)
			end,
		}})

		Track.SetEnabled(ctor, false)
	end

	return ctor
end

function Track:_ParentTrackItem(TrackItem)
	assert(self.LayerSystem ~= nil, "No LayerSystem found.")
	assert(TrackItem.ParentTrack == nil, "TrackItem already parented to a Track.")

	TrackItem.ParentTrack = self
	TrackItem:_Size()
	TrackItem:_Position()
	TrackItem.UI.Parent = self.TimelineComponent
	self.LayerSystem.SelectionHandler:RegisterTrackItem(TrackItem)
	
	TrackItem.UI.Visible = true
end

function Track:_Update(frm_pos)
	assert(false, "_Update not implemented.")
end

function Track:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	if self.HandleTarget then
		self.HandleTarget(nil)
	end
	self:SetEnabled(false, true)
	self.TrackItems:Iterate(function(TI)
		TI:Destroy()
	end)
	self.TrackItems:Destroy()
	super.Destroy(self)
end

function Track:set_select(value)
	self.selected = value
	
	local target_color = self.selected and "highlight" or "second"
	
	self:SetItemPaint(self.ListComponent.Label, {TextColor3 = value and "highlight" or "text"})
	self:SetItemPaint(self.ListComponent.TrackEnable.Open.UIStroke, {Color = value and "highlight" or "main"})
	self:SetItemPaint(self.ListComponent.TrackEnable.Closed, {BackgroundColor3 = value and "highlight" or "main"})
	self:SetItemPaint(self.ListComponent.NotActive, {BackgroundColor3 = target_color})
	self:SetItemPaint(self.ListComponent.Line, {BackgroundColor3 = target_color})
	self:SetItemPaint(self.ListComponent.Arrow.ArrowDown, {TextColor3 = target_color})
	self:SetItemPaint(self.ListComponent.Arrow.ArrowRight, {TextColor3 = target_color})
	self:SetItemPaint(self.TimelineComponent.Middle.Start, {BackgroundColor3 = target_color})
	self:SetItemPaint(self.TimelineComponent.Middle.Line, {BackgroundColor3 = target_color})
	self:SetItemPaint(self.TimelineComponent.Middle.End, {BackgroundColor3 = target_color})
end

function Track:SetEnabled(value, inputted)
	if value and self.TrackItems.size == 0 then
		value = false
	end

	if value ~= self.Enabled then
		self.ItemObject.EnabledTracks = value and (self.ItemObject.EnabledTracks + 1) or (self.ItemObject.EnabledTracks - 1)
	end

	self.Enabled = value
	self.ListComponent.TrackEnable.Closed.Visible = value
	self.ListComponent.TrackEnable.Open.Visible = not value
	self.ListComponent.NotActive.Visible = not value
	self.ListComponent.Line.Visible = value
	self.TimelineComponent.Middle.Line.Visible = value
	
	self.TrackItems:Iterate(function(TrackItem)
		if TrackItem.width > 0 then
			TrackItem.UI.BG_Middle.Line.Visible = value
		end
	end)
	
	local item_enabled = self.ItemObject.EnabledTracks > 0

	self.ItemObject.ObjectLabel.ListComponent.AllTracksEnable.Closed.Visible = item_enabled
	self.ItemObject.ObjectLabel.ListComponent.AllTracksEnable.Open.Visible = not item_enabled
	
	if self.ItemObject.ObjectLabel.icon_highlight then
		for _, obj in pairs(self.ItemObject.ObjectLabel.icon_highlight) do
			self:SetItemPaint(obj, {BackgroundColor3 = item_enabled and "highlight" or "second"})
		end
	end
end

function Track:IsPosTaken(fromPos, toPos)
	for p = fromPos, toPos do
		if self.TrackItemPositions[p] then
			return true
		end
	end
	return false
end

function Track:MoveTrackItem(TrackItem, frm_pos)
	self:RemoveTrackItem(TrackItem)
	TrackItem.frm_pos = frm_pos
	self:AddTrackItem(TrackItem)
	return TrackItem
end

function Track:AddTrackItem(TrackItem, overwrite)
	assert(TrackItem.ParentTrack == nil, "TrackItem already is parented to a Track.")

	if not overwrite and self.TrackItemPositions[TrackItem.frm_pos] ~= nil then 
		assert(false, "Keyframe already exists at frame "..tostring(TrackItem.frm_pos)..".")
	elseif overwrite and self.TrackItemPositions[TrackItem.frm_pos] ~= nil then
		self.TrackItemPositions[TrackItem.frm_pos]:Destroy()
	end

	local index = nil
	local objs = self.TrackItems.Objects
	local size = #objs
	local frames = TrackItem.frm_pos

	if size == 0 or frames <= objs[1].frm_pos then 
		index = 1
	elseif frames >= objs[size].frm_pos then 
		index = size + 1
	else
		for i = 2, size, 1 do
			if objs[i].frm_pos > frames then
				index = i
				break
			end
		end
	end

	for i = TrackItem.frm_pos, TrackItem.frm_pos + TrackItem.width, 1 do
		if self.TrackItemPositions[i] ~= nil then
			self.TrackItemPositions[i]:Destroy()
			if i <= index then
				index = index - 1
			end
		end
		self.TrackItemPositions[i] = TrackItem
	end

	self.TrackItems:Insert(TrackItem, index)
	self:_ParentTrackItem(TrackItem)
	self:SetEnabled(true)

	return TrackItem
end

function Track:RemoveTrackItem(TrackItem)
	assert(TrackItem.ParentTrack == self, "TrackItem does not exist in Track.")

	for i = TrackItem.frm_pos, TrackItem.frm_pos + TrackItem.width, 1 do
		self.TrackItemPositions[i] = nil
	end
	self.TrackItems:Remove(TrackItem)

	TrackItem.UI.Parent = nil
	TrackItem.ParentTrack = nil

	if self.TrackItems.size == 0 then
		self:SetEnabled(false, true)
	end
	return TrackItem
end

function Track:from_frame(frame)
	local found = -1
	local found_next = -1
	for num, _ in pairs(self.TrackItemPositions) do
		if (found == -1 or num > found) and num < frame then
			found = num
		end
		if (found_next == -1 or num < found_next) and num >= frame then
			found_next = num
		end
	end

	if found ~= -1 then
		return self.TrackItemPositions[found]
	elseif found_next ~= -1 then
		return self.TrackItemPositions[found_next]
	end
end

function Track:GetPreviousTrackItem(TrackItem)
	local ind = self.TrackItems:IndexOf(TrackItem)
	if ind == nil or ind == 1 then return nil end
	return self.TrackItems.Objects[ind - 1]
end

function Track:GetNextTrackItem(TrackItem)
	local ind = self.TrackItems:IndexOf(TrackItem)
	if ind == nil or ind == self.TrackItems.size then return nil end
	return self.TrackItems.Objects[ind + 1]
end

function Track:GetLastTrackItem()
	if self.TrackItems.size == 0 then return nil end
	return self.TrackItems.Objects[self.TrackItems.size]
end

function Track:GetLastFramePosition()
	if self.TrackItems.size == 0 then return 0 end
	return self.TrackItems.Objects[self.TrackItems.size].frm_pos + self.TrackItems.Objects[self.TrackItems.size].width
end

return Track

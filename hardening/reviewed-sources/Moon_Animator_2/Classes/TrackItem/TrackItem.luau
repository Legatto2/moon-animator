local _g = _G.MoonGlobal; _g.req("Object")

local TrackItem = super:new()
function TrackItem:new(UI, width, frm_pos)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor.UI = UI
		ctor.ParentTrack = nil
		ctor.width = width
		ctor.frm_pos = frm_pos
		ctor.selected = false
		
		ctor.LayerSystem = nil
		ctor.SelectionHandler = nil
		ctor.SelectedTrackItems = nil
		
		local overlay = Instance.new("ImageLabel")
		overlay.BackgroundTransparency = 1
		overlay.Name = "Click"
		overlay.Parent = ctor.UI
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.ZIndex = ctor.UI.ZIndex + 1
		overlay.Image = ctor.UI.Image
		overlay.ImageColor3 = Color3.new(0, 0, 0)
		overlay.ImageTransparency = 1
	end

	return ctor
end

do
	local iniFrmPos = nil
	local oldPos = nil
	local range
	local has_width

	local needs_click = false

	function TrackItem:init_ti_drag()
		if not self.SelectedTrackItems:Contains(self) then
			self.SelectionHandler:_DeselectAllTrackItems()
			self.SelectionHandler:_SelectTrackItem(self)
		end
		
		local front = self.UI.Parent
		self.UI.Parent = nil; self.UI.Parent = front

		iniFrmPos = self.frm_pos
		oldPos = iniFrmPos

		range = {math.huge, -math.huge}
		self.SelectedTrackItems:Iterate(function(self)
			if self.frm_pos < range[1] then
				range[1] = self.frm_pos
			end
			if self.frm_pos + self.width > range[2] then
				range[2] = self.frm_pos + self.width
			end
		end)
		range[1] = -range[1]
		range[2] = self.LayerSystem.length - range[2]

		has_width = self.width > 0 and self.width or nil

		self.LayerSystem:SetupTickFrameCoords(self.frm_pos, 0)
		self.LayerSystem:MoveTickActive(true, iniFrmPos, has_width)
		self.LayerSystem:ConnectScrollBounds(true, "h")
	end

	function TrackItem:_TrackItemDragBegin(ui, no_click)
		self.LayerSystem.PlaybackHandler:Stop()
		if no_click ~= true then
			if _g.Input:ControlHeld() or self.SelectedTrackItems:Contains(self) then
				needs_click = true
			else
				self.SelectionHandler:_TrackItemClicked(self)
				needs_click = false
			end
		else
			needs_click = false
		end
	end

	function TrackItem:_TrackItemDragChanged(ui, changed)
		if iniFrmPos == nil then
			if math.abs(changed.X) >= 4 then
				self:init_ti_drag()
			end
		else
			local newPos = self.LayerSystem:GetFrameAtMousePosition(0)
			if newPos ~= oldPos then
				local delta = math.clamp(newPos - iniFrmPos, range[1], range[2])
				for _, TI in pairs(self.SelectedTrackItems.Objects) do
					TI:_Position(TI.frm_pos + delta)
				end
				self.LayerSystem:UpdateMoveTick(iniFrmPos + delta, has_width)
				oldPos = newPos
			end
		end
	end

	function TrackItem:_TrackItemDragEnd(ui)
		if iniFrmPos == nil then
			if needs_click then
				self.SelectionHandler:_TrackItemClicked(self)
			end
		else
			local delta = math.clamp(oldPos - iniFrmPos, range[1], range[2])

			if delta ~= 0 then
				self.SelectionHandler.MoveTrackItemCallback(self.SelectedTrackItems.Objects, delta)
			end

			self.LayerSystem:MoveTickActive(false)
			self.LayerSystem:ConnectScrollBounds(false)
			iniFrmPos = nil
		end
	end
end

function TrackItem:Destroy()
	if self.ParentTrack then
		self.ParentTrack:RemoveTrackItem(self)
	end
	super.Destroy(self)
end

function TrackItem:_SetSelect(value)
	self.selected = value
end

function TrackItem:_Position(frm_pos)
	if frm_pos == nil then frm_pos = self.frm_pos end
	local per = frm_pos / self.ParentTrack.LayerSystem.length
	self.UI.Position = self.UI.Position - UDim2.new(self.UI.Position.X.Scale - per, 0, 0, 0)
	if self.pose_ui then
		self.pose_ui.Position = self.pose_ui.Position - UDim2.new(self.pose_ui.Position.X.Scale - per, 0, 0, 0)
	end
end

function TrackItem:_Size(width)
	if width == nil then width = self.width end
	self.UI.Size = self.UI.Size - UDim2.new(self.UI.Size.X.Scale - width / self.ParentTrack.LayerSystem.length)
end

return TrackItem

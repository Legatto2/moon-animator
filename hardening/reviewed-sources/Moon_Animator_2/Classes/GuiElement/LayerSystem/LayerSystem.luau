local _g = _G.MoonGlobal; _g.req("GuiElement", "Slider", "MoonScroll", "ItemObject", "Path", "LayerHandler", "PlaybackHandler", "SelectionHandler")
local LayerSystem = super:new()

function LayerSystem:new(UI)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		do
			ctor.length = _g.DEFAULT_FRAMES
			ctor.Zoom = ctor.length
			ctor.ScrollFrame = 0
			ctor.SliderFrame = 0
			ctor.KeyframeCount = 0
			ctor.FPS = _g.DEFAULT_FPS
			ctor.ExportPriority = "Action"
			ctor.LayerHandler = nil
			ctor.PlaybackHandler = nil
			ctor.SelectionHandler = nil
			ctor.CurrentFile = nil
			ctor.CameraReferencePart = nil
			ctor.LayerScroll = MoonScroll:new(ctor.UI.LayerList.Layers, 21)
			ctor.NoFile = UI.Parent.NoFile
			ctor.export_hook = _g.BLANK_FUNC
			ctor.AddPoseCallback = _g.BLANK_FUNC
			ctor.AddMoreCallback = _g.BLANK_FUNC
			ctor.NudgeTICallback = _g.BLANK_FUNC
			ctor.is_on_pose = false
			ctor.split_size = 3

			ctor.FileCreated = nil

			ctor.LayerList = ctor.UI.LayerList; ctor.MoveLine = ctor.UI.MoveLine; ctor.Timeline = ctor.UI.Timeline; ctor.ScrollBar = ctor.UI.Timeline.BottomSec.ScrollBar; ctor.Scalable = ctor.UI.Timeline.Frame.FrameRegion.Scalable
			ctor.Layers = ctor.Scalable.LayerFrame.Layers
			ctor.TimeTickTemplate = ctor.Scalable.TickFrame.Tick; ctor.TimeTickTemplate.Parent = nil
			ctor.TimeGuideTemplate = ctor.Scalable.Guides.Guide; ctor.TimeGuideTemplate.Parent = nil
			
			ctor.MoveTick = ctor.Scalable.MoveTick; ctor.MoveTick.Visible = false
			ctor.OffsetTick = ctor.Scalable.OffsetTick; ctor.OffsetTick.Visible = false
			
			ctor.AddPose = ctor.Scalable.Line.AddPose
			
			ctor:AddPaintedItem(ctor.MoveTick, {TextColor3 = "main"})
			ctor:AddPaintedItem(ctor.OffsetTick, {TextColor3 = "main"})
			
			ctor.ZoomSlider = Slider:new(
				ctor.UI.LayerList.BottomSec.Zoom.Slider,
				0, false, 
				function(val) LayerSystem.SetZoomPercentage(ctor, val, true) end, 
				function(val) LayerSystem.SetZoomFrames(ctor, ctor.Zoom) end
			)
			ctor.LayerHandler = LayerHandler:new(ctor)
			ctor.PlaybackHandler = PlaybackHandler:new(ctor)
			ctor.SelectionHandler = SelectionHandler:new(ctor)
			
			_g.GuiLib:AddInput(ctor.LayerList.BottomSec.Zoom, {scroll = {
				func = function(dir)
					if not _g.Input:ModifierHeld() then
						LayerSystem.SetZoomByFrames(ctor, -dir * (ctor.Zoom / 10))
					end
				end,
			}})
			
			_g.GuiLib:AddInput(ctor.ScrollBar, {scroll = {
				func = function(dir)
					if not _g.Input:ModifierHeld() then
						LayerSystem.SetScrollByFrames(ctor, dir)
					end
				end,
			}})
			
			_g.GuiLib:AddInput(ctor.Scalable.Line.Drag, {drag = {
				caller_obj = ctor, render_loop = true,
				func_start = LayerSystem._SliderDragBegin, func_changed = LayerSystem._SliderDragChanged, func_ended = LayerSystem._SliderDragEnded,
			}})
			_g.GuiLib:AddInput(ctor.Timeline.TopDecor, {drag = {
				caller_obj = ctor, render_loop = true,
				func_start = LayerSystem._TickFrameDragBegin, func_changed = LayerSystem._TickFrameDragChanged, func_ended = LayerSystem._SliderDragEnded,
			}})
			
			_g.GuiLib:AddInput(ctor.ScrollBar.Bar, {drag = {
				caller_obj = ctor,
				func_start = LayerSystem._ScrollDragBegin, func_changed = LayerSystem._ScrollDragChanged,
			}})
			_g.GuiLib:AddInput(ctor.ScrollBar.Bar.Start, {drag = {
				caller_obj = ctor,
				func_start = LayerSystem._MinimapZoomBegin, func_changed = LayerSystem._ZoomLeftChanged,
			}})
			_g.GuiLib:AddInput(ctor.ScrollBar.Bar.End, {drag = {
				caller_obj = ctor,
				func_start = LayerSystem._MinimapZoomBegin, func_changed = LayerSystem._ZoomRightChanged,
			}})
			
			_g.GuiLib:AddInput(ctor.Timeline, {drag = {
				caller_obj = ctor, render_loop = true, mouse_but = Enum.UserInputType.MouseButton3,
				func_start = LayerSystem._PanBegin, func_changed = LayerSystem._PanChanged, func_ended = LayerSystem._PanEnd
			}})
			_g.GuiLib:AddInput(ctor.LayerList, {drag = {
				caller_obj = ctor, render_loop = true, mouse_but = Enum.UserInputType.MouseButton3,
				func_start = LayerSystem._PanBegin, func_changed = LayerSystem._PanChanged, func_ended = LayerSystem._PanEnd
			}})
			
			_g.GuiLib:AddInput(ctor.LayerList.TopDecor.Resize, {drag = {
				caller_obj = ctor,
				func_start = LayerSystem._ResizeDragBegin, func_changed = LayerSystem._ResizeDragChanged,
			}})

			LayerSystem.SetTimelineLength(ctor, ctor.length)
		end
		
		do
			ctor._step = _g.run_serv.RenderStepped
			ctor._scrollBoundsEvent = nil
			ctor._scrollBoundsFrm = 0
			ctor._scrollBoundsRes = 1
			ctor._scrollBoundsDir = nil
			ctor._scrollBoundsY = 0
			ctor._scrollBoundsYmax = 0

			ctor._scrollBounds = function(step)
				local scalable_pos = ctor.Scalable.Parent.AbsolutePosition.X
				local scalable_size = ctor.Scalable.Parent.AbsoluteSize.X

				local timeline_pos = ctor.Layers.AbsolutePosition.Y
				local timeline_size = ctor.Layers.AbsoluteSize.Y

				if ctor._scrollBoundsDir == nil or ctor._scrollBoundsDir == "h" then
					if _g.Mouse.X < scalable_pos then
						local dist = scalable_pos - _g.Mouse.X

						ctor._scrollBoundsFrm = math.clamp(ctor._scrollBoundsFrm - ((400 + 5 * dist) / ctor._scrollBoundsRes) * step, 0, ctor.length - ctor.Zoom)
						LayerSystem.SetScrollFrame(ctor, ctor._scrollBoundsFrm + 0.5)
					elseif _g.Mouse.X > scalable_pos + scalable_size then
						local dist = _g.Mouse.X - (scalable_pos + scalable_size)

						ctor._scrollBoundsFrm = math.clamp(ctor._scrollBoundsFrm + ((400 + 5 * dist) / ctor._scrollBoundsRes) * step, 0, ctor.length - ctor.Zoom)
						LayerSystem.SetScrollFrame(ctor, ctor._scrollBoundsFrm + 0.5)
					end
				end
				
				if ctor._scrollBoundsDir == nil or ctor._scrollBoundsDir == "v" then
					if _g.Mouse.Y < timeline_pos then
						local dist = timeline_pos - _g.Mouse.Y
						ctor._scrollBoundsY = math.clamp(ctor._scrollBoundsY - (200 + 5 * dist) * step, 0, ctor._scrollBoundsYmax)
						ctor.LayerScroll:SetCanvasPosition(ctor._scrollBoundsY)
					elseif _g.Mouse.Y > timeline_pos + timeline_size then
						local dist = _g.Mouse.Y - (timeline_pos + timeline_size)
						ctor._scrollBoundsY = math.clamp(ctor._scrollBoundsY + (200 + 5 * dist) * step, 0, ctor._scrollBoundsYmax)
						ctor.LayerScroll:SetCanvasPosition(ctor._scrollBoundsY)
					end
				end
			end
			
			_g.GuiLib:AddInput(ctor.Timeline, {scroll = {
				func = function(dir)
					if _g.Input:AltHeld() then
						LayerSystem.SetSliderByFrames(ctor, -dir)
					elseif _g.Input:ShiftHeld() then
						ctor.LayerScroll:SetLineNumber(ctor.LayerScroll:GetLineNumber() + -dir)
					elseif _g.Input:ControlHeld() then
						ctor.NudgeTICallback(dir)
					else
						local Zoom_amount = -dir * (ctor.Zoom / 10)
						if Zoom_amount == 0 then Zoom_amount = -dir end 
						LayerSystem.SetZoomByFrames(ctor, Zoom_amount, false, {ToMouse = true})
					end
				end,
			}})

			ctor.LayerScroll.Canvas:GetPropertyChangedSignal("Position"):Connect(function()
				local tlPos = Vector2.new(ctor.Layers.CanvasPosition.X, ctor.LayerScroll:GetCanvasPosition())
				ctor.Layers.CanvasPosition = tlPos
				ctor.Scalable.SelectionBox.CanvasPosition = tlPos
			end)
			
			_g.GuiLib:AddInput(ctor.ZoomSlider.UI.Button, {down = {func = function() ctor.PlaybackHandler:Stop() end}})
		end

		do
			ctor.OpenSettings = UI.LayerList.TopDecor.OpenSettings
			ctor.open_frames = {}
			ctor.open_hover = {}
			
			local t = 2 * _g.Themer.QUICK_TWEEN
			
			for _, frame in pairs(ctor.OpenSettings:GetDescendants()) do
				if frame.Name == "Frame" then
					if frame.Parent.Name == "Hover" then
						ctor:AddPaintedItem(frame, {BackgroundColor3 = "text"})
						table.insert(ctor.open_hover, frame)
					else
						ctor:AddPaintedItem(frame, {BackgroundColor3 = "main"})
						table.insert(ctor.open_frames, frame)
					end
				end
			end
			_g.GuiLib:AddInput(ctor.OpenSettings, {hover = {caller_obj = ctor,
				func_start = function()
					for _, frame in pairs(ctor.open_hover) do
						_g.Themer:QuickTween(frame, t, {BackgroundTransparency = 0})
					end
					for _, frame in pairs(ctor.open_frames) do
						_g.Themer:QuickTween(frame, t, {BackgroundTransparency = 1})
					end
				end,
				func_ended = function()
					for _, frame in pairs(ctor.open_hover) do
						_g.Themer:QuickTween(frame, t, {BackgroundTransparency = 1})
					end
					for _, frame in pairs(ctor.open_frames) do
						_g.Themer:QuickTween(frame, t, {BackgroundTransparency = 0})
					end
				end,
			}})
			
			_g.GuiLib:AddInput(ctor.AddPose.Input, {down = {
				func = function() ctor.AddPoseCallback() end,
			}})
			
			_g.GuiLib:AddInput(ctor.Scalable.Poses.More, {down = {
				func = function() ctor.AddMoreCallback() end,
			}})
			
			ctor.LoopToggle = UI.LayerList.TopDecor.LoopToggle
			
			ctor:AddPaintedItem(ctor.LoopToggle.Bottom.Frame.UIStroke, {Color = "second"})
			ctor:AddPaintedItem(ctor.LoopToggle.Top.Frame.UIStroke, {Color = "second"})
			ctor:AddPaintedItem(ctor.LoopToggle.BottomCircle, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(ctor.LoopToggle.TopCircle, {BackgroundColor3 = "second"})
			
			ctor:AddPaintedItem(ctor.LoopToggle.Hover.Bottom.Frame.UIStroke, {Color = "text"})
			ctor:AddPaintedItem(ctor.LoopToggle.Hover.Top.Frame.UIStroke, {Color = "text"})
			ctor:AddPaintedItem(ctor.LoopToggle.Hover.BottomCircle, {BackgroundColor3 = "text"})
			ctor:AddPaintedItem(ctor.LoopToggle.Hover.TopCircle, {BackgroundColor3 = "text"})
			
			ctor:AddPaintedItem(ctor.LoopToggle.Off, {TextColor3 = "main"})
			ctor:AddPaintedItem(ctor.LoopToggle.OffHover, {TextColor3 = "text"})
			
			_g.GuiLib:AddInput(ctor.LoopToggle, {hover = {caller_obj = ctor,
				func_start = function()
					_g.Themer:QuickTween(ctor.LoopToggle.Bottom.Frame.UIStroke, t, {Transparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.Top.Frame.UIStroke, t, {Transparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.BottomCircle, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.TopCircle, t, {BackgroundTransparency = 1})
					
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.Bottom.Frame.UIStroke, t, {Transparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.Top.Frame.UIStroke, t, {Transparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.BottomCircle, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.TopCircle, t, {BackgroundTransparency = 0})
					
					_g.Themer:QuickTween(ctor.LoopToggle.OffHover, t, {TextTransparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.Off, t, {TextTransparency = 1})
				end,
				func_ended = function()
					_g.Themer:QuickTween(ctor.LoopToggle.Bottom.Frame.UIStroke, t, {Transparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.Top.Frame.UIStroke, t, {Transparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.BottomCircle, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.LoopToggle.TopCircle, t, {BackgroundTransparency = 0})
					
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.Bottom.Frame.UIStroke, t, {Transparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.Top.Frame.UIStroke, t, {Transparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.BottomCircle, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.Hover.TopCircle, t, {BackgroundTransparency = 1})
					
					_g.Themer:QuickTween(ctor.LoopToggle.OffHover, t, {TextTransparency = 1})
					_g.Themer:QuickTween(ctor.LoopToggle.Off, t, {TextTransparency = 0})
				end,
			}})
			

			ctor.AddItemButton = UI.LayerList.TopDecor.AddItem
			ctor:AddPaintedItem(ctor.AddItemButton.H1, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.AddItemButton.H2, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.AddItemButton.V, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.AddItemButton.Hover.H1, {BackgroundColor3 = "text"})
			ctor:AddPaintedItem(ctor.AddItemButton.Hover.H2, {BackgroundColor3 = "text"})
			ctor:AddPaintedItem(ctor.AddItemButton.Hover.V, {BackgroundColor3 = "text"})
			_g.GuiLib:AddInput(ctor.AddItemButton, {hover = {caller_obj = ctor,
				func_start = function()
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.H1, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.H2, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.V, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.AddItemButton.H1, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.AddItemButton.H2, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.AddItemButton.V, t, {BackgroundTransparency = 1})
				end,
				func_ended = function()
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.H1, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.H2, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.AddItemButton.Hover.V, t, {BackgroundTransparency = 1})
					_g.Themer:QuickTween(ctor.AddItemButton.H1, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.AddItemButton.H2, t, {BackgroundTransparency = 0})
					_g.Themer:QuickTween(ctor.AddItemButton.V, t, {BackgroundTransparency = 0})
				end,
			}})

			ctor:AddPaintedItem(ctor.ScrollBar.Bar, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.ScrollBar.Bar.Start.Frame, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(ctor.ScrollBar.Bar.End.Frame, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(ctor.ScrollBar.Past.Frame, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.ScrollBar.Future.Frame, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.ScrollBar.Time.ActLine, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.MoveLine, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.Scalable.Line.ActLine, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.Scalable.Line.Drag, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.AddPose.Frame, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.AddPose.Frame.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.Resize.Frame, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.CurrentTime.Frame, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.CurrentTime.FrameDisplay.Label, {TextColor3 = "main"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.CurrentTime.Time.Label, {TextColor3 = "main"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.Stats.Frame, {BackgroundColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.Stats.FPS.Label, {TextColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.LayerList.TopDecor.Stats.KeyframeCount.Label, {TextColor3 = "highlight"})
			ctor:AddPaintedItem(ctor.Scalable.Poses.More.Frame, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.Scalable.Poses.More.Frame.UIStroke, {Color = "main"})
		end
		
		LayerSystem.Reset(ctor)
	end

	return ctor
end

function LayerSystem:update_kf_count(count)
	self.LayerList.TopDecor.Stats.KeyframeCount.Label.Text = tostring(count).." KEYFRAME"..(count == 1 and "" or "S")
end

do
	function LayerSystem:Reset()
		self.PlaybackHandler:Stop()
		self.SelectionHandler:DeselectAll()
		
		if self.CurrentFile and self.RigOnlyMode then
			self.CurrentFile:Destroy()
		end
		
		self.RigOnlyMode = false
		self.CameraReferencePart = nil
		self.CurrentFile = nil
		self.FileCreated = nil
		self.UI.Visible = false
		self.NoFile.Visible = true
		
		_g.time_offset = 0

		self:SetFPS(_g.DEFAULT_FPS)
		self:SetSliderFrame(0)
		self.PlaybackHandler:SetLoop(false)

		self.PlaybackHandler.ActiveTracks = {}
		self.PlaybackHandler.InvalidKeyframeTracks = {}

		local ItemObjects = {}

		for _, Container in pairs(self.LayerHandler.LayerContainer.Objects) do
			table.insert(ItemObjects, Container.ItemObject)
		end

		for _, ItemObject in pairs(ItemObjects) do
			self.LayerHandler:RemoveItemObject(ItemObject)
		end
		
		self.KeyframeCount = 0
		self:update_kf_count(self.KeyframeCount)

		self:SetScrollFrame(0)
		self:SetTimelineLength(_g.DEFAULT_FRAMES)
		self:SetZoomPercentage(0)
		
		self.PlaybackHandler:SetPlayArea(0, _g.DEFAULT_FRAMES)

		self.LayerScroll:SetLineNumber(1)
	end
	
	function LayerSystem:TurnOffRigOnlyMode()
		self.RigOnlyMode = false
		self:SaveFile()
		self.CurrentFile.Parent = nil
	end

	function LayerSystem:SaveFile()
		assert(self.CurrentFile, "No file open.")

		if self.RigOnlyMode then
			self.export_hook()
		else
			local file = Instance.new("StringValue")
			file.Name = self.CurrentFile.Name

			local Data = {}

			local RefPath = self.CameraReferencePart and Path:new(self.CameraReferencePart) or nil
			Data.Information = {
				Length = self.length,
				Looped = self.PlaybackHandler.Loop,
				ExportPriority = self.ExportPriority,
				Modified = os.time(),
				Created = self.FileCreated,
				CamRef = RefPath and RefPath:Serialize() or nil,
				FPS = self.FPS ~= 60 and self.FPS or nil,
			}
			if RefPath then
				RefPath:Destroy()
			end

			Data.Items = {}

			local ItemObjects = self.LayerHandler.LayerContainer

			for ind = ItemObjects.size, 1, -1 do
				local ItemObject = ItemObjects.Objects[ind].ItemObject
				local data, folder = ItemObject:Serialize()

				table.insert(Data.Items, data)
				folder.Name = ItemObjects.size - ind + 1
				folder.Parent = file
			end

			file.Value = game:GetService("HttpService"):JSONEncode(Data)

			file.Parent = self.CurrentFile.Parent

			self.CurrentFile:Destroy()
			self.CurrentFile = file
		end
	end

	function LayerSystem:OpenFile(File)
		if self.CurrentFile then
			self:Reset()
		end

		local tryOpen = _g.Files.OpenFile(File)
		if tryOpen == nil then return false end

		self.CurrentFile = File
		
		local Info = tryOpen.Information
		if Info.Length then
			self:SetTimelineLength(Info.Length)
			self:SetZoomPercentage(0)
		end
		if Info.Looped then
			self.PlaybackHandler:SetLoop(Info.Looped)
		end
		if Info.ExportPriority then
			self.ExportPriority = Info.ExportPriority
		else
			self.ExportPriority = "Action"
		end
		self.FileCreated = Info.Created
		if Info.CamRef then
			local RefPath = Path.Deserialize(Info.CamRef)
			if RefPath then
				self.CameraReferencePart = RefPath:GetItem()
				RefPath:Destroy()
			end
		end
		if Info.FPS then
			self:SetFPS(Info.FPS)
		end
		
		self.PlaybackHandler:SetPlayArea(0, self.length)
		
		local Items = tryOpen.Items
		local item_collapse = {}
		local collapse = {}

		for ind, ItemTbl in pairs(Items) do
			local itemObjFolder = File:FindFirstChild(tostring(ind))
			if itemObjFolder then
				local ItemObj, err, track_tbl = ItemObject.Deserialize(self, ItemTbl, itemObjFolder)
				if ItemObj then
					self.LayerHandler:AddItemObject(ItemObj)
					table.insert(item_collapse, ItemObj)
					table.insert(collapse, track_tbl)
				end
			end
		end
		if self.LayerHandler.LayerContainer.size > 0 then
			self.LayerHandler:SetActiveItemObject(self.LayerHandler.LayerContainer.Objects[1].ItemObject)
			
			for _, tbl in pairs(collapse) do
				table.sort(tbl, function(a,b) return a.hierLevel > b.hierLevel end)
				for _, lsi in pairs(tbl) do
					lsi:Collapse(true)
				end
			end
			for ind, item in pairs(item_collapse) do
				if ind ~= #item_collapse then
					item.ObjectLabel:Collapse(true)
				end
			end
		end

		self.UI.Visible = true
		self.NoFile.Visible = false

		return true
	end
end

do
	local timeline_size; local line_count
	local pixels_per_frame; local pixels_per_line
	local cont_offset
	local columns

	function LayerSystem:SetupTickFrameCoords(ini_frm, offset)
		timeline_size = self.Scalable.AbsoluteSize; line_count = self.LayerScroll:GetCanvasLines()
		pixels_per_frame = timeline_size.X / self.length; pixels_per_line = timeline_size.Y / line_count
		
		columns = {}
		if self.LayerHandler.ActiveItemObject and next(self.LayerHandler.ActiveItemObject.PoseMap) then
			local has_zero
			local has_slider
			local has_length
			for pos, _ in pairs(self.LayerHandler.ActiveItemObject.PoseMap) do
				if pos == 0 then has_zero = true end 
				if pos == self.SliderFrame then has_slider = true end
				if pos == self.length then has_length = true end 
				table.insert(columns, pos)
			end
			
			if not has_slider then
				table.insert(columns, self.SliderFrame)
			end
			table.sort(columns, function(a,b) return a < b end)
			if not has_zero then
				table.insert(columns, 1, 0)
			end
			if not has_length then
				table.insert(columns, self.length)
			end
		end
		if #columns == 0 then
			columns = {0, self.SliderFrame, self.length}
		end
		
		if ini_frm then
			cont_offset = 0
			local _, _, cont = self:GetFrameAtMousePosition(offset)
			cont_offset = cont - ini_frm
		else
			cont_offset = 0
		end
	end

	function LayerSystem:GetFrameAtXPositionOnTimeline(x_pos)
		if timeline_size.X == 0 then
			return 0, 0, 0
		end
		local continuous = x_pos / pixels_per_frame - cont_offset
		local   discrete = math.floor(continuous + 0.5)
		local      final = math.clamp(discrete, 0, self.length)

		return final, discrete, continuous
	end
	function LayerSystem:GetFrameAtXPosition(x_pos)
		return self:GetFrameAtXPositionOnTimeline(x_pos - self.Scalable.AbsolutePosition.X)
	end
	function LayerSystem:GetFrameAtMousePosition(offset)
		if _g.Input:ControlHeld() then
			local f, d, c = self:GetFrameAtXPosition(_g.Mouse.X + offset)
			return _g.ClosestValue(columns, f, 1), d, c
		else
			return self:GetFrameAtXPosition(_g.Mouse.X + offset)
		end
	end

	function LayerSystem:GetLineAtYPositionOnList(y_pos)
		if timeline_size.Y == 0 then
			return 1, 0, 0, 0
		end
		local continuous = y_pos / pixels_per_line + 1
		local   discrete = math.floor(continuous)
		local      final = math.clamp(discrete, 1, line_count)

		local per
		if continuous < 1 then
			per = 0
		elseif continuous > line_count then
			per = 1
		else
			per = continuous - discrete
		end
		return final, per, discrete, continuous
	end
	function LayerSystem:GetLineAtYPosition(y_pos)
		return self:GetLineAtYPositionOnList(y_pos - self.Scalable.AbsolutePosition.Y)
	end
	function LayerSystem:GetLineAtMousePosition(offset)
		return self:GetLineAtYPosition(_g.Mouse.Y + offset)
	end
end

do
	function LayerSystem:ConnectScrollBounds(value, dir)
		if value and self.sb_event == nil then
			local sb_res = self.Scalable.AbsoluteSize.X / self.length
			local sb_frame = self.ScrollFrame
			local sb_y = self.LayerScroll:GetCanvasPosition()
			local sb_ymax = self.LayerScroll:GetMaxCanvasPosition()

			local scalable_pos = self.Scalable.Parent.AbsolutePosition.X
			local scalable_size = self.Scalable.Parent.AbsoluteSize.X

			local timeline_pos = self.Scalable.Parent.AbsolutePosition.Y + 26
			local timeline_size = self.Scalable.Parent.AbsoluteSize.Y - 26

			self.sb_event = _g.run_serv.RenderStepped:Connect(function(step)
				if dir == nil or dir == "h" then
					if _g.Mouse.X < scalable_pos then
						local dist = scalable_pos - _g.Mouse.X

						sb_frame = math.clamp(sb_frame - ((400 + 5 * dist) / sb_res) * step, 0, self.length - self.Zoom)
						self:SetScrollFrame(sb_frame)
					elseif _g.Mouse.X > scalable_pos + scalable_size then
						local dist = _g.Mouse.X - (scalable_pos + scalable_size)

						sb_frame = math.clamp(sb_frame + ((400 + 5 * dist) / sb_res) * step, 0, self.length - self.Zoom)
						self:SetScrollFrame(sb_frame)
					end
				end

				if dir == nil or dir == "v" then
					if _g.Mouse.Y < timeline_pos then
						local dist = timeline_pos - _g.Mouse.Y
						sb_y = math.clamp(sb_y - (200 + 5 * dist) * step, 0, sb_ymax)
						self.LayerScroll:SetCanvasPosition(sb_y)
					elseif _g.Mouse.Y > timeline_pos + timeline_size then
						local dist = _g.Mouse.Y - (timeline_pos + timeline_size)
						sb_y = math.clamp(sb_y + (200 + 5 * dist) * step, 0, sb_ymax)
						self.LayerScroll:SetCanvasPosition(sb_y)
					end
				end
			end)
		elseif not value and self.sb_event then
			self.sb_event:Disconnect()
			self.sb_event = nil
		end
	end

	function LayerSystem:MoveTickActive(value, frm, offset)
		if value then
			self:UpdateMoveTick(frm, offset)
		end
		
		self.Scalable.TickFrame.Visible = not value
		self.Scalable.Line.Drag.Tick.Visible = not value
		self.MoveTick.Visible = value
		
		if not value then
			local frame_text, time_text = _g.FormatFrameTime(self.SliderFrame + _g.time_offset, self.FPS)
			self.LayerList.TopDecor.CurrentTime.FrameDisplay.Label.Text = frame_text
			self.LayerList.TopDecor.CurrentTime.Time.Label.Text = time_text
			
			self.OffsetTick.Visible = false
		elseif offset and offset > 0 then
			self.OffsetTick.Visible = value
		end
	end

	function LayerSystem:UpdateMoveTick(frm, offset)
		local frame_text, time_text = _g.FormatFrameTime(frm + _g.time_offset, self.FPS)
		self.LayerList.TopDecor.CurrentTime.FrameDisplay.Label.Text = frame_text
		self.LayerList.TopDecor.CurrentTime.Time.Label.Text = time_text
		
		self.MoveTick.Text = tostring(frm)
		self.MoveTick.Position = UDim2.new(frm / self.length, 0, 0, self.TimeTickTemplate.Position.Y.Offset)

		if offset and offset > 0 then
			frm = frm + offset
			self.OffsetTick.Text = tostring(frm)
			self.OffsetTick.Position = UDim2.new(frm / self.length, 0, 0, self.TimeTickTemplate.Position.Y.Offset)
		end
	end
end

do
	local presetScales = {5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600, 7200, 18000, 36000, 54000, 108000}
	local numScales = #presetScales

	local function FindScale(frames)
		if frames == 30 then return 2 end
		frames = math.floor(frames / 8)
		
		if frames <= presetScales[1] then return presetScales[1] end
		if frames >= presetScales[numScales] then return presetScales[numScales] end

		return _g.ClosestValue(presetScales, frames, 8)
	end

	function LayerSystem:_UpdateTimeTicks()
		local newScale = FindScale(self.Zoom)
		local newStart = math.clamp(_g.round(self.ScrollFrame - math.floor(self.Zoom / 10), newScale), 0, self.length)
		local newEnd = math.clamp(_g.round(self.ScrollFrame + self.Zoom + math.floor(self.Zoom / 10), newScale), 0, self.length)

		local TickFrame = self.Scalable.TickFrame
		local GuideFrame = self.Scalable.Guides

		local NewTimeUI = {}

		for ind = newStart, newEnd, newScale do
			if TickFrame:FindFirstChild("Tick"..ind) then
				table.insert(NewTimeUI, {TickFrame["Tick"..ind], GuideFrame["Guide"..ind]})

				TickFrame["Tick"..ind].Position = UDim2.new(ind / self.length, 0, 0, self.TimeTickTemplate.Position.Y.Offset)
				TickFrame["Tick"..ind].Parent = nil

				GuideFrame["Guide"..ind].Position = UDim2.new(ind / self.length, 0, 0, 0)
				GuideFrame["Guide"..ind].Parent = nil
			else
				local NewTick = self.TimeTickTemplate:Clone()
				NewTick.Name = "Tick"..ind
				NewTick.Text = ind
				NewTick.Position = UDim2.new(ind / self.length, 0, 0, self.TimeTickTemplate.Position.Y.Offset)
				self:AddPaintedItem(NewTick, {TextColor3 = "main"})

				local NewGuide = self.TimeGuideTemplate:Clone()
				NewGuide.Name = "Guide"..ind
				NewGuide.Position = UDim2.new(ind / self.length, 0, 0, 0)
				self:AddPaintedItem(NewGuide, {BackgroundColor3 = "highlight"})

				table.insert(NewTimeUI, {NewTick, NewGuide})
			end
		end

		for _, t in pairs(TickFrame:GetChildren()) do
			self:RemovePaintedItem(t)
			t:Destroy()
		end
		for _, g in pairs(GuideFrame:GetChildren()) do
			self:RemovePaintedItem(g)
			g:Destroy()
		end

		for _, tbl in pairs(NewTimeUI) do
			tbl[1].Parent = TickFrame
			tbl[2].Parent = GuideFrame
		end
	end
end

do
	function LayerSystem:SetTimelineLength(frames)
		local old_length = self.length

		local last = self.LayerHandler:GetLastKeyframePosition()
		if last < _g.MIN_FRAMES then
			last = _g.MIN_FRAMES
		end
		self.length = math.clamp(frames, last, _g.MAX_FRAMES)
		
		if self.PlaybackHandler.PlayArea_Start > self.length then
			self.PlaybackHandler:SetPlayArea(0, self.length)
		elseif self.PlaybackHandler.PlayArea_End == old_length or self.PlaybackHandler.PlayArea_End > self.length then
			self.PlaybackHandler:SetPlayArea(self.PlaybackHandler.PlayArea_Start, self.length)
		else
			self.PlaybackHandler:SetPlayArea(self.PlaybackHandler.PlayArea_Start, self.PlaybackHandler.PlayArea_End)
		end

		for i = 1, #self.LayerHandler.LayerSystemItems, 1 do
			local LayerSystemItem = self.LayerHandler.LayerSystemItems[i]
			if _g.objIsType(LayerSystemItem, "Track") then
				LayerSystemItem.TrackItems:Iterate(function(TrackItem)
					TrackItem:_Position()
					TrackItem:_Size()
				end)
			end
		end

		self:SetZoomFrames(self.Zoom)
		self:SetSliderFrame(self.SliderFrame)
		self.LayerHandler:refresh_poseframe(self.LayerHandler.ActiveItemObject)
	end

	function LayerSystem:SetFPS(fps)
		self.FPS = fps
		_g.current_fps = fps
		
		self.LayerList.TopDecor.Stats.FPS.Label.Text = tostring(fps).." FPS"

		self:SetZoomFrames(self.Zoom)
		self:SetSliderFrame(self.SliderFrame)
	end
	
	do
		local move_slider

		local ini_canvas_pos
		local ini_scroll_pos
		local ini_slider_pos
		local frames_per_pixel

		function LayerSystem:_PanBegin(SelectBoxArea, ini_pos)
			move_slider = _g.Input:ShiftHeld() and SelectBoxArea == self.Timeline

			if not move_slider then
				ini_canvas_pos = self.LayerScroll:GetCanvasPosition()
				frames_per_pixel = self.length / self.Scalable.AbsoluteSize.X
				ini_scroll_pos = self.ScrollFrame
			else
				ini_slider_pos = self.SliderFrame
				self:SetupTickFrameCoords()
				self:SetSliderFrame(self:GetFrameAtMousePosition(0))
				self:ConnectScrollBounds(true, "h")
			end
		end

		function LayerSystem:_PanChanged(SelectBoxArea, changed)
			if not move_slider then
				if SelectBoxArea == self.Timeline then
					self:SetScrollFrame(ini_scroll_pos - (changed.X * frames_per_pixel))
				end
				self.LayerScroll:SetCanvasPosition(ini_canvas_pos - changed.Y)
			else
				self:SetSliderFrame(self:GetFrameAtMousePosition(0))
			end
		end

		function LayerSystem:_PanEnd(SelectBoxArea)
			if move_slider then
				self:ConnectScrollBounds(false)
			end
		end
	end

	do
		function LayerSystem:SetZoomFrames(frames, inputted, data)
			local timeline_ini_size = self.Scalable.Parent.AbsoluteSize.X
			local timeline_pos = self.Scalable.Parent.AbsolutePosition.X

			local anchor_pos
			local anchor_frm

			if data and data.ToMouse then
				anchor_pos = _g.Mouse.X
				self:SetupTickFrameCoords()
				anchor_frm = self:GetFrameAtMousePosition(0)
			elseif data and data.AnchorRight then
				anchor_pos = self.ScrollFrame + self.Zoom
			else
				anchor_pos = self.Scalable.Line.AbsolutePosition.X
				anchor_frm = self.SliderFrame
			end

			self.Zoom = math.clamp(frames, (_g.MIN_FRAMES / 2), self.length)
			local timeline_scale = self.length / self.Zoom
			self.Scalable.Size = UDim2.new(self.length / self.Zoom, 0, 1, 0)
			self.ScrollBar.Bar.Size = UDim2.new(self.Zoom / self.length, 1, 1, 0)

			if not inputted then
				self.ZoomSlider:Set((self.length - self.Zoom) / (self.length - (_g.MIN_FRAMES / 2)))
			end

			if data and data.AnchorLeft then
				self:SetScrollFrame(self.ScrollFrame)
			elseif data and data.AnchorRight then
				self:SetScrollFrame(anchor_pos - self.Zoom)
			else
				local scalable_size = timeline_ini_size * timeline_scale
				local pos_at_zero = (scalable_size / self.length) * anchor_frm + timeline_pos
				self:SetScrollFrame((pos_at_zero - anchor_pos) * (self.length / scalable_size))
			end

			self:_UpdateTimeTicks()
		end
		function LayerSystem:SetZoomByFrames(frameDifference, inputted, data)
			self:SetZoomFrames(self.Zoom + frameDifference, inputted, data)
		end
		function LayerSystem:SetZoomPercentage(percent, inputted, data)
			self:SetZoomFrames(self.length - ((self.length - (_g.MIN_FRAMES / 2)) * percent), inputted, data)
		end
	end

	do
		function LayerSystem:SetScrollFrame(frame, inputted)
			self.ScrollFrame = math.clamp(frame, 0, self.length - self.Zoom)
			self.Scalable.Position = self.Scalable.Position + UDim2.new(-self.Scalable.Position.X.Scale + (-self.ScrollFrame / self.Zoom), 0, 0, 0)

			if not inputted then
				local scrollbar_pos = self.length - self.Zoom ~= 0 and (1 - self.ScrollBar.Bar.Size.X.Scale) * (self.ScrollFrame / (self.length - self.Zoom)) or 0
				self.ScrollBar.Bar.Position = UDim2.new(scrollbar_pos, 0, 0, 0)
			end

			self:_UpdateTimeTicks()
		end
		function LayerSystem:SetScrollByFrames(delta, inputted)
			self:SetScrollFrame(self.ScrollFrame + delta, inputted)
		end
		function LayerSystem:SetScrollPercentage(percent, inputted)
			self:SetScrollFrame((self.length - self.Zoom) * percent, inputted)
		end

		local frames_per_pixel
		local ini_scroll_frame

		function LayerSystem:_ScrollDragBegin(Bar, ini_pos)
			frames_per_pixel = self.length / self.ScrollBar.AbsoluteSize.X
			ini_scroll_frame = self.ScrollFrame
		end
		function LayerSystem:_ScrollDragChanged(Bar, changed)
			local add_frames = frames_per_pixel * changed.X
			self:SetScrollFrame(ini_scroll_frame + add_frames)
		end

		local ini_Zoom
		local bounds = {}

		function LayerSystem:_MinimapZoomBegin(but, ini_pos)
			frames_per_pixel = self.length / self.ScrollBar.AbsoluteSize.X
			ini_Zoom = self.Zoom
			bounds = {-self.ScrollFrame, self.length - (self.ScrollFrame + self.Zoom)}
		end

		function LayerSystem:_ZoomLeftChanged(but, changed)
			local add_frames = math.clamp(frames_per_pixel * changed.X, bounds[1], math.huge)
			self:SetZoomFrames(ini_Zoom - add_frames, false, {AnchorRight = true})
		end

		function LayerSystem:_ZoomRightChanged(but, changed)
			local add_frames = math.clamp(frames_per_pixel * changed.X, -math.huge, bounds[2])
			self:SetZoomFrames(ini_Zoom + add_frames, false, {AnchorLeft = true})
		end
	end

	do
		function LayerSystem:refresh_on_pose()
			if self.LayerHandler.ActiveItemObject and not self.PlaybackHandler.Playing then
				local pos = self.LayerHandler.ActiveItemObject.PoseMap[self.SliderFrame]
				if pos and not self.is_on_pose then
					self.is_on_pose = true
					self:SetItemPaint(self.AddPose.Frame, {BackgroundColor3 = "main"}, _g.Themer.QUICK_TWEEN)
					self:SetItemPaint(self.AddPose.Frame.UIStroke, {Color = "main"}, _g.Themer.QUICK_TWEEN)
				elseif not pos and self.is_on_pose then
					self.is_on_pose = false
					self:SetItemPaint(self.AddPose.Frame, {BackgroundColor3 = "third"}, _g.Themer.QUICK_TWEEN)
					self:SetItemPaint(self.AddPose.Frame.UIStroke, {Color = "third"}, _g.Themer.QUICK_TWEEN)
				end
			elseif self.is_on_pose then
				self.is_on_pose = false
				self:SetItemPaint(self.AddPose.Frame, {BackgroundColor3 = "third"}, _g.Themer.QUICK_TWEEN)
				self:SetItemPaint(self.AddPose.Frame.UIStroke, {Color = "third"}, _g.Themer.QUICK_TWEEN)
			end
			self.AddPose.Input.Visible = not self.is_on_pose
		end
		
		function LayerSystem:SetSliderFrame(frame)
			local ini_frame = self.SliderFrame

			self.SliderFrame = math.clamp(math.floor(frame), 0, self.length)
			local per = self.SliderFrame / self.length

			self.Scalable.Line.Position = UDim2.new(per, 0, 0, 0)
			self.ScrollBar.Time.Position = UDim2.new(per, 0, 0, 0)

			local str_frm = tostring(self.SliderFrame)
			self.Scalable.Line.Drag.Tick.Text = str_frm
			local new_x_size = (#str_frm * 7) + 6
			if self.Scalable.Line.Drag.Size.X.Offset ~= new_x_size then
				self.Scalable.Line.Drag.Size = UDim2.new(0, new_x_size, 0, 12)
			end
			
			local frame_text, time_text = _g.FormatFrameTime(self.SliderFrame + _g.time_offset, self.FPS)
			self.LayerList.TopDecor.CurrentTime.FrameDisplay.Label.Text = frame_text
			self.LayerList.TopDecor.CurrentTime.Time.Label.Text = time_text
			
			self:refresh_on_pose()
			self.PlaybackHandler:UpdateTracks()
		end
		function LayerSystem:SetSliderByFrames(delta)
			self:SetSliderFrame(self.SliderFrame + delta)
		end
		function LayerSystem:SetSliderPercentage(percent)
			self:SetSliderFrame(self.length * percent + 0.5)
		end
		
		local ini_drag_pos
		local ini_slider_pos

		function LayerSystem:_SliderDragBegin(Slider, ini_pos)
			self.PlaybackHandler:Stop()
			ini_drag_pos = Slider.AbsolutePosition.X + (Slider.Size.X.Offset / 2) - ini_pos.X
			ini_slider_pos = self.SliderFrame
			self:SetupTickFrameCoords(ini_slider_pos, ini_drag_pos)
			self:ConnectScrollBounds(true, "h")
		end
		function LayerSystem:_SliderDragChanged(Slider, changed)
			self:SetSliderFrame(self:GetFrameAtMousePosition(ini_drag_pos))
		end
		function LayerSystem:_SliderDragEnded(Slider)
			self:SetSliderFrame(self.SliderFrame)
			self:ConnectScrollBounds(false)
		end

		function LayerSystem:_TickFrameDragBegin(TickFrame, ini_pos)
			self.PlaybackHandler:Stop()
			self:SetupTickFrameCoords()
			self:_TickFrameDragChanged(TickFrame, nil)
			self:SetSliderFrame(self:GetFrameAtXPosition(ini_pos.X))
			ini_slider_pos = self.SliderFrame
			self:ConnectScrollBounds(true, "h")
		end
		function LayerSystem:_TickFrameDragChanged(TickFrame, changed)
			self:SetSliderFrame(self:GetFrameAtMousePosition(0))
		end
	end

	do
		local iniSize
		local abs_x

		function LayerSystem:_ResizeDragBegin(but, ini_pos)
			iniSize = self.LayerList.Size.X.Offset
			abs_x = self.UI.AbsoluteSize.X
		end
		function LayerSystem:_ResizeDragChanged(but, changed)
			local newSize = math.clamp(iniSize + changed.X, 200, abs_x)

			self.LayerList.Size = self.LayerList.Size + UDim2.new(0, -self.LayerList.Size.X.Offset + newSize, 0, 0)
			self.Timeline.Size = self.Timeline.Size + UDim2.new(0, -self.Timeline.Size.X.Offset - newSize, 0, 0)

			self.Timeline.Position = self.Timeline.Position + UDim2.new(0, -self.Timeline.Position.X.Offset + newSize, 0, 0)
		end
	end
end

return LayerSystem

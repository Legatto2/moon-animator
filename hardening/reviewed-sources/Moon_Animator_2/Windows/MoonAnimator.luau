local _g = _G.MoonGlobal
------------------------------------------------------------
	local Ease = require(_g.class.Ease)
	local Path = require(_g.class.Path)

	local FILE_MENU = {
	{"fileMain", "File"}, {"editMain", "Edit"}, {"itemMain", "Item"}, {"keyframeMain", "Keyframe"}, {"frameMain", "Frame"}, {"cameraMain", "Camera"}, {"settingsMain", "Options"}, {"h_theme", "Theme"},
		fileMain = {
			{"Save", "Save"},
			{"OpenSaveAs", "Save As..."},
			{"SaveClose", "Save and Close"},
			{"CloseFile", "Close"},
			{"OpenAnimationSettings", "File Settings..."},
			"~",
			{"Export", "Export Rigs"},
			{"OpenImport", "Import..."},
			{"OpenExportFiles", "Export Files..."},
			"~",
			{"ToggleLoop", "Toggle Loop"},
			{"Play", "Play"},
			{"HideUI", "Hide UI"},
		},
		editMain = {
			{"Cut", "Cut"},
			{"Copy", "Copy"},
			{"Paste", "Paste"},
			{"PasteIntoItem", "Paste Into"},
			{"DeleteSelectedTrackItems", "Delete"},
			{"SelectAllTrackItems", "Select All"},
			"~",
			{"Undo", "Undo"},
			{"Redo", "Redo"},
		},
		itemMain = {
			{"RigMenu", "Rig"},
			RigMenu = {
				{"ReflectRig", "Reflect"},
				{"ToggleHandles", "Toggle Handles", extra = {NoClickOff = true}},
				"~",
				{"ToggleOnionSkin", "Toggle Onion Skin", extra = {NoClickOff = true}},
				{"ApplyOnionSkin", "Apply Onion Skin"},
				{"ClearOnionSkins", "Clear Onion Skin"},
			},
			{"EffectsMenu", "Add Effects"},
			EffectsMenu = {
				{"AddVignette", "Vignette"},
				{"AddLetterboxing", "Letterboxing"},
				{"AddScreenCover", "Screen Cover"},
				{"AddSubtitles", "Subtitles"},
				"~",
				{"SubtitlesAutoSize", "Scale Subtitles", extra = {IsToggle = true, NoClickOff = true}},
			},
			{"OpenAddItem", "Add..."},
			"~",
			{"JumpCameraToItem", "View"},
			{"ToggleItemTracks", "Toggle All"},
			{"CollapseToggle", "Collapse All"},
			{"OpenJumpToItem", "Jump To..."},
		},
		keyframeMain = {
			{"OpenEditTrackItems", "Edit Selection..."},
			{"AddToSelectedTracks", "Add"},
			{"AddDefaultKeyframesToSelectedTracks", "Add Default"},
			{"PrevKeyframe", "Previous Pose", extra = {NoClickOff = true}},
			{"NextKeyframe", "Next Pose", extra = {NoClickOff = true}},
			{"split_menu", "Split"},
			split_menu = {
				{"SplitKeyframe", "Split Keyframe"},
				{"OpenSplitKFVal", "Stride..."},
			},
			"~",
			{"GroupKeyframes", "Group Selection"},
			{"OpenUngroup", "Ungroup..."},
			{"UngroupKeyframes", "Ungroup All"},
		},
		frameMain = {
			{"OpenStretchFrames", "Stretch..."},
			{"OpenRepeatFrames", "Repeat..."},
			{"OpenFillFrames", "Fill..."},
			
			"~",
			{"FitTimeline", "Fit Timeline"},
			{"OpenFrameOffset", "Offset..."},
			"~",
			{"PrevFrame", "Previous", extra = {NoClickOff = true}},
			{"NextFrame", "Next", extra = {NoClickOff = true}},
			{"JumpBegin", "Frame 0"},
		},
		cameraMain = {
			{"AddCamera", "Add"},
			{"ToggleCameraTracks", "Toggle"},
			"~",
			{"OpenCameraRotation", "Rotation..."},
			{"OpenCameraRef", "Reference..."},
			"~",
			{"ROTGrid", "Grid", extra = {IsToggle = true, NoClickOff = true}},
		},
		settingsMain = {
			{"HandlesMenu", "Handles"},
			HandlesMenu = {
				{"FullPartHandles", "Full Part", extra = {IsToggle = true, NoClickOff = true}},
				{"SmallBoneHandles", "Small Bone", extra = {IsToggle = true, NoClickOff = true}},
				{"NoHideHandles", "Never Hide", extra = {IsToggle = true, NoClickOff = true}},
				"~",
				{"ShowBoneCones", "Bone Cone", extra = {IsToggle = true, NoClickOff = true}},
				{"ShowBoneSpheres", "Bone Sphere", extra = {IsToggle = true, NoClickOff = true}},
				{"ShowPart", "Part", extra = {IsToggle = true, NoClickOff = true}},
			},
			{"GizmoMenu", "Gizmos"},
			GizmoMenu = {
				{"NoScaleHandles", "Constant Size", extra = {IsToggle = true, NoClickOff = true}},
				{"HandlesNotOnTop", "Not Always On Top", extra = {IsToggle = true, NoClickOff = true}},
				{"AlwaysUseIncrement", "Use Increment", extra = {IsToggle = true, NoClickOff = true}},
				"~",
				{"dragger_ver", "KojoGizmos v1.1"},
			},
			{"UseLastEasing", "Use Last Ease", extra = {IsToggle = true, NoClickOff = true}},
			{"KeyframeColor", "Easing Colors", extra = {IsToggle = true, NoClickOff = true}},
			{"TotalInSeconds", "Show Seconds", extra = {IsToggle = true, NoClickOff = true}},
			"~",
			{"other", "Other"},
			other = {
				{"OpenActivate", "EULA..."},
				{"OpenEditTheme", "Edit Theme..."},
				{"version", "!V"..tostring(_g.ver)},
			},
		},
		h_theme = {
			
		}
	}

	local cur_list = FILE_MENU.h_theme
	local price = true
	for _, theme in pairs(_g.Themer.ThemeList) do
		if theme == "~" then
			table.insert(cur_list, "~")
			price = false
		else
			table.insert(cur_list, {"Theme_"..theme, theme, extra = {NoClickOff = true, Price = price}})
		end
	end

	local FM_DEFAULT_DISABLE = {
		"CloseFile",
		"OpenAddItem",
		"CollapseToggle",
		"ToggleItemTracks",
		"OpenJumpToItem",
		"PasteIntoItem",
		"FitTimeline",
		"Play",
		"ToggleLoop",
		"JumpBegin",
		"PrevFrame",
		"NextFrame",
		"AddToSelectedTracks",
		"AddDefaultKeyframesToSelectedTracks",
		"DeleteSelectedTrackItems",
		"OpenEditTrackItems",
		"GroupKeyframes",
		"OpenUngroup",
		"OpenImport",
		"ReflectRig",
		"ToggleHandles",
		"OpenAnimationSettings",
		"Copy",
		"Paste",
		"Save",
		"OpenSaveAs",
		"SaveClose",
		"Export",
		"Cut",
		"DeleteSelectedTrackItems",
		"Undo",
		"Redo",
		"OpenCameraRef",
		"ToggleCameraTracks",
		"OpenFillFrames",
		"OpenFrameOffset",
		"OpenRepeatFrames",
		"OpenStretchFrames",
		"AddCamera",
		"AddSubtitles",
		"AddVignette",
		"AddLetterboxing",
		"AddScreenCover",
		"SelectAllTrackItems",
		"ToggleOnionSkin",
		"ApplyOnionSkin",
		"ClearOnionSkins",
		"JumpCameraToItem",
		"NextKeyframe",
		"PrevKeyframe",
		"SplitKeyframe",
		"OpenSplitKFVal",
	}
	local FM_DEFAULT_ENABLE = {
		"CloseFile",
		"ApplyOnionSkin",
		"OpenAddItem",
		"CollapseToggle",
		"OpenJumpToItem",
		"FitTimeline",
		"Play",
		"ToggleLoop",
		"JumpBegin",
		"PrevFrame",
		"NextFrame",
		"OpenImport",
		"OpenAnimationSettings",
		"Save",
		"OpenSaveAs",
		"SaveClose",
		"Export",
		"OpenCameraRef",
		"ToggleCameraTracks",
		"OpenFrameOffset",
		"OpenStretchFrames",
		"AddCamera",
		"AddSubtitles",
		"AddVignette",
		"AddLetterboxing",
		"AddScreenCover",
		"SelectAllTrackItems",
		"ClearOnionSkins",
		"OpenSplitKFVal",
	}

	local file_dirty = false

	local history = {{}}
	local history_ind = 1
	local HISTORY_SIZE = 30

	local copy_buffer = {begin = 0, length = 0}

	local SecondaryScreenGui = Instance.new("ScreenGui")
	local CurrentHandleTarget

	local no_file_sel
	local grab_rig
	local grab_file
	local grab_folder

	local WindowData = _g.WindowData:new("Moon Animator", script.Contents)
	WindowData.img = true
	WindowData.resize = true
	WindowData.NeedsMouse = true
	WindowData.ResizeIncrement = {X = 0, Y = 21}
	WindowData.MenuBar = _g.MenuBar.MenuBarFactory("MoonAnimatorMenu", FILE_MENU)

	local Win  = _g.Window:new(script.Name, WindowData)
	Button:new(Win.g_e.CloseFile); CloseFile.UI.Parent = WindowData.MenuBar.UI; CloseFile.UI.Visible = false

	Win:AddPaintedItem(CloseFile.UI.BG.Frame1, {BackgroundColor3 = "main"})
	Win:AddPaintedItem(CloseFile.UI.BG.Frame2, {BackgroundColor3 = "main"})

	CloseFile.OnClick = function()
		Win.PromptSave()
	end

	LayerSystem:new(Win.g_e.LayerSystem); local LayerHandler = LayerSystem.LayerHandler; local SelectionHandler = LayerSystem.SelectionHandler; local PlaybackHandler = LayerSystem.PlaybackHandler
	_g.GuiLib:AddInput(LayerSystem.LoopToggle, {click = {func = function() 
		PlaybackHandler:SetLoop(not PlaybackHandler.Loop)
	end}})
	_g.GuiLib:AddInput(LayerSystem.AddItemButton, {click = {func = function() 
		_g.Input:DoAction("OpenAddItem")
	end}})
	_g.GuiLib:AddInput(LayerSystem.OpenSettings, {click = {func = function() 
		Win:OpenModal(_g.Windows.AnimationSettings)
	end}})
------------------------------------------------------------
do
	_g.Toggles.CreateToggle("ShowBoneCones", {Default = true})
	_g.Toggles.SetToggleChanged("ShowBoneCones", function(value)
		_g.show_bone_cones = value
	end)
	
	_g.Toggles.CreateToggle("ShowBoneSpheres", {Default = true})
	_g.Toggles.SetToggleChanged("ShowBoneSpheres", function(value)
		_g.show_bone_spheres = value
	end)
	
	_g.Toggles.CreateToggle("ShowPart", {Default = true})
	_g.Toggles.SetToggleChanged("ShowPart", function(value)
		_g.show_part_handles = value
	end)
	
	_g.Toggles.CreateToggle("SmallBoneHandles", {Default = false})
	_g.Toggles.SetToggleChanged("SmallBoneHandles", function(value)
		_g.bone_handle_size = value and 0.2 or 1
	end)
	
	_g.Toggles.CreateToggle("FullPartHandles", {Default = false})
	_g.Toggles.SetToggleChanged("FullPartHandles", function(value)
		_g.full_part_handles = value
	end)
	
	_g.Toggles.CreateToggle("NoHideHandles", {Default = false})
	_g.Toggles.SetToggleChanged("NoHideHandles", function(value)
		_g.no_hide_handles = value
		Win:SetHidden(not Win.UI.Visible)
	end)
	
	_g.Toggles.CreateToggle("UseLastEasing", {Default = false})
	_g.Toggles.SetToggleChanged("UseLastEasing", function(value)
		_g.use_last_ease = value
	end)

	_g.Toggles.CreateToggle("KeyframeColor", {Default = false})
	_g.Toggles.SetToggleChanged("KeyframeColor", function(value)
		_g.set_kf_color(value)
	end)
	
	_g.Toggles.CreateToggle("TotalInSeconds", {Default = false})
	_g.Toggles.SetToggleChanged("TotalInSeconds", function(value)
		_g.FormatFrameTime = value and _g.FormatFrameTime_s or _g.FormatFrameTime_f
		LayerSystem:SetSliderFrame(LayerSystem.SliderFrame)
	end)
end
------------------------------------------------------------
do
	SecondaryScreenGui.ResetOnSpawn = false
	SecondaryScreenGui.IgnoreGuiInset = true
	SecondaryScreenGui.Name = "MoonAnimatorEffects"
	SecondaryScreenGui.DisplayOrder = -6
	
	local Grid = UI["Grid"]; Grid.Parent = SecondaryScreenGui
	_g.Toggles.CreateToggle("ROTGrid", {Default = false, Temp = true})
	_g.Toggles.SetToggleChanged("ROTGrid", function(value)
		Grid.Visible = value
		Grid.Parent = nil
		Grid.Parent = SecondaryScreenGui
	end)

	local Vignette = UI.Vignette; Vignette.Parent = SecondaryScreenGui
	for _, Property in pairs(_g.ItemTable.Items["ImageLabel"]) do
		local prop = Property[1]
		Vignette:GetPropertyChangedSignal(prop):Connect(function()
			Vignette.LL[prop] = Vignette[prop]
			Vignette.LL.LR[prop] = Vignette[prop]
			Vignette.UR[prop] = Vignette[prop]
		end)
	end
	_g.Input:BindAction(Win, "AddVignette", function()
		if LayerHandler.ItemMap[Vignette:GetDebugId(8)] == nil then
			DoCompositeAction("AddItems", {ItemList = {Vignette}, PropList = {"ImageTransparency"}, MarkerTrack = false})
		end
	end, {}, true)

	local Letterbox = UI.Letterbox; Letterbox.Parent = SecondaryScreenGui
	for _, Property in pairs(_g.ItemTable.Items["Frame"]) do
		local prop = Property[1]
		Letterbox.Letterbox:GetPropertyChangedSignal(prop):Connect(function()
			Letterbox.Top[prop] = Letterbox.Letterbox[prop]
		end)
	end
	
	_g.Input:BindAction(Win, "AddLetterboxing", function()
		if LayerHandler.ItemMap[Letterbox.Letterbox:GetDebugId(8)] == nil then
			DoCompositeAction("AddItems", {ItemList = {Letterbox.Letterbox}, PropList = {"BackgroundColor3", "BackgroundTransparency"}, MarkerTrack = false})
		end
	end, {}, true)

	local Subtitles = UI.Subtitles; Subtitles.Parent = SecondaryScreenGui
	local size_change = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")
	local subSize
	_g.Toggles.CreateToggle("SubtitlesAutoSize", {Default = true, Temp = true})
	_g.Toggles.SetToggleChanged("SubtitlesAutoSize", function(value)
		if value then
			Subtitles.TextSize = math.floor((72 / 1080) * workspace.CurrentCamera.ViewportSize.Y + 0.5)
			subSize = size_change:Connect(function()
				Subtitles.TextSize = math.floor((72 / 1080) * workspace.CurrentCamera.ViewportSize.Y + 0.5)
			end)
		else
			if subSize then 
				subSize:Disconnect()
				subSize = nil
			end
			Subtitles.TextSize = 72
		end
	end)
	_g.Input:BindAction(Win, "AddSubtitles", function()
		if LayerHandler.ItemMap[Subtitles:GetDebugId(8)] == nil then
			DoCompositeAction("AddItems", {ItemList = {Subtitles}, PropList = {"Text", "MaxVisibleGraphemes"}, MarkerTrack = false})
		end
	end, {}, true)

	local ScreenCover = UI["Screen Cover"]; ScreenCover.Parent = SecondaryScreenGui
	_g.Input:BindAction(Win, "AddScreenCover", function()
		if LayerHandler.ItemMap[ScreenCover:GetDebugId(8)] == nil then
			DoCompositeAction("AddItems", {ItemList = {ScreenCover}, PropList = {"BackgroundTransparency"}, MarkerTrack = false})
		end
	end, {}, true)
end
------------------------------------------------------------
do
	local kojo_handles = script.Parent.Parent.KojoGizmos
	Win.HandlePart = Instance.new("Part"); Win.HandlePart.Name = "MoonAnimatorHandlePart"; Win.HandlePart.Anchored = true; Win.HandlePart.CanCollide = false; Win.HandlePart.Locked = true; Win.HandlePart.Massless = true; Win.HandlePart.Archivable = false

	local RotHandles = require(kojo_handles.RotationGizmos):new()
	local PosHandles = require(kojo_handles.PositionGizmos):new()
	
	RotHandles.target = Win.HandlePart; PosHandles.target = Win.HandlePart
	
	local percise_handle_parts = {}
	
	for _, part in pairs(RotHandles.model:GetChildren()) do 
		if part:IsA("BasePart") and part.Name ~= "Origin" and part.Name ~= "Sphere" and part.ClassName ~= "MeshPart" then
			table.insert(percise_handle_parts, part)
		end 
	end
	for _, part in pairs(PosHandles.model:GetChildren()) do 
		if part:IsA("BasePart") and part.Name ~= "Origin" then 
			table.insert(percise_handle_parts, part)
		end 
	end
	
	Win:AddPaintedItem(RotHandles.model.Origin.Sphere, {Color3 = "main"})
	Win:AddPaintedItem(PosHandles.model.Origin.Sphere, {Color3 = "main"})
	
	local CursorInfo = UI.CursorInfo; CursorInfo.Parent = SecondaryScreenGui
	
	local always_inc = false
	local ctrl_held = false
	local scaling = true
	
	function update_inc()
		local rot = 0
		local pos = 0
		if (not always_inc and ctrl_held) or (always_inc and not ctrl_held) then
			rot = _g.studioServ.RotateIncrement > 0 and math.rad(_g.studioServ.RotateIncrement) or 0
			pos = _g.studioServ.GridSize > 0 and _g.studioServ.GridSize or 0
		end
		RotHandles.increment = rot
		PosHandles.increment = pos
	end
	
	_g.Toggles.CreateToggle("AlwaysUseIncrement", {Default = false})
	_g.Toggles.SetToggleChanged("AlwaysUseIncrement", function(value)
		always_inc = value
		update_inc()
	end)
	
	_g.Toggles.CreateToggle("NoScaleHandles", {Default = false})
	_g.Toggles.SetToggleChanged("NoScaleHandles", function(value)
		_g.scale_handles = not value
		RotHandles._prevCamDist = -1
		PosHandles._prevCamDist = -1
	end)
	
	_g.Toggles.CreateToggle("HandlesNotOnTop", {Default = false})
	_g.Toggles.SetToggleChanged("HandlesNotOnTop", function(value)
		for _, giz in pairs(RotHandles.gizmos) do
			for _, ador in pairs(giz.adornments) do
				ador.AlwaysOnTop = not value
			end
		end
		for _, giz in pairs(PosHandles.gizmos) do
			for _, ador in pairs(giz.adornments) do
				ador.AlwaysOnTop = not value
			end
		end
	end)
		
	Win:AddPaintedItem(CursorInfo.BG, {BackgroundColor3 = "bg"})
	Win:AddPaintedItem(CursorInfo.BG.UIStroke, {Color = "main"})

	Win:AddPaintedItem(CursorInfo.Offset, {BackgroundColor3 = "bg"})
	Win:AddPaintedItem(CursorInfo.Offset.UIStroke, {Color = "main"})
	Win:AddPaintedItem(CursorInfo.Offset.Label, {TextColor3 = "main"})
		
	local HandleActive = false
	local IniOffset = false
	
	local PRS = 1; local PRS_str = {"Rotation", "Position"}
	local Space_tbl = {1, 1}; local Space_str = {"Local", "World"};

	local DragTargets = {}
	
	Win.OnMouseDown = function()
		local scrRay = workspace.CurrentCamera:ScreenPointToRay(_g.Mouse.X, _g.Mouse.Y, 0)
		if scrRay then
			local part = workspace:FindPartOnRayWithWhitelist(Ray.new(scrRay.Origin, scrRay.Direction * 1000), percise_handle_parts, false, true)
			if part == nil then
				part = workspace:FindPartOnRayWithWhitelist(Ray.new(scrRay.Origin, scrRay.Direction * 1000), _g.MouseFilter:GetChildren(), false, true)
				if part then
					part.PartClicked:Fire()
				else
					SelectionHandler:DeselectAll()
				end
			end
		end
	end

	local function UpdateCursorInfo()
		RotHandles._prevCamDist = nil
		PosHandles._prevCamDist = nil
		CursorInfo.Info.Mode.Label.Text = "Mode (R): "..PRS_str[PRS]
		CursorInfo.Info.Space.Label.Text = "Space (Y): "..Space_str[Space_tbl[PRS]]
	end

	local function SetSelectionBoxes(value)
		CursorInfo.BG.Visible = value
		CursorInfo.Info.Visible = value
	end

	local function SetDragTargets()
		DragTargets = {}
		SelectionHandler.SelectedTracks:Iterate(function(KeyframeTrack)
			if _g.objIsType(KeyframeTrack, "MotorTrack") then
				table.insert(DragTargets, {ini_transform = KeyframeTrack.Target.C1, ini_cf = KeyframeTrack.Target.Part1.CFrame, Track = KeyframeTrack})
			elseif _g.objIsType(KeyframeTrack, "BoneTrack") then
				table.insert(DragTargets, {ini_transform = KeyframeTrack.Target.Transform, ini_cf = KeyframeTrack.Target.TransformedWorldCFrame, Track = KeyframeTrack})
			elseif KeyframeTrack.part then
				table.insert(DragTargets, {ini_transform = KeyframeTrack.part.CFrame, ini_cf = KeyframeTrack.part.CFrame, Track = KeyframeTrack})
			end
		end, "KeyframeTrack")
		update_inc()
	end
	
	for _, obj in pairs(CursorInfo.Info:GetChildren()) do
		if obj.ClassName == "Frame" then
			Win:AddPaintedItem(obj.Label, {TextColor3 = "main"})
		end
	end
	UpdateCursorInfo()
	
	_g.Input:BindAction(Win, "ChangePRS", function() 
		if HandleActive then return end 
		PRS = PRS + 1 
		if PRS > #PRS_str then 
			PRS = 1 
		end 
		UpdateCursorInfo() 
		if CursorInfo.Visible then
			UpdateHandleView()
		end
	end, {"R"}, false)
	_g.Input:BindAction(Win, "ChangeSpace", function() 
		Space_tbl[PRS] = Space_tbl[PRS] + 1 
		if Space_tbl[PRS] > #Space_str then 
			Space_tbl[PRS] = 1 
		end 
		if PRS == 1 then
			RotHandles:SetGlobal(Space_tbl[PRS] == 2)
		else
			PosHandles:SetGlobal(Space_tbl[PRS] == 2)
		end
		UpdateCursorInfo()
	end, {"Y"}, false)

	local function FixAngle(ang)
		if math.deg(ang) == 360 then
			ang = 0
		elseif ang < 0 then
			ang = ang + math.pi * 2
		end
		if math.deg(ang) > 180 then
			ang = -(math.pi * 2 - ang)
		end
		
		return ang
	end
	RotHandles.MouseDrag:Connect(function(axis, rel, axisVectorWorld)
		if not IniOffset then
			IniOffset = rel
		end
		rel = rel - IniOffset
		CursorInfo.Offset.Label.Text = _g.format_number(_g.round(math.deg(FixAngle(rel)), 0.01))
		if not HandleActive then return end
		for _, tbl in pairs(DragTargets) do
			local Track = tbl.Track
			if Track.Target.ClassName == "Motor6D" then
				if Space_tbl[PRS] == 1 then
					local default = Track.defaultValue
					local defaultPosition = CFrame.new(default.p)
					local transform = CFrame.fromAxisAngle(Vector3.FromAxis(axis), -rel)
					local oldTransform = tbl.ini_transform * default:Inverse()

					Track.Target.C1 = ((defaultPosition * transform * defaultPosition:Inverse() * oldTransform) * default)
				else
					local pivotCFrame = Track.Target.Part0.CFrame * Track.Target.C0
					local pivotPosition = (tbl.ini_cf * Track.defaultValue).p
					local delta = pivotPosition - pivotCFrame.p
					pivotCFrame = pivotCFrame + delta

					local relativeToPivot = pivotCFrame:toObjectSpace(tbl.ini_cf)
					local newPartCFrame = (CFrame.fromAxisAngle(Vector3.FromAxis(axis), rel) * (pivotCFrame - pivotCFrame.p) + pivotCFrame.p):toWorldSpace(relativeToPivot)

					Track.Target.C1 = newPartCFrame:Inverse() * (pivotCFrame - delta)
				end
			elseif Track.Target.ClassName == "Bone" then
				if Space_tbl[PRS] == 1 then
					Track.Target.Transform = tbl.ini_transform * CFrame.fromAxisAngle(Vector3.FromAxis(axis), rel)
				else
					local transformedWorld = tbl.ini_cf
					local newWorldCF = (CFrame.fromAxisAngle(Vector3.FromAxis(axis), rel) + transformedWorld.p) * (transformedWorld - transformedWorld.p)
					local transformOffset = transformedWorld:toObjectSpace(newWorldCF)
					Track.Target.Transform = tbl.ini_transform * transformOffset
				end
			else
				local cf = CFrame.fromAxisAngle(axisVectorWorld, rel) * tbl.ini_transform.Rotation + tbl.ini_transform.Position
				Track:set_prop(cf)
				Track.value = cf
			end
		end
	end)
	PosHandles.MouseDrag:Connect(function(face, rel, axisVectorWorld)
		CursorInfo.Offset.Label.Text = _g.format_number(_g.round(rel, 0.001))
		if not HandleActive then return end
		for _, tbl in pairs(DragTargets) do
			local Track = tbl.Track
			if Track.Target.ClassName == "Motor6D" then
				if Space_tbl[PRS] == 1 then
					Track.Target.C1 = CFrame.new(-Vector3.FromNormalId(face)*rel) * tbl.ini_transform
				else
					Track.Target.C1 = (tbl.ini_cf + (Vector3.FromNormalId(face) * rel)):Inverse() * (Track.Target.Part0.CFrame * Track.Target.C0)
				end
			elseif Track.Target.ClassName == "Bone" then
				if Space_tbl[PRS] == 1 then
					Track.Target.Transform = tbl.ini_transform * CFrame.new(Vector3.FromNormalId(face)*rel)
				else
					local transformedWorld = tbl.ini_cf
					local newWorldCF = transformedWorld + (Vector3.FromNormalId(face) * rel)
					local transformOffset = transformedWorld:toObjectSpace(newWorldCF)
					Track.Target.Transform = tbl.ini_transform * transformOffset
				end
			else
				local cf = tbl.ini_transform + axisVectorWorld * rel
				Track:set_prop(cf)
				Track.value = cf
			end
		end
	end)

	function ReleaseHandles(input)
		_g.ReleaseHandlesCon:Disconnect()
		_g.ReleaseHandlesCon = nil

		SetSelectionBoxes(true)
		RotHandles.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
		PosHandles.Faces = Faces.new(Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Back, Enum.NormalId.Front)
		HandleActive = false

		local FinalTracks = {}
		for _, tbl in pairs(DragTargets) do
			local Track = tbl.Track
			if Track.Target.ClassName == "Motor6D" then
				if Track.Target.C1 ~= tbl.ini_transform then
					table.insert(FinalTracks, Track)
				end
			elseif Track.Target.ClassName == "Bone" then
				if Track.Transform ~= tbl.ini_transform then
					table.insert(FinalTracks, Track)
				end
			else
				if Track:get_prop() ~= tbl.ini_transform then
					table.insert(FinalTracks, Track)
				end
			end
		end
		Win.DoCompositeAction("AddToTracks", {Tracks = FinalTracks})
	end

	RotHandles.MouseButton1Down:Connect(function(axis)
		if _g.ReleaseHandlesCon then return end

		IniOffset = false
		SetDragTargets()
		RotHandles.Axes = Axes.new(axis)
		HandleActive = axis
		SetSelectionBoxes(false)
		
		_g.ReleaseHandlesCon = _g.input_serv.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				ReleaseHandles()
			end
		end)
	end)
	PosHandles.MouseButton1Down:Connect(function(face)
		if _g.ReleaseHandlesCon then return end

		SetDragTargets()
		PosHandles.Faces = Faces.new(face)
		HandleActive = face
		SetSelectionBoxes(false)

		_g.ReleaseHandlesCon = _g.input_serv.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				ReleaseHandles()
			end
		end)
	end)

	function UpdateHandleView()
		if PRS == 1 then
			PosHandles:SetActive(false)
			RotHandles:SetActive(true)
		else
			PosHandles:SetActive(true)
			RotHandles:SetActive(false)
		end
	end
	
	function CursorAndHandleTick()
		if _g.scale_handles ~= scaling then
			local scale = _g.scale_handles and -1 or (1 + (1/3))
			RotHandles.minScale = scale; RotHandles.maxScale = scale
			PosHandles.minScale = scale; PosHandles.maxScale = scale
			scaling = _g.scale_handles
		end
		RotHandles:Update()
		PosHandles:Update()
		
		CursorInfo.Position = UDim2.new(0, _g.Mouse.X + 28, 0, _g.Mouse.Y + 44)

		local motor = CurrentHandleTarget.Target
		local default = CurrentHandleTarget.defaultValue
		
		if RotHandles.TargetPart then
			local cf = RotHandles.TargetPart.CFrame
			Win.HandlePart.CFrame = Space_tbl[PRS] == 1 and CFrame.new(cf.p) * (cf - cf.p) or CFrame.new(cf.p)
		elseif motor.ClassName == "Motor6D" then
			local cf = motor.Part1.CFrame
			Win.HandlePart.CFrame = Space_tbl[PRS] == 1 and CFrame.new((cf * default).p) * (cf - cf.p) or CFrame.new((cf * default).p)
		elseif motor.ClassName == "Bone" then
			local cf = motor.TransformedWorldCFrame
			Win.HandlePart.CFrame = Space_tbl[PRS] == 1 and CFrame.new(cf.p) * (cf - cf.p) or CFrame.new(cf.p)
		else
			local cf = CurrentHandleTarget.part.CFrame
			Win.HandlePart.CFrame = Space_tbl[PRS] == 1 and CFrame.new(cf.p) * (cf - cf.p) or CFrame.new(cf.p)
		end
		
		if not HandleActive and (not Win.Focused or PlaybackHandler.Playing or _g.GuiLib.drag_data.started) then
			if CursorInfo.Visible then
				PosHandles:SetActive(false)
				RotHandles:SetActive(false)
				CursorInfo.Visible = false
			end
		else
			if CursorInfo.Visible == false then
				CursorInfo.Visible = true
				UpdateHandleView()
			end
		end
	end

	Win.SetHandleTarget = function(Track)
		if Track == nil then
			if CurrentHandleTarget then
				_g.run_serv:UnbindFromRenderStep(tostring(Win).."_Cursor")
				CurrentHandleTarget.HandleTarget = nil
			end
			CurrentHandleTarget = nil
			PosHandles:SetActive(false); RotHandles:SetActive(false)
			CursorInfo.Visible = false
			
			RotHandles.TargetPart = nil
			PosHandles.TargetPart = nil
			
			RotHandles:Deactivate()
			
			_g.Input.ctrl_hook = _g.BLANK_FUNC
		else
			CurrentHandleTarget = Track
			CurrentHandleTarget.HandleTarget = Win.SetHandleTarget
			
			if not _g.scale_handles then
				if _g.objIsType(Track, "MotorTrack") then
					RotHandles.TargetPart = Track.Target.Part1
					PosHandles.TargetPart = Track.Target.Part1
				elseif Track.part then
					RotHandles.TargetPart = Track.part
					PosHandles.TargetPart = Track.part
				end
			end
			
			RotHandles:Activate()
			
			_g.run_serv:BindToRenderStep(tostring(Win).."_Cursor", 200, CursorAndHandleTick)
			ctrl_held = _g.Input:ControlHeld()
			_g.Input.ctrl_hook = function(value) ctrl_held = value update_inc() end
		end
	end
	Win.SetHandleTarget(nil)
end
------------------------------------------------------------
do
	local current_rig_selected
	local current_file_selected

	local buffers, length, counter
	local ani_playing
	
	local Files = _g.Files
	local NoFile = UI.NoFile.Frames
	local NewFile = NoFile.NewFile; local Import = FileList:new(NoFile.Import); local AllFiles = FileList:new(NoFile.AllFiles)
	
	local new_file = Button:new(Win.g_e.NewFile)
	local template_file = Button:new(Win.g_e.NewFromTemplate)
	
	local synonyms = {"none", "vacant", "empty", "nothing", "blank", "void", count = 0} local function rand() synonyms.count = synonyms.count + 1 if synonyms.count < 6 then return synonyms[1] end return synonyms[math.random(1, #synonyms)] end
	
	local RigSelLabel = NewFile.Hint
	local SupportersFrame = NewFile.Supporters
	
	local support_data = {
		Voldex = {"Voldex", 13912834315, "Supported by Voldex!\n\n@VoldexGames"},
		Themes = {"Moon Animator Themes", 13913165611, "Buy themes to support Moon Animator!\n\n@xsixx"},
	}
	
	Win:AddPaintedItem(RigSelLabel, {TextColor3 = "highlight"})
	Win:AddPaintedItem(SupportersFrame.Title, {TextColor3 = "main"})
	
	for _, but in pairs(SupportersFrame.Icons:GetChildren()) do
		if but.ClassName == "ImageButton" then
			Win:AddPaintedItem(but.Label, {TextColor3 = "main"})
			_g.GuiLib:AddInput(but, {
				hover = {caller_obj = Win,
					func_start = function()
						but.Label.Visible = true
					end,
					func_ended = function()
						but.Label.Visible = false
					end,
				},
				click = {
					func = function() 
						Win:OpenModal(_g.Windows.Supporters, support_data[but.Name])
					end
				}
			})
		end
	end

	local GroupImport = Check:new(Win.g_e.GroupImport, false)
	local RigOnly = Check:new(Win.g_e.RigOnly, true)
	
	Win.refresh_new_file_button = function()
		if current_rig_selected then
			RigOnly:SetEnabled(true)
			new_file.UI.Label.Text = RigOnly.Value and "New Rig Animation" or "New Moon 2 File"
			new_file:set_highlight(RigOnly.Value)
			Win:SetItemPaint(NewFile.Background.UIStroke, {Color = "main"})
		else
			RigOnly:SetEnabled(false)
			new_file.UI.Label.Text = "New Moon 2 File"
			new_file:set_highlight(false)
			Win:SetItemPaint(NewFile.Background.UIStroke, {Color = "third"})
		end
	end
	
	_g.Toggles.CreateToggle("GroupImport", {Default = false})
	_g.Toggles.SetToggleChanged("GroupImport", function(value)
		GroupImport:Set(value)
	end)
	GroupImport._changed = function(value)
		_g.Toggles.SetToggleValue("GroupImport", value)
	end
	
	_g.Toggles.CreateToggle("RigOnly", {Default = true})
	_g.Toggles.SetToggleChanged("RigOnly", function(value)
		RigOnly:Set(value)
		Win.refresh_new_file_button()
	end)
	RigOnly._changed = function(value)
		_g.Toggles.SetToggleValue("RigOnly", value)
	end
	
	local file_hover = _g.new_ui.FileHover; Win:AddPaintedItem(file_hover, {BackgroundColor3 = "main"}); Win:AddPaintedItem(file_hover.UIStroke, {Color = "main"})
	file_hover.Visible = false; file_hover.Parent = nil
	
	local function check_unique(item)
		local check = Path.CheckIfUnique(item)
		if not check then
			_g.Windows.MsgBox.Popup(Win, 
				{
					Title = "Bad Selection", 
					Content = "Rig path names must be unique.",
				})
			return false
		end
		return true
	end
	
	LayerSystem.export_hook = function()
		Win.ExportRigs(true)
	end
	
	new_file.OnClick = function()
		local add_rigs = {}
		for _, rig in pairs(game.Selection:Get()) do
			if _g.CheckIfRig(rig) then
				if not check_unique(rig) then return end
				table.insert(add_rigs, 1, rig)
				if RigOnly.Value then break end
			end
		end
		
		grab_rig = nil
		grab_file = nil
		
		local new_file = _g.Files.NewFile("Untitled", "moon2")
		Win.OpenFile(new_file, true)
		if #add_rigs > 0 then
			Win.DoCompositeAction("AddItems", {ItemList = add_rigs, PropList = {"Rig"}, MarkerTrack = RigOnly.Value})
			LayerHandler:SetActiveItemObject(LayerHandler.LayerContainer.Objects[1].ItemObject)
			Win.SaveFile(true)
			Win.ClearActionHistory()
			
			LayerSystem.RigOnlyMode = RigOnly.Value
			CloseFile:set_highlight(RigOnly.Value)
			Win:SetItemPaint(CloseFile.UI.BG.Frame1, {BackgroundColor3 = RigOnly.Value and "highlight" or "main"})
			Win:SetItemPaint(CloseFile.UI.BG.Frame2, {BackgroundColor3 = RigOnly.Value and "highlight" or "main"})
			
			if RigOnly.Value then
				grab_rig = add_rigs[1]
			end
		else
			CloseFile:set_highlight(false)
			Win:SetItemPaint(CloseFile.UI.BG.Frame1, {BackgroundColor3 = "main"})
			Win:SetItemPaint(CloseFile.UI.BG.Frame2, {BackgroundColor3 = "main"})
		end
	end
	
	template_file.OnClick = function()
		local find = Win.find_template_file()
		if not find then
			_g.Windows.MsgBox.Popup(Win, {
				Title = "No Template", 
				Content = "No Moon 2 File named \"Template\".",
			})
			return
		end
		local clone = find:Clone(); clone.Name = "Untitled"
		Win.OpenFile(clone, true)
	end
	
	Win.selection_made = function()
		grab_rig = current_rig_selected
		grab_file = current_file_selected
		Win.clear_file_selected()
		
		if grab_file.Type == "moon2" then
			Win.OpenFile(grab_file.Target, true)
			CloseFile:set_highlight(false)
			Win:SetItemPaint(CloseFile.UI.BG.Frame1, {BackgroundColor3 = "main"})
			Win:SetItemPaint(CloseFile.UI.BG.Frame2, {BackgroundColor3 = "main"})
		elseif grab_file.Type == "Folder" then
			Win.refresh_files(nil, grab_file.Target)
		elseif grab_file.Type == "Import" then
			if not check_unique(grab_rig) then return end
			local new_file = _g.Files.NewFile(grab_file.Target.Name, "moon2")
			Win.OpenFile(new_file, true)
			Win.DoCompositeAction("AddItems", {ItemList = {grab_rig}, PropList = {"Rig"}, MarkerTrack = true})
			Win.DoCompositeAction("Import", {TargetKeyframeSequence = grab_file.Target, ItemObjects = {LayerHandler.ActiveItemObject}, Group = GroupImport.Value})
			DoCompositeAction("FitTimeline")
			SelectionHandler:DeselectAll()
			PlaybackHandler:SetLoop(grab_file.Target.Loop)
			LayerSystem.ExportPriority = grab_file.Target.Priority.Name
			LayerSystem:SetZoomPercentage(0)
			Win.SaveFile(true)
			Win.ClearActionHistory()
			LayerSystem.RigOnlyMode = true
			LayerSystem.CurrentFile.Parent = _g.plugin
			CloseFile:set_highlight(true)
			Win:SetItemPaint(CloseFile.UI.BG.Frame1, {BackgroundColor3 = "highlight"})
			Win:SetItemPaint(CloseFile.UI.BG.Frame2, {BackgroundColor3 = "highlight"})
		end
	end
	
	Win.clear_file_selected = function()
		if current_file_selected then
			if current_file_selected.Type == "moon2" then
				current_file_selected.ui.Frame.Sel.Visible = false
			end
			file_hover.Visible = false
			file_hover.Parent = nil
			current_file_selected = nil
		end
		if ani_playing then
			_g.run_serv:UnbindFromRenderStep(ani_playing)
			for _, data in pairs(buffers) do
				data.Target[data.Prop] = data.Default
			end
			ani_playing = nil
			buffers = nil
		end
	end
	
	Win.OnFocusLost = Win.clear_file_selected
	
	AllFiles._changed = function(value)
		if current_file_selected == value then Win.selection_made() return end
		Win.clear_file_selected()
		current_file_selected = value
		Win:SetItemPaint(file_hover, {BackgroundColor3 = "highlight"}); Win:SetItemPaint(file_hover.UIStroke, {Color = "highlight"})
		file_hover.Parent = value.ui
		task.delay(0, function()
			file_hover.Visible = true
			if value.Type == "moon2" then
				value.ui.Frame.Sel.Visible = true
			end
		end)
	end
	
	Import._changed = function(value)
		if current_file_selected == value then Win.selection_made() return end
		
		if value.import then
			local id = _g.plugin:PromptForExistingAssetId("Animation")
			if id ~= -1 then
				local seq
				local succ = pcall(function() seq = _g.insert:LoadAsset(id):GetChildren()[1] end)
				if succ and seq then
					local folder = current_rig_selected:FindFirstChild("AnimSaves"); if not folder then folder = Instance.new("Model", current_rig_selected) folder.Name = "AnimSaves" end
					seq.Parent = folder
					Win.clear_selection()
					Win.NoFileSel()
					for _, tbl in pairs(Import.List) do
						if tbl.Target == seq then
							Import._changed(tbl)
							break
						end
					end
				end
			end
			return
		elseif value.avatar_shop then
			task.delay(0, function()
				Win:OpenModal(_g.Windows.IdImport, {rig = current_rig_selected})
			end)
			return
		elseif value.combo then
			local next_num
			local next_ind
			if current_file_selected then
				for ind, num in pairs(value.combo) do
					if current_file_selected.Target.Name == value.Target..tostring(num) then
						next_num = value.combo[ind + 1] and value.combo[ind + 1] or value.combo[1]
						next_ind = value.combo[ind + 1] and ind + 1 or 1
						break
					end
				end
			end
			if next_num == nil then next_num = value.combo[1] next_ind = 1 end
			
			local next_ani
			for _, file in pairs(Import.List) do
				if file.Type == "Import" then
					if file.Target.Name == value.Target..tostring(next_num) then
						next_ani = file
						break
					end
				end
			end
			if next_ani then
				task.delay(0, function()
					value.ui.LabelFrame.Prog.Text = tostring(next_ind).." / "..tostring(#value.combo)
					value.ui.LabelFrame.Divider.Visible = true
					value.ui.LabelFrame.Prog.Visible = true
					Import._changed(next_ani)
				end)
			end
			return
		end
		
		Win.clear_file_selected()
		current_file_selected = value
		Win:SetItemPaint(file_hover, {BackgroundColor3 = "main"}); Win:SetItemPaint(file_hover.UIStroke, {Color = "main"})
		file_hover.Parent = value.ui
		task.delay(0, function()
			file_hover.Visible = true
		end)
		
		buffers, length = _g.RobloxToBuffers(value.Target, current_rig_selected, _g.DEFAULT_FPS)
		if length then
			counter = 0
			ani_playing = "MoonAnimator2Preview_"..current_rig_selected.Name
			
			if length == 0 then
				_g.run_serv:BindToRenderStep(ani_playing, 200, function() end)
				for _, data in pairs(buffers) do
					data.Target[data.Prop] = data.Buffer[0]
				end
			else
				if value.Target.Loop then
					_g.run_serv:BindToRenderStep(ani_playing, 200, function(step)
						counter = (counter + step * _g.DEFAULT_FPS) % length
						local frame = math.floor(counter)
						for _, data in pairs(buffers) do
							data.Target[data.Prop] = data.Buffer[frame]
						end
					end)
				else
					local wait_time = 0
					
					_g.run_serv:BindToRenderStep(ani_playing, 200, function(step)
						if wait_time > 0 then
							wait_time = math.clamp(wait_time - step, 0, math.huge)
						else
							counter = counter + step * _g.DEFAULT_FPS
							if counter > length then wait_time = 1/3 counter = length end
							local frame = math.floor(counter)
							for _, data in pairs(buffers) do
								data.Target[data.Prop] = data.Buffer[frame]
							end
							if wait_time > 0 then
								counter = 0
							end
						end
						
					end)
				end
			end
		else
			buffers = nil
		end
	end
	
	Win.find_template_file = function()
		local found
		local function scan(dir)
			if found then return end
			for _, file in pairs(dir:GetChildren()) do
				if file.ClassName == "Folder" then 
					scan(file) 
				elseif file.Name == "Template" and _g.Files.OpenFile(file) then
					found = file
				end
			end
		end
		scan(_g.Files.GetRoot())
		return found 
	end
	
	Win.refresh_files = function(target_rig, folder)
		local moon2_files = {}
		
		local root = _g.Files.GetRoot()
		if folder == root or (folder and folder.Parent == nil) then folder = nil grab_folder = nil end
		
		if folder then
			table.insert(moon2_files, {folder.Parent, math.huge, back = true})
			grab_folder = folder
		end
		
		local function scan(dir)
			for _, file in pairs(dir:GetChildren()) do
				if file.ClassName == "Folder" then 
					if target_rig then
						scan(file)
					else
						table.insert(moon2_files, {file, math.huge})
					end
				elseif _g.Files.OpenFile(file) then
					local insert_file
					if target_rig then
						local found_rig = false
						local file_data = _g.http:JSONDecode(file.Value)
						if file_data and file_data.Items then
							for _, path_tbl in pairs(file_data.Items) do
								local path_obj = Path.Deserialize(path_tbl.Path)
								if path_obj then
									if path_obj:GetItem() == target_rig then
										found_rig = true
										path_obj:Destroy()
										break
									end
									path_obj:Destroy()
								end
							end
						end
						if found_rig then
							insert_file = file
						end
					else
						insert_file = file
					end
					if insert_file then
						local file_data = _g.http:JSONDecode(insert_file.Value)
						if file_data.Information and file_data.Information.Modified then
							table.insert(moon2_files, {insert_file, file_data.Information.Modified})
						end
					end
				end
			end
		end
		scan(folder and folder or root)
		table.sort(moon2_files, function(a,b) return a[2] > b[2] end)
		
		if #moon2_files > 0 then
			AllFiles:SetList(moon2_files)
		else
			AllFiles:SetList(nil, rand())
		end
	end
	
	Win.clear_selection = function()
		Win.clear_file_selected()
		current_rig_selected = nil
		Win.refresh_new_file_button()
		RigSelLabel.Visible = false
		SupportersFrame.Visible = true
		Import:SetList(nil, rand(), true)
		GroupImport:SetEnabled(false)
		Win.refresh_files(nil, grab_folder)
	end
	
	_g.GuiLib:AddInput(NoFile, {down = {func = function() 
		Win.clear_file_selected()
	end}})
	
	local mas_convert = _g.MASConvert.ConvertMASFile
	local function convert_mas_files(rig)
		local files = {}

		for _, folder in pairs(rig.xSIXxAnimationSaves:GetChildren()) do
			if folder.ClassName == "Folder" and folder:FindFirstChild("_root") then
				table.insert(files, folder)
			end
		end

		local target = rig:FindFirstChild("AnimSaves")
		if target == nil then target = Instance.new("Model", rig) target.Name = "AnimSaves" end

		for _, file in pairs(files) do
			pcall(function() mas_convert(file, rig)[1].Parent = target end)
		end
		
		rig.xSIXxAnimationSaves.Name = "MAS_files"
	end
	
	Win.NoFileSel = function()
		if LayerSystem.CurrentFile then return end
		
		local target = _g.first_sel()
		if target and not _g.CheckIfRig(target) then target = nil end
		
		if target == current_rig_selected then return end
		Win.clear_selection()
		if target == nil then return end
		
		current_rig_selected = target
		Win.refresh_new_file_button()
		RigSelLabel.Text = "<b>"..target.Name.."</b>"
		RigSelLabel.Visible = true
		SupportersFrame.Visible = false
		
		Win.refresh_files(target)
		local import_tbl = {}
		
		if target:FindFirstChild("xSIXxAnimationSaves") then
			convert_mas_files(target)
		end
		
		if target:FindFirstChild("AnimSaves") then

			local combo_map = {}
			local kf_count = 0
			local pose_count = 0
			
			for _, kf_seq in pairs(target.AnimSaves:GetChildren()) do
				if kf_seq.ClassName == "KeyframeSequence" then
					local k, p = _g.RobloxKeyframeCount(kf_seq)
					kf_count = kf_count + k
					pose_count = pose_count + p
					table.insert(import_tbl, 1, {kf_seq})
					combo_map[kf_seq.Name] = kf_seq
				end
			end
			
			local function scan_combos()
				local combo_name = nil
				for Name, kf_seq in pairs(combo_map) do
					local get_num = tonumber(Name:match("%d+$"))
					if get_num and get_num > 0 then
						local get_name = Name:sub(1, #Name - #tostring(get_num))
						if combo_map[get_name..tostring(get_num - 1)] or combo_map[get_name..tostring(get_num + 1)] then
							combo_name = get_name
							break
						end
					end
				end
				if combo_name then
					local combo = {}
					for Name, kf_seq in pairs(combo_map) do
						local get_num = tonumber(Name:match("%d+$"))
						if get_num then
							local get_name = Name:sub(1, #Name - #tostring(get_num))
							if get_name == combo_name then
								table.insert(combo, get_num)
								combo_map[Name] = nil
							end
						end
					end
					table.sort(combo, function(a,b) return a<b end)
					table.insert(import_tbl, 1, {combo_name, combo})
				end
				return combo_name
			end while scan_combos() do end

			RigSelLabel.Text = RigSelLabel.Text.."\n"..tostring(#import_tbl).." Rig Animation"..(#import_tbl == 1 and "" or "s")
			RigSelLabel.Text = RigSelLabel.Text.."\n"..tostring(kf_count).." Keyframe"..(kf_count == 1 and "" or "s")
			RigSelLabel.Text = RigSelLabel.Text.."\n"..tostring(pose_count).." Pose"..(pose_count == 1 and "" or "s")
			
		else
			
			RigSelLabel.Text = RigSelLabel.Text.."\n0 Rig Animations"
			RigSelLabel.Text = RigSelLabel.Text.."\n0 Keyframes"
			RigSelLabel.Text = RigSelLabel.Text.."\n0 Poses"
			
		end
		GroupImport:SetEnabled(#import_tbl > 0)
		Import:SetList(import_tbl, nil, true)
	end
end
------------------------------------------------------------
do
	PlaybackHandler.PlayAreaMiddleCallback = function() 
		PlaybackHandler:SetPlayArea(math.floor(LayerSystem.ScrollFrame), math.floor(LayerSystem.ScrollFrame + LayerSystem.Zoom))
	end
	
	SelectionHandler.TrackItemDCCallback = function(TrackItem)
		if _g.objIsType(TrackItem, "Marker") then
			Win:OpenModal(_g.Windows.EditMarkers)
		else
			Win:OpenModal(_g.Windows.EditKeyframes)
		end
	end
	
	SelectionHandler.TrackDCCallback = function()
		DoCompositeAction("AddToSelectedTracks")
	end
	
	LayerSystem.NudgeTICallback = function(dir)
		SelectionHandler.MoveTrackItemCallback(SelectionHandler.SelectedTrackItems.Objects, dir)
	end
	
	LayerSystem.AddMoreCallback = function()
		DoCompositeAction("AddMoreFrames")
	end
	
	LayerSystem.AddPoseCallback = function()
		local item = LayerHandler.ActiveItemObject
		if item then
			local set_sel = {}
			SelectionHandler.SelectedTracks:Iterate(function(Track)
				if not Track.Enabled or Track.ItemObject ~= item or not _g.objIsType(Track, "KeyframeTrack") then
					SelectionHandler:_DeselectTrack(Track)
				end
			end)
			item.MainContainer:Iterate(function(KeyframeTrack)
				table.insert(set_sel, {KeyframeTrack, KeyframeTrack.selected})
				if KeyframeTrack.Enabled and not KeyframeTrack.selected then
					SelectionHandler:_SelectTrack(KeyframeTrack)
				end
			end, "KeyframeTrack")
			DoCompositeAction("AddToSelectedTracks")
			for _, tbl in pairs(set_sel) do
				if not tbl[2] then
					SelectionHandler:_DeselectTrack(tbl[1])
				end
			end
		end
	end
	
	SelectionHandler.MoveTrackItemCallback = function(TrackItems, delta)
		local Keyframes = {}
		local Markers = {}

		for _, TrackItem in pairs(TrackItems) do
			for pos = TrackItem.frm_pos + delta, TrackItem.frm_pos + delta + TrackItem.width, 1 do
				local col = TrackItem.ParentTrack.TrackItemPositions[pos]
				if (col and not SelectionHandler.SelectedTrackItems:Contains(col)) or pos > LayerSystem.length or pos < 0 then 
					for _, TI in pairs(TrackItems) do
						TI:_Position()
					end
					return
				end
			end
			if _g.objIsType(TrackItem, "Keyframe") then
				table.insert(Keyframes, TrackItem)
			elseif _g.objIsType(TrackItem, "Marker") then
				table.insert(Markers, TrackItem)
			end
		end

		local cmp = delta > 0 and function(a, b) return a.frm_pos > b.frm_pos end or function(a, b) return a.frm_pos < b.frm_pos end
		table.sort(Keyframes, cmp); table.sort(Markers, cmp)

		Win.DoCompositeAction("EditKeyframes", {TargetKeyframes = Keyframes, frmPosDelta = delta})
		Win.DoCompositeAction("EditMarkers", {TargetMarkers = Markers, frmPosDelta = delta})
	end

	SelectionHandler.TrackItemSelectionChanged = function(TrackItem, selected, SelectedTrackItems)
		local empty = SelectedTrackItems.size == 0
		_g.Input:SetActionDisabled("Cut", empty)
		_g.Input:SetActionDisabled("Copy", empty)
		_g.Input:SetActionDisabled("DeleteSelectedTrackItems", empty)
		
		_g.Input:SetActionDisabled("OpenRepeatFrames", empty)
		_g.Input:SetActionDisabled("OpenFillFrames", empty)
		
		local kfSelected = SelectionHandler.TrackItemTypeMap["Keyframe"]
		_g.Input:SetActionDisabled("OpenEditTrackItems", (not kfSelected and not SelectionHandler.TrackItemTypeMap["Marker"]))
		_g.Input:SetActionDisabled("GroupKeyframes", not kfSelected)
		_g.Input:SetActionDisabled("UngroupKeyframes", not kfSelected)
		_g.Input:SetActionDisabled("OpenUngroup", not kfSelected)
		
		_g.Input:SetActionDisabled("SplitKeyframe", not kfSelected)
	end

	SelectionHandler.TrackSelectionChanged = function(Track, selected, SelectedTracks)
		_g.Input:SetActionDisabled("AddToSelectedTracks", SelectedTracks.size == 0)
		_g.Input:SetActionDisabled("AddDefaultKeyframesToSelectedTracks", SelectionHandler.TrackTypeMap["KeyframeTrack"] == nil)
		
		if not selected and CurrentHandleTarget == Track then
			Win.SetHandleTarget(nil)
		elseif selected and CurrentHandleTarget == nil then
			if Track.part or _g.objIsType(Track, "BoneTrack") then
				PlaybackHandler:Stop()
				Win.SetHandleTarget(Track)
			end
		end
	end

	local Jumpable = {Model = true, Rig = true, BasePart = true}
	LayerHandler.ActiveItemObjectChanged = function(ItemObject)
		_g.Input:SetActionDisabled("ToggleOnionSkin", ItemObject == nil)
		_g.Input:SetActionDisabled("ToggleItemTracks", ItemObject == nil)
		_g.Input:SetActionDisabled("PasteIntoItem", ItemObject == nil or #copy_buffer == 0)
		
		_g.Input:SetActionDisabled("JumpCameraToItem", ItemObject == nil or not Jumpable[ItemObject.Path.ItemType])

		_g.Input:SetActionDisabled("PrevKeyframe", ItemObject == nil)
		_g.Input:SetActionDisabled("NextKeyframe", ItemObject == nil)
		
		_g.Input:SetActionDisabled("ReflectRig", ItemObject == nil or ItemObject.RigContainer == nil)
		_g.Input:SetActionDisabled("ToggleHandles", ItemObject == nil or ItemObject.RigContainer == nil)
	end

	LayerHandler.MoveItemCallback = function(from, to)
		Win.DoCompositeAction("EditItems", {ItemList = {LayerHandler.LayerContainer.Objects[from].ItemObject}, NewPos = to})
	end

	LayerHandler.EditItemCallback = function(ItemObject)
		LayerHandler:SetActiveItemObject(ItemObject)
		Win:OpenModal(_g.Windows.EditItem, ItemObject)
	end
	
	Win.OnOpen = function()
		Win.clear_selection()
		Win.NoFileSel()
		no_file_sel = game.Selection.SelectionChanged:Connect(Win.NoFileSel)
		SecondaryScreenGui.Parent = game:GetService("CoreGui")
		return true
	end

	Win.OnClose = function(args)
		if not args and LayerSystem.CurrentFile and file_dirty then
			_g.Windows.MsgBox.Popup(Win, 
				{
					Title = "Discard Changes", 
					Content = "Are you sure you want to close without saving?",
					Button1 = {
						"Yes",
						function()
							Win:Close(true)
						end
					}
				})
			return false
		else
			no_file_sel:Disconnect()
			no_file_sel = nil
			Win.clear_selection()
			if LayerSystem.CurrentFile then
				Win.CloseFile()
			end
			_g.Toggles.SetToggleValue("ROTGrid", false)
			SecondaryScreenGui.Parent = nil
			return true
		end
	end

	Win.OnModalOpen = function()
		PlaybackHandler:Stop()
		return true
	end
end
------------------------------------------------------------
do
	local no_file_size = nil
	local yes_file_size = nil
	
	Win.OpenFile = function(File, save_rig_sel)
		if Win.Visible == false then 
			Win:Open() 
		end
		if Win.Visible == false then return end
		
		if not save_rig_sel then
			grab_rig = nil
		end
		Win.clear_selection()
		local try = LayerSystem:OpenFile(File)
		
		if try then
			for _, action in pairs(FM_DEFAULT_ENABLE) do
				_g.Input:SetActionDisabled(action, false)
			end
			_g.Input:SetActionDisabled("Paste", LayerHandler.ActiveItemObject == nil or #copy_buffer == 0)
			_g.Input:SetActionDisabled("PasteIntoItem", LayerHandler.ActiveItemObject == nil or #copy_buffer == 0)
			Win:SetTitle(File.Name.." - "..WindowData.title)

			file_dirty = false
			Win:SetMouseEnabled(true)
			
			no_file_size = Win.UI.Size
			if yes_file_size then
				Win:SetSize(yes_file_size.X.Offset, yes_file_size.Y.Offset)
			end
			
			CloseFile.UI.Visible = true
			
			return true
		end

		return false
	end
	
	Win.RenameFile = function(name)
		LayerSystem.CurrentFile.Name = name
		Win:SetTitle(name.." - "..WindowData.title)
	end

	Win.CloseFile = function()
		Win:SetTitle(WindowData.title.." - Supported by Voldex!")
		CloseFile.UI.Visible = false
		LayerSystem:Reset()
		Win.ClearActionHistory()
		for _, action in pairs(FM_DEFAULT_DISABLE) do
			_g.Input:SetActionDisabled(action, true)
		end
		file_dirty = false
		Win:SetMouseEnabled(false)
		Win.clear_selection()
		if grab_rig then
			game.Selection:Set({grab_rig})
		end
		
		yes_file_size = Win.UI.Size
		if no_file_size then
			Win:SetSize(no_file_size.X.Offset, no_file_size.Y.Offset)
		end
	end

	Win.DirtyFile = function()
		assert(LayerSystem.CurrentFile)

		Win:SetTitle(LayerSystem.CurrentFile.Name.." * - "..WindowData.title)
		file_dirty = true
	end

	Win.SaveFile = function(force, close_after)
		assert(LayerSystem.CurrentFile)
		
		if not force and LayerSystem.CurrentFile.Parent == nil then
			Win:OpenModal(_g.Windows.SaveAs, {close_after = close_after})
			return false
		end

		LayerSystem:SaveFile()
		Win:SetTitle(LayerSystem.CurrentFile.Name.." - "..WindowData.title)
		file_dirty = false

		task.spawn(function()
			_g.ResetUndoRedo()
		end)
		
		if close_after then
			task.delay(0, function()
				Win.CloseFile()
			end)
		end
		
		return true
	end

	Win.PromptSave = function()
		if file_dirty and LayerSystem.CurrentFile then
			_g.Windows.MsgBox.Popup(Win, 
				{
					Title = "Save Changes",
					Content = "Do you want to save changes to '"..LayerSystem.CurrentFile.Name.."'?",
					Button1 = {
						"Yes",
						function()
							Win.SaveFile(false, true)
						end
					},
					Button2 = {
						"No",
						function()
							Win.CloseFile()
						end
					}
				})
			return false
		else
			Win.CloseFile()
			return true
		end
	end
	
	Win.apply_theme = function(theme, noTween)
		_g.Themer:QuickTween(Win.Contents.Background, noTween and 0 or 0.4, {ImageTransparency = 1})
		
		for paintName, paint in pairs(theme) do
			if string.sub(paintName, 1, 1) == "_" and type(paint[1]) == "string" then
				if paintName == "_bgOuter" and paint[1] and paint[2] and paint[3] then
					Win.Contents.Background.Image = paint[1]
					Win.Contents.Background.ScaleType = Enum.ScaleType[paint[2]]
					Win.Contents.Background.ResampleMode = Enum.ResamplerMode[paint[4] and paint[4] or "Default"]
					_g.Themer:QuickTween(Win.Contents.Background, noTween and 0 or 0.4, {ImageTransparency = 1 - paint[3]})
				end
			end
		end
	end
	
	table.insert(_g.Themer.theme_changed, Win.apply_theme)
	
	Win.GetBackground = function()
		return Win.Contents.Background
	end
end
------------------------------------------------------------
do
	do
		function FindItemObject(IO_Index)
			return LayerHandler.LayerContainer.Objects[IO_Index].ItemObject
		end

		function FindKeyframeTrack(IO_Index, KT_Target, KT_property)
			local MainContainer = FindItemObject(IO_Index).MainContainer
			local found_kf_track

			MainContainer:Iterate(function(KeyframeTrack)
				if KeyframeTrack.Target == KT_Target and KeyframeTrack.property == KT_property then
					found_kf_track = KeyframeTrack
					return false
				end
			end, "KeyframeTrack")

			return found_kf_track
		end

		function FindKeyframe(KeyframeTrack, KF_frm_pos)
			return KeyframeTrack.TrackItemPositions[KF_frm_pos]
		end

		function FindMarker(IO_Index, Marker_frm_pos)
			return FindItemObject(IO_Index).MarkerTrack.TrackItemPositions[Marker_frm_pos]
		end
	end

	local baseActions = {}
	local Keyframe_Obj = require(_g.class.Keyframe)
	local Marker_Obj = require(_g.class.Marker)
	local ItemObject_Obj = require(_g.class.ItemObject)
	local Ease_Obj = require(_g.class.Ease)
	do
		function baseActions.AddKeyframe(KeyframeTrack, data)
			local newKf = Keyframe_Obj.Detableize(data)
			KeyframeTrack:AddKeyframe(newKf)

			local IO_Index = LayerHandler.LayerContainer:IndexOf(KeyframeTrack.ItemObject.MainContainer)
			local KT_Target = KeyframeTrack.Target
			local KT_property = KeyframeTrack.property

			local KF_frm_pos = newKf.frm_pos

			return {
				ActionName = "Add Keyframe",
				has_sel_redo = true,
				Undo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					local Keyframe = FindKeyframe(KeyframeTrack, KF_frm_pos)
					baseActions.RemoveKeyframe(Keyframe)
					if data.JumpTo then
						LayerSystem.after_buffer = KF_frm_pos
					end
				end,
				Redo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					baseActions.AddKeyframe(KeyframeTrack, data)
					SelectionHandler:_SelectTrackItem(KeyframeTrack.TrackItemPositions[data.frm_pos])
					if data.JumpTo then
						LayerSystem.after_buffer = data.frm_pos
					end
				end,
			}
		end

		function baseActions.RemoveKeyframe(Keyframe, data)
			local KeyframeTrack = Keyframe.ParentTrack
			local oldData = Keyframe:Tableize()

			SelectionHandler:_DeselectTrackItem(Keyframe)
			Keyframe:Destroy()

			local IO_Index = LayerHandler.LayerContainer:IndexOf(KeyframeTrack.ItemObject.MainContainer)
			local KT_Target = KeyframeTrack.Target
			local KT_property = KeyframeTrack.property

			local KF_frm_pos = oldData.frm_pos

			return {
				ActionName = "Remove Keyframe",
				has_sel_undo = true,
				Undo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					baseActions.AddKeyframe(KeyframeTrack, oldData)
					SelectionHandler:_SelectTrackItem(KeyframeTrack.TrackItemPositions[oldData.frm_pos])
				end,
				Redo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					local Keyframe = FindKeyframe(KeyframeTrack, KF_frm_pos)
					baseActions.RemoveKeyframe(Keyframe)
				end,
			}
		end

		function baseActions.EditKeyframe(Keyframe, data)
			local KeyframeTrack = Keyframe.ParentTrack
			local oldData = {}

			if data.frmPosDelta then
				oldData.frm_pos = Keyframe.frm_pos
				KeyframeTrack:MoveKeyframe(Keyframe, Keyframe.frm_pos + data.frmPosDelta)
			elseif data.frm_pos then
				oldData.frm_pos = Keyframe.frm_pos
				KeyframeTrack:MoveKeyframe(Keyframe, data.frm_pos)
			end
			if data.ease then
				oldData.ease = Keyframe:GetEase():Tableize()
				Keyframe:SetEase(Ease_Obj.Detableize(data.ease))
				KeyframeTrack:InvalidateBuffer(Keyframe)
			end
			if data.TargetValues ~= nil then
				if type(data.TargetValues) == "table" then
					oldData.TargetValues = Keyframe.TargetValues
					Keyframe.TargetValues = data.TargetValues
				else
					oldData.TargetValues = Keyframe:GetTargetValue()
					Keyframe:SetTargetValue(data.TargetValues)
				end
				KeyframeTrack:InvalidateBuffer(Keyframe)
			end

			local IO_Index = LayerHandler.LayerContainer:IndexOf(KeyframeTrack.ItemObject.MainContainer)
			local KT_Target = KeyframeTrack.Target
			local KT_property = KeyframeTrack.property

			local KF_frm_pos = Keyframe.frm_pos
			local KF_old_frm_pos = oldData.frm_pos and oldData.frm_pos or KF_frm_pos

			return {
				ActionName = "Edit Keyframe",
				has_sel = true,
				Undo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					local Keyframe = FindKeyframe(KeyframeTrack, KF_frm_pos)
					baseActions.EditKeyframe(Keyframe, oldData)
					SelectionHandler:_SelectTrackItem(Keyframe)
					if data.JumpTo then
						LayerSystem.after_buffer = Keyframe.frm_pos
					end
				end,
				Redo = function()
					local KeyframeTrack = FindKeyframeTrack(IO_Index, KT_Target, KT_property)
					local Keyframe = FindKeyframe(KeyframeTrack, KF_old_frm_pos)
					baseActions.EditKeyframe(Keyframe, data)
					SelectionHandler:_SelectTrackItem(Keyframe)
					if data.JumpTo then
						LayerSystem.after_buffer = Keyframe.frm_pos
					end
				end,
			}
		end

		function baseActions.AddMarker(MarkerTrack, data)
			local newMarker = Marker_Obj.Detableize(data)
			MarkerTrack:AddMarker(newMarker)

			local IO_Index = LayerHandler.LayerContainer:IndexOf(MarkerTrack.ItemObject.MainContainer)
			local Marker_frm_pos = newMarker.frm_pos

			return {
				ActionName = "Add Marker",
				has_sel_redo = true,
				Undo = function()
					local Marker = FindMarker(IO_Index, Marker_frm_pos)
					baseActions.RemoveMarker(Marker)
					if data.JumpTo then
						LayerSystem.after_buffer = data.frm_pos
					end
				end,
				Redo = function()
					local MarkerTrack = FindItemObject(IO_Index).MarkerTrack
					baseActions.AddMarker(MarkerTrack, data)
					SelectionHandler:_SelectTrackItem(MarkerTrack.TrackItemPositions[data.frm_pos])
					if data.JumpTo then
						LayerSystem.after_buffer = Marker_frm_pos
					end
				end,
			}
		end

		function baseActions.RemoveMarker(Marker, data)
			local MarkerTrack = Marker.ParentTrack
			local oldData = Marker:Tableize()
			Marker:Destroy()

			local IO_Index = LayerHandler.LayerContainer:IndexOf(MarkerTrack.ItemObject.MainContainer)
			local Marker_frm_pos = oldData.frm_pos

			return {
				ActionName = "Remove Marker",
				has_sel_undo = true,
				Undo = function()
					local MarkerTrack = FindItemObject(IO_Index).MarkerTrack
					baseActions.AddMarker(MarkerTrack, oldData)
					SelectionHandler:_SelectTrackItem(MarkerTrack.TrackItemPositions[oldData.frm_pos])
				end,
				Redo = function()
					local Marker = FindMarker(IO_Index, Marker_frm_pos)
					baseActions.RemoveMarker(Marker)
				end,
			}
		end

		function baseActions.EditMarker(Marker, data)
			local MarkerTrack = Marker.ParentTrack
			local oldData = {}

			if data.frmPosDelta then
				oldData.frm_pos = Marker.frm_pos
				Marker.ParentTrack:MoveMarker(Marker, oldData.frm_pos + data.frmPosDelta)
			elseif data.frm_pos then
				oldData.frm_pos = Marker.frm_pos
				Marker.ParentTrack:MoveMarker(Marker, data.frm_pos)
			end
			if data.name then
				oldData.name = Marker.name
				Marker.name = data.name
			end
			if data.width then
				oldData.width = Marker.width
				Marker.ParentTrack:ResizeMarker(Marker, data.width)
			end
			if data.codeBegin then
				oldData.codeBegin = Marker.codeBegin
			 	Marker.codeBegin = data.codeBegin
			end
			if data.codeEnd then
				oldData.codeEnd = Marker.codeEnd
				Marker.codeEnd = data.codeEnd
			end
			if data.KFMarkers then
				oldData.KFMarkers = Marker.KFMarkers
				Marker.KFMarkers = data.KFMarkers
			end

			local IO_Index = LayerHandler.LayerContainer:IndexOf(MarkerTrack.ItemObject.MainContainer)
			local Marker_frm_pos = Marker.frm_pos
			local Marker_old_frm_pos = oldData.frm_pos and oldData.frm_pos or Marker_frm_pos

			return {
				ActionName = "Edit Marker",
				has_sel = true,
				Undo = function()
					local Marker = FindMarker(IO_Index, Marker_frm_pos)
					baseActions.EditMarker(Marker, oldData)
					SelectionHandler:_SelectTrackItem(Marker)
				end,
				Redo = function()
					local Marker = FindMarker(IO_Index, Marker_old_frm_pos)
					baseActions.EditMarker(Marker, data)
					SelectionHandler:_SelectTrackItem(Marker)
				end,
			}
		end

		function baseActions.AddItem(data)
			local ItemObject = ItemObject_Obj.ItemFactory(LayerSystem, data.Item, data.PropList, data.MarkerTrack)
			LayerHandler:AddItemObject(ItemObject)

			local IO_Index = LayerHandler.LayerContainer:IndexOf(ItemObject.MainContainer)

			return {
				ActionName = "Add Item",
				Undo = function()
					local ItemObject = FindItemObject(IO_Index)
					LayerHandler:RemoveItemObject(ItemObject)
				end,
				Redo = function()
					baseActions.AddItem(data)
				end,
			}
		end

		function baseActions.RemoveItem(ItemObject)
			local oldData, oldFolder = ItemObject:Serialize()

			local IO_Index = LayerHandler.LayerContainer:IndexOf(ItemObject.MainContainer)
			LayerHandler:RemoveItemObject(ItemObject)

			return {
				ActionName = "Remove Item",
				Undo = function()
					local ItemObject = ItemObject_Obj.Deserialize(LayerSystem, oldData, oldFolder)
					LayerHandler:InsertItemObject(ItemObject, IO_Index)
				end,
				Redo = function()
					local ItemObject = FindItemObject(IO_Index)
					LayerHandler:RemoveItemObject(ItemObject)
				end,
			}
		end

		function baseActions.EditItem(ItemObject, data)
			local oldData = {}

			if data.PropList then
				oldData.PropList = {}

				local PropDict = {}
					for _, prop in pairs(data.PropList) do
						PropDict[prop] = true
					end

				local rem = {}
				for prop, _ in pairs(ItemObject.PropertyMap) do
					table.insert(oldData.PropList, prop)
					if PropDict[prop] == nil then
						table.insert(rem, prop)
					end
				end
				if ItemObject.RigContainer then
					table.insert(oldData.PropList, 1, "Rig")
					if PropDict["Rig"] == nil then
						table.insert(rem, "Rig")
					end
				end

				local add = {}
				for prop, _ in pairs(PropDict) do
					if prop ~= "Rig" and ItemObject.PropertyMap[prop] == nil then
						table.insert(add, prop)
					end
				end
				if ItemObject.RigContainer == nil and PropDict["Rig"] then
					table.insert(add, "Rig")
				end

				for _, prop in pairs(rem) do
					if prop == "Rig" then
						ItemObject:RemoveRig()
					else
						ItemObject:RemoveProperty(prop)
					end
				end
				for _, prop in pairs(add) do
					if prop == "Rig" then
						ItemObject:AddRig()
					else
						ItemObject:AddProperty(prop)
					end
				end
			end
			if data.NewPos then
				oldData.NewPos = LayerHandler.LayerContainer:IndexOf(ItemObject.MainContainer)
				LayerHandler:MoveItemObject(oldData.NewPos, data.NewPos)
			end
			if data.MarkerTrack ~= nil then
				if data.MarkerTrack and not ItemObject.MarkerTrack then
					oldData.MarkerTrack = false
					ItemObject:AddEventTrack()
				elseif not data.MarkerTrack and ItemObject.MarkerTrack then
					oldData.MarkerTrack = true
					ItemObject:RemoveEventTrack()
				end
			end

			if data.PropList or data.MarkerTrack ~= nil then
				LayerHandler:_GetAllLayerSystemItems()
			end

			local IO_Index = LayerHandler.LayerContainer:IndexOf(ItemObject.MainContainer)
			local IO_old_Index = oldData.NewPos and oldData.NewPos or IO_Index
			
			return {
				ActionName = "Edit Item",
				Undo = function()
					local ItemObject = FindItemObject(IO_Index)
					baseActions.EditItem(ItemObject, oldData)
				end,
				Redo = function()
					local ItemObject = FindItemObject(IO_old_Index)
					baseActions.EditItem(ItemObject, data)
				end,
			}
		end

		function baseActions.EditAnimationSettings(data)
			local oldData = {}
			
			if data.Priority ~= nil then
				oldData.Priority = LayerSystem.ExportPriority
				LayerSystem.ExportPriority = data.Priority
			end
			if data.Loop ~= nil then
				oldData.Loop = PlaybackHandler.Loop
				PlaybackHandler:SetLoop(data.Loop)
			end
			if data.length then
				oldData.length = LayerSystem.length
				LayerSystem:SetTimelineLength(data.length)
			end
			if data.FPS then
				oldData.FPS = LayerSystem.FPS
				LayerSystem:SetFPS(data.FPS)
			end
			if data.FileName then
				oldData.FileName = LayerSystem.CurrentFile.Name
				Win.RenameFile(data.FileName)
			end

			return {
				ActionName = "Edit Animation Settings",
				Undo = function()
					baseActions.EditAnimationSettings(oldData)
				end,
				Redo = function()
					baseActions.EditAnimationSettings(data)
				end,
			}
		end

		function baseActions.ChangeCameraReferencePart(part)
			local oldRef = LayerSystem.CameraReferencePart
			LayerSystem.CameraReferencePart = part

			return {
				ActionName = "Change Camera Reference Part",
				Undo = function()
					baseActions.ChangeCameraReferencePart(oldRef)
				end,
				Redo = function()
					baseActions.ChangeCameraReferencePart(part)
				end,
			}
		end
	end

	Win.compositeActions = {}
	local compositeActions = Win.compositeActions
	do
		function compositeActions.AddToTracks(args)
			local actionSeq = {}

			local deselected = false
			for ind, Track in pairs(args.Tracks) do
				if _g.objIsType(Track, "KeyframeTrack") then
					local newValue
					if args.default then
						newValue = Track.defaultValue
					else
						newValue = Track:get_prop()
					end
					if newValue == nil then newValue = _g.NIL_VALUE end
					
					local conflictKeyframe = Track.TrackItemPositions[LayerSystem.SliderFrame]
					if conflictKeyframe then
						if not conflictKeyframe.group then
							if conflictKeyframe:GetTargetValue() ~= newValue then
								table.insert(actionSeq, baseActions.EditKeyframe(conflictKeyframe, {TargetValues = newValue, JumpTo = ind == 1}))
							end
							if not deselected then
								deselected = true
								SelectionHandler:SetTrackItemSelection({})
							end
							SelectionHandler:_SelectTrackItem(conflictKeyframe)
						elseif conflictKeyframe.group then
							Track.previous_value = nil
							Track:_Update(LayerSystem.SliderFrame)
						end
					else
						local EaseMap
						if _g.use_last_ease then
							local get_ease = Track:from_frame(LayerSystem.SliderFrame)
							if get_ease then
								EaseMap = get_ease.EaseMap[0]:Tableize()
							end
						end
						table.insert(actionSeq, baseActions.AddKeyframe(Track, {frm_pos = LayerSystem.SliderFrame, TargetValues = newValue, EaseMap = EaseMap, JumpTo = ind == 1}))
						if not deselected then
							deselected = true
							SelectionHandler:SetTrackItemSelection({})
						end
						SelectionHandler:_SelectTrackItem(Track.TrackItemPositions[LayerSystem.SliderFrame])
					end
				elseif _g.objIsType(Track, "MarkerTrack") then
					if Track.TrackItemPositions[LayerSystem.SliderFrame] == nil then
						table.insert(actionSeq, baseActions.AddMarker(Track, {frm_pos = LayerSystem.SliderFrame, JumpTo = ind == 1}))
						if not deselected then
							deselected = true
							SelectionHandler:SetTrackItemSelection({})
						end
						SelectionHandler:_SelectTrackItem(Track.TrackItemPositions[LayerSystem.SliderFrame])
					end
				end
			end

			return actionSeq
		end

		function compositeActions.AddToSelectedTracks(args)
			if args == nil then args = {} end
			local get_sel = {}
			SelectionHandler.SelectedTracks:Iterate(function(Track) table.insert(get_sel, Track) end)
			return compositeActions.AddToTracks({Tracks = get_sel, default = args.default})
		end

		function compositeActions.AddTrackItems(args)
			local actionSeq = {}

			for _, tbl in pairs(args.TrackTbl) do
				for _, data in pairs(tbl.TrackItems) do
					if data._tblType == "Keyframe" then
						table.insert(actionSeq, baseActions.AddKeyframe(tbl.Track, data))
					elseif data._tblType == "Marker" then
						table.insert(actionSeq, baseActions.AddMarker(tbl.Track, data))
					end
				end
			end

			return actionSeq
		end

		function compositeActions.DeleteTrackItems(args)
			local actionSeq = {}

			local final = {}
			for _, TrackItem in pairs(args.TrackItems) do
				table.insert(final, TrackItem)
			end
			for _, TrackItem in pairs(final) do
				if _g.objIsType(TrackItem, "Keyframe") then
					table.insert(actionSeq, baseActions.RemoveKeyframe(TrackItem))
				elseif _g.objIsType(TrackItem, "Marker") then
					table.insert(actionSeq, baseActions.RemoveMarker(TrackItem))
				end
			end

			return actionSeq
		end

		function compositeActions.DeleteSelectedTrackItems()
			return compositeActions.DeleteTrackItems({TrackItems = SelectionHandler.SelectedTrackItems.Objects})
		end

		function compositeActions.FitTimeline()
			return {baseActions.EditAnimationSettings({length = LayerHandler:GetLastKeyframePosition()})}
		end
		
		function compositeActions.AddMoreFrames()
			return {baseActions.EditAnimationSettings({length = LayerSystem.length + LayerSystem.FPS})}
		end
		
		function compositeActions.SplitKeyframes()
			local actionSeq = {}
			
			local target_kfs = {}
			SelectionHandler.SelectedTrackItems:Iterate(function(Keyframe)
				table.insert(target_kfs, Keyframe)
			end, "Keyframe")
			table.sort(target_kfs, function(a, b) return a.frm_pos < b.frm_pos end)
			
			local stride = LayerSystem.split_size
			
			for _, kf in pairs(target_kfs) do
				local left = kf.frm_pos - stride
				local right = kf.frm_pos + stride
				if left >= 0 then
					left = (not kf.ParentTrack:IsPosTaken(left, kf.frm_pos - 1)) and left or false
				else
					left = false
				end
				if right <= LayerSystem.length then
					right = (not kf.ParentTrack:IsPosTaken(kf.frm_pos + 1, right)) and right or false
				else
					right = false
				end
				if left or right then
					local track = kf.ParentTrack
					local ease = kf.EaseMap[0]:Tableize()
					table.insert(actionSeq, baseActions.RemoveKeyframe(kf))
					if left then
						table.insert(actionSeq, baseActions.AddKeyframe(track, {frm_pos = left, TargetValues = track.BufferMap[left], EaseMap = ease}))
					end
					if right then
						table.insert(actionSeq, baseActions.AddKeyframe(track, {frm_pos = right, TargetValues = track.BufferMap[right] and track.BufferMap[right] or track.BufferMap[track.lastFrame], EaseMap = ease}))
					end
				end
			end
			
			return actionSeq
		end

		function compositeActions.GroupKeyframes()
			local actionSeq = {}

			local TargetTracks = {}
			local SelectedTrackItems = SelectionHandler.SelectedTrackItems

			SelectionHandler.SelectedTrackItems:Iterate(function(Keyframe)
				local index = Keyframe.ParentTrack.TrackItems:IndexOf(Keyframe)
				local tbl = TargetTracks[tostring(Keyframe.ParentTrack)] 
				if tbl == nil then
					TargetTracks[tostring(Keyframe.ParentTrack)]  = {index, index, KeyframeTrack = Keyframe.ParentTrack}
				else
					if index < tbl[1] then
						tbl[1] = index
					elseif index > tbl[2] then
						tbl[2] = index
					end
				end
			end, "Keyframe")

			for _, tbl in pairs(TargetTracks) do
				if tbl[1] < tbl[2] then
					local ini = tbl.KeyframeTrack.TrackItems.Objects[tbl[1]].frm_pos
					local TargetValues = {}
					local EaseMap = {}

					for _ = tbl[1], tbl[2], 1 do
						local Keyframe = tbl.KeyframeTrack.TrackItems.Objects[tbl[1]]
						for pos, val in pairs(Keyframe.TargetValues) do
							TargetValues[(pos + Keyframe.frm_pos) - ini] = val
							EaseMap[(pos + Keyframe.frm_pos) - ini] = Keyframe.EaseMap[pos]:Tableize()
						end
						table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
					end

					table.insert(actionSeq, baseActions.AddKeyframe(tbl.KeyframeTrack, {frm_pos = ini, EaseMap = EaseMap, TargetValues = TargetValues}))
				end
			end

			return actionSeq
		end

		function compositeActions.UngroupKeyframes(args)
			local actionSeq = {}

			local TargetKeyframes = args.TargetKeyframes
			local minPos = args.minPos
			local maxPos = args.maxPos
			
			for _, Keyframe in pairs(TargetKeyframes) do
				local KeyframeTrack = Keyframe.ParentTrack
				local kfFrmPos = Keyframe.frm_pos

				if args.InRange then
					local LeftBreakValues
					local LeftBreakEases

					local Middle = {}

					local RightBreakValues
					local RightBreakEases

					Keyframe:IterateTargetValues(function(pos, value, ease, actPos)
						if actPos >= minPos and actPos <= maxPos then
							table.insert(Middle, {frm_pos = actPos, TargetValues = value, EaseMap = ease:Tableize()})
						elseif actPos < minPos then
							if LeftBreakValues == nil then
								LeftBreakValues = {startPos = pos}
								LeftBreakEases = {}
							end
							LeftBreakValues[pos - LeftBreakValues.startPos] = value
							LeftBreakEases[pos - LeftBreakValues.startPos] = ease:Tableize()
						elseif actPos > maxPos then
							if RightBreakValues == nil then
								RightBreakValues = {startPos = pos}
								RightBreakEases = {}
							end
							RightBreakValues[pos - RightBreakValues.startPos] = value
							RightBreakEases[pos - RightBreakValues.startPos] = ease:Tableize()
						end
					end)

					table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))

					if LeftBreakValues then
						local startPos = LeftBreakValues.startPos
						LeftBreakValues.startPos = nil
						table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, {frm_pos = startPos + kfFrmPos, TargetValues = LeftBreakValues, EaseMap = LeftBreakEases}))
					end
					if not args.Delete then
						for _, kf in pairs(Middle) do
							table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, kf))
						end
					end
					if RightBreakValues then
						local startPos = RightBreakValues.startPos
						RightBreakValues.startPos = nil
						table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, {frm_pos = startPos + kfFrmPos, TargetValues = RightBreakValues, EaseMap = RightBreakEases}))
					end
				else
					local Left = {}

					local MiddleBreakValues
					local MiddleBreakEases

					local Right = {}

					Keyframe:IterateTargetValues(function(pos, value, ease, actPos)
						if actPos >= minPos and actPos <= maxPos then
							if MiddleBreakValues == nil then
								MiddleBreakValues = {startPos = pos}
								MiddleBreakEases = {}
							end
							MiddleBreakValues[pos - MiddleBreakValues.startPos] = value
							MiddleBreakEases[pos - MiddleBreakValues.startPos] = ease:Tableize()
						elseif actPos < minPos then
							table.insert(Left, {frm_pos = actPos, TargetValues = value, EaseMap = ease:Tableize()})
						elseif actPos > maxPos then
							table.insert(Right, {frm_pos = actPos, TargetValues = value, EaseMap = ease:Tableize()})
						end
					end)

					table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))

					if not args.Delete then
						for _, kf in pairs(Left) do
							table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, kf))
						end
					end
					if MiddleBreakValues then
						local startPos = MiddleBreakValues.startPos
						MiddleBreakValues.startPos = nil
						table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, {frm_pos = startPos + kfFrmPos, TargetValues = MiddleBreakValues, EaseMap = MiddleBreakEases}))
					end
					if not args.Delete then
						for _, kf in pairs(Right) do
							table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, kf))
						end
					end
				end
			end

			return actionSeq
		end

		function compositeActions.EditAnimationSettings(args)
			local actionSeq = {}

			local OldFPS = LayerSystem.FPS

			if args.StretchFPS then
				SelectionHandler:SelectAll()
				local TrackData, TargetTrackItems, PropertyType, IniFrmPos, LastFrmPos = SelectionHandler:GetFromToSelectionData(true)
				local stretchSeq = Win.compositeActions.Stretch({TrackData = TrackData, TargetTrackItems = TargetTrackItems, Factor = args.FPS / OldFPS, IniFrmPos = IniFrmPos})
				for _, tbl in pairs(stretchSeq) do
					table.insert(actionSeq, tbl)
				end
				args.length = nil
				SelectionHandler:DeselectAll()
			end
			table.insert(actionSeq, baseActions.EditAnimationSettings(args))

			return actionSeq
		end

		function compositeActions.EditKeyframes(args)
			local actionSeq = {}
			
			if type(args.TargetValues) == "table" then
				for ind, Keyframe in pairs(args.TargetKeyframes) do
					table.insert(actionSeq, baseActions.EditKeyframe(Keyframe, {frmPosDelta = args.frmPosDelta, ease = args.ease, TargetValues = args.TargetValues[ind]}))
				end
			else
				for _, Keyframe in pairs(args.TargetKeyframes) do
					table.insert(actionSeq, baseActions.EditKeyframe(Keyframe, args))
				end
			end

			return actionSeq
		end

		function compositeActions.EditMarkers(args)
			local actionSeq = {}

			for _, Marker in pairs(args.TargetMarkers) do
				table.insert(actionSeq, baseActions.EditMarker(Marker, args))
			end

			return actionSeq
		end

		function compositeActions.AddItems(args)
			local actionSeq = {}

			for _, Item in pairs(args.ItemList) do
				table.insert(actionSeq, baseActions.AddItem({Item = Item, PropList = args.PropList, MarkerTrack = args.MarkerTrack}))
			end

			return actionSeq
		end

		function compositeActions.RemoveItems(args)
			local actionSeq = {}

			for _, Item in pairs(args.ItemList) do
				table.insert(actionSeq, baseActions.RemoveItem(Item))
			end

			return actionSeq
		end

		function compositeActions.EditItems(args)
			local actionSeq = {}

			for _, Item in pairs(args.ItemList) do
				table.insert(actionSeq, baseActions.EditItem(Item, {PropList = args.PropList, NewPos = args.NewPos, MarkerTrack = args.MarkerTrack}))
			end

			return actionSeq
		end

		function compositeActions.Import(args)
			local actionSeq = {}
	
			for _, ItemObject in pairs(args.ItemObjects) do
				if ItemObject.Path:GetItem() then
					local convert, length, ani_events, face_ani = _g.RobloxToSimple(args.TargetKeyframeSequence, ItemObject.Path.Item, LayerSystem.FPS)
					if convert == nil then
						break
					end
					
					if args.Face == false then
						face_ani = {}
					end
					if args.Events == false then
						ani_events = {}
					end
					
					SelectionHandler:DeselectAll()
					
					local has_markers = next(ani_events)
					local has_face = next(face_ani)

					local start
					if args.Replace ~= false then
						ItemObject.RigContainer:Iterate(function(KeyframeTrack)
							KeyframeTrack.TrackItems:Iterate(function(Keyframe)
								table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
							end)
						end, "KeyframeTrack")
						if has_markers and ItemObject.MarkerTrack then
							ItemObject.MarkerTrack.TrackItems:Iterate(function(Marker)
								table.insert(actionSeq, baseActions.RemoveMarker(Marker))
							end)
						end
						start = 0
					else
						start = LayerHandler.LayerSystem.SliderFrame
					end
					if has_face then
						for id, data in pairs(face_ani) do
							if LayerHandler.ItemMap[id] then
								table.insert(actionSeq, baseActions.RemoveItem(LayerHandler.ItemMap[id]))
							end
						end
					end
					
					if start + length > LayerHandler.LayerSystem.length then
						table.insert(actionSeq, baseActions.EditAnimationSettings({length = start + length}))
					end
					if has_markers and not ItemObject.MarkerTrack then
						table.insert(actionSeq, baseActions.EditItem(ItemObject, {MarkerTrack = true}))
					end
					
					local function add_keyframes(KeyframeTrack, data, is_motor)
						local allPos = {}
						local find_start
						for pos, _ in pairs(data.TargetValues) do
							table.insert(allPos, pos)
						end
						table.sort(allPos, function(a, b) return a < b end)
						find_start = allPos[1]
						
						local newTV = {}
						local newEaseMap = {}
						for _, pos in pairs(allPos) do
							local val = data.TargetValues[pos]
							newTV[pos - find_start] = is_motor and (val * KeyframeTrack.defaultValue:Inverse()):Inverse() or val
							newEaseMap[pos - find_start] = data.Easing[pos]
						end
						
						if #allPos > 0 and not KeyframeTrack:IsPosTaken(start + find_start, start + allPos[#allPos]) then
							if args.Group ~= false then
								table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, {frm_pos = start + find_start, TargetValues = newTV, EaseMap = newEaseMap}))
								SelectionHandler:_SelectTrackItem(KeyframeTrack.TrackItemPositions[start + find_start])
							else
								for ind, pos in pairs(allPos) do
									table.insert(actionSeq, baseActions.AddKeyframe(KeyframeTrack, {frm_pos = start + pos, TargetValues = newTV[pos - find_start], EaseMap = newEaseMap[pos - find_start]}))
								end
							end
						end
					end
					
					if has_face then
						for id, data in pairs(face_ani) do
							if LayerHandler.ItemMap[id] == nil then
								local prop_list = {}
								for id, _ in pairs(data.Properties) do
									table.insert(prop_list, id)
								end
								if #prop_list > 0 then
									table.insert(actionSeq, baseActions.AddItem({Item = data.FaceControls, PropList = prop_list}))
									local get_fc = LayerHandler.ItemMap[id]
									get_fc.ObjectLabel:Collapse(true)
									for prop, track in pairs(get_fc.PropertyMap) do
										if data.Properties[prop] then
											add_keyframes(track, data.Properties[prop])
										end
									end
								end
							end
						end
					end

					ItemObject.RigContainer:Iterate(function(KeyframeTrack)
						local data = convert[KeyframeTrack.Target:GetDebugId(8)]
						if data then
							add_keyframes(KeyframeTrack, data, _g.objIsType(KeyframeTrack, "MotorTrack"))
						end
					end, "KeyframeTrack")
					
					if has_markers then
						for frm_pos, events in pairs(ani_events) do
							local act_pos = frm_pos + start
							local get_name = events.name; if get_name then events.name = nil end
							local get_events = next(events) and events or nil
							if not ItemObject.MarkerTrack:IsPosTaken(act_pos, act_pos) then
								table.insert(actionSeq, baseActions.AddMarker(ItemObject.MarkerTrack, {frm_pos = act_pos, KFMarkers = get_events, name = get_name}))
							end
						end
					end
				end
			end

			return actionSeq
		end

		local wiggleFuncs = {}
		function wiggleFuncs:number(value, Params)
			local upper = math.abs(Params.number_Mag)
			local lower = Params.MinZero and 0 or -upper
			return value + math.random(lower * 1024, upper * 1024) / 1024
		end
		function wiggleFuncs:NumberSequence(value, Params)
			return NumberSequence.new(self:number(value.Keypoints[1].Value, Params))
		end
		function wiggleFuncs:NumberRange(value, Params)
			local res = self:number(value.Min, Params)
			return NumberRange.new(res, res)
		end
		function wiggleFuncs:boolean(value, Params)
			return math.random() < Params.boolean_Prob
		end
		function wiggleFuncs:Vector3(value, Params)
			return Vector3.new(self:number(value.X, {number_Mag = Params.Vector3_Mag.X}), self:number(value.Y, {number_Mag = Params.Vector3_Mag.Y}), self:number(value.Z, {number_Mag = Params.Vector3_Mag.Z}))
		end
		function wiggleFuncs:string(value, Params)
			local new_str = ""
			for i = 1, #value do
				local cur_char = value:sub(i,i)
				local code = string.byte(cur_char)
				if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) then
					local rand_char = string.char(math.clamp(code + math.random(-Params.string_Mag, Params.string_Mag), 33, 126))
					new_str = new_str..rand_char
				else
					new_str = new_str..cur_char
				end
			end
			return new_str
		end
		function wiggleFuncs:Vector2(value, Params)
			return Vector2.new(self:number(value.X, {number_Mag = Params.Vector2_Mag.X}), self:number(value.Y, {number_Mag = Params.Vector2_Mag.Y}))
		end
		function wiggleFuncs:Color3(value, Params)
			return Color3.new(self:number(value.r, {number_Mag = Params.Color3_Mag.r}), self:number(value.g, {number_Mag = Params.Color3_Mag.g}), self:number(value.b, {number_Mag = Params.Color3_Mag.b}))
		end
		function wiggleFuncs:ColorSequence(value, Params)
			return ColorSequence.new(self:Color3(value.Keypoints[1].Value, Params))
		end
		function wiggleFuncs:CFrame(value, Params)
			local angles = CFrame.Angles(self:number(0, {number_Mag = math.rad(Params.CFrame_Mag.AngleX.Value)}), self:number(0, {number_Mag = math.rad(Params.CFrame_Mag.AngleY.Value)}), self:number(0, {number_Mag = math.rad(Params.CFrame_Mag.AngleZ.Value)}))
			local pos = Vector3.new(self:number(0, {number_Mag = Params.CFrame_Mag.X.Value}), self:number(0, {number_Mag = Params.CFrame_Mag.Y.Value}), self:number(0, {number_Mag = Params.CFrame_Mag.Z.Value}))
			return (value * angles) + pos
		end

		function compositeActions.FillFrames(args)
			local actionSeq = {}

			local delKeyframes = {}
			for _, tbl in pairs(args.TrackData) do
				if tbl.From ~= tbl.To then
					local nextkf = tbl.From.ParentTrack:GetNextTrackItem(tbl.From)
					while nextkf ~= tbl.To do
						table.insert(delKeyframes, nextkf)
						nextkf = tbl.From.ParentTrack:GetNextTrackItem(nextkf)
					end
				end
			end
			for _, Keyframe in pairs(delKeyframes) do
				table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
			end
			
			local wiggle = args.Params ~= nil

			for _, tbl in pairs(args.TrackData) do
				if tbl.From ~= tbl.To then

					local start = tbl.From.frm_pos + tbl.From.width
					local TargetValues = {}
					local EaseMap = {}
					local tvPos = 0
					for curPos = start + args.Interval, tbl.To.frm_pos - 1, args.Interval do
						TargetValues[tvPos] = wiggle and wiggleFuncs[args.PropertyType](wiggleFuncs, tbl.Track.BufferMap[curPos], args.Params) or tbl.Track.BufferMap[curPos]
						EaseMap[tvPos] = args.Ease
						tvPos = tvPos + args.Interval
					end
					if TargetValues[0] ~= nil then
						table.insert(actionSeq, baseActions.AddKeyframe(tbl.Track, {frm_pos = start + args.Interval, TargetValues = TargetValues, EaseMap = EaseMap}))
						SelectionHandler:_SelectTrackItem(tbl.Track.TrackItemPositions[start + args.Interval])
					end
					
				end
			end

			return actionSeq
		end

		function compositeActions.RepeatFrames(args)
			local actionSeq = {}

			local increaseLength = nil
			for _, tbl in pairs(args.TrackData) do
				local lastPos = tbl.Track:GetLastFramePosition() + args.LoopLength
				if lastPos > LayerSystem.length and (increaseLength == nil or lastPos - LayerSystem.length > increaseLength) then
					increaseLength = lastPos - LayerSystem.length
				end
			end
			if increaseLength then
				table.insert(actionSeq, baseActions.EditAnimationSettings({length = LayerSystem.length + increaseLength}))
			end

			for _, tbl in pairs(args.TrackData) do
				local pushTo = tbl.To

				local offsetKeyframes = {}
				while true do
					pushTo = pushTo.ParentTrack:GetNextTrackItem(pushTo)
					if pushTo == nil then break end
					table.insert(offsetKeyframes, 1, pushTo)
				end
				for _, Keyframe in pairs(offsetKeyframes) do
					table.insert(actionSeq, baseActions.EditKeyframe(Keyframe, {frmPosDelta = args.LoopLength}))
				end

				local len = args.To - args.From
				local TargetValues = {}
				for pos = 0, args.LoopLength - 1, 1 do
					TargetValues[pos] = tbl.Track.BufferMap[(args.From + 1) + pos % len]
				end
				if TargetValues[0] ~= nil then
					table.insert(actionSeq, baseActions.AddKeyframe(tbl.Track, {frm_pos = args.To + 1, TargetValues = TargetValues}))
				end
			end

			return actionSeq
		end

		function compositeActions.AdjustCameraRef(args)
			local actionSeq = {}
			table.insert(actionSeq, baseActions.ChangeCameraReferencePart(args.Part))
			return actionSeq
		end

		function compositeActions.ReflectRig(args)
			local actionSeq = {}

			local ItemObject = args.ItemObject
			if ItemObject.RigContainer then
				local TrackTbl = {}
				
				local function check_track(key, str_1, str_2)
					local leftVer = key:gsub(str_1, str_2)
					local rightVer = key:gsub(str_2, str_1)
					if leftVer ~= rightVer and TrackTbl[leftVer] == nil and ItemObject.RigMap[leftVer] and ItemObject.RigMap[rightVer]  then
						TrackTbl[leftVer] = {Left = ItemObject.RigMap[leftVer], Right = ItemObject.RigMap[rightVer]}
					end
				end

				for key, Track in pairs(ItemObject.RigMap) do
					check_track(key, "Right", "Left")
					check_track(key, "\.R", "\.L")
					check_track(key, "_R", "_L")
				end

				for _, Tracks in pairs(TrackTbl) do
					local left_kfs = {}
					Tracks.Left.TrackItems:Iterate(function(Keyframe)
						table.insert(left_kfs, Keyframe:Tableize())
						table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
					end)

					local right_kfs = {}
					Tracks.Right.TrackItems:Iterate(function(Keyframe)
						table.insert(right_kfs, Keyframe:Tableize())
						table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
					end)

					for _, kfTbl in pairs(left_kfs) do
						table.insert(actionSeq, baseActions.AddKeyframe(Tracks.Right, kfTbl))
					end
					for _, kfTbl in pairs(right_kfs) do
						table.insert(actionSeq, baseActions.AddKeyframe(Tracks.Left, kfTbl))
					end
				end

				for _, Track in pairs(ItemObject.RigMap) do
					Track.TrackItems:Iterate(function(Keyframe)
						local newTV = {}
						for ind, val in pairs(Keyframe.TargetValues) do
							newTV[ind] = _g.reflect(val)
						end
						table.insert(actionSeq, baseActions.EditKeyframe(Keyframe, {TargetValues = newTV}))
					end)
				end
			end

			return actionSeq
		end

		function compositeActions.Stretch(args)
			local actionSeq = {}

			local function ComputeStretch(frm_pos)
				return math.floor((frm_pos - args.IniFrmPos) * args.Factor + 0.5) + args.IniFrmPos
			end

			local increaseLength = nil
			for _, tbl in pairs(args.TrackData) do
				tbl.StretchBy = ComputeStretch(tbl.To.frm_pos + tbl.To.width) - (tbl.To.frm_pos + tbl.To.width)
				local lastPos = tbl.Track:GetLastFramePosition() + tbl.StretchBy
				if lastPos > LayerSystem.length and (increaseLength == nil or lastPos - LayerSystem.length > increaseLength) then
					increaseLength = lastPos - LayerSystem.length
				end
				tbl.AfterTo = {}
				local cur = tbl.Track:GetNextTrackItem(tbl.To)
				while cur ~= nil do
					table.insert(tbl.AfterTo, cur)
					cur = tbl.Track:GetNextTrackItem(cur)
				end
			end
			if increaseLength then
				table.insert(actionSeq, baseActions.EditAnimationSettings({length = LayerSystem.length + increaseLength}))
			end

			local TI_tbls = {}

			for _, TrackItem in pairs(args.TargetTrackItems) do
				if TrackItem.frm_pos + TrackItem.width > args.IniFrmPos then
					table.insert(TI_tbls, {Track = TrackItem.ParentTrack, tiTbl = TrackItem:Tableize()})
					if _g.objIsType(TrackItem, "Keyframe") then 
						table.insert(actionSeq, baseActions.RemoveKeyframe(TrackItem, {select = true}))
					elseif _g.objIsType(TrackItem, "Marker") then 
						table.insert(actionSeq, baseActions.RemoveMarker(TrackItem, {select = true}))
					end
				elseif TrackItem.frm_pos + TrackItem.width == args.IniFrmPos then
					if _g.objIsType(TrackItem, "Keyframe") then 
						table.insert(actionSeq, baseActions.EditKeyframe(TrackItem, {frmPosDelta = 0}))
					elseif _g.objIsType(TrackItem, "Marker") then 
						table.insert(actionSeq, baseActions.EditMarker(TrackItem, {frmPosDelta = 0}))
					end
				end
			end

			table.sort(TI_tbls, function(a, b) return a.tiTbl.frm_pos < b.tiTbl.frm_pos end)

			for _, tbl in pairs(args.TrackData) do
				if tbl.StretchBy > 0 then
					table.sort(tbl.AfterTo, function(a, b) return a.frm_pos > b.frm_pos end)
				else
					table.sort(tbl.AfterTo, function(a, b) return a.frm_pos < b.frm_pos end)
				end
				for _, TrackItem in pairs(tbl.AfterTo) do
					if _g.objIsType(TrackItem, "Keyframe") then 
						table.insert(actionSeq, baseActions.EditKeyframe(TrackItem, {frmPosDelta = tbl.StretchBy, noSelect = true}))
					elseif _g.objIsType(TrackItem, "Marker") then 
						table.insert(actionSeq, baseActions.EditMarker(TrackItem, {frmPosDelta = tbl.StretchBy, noSelect = true}))
					end
				end
			end

			for _, tbl in pairs(TI_tbls) do
				local Track = tbl.Track
				local tiTbl = tbl.tiTbl

				local newFrmPos = ComputeStretch(tiTbl.frm_pos)
				if not Track:IsPosTaken(newFrmPos, ComputeStretch(tiTbl.width + tiTbl.frm_pos)) then
					tiTbl.select = true
					if tiTbl._tblType == "Keyframe" then
						local allPos = {}
						for pos, _ in pairs(tiTbl.TargetValues) do
							table.insert(allPos, pos)
						end
						table.sort(allPos, function(a, b) return a < b end)

						local newTargetValues = {}
						local newEases = {}
						for _, pos in pairs(allPos) do
							local shift = ComputeStretch(pos + tiTbl.frm_pos) - newFrmPos
							if newTargetValues[shift] == nil then
								newTargetValues[shift] = tiTbl.TargetValues[pos]
								newEases[shift] = tiTbl.EaseMap[pos]
							end
						end

						tiTbl.TargetValues = newTargetValues
						tiTbl.EaseMap = newEases
						tiTbl.frm_pos = newFrmPos
						table.insert(actionSeq, baseActions.AddKeyframe(Track, tiTbl))
					elseif tiTbl._tblType == "Marker" then
						tiTbl.width = ComputeStretch(tiTbl.width + tiTbl.frm_pos) - newFrmPos
						tiTbl.frm_pos = newFrmPos
						table.insert(actionSeq, baseActions.AddMarker(Track, tiTbl))
					end
					SelectionHandler:_SelectTrackItem(Track.TrackItemPositions[newFrmPos])
				end
			end

			return actionSeq
		end
		
		local no_rig_only_actions = {AddItems = true, RemoveItems = true, AdjustCameraRef = true}

		function DoCompositeAction(actionName, args)
			if LayerSystem.RigOnlyMode and no_rig_only_actions[actionName] then
				task.delay(0, function()
					_g.Windows.MsgBox.Popup(Win, {
						Title = "Moon 2 File", 
						Content = "Action requires Moon 2 File. Convert to Moon 2 File?",
						Button1 = {
							"Yes",
							function()
								LayerSystem:TurnOffRigOnlyMode()
								DoCompositeAction(actionName, args)
								CloseFile:set_highlight(false)
								Win:SetItemPaint(CloseFile.UI.BG.Frame1, {BackgroundColor3 = "main"}, _g.Themer.QUICK_TWEEN)
								Win:SetItemPaint(CloseFile.UI.BG.Frame2, {BackgroundColor3 = "main"}, _g.Themer.QUICK_TWEEN)
							end
						},
					})
				end)
				return false
			end
			
			PlaybackHandler:Stop()
			local actionSeq = compositeActions[actionName](args)
			
			for i = 1, #actionSeq do
				local action = actionSeq[i]
				if action.has_sel then
					actionSeq.has_sel = true
				elseif action.has_sel_undo then
					actionSeq.has_sel_undo = true
				elseif action.has_sel_redo then
					actionSeq.has_sel_redo = true
				end
			end

			if #actionSeq > 0 then
				Win.DirtyFile()
				PlaybackHandler:BufferKeyframeTracks()
				if history_ind < #history then
					repeat
						table.remove(history, #history)
					until #history == history_ind
				end

				if #history > HISTORY_SIZE then
					table.remove(history, 1)
					history_ind = history_ind - 1
				end

				table.insert(history, actionSeq)
				history_ind = history_ind + 1

				_g.Input:SetActionDisabled("Undo", false)
				_g.Input:SetActionDisabled("Redo", true)
			end
		end
		Win.DoCompositeAction = DoCompositeAction

		_g.Input:BindAction(Win, "AddToSelectedTracks", function() DoCompositeAction("AddToSelectedTracks") end, {"KeypadPlus", "Equals"}, true)
		_g.Input:BindAction(Win, "AddDefaultKeyframesToSelectedTracks", function() DoCompositeAction("AddToSelectedTracks", {default = true}) end, {"G"}, true)
		_g.Input:BindAction(Win, "DeleteSelectedTrackItems", function() DoCompositeAction("DeleteSelectedTrackItems") end, {"Delete", "KeypadMinus"}, true)
		_g.Input:BindAction(Win, "FitTimeline", function() DoCompositeAction("FitTimeline") end, {"SHIFT_F"}, true)
		_g.Input:BindAction(Win, "GroupKeyframes", function() DoCompositeAction("GroupKeyframes") end, {"CTRL_G"}, true)
		_g.Input:BindAction(Win, "UngroupKeyframes", function()
			local TargetKeyframes = {}
			local MinBound
			local MaxBound
			SelectionHandler.SelectedTrackItems:Iterate(function(Keyframe)
				if Keyframe.group then
					if MinBound == nil or Keyframe.frm_pos < MinBound then
						MinBound = Keyframe.frm_pos
					end
					if MaxBound == nil or Keyframe.frm_pos + Keyframe.width > MaxBound then
						MaxBound = Keyframe.frm_pos + Keyframe.width
					end
					table.insert(TargetKeyframes, Keyframe)
				end
			end, "Keyframe")
			DoCompositeAction("UngroupKeyframes", {TargetKeyframes = TargetKeyframes, minPos = MinBound, maxPos = MaxBound, InRange = true, Delete = false})
		end, {"SHIFT_CTRL_U"}, true)
	end

	do
		function UndoAction()
			if history_ind == 1 then return end
			
			PlaybackHandler:Stop()
			if history[history_ind].has_sel or history[history_ind].has_sel_undo then
				SelectionHandler:DeselectAll()
			end			

			for ind = #history[history_ind], 1, -1 do
				local action = history[history_ind][ind]
				action.Undo()
			end
			PlaybackHandler:BufferKeyframeTracks()
			history_ind = history_ind - 1

			_g.Input:SetActionDisabled("Undo", history_ind == 1)
			_g.Input:SetActionDisabled("Redo", false)

			Win.DirtyFile()
		end

		function RedoAction()
			if history_ind == #history then return end
			
			history_ind = history_ind + 1
			PlaybackHandler:Stop()
			if history[history_ind].has_sel or history[history_ind].has_sel_redo then
				SelectionHandler:DeselectAll()
			end	
			
			for ind = 1, #history[history_ind], 1 do
				local action = history[history_ind][ind]
				action.Redo()
			end
			PlaybackHandler:BufferKeyframeTracks()

			_g.Input:SetActionDisabled("Undo", false)
			_g.Input:SetActionDisabled("Redo", history_ind == #history)

			Win.DirtyFile()
		end

		function Win.ClearActionHistory()
			history = {{}}
			history_ind = 1

			_g.Input:SetActionDisabled("Undo", true)
			_g.Input:SetActionDisabled("Redo", true)
		end

		_g.Input:BindAction(Win, "Undo", UndoAction, {"CTRL_Z", "SHIFT_Z"}, true)
		_g.Input:BindAction(Win, "Redo", RedoAction, {"SHIFT_CTRL_Z", "CTRL_Y", "SHIFT_Y"}, true)
	end

	do
		function CopyTrackItems(cut)
			local newBuffer = {begin = LayerSystem.length, length = 0}
			SelectionHandler.SelectedTrackItems:Iterate(function(TrackItem)
				local data = {TI = TrackItem:Tableize(), type = TrackItem.type[1]}

				if _g.objIsType(TrackItem, "Keyframe") and TrackItem.ParentTrack.Target and TrackItem.ParentTrack.Target.Parent then
					data.location = {
						Item = TrackItem.ParentTrack.ItemObject.Path:GetItem(),
						name = TrackItem.ParentTrack.name,
						property = TrackItem.ParentTrack.property,
					}
					table.insert(newBuffer, data)
				elseif _g.objIsType(TrackItem, "Marker") then
					data.location = {
						Item = TrackItem.ParentTrack.ItemObject.Path:GetItem(),
					}
					table.insert(newBuffer, data)
				end

				if TrackItem.frm_pos < newBuffer.begin then
					newBuffer.begin = TrackItem.frm_pos
				end
				if TrackItem.frm_pos + TrackItem.width > newBuffer.length then
					newBuffer.length = TrackItem.frm_pos + TrackItem.width
				end
			end)
			if #newBuffer > 0 then
				newBuffer.length = newBuffer.length - newBuffer.begin
				copy_buffer = newBuffer
				_g.Input:SetActionDisabled("Paste", false)
				_g.Input:SetActionDisabled("PasteIntoItem", false)

				if cut then
					DoCompositeAction("DeleteSelectedTrackItems")
				end
			end
		end

		function compositeActions.PasteTrackItems(args)
			local actionSeq = {}

			if #copy_buffer > 0 then
				SelectionHandler:SetTrackItemSelection({})
				if copy_buffer.length + LayerSystem.SliderFrame > LayerSystem.length then
					table.insert(actionSeq, baseActions.EditAnimationSettings({length = copy_buffer.length + LayerSystem.SliderFrame}))
				end
			end
			for ind = 1, #copy_buffer do
				local data = copy_buffer[ind]
				local MainContainer
				if args then
					MainContainer = args.ItemObject.MainContainer
				else
					for _, con in pairs(LayerHandler.LayerContainer.Objects) do
						if con.ItemObject.Path:GetItem() == data.location.Item then
							MainContainer = con
							break 
						end
					end
				end

				if MainContainer then
					local Track
					if data.type == "Keyframe" then
						local propTrack = MainContainer.ItemObject.PropertyMap[data.location.name]
						local rigTrack = MainContainer.ItemObject.RigMap[data.location.name]

						if propTrack and propTrack.Target and propTrack.Target.Parent and propTrack.property == data.location.property then
							Track = propTrack
						elseif rigTrack and rigTrack.Target and rigTrack.Target.Parent and rigTrack.property == data.location.property then
							Track = rigTrack
						end
					elseif data.type == "Marker" then
						Track = MainContainer.ItemObject.MarkerTrack
					end
					local TrackItem = _g.deepcopy(data.TI)

					if Track and TrackItem then
						local RemoveTargets = {}

						local targetPos = LayerSystem.SliderFrame + TrackItem.frm_pos - copy_buffer.begin
						for pos = targetPos, targetPos + TrackItem.width, 1 do
							if Track.TrackItemPositions[pos] then
								RemoveTargets[tostring(Track.TrackItemPositions[pos])] = Track.TrackItemPositions[pos]
							end
						end

						TrackItem.frm_pos = targetPos
						if data.type == "Keyframe" then
							for _, Keyframe in pairs(RemoveTargets) do
								table.insert(actionSeq, baseActions.RemoveKeyframe(Keyframe))
							end
							table.insert(actionSeq, baseActions.AddKeyframe(Track, TrackItem))					
						elseif data.type == "Marker" then
							for _, Marker in pairs(RemoveTargets) do
								table.insert(actionSeq, baseActions.RemoveMarker(Marker))
							end
							table.insert(actionSeq, baseActions.AddMarker(Track, TrackItem))			
						end

						SelectionHandler:_SelectTrackItem(Track.TrackItemPositions[targetPos])
					end
				end
			end

			return actionSeq
		end

		_g.Input:BindAction(Win, "Cut", function() CopyTrackItems(true) end, {"CTRL_X", "SHIFT_X"}, true)
		_g.Input:BindAction(Win, "Copy", function() CopyTrackItems() end, {"CTRL_C", "SHIFT_C"}, true)
		_g.Input:BindAction(Win, "Paste", function() DoCompositeAction("PasteTrackItems") end, {"CTRL_V", "SHIFT_V"}, true)
	end

	do
		_g.Input:BindAction(Win, "PasteIntoItem", function()
			DoCompositeAction("PasteTrackItems", {ItemObject = LayerHandler.ActiveItemObject})
		end, {"SHIFT_CTRL_V"}, true)

		_g.Input:BindAction(Win, "ToggleItemTracks", function()
			local Disable = false
			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				local i_o = ItemObject.ItemObject
				if i_o.EnabledTracks > 0 then Disable = true break end
			end
			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				local i_o = ItemObject.ItemObject
				if (Disable and i_o.EnabledTracks > 0) or (not Disable and i_o.EnabledTracks == 0) then
					i_o:ToggleTracks()
				end
			end
		end, {"SHIFT_Space"}, true)
		
		_g.Input:BindAction(Win, "ApplyOnionSkin", function()
			local cleared = false
			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				ItemObject = ItemObject.ItemObject
				if ItemObject.OnionSkin then
					if not cleared then SelectionHandler:DeselectAll() cleared = true end
					ItemObject:ApplyOnionSkin()
				end
			end
			if cleared then
				DoCompositeAction("AddToSelectedTracks")
			end
		end, {"N"}, false)

		_g.Input:BindAction(Win, "ToggleOnionSkin", function()
			LayerHandler.ActiveItemObject:ToggleOnionSkin()
		end, {"B"}, true)

		_g.Input:BindAction(Win, "ClearOnionSkins", function()
			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				ItemObject = ItemObject.ItemObject
				if ItemObject.OnionSkin then
					ItemObject:ClearOnionSkin()
				end
			end
		end, {"ALT_B"}, true)

		_g.Input:BindAction(Win, "JumpCameraToItem", function()
			local get_path = LayerHandler.ActiveItemObject.Path
			local cf

			if (get_path.ItemType == "Rig" or get_path.ItemType == "Model") and get_path.Item.PrimaryPart then
				local Part = LayerHandler.ActiveItemObject.Path.Item.PrimaryPart
				cf = CFrame.new(Part.Position + Vector3.new(-5, 5, -5), Part.Position)
			elseif get_path.ItemType == "BasePart" then
				local Part = LayerHandler.ActiveItemObject.Path.Item
				cf = CFrame.new(Part.Position + Vector3.new(-5, 5, -5), Part.Position)
			end

			if cf then
				workspace.Camera.CameraType = Enum.CameraType.Scriptable
				workspace.Camera.CFrame = cf
				workspace.Camera.CameraType = Enum.CameraType.Custom
			end
		end, {"F"}, true)

		_g.Input:BindAction(Win, "PrevKeyframe", function()
			if PlaybackHandler.Playing then
				PlaybackHandler:Stop()
			end

			local find = 0
			for pos, _ in pairs(LayerHandler.ActiveItemObject.PoseMap) do
				if pos > find and pos < LayerSystem.SliderFrame then
					find = pos
				end
			end
			LayerSystem:SetSliderFrame(find)
		end, {"J"}, true)

		_g.Input:BindAction(Win, "NextKeyframe", function()
			if PlaybackHandler.Playing then
				PlaybackHandler:Stop()
			end

			local find = LayerSystem.length
			for pos, _ in pairs(LayerHandler.ActiveItemObject.PoseMap) do
				if pos < find and pos > LayerSystem.SliderFrame then
					find = pos
				end
			end
			LayerSystem:SetSliderFrame(find)
		end, {"K"}, true)
		
		_g.Input:BindAction(Win, "SplitKeyframe", function()
			DoCompositeAction("SplitKeyframes")
		end, {"M"}, true)
		
		_g.Input:BindAction(Win, "OpenSplitKFVal", function()
			Win:OpenModal(_g.Windows.SplitKFVal)
		end, {"SHIFT_M"}, true)
	end

	do
		_g.Input:BindAction(Win, "OpenActivate", function() _g.Windows.Activate:Open() end, {}, false)
		
		_g.Input:BindAction(Win, "OpenUngroup", function() Win:OpenModal(_g.Windows.Ungroup) end, {"CTRL_U"}, true)
		_g.Input:BindAction(Win, "OpenAnimationSettings", function() Win:OpenModal(_g.Windows.AnimationSettings) end, {"KeypadEight", "Eight"}, true)
		_g.Input:BindAction(Win, "OpenEditTrackItems", function()
			if SelectionHandler.TrackItemTypeMap["Keyframe"] then
				Win:OpenModal(_g.Windows.EditKeyframes)
			elseif SelectionHandler.TrackItemTypeMap["Marker"] then
				Win:OpenModal(_g.Windows.EditMarkers)
			end
		end, {"KeypadSeven", "Seven"}, true)
		_g.Input:BindAction(Win, "OpenAddItem", function() Win:OpenModal(_g.Windows.AddItem) end, {"KeypadNine", "Nine"}, true)
		_g.Input:BindAction(Win, "OpenImport", function() 
			if LayerHandler.ActiveItemObject and LayerHandler.ActiveItemObject.RigContainer then
				Win:OpenModal(_g.Windows.Import, {ItemObjectIndex = LayerHandler.LayerContainer:IndexOf(LayerHandler.ActiveItemObject.MainContainer)}) 
			else
				Win:OpenModal(_g.Windows.Import) 
			end
		end, {"SHIFT_I"}, true)
		_g.Input:BindAction(Win, "OpenExportFiles", function() Win:OpenModal(_g.Windows.ExportFiles) end, {}, false)
		_g.Input:BindAction(Win, "ReflectRig", function() Win.DoCompositeAction("ReflectRig", {ItemObject = LayerHandler.ActiveItemObject}) end, {"CTRL_R"}, true)
		_g.Input:BindAction(Win, "ToggleHandles", function() LayerHandler.ActiveItemObject:ToggleHandles() end, {"CTRL_B"}, true)
		_g.Input:BindAction(Win, "OpenFillFrames", function() Win:OpenModal(_g.Windows.FillFrames) end, {"SHIFT_K"}, true)
		_g.Input:BindAction(Win, "OpenFrameOffset", function() Win:OpenModal(_g.Windows.FrameOffset) end, {}, true)
		_g.Input:BindAction(Win, "OpenRepeatFrames", function() Win:OpenModal(_g.Windows.RepeatFrames) end, {"SHIFT_L"}, true)
		_g.Input:BindAction(Win, "OpenStretchFrames", function()
			if SelectionHandler.SelectedTrackItems.size == 0 then
				SelectionHandler:SelectAll()
			end
			Win:OpenModal(_g.Windows.StretchFrames) 
		end, {"KeypadThree", "Three"}, true)

		for _, theme in pairs(_g.Themer.ThemeList) do
			if theme ~= "~" then
				if theme == "Default" then
					_g.Input:BindAction(Win, "Theme_"..theme, function()
						_g.Themer:SetTheme(theme)
						_g.plugin:SetSetting(_g.theme_key, nil)
					end, {}, false)
				else
					_g.Input:BindAction(Win, "Theme_"..theme, function()
						_g.Themer:SetTheme(theme)
						_g.plugin:SetSetting(_g.theme_key, theme)
					end, {}, false)
				end
			end
		end
		
		_g.Input:BindAction(Win, "SmallBoneHandles", function() _g.Toggles.FlipToggleValue("SmallBoneHandles") end, {"SHIFT_B"}, false)
		_g.Input:BindAction(Win, "NoHideHandles", function() _g.Toggles.FlipToggleValue("NoHideHandles") end, {"SHIFT_H"}, false)
		_g.Input:BindAction(Win, "ROTGrid", function() _g.Toggles.FlipToggleValue("ROTGrid") end, {"C"}, false)
		
		_g.Input:BindAction(Win, "OpenEditTheme", function() Win:OpenModal(_g.Windows.EditTheme) end, {}, false)
		_g.Input:BindAction(Win, "Play", function() PlaybackHandler:TogglePlayback() end, {"Space", "KeypadEnter"}, true)
		_g.Input:BindAction(Win, "ToggleLoop", function() PlaybackHandler:SetLoop(not PlaybackHandler.Loop) end, {"Tab"}, true)
		_g.Input:BindAction(Win, "JumpBegin", function() PlaybackHandler:Stop() LayerSystem:SetSliderPercentage(0) end, {"KeypadOne", "One"}, true)
		_g.Input:BindAction(Win, "PrevFrame", function() PlaybackHandler:Stop() LayerSystem:SetSliderFrame(LayerSystem.SliderFrame - 1) end, {"KeypadFour", "Four"}, true)
		_g.Input:BindAction(Win, "NextFrame", function() PlaybackHandler:Stop() LayerSystem:SetSliderFrame(LayerSystem.SliderFrame + 1) end, {"KeypadSix", "Six"}, true)
		_g.Input:BindAction(Win, "QuickPlayBackward", function()
			PlaybackHandler:Play(-1, 0)
		end, {"KeypadFour*", "Four*"}, false, function()
			PlaybackHandler:Stop()
		end)
		_g.Input:BindAction(Win, "QuickPlayForward", function()
			PlaybackHandler:Play(1, LayerSystem.length)
		end, {"KeypadSix*", "Six*"}, false, function()
			PlaybackHandler:Stop()
		end)
		_g.Input:BindAction(Win, "CameraToPart", function()
			local sel = game.Selection:Get()
			if #sel == 1 and sel[1].Parent and sel[1]:IsA("BasePart") then
				game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
				game.Workspace.CurrentCamera.CFrame = sel[1].CFrame
				game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			end
		end, {}, false)
		
		Win.ExportRigs = function(no_sel)
			local sel = {}

			for _, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				ItemObject = ItemObject.ItemObject
				local exportFolder = _g.ExportItemObject(ItemObject)
				if exportFolder then
					for _, obj in pairs(exportFolder:GetChildren()) do
						table.insert(sel, obj)
						if ItemObject.RigContainer then
							local rig = ItemObject.Path:GetItem()
							if rig and rig.Parent then
								local anim_saves = rig:FindFirstChild("AnimSaves")
								if anim_saves == nil then
									anim_saves = Instance.new("Model", rig); anim_saves.Name = "AnimSaves"
								end
								if anim_saves:FindFirstChild(obj.Name) then
									anim_saves[obj.Name]:Destroy()
								end
								obj.Parent = anim_saves
							end
						elseif ItemObject.Path:GetItem().ClassName == "Camera" then
							obj.Parent = ItemObject.Path:GetItem()
						end
					end
					exportFolder:Destroy()
				end
			end
			
			if not no_sel then
				game.Selection:Set(sel)
			end
		end
		
		_g.Input:BindAction(Win, "Export", function()
			Win.ExportRigs()
		end, {"KeypadFive", "Five"}, true)

		_g.Input:BindAction(Win, "Save", function() Win.SaveFile() end, {"KeypadZero", "Zero"}, true)
		_g.Input:BindAction(Win, "OpenSaveAs", function() Win:OpenModal(_g.Windows.SaveAs) end, {}, true)
		_g.Input:BindAction(Win, "SaveClose", function() Win.SaveFile(false, true) end, {"KeypadDivide", "Slash"}, true)
		_g.Input:BindAction(Win, "CloseFile", function(force)
			Win.PromptSave()
		end, {"BackSlash"}, false)

		_g.Input:BindAction(Win, "HideUI", function()
			WindowData.MenuBar:Close()
			Win:SetHidden(Win.UI.Visible)
		end, {"CTRL_H"}, false)
		_g.Input:BindAction(Win, "ToggleCameraTracks", function()
			local camId = workspace.CurrentCamera:GetDebugId(8)
			if LayerHandler.ItemMap[camId] then
				local ItemObject = LayerHandler.ItemMap[camId]

				local hasEnabled = false
				for propName, KeyframeTrack in pairs(ItemObject.PropertyMap) do
					if KeyframeTrack.Enabled then
						hasEnabled = true
						break
					end
				end
				for propName, KeyframeTrack in pairs(ItemObject.PropertyMap) do
					KeyframeTrack:SetEnabled(not hasEnabled, true)
				end
			end
		end, {"CTRL_Space"}, false)
		_g.Input:BindAction(Win, "OpenCameraRef", function() Win:OpenModal(_g.Windows.CameraRef) end, {}, false)
		_g.Input:BindAction(Win, "OpenCameraRotation", function() Win:OpenModal(_g.Windows.CameraRotation) end, {"SHIFT_O"}, false)
		_g.Input:BindAction(Win, "OpenJumpToItem", function() Win:OpenModal(_g.Windows.JumpToItem) end, {"SHIFT_P"}, true)
		_g.Input:BindAction(Win, "CollapseToggle", function()
			local ItemObjects = {}
			local hide = false

			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				ItemObject = ItemObject.ItemObject
				table.insert(ItemObjects, ItemObject)
				if not ItemObject.ObjectLabel.collapsed then
					hide = true
				end
			end

			for _, ItemObject in pairs(ItemObjects) do
				ItemObject.ObjectLabel:Collapse(hide)
			end
		end, {"KeypadTwo", "Two"}, true)
		_g.Input:BindAction(Win, "AddCamera", function()
			if LayerHandler.ItemMap[workspace.CurrentCamera:GetDebugId(8)] == nil then
				DoCompositeAction("AddItems", {ItemList = {workspace.CurrentCamera}, PropList = {"CFrame", "FieldOfView"}, MarkerTrack = false})
			end
		end, {}, true)

		_g.Input:BindAction(Win, "SelectAllTrackItems", function()
			SelectionHandler:SelectAll()
		end, {"ALT_F"}, true)

		_g.Input:BindAction(Win, "TotalInSeconds", function()
			_g.Toggles.FlipToggleValue("TotalInSeconds")
		end, {"SHIFT_T"}, false)
	end

	Win.CloseFile()
end

return Win

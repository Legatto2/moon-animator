local _g = _G.MoonGlobal
------------------------------------------------------------
	local SelectionHandler

	local KFMarkerChanged = false
	local Marker_obj = require(_g.class.Marker)
	local MarkerTrackModule = require(_g.class.MarkerTrack)

	local TargetMarkers = {}
	local CurrentProperties = {}; local AllProperties = {"name", "width", "codeBegin", "codeEnd"}
	local VariedProperties = {}
	local EditedProperties = {}
	local DisplayedText = {}
	local OpenSources = {}
	local UpdatingFields = false
	local EditorOpen = false
	local PreviewEnabled = false
	local PreviewOptIn = false
	
	local data = _g.WindowData:new("Edit Events (session preview)", script.Contents); data.resize = true; data.ResizeIncrement = {X = 0, Y = 15}
	local Win  = _g.Window:new(script.Name, data)

	local SaveButton = Button:new(Win.g_e.Confirm)
	SaveButton.UI.Label.Text = "Save"
	SaveButton.UI.Size = UDim2.new(0.5, -4, 0, 20)
	SaveButton.UI.LayoutOrder = 1
	local previewUI = SaveButton.UI:Clone()
	previewUI.Name = "PreviewSession"
	previewUI.LayoutOrder = 0
	previewUI.Parent = SaveButton.UI.Parent
	local PreviewButton = Button:new(previewUI)
	PreviewButton.UI.Label.Text = "Preview: OFF"
	Tabs:new(Win.g_e.Tabs, "Events", nil)
	Win.g_e.Tabs.UI.Tabs.CodeBegin.Label.Text = "On Begin"
	Win.g_e.Tabs.UI.Tabs.CodeEnd.Label.Text = "On End"

	TextInput:new(Win.g_e.MarkerName, "", nil)
	TimeInput:new(Win.g_e.Width, 0, nil, {0, _g.MAX_FRAMES, 1})
	TimeInput:new(Win.g_e.EndTime, 0, nil, {0, _g.MAX_FRAMES, 1})
	MultiInput:new(Win.g_e.BeginCodeInput, "", nil)
	MultiInput:new(Win.g_e.EndCodeInput, "", nil)
	BeginCodeInput.UI.Frame.Input.PlaceholderText = '{"version":1,"actions":[{"op":"sound.play","target":["Head","Footstep"]},{"op":"particle.emit","target":["Muzzle","Flash"],"count":12}]}'
	EndCodeInput.UI.Frame.Input.PlaceholderText = '{"version":1,"actions":[{"op":"sound.stop","target":["Head","Footstep"]},{"op":"particle.clear","target":["Muzzle","Flash"]}]}'
	KeyValueList:new(Win.g_e.KeyValueList, {}, function() KFMarkerChanged = true end)

	local PropertyElementMap = {name = MarkerName, width = Width, codeBegin = BeginCodeInput, codeEnd = EndCodeInput}
------------------------------------------------------------
do
	local sourceNames = {codeBegin = "On Begin", codeEnd = "On End"}
	local function SetPreview(value, explicit)
		PreviewEnabled = value
		PreviewOptIn = value and explicit == true
		PreviewButton.UI.Label.Text = value and "Preview: ON" or "Preview: OFF"
		PreviewButton:set_highlight(value)
	end

	local function ShowError(message)
		_g.Windows.MsgBox.Popup(Win, {Title = "Event preview", Content = tostring(message)})
	end

	-- Track textbox edits separately from FocusLost: an untouched mixed-value
	-- placeholder must not become literal source text, and legacy text stays intact.
	for propName, element in pairs(PropertyElementMap) do
		local input = element.UI.Frame.Input
		input:GetPropertyChangedSignal("Text"):Connect(function()
			if EditorOpen and not UpdatingFields and DisplayedText[propName] ~= input.Text then
				DisplayedText[propName] = input.Text
				EditedProperties[propName] = true
				if sourceNames[propName] then SetPreview(false) end
			end
		end)
	end

	local function SyncText(propName)
		local element = PropertyElementMap[propName]
		local input = element.UI.Frame.Input
		if DisplayedText[propName] ~= input.Text then
			EditedProperties[propName] = true
			if sourceNames[propName] then SetPreview(false) end
		end
		if EditedProperties[propName] then
			element:Set(input.Text, true)
		end
		if input:IsFocused() then input:ReleaseFocus() end
		-- Property signals may be deferred. Record the normalized text now so a
		-- later notification does not undo a preview choice made after this sync.
		DisplayedText[propName] = input.Text
	end

	local function SyncTime(element)
		local input = element.UI.Frame.Input
		if element.Enabled and input.Text ~= element.OldText then
			-- Match TimeInput's focus-loss units, including seconds and frame suffixes.
			local value = tonumber(input.Text)
			if value then
				value = _g.TimeConvert(value, "s", "f", element:get_fps())
			elseif string.find(input.Text, ":") then
				value = _g.TimeConvert(input.Text, "t", "f", element:get_fps())
			elseif string.sub(input.Text, -1) == "f" then
				value = tonumber(string.sub(input.Text, 1, -2))
			end
			element:Set(value ~= nil and value or element.Value, true)
		end
		if input:IsFocused() then input:ReleaseFocus() end
	end

	local function SyncInputs()
		SyncText("name")
		SyncTime(Width)
		SyncTime(EndTime)
		SyncText("codeBegin")
		SyncText("codeEnd")
	end

	local function BuildChanges()
		local changes = {TargetMarkers = TargetMarkers}
		for _, propName in pairs(AllProperties) do
			local value = PropertyElementMap[propName].Value
			if EditedProperties[propName] and value ~= nil
				and (VariedProperties[propName] or CurrentProperties[propName] ~= value) then
				changes[propName] = value
			end
		end
		if KFMarkerChanged then changes.KFMarkers = KeyValueList.List end
		return changes
	end

	local function ValidateChanges(changes, preview)
		-- Never approve text that changed behind the displayed editor fields.
		for index, marker in ipairs(TargetMarkers) do
			local opened = OpenSources[marker]
			if not opened or marker.codeBegin ~= opened[1] or marker.codeEnd ~= opened[2] then
				return false, "Event " .. index .. " changed while this editor was open. Close and reopen it to review the current commands."
			end
		end
		for propName, label in pairs(sourceNames) do
			if changes[propName] ~= nil then
				local valid, err = MarkerTrackModule.ValidateCommands(changes[propName])
				if not valid then return false, label .. ": " .. tostring(err) end
			end
		end
		if preview then
			for index, marker in ipairs(TargetMarkers) do
				for propName, label in pairs(sourceNames) do
					local source = changes[propName] ~= nil and changes[propName] or marker[propName]
					local valid, err = MarkerTrackModule.ValidateCommands(source)
					if not valid then
						return false, "Event " .. index .. ", " .. label .. ": " .. tostring(err)
					end
				end
			end
		end
		return true
	end

	local function SelectionIsApproved()
		for _, marker in ipairs(TargetMarkers) do
			local ok, approved = pcall(function() return marker.ParentTrack:IsMarkerApproved(marker) end)
			if not ok or not approved then return false end
		end
		return true
	end

	local function RevokeSelection()
		local firstError
		for _, marker in ipairs(TargetMarkers) do
			local ok, err = pcall(function() marker.ParentTrack:RevokeMarkerCommands(marker) end)
			if not ok and not firstError then firstError = err end
		end
		return firstError == nil, firstError
	end

	PreviewButton.OnClick = function()
		local turnOn = not PreviewEnabled
		SyncInputs()
		if not turnOn then
			SetPreview(false)
		else
			local valid, err = ValidateChanges(BuildChanges(), true)
			if not valid then
				ShowError("Preview requires valid JSON commands. " .. tostring(err) .. "\nExisting Lua text can stay saved with Preview OFF.")
				return
			end
			-- This is only a draft choice. Approval is granted after Save succeeds.
			SetPreview(true, true)
		end
	end

	Width._changed = function(value)
		if EditorOpen and not UpdatingFields then
			EditedProperties.width = true
			DisplayedText.width = Width.UI.Frame.Input.Text
		end
		if #TargetMarkers == 1 then
			EndTime:Set(TargetMarkers[1].frm_pos + value)
		end
	end
	EndTime._changed = function(value)
		if #TargetMarkers == 1 then
			Width:Set(value - TargetMarkers[1].frm_pos)
			if EditorOpen and not UpdatingFields then
				EditedProperties.width = true
				DisplayedText.width = Width.UI.Frame.Input.Text
			end
		end
	end

	Win.OnOpen = function()
		EditorOpen = false
		TargetMarkers = {}
		CurrentProperties = {}
		VariedProperties = {}
		EditedProperties = {}
		DisplayedText = {}
		OpenSources = {}
		SetPreview(false)
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if not SelectionHandler.TrackItemTypeMap["Marker"] then return false end

		KFMarkerChanged = false

		local maxWidth = SelectionHandler.LayerSystem.length

		for _, TrackItem in pairs(SelectionHandler.SelectedTrackItems.Objects) do
			if _g.objIsType(TrackItem, "Marker") then
				local nextTI = TrackItem.ParentTrack:GetNextTrackItem(TrackItem)
				if nextTI then
					nextTI = nextTI.frm_pos - TrackItem.frm_pos - 1
				else
					nextTI = SelectionHandler.LayerSystem.length - TrackItem.frm_pos
				end
				if nextTI < maxWidth then
					maxWidth = nextTI
				end
				table.insert(TargetMarkers, TrackItem)
				OpenSources[TrackItem] = {TrackItem.codeBegin, TrackItem.codeEnd}
			end
		end
		if #TargetMarkers == 0 then return false end

		Width.Max = maxWidth

		for _, Marker in pairs(TargetMarkers) do
			for _, propName in pairs(AllProperties) do
				if VariedProperties[propName] == nil then
					local value = CurrentProperties[propName]
					if value == nil then
						CurrentProperties[propName] = Marker[propName]
					elseif value ~= nil and value ~= Marker[propName] then
						CurrentProperties[propName] = nil
						VariedProperties[propName] = true
					end
				end
			end
		end

		UpdatingFields = true
		MarkerName:Set(CurrentProperties.name)
		Width:Set(CurrentProperties.width)
		BeginCodeInput:Set(CurrentProperties.codeBegin)
		EndCodeInput:Set(CurrentProperties.codeEnd)

		EndTime:SetEnabled(true)
		if #TargetMarkers == 1 then
			EndTime.Min = TargetMarkers[1].frm_pos
			EndTime.Max = TargetMarkers[1].frm_pos + maxWidth
			EndTime:Set(TargetMarkers[1].frm_pos + TargetMarkers[1].width)
			KeyValueList:SetList(_g.deepcopy(TargetMarkers[1].KFMarkers))
		else
			EndTime:Set(nil)
			EndTime:SetEnabled(false)
			KeyValueList:SetList({})
		end
		for propName, element in pairs(PropertyElementMap) do
			DisplayedText[propName] = element.UI.Frame.Input.Text
		end
		UpdatingFields = false
		local allApproved = true
		for _, marker in ipairs(TargetMarkers) do
			if not marker.ParentTrack:IsMarkerApproved(marker) then allApproved = false end
		end
		SetPreview(allApproved)
		EditorOpen = true

		Win.g_e.Tabs:ShowTab("Events")

		return true
	end

	Win.OnClose = function(save)
		if save then
			SyncInputs()
			local changes = BuildChanges()
			local valid, err = ValidateChanges(changes, PreviewEnabled)
			if not valid then SetPreview(false) ShowError(err) return false end
			if PreviewEnabled and not PreviewOptIn and not SelectionIsApproved() then
				SetPreview(false)
				ShowError("Existing preview approval changed. Review the event and choose Preview ON again before saving, or save with Preview OFF.")
				return false
			end
			local saved, result = pcall(function()
				return _g.Windows.MoonAnimator.DoCompositeAction("EditMarkers", changes)
			end)
			if not saved or result == false then
				ShowError("Changes could not be saved. " .. (not saved and tostring(result) or "Please try again."))
				return false
			end
			-- The action has committed the edits. Retrying after a preview error must
			-- compare against those saved values, including unchanged mixed fields.
			for _, propName in pairs(AllProperties) do
				if changes[propName] ~= nil then
					CurrentProperties[propName] = changes[propName]
					VariedProperties[propName] = nil
				end
			end
			EditedProperties = {}
			KFMarkerChanged = false
			for _, marker in ipairs(TargetMarkers) do
				OpenSources[marker] = {marker.codeBegin, marker.codeEnd}
			end
			if PreviewEnabled and PreviewOptIn then
				for _, marker in ipairs(TargetMarkers) do
					local ok, approved, approvalError = pcall(function()
						return marker.ParentTrack:ApproveMarkerCommands(marker)
					end)
					if not ok or not approved then
						RevokeSelection()
						SetPreview(false)
						ShowError("Changes were saved, but preview could not be enabled. "
							.. tostring(ok and approvalError or approved) .. "\nPreview is OFF for the selection.")
						return false
					end
				end
			elseif PreviewEnabled then
				-- ON inherited from opening only preserves a still-valid grant. It
				-- never silently renews one after external edits or revocation.
				if not SelectionIsApproved() then
					SetPreview(false)
					ShowError("Changes were saved, but existing preview approval changed. Review the event and choose Preview ON again, or save with Preview OFF.")
					return false
				end
			else
				local revoked, revokeError = RevokeSelection()
				if not revoked then ShowError("Could not turn preview off. " .. tostring(revokeError)) return false end
			end
		end
		
		EditorOpen = false
		TargetMarkers = {}
		CurrentProperties = {}
		VariedProperties = {}
		EditedProperties = {}
		DisplayedText = {}
		OpenSources = {}

		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

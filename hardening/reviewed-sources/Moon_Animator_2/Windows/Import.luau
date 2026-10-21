local _g = _G.MoonGlobal
------------------------------------------------------------
	local TargetKeyframeSequence = nil
	local sel_con
local LayerHandler
local current_rig_selected
	
	local WindowData = _g.WindowData:new("Import to Rig", script.Contents)
	WindowData.ResizeIncrement = {X = 0, Y = 16}
	local Win  = _g.Window:new(script.Name, WindowData)
	

	Checklist:new(Win.g_e.RigList, nil)
	Radio:new(Win.g_e.Options, "Replace", nil)
	Button:new(Win.g_e.Set)
	Button:new(Win.g_e.ImportId)
	Check:new(Win.g_e.Group, false, nil)
	Check:new(Win.g_e.Events, true, nil)
	Check:new(Win.g_e.Face, true, nil)
	ValueLabel:new(Win.g_e.Selection, nil)
	Button:new(Win.g_e.Confirm)
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		LayerHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.LayerHandler
		if LayerHandler == nil then return false end

		local List = {}
		local Rigs = {}
		for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
			ItemObject = ItemObject.ItemObject
			if ItemObject.Path:GetItem() and ItemObject.Path.ItemType == "Rig" and ItemObject.RigContainer then
				table.insert(Rigs, ItemObject)
				table.insert(List, {Label = ItemObject.Path.Item.Name, Id = ind})
			end
		end
		RigList:SetList(List)
		
		if #List == 0 then
			task.delay(0, function()
				_g.Windows.MsgBox.Popup(_g.Windows.MoonAnimator, 
				{
					Title = "Cannot Import", 
					Content = "No Rigs exist in file.",
				})
			end)
			return false 
		end
		
		local rig_ind
		if args and args.ItemObjectIndex then
			RigList:SetChecked(tostring(args.ItemObjectIndex), true, true)
			rig_ind = args.ItemObjectIndex
		elseif #List > 0 then
			RigList:SetChecked(tostring(RigList.List[1].Id), true)
			rig_ind = tonumber(RigList.List[1].Id)
		end

		Win.g_e.Group:Set(true)
		Win.g_e.Confirm:SetActive(false)
		
		if rig_ind then
			local selected = LayerHandler.LayerContainer.Objects[rig_ind].ItemObject
			current_rig_selected = selected.Path:GetItem()
			if selected.Path.Item:FindFirstChild("AnimSaves") and selected.Path.Item.AnimSaves:FindFirstChildOfClass("KeyframeSequence") then
				local last
				for _, kf_seq in pairs(selected.Path.Item.AnimSaves:GetChildren()) do
					if kf_seq.ClassName == "KeyframeSequence" then
						last = kf_seq
					end
				end
				game.Selection:Set({last})
				Win.sel_changed()
			end
		end

		sel_con = game.Selection.SelectionChanged:Connect(Win.sel_changed)

		return true
	end

	Win.OnClose = function(save)
		if save then
			if TargetKeyframeSequence and #RigList:GetAllChecked() > 0 then

				local kfCount = _g.RobloxKeyframeCount(TargetKeyframeSequence)

				if not save.force and kfCount >= 512 and not Group.Value then
					_g.Windows.MsgBox.Popup(Win, 
					{
						Title = "Big Import", 
						Content = "The animation you are importing has "..kfCount.. " Keyframes. Are you sure you want to import without grouping Keyframes?",
						Button1 = {
							"Yes",
							function()
								Win:Close({force = true})
							end
						},
					})
					return false
				end

				local ItemObjects = {}
				for _, num in pairs(RigList:GetAllChecked()) do
					table.insert(ItemObjects, LayerHandler.LayerContainer.Objects[tonumber(num)].ItemObject) 
				end

				_g.Windows.MoonAnimator.DoCompositeAction("Import", {TargetKeyframeSequence = TargetKeyframeSequence, ItemObjects = ItemObjects, Replace = Win.g_e.Options.Value == "Replace", Group = Win.g_e.Group.Value, Events = Events.Value, Face = Face.Value})
			end
		end

		Win.SetKFSeq(nil)
		
		sel_con:Disconnect()
		sel_con = nil
		
		current_rig_selected = nil

		return true
	end

	RigList._changed = function(val)
		local checkCount = #RigList:GetAllChecked()

		if TargetKeyframeSequence ~= nil and checkCount > 0 then
			Win.g_e.Confirm:SetActive(true)
		else
			Win.g_e.Confirm:SetActive(false)
		end
	end


	Win.g_e.Confirm.OnClick = function()
		Win:Close({})
	end

	Win.SetKFSeq = function(KFSeq)
		if KFSeq then
			TargetKeyframeSequence = KFSeq
			Win.g_e.Selection:Set(KFSeq.Name)
		else
			TargetKeyframeSequence = nil
			Win.g_e.Selection:Set(nil)
		end

		if TargetKeyframeSequence ~= nil and #RigList:GetAllChecked() > 0 then
			Win.g_e.Confirm:SetActive(true)
		else
			Win.g_e.Confirm:SetActive(false)
		end
	end

	Set.OnClick = function()
		local id = _g.plugin:PromptForExistingAssetId("Animation")
		if id ~= -1 then
			local succ = pcall(function()
				local seq = _g.insert:LoadAsset(id)
				for _, obj in pairs(seq:GetChildren()) do
					if obj.ClassName == "KeyframeSequence" then
						Win.SetKFSeq(obj)
						break
					end
				end
			end)
			if not succ then
				Win.SetKFSeq(nil)
			end
		end
	end
	
	ImportId.OnClick = function()
		task.delay(0, function()
			Win:OpenModal(_g.Windows.IdImport, {rig = current_rig_selected, select_kf = true})
		end)
	end
	
	Win.sel_changed = function()
		local sel = _g.first_sel()
		if sel and sel.ClassName == "KeyframeSequence" then
			Win.SetKFSeq(sel)
		end
	end
end

return Win

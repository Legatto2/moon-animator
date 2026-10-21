local _g = _G.MoonGlobal
------------------------------------------------------------
	local Path_obj = require(_g.class.Path)

	local CurrentSelection = {}
	local SelectionType = nil

	local LayerHandler

	local WindowData = _g.WindowData:new("Add Item", script.Contents)
	WindowData.ResizeIncrement = {X = 0, Y = 16}

	local Win = _g.Window:new(script.Name, WindowData)

	Button:new(Win.g_e.Confirm)
	Button:new(Win.g_e.Delete)
	ValueLabel:new(Win.g_e.TargetItem, nil)
	ValueLabel:new(Win.g_e.ItemType, nil)
	Checklist:new(Win.g_e.Checklist)
	Check:new(Win.g_e.MarkerTrack, false, nil)

	Win.g_e.Confirm:SetActive(false)
	Win.g_e.Delete:SetActive(false)
------------------------------------------------------------
do
	local selCon = nil

	Win.OnOpen = function()
		MarkerTrack:Set(false)
		LayerHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.LayerHandler
		RefreshSelection()
		selCon = game.Selection.SelectionChanged:Connect(RefreshSelection)
		return true
	end
	
	Win.OnClose = function(save)
		if save then
			for _, Item in pairs(CurrentSelection) do

				if LayerHandler.ItemMap[Item:GetDebugId(8)] ~= nil then
					_g.Windows.MsgBox.Popup(Win, 
					{
						Title = "Item Exists", 
						Content = SelectionType.." '"..Path_obj.GetPath(Item).."' already exists in the Animator.",
					})
					game.Selection:Set({Item})
					return false
				end

				local isUnique, sameNames, badInstance, hier = Path_obj.CheckIfUnique(Item)
				if not isUnique then
					_g.Windows.MsgBox.Popup(Win, 
					{
						Title = "Bad Selection", 
						Content = "There are multiple "..badInstance.ClassName.."s with the name '"..(badInstance.Name).."' in '"..Path_obj.GetPath(hier).."'. Names must be different.",
					})
					table.insert(sameNames, badInstance)
					game.Selection:Set(sameNames)
					return false
				end

				if SelectionType == "Model" and Item.PrimaryPart == nil then
					_g.Windows.MsgBox.Popup(Win, 
					{
						Title = "No PrimaryPart", 
						Content = SelectionType.."s must have their PrimaryPart property set.",
					})
					game.Selection:Set({Item})
					return false
				end
			end
			
			_g.Windows.MoonAnimator.DoCompositeAction("AddItems", {ItemList = CurrentSelection, PropList = Checklist:GetAllChecked(), MarkerTrack = MarkerTrack.Value})
			for ind, ItemObject in pairs(LayerHandler.LayerContainer.Objects) do
				local i_o = ItemObject.ItemObject
				if i_o.Path:GetItem() == CurrentSelection[#CurrentSelection] then 
					LayerHandler:SetActiveItemObject(i_o)
					break
				end
			end
		end

		selCon:Disconnect()
		selCon = nil
			
		game.Selection:Set({})

		return true
	end

	Checklist._changed = function(prop, value)
		Win.g_e.Confirm:SetActive(#Checklist:GetAllChecked() > 0)
	end
	
	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end
------------------------------------------------------------
do
	function RefreshSelection()
		local finalSel = {}
		local finalType = nil

		for _, sel in pairs(game.Selection:Get()) do
			local foundType = nil

			local succ = pcall(function()
				if sel.Parent then
					foundType = _g.ItemTable.GetItemType(sel)
				else
					foundType = nil
				end
			end)

			if succ and foundType and _g.ItemTable.Items[foundType] then
				if finalType == nil then
					finalType = foundType
				end
				if finalType == foundType then
					table.insert(finalSel, sel)
				end
			end
		end

		local hasChanged = finalType ~= SelectionType

		CurrentSelection = finalSel
		SelectionType = finalType

		if #CurrentSelection == 0 then
			CurrentSelection = {}
			SelectionType = nil

			TargetItem:Set(nil)
			ItemType:Set(nil)
			Checklist:SetList({})
			Win.g_e.Confirm:SetActive(false)
		elseif hasChanged then
			local PropList = _g.ItemTable.GetProperties(SelectionType)
			Checklist:SetList(PropList)
			Win.g_e.Confirm:SetActive(true)
		end
		
		if SelectionType then
			if #CurrentSelection > 1 then
				TargetItem:Set("< varied >")
				ItemType:Set(SelectionType)
			else
				TargetItem:Set(CurrentSelection[1].Name)
				ItemType:Set(SelectionType)
			end
		end
	end
end

return Win

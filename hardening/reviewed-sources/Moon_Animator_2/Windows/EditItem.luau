local _g = _G.MoonGlobal
------------------------------------------------------------
	local Path_obj = require(_g.class.Path)
	local Target = nil
	
	local WindowData = _g.WindowData:new("Edit Item", script.Contents)
	WindowData.ResizeIncrement = {X = 0, Y = 16}

	local Win  = _g.Window:new(script.Name, WindowData)
	local LayerHandler

	Button:new(Win.g_e.Confirm)
	Button:new(Win.g_e.Delete)
	ValueLabel:new(Win.g_e.TargetItem, nil)
	ValueLabel:new(Win.g_e.ItemType, nil)
	Checklist:new(Win.g_e.Checklist)
	Check:new(Win.g_e.MarkerTrack, false, nil)
------------------------------------------------------------
do
	function CheckItemExists()
		if Target.Path:GetItem() == nil then
			_g.Windows.MsgBox.Popup(Win, {
				Title = "Item Missing", 
				Content = "Item no longer exists.",
			})
			return false
		end
		return true
	end

	Win.OnOpen = function(ItemObject)
		LayerHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.LayerHandler
		Target = ItemObject

		local exists = CheckItemExists()
		if not exists then return false end
		
		local PropList = _g.ItemTable.GetProperties(Target.Path.ItemType)

		local PropDict = {}
			for _, prop in pairs(PropList) do
				prop.Checked = false
				PropDict[prop.Label] = prop
				if prop.Label == "Rig" and Target.RigContainer then
					prop.Checked = true
				end
			end
		for prop, Track in pairs(Target.PropertyMap) do
			if PropDict[prop] then
				PropDict[prop].Checked = true
				if Track.TrackItems.size > 0 then
					PropDict[prop].Locked = true
				end
			end
		end
		if PropDict["Rig"] and Target.RigContainer then
			Target.RigContainer:Iterate(function(KeyframeTrack)
				if KeyframeTrack.TrackItems and KeyframeTrack.TrackItems.size > 0 then
					PropDict["Rig"].Locked = true
					return false
				end
			end, "KeyframeTrack")
		end

		Checklist:SetList(PropList)

		TargetItem:Set(Target.Path.Item.Name)
		ItemType:Set(Target.Path.ItemType)

		if ItemObject.MarkerTrack then
			MarkerTrack:Set(true)
			MarkerTrack:SetEnabled(ItemObject.MarkerTrack.TrackItems.size == 0)
		else
			MarkerTrack:Set(false)
			MarkerTrack:SetEnabled(true)
		end

		return true
	end
	Win.OnClose = function(save)
		if save then
			local exists = CheckItemExists()
			if not exists then return false end

			local PropList = Checklist:GetAllChecked()
			_g.Windows.MoonAnimator.DoCompositeAction("EditItems", {ItemList = {Target}, PropList = PropList, MarkerTrack = MarkerTrack.Value})
		end
		Target = nil
		return true
	end
	
	Win.g_e.Delete.OnClick = function()
		_g.Windows.MoonAnimator.DoCompositeAction("RemoveItems", {ItemList = {Target}})
		Win:Close()
	end
	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

local _g = _G.MoonGlobal
------------------------------------------------------------
	local LayerSystem

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Jump To Item", script.Contents))

	TextInput:new(Win.g_e.ItemName, "", nil, 20); ItemName.TrimWhitespace = true
	Button:new(Win.g_e.Confirm)

	Win.FocusedTextBox = ItemName.UI.Frame.Input
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		return true
	end

	Win.OnClose = function(save)
		if save then
			local get_name = ItemName.Value:lower()
			
			if #get_name > 0 then
				local find_dot = get_name:find(".", 1, true)
				local get_track
				if find_dot then
					get_track = get_name:sub(find_dot + 1)
					get_name = get_name:sub(1, find_dot - 1)
				end
				
				local found_items = {}
				
				for ind, ItemObject in pairs(LayerSystem.LayerHandler.LayerContainer.Objects) do
					local i_o = ItemObject.ItemObject
					local find_i, find_f = i_o.Path:GetItem().Name:lower():find(get_name)
					if find_i and find_i == 1 then
						table.insert(found_items, i_o)
					end
				end
				
				if #found_items > 0 then
					local target_item = found_items[1]
					
					LayerSystem.LayerHandler:SetActiveItemObject(target_item)
					LayerSystem.LayerHandler:ScrollToLSI(target_item.ObjectLabel)
					
					if get_track and not target_item.ObjectLabel.collapsed then
						local found_track = nil
						target_item.MainContainer:Iterate(function(LSI)
							local find_i, find_f =	LSI.ListComponent.Label.Text:lower():find(get_track)
							if find_i and find_i == 1 then
								found_track = LSI
								return false
							end
						end)
						if found_track then
							LayerSystem.LayerHandler:ScrollToLSI(found_track)
						end
					end
				end
			end
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

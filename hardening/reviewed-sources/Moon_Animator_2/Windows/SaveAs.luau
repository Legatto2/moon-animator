local _g = _G.MoonGlobal
------------------------------------------------------------
	local LayerSystem
	local close_after
	local old_name

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Save As", script.Contents))

	TextInput:new(Win.g_e.FileName, "", nil, 20); FileName.TrimWhitespace = true
	Button:new(Win.g_e.Confirm)

	Win.FocusedTextBox = FileName.UI.Frame.Input
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		close_after = args and args.close_after ~= nil
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		
		old_name = LayerSystem.CurrentFile.Name
		FileName:Set(old_name)
		
		return true
	end

	Win.OnClose = function(save)
		if save and #FileName.Value > 0 then
			if LayerSystem.CurrentFile.Parent == nil then
				LayerSystem.CurrentFile.Name = FileName.Value
				if LayerSystem.RigOnlyMode == false then
					local root_folder = _g.Files.GetRoot()
					LayerSystem.CurrentFile.Parent = root_folder
					if root_folder.Parent == nil then
						root_folder.Parent = game.ServerStorage
					end
				else
					LayerSystem.CurrentFile.Parent = _g.plugin
				end
			elseif FileName.Value ~= old_name then
				local get_parent = LayerSystem.CurrentFile.Parent
				local new_file = LayerSystem.CurrentFile:Clone(); new_file.Name = FileName.Value
				if LayerSystem.RigOnlyMode then
					LayerSystem.CurrentFile:Destroy()
				end
				LayerSystem.CurrentFile = new_file
				LayerSystem.CurrentFile.Parent = get_parent
			end
			_g.Windows.MoonAnimator.SaveFile(false, close_after)
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

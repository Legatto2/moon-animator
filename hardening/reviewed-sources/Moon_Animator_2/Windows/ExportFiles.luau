local _g = _G.MoonGlobal
------------------------------------------------------------
	local all_files = {}
	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Export Files", script.Contents))
	Button:new(Win.g_e.Confirm)
------------------------------------------------------------
do
	Win.OnOpen = function()
		all_files = {}

		local function scan(o)
			for _, file in pairs(o:GetChildren()) do
				if file.ClassName == "Folder" then scan(file) else
					local try = _g.Files.OpenFile(file)
					if try then
						table.insert(all_files, file)
					end
				end
			end
		end
		scan(_g.Files.GetRoot())
		
		Win.Contents.Section.Label1.Text = tostring(#all_files).." File"..(#all_files == 1 and "" or "s").." Found"
		
		return true
	end

	Win.OnClose = function(save)
		if save then
			local Win = _g.Windows.MoonAnimator
			if Win.g_e.LayerSystem.CurrentFile then
				Win.CloseFile()
			end
			game.Selection:Set({})
			
			for _, file in pairs(all_files) do
				Win.OpenFile(file)
				Win.ExportRigs(true)
				Win.CloseFile()
			end
		end
		all_files = nil
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

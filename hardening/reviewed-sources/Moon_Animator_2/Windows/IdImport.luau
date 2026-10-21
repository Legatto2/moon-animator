local _g = _G.MoonGlobal
------------------------------------------------------------
	local rig
	local select_kf

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Avatar Shop", script.Contents))

	NumberInput:new(Win.g_e.Id, 0, nil, {0, math.huge, 1, true})
	Button:new(Win.g_e.Confirm)

	Win.FocusedTextBox = Id.UI.Frame.Input
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		if args.rig then
			rig = args.rig
			select_kf = args.select_kf
			Id:Set(nil)
			return true
		end
		return false
	end

	Win.OnClose = function(save)
		if save then
			local target = Id.Value
			if target then
				local succ, err = pcall(function()
					if target < 65536 then
						target = _g.asset:GetBundleDetailsAsync(target)
						
						if target ~= nil then
							local data = target
							target = {}
							local gather = {}
							
							local pkg_name
							if string.find(data.Name, " Animation Package") then
								pkg_name = data.Name:gsub(" Animation Package", ""):gsub("^%s*(.-)%s*$", "%1")
							else
								pkg_name = data.Name:gsub(" Animation Pack", ""):gsub("^%s*(.-)%s*$", "%1")
							end
							for _, item in pairs(data.Items) do
								local item_name = item.Name:gsub(pkg_name.." ", ""):gsub("^%s*(.-)%s*$", "%1")
								if item_name ~= "Animation Package" and item_name ~= "Animation Pack" then
									table.insert(gather, {_g.insert:LoadAsset(item.Id):GetChildren()[1], pkg_name.."_"..item_name})
								end
							end
							
							for _, folder in pairs(gather) do
								local ani_name = folder[2]
								folder = folder[1]
								local ani
								for _, obj in pairs(folder:GetDescendants()) do
									if obj.ClassName == "Animation" then
										ani = obj
										break
									end
								end
								local ani_id = tonumber(ani.AnimationId:match("%d+$"))
								local act_ani = _g.insert:LoadAsset(ani_id):GetChildren()[1]
								act_ani.Name = ani_name
								table.insert(target, act_ani)
							end
						end
					else
						target = _g.insert:LoadAsset(target):GetChildren()[1]
						if target.ClassName == "Animation" then
							target = _g.insert:LoadAsset(tonumber(target.AnimationId:match("%d+$"))):GetChildren()[1]
						end
					end
					if type(target) == "table" and #target > 0 then
						local folder = rig:FindFirstChild("AnimSaves") if folder == nil then folder = Instance.new("Model", rig) folder.Name = "AnimSaves" end
						for i = 1, #target do
							local seq = target[i]
							seq.Parent = folder
						end
						target = target[#target]
					elseif target.ClassName == "KeyframeSequence" then
						local folder = rig:FindFirstChild("AnimSaves") if folder == nil then folder = Instance.new("Model", rig) folder.Name = "AnimSaves" end
						target.Parent = folder
					end
					assert(target.ClassName == "KeyframeSequence")
				end)
				if succ then
					if select_kf then
						local anis = rig.AnimSaves:GetChildren()
						game.Selection:Set({anis[#anis]})
					else 
						game.Selection:Set({rig})
					end
					task.delay(0, function()
						local Win = _g.Windows.MoonAnimator
						local Import = Win.g_e.Import
						Win.clear_selection()
						Win.NoFileSel()
						for _, tbl in pairs(Import.List) do
							if tbl.Target == target then
								Import._changed(tbl)
								break
							end
						end
					end)
					
				end
			end
		end
		rig = nil
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

local _g = _G.MoonGlobal
------------------------------------------------------------
	local Players = game:GetService("Players")
	local thumbnail = function(id)
		return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size150x150)
	end

	local WindowData = _g.WindowData:new("Character Inserter", script.Contents)
	WindowData.resize = true

	local Win  = _g.Window:new(script.Name, WindowData)
	local OwnId = game:GetService("StudioService"):GetUserId()
	local SavedCharacterList = Win:GetSavedValue("CharList", {})
	if SavedCharacterList[1] == nil or SavedCharacterList[1].Id ~= OwnId then
		SavedCharacterList[1] = {Id = OwnId, Image = thumbnail(OwnId)}
		Win:SaveValue("CharList", SavedCharacterList)
	end

	ImageList:new(Win.g_e.CharList, OwnId, nil, SavedCharacterList)
	Tabs:new(Win.g_e.Tabs, "User")

	Radio:new(Win.g_e.BodyChoice, "Original")
	Button:new(Win.g_e.Delete)
	Check:new(Win.g_e.IgnoreBody, false)
	Button:new(Win.g_e.Insert)
	TextInput:new(Win.g_e.UserInput, "")

	MoonScroll:new(Win.g_e.Presets, 30)
	MoonScroll:new(Win.g_e.FaceEdit, 30)

	local LoadingUI = Win.g_e.Tabs.UI.User.Loading
	Win:AddPaintedItem(LoadingUI, {TextColor3 = "main"})
------------------------------------------------------------
do
	local finding = false
	
	local buffers
	local ani_running = false
	
	local preset_buffers
	local face_ui_data
	local face_stored
	local face_done

	local face_accs = {}
	
	Win.ani_step = function(step)
		for _, buffer in pairs(buffers) do
			buffer[2] = (buffer[2] + step * _g.DEFAULT_FPS) % buffer[3]
			local frame = math.floor(buffer[2])
			for _, data in pairs(buffer[1]) do
				data.Target[data.Prop] = data.Buffer[frame]
			end
			if buffers == preset_buffers then
				buffer[5] = (buffer[5] + step) % 2
				buffer[4]:SetPrimaryPartCFrame(CFrame.new() * CFrame.Angles(0, (math.pi/6) * math.sin(2*math.pi * (buffer[5] / 2)), 0))
			else
				local cf = buffer[4].Head:GetRenderCFrame()
				buffer[5].CFrame = CFrame.new(cf.p + Vector3.new(0, 0.1, 0) + cf.lookVector*100, cf.p + Vector3.new(0, 0.1, 0))
			end
		end
	end
	
	Win.apply_face = function(tbl)
		if not face_done then return end
		
		local desc = tbl[3]
		local insert_accs = tbl.acc_tbl
		
		local target_rigs = {}
		
		for _, rig in pairs(game.Selection:Get()) do
			if _g.CheckIfRig(rig) and rig:FindFirstChild("Humanoid") and rig.Humanoid:FindFirstChildOfClass("HumanoidDescription") and rig:FindFirstChild("Head") then
				table.insert(target_rigs, rig)
			end
		end
		
		if #target_rigs > 0 then
			_g.chs:SetWaypoint("Applying Faces")
			for _, rig in pairs(target_rigs) do
				local get_desc = rig.Humanoid:FindFirstChildOfClass("HumanoidDescription")
				get_desc.MoodAnimation = desc.MoodAnimation
				get_desc.Head = desc.Head
				rig.Humanoid:ApplyDescriptionReset(get_desc)
				
				for _, acc in pairs(rig:GetChildren()) do
					if acc.ClassName == "Accessory" and face_accs[acc.Name] then
						acc:Destroy()
					end
				end
				
				if insert_accs then
					for _, acc in pairs(insert_accs) do
						acc:Clone().Parent = rig
					end
				end
				
				for _, part in pairs(rig:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Locked = false
					end
				end
			end
			_g.chs:SetWaypoint("Applied Faces")
		end
	end
	
	local PresetTemplate = Presets.Canvas.Template
	PresetTemplate.Parent = nil

	local PresetRigs = {"R6", "TemplateR6", "R15", "TemplateR15", "OldR15", "TemplateOldR15"}

	Presets:SetCanvasSize(Presets.Canvas.UIGridLayout.AbsoluteContentSize.Y)
	Presets.Canvas.UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Presets:SetCanvasSize(Presets.Canvas.UIGridLayout.AbsoluteContentSize.Y)
	end)

	local PresetParent = Presets.Canvas.Parent
	Presets.Canvas.Parent = nil
	
	local FaceTemplate = FaceEdit.Canvas.Template
	FaceTemplate.Parent = nil

	local face_ids = {946, 945, 948, 947, 949, 966, 956, 957, 962, 964, 967, 959}

	FaceEdit:SetCanvasSize(FaceEdit.Canvas.UIGridLayout.AbsoluteContentSize.Y)
	FaceEdit.Canvas.UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		FaceEdit:SetCanvasSize(FaceEdit.Canvas.UIGridLayout.AbsoluteContentSize.Y)
	end)

	local FaceParent = FaceEdit.Canvas.Parent
	FaceEdit.Canvas.Parent = nil
	
	
	Tabs._changed = function(tabName)
		if ani_running then
			ani_running = false
			_g.run_serv:UnbindFromRenderStep("MoonAnimator2CharacterInserter")
			buffers = nil
		end
		if tabName == "FaceEdit" then
			if face_stored == nil then
				face_stored = {}
				face_ui_data = {}
				
				local succ, err = pcall(function()
					for _, id in pairs(face_ids) do
						local bundle = _g.asset:GetBundleDetailsAsync(id)
						local get_fit
						for _, item in pairs(bundle.Items) do
							if item.Type == "UserOutfit" then
								get_fit = item.Id
								break
							end
						end
						
						if get_fit then
							local desc = game.Players:GetHumanoidDescriptionFromOutfitId(get_fit)
							if desc then
								local newFace = FaceTemplate:Clone()
								newFace.Name = bundle.Name
								newFace.Label.Text = bundle.Name
								newFace.CurrentCamera = newFace.Camera

								local rigView = _g.rigs.R15:Clone()
								rigView:SetPrimaryPartCFrame(CFrame.new())
								rigView.Parent = newFace.WorldModel
								
								for _, part in pairs(rigView:GetDescendants()) do
									if part:IsA("BasePart") and part.Name ~= "Head" then
										part.Transparency = 1
									end
								end
								
								table.insert(face_ui_data, {newFace, rigView, desc, newFace.CurrentCamera})
							end
						end
					end
				end)
				
				local count = #face_ui_data
				local face_buffers = {}
				
				if succ and count > 0 then
					local sorting = {
						["Chiseled Good Looks"] = 1,
						["Makeup Minimalist"] = 2,
						["Sun Kissed Freckles"] = 3,
						["Squigglin' Out"] = 4,
						["Ready for Adventure"] = 5,
						["Cute and Casual"] = 6,
					}
					setmetatable(sorting, {__index = function() return math.huge end})
					table.sort(face_ui_data, function(a,b) return sorting[a[1].Name] < sorting[b[1].Name] end)
					
					local apply_count = 0
					for _, tbl in pairs(face_ui_data) do
						if Tabs.CurrentTab ~= "FaceEdit" then
							face_stored = nil
							return
						end
						Win:AddPaintedItem(tbl[1].Label, {TextColor3 = "main"})
						tbl[1].Parent = FaceEdit.Canvas
						tbl[1].InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								Win.apply_face(tbl)
							end
						end)
						task.delay(0, function()
							tbl[2].Humanoid:ApplyDescription(tbl[3])
							local buf, len = _g.RobloxToBuffers(_g.anis.R15Idle, tbl[2], 60)
							table.insert(face_buffers, {buf, math.random(0, len - 1), len, tbl[2], tbl[4]})
							apply_count = apply_count + 1
							if apply_count == count then
								FaceEdit.Canvas.Parent.Parent.Loading.Visible = false
								
								face_stored = face_buffers
								if Tabs.CurrentTab == "FaceEdit" then
									buffers = face_stored
									_g.run_serv:BindToRenderStep("MoonAnimator2CharacterInserter", 200, Win.ani_step)
									ani_running = true
								end

								for _, tbl in pairs(face_ui_data) do
									for _, acc in pairs(tbl[2]:GetChildren()) do
										if acc.ClassName == "Accessory" then
											if tbl.acc_tbl == nil then tbl.acc_tbl = {} end
											table.insert(tbl.acc_tbl, acc)
											face_accs[acc.Name] = true
										end
									end
								end
	
								face_done = true
							end
						end)
					end
				else
					face_stored = nil
				end
			end
			if Tabs.CurrentTab == "FaceEdit" then
				if face_done then
					buffers = face_stored
					_g.run_serv:BindToRenderStep("MoonAnimator2CharacterInserter", 200, Win.ani_step)
					ani_running = true
				end
				FaceEdit.Canvas.Parent = FaceParent
				Presets.Canvas.Parent = nil
			end
		elseif tabName == "Presets" then
			if preset_buffers == nil then
				preset_buffers = {}
				for ind, nm in pairs(PresetRigs) do
					local newPreset = PresetTemplate:Clone()
					newPreset.Name = nm
					newPreset.Label.Text = nm
					newPreset.CurrentCamera = newPreset.Camera

					Win:AddPaintedItem(newPreset.Label, {TextColor3 = "main"})

					local rigView = _g.rigs[nm]:Clone()
					rigView:SetPrimaryPartCFrame(CFrame.new())
					rigView.Parent = newPreset.WorldModel
					newPreset.CurrentCamera.CFrame = CFrame.new(Vector3.new(220, 220, -220), Vector3.new(0, 0, 0))
					newPreset.Parent = Presets.Canvas

					local buf, len = _g.RobloxToBuffers((nm == "R6" or nm == "TemplateR6") and _g.anis.R6Walk or _g.anis.R15Walk, rigView, 60)
					table.insert(preset_buffers, {buf, math.random(0, len - 1), len, rigView, math.random(0, 199) / 100})

					newPreset.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							Win.ParentRig(_g.rigs[newPreset.Name]:Clone())
						end
					end)
				end
			end
			buffers = preset_buffers
			_g.run_serv:BindToRenderStep("MoonAnimator2CharacterInserter", 200, Win.ani_step)
			ani_running = true
			FaceEdit.Canvas.Parent = nil
			Presets.Canvas.Parent = PresetParent
		else
			FaceEdit.Canvas.Parent = nil
			Presets.Canvas.Parent = nil
		end
	end	
	
	Win.OnFocusGained = function()
		if Tabs.CurrentTab == "Presets" then
			Presets.Canvas.Parent = nil
			task.delay(0, function()
				Tabs._changed("Presets")
			end)
		elseif Tabs.CurrentTab == "FaceEdit" then
			FaceEdit.Canvas.Parent = nil
			task.delay(0, function()
				Tabs._changed("FaceEdit")
			end)
		end
	end

	Win.OnOpen = function()
		Win.g_e.CharList:Set(OwnId)
		UserInput:Set(OwnId)
		Win.g_e.Delete:SetActive(false)

		local txt = Win.g_e.CharList.UI.ImageId.Label.Text

		task.spawn(function() 
			nm = Players:GetNameFromUserIdAsync(tonumber(txt)) 
			if txt == Win.g_e.CharList.UI.ImageId.Label.Text then
				Win.g_e.CharList.UI.ImageId.Label.Text = nm
			end
		end)

		return true
	end

	Win.OnClose = function()
		Tabs:ShowTab("User", true)
		return true
	end

	Win.g_e.Delete.OnClick = function()
		local found = Win.FindId(tonumber(UserInput.Value))

		if found and found ~= 1 then
			local id = SavedCharacterList[found + 1]
			if id then
				id = id.Id
			else
				id = SavedCharacterList[found - 1]
				if id then
					id = id.Id
				end
			end

			table.remove(SavedCharacterList, found)
			Win.RefreshCharacterList(id)
		end
	end

	Insert.OnClick = function()
		if finding or LoadingUI.Visible then return false end

		LoadingUI.Text = "Inserting..."
		for _, ui in pairs(LoadingUI.Parent:GetChildren()) do
			if ui.Visible ~= nil then
				ui.Visible = ui == LoadingUI
			end
		end

		UserInput:Set(CharList.Value)
		
		local insertedId = tonumber(UserInput.Value)
		local insertedImage = CharList.UI.CurrentImg.Image

		local rig
		local succ, err = pcall(function() rig = Win.InsertRigFromPlayerId(insertedId, Win.g_e.BodyChoice.Value, Win.g_e.IgnoreBody.Value) end)
		if succ and rig then
			Win.ParentRig(rig)

			if insertedId ~= SavedCharacterList[1].Id then
				local found = Win.FindId(insertedId)
				if found then
					local tbl = table.remove(SavedCharacterList, found)
					table.insert(SavedCharacterList, 2, tbl)
				else
					if #SavedCharacterList == 10 then
						table.remove(SavedCharacterList, 10)
					end
					table.insert(SavedCharacterList, 2, {Id = insertedId, Image = insertedImage})
				end
				Win.RefreshCharacterList(insertedId)
			else
				CharList:Set(SavedCharacterList[1].Id)
			end
		else
			LoadingUI.Text = "Failed..."
			wait(2)
		end

		for _, ui in pairs(LoadingUI.Parent:GetChildren()) do
			if ui.Visible ~= nil then
				ui.Visible = ui ~= LoadingUI
			end
		end
	end

	Win.g_e.CharList._changed = function(value)
		Win.g_e.Delete:SetActive(Win.g_e.CharList.Value ~= OwnId)
		UserInput:Set(Win.g_e.CharList.Value)
		local txt = Win.g_e.CharList.UI.ImageId.Label.Text

		task.spawn(function() 
			nm = Players:GetNameFromUserIdAsync(tonumber(txt)) 
			if txt == Win.g_e.CharList.UI.ImageId.Label.Text then
				Win.g_e.CharList.UI.ImageId.Label.Text = nm
			end
		end)
	end
	
	UserInput._changed = function(getVal)
		if finding or LoadingUI.Visible then return false end

		finding = true
		UserInput.UI.Frame.Input.TextEditable = false
		UserInput.UI.Frame.Input.Text = "finding user..."
		Insert:SetActive(false)
		
		if tonumber(getVal) then
			local nm
			local img
			local res = pcall(function() 
				nm = Players:GetNameFromUserIdAsync(tonumber(getVal)) 
				img = thumbnail(getVal)
			end)
			
			if res then
				CharList.UI.CurrentImg.Image = img
				CharList.UI.ImageId.Label.Text = nm
				CharList.UI.BottomSec.Label.Text = "- / -"
				CharList.Value = tonumber(getVal)
				UserInput:Set(getVal)
			else
				UserInput.UI.Frame.Input.Text = "user not found..."
			end
		else
			local nm
			local id
			local img
			local res = pcall(function() 
				id = Players:GetUserIdFromNameAsync(getVal)
				nm = Players:GetNameFromUserIdAsync(id) 
				img = thumbnail(id)
			end)
			
			if res then
				CharList.UI.CurrentImg.Image = img
				CharList.UI.ImageId.Label.Text = nm
				CharList.UI.BottomSec.Label.Text = "- / -"
				CharList.Value = id
				UserInput:Set(tostring(id))
			else
				UserInput.UI.Frame.Input.Text = "user not found..."
			end
		end

		finding = false
		UserInput.UI.Frame.Input.TextEditable = true
		Insert:SetActive(true)
	end
end
------------------------------------------------------------
do
	Win.FindId = function(id)
		local found = nil

		for ind, tbl in pairs(SavedCharacterList) do
			if tbl.Id == id then
				found = ind
				break
			end
		end

		return found
	end

	Win.RefreshCharacterList = function(insertedId)
		CharList:SetList(SavedCharacterList)
		
		if insertedId == nil then
			CharList:Set(SavedCharacterList[1].Id)
		else
			local found = Win.FindId(insertedId)
			if found then
				CharList:Set(SavedCharacterList[found].Id, true)
			end
		end

		Win:SaveValue("CharList", SavedCharacterList)
	end

	Win.ParentRig = function(rig)
		_g.chs:SetWaypoint("Parenting Rig")
		rig.Parent = workspace

		local pos = workspace.CurrentCamera.CFrame.p + Vector3.new(6, 6, 6) * workspace.CurrentCamera.CFrame.lookVector
		pos = Vector3.new(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5), math.floor(pos.Z + 0.5))
		rig.PrimaryPart.CFrame = CFrame.new(pos)

		game.Selection:Set({rig})
		_g.chs:SetWaypoint("Parented Rig")
	end
	
	function get_hum_desc(model, id)
		--pcall(function() game.Players:GetHumanoidDescriptionFromUserId(id).Parent = model.Humanoid end)
	end

	Win.InsertRigFromPlayerId = function(targetId, bodyType, ignoreBodyParts)
		local charName = Players:GetNameFromUserIdAsync(targetId)
		
		if bodyType ~= "OldR15" then
			local model
			
			if bodyType == "Original" then
				model = Players:CreateHumanoidModelFromUserId(targetId)
			elseif bodyType == "R6" then
				model = Players:CreateHumanoidModelFromDescription(Players:GetHumanoidDescriptionFromUserId(targetId), Enum.HumanoidRigType.R6)
			elseif bodyType == "R15" then
				model = Players:CreateHumanoidModelFromDescription(Players:GetHumanoidDescriptionFromUserId(targetId), Enum.HumanoidRigType.R15)
			end
			
			model.Name = charName
			model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
			model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			model.PrimaryPart.Anchored = true

			for _, obj in pairs(model:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Locked = false
				elseif obj:IsA("BaseScript") then
					obj:Destroy()
				end
			end
			get_hum_desc(model, targetId)
			return model
		end
		
		local charAppear = Players:GetCharacterAppearanceAsync(targetId)
		local charName = Players:GetNameFromUserIdAsync(targetId)
		
		if charAppear and charName then
			local baseRig = _g.rigs[bodyType]:Clone()
			baseRig.Name = charName
			
			if not ignoreBodyParts then
				for _, acc in pairs(charAppear:GetChildren()) do
					if acc.Name == "R6" and bodyType == "R6" then
						for _,obj in pairs(acc:GetChildren()) do
							obj.Parent = baseRig
						end
					elseif acc.Name == "R15Fixed" and bodyType ~= "R6"  then
						for _,obj in pairs(acc:GetChildren()) do
							if baseRig:FindFirstChild(obj.Name) then
								for _,junk in pairs(obj:GetChildren()) do
									if junk.ClassName == "Motor6D" then
										junk:Destroy()
									end
								end
								
								local origPart = baseRig[obj.Name]
								local motor = origPart:FindFirstChildOfClass("Motor6D")
								
								obj.Parent = baseRig
								obj.CFrame = origPart.CFrame
								if motor then
									motor.Parent = obj
									motor.Part1 = obj
								end

								origPart:Destroy()
							end
						end
					elseif acc.ClassName == "NumberValue" and bodyType ~= "R6" then
						acc.Parent = baseRig.Humanoid
					end
				end
				if bodyType ~= "R6" then
					for _, joint in pairs(baseRig:GetDescendants()) do
						if joint.ClassName == "Motor6D" then
							if joint.Part0 and joint.Part0:FindFirstChild(joint.Name.."RigAttachment") then
								joint.C0 = joint.Part0[joint.Name.."RigAttachment"].CFrame
							end
							if joint.Part1 and joint.Part1:FindFirstChild(joint.Name.."RigAttachment") then
								joint.C1 = joint.Part1[joint.Name.."RigAttachment"].CFrame
							end
						end
					end
				end
			end

			for _,acc in pairs(charAppear:GetChildren()) do
				if acc.ClassName == "Accessory" or acc.ClassName == "BodyColors" or acc.ClassName == "Shirt" or acc.ClassName == "Pants" or acc.ClassName == "ShirtGraphic" then
					if acc.ClassName == "Accessory" then
						baseRig.Humanoid:AddAccessory(acc)
					else
						acc.Parent = baseRig
					end
				elseif acc.Name == "face" or acc.Name == "Face" then
					local oldFace = baseRig.Head:FindFirstChild("face") and baseRig.Head.face or baseRig.Head:FindFirstChild("Face")
					if oldFace then
						oldFace:Destroy()
					end
					acc.Parent = baseRig.Head
				elseif acc:IsA("DataModelMesh") then
					local oldMesh = baseRig.Head:FindFirstChildWhichIsA("DataModelMesh")
					if oldMesh then
						oldMesh:Destroy()
					end
					acc.Parent = baseRig.Head
				end
			end
				
			for _,part in pairs(baseRig:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Locked = false
				end
			end
			
			charAppear:Destroy()
			get_hum_desc(baseRig, targetId)
			return baseRig
		end
	end
end

return Win

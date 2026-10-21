local _g = _G.MoonGlobal
------------------------------------------------------------
	local selServ = game:GetService("Selection")
	
	local WindowData = _g.WindowData:new("Easy Weld", script.Contents)

	local Win  = _g.Window:new(script.Name, WindowData)

	Tabs:new(Win.g_e.Tabs, "Cleaner")

	ValueLabel:new(Win.g_e.model_Model, nil); local model_Model = Win.g_e.model_Model
	ValueLabel:new(Win.g_e.model_BasePart, nil); local model_BasePart = Win.g_e.model_BasePart
	Button:new(Win.g_e.model_WeldModel); local model_WeldModel = Win.g_e.model_WeldModel

	ValueLabel:new(Win.g_e.part_BasePart, nil); local part_BasePart = Win.g_e.part_BasePart
	ValueLabel:new(Win.g_e.part_TargetPart, nil); local part_TargetPart = Win.g_e.part_TargetPart
	Button:new(Win.g_e.part_Join); local part_Join = Win.g_e.part_Join
	Button:new(Win.g_e.part_JoinInPlace); local part_JoinInPlace = Win.g_e.part_JoinInPlace
	Check:new(Win.g_e.part_Animatable, true, nil); local part_Animatable = Win.g_e.part_Animatable

	ValueLabel:new(Win.g_e.clean_TargetTool, nil); local clean_TargetTool = Win.g_e.clean_TargetTool
	Button:new(Win.g_e.clean_Tool); local clean_Tool = Win.g_e.clean_Tool

	Win:AddPaintedItem(UI.Tabs.Cleaner.Instr, {TextColor3 = "highlight"})
	Win:AddPaintedItem(UI.Tabs.Model.Instr, {TextColor3 = "highlight"})
	Win:AddPaintedItem(UI.Tabs.Parts.Instr, {TextColor3 = "highlight"})
------------------------------------------------------------
do
	local selCon

	Win.OnOpen = function()
		selCon = selServ.SelectionChanged:Connect(Win.RefreshSelection)
		Win.RefreshSelection()
		part_Animatable:Set(true)
		return true
	end

	Win.OnClose = function()
		selCon:Disconnect()
		selCon = nil
		return true
	end

	function JoinParts(jointType, p0, p1, in_place)
		local cf
		if in_place then
			cf = p0.CFrame:ToObjectSpace(p1.CFrame)
		end

		p1.Anchored = true
		for _, joint in pairs(p1:GetJoints()) do
			if (joint.Part0 == p0 and joint.Part1 == p1) or (joint.Part0 == p1 and joint.Part1 == p0) then
				joint.Parent = nil
			end
		end

		local motor = Instance.new(jointType)
		motor.Name = p1.Name
		motor.Part0 = p0
		motor.Part1 = p1
		if cf then
			motor.C0 = cf
		end
		motor.Parent = p0

		p1.Anchored = false

		return motor
	end

	local function part_joinHelp(inPlace)
		_g.chs:SetWaypoint("Welding Parts")
		local jointType = part_Animatable.Value and "Motor6D" or "Weld"

		if type(part_TargetPart.Value) == "table" then
			local newMotors = {}
			for _, part in pairs(part_TargetPart.Value) do
				table.insert(newMotors, JoinParts(jointType, part_BasePart.Value, part, inPlace))
			end
			selServ:Set(newMotors)
		else
			selServ:Set({JoinParts(jointType, part_BasePart.Value, part_TargetPart.Value, inPlace)})
		end
		_g.chs:SetWaypoint("Welded Parts")
	end
	part_Join.OnClick = function()
		part_joinHelp(false)
	end
	part_JoinInPlace.OnClick = function()
		part_joinHelp(true)
	end

	model_WeldModel.OnClick = function()
		_g.chs:SetWaypoint("Welding Model")
		local basePart = model_BasePart.Value
		local parts = {}

		for _, obj in pairs(model_Model.Value:GetDescendants()) do
			if obj:IsA("BasePart") and obj ~= basePart then
				obj:BreakJoints()
				table.insert(parts, obj)
			elseif obj:IsA("JointInstance") then
				obj.Parent = nil	
			end
		end

		local newMotors = {}
		for _, part in pairs(parts) do
			table.insert(newMotors, JoinParts("Weld", basePart, part, true))
		end
		selServ:Set(newMotors)
		_g.chs:SetWaypoint("Welded Model")
	end

	
		local function planCleanInput(cleanTarget)
			if typeof(cleanTarget) ~= "Instance" or not (cleanTarget.ClassName == "Tool"
				or cleanTarget.ClassName == "Model" or cleanTarget.ClassName == "Folder") then
				return nil, "Select a Tool, Model, or Folder containing at least one BasePart."
			end
		local masterHandles = {Handle = true, Grip = true}
		local basePart
		local allParts = {}

		for _, obj in pairs(cleanTarget:GetDescendants()) do
			if obj:IsA("BasePart") then
				table.insert(allParts, obj)
				if masterHandles[obj.Name] then
					basePart = obj
				elseif basePart == nil or not masterHandles[basePart.Name] then
					if obj.Transparency == 1 and (basePart == nil or obj.Size.magnitude > basePart.Size.magnitude) then
						basePart = obj
					end
				end
			end
		end
			if #allParts == 0 then
				return nil, "A selected Tool, Model, or Folder contains no BaseParts to clean."
			end

		if basePart == nil then
			for _, part in pairs(allParts) do
				if basePart == nil or part.Size.magnitude > basePart.Size.magnitude then
					basePart = part
				end
			end
		end
			return {target = cleanTarget, basePart = basePart, parts = allParts}
		end

		local function clean_InputTool(plan)
			local cleanTarget, basePart, allParts = plan.target, plan.basePart, plan.parts
			local allowed = {"ParticleEmitter", "Trail", "Beam", "Fire",
							 "ForceField", "Sparkles", "Smoke", "Decal", 
							 "BlockMesh", "DataModelMesh", "Light", "Constraint",
							 "SurfaceGui", "BillboardGui", "GuiObject", "SurfaceAppearance"}

		local cleanedTool = Instance.new("Model"); cleanedTool.Name = cleanTarget.Name
			local decorParts = Instance.new("Model", cleanedTool); decorParts.Name = "Parts"

		local newBasePart
		local newParts = {}
		
		for _, part in pairs(allParts) do
			local cpy = part:Clone()
			cpy.Locked = false
			cpy.CanCollide = false
			cpy.Massless = true

			for _, obj in pairs(cpy:GetDescendants()) do
				local check = false

				for _, cN in pairs(allowed) do
					if obj:IsA(cN) then
						check = true
						break
					end
				end

				if not check then
					obj.Parent = nil
				end
			end

			if part == basePart then
				newBasePart = cpy
				cpy.Anchored = true
				cpy.Parent = cleanedTool
				cleanedTool.PrimaryPart = cpy
			else
				table.insert(newParts, cpy)
				cpy.Anchored = false
				cpy.Parent = decorParts
			end

			cpy:BreakJoints()
		end

		for _, part in pairs(newParts) do
			JoinParts("Weld", newBasePart, part, true)
		end

		cleanedTool:SetPrimaryPartCFrame(CFrame.new(newBasePart.Position))
		cleanTarget.Parent = nil
		cleanedTool.Parent = workspace
	end
	clean_Tool.OnClick = function()
			local targets = type(clean_TargetTool.Value) == "table" and clean_TargetTool.Value or {clean_TargetTool.Value}
			local plans = {}
			-- Validate the complete selection before changing any container. A bad
			-- later selection must not leave earlier tools partially cleaned.
			for _, tool in pairs(targets) do
				local plan, message = planCleanInput(tool)
				if not plan then
					_g.Windows.MsgBox.Popup(Win, {Title = "Cannot Clean Tool", Content = message})
					return false, message
			end
				table.insert(plans, plan)
		end
			if #plans == 0 then
				local message = "Select a Tool, Model, or Folder containing at least one BasePart."
				_g.Windows.MsgBox.Popup(Win, {Title = "Cannot Clean Tool", Content = message})
				return false, message
			end
			_g.chs:SetWaypoint("Cleaning Tool")
			for _, plan in ipairs(plans) do clean_InputTool(plan) end
		_g.chs:SetWaypoint("Cleaned Tool")
			return true
	end
end
------------------------------------------------------------
do
	function Win.RefreshSelection()
		local sel = selServ:Get()

		model_Model:Set(nil)
		model_BasePart:Set(nil)
		model_WeldModel:SetActive(false)

		part_Join:SetActive(false)
		part_JoinInPlace:SetActive(false)
		part_BasePart:Set(nil)
		part_TargetPart:Set(nil)

		clean_TargetTool:Set(nil)
		clean_Tool:SetActive(false)

		for ind, obj in pairs(sel) do
			if ind == 1 then
				if obj.ClassName == "Model" then
					model_Model:Set(obj)
				end

				if obj:IsA("BasePart") then
					part_BasePart:Set(obj)
				end

				if obj.ClassName == "Tool" or obj.ClassName == "Model" or obj.ClassName == "Folder" then
					clean_TargetTool:Set(obj)
					clean_Tool:SetActive(true)
				end
			elseif ind == 2 then
				if model_Model.Value and obj:IsDescendantOf(model_Model.Value) and obj:IsA("BasePart") then
					model_BasePart:Set(obj)
					model_WeldModel:SetActive(true)
				end

				if part_BasePart.Value and obj:IsA("BasePart") then
					part_TargetPart:Set(obj)
					part_Join:SetActive(true)
					part_JoinInPlace:SetActive(true)
				end

				if clean_TargetTool.Value and (obj.ClassName == "Tool" or obj.ClassName == "Model" or obj.ClassName == "Folder") then
					clean_TargetTool:Set({sel[1], sel[2]})
				end
			elseif ind == 3 then
				if part_BasePart.Value and part_TargetPart.Value then
					local variedParts = {sel[2]}
					for ind = 3, #sel do
						local obj = sel[ind]
						if obj:IsA("BasePart") then
							table.insert(variedParts, obj)
						end
					end
					if #variedParts > 1 then
						part_TargetPart:Set(variedParts)
					end
				end

				local variedTools = {}
				for ind = 1, #sel do
					local obj = sel[ind]
					if obj.ClassName == "Tool" or obj.ClassName == "Model" or obj.ClassName == "Folder" then
						table.insert(variedTools, obj)
					end
				end
				if #variedTools > 1 then
					clean_TargetTool:Set(variedTools)
				end
				
				break
			end
		end
	end
end

return Win

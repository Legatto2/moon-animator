local module = {}
------------------------------------------------------------
local global = {}

global.ease = {}

function easeIn(t,func)
	return func(t)
end

function easeOut(t,func)
	return 1-func(1-t)
end

function bounce(t)
	if t<.36363636 then
		return 7.5625*t*t
	elseif t<.72727272 then
		t=t-.54545454
		return 7.5625*t*t+.75
	elseif t<.90909090 then
		t=t-.81818181
		return 7.5625*t*t+.9375
	else
		t=t-.95454545
		return 7.5625*t*t+.984375
	end
end

-- linear
global.ease.Linear = function(val)
	return val
end

-- constant
global.ease.ConstantIn = function(val)
	return 1
end
global.ease.ConstantOut = function(val)
	return 0
end
global.ease.ConstantInOut = function(val)
	return 0.5
end

-- elastic
global.ease.ElasticIn = function(val)
	local p = 0.3;
	local t = 1 - val;
	local s = p/4;
	return 1 - (1 + 2^(-10*t) * math.sin( (t-s)*(math.pi*2)/p ));
end
global.ease.ElasticOut = function(val)
	local p = 0.3;
	local t = val;
	local s = p/4;
	return (1 +2^(-10*t) * math.sin( (t-s)*(math.pi*2)/p ));
end
global.ease.ElasticInOut = function(val)
	local t = (1 - val) *2;
	local p = (.3*1.5);
	local s = p/4;
	if (t < 1) then
		t = t - 1;
		return 1 - (-.5 * 2^(10*t) * math.sin((t-s)*(math.pi*2)/p ));
	else
		t  = t - 1;
		return 1 - (1 + 0.5 * 2^(-10*t) * math.sin((t-s)*(math.pi*2)/p ));
	end
end
global.ease.ElasticOutIn = function(val)
	val=val*2
	if val < 1 then
		return easeOut(val,global.ease.ElasticIn)*.5
	else
		return .5+easeIn(val-1,global.ease.ElasticIn)*.5
	end
end

-- cubic
global.ease.CubicIn = function(val)
	return val^3
end
global.ease.CubicOut = function(val)
	return easeOut(val, global.ease.CubicIn)
end
global.ease.CubicInOut = function(val)
	val=val*2
	if val < 1 then
		return easeIn(val,global.ease.CubicIn)*.5
	else
		return .5+easeOut(val-1,global.ease.CubicIn)*.5
	end
end
global.ease.CubicOutIn = function(val)
	val=val*2
	if val < 1 then
		return easeOut(val,global.ease.CubicIn)*.5
	else
		return .5+easeIn(val-1,global.ease.CubicIn)*.5
	end
end

-- bounce
global.ease.BounceIn = function(val)
	return easeOut(val, bounce)
end
global.ease.BounceOut = function(val)
	return bounce(val)
end
global.ease.BounceInOut = function(val)
	val=val*2
	if val < 1 then
		return easeOut(val,bounce)*.5
	else
		return .5+easeIn(val-1,bounce)*.5
	end
end
global.ease.BounceOutIn = function(val)
	val=val*2
	if val < 1 then
		return easeIn(val,bounce)*.5
	else
		return .5+easeOut(val-1,bounce)*.5
	end
end

-- quad
global.ease.QuadIn = function(val)
	return val*val
end
global.ease.QuadOut = function(val)
	return -val*val + 2*val
end
global.ease.QuadInOut = function(val)
	return val < 0.5 and 2*val*val or -2*val*val + 4*val - 1
end
global.ease.QuadOutIn = function(val)
	return val < 0.5 and -2*(val-0.5)^2+0.5 or 2*(val-0.5)^2+0.5
end

-- quart
global.ease.QuartIn = function(val)
	return val^4
end
global.ease.QuartOut = function(val)
	return -(val-1)^4+1
end
global.ease.QuartInOut = function(val)
	return val < 0.5 and 8*val^4 or -8*(val-1)^4+1
end
global.ease.QuartOutIn = function(val)
	return val < 0.5 and -8*(val-0.5)^4+0.5 or 8*(val-0.5)^4+0.5
end

-- quint
global.ease.QuintIn = function(val)
	return val^5
end
global.ease.QuintOut = function(val)
	return (val-1)^5+1
end
global.ease.QuintInOut = function(val)
	return val < 0.5 and 16*val^5 or 16*(val-1)^5+1
end
global.ease.QuintOutIn = function(val)
	return 16*(val-0.5)^5+0.5
end

-- sextic
global.ease.SexticIn = function(val)
	return val^6
end
global.ease.SexticOut = function(val)
	return -(val-1)^6+1
end
global.ease.SexticInOut = function(val)
	return val < 0.5 and 32*val^6 or -32*(val-1)^6+1
end
global.ease.SexticOutIn = function(val)
	return val < 0.5 and -32*(val-0.5)^6+0.5 or 32*(val-0.5)^6+0.5
end

-- sine
global.ease.SineIn = function(val)
	return math.sin(math.pi/2*val-math.pi/2)+1
end
global.ease.SineOut = function(val)
	return math.sin(math.pi/2*val)
end
global.ease.SineInOut = function(val)
	return 0.5*math.sin(math.pi*val-math.pi/2)+0.5
end
global.ease.SineOutIn = function(val)
	return val < 0.5 and 0.5*math.sin(math.pi*val) or 0.5*math.sin(math.pi*val-math.pi)+1
end

-- circ
global.ease.CircIn = function(val)
	return -math.sqrt(1-val*val)+1
end
global.ease.CircOut = function(val)
	return math.sqrt(-(val-1)^2+1)
end
global.ease.CircInOut = function(val)
	return val < 0.5 and -math.sqrt(-val*val+0.25)+0.5 or math.sqrt(-(val-1)^2+0.25)+0.5
end
global.ease.CircOutIn = function(val)
	return val < 0.5 and math.sqrt(-(val-0.5)^2+0.25) or -math.sqrt(-(val-0.5)^2+0.25)+ 1	
end

-- expo
global.ease.ExpoIn = function(val)
	if val == 0 or val == 1 then
		return val
	end
	return 2^(10*val-10)
end
global.ease.ExpoOut = function(val)
	if val == 0 or val == 1 then
		return val
	end
	return -2^(-10*val)+1
end
global.ease.ExpoInOut = function(val)
	if val == 0 or val == 1 then
		return val
	end
	return val == 0.5 and 0.5 or val < 0.5 and 0.5*2^(20*val-10) or 0.5*-2^(-20*val+10)+1
end
global.ease.ExpoOutIn = function(val)
	if val == 0 or val == 1 then
		return val
	end
	return val == 0.5 and 0.5 or val < 0.5 and 0.5005*-2^(-20*val)+0.5005 or 0.5*2^(20*val-20)+0.4995
end

-- back
global.ease.BackIn = function(val)
	return val*val*(2.70158*val-1.70158)
end
global.ease.BackOut = function(val)
	return (val-1)^2*(2.70158*(val-1)+1.70158)+1
end
global.ease.BackInOut = function(val)
	return val < 0.5 and 2*val*val*(7.189819*val-2.5949095) or 0.5*(2*val-2)^2*(3.5949095*(2*val-2)+2.5949095)+1
end
global.ease.BackOutIn = function(val)
	return val < 0.5 and 0.5*(2*val-1)^2*(3.5949095*(2*val-1)+2.5949095)+0.5 or 0.5*(2*val-1)^2*(3.5949095*(2*val-1)-2.5949095)+0.5	
end

global.ParsePath = function(model, path)
	local split = {}

	while true do
		local getDot = string.find(path, "%.")
		if getDot == nil then
			table.insert(split, path)
			break
		end
		table.insert(split, string.sub(path, 1, getDot - 1))
		path = string.sub(path, getDot + 1)
	end

	local cur = model:GetChildren()
	local new = {}

	for i = 1, #split do
		for _,obj in pairs(cur) do
			if obj.Name == split[i] then
				if i == #split then
					table.insert(new, obj)
				else
					for _,ch in pairs(obj:GetChildren()) do
						table.insert(new, ch)
					end	
				end
			end
		end	
		cur = new
		new = {}
	end

	if #cur > 1 then
		for _,getJoint in pairs(cur) do
			if getJoint.className == "Motor6D" then
				return getJoint
			end
		end
	end

	return cur[1]
end

global.ScanAniModel = function(model, noReset)
	local allJoints = {}
	local allModels = {model}

	function Scan(o)
		for i,v in pairs(o:GetChildren()) do
			if v.className == "Motor6D" then

				if tonumber(v.Name) then
					return false, ""
				end
				if string.find(v.Name, "%.") then
					return false, ""
				end
				if v.Part0 == v.Part1 and (v.Part0 and v.Part1) then
					return false, ""
				end

				table.insert(allJoints, {v, allModels[#allModels]})

				if v:FindFirstChild("DefaultC1") == nil then
					local def = Instance.new("CFrameValue")
					def.Value = v.C1
					def.Name = "DefaultC1"
					def.Parent = v
				elseif not noReset then
					v.C1 = v.DefaultC1.Value
				end
			elseif v.className == "Model" and v.PrimaryPart then

				if string.find(v.Name, "%.") then
					return false, ""
				end
				if tonumber(v.Name) then
					return false, ""
				end

				table.insert(allModels, v)
			end
			local res1, res2 = Scan(v)
			if res1 == false then
				return res1, res2
			end
		end
	end
	local res1, res2 = Scan(model)
	if res1 == false then
		return res1, res2
	end

	for indCurModel, actCurModel in pairs(allModels) do
		for indCheckModel, actCheckModel in pairs(allModels) do
			if indCheckModel ~= indCurModel then
				if actCheckModel:GetFullName() == actCurModel:GetFullName() then
					return false, ""
				end					
			end
		end
	end

	for indCurJoint, actCurJoint in pairs(allJoints) do
		for indCheckJoint, actCheckJoint in pairs(allJoints) do
			if indCheckJoint ~= indCurJoint then
				if actCheckJoint[1]:GetFullName() == actCurJoint[1]:GetFullName() then
					return false, ""
				end					
			end
		end
	end

	return allJoints, allModels
end

global.deepcopy = function(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[global.deepcopy(orig_key)] = global.deepcopy(orig_value)
		end
		setmetatable(copy, global.deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

global.EaseStyle = {
	{
		Name = "Linear",
		rblxEnum = Enum.PoseEasingStyle.Linear,
		dir = {"In", "Out", "InOut", "OutIn"},
		correction = {OutIn = "InOut"},
		func = {
			global.ease.Linear,
			global.ease.Linear,
			global.ease.Linear,
			global.ease.Linear
		}
	},
	{
		Name = "Constant",
		rblxEnum = Enum.PoseEasingStyle.Constant,
		dir = {"In", "Out", "InOut", "OutIn"},
		correction = {OutIn = "InOut"},
		func = {
			global.ease.ConstantIn,
			global.ease.ConstantOut,
			global.ease.ConstantInOut,
			global.ease.ConstantInOut
		}
	},
	{
		Name = "Sine",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.SineIn,
			global.ease.SineOut,
			global.ease.SineInOut,
			global.ease.SineOutIn,
		}
	},
	{
		Name = "Quad",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.QuadIn,
			global.ease.QuadOut,
			global.ease.QuadInOut,
			global.ease.QuadOutIn,
		}
	},
	{
		Name = "Cubic",
		rblxEnum = Enum.PoseEasingStyle.Cubic,
		dir = {"In", "Out", "InOut", "OutIn"},
		correction = {In = "Out", Out = "In"},
		custom = {OutIn = true},
		func = {
			global.ease.CubicIn,
			global.ease.CubicOut,
			global.ease.CubicInOut,
			global.ease.CubicOutIn,
		}
	},
	{
		Name = "Quart",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.QuartIn,
			global.ease.QuartOut,
			global.ease.QuartInOut,
			global.ease.QuartOutIn,
		}
	},
	{
		Name = "Quint",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.QuintIn,
			global.ease.QuintOut,
			global.ease.QuintInOut,
			global.ease.QuintOutIn,
		}
	},
	{
		Name = "Sextic",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.SexticIn,
			global.ease.SexticOut,
			global.ease.SexticInOut,
			global.ease.SexticOutIn,
		}
	},
	{
		Name = "Expo",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.ExpoIn,
			global.ease.ExpoOut,
			global.ease.ExpoInOut,
			global.ease.ExpoOutIn,
		}
	},
	{
		Name = "Circ",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.CircIn,
			global.ease.CircOut,
			global.ease.CircInOut,
			global.ease.CircOutIn,
		}
	},
	{
		Name = "Back",
		dir = {"In", "Out", "InOut", "OutIn"},
		func = {
			global.ease.BackIn,
			global.ease.BackOut,
			global.ease.BackInOut,
			global.ease.BackOutIn,
		}
	},
	{
		Name = "Elastic",
		rblxEnum = Enum.PoseEasingStyle.Elastic,
		dir = {"In", "Out", "InOut", "OutIn"},
		custom = {OutIn = true},
		func = {
			global.ease.ElasticIn,
			global.ease.ElasticOut,
			global.ease.ElasticInOut,
			global.ease.ElasticOutIn,
		}
	},
	{
		Name = "Bounce",
		rblxEnum = Enum.PoseEasingStyle.Bounce,
		dir = {"In", "Out", "InOut", "OutIn"},
		correction = {OutIn = "InOut"},
		custom = {InOut = true},
		func = {
			global.ease.BounceIn,
			global.ease.BounceOut,
			global.ease.BounceInOut,
			global.ease.BounceOutIn,
		}
	},
}

global.EaseColors = {
	Linear = Color3.fromRGB(23, 101, 184),
	Constant = Color3.fromRGB(233, 216, 121),
	Elastic = Color3.fromRGB(93, 184, 23),
	Cubic = Color3.fromRGB(184, 23, 133),
	Bounce = Color3.fromRGB(103, 23, 184),
	Quad = Color3.fromRGB(233, 24, 24),
	Quart = Color3.fromRGB(253, 91, 3),
	Quint = Color3.fromRGB(254, 198, 6),
	Sextic = Color3.fromRGB(172, 141, 224),
	Sine = Color3.fromRGB(0, 215, 23),
	Circ = Color3.fromRGB(16, 210, 229),
	Expo = Color3.fromRGB(255, 127, 200),
	Back = Color3.fromRGB(189, 195, 199),
}

for styNum,styTbl in pairs(global.EaseStyle) do
	styTbl.Value = styNum
	global.EaseColors[styNum] = global.EaseColors[styTbl.Name]

	for dirNum,dirName in pairs(styTbl.dir) do
		styTbl.dir[dirName] = dirNum
		styTbl.func[dirName] = styTbl.func[dirNum]
	end
	if styTbl.correction then
		styTbl.rev = {}
		for i,v in pairs(styTbl.correction) do
			styTbl.rev[v] = i
		end
	end
end
for styNum,styTbl in pairs(global.EaseStyle) do
	global.EaseStyle[styTbl.Name] = styTbl
end

global.defaultEaseColors = nil

global.labelColors = {
	Color3.fromRGB(64,101,184),
	Color3.fromRGB(255,236,145),
	Color3.fromRGB(145,255,181),
	Color3.fromRGB(255,145,164),
	Color3.fromRGB(181,145,255),
}
global.labelColorsText = {
	"Blue",
	"Yellow",
	"Green",
	"Red",
	"Purple",
}

global.Priority = {
	Enum.AnimationPriority.Core,
	Enum.AnimationPriority.Idle,
	Enum.AnimationPriority.Movement,
	Enum.AnimationPriority.Action,
}
global.PriorityText = {
	"Core (lowest)",
	"Idle",
	"Movement",
	"Action (highest)",
}

global.curModel = nil
global.curAni = nil
global.curName = nil
global.curJoints = nil

global.lastModel = nil

global.defaults = {
	Animation = {
		modelOrder = {}, 
		info = {
			name = "", 
			priority = Enum.AnimationPriority.Action, 
			looped = false, 
			length = 0, 
			fps = 60, 
			fastMode = false, 
			camSettings = {aniCameraRef = nil},
			hidden = {},
			lockedJoints = {}
		},
		labels = {}
	},
	Keyframe = {
		cf		  = CFrame.new(),
		easeDir   = "In",
		easeSty   = "Linear",
		weight 	  = 1,
		frmPos 	  = 0
	},
	Label = {
		frmPos = 0,
		name = "Label",
		code = "",
		color = 1
	}
}
------------------------------------------------------------
do
	function FindJoint(model, pose)
		local foundJoint = nil

		function JointScan(o)
			for i,v in pairs(o:GetChildren()) do
				if v.className == "Motor6D" and v.Part1.Name == pose.Name then
					foundJoint = v
					break
				end
				JointScan(v)
			end
		end
		JointScan(model)

		return foundJoint
	end
end
------------------------------------------------------------
do
	function Convert(input, fileTy1, fileTy2, model)
		if fileTy1 == "folder" and fileTy2 == "raw" then
			
			local newTbl = {}
			
			local curParent = newTbl
			local curIndex = {}
			
			function Scan(o)
				
				for i,v in pairs(o:GetChildren()) do
					if v.className == "Folder" then
						curParent[tonumber(v.Name) and tonumber(v.Name) or v.Name] = {}
						
						table.insert(curIndex, curParent)
						curParent = curParent[tonumber(v.Name) and tonumber(v.Name) or v.Name]
						
						Scan(v)
						
						curParent = curIndex[#curIndex]
						table.remove(curIndex, #curIndex)
					elseif string.find(v.className, "Value") then
						
						if v:FindFirstChild("enTy") and (v.Name == "easeDir" or v.Name == "easeSty") then
							v.enTy:Destroy()
						end
						
						if v:FindFirstChild("enTy") then
							curParent[tonumber(v.Name) and tonumber(v.Name) or v.Name] = Enum[v.enTy.Value][v.Value]
						else
							curParent[tonumber(v.Name) and tonumber(v.Name) or v.Name] = v.Value
						end
						
					end
				end
				
			end
			Scan(input)
			
			return newTbl
			
		elseif fileTy1 == "raw" and fileTy2 == "roblox" then

			local finalTbl = {}

			local allLabels = {}
			local usedLabels = {}
				for i,v in pairs(input.labels) do
					if v.name ~= "Label" then
						allLabels["lbl"..tostring(v.frmPos)] = v.name
					end
				end

			for _, modelPath in pairs(input.modelOrder) do
				local jointTbl = input[modelPath]
				if jointTbl then

					local actRig = modelPath == "_root" and model or global.ParsePath(model, modelPath)
					local allJoints, allModels = global.ScanAniModel(actRig, true)

					local output = Instance.new("KeyframeSequence")
					output.Name = input.info.name
					output.Loop = input.info.looped
					output.Priority = input.info.priority

						local allPaths = {}
					
						local allRobloxKeyframes = {}
						for jointPath, joint in pairs(jointTbl) do
							for keyframeIndex, keyframe in pairs(joint) do
								if allRobloxKeyframes[keyframe.frmPos] == nil then
									allRobloxKeyframes[keyframe.frmPos] = {}
								end
								allRobloxKeyframes[keyframe.frmPos][jointPath] = keyframe
							end
							allPaths[jointPath] = true
						end
						if allRobloxKeyframes[0] == nil then
							allRobloxKeyframes[0] = {}
						end
						for path,_ in pairs(allPaths) do
							if allRobloxKeyframes[0][path] == nil then
								local actJoint = global.ParsePath(model, path)
								
								allRobloxKeyframes[0][path] = global.deepcopy(global.defaults.Keyframe)
								allRobloxKeyframes[0][path].weight = 1
								if actJoint and actJoint:FindFirstChild("DefaultC1") then
									allRobloxKeyframes[0][path].cf = actJoint.DefaultC1.Value
								end
							end
						end
						
						local kfOrder = {}
							for i,v in pairs(allRobloxKeyframes) do
								table.insert(kfOrder, i)
							end
						table.sort(kfOrder, function(a, b) return a < b end)
						
						local needsLerp = {}

						for index, robloxKeyframePos in pairs(kfOrder) do
							local robloxKeyframe = allRobloxKeyframes[robloxKeyframePos]

							local actKeyframe = Instance.new("Keyframe")
								if allLabels["lbl"..tostring(robloxKeyframePos)] then
									actKeyframe.Name = allLabels["lbl"..tostring(robloxKeyframePos)]
									usedLabels["lbl"..tostring(robloxKeyframePos)] = true
								end
							actKeyframe.Time = robloxKeyframePos/input.info.fps

							for jointPath, poseData in pairs(robloxKeyframe) do
								local actJoint = global.ParsePath(model, jointPath)

								if actJoint and actJoint.Part0 and actJoint.Part0.Name then
									local parentPose
									if actKeyframe:FindFirstChild(actJoint.Part0.Name) then
										parentPose = actKeyframe[actJoint.Part0.Name]
									else
										parentPose = Instance.new("Pose")
										parentPose.Name = actJoint.Part0.Name
										parentPose.Weight = 0
									end
									
									local newPose = Instance.new("Pose")
									newPose.Name = actJoint.Part1.Name
									newPose.Weight = poseData.weight
									newPose.CFrame = poseData.cf:toObjectSpace(actJoint.DefaultC1.Value)
									newPose.Parent = parentPose
									
									local nextPose = nil
									local nextKfPos = nil
									for i = index + 1, #kfOrder do
										if allRobloxKeyframes[kfOrder[i]][jointPath] then
											nextPose = allRobloxKeyframes[kfOrder[i]][jointPath]
											nextKfPos = kfOrder[i]
											break
										end
									end								
									
									if nextPose then
										if global.EaseStyle[nextPose.easeSty] and global.EaseStyle[nextPose.easeSty].rblxEnum and (global.EaseStyle[nextPose.easeSty].custom == nil or global.EaseStyle[nextPose.easeSty].custom[nextPose.easeDir] == nil) then
											newPose.EasingStyle = nextPose.easeSty
											if global.EaseStyle[nextPose.easeSty].correction and global.EaseStyle[nextPose.easeSty].correction[nextPose.easeDir] then
												newPose.EasingDirection = global.EaseStyle[nextPose.easeSty].correction[nextPose.easeDir]
											else
												newPose.EasingDirection = nextPose.easeDir
											end
										elseif global.EaseStyle[nextPose.easeSty] then
											newPose.EasingStyle = Enum.PoseEasingStyle.Linear
											newPose.EasingDirection = Enum.PoseEasingDirection.In
											
											table.insert(needsLerp, {
																		joint = actJoint,
																		partNames = {actJoint.Part0.Name, actJoint.Part1.Name},
																		poseWeight = nextPose.weight,
																		bounds = {kfOrder[index], nextKfPos, nextKfPos - kfOrder[index]},
																		cf = {poseData.cf, nextPose.cf},
																		ease = {nextPose.easeSty, nextPose.easeDir}
																	}
											)
											
											local strVal = Instance.new("StringValue")
											strVal.Name = "xSIXxCustomStyle"
											strVal.Value = nextPose.easeSty
											strVal.Parent = newPose
											strVal = Instance.new("StringValue")
											strVal.Name = "xSIXxCustomDir"
											strVal.Value = nextPose.easeDir
											strVal.Parent = newPose
											
										else
											newPose.EasingStyle = Enum.PoseEasingStyle.Linear
											newPose.EasingDirection = Enum.PoseEasingDirection.In
										end
									end
									parentPose.Parent = actKeyframe	
								end
												
							end
							robloxKeyframe.actObj = actKeyframe	
							
							output:AddKeyframe(actKeyframe)
						end
						
						for _,data in pairs(needsLerp) do

							for pos = data.bounds[1] + 1, data.bounds[2] - 1, 1 do	
								
								local newKf
								
								if allRobloxKeyframes[pos] then
									newKf = allRobloxKeyframes[pos].actObj
								else
									newKf = Instance.new("Keyframe")
									newKf.Time = pos/input.info.fps
									Instance.new("IntValue", newKf).Name = "Null"
									newKf.Parent = output
									
									allRobloxKeyframes[pos] = {actObj = newKf}
									
									if allLabels["lbl"..tostring(pos)] then
										newKf.Name = allLabels["lbl"..tostring(pos)]
										usedLabels["lbl"..tostring(pos)] = true
									end
								end
								
								local base = data.joint.DefaultC1.Value
								local weight = global.EaseStyle[data.ease[1]].func[data.ease[2]]((pos - data.bounds[1])/data.bounds[3])
								local lastCFrame = data.cf[1] * base:inverse()
								local nextCFrame = data.cf[2] * base:inverse()
								
								local parentPose
								if newKf:FindFirstChild(data.partNames[1]) then
									parentPose = newKf[data.partNames[1]]
								else
									parentPose = Instance.new("Pose")
									parentPose.Name = data.partNames[1]
									parentPose.Weight = 0
									Instance.new("IntValue", parentPose).Name = "Null"
								end
								
								local newPose = Instance.new("Pose")
								newPose.Name = data.partNames[2]
								newPose.Weight = data.poseWeight
								newPose.CFrame = (lastCFrame:inverse():lerp(nextCFrame:inverse(), weight):inverse() * base):toObjectSpace(base)
								newPose.Parent = parentPose
								Instance.new("IntValue", newPose).Name = "Null"
								
								parentPose.Parent = newKf
								
							end						
							
						end
						
						for i,v in pairs(allLabels) do
							if not usedLabels[i] then
								local actKeyframe = Instance.new("Keyframe")
								actKeyframe.Name = v
								actKeyframe.Time = tonumber(string.sub(i, 4))/input.info.fps
								output:AddKeyframe(actKeyframe)
							end
						end

					table.insert(finalTbl, output)
				end
			end
			return finalTbl
		end
	end
	
	module.ConvertMASFile = function(file, rig)
		return Convert(Convert(file, "folder", "raw", rig), "raw", "roblox", rig)
	end	
end

return module

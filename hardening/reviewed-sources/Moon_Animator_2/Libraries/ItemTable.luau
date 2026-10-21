local _g = _G.MoonGlobal
local ItemTable = {}; local StudioService = game:GetService("StudioService")


------------------------------------------------------------
do
	local icon_replace = {
		Light = "PointLight",
		Rig = "Bone",
		BasePart = "Part",
	}
	ItemTable.SetIcon = function(label, class)
		if icon_replace[class] then class = icon_replace[class] end
		local image
		pcall(function()
			image = StudioService:GetClassIcon(class)
		end)
		if image then
			for prop, val in pairs(image) do
				label[prop] = val
			end
		end
	end 
	
	ItemTable.GetProperties = function(Type)
		local PropertiesTable = ItemTable.Items[Type]
		if PropertiesTable == nil then return {}, false end
		local PropList = {}
		for i = 1, #PropertiesTable, 1 do
			local PropertyData = PropertiesTable[i]
			table.insert(PropList, {Label = PropertyData[1], Checked = (i == 1 or PropertyData.def)})
		end
		return PropList
	end

	ItemTable.GetItemType = function(Item)
		local ret = Item.ClassName
		if Item:IsA("BasePart") then
			if Item.ClassName == "Terrain" then
				ret = Item.ClassName
			else
				ret = "BasePart"
			end
		elseif Item.ClassName == "Model" and _g.CheckIfRig(Item) then
			ret = "Rig"
		end
		return ret
	end
end
------------------------------------------------------------
do
	ItemTable.TweenFunctions = {}

	ItemTable.TweenFunctions.Discrete = function(orig, dest, per, default)
		if per == 1 then
			return dest
		else
			return orig
		end
	end

	ItemTable.TweenFunctions.Number = function(orig, dest, per, default)
		return orig - (orig - dest) * per
	end

	ItemTable.TweenFunctions.Lerp = function(orig, dest, per, default)
		return orig:lerp(dest, per)
	end
	
	ItemTable.TweenFunctions.ColorSeqLerp = function(orig, dest, per, default)
		orig = orig.Keypoints[1].Value
		dest = dest.Keypoints[1].Value
		return ColorSequence.new(orig:lerp(dest, per))
	end
	
	ItemTable.TweenFunctions.NumberSeqLerp = function(orig, dest, per, default)
		orig = orig.Keypoints[1].Value
		dest = dest.Keypoints[1].Value
		return NumberSequence.new(orig - (orig - dest) * per)
	end
	
	ItemTable.TweenFunctions.NumberRangeLerp = function(orig, dest, per, default)
		orig = orig.Min
		dest = dest.Min
		local res = orig - (orig - dest) * per
		return NumberRange.new(res, res)
	end

	ItemTable.TweenFunctions.MotorLerp = function(orig, dest, per, default)
		return ((orig:toObjectSpace(default)):lerp(dest:toObjectSpace(default), per) * default:Inverse()):Inverse()
	end
end
------------------------------------------------------------
do
	ItemTable.PropertyTypes = {
		["number"] = ItemTable.TweenFunctions.Number,

		["string"] 	 = ItemTable.TweenFunctions.Discrete,
		["Instance"] = ItemTable.TweenFunctions.Discrete,
		["boolean"]  = ItemTable.TweenFunctions.Discrete,
		["EnumItem"] = ItemTable.TweenFunctions.Discrete,

		["CFrame"] 	= ItemTable.TweenFunctions.Lerp,
		["Color3"]  = ItemTable.TweenFunctions.Lerp,
		["Vector2"] = ItemTable.TweenFunctions.Lerp,
		["Vector3"] = ItemTable.TweenFunctions.Lerp,
		
		["ColorSequence"] = ItemTable.TweenFunctions.ColorSeqLerp,
		["NumberSequence"] = ItemTable.TweenFunctions.NumberSeqLerp,
		["NumberRange"] = ItemTable.TweenFunctions.NumberRangeLerp,
	}

	ItemTable.PropertyTypeHolders = {
		["number"] = Instance.new("NumberValue"),

		["string"] 	 = Instance.new("StringValue"),
		["Instance"] = Instance.new("ObjectValue"),
		["boolean"]  = Instance.new("BoolValue"),
		["EnumItem"] = Instance.new("StringValue"),

		["CFrame"] 	= Instance.new("CFrameValue"),
		["Color3"]  = Instance.new("Color3Value"),
		["Vector2"] = Instance.new("Vector3Value"),
		["Vector3"] = Instance.new("Vector3Value"),
		
		["ColorSequence"]  = Instance.new("Color3Value"),
		["NumberSequence"]  = Instance.new("NumberValue"),
		["NumberRange"]  = Instance.new("NumberValue"),
	}

	function ItemTable.StoreValue(name, value, parent)
		local get_type = typeof(value)
		local val_holder = ItemTable.PropertyTypeHolders[get_type]
		assert(val_holder ~= nil, "Cannot store a '"..typeof(value).."' value.")

		local stored_value = val_holder:Clone()
		stored_value.Name = name
		if get_type == "ColorSequence" or get_type == "NumberSequence" then
			stored_value.Value = value.Keypoints[1].Value
			local ind = Instance.new("IntValue", stored_value); ind.Name = get_type
		elseif get_type == "NumberRange" then
			stored_value.Value = value.Min
			local ind = Instance.new("IntValue", stored_value); ind.Name = get_type
		elseif get_type == "EnumItem" then
			stored_value.Value = value.Name
			local ind = Instance.new("StringValue", stored_value); ind.Value = tostring(value.EnumType); ind.Name = get_type
		elseif get_type == "Vector2" then
			stored_value.Value = Vector3.new(value.X, value.Y, 0)
			local ind = Instance.new("IntValue", stored_value); ind.Name = get_type
		else
			stored_value.Value = value
		end
		stored_value.Parent = parent

		return stored_value
	end
	
	function ItemTable.GetValue(value)
		if value:FindFirstChild("ColorSequence") then
			return ColorSequence.new(value.Value)
		elseif value:FindFirstChild("NumberSequence") then
			return NumberSequence.new(value.Value)
		elseif value:FindFirstChild("NumberRange") then
			return NumberRange.new(value.Value, value.Value)
		elseif value:FindFirstChild("EnumItem") then
			return Enum[value.EnumItem.Value][value.Value]
		elseif value:FindFirstChild("Vector2") then
			return Vector2.new(value.Value.X, value.Value.Y)
		else
			return value.Value
		end
	end
end
------------------------------------------------------------
do
	ItemTable.Items = {
		["Workspace"] = {
			{"GlobalWind", "Vector3"},
			{"AirDensity", "number"},
			{"Gravity", "number"},
		},
		
		Terrain = {
			{"WaterColor", "Color3", def = true},
			{"WaterTransparency", "number", Inc = 0.1, def = true},
			{"WaterReflectance", "number", Inc = 0.1},
			{"WaterWaveSize", "number", Inc = 0.1},
			{"WaterWaveSpeed", "number"},
			{"MC_Asphalt", "Color3"},
			{"MC_Basalt", "Color3"},
			{"MC_Brick", "Color3"},
			{"MC_Cobblestone", "Color3"},
			{"MC_Concrete", "Color3"},
			{"MC_CrackedLava", "Color3"},
			{"MC_Glacier", "Color3"},
			{"MC_Grass", "Color3"},
			{"MC_Ground", "Color3"},
			{"MC_Ice", "Color3"},
			{"MC_LeafyGrass", "Color3"},
			{"MC_Limestone", "Color3"},
			{"MC_Mud", "Color3"},
			{"MC_Pavement", "Color3"},
			{"MC_Rock", "Color3"},
			{"MC_Salt", "Color3"},
			{"MC_Sand", "Color3"},
			{"MC_Sandstone", "Color3"},
			{"MC_Slate", "Color3"},
			{"MC_Snow", "Color3"},
			{"MC_WoodPlanks", "Color3"},
		},
		
		Camera = {
			{"FieldOfView",  "number", def = true},
			{"CFrame",		 "CFrame", def = true},
			{"AttachToPart", "Instance", Holder = true},
			{"LookAtPart", 	 "Instance", Holder = true},
		},

		BlockMesh = {
			{"Scale",	 	"Vector3", def = true},
			{"Offset", 		"Vector3", def = true},
			{"VertexColor", "Vector3"},
		},

		SpecialMesh = {
			{"Scale",	 	"Vector3", def = true},
			{"Offset", 		"Vector3", def = true},
			{"VertexColor", "Vector3"},
			{"MeshType", 	"EnumItem"},
			{"MeshId", 		"string"},
			{"TextureId", 	"string"},
		},
		
		Humanoid = {
			{"PlayAnimation", "Instance", def = true},
			{"MoveTo", "Vector3", def = true},
			{"Jump", "boolean", def = true},
			{"EquipTool", "Instance"},
			{"Sit", "boolean"},
			{"UnequipTools", "boolean"},
			{"AddAccessory", "Instance"},
			{"RemoveAccessories", "boolean"},
			{"Health", "number"},
			{"MaxHealth", "number"},
			{"HipHeight", "number"},
			{"MaxSlopeAngle", "number"},
			{"WalkSpeed", "number"},
			{"AutoRotate", "boolean"},
			{"PlatformStand", "boolean"},
			{"Move", "Vector3"},
			{"WalkToPart", "Instance"},
			{"TakeDamage", "number"},
			{"PlayEmote", "string"},
			{"ChangeState", "EnumItem", SpecialEnum = "HumanoidStateType"},
			{"AutomaticScalingEnabled", "boolean"},
			{"AutoJumpEnabled", "boolean"},
			{"JumpPower", "number"},
			{"UseJumpPower", "boolean"},
			{"CameraOffset", "Vector3"},
			{"DisplayDistanceType", "EnumItem", SpecialEnum = "HumanoidDisplayDistanceType"},
			{"DisplayName", "string"},
			{"HealthDisplayDistance", "number"},
			{"HealthDisplayType", "EnumItem", SpecialEnum = "HumanoidHealthDisplayType"},
			{"NameDisplayDistance", "number"},
			{"NameOcclusion", "EnumItem"},
		},
		
		FaceControls = {
			{"ChinRaiser", "number", Inc = 0.1},
			{"ChinRaiserUpperLip", "number", Inc = 0.1},
			{"Corrugator", "number", Inc = 0.1},
			{"EyesLookDown", "number", Inc = 0.1},
			{"EyesLookLeft", "number", Inc = 0.1},
			{"EyesLookRight", "number", Inc = 0.1},
			{"EyesLookUp", "number", Inc = 0.1},
			{"FlatPucker", "number", Inc = 0.1},
			{"Funneler", "number", Inc = 0.1},
			{"JawDrop", "number", Inc = 0.1},
			{"JawLeft", "number", Inc = 0.1},
			{"JawRight", "number", Inc = 0.1},
			{"LeftBrowLowerer", "number", Inc = 0.1},
			{"LeftCheekPuff", "number", Inc = 0.1},
			{"LeftCheekRaiser", "number", Inc = 0.1},
			{"LeftDimpler", "number", Inc = 0.1},
			{"LeftEyeClosed", "number", Inc = 0.1},
			{"LeftEyeUpperLidRaiser", "number", Inc = 0.1},
			{"LeftInnerBrowRaiser", "number", Inc = 0.1},
			{"LeftLipCornerDown", "number", Inc = 0.1},
			{"LeftLipCornerPuller", "number", Inc = 0.1},
			{"LeftLipStretcher", "number", Inc = 0.1},
			{"LeftLowerLipDepressor", "number", Inc = 0.1},
			{"LeftNoseWrinkler", "number", Inc = 0.1},
			{"LeftOuterBrowRaiser", "number", Inc = 0.1},
			{"LeftUpperLipRaiser", "number", Inc = 0.1},
			{"LipPresser", "number", Inc = 0.1},
			{"LipsTogether", "number", Inc = 0.1},
			{"LowerLipSuck", "number", Inc = 0.1},
			{"MouthLeft", "number", Inc = 0.1},
			{"MouthRight", "number", Inc = 0.1},
			{"Pucker", "number", Inc = 0.1},
			{"RightBrowLowerer", "number", Inc = 0.1},
			{"RightCheekPuff", "number", Inc = 0.1},
			{"RightCheekRaiser", "number", Inc = 0.1},
			{"RightDimpler", "number", Inc = 0.1},
			{"RightEyeClosed", "number", Inc = 0.1},
			{"RightEyeUpperLidRaiser", "number", Inc = 0.1},
			{"RightInnerBrowRaiser", "number", Inc = 0.1},
			{"RightLipCornerDown", "number", Inc = 0.1},
			{"RightLipCornerPuller", "number", Inc = 0.1},
			{"RightLipStretcher", "number", Inc = 0.1},
			{"RightLowerLipDepressor", "number", Inc = 0.1},
			{"RightNoseWrinkler", "number", Inc = 0.1},
			{"RightOuterBrowRaiser", "number", Inc = 0.1},
			{"RightUpperLipRaiser", "number", Inc = 0.1},
			{"TongueDown", "number", Inc = 0.1},
			{"TongueOut", "number", Inc = 0.1},
			{"TongueUp", "number", Inc = 0.1},
			{"UpperLipSuck", "number", Inc = 0.1},
		},
		
		Sound = {
			{"PlayOnce", "boolean", def = true},
			{"Play", "boolean"},
			{"Stop", "boolean"},
			{"SetTime", "number", Inc = 0.1},
			{"Pause", "boolean"},
			{"Resume", "boolean"},
			{"Volume", "number", Inc = 0.1},
			{"PlaybackSpeed", "number", Inc = 0.1},
			{"SoundId", "string"},
			{"Looped", "boolean"},
			{"RollOffMaxDistance", "number"},
			{"RollOffMinDistance", "number"},
			{"RollOffMode", "EnumItem"},
			{"SoundGroup", "Instance"},
			{"PlayOnRemove", "boolean"},
		},
		
		SoundGroup = {
			{"Volume", "number", Inc = 0.1},
		},
		
		SoundService = {
			{"AmbientReverb", "EnumItem", SpecialEnum = "ReverbType"},
			{"DistanceFactor", "number"},
			{"DopplerScale", "number", Inc = 0.1},
			{"RolloffScale", "number", Inc = 0.1},
		},

		Script = {
			{"Disabled", "boolean"},
		},

		LocalScript = {
			{"Disabled", "boolean"},
		},

		Decal = {
			{"Transparency", "number", Inc = 0.05},
			{"Color3",		 "Color3"},
			{"Texture",		 "string"},
			{"Face", 		 "EnumItem", SpecialEnum = "NormalId"},
		},

		Texture = {
			"Decal",
			{"OffsetStudsU",  "number", Inc = 0.5},
			{"OffsetStudsV",  "number", Inc = 0.5},
			{"StudsPerTileU", "number", Inc = 0.5},
			{"StudsPerTileV", "number", Inc = 0.5},
		},

		BasePart = {
			{"CFrame",		 "CFrame"},
			{"Size",		 "Vector3"},
			{"ApplyTexture", "string"},
			{"ApplyMesh", 	 "Instance"},
			{"Color",		 "Color3"},
			{"Transparency", "number",  Inc = 0.05},
			{"Reflectance",  "number",  Inc = 0.05},
			{"Material",	 "EnumItem"},
			{"Anchored",	 "boolean"},
			{"CastShadow",	 "boolean"},
		},

		Model = {
			{"CFrame",	     "CFrame", Holder = true},
			{"Scale", 		 "number", 1, Inc = 0.05, Holder = true},
			{"Transparency", "number", 0, Inc = 0.05, Holder = true},
			{"Color",		 "Color3"},
			{"Reflectance",  "number", 0, Inc = 0.05, Holder = true},
		},

		Rig = {
			{"Rig"},
			"Model",
		},
		
		Shirt = {
			{"Color3", "Color3"},
			{"ShirtTemplate", "string"},
		},
		
		Pants = {
			{"Color3", "Color3"},
			{"PantsTemplate", "string"},
		},
		
		Frame = {
			{"BackgroundTransparency", "number", Inc = 0.05, def = true},
			{"BackgroundColor3", "Color3", def = true},
			{"Visible", "boolean"},
			{"Rotation", "number"},
			{"BorderColor3", "Color3"},
			{"BorderSizePixel", "number"},
			{"AnchorPoint", "Vector2"},
			{"ClipsDescendants", "boolean"},
			{"LayoutOrder", "number"},
		},

		TextLabel = {
			{"Text",				   "string", def = true},
			{"MaxVisibleGraphemes",	   "number", def = true},
			{"TextColor3",			   "Color3"},
			{"TextStrokeColor3",	   "Color3"},
			{"Font",				   "EnumItem"},
			{"TextSize",			   "number"},
			{"TextTransparency",	   "number", Inc = 0.05},
			{"TextStrokeTransparency", "number", Inc = 0.05},
			{"TextXAlignment",		   "EnumItem"},
			{"TextYAlignment", 		   "EnumItem"},
			"Frame",
		},

		ImageLabel = {
			{"ImageTransparency", "number", Inc = 0.05, def = true},
			{"ImageColor3",		  "Color3", def = true},
			"Frame",
		},

		NumberValue = {
			{"Value", "number"},
		},

		StringValue = {
			{"Value", "string"},
		},

		ObjectValue = {
			{"Value", "Instance"},
		},

		BoolValue = {
			{"Value", "boolean"},
		},

		Vector3Value = {
			{"Value", "Vector3"},
		},

		Lighting = {
			{"ClockTime",				 "number", Inc = 0.25, def = true},
			{"Brightness",				 "number", Inc = 0.05, def = true},
			{"Ambient",					 "Color3", def = true},
			{"OutdoorAmbient",			 "Color3"},
			{"ExposureCompensation",	 "number", Inc = 0.05},
			{"FogEnd",				 	 "number", Inc = 10},
			{"FogStart",				 "number", Inc = 10},
			{"FogColor",				 "Color3"},
			{"GeographicLatitude",		 "number", Inc = 0.5},
			{"ColorShift_Bottom",		 "Color3"},
			{"ColorShift_Top",			 "Color3"},
			{"EnvironmentDiffuseScale",  "number", Inc = 0.05},
			{"EnvironmentSpecularScale", "number", Inc = 0.05},
			{"ShadowSoftness", 			 "number", Inc = 0.05},
			{"GlobalShadows",			 "boolean"},
		},

		Sky = {
			{"MoonAngularSize",		 "number"},
			{"SunAngularSize",		 "number"},
			{"StarCount",			 "number"},
			{"CelestialBodiesShown", "boolean"},
			{"SunTextureId",		 "string"},
			{"MoonTextureId",		 "string"},
			{"SkyboxBk",			 "string"},
			{"SkyboxDn",			 "string"},
			{"SkyboxFt",			 "string"},
			{"SkyboxLf",			 "string"},
			{"SkyboxRt",			 "string"},
			{"SkyboxUp",			 "string"},
		},

		Atmosphere = {
			{"Color", 	"Color3", def = true},
			{"Density", "number", Inc = 0.05, def = true},
			{"Offset", 	"number", Inc = 0.05},
			{"Haze", 	"number", Inc = 0.1},
			{"Decay", 	"Color3"},
			{"Glare", 	"number", Inc = 0.1},
		},
		
		Clouds = {
			{"Cover", 	"number", Inc = 0.05, def = true},
			{"Density", "number", Inc = 0.05, def = true},
			{"Color", 	"Color3"},
			{"Enabled", "boolean"},
		},

		PostEffect = {
			{"Enabled", "boolean", def = true},
		},

		DepthOfFieldEffect = {
			"PostEffect",
			{"FocusDistance", "number", Inc = 0.1, def = true},
			{"InFocusRadius", "number", Inc = 0.1, def = true},
			{"FarIntensity",  "number", Inc = 0.05},
			{"NearIntensity", "number", Inc = 0.05},
		},

		BloomEffect = {
			"PostEffect",
			{"Intensity", "number", Inc = 0.05, def = true},
			{"Size", 	  "number", def = true},
			{"Threshold", "number"},
		},

		BlurEffect = {
			"PostEffect",
			{"Size", "number", def = true},
		},

		ColorCorrectionEffect = {
			"PostEffect",
			{"TintColor",  "Color3", def = true},
			{"Brightness", "number", Inc = 0.05, def = true},
			{"Contrast",   "number", Inc = 0.05, def = true},
			{"Saturation", "number", Inc = 0.05, def = true},
		},

		SunRaysEffect = {
			"PostEffect",
			{"Intensity", "number", Inc = 0.05, def = true},
			{"Spread",	  "number", Inc = 0.05, def = true},
		},

		Light = {
			{"Enabled",	   "boolean", def = true},
			{"Brightness", "number", Inc = 0.5, def = true},
			{"Color", 	   "Color3", def = true},
			{"Shadows",	   "boolean"},
		},

		PointLight = {
			"Light",
			{"Range", "number", Inc = 0.5},
		},

		SpotLight = {
			"Light",
			{"Range", "number", Inc = 0.5},
			{"Angle", "number"},
			{"Face",  "EnumItem", SpecialEnum = "NormalId"},
		},

		SurfaceLight = {
			"Light",
			{"Range", "number", Inc = 0.5},
			{"Angle", "number"},
			{"Face",  "EnumItem", SpecialEnum = "NormalId"},
		},
		
		Motor6D = {
			{"Enabled", "boolean"},
		},

		Weld = {
			{"Enabled", "boolean"},
		},

		Attachment = {
			{"CFrame", "CFrame"},
		},
		
		IKControl = {
			{"ChainRoot",	"Instance"},
			{"Enabled", "boolean"},
			{"EndEffector", "Instance"},
			{"EndEffectorOffset", "CFrame"},
			{"Offset",	"CFrame"},
			{"Pole", "Instance"},
			{"Priority", "number"},
			{"SmoothTime", "number"},
			{"Target",	"Instance"},
			{"Type",	"EnumItem", SpecialEnum = "IKControlType"},
			{"Weight",	"number"},
		},

		Constraint = {
			{"Enabled",		"boolean"},
			{"Attachment0", "Instance"},
			{"Attachment1", "Instance"},
			{"Visible",		"boolean"},
		},
		
		LinearVelocity = {
			"Constraint",
			{"ForceLimitMode", "EnumItem"},
			{"ForceLimitsEnabled", "boolean"},
			{"LineDirection", "Vector3"},
			{"LineVelocity", "number"},
			{"MaxAxesForce",	"Vector3"},
			{"MaxForce", "number"},
			{"MaxPlanarAxesForce", "Vector2"},
			{"PlaneVelocity", "Vector2"},
			{"PrimaryTangentAxis",	"Vector3"},
			{"RelativeTo",	"EnumItem", SpecialEnum = "ActuatorRelativeTo"},
			{"SecondaryTangentAxis", "Vector3"},
			{"VectorVelocity", "Vector3"},
			{"VelocityConstraintMode",	"EnumItem"},
		},

		AlignOrientation = {
			"Constraint",
			{"PrimaryAxisOnly",		  "boolean"},
			{"ReactionTorqueEnabled", "boolean"},
			{"RigidityEnabled",		  "boolean"},
			{"AlignType",			  "EnumItem"},
			{"MaxAngularVelocity",	  "number"},
			{"MaxTorque",			  "number"},
			{"Responsiveness", 		  "number"},
		},

		AlignPosition = {
			"Constraint",
			{"ApplyAtCenterOfMass",  "boolean"},
			{"ReactionForceEnabled", "boolean"},
			{"RigidityEnabled",		 "boolean"},
			{"MaxForce",		     "number"},
			{"MaxVelocity", 		 "number"},
			{"Responsiveness",		 "number"},
		},

		AngularVelocity = {
			"Constraint",
			{"ReactionTorqueEnabled", "boolean"},
			{"RelativeTo",			  "EnumItem", SpecialEnum = "ActuatorRelativeTo"},
			{"MaxTorque",			  "number"},	
			{"AngularVelocity",		  "Vector3"},
		},

		BallSocketConstraint = {
			"Constraint",
			{"LimitsEnabled",	   "boolean"},
			{"TwistLimitsEnabled", "boolean"},
			{"MaxFrictionTorque",  "number"},
			{"Radius",			   "number"},
			{"Restitution",		   "number"},
			{"TwistLowerAngle",	   "number"},
			{"TwistUpperAngle",	   "number"},
			{"UpperAngle", 		   "number"},
		},

		HingeConstraint = {
			"Constraint",
			{"LimitsEnabled", 		 "boolean"},
			{"ActuatorType", 		 "EnumItem"},
			{"LowerAngle", 			 "number"},
			{"MotorMaxAcceleration", "number"},
			{"MotorMaxTorque",		 "number"},
			{"Radius",				 "number"},
			{"Restitution",			 "number"},
			{"ServoMaxTorque",		 "number"},
			{"TargetAngle",			 "number"},
			{"UpperAngle",			 "number"},
			{"AngularSpeed",		 "number"},
			{"AngularVelocity",		 "number"},
			{"CurrentAngle",		 "number"},
		},

		LineForce = {
			"Constraint",
			{"ApplyAtCenterOfMass",  "boolean"},
			{"InverseSquareLaw",	 "boolean"},
			{"ReactionForceEnabled", "boolean"},
			{"Magnitude", 			 "number"},
			{"MaxForce", 			 "number"},
		},

		RodConstraint = {
			"Constraint",
			{"CurrentDistance", "number"},
			{"Length",		    "number"},
			{"Thickness", 		"number"},
		},

		RopeConstraint = {
			"Constraint",
			{"CurrentDistance", "number"},
			{"Length", 			"number"},
			{"Restitution", 	"number"},
			{"Thickness", 		"number"},
		},

		SlidingBallConstraint = {
			"Constraint",
			{"LimitsEnabled", 		 "boolean"},
			{"ActuatorType", 		 "EnumItem"},
			{"CurrentPosition", 	 "number"},
			{"LowerLimit", 			 "number"},
			{"MotorMaxAcceleration", "number"},
			{"MotorMaxForce", 		 "number"},
			{"Restitution", 		 "number"},
			{"ServoMaxForce", 		 "number"},
			{"Size", 				 "number"},
			{"Speed", 				 "number"},
			{"TargetPosition",		 "number"},
			{"UpperLimit", 			 "number"},
			{"Velocity", 			 "number"},
		},

		SpringConstraint = {
			"Constraint",
			{"LimitsEnabled", "boolean"},
			{"Coils", 		  "number"},
			{"CurrentLength", "number"},
			{"Damping", 	  "number"},
			{"FreeLength",	  "number"},
			{"MaxForce", 	  "number"},
			{"MaxLength", 	  "number"},
			{"MinLength", 	  "number"},
			{"Radius", 		  "number"},
			{"Stiffness",	  "number"},
			{"Thickness", 	  "number"},
		},

		Torque = {
			"Constraint",
			{"RelativeTo", "EnumItem", SpecialEnum = "ActuatorRelativeTo"},
			{"Torque",	   "Vector3"},
		},

		VectorForce = {
			"Constraint",
			{"ApplyAtCenterOfMass", "boolean"},
			{"RelativeTo",			"EnumItem", SpecialEnum = "ActuatorRelativeTo"},
			{"Force", 				"Vector3"},
		},

		WeldConstraint = {
			"Constraint",
			{"Enabled", "boolean"},
			{"Part0",	"Instance"},
			{"Part1",	"Instance"},
		},
		
		Highlight = {
			{"Enabled", 			"boolean", def = true},
			{"FillColor", 			"Color3", def = true},
			{"FillTransparency", 	"number", Inc = 0.05, def = true},
			{"OutlineColor", 		"Color3"},
			{"OutlineTransparency", "number", Inc = 0.05},
			{"Adornee", 			"Instance"},
			{"DepthMode", 			"EnumItem", SpecialEnum = "HighlightDepthMode"},
		},

		ParticleEmitter = {
			{"Emit", "number", def = true},
			{"Enabled", "boolean", def = true},
			{"Size", "NumberSequence", def = true},
			{"Color", "ColorSequence", def = true},
			{"Transparency", "NumberSequence", def = true},
			{"Clear", "boolean"},
			{"Speed", "NumberRange"},
			{"Squash", "NumberSequence"},
			{"Shape",   	 "EnumItem", SpecialEnum = "ParticleEmitterShape"},
			{"ShapeInOut",   "EnumItem", SpecialEnum = "ParticleEmitterShapeInOut"},
			{"ShapeStyle",   "EnumItem", SpecialEnum = "ParticleEmitterShapeStyle"},
			{"TimeScale", 			"number", Inc = 0.1},
			{"Rate",			    "number"},
			{"Drag", 				"number", Inc = 0.1},
			{"Lifetime", "NumberRange"},
			{"Rotation", "NumberRange"},
			{"RotSpeed", "NumberRange"},
			{"LightEmission", 		"number", Inc = 0.05},
			{"LightInfluence", 		"number", Inc = 0.05},
			{"Texture",			    "string"},
			{"EmissionDirection",   "EnumItem", SpecialEnum = "NormalId"},
			{"SpreadAngle",		    "Vector2"},
			{"Acceleration", 	    "Vector3"},
			{"VelocityInheritance", "number", Inc = 0.05},
			{"ZOffset", 			"number"},
			{"LockedToPart", 		"boolean"},
		},

		Trail = {
			{"Enabled",		   "boolean", def = true},
			{"Color", "ColorSequence", def = true},
			{"Transparency", "NumberSequence", def = true},
			{"WidthScale", "NumberSequence"},
			{"LightEmission",  "number", Inc = 0.05},
			{"LightInfluence", "number", Inc = 0.05},
			{"TextureLength",  "number"},
			{"Lifetime", 	   "number"},
			{"MaxLength",	   "number"},
			{"MinLength",	   "number"},
			{"Attachment0",	   "Instance"},
			{"Attachment1",    "Instance"},
			{"Texture",		   "string"},
			{"TextureMode",	   "EnumItem"},
			{"FaceCamera",	   "boolean"},
		},

		Beam = {
			{"Enabled", 	   "boolean", def = true},
			{"Color", "ColorSequence", def = true},
			{"Transparency", "NumberSequence", def = true},
			{"Width0", 		   "number", Inc = 0.5},
			{"Width1", 		   "number", Inc = 0.5},
			{"TextureSpeed",   "number", Inc = 0.5},
			{"TextureLength",  "number", Inc = 0.5},
			{"CurveSize0",	   "number", Inc = 0.5},
			{"CurveSize1",	   "number", Inc = 0.5},
			{"LightEmission",  "number", Inc = 0.05},
			{"LightInfluence", "number", Inc = 0.05},
			{"Segments",	   "number"},
			{"Attachment0",    "Instance"},
			{"Attachment1",    "Instance"},
			{"Texture", 	   "string"},
			{"TextureMode",    "EnumItem"},
			{"FaceCamera",	   "boolean"},
			{"ZOffset", 	   "number"},
		},

		Fire = {
			{"Enabled",		   "boolean", def = true},
			{"Color", 		   "Color3", def = true},
			{"SecondaryColor", "Color3", def = true},
			{"Size",		   "number", def = true},
			{"Heat",		   "number"},
		},

		ForceField = {
			{"Visible", "boolean"},
		},

		Sparkles = {
			{"Enabled",		 "boolean", def = true},
			{"SparkleColor", "Color3", def = true},
		},

		Smoke = {
			{"Enabled",		 "boolean", def = true},
			{"Color",		 "Color3", def = true},
			{"Size",		 "number", def = true},
			{"Opacity", 	 "number", Inc = 0.05, def = true},
			{"RiseVelocity", "number"},
		},
	}

	local again = true
	while again do
		again = false
		for item_type, PropertiesTable in pairs(ItemTable.Items) do
			local new_prop_table = {}
			for _, PropertyData in pairs(PropertiesTable) do
				if type(PropertyData) == "string" then
					again = true
					for _, inher in pairs(ItemTable.Items[PropertyData]) do
						table.insert(new_prop_table, inher)
					end
				else
					table.insert(new_prop_table, PropertyData)
				end
			end
			ItemTable.Items[item_type] = new_prop_table
		end
	end

	for item_type, PropertiesTable in pairs(ItemTable.Items) do
		local new_prop_table = {}
		for index, PropertyData in pairs(PropertiesTable) do
			PropertyData.index = index
			table.insert(new_prop_table, PropertyData)
			new_prop_table[PropertyData[1]] = PropertyData
		end
		ItemTable.Items[item_type] = new_prop_table
	end
end

return ItemTable

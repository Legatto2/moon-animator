local _g = _G.MoonGlobal; _g.req("Object")
local Ease = super:new()

local Pool = {}

function Ease:new(ease_type, params)
	local ctor = super:new(ease_type)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if ease_type then
		ctor.ease_type = ease_type 
		ctor.params = params
		ctor._func = nil
		ctor._poolcount = 0

		local ease_data = Ease.EASE_DATA[ease_type]
		if ease_data.Params == nil then
			ctor.params = nil
			ctor._func = _g.EasingFunctions[ease_type]
		elseif ease_data.Params.Direction then
			ctor._func = _g.EasingFunctions[ease_type..params.Direction]

			if ease_type == "Back" then
				if params.Overshoot == nil then params.Overshoot = Ease.PARAM_DATA.Overshoot.default end

				local ease_func = ctor._func
				ctor._func = function(val)
					return ease_func(val, params.Overshoot)
				end
			elseif ease_type == "Elastic" then
				if params.Amplitude == nil then params.Amplitude = Ease.PARAM_DATA.Amplitude.default end
				if params.Period == nil then params.Period = Ease.PARAM_DATA.Period.default end

				local ease_func = ctor._func
				ctor._func = function(val)
					return ease_func(val, params.Amplitude, params.Period)
				end
			end
		end

		for _, existing_ease in pairs(Pool) do
			if Ease.Equals(existing_ease, ctor) then
				Ease.Destroy(ctor)
				existing_ease._poolcount = existing_ease._poolcount + 1
				return existing_ease
			end
		end

		Pool[tostring(ctor)] = ctor
		ctor._poolcount = 1
	end

	return ctor
end

Ease.LINEAR = function()
	return Ease:new("Linear")
end

Ease.LINEAR_tbl = function()
	local ease = Ease.LINEAR()
	local tbl = ease:Tableize()
	ease:Destroy()
	return tbl
end

Ease.CONSTANT = function()
	return Ease:new("Constant")
end

Ease.DIR_PARAMS = {["Direction"] = true}
Ease.PARAM_DATA = {
	Overshoot = {
		name = "Overshoot",
		input_type = "number",
		default = 1.70158,
		inc = 0.1,
	},
	Amplitude = {
		name = "Amplitude",
		input_type = "number",
		default = 1,
		inc = 0.1,
	},
	Period = {
		name = "Period",
		input_type = "number",
		default = 0.3,
		frame_relative = true,
		inc = 0.01,
	},
}

Ease.EASE_DATA = {
	Linear = {
		Color = Color3.fromRGB(23, 101, 184),
	},
	Constant = {
		Color = Color3.fromRGB(117, 108, 60),
	},
	Sine = {
		Color = Color3.fromRGB(0, 215, 23), Params = Ease.DIR_PARAMS,
	},
	Quad = {
		Color = Color3.fromRGB(233, 24, 24), Params = Ease.DIR_PARAMS,
	},
	Cubic = {
		Color = Color3.fromRGB(184, 23, 133), Params = Ease.DIR_PARAMS,
	},
	Quart = {
		Color = Color3.fromRGB(253, 91, 3), Params = Ease.DIR_PARAMS,
	},
	Quint = {
		Color = Color3.fromRGB(254, 198, 6), Params = Ease.DIR_PARAMS,
	},
	Sextic = {
		Color = Color3.fromRGB(172, 141, 224), Params = Ease.DIR_PARAMS,
	},
	Expo = {
		Color = Color3.fromRGB(255, 127, 200), Params = Ease.DIR_PARAMS,
	},
	Circ = {
		Color = Color3.fromRGB(16, 210, 229), Params = Ease.DIR_PARAMS,
	},
	Back = {
		Color = Color3.fromRGB(189, 195, 199), Params = {["Direction"] = true, ["Overshoot"] = true},
	},
	Elastic = {
		Color = Color3.fromRGB(93, 184, 23), Params = {["Direction"] = true, ["Amplitude"] = true, ["Period"] = true},
	},
	Bounce = {
		Color = Color3.fromRGB(103, 23, 184), Params = Ease.DIR_PARAMS,
	},
}

Ease.EASE_LIST = {
	{"Linear", "Linear"},
	{"Constant", "None"},
	{"Sine", "Sine"},
	{"Back", "Back"},
	{"Quad", "Quad"},
	{"Cubic", "Cubic"},
	{"Quart", "Quart"},
	{"Quint", "Quint"},
	{"Sextic", "Sextic"},
	{"Expo", "Expo"},
	{"Circ", "Circ"},
	{"Bounce", "Bounce"},
	{"Elastic", "Elastic"},
}
Ease.DIR_LIST = {{"In", "In"}, {"Out", "Out"}, {"InOut", "InOut"}, {"OutIn", "OutIn"}}

function Ease.Detableize(ease_tbl)
	return Ease:new(ease_tbl.ease_type, ease_tbl.params)
end

function Ease.Deserialize(ease_folder)
	local ease_type = ease_folder.Type.Value
	local params
	
	if ease_folder:FindFirstChild("Params") then
		params = {}
		for _, val in pairs(ease_folder.Params:GetChildren()) do
			params[val.Name] = val.Value
		end
	end
	
	return Ease:new(ease_type, params)
end

function Ease:Destroy()
	self._poolcount = self._poolcount - 1

	if self._poolcount <= 0 then
		Pool[tostring(self)] = nil
		super.Destroy(self)
	end
end

function Ease:Tableize()
	return {_tblType = "Ease", ease_type = self.ease_type, params = self.params}
end

function Ease:Serialize()
	local ease_folder = Instance.new("Folder")
	ease_folder.Name = "Ease"

	_g.ItemTable.StoreValue("Type", self.ease_type, ease_folder)
	if self.params then
		local params_folder = Instance.new("Folder", ease_folder)
		params_folder.Name = "Params"

		for k, v in pairs(self.params) do
			if not Ease.PARAM_DATA[k] or v ~= Ease.PARAM_DATA[k].default then
				_g.ItemTable.StoreValue(k, v, params_folder)
			end
		end
	end
	
	return ease_folder
end

function Ease:Equals(other_ease)
	if self.ease_type ~= other_ease.ease_type then return false end

	if self.params then
		for k, v in pairs(self.params) do
			if other_ease.params[k] ~= v then
				return false
			end
		end
	end

	return true
end

return Ease

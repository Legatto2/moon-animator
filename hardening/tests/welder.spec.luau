-- Only the reviewed Welder module runs. Scene objects, UI, history, and selection
-- are explicit inert doubles; no complete plugin or embedded script is executed.
-- BASELINE_MODE_INSERTION_POINT
local passed = 0
local function test(name, callback)
	callback()
	passed += 1
	print("PASS " .. name)
end

local function fixture()
	local state = {newInstances = 0, clones = 0, parentChanges = 0, waypoints = {}, popups = {}, selection = {}}
	local instanceMethods = {}
	local create
	local instanceMeta = {
		__index = function(object, key)
			if key == "Parent" then return rawget(object, "_parent") end
			return instanceMethods[key]
		end,
		__newindex = function(object, key, value)
			if key ~= "Parent" then rawset(object, key, value) return end
			local oldParent = rawget(object, "_parent")
			if oldParent == value then return end
			state.parentChanges += 1
			if oldParent then
				for index, child in ipairs(oldParent._children) do
					if child == object then table.remove(oldParent._children, index) break end
				end
			end
			rawset(object, "_parent", value)
			if value then table.insert(value._children, object) end
		end,
	}
	function instanceMethods:IsA(class)
		return self.ClassName == class
			or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "MeshPart"))
			or (class == "JointInstance" and (self.ClassName == "Weld" or self.ClassName == "Motor6D"))
	end
	function instanceMethods:GetDescendants()
		local result = {}
		local function visit(object)
			for _, child in ipairs(object._children) do
				table.insert(result, child)
				visit(child)
			end
		end
		visit(self)
		return result
	end
	function instanceMethods:GetChildren() return table.clone(self._children) end
	function instanceMethods:IsDescendantOf(parent)
		local current = self.Parent
		while current do
			if current == parent then return true end
			current = current.Parent
		end
		return false
	end
	function instanceMethods:Clone()
		state.clones += 1
		local clone = create(self.ClassName, self.Name)
		for _, property in ipairs({"Size", "Position", "CFrame", "Transparency", "Anchored", "Locked", "CanCollide", "Massless"}) do
			clone[property] = self[property]
		end
		for _, child in ipairs(self._children) do child:Clone().Parent = clone end
		return clone
	end
	function instanceMethods:GetJoints() return table.clone(self._joints) end
	function instanceMethods:BreakJoints() self.breakCalls = (self.breakCalls or 0) + 1 end
	function instanceMethods:SetPrimaryPartCFrame(value) self.positionedAt = value end
	create = function(class, name, parent)
		local object = setmetatable({
			_instance = true, ClassName = class, Name = name or class, _children = {}, _joints = {},
			Size = {magnitude = 1}, Position = {label = name or class}, Transparency = 0,
			Anchored = false, Locked = true, CanCollide = true, Massless = false,
		}, instanceMeta)
		object.CFrame = {label = object.Name, ToObjectSpace = function(from, to)
			return {relativeFrom = from, relativeTo = to}
		end}
		object.Parent = parent
		return object
	end
	local workspace = create("Workspace", "Workspace")
	local Instance = {new = function(class, parent)
		state.newInstances += 1
		return create(class, class, parent)
	end}
	local CFrame = {new = function(position) return {position = position} end}
	local nativeType = type
	local function type(value)
		if nativeType(value) == "table" and value._instance then return "userdata" end
		return nativeType(value)
	end
	local function typeof(value)
		if nativeType(value) == "table" and value._instance then return "Instance" end
		return nativeType(value)
	end
	local function control()
		return {
			Set = function(self, value) self.Value = value end,
			SetActive = function(self, active) self.Active = active end,
		}
	end
	local elements = {}
	for _, name in ipairs({"Tabs", "model_Model", "model_BasePart", "model_WeldModel", "part_BasePart",
		"part_TargetPart", "part_Join", "part_JoinInPlace", "part_Animatable", "clean_TargetTool", "clean_Tool"}) do
		elements[name] = control()
	end
	local win = {g_e = elements, AddPaintedItem = function() end}
	local constructor = {new = function(_, element, default)
		element.Value = default
		return element
	end}
	local Tabs, ValueLabel, Button, Check = constructor, constructor, constructor, constructor
	local UI = {Tabs = {Cleaner = {Instr = {}}, Model = {Instr = {}}, Parts = {Instr = {}}}}
	local selectionService = {
		Get = function() return state.selection end,
		Set = function(_, value) state.selection = value end,
		SelectionChanged = {Connect = function() return {Disconnect = function() end} end},
	}
	local game = {GetService = function(_, name)
		assert(name == "Selection", "Unexpected service")
		return selectionService
	end}
	local _G = {MoonGlobal = {
		WindowData = {new = function() return {} end},
		Window = {new = function() return win end},
		chs = {SetWaypoint = function(_, label) table.insert(state.waypoints, label) end},
		Windows = {MsgBox = {Popup = function(owner, message)
			assert(owner == win)
			table.insert(state.popups, message)
		end}},
	}}
	local script = {Contents = {}, Name = "Welder"}
	local JoinParts
	local module = (function()
-- MODULE_SOURCE_INSERTION_POINT
	end)()
	local function resetCounts()
		state.newInstances, state.clones, state.parentChanges = 0, 0, 0
		state.waypoints, state.popups = {}, {}
	end
	return {state = state, create = create, world = workspace, controls = elements, module = module,
		resetCounts = resetCounts, clickClean = function() return elements.clean_Tool.OnClick() end}
end

local function assertNoSceneWork(fixture)
	local state = fixture.state
	assert(state.newInstances == 0 and state.clones == 0 and state.parentChanges == 0,
		"Invalid input created, cloned, or reparented scene objects")
	assert(#state.waypoints == 0, "Invalid input changed history")
	assert(#state.popups == 1 and state.popups[1].Title == "Cannot Clean Tool")
	assert(state.popups[1].Content:find("BasePart"), "Missing actionable error")
end

if BASELINE_REPRO then
	test("baseline empty tool reproduces nil BasePart error", function()
		local f = fixture()
		local target = f.create("Tool", "Empty", f.world)
		f.controls.clean_TargetTool:Set(target)
		f.resetCounts()
		local ok, message = pcall(f.clickClean)
		assert(not ok and tostring(message):find("nil"), "Baseline failure was not reproduced")
		assert(f.state.newInstances > 0, "Expected original allocation before failure")
		assert(target.Parent == f.world, "Baseline fixture unexpectedly removed target")
	end)
	print("Welder baseline: reproduced the empty-container failure with mocked Roblox APIs.")
	return
end

for _, class in ipairs({"Tool", "Model", "Folder"}) do
	test("empty " .. class .. " is rejected before scene or history changes", function()
		local f = fixture()
		local target = f.create(class, "Empty", f.world)
		f.state.selection = {target}
		f.module.RefreshSelection()
		assert(f.controls.clean_Tool.Active, "Fixture must follow the enabled baseline UI path")
		f.resetCounts()
		local ok, message = f.clickClean()
		assert(ok == false and type(message) == "string")
		assert(target.Parent == f.world)
		assertNoSceneWork(f)
	end)
end

test("container with only non-part descendants is rejected", function()
	local f = fixture()
	local target = f.create("Model", "Decorations", f.world)
	f.create("Folder", "Nested", target)
	f.create("ParticleEmitter", "Effect", target)
	f.controls.clean_TargetTool:Set(target)
	f.resetCounts()
	assert(f.clickClean() == false)
	assertNoSceneWork(f)
end)

test("a bad later target prevents cleaning an earlier valid tool", function()
	local f = fixture()
	local valid = f.create("Tool", "Valid", f.world)
	local handle = f.create("Part", "Handle", valid)
	local invalid = f.create("Folder", "Empty", f.world)
	f.controls.clean_TargetTool:Set({valid, invalid})
	f.resetCounts()
	assert(f.clickClean() == false)
	assert(valid.Parent == f.world and handle.Parent == valid and invalid.Parent == f.world)
	assertNoSceneWork(f)
end)

test("stale empty selection returns a useful error", function()
	local f = fixture()
	f.controls.clean_TargetTool:Set(nil)
	f.resetCounts()
	assert(f.clickClean() == false)
	assertNoSceneWork(f)
end)

test("normal tool cleaning preserves handle, decoration, and weld behavior", function()
	local f = fixture()
	local target = f.create("Tool", "Sword", f.world)
	local originalHandle = f.create("Part", "Handle", target)
	local originalBlade = f.create("Part", "Blade", target)
	f.create("ParticleEmitter", "Spark", originalBlade)
	f.create("Script", "NeverExecuted", originalBlade)
	f.controls.clean_TargetTool:Set(target)
	f.resetCounts()
	assert(f.clickClean() == true)
	assert(#f.state.popups == 0 and table.concat(f.state.waypoints, ",") == "Cleaning Tool,Cleaned Tool")
	assert(target.Parent == nil and originalHandle.Parent == target and originalBlade.Parent == target)
	local cleaned = f.world:GetChildren()[1]
	assert(cleaned.ClassName == "Model" and cleaned.Name == "Sword")
	local handle = cleaned.PrimaryPart
	assert(handle ~= originalHandle and handle.Name == "Handle" and handle.Anchored)
	assert(not handle.Locked and not handle.CanCollide and handle.Massless)
	assert(cleaned.positionedAt.position == handle.Position)
	local blade, weld, particle
	for _, child in ipairs(cleaned:GetDescendants()) do
		assert(child.ClassName ~= "Script", "Cleaner retained an unsupported cloned descendant")
		if child.Name == "Blade" and child:IsA("BasePart") then blade = child end
		if child.ClassName == "Weld" then weld = child end
		if child.ClassName == "ParticleEmitter" then particle = child end
	end
	assert(blade and not blade.Anchored and blade.Massless and not blade.CanCollide)
	assert(particle and particle.Parent == blade)
	assert(weld and weld.Part0 == handle and weld.Part1 == blade and weld.Parent == handle)
	assert(weld.C0.relativeFrom == handle.CFrame and weld.C0.relativeTo == blade.CFrame)
end)

test("all valid containers in a selection are still cleaned", function()
	local f = fixture()
	local one = f.create("Tool", "One", f.world)
	f.create("Part", "Handle", one)
	local two = f.create("Folder", "Two", f.world)
	local largest = f.create("Part", "Large", two)
	largest.Size = {magnitude = 3}
	f.create("Part", "Small", two)
	f.controls.clean_TargetTool:Set({one, two})
	f.resetCounts()
	assert(f.clickClean() == true)
	assert(one.Parent == nil and two.Parent == nil and #f.world:GetChildren() == 2)
	for _, model in ipairs(f.world:GetChildren()) do
		assert(model.PrimaryPart.Name == (model.Name == "One" and "Handle" or "Large"))
	end
	assert(#f.state.waypoints == 2 and #f.state.popups == 0)
end)

for _, settings in ipairs({
	{name = "animatable join", animatable = true, inPlace = false, class = "Motor6D"},
	{name = "animatable in-place join", animatable = true, inPlace = true, class = "Motor6D"},
	{name = "rigid in-place join", animatable = false, inPlace = true, class = "Weld"},
}) do
	test(settings.name .. " retains existing joint semantics", function()
		local f = fixture()
		local body = f.create("Part", "Body", f.world)
		local prop = f.create("Part", "Prop", f.world)
		local old = f.create("Weld", "Previous", body)
		old.Part0, old.Part1 = body, prop
		prop._joints = {old}
		f.controls.part_BasePart:Set(body)
		f.controls.part_TargetPart:Set(prop)
		f.controls.part_Animatable:Set(settings.animatable)
		f.resetCounts()
		f.controls[settings.inPlace and "part_JoinInPlace" or "part_Join"].OnClick()
		local joint = f.state.selection[1]
		assert(joint.ClassName == settings.class and joint.Parent == body)
		assert(joint.Part0 == body and joint.Part1 == prop and not prop.Anchored)
		assert(old.Parent == nil)
		if settings.inPlace then
			assert(joint.C0.relativeFrom == body.CFrame and joint.C0.relativeTo == prop.CFrame)
		else
			assert(joint.C0 == nil)
		end
		assert(table.concat(f.state.waypoints, ",") == "Welding Parts,Welded Parts")
	end)
end

print(string.format("Welder: %d behavior tests passed with mocked Roblox APIs; Studio not tested.", passed))

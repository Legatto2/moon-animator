local _g = _G.MoonGlobal; _g.req("RigKeyframeTrack", "Path")
local MotorTrack = super:new()

function MotorTrack:new(LayerSystem, ItemObject, hierLevel, Motor)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, LayerSystem and Path:new(Motor) or nil, {"C1", "CFrame"})
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.ListComponent.Label.Text = ctor.Target.Part1.Name
		ctor.tweenFunction = _g.ItemTable.TweenFunctions.MotorLerp
		ctor.part = ctor.Target.Part1; ctor.ratio = 3
		
		_g.PartHandles.AddPart(ctor, "main")
		MotorTrack.SetHandleHidden(ctor, false)
	end

	return ctor
end

function MotorTrack:make_onion(parent)
	if self.GhostPart then
		local check_highlight = pcall(function() local prop = self.GhostPart.Name end)
		if not check_highlight then
			self.GhostPart = nil
		end
	end
	if not self.GhostPart then
		self.GhostPart = _g.ghost_part(self.Target.Part1, parent)
	end
end

function MotorTrack:clear_onion(parent)
	if self.GhostPart then
		local check_highlight = pcall(function() local prop = self.GhostPart.Name end)
		if not check_highlight then
			self.GhostPart = nil
		end
	end
	if self.GhostPart then
		self.GhostPart:Destroy()
		self.GhostPart = nil
	end
end

function MotorTrack:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	_g.PartHandles.RemovePart(self)
	super.Destroy(self)
end

function MotorTrack:set_select(value)
	super.set_select(self, value)
	_g.PartHandles.SetSelect(self, value)
end

function MotorTrack:SetHandleHidden(value, all)
	super.SetHandleHidden(self, value, all)
	if value then
		self.sel_part.Parent = nil
	else
		self.sel_part.Parent = _g.MouseFilter
	end

	if all then
		self.ItemObject.RigContainer:Iterate(function(track)
			if track ~= self then
				track:SetHandleHidden(not track.HandleHidden)
			end
		end, "MotorTrack")
	end
end

return MotorTrack

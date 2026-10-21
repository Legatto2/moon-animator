local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local BasePartCFrameTrack = super:new()

function BasePartCFrameTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.part = Path.Item; ctor.ratio = 4; ctor.resize = true

		_g.PartHandles.AddPart(ctor, "third")
	end

	return ctor
end

function BasePartCFrameTrack:make_onion(parent)
	if self.GhostPart then
		local check_highlight = pcall(function() local prop = self.GhostPart.Name end)
		if not check_highlight then
			self.GhostPart = nil
		end
	end
	if not self.GhostPart then
		self.GhostPart = _g.ghost_part(self.part, parent)
	end
end

function BasePartCFrameTrack:clear_onion(parent)
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

function BasePartCFrameTrack:set_select(value)
	super.set_select(self, value)
	_g.PartHandles.SetSelect(self, value)
end

function BasePartCFrameTrack:Destroy()
	if self.selected then
		self.LayerSystem.SelectionHandler:_DeselectTrack(self)
	end
	_g.PartHandles.RemovePart(self)
	super.Destroy(self)
end
return BasePartCFrameTrack

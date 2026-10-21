local _g = _G.MoonGlobal; _g.req("KeyframeTrack")
local LightingClockTimeTrack = super:new()

function LightingClockTimeTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		
	end

	return ctor
end

function LightingClockTimeTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if self.value == self.previous_value then return end
	self.previous_value = self.value
	
	local hours = math.modf(self.value)
	local minutes = math.modf((self.value - hours) * 60)
	local seconds = math.modf((self.value - hours - (minutes / 60)) * 3600)
	self.Target.TimeOfDay = tostring(hours)..":"..tostring(minutes)..":"..tostring(seconds)
end

return LightingClockTimeTrack

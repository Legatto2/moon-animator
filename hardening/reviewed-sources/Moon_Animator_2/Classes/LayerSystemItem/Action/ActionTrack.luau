local _g = _G.MoonGlobal; _g.req("DiscreteKeyframeTrack")
local ActionTrack = super:new()

function ActionTrack:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.defaultValue = true
		ctor.ListComponent.Label.Text = ctor.ListComponent.Label.Text.."()"
		ctor.func = _g.BLANK_FUNC
	end

	return ctor
end

function ActionTrack:init_values()
	self.value = self.defaultValue
	self.defaultValue = self.value
	self.lastValue = self.value
end

function ActionTrack:get_prop()
	return self.value
end

function ActionTrack:set_prop(value)
	self.Target.Value = value
end

function ActionTrack:SetEnabled(value, inputted)
	self.LastUpdate = self.LayerSystem.SliderFrame - 1
	super.SetEnabled(self, value, inputted)
end


function ActionTrack:_Update(frm_pos)
	super.update_value(self, frm_pos)
	if not self.Enabled or not self.LayerSystem.PlaybackHandler.Playing then return end

	if frm_pos < self.LastUpdate then
		for pos = self.LastUpdate + 1, self.LayerSystem.length, 1 do
			if self.KeyframeMap[pos] ~= nil then
				local val = self.KeyframeMap[pos] ~= _g.NIL_VALUE and self.KeyframeMap[pos] or nil
				self.func(val)
			end
		end
		self.LastUpdate = -1
	end
	for pos = self.LastUpdate + 1, frm_pos do
		if self.KeyframeMap[pos] ~= nil then
			local val = self.KeyframeMap[pos] ~= _g.NIL_VALUE and self.KeyframeMap[pos] or nil
			self.func(val)
		end
	end

	self.LastUpdate = frm_pos
end

return ActionTrack

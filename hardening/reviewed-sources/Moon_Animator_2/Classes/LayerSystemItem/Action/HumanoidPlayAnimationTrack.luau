local _g = _G.MoonGlobal; _g.req("ActionTrack")
local Track = super:new()

local kf = game:GetService("KeyframeSequenceProvider"); local reg_kf = kf.RegisterKeyframeSequence

function Track:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	local ctor = super:new(LayerSystem, ItemObject, hierLevel, Path, PropertyData)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.defaultValue = nil
		ctor.loaded_anis = {}
		
		ctor.func = function(value)
			if value then
				pcall(function()  
					local id = value:GetDebugId()
					if ctor.loaded_anis[id] == nil then
						if ctor.Target:FindFirstChild("Animator") == nil then
							Instance.new("Animator", ctor.Target)
						end
						if value.ClassName == "KeyframeSequence" then
							local new_ani = Instance.new("Animation"); new_ani.AnimationId = reg_kf(kf, value)
							ctor.loaded_anis[id] = ctor.Target.Animator:LoadAnimation(new_ani)
						else
							ctor.loaded_anis[id] = ctor.Target.Animator:LoadAnimation(value)
						end
					end
					ctor.loaded_anis[id]:Play()
				end)
			else
				pcall(function()  
					for _, track in pairs(ctor.loaded_anis) do
						track:Stop()
					end
				end)
			end
		end
	end

	return ctor
end

function Track:Destroy()
	local grab_tracks = self.loaded_anis
	self.loaded_anis = {}
	for _, track in pairs(grab_tracks) do
		track:Destroy()
	end
	super.Destroy(self)
end

return Track

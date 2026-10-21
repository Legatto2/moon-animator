-- Only the patched PlaybackHandler module is inserted; no complete plugin runs.
local passed = 0
local function test(name, callback)
	callback()
	passed += 1
	print("PASS " .. name)
end

local function fixture(playing, unbindFails)
	local calls = {}
	local state = {effects = true}
	local _G = {MoonGlobal = {req = function() end, class = {MarkerTrack = {}}}}
	local _g = _G.MoonGlobal
	local super = {new = function() return {} end}
	local function require(target)
		assert(target == _g.class.MarkerTrack, "Unexpected module dependency")
		return {StopSafeEffects = function(handler)
			assert(handler == state.handler, "Cleanup used the wrong playback handler")
			table.insert(calls, "cleanup")
			state.effects = false
		end}
	end
	_g.run_serv = {UnbindFromRenderStep = function(_, _name)
		table.insert(calls, "unbind")
		if unbindFails then error("Already unbound") end
	end}
	local module = (function()
-- MODULE_SOURCE_INSERTION_POINT
	end)()
	state.handler = setmetatable({
		Playing = playing,
		LayerSystem = {
			AddPose = {Visible = not playing},
			refresh_on_pose = function()
				assert(not state.effects, "Pose restored before event effects were cleaned")
				assert(not state.handler.Playing, "Pose restored while still playing")
				table.insert(calls, "refresh")
			end,
		},
	}, {__index = module})
	return state.handler, state, calls
end

test("active Stop cleans event effects before restoring the pose", function()
	local handler, state, calls = fixture(true)
	handler:Stop()
	assert(not state.effects and not handler.Playing)
	assert(handler.LayerSystem.AddPose.Visible)
	assert(table.concat(calls, ",") == "cleanup,unbind,refresh")
end)

test("idle Stop still cleans event effects without refreshing the timeline", function()
	local handler, state, calls = fixture(false)
	handler:Stop()
	assert(not state.effects and not handler.Playing)
	assert(table.concat(calls, ",") == "cleanup")
end)

test("repeated Stop is safe and does not restore the pose twice", function()
	local handler, state, calls = fixture(true)
	handler:Stop()
	handler:Stop()
	assert(not state.effects and not handler.Playing)
	assert(table.concat(calls, ",") == "cleanup,unbind,refresh,cleanup")
end)

test("render unbind errors cannot skip cleanup or pose restoration", function()
	local handler, state, calls = fixture(true, true)
	handler:Stop()
	assert(not state.effects and not handler.Playing)
	assert(handler.LayerSystem.AddPose.Visible)
	assert(table.concat(calls, ",") == "cleanup,unbind,refresh")
end)

print(string.format("Passed %d playback cleanup cases.", passed))

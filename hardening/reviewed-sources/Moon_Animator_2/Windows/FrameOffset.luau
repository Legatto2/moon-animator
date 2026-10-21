local _g = _G.MoonGlobal
------------------------------------------------------------
	local MoonSystem

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Frame Offset", script.Contents))

	TimeInput:new(Win.g_e.Offset, _g.DEFAULT_FRAMES, nil, {0, _g.MAX_FRAMES, 1})

	Button:new(Win.g_e.Confirm)
	Win.FocusedTextBox = Offset.UI.Frame.Input
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		Offset:Set(_g.time_offset)
		return true
	end

	Win.OnClose = function(save)
		if save then
			local layer_sys = _g.Windows.MoonAnimator.g_e.LayerSystem
			_g.time_offset = Offset.Value
			layer_sys:SetSliderFrame(layer_sys.SliderFrame)
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

local _g = _G.MoonGlobal
------------------------------------------------------------
	local LayerSystem

	local Win  = _g.Window:new(script.Name, _g.WindowData:new("Split Stride", script.Contents))

	NumberInput:new(Win.g_e.SplitSize, 0, nil, {1, math.huge, 1, true})
	Button:new(Win.g_e.Confirm)

	Win.FocusedTextBox = SplitSize.UI.Frame.Input
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		SplitSize:Set(LayerSystem.split_size)
		return true
	end

	Win.OnClose = function(save)
		if save then
			LayerSystem.split_size = SplitSize.Value
		end
		return true
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

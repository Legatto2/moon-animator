local _g = _G.MoonGlobal
------------------------------------------------------------
	local LayerSystem

	local WindowData = _g.WindowData:new("Camera Reference", script.Contents)

	local Win  = _g.Window:new(script.Name, WindowData)

	Button:new(Win.g_e.Confirm)

	Button:new(Win.g_e.SetRef); local SetRef = Win.g_e.SetRef
	ValueLabel:new(Win.g_e.CurrentRef, nil); local CurrentRef = Win.g_e.CurrentRef

	local SelectionBox = Win.Contents.SelectionBox
	Win:AddPaintedItem(SelectionBox, {Color3 = "second", SurfaceColor3 = "second"})
------------------------------------------------------------
do
	Win.OnOpen = function()
		LayerSystem = _g.Windows.MoonAnimator.g_e.LayerSystem
		CurrentRef:Set(LayerSystem.CameraReferencePart)
		SelectionBox.Adornee = CurrentRef.Value
		return true
	end

	Win.OnClose = function(save)
		if save then
			_g.Windows.MoonAnimator.DoCompositeAction("AdjustCameraRef", {Part = CurrentRef.Value})
		end
		SelectionBox.Adornee = nil
		return true
	end

	SetRef.OnClick = function()
		local sel = _g.first_sel()
		if sel and sel:IsA("BasePart") then
			CurrentRef:Set(sel)
		else
			CurrentRef:Set(nil)
		end
		SelectionBox.Adornee = CurrentRef.Value
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

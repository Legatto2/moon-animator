local _g = _G.MoonGlobal
local PartHandles = {}

------------------------------------------------------------
	PartHandles.handles_shown = true
	PartHandles.handles_full = false

	local PartSelect = {}
------------------------------------------------------------
do
	PartHandles.SetSelect = function(track, value)
		track.sel_part.Handle.Transparency = value and 1 or 0.5
		track.sel_part.Select.Visible = value
		track.sel_part.SelectionBox.Visible = value
	end
	
	PartHandles.AddPart = function(track, color)
		assert(PartSelect[tostring(track)] == nil)
		
		track.sel_part = _g.new_ui.Handles.Box:Clone(); track.sel_part.Handle.Adornee = track.sel_part; track.sel_part.Parent = _g.MouseFilter
		track.sel_part.Handle.ZIndex = track.hierLevel

		track.sel_part.Size = PartHandles.handles_full and track.part.Size or track.part.Size * (1 / track.ratio)
		track.sel_part.Handle.Adornee = (not PartHandles.handles_full) and track.sel_part or nil
		track.sel_part.Handle.Size = track.sel_part.Size
		track.sel_part.Handle.Visible = _g.PartHandles.handles_shown
		
		
		track.sel_part.Select.Adornee = track.sel_part
		
		track.sel_part.SelectionBox.Adornee = PartHandles.handles_full and track.sel_part or nil
		track.sel_part.Select.Size = (not PartHandles.handles_full) and track.sel_part.Size or track.sel_part.Size + Vector3.new(0.05, 0.05, 0.05)
		track.sel_part.Select.Transparency = (not PartHandles.handles_full) and 0.4 or 1
		track.sel_part.Select.AlwaysOnTop = not PartHandles.handles_full
		
		track.sel_part.Select.ZIndex = track.hierLevel
		
		track:AddPaintedItem(track.sel_part.SelectionBox, {Color3 = color, SurfaceColor3 = color})
		track:AddPaintedItem(track.sel_part.Handle, {Color3 = "highlight"})
		track:AddPaintedItem(track.sel_part.Select, {Color3 = color})

		track.sel_part.PartClicked.Event:Connect(function() track.handle_clicked() end)
		
		PartSelect[tostring(track)] = track
	end
	
	PartHandles.RemovePart = function(track)
		assert(PartSelect[tostring(track)])
		PartSelect[tostring(track)] = nil
		track.sel_part:Destroy()
	end
	
	_g.run_serv:BindToRenderStep("MoonAnimator2_PartSelect", 100, function()
		if _g.MouseFilter.Parent == nil then return end
		
		if PartHandles.handles_shown ~= _g.show_part_handles then
			PartHandles.handles_shown = _g.show_part_handles
			for _, track in pairs(PartSelect) do
				track.sel_part.Handle.Visible = PartHandles.handles_shown
			end
		end
		if PartHandles.handles_full ~= _g.full_part_handles then
			PartHandles.handles_full = _g.full_part_handles
			for _, track in pairs(PartSelect) do
				track.sel_part.Size = PartHandles.handles_full and track.part.Size or track.part.Size * (1 / track.ratio)
				track.sel_part.Handle.Size = track.sel_part.Size
				
				track.sel_part.SelectionBox.Adornee = PartHandles.handles_full and track.sel_part or nil
				track.sel_part.Select.Size = (not PartHandles.handles_full) and track.sel_part.Size or track.sel_part.Size + Vector3.new(0.05, 0.05, 0.05)
				track.sel_part.Select.Transparency = (not PartHandles.handles_full) and 0.4 or 1
				track.sel_part.Select.AlwaysOnTop = not PartHandles.handles_full
				
				track.sel_part.Handle.Adornee = (not PartHandles.handles_full) and track.sel_part or nil
			end
		end
		for _, track in pairs(PartSelect) do
			if track.resize then
				track.sel_part.Size = PartHandles.handles_full and track.part.Size or track.part.Size * (1 / track.ratio)
				if not PartHandles.handles_full then
					track.sel_part.Handle.Size = track.sel_part.Size
					track.sel_part.Select.Size = track.sel_part.Handle.Size
				end
			end
			track.sel_part.CFrame = track.part:GetRenderCFrame()
		end
	end)
end

return PartHandles

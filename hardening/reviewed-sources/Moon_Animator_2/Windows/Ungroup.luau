local _g = _G.MoonGlobal
------------------------------------------------------------
	local TargetKeyframes
	local MinBound
	local MaxBound
	local NormalMax
	
	local WindowData = _g.WindowData:new("Ungroup", script.Contents)

	 local Win  = _g.Window:new(script.Name, WindowData)
	local SelectionHandler

	Button:new(Win.g_e.Confirm)
	Button:new(Win.g_e.All)
	NumberInput:new(Win.g_e.From, 0, nil, {0, math.huge, 1, true})
	NumberInput:new(Win.g_e.To, 0, nil, {0, math.huge, 1, true})
	TimeInput:new(Win.g_e.Start, _g.DEFAULT_FRAMES, nil, {0, _g.MAX_FRAMES, 1})
	TimeInput:new(Win.g_e.End, _g.DEFAULT_FRAMES, nil, {0, _g.MAX_FRAMES, 1})
	Radio:new(Win.g_e.RangeSelect, "In")
	Check:new(Win.g_e.DeleteUngrouped, false, nil)
------------------------------------------------------------
do
	Win.OnOpen = function()
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if SelectionHandler.SelectedTrackItems.size == 0 then return false end

		TargetKeyframes = {}
		SelectionHandler.SelectedTrackItems:Iterate(function(Keyframe)
			if Keyframe.group then
				if MinBound == nil or Keyframe.frm_pos < MinBound then
					MinBound = Keyframe.frm_pos
				end
				if MaxBound == nil or Keyframe.frm_pos + Keyframe.width > MaxBound then
					MaxBound = Keyframe.frm_pos + Keyframe.width
				end
				table.insert(TargetKeyframes, Keyframe)
			end
		end, "Keyframe")

		if #TargetKeyframes == 0 then 
			TargetKeyframes = nil
			return false
		end

		NormalMax = MaxBound - MinBound

		table.sort(TargetKeyframes, function(a, b) return a.frm_pos < b.frm_pos end)

		Win.g_e.From.Min = 0; 		 Win.g_e.Start.Min = MinBound
		Win.g_e.From.Max = NormalMax; Win.g_e.Start.Max = MaxBound
		Win.g_e.From:Set(0); 		 Win.g_e.Start:Set(MinBound)

		Win.g_e.To.Min = 0; 		   Win.g_e.End.Min = MinBound
		Win.g_e.To.Max = NormalMax; Win.g_e.End.Max = MaxBound
		Win.g_e.To:Set(NormalMax);  Win.g_e.End:Set(MaxBound)
		
		Win.g_e.All:SetActive(false)

		return true
	end
	Win.OnClose = function(save)
		if save then
			_g.Windows.MoonAnimator.DoCompositeAction("UngroupKeyframes", {TargetKeyframes = TargetKeyframes,
				minPos = Win.g_e.Start.Value, 
				maxPos = Win.g_e.End.Value,
				InRange = Win.g_e.RangeSelect.Value == "In",
				Delete = Win.g_e.DeleteUngrouped.Value})
		end
		TargetKeyframes = nil
		MinBound = nil
		MaxBound = nil
		NormalMax = nil
		return true
	end

	function RefreshSelectAll()
		Win.g_e.All:SetActive(Win.g_e.From.Value ~= 0 or Win.g_e.To.Value ~= NormalMax)
	end

	Win.g_e.From._changed = function(val)
		Win.g_e.Start:Set(MinBound + val)
		RefreshSelectAll()
	end
	Win.g_e.To._changed = function(val)
		Win.g_e.End:Set(MinBound + val)
		RefreshSelectAll()
	end
	Win.g_e.Start._changed = function(val)
		Win.g_e.From:Set(val - MinBound)
		RefreshSelectAll()
	end
	Win.g_e.End._changed = function(val)
		Win.g_e.To:Set(val - MinBound)
		RefreshSelectAll()
	end

	Win.g_e.All.OnClick = function()
		Win.g_e.From:Set(0); 	  Win.g_e.Start:Set(MinBound)
		Win.g_e.To:Set(NormalMax); Win.g_e.End:Set(MaxBound)
		Win.g_e.All:SetActive(false)
	end

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

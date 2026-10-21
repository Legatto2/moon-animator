local _g = _G.MoonGlobal
------------------------------------------------------------
	local SelectionHandler

	local From
	local To
	
	local WindowData = _g.WindowData:new("Repeat Frames", script.Contents)

	local Win  = _g.Window:new(script.Name, WindowData)

	Button:new(Win.g_e.Confirm); local Confirm = Win.g_e.Confirm

	NumberInput:new(Win.g_e.LoopCount, 1, nil, {0, 1000, 1}); local LoopCount = Win.g_e.LoopCount
	TimeInput:new(Win.g_e.Length, 0, nil); local Length = Win.g_e.Length
	TimeInput:new(Win.g_e.EndTime, 0, nil); local EndTime = Win.g_e.EndTime
	Button:new(Win.g_e.ToEnd)
------------------------------------------------------------
do
	LoopCount._changed = function(value)
		Length:Set(Length.Min + Length.Min * value)
		EndTime:Set(EndTime.Min + Length.Min * value)

		Confirm:SetActive(LoopCount.Value > 0)
	end

	Length._changed = function(value)
		LoopCount:Set((value - Length.Min) / Length.Min)
		EndTime:Set(EndTime.Min + (value - Length.Min))

		Confirm:SetActive(LoopCount.Value > 0)
	end

	EndTime._changed = function(value)
		LoopCount:Set((value - EndTime.Min) / Length.Min)
		Length:Set(Length.Min + (value - EndTime.Min))

		Confirm:SetActive(LoopCount.Value > 0)
	end

	function ClearBuffers()
		From = nil
		To = nil
	end
	ClearBuffers()

	Win.OnOpen = function()
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if SelectionHandler.SelectedTrackItems.size == 0 then return false end

		TrackData, TargetTrackItems, CurrentPropertyType = SelectionHandler:GetFromToSelectionData(false, "Keyframe")

		for _, tbl in pairs(TrackData) do
			if From == nil or (tbl.From.frm_pos < From) then
				From = tbl.From.frm_pos
			end
			if To == nil or (tbl.To.frm_pos + tbl.To.width > To) then
				To = tbl.To.frm_pos + tbl.To.width
			end
		end

		if From == To then 
			ClearBuffers()
			return false 
		end

		Length.Min = To - From
		Length.Max = Length.Min + Length.Min * 1000

		EndTime.Min = To
		EndTime.Max = EndTime.Min + Length.Min * 1000

		LoopCount:Set(0)
		Length:Set(To - From)
		EndTime:Set(To)

		Confirm:SetActive(false)
		return true
	end

	Win.g_e.ToEnd.OnClick = function()
		EndTime:Set(SelectionHandler.LayerSystem.length, true)
	end

	Win.OnClose = function(save)
		if save then
			_g.Windows.MoonAnimator.DoCompositeAction("RepeatFrames", {TrackData = TrackData, LoopLength = Length.Value - Length.Min, From = From, To = To})
		end
		ClearBuffers()
		return true
	end
	
	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

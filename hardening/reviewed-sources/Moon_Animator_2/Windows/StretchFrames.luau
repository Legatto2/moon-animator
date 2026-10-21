local _g = _G.MoonGlobal
------------------------------------------------------------
	local SelectionHandler

	local TrackData = {}
	local TargetTrackItems = {}

	local IniFrmPos
	local LastFrmPos

	local Win = _g.Window:new(script.Name, _g.WindowData:new("Stretch Frames", script.Contents))

	Button:new(Win.g_e.Confirm)
	ValueLabel:new(Win.g_e.CurDuration, nil, true)
	NumberInput:new(Win.g_e.Factor, 100, nil)
	TimeInput:new(Win.g_e.NewDuration, 0, nil)
	TimeInput:new(Win.g_e.EndTime, 0, nil)
------------------------------------------------------------
do
	function ClearBuffers()
		TrackData = {}
		TargetTrackItems = {}

		IniFrmPos = nil
		LastFrmPos = nil
	end
	ClearBuffers()

	Factor._changed = function(value)
		NewDuration:Set(math.floor((LastFrmPos - IniFrmPos) * (value / 100)))
		EndTime:Set(IniFrmPos + NewDuration.Value)
		Confirm:SetActive(Factor.Value ~= 100)
	end

	NewDuration._changed = function(value)
		Factor:Set((value / (LastFrmPos - IniFrmPos)) * 100)
		EndTime:Set(IniFrmPos + value)
		Confirm:SetActive(Factor.Value ~= 100)
	end

	EndTime._changed = function(value)
		NewDuration:Set(value - IniFrmPos)
		Factor:Set((NewDuration.Value / (LastFrmPos - IniFrmPos)) * 100)
		Confirm:SetActive(Factor.Value ~= 100)
	end

	Win.OnOpen = function()
		SelectionHandler = _g.Windows.MoonAnimator.g_e.LayerSystem.SelectionHandler
		if SelectionHandler.SelectedTrackItems.size == 0 then return false end

		TrackData, TargetTrackItems, PropertyType, IniFrmPos, LastFrmPos = SelectionHandler:GetFromToSelectionData(true)

		if (IniFrmPos == nil or LastFrmPos == nil) or (IniFrmPos == LastFrmPos) or IniFrmPos > LastFrmPos then 
			ClearBuffers()
			return false 
		end

		Factor.Min = 1 / (LastFrmPos - IniFrmPos)

		CurDuration:Set(_g.TimeConvert(LastFrmPos - IniFrmPos, "f", "t", SelectionHandler.LayerSystem.FPS))
		Factor:Set(100)
		NewDuration:Set(LastFrmPos - IniFrmPos)
		EndTime:Set(LastFrmPos)

		Confirm:SetActive(false)
		return true
	end

	Win.OnClose = function(save)
		if save then
			_g.Windows.MoonAnimator.DoCompositeAction("Stretch", {TrackData = TrackData, TargetTrackItems = TargetTrackItems, Factor = Factor.Value / 100, IniFrmPos = IniFrmPos})
		end
		ClearBuffers()
		return true
	end
	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win

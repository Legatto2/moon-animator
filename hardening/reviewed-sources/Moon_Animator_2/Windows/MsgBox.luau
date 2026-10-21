local _g = _G.MoonGlobal
------------------------------------------------------------
	local button1Func = nil
	local button2Func = nil

	local Win = _g.Window:new(script.Name, _g.WindowData:new("Message Box", script.Contents))

	Button:new(Win.g_e.Button1)
	Button:new(Win.g_e.Button2)
	Button:new(Win.g_e.Confirm)

	Win:AddPaintedItem(Win.Contents.Section.Content, {TextColor3 = "main"})
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		if args == nil then return false end

		Win:SetTitle(args.Title)
		Win.Contents.Section.Content.Text = args.Content
		button1Func = args.Button1
		button2Func = args.Button2

		Button1.UI.Visible = not (button1Func == nil)
		Button1.UI.Label.Text = button1Func and button1Func[1] or ""
		Button2.UI.Visible = not (button2Func == nil)
		Button2.UI.Label.Text = button2Func and button2Func[1] or ""
		
		Confirm.UI.Visible = (not button1Func and not button2Func)

		return true
	end

	Button1.OnClick = function()
		if button1Func then
			Win:Close()
			button1Func[2]()
		end
	end

	Button2.OnClick = function()
		if button2Func then
			Win:Close()
			button2Func[2]()
		end
	end
	
	Confirm.OnClick = function()
		Win:Close()
	end
end
------------------------------------------------------------
do
	local CurrentWindow = nil
	Win.Popup = function(TargetWindow, args)
		if Win.Visible then
			Win:GetFocus()
			return false
		end
		TargetWindow:OpenModal(Win, args)
		return true
	end
end

return Win

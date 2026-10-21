local _g = _G.MoonGlobal
------------------------------------------------------------
	local WindowData = _g.WindowData:new("Supporters",  script.Contents)
	local Win = _g.Window:new(script.Name, WindowData)

	for _, ui in pairs(UI.Parent.Resizers:GetChildren()) do
		ui.Visible = false
	end
------------------------------------------------------------
do
	Win:AddPaintedItem(Win.Contents.Section.Label, {TextColor3 = "main"})
	
	Win.OnOpen = function(args)
		Win.UI.TitleBar.Title.Text = args[1]
		Win.Contents.Section.Banner.Image = "rbxassetid://"..tostring(args[2])
		Win.Contents.Section.Label.Text = args[3]
		return true
	end
end

return Win

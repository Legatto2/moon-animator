local _g = _G.MoonGlobal
------------------------------------------------------------
-- The original terms remain an optional reference in the credits window.
local EULA = [[The SOFTWARE PRODUCT (Moon Animator 2) is licensed.
1. LICENSES
*1Moon Animator 2 is licensed as follows:
*2a. Installation and Usage.
*3Licenses are per account and may be used on multiple computers
*3and operating systems.
*2b. Enterprise License.
*3Internal Roblox use or use on Roblox sponsored projects requires an
*3Enterprise License.
2. DESCRIPTION OF OTHER RIGHTS AND LIMITATIONS
!*1The use of Moon Animator 2 <u>must</u> abide by <b>Roblox Community Standards</b>.
!*1Licenses will be revoked otherwise.
3. NO WARRANTIES
*1Moon Animator 2 is provided 'as is' without any express or implied warranty
*1of any kind.
4. LIMITATION OF LIABILITY
*1In no event shall the developer of Moon Animator 2 be liable for any damages
*1due to use of Moon Animator 2.
]]

local WindowData = _g.WindowData:new("Credits & terms", script.Contents)
local Win = _g.Window:new(script.Name, WindowData)

-- Keep the serialized hierarchy compatible while removing acceptance controls.
UI.Buttons.Activate.Visible = false
local CloseButton = Button:new(Win.g_e.Decline)
CloseButton.UI.Label.Text = "Close"

UI.LicId.Text = "Moon Animator 2 — @xsixx"
UI.LicStatus.Text = ""
UI.LicStatus.Visible = false
Win:AddPaintedItem(UI.LicId, {TextColor3 = "main"})

local line_ui = UI.Section.Lines.Line
local frame = line_ui.Parent; line_ui.Parent = nil

for line in EULA:gmatch("[%w%p ]+\n+") do line = line:gsub("\n", "")
	local pos = 0
	local color = "main"
	if line:sub(1,1) == "!" then
		color = "highlight"
		line = line:sub(2)
	end
	if line:sub(1,1) == "*" then
		pos = tonumber(line:sub(2,2)) * 8
		line = line:sub(3)
	end
	local new_line = line_ui:Clone()
	new_line.Content.Text = line:gsub("\n", "")
	new_line.Size = UDim2.new(1,-pos,0,0)
	Win:AddPaintedItem(new_line.Content, {TextColor3 = color})
	new_line.Parent = frame
end

for _, ui in pairs(UI.Parent.Resizers:GetChildren()) do
	ui.Visible = false
end

Win.OnOpen = function()
	return true
end
CloseButton.OnClick = function()
	Win:Close()
end

return Win

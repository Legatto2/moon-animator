local _g = _G.MoonGlobal
------------------------------------------------------------
local FILE_MENU = {
	{"theme_list", "Theme"},
	{"h_contact", "@xsixx"},
	theme_list = {

	},
}
local cur_list = FILE_MENU.theme_list
local price = true
for _, theme in pairs(_g.Themer.ThemeList) do
	if theme == "~" then
		table.insert(cur_list, "~")
		price = false
	else
		table.insert(cur_list, {"Activate_Theme_"..theme, theme, extra = {NoClickOff = true, Price = price}})
	end
end

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

local WindowData = _g.WindowData:new("End User License Agreement",  script.Contents)
WindowData.MenuBar = _g.MenuBar.MenuBarFactory("ActivateMenu", FILE_MENU)
local Win = _g.Window:new(script.Name, WindowData)

for _, theme in pairs(_g.Themer.ThemeList) do
	if theme ~= "~" then
		if theme == "Default" then
			_g.Input:BindAction(Win, "Activate_Theme_"..theme, function()
				_g.Themer:SetTheme(theme)
				_g.plugin:SetSetting(_g.theme_key, nil)
			end, {}, false)
		else
			_g.Input:BindAction(Win, "Activate_Theme_"..theme, function()
				_g.Themer:SetTheme(theme)
				_g.plugin:SetSetting(_g.theme_key, theme)
			end, {}, false)
		end
	end
end

Button:new(Win.g_e.Activate)
Button:new(Win.g_e.Decline)

local LicId = UI.LicId
local LicStatus = UI.LicStatus

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

local id = game:GetService("StudioService"):GetUserId()
LicId.Text = "License for account <b>"..tostring(id).."</b>"
LicStatus.Text = '<i>NOT ACTIVATED</i>'

Win:AddPaintedItem(LicId, {TextColor3 = "main"})
Win:AddPaintedItem(LicStatus, {TextColor3 = "highlight"})

for _, ui in pairs(UI.Parent.Resizers:GetChildren()) do
	ui.Visible = false
end
------------------------------------------------------------
do
	Win.OnOpen = function(args)
		return true
	end

	Decline.OnClick = function()
		Win:Close()
	end
end

return Win

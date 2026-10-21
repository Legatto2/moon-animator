-- Isolated reviewed startup/UI blocks and actual Themer/MenuItem modules.
-- Inert doubles replace Roblox services, settings, toolbar, and UI. This does
-- not execute the complete plugin, load assets, or claim a Studio smoke test.
local passed = 0
local function test(name, callback)
    local ok, message = pcall(callback)
    assert(ok, name .. ": " .. tostring(message))
    passed += 1
    print("PASS " .. name)
end

local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            table.insert(callbacks, callback)
            return {Disconnect=function() error("Startup should not replace gated handlers") end}
        end,
        Fire = function() for _, callback in ipairs(callbacks) do callback() end end,
        Count = function() return #callbacks end,
    }
end

local function colorMatches(color, rgb)
    return color.r == rgb[1] / 255 and color.g == rgb[2] / 255 and color.b == rgb[3] / 255
end

local function fixture(settings)
    local state = {
        settings=settings or {}, reads={}, writes={}, buttons={}, files=0, services={},
        toggles={}, opens={}, themeChanges=0, termLines={}, createdControls={},
    }
    local _g = {Mouse={Icon=""}, Windows={}}
    local _G = {MoonGlobal=_g}
    local game = {GetService=function(_, name)
        table.insert(state.services, name)
        assert(name == "TweenService", "Startup must not query account, Marketplace, or network services")
        return {Create=function() error("Engine tweening is outside this test") end}
    end}
    local Color3 = {fromRGB=function(r, g, b)
        assert(type(r) == "number" and type(g) == "number" and type(b) == "number")
        return {r=r/255, g=g/255, b=b/255}
    end}
    local plugin = {
        GetSetting=function(_, key)
            table.insert(state.reads, key)
            assert(key == "MoonAnimator2_Colors", "Unexpected activation-setting read")
            return state.settings[key]
        end,
        SetSetting=function(_, key, value)
            table.insert(state.writes, {key=key, value=value})
            assert(key == "MoonAnimator2_Colors", "Unexpected activation-setting write")
            state.settings[key] = value
        end,
    }
    _g.plugin = plugin
    _g.Files = {RefreshFiles=function() state.files += 1 end}
    for _, name in {"MoonAnimator", "CharacterInserter", "Welder", "Activate"} do
        state.toggles[name], state.opens[name] = 0, 0
        _g.Windows[name] = {
            Toggle=function() state.toggles[name] += 1 end,
            Open=function() state.opens[name] += 1 end,
        }
    end
    local pluginToolbar = {CreateButton=function(_, id, description, icon)
        local button = {id=id, description=description, icon=icon, Click=signal(), activeCalls=0}
        function button:SetActive(value) self.active=value; self.activeCalls += 1 end
        table.insert(state.buttons, button)
        return button
    end}
    _g.Themer = (function()
-- THEMER_SOURCE_INSERTION_POINT
    end)()
    table.insert(_g.Themer.theme_changed, function() state.themeChanges += 1 end)

    function state:start()
-- STARTUP_SOURCE_INSERTION_POINT
    end

    function state:loadMenu()
        local menu = (function()
-- MENU_SOURCE_INSERTION_POINT
        end)()
        local Win = _g.Windows.MoonAnimator
        self.actions = {}
        _g.Input = {BindAction=function(_, window, name, callback, keys, disabled)
            assert(window == Win and not self.actions[name], "Duplicate menu binding")
            self.actions[name] = {callback=callback, keys=keys, disabled=disabled}
        end}
-- MENU_BINDINGS_INSERTION_POINT
        return menu
    end

    function state:loadCredits()
        local template = {Parent={}}
        function template:Clone()
            local line = {Content={}}
            table.insert(state.termLines, line)
            return line
        end
        local resizers = {{Visible=true}, {Visible=true}}
        local UI = {
            Buttons={Activate={Name="Activate", Visible=true, Label={Text="Activate"}},
                Decline={Name="Decline", Visible=true, Label={Text="Decline"}}},
            LicId={Text="Old account"}, LicStatus={Text="NOT ACTIVATED", Visible=true},
            Section={Lines={Line=template}},
            Parent={Resizers={GetChildren=function() return resizers end}},
        }
        local win = {g_e={Activate=UI.Buttons.Activate, Decline=UI.Buttons.Decline}, Visible=false}
        function win:AddPaintedItem() end
        function win:Open()
            assert(self.OnOpen())
            self.Visible = true
            state.opens.Activate += 1
        end
        function win:Close() self.Visible = false; state.creditsClosed = true end
        _g.WindowData = {new=function(_, title) return {title=title} end}
        _g.Window = {new=function(_, name, data)
            assert(name == "Activate", "Serialized window identity stays compatible")
            state.creditsTitle = data.title
            assert(data.MenuBar == nil, "Credits must not retain an activation/theme menubar")
            return win
        end}
        local Button = {new=function(_, button)
            table.insert(state.createdControls, button.Name)
            local control = {UI=button}
            win.g_e[button.Name] = control
            return control
        end}
        local script = {Name="Activate", Contents={}}
        local UDim2 = {new=function(...) return {...} end}
        local credits = (function()
-- CREDITS_SOURCE_INSERTION_POINT
        end)()
        _g.Windows.Activate = credits
        state.creditsUI, state.credits = UI, credits
        return credits
    end

    state.globals = _g
    return state
end

test("first launch refreshes files and is ready without an acceptance prompt", function()
    local state = fixture()
    state:start()
    assert(state.files == 1 and state.globals.ready == true and state.globals.theme_key == "MoonAnimator2_Colors")
    assert(#state.reads == 1 and #state.writes == 0)
    for name, count in pairs(state.opens) do assert(count == 0, "Unexpected opened window: " .. name) end
    for _, count in pairs(state.toggles) do assert(count == 0) end
end)

test("all three toolbar tools have one direct callback for their own window", function()
    local state = fixture()
    state:start()
    local names = {"MoonAnimator", "CharacterInserter", "Welder"}
    assert(#state.buttons == #names)
    for index, button in ipairs(state.buttons) do
        assert(button.Click:Count() == 1 and button.icon ~= "" and button.description ~= "")
        button.Click:Fire()
        assert(state.toggles[names[index]] == 1)
        assert(button.active == false and button.activeCalls == 1)
    end
    state.buttons[1].Click:Fire()
    assert(state.toggles.MoonAnimator == 2 and state.opens.Activate == 0)
    assert(state.files == 1, "Opening tools must not rerun activation-style initialization")
end)

for _, activated in {false, true} do
    test("old activation setting " .. tostring(activated) .. " has no effect and is left untouched", function()
        local settings = {MoonAnimator2Activated_1=not activated, MoonAnimator2Activated_2=activated}
        local state = fixture(settings)
        state:start()
        state.buttons[1].Click:Fire()
        assert(state.globals.ready and state.toggles.MoonAnimator == 1 and state.files == 1)
        assert(settings.MoonAnimator2Activated_2 == activated and settings.MoonAnimator2Activated_1 == not activated)
        assert(#state.reads == 1 and #state.writes == 0 and state.reads[1] == "MoonAnimator2_Colors")
    end)
end

test("startup performs no remote-version or account request when offline", function()
    local state = fixture()
    -- The local TweenService is used when creating Themer; every other service
    -- throws, including inside pcall, and is recorded for this assertion.
    state:start()
    assert(#state.services == 1 and state.services[1] == "TweenService")
    assert(state.globals.ready and #state.buttons == 3)
end)

for _, name in {"Default", "Lunar", "Taiga", "Catppuccin Mocha"} do
    test("startup restores saved " .. name .. " without registration", function()
        local state = fixture({MoonAnimator2_Colors=name})
        state:start()
        local themer = state.globals.Themer
        for _, field in ipairs(themer.ColorList) do
            assert(colorMatches(themer._Theme[field[1]], themer._BuiltInThemes[name][field[1]]))
        end
        assert(state.themeChanges == 1 and state.globals.ready and #state.writes == 0)
    end)
end

test("startup restores a validated custom palette and background", function()
    local palette = {main={20,40,60}, _bgOuter={"rbxassetid://123", "Fit", 0.5, "Pixelated"}}
    local state = fixture({MoonAnimator2_Colors=palette})
    state:start()
    local themer = state.globals.Themer
    assert(colorMatches(themer._Theme.main, palette.main))
    assert(colorMatches(themer._Theme.second, themer._BuiltInThemes.Default.second))
    assert(themer._Theme._bgOuter[4] == "Pixelated" and themer._Theme._bgOuter ~= palette._bgOuter)
    assert(state.globals.ready and #state.writes == 0)
end)

for _, invalid in {
    {name="obsolete theme name", value="removed-name"},
    {name="boolean", value=false},
    {name="number", value=42},
    {name="malformed color", value={main={false,40,60}}},
    {name="malformed background", value={main={20,40,60}, _bgOuter={"image","Unknown",1}}},
} do
    test("invalid saved " .. invalid.name .. " keeps Default and does not block startup", function()
        local state = fixture({MoonAnimator2_Colors=invalid.value})
        state:start()
        local themer = state.globals.Themer
        for _, field in ipairs(themer.ColorList) do
            assert(colorMatches(themer._Theme[field[1]], themer._BuiltInThemes.Default[field[1]]))
        end
        assert(themer._Theme._bgOuter[1] == "" and state.themeChanges == 0)
        assert(state.globals.ready and #state.buttons == 3 and #state.writes == 0)
    end)
end

test("main theme menu exposes every bundled palette with no price flag or disabled action", function()
    local state = fixture()
    state:start()
    local menu = state:loadMenu()
    local count = 0
    for _, entry in ipairs(menu.h_theme) do
        if type(entry) == "table" then
            count += 1
            assert(entry.extra.Price == nil and entry.extra.NoClickOff == true)
            local action = state.actions[entry[1]]
            assert(action and action.disabled == false)
            action.callback()
            local palette = state.globals.Themer._BuiltInThemes[entry[2]]
            assert(colorMatches(state.globals.Themer._Theme.main, palette.main))
        end
    end
    assert(count == 18)
end)

test("a selected formerly gated theme persists through a new plugin session", function()
    local settings = {}
    local first = fixture(settings)
    first:start()
    first:loadMenu()
    first.actions.Theme_Taiga.callback()
    assert(settings.MoonAnimator2_Colors == "Taiga")
    local second = fixture(settings)
    second:start()
    assert(colorMatches(second.globals.Themer._Theme.main, second.globals.Themer._BuiltInThemes.Taiga.main))
    assert(second.opens.Activate == 0 and #second.writes == 0)
end)

test("choosing Default clears only the stored theme preference", function()
    local settings = {MoonAnimator2_Colors="Taiga", MoonAnimator2Activated_2=false}
    local state = fixture(settings)
    state:start()
    state:loadMenu()
    state.actions.Theme_Default.callback()
    assert(settings.MoonAnimator2_Colors == nil and settings.MoonAnimator2Activated_2 == false)
    assert(#state.writes == 1 and state.writes[1].key == "MoonAnimator2_Colors")
end)

test("optional credits retain upstream terms and author without account status", function()
    local state = fixture()
    state:start()
    local credits = state:loadCredits()
    assert(state.creditsTitle == "Credits & terms" and not credits.Visible)
    assert(state.creditsUI.LicId.Text:find("@xsixx", 1, true))
    assert(state.creditsUI.LicStatus.Text == "" and not state.creditsUI.LicStatus.Visible)
    assert(not state.creditsUI.Buttons.Activate.Visible)
    assert(#state.createdControls == 1 and state.createdControls[1] == "Decline")
    assert(credits.g_e.Decline.UI.Label.Text == "Close")
    local lines = {}
    for _, line in ipairs(state.termLines) do table.insert(lines, line.Content.Text) end
    local rendered = table.concat(lines, "\n")
    for _, text in {"1. LICENSES", "2. DESCRIPTION OF OTHER RIGHTS AND LIMITATIONS", "3. NO WARRANTIES", "4. LIMITATION OF LIABILITY"} do
        assert(rendered:find(text, 1, true), "Missing original terms section")
    end
    assert(#state.services == 1 and #state.writes == 0)
end)

test("Credits and terms menu opens an optional view whose Close button has no side effects", function()
    local state = fixture()
    state:start()
    local credits = state:loadCredits()
    local menu = state:loadMenu()
    local entry = menu.settingsMain.other[1]
    assert(entry[1] == "OpenActivate" and entry[2] == "Credits & terms...")
    assert(not state.actions.OpenActivate.disabled)
    state.actions.OpenActivate.callback()
    assert(credits.Visible and state.opens.Activate == 1)
    credits.g_e.Decline.OnClick()
    assert(not credits.Visible and state.creditsClosed and state.globals.ready)
    assert(state.files == 1 and #state.writes == 0 and state.themeChanges == 0)
    for _, count in pairs(state.toggles) do assert(count == 0) end
end)

local function menuItemFixture()
    local state = {clones={}, paints={}}
    local function template(kind)
        return {Clone=function()
            table.insert(state.clones, kind)
            return {Label={}, Frame={UIStroke={}}, Hover={UIStroke={}}, Input={}, Arrow={}}
        end}
    end
    local _g = {req=function() end, AllMenus={}, AllMenuItems={}, Input={Actions={}},
        GuiLib={AddInput=function() end}, new_ui={Menu={}}}
    for _, kind in {"Left", "Middle", "Right", "ItemFrame", "CheckFrame", "ControlFrame", "MoreFrame"} do
        _g.new_ui.Menu[kind] = template(kind)
    end
    _g.new_ui.Menu.PriceFrame = {Clone=function() error("Removed theme-price UI must not be constructed") end}
    _g.Input.PrettyFormat = function(key) return key end
    local _G = {MoonGlobal=_g}
    local super = {}
    function super:new()
        return {type={}, AddPaintedItem=function() end, SetItemPaint=function(_, item, properties)
            state.paints[item] = properties
        end}
    end
    local script = {Name="MenuItem"}
    local MenuItem = (function()
-- MENU_ITEM_SOURCE_INSERTION_POINT
    end)()
    local menu = {_AddMenuItem=function(_, item) state.item=item end}
    state.globals, state.menu = _g, menu
    state.create = function(name, label, extra) return MenuItem:new(name, menu, label, extra) end
    return state
end

test("ordinary theme menu items need no price UI or entitlement registry", function()
    local state = menuItemFixture()
    local item = state.create("Theme_Taiga", "Taiga", {NoClickOff=true})
    assert(item.Disabled == false and item.NoClickOff and item.item_frame.Label.Text == "Taiga")
    assert(item.price_frame == nil and state.globals.Themer == nil)
    item:_SetDisabled(true)
    assert(item.Disabled and state.paints[item.item_frame.Label].TextColor3 == "third")
    item:_SetDisabled(false)
    assert(not item.Disabled and state.paints[item.item_frame.Label].TextColor3 == "main")
end)

test("removing price UI preserves menu toggles and keyboard hints", function()
    local state = menuItemFixture()
    state.globals.Input.Actions.Example = {keys={"CTRL_G"}, disabled=false}
    local item = state.create("Example", "Example option", {IsToggle=true, NoClickOff=true})
    assert(item.check_frame and item.control_frame and item.control_frame.Label.Text == "CTRL_G")
    item:set_check(true)
    assert(item.check_frame.Frame.UIStroke.Thickness == 2)
    item:_SetDisabled(true)
    assert(state.paints[item.control_frame.Label].TextColor3 == "third")
end)

print(string.format("Startup: %d focused behavior tests passed with mocked Roblox APIs; Studio not tested", passed))

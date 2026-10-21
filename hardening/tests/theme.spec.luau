-- Mocked unit behavior tests only: no Studio, full plugin, network, or assets.
-- Color3 validates the documented number argument contract. The stubs are not
-- intended to simulate engine rendering, animation, JSON parsing, or persistence.
-- BASELINE_MODE_INSERTION_POINT

local checks = 0
local function test(name, callback)
    local ok, err = pcall(callback)
    assert(ok, name .. ": " .. tostring(err))
    checks += 1
    print("PASS " .. name)
end

local function colorMatches(color, rgb)
    return color.r == rgb[1] / 255 and color.g == rgb[2] / 255 and color.b == rgb[3] / 255
end

local function newThemer()
    local state = {paintCalls = 0, callbacks = 0, noTween = nil, callbackTheme = nil}
    local _G = {MoonGlobal = {Mouse = {Icon = "original-cursor"}}}
    local Color3 = {}
    function Color3.fromRGB(r, g, b)
        assert(type(r) == "number" and type(g) == "number" and type(b) == "number",
            "Color3.fromRGB expects numbers")
        return {r = r / 255, g = g / 255, b = b / 255}
    end
    local game = {}
    function game:GetService(name)
        assert(name == "TweenService", "Unexpected service")
        return {Create = function() error("Engine tweening is outside this unit test") end}
    end
    local Themer = (function()
-- THEMER_SOURCE_INSERTION_POINT
    end)()
    _G.MoonGlobal.Themer = Themer
    local painted = {
        GetDebugId = function() return "painted-item" end,
        IsDescendantOf = function() return false end,
    }
    Themer:AddPaintedItem(painted, {BackgroundColor3 = "main"})
    local paintAll = Themer._paintAll
    function Themer:_paintAll(noTween)
        state.paintCalls += 1
        state.noTween = noTween
        return paintAll(self, noTween)
    end
    table.insert(Themer.theme_changed, function(theme, noTween)
        state.callbacks += 1
        state.callbackTheme = theme
        assert(noTween == state.noTween, "Callback must use the same tween setting")
    end)
    return Themer, state, _G.MoonGlobal, painted
end

if baselineMode then
    for _, name in {"Default", "Lunar"} do
        test("baseline " .. name .. " reproduces metadata passed as RGB", function()
            local themer = newThemer()
            local ok, err = pcall(function() themer:SetTheme(name) end)
            assert(not ok and string.find(tostring(err), "Color3.fromRGB expects numbers", 1, true),
                "Expected the original numeric argument error")
        end)
    end
    print("BASELINE: " .. checks .. " expected failures reproduced with mocks")
    return
end

test("initial background metadata retains resampler", function()
    local themer = newThemer()
    assert(themer._Theme._bgOuter[4] == "Default")
end)

test("nil restores Default without passing metadata as RGB", function()
    local themer, state, globals, painted = newThemer()
    assert(themer:SetTheme() == true)
    assert(colorMatches(themer._Theme.main, {246, 142, 31}))
    assert(themer._Theme._bgOuter[1] == "" and themer._Theme._bgOuter[2] == "Crop")
    assert(themer._Theme._bgOuter[3] == 1 and themer._Theme._bgOuter[4] == "Default")
    assert(state.paintCalls == 1 and state.callbacks == 1 and state.noTween == true)
    assert(state.callbackTheme == themer._BuiltInThemes.Default)
    assert(globals.Mouse.Icon == "" and painted.BackgroundColor3 == themer._Theme.main)
end)

for _, name in {"Default", "Dark", "Lunar", "Subspace"} do
    test("allowed built-in " .. name .. " retains callback and tween behavior", function()
        local themer, state = newThemer()
        assert(themer:SetTheme(name) == true)
        for _, color in themer.ColorList do
            assert(colorMatches(themer._Theme[color[1]], themer._BuiltInThemes[name][color[1]]))
        end
        assert(state.paintCalls == 1 and state.callbacks == 1 and state.noTween == true)
        assert(state.callbackTheme == themer._BuiltInThemes[name])
    end)
end

test("partial palette preserves omitted colors and callback input", function()
    local themer, state, _, painted = newThemer()
    local originalSecond = themer._Theme.second
    local theme = {main = {20.5, 0, 255}}
    assert(themer:SetTheme(theme) == true)
    assert(colorMatches(themer._Theme.main, theme.main))
    assert(themer._Theme.second == originalSecond)
    assert(state.callbackTheme == theme and state.noTween == false)
    assert(painted.BackgroundColor3 == themer._Theme.main)
end)

test("legacy locked key still updates highlight", function()
    local themer = newThemer()
    assert(themer:SetTheme({locked = {20, 40, 60}}) == true)
    assert(colorMatches(themer._Theme.highlight, {20, 40, 60}))
    assert(themer._Theme.locked == nil)
end)

-- Numeric palette fixtures from catppuccin/moon-animator-2, commit
-- 7541ad7e017c3447cf53f0c4b79ee2963fe7528b. These are the six RGB fields
-- of its four JSON themes; this test does not install or execute the generator.
local catppuccin = {
    Frappe = {second={115,121,148}, main={148,156,187}, text={198,208,245}, bg={48,52,70}, third={131,139,167}, highlight={140,170,238}},
    Latte = {second={156,160,176}, main={124,127,147}, text={76,79,105}, bg={239,241,245}, third={140,143,161}, highlight={30,102,245}},
    Macchiato = {second={110,115,141}, main={147,154,183}, text={202,211,245}, bg={36,39,58}, third={128,135,162}, highlight={138,173,244}},
    Mocha = {second={108,112,134}, main={147,153,178}, text={205,214,244}, bg={30,30,46}, third={127,132,156}, highlight={137,180,250}},
}
for name, theme in catppuccin do
    test("Catppuccin " .. name .. " palette applies", function()
        local themer, state = newThemer()
        assert(themer:SetTheme(theme) == true)
        for colorName, rgb in theme do assert(colorMatches(themer._Theme[colorName], rgb)) end
        assert(state.callbacks == 1 and state.paintCalls == 1 and state.noTween == false)
    end)
    test("Catppuccin " .. name .. " preset selects by its free built-in name", function()
        local themer, state = newThemer()
        local presetName = "Catppuccin " .. name
        assert(themer:SetTheme(presetName) == true)
        for colorName, rgb in theme do assert(colorMatches(themer._Theme[colorName], rgb)) end
        assert(state.callbackTheme == themer._BuiltInThemes[presetName])
        assert(state.callbacks == 1 and state.paintCalls == 1)
        assert(themer.theme_buttons[presetName] == nil, "A free preset must not require a price button")
    end)
end

test("optional presets leave Default as the initial and reset theme", function()
    local themer = newThemer()
    for _, color in themer.ColorList do
        assert(colorMatches(themer._Theme[color[1]], themer._BuiltInThemes.Default[color[1]]))
    end
    assert(themer:SetTheme("Catppuccin Mocha") == true)
    assert(themer:SetTheme() == true)
    for _, color in themer.ColorList do
        assert(colorMatches(themer._Theme[color[1]], themer._BuiltInThemes.Default[color[1]]))
    end
    assert(themer._Theme._bgOuter[1] == "" and themer._Theme._bgOuter[4] == "Default")
end)

test("menu separator keeps original paid themes priced and Catppuccin presets free", function()
    local themer = newThemer()
    local paid = {Taiga=true, Blush=true, Blonde=true, Wheat=true, Gaia=true,
        Ares=true, Aqua=true, Energy=true, Digital=true, Fuchsia=true}
    local originalFree = {Default=true, Dark=true, Lunar=true, Subspace=true}
    local seen, price, separators = {}, true, 0
    -- Both Activate and MoonAnimator build their Price flags from this
    -- separator; MenuItem registers entitlement buttons only for priced rows.
    for _, name in pairs(themer.ThemeList) do
        if name == "~" then
            price = false
            separators += 1
        else
            assert(not seen[name], "Duplicate menu theme")
            seen[name] = true
            if paid[name] then
                assert(price, "An original paid theme moved into the free menu section")
            else
                assert(not price, "A free theme moved into the paid menu section")
                assert(originalFree[name] or catppuccin[string.sub(name, 12)], "Unexpected free theme")
            end
        end
    end
    assert(separators == 1)
    for name in paid do assert(seen[name], "Missing original paid theme") end
    for name in originalFree do assert(seen[name], "Missing original free theme") end
    for name in catppuccin do assert(seen["Catppuccin " .. name], "Missing Catppuccin preset") end
end)

test("selecting free presets does not grant original paid theme entitlements", function()
    local themer = newThemer()
    for name in catppuccin do assert(themer:SetTheme("Catppuccin " .. name) == true) end
    for _, name in {"Taiga", "Blush", "Blonde", "Wheat", "Gaia", "Ares", "Aqua", "Energy", "Digital", "Fuchsia"} do
        assert(themer:SetTheme(name) == false)
    end
end)

for _, scaleType in {"Stretch", "Slice", "Tile", "Fit", "Crop"} do
    test("background " .. scaleType .. " with legacy optional resampler applies", function()
        local themer, state = newThemer()
        local originalMain = themer._Theme.main
        local theme = {_bgOuter = {"rbxassetid://123", scaleType, 0.25}}
        assert(themer:SetTheme(theme) == true)
        assert(themer._Theme._bgOuter[2] == scaleType and themer._Theme._bgOuter[3] == 0.25)
        assert(themer._Theme._bgOuter[4] == nil and themer._Theme.main == originalMain)
        assert(state.callbackTheme == theme)
        theme._bgOuter[1] = "changed-after-call"
        assert(themer._Theme._bgOuter[1] == "rbxassetid://123", "Stored metadata must be copied")
    end)
end

test("Lunar keeps all four background fields", function()
    local themer, state = newThemer()
    assert(themer:SetTheme("Lunar") == true)
    assert(themer._Theme._bgOuter[1] == "rbxassetid://11869805803")
    assert(themer._Theme._bgOuter[2] == "Fit" and themer._Theme._bgOuter[4] == "Pixelated")
    assert(state.callbackTheme._bgOuter[4] == "Pixelated")
end)

for _, name in {"Taiga", "Blush", "Blonde", "Wheat", "Gaia", "Ares", "Aqua", "Energy", "Digital", "Fuchsia"} do
    test("unavailable named theme " .. name .. " remains unavailable", function()
        local themer, state, globals = newThemer()
        local previousMain = themer._Theme.main
        assert(themer:SetTheme(name) == false)
        assert(themer._Theme.main == previousMain and state.paintCalls == 0 and state.callbacks == 0)
        assert(globals.Mouse.Icon == "original-cursor")
    end)
end

test("existing AddTheme registration still activates deferred selection", function()
    local themer, state = newThemer()
    local button = {price_frame = {Icon = {}, Label = {}}}
    themer.theme_buttons.Taiga = {button}
    assert(themer:SetTheme("Taiga") == false)
    themer:AddTheme("Taiga")
    assert(colorMatches(themer._Theme.main, themer._BuiltInThemes.Taiga.main))
    assert(state.paintCalls == 1 and state.callbacks == 1 and state.noTween == false)
    assert(button.price_frame.Icon.TextTransparency == 1 and button.price_frame.Label.TextTransparency == 1)
end)

local malformed = {
    {"boolean theme", false},
    {"numeric theme", 1},
    {"empty theme", {}},
    {"array theme", {{0, 0, 0}}},
    {"unknown field", {madeUp = {1, 2, 3}}},
    {"unknown metadata", {_madeUp = 1}},
    {"scalar color", {main = 1}},
    {"string color component", {main = {"1", 2, 3}}},
    {"missing color component", {main = {1, 2}}},
    {"extra color component", {main = {1, 2, 3, 4}}},
    {"dictionary color", {main = {r = 1, g = 2, b = 3}}},
    {"negative color", {main = {-1, 2, 3}}},
    {"oversized color", {main = {256, 2, 3}}},
    {"NaN color", {main = {0/0, 2, 3}}},
    {"infinite color", {main = {math.huge, 2, 3}}},
    {"scalar background", {_bgOuter = false}},
    {"invalid background image", {_bgOuter = {123, "Crop", 1}}},
    {"missing background scale", {_bgOuter = {"image"}}},
    {"invalid background scale", {_bgOuter = {"image", "Unknown", 1}}},
    {"invalid background opacity type", {_bgOuter = {"image", "Crop", "1"}}},
    {"negative opacity", {_bgOuter = {"image", "Crop", -0.1}}},
    {"oversized opacity", {_bgOuter = {"image", "Crop", 1.1}}},
    {"NaN opacity", {_bgOuter = {"image", "Crop", 0/0}}},
    {"infinite opacity", {_bgOuter = {"image", "Crop", math.huge}}},
    {"invalid resampler", {_bgOuter = {"image", "Crop", 1, "Unknown"}}},
    {"false resampler", {_bgOuter = {"image", "Crop", 1, false}}},
    {"extra background component", {_bgOuter = {"image", "Crop", 1, "Default", 5}}},
    {"valid and invalid colors", {main = {1, 2, 3}, second = {4, 5, 6}, text = {false, 2, 3}}},
    {"valid color and invalid background", {main = {1, 2, 3}, _bgOuter = {"image", "Bogus", 1}}},
}
for _, case in malformed do
    test("reject " .. case[1] .. " before any state change", function()
        local themer, state, globals, painted = newThemer()
        local oldTheme = table.clone(themer._Theme)
        local oldPaint = painted.BackgroundColor3
        local applied, message = themer:SetTheme(case[2])
        assert(applied == false and type(message) == "string" and #message > 0)
        for key, value in oldTheme do assert(themer._Theme[key] == value, "Changed " .. key) end
        assert(painted.BackgroundColor3 == oldPaint)
        assert(state.callbacks == 0 and state.paintCalls == 0)
        assert(globals.Mouse.Icon == "original-cursor")
    end)
end

local function newThemeEditor(themer, decoded, decodeFails)
    local Import = {Value = "", calls = 0}
    function Import:Set(value) self.Value = value; self.calls += 1 end
    local Color = {calls = 0}
    function Color:Set(value) self.Value = value; self.calls += 1 end
    local TargetColor = {Value = "main"}
    local ImageId, BGScaling, Resize, Opacity = {}, {}, {}, {}
    local game = {}
    function game:GetService(name)
        assert(name == "HttpService")
        return {JSONDecode = function()
            if decodeFails then error("Mock JSON parse failure") end
            return decoded
        end}
    end
    local Win = {g_e = {Export = {}, Save = {}}, Close = function() end}
    local _G = {MoonGlobal = {
        Themer = themer,
        WindowData = {new = function() return {} end},
        Window = {new = function() return Win end},
    }}
    local script = {Contents = {}, Name = "EditTheme"}
    local Color3 = {new = function() return {} end}
    local control = {new = function() return {} end}
    local Tabs, ListInput, ColorInput, Button, TextInput, NumberInput = control, control, control, control, control, control
    -- The original module writes EncodeTheme in its environment. Keep that
    -- binding local so each mocked editor stays isolated.
    local EncodeTheme
    (function()
-- THEME_EDITOR_SOURCE_INSERTION_POINT
    end)()
    return Import, Color
end

test("editor reports a valid imported palette", function()
    local themer = newThemer()
    local import, color = newThemeEditor(themer, catppuccin.Mocha, false)
    import._changed("mock JSON")
    assert(import.Value == "theme applied" and color.calls == 1)
    assert(colorMatches(color.Value, catppuccin.Mocha.main))
end)

test("editor reports malformed theme without a success message", function()
    local themer, state = newThemer()
    local import, color = newThemeEditor(themer, {main = {"bad", 0, 0}}, false)
    import._changed("mock JSON")
    assert(import.Value == "Invalid RGB color: main." and color.calls == 0)
    assert(state.paintCalls == 0 and state.callbacks == 0)
end)

test("editor retains JSON parse failure handling", function()
    local themer, state = newThemer()
    local import, color = newThemeEditor(themer, nil, true)
    import._changed("mock invalid JSON")
    assert(import.Value == "failed..." and color.calls == 0)
    assert(state.paintCalls == 0 and state.callbacks == 0)
end)

print("THEME TESTS: " .. checks .. " passed with mocked Roblox APIs; Studio not tested")

-- Focused editor tests with the real reviewed InputBox/TextInput/MultiInput/
-- TimeInput modules. Roblox signals, UI objects, history, and the separately
-- tested MarkerTrack command API are inert mocks. No Studio layout is claimed.
local passed = 0
local function test(name, callback)
    local ok, err = pcall(callback)
    assert(ok, name .. ": " .. tostring(err))
    passed += 1
    print("PASS " .. name)
end

local BEGIN = '{"version":1,"actions":[{"op":"sound.play","target":["Head","Footstep"]}]}'
local END = '{"version":1,"actions":[{"op":"sound.stop","target":["Head","Footstep"]}]}'
local OTHER = '{"version":1,"actions":[{"op":"particle.emit","target":["Muzzle","Flash"],"count":12}]}'
local EMPTY = '{"version":1,"actions":[]}'
local validSources = {[BEGIN]=true, [END]=true, [OTHER]=true, [EMPTY]=true}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback) table.insert(callbacks, callback); return {Disconnect=function() end} end,
        Fire = function(_, ...) for _, callback in ipairs(callbacks) do callback(...) end end,
    }
end

local function textBox(state)
    local values, signals = {Text="", PlaceholderText=""}, {}
    local box = {FocusLost=signal(), focused=false}
    function box:GetPropertyChangedSignal(property)
        if not signals[property] then signals[property] = signal() end
        return signals[property]
    end
    function box:IsFocused() return self.focused end
    function box:CaptureFocus() self.focused = true end
    function box:ReleaseFocus()
        if not self.focused then return end
        self.focused = false
        if state.deferFocusLost then
            table.insert(state.deferred, function() self.FocusLost:Fire() end)
        else
            self.FocusLost:Fire()
        end
    end
    return setmetatable(box, {
        __index = function(_, key) return values[key] end,
        __newindex = function(_, key, value)
            local changed = values[key] ~= value
            values[key] = value
            if changed and signals[key] then
                if state.deferTextChanged then
                    table.insert(state.deferred, function() signals[key]:Fire() end)
                else
                    signals[key]:Fire()
                end
            end
        end,
    })
end

local function inputUI(name, state)
    return {Name=name, ClassName="Frame", Frame={BG={UIStroke={}}, Input=textBox(state)}}
end

local function buttonUI(name, parent)
    local button = {Name=name, Parent=parent, Label={Text="OK"}, BG={UIStroke={}}, AutoButtonColor=true}
    function button:Clone()
        local result = buttonUI(self.Name, self.Parent)
        result.Label.Text = self.Label.Text
        result.Size, result.LayoutOrder = self.Size, self.LayoutOrder
        return result
    end
    return button
end

local function inputClasses(globals)
    local _G = {MoonGlobal=globals}
    local base = {}
    function base:new(UI)
        return {type={}, UI=UI, AddPaintedItem=function() end, SetItemPaint=function() end}
    end
    local InputBox = (function()
        local super, script = base, {Name="InputBox"}
-- INPUT_BOX_SOURCE_INSERTION_POINT
    end)()
    local TextInput = (function()
        local super, script = InputBox, {Name="TextInput"}
-- TEXT_INPUT_SOURCE_INSERTION_POINT
    end)()
    local MultiInput = (function()
        local super, script = InputBox, {Name="MultiInput"}
-- MULTI_INPUT_SOURCE_INSERTION_POINT
    end)()
    local TimeInput = (function()
        local super, script = InputBox, {Name="TimeInput"}
-- TIME_INPUT_SOURCE_INSERTION_POINT
    end)()
    return TextInput, MultiInput, TimeInput
end

local function newEditor(definitions)
    local state = {
        controls={}, markers={}, actions={}, popups={}, calls={}, grants={},
        approved={}, revoked={}, validated={}, deferred={}, open=false,
        bindingRevision=0,
    }
    local globals = {
        class={Marker="Marker", MarkerTrack="MarkerTrack"}, MAX_FRAMES=30000,
        current_fps=30, BLANK_FUNC=function() end, req=function() end,
        deepcopy=copy, format_number=tostring, Themer={QUICK_TWEEN=0.06},
        objIsType=function(item, name) return name == "Marker" and item.isMarker end,
        GuiLib={AddInput=function(_, UI, bindings)
            if bindings.focus_lost then UI.FocusLost:Connect(bindings.focus_lost.func) end
        end},
        TimeConvert=function(value, from, to, fps)
            if from == "s" and to == "f" then return value * fps end
            if from == "f" and to == "t" then return tostring(value) .. "f" end
            if from == "t" and to == "f" then return tonumber(string.match(value, "(%d+)$")) end
            error("Unexpected mocked time conversion")
        end,
    }
    local MarkerTrackModule = {}
    function MarkerTrackModule.ValidateCommands(text)
        table.insert(state.validated, text)
        if type(text) == "string" then
            local trimmed = text:match("^%s*(.-)%s*$")
            if trimmed == "" or validSources[trimmed] then return true end
        end
        return false, "Expected version 1 JSON commands."
    end
    local track = {}
    function track:GetNextTrackItem() return nil end
    function track:IsMarkerApproved(marker)
        local grant = state.grants[marker]
        if grant and (grant[1] ~= marker.codeBegin or grant[2] ~= marker.codeEnd
            or grant[3] ~= state.bindingRevision) then
            state.grants[marker] = nil
            grant = nil
        end
        return grant ~= nil
    end
    function track:ApproveMarkerCommands(marker)
        table.insert(state.calls, "approve:" .. marker.id)
        table.insert(state.approved, marker)
        assert(#state.actions > 0, "Approval must follow the save action")
        if state.throwApprovalFor == marker then error("Mock approval exception") end
        if state.failApprovalFor == marker then
            state.grants[marker] = nil
            return false, "Target was not found in this event's item."
        end
        for _, text in {marker.codeBegin, marker.codeEnd} do
            local valid, err = MarkerTrackModule.ValidateCommands(text)
            if not valid then return false, err end
        end
        state.grants[marker] = {marker.codeBegin, marker.codeEnd, state.bindingRevision}
        return true
    end
    function track:RevokeMarkerCommands(marker)
        table.insert(state.calls, "revoke:" .. marker.id)
        table.insert(state.revoked, marker)
        state.grants[marker] = nil
    end
    for index, definition in ipairs(definitions or {{}}) do
        local marker = {
            id=tostring(index), isMarker=true, ParentTrack=track, frm_pos=index*10,
            width=3, name="Event " .. index, codeBegin=BEGIN, codeEnd=END, KFMarkers={{"Footstep", "left"}},
        }
        for key, value in pairs(definition) do marker[key] = value end
        table.insert(state.markers, marker)
        if definition.initiallyApproved then state.grants[marker] = {marker.codeBegin, marker.codeEnd, state.bindingRevision} end
    end
    local selection = {
        TrackItemTypeMap={Marker=true}, SelectedTrackItems={Objects=state.markers}, LayerSystem={length=300},
    }
    local Win = {g_e={}}
    local buttonsParent = {}
    Win.g_e.Confirm = buttonUI("Confirm", buttonsParent)
    Win.g_e.Tabs = {Name="Tabs", Tabs={CodeBegin={Label={}}, CodeEnd={Label={}}}}
    for _, name in {"MarkerName", "Width", "EndTime", "BeginCodeInput", "EndCodeInput"} do
        Win.g_e[name] = inputUI(name, state)
    end
    Win.g_e.KeyValueList = {Name="KeyValueList"}
    function Win:Close(save)
        local closed = self.OnClose(save)
        if closed then state.open = false end
        state.lastCloseResult = closed
        return closed
    end
    globals.WindowData = {new=function(_, title) return {title=title} end}
    globals.Window = {new=function(_, _, data) state.windowTitle=data.title; return Win end}
    globals.Windows = {
        MsgBox={Popup=function(window, args) assert(window == Win); table.insert(state.popups, args) end},
        MoonAnimator={g_e={LayerSystem={SelectionHandler=selection}}, DoCompositeAction=function(name, changes)
            assert(name == "EditMarkers")
            table.insert(state.calls, "save")
            if state.throwSave then error("Mock history exception") end
            if state.refuseSave then return false end
            local saved = table.clone(changes)
            saved.TargetMarkers = table.clone(changes.TargetMarkers)
            table.insert(state.actions, saved)
            for _, marker in ipairs(changes.TargetMarkers) do
                for key, value in pairs(changes) do
                    if key ~= "TargetMarkers" then marker[key] = value end
                end
            end
            if state.revokeDuringSave then track:RevokeMarkerCommands(state.revokeDuringSave) end
            -- Actual DoCompositeAction returns nil when it succeeds.
        end},
    }

    local MarkerName, Width, EndTime, BeginCodeInput, EndCodeInput, KeyValueList
    local actualText, actualMulti, actualTime = inputClasses(globals)
    local function bind(UI, control)
        state.controls[UI.Name], Win.g_e[UI.Name] = control, control
        if UI.Name == "MarkerName" then MarkerName = control
        elseif UI.Name == "Width" then Width = control
        elseif UI.Name == "EndTime" then EndTime = control
        elseif UI.Name == "BeginCodeInput" then BeginCodeInput = control
        elseif UI.Name == "EndCodeInput" then EndCodeInput = control end
        return control
    end
    local TextInput = {new=function(_, UI, ...) return bind(UI, actualText:new(UI, ...)) end}
    local MultiInput = {new=function(_, UI, ...) return bind(UI, actualMulti:new(UI, ...)) end}
    local TimeInput = {new=function(_, UI, ...) return bind(UI, actualTime:new(UI, ...)) end}
    local Button = {new=function(_, UI)
        local control = {UI=UI, set_highlight=function(self, value) self.highlight=value end}
        return bind(UI, control)
    end}
    local Tabs = {new=function(_, UI, default)
        local control = {UI=UI, CurrentTab=default, ShowTab=function(self, name) self.CurrentTab=name end}
        return bind(UI, control)
    end}
    KeyValueList = {new=function(_, UI, list, changed)
        local control = {UI=UI, List=list, _changed=changed, SetList=function(self, value) self.List=value end}
        KeyValueList = bind(UI, control)
        return control
    end}
    local _G = {MoonGlobal=globals}
    local require = function(module)
        if module == "Marker" then return {} end
        assert(module == "MarkerTrack")
        return MarkerTrackModule
    end
    local script = {Name="EditMarkers", Contents={}}
    local UDim2 = {new=function(xs, xo, ys, yo) return {X={Scale=xs,Offset=xo}, Y={Scale=ys,Offset=yo}} end}
    local editor = (function()
-- EDIT_MARKERS_SOURCE_INSERTION_POINT
    end)()
    function state:openEditor()
        self.open = editor.OnOpen()
        return self.open
    end
    function state:toggle() self.controls.PreviewSession.OnClick() end
    function state:save() self.controls.Confirm.OnClick(); return self.lastCloseResult end
    function state:cancel() return editor:Close(false) end
    function state:type(name, value)
        local input = self.controls[name].UI.Frame.Input
        input:CaptureFocus()
        input.Text = value
        return input
    end
    function state:preview() return self.controls.PreviewSession.UI.Label.Text == "Preview: ON" end
    function state:flushFocus()
        local callbacks = self.deferred
        self.deferred = {}
        for _, callback in ipairs(callbacks) do callback() end
    end
    state.track, state.selection, state.editor = track, selection, editor
    return state
end

test("opening imported commands is OFF and adds only local UI controls", function()
    local state = newEditor()
    assert(state:openEditor() and not state:preview())
    assert(#state.approved == 0 and #state.actions == 0 and #state.revoked == 0)
    assert(state.controls.Confirm.UI.Label.Text == "Save")
    assert(state.controls.PreviewSession.UI.Size.X.Scale == 0.5)
    assert(state.controls.Confirm.UI.Size.X.Offset == -4)
    assert(state.controls.Tabs.UI.Tabs.CodeBegin.Label.Text == "On Begin")
    assert(state.controls.Tabs.UI.Tabs.CodeEnd.Label.Text == "On End")
    assert(string.find(state.controls.BeginCodeInput.UI.Frame.Input.PlaceholderText, '"particle.emit"', 1, true))
    assert(string.find(state.windowTitle, "session", 1, true))
end)

test("toggle ON is a draft choice and Cancel never approves", function()
    local state = newEditor()
    assert(state:openEditor())
    state:toggle()
    assert(state:preview() and #state.approved == 0 and #state.actions == 0)
    assert(state:cancel() and #state.approved == 0 and #state.actions == 0 and #state.revoked == 0)
end)

test("Save ON commits focused text before granting session approval", function()
    local state = newEditor()
    state:openEditor()
    state:type("BeginCodeInput", OTHER)
    assert(state.controls.BeginCodeInput.Value == BEGIN)
    state:toggle()
    assert(state:preview() and state.controls.BeginCodeInput.Value == OTHER and #state.approved == 0)
    assert(state:save())
    assert(state.markers[1].codeBegin == OTHER and state.grants[state.markers[1]][1] == OTHER)
    assert(state.calls[1] == "save" and state.calls[2] == "approve:1")
end)

test("all previously approved markers open ON without creating new grants", function()
    local state = newEditor({{initiallyApproved=true}, {initiallyApproved=true}})
    assert(state:openEditor() and state:preview() and #state.approved == 0)
    state:toggle()
    assert(not state:preview())
    assert(state:cancel())
    for _, marker in ipairs(state.markers) do assert(state.track:IsMarkerApproved(marker)) end
    assert(#state.revoked == 0)
end)

test("saving inherited ON preserves existing approval without renewing it", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    local grant = state.grants[state.markers[1]]
    state:type("MarkerName", "Rename only")
    assert(state:save() and state.markers[1].name == "Rename only")
    assert(#state.approved == 0 and state.grants[state.markers[1]] == grant)
end)

test("external source changes cannot be hidden by an inherited or new opt-in", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    state.markers[1].codeBegin = OTHER
    state:type("MarkerName", "Rename only")
    assert(not state:save() and state.open and not state:preview())
    assert(#state.actions == 0 and #state.approved == 0)
    state:toggle()
    assert(not state:preview() and #state.approved == 0)
    assert(string.find(state.popups[1].Content, "Close and reopen", 1, true))
    state:cancel()
    state:openEditor()
    assert(state.controls.BeginCodeInput.Value == OTHER and not state:preview())
    state:toggle()
    assert(state:save() and state.track:IsMarkerApproved(state.markers[1]) and #state.approved == 1)
end)

for _, kind in {"revocation", "scene binding change"} do
    test("inherited ON cannot silently renew after " .. kind, function()
        local state = newEditor({{initiallyApproved=true}})
        state:openEditor()
        if kind == "revocation" then
            state.track:RevokeMarkerCommands(state.markers[1])
        else
            state.bindingRevision += 1
        end
        state:type("MarkerName", "Rename only")
        assert(not state:save() and state.open and not state:preview())
        assert(#state.actions == 0 and #state.approved == 0 and not state.track:IsMarkerApproved(state.markers[1]))
        state:toggle()
        assert(state:preview() and state:save() and #state.approved == 1)
        assert(state.track:IsMarkerApproved(state.markers[1]))
    end)
end

test("revocation during a rename commit is not silently renewed", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    state.revokeDuringSave = state.markers[1]
    state:type("MarkerName", "Saved rename")
    assert(not state:save() and state.open and not state:preview())
    assert(#state.actions == 1 and state.markers[1].name == "Saved rename" and #state.approved == 0)
    assert(not state.track:IsMarkerApproved(state.markers[1]))
end)

test("stale inherited batch approval does not revoke other grants before an OFF save", function()
    local state = newEditor({{initiallyApproved=true}, {initiallyApproved=true}})
    state:openEditor()
    state.track:RevokeMarkerCommands(state.markers[1])
    assert(not state:save() and #state.approved == 0)
    assert(state.track:IsMarkerApproved(state.markers[2]))
    assert(state:cancel() and state.track:IsMarkerApproved(state.markers[2]))
end)

test("mixed approval opens OFF and Cancel preserves existing grants", function()
    local state = newEditor({{initiallyApproved=true}, {}})
    assert(state:openEditor() and not state:preview())
    state:cancel()
    assert(state.track:IsMarkerApproved(state.markers[1]) and not state.track:IsMarkerApproved(state.markers[2]))
    assert(#state.approved == 0 and #state.revoked == 0)
end)

test("source edits reset preview OFF and Save OFF revokes prior grants", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    assert(state:preview())
    state:type("BeginCodeInput", OTHER)
    assert(not state:preview())
    assert(state:save() and state.markers[1].codeBegin == OTHER)
    assert(#state.approved == 0 and #state.revoked == 1 and not state.track:IsMarkerApproved(state.markers[1]))
end)

test("an edit after explicit ON requires another opt-in", function()
    local state = newEditor()
    state:openEditor()
    state:toggle()
    state:type("EndCodeInput", EMPTY)
    assert(not state:preview())
    assert(state:save() and state.markers[1].codeEnd == EMPTY and #state.approved == 0)
end)

test("Save captures latest focused source even with deferred FocusLost", function()
    local state = newEditor()
    state.deferFocusLost = true
    state:openEditor()
    state:type("BeginCodeInput", OTHER)
    assert(state:save())
    assert(state.markers[1].codeBegin == OTHER and #state.approved == 0)
    state:flushFocus()
    assert(state.markers[1].codeBegin == OTHER)
end)

for _, flushBeforeSave in {false, true} do
    test("source opt-in survives deferred Text signals, flush before Save=" .. tostring(flushBeforeSave), function()
        local state = newEditor()
        state:openEditor()
        state.deferTextChanged = true
        state.deferFocusLost = true
        state:type("BeginCodeInput", "  " .. OTHER .. "\n")
        state:toggle()
        assert(state:preview() and #state.approved == 0)
        if flushBeforeSave then state:flushFocus() end
        assert(state:preview(), "Queued notifications for synchronized text must not revoke the draft choice")
        assert(state:save() and #state.approved == 1)
        assert(state.markers[1].codeBegin == OTHER and state.track:IsMarkerApproved(state.markers[1]))
        state:flushFocus()
        assert(state.track:IsMarkerApproved(state.markers[1]))
    end)
end

test("a newer source edit still requires consent when Text signals are deferred", function()
    local state = newEditor()
    state:openEditor()
    state.deferTextChanged = true
    state:type("BeginCodeInput", OTHER)
    state:toggle()
    assert(state:preview())
    state:type("EndCodeInput", EMPTY)
    assert(state:save() and #state.approved == 0)
    assert(state.markers[1].codeEnd == EMPTY and not state.track:IsMarkerApproved(state.markers[1]))
end)

test("clicking an ON toggle still means OFF when a source notification was deferred", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    state.deferTextChanged = true
    state:type("BeginCodeInput", OTHER)
    assert(state:preview(), "Fixture requires the old ON label before its queued signal")
    state:toggle()
    assert(not state:preview() and state:save() and #state.approved == 0)
    assert(state.markers[1].codeBegin == OTHER and not state.track:IsMarkerApproved(state.markers[1]))
end)

for _, name in {"BeginCodeInput", "EndCodeInput"} do
    test("invalid edited " .. name .. " blocks Save and keeps editor open", function()
        local state = newEditor()
        state:openEditor()
        state:type(name, "this is not JSON")
        assert(not state:save() and state.open)
        assert(#state.actions == 0 and #state.approved == 0 and #state.popups == 1)
        assert(state.markers[1].codeBegin == BEGIN and state.markers[1].codeEnd == END)
    end)
end

test("unchanged legacy Lua can be renamed while its exact bytes remain inert", function()
    local legacy = "  print('legacy')\n"
    local state = newEditor({{codeBegin=legacy, codeEnd="other legacy text"}})
    state:openEditor()
    state.controls.BeginCodeInput.UI.Frame.Input:CaptureFocus()
    state.controls.BeginCodeInput.UI.Frame.Input:ReleaseFocus()
    state:type("MarkerName", "Renamed event")
    assert(state:save())
    assert(state.markers[1].name == "Renamed event" and state.markers[1].codeBegin == legacy)
    assert(state.actions[1].codeBegin == nil and state.actions[1].codeEnd == nil)
    assert(#state.approved == 0 and #state.popups == 0)
end)

test("legacy Lua cannot enable preview and receives a clear validation message", function()
    local state = newEditor({{codeBegin="print('legacy')"}})
    state:openEditor()
    state:toggle()
    assert(not state:preview() and #state.approved == 0 and #state.actions == 0)
    assert(#state.popups == 1 and string.find(state.popups[1].Content, "Preview OFF", 1, true))
    assert(state.open)
end)

test("untouched mixed '-' placeholders never overwrite individual fields", function()
    local state = newEditor({{codeBegin=BEGIN,codeEnd=END,width=3}, {codeBegin=OTHER,codeEnd="legacy",width=8}})
    state:openEditor()
    for _, name in {"MarkerName", "BeginCodeInput", "EndCodeInput"} do
        local input = state.controls[name].UI.Frame.Input
        assert(input.Text == "-")
        input:CaptureFocus()
        input:ReleaseFocus()
        assert(state.controls[name].Value == "-", "Fixture must exercise actual focus-loss sentinel conversion")
    end
    assert(state:save())
    local action = state.actions[1]
    assert(action.name == nil and action.codeBegin == nil and action.codeEnd == nil and action.width == nil)
    assert(state.markers[1].codeBegin == BEGIN and state.markers[2].codeBegin == OTHER)
    assert(state.markers[2].codeEnd == "legacy" and state.markers[2].width == 8)
end)

test("editing one mixed source changes only that field for all selected markers", function()
    local state = newEditor({{codeBegin=BEGIN,codeEnd=END}, {codeBegin=OTHER,codeEnd=EMPTY}})
    state:openEditor()
    state:type("BeginCodeInput", EMPTY)
    state:toggle()
    assert(state:preview() and state:save())
    assert(state.actions[1].codeEnd == nil)
    assert(state.markers[1].codeBegin == EMPTY and state.markers[2].codeBegin == EMPTY)
    assert(state.markers[1].codeEnd == END and state.markers[2].codeEnd == EMPTY)
    assert(state.track:IsMarkerApproved(state.markers[1]) and state.track:IsMarkerApproved(state.markers[2]))
end)

test("mixed selection containing legacy source cannot collectively enable preview", function()
    local state = newEditor({{}, {codeBegin="legacy"}})
    state:openEditor()
    state:toggle()
    assert(not state:preview() and #state.approved == 0 and #state.actions == 0 and #state.popups == 1)
end)

test("partial approval failure revokes the whole selected batch and keeps edits saved", function()
    local state = newEditor({{}, {}, {initiallyApproved=true}})
    state.failApprovalFor = state.markers[2]
    state:openEditor()
    state:type("BeginCodeInput", OTHER)
    state:toggle()
    assert(not state:save() and state.open and not state:preview())
    assert(#state.approved == 2 and #state.revoked == 3 and #state.actions == 1)
    for _, marker in ipairs(state.markers) do
        assert(marker.codeBegin == OTHER and not state.track:IsMarkerApproved(marker))
    end
    assert(string.find(state.popups[1].Content, "Changes were saved", 1, true))
    assert(state:save(), "Retry OFF should close without granting")
    assert(state.actions[2].codeBegin == nil, "Retry must use the already saved source as its baseline")
    assert(#state.approved == 2)
end)

test("approval exceptions also revoke partial grants and leave editor open", function()
    local state = newEditor({{}, {}})
    state.throwApprovalFor = state.markers[2]
    state:openEditor()
    state:toggle()
    assert(not state:save() and state.open and #state.revoked == 2)
    for _, marker in ipairs(state.markers) do assert(not state.track:IsMarkerApproved(marker)) end
end)

for _, failure in {"refuseSave", "throwSave"} do
    test(failure .. " never grants approval and keeps editor open", function()
        local state = newEditor()
        state[failure] = true
        state:openEditor()
        state:toggle()
        assert(not state:save() and state.open and #state.approved == 0 and #state.popups == 1)
    end)
end

test("Cancel after source editing preserves stored text and its existing grant", function()
    local state = newEditor({{initiallyApproved=true}})
    state:openEditor()
    state:type("BeginCodeInput", OTHER)
    assert(not state:preview())
    assert(state:cancel())
    assert(state.markers[1].codeBegin == BEGIN and state.track:IsMarkerApproved(state.markers[1]))
    assert(#state.actions == 0 and #state.revoked == 0)
end)

test("focused width text keeps TimeInput seconds-to-frames semantics", function()
    local state = newEditor()
    state:openEditor()
    state:type("Width", "2")
    assert(state:save() and state.markers[1].width == 60)
end)

test("focused end-time text updates the stored width before Save", function()
    local state = newEditor()
    state:openEditor()
    state:type("EndTime", "40f")
    assert(state:save() and state.markers[1].width == 30)
end)

for _, input in {{name="Width", text="2", width=60}, {name="EndTime", text="40f", width=30}} do
    test("deferred Text signals preserve focused " .. input.name .. " changes", function()
        local state = newEditor()
        state:openEditor()
        state.deferTextChanged = true
        state.deferFocusLost = true
        state:type(input.name, input.text)
        assert(state:save() and state.markers[1].width == input.width)
        state:flushFocus()
        assert(state.markers[1].width == input.width)
    end)
end

test("empty commands can be explicitly saved and approved as no-ops", function()
    local state = newEditor()
    state:openEditor()
    state:type("BeginCodeInput", "")
    state:type("EndCodeInput", "")
    state:toggle()
    assert(state:save() and state.track:IsMarkerApproved(state.markers[1]))
    assert(state.markers[1].codeBegin == "" and state.markers[1].codeEnd == "")
end)

test("ordinary animation marker list edits still save independently of preview", function()
    local state = newEditor()
    state:openEditor()
    state.controls.KeyValueList.List = {{"Sound", "boot"}}
    state.controls.KeyValueList._changed()
    assert(state:save() and state.markers[1].KFMarkers[1][2] == "boot")
    assert(#state.approved == 0)
end)

test("opening again resets stale selection and draft consent", function()
    local state = newEditor({{}, {}})
    state:openEditor()
    state:toggle()
    state:cancel()
    state.selection.SelectedTrackItems.Objects = {state.markers[2]}
    assert(state:openEditor() and not state:preview())
    assert(state:save() and #state.actions[1].TargetMarkers == 1)
    assert(state.actions[1].TargetMarkers[1] == state.markers[2])
end)

test("empty or non-marker selection does not open the editor", function()
    local state = newEditor({})
    assert(not state:openEditor())
    state.selection.TrackItemTypeMap.Marker = nil
    assert(not state:openEditor() and #state.approved == 0)
end)

print(string.format("EditMarkers: %d behavior tests passed with mocked UI; Studio layout not tested", passed))

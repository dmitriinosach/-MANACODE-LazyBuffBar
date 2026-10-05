local ADDON, ns = ...
ns.Settings = {}
local W = 380
local PAD = 14
local COL2 = W - PAD
local GAP = 10
local INSET = 12
local CAP_H = 26
local ROW = 26
local CHECK_SZ = 20
local SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }
local REPEATS = { 2, 3, 5, 10, 15 }
local win
local checks = {}
local strips = {}
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function rebuffKnob()
    for _, w in ipairs((ns.Watchers and ns.Watchers()) or {}) do
        if w.id == "rebuff" then return w.knobs and w.knobs[1] end
    end
    return nil
end
local function checkRow(panel, y, label, tip, get, set)
    local c = ns.MakeCheck(panel)
    c:SetWidth(CHECK_SZ)
    c:SetHeight(CHECK_SZ)
    c:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    c.label:SetText(label)
    c.label:Show()
    c.tip = tip
    c.onToggle = function(on)
        set(on)
        ns.Settings.Refresh()
    end
    checks[#checks + 1] = { frame = c, get = get }
    return y + ROW
end
local function strip(panel, y, list, label, get, apply)
    local made = {}
    local room = W - PAD * 2 - INSET
    local x = INSET
    for _, value in ipairs(list) do
        local v = value
        local b = ns.MakeButton(panel)
        b:SetLabel(label(v))
        if x > INSET and x + b:GetWidth() > room then
            x = INSET
            y = y + ROW
        end
        b:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
        b.value = v
        b.onClick = function()
            apply(v)
            ns.Settings.Refresh()
        end
        made[#made + 1] = b
        x = x + b:GetWidth() + 4
    end
    strips[#strips + 1] = { buttons = made, get = get }
    return y + ROW
end
local function noteHeight(fs)
    local room = W - PAD * 2 - INSET * 2
    local lines = math.ceil((fs:GetStringWidth() or 0) / room)
    if lines < 1 then lines = 1 end
    local h = lines * (fs:GetStringHeight() or 12)
    local own = fs:GetHeight() or 0
    return (own > h) and own or h
end
local function note(panel, y, text)
    local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    fs:SetWidth(W - PAD * 2 - INSET * 2)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return y + noteHeight(fs) + 8
end
local function button(panel, y, x, label, tip, onClick)
    local b = ns.MakeButton(panel)
    b:SetLabel(label)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", x or INSET, -y)
    b.tip = tip
    b.onClick = onClick
    return y + ROW, b
end
local resetBtn
local takeBtn, giveBtn
local BAR_STEP_W = 28
local BAR_NAME_W = 74
local BAR_VALUE_W = 54
local barsPanel
local sideBottom = 0
local barsNote
local barsTop = 0
local addBtn
local barRows = {}
local function acquireBarRow(n)
    local r = barRows[n]
    if r then return r end
    local f = CreateFrame("Frame", nil, barsPanel)
    f:SetWidth(W - PAD * 2 - INSET * 2)
    f:SetHeight(ROW)
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    f:SetScript("OnLeave", function() ns.TipHide() end)
    r = { frame = f, id = n, perRow = 0 }
    r.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", f, "LEFT", 0, 0)
    r.name:SetWidth(BAR_NAME_W)
    r.name:SetJustifyH("LEFT")
    r.less = ns.MakeButton(f)
    r.less:SetLabel("-")
    r.less:SetWidth(BAR_STEP_W)
    r.less:SetPoint("LEFT", f, "LEFT", BAR_NAME_W, 0)
    r.less.onClick = function()
        ns.buffbar:SetPerRow(r.id, r.perRow - 1)
        ns.Settings.Refresh()
    end
    r.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.value:SetPoint("LEFT", r.less, "RIGHT", 4, 0)
    r.value:SetWidth(BAR_VALUE_W)
    r.value:SetJustifyH("CENTER")
    r.more = ns.MakeButton(f)
    r.more:SetLabel("+")
    r.more:SetWidth(BAR_STEP_W)
    r.more:SetPoint("LEFT", r.value, "RIGHT", 4, 0)
    r.more.onClick = function()
        ns.buffbar:SetPerRow(r.id, r.perRow + 1)
        ns.Settings.Refresh()
    end
    r.kill = ns.MakeButton(f)
    r.kill:SetLabel(ns.T("settings.bar_kill"))
    r.kill:SetPoint("LEFT", r.more, "RIGHT", 10, 0)
    r.kill.onClick = function()
        if ns.buffbar:RemoveBar(r.id) then ns.Settings.Refresh() end
    end
    r.look = ns.MakeButton(f)
    r.look:SetLabel(ns.T("settings.bar_look"))
    r.look.tip = ns.T("settings.bar_look_tip")
    r.look:SetPoint("LEFT", r.kill, "RIGHT", 6, 0)
    r.look.onClick = function()
        local panel
        for _, p in ipairs(ns.buffbar:Panels()) do
            if p.id == r.id then panel = p.frame end
        end
        ns.BarMenu.Open(r.id, panel)
    end
    barRows[n] = r
    return r
end
local function fillBarRow(r, b, total)
    r.id, r.perRow = b.id, b.perRow
    local rows = b.perRow > 0 and tostring(b.perRow) or ns.T("bar.row_all")
    r.name:SetText(ns.T("settings.bar_n", b.id))
    r.value:SetText(rows)
    r.frame.tipTitle = ns.T("settings.bar_n", b.id)
    local list = table.concat(b.groups, ", ")
    if not b.holds then
        r.frame.tip = ns.T("settings.bar_empty")
    elseif b.empty then
        r.frame.tip = ns.T("settings.bar_silent", list)
    else
        r.frame.tip = ns.T("settings.bar_holds", list)
    end
    r.frame.tipDim = ns.T("settings.bar_rows", rows)
    r.less.tip = ns.T("settings.bar_rows", rows)
    r.more.tip = r.less.tip
    if b.perRow > 0 then r.less:Enable() else r.less:Disable() end
    if not b.empty then
        r.kill.tip = ns.T("settings.bar_kill_no")
        r.kill:Disable()
    elseif total < 2 then
        r.kill.tip = ns.T("settings.bar_kill_last")
        r.kill:Disable()
    else
        r.kill.tip = ns.T("settings.bar_kill_tip")
        r.kill:Enable()
    end
end
local function layoutBars()
    if not barsPanel then return end
    local y = CAP_H
    barsNote:ClearAllPoints()
    barsNote:SetPoint("TOPLEFT", barsPanel, "TOPLEFT", INSET, -y)
    y = y + noteHeight(barsNote) + 8
    local list = ns.buffbar:Bars()
    for i, b in ipairs(list) do
        local r = acquireBarRow(i)
        fillBarRow(r, b, #list)
        r.frame:ClearAllPoints()
        r.frame:SetPoint("TOPLEFT", barsPanel, "TOPLEFT", INSET, -y)
        r.frame:Show()
        y = y + ROW
    end
    for i = #list + 1, #barRows do barRows[i].frame:Hide() end
    addBtn:ClearAllPoints()
    addBtn:SetPoint("TOPLEFT", barsPanel, "TOPLEFT", INSET, -y)
    if ns.buffbar:IsLocked() then addBtn:Disable() else addBtn:Enable() end
    y = y + ROW
    barsPanel:SetHeight(y + 6)
    win:SetHeight(math.max(barsTop + y + 6, sideBottom) + PAD)
    ns.PaintWindow(win)
end
local function section(parent, caption, y, fill, x)
    local p = ns.MakePanel(parent, caption)
    p:SetWidth(W - PAD * 2)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD + (x or 0), -y)
    local h = fill(p, CAP_H)
    p:SetHeight(h + 6)
    return y + h + 6 + GAP
end
local function scaleLabel(v)
    return ns.T("settings.scale_fmt", math.floor(v * 100 + 0.5))
end
local function themeLabel(key)
    local t = ns.themes and ns.themes[key]
    if not t then return key end
    return (t.labelKey and ns.L[t.labelKey]) or t.label or key
end
local function build()
    if win then return end
    win = ns.MakeWindow("LazyBuffBarSettings", ns.T("settings.title"))
    win:SetWidth(W + COL2)
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 2, -PAD)
    win.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
    local pos = db().settingsPos
    if pos then
        win:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        db().settingsPos = { p, rp, x, y }
    end)
    local y = PAD + 26
    y = section(win, ns.T("settings.panel"), y, function(p, ry)
        ry = checkRow(p, ry, ns.T("settings.show"), ns.T("settings.show_tip"),
            function() return ns.buffbar:IsShown() end,
            function(on) ns.buffbar:SetShown(on); ns.Chrome.Apply() end)
        ry = checkRow(p, ry, ns.T("settings.lock"), ns.T("settings.lock_tip"),
            function() return ns.buffbar:IsLocked() end,
            function(on) ns.buffbar:SetLocked(on); ns.Chrome.Apply() end)
        ry, resetBtn = button(p, ry, nil, ns.T("settings.reset"), ns.T("settings.reset_tip"),
            function()
                ns.buffbar:ResetBars()
                ns.Chrome.Apply()
            end)
        return note(p, ry, ns.T("settings.combat_note"))
    end)
    y = section(win, ns.T("settings.scale"), y, function(p, ry)
        ry = strip(p, ry, SCALES, scaleLabel,
            function() return ns.buffbar:GetScale() end,
            function(v) ns.buffbar:SetScale(v); ns.Chrome.Apply() end)
        return note(p, ry, ns.T("settings.scale_note"))
    end)
    local side = PAD + 26
    side = section(win, ns.T("settings.skin"), side, function(p, ry)
        return strip(p, ry, ns.themeOrder or {}, themeLabel,
            function() return ns.SkinKey() end,
            function(key) ns.SetSkin(key) end)
    end, COL2)
    side = section(win, ns.T("settings.look"), side, function(p, ry)
        ry = note(p, ry, ns.T("settings.look_edge"))
        ry = strip(p, ry, ns.Look.ALL.edge.list,
            function(v) return ns.T("settings.edge." .. v) end,
            function() return ns.Look.Get("edge") end,
            function(v) ns.Look.Set("edge", v) end)
        ry = note(p, ry, ns.T("settings.look_plate"))
        ry = strip(p, ry, ns.Look.ALL.plate.list,
            function(v) return ns.T("settings.plate." .. v) end,
            function() return ns.Look.Get("plate") end,
            function(v) ns.Look.Set("plate", v) end)
        ry = note(p, ry, ns.T("settings.look_absent"))
        ry = strip(p, ry, ns.Look.ALL.absent.list, scaleLabel,
            function() return ns.Look.Get("absent") end,
            function(v) ns.Look.Set("absent", v) end)
        ry = note(p, ry, ns.T("settings.look_digits"))
        ry = strip(p, ry, ns.Look.ALL.digits.list,
            function(v) return ns.T("settings.digits." .. v) end,
            function() return ns.Look.Get("digits") end,
            function(v) ns.Look.Set("digits", v) end)
        ry = checkRow(p, ry, ns.T("settings.tint"), ns.T("settings.tint_tip"),
            function() return ns.Look.Get("tint") end,
            function(on) ns.Look.Set("tint", on) end)
        return checkRow(p, ry, ns.T("settings.snap"), ns.T("settings.snap_tip"),
            function() return ns.Look.Get("snap") end,
            function(on) ns.Look.Set("snap", on) end)
    end, COL2)
    side = section(win, ns.T("profile.title"), side, function(p, ry)
        ry = checkRow(p, ry, ns.T("profile.own"), ns.T("profile.own_tip"),
            function() return ns.Profile.IsOwn() end,
            function(on) ns.Profile.SetOwn(on) end)
        local _, b = button(p, ry, nil, ns.T("profile.take"), ns.T("profile.take_tip"),
            function() ns.Profile.TakeShared(); ns.Settings.Refresh() end)
        takeBtn = b
        ry, giveBtn = button(p, ry, INSET + takeBtn:GetWidth() + 6, ns.T("profile.give"), ns.T("profile.give_tip"),
            function()
                if ns.Profile.MakeShared() and ns.say then ns.say(ns.T("profile.given")) end
            end)
        return note(p, ry, ns.T("profile.note"))
    end, COL2)
    sideBottom = side - GAP
    local knob = rebuffKnob()
    y = section(win, ns.T("settings.watch"), y, function(p, ry)
        ry = checkRow(p, ry, ns.T("notify.watch.rebuff.check"),
            ns.T("notify.watch.rebuff.note"),
            function() return ns.WatchEnabled("rebuff") end,
            function(on) ns.SetWatchEnabled("rebuff", on) end)
        if not knob then return ry end
        ry = note(p, ry, ns.T("notify.watch.rebuff.every_note"))
        return strip(p, ry, REPEATS,
            function(v) return ns.T("settings.minutes_fmt", v) end,
            knob.get, knob.set)
    end)
    barsTop = y
    y = section(win, ns.T("settings.bars"), y, function(p, ry)
        barsPanel = p
        barsNote = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        barsNote:SetWidth(W - PAD * 2 - INSET * 2)
        barsNote:SetJustifyH("LEFT")
        barsNote:SetText(ns.T("settings.bars_note"))
        addBtn = ns.MakeButton(p)
        addBtn:SetLabel(ns.T("settings.bar_add"))
        addBtn.tip = ns.T("settings.bar_add_tip")
        addBtn.onClick = function()
            ns.buffbar:AddBar()
            ns.Chrome.Apply()
            ns.Settings.Refresh()
        end
        return ry
    end)
    win:SetHeight(math.max(y - GAP, sideBottom) + PAD)
    ns.PaintWindow(win)
    layoutBars()
end
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then
        return math.abs(a - b) < 0.001
    end
    return a == b
end
function ns.Settings.Refresh()
    if not win or not win:IsShown() then return end
    for _, c in ipairs(checks) do
        c.frame:SetChecked(c.get())
        if ns.StyleCheck then ns.StyleCheck(c.frame) end
    end
    for _, s in ipairs(strips) do
        local cur = s.get()
        for _, b in ipairs(s.buttons) do b:SetActive(same(b.value, cur)) end
    end
    if resetBtn then
        if ns.buffbar:IsLocked() then resetBtn:Disable() else resetBtn:Enable() end
    end
    if takeBtn then
        local own = ns.Profile.IsOwn()
        if own then takeBtn:Enable(); giveBtn:Enable() else takeBtn:Disable(); giveBtn:Disable() end
    end
    layoutBars()
end
function ns.Settings.Show()
    build()
    win:Show()
    ns.Settings.Refresh()
end
function ns.Settings.Toggle()
    build()
    if win:IsShown() then
        win:Hide()
        return
    end
    ns.Settings.Show()
end
ns.settingsLoaded = true

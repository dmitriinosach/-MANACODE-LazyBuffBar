local _, ns = ...
ns.Options = {}
local O = ns.Options
local W = 560
local PAD = 14
local TOP = 36
local TAB_H = 24
local SEC_GAP = 10
local LABEL_W = 150
local ROW_H = 22
local DOT = 8
local BTN_GAP = 4
local SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }
local WIN_SCALES = { 0.8, 0.9, 1, 1.1, 1.25 }
local REPEATS = { 2, 3, 5, 10, 15 }
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C_DOT = { 1, 0.82, 0.25 }
local TABS = { "look", "presets", "panels", "catalog" }
local win
local tabs
local pages = {}
local pageH = {}
local builders = {}
local refreshers = {}
local overrideSources = {}
local lookSync = {}
local dots = {}
local curTab = TABS[1]
local panel
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function nearestScale(v)
    v = tonumber(v) or 1
    local best = 1
    for _, s in ipairs(WIN_SCALES) do
        if math.abs(s - v) < math.abs(best - v) then best = s end
    end
    return best
end
function ns.WindowScale()
    local d = db()
    local v = nearestScale(d.settingsScale or d.barMenuScale or 1)
    local keep = (math.abs(v - 1) > 0.01) and v or nil
    d.settingsScale, d.barMenuScale = keep, keep
    return v
end
local function setWindowScale(v)
    local keep = (math.abs(v - 1) > 0.01) and v or nil
    db().settingsScale, db().barMenuScale = keep, keep
    if win then ns.RescaleWindow(win, v) end
    if ns.PanelCard then ns.PanelCard.ApplyScale() end
end
local function pct(v)
    return ns.T("settings.scale_fmt", math.floor(v * 100 + 0.5))
end
function O.OnOverride(key, fn)
    overrideSources[key] = fn
end
local BLOCK_FIELD = { absent = "absent", plate = "plate" }
local function itemName(k)
    local id = k:match("^spell:(%d+)$")
    if id then return (GetSpellInfo(tonumber(id))) or k end
    id = k:match("^item:(%d+)$")
    if id then return (GetItemInfo(tonumber(id))) or k end
    local w = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(k)
    if w then return ns.WidgetLabel(w) end
    return k
end
function O.Overrides(key)
    local out = {}
    local src = overrideSources[key]
    if src then
        for _, o in ipairs(src(key) or {}) do out[#out + 1] = o end
    end
    if not (ns.Preset and ns.Preset.Blocks) then return out end
    local field = BLOCK_FIELD[key]
    for i, b in ipairs(ns.Preset.Blocks()) do
        if field and b[field] ~= nil then
            out[#out + 1] = { text = ns.T("options.over_panel", ns.BarName(b, i), tostring(b[field])) }
        end
        if key == "stack" then
            for _, it in ipairs(b.items or {}) do
                if it.view ~= nil and not ns.Widget.NameOf(it.k) then
                    out[#out + 1] = { text = ns.T("options.over_button", itemName(it.k), ns.BarName(b, i), tostring(it.view)) }
                end
            end
        end
    end
    return out
end
local function makeDot(ctl, key)
    local d = CreateFrame("Button", nil, ctl)
    d:SetWidth(DOT + 6)
    d:SetHeight(DOT + 6)
    d:SetPoint("LEFT", ctl, "LEFT", LABEL_W - DOT - 10, 0)
    d.tex = d:CreateTexture(nil, "OVERLAY")
    d.tex:SetTexture(WHITE)
    d.tex:SetWidth(DOT)
    d.tex:SetHeight(DOT)
    d.tex:SetPoint("CENTER", d, "CENTER", 0, 0)
    d.tex:SetVertexColor(C_DOT[1], C_DOT[2], C_DOT[3], 1)
    d.key = key
    d.tipTitle = ns.T("options.overridden")
    d:SetScript("OnEnter", function(self)
        local lines = {}
        for _, o in ipairs(O.Overrides(self.key)) do lines[#lines + 1] = o.text end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.T("options.overridden"), 1, 1, 1, 1, true)
        for _, l in ipairs(lines) do GameTooltip:AddLine(l, 1, 0.82, 0, true) end
        GameTooltip:Show()
    end)
    d:SetScript("OnLeave", ns.TipHide)
    d:Hide()
    dots[key] = d
    return d
end
local function segRow(sec, label, options, get, set, lookKey)
    local seg = ns.MakeSegments(sec, options, { label = label, labelW = LABEL_W })
    seg.onPick = function(v)
        set(v)
        O.Refresh()
    end
    sec:Add(seg)
    lookSync[#lookSync + 1] = function()
        local v = get()
        if seg:GetValue() ~= v then seg:SetValue(v) end
        seg:Layout()
    end
    if lookKey then makeDot(seg, lookKey) end
    return seg
end
local function makeCheck(parent, label, tip, get, set)
    local c = ns.MakeCheck(parent)
    c:SetLabel(label)
    c.help = tip
    c.onToggle = function(on)
        set(on)
        O.Refresh()
    end
    local onEnter = c:GetScript("OnEnter")
    c:SetScript("OnEnter", function(self)
        self.tip = ns.HelpTips() and self.help or nil
        onEnter(self)
    end)
    lookSync[#lookSync + 1] = function() c:SetChecked(get()) end
    return c
end
local function checkRow(sec, defs)
    local row = CreateFrame("Frame", nil, sec)
    row:SetHeight(ROW_H)
    local x = 0
    for i, d in ipairs(defs) do
        local c = makeCheck(row, d.label, d.tip, d.get, d.set)
        if i == 1 then
            c:SetPoint("LEFT", row, "LEFT", x, 0)
        else
            c:SetPoint("LEFT", row, "LEFT", W / 2 - PAD, 0)
        end
    end
    sec:Add(row, ROW_H)
end
local function stripRow(sec, label, values, fmt, get, set)
    local row = CreateFrame("Frame", nil, sec)
    row:SetHeight(ROW_H)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetWidth(LABEL_W)
    row.label:SetJustifyH("LEFT")
    row.label:SetText(label)
    local btns = {}
    local x = LABEL_W
    for _, v in ipairs(values) do
        local b = ns.MakeButton(row)
        b:SetLabel(fmt(v))
        b.value = v
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        b.onClick = function()
            set(v)
            O.Refresh()
        end
        x = x + b:GetWidth() + BTN_GAP
        btns[#btns + 1] = b
    end
    sec:Add(row, ROW_H)
    lookSync[#lookSync + 1] = function()
        local cur = get()
        for _, b in ipairs(btns) do
            b:SetActive(type(cur) == "number" and type(b.value) == "number" and math.abs(cur - b.value) < 0.001 or cur == b.value)
        end
    end
    return btns
end
local function keyOptions(prefix, list)
    local out = {}
    for _, v in ipairs(list) do out[#out + 1] = { key = v, label = ns.T(prefix .. v) } end
    return out
end
local function pctOptions(list)
    local out = {}
    for _, v in ipairs(list) do out[#out + 1] = { key = v, label = pct(v) } end
    return out
end
local function lookRow(sec, label, key, options)
    segRow(sec, label, options,
        function() return ns.Look.Get(key) end,
        function(v) ns.Look.Set(key, v) end, key)
end
local function section(page, caption)
    local sec = ns.MakeSection(page, caption)
    page.secs = page.secs or {}
    page.secs[#page.secs + 1] = sec
    return sec
end
local function stack(page)
    local y = 0
    local prev
    for _, sec in ipairs(page.secs or {}) do
        sec:ClearAllPoints()
        if prev then y = y + SEC_GAP end
        sec:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -y)
        sec:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAD, -y)
        y = y + (sec:GetHeight() or 0)
        prev = sec
    end
    return y
end
local function themeOptions()
    local out = {}
    for _, key in ipairs(ns.themeOrder or {}) do
        local t = ns.themes and ns.themes[key]
        out[#out + 1] = { key = key, label = (t and t.labelKey and ns.L[t.labelKey]) or key }
    end
    return out
end
local function tipOptions()
    local out = {}
    for _, v in ipairs(ns.buffbar:IconTipModes()) do
        out[#out + 1] = { key = v, label = ns.T("settings.tips_" .. v), tip = ns.T("settings.tips_" .. v .. "_tip") }
    end
    return out
end
local function buildLook(page)
    local sec = section(page, ns.T("settings.skin"))
    segRow(sec, ns.T("options.theme"), themeOptions(),
        function() return ns.SkinKey() end,
        function(key) ns.SetSkin(key) end)
    sec = section(page, ns.T("options.panels_windows"))
    stripRow(sec, ns.T("settings.scale"), SCALES, pct,
        function() return ns.buffbar:GetScale() end,
        function(v) ns.buffbar:SetScale(v); ns.Chrome.Apply() end)
    segRow(sec, ns.T("options.win_scale"), pctOptions(WIN_SCALES),
        function() return db().settingsScale or 1 end, setWindowScale)
    checkRow(sec, {
        { label = ns.T("settings.show"), tip = ns.T("settings.show_tip"),
          get = function() return ns.buffbar:IsShown() end,
          set = function(on) ns.buffbar:SetShown(on); ns.Chrome.Apply() end },
        { label = ns.T("settings.minimap"), tip = ns.T("settings.minimap_tip"),
          get = function() return ns.Chrome.MinimapShown() end,
          set = function(on) ns.Chrome.SetMinimapShown(on) end },
    })
    sec = section(page, ns.T("settings.look"))
    lookRow(sec, ns.T("options.plate"), "plate", keyOptions("settings.plate.", ns.Look.ALL.plate.list))
    lookRow(sec, ns.T("options.absent"), "absent", pctOptions(ns.Look.ALL.absent.list))
    lookRow(sec, ns.T("options.sweep"), "sweep", pctOptions(ns.Look.ALL.sweep.list))
    lookRow(sec, ns.T("options.digits"), "digits", keyOptions("settings.digits.", ns.Look.ALL.digits.list))
    lookRow(sec, ns.T("options.fx"), "fx", keyOptions("settings.fx.", ns.Look.ALL.fx.list))
    lookRow(sec, ns.T("options.font"), "font", keyOptions("settings.font.", ns.Look.ALL.font.list))
    lookRow(sec, ns.T("options.stack"), "stack", keyOptions("settings.font.", ns.Look.ALL.stack.list))
    checkRow(sec, {
        { label = ns.T("settings.tint"), tip = ns.T("settings.tint_tip"),
          get = function() return ns.Look.Get("tint") end, set = function(on) ns.Look.Set("tint", on) end },
        { label = ns.T("settings.snap"), tip = ns.T("settings.snap_tip"),
          get = function() return ns.Look.Get("snap") end, set = function(on) ns.Look.Set("snap", on) end },
    })
    sec = section(page, ns.T("style.section_all"))
    local styleRows = ns.StyleUI.Rows(sec, { scope = "all", width = W - PAD * 2, onChange = function() O.Refresh() end })
    sec:Add(styleRows.frame, styleRows.frame:GetHeight())
    lookSync[#lookSync + 1] = function() styleRows:Set(nil, InCombatLockdown() and true or false) end
    sec = section(page, ns.T("settings.tips"))
    segRow(sec, ns.T("settings.tips_when"), tipOptions(),
        function() return ns.buffbar:IconTips() end,
        function(v) ns.buffbar:SetIconTips(v) end)
    checkRow(sec, { { label = ns.T("settings.tips_novice"), tip = ns.T("settings.tips_novice_tip"),
        get = function() return ns.Look.Get("novice") end, set = function(on) ns.Look.Set("novice", on) end } })
    sec = section(page, ns.T("options.watch_check"))
    local knob = ns.WatchKnob("rebuff")
    checkRow(sec, { { label = ns.T("notify.watch.rebuff.check"), tip = ns.T("notify.watch.rebuff.note"),
        get = function() return ns.WatchEnabled("rebuff") end,
        set = function(on) ns.SetWatchEnabled("rebuff", on) end } })
    if knob then
        local opts = {}
        for _, v in ipairs(REPEATS) do opts[#opts + 1] = { key = v, label = ns.T("settings.minutes_fmt", v) } end
        segRow(sec, ns.T("options.repeat"), opts, knob.get, knob.set)
    end
    checkRow(sec, { { label = ns.T("settings.fake"), tip = ns.T("settings.fake_tip"),
        get = function() return ns.Incoming.IsFake() end, set = function(on) ns.Incoming.SetFake(on) end } })
    return stack(page)
end
local function refreshLook()
    for _, fn in ipairs(lookSync) do fn() end
    for key, d in pairs(dots) do
        if #O.Overrides(key) > 0 then d:Show() else d:Hide() end
    end
end
function O.AddTab(key, build, refresh)
    builders[key] = build
    refreshers[key] = refresh
end
O.AddTab("look", buildLook, refreshLook)
local function savePos()
    local p, _, rp, x, y = win:GetPoint()
    db().optionsPos = { p, rp, x, y }
end
local function fit()
    local h = 0
    for _, key in ipairs(TABS) do
        if (pageH[key] or 0) > h then h = pageH[key] end
    end
    h = TOP + TAB_H + 8 + h + PAD
    if math.abs((win:GetHeight() or 0) - h) < 0.5 then return end
    win:SetHeight(h)
    ns.PaintWindow(win)
end
local function selectTab(key)
    if not pages[key] then key = TABS[1] end
    curTab = key
    db().optionsTab = key
    for _, k in ipairs(TABS) do
        if k == key then pages[k]:Show() else pages[k]:Hide() end
    end
    if tabs and tabs:GetValue() ~= key then tabs:SetValue(key) end
    ns.MenuClose()
    O.Refresh()
end
local function build()
    if win then return end
    win = ns.MakeWindow("LazyBuffBarOptions", ns.T("settings.title"))
    win:SetWidth(W)
    win:SetScale(ns.WindowScale())
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 2, -PAD)
    win.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
    win.sub = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    win.sub:SetPoint("LEFT", win.title, "RIGHT", 8, -1)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePos()
    end)
    win:SetScript("OnHide", function() ns.MenuClose() end)
    local opts = {}
    for _, key in ipairs(TABS) do opts[#opts + 1] = { key = key, label = ns.T("options.tab_" .. key) } end
    tabs = ns.MakeSegments(win, opts)
    tabs:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -TOP)
    tabs:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -TOP)
    tabs:SetHeight(TAB_H)
    tabs.onPick = selectTab
    for _, key in ipairs(TABS) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(TOP + TAB_H + 8))
        p:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, -(TOP + TAB_H + 8))
        p:SetHeight(1)
        p:Hide()
        pages[key] = p
        local b = builders[key]
        pageH[key] = b and b(p) or 0
        p:SetHeight(pageH[key])
    end
    fit()
    tabs:Layout()
    local pos = db().optionsPos
    win:ClearAllPoints()
    if type(pos) == "table" and pos[1] then
        win:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end
function O.SetPageHeight(key, h)
    if not pages[key] then return end
    pageH[key] = h
    pages[key]:SetHeight(h)
    if win then fit() end
end
function O.Refresh()
    if ns.EditBar and ns.EditBar.Refresh then ns.EditBar.Refresh() end
    if not win or not win:IsShown() then return end
    win.sub:SetText(ns.T("options.sub", ns.ClassName(ns.PlayerClass()), UnitLevel("player") or 0))
    local fn = refreshers[curTab]
    if fn then fn() end
end
local function rescue()
    local l, r, t, b = win:GetLeft(), win:GetRight(), win:GetTop(), win:GetBottom()
    if not (l and r and t and b) then return end
    local sw, sh = ns.ScreenIn(win)
    if r > 0 and l < sw and t > 0 and b < sh then return end
    win:ClearAllPoints()
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    db().optionsPos = nil
end
function O.Show(tab)
    build()
    win:Show()
    rescue()
    selectTab(tab or db().optionsTab or TABS[1])
end
function O.Toggle()
    build()
    if win:IsShown() then
        win:Hide()
        return
    end
    O.Show()
end
function O.Hide()
    if win then win:Hide() end
end
function O.IsShown()
    return win ~= nil and win:IsShown() and true or false
end
function O.Tab()
    return curTab
end
function O.Window()
    return win
end
function O.Page(key)
    return pages[key]
end
function O.Dot(key)
    return dots[key]
end
local function openFromPanel()
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        if HideUIPanel then HideUIPanel(InterfaceOptionsFrame) else InterfaceOptionsFrame:Hide() end
    end
    if GameMenuFrame and GameMenuFrame:IsShown() then
        if HideUIPanel then HideUIPanel(GameMenuFrame) else GameMenuFrame:Hide() end
    end
    O.Show()
end
function ns.BuildOptions()
    if panel then return end
    panel = CreateFrame("Frame", "LazyBuffBarOptionsPanel", UIParent)
    panel.name = ns.T("options.title")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText(ns.T("options.title"))
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(520)
    sub:SetJustifyH("LEFT")
    sub:SetText(ns.T("options.note"))
    local open = CreateFrame("Button", "LazyBuffBarOptionsOpen", panel, "UIPanelButtonTemplate")
    open:SetWidth(200)
    open:SetHeight(24)
    open:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    open:SetText(ns.T("options.open"))
    open.tip = ns.T("options.open_tip")
    open.tipTitle = false
    open:SetScript("OnClick", openFromPanel)
    open:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    open:SetScript("OnLeave", function() ns.TipHide() end)
    InterfaceOptions_AddCategory(panel)
end
function ns.OpenOptions()
    if not panel then return end
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
ns.optionsLoaded = true

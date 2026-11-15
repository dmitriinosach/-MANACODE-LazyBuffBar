local _, ns = ...
ns.PanelCard = {}
local PC = ns.PanelCard
local W = 520
local PAD = 12
local TOP = 10
local COL_GAP = 16
local ROW = 20
local SEC_GAP = 8
local LABEL_W = 92
local DIGITS_LABEL_W = 48
local STEP_W = 20
local VALUE_W = 36
local SIDE_GAP = 8
local DOT = 6
local RESET_SZ = 14
local CHECK = 16
local CHECK_GAP = 6
local SEP_LABEL_W = 64
local SEP_GAP = 4
local SEP_ROWS = 5
local FOOT = 24
local COL_W = (W - PAD * 2 - COL_GAP) / 2
local PREVIEW_SECS = 2
local RESET_TEX = "Interface\\Buttons\\UI-RefreshButton"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EPS = 0.0001
local LIVE = { alpha = true, idle = true, fight = true, plate = true, plateRound = true }
local LOOK_ORDER = { "gap", "pad", "round", "plateRound", "alpha", "idle", "fight", "plate", "absent" }
local COND_ORDER = { "spec", "combat", "where", "group" }
local win, nameFld, summary, divider, leftCol, rightCol
local sizeSec, showSec, lookSec, sizeNote, previewHint
local rulesSec
local rulesEd
local styleRow
local steps = {}
local sliders = {}
local checks = {}
local condRows = {}
local labels = {}
local offCheck, digitsSeg, previewBtn, libBtn
local sepsCheck
local sepUI = {}
local barKey
local barProfile
local function liveProfile()
    return ns.Profile and ns.Profile.Current and ns.Profile.Current() or nil
end
function PC.Current()
    local i = barKey and barProfile == liveProfile() and ns.buffbar:BarIndex(barKey)
    if not i then
        barKey = nil
        if win then win:Hide() end
        return nil
    end
    return i
end
function PC.CurrentId()
    return PC.Current() and barKey
end
local function cur()
    local i = PC.Current()
    if not i then return nil end
    return ns.Preset.Blocks()[i], i
end
local function label(parent, text, w)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", parent, "LEFT", 0, 0)
    fs:SetWidth(w or LABEL_W)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    ns.Ink(fs, ns.EDIT.mute)
    labels[#labels + 1] = fs
    return fs
end
local function hint(parent, text)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    ns.Ink(fs, ns.EDIT.mute)
    labels[#labels + 1] = fs
    return fs
end
local function tipped(f)
    f:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    f:SetScript("OnLeave", function() ns.TipHide() end)
end
local function nudge(key, dir)
    local b, i = cur()
    if not b then return end
    if key == "cols" then
        ns.buffbar:Resize(b.key, b.cols + dir, b.rows)
    elseif key == "rows" then
        ns.buffbar:Resize(b.key, b.cols, b.rows + dir)
    else
        local s = ns.BAR_SCALE
        local v = (ns.buffbar:GetScale(i) or 1) + dir * s.step
        if v < s.min - EPS or v > s.max + EPS then return end
        ns.buffbar:SetScale(v, b.key)
        if ns.Chrome then ns.Chrome.Apply() end
    end
    PC.Refresh()
end
local function stepRow(sec, key)
    local f = CreateFrame("Frame", nil, sec)
    f:SetHeight(ROW)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f.tipTitle = ns.T("look." .. key)
    f.tip = ns.T("look." .. key .. "_tip")
    tipped(f)
    label(f, ns.T("look." .. key))
    local r = { frame = f, knob = { key = key } }
    r.step = ns.MakeStepper(f, LABEL_W, STEP_W, VALUE_W, function(dir) nudge(key, dir) end)
    r.hint = hint(f, ns.T("pcard." .. key .. "_hint"))
    r.hint:SetPoint("LEFT", r.step.more, "RIGHT", 8, 0)
    r.hint:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    f.step, f.knob = r.step, r.knob
    f:SetScript("OnMouseWheel", function(_, delta)
        if InCombatLockdown() then return end
        nudge(key, delta > 0 and 1 or -1)
    end)
    sec:Add(f, ROW)
    return r
end
local function toggleCond(field, key, on)
    local b = cur()
    if not b then return end
    local nc = ns.Cond.With(b.cond, field, key, on)
    if nc ~= b.cond then ns.Preset.SetBlock(b.key, "cond", nc) end
    PC.Refresh()
end
local function smallCheck(parent)
    local c = ns.MakeCheck(parent)
    c:SetWidth(CHECK)
    c:SetHeight(CHECK)
    c.label:SetFontObject("GameFontHighlightSmall")
    return c
end
local function checkWidth(c)
    return CHECK + 2 + (c.label:GetStringWidth() or 0)
end
local function flowChecks(cr)
    local x, row = LABEL_W, 0
    for _, c in ipairs(cr.list) do
        local w = checkWidth(c)
        if x > LABEL_W and x + w > COL_W then
            row = row + 1
            x = LABEL_W
        end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", cr.group, "TOPLEFT", x, -(row * ROW + (ROW - CHECK) / 2))
        x = x + w + CHECK_GAP
    end
    cr.group:SetHeight((row + 1) * ROW)
end
local function checkRows(sec, caption, field, keys, labelsOf)
    checks[field] = checks[field] or {}
    local group = CreateFrame("Frame", nil, sec)
    group:SetHeight(ROW)
    local cr = { group = group, label = label(group, caption), list = {}, keys = keys }
    cr.label:ClearAllPoints()
    cr.label:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -(ROW - 12) / 2)
    for n, key in ipairs(keys) do
        local c = smallCheck(group)
        c:SetLabel(labelsOf[key])
        c.onToggle = function(on) toggleCond(field, key, on) end
        c.tip = ns.T("pcard." .. field .. "_tip")
        c.field, c.key = field, key
        checks[field][key] = c
        cr.list[n] = c
    end
    condRows[field] = cr
    flowChecks(cr)
    sec:Add(group, group:GetHeight())
end
local function slide(key, v)
    local b, i = cur()
    if not b then return end
    if LIVE[key] then
        local own = v
        if math.abs(v - ns.Look.General(key)) < 0.001 then own = nil end
        ns.Preset.SetBlock(b.key, key, own)
        if ns.buffbar.ApplyTheme then ns.buffbar:ApplyTheme() end
        return
    end
    ns.Look.SetBar(i, key, v)
end
local function commit(key, v)
    local _, i = cur()
    if not i then return end
    ns.Look.SetBar(i, key, v)
end
local function sliderRow(sec, key)
    local k = ns.Look.BAR[key]
    local f = CreateFrame("Frame", nil, sec)
    f:SetHeight(ROW)
    local s = ns.MakeSlider(f, { min = k.min, max = k.max, step = k.step, labelW = LABEL_W, valueW = VALUE_W,
                                 fmt = function(v) return ns.Look.Format(key, v) end })
    s:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(DOT + RESET_SZ + 8), 0)
    s:SetLabel(ns.T("look." .. key))
    s.tipTitle = ns.T("look." .. key)
    s.tip = ns.T("look." .. key .. "_tip")
    s.onChange = function(v) slide(key, v) end
    s.onCommit = function(v) commit(key, v) end
    local dot = f:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(WHITE)
    dot:SetWidth(DOT)
    dot:SetHeight(DOT)
    dot:SetPoint("LEFT", s, "RIGHT", 3, 0)
    dot:Hide()
    local reset = CreateFrame("Button", nil, f)
    reset:SetWidth(RESET_SZ)
    reset:SetHeight(RESET_SZ)
    reset:SetPoint("LEFT", dot, "RIGHT", 3, 0)
    reset:SetNormalTexture(RESET_TEX)
    reset:SetHighlightTexture(RESET_TEX)
    reset.tipTitle = ns.T("pcard.as_general")
    reset.tip = ns.T("pcard.as_general_tip")
    tipped(reset)
    reset:SetScript("OnClick", function()
        local _, i = cur()
        if not i then return end
        ns.Look.ClearBar(i, key)
        PC.Refresh()
    end)
    reset:Hide()
    sec:Add(f, ROW)
    return { s = s, dot = dot, reset = reset, key = key }
end
local function commitName(text)
    local b = cur()
    if not b then return end
    ns.buffbar:SetBarName(b.key, text)
    nameFld:SetText(ns.buffbar:BarName(b.key) or "")
    PC.Refresh()
end
local function gold()
    local c = ns.EDIT.gold
    return c[1], c[2], c[3]
end
local function paint()
    if not win then return end
    local r, g, b = gold()
    for _, row in pairs(sliders) do row.dot:SetVertexColor(r, g, b, 1) end
    for _, sec in ipairs({ sizeSec, showSec, lookSec, rulesSec }) do
        if sec and sec.caption then sec.caption:SetTextColor(r, g, b) end
        if sec and sec.line then sec.line:SetVertexColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1) end
    end
    local l = ns.EDIT.line
    if divider then divider:SetVertexColor(l[1], l[2], l[3], 1) end
    for _, fs in ipairs(labels) do ns.Ink(fs, ns.EDIT.mute) end
    if summary then ns.Ink(summary, ns.EDIT.mute) end
    if styleRow then styleRow:Restyle() end
    ns.PaintEdit(win)
end
local function buildHeader()
    nameFld = ns.MakeField(win, { maxLetters = 24 })
    nameFld:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -TOP)
    nameFld:SetPoint("RIGHT", win, "RIGHT", -(PAD + 150), 0)
    nameFld.onCommit = commitName
    for _, t in ipairs({ nameFld, nameFld.box }) do
        t.tipTitle = ns.T("look.name")
        t.tip = ns.T("pcard.name_tip")
        tipped(t)
    end
    summary = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summary:SetPoint("LEFT", nameFld, "RIGHT", 10, 0)
    summary:SetPoint("RIGHT", win.close, "LEFT", -6, 0)
    summary:SetJustifyH("RIGHT")
    summary:SetWordWrap(false)
end
local function buildLeft()
    sizeSec = ns.MakeSection(leftCol, ns.T("pcard.size"))
    sizeSec:SetPoint("TOPLEFT", leftCol, "TOPLEFT", 0, 0)
    sizeSec:SetPoint("TOPRIGHT", leftCol, "TOPRIGHT", 0, 0)
    for _, key in ipairs({ "cols", "rows", "scale" }) do steps[key] = stepRow(sizeSec, key) end
    local noteRow = CreateFrame("Frame", nil, sizeSec)
    sizeNote = hint(noteRow, ns.T("pcard.size_note"))
    sizeNote:SetPoint("TOPLEFT", noteRow, "TOPLEFT", 0, 0)
    sizeNote:SetPoint("TOPRIGHT", noteRow, "TOPRIGHT", 0, 0)
    sizeNote:SetWidth(COL_W)
    sizeSec:Add(noteRow, ns.NoteHeight(sizeNote))
    showSec = ns.MakeSection(leftCol, ns.T("pcard.show"))
    showSec:SetPoint("TOPLEFT", sizeSec, "BOTTOMLEFT", 0, -SEC_GAP)
    showSec:SetPoint("TOPRIGHT", sizeSec, "BOTTOMRIGHT", 0, -SEC_GAP)
    local K = ns.Cond.KEYS
    checkRows(showSec, ns.T("pcard.spec"), "spec", K.spec, { [1] = ns.T("pcard.spec_n", 1, ""), [2] = ns.T("pcard.spec_n", 2, "") })
    checkRows(showSec, ns.T("pcard.combat"), "combat", K.combat, { ["in"] = ns.T("pcard.combat_in"), out = ns.T("pcard.combat_out") })
    checkRows(showSec, ns.T("pcard.where"), "where", K.where, {
        raid = ns.T("pcard.where_raid"), party = ns.T("pcard.where_party"), arena = ns.T("pcard.where_arena"),
        pvp = ns.T("pcard.where_pvp"), world = ns.T("pcard.where_world"),
    })
    checkRows(showSec, ns.T("pcard.group"), "group", K.group, { group = ns.T("pcard.group_in"), solo = ns.T("pcard.group_solo") })
    local row = CreateFrame("Frame", nil, showSec)
    row:SetHeight(ROW)
    label(row, "")
    offCheck = smallCheck(row)
    offCheck:SetPoint("LEFT", row, "LEFT", LABEL_W, 0)
    offCheck:SetLabel(ns.T("pcard.off"))
    offCheck.tip = ns.T("look.off_tip")
    offCheck.onToggle = function(on)
        local b = cur()
        if b then ns.buffbar:SetBarOff(b.key, on) end
        PC.Refresh()
    end
    showSec:Add(row, ROW)
end
local function setSep(field, v)
    local b = cur()
    if b then ns.buffbar:SetBarSepLook(b.key, field, v) end
    PC.Refresh()
end
local function sepColorName(key)
    return ns.T("pcard.sep_c_" .. (key or "theme"))
end
local function openSepColors(anchor)
    local b = cur()
    if not b or InCombatLockdown() then return end
    local now = ns.buffbar:BarSepLook(b.key).c
    local items = { { text = ns.T("pcard.sep_c"), isTitle = true } }
    local keys = { false }
    for _, k in ipairs(ns.Blocks.SEP_COLORS) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do
        local key = k or nil
        local r, g, bl = ns.Blocks.SepColor(key)
        items[#items + 1] = { text = sepColorName(key), swatch = { r, g, bl }, checked = now == key,
                              func = function() setSep("c", key) end }
    end
    ns.MakeMenu(items, anchor)
end
local function sepSegments(parent, key, opts, n)
    local seg = ns.MakeSegments(parent, opts, { label = ns.T("pcard.sep_" .. key), labelW = SEP_LABEL_W })
    seg.tipTitle = ns.T("pcard.sep_" .. key)
    seg.tip = ns.T("pcard.sep_" .. key .. "_tip")
    seg:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(n - 1) * (ROW + SEP_GAP))
    seg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(n - 1) * (ROW + SEP_GAP))
    seg:SetHeight(ROW)
    labels[#labels + 1] = seg.label
    return seg
end
local function sepOpts(list, prefix)
    local out = {}
    for i, v in ipairs(list) do out[i] = { key = v, label = ns.T(prefix .. tostring(v)) } end
    return out
end
local function buildSepLook()
    local box = CreateFrame("Frame", nil, lookSec)
    box.fold = true
    local L = ns.Blocks.SEP_LIMITS
    sepUI.box = box
    sepUI.kind = sepSegments(box, "kind", sepOpts(ns.Blocks.SEP_KINDS, "pcard.sep_k_"), 1)
    sepUI.kind.onPick = function(v) setSep("kind", v) end
    sepUI.w = sepSegments(box, "w", sepOpts({ 1, 2, 3 }, "pcard.sep_w_"), 2)
    sepUI.w.onPick = function(v) setSep("w", v) end
    sepUI.len = sepSegments(box, "len", sepOpts({ "inset", "full" }, "pcard.sep_len_"), 3)
    sepUI.len.onPick = function(v) setSep("len", v) end
    local s = ns.MakeSlider(box, { min = L.aMin, max = L.aMax, step = L.aStep, labelW = SEP_LABEL_W, valueW = VALUE_W,
                                   fmt = function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end })
    s:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -3 * (ROW + SEP_GAP))
    s:SetPoint("TOPRIGHT", box, "TOPRIGHT", -(DOT + RESET_SZ + 8), -3 * (ROW + SEP_GAP))
    s:SetHeight(ROW)
    s:SetLabel(ns.T("pcard.sep_a"))
    s.tipTitle = ns.T("pcard.sep_a")
    s.tip = ns.T("pcard.sep_a_tip")
    s.onCommit = function(v) setSep("a", v) end
    s.onChange = function(v) setSep("a", v) end
    sepUI.alpha = s
    local row = CreateFrame("Frame", nil, box)
    row:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -4 * (ROW + SEP_GAP))
    row:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, -4 * (ROW + SEP_GAP))
    row:SetHeight(ROW)
    label(row, ns.T("pcard.sep_c"), SEP_LABEL_W)
    local sw = ns.MakeSwatch(row)
    sw:SetWidth(CHECK)
    sw:SetHeight(CHECK)
    sw:SetPoint("LEFT", row, "LEFT", SEP_LABEL_W + 4, 0)
    sw.tipTitle = ns.T("pcard.sep_c")
    sw.tip = ns.T("pcard.sep_c_tip")
    sw:SetScript("OnClick", function(self)
        if self.off then return end
        openSepColors(self)
    end)
    sepUI.color = sw
    sepUI.colorName = hint(row, "")
    sepUI.colorName:SetPoint("LEFT", sw, "RIGHT", 6, 0)
    sepUI.colorName:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    box:SetHeight(SEP_ROWS * ROW + (SEP_ROWS - 1) * SEP_GAP)
    lookSec:Add(box, box:GetHeight())
end
local function refreshSepLook(b, i, combat)
    local box = sepUI.box
    if not box then return end
    local on = b.seps and true or false
    if on then box:Show() else box:Hide() end
    lookSec:Relayout()
    if not on then return end
    local lk = ns.buffbar:BarSepLook(i)
    local segs = { kind = lk.kind, w = lk.w, len = lk.inset == 0 and "full" or "inset" }
    for key, v in pairs(segs) do
        local seg = sepUI[key]
        seg:Layout()
        seg:SetValue(v)
        if combat then seg:Disable() else seg:Enable() end
    end
    sepUI.alpha:SetValue(lk.a)
    if combat then sepUI.alpha:Disable() else sepUI.alpha:Enable() end
    sepUI.color:SetColor(ns.Blocks.SepColor(lk.c))
    if combat then sepUI.color:Disable() else sepUI.color:Enable() end
    sepUI.colorName:SetText(sepColorName(lk.c))
end
local function buildRight()
    lookSec = ns.MakeSection(rightCol, ns.T("pcard.look"))
    lookSec:SetPoint("TOPLEFT", rightCol, "TOPLEFT", 0, 0)
    lookSec:SetPoint("TOPRIGHT", rightCol, "TOPRIGHT", 0, 0)
    for _, key in ipairs(LOOK_ORDER) do sliders[key] = sliderRow(lookSec, key) end
    local opts = {}
    for _, mode in ipairs(ns.buffbar:DigitsModes()) do
        opts[#opts + 1] = { key = mode, label = ns.T("look.digits_" .. mode), tip = ns.T("look.digits_" .. mode .. "_tip") }
    end
    digitsSeg = ns.MakeSegments(lookSec, opts, { label = ns.T("look.digits"), labelW = DIGITS_LABEL_W })
    digitsSeg.tipTitle = ns.T("look.digits")
    digitsSeg.tip = ns.T("look.digits_tip")
    digitsSeg.onPick = function(mode)
        local b = cur()
        if b then ns.buffbar:SetDigitsMode(b.key, mode) end
        PC.Refresh()
    end
    lookSec:Add(digitsSeg, ROW)
    labels[#labels + 1] = digitsSeg.label
    local row = CreateFrame("Frame", nil, lookSec)
    row:SetHeight(ROW)
    label(row, "")
    sepsCheck = smallCheck(row)
    sepsCheck:SetPoint("LEFT", row, "LEFT", LABEL_W, 0)
    sepsCheck:SetLabel(ns.T("pcard.seps"))
    sepsCheck.tipTitle = ns.T("pcard.seps")
    sepsCheck.tip = ns.T("pcard.seps_tip")
    sepsCheck.onToggle = function(on)
        local b = cur()
        if b then ns.buffbar:SetBarSeps(b.key, on) end
        PC.Refresh()
    end
    lookSec:Add(row, ROW)
    buildSepLook()
end
local function buildRules()
    rulesSec = ns.MakeSection(win, ns.T("pcard.rules"))
    rulesSec:SetPoint("TOPLEFT", leftCol, "BOTTOMLEFT", 0, -SEC_GAP)
    rulesSec:SetPoint("RIGHT", win, "RIGHT", -PAD, 0)
    rulesEd = ns.CondRules.New(rulesSec, {
        tip = ns.T("pcard.rules_tip"),
        onChange = function(rules)
            local b = cur()
            if not b then return end
            local nc = ns.Cond.WithRules(b.cond, rules)
            ns.Preset.SetBlock(b.key, "cond", nc)
            PC.Refresh()
        end,
    })
    rulesSec:Add(rulesEd.frame, rulesEd.frame:GetHeight())
end
local function buildStyle()
    styleRow = ns.StyleUI.BarRow(lookSec, LABEL_W, ns.T("style.section"))
    styleRow.onChange = function() PC.Refresh() end
    lookSec:Add(styleRow.frame, ROW)
end
local function buildFooter()
    previewBtn = ns.MakeButton(win)
    previewBtn:SetLabel(ns.T("pcard.preview"))
    previewBtn.tip = ns.T("pcard.preview_tip")
    previewBtn:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD, PAD)
    previewBtn.onClick = function()
        local b = cur()
        if b then ns.buffbar:PreviewCooldown(b.key, PREVIEW_SECS) end
    end
    libBtn = ns.MakeButton(win)
    libBtn:SetLabel(ns.T("library.save"))
    libBtn.tipTitle = ns.T("library.save")
    libBtn.tip = ns.T("library.save_tip")
    libBtn:SetPoint("LEFT", previewBtn, "RIGHT", 6, 0)
    libBtn.onClick = function(self)
        local b = cur()
        if not b or InCombatLockdown() then return end
        local key = b.key
        ns.AskName(self, {
            title = ns.T("library.save_ask"), text = ns.buffbar:BarName(key), ghost = ns.T("presets.name_ghost"),
            ok = ns.T("presets.save"), cancel = ns.T("presets.cancel"),
            choice = { value = "char", options = {
                { key = "char", label = ns.T("library.scope_char"), tip = ns.T("library.scope_char_tip") },
                { key = "account", label = ns.T("library.scope_account"), tip = ns.T("library.scope_account_tip") },
            } },
            onCommit = function(name, scope)
                if ns.Library.Save(key, name, scope) then
                    ns.say(ns.T("library.saved", name))
                    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
                end
            end,
        })
    end
    previewHint = hint(win, ns.T("pcard.preview_hint"))
    previewHint:SetPoint("LEFT", libBtn, "RIGHT", 10, 0)
    previewHint:SetPoint("RIGHT", win, "RIGHT", -PAD, 0)
    previewHint:SetWordWrap(false)
end
local function fit()
    local leftH = (sizeSec:GetHeight() or 0) + SEC_GAP + (showSec:GetHeight() or 0)
    local rightH = lookSec:GetHeight() or 0
    local body = math.max(leftH, rightH)
    leftCol:SetHeight(body)
    rightCol:SetHeight(body)
    local rules = rulesSec and (rulesSec:GetHeight() or 0) + SEC_GAP or 0
    win:SetHeight(TOP + ROW + SEC_GAP + body + SEC_GAP + rules + FOOT + PAD)
end
local function build()
    if win then return end
    win = ns.MakeEditFrame("LazyBuffBarPanelCard", "panelcard")
    win:SetScale(ns.WindowScale and ns.WindowScale() or 1)
    win:SetWidth(W)
    leftCol = CreateFrame("Frame", nil, win)
    leftCol:SetWidth(COL_W)
    leftCol:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(TOP + ROW + SEC_GAP))
    rightCol = CreateFrame("Frame", nil, win)
    rightCol:SetWidth(COL_W)
    rightCol:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + COL_W + COL_GAP, -(TOP + ROW + SEC_GAP))
    divider = win:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(WHITE)
    divider:SetWidth(1)
    divider:SetPoint("TOP", rightCol, "TOPLEFT", -COL_GAP / 2, 0)
    divider:SetPoint("BOTTOM", rightCol, "BOTTOMLEFT", -COL_GAP / 2, 0)
    buildHeader()
    buildLeft()
    buildRight()
    buildRules()
    buildStyle()
    buildFooter()
    paint()
    fit()
    win:RegisterEvent("PLAYER_REGEN_DISABLED")
    win:RegisterEvent("PLAYER_REGEN_ENABLED")
    win:SetScript("OnEvent", function() PC.Refresh() end)
    win:SetScript("OnHide", function()
        nameFld.box:ClearFocus()
        ns.TipHide()
        if ns.Blocks.Select then ns.Blocks.Select(nil) end
    end)
end
local function placeNear(f)
    win:ClearAllPoints()
    local u = UIParent:GetEffectiveScale()
    local q = win:GetEffectiveScale() / u
    local cw, ch = W * q, (win:GetHeight() or 0) * q
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local x, y
    if not (f and f:GetLeft()) then
        x, y = (sw - cw) / 2, (sh + ch) / 2
    else
        local k = f:GetEffectiveScale() / u
        local l, r, t, b = f:GetLeft() * k, f:GetRight() * k, f:GetTop() * k, f:GetBottom() * k
        local gap = SIDE_GAP * q
        if r + gap + cw <= sw then
            x, y = r + gap, t
        elseif l - gap - cw >= 0 then
            x, y = l - gap - cw, t
        elseif t + gap + ch <= sh then
            x, y = l, t + gap + ch
        elseif b - gap - ch >= 0 then
            x, y = l, b - gap
        else
            x, y = 0, t
        end
    end
    x = math.max(0, math.min(x, sw - cw))
    y = math.max(ch, math.min(y, sh))
    win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / q, y / q)
end
function PC.Open(x, f)
    local bc = x and ns.buffbar:Record(x)
    if not bc then return end
    build()
    nameFld.box:ClearFocus()
    local same = win:IsShown() and barKey == bc.key and barProfile == liveProfile()
    barKey, barProfile = bc.key, liveProfile()
    if not same then placeNear(f or ns.Blocks.Frame(bc.key)) end
    win:Show()
    if ns.Blocks.Select then ns.Blocks.Select(bc.key) end
    PC.Refresh()
end
function PC.Close()
    if win then win:Hide() end
end
function PC.IsShown()
    return win and win:IsShown() and true or false
end
local function setCheck(c, on, combat)
    c:SetChecked(on)
    if combat then c:Disable() else c:Enable() end
end
function PC.Refresh()
    if not win or not win:IsShown() then return end
    local b, i = cur()
    if not b then return end
    local combat = InCombatLockdown() and true or false
    if not nameFld.focused then nameFld:SetText(ns.buffbar:BarName(i)) end
    summary:SetText(ns.T("pcard.summary", b.cols, b.rows, #(b.items or {})))
    local mc, mr = ns.Grid.MinSize(b)
    local xc, xr = ns.Blocks.MaxSize(b.key)
    steps.cols.step:Set(tostring(b.cols), b.cols > mc and not combat, b.cols < xc and not combat)
    steps.rows.step:Set(tostring(b.rows), b.rows > mr and not combat, b.rows < xr and not combat)
    local sc = ns.buffbar:GetScale(i) or 1
    steps.scale.step:Set(("%d%%"):format(math.floor(sc * 100 + 0.5)), sc > ns.BAR_SCALE.min + EPS and not combat,
                         sc < ns.BAR_SCALE.max - EPS and not combat)
    for n = 1, 2 do
        local c = checks.spec[n]
        local _, name = ns.GetSpec(n)
        c:SetLabel(ns.T("pcard.spec_n", n, name or ""))
    end
    for field, set in pairs(checks) do
        for key, c in pairs(set) do
            setCheck(c, ns.Cond.Has(b.cond, field, key), combat or (field == "spec" and ns.SlotCount() < 2))
        end
    end
    setCheck(offCheck, b.off and true or false, combat)
    setCheck(sepsCheck, b.seps and true or false, combat)
    for _, field in ipairs(COND_ORDER) do flowChecks(condRows[field]) end
    showSec:Relayout()
    rulesEd:Set(b.cond and b.cond.rules, combat)
    rulesSec:Relayout()
    refreshSepLook(b, i, combat)
    fit()
    for key, row in pairs(sliders) do
        row.s:SetValue(ns.Look.Bar(i, key))
        if ns.Look.Own(i, key) then
            row.dot:Show()
            row.reset:Show()
        else
            row.dot:Hide()
            row.reset:Hide()
        end
        if combat then row.s:Disable() else row.s:Enable() end
    end
    digitsSeg:Layout()
    digitsSeg:SetValue(ns.buffbar:DigitsMode(i))
    if combat then digitsSeg:Disable() else digitsSeg:Enable() end
    if combat then libBtn:Disable() else libBtn:Enable() end
    if styleRow then styleRow:Set(i, combat) end
end
function PC.Style()
    return styleRow
end
function PC.ApplyScale()
    if win then ns.RescaleWindow(win, ns.WindowScale and ns.WindowScale() or 1) end
end
function PC.Frame()
    return win
end
function PC.Name()
    return nameFld and nameFld:GetText() or nil
end
function PC.Controls()
    return steps, sliders, checks, offCheck, digitsSeg, previewBtn, libBtn, sepsCheck
end
function PC.SepLook()
    return sepUI
end
function PC.CondRows()
    return condRows
end
function PC.Rules()
    return rulesEd
end
ns.OnTheme(paint)
ns.panelCardLoaded = true

local _, ns = ...
ns.EditBar = {}
local E = ns.EditBar
local PAD_X = 12
local PAD_Y = 5
local GAP = 8
local ROW_H = 16
local SUB_H = 12
local SUB_GAP = 3
local DOT = 7
local SEP_DOT = 3
local SEP_H = 12
local ARROW_SZ = 12
local PULSE = 2.6
local ARROW = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"
local ARROW_COORD = { 0.25, 0.75, 0.25, 0.75 }
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C_DOT = { 1, 0.82, 0.25 }
local C_LINK = { 0.91, 0.9, 0.86 }
local C_HOT = { 1, 1, 1 }
local C_NAME = "|cffffffff"
local C_NOTE = "|cffffc53d"
local C_DIM = "|cff999999"
local C_LIVE = "|cffffd100"
local bar
local row = {}
local seps = {}
local bindFs = {}
local bindDots = {}
local dot, modeFs, presetBtn, addBtn, catBtn, lookBtn, doneBtn
local elapsed = 0
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function specName(s)
    local class, v = tostring(s):match("^(.-)/(.*)$")
    if not class then return tostring(s) end
    return ns.LocalName(ns.SpecInfo(class, v)) or v
end
function E.PresetLabel(id)
    local name = ns.Preset.Label(id)
    local st = ns.Preset.StateOf(id)
    if st == "edited" then return name .. " " .. ns.T("editbar.edited") end
    if st == "factory" then return name .. ns.T("editbar.factory") end
    return name
end
local function presetColored(id)
    local name = C_NAME .. ns.Preset.Label(id) .. "|r"
    local st = ns.Preset.StateOf(id)
    if st == "edited" then return name .. " " .. C_NOTE .. ns.T("editbar.edited") .. "|r" end
    if st == "factory" then return name .. C_DIM .. ns.T("editbar.factory") .. "|r" end
    return name
end
function E.Select(group, id)
    ns.Preset.Select(group, id)
    E.Refresh()
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
end
function E.SaveAs(anchor)
    ns.AskName(anchor, {
        title = ns.T("presets.name_title"), ok = ns.T("presets.save"), cancel = ns.T("presets.cancel"),
        ghost = ns.T("presets.name_ghost"),
        onCommit = function(name)
            local id = ns.Preset.SaveAs(name)
            if id then ns.say(ns.T("presets.saved", name)) end
            E.Refresh()
            if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
        end,
    })
end
function E.Rename(id, anchor)
    ns.AskName(anchor, {
        title = ns.T("presets.rename_title"), ok = ns.T("presets.save"), cancel = ns.T("presets.cancel"),
        text = ns.Preset.Label(id),
        onCommit = function(name)
            ns.Preset.Rename(id, name)
            E.Refresh()
            if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
        end,
    })
end
function E.Delete(id)
    local name = ns.Preset.Label(id)
    if ns.Preset.Delete(id) then ns.say(ns.T("presets.deleted", name)) end
    E.Refresh()
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
end
function E.Reset(group)
    local ok
    local id = ns.Preset.Bound(group)
    if group == ns.ActiveSlot() then
        ok = ns.buffbar:ResetBars(id)
        if ns.Chrome then ns.Chrome.Apply() end
    else
        ok = ns.Preset.Reset(id)
    end
    E.Refresh()
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
    return ok
end
function E.PresetItems(group, anchor)
    local P = ns.Preset
    local class = ns.PlayerClass()
    local spec = P.SpecOf(group)
    local cur = P.Bound(group)
    local variant = spec:match("/(.*)$")
    local items = { { text = ns.T("presets.menu_title", ns.ClassName(class), specName(spec)), isTitle = true } }
    local others = {}
    for _, e in ipairs(P.List(class)) do
        local id = e.id
        local note
        if e.state == "edited" then note = ns.T("editbar.edited")
        elseif e.state == "factory" then note = ns.T("editbar.factory_note")
        elseif e.spec ~= variant then note = specName(class .. "/" .. e.spec) end
        local it = { text = e.label, note = note, checked = id == cur, func = function() E.Select(group, id) end }
        if e.own or id == spec then items[#items + 1] = it else others[#others + 1] = it end
    end
    local st = P.StateOf(cur)
    if group == ns.ActiveSlot() then
        items[#items + 1] = { text = ns.T("presets.save_as"), tip = ns.T("presets.save_as_tip"),
                              func = function() E.SaveAs(anchor) end }
    end
    if st == "own" then
        items[#items + 1] = { text = ns.T("presets.rename"), func = function() E.Rename(cur, anchor) end }
        items[#items + 1] = { text = ns.T("presets.delete"), tip = ns.T("presets.delete_tip"), func = function() E.Delete(cur) end }
    end
    if st == "edited" then
        items[#items + 1] = { text = ns.T("presets.reset"), tip = ns.T("presets.reset_tip"), func = function() E.Reset(group) end }
    end
    if #others > 0 then
        items[#items + 1] = { text = ns.T("presets.others"), submenu = others }
    end
    return items
end
function E.OpenMenu(group, anchor)
    ns.MakeMenu(E.PresetItems(group, anchor), anchor)
end
local function gold()
    local c = ns.EDIT.gold
    return c[1], c[2], c[3]
end
local function styleLink(b)
    local r, g, bl
    if b.gold then
        r, g, bl = gold()
        if b.hovered or b.active then r, g, bl = math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, bl + 0.4) end
    elseif b.hovered or b.active then
        r, g, bl = C_HOT[1], C_HOT[2], C_HOT[3]
    else
        r, g, bl = C_LINK[1], C_LINK[2], C_LINK[3]
    end
    b.text:SetTextColor(r, g, bl)
    if b.active then b.mark:Show() else b.mark:Hide() end
end
local function paint()
    if not bar then return end
    ns.PaintEdit(bar)
    local sep = ns.EDIT.border
    for _, s in ipairs(seps) do s:SetVertexColor(sep[1], sep[2], sep[3], 0.8) end
    modeFs:SetTextColor(gold())
    for _, b in ipairs({ presetBtn, addBtn, catBtn, lookBtn, doneBtn }) do
        if b then
            styleLink(b)
            local r, g, bl = gold()
            if b.gold then
                b.line:SetVertexColor(r, g, bl, 0.9)
                b.mark:SetVertexColor(r, g, bl, 0.9)
            else
                b.line:SetVertexColor(1, 1, 1, 0.45)
                b.mark:SetVertexColor(1, 1, 1, 0.45)
            end
        end
    end
end
local function savePos()
    local p, _, rp, x, y = bar:GetPoint()
    db().editBarPos = { p, rp, x, y }
end
local function place()
    bar:ClearAllPoints()
    local pos = db().editBarPos
    if type(pos) == "table" and pos[1] then
        bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        bar:SetPoint("TOP", UIParent, "TOP", 0, 0)
    end
end
local function makeSep(w, h)
    local s = bar:CreateTexture(nil, "ARTWORK")
    s:SetTexture(WHITE)
    s:SetWidth(w)
    s:SetHeight(h)
    seps[#seps + 1] = s
    return s
end
local function makeLink(gold, extraW)
    local b = CreateFrame("Button", nil, bar)
    b:SetHeight(ROW_H)
    b.gold = gold
    b.extraW = extraW or 0
    b.text = b:CreateFontString(nil, "OVERLAY", gold and "GameFontNormalSmall" or "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
    b:SetFontString(b.text)
    b.line = b:CreateTexture(nil, "HIGHLIGHT")
    b.line:SetTexture(WHITE)
    b.line:SetHeight(1)
    b.line:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 1)
    b.line:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 1)
    b.mark = b:CreateTexture(nil, "ARTWORK")
    b.mark:SetTexture(WHITE)
    b.mark:SetHeight(1)
    b.mark:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 1)
    b.mark:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 1)
    b.mark:Hide()
    function b:SetLabel(label)
        self.text:SetText(label)
        self:SetWidth((self.text:GetStringWidth() or 0) + self.extraW)
    end
    function b:SetActive(on)
        self.active = on and true or false
        styleLink(self)
    end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        styleLink(self)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = false
        styleLink(self)
        ns.TipHide()
    end)
    b:SetScript("OnClick", function(self, button)
        if self.onClick then self.onClick(self, button) end
    end)
    styleLink(b)
    return b
end
local function makeAction(label, tipKey, onClick, gold)
    local b = makeLink(gold and true or false)
    b:SetLabel(ns.T(label))
    b.tip = ns.T(tipKey)
    b.onClick = onClick
    return b
end
local function bindLine(n)
    local fs = bindFs[n]
    if not fs then
        fs = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetHeight(SUB_H)
        bindFs[n] = fs
        if n > 1 then bindDots[n - 1] = makeSep(SEP_DOT, SEP_DOT) end
    end
    return fs
end
local function layoutRow()
    local x = PAD_X
    local y = -(PAD_Y + ROW_H / 2)
    for i, part in ipairs(row) do
        local f = part.f
        f:ClearAllPoints()
        f:SetPoint("LEFT", bar, "TOPLEFT", x, y)
        x = x + (part.w or f:GetWidth() or 0)
        if i < #row then x = x + GAP end
    end
    return x - PAD_X
end
local function bindWidth(n)
    local w = 0
    for i = 1, n do
        w = w + (bindFs[i]:GetStringWidth() or 0)
        if i < n then w = w + GAP + SEP_DOT + GAP end
    end
    return w
end
local function layoutBind(n, barW)
    local x = (barW - bindWidth(n)) / 2
    local y = -(PAD_Y + ROW_H + SUB_GAP + SUB_H / 2)
    for i = 1, n do
        local fs = bindFs[i]
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", bar, "TOPLEFT", x, y)
        x = x + (fs:GetStringWidth() or 0)
        if i < n then
            local d = bindDots[i]
            d:ClearAllPoints()
            d:SetPoint("LEFT", bar, "TOPLEFT", x + GAP, y)
            d:Show()
            x = x + GAP + SEP_DOT + GAP
        end
    end
    for i = n + 1, #bindFs do bindFs[i]:Hide() end
    for i = n, #bindDots do bindDots[i]:Hide() end
end
local function layout(n)
    local rowW = layoutRow()
    local w = math.max(rowW, bindWidth(n)) + PAD_X * 2
    bar:SetWidth(w)
    bar:SetHeight(PAD_Y + ROW_H + SUB_GAP + SUB_H + PAD_Y)
    layoutBind(n, w)
end
local function build()
    if bar then return end
    bar = CreateFrame("Frame", "LazyBuffBarEditBar", UIParent)
    ns.Layer(bar, "editbar")
    bar:EnableMouse(true)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePos()
    end)
    bar.tip = ns.T("editbar.drag_tip")
    bar.tipTitle = ns.T("editbar.mode")
    bar:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    bar:SetScript("OnLeave", function() ns.TipHide() end)
    dot = bar:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(WHITE)
    dot:SetWidth(DOT)
    dot:SetHeight(DOT)
    dot:SetVertexColor(C_DOT[1], C_DOT[2], C_DOT[3], 1)
    modeFs = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeFs:SetText(ns.T("editbar.mode"))
    presetBtn = makeLink(false, ARROW_SZ + 2)
    presetBtn.arrow = presetBtn:CreateTexture(nil, "OVERLAY")
    presetBtn.arrow:SetWidth(ARROW_SZ)
    presetBtn.arrow:SetHeight(ARROW_SZ)
    presetBtn.arrow:SetTexture(ARROW)
    presetBtn.arrow:SetTexCoord(ARROW_COORD[1], ARROW_COORD[2], ARROW_COORD[3], ARROW_COORD[4])
    presetBtn.arrow:SetPoint("RIGHT", presetBtn, "RIGHT", 0, 0)
    presetBtn.tip = ns.T("editbar.preset_tip")
    presetBtn.onClick = function(self) E.OpenMenu(ns.ActiveSlot(), self) end
    addBtn = makeAction("editbar.add", "editbar.add_tip", function()
        ns.buffbar:AddBar()
        if ns.Chrome then ns.Chrome.Apply() end
        if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
    end)
    catBtn = makeAction("editbar.catalog", "editbar.catalog_tip", function()
        if ns.Options then ns.Options.Show("catalog") end
    end)
    lookBtn = makeAction("editbar.look", "editbar.look_tip", function()
        if ns.Options then ns.Options.Show("look") end
    end)
    doneBtn = makeAction("editbar.done", "editbar.done_tip", function()
        ns.buffbar:SetLocked(true)
        if ns.Chrome then ns.Chrome.Apply() end
        if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
    end, true)
    row = {
        { f = dot, w = DOT },
        { f = modeFs },
        { f = makeSep(1, SEP_H), w = 1 },
        { f = presetBtn },
        { f = makeSep(SEP_DOT, SEP_DOT), w = SEP_DOT },
        { f = addBtn },
        { f = makeSep(SEP_DOT, SEP_DOT), w = SEP_DOT },
        { f = catBtn },
        { f = makeSep(SEP_DOT, SEP_DOT), w = SEP_DOT },
        { f = lookBtn },
        { f = makeSep(SEP_DOT, SEP_DOT), w = SEP_DOT },
        { f = doneBtn },
    }
    bar:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        dot:SetAlpha(0.55 + 0.45 * math.sin(elapsed * PULSE))
    end)
    paint()
    place()
    bar:Hide()
end
function E.Refresh()
    if not bar or not bar:IsShown() then return end
    local P = ns.Preset
    local active = ns.ActiveSlot()
    presetBtn:SetLabel(ns.T("editbar.preset", presetColored(P.Bound(active))))
    local n = ns.SlotCount()
    for slot = 1, n do
        local line = ns.T("editbar.bind", slot, specName(P.SpecOf(slot)), E.PresetLabel(P.Bound(slot)))
        if slot == active then line = C_LIVE .. line .. "|r" end
        local fs = bindLine(slot)
        fs:SetText(line)
        fs:Show()
    end
    layout(n)
end
function E.BindText()
    local parts = {}
    for i = 1, ns.SlotCount() do
        local t = bindFs[i] and bindFs[i]:GetText() or ""
        parts[#parts + 1] = (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    return table.concat(parts, "  ")
end
local function wanted()
    local b = ns.buffbar
    return b ~= nil and b.IsLocked ~= nil and not b:IsLocked() and b:IsShown()
end
function E.Apply()
    if not (ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return end
    if wanted() then
        build()
        if not bar:IsShown() then
            place()
            bar:Show()
        end
        E.Refresh()
    elseif bar then
        bar:Hide()
        ns.MenuClose()
    end
end
function E.IsShown()
    return bar ~= nil and bar:IsShown() and true or false
end
function E.Frame()
    return bar
end
function E.Buttons()
    return { preset = presetBtn, add = addBtn, catalog = catBtn, look = lookBtn, done = doneBtn, binds = bindFs }
end
ns.OnTheme(paint)
ns.editBarLoaded = true

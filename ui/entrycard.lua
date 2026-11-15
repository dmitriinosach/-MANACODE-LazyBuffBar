local _, ns = ...
ns.EntryCard = {}
local E = ns.EntryCard
local OPEN_DELAY = 0.12
local CLOSE_DELAY = 0.18
local PAD = 7
local GAP = 4
local ROW_GAP = 10
local ICON = 16
local PIC = 18
local TOP_H = 18
local CAP_H = 14
local CTL_H = 22
local CLOSE_SZ = 18
local ARROW_H = 6
local MAX_W = 420
local MENU_ROW = 18
local NAMES_COL = 10
local NAME_W = 90
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C_FOUND = { 0.85, 0.85, 0.85 }
local C_LOST = { 1, 0.35, 0.35 }
local C_TEXT = { 1, 1, 1 }
local C_OFF = { 0.5, 0.5, 0.5 }
local C_NAME = "|cffffd100"
local STACK_VIEWS = { "digits", "pips", "segments", "ring", "fill" }
local SHOW_KEYS = { "always", "on", "off" }
local PROC_KEYS = { "glow", "only", "off" }
local SHOW_LOW = { "always", "on", "low", "off" }
local ACT_SHOW = { "always", "can" }
local CHECK_KEYS = { "auto", "target", "focus", "player", "unit" }
local ROLE_UNIT = { dot = "target", ally = "tank" }
local state
local fillWho
local hoverF
local mutedF
local hoverT = 0
local awayT = 0
local naming = false
local card, driver, menu
local menuRows = {}
local controls = {}
local wopts = {}
local wicons = {}
local worders = {}
local wchecks = {}
local wmenus = {}
local wgrids = {}
local ROW_H = 18
local BOX = 16
local INFO_SZ = 18
local STEP_W = 18
local ARROW_W = 20
local ARROW_TEX = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local function editing()
    return ns.buffbar and ns.buffbar.IsLocked and not ns.buffbar:IsLocked() or false
end
local function dragging()
    if ns.Reorder and ns.Reorder.Active and ns.Reorder.Active() then return true end
    return ns.Blocks and ns.Blocks.Busy and ns.Blocks.Busy() or false
end
local function over(f)
    if MouseIsOver then return MouseIsOver(f) and true or false end
    return f.IsMouseOver and f:IsMouseOver() and true or false
end
local function cellFrame(key, x, y)
    local f = ns.buffbar:IconAt(key, x, y)
    if f then return f end
    return ns.Blocks and ns.Blocks.HoleAt and ns.Blocks.HoleAt(key, x, y) or nil
end
local function iconOf(st)
    return cellFrame(st.key, st.x, st.y)
end
local function cardable(f)
    local it = f._item
    if not it or not f._key then return false end
    return tostring(it.k) ~= "want"
end
local function ink(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function unitOf(item, entry)
    if item.unit then return item.unit end
    local u = entry.unit or ROLE_UNIT[item.role or ""]
    if not u or u == "player" then return nil end
    return u
end
local function nameOf(f, entry)
    if f.spellId then
        local n = GetSpellInfo(f.spellId)
        if n then return n end
    end
    if entry.item then
        local n = GetItemInfo(entry.item)
        if n then return n end
    end
    if f.link then
        local n = GetItemInfo(f.link)
        if n then return n end
    end
    if entry.id then
        local n = GetSpellInfo(entry.id)
        if n then return n end
    end
    return entry.byName or tostring(f._item and f._item.k or "?")
end
local function stacksOf(f, item)
    local fx = ns.Facts and ns.Facts.Of and ns.Facts.Of(item) or {}
    if fx.stacks and fx.stacks > 1 then return fx.stacks end
    local n = f.count and f.count:IsShown() and tonumber(f.count:GetText() or "") or nil
    if n and n > 1 then return n end
    if item.view and item.view ~= "digits" then return 5 end
    return nil
end
local function blessOf(f)
    local b = f.bless
    if not (b and ns.MyBlessing and ns.MyBlessing() == b.key) then return nil end
    if not (ns.IsLearned and ns.IsLearned(b.great)) then return nil end
    return b
end
local function setField(field, v)
    local st = state
    if not st then return end
    ns.Preset.Set(st.key, st.x, st.y, field, v)
end
local function maxText(seg, n)
    local w = 0
    for i = 1, n do
        local b = seg.buttons[i]
        local tw = b and b.text:GetStringWidth() or 0
        if tw > w then w = tw end
    end
    return w
end
local function segWidth(seg, n)
    local lw = seg.label:IsShown() and (seg.label:GetWidth() or 0) + 6 or 0
    return lw + n * (maxText(seg, n) + 12)
end
local function sizeSeg(seg, n)
    local w = segWidth(seg, n)
    seg:SetWidth(w)
    seg.body:SetWidth(w - (seg.label:GetWidth() or 0) - 6)
    seg:Layout()
end
local function relabel(seg, text, lw)
    seg:SetLabel(text)
    seg.label:SetWidth(lw or (seg.label:GetStringWidth() + 2))
    seg.body:SetPoint("LEFT", seg, "LEFT", (seg.label:GetWidth() or 0) + 6, 0)
end
local function makeSeg(label, options, onPick)
    local seg = ns.MakeSegments(card, options, { label = label, labelW = 1 })
    seg.label:SetWidth(seg.label:GetStringWidth() + 2)
    seg.body:ClearAllPoints()
    seg.body:SetPoint("TOP", seg, "TOP", 0, 0)
    seg.body:SetPoint("BOTTOM", seg, "BOTTOM", 0, 0)
    seg.body:SetPoint("RIGHT", seg, "RIGHT", 0, 0)
    seg.body:SetPoint("LEFT", seg, "LEFT", seg.label:GetWidth() + 6, 0)
    seg.onPick = onPick
    seg:Hide()
    return seg
end
local function paintPic(b, on)
    local r, g, bl = ns.Edge()
    local off = b.row and b.row.off
    if on then
        b.ring:SetVertexColor(r, g, bl, off and 0.5 or 1)
    else
        b.ring:SetVertexColor(1, 1, 1, (b.hovered and not off) and 0.6 or 0.25)
    end
    b.tex:SetAlpha((off or b.dis) and 0.4 or 1)
end
local function pic(row, i)
    local b = row.buttons[i]
    if b then return b end
    b = CreateFrame("Button", nil, row.body)
    b.row = row
    b:SetWidth(PIC + 4)
    b:SetHeight(PIC + 4)
    b.ring = b:CreateTexture(nil, "BACKGROUND")
    b.ring:SetTexture(WHITE)
    b.ring:SetAllPoints(b)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b:SetScript("OnClick", function(self)
        local r = self.row
        if r.off or self.dis then return end
        r.onPick(self.index)
    end)
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        paintPic(self, self.on)
        if self.row.tips then
            self.tipTitle = self.name
            ns.TipShow(self)
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = nil
        paintPic(self, self.on)
        if self.row.tips then ns.TipHide() end
    end)
    row.buttons[i] = b
    return b
end
local function fillIcons(row, list, cur)
    for i, e in ipairs(list) do
        local b = pic(row, i)
        b.index, b.name, b.id, b.on, b.dis = i, e.name, e.id, i == cur, e.off and true or nil
        b.tex:SetTexture(e.icon or ns.QMARK)
        b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        paintPic(b, b.on)
        b:ClearAllPoints()
        b:SetPoint("LEFT", row.body, "LEFT", (i - 1) * (PIC + 6), 0)
        b:Show()
    end
    for i = #list + 1, #row.buttons do row.buttons[i]:Hide() end
    local bw = math.max(1, #list * (PIC + 6) - 2)
    row.body:SetWidth(bw)
    row:SetWidth((row.label:GetWidth() or 0) + 6 + bw)
end
local function relabelIcons(row, text)
    row.label:SetText(text)
    row.label:SetWidth(row.label:GetStringWidth() + 2)
end
local function paintIcons(row)
    for _, b in ipairs(row.buttons) do paintPic(b, b.on) end
end
local function makeIcons(text, tips, onPick)
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(CTL_H)
    row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetText(text)
    row.label:SetWidth(row.label:GetStringWidth() + 2)
    row.body = CreateFrame("Frame", nil, row)
    row.body:SetHeight(CTL_H)
    row.body:SetPoint("LEFT", row.label, "RIGHT", 6, 0)
    row.buttons, row.tips, row.onPick = {}, tips, onPick
    row.Enable = function(self)
        self.off = nil
        paintIcons(self)
    end
    row.Disable = function(self)
        self.off = true
        paintIcons(self)
    end
    row:Hide()
    return row
end
local function rulesEditor()
    if card.rules then return card.rules end
    local ed = ns.CondRules.New(card, {
        label = ns.T("card.rules"),
        tip = ns.T("card.rules_tip"),
        onChange = function(rules) setField("rules", rules) end,
    })
    ed.frame.solo = true
    ed.frame:Hide()
    card.rules = ed
    return ed
end
local function unitLabel(l)
    return ns.Units.Label(l)
end
local openNames
local function pickUnit(pickKey)
    menu:Hide()
    if pickKey == "name" then
        naming = true
        E.Refresh()
        if not openNames() then card.name:SetFocus() end
        return
    end
    naming = false
    setField("unit", pickKey)
end
local function menuRow(i)
    local r = menuRows[i]
    if r then return r end
    r = CreateFrame("Button", nil, menu)
    r:SetHeight(MENU_ROW)
    r.hl = r:CreateTexture(nil, "BACKGROUND")
    r.hl:SetTexture(WHITE)
    r.hl:SetAllPoints(r)
    r.hl:SetVertexColor(1, 1, 1, 0.12)
    r.hl:Hide()
    r.text = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
    r.text:SetJustifyH("LEFT")
    r:SetScript("OnEnter", function(self) self.hl:Show() end)
    r:SetScript("OnLeave", function(self) self.hl:Hide() end)
    r:SetScript("OnClick", function(self) pickUnit(self.key) end)
    menuRows[i] = r
    return r
end
local function showMenu(keys, per)
    local w = 0
    for i, k in ipairs(keys) do
        local r = menuRow(i)
        r.key = k
        r.text:SetText((k == "name" and ns.T("card.unit_player")) or k:match("^name:(.+)$") or unitLabel(k))
        local cur = state.unit == k or (k == "name" and state.unit:match("^name:") ~= nil)
        ink(r.text, cur and { ns.Edge() } or C_TEXT)
        local tw = r.text:GetStringWidth() + 12
        if tw > w then w = tw end
        r:Show()
    end
    for i = #keys + 1, #menuRows do menuRows[i]:Hide() end
    for i = 1, #keys do
        local r = menuRows[i]
        r:SetWidth(w)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", menu, "TOPLEFT", 4 + math.floor((i - 1) / per) * w, -4 - ((i - 1) % per) * MENU_ROW)
    end
    menu:SetWidth(math.max(1, math.ceil(#keys / per)) * w + 8)
    menu:SetHeight(math.min(#keys, per) * MENU_ROW + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", card.unit.btn, "BOTTOMLEFT", 0, -2)
    menu:Show()
end
local function openMenu()
    if not state or state.unit == nil or card.unit.off then return end
    local keys = {}
    for _, l in ipairs(ns.Units.LIST) do keys[#keys + 1] = l end
    keys[#keys + 1] = "name"
    showMenu(keys, #keys)
end
openNames = function()
    if not state or state.unit == nil or card.unit.off then return false end
    local names = ns.Units.Names()
    if #names == 0 then return false end
    local keys = {}
    for i, n in ipairs(names) do keys[i] = "name:" .. n end
    showMenu(keys, NAMES_COL)
    return true
end
local function styleUnit()
    local u = card.unit
    ink(u.label, C_TEXT)
    ink(u.btn.text, u.off and C_OFF or C_TEXT)
    u.btn.arrow:SetVertexColor(1, 1, 1, u.off and 0.3 or 0.8)
end
local function makeUnit()
    local u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("LEFT", u, "LEFT", 0, 0)
    u.label:SetText(ns.T("card.unit"))
    u.label:SetWidth(u.label:GetStringWidth() + 2)
    local b = CreateFrame("Button", nil, u)
    b:SetHeight(CTL_H)
    b:SetPoint("LEFT", u.label, "RIGHT", 6, 0)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
                    insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    b:SetBackdropColor(0, 0, 0, 0.5)
    b:SetBackdropBorderColor(1, 1, 1, 0.2)
    b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b, "LEFT", 6, 0)
    b.text:SetJustifyH("LEFT")
    b.arrow = b:CreateTexture(nil, "ARTWORK")
    b.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    b.arrow:SetWidth(14)
    b.arrow:SetHeight(14)
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -3, 0)
    b:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else openMenu() end
    end)
    u.btn = b
    u.name = ns.MakeField(u, { ghost = ns.T("card.name_ghost"), maxLetters = 12 })
    u.name:SetWidth(NAME_W)
    u.name:SetPoint("LEFT", b, "RIGHT", 4, 0)
    u.name.onCommit = function(text)
        text = tostring(text or ""):match("^%s*(.-)%s*$")
        if text == "" then return end
        naming = false
        menu:Hide()
        setField("unit", "name:" .. text)
    end
    card.name = u.name
    u.Disable = function(self)
        self.off = true
        self.name:Disable()
        styleUnit()
        menu:Hide()
    end
    u.Enable = function(self)
        self.off = nil
        self.name:Enable()
        styleUnit()
    end
    u:Hide()
    return u
end
local function makeCause()
    local u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    local c = ns.MakeCheck(u)
    c:SetWidth(BOX)
    c:SetHeight(BOX)
    c:SetPoint("LEFT", u, "LEFT", 0, 0)
    c.label:SetFontObject("GameFontHighlightSmall")
    c.onToggle = function(on) setField("cause", on or nil) end
    u.box = c
    u:Hide()
    return u
end
local function fillUnit(st)
    local u = card.unit
    local l = st.unit
    if not l then
        u.name:Hide()
        u:Hide()
        return
    end
    local name = l:match("^name:(.+)$")
    u.btn.text:SetText(name and ns.T("card.unit_player") or unitLabel(l))
    u.btn:SetWidth(u.btn.text:GetStringWidth() + 26)
    local showName = naming or name ~= nil
    if showName then
        u.name:SetText(name or "")
        u.name:Show()
    else
        u.name:Hide()
    end
    u:SetWidth((u.label:GetWidth() or 0) + 6 + u.btn:GetWidth() + (showName and NAME_W + 4 or 0))
    styleUnit()
    u:Show()
end
local function fillCaption(st)
    local cap = card.caption
    local l = st.unit
    if not l and st.why == "passive" then
        ink(cap, C_LOST)
        cap:SetText(ns.Avail.Text(st.why, st.what))
        cap:Show()
        return
    end
    if not l then cap:Hide(); return end
    local text, found = ns.Units.Tip(l)
    if found then
        local u = ns.Units.Resolve(l)
        local who = l:match("^name:(.+)$") or UnitName(u) or "?"
        text = ns.T("card.unit_on", unitLabel(l), who)
        local how = ns.Units.How(l)
        if how then text = text .. ns.T("facts.sep") .. ns.T("card.how_" .. how) end
        ink(cap, C_FOUND)
    else
        ink(cap, C_LOST)
    end
    cap:SetText(text)
    cap:Show()
end
local function fillTop(f, st)
    card.icon:SetTexture(f._icon or ns.QMARK)
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local parts = { C_NAME .. nameOf(f, st.entry) .. "|r" }
    local line = ns.Facts and ns.Facts.Line and ns.Facts.Line(st.item)
    if line then parts[#parts + 1] = line end
    card.facts:SetText(table.concat(parts, ns.T("facts.sep")))
end
local function armHeader(combat)
    if combat then card.remove:Disable() else card.remove:Enable() end
    card.close:Enable()
    card.remove:ClearAllPoints()
    if state and state.info then
        card.info:Show()
        card.remove:SetPoint("LEFT", card.info, "RIGHT", 4, 0)
    else
        card.info:Hide()
        card.remove:SetPoint("LEFT", card.facts, "RIGHT", 6, 0)
    end
end
local function fillControls(st)
    wipe(controls)
    local combat = InCombatLockdown() and true or false
    local it = st.item
    local show = card.show
    local look = ns.ProcLook(st.entry)
    local keys = (st.act and ACT_SHOW) or ((look and look.full) and SHOW_LOW) or SHOW_KEYS
    if show.keys ~= keys then
        local opts = {}
        for i, k in ipairs(keys) do
            local tip = k == "can" and ns.T("card.show_can_tip") or nil
            opts[i] = { key = k, label = ns.T("card.show_" .. k), tip = tip }
        end
        show:SetOptions(opts)
        sizeSeg(show, #opts)
        show.keys = keys
    end
    if st.act then
        show:SetValue(it.show == "can" and "can" or "always")
    else
        show:SetValue(it.show or (look and look.show) or "always")
    end
    show:Enable()
    controls[#controls + 1] = show
    if st.check then
        card.check:SetValue(it.check or "auto")
        card.check:Enable()
        controls[#controls + 1] = card.check
    end
    local role = card.role
    if #st.roles >= 2 then
        local opts = {}
        for i, r in ipairs(st.roles) do opts[i] = { key = r, label = ns.T("card.role_" .. r) } end
        role:SetOptions(opts)
        role:SetValue(it.role)
        if combat then role:Disable() else role:Enable() end
        sizeSeg(role, #opts)
        controls[#controls + 1] = role
    end
    fillUnit(st)
    if st.unit then
        if combat then card.unit:Disable() else card.unit:Enable() end
        controls[#controls + 1] = card.unit
    end
    if st.cause then
        local c = card.cause
        c.box:SetLabel(ns.T("card.cause_" .. st.cause.kind))
        c.box:SetChecked(it.cause and true or false)
        c.box:Enable()
        c:SetWidth(BOX + 4 + (c.box.label:GetStringWidth() or 0))
        controls[#controls + 1] = c
    end
    if st.stacks then
        card.stacks:SetValue(it.view or "digits")
        card.stacks:Enable()
        controls[#controls + 1] = card.stacks
    end
    if st.bless then
        card.bless:SetValue(ns.BlessingWantsPlain() and "plain" or "great")
        if combat then card.bless:Disable() else card.bless:Enable() end
        controls[#controls + 1] = card.bless
    end
    if st.who then fillWho(st, combat) end
    if st.food then
        card.foodIcon:SetValue(it.foodIcon and "item" or "buff")
        card.foodIcon:Enable()
        controls[#controls + 1] = card.foodIcon
    end
    if st.proc then
        card.proc:SetValue(it.procLink or "glow")
        card.proc:Enable()
        controls[#controls + 1] = card.proc
    end
    card.style:Set(st.key, st.x, st.y, combat)
    controls[#controls + 1] = card.style.btn
    local ed = rulesEditor()
    ed:Set(it.rules, combat)
    controls[#controls + 1] = ed.frame
    armHeader(combat)
end
local function originRow()
    if card.origin then return card.origin end
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(CTL_H)
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    ink(row.text, C_FOUND)
    local b = ns.MakeButton(row)
    b:SetHeight(TOP_H)
    b:SetLabel(ns.T("card.similar"))
    b:SetPoint("LEFT", row.text, "RIGHT", 8, 0)
    b.tipTitle = ns.T("card.similar_tip")
    b.onClick = function()
        local st = state
        local o = st and st.origin
        if not o or not ns.PickerLib then return end
        local key = st.key
        E.Close()
        ns.PickerLib.OpenAt(o.sec, o.key, key)
    end
    row.btn = b
    row:Hide()
    card.origin = row
    return row
end
local function fillOrigin(st)
    local row = originRow()
    st.origin = ns.Catalog and ns.Catalog.Origin and ns.Catalog.Origin(st.item) or nil
    if not st.origin then
        row:Hide()
        return
    end
    row.text:SetText(ns.T("card.origin", st.origin.text))
    local bw = row.btn:GetWidth() or 0
    local tw = math.min(row.text:GetStringWidth(), MAX_W - bw - 8)
    row.text:SetWidth(tw)
    row:SetWidth(tw + 8 + bw)
end
local function viewLabel(name, view, opt)
    local key = "widget." .. name .. "_" .. view
    local label = ns.L[key] and ns.T(key) or tostring(view)
    local w, h = ns.Widget.Size(name, view, opt)
    if w * h > 1 and not label:find("%d+x%d+") then label = ns.T("card.vsize", label, w, h) end
    return label
end
local function putOpt(st, k, v)
    if ns.buffbar and ns.buffbar.SetWidgetOpt then return ns.buffbar:SetWidgetOpt(st.key, st.x, st.y, k, v) end
    return (ns.Preset.SetOpt(st.key, st.x, st.y, k, v))
end
local function writeOpt(st, o, v)
    putOpt(st, o.key, v)
    for k, x in pairs(o.with and o.with(st.item, v) or {}) do
        putOpt(st, k, x)
    end
end
local function woptSeg(i)
    local seg = wopts[i]
    if seg then return seg end
    seg = makeSeg("", {}, function(idx)
        local st = state
        local o = seg.optDef
        local v = o and ns.Widget.OptValues(o, st and st.item)[idx]
        if not (st and o and v) then return end
        if o.write then
            o.write(st.item, v.v, function(k, x) return putOpt(st, k, x) end)
            E.Refresh()
            return
        end
        writeOpt(st, o, v.v)
    end)
    wopts[i] = seg
    return seg
end
local function wiconRow(i)
    local row = wicons[i]
    if row then return row end
    row = makeIcons("", false, function(idx)
        local st = state
        local o = row.optDef
        local v = o and ns.Widget.OptValues(o, st and st.item)[idx]
        if not (st and o and v) or v.off then return end
        if o.write then
            o.write(st.item, v.v, function(k, x) return putOpt(st, k, x) end)
            E.Refresh()
            return
        end
        writeOpt(st, o, v.v)
    end)
    wicons[i] = row
    return row
end
local function arrowBtn(parent, up)
    local b = ns.MakeButton(parent)
    b:SetLabel("")
    b:SetWidth(ARROW_W)
    b:SetHeight(BOX)
    b.arrow = b:CreateTexture(nil, "OVERLAY")
    b.arrow:SetTexture(ARROW_TEX)
    b.arrow:SetWidth(10)
    b.arrow:SetHeight(10)
    b.arrow:SetPoint("CENTER", b, "CENTER", 0, 0)
    if up then
        b.arrow:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    else
        b.arrow:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
    end
    return b
end
local function chosenOf(st, o)
    local cur = st.item.opt and st.item.opt[o.key]
    if type(cur) == "table" and #cur > 0 then
        local out = {}
        for i, v in ipairs(cur) do out[i] = v end
        return out
    end
    return o.chosen and o.chosen(st.item) or {}
end
local function indexOf(list, v)
    for i, x in ipairs(list) do
        if x == v then return i end
    end
    return nil
end
local function orderRow(u, i)
    local r = u.rows[i]
    if r then return r end
    r = CreateFrame("Frame", nil, u)
    r:SetHeight(ROW_H)
    r.check = ns.MakeCheck(r)
    r.check:SetWidth(BOX)
    r.check:SetHeight(BOX)
    r.check:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(BOX)
    r.icon:SetHeight(BOX)
    r.icon:SetPoint("LEFT", r.check, "RIGHT", 4, 0)
    r.name = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
    r.name:SetJustifyH("LEFT")
    r.up = arrowBtn(r, true)
    r.down = arrowBtn(r, false)
    r.check.onToggle = function(on)
        local st, o = state, u.optDef
        if not (st and o) then return end
        local list = chosenOf(st, o)
        local at = indexOf(list, r.v)
        if on and not at then
            list[#list + 1] = r.v
        elseif not on and at then
            if #list < 2 or (o.lock and o.lock(st.item, r.v)) then E.Refresh(); return end
            table.remove(list, at)
        end
        if not putOpt(st, o.key, list) then E.Refresh() end
    end
    local function move(d)
        local st, o = state, u.optDef
        if not (st and o) or InCombatLockdown() then return end
        local list = chosenOf(st, o)
        local at = indexOf(list, r.v)
        local to = at and at + d
        if not (to and list[to]) then return end
        list[at], list[to] = list[to], list[at]
        putOpt(st, o.key, list)
    end
    r.up.onClick = function() move(-1) end
    r.down.onClick = function() move(1) end
    u.rows[i] = r
    return r
end
local function worderOf(i)
    local u = worders[i]
    if u then return u end
    u = CreateFrame("Frame", nil, card)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("TOPLEFT", u, "TOPLEFT", 0, -3)
    u.rows = {}
    u.solo = true
    u:Hide()
    worders[i] = u
    return u
end
local function fillOrderOpt(o, st, combat, i, colW)
    local u = worderOf(i)
    u.optDef = o
    u.label:SetText((o.text and o.text(st.item)) or ns.T(o.label))
    u.label:SetWidth(colW or (u.label:GetStringWidth() + 2))
    ns.Ink(u.label, ns.EDIT.mute)
    local items = o.items and o.items(st.item) or {}
    local chosen = chosenOf(st, o)
    local rows = {}
    for _, v in ipairs(chosen) do
        for _, it in ipairs(items) do
            if it.v == v then rows[#rows + 1] = it end
        end
    end
    for _, it in ipairs(items) do
        if not indexOf(chosen, it.v) then rows[#rows + 1] = it end
    end
    local lw = (u.label:GetWidth() or 0) + 6
    local nameW = 0
    for k, it in ipairs(rows) do
        local r = orderRow(u, k)
        r.v = it.v
        r.name:SetText(it.text or tostring(it.v))
        local tw = r.name:GetStringWidth() or 0
        if tw > nameW then nameW = tw end
    end
    for k, it in ipairs(rows) do
        local r = u.rows[k]
        local at = indexOf(chosen, it.v)
        r.icon:SetTexture(it.icon or ns.QMARK)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.check:SetChecked(at ~= nil)
        local lock = at and (#chosen < 2 and "card.lock_last" or (o.lock and o.lock(st.item, it.v))) or nil
        r.check.tip = lock and ns.T(lock) or nil
        if combat or lock then r.check:Disable() else r.check:Enable() end
        r.name:SetWidth(nameW + 2)
        r.up:ClearAllPoints()
        r.up:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
        r.down:ClearAllPoints()
        r.down:SetPoint("LEFT", r.name, "RIGHT", 6 + ARROW_W + 2, 0)
        if at and at > 1 then r.up:Show() else r.up:Hide() end
        if at and at < #chosen then r.down:Show() else r.down:Hide() end
        if combat then
            r.up:Disable()
            r.down:Disable()
        else
            r.up:Enable()
            r.down:Enable()
        end
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", u, "TOPLEFT", lw, -(k - 1) * ROW_H)
        r:SetWidth(BOX * 2 + 14 + 2 * ARROW_W + nameW)
        r:Show()
    end
    for k = #rows + 1, #u.rows do u.rows[k]:Hide() end
    u:SetWidth(lw + BOX * 2 + 14 + 2 * ARROW_W + nameW)
    u:SetHeight(math.max(CTL_H, #rows * ROW_H))
    controls[#controls + 1] = u
end
local function checkBox(u, i)
    local c = u.boxes[i]
    if c then return c end
    c = ns.MakeCheck(u)
    c:SetWidth(BOX)
    c:SetHeight(BOX)
    c.label:SetFontObject("GameFontHighlightSmall")
    c.onToggle = function(on)
        local st = state
        local def = c.def
        if not (st and def) then return end
        if def.set then
            def.set(st.item, on)
            E.Refresh()
            return
        end
        local base = def.def and true or false
        local v = on
        if on == base then v = nil end
        if not putOpt(st, def.key, v) then E.Refresh() end
    end
    u.boxes[i] = c
    return c
end
local function wcheckOf(i)
    local u = wchecks[i]
    if u then return u end
    u = CreateFrame("Frame", nil, card)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("TOPLEFT", u, "TOPLEFT", 0, -3)
    u.boxes = {}
    u.solo = true
    u:Hide()
    wchecks[i] = u
    return u
end
local function fillChecksOpt(o, st, combat, i, colW)
    local u = wcheckOf(i)
    u.label:SetText((o.text and o.text(st.item)) or ns.T(o.label))
    u.label:SetWidth(colW or (u.label:GetStringWidth() + 2))
    ns.Ink(u.label, ns.EDIT.mute)
    local lw = (u.label:GetWidth() or 0) + 6
    local wmax = 0
    local list = o.checks or {}
    if type(list) == "function" then list = list(st.item) end
    for k, def in ipairs(list) do
        local c = checkBox(u, k)
        c.def = def
        c:SetLabel(ns.T(def.label))
        local on
        if def.get then
            on = def.get(st.item) and true or false
        else
            local cur = st.item.opt and st.item.opt[def.key]
            if cur == nil then on = def.def and true or false else on = cur and true or false end
        end
        c:SetChecked(on)
        if combat then c:Disable() else c:Enable() end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", u, "TOPLEFT", lw, -(k - 1) * ROW_H - 1)
        c:Show()
        local tw = BOX + 4 + (c.label:GetStringWidth() or 0)
        if tw > wmax then wmax = tw end
    end
    for k = #list + 1, #u.boxes do u.boxes[k]:Hide() end
    u:SetWidth(lw + wmax)
    u:SetHeight(math.max(CTL_H, #list * ROW_H))
    controls[#controls + 1] = u
end
local function paintCell(b)
    b.tex:SetDesaturated(not b.on)
    b.tex:SetAlpha(b.on and 1 or 0.35)
    b.ring:SetVertexColor(1, 1, 1, b.hovered and 0.6 or 0)
end
local function gridCell(r, j)
    local b = r.cells[j]
    if b then return b end
    b = CreateFrame("Button", nil, r)
    b:SetWidth(PIC)
    b:SetHeight(PIC)
    b.ring = b:CreateTexture(nil, "BACKGROUND")
    b.ring:SetTexture(WHITE)
    b.ring:SetAllPoints(b)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b:SetScript("OnClick", function(self)
        local st, u = state, r.grid
        local o = u and u.optDef
        if not (st and o and o.toggle) or u.off or InCombatLockdown() then return end
        o.toggle(st.item, r.key, self.v, function(k, x) return putOpt(st, k, x) end)
        E.Refresh()
    end)
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        paintCell(self)
        self.tipTitle = self.name
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = nil
        paintCell(self)
        ns.TipHide()
    end)
    r.cells[j] = b
    return b
end
local function wgridOf(i)
    local u = wgrids[i]
    if u then return u end
    u = CreateFrame("Frame", nil, card)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("TOPLEFT", u, "TOPLEFT", 0, -4)
    u.rows = {}
    u.solo = true
    u:Hide()
    wgrids[i] = u
    return u
end
local function fillGridOpt(o, st, combat, i, colW)
    local u = wgridOf(i)
    u.optDef, u.off = o, combat or nil
    u.label:SetText((o.text and o.text(st.item)) or ns.T(o.label))
    u.label:SetWidth(colW or (u.label:GetStringWidth() + 2))
    ns.Ink(u.label, ns.EDIT.mute)
    local lw = (u.label:GetWidth() or 0) + 6
    local rows = o.rows and o.rows(st.item) or {}
    local step = PIC + 2
    local wmax = 0
    for k, row in ipairs(rows) do
        local r = u.rows[k]
        if not r then
            r = CreateFrame("Frame", nil, u)
            r:SetHeight(PIC)
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetWidth(BOX)
            r.icon:SetHeight(BOX)
            r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
            r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            r.cells, r.grid = {}, u
            u.rows[k] = r
        end
        r.key = row.key
        r.icon:SetTexture(row.icon or ns.QMARK)
        for j, c in ipairs(row.cells or {}) do
            local b = gridCell(r, j)
            b.v, b.on, b.name = c.v, c.on and true or false, c.tip
            b.tex:SetTexture(c.tex or ns.QMARK)
            if c.coord then b.tex:SetTexCoord(c.coord[1], c.coord[2], c.coord[3], c.coord[4]) end
            paintCell(b)
            b:ClearAllPoints()
            b:SetPoint("LEFT", r, "LEFT", BOX + 6 + (j - 1) * step, 0)
            b:Show()
        end
        for j = #(row.cells or {}) + 1, #r.cells do r.cells[j]:Hide() end
        local w = BOX + 6 + #(row.cells or {}) * step
        if w > wmax then wmax = w end
        r:SetWidth(w)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", u, "TOPLEFT", lw, -(k - 1) * (PIC + 3))
        r:Show()
    end
    for k = #rows + 1, #u.rows do u.rows[k]:Hide() end
    u:SetWidth(lw + wmax)
    u:SetHeight(math.max(CTL_H, #rows * (PIC + 3)))
    controls[#controls + 1] = u
end
local function makeWho()
    local u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("LEFT", u, "LEFT", 0, 0)
    u.label:SetText(ns.T("card.who"))
    local r = CreateFrame("Frame", nil, u)
    r:SetHeight(PIC)
    r:SetPoint("LEFT", u.label, "RIGHT", 6, 0)
    r.cells, r.grid = {}, u
    u.row = r
    u.optDef = {
        toggle = function(_, key, class)
            local skip = ns.BlessSkip(key)
            ns.SetBlessSkip(key, class, not (skip and skip[class]))
        end,
    }
    local c = ns.MakeCheck(u)
    c:SetWidth(BOX)
    c:SetHeight(BOX)
    c:SetPoint("LEFT", r, "RIGHT", 8, 0)
    c.label:SetFontObject("GameFontHighlightSmall")
    c:SetLabel(ns.T("card.who_pp"))
    c.tip = ns.T("card.who_pp_tip")
    c.onToggle = function(on)
        if not ns.BlessPP.Set(on) then E.Refresh() end
    end
    c:Hide()
    u.pp = c
    u:Hide()
    return u
end
fillWho = function(st, combat)
    local u, d = card.who, ns.blessData
    local r = u.row
    local skip = ns.BlessSkip(st.who.key)
    u.off = combat or nil
    r.key = st.who.key
    local ruled = ns.BlessPP.Rules(st.who.key)
    ns.Ink(u.label, ruled and ns.EDIT.mana or ns.EDIT.mute)
    local step = PIC + 2
    for j, c in ipairs(d.classes) do
        local b = gridCell(r, j)
        local co = d.classCoords[c]
        b.v, b.on, b.name = c, not (skip and skip[c]), ns.CLASS_NAME[c] or c
        b.tip = ns.T(b.on and "card.who_on" or "card.who_off") .. (ruled and ("\n" .. ns.T("card.who_ruled")) or "")
        b.tex:SetTexture(d.classTex)
        b.tex:SetTexCoord(co[1], co[2], co[3], co[4])
        paintCell(b)
        b:ClearAllPoints()
        b:SetPoint("LEFT", r, "LEFT", (j - 1) * step, 0)
        b:Show()
    end
    r:SetWidth(#d.classes * step)
    local w = (u.label:GetStringWidth() or 0) + 6 + #d.classes * step
    if ns.BlessPP.Loaded() then
        u.pp:SetChecked(ns.BlessPP.On())
        if combat then u.pp:Disable() else u.pp:Enable() end
        u.pp:Show()
        w = w + 8 + BOX + 4 + (u.pp.label:GetStringWidth() or 0)
    else
        u.pp:Hide()
    end
    u:SetWidth(w)
    controls[#controls + 1] = u
end
local function colorOf(o, item)
    local cur = item.opt and item.opt[o.key]
    if type(cur) == "table" and cur[1] then return cur[1], cur[2], cur[3] end
    local p = o.palette and o.palette(item) or nil
    if p then return p[1], p[2], p[3] end
    return 1, 1, 1
end
local function makeColor()
    local u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("LEFT", u, "LEFT", 0, 0)
    u.swatch = ns.MakeSwatch(u)
    u.swatch:SetPoint("LEFT", u.label, "RIGHT", 6, 0)
    u.swatch.tipTitle = ns.T("widget.m_color")
    u.swatch.tip = ns.T("widget.m_color_tip")
    u.swatch.onChange = function(r, g, b)
        local st, o = state, u.optDef
        if not (st and o) then return end
        local p = o.palette and o.palette(st.item) or nil
        local same = p and math.abs(r - p[1]) < 0.002 and math.abs(g - p[2]) < 0.002 and math.abs(b - p[3]) < 0.002
        ns.Preset.SetOpt(st.key, st.x, st.y, o.key, (not same) and { r, g, b } or nil)
    end
    u.btn = ns.MakeButton(u)
    u.btn:SetLabel(ns.T("widget.m_by_class"))
    u.btn:SetPoint("LEFT", u.swatch, "RIGHT", 6, 0)
    u.btn.tip = ns.T("widget.m_by_class_tip")
    u.btn.onClick = function()
        local st, o = state, u.optDef
        if st and o then ns.Preset.SetOpt(st.key, st.x, st.y, o.key, nil) end
    end
    u.Disable = function(self)
        self.swatch:Disable()
        self.btn:Disable()
    end
    u.Enable = function(self)
        self.swatch:Enable()
        self.btn:Enable()
    end
    u:Hide()
    return u
end
local function fillColor(o, item, combat)
    local u = card.color
    u.optDef = o
    u.label:SetText(ns.T(o.label))
    u.label:SetWidth(u.label:GetStringWidth() + 2)
    u.swatch.tipTitle = ns.T(o.label)
    u.swatch.tip = ns.T(o.tip or "widget.m_color_tip")
    u.btn:SetLabel(ns.T(o.reset or "widget.m_by_class"))
    u.btn.tip = ns.T(o.resetTip or "widget.m_by_class_tip")
    u.swatch:SetColor(colorOf(o, item))
    local own = item.opt and item.opt[o.key] ~= nil
    if combat then
        u:Disable()
    else
        u:Enable()
        if not own then u.btn:Disable() end
    end
    u:SetWidth((u.label:GetWidth() or 0) + 6 + (u.swatch:GetWidth() or 0) + 6 + (u.btn:GetWidth() or 0))
    return u
end
local function makeText()
    local u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("LEFT", u, "LEFT", 0, 0)
    u.field = ns.MakeField(u, { maxLetters = 12 })
    u.field:SetWidth(NAME_W)
    u.field:SetPoint("LEFT", u.label, "RIGHT", 6, 0)
    u.field.onCommit = function(text)
        local st, o = state, u.optDef
        if not (st and o) then return end
        text = tostring(text or ""):match("^%s*(.-)%s*$")
        ns.Preset.SetOpt(st.key, st.x, st.y, o.key, text ~= "" and text or nil)
    end
    u.Disable = function(self) self.field:Disable() end
    u.Enable = function(self) self.field:Enable() end
    u:Hide()
    return u
end
local function fillText(o, item, combat)
    local u = card.text
    u.optDef = o
    u.label:SetText(ns.T(o.label))
    u.label:SetWidth(u.label:GetStringWidth() + 2)
    u.field.box:SetMaxLetters(o.max or 12)
    u.field.ghost:SetText(o.ghost and ns.T(o.ghost) or "")
    local cur = item.opt and item.opt[o.key]
    u.field:SetText(type(cur) == "string" and cur or "")
    if combat then u:Disable() else u:Enable() end
    u:SetWidth((u.label:GetWidth() or 0) + 6 + NAME_W)
    return u
end
local function wmenuRow(i)
    local u = wmenus[i]
    if u then return u end
    u = CreateFrame("Frame", nil, card)
    u:SetHeight(CTL_H)
    u.label = u:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    u.label:SetPoint("LEFT", u, "LEFT", 0, 0)
    u.prev = ns.MakeButton(u)
    u.prev:SetLabel("<")
    u.prev:SetWidth(STEP_W)
    u.prev:SetPoint("LEFT", u.label, "RIGHT", 6, 0)
    u.btn = ns.MakeButton(u)
    u.btn:SetPoint("LEFT", u.prev, "RIGHT", 2, 0)
    u.next = ns.MakeButton(u)
    u.next:SetLabel(">")
    u.next:SetWidth(STEP_W)
    u.next:SetPoint("LEFT", u.btn, "RIGHT", 2, 0)
    u.step = function(dir)
        local st, o, vals = state, u.optDef, u.vals
        if not (st and o and vals and #vals > 0) or InCombatLockdown() then return end
        local i = ((u.idx or 1) - 1 + dir) % #vals + 1
        local val = vals[i].v
        if o.write then
            o.write(st.item, val, function(k, x) return putOpt(st, k, x) end)
        else
            writeOpt(st, o, val)
        end
        E.Refresh()
    end
    u.prev.onClick = function() u.step(-1) end
    u.next.onClick = function() u.step(1) end
    u.btn:EnableMouseWheel(true)
    u.btn:SetScript("OnMouseWheel", function(_, d) u.step(d > 0 and -1 or 1) end)
    u.btn.onClick = function(self)
        local st, o = state, u.optDef
        if not (st and o) then return end
        local cur = st.item.opt and st.item.opt[o.key]
        local items = { { text = ((o.text and o.text(st.item)) or ns.T(o.label)), isTitle = true } }
        for _, v in ipairs(ns.Widget.OptValues(o, st.item)) do
            local val = v.v
            items[#items + 1] = { text = v.text or ns.T(v.label), checked = val == cur, func = function()
                if o.write then
                    o.write(st.item, val, function(k, x) return putOpt(st, k, x) end)
                else
                    writeOpt(st, o, val)
                end
                E.Refresh()
            end }
        end
        ns.MakeMenu(items, self)
    end
    u.Disable = function(self) self.btn:Disable() self.prev:Disable() self.next:Disable() end
    u.Enable = function(self) self.btn:Enable() self.prev:Enable() self.next:Enable() end
    u:Hide()
    wmenus[i] = u
    return u
end
local function fillMenuOpt(o, st, combat, i, colW)
    local u = wmenuRow(i)
    u.optDef = o
    u.label:SetText(((o.text and o.text(st.item)) or ns.T(o.label)))
    u.label:SetWidth(colW or (u.label:GetStringWidth() + 2))
    u.solo = colW and true or nil
    local cur = st.item.opt and st.item.opt[o.key]
    if cur == nil and o.cur then cur = o.cur(st.item) end
    local vals = ns.Widget.OptValues(o, st.item)
    local pick
    for _, v in ipairs(vals) do
        if v.v == cur then pick = v end
    end
    if not pick then
        for _, v in ipairs(vals) do
            if v.v == nil then pick = v end
        end
    end
    pick = pick or vals[1]
    u.vals, u.idx = vals, 1
    for k, v in ipairs(vals) do
        if v == pick then u.idx = k end
    end
    u.btn:SetLabel(pick and (pick.text or ns.T(pick.label)) or "")
    u.btn:SetActive(cur ~= nil)
    if combat then u:Disable() else u:Enable() end
    u:SetWidth((u.label:GetWidth() or 0) + 6 + (u.btn:GetWidth() or 0) + 2 * (STEP_W + 2))
    return u
end
local function optLabel(o, st)
    return (o.text and o.text(st.item)) or ns.T(o.label)
end
local function fillSegOpt(o, st, combat, from, colW)
    local vals = ns.Widget.OptValues(o, st.item)
    local cur = st.item.opt and st.item.opt[o.key]
    if cur == nil and o.cur then cur = o.cur(st.item) end
    local opts, curIdx, nilIdx = {}, nil, nil
    for j, v in ipairs(vals) do
        opts[j] = { key = j, label = v.text or ns.T(v.label) }
        if v.v == cur then curIdx = j end
        if v.v == nil then nilIdx = j end
    end
    curIdx = curIdx or nilIdx
    local first = woptSeg(from)
    relabel(first, optLabel(o, st), colW)
    first:SetOptions(opts)
    local lw = first.label:GetWidth() or 0
    local per = maxText(first, #opts) + 12
    local fit = math.max(1, math.floor((MAX_W - lw - 6) / per))
    local chunks = math.max(1, math.ceil(#opts / fit))
    for c = 1, chunks do
        local seg = woptSeg(from + c - 1)
        seg.optDef = o
        local part = {}
        for j = (c - 1) * fit + 1, math.min(c * fit, #opts) do part[#part + 1] = opts[j] end
        if c > 1 then relabel(seg, "", lw) end
        seg:SetOptions(part)
        seg:SetValue(curIdx)
        seg.solo = chunks > 1
        if combat then seg:Disable() else seg:Enable() end
        sizeSeg(seg, #part)
        controls[#controls + 1] = seg
    end
    return chunks
end
local function fillIconOpt(o, st, combat, i, colW)
    local row = wiconRow(i)
    row.optDef = o
    relabelIcons(row, optLabel(o, st))
    if colW then row.label:SetWidth(colW) end
    ns.Ink(row.label, ns.EDIT.mute)
    row.solo = colW and true or nil
    local cur = st.item.opt and st.item.opt[o.key]
    if cur == nil and o.cur then cur = o.cur(st.item) end
    local list, curIdx = {}, nil
    for j, v in ipairs(ns.Widget.OptValues(o, st.item)) do
        list[j] = { icon = v.icon, name = v.text or (v.label and ns.T(v.label)) or nil, off = v.off }
        if v.v == cur then curIdx = j end
    end
    fillIcons(row, list, curIdx)
    if combat then row:Disable() else row:Enable() end
    controls[#controls + 1] = row
end
local function columnWidth(views, st)
    local fs = card.measure
    local w = 0
    local function take(text)
        fs:SetText(text)
        local tw = (fs:GetStringWidth() or 0) + 2
        if tw > w then w = tw end
    end
    if #views > 1 then take(ns.T("card.view")) end
    for _, o in ipairs(st.wopts or {}) do take((o.text and o.text(st.item)) or ns.T(o.label)) end
    return w
end
local function fillWidget(f, st)
    local host = f._widget
    local name = host.name
    st.widget, st.wopts = name, ns.Widget.Opts(name, st.item)
    st.roles, st.unit, st.stacks, st.bless, st.who = {}, nil, nil, nil, nil
    card.icon:SetTexture(f._icon or ns.QMARK)
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local w, h = ns.Widget.Size(name, st.item.view, st.item.opt)
    card.facts:SetText(C_NAME .. ns.WidgetLabel(name) .. "|r" .. ns.T("facts.sep") .. ns.T("card.wsize", w, h))
    local d = ns.Widget.Get(name)
    st.info = (d and d.info) and true or false
    local hst = ns.Widget.State(host)
    local cap = d and d.Caption and hst and d.Caption(hst, st.item.opt or {}) or nil
    if cap then
        ink(card.caption, C_FOUND)
        card.caption:SetText(cap)
        card.caption:Show()
    else
        card.caption:Hide()
    end
    wipe(controls)
    local combat = InCombatLockdown() and true or false
    local views = ns.Widget.Views(name)
    local colW = (d and d.card == "column") and columnWidth(views, st) or nil
    relabel(card.view, ns.T("card.view"), colW)
    card.view.solo = colW and true or nil
    if #views > 1 then
        local opts = {}
        for i, v in ipairs(views) do opts[i] = { key = v, label = viewLabel(name, v, st.item.opt) } end
        card.view:SetOptions(opts)
        card.view:SetValue(ns.Widget.ViewOf(name, st.item.view))
        if combat then card.view:Disable() else card.view:Enable() end
        sizeSeg(card.view, #opts)
        controls[#controls + 1] = card.view
    end
    local segs, icons, orders, checks, menus, grids = 0, 0, 0, 0, 0, 0
    for _, o in ipairs(st.wopts) do
        if o.kind == "color" then
            controls[#controls + 1] = fillColor(o, st.item, combat)
        elseif o.kind == "text" then
            controls[#controls + 1] = fillText(o, st.item, combat)
        elseif o.kind == "icons" then
            icons = icons + 1
            fillIconOpt(o, st, combat, icons, colW)
        elseif o.kind == "order" then
            orders = orders + 1
            fillOrderOpt(o, st, combat, orders, colW)
        elseif o.kind == "grid" then
            grids = grids + 1
            fillGridOpt(o, st, combat, grids, colW)
        elseif o.kind == "checks" then
            checks = checks + 1
            fillChecksOpt(o, st, combat, checks, colW)
        elseif o.kind == "menu" then
            menus = menus + 1
            controls[#controls + 1] = fillMenuOpt(o, st, combat, menus, colW)
        else
            local from = segs + 1
            segs = segs + fillSegOpt(o, st, combat, from, colW)
            if colW then
                for k = from, segs do wopts[k].solo = true end
            end
        end
    end
    armHeader(combat)
end
local function layoutCard()
    local y = PAD
    local rw = card.remove:GetWidth() or 0
    local fixed = ICON + 6 + 6 + rw + 6 + CLOSE_SZ + (card.info:IsShown() and INFO_SZ + 4 or 0)
    local fw = math.max(40, math.min(card.facts:GetStringWidth(), MAX_W - fixed))
    card.facts:SetWidth(fw)
    local w = fixed + fw
    y = y + TOP_H
    if card.caption:IsShown() then
        local cw = ICON + 6 + card.caption:GetStringWidth()
        if cw > w then w = math.min(cw, MAX_W) end
        y = y + CAP_H
    end
    local visible = { card.show, card.check, card.role, card.unit, card.cause, card.stacks, card.bless, card.who, card.foodIcon,
                      card.proc, card.view, card.color, card.text }
    if card.rules then visible[#visible + 1] = card.rules.frame end
    visible[#visible + 1] = card.style.btn
    for _, seg in ipairs(wopts) do visible[#visible + 1] = seg end
    for _, row in ipairs(wicons) do visible[#visible + 1] = row end
    for _, u in ipairs(worders) do visible[#visible + 1] = u end
    for _, u in ipairs(wchecks) do visible[#visible + 1] = u end
    for _, u in ipairs(wmenus) do visible[#visible + 1] = u end
    for _, u in ipairs(wgrids) do visible[#visible + 1] = u end
    for _, c in ipairs(visible) do
        local keep = false
        for _, k in ipairs(controls) do
            if k == c then keep = true end
        end
        if not keep then c:Hide() end
    end
    local x, rowW, rowH = PAD, 0, CTL_H
    local first = true
    if #controls > 0 then y = y + GAP end
    for _, c in ipairs(controls) do
        local cw = c:GetWidth() or 0
        if not first and (c.solo or x + cw > MAX_W + PAD) then
            x = PAD
            y = y + rowH + GAP
            rowH = CTL_H
        end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", card, "TOPLEFT", x, -y)
        c:Show()
        local ch = c:GetHeight() or CTL_H
        if ch > rowH then rowH = ch end
        x = x + cw + ROW_GAP
        if x - ROW_GAP - PAD > rowW then rowW = x - ROW_GAP - PAD end
        if c.solo then x = MAX_W + PAD + 1 end
        first = false
    end
    if #controls > 0 then y = y + rowH end
    if rowW > w then w = math.min(rowW, MAX_W) end
    local foot = card.origin
    if foot and state and state.origin then
        y = y + GAP
        foot:ClearAllPoints()
        foot:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -y)
        foot:Show()
        y = y + CTL_H
        local fwid = foot:GetWidth() or 0
        if fwid > w then w = math.min(fwid, MAX_W) end
    elseif foot then
        foot:Hide()
    end
    local W, H = w + 2 * PAD, y + PAD
    card:SetWidth(W)
    card:SetHeight(H)
    return W, H
end
local function noRoomAbove(f, h)
    local k = UIParent:GetEffectiveScale()
    local top = f:GetTop()
    if not top then return false end
    local topPx = top * f:GetEffectiveScale()
    local need = (h + GAP + ARROW_H) * k
    return topPx + need > (UIParent:GetTop() or 0) * k
end
local function placeCard(f, h)
    local st = state
    local below = noRoomAbove(f, h)
    st.below = below
    card:ClearAllPoints()
    if below then
        card:SetPoint("TOP", f, "BOTTOM", 0, -(GAP + ARROW_H))
        card.arrowDown:Hide()
        card.arrowUp:Show()
    else
        card:SetPoint("BOTTOM", f, "TOP", 0, GAP + ARROW_H)
        card.arrowUp:Hide()
        card.arrowDown:Show()
    end
end
local function fillHole(f, st)
    st.roles, st.unit, st.stacks, st.bless, st.who = {}, nil, nil, nil, nil
    local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(st.item.k)
    local known = name and ns.Widget.Get(name) and true or false
    card.icon:SetTexture(f._icon or ns.QMARK)
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    card.facts:SetText(C_NAME .. (name and ns.WidgetLabel(name) or tostring(st.item.k)) .. "|r")
    ink(card.caption, C_FOUND)
    card.caption:SetText(ns.T(known and "card.hole_na" or "card.hole_later"))
    card.caption:Show()
    wipe(controls)
    armHeader(InCombatLockdown() and true or false)
end
local function fill(f)
    local st = state
    st.item, st.entry = f._item, f._entry or {}
    st.widget, st.wopts, st.info, st.food, st.proc, st.origin = nil, nil, nil, nil, nil, nil
    st.act, st.check, st.cause = nil, nil, nil
    if f._hole then
        fillHole(f, st)
        fillOrigin(st)
        local _, h = layoutCard()
        placeCard(f, h)
        return
    end
    if f._widget then
        fillWidget(f, st)
        fillOrigin(st)
        local _, h = layoutCard()
        placeCard(f, h)
        return
    end
    st.roles = ns.Catalog and ns.Catalog.RolesOf and ns.Catalog.RolesOf(st.item.k, st.item.role) or { st.item.role }
    st.unit = unitOf(st.item, st.entry)
    if f._track and st.entry.act then
        st.act = true
        st.cause = ns.ActCause(st.entry)
        local name = f.spellId and GetSpellInfo(f.spellId)
        st.check = (st.cause or (name and SpellHasRange and SpellHasRange(name))) and true or nil
        if not st.check or st.item.check ~= "unit" then st.unit = nil end
    end
    st.stacks = stacksOf(f, st.item)
    st.bless = blessOf(f)
    st.who = f.bless
    st.food = (st.item.role == "food" and f.tipKind == "food") or nil
    st.why, st.what = f._why, f._what
    st.proc = (f._track and f._kind == "spell" and ns.ProcLink and ns.ProcLink.Of(st.entry) and true) or nil
    fillTop(f, st)
    fillCaption(st)
    fillControls(st)
    fillOrigin(st)
    local _, h = layoutCard()
    placeCard(f, h)
end
local function close()
    state = nil
    naming = false
    awayT = 0
    if card and card.name and card.name.box:HasFocus() then card.name.box:ClearFocus() end
    if card and card.text and card.text.field.box:HasFocus() then card.text.field.box:ClearFocus() end
    if menu then menu:Hide() end
    if card then card:Hide() end
end
local function dismiss()
    mutedF = hoverF
    close()
end
local function open(f)
    if not cardable(f) then return end
    naming = false
    state = { key = f._key, x = f._cx, y = f._cy }
    local fr = ns.Blocks.Frame(f._key)
    if fr and fr.over and GameTooltip:IsOwned(fr.over) then GameTooltip:Hide() end
    fill(f)
    awayT = 0
    card:Show()
end
local function paintArrow(tex, r, g, b)
    for _, t in ipairs(tex) do t:SetVertexColor(r, g, b, 1) end
end
local function makeArrow(down)
    local a = CreateFrame("Frame", nil, card)
    a:SetWidth(10)
    a:SetHeight(ARROW_H)
    a.tex = {}
    for i, wd in ipairs({ 10, 6, 2 }) do
        local t = a:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        t:SetWidth(wd)
        t:SetHeight(2)
        if down then
            t:SetPoint("TOP", a, "TOP", 0, -(i - 1) * 2)
        else
            t:SetPoint("BOTTOM", a, "BOTTOM", 0, (i - 1) * 2)
        end
        a.tex[i] = t
    end
    if down then
        a:SetPoint("TOP", card, "BOTTOM", 0, 2)
    else
        a:SetPoint("BOTTOM", card, "TOP", 0, -2)
    end
    a:Hide()
    return a
end
local function style()
    if not card then return end
    ns.PaintEdit(card)
    ns.PaintEdit(menu)
    local e = ns.EDIT.border
    paintArrow(card.arrowUp.tex, e[1], e[2], e[3])
    paintArrow(card.arrowDown.tex, e[1], e[2], e[3])
    for _, seg in ipairs({ card.show, card.role, card.stacks, card.bless, card.foodIcon, card.proc, card.view }) do
        ns.Ink(seg.label, ns.EDIT.mute)
    end
    for _, seg in ipairs(wopts) do ns.Ink(seg.label, ns.EDIT.mute) end
    ns.Ink(card.color.label, ns.EDIT.mute)
    ns.Ink(card.text.label, ns.EDIT.mute)
    ns.Ink(card.unit.label, ns.EDIT.mute)
    if card.rules then card.rules:Restyle() end
    for _, row in ipairs(wicons) do
        ns.Ink(row.label, ns.EDIT.mute)
        paintIcons(row)
    end
    for _, u in ipairs(wmenus) do ns.Ink(u.label, ns.EDIT.mute) end
end
local function build()
    card = CreateFrame("Frame", "LazyBuffBarEntryCard", UIParent)
    ns.Layer(card, "entrycard")
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    card:Hide()
    tinsert(UISpecialFrames, "LazyBuffBarEntryCard")
    card:SetScript("OnHide", function()
        if state then dismiss() end
    end)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetWidth(ICON)
    card.icon:SetHeight(ICON)
    card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -PAD - 1)
    card.facts = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.facts:SetPoint("TOPLEFT", card, "TOPLEFT", PAD + ICON + 6, -PAD - 2)
    card.facts:SetJustifyH("LEFT")
    card.facts:SetWordWrap(false)
    ink(card.facts, C_TEXT)
    card.caption = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.caption:SetPoint("TOPLEFT", card, "TOPLEFT", PAD + ICON + 6, -PAD - TOP_H)
    card.caption:SetJustifyH("LEFT")
    card.caption:SetWordWrap(false)
    card.caption:Hide()
    card.measure = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.measure:Hide()
    local x = ns.MakeCloseX(card)
    x:SetWidth(CLOSE_SZ)
    x:SetHeight(CLOSE_SZ)
    x:SetPoint("TOPRIGHT", card, "TOPRIGHT", -PAD + 3, -PAD + 3)
    x.onClick = function() dismiss() end
    card.close = x
    local rm = ns.MakeButton(card)
    rm:SetHeight(TOP_H)
    rm:SetLabel(ns.T("card.remove"))
    rm:SetPoint("LEFT", card.facts, "RIGHT", 6, 0)
    rm.tipTitle = ns.T("card.remove_tip")
    local info = ns.MakeButton(card)
    info:SetHeight(INFO_SZ)
    info:SetLabel("i")
    info:SetWidth(INFO_SZ)
    info:SetPoint("LEFT", card.facts, "RIGHT", 6, 0)
    info.tipTitle = ns.T("card.info_tip")
    info.onClick = function()
        local st = state
        if st and st.widget and ns.WidgetInfo then ns.WidgetInfo.Open(st.widget, st.item) end
    end
    info:Hide()
    card.info = info
    rm.onClick = function()
        local st = state
        if not st or InCombatLockdown() then return end
        if ns.Preset.Remove(st.key, st.x, st.y) then close() end
    end
    card.remove = rm
    local gear = CreateFrame("Button", nil, card)
    gear:SetWidth(CLOSE_SZ)
    gear:SetHeight(CLOSE_SZ)
    gear:SetPoint("RIGHT", x, "LEFT", -2, 0)
    gear:Hide()
    card.gear = gear
    card.arrowDown = makeArrow(true)
    card.arrowUp = makeArrow(false)
    menu = CreateFrame("Frame", nil, card)
    menu:SetFrameLevel(card:GetFrameLevel() + 10)
    menu:EnableMouse(true)
    menu:Hide()
    local showOpts = {}
    for i, k in ipairs(SHOW_KEYS) do showOpts[i] = { key = k, label = ns.T("card.show_" .. k) } end
    card.show = makeSeg(ns.T("card.show"), showOpts, function(k)
        local look = state and ns.ProcLook(state.entry)
        local def = (look and look.show) or "always"
        setField("show", k ~= def and k or nil)
    end)
    card.show.keys = SHOW_KEYS
    sizeSeg(card.show, #showOpts)
    card.role = makeSeg(ns.T("card.what"), {}, function(r) setField("role", r) end)
    local checkOpts = {}
    for i, k in ipairs(CHECK_KEYS) do
        checkOpts[i] = { key = k, label = ns.T("card.check_" .. k), tip = k == "auto" and ns.T("card.check_auto_tip") or nil }
    end
    card.check = makeSeg(ns.T("card.check"), checkOpts, function(k)
        setField("check", k ~= "auto" and k or nil)
    end)
    sizeSeg(card.check, #checkOpts)
    card.cause = makeCause()
    card.unit = makeUnit()
    card.color = makeColor()
    card.text = makeText()
    local stackOpts = {}
    for i, k in ipairs(STACK_VIEWS) do stackOpts[i] = { key = k, label = ns.T("card.view_" .. k) } end
    card.stacks = makeSeg(ns.T("card.stacks"), stackOpts, function(k)
        setField("view", k ~= "digits" and k or nil)
    end)
    sizeSeg(card.stacks, #stackOpts)
    card.view = makeSeg(ns.T("card.view"), {}, function(k)
        local st = state
        if not st then return end
        if not ns.buffbar:SetWidgetView(st.key, st.x, st.y, k) then E.Refresh() end
    end)
    card.bless = makeSeg(ns.T("card.bless"), {
        { key = "great", label = ns.T("card.bless_great") },
        { key = "plain", label = ns.T("card.bless_plain") },
    }, function(k)
        local st = state
        local f = st and iconOf(st)
        if f then ns.buffbar:FlipBlessing(f, k == "plain") end
    end)
    sizeSeg(card.bless, 2)
    card.who = makeWho()
    card.foodIcon = makeSeg(ns.T("card.food_icon"), {
        { key = "buff", label = ns.T("card.food_icon_buff") },
        { key = "item", label = ns.T("card.food_icon_item") },
    }, function(k) setField("foodIcon", k == "item" or nil) end)
    sizeSeg(card.foodIcon, 2)
    local procOpts = {}
    for i, k in ipairs(PROC_KEYS) do
        procOpts[i] = { key = k, label = ns.T("card.proc_" .. k), tip = ns.T("card.proc_" .. k .. "_tip") }
    end
    card.proc = makeSeg(ns.T("card.proc"), procOpts, function(k)
        setField("procLink", k ~= "glow" and k or nil)
    end)
    sizeSeg(card.proc, #procOpts)
    card.style = ns.StyleUI.ItemButton(card)
    card.style.onChange = function() E.Refresh() end
    driver = CreateFrame("Frame")
    driver:Hide()
    driver:SetScript("OnUpdate", function(_, elapsed) E.Tick(elapsed) end)
    local watch = CreateFrame("Frame")
    watch:RegisterEvent("PLAYER_REGEN_DISABLED")
    watch:RegisterEvent("PLAYER_REGEN_ENABLED")
    watch:SetScript("OnEvent", function() E.Refresh() end)
    style()
    if ns.OnTheme then ns.OnTheme(style) end
end
function E.Hover(key, x, y)
    if state and card:IsShown() and (over(card) or (menu:IsShown() and over(menu))) then key = nil end
    local f = key and x and y and cellFrame(key, x, y) or nil
    if f and not cardable(f) then f = nil end
    if f ~= hoverF then
        hoverF = f
        hoverT = 0
        if f ~= mutedF then mutedF = nil end
    end
    if (hoverF or state) and driver then driver:Show() end
end
local function hovering()
    local fr = hoverF and ns.Blocks.Frame(hoverF._key)
    local o = fr and fr.over
    return o and o:IsShown() and over(o) or false
end
function E.Tick(elapsed)
    if not editing() or dragging() then
        hoverT = 0
        if state then close() end
        if not editing() then
            hoverF = nil
            driver:Hide()
        end
        return
    end
    if hoverF and not hovering() then
        hoverF, hoverT = nil, 0
    end
    local st = state
    if hoverF and hoverF ~= mutedF then
        local same = st and hoverF._key == st.key and hoverF._cx == st.x and hoverF._cy == st.y
        if not same then
            hoverT = hoverT + elapsed
            if hoverT >= OPEN_DELAY then
                hoverT = 0
                open(hoverF)
            end
        end
    end
    st = state
    if st then
        local onCard = hoverF ~= nil or over(card) or (menu:IsShown() and over(menu))
        if ns.StyleUI.Holding(card.style.btn) then onCard = true end
        local focus = (card.name:IsShown() and card.name.box:HasFocus()) or (card.text:IsShown() and card.text.field.box:HasFocus())
        focus = focus and true or false
        local picking = card.color:IsShown() and ColorPickerFrame and ColorPickerFrame:IsShown() and true or false
        local pressed = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
        if onCard or picking then
            awayT = 0
        elseif pressed then
            dismiss()
        elseif focus then
            awayT = 0
        else
            awayT = awayT + elapsed
            if awayT >= CLOSE_DELAY then close() end
        end
    end
    if not hoverF and not state then driver:Hide() end
end
function E.IsShown()
    return card ~= nil and card:IsShown() and true or false
end
function E.State()
    return state
end
function E.Frame()
    return card
end
function E.Menu()
    return menu
end
function E.Controls()
    return controls
end
function E.Open(f)
    if not card or not editing() then return end
    open(f)
    if driver then driver:Show() end
end
function E.Close()
    close()
end
function E.Refresh()
    local st = state
    if not st then return false end
    local f = iconOf(st)
    if not f or not cardable(f) then
        close()
        return false
    end
    fill(f)
    return true
end
if ns.Blocks and ns.Blocks.OnHover then
    ns.Blocks.OnHover(function(key, x, y)
        if card then E.Hover(key, x, y) end
    end)
end
build()
ns.entrycardLoaded = true

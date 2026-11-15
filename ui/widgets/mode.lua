local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MINI = 0.45
local EDGE = ns.STATE
local HOT = ns.STATE.text
local MARK_C = ns.STATE.ok
local GOLD = ns.STATE.full
local BLACK = { 0, 0, 0, 1 }
local WHITE_C = ns.STATE.text
local DIM_NONE = 0.4
local DIM_OFF = 0.3
local GLOW_TEX = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SPAN = 1.9
local CORNER = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }
local CORNER_OUT = 3
local LABEL_GAP = 4
local LIGHTEN = 0.25
local function data()
    return ns.widgetData.mode
end
local function gridOf()
    local n = #ns.Mode.Modes()
    if n == 0 then return 1, 1 end
    local d = data()
    if n <= d.max then return n, 1 end
    return d.cols, math.ceil(n / d.cols)
end
local function tile(parent, top, x, y, s)
    local o = {}
    o.edge = parent:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = parent:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    local dot = math.max(4, math.floor(s * 0.22))
    o.ring = top:CreateTexture(nil, "OVERLAY")
    o.ring:SetTexture(WHITE)
    o.ring:SetPoint("TOPRIGHT", o.edge, "TOPRIGHT", -2, -2)
    o.ring:SetWidth(dot)
    o.ring:SetHeight(dot)
    o.under = top:CreateTexture(nil, "OVERLAY")
    o.under:SetTexture(WHITE)
    o.under:SetPoint("BOTTOMLEFT", o.edge, "BOTTOMLEFT", 2, 2)
    o.under:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -2, 2)
    o.under:SetHeight(2)
    o.text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.text:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -2, 2)
    o.text:SetJustifyH("RIGHT")
    return o
end
local function buildRow(parent, cols, rows, cell, gap, gapY)
    local top = CreateFrame("Frame", nil, parent)
    top:SetAllPoints(parent)
    local out = {}
    local n = #ns.Mode.Modes()
    for i = 1, n do
        local cx, cy = (i - 1) % cols, math.floor((i - 1) / cols)
        if cy < rows then out[i] = tile(parent, top, cx * (cell + gap), cy * (cell + gapY), cell) end
    end
    return out
end
local function paintRow(cells, st)
    local W = ns.Widget
    for i, m in ipairs(st.modes) do
        local o = cells[i]
        if o then
            local isCur, isExp, known = m.key == st.current, m.key == st.expect, st.known[i]
            W.Tex(o.icon, m.icon or ns.QMARK, not known)
            W.Alpha(o.icon, known and 1 or DIM_OFF)
            local edge
            if isCur then
                edge = HOT
            elseif isExp then
                if st.verdict == "off" then edge = EDGE.off
                elseif st.mark == "frame" then edge = EDGE.ok
                else edge = EDGE.bad end
            end
            if edge then W.Color(o.edge, edge) end
            W.Alpha(o.edge, edge and 1 or 0)
            local marked = isExp and st.verdict ~= "off" and st.mark ~= "frame"
            W.Color(o.ring, MARK_C)
            W.Color(o.under, MARK_C)
            W.Alpha(o.ring, (marked and st.mark == nil) and 1 or 0)
            W.Alpha(o.under, (marked and st.mark == "under") and 1 or 0)
            W.Text(o.text, (isCur and st.count > 1) and tostring(st.count) or "")
            W.Color(o.text, WHITE_C)
        end
    end
end
local function buildPulse(layer, s)
    local pulse = CreateFrame("Frame", nil, layer)
    pulse:SetAllPoints(layer)
    pulse.glow = pulse:CreateTexture(nil, "OVERLAY")
    pulse.glow:SetTexture(GLOW_TEX)
    pulse.glow:SetBlendMode("ADD")
    pulse.glow:SetWidth(s * GLOW_SPAN)
    pulse.glow:SetHeight(s * GLOW_SPAN)
    pulse.glow:SetPoint("CENTER", layer, "CENTER", 0, 0)
    pulse.corner = CreateFrame("Frame", nil, pulse)
    pulse.corner:SetPoint("TOPLEFT", layer, "TOPLEFT", -CORNER_OUT, CORNER_OUT)
    pulse.corner:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", CORNER_OUT, -CORNER_OUT)
    pulse.corner:SetBackdrop(CORNER)
    pulse:Hide()
    return pulse
end
local function buildOne(layer)
    local s = layer.h
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    local o = tile(layer, top, 0, 0, s)
    o.pulse = buildPulse(layer, s)
    o.label = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    o.label:SetPoint("TOP", layer, "BOTTOM", 0, -LABEL_GAP)
    o.label:Hide()
    local ms = math.floor(s * MINI)
    o.miniBg = top:CreateTexture(nil, "BACKGROUND")
    o.miniBg:SetTexture(WHITE)
    o.miniBg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    o.miniBg:SetWidth(ms + 2)
    o.miniBg:SetHeight(ms + 2)
    o.mini = top:CreateTexture(nil, "ARTWORK")
    o.mini:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", -1, 1)
    o.mini:SetWidth(ms)
    o.mini:SetHeight(ms)
    layer.one = o
    local cols, rows = gridOf()
    local cell, gap, gapY = layer.cell or s, layer.gap or 2, layer.gapY or 2
    local fly = CreateFrame("Frame", nil, layer)
    local fw, fh = cols * cell + (cols - 1) * gap, rows * cell + (rows - 1) * gapY
    fly:SetWidth(fw)
    fly:SetHeight(fh + gapY)
    fly:SetPoint("BOTTOMLEFT", layer, "TOPLEFT", 0, 0)
    local bg = fly:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetVertexColor(0, 0, 0, 0.75)
    bg:SetPoint("TOPLEFT", fly, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", fly, "TOPRIGHT", 1, -fh - 1)
    fly.cells = buildRow(fly, cols, rows, cell, gap, gapY)
    fly:Hide()
    layer.fly = fly
end
local function paintRemind(o, st, e)
    local v = st.verdict
    local c = st.color
    local alert = st.glow and e and (v == "none" or v == "bad") and true or false
    if alert then
        if o.glowC ~= c then
            o.glowC = c
            o.pulse.glow:SetVertexColor(c[1], c[2], c[3])
            o.pulse.corner:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        end
        if not o.pulse:IsShown() then o.pulse:Show() end
    elseif o.pulse:IsShown() then
        o.pulse:Hide()
    end
    ns.Anim.Pulse(o.pulse, alert)
    local text = st.label and e and e.name or nil
    ns.Widget.Text(o.label, text or "")
    if text then
        if o.labelC ~= c then
            o.labelC = c
            o.label:SetTextColor(c[1] + (1 - c[1]) * LIGHTEN, c[2] + (1 - c[2]) * LIGHTEN, c[3] + (1 - c[3]) * LIGHTEN)
        end
        if not o.label:IsShown() then o.label:Show() end
    elseif o.label:IsShown() then
        o.label:Hide()
    end
end
local function paintOne(layer, st)
    local W = ns.Widget
    local o = layer.one
    local e = ns.Mode.Get(st.expect)
    local cur = ns.Mode.Get(st.current)
    local v = st.verdict
    local big, desat, alpha, mini, miniC
    if not e then
        alpha = 0
    elseif v == "ok" then
        big, alpha = e.icon, 1
    elseif v == "off" then
        big, desat, alpha = e.icon, true, DIM_OFF
    else
        local showOther = v == "bad" and st.other ~= "none" and cur ~= nil
        if showOther and st.other == "swap" then
            big, alpha, mini, miniC = cur.icon, 1, e.icon, GOLD
        else
            big, desat, alpha = e.icon, true, DIM_NONE
            if showOther then mini, miniC = cur.icon, BLACK end
        end
    end
    W.Tex(o.icon, big or ns.QMARK, desat)
    W.Alpha(o.icon, alpha)
    local edge = e and v ~= "ok" and EDGE[v] or nil
    if edge then W.Color(o.edge, edge) end
    W.Alpha(o.edge, edge and 1 or 0)
    W.Tex(o.mini, mini or ns.QMARK, false)
    W.Alpha(o.mini, mini and 1 or 0)
    W.Color(o.miniBg, miniC or BLACK)
    W.Alpha(o.miniBg, mini and 1 or 0)
    W.Alpha(o.ring, 0)
    W.Alpha(o.under, 0)
    W.Text(o.text, (e and v == "ok" and st.count > 1) and tostring(st.count) or "")
    W.Color(o.text, WHITE_C)
    paintRemind(o, st, e)
    if layer.fly then paintRow(layer.fly.cells, st) end
end
local function build(layer, view)
    if view == "one" then
        buildOne(layer)
        return
    end
    local cols, rows = gridOf()
    layer.cells = buildRow(layer, cols, rows, layer.cell or layer.h, layer.gap or 2, layer.gapY or 2)
end
local function paint(layer, st, view)
    if view == "one" then
        paintOne(layer, st)
        return
    end
    paintRow(layer.cells, st)
end
local function castAttrs(spell)
    if not spell then return {} end
    return { type = "macro", macrotext = "/cast !" .. spell }
end
local ONE_CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st) return castAttrs(st.spell) end },
}
local rowCells = {}
local flyCells = {}
local function modeAttrs(i)
    return function(st)
        local m = st.modes[i]
        return castAttrs(m and st.known[i] and ns.Mode.Spell(m) or nil)
    end
end
local function modePost(i)
    return function(b, button, st)
        local h = b.host
        local m = st and st.modes[i]
        if button ~= "LeftButton" or InCombatLockdown() or not h or h.edit or not m or not st.known[i] then return end
        local at = h.addr
        if at and ns.buffbar then
            ns.buffbar:SetWidgetOpt(at[1], at[2], at[3], "ppAt", ns.Mode.PPIndex())
            ns.buffbar:SetWidgetOpt(at[1], at[2], at[3], "expect", m.key)
        else
            h.opt.expect, h.opt.ppAt = m.key, ns.Mode.PPIndex()
            ns.Widget.SetOpt(h, h.opt)
        end
    end
end
local function gridCells(store, dy)
    local _, class = UnitClass("player")
    local list = store[class or ""]
    if list then return list end
    list = {}
    local cols, rows = gridOf()
    for i = 1, #ns.Mode.Modes() do
        local cx, cy = (i - 1) % cols, math.floor((i - 1) / cols)
        if cy < rows then list[i] = { cx = cx, cy = cy + dy * rows, attrs = modeAttrs(i), post = modePost(i) } end
    end
    store[class or ""] = list
    return list
end
local function isOne(item)
    return ns.Widget.ViewOf("mode", item.view) == "one"
end
local function hasRemind(item)
    local opt = item.opt
    return isOne(item) and opt ~= nil and (opt.glow or opt.label) and true or false
end
local function coverList()
    local out = { "slot:aura" }
    local c = ns.Mode.Class()
    for _, m in ipairs(c and c.modes or {}) do
        out[#out + 1] = "spell:" .. m.id
        for _, id in ipairs(m.alt or {}) do out[#out + 1] = "spell:" .. id end
    end
    return out
end
local firstMode = ns.Mode.Class() and ns.Mode.Class().modes[1]
ns.Widget.Register("mode", {
    icon = firstMode and firstMode.id or 2457,
    label = "widget.mode",
    personal = true,
    views = { one = { w = 1, h = 1 }, row = function() return gridOf() end },
    order = { "one", "row" },
    view = "one",
    covers = coverList(),
    avail = function() return ns.Mode.Avail() end,
    events = {
        UPDATE_SHAPESHIFT_FORM = true, UPDATE_SHAPESHIFT_FORMS = true, UNIT_AURA = "player", SPELLS_CHANGED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true, PLAYER_ENTERING_WORLD = true,
        PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PARTY_MEMBERS_CHANGED = true, RAID_ROSTER_UPDATE = true, CHAT_MSG_ADDON = "PLPWR",
    },
    delay = { CHAT_MSG_ADDON = 0.3 },
    State = function(opt)
        local st = ns.Mode.State(opt)
        st.other, st.mark = opt and opt.other or nil, opt and opt.mark or nil
        if st.other == "diag" then st.other = nil end
        st.glow, st.label = opt and opt.glow or nil, opt and opt.label or nil
        st.color = ns.Mode.GlowColor(opt)
        return st
    end,
    active = function(st, opt) return ns.Mode.Active(st, opt) end,
    driver = function(st, opt) return ns.Mode.Driver(st, opt) end,
    Build = build,
    Paint = paint,
    cells = function(view)
        if view == "one" then return ONE_CELLS end
        return gridCells(rowCells, 0)
    end,
    flyout = function(view)
        if view ~= "one" then return nil end
        return gridCells(flyCells, -1)
    end,
    Caption = function(st, opt)
        local e = ns.Mode.Get(st.expect)
        local parts = { e and e.name or ns.T("widget.m_src_none") }
        if st.source == "pp" then
            parts[#parts + 1] = ns.T("widget.m_src_pp")
        elseif opt and opt.pp and ns.Mode.PPLoaded() and not st.ppIdx then
            parts[#parts + 1] = ns.T("widget.m_src_pp_none")
        end
        return table.concat(parts, ns.T("facts.sep"))
    end,
    opts = {
        { key = "expect", label = "widget.m_expect", kind = "icons",
          values = function()
              local out = {}
              for _, m in ipairs(ns.Mode.Modes()) do out[#out + 1] = { v = m.key, icon = m.icon, text = m.name } end
              return out
          end,
          cur = function(item) return (ns.Mode.Expected(item.opt or {})) end,
          with = function(_, v) return { ppAt = v and ns.Mode.PPIndex() or nil } end },
        { key = "when", label = "widget.m_when", values = {
            { v = nil, label = "widget.m_when_always" }, { v = "none", label = "widget.m_when_none" }, { v = "ok", label = "widget.m_when_ok" },
        } },
        { key = "other", label = "widget.m_other", when = isOne, values = {
            { v = nil, label = "widget.m_other_mini" }, { v = "swap", label = "widget.m_other_swap" },
            { v = "none", label = "widget.m_other_none" },
        } },
        { key = "mark", label = "widget.m_mark", when = function(item) return not isOne(item) end, values = {
            { v = nil, label = "widget.m_mark_ring" }, { v = "frame", label = "widget.m_mark_frame" }, { v = "under", label = "widget.m_mark_under" },
        } },
        { key = "glow", label = "widget.m_glow", when = isOne, values = {
            { v = nil, label = "widget.m_off" }, { v = true, label = "widget.m_on" },
        } },
        { key = "label", label = "widget.m_label", when = isOne, values = {
            { v = nil, label = "widget.m_off" }, { v = true, label = "widget.m_on" },
        } },
        { key = "color", label = "widget.m_color", kind = "color", when = hasRemind, palette = function() return ns.Mode.ClassColor() end },
        { key = "pp", label = "widget.m_pp", when = function() return ns.Mode.PPLoaded() end, values = {
            { v = nil, label = "widget.m_pp_off" }, { v = true, label = "widget.m_pp_on" },
        } },
    },
})
ns.modeWidgetLoaded = true

local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local INK = ns.STATE
local COUNT = 4
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
end
local function inkOf(hit)
    if not (hit and hit.on) then return INK.none end
    return hit.pct < hit.full and INK.soon or INK.ok
end
local function build(layer, view)
    local d = ns.widgetData.tdebuff
    local s = layer.h
    if view ~= "row" then
        local bg = layer:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(WHITE)
        bg:SetAllPoints(layer)
        bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
        layer.num = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        fontSize(layer.num, s * d.wideFont)
        layer.num:SetPoint("CENTER", layer, "CENTER", 0, 0)
        return
    end
    layer.slots = {}
    local step = s + (layer.gap or 2)
    for i = 1, COUNT do
        local edge = layer:CreateTexture(nil, "BORDER")
        edge:SetTexture(WHITE)
        edge:SetPoint("TOPLEFT", layer, "TOPLEFT", (i - 1) * step, 0)
        edge:SetWidth(s)
        edge:SetHeight(s)
        local icon = layer:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", edge, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -1, 1)
        layer.slots[i] = { edge = edge, icon = icon }
    end
end
local function paint(layer, st)
    local W = ns.Widget
    local d = ns.widgetData.tdebuff
    if layer.num then
        W.Text(layer.num, ns.T("widget.td_stacks", st.n, #st.set))
        W.Color(layer.num, INK[st.verdict])
        return
    end
    for i, slot in ipairs(layer.slots) do
        local cat, hit = st.set[i], st.cats[i]
        local on = hit and hit.on
        W.Tex(slot.icon, on and hit.icon or (cat and ns.TDebuff.Icon(cat)) or d.icon, not on)
        W.Alpha(slot.icon, on and 1 or d.dim)
        W.Color(slot.edge, inkOf(hit))
    end
end
local ONE = { { l = 0, t = 0, r = 1, b = 1 } }
local ROW = {}
for i = 1, COUNT do ROW[i] = { cx = i - 1, cy = 0 } end
local function summary(st)
    local rows = {}
    for i, hit in ipairs(st.cats) do
        local label = ns.T(ns.widgetData.tdebuff.cats[st.set[i]].label)
        if hit.on then
            rows[#rows + 1] = { l = label, r = hit.name, rc = inkOf(hit) }
        else
            rows[#rows + 1] = { l = label, r = ns.T("widget.td_none"), rc = INK.none }
        end
    end
    return rows
end
local DEMO = { solo = 0, party = 2, raid = COUNT }
local function demo(scene)
    local d = ns.widgetData.tdebuff
    local n = DEMO[scene.size] or COUNT
    local st = { idle = false, cats = {}, n = n, set = d.sets.phys, verdict = (n >= COUNT and "ok") or (n > 0 and "soon") or "none" }
    for i, cat in ipairs(st.set) do
        local full = d.cats[cat].full
        st.cats[i] = { cat = cat, on = i <= n, icon = d.icon, count = 0, pct = i <= n and full or 0, full = full }
    end
    return st
end
ns.Widget.Register("tdebuff", {
    info = { text = "widget.tdebuff_info", demo = demo },
    icon = "Interface\\Icons\\Spell_Shadow_ChillTouch",
    label = "widget.tdebuff",
    general = true,
    views = { one = { w = 1, h = 1 }, row = { w = COUNT, h = 1 } },
    order = { "one", "row" },
    view = "one",
    avail = function() return true end,
    events = { UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, PLAYER_ENTERING_WORLD = true },
    State = function(opt)
        local set = ns.TDebuff.Set(opt)
        local st = ns.TDebuff.State(set, opt)
        st.set = set
        return st
    end,
    active = function(st) return not st.idle end,
    Build = build,
    Paint = paint,
    cells = function(view) return view == "row" and ROW or ONE end,
    Tip = function(i, st, view)
        if st.idle then return nil end
        if view ~= "row" then return ns.T("widget.tdebuff"), nil, summary(st) end
        local hit = st.cats[i]
        if not hit then return nil end
        return ns.T(ns.widgetData.tdebuff.cats[hit.cat].label), nil, ns.TDebuff.Rows(hit)
    end,
    opts = {
        { key = "set", label = "widget.td_set", values = {
            { v = nil, label = "widget.h_kind_auto" }, { v = "phys", label = "widget.td_set_phys" },
            { v = "caster", label = "widget.td_set_caster" },
        } },
        { key = "when", label = "widget.td_when", values = {
            { v = nil, label = "widget.td_when_enemy" }, { v = "boss", label = "widget.td_when_boss" },
        } },
    },
})
ns.tdebuffWidgetLoaded = true

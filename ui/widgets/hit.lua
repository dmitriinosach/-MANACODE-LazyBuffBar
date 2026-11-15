local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local INK = ns.STATE
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
end
local function build(layer, view)
    local d = ns.widgetData.hit
    local s = layer.h
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(layer)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    layer.num = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSize(layer.sub, s * d.subFont)
    if view == "wide" then
        local pad = math.max(2, math.floor(s * 0.1 + 0.5))
        fontSize(layer.num, s * d.wideFont)
        layer.num:SetPoint("LEFT", layer, "LEFT", pad, 0)
        layer.sub:SetPoint("RIGHT", layer, "RIGHT", -pad, 0)
        return
    end
    fontSize(layer.num, s * d.numFont)
    layer.num:SetPoint("BOTTOM", layer, "CENTER", 0, -s * 0.08)
    layer.sub:SetPoint("TOP", layer, "CENTER", 0, -s * 0.1)
end
local function paint(layer, st, view)
    local W = ns.Widget
    local ink = st.verdict == "off" and INK.mute or INK[st.verdict]
    local num = ns.Hit.Num(st.total)
    W.Text(layer.num, view == "wide" and (num .. "%") or num)
    W.Color(layer.num, ink)
    W.Text(layer.sub, ns.Hit.Sub(st) or "")
    W.Color(layer.sub, ink)
end
local CELLS = { { l = 0, t = 0, r = 1, b = 1 } }
local DEMO = { solo = { 13, 0, 0 }, party = { 13, 1, 0 }, raid = { 13, 1, 3 } }
local function demo(scene)
    local d = ns.widgetData.hit
    local p = DEMO[scene.size] or DEMO.raid
    local st = { kind = "spell", heal = false, rating = math.floor(p[1] * d.per.spell + 0.5), gear = p[1], tal = 0,
        aura = p[2], tgt = p[3], cap = d.caps.spell, per = d.per.spell, verdict = "ok" }
    st.total = st.gear + st.aura + st.tgt
    st.delta = st.total - st.cap
    if st.delta < -d.eps then st.verdict = "bad" end
    return st
end
ns.Widget.Register("hit", {
    info = { text = "widget.hit_info", demo = demo },
    icon = ns.widgetData.hit.icon,
    label = "widget.hit",
    general = true,
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = function() return true end,
    events = {
        COMBAT_RATING_UPDATE = true, UNIT_AURA = { player = true, target = true }, PLAYER_TARGET_CHANGED = true,
        UNIT_INVENTORY_CHANGED = "player", PLAYER_ENTERING_WORLD = true,
    },
    State = function(opt) return ns.Hit.State(opt) end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st)
        return ns.T("widget.h_title_" .. st.kind), nil, ns.Hit.Rows(st)
    end,
    opts = {
        { key = "kind", label = "widget.h_kind", values = {
            { v = nil, label = "widget.h_kind_auto" }, { v = "spell", label = "widget.h_kind_spell" },
            { v = "melee", label = "widget.h_kind_melee" }, { v = "ranged", label = "widget.h_kind_ranged" },
        } },
    },
})
ns.hitWidgetLoaded = true

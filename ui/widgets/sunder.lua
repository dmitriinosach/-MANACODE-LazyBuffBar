local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local INK = ns.STATE
local CATS = { "armor" }
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function score(hit)
    if not (hit and hit.on) then return "0" end
    if hit.max then return tostring(hit.count) end
    return ns.T("widget.td_pct", hit.pct)
end
local function build(layer, view)
    local d = ns.widgetData.tdebuff
    local s = layer.h
    layer.edge = layer:CreateTexture(nil, "BORDER")
    layer.edge:SetTexture(WHITE)
    layer.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    layer.edge:SetWidth(s)
    layer.edge:SetHeight(s)
    layer.icon = layer:CreateTexture(nil, "ARTWORK")
    layer.icon:SetPoint("TOPLEFT", layer.edge, "TOPLEFT", 1, -1)
    layer.icon:SetPoint("BOTTOMRIGHT", layer.edge, "BOTTOMRIGHT", -1, 1)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.num = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    layer.left = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    fontSize(layer.left, s * d.leftFont)
    layer.left:SetPoint("BOTTOM", layer.edge, "BOTTOM", 0, 2)
    if view ~= "wide" then
        fontSize(layer.num, s * d.numFont)
        layer.num:SetPoint("CENTER", layer.edge, "CENTER", 0, s * 0.1)
        return
    end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    fontSize(layer.num, s * d.wideFont)
    layer.num:SetPoint("CENTER", bg, "CENTER", 0, 0)
end
local function paint(layer, st, view)
    local W = ns.Widget
    local d = ns.widgetData.tdebuff
    local hit = st.cats[1]
    local on = hit and hit.on
    local ink = INK[st.verdict]
    if hit and hit.on and hit.pct < hit.full then ink = INK.soon end
    W.Tex(layer.icon, on and hit.icon or ns.TDebuff.Icon("armor") or d.icon, not on)
    W.Alpha(layer.icon, on and 1 or d.dim)
    W.Color(layer.edge, ink)
    local text = score(hit)
    if view == "wide" and on and hit.max then text = ns.T("widget.td_stacks", hit.count, hit.max) end
    W.Text(layer.num, text)
    W.Color(layer.num, ink)
    W.Text(layer.left, on and W.Left(hit.left) or "")
end
local CELLS = { { l = 0, t = 0, r = 1, b = 1 } }
local function tip(st)
    local T = ns.TDebuff
    local rows = T.Rows(st.cats[1])
    local minor = T.Cat("armor5")
    rows[#rows + 1] = { l = minor.on and minor.name or ns.T("widget.td_armor5"),
        r = minor.on and ns.T("widget.td_pct", minor.pct) or ns.T("widget.td_none"),
        lc = (not minor.on) and INK.mute or nil, rc = minor.on and INK.ok or nil }
    local a, b = st.cats[1].pct, minor.pct
    rows[#rows + 1] = { l = ns.T("widget.h_total"), r = ns.T("widget.td_pct", math.floor(a + b - a * b / 100 + 0.5)) }
    return ns.T("widget.sunder"), nil, rows
end
local DEMO = { solo = 0, party = 3, raid = 5 }
local function demo(scene)
    local n = DEMO[scene.size] or 5
    local hit = { cat = "armor", on = n > 0, icon = ns.widgetData.tdebuff.icon, count = n, max = 5, pct = n * 4, full = 20,
        left = n > 0 and 24 or nil }
    return { idle = false, cats = { hit }, n = n > 0 and 1 or 0, verdict = n > 0 and "ok" or "none", left = hit.left }
end
ns.Widget.Register("sunder", {
    info = { text = "widget.sunder_info", demo = demo },
    icon = ns.widgetData.tdebuff.icon,
    label = "widget.sunder",
    general = true,
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = function() return true end,
    events = { UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, PLAYER_ENTERING_WORLD = true },
    tick = function(st) return (st.left and ns.widgetData.tdebuff.tick) or nil end,
    State = function(opt) return ns.TDebuff.State(CATS, opt) end,
    active = function(st) return not st.idle end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if st.idle then return nil end
        return tip(st)
    end,
    opts = {
        { key = "when", label = "widget.td_when", values = {
            { v = nil, label = "widget.td_when_enemy" }, { v = "boss", label = "widget.td_when_boss" },
        } },
    },
})
ns.sunderWidgetLoaded = true

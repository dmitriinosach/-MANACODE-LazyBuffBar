local _, ns = ...
local NAME = "war_tankdebuffs"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local INK = ns.STATE
local function cats()
    return ns.widgetData.war_tankdebuffs.cats
end
local COUNT = #cats()
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
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
    layer.tiles, layer.looks = {}, {}
    for i = 1, COUNT do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + (layer.gap or 2)), 0, s)
        layer.looks[i] = {}
    end
end
local function paint(layer, st)
    local W = ns.Widget
    local d = ns.widgetData.tdebuff
    if layer.num then
        W.Text(layer.num, ns.T("widget.td_stacks", st.n, COUNT))
        W.Color(layer.num, INK[st.verdict])
        return
    end
    for i, cat in ipairs(cats()) do
        local hit = st.cats[i]
        local on = hit and hit.on
        local k = layer.looks[i]
        k.icon = on and hit.icon or ns.TDebuff.Icon(cat) or d.icon
        k.grey = not on
        k.alpha = on and 1 or d.dim
        k.edge = on and INK.ok or INK.none
        ns.WTile.Paint(layer.tiles[i], k)
    end
end
local ONE = { { l = 0, t = 0, r = 1, b = 1 } }
local ROW = {}
for i = 1, COUNT do ROW[i] = { cx = i - 1, cy = 0 } end
local function held(hit)
    local who = ns.TDebuff.Caster(hit)
    return who ~= "" and ns.T("widget.td_by", hit.name, who) or hit.name
end
local function summary(st)
    local out = {}
    for i, hit in ipairs(st.cats) do
        local label = ns.T(ns.widgetData.tdebuff.cats[cats()[i]].label)
        if hit.on then
            out[#out + 1] = { l = label, r = held(hit), rc = INK.ok }
        else
            out[#out + 1] = { l = label, r = ns.T("widget.td_none"), rc = INK.none }
        end
    end
    return out
end
local function detail(hit)
    local out = {}
    local c = ns.widgetData.tdebuff.cats[hit.cat]
    for _, e in ipairs(c and c.list or {}) do
        local name = ns.TDebuff.Name(e.id)
        if name then
            if hit.on and hit.id == e.id then
                out[#out + 1] = { l = held(hit), r = hit.max and ns.T("widget.td_stacks", hit.count, hit.max) or nil, lc = INK.ok }
            else
                out[#out + 1] = { l = name, lc = INK.mute }
            end
        end
    end
    return out
end
local function avail()
    local _, class = UnitClass("player")
    if class == "WARRIOR" then return true end
    return ns.PlayerRole and ns.PlayerRole() == "tank" or false
end
local DEMO = { solo = 0, party = 2, raid = COUNT }
local function demo(scene)
    local d = ns.widgetData.tdebuff
    local n = DEMO[scene.size] or COUNT
    local st = { idle = false, cats = {}, n = n, verdict = (n >= COUNT and "ok") or (n > 0 and "soon") or "none" }
    for i, cat in ipairs(cats()) do
        local e = d.cats[cat].list[1]
        local name, icon = ns.TDebuff.Name(e.id)
        st.cats[i] = { cat = cat, on = i <= n, id = e.id, name = name, icon = icon, count = e.max or 0, max = e.max,
                       pct = d.cats[cat].full, full = d.cats[cat].full }
    end
    return st
end
ns.Widget.Register(NAME, {
    info = { text = "widget.war_tankdebuffs_info", demo = demo },
    icon = ns.widgetData.war_tankdebuffs.icon,
    label = "widget.war_tankdebuffs",
    views = { one = { w = 1, h = 1 }, row = { w = COUNT, h = 1 } },
    order = { "one", "row" },
    view = "one",
    avail = avail,
    events = { UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, PLAYER_ENTERING_WORLD = true },
    State = function(opt) return ns.TDebuff.State(cats(), opt) end,
    active = function(st) return not st.idle end,
    Build = build,
    Paint = paint,
    cells = function(view) return view == "row" and ROW or ONE end,
    Tip = function(i, st, view)
        if st.idle then return nil end
        if view ~= "row" then return ns.T("widget.war_tankdebuffs"), nil, summary(st) end
        local hit = st.cats[i]
        if not hit then return nil end
        return ns.T(ns.widgetData.tdebuff.cats[hit.cat].label), nil, detail(hit)
    end,
    opts = {
        { key = "when", label = "widget.td_when", values = {
            { v = nil, label = "widget.td_when_enemy" }, { v = "boss", label = "widget.td_when_boss" },
        } },
    },
})
ns.warTankDebuffsWidgetLoaded = true

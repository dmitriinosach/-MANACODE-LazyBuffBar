local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function inCat()
    local cat = GetSpellInfo(ns.widgetData.combo.cat)
    for i = 1, GetNumShapeshiftForms() or 0 do
        local _, name, active = GetShapeshiftFormInfo(i)
        if active and name == cat then return true end
    end
    return false
end
local function state()
    local d = ns.widgetData.combo
    local _, class = UnitClass("player")
    local target = UnitExists("target") and true or false
    local cp = target and (GetComboPoints("player", "target") or 0) or 0
    local emax = UnitPowerMax("player", 3) or 0
    return {
        cp = cp, max = d.max, target = target,
        energy = UnitPower("player", 3) or 0, emax = emax > 0 and emax or 100,
        dim = class == "DRUID" and not inCat(),
        ticks = d.ticks[ns.BarProfile()] or {},
    }
end
local function build(layer, view)
    local d = ns.widgetData.combo
    local w, h = layer.w, layer.h
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(layer)
    bg:SetVertexColor(0, 0, 0, 0.35)
    if view == "b" then
        layer.bar = ns.Gauge.New(layer, "bar", { w = w - 4, h = h - 10, max = 100, color = d.energy, text = true })
        layer.bar:Frame():SetPoint("BOTTOM", layer, "BOTTOM", 0, 2)
        layer.pips = ns.Gauge.New(layer, "segments", { w = w - 8, h = 6, max = d.max, color = d.color, full = d.full, gap = 3 })
        layer.pips:Frame():SetPoint("TOP", layer, "TOP", 0, -1)
        return
    end
    layer.pips = ns.Gauge.New(layer, "pips", { w = w - 8, h = math.floor(h * 0.5), max = d.max, color = d.color, full = d.full, gap = 3 })
    layer.pips:Frame():SetPoint("TOP", layer, "TOP", 0, -2)
    layer.bar = ns.Gauge.New(layer, "bar", { w = w - 6, h = math.floor(h * 0.3), max = 100, color = d.energy, text = true })
    layer.bar:Frame():SetPoint("BOTTOM", layer, "BOTTOM", 0, 2)
end
local function paint(layer, st, view)
    local d = ns.widgetData.combo
    local c = st.target and d.color or d.none
    layer.pips:SetColor(c[1], c[2], c[3], c[4])
    layer.pips:Set(st.cp, st.max)
    layer.bar:Set(st.energy, st.emax)
    if view == "b" then layer.bar:SetTicks(st.ticks) end
    ns.Widget.Alpha(layer, st.dim and 0.3 or 1)
end
ns.Widget.Register("combo", {
    icon = 2098,
    label = "widget.combo",
    views = { a = { w = 2, h = 1 }, b = { w = 3, h = 1 } },
    order = { "a", "b" },
    view = "a",
    avail = function()
        local _, class = UnitClass("player")
        if class == "ROGUE" then return true end
        return class == "DRUID" and ns.CurrentVariant() == "cat"
    end,
    events = {
        UNIT_COMBO_POINTS = true, PLAYER_TARGET_CHANGED = true, UNIT_ENERGY = "player", UNIT_MAXENERGY = "player",
        UNIT_DISPLAYPOWER = "player", UPDATE_SHAPESHIFT_FORM = true, UPDATE_SHAPESHIFT_FORMS = true,
    },
    State = state,
    Build = build,
    Paint = paint,
})
ns.comboWidgetLoaded = true

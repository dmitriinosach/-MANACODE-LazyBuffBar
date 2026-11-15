local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MAX, COLS = 12, 4
local TEXT, OK = ns.STATE.text, ns.STATE.ok
local function tile(parent, x, y, s)
    local o = {}
    o.edge = parent:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = parent:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    local top = CreateFrame("Frame", nil, parent)
    top:SetAllPoints(parent)
    o.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.count:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -2, 2)
    o.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.time:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    return o
end
local function build(layer)
    local s, gap, gapY = layer.cell or layer.h, layer.gap or 2, layer.gapY or 2
    layer.main = tile(layer, 0, 0, s)
    local fly = CreateFrame("Frame", nil, layer)
    fly:SetPoint("BOTTOMLEFT", layer, "TOPLEFT", 0, 0)
    fly:SetWidth(COLS * s + (COLS - 1) * gap)
    fly:SetHeight(3 * (s + gapY))
    fly.cells = {}
    for i = 1, MAX do
        local x, y = (i - 1) % COLS, math.floor((i - 1) / COLS)
        fly.cells[i] = tile(fly, x * (s + gap), (2 - y) * (s + gapY), s)
    end
    fly:Hide()
    layer.fly = fly
end
local function paintTile(o, item, selected, empty)
    local W = ns.Widget
    W.Tex(o.icon, item and item.icon or select(3, GetSpellInfo(ns.widgetData.food.wellFed)), not item)
    W.Alpha(o.icon, item and 1 or (empty and 0.35 or 0))
    W.Color(o.edge, selected and OK or TEXT)
    W.Alpha(o.edge, selected and 1 or 0)
    W.Text(o.count, item and tostring(item.count) or "")
end
local function paint(layer, st)
    paintTile(layer.main, st.display, st.eating, true)
    ns.Widget.Text(layer.main.time, st.left and ns.Widget.Left(st.left) or "")
    for i = 1, MAX do
        local item = st.items[i]
        paintTile(layer.fly.cells[i], item, item ~= nil and st.pick and item.id == st.pick.id)
    end
end
local MAIN = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp",
      attrs = function(st) return ns.Meal.Attrs(st.pick, st) end,
      post = function(b, button) ns.Meal.Post(b, button, false) end },
}
local FLY = {}
for i = 1, MAX do
    local index = i
    FLY[i] = { cx = (i - 1) % COLS, cy = -1 - math.floor((i - 1) / COLS), clicks = "AnyUp",
        attrs = function(st) return ns.Meal.Attrs(st.items[index], st) end,
        armed = function(b, st)
            local enabled = st.items[index] ~= nil
            if (b:IsMouseEnabled() and true or false) ~= enabled then b:EnableMouse(enabled) end
        end,
        post = function(b, button) ns.Meal.Post(b, button, true) end }
end
ns.Widget.Register("meal", {
    icon = ns.widgetData.food.wellFed,
    label = "widget.meal",
    personal = true,
    views = { one = { w = 1, h = 1 } },
    order = { "one" },
    view = "one",
    avail = function() return true end,
    events = { UNIT_AURA = "player", UNIT_HEALTH = "player", UNIT_MAXHEALTH = "player",
        UNIT_MANA = "player", UNIT_MAXMANA = "player", UNIT_DISPLAYPOWER = "player",
        PLAYER_ENTERING_WORLD = true, PLAYER_LEVEL_UP = true, PLAYER_DEAD = true, PLAYER_ALIVE = true },
    delay = { PLAYER_LEVEL_UP = 0.1 },
    tick = function(st) return (st.eating or st.pending) and 1 or nil end,
    State = function(opt) return ns.Meal.State(opt) end,
    Build = build,
    Paint = paint,
    cells = function() return MAIN end,
    flyout = function() return FLY end,
    Tip = function(i, st, _, fly)
        if fly then
            if not st.items[i] then return nil end
            return ns.Meal.Tip(st.items[i])
        end
        return ns.Meal.Tip(st.display)
    end,
    Caption = function(st) return st.pick and st.pick.name or ns.T("widget.f_nofood") end,
    opts = {
        { key = "item", label = "widget.f_item", kind = "menu", values = function() return ns.Meal.Choices() end },
    },
})

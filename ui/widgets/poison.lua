local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local HANDS = { "main", "off" }
local SLOT = { main = 16, off = 17 }
local TOP = 0.62
local EDGE = ns.STATE
local STACK = ns.STATE.stack
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local function wanted(opt)
    local out = {}
    local _, class = UnitClass("player")
    local s = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
    for _, e in ipairs(s and s.weapon or {}) do
        if e.poison then out[e.hand] = e.poison end
    end
    for _, hand in ipairs(HANDS) do
        if opt and opt[hand] then out[hand] = opt[hand] end
    end
    return out
end
local function iconOf(key)
    if not key then return nil end
    local vial = ns.weaponPoisons and ns.weaponPoisons[key] and ns.Weapon.Vial(key)
    if vial then return GetItemIcon(vial) end
    local id = ns.widgetData.poison.spells[key]
    local _, _, icon = GetSpellInfo(id or 0)
    return icon
end
local function handState(hand, want)
    local armed
    if hand == "off" then armed = OffhandHasWeapon() and true or false
    else armed = GetInventoryItemLink("player", SLOT.main) ~= nil end
    local h = { armed = armed, want = want, vial = want and ns.Weapon.Vial(want) or nil }
    h.left = armed and ns.Weapon.Left(hand) or nil
    if h.left then h.name, h.key = ns.Weapon.Name(hand) end
    if not armed then
        h.verdict = "off"
    elseif not h.left then
        h.verdict = "none"
    elseif want and h.key ~= want then
        h.verdict = "bad"
    elseif h.left < ns.widgetData.poison.soon then
        h.verdict = "soon"
    else
        h.verdict = "ok"
    end
    if h.key then
        h.icon = iconOf(h.key)
    elseif h.left then
        h.icon = GetInventoryItemTexture("player", SLOT[hand])
    else
        h.icon = iconOf(want)
    end
    return h
end
local function onTarget()
    if not UnitExists("target") then return 0, nil end
    local id = ns.widgetData.poison.debuff
    local want = GetSpellInfo(id)
    local i = 1
    while true do
        local name, _, _, count, _, _, expires, _, _, _, spellId = UnitAura("target", i, "HARMFUL|PLAYER")
        if not name then break end
        if spellId == id or name == want then
            local left = (expires and expires > 0) and (expires - GetTime()) or nil
            return count or 0, left
        end
        i = i + 1
    end
    return 0, nil
end
local function state(opt)
    local want = wanted(opt)
    local st = { main = handState("main", want.main), off = handState("off", want.off), target = UnitExists("target") and true or false }
    st.stacks, st.tleft = onTarget()
    return st
end
local function half(layer, x, w, h)
    local o = {}
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", x, 0)
    o.edge:SetWidth(w)
    o.edge:SetHeight(h)
    o.inner = layer:CreateTexture(nil, "ARTWORK")
    o.inner:SetTexture(WHITE)
    o.inner:SetVertexColor(0, 0, 0, 0.8)
    o.inner:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.inner:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    local s = h - 4
    o.icon = layer:CreateTexture(nil, "OVERLAY")
    o.icon:SetPoint("LEFT", o.edge, "LEFT", 2, 0)
    o.icon:SetWidth(s)
    o.icon:SetHeight(s)
    o.text = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.text:SetPoint("RIGHT", o.edge, "RIGHT", -2, 0)
    o.text:SetJustifyH("RIGHT")
    return o
end
local function build(layer)
    local w, h = layer.w, layer.h
    local top = math.floor(h * TOP)
    local hw = (w - 1) / 2
    layer.hands = { main = half(layer, 0, hw, top), off = half(layer, hw + 1, hw, top) }
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetVertexColor(0, 0, 0, 0.35)
    bg:SetAllPoints(layer)
    local bh = h - top - 2
    layer.pips = ns.Gauge.New(layer, "pips", { w = math.floor(w * 0.6), h = bh, max = ns.widgetData.poison.stacks, color = STACK, gap = 2 })
    layer.pips:Frame():SetPoint("BOTTOMLEFT", layer, "BOTTOMLEFT", 2, 1)
    layer.tsec = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.tsec:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", -2, 1)
    layer.tsec:SetJustifyH("RIGHT")
end
local function paint(layer, st)
    local W = ns.Widget
    for _, hand in ipairs(HANDS) do
        local o, h = layer.hands[hand], st[hand]
        W.Color(o.edge, EDGE[h.verdict])
        W.Tex(o.icon, h.icon or ns.QMARK, h.verdict == "none" or h.verdict == "off")
        W.Alpha(o.icon, h.verdict == "off" and 0.35 or 1)
        W.Text(o.text, h.left and W.Left(h.left) or "")
        W.Color(o.text, h.verdict == "soon" and WARN_C or WHITE_C)
    end
    layer.pips:Set(st.stacks, ns.widgetData.poison.stacks)
    W.Text(layer.tsec, st.stacks > 0 and W.Left(st.tleft) or "")
end
local function cell(hand)
    local l = hand == "main" and 0 or 0.5
    return {
        l = l, t = 0, r = l + 0.5, b = TOP,
        attrs = function(st)
            local h = st[hand]
            if not (h and h.armed and h.vial) then return {} end
            return { type = "item", item = "item:" .. h.vial, ["target-slot"] = SLOT[hand] }
        end,
    }
end
local CELLS = { cell("main"), cell("off") }
local function poisonName(key)
    local id = key and ns.widgetData.poison.spells[key]
    return (id and GetSpellInfo(id)) or "?"
end
ns.Widget.Register("poisons", {
    icon = 57973,
    label = "widget.poisons",
    views = { a = { w = 2, h = 1 } },
    order = { "a" },
    view = "a",
    covers = { "weapon:main", "weapon:off", "spell:57970" },
    avail = function()
        local _, class = UnitClass("player")
        if class ~= "ROGUE" then return false end
        local s = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
        return s ~= nil and s.weapon ~= nil
    end,
    events = {
        UNIT_INVENTORY_CHANGED = "player", UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, BAG_UPDATE = true,
    },
    tick = 1,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Split = function()
        return {
            { k = "weapon:main", role = "weapon" },
            { k = "weapon:off", role = "weapon" },
            { k = "spell:" .. ns.widgetData.poison.debuff, role = "dot" },
        }
    end,
    Tip = function(i, st)
        local hand = HANDS[i]
        local h = st[hand]
        if not h then return nil end
        local title = ns.T("weapon." .. hand)
        if h.verdict == "none" then return title, ns.T("widget.p_none", poisonName(h.want)) end
        if h.verdict == "bad" then return title, ns.T("widget.p_bad", h.name or "?", poisonName(h.want)) end
        return nil
    end,
})
ns.poisonWidgetLoaded = true

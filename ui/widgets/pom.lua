local _, ns = ...
local NAME_PAD = 3
local function data()
    return ns.widgetData.pom
end
local NAMES = {}
local function avail()
    local _, class = UnitClass("player")
    if class ~= "PRIEST" then return false end
    local d = data()
    if ns.IsLearned(d.id) then return true end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function state()
    local d = data()
    local st = { charges = 0, left = 0, cd = 0 }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    local aura = GetSpellInfo(d.aura)
    local R = ns.Raid
    if st.spell and aura and R then
        NAMES[1] = aura
        R.Watch("pom", NAMES, true)
        R.Touch()
        local now = GetTime()
        local best
        for _, m in ipairs(R.Roster()) do
            local e, c = R.Own(m, NAMES)
            if e and (e == 0 or e > now) and (not best or e == 0 or e > best) then
                best = e
                st.who, st.class, st.charges = m.name, m.class, c or 0
                st.left = e > 0 and (e - now) or 0
            end
        end
    end
    if st.spell then st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell)) end
    if not st.spell then
        st.why, st.verdict = "none", "off"
    elseif st.who then
        st.why = "on"
        st.verdict = (st.left > 0 and st.left < d.soon) and "soon" or "ok"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "off"
    else
        st.why, st.verdict = "ready", "full"
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -NAME_PAD, -NAME_PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", NAME_PAD, NAME_PAD)
    layer.sub:SetJustifyH("LEFT")
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    local on = st.why == "on"
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = v == "off" and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "full" and S.full) or nil
    k.text = on and tostring(st.charges) or (st.cd > 0 and W.Left(st.cd) or "")
    k.textColor = S.text
    k.corner = (on and view ~= "wide" and st.left > 0) and W.Left(st.left) or nil
    k.cornerColor = v == "soon" and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.who, on and st.who or "")
    W.Color(layer.who, on and ns.WTile.ClassColor(st.class) or S.text)
    W.Text(layer.sub, (on and st.left > 0) and W.Left(st.left) or "")
    W.Color(layer.sub, v == "soon" and S.soon or S.text)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local DEMO = {
    solo  = { 0, 0, nil, 6 },
    party = { 4, 22, "WARRIOR" },
    raid  = { 2, 4, "PALADIN" },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local st = { spell = name, icon = icon, charges = p[1], left = p[2], cd = p[4] or 0 }
    if p[3] then
        st.who, st.class = ns.T("widget.bless_demo_name", 1), p[3]
        st.why = "on"
        st.verdict = st.left < d.soon and "soon" or "ok"
    else
        st.why, st.verdict = "cd", "off"
    end
    return st
end
ns.Widget.Register("pom", {
    info = { text = "widget.pom_info", demo = demo },
    icon = 48113,
    label = "widget.pom",
    class = "PRIEST",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:48113" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
    },
    tick = function(st) return (st.why == "on" or st.cd > 0) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if st.why ~= "on" then return nil end
        return st.spell, ns.T("widget.pm_on", st.who, st.charges)
    end,
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("pom") end)
end
ns.pomWidgetLoaded = true

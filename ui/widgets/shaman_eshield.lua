local _, ns = ...
local NAME_PAD = 3
local function data()
    return ns.widgetData.shaman_eshield
end
local NAMES = {}
local last
local function learnedId()
    local d = data()
    if ns.IsLearned(d.id) then return d.id end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
local function avail()
    local _, class = UnitClass("player")
    return class == "SHAMAN" and learnedId() ~= nil
end
local function lowOf(opt)
    return (opt and opt.low) or data().low
end
local function state(opt)
    local d = data()
    local st = { charges = 0, left = 0, group = false }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.why, st.verdict = "off", "off"
        return st
    end
    local R = ns.Raid
    local holder, lost
    if R then
        NAMES[1] = st.spell
        R.Watch("shaman_eshield", NAMES, true)
        R.Touch()
        st.group = R.Grouped() and true or false
        local now = GetTime()
        local best
        for _, m in ipairs(R.Roster()) do
            local e, c = R.Own(m, NAMES)
            if e and (e == 0 or e > now) and (not best or e == 0 or e > best) then
                best, holder = e, m
                st.charges = c or 0
                st.left = e > 0 and (e - now) or 0
            end
            if last and m.guid == last.guid and (m.dead or m.off) then lost = m end
        end
        if holder then
            if not (last and last.guid == holder.guid) then
                last = { guid = holder.guid, name = holder.name, class = holder.class }
            end
            lost = nil
        elseif not lost then
            last = nil
        end
    end
    st.group = (st.group or InCombatLockdown()) and true or false
    if holder then
        st.who, st.class = holder.name, holder.class
        local low = st.charges <= lowOf(opt) or (st.left > 0 and st.left < d.soon)
        st.why = low and "low" or "on"
        st.verdict = low and "soon" or "ok"
    elseif lost then
        st.who, st.class = lost.name, lost.class
        st.why, st.verdict = "dead", "bad"
    else
        st.why, st.verdict = "gone", "none"
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
    local on = st.why == "on" or st.why == "low"
    local k = layer.look
    k.icon = st.icon
    k.grey = st.why == "gone" or st.why == "off"
    k.alpha = (st.why == "gone" or st.why == "off") and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or ((v == "bad" or v == "none") and S.bad) or nil
    k.text = on and tostring(st.charges) or ""
    k.textColor = v == "soon" and S.soon or S.text
    k.mark = st.why == "dead" and ns.T("widget.ses_dead_mark") or nil
    k.markColor = S.bad
    k.corner = (on and view ~= "wide" and st.left > 0) and W.Left(st.left) or nil
    k.cornerColor = v == "soon" and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.who, st.who or (st.why == "gone" and ns.T("widget.ses_nobody") or ""))
    W.Color(layer.who, st.who and ns.WTile.ClassColor(st.class) or S.bad)
    local sub = (on and st.left > 0 and W.Left(st.left)) or (st.why == "dead" and ns.T("widget.ses_dead")) or ""
    W.Text(layer.sub, sub)
    W.Color(layer.sub, (v == "soon" and S.soon) or (v == "bad" and S.bad) or S.text)
end
local function targetOf(opt)
    local to = opt and opt.to
    if to == "focus" or to == "target" then return to end
    local u = ns.Units and ns.Units.Resolve("tank")
    if not u then return nil end
    local m = ns.Raid and ns.Raid.Member(u)
    return (m and m.click) or u
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp", attrs = function(st, opt)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell, unit = targetOf(opt),
            type2 = "spell", spell2 = st.spell, unit2 = "focus" }
    end },
}
local DEMO = {
    solo  = { "gone", 0, 0 },
    party = { "on", 6, 420, "WARRIOR" },
    raid  = { "dead", 0, 0, "PALADIN" },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(data().id)
    local st = { spell = name, icon = icon, why = p[1], charges = p[2], left = p[3], group = scene.size ~= "solo" }
    if p[4] then st.who, st.class = ns.T("widget.bless_demo_name", 1), p[4] end
    st.verdict = (p[1] == "on" and "ok") or (p[1] == "dead" and "bad") or "none"
    return st
end
local LOWS = {}
for _, n in ipairs(ns.widgetData.shaman_eshield.lows) do
    LOWS[#LOWS + 1] = { v = n ~= ns.widgetData.shaman_eshield.low and n or nil, text = tostring(n) }
end
ns.Widget.Register("shaman_eshield", {
    info = { text = "widget.shaman_eshield_info", demo = demo },
    icon = 49284,
    label = "widget.shaman_eshield",
    class = "SHAMAN",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:49284" },
    avail = avail,
    units = function(opt)
        local to = opt and opt.to
        if to == "focus" or to == "target" then return nil end
        return { "tank" }
    end,
    events = {
        SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
        PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, PLAYER_FOCUS_CHANGED = true,
    },
    tick = function(st) return (st.why == "on" or st.why == "low") and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.why ~= "off" and (st.why ~= "gone" or st.group) end,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if not st.spell then return nil end
        local line
        if st.why == "on" or st.why == "low" then
            line = ns.T("widget.ses_on", st.who, st.charges, ns.Widget.Left(st.left))
        elseif st.why == "dead" then
            line = ns.T("widget.ses_dead_tip", st.who)
        else
            line = ns.T("widget.ses_none")
        end
        return st.spell, line, { { l = ns.T("widget.ses_click") } }
    end,
    opts = {
        { key = "to", label = "widget.ses_to", values = {
            { v = nil, label = "widget.ses_to_tank" },
            { v = "focus", label = "widget.ses_to_focus" },
            { v = "target", label = "widget.ses_to_target" },
        } },
        { key = "low", label = "widget.ses_low", values = LOWS },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("shaman_eshield") end)
end
if ns.Units then
    ns.Units.OnChange(function() ns.Widget.Poke("shaman_eshield") end)
end
ns.shamanEshieldWidgetLoaded = true

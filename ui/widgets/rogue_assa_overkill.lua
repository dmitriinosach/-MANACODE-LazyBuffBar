local _, ns = ...
local NAME = "rogue_assa_overkill"
local ENERGY = 3
local BAR_PAD = 6
local function data()
    return ns.widgetData.rogue_assa_overkill
end
local function window()
    local _, class = UnitClass("player")
    if class ~= "ROGUE" then return nil end
    for _, w in ipairs(data().windows) do
        if ns.IsLearned(w.talent) then return w end
    end
    return nil
end
local function auraLeft(id, now)
    for i = 1, data().auraMax do
        local n, _, _, _, _, _, expires, _, _, _, sid = UnitAura("player", i, "HELPFUL")
        if not n then break end
        if sid == id then
            if expires and expires > 0 then return true, math.max(0, expires - now) end
            return true, 0
        end
    end
    return false, 0
end
local function enemy()
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and true or false
end
local function state(opt)
    local d = data()
    local max = UnitPowerMax("player", ENERGY) or 0
    local st = {
        cd = 0, left = 0, win = 0, energy = UnitPower("player", ENERGY) or 0, max = max > 0 and max or 100,
        low = tonumber(opt and opt.low) or d.low, fight = UnitAffectingCombat("player") and true or false,
    }
    local w = window()
    if not w then
        st.why, st.verdict = "none", "hide"
        return st
    end
    local name, _, icon = GetSpellInfo(d.vanish)
    local wname, _, wicon = GetSpellInfo(w.aura)
    st.spell, st.icon, st.wname, st.wicon = name, icon, wname, wicon
    st.win = w.win
    st.cd = name and ns.WTile.Left(d.gcd, GetSpellCooldown(name)) or 0
    local has, left = auraLeft(w.aura, GetTime())
    st.left = left
    local grouped = (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0
    if has then
        st.why, st.verdict = left > 0 and "window" or "shadow", "act"
    elseif not st.fight then
        st.why, st.verdict = "ooc", "off"
    elseif not grouped then
        st.why, st.verdict = "solo", "off"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "soon"
    elseif not enemy() then
        st.why, st.verdict = "notarget", "off"
    elseif st.energy < st.low then
        st.why, st.verdict = "low", "go"
    else
        st.why, st.verdict = "high", "ok"
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.look = {}
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    layer.bar = ns.Gauge.New(layer, "bar", { w = layer.w - s - gap, h = s - BAR_PAD * 2, max = 100, color = data().bar,
        text = true, flash = false })
    layer.bar:Frame():SetPoint("LEFT", layer, "LEFT", s + gap, 0)
end
local NO_TICKS = {}
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local act = v == "act"
    local k = layer.look
    k.icon = act and st.wicon or st.icon
    k.grey = st.cd > 0 and not act
    k.alpha = (v == "off" or not st.fight) and data().dim or 1
    k.edge = act and S.ok or nil
    k.text = (st.why == "window" and W.Left(st.left)) or (st.cd > 0 and not act and W.Left(st.cd)) or ""
    k.textColor = (act and S.ok) or (v == "off" and S.mute) or S.text
    k.corner = st.why == "shadow" and ns.T("widget.rogue_assa_ok_shadow_s") or nil
    k.cornerColor = S.ok
    k.glow = v == "go"
    ns.WTile.Paint(layer.tile, k)
    if not layer.bar then return end
    if act then
        local c = data().win
        layer.bar:SetColor(c[1], c[2], c[3], c[4])
        layer.bar:SetTicks(NO_TICKS)
        layer.bar:Set(st.why == "window" and math.floor(st.left + 0.5) or st.win, st.win)
        return
    end
    local c = (v == "off" and S.mute) or data().bar
    layer.bar:SetColor(c[1], c[2], c[3], c[4])
    if layer.lowTicks == nil or layer.lowTicks[1] ~= st.low then layer.lowTicks = { st.low } end
    layer.bar:SetTicks(layer.lowTicks)
    layer.bar:Set(st.energy, st.max)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local WHY = {
    shadow = "widget.rogue_assa_ok_shadow", window = "widget.rogue_assa_ok_window", ooc = "widget.rogue_assa_ok_ooc",
    solo = "widget.rogue_assa_ok_solo", cd = "widget.rogue_assa_ok_cd", notarget = "widget.rogue_assa_ok_notarget",
    low = "widget.rogue_assa_ok_low", high = "widget.rogue_assa_ok_high",
}
local function arg(st)
    local W = ns.Widget
    if st.why == "window" then return W.Left(st.left) end
    if st.why == "low" or st.why == "high" then return tostring(st.energy) end
    return W.Left(st.cd)
end
local function tip(_, st)
    if not st.spell then return nil end
    local key = WHY[st.why]
    if not key then return nil end
    local line = ns.T(key, arg(st))
    if st.cd > 0 and st.why ~= "cd" and st.verdict ~= "act" then
        line = line .. "\n" .. ns.T("widget.rogue_assa_ok_cd", ns.Widget.Left(st.cd))
    end
    return (st.verdict == "act" and st.wname) or st.spell, line
end
local DEMO = {
    solo  = { "solo", "off", 80, 0 },
    party = { "low", "go", 25, 0 },
    raid  = { "window", "act", 60, 14 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local w = d.windows[1]
    local name, _, icon = GetSpellInfo(d.vanish)
    local wname, _, wicon = GetSpellInfo(w.aura)
    return {
        spell = name, icon = icon, wname = wname, wicon = wicon, win = w.win, cd = 0, left = p[4], energy = p[3], max = 100,
        low = tonumber(scene.opt and scene.opt.low) or d.low, fight = p[2] ~= "off", why = p[1], verdict = p[2],
    }
end
local function active(st, opt)
    local v = st.verdict
    if v == "hide" then return false end
    if opt and opt.ooc == "hide" and not st.fight then return false end
    if opt and opt.show == "ready" and v ~= "act" and st.cd > 0 then return false end
    return true
end
local function lowValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.energy) do
        out[#out + 1] = { v = n ~= d.low and n or nil, text = tostring(n) }
    end
    return out
end
ns.Widget.Register(NAME, {
    info = { text = "widget.rogue_assa_overkill_info", demo = demo },
    icon = 58427,
    label = "widget.rogue_assa_overkill",
    class = "ROGUE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:26889", "spell:58427" },
    avail = function() return window() ~= nil end,
    events = {
        SPELL_UPDATE_COOLDOWN = true, UNIT_AURA = "player", UNIT_ENERGY = "player", UNIT_MAXENERGY = "player",
        UPDATE_STEALTH = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, PLAYER_TARGET_CHANGED = true,
        UNIT_HEALTH = "target", PARTY_MEMBERS_CHANGED = true, RAID_ROSTER_UPDATE = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if st.cd > 0 or st.why == "window" then return data().tick end
        return nil
    end,
    State = state,
    active = active,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "low", label = "widget.rogue_assa_ok_opt_low", values = lowValues },
        { key = "ooc", label = "widget.rogue_assa_ok_opt_ooc", values = {
            { v = nil, label = "widget.rogue_assa_ok_ooc_dim" }, { v = "hide", label = "widget.rogue_assa_ok_ooc_hide" },
        } },
        { key = "show", label = "widget.rogue_assa_ok_opt_show", values = {
            { v = nil, label = "widget.rogue_assa_ok_show_all" }, { v = "ready", label = "widget.rogue_assa_ok_show_ready" },
        } },
    },
})
ns.rogueAssaOverkillWidgetLoaded = true

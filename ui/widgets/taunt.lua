local _, ns = ...
local function data()
    return ns.widgetData.taunt
end
local function choices()
    local _, class = UnitClass("player")
    local out = {}
    for _, id in ipairs(data().classes[class or ""] or {}) do
        if ns.IsLearned(id) then out[#out + 1] = id end
    end
    return out
end
local ANY_SPEC = { WARRIOR = true, DEATHKNIGHT = true }
local function avail()
    local _, class = UnitClass("player")
    if not data().classes[class or ""] then return false end
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local info = v and ns.SpecInfo and ns.SpecInfo(class, v)
    if not ANY_SPEC[class] and not (info and info.role == "tank") then return false end
    return #choices() > 0
end
local function pick(opt)
    local list = choices()
    local want = opt and opt.spell
    for _, id in ipairs(list) do
        if id == want then return id end
    end
    return list[1]
end
local function isTank(unit)
    if UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) then return true end
    local R = ns.Raid
    local guid = UnitGUID(unit)
    if not (R and guid and ns.Rez) then return false end
    R.Touch()
    for _, m in ipairs(R.Roster()) do
        if m.guid == guid then return ns.Rez.IsTank(m) end
    end
    return false
end
local function state(opt)
    local id = pick(opt)
    local st = { cd = 0, go = false, far = false, nores = false, unusable = false }
    if id then
        local name, _, icon = GetSpellInfo(id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.why, st.verdict = "none", "off"
        return st
    end
    st.cd = ns.WTile.Left(data().gcd, GetSpellCooldown(st.spell))
    local usable, nomana = IsUsableSpell(st.spell)
    st.nores = (not usable and nomana) and true or false
    st.unusable = (not usable and not nomana) and true or false
    if UnitIsDeadOrGhost("player") then
        st.why = "dead"
    elseif not (UnitExists("target") and UnitCanAttack("player", "target")) or UnitIsDeadOrGhost("target") then
        st.why = "notarget"
    else
        if UnitExists("targettarget") then
            st.who = UnitName("targettarget")
            local _, c = UnitClass("targettarget")
            st.whoClass = c
        end
        local tanking = UnitDetailedThreatSituation("player", "target")
        if tanking then
            st.why = "mine"
        elseif not UnitAffectingCombat("target") or not st.who then
            st.why = "calm"
        elseif UnitIsUnit("targettarget", "player") then
            st.why = "mine"
        elseif isTank("targettarget") then
            st.why = "tank"
        else
            st.why = "lost"
            st.far = IsSpellInRange(st.spell, "target") == 0
        end
    end
    if st.why ~= "lost" then
        st.verdict = "off"
    elseif st.cd > 0 then
        st.verdict = "soon"
    elseif st.nores or st.unusable then
        st.verdict = "off"
    elseif st.far then
        st.verdict = "bad"
    else
        st.verdict, st.go = "ok", true
    end
    return st
end
local function build(layer)
    layer.tile = ns.WTile.New(layer, 0, 0, layer.h)
    layer.look = {}
end
local function paint(layer, st)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local lost = st.why == "lost"
    local k = layer.look
    k.icon = st.icon
    k.grey = st.cd > 0 or st.unusable
    k.alpha = lost and 1 or data().dim
    k.tint = st.nores and data().tint or nil
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "bad" and S.bad) or nil
    k.text = st.cd > 0 and W.Left(st.cd) or ""
    k.textColor = v == "soon" and S.soon or S.text
    k.glow = st.go
    ns.WTile.Paint(layer.tile, k)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local DEMO = { solo = { "mine", 0 }, party = { "lost", 0, "PRIEST" }, raid = { "lost", 5, "MAGE" } }
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local list = data().classes[scene.class] or data().classes.WARRIOR
    local name, _, icon = GetSpellInfo(list[1])
    local st = { spell = name, icon = icon, cd = p[2], why = p[1], go = false, far = false, nores = false, unusable = false }
    if p[3] then st.who, st.whoClass = ns.T("widget.bless_demo_name", 2), p[3] end
    if st.why ~= "lost" then st.verdict = "off"
    elseif st.cd > 0 then st.verdict = "soon"
    else st.verdict, st.go = "ok", true end
    return st
end
local function coverList()
    local out = {}
    for _, list in pairs(data().classes) do
        for _, id in ipairs(list) do out[#out + 1] = "spell:" .. id end
    end
    table.sort(out)
    return out
end
ns.Widget.Register("taunt", {
    info = { text = "widget.taunt_info", demo = demo },
    icon = 355,
    label = "widget.taunt",
    views = { one = { w = 1, h = 1 } },
    order = { "one" },
    view = "one",
    covers = coverList(),
    avail = avail,
    units = function() return { "tank", "tank2" } end,
    events = {
        UNIT_THREAT_SITUATION_UPDATE = "player", UNIT_THREAT_LIST_UPDATE = "target", UNIT_TARGET = "target",
        UNIT_FLAGS = "target", PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true,
        UPDATE_SHAPESHIFT_FORM = true, SPELLS_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.cd > 0 or st.why == "lost") and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if not st.who or st.why == "notarget" then return nil end
        return st.spell, ns.T("widget.tn_who", st.who)
    end,
    opts = {
        { key = "spell", label = "widget.tn_spell", when = function() return #choices() > 1 end,
          values = function()
              local out = { { v = nil, label = "widget.tn_auto" } }
              for _, id in ipairs(choices()) do out[#out + 1] = { v = id, text = GetSpellInfo(id) or ("#" .. id) } end
              return out
          end },
    },
})
ns.tauntWidgetLoaded = true

local _, ns = ...
local NAME = "druid_bear_rage"
local RAGE = 1
local function data()
    return ns.widgetData.druid_bear_rage
end
local function judge(st)
    if st.queued then return (st.rage - st.qcost < st.need) and "soon" or "ok" end
    if st.clarity or st.rage >= st.dump then return "full" end
    if st.rage < st.need then return "mute" end
    return "text"
end
local function fill(st, costs)
    local d, K = data(), ns.WarRage
    st.marks = {}
    for i, m in ipairs(d.marks) do
        st.marks[i] = { name = GetSpellInfo(m.id), cost = costs and K.CostOf(m.id, m.cost) or m.cost }
    end
    st.ticks = K.TicksOf(st.marks)
    st.need = st.marks[1].cost
    local name, _, icon = GetSpellInfo(d.maul)
    st.qname, st.qicon = name, icon
    st.qcost = st.clarity and 0 or (costs and K.CostOf(d.maul, d.maulCost) or d.maulCost)
    st.verdict = judge(st)
end
local function state(opt)
    local d = data()
    local bear = UnitPowerType("player") == RAGE
    local max = UnitPowerMax("player", RAGE) or 0
    local cname = GetSpellInfo(d.clarity)
    local st = {
        bear = bear, rage = bear and (UnitPower("player", RAGE) or 0) or 0, max = max > 0 and max or 100,
        dump = tonumber(opt and opt.dump) or d.dump, cname = cname,
        clarity = (cname and UnitAura("player", cname)) and true or false,
        fight = UnitAffectingCombat("player") and true or false,
    }
    local maul = GetSpellInfo(d.maul)
    st.queued = (maul and IsCurrentSpell(maul)) and true or false
    fill(st, true)
    return st
end
local function demo(scene)
    local d = data()
    local st = {
        bear = true, rage = d.demoRage[scene.size] or d.demoRage.raid, max = 100, fight = true, clarity = false,
        queued = scene.size == "party", dump = tonumber(scene.opt and scene.opt.dump) or d.dump,
        cname = GetSpellInfo(d.clarity),
    }
    fill(st, false)
    return st
end
local function avail()
    if ns.PlayerClass() ~= "DRUID" then return false end
    local v = ns.CurrentVariant and ns.CurrentVariant()
    return data().variants[v or ""] == true and ns.IsLearned(data().maul)
end
local function rows(st)
    local out = ns.WarRage.Rows(st)
    if st.clarity then
        out[#out + 1] = { l = ns.T("widget.dbr_clarity", st.cname or "?", st.qname or "?"), lc = ns.STATE.full }
    end
    return out
end
local function dumpValues()
    local out = { { v = nil, label = "widget.h_kind_auto" } }
    for _, n in ipairs(data().steps) do out[#out + 1] = { v = n, text = tostring(n) } end
    return out
end
ns.Widget.Register(NAME, ns.WarRage.Def({
    info = { text = "widget.druid_bear_rage_info", demo = demo },
    icon = data().maul,
    label = "widget.druid_bear_rage",
    class = "DRUID",
    avail = avail,
    events = {
        UNIT_RAGE = "player", UNIT_MAXRAGE = "player", UNIT_DISPLAYPOWER = "player", UNIT_AURA = "player",
        CURRENT_SPELL_CAST_CHANGED = true, UPDATE_SHAPESHIFT_FORM = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, SPELLS_CHANGED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    State = state,
    active = function(st, opt)
        if not st.bear then return false end
        return (opt and opt.when == "always") or st.fight or st.rage > 0
    end,
    Tip = function(_, st)
        return ns.T("widget.druid_bear_rage"), nil, rows(st)
    end,
    opts = {
        { key = "dump", label = "widget.wr_dump", values = dumpValues },
        { key = "when", label = "widget.wr_when", values = {
            { v = nil, label = "widget.wr_when_fight" }, { v = "always", label = "widget.wr_when_always" },
        } },
    },
}))
ns.druidBearRageWidgetLoaded = true

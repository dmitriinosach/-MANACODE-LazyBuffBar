local _, ns = ...
local NAME = "druid_resto_rejuv"
local function data()
    return ns.widgetData.druid_resto_rejuv
end
local REJ = {}
local REG = {}
local ALL = {}
local function fight()
    return (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
end
local function avail()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return false end
    local d = data()
    if ns.TalentsKnown and ns.TalentsKnown() and ns.CurrentTab() ~= d.tab then return false end
    if ns.IsLearned(d.id) then return true end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function names()
    if ALL[1] then return true end
    local d = data()
    local a, j, r = GetSpellInfo(d.id), GetSpellInfo(d.jump), GetSpellInfo(d.regrowth)
    if not (a and r) then return false end
    REJ[1], ALL[1] = a, a
    if j and j ~= a then
        REJ[2] = j
        ALL[#ALL + 1] = j
    end
    REG[1] = r
    ALL[#ALL + 1] = r
    return true
end
local function judge(st, inFight)
    st.verdict = "off"
    if not st.spell then st.why = "none"
    elseif st.dead then st.why = "dead"
    elseif not st.grouped then st.why = "solo"
    elseif inFight then
        if st.keep > 0 and st.n < st.keep then st.why, st.verdict = "fight", "none"
        elseif st.keep > 0 and st.n - st.gone < st.keep then st.why, st.verdict = "fight", "soon"
        elseif st.n > 0 then st.why, st.verdict = "fight", "ok"
        else st.why = "idle" end
    elseif st.n > 0 and not st.hide then st.why, st.verdict = "calm", "calm"
    else st.why = "idle" end
    st.ticking = (st.why == "fight" or st.why == "calm") and (st.n > 0 or st.rn > 0)
end
local function blank(opt)
    local d = data()
    return {
        n = 0, gone = 0, rn = 0, stacks = 0, sleft = 0, idol = false, dead = false, grouped = false,
        keep = (opt and opt.keep) or d.keep, soon = (opt and opt.soon) or d.soon,
        hide = (opt and opt.calm == "hide") and true or false, why = "none", verdict = "off", ticking = false,
    }
end
local function idol(st, now)
    local d = data().idol
    st.idol = GetInventoryItemID("player", d.slot) == d.item
    if not st.idol then return end
    local aura = GetSpellInfo(d.aura)
    local n, _, _, count, _, _, expires = UnitBuff("player", aura or "")
    if not n then return end
    st.stacks = math.max(count or 0, 1)
    st.sleft = (expires and expires > now) and (expires - now) or 0
end
local function state(opt)
    local d = data()
    local st = blank(opt)
    if avail() and names() then
        local _, _, icon = GetSpellInfo(d.id)
        local _, _, ricon = GetSpellInfo(d.regrowth)
        st.spell, st.icon, st.rspell, st.ricon = REJ[1], icon, REG[1], ricon
    end
    local R = ns.Raid
    if st.spell and R then
        R.Watch(NAME, ALL, true)
        R.Touch()
        st.grouped = R.Grouped()
        local now = GetTime()
        for _, m in ipairs(R.Roster()) do
            local e = R.Own(m, REJ)
            if e and (e == 0 or e > now) then
                st.n = st.n + 1
                if e > 0 and e - now <= st.soon then st.gone = st.gone + 1 end
            end
            e = R.Own(m, REG)
            if e and (e == 0 or e > now) then st.rn = st.rn + 1 end
        end
        idol(st, now)
    end
    st.dead = UnitIsDeadOrGhost("player") and true or false
    judge(st, fight())
    return st
end
local function build(layer, view)
    local s = layer.cell or layer.h
    layer.tiles, layer.looks = {}, {}
    for i = 1, view == "pair" and 2 or 1 do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + (layer.gap or 2)), 0, s)
        layer.looks[i] = {}
    end
end
local function paint(layer, st)
    local S = ns.STATE
    local v = st.verdict
    local k = layer.looks[1]
    k.icon = st.icon
    k.grey = v == "none"
    k.alpha = v == "none" and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "none" and S.none) or nil
    k.text = tostring(st.n)
    k.textColor = (v == "none" and S.none) or (v == "soon" and S.soon) or S.text
    k.mark = st.gone > 0 and tostring(st.gone) or nil
    k.markColor = S.soon
    k.corner = (st.idol and st.stacks > 0) and tostring(st.stacks) or nil
    k.cornerColor = st.stacks >= data().idol.max and S.stack or S.text
    ns.WTile.Paint(layer.tiles[1], k)
    local t = layer.tiles[2]
    if not t then return end
    k = layer.looks[2]
    k.icon = st.ricon
    k.grey = st.rn == 0
    k.alpha = st.rn == 0 and data().dim or 1
    k.text = st.rn > 0 and tostring(st.rn) or ""
    ns.WTile.Paint(t, k)
end
local CELLS = {
    one  = { { cx = 0, cy = 0 } },
    pair = { { cx = 0, cy = 0 }, { cx = 1, cy = 0 } },
}
local function sooner(a, b)
    local x, y = a.left > 0 and a.left or math.huge, b.left > 0 and b.left or math.huge
    if x ~= y then return x < y end
    return a.name < b.name
end
local function hots(st, which)
    if st.demo then return st.demo[which] or {} end
    local out = {}
    local R = ns.Raid
    if not (R and st.spell) then return out end
    local list = which == 1 and REJ or REG
    local now = GetTime()
    for _, m in ipairs(R.Roster()) do
        local e = R.Own(m, list)
        if e and (e == 0 or e > now) then
            out[#out + 1] = { name = m.name, class = m.class, left = e > 0 and (e - now) or 0 }
        end
    end
    table.sort(out, sooner)
    return out
end
local function addHots(rows, list, st)
    local S = ns.STATE
    local lines = data().lines
    for i, h in ipairs(list) do
        if i > lines then
            rows[#rows + 1] = { l = ns.T("widget.drr_more", #list - lines), lc = S.mute }
            return
        end
        rows[#rows + 1] = { l = h.name, r = ns.Widget.Left(h.left), lc = ns.WTile.ClassColor(h.class),
            rc = (h.left > 0 and h.left <= st.soon) and S.soon or S.text }
    end
end
local function tip(i, st)
    if not st.spell then return nil end
    local rows = {}
    if i == 2 then
        addHots(rows, hots(st, 2), st)
        return ns.T("widget.drr_reg_title", st.rspell, st.rn), nil, rows
    end
    addHots(rows, hots(st, 1), st)
    if st.rn > 0 then rows[#rows + 1] = { l = st.rspell, r = tostring(st.rn) } end
    if st.idol then
        local aura = GetSpellInfo(data().idol.aura) or ""
        rows[#rows + 1] = st.stacks > 0 and { l = aura, r = ns.T("widget.drr_stacks", st.stacks, ns.Widget.Left(st.sleft)) }
            or { l = aura, r = ns.T("widget.drr_nostacks"), rc = ns.STATE.mute }
    end
    return ns.T("widget.drr_title", st.n), ns.T("widget.drr_keep", st.keep), rows
end
local DEMO = {
    solo  = { {}, {}, 0 },
    party = { { { "WARRIOR", 11 }, { "PRIEST", 7 }, { "MAGE", 2 } }, { { "WARRIOR", 16 } }, 8 },
    raid  = {
        { { "PALADIN", 13 }, { "DEATHKNIGHT", 12 }, { "ROGUE", 9 }, { "MAGE", 8 }, { "WARLOCK", 6 }, { "HUNTER", 5 },
          { "SHAMAN", 4 }, { "PRIEST", 2.5 }, { "WARRIOR", 1.2 } },
        { { "PALADIN", 18 }, { "DEATHKNIGHT", 9 } },
        6,
    },
}
local function demo(scene)
    local d = data()
    local st = blank(scene.opt)
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local rname, _, ricon = GetSpellInfo(d.regrowth)
    st.spell, st.icon, st.rspell, st.ricon = name, icon, rname, ricon
    st.grouped = scene.size ~= "solo"
    st.demo = { {}, {} }
    for which = 1, 2 do
        for j, h in ipairs(p[which]) do
            st.demo[which][j] = { name = ns.T("widget.bless_demo_name", j), class = h[1], left = h[2] }
        end
    end
    st.n, st.rn = #p[1], #p[2]
    for _, h in ipairs(st.demo[1]) do
        if h.left <= st.soon then st.gone = st.gone + 1 end
    end
    st.idol, st.stacks, st.sleft = p[3] > 0, p[3], 12
    judge(st, scene.fight)
    return st
end
local function steps(key, label, list, def)
    local values = {}
    for i, n in ipairs(list) do values[i] = { v = n ~= def and n or nil, text = tostring(n) } end
    return { key = key, label = label, values = values }
end
ns.Widget.Register(NAME, {
    info = { text = "widget.druid_resto_rejuv_info", demo = demo, fight = true },
    icon = 48441,
    label = "widget.druid_resto_rejuv",
    class = "DRUID",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "one",
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, PLAYER_EQUIPMENT_CHANGED = true,
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_ENTERING_WORLD = true, SPELLS_CHANGED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PLAYER_TALENT_UPDATE = true, UNIT_SPELLCAST_SUCCEEDED = "player",
    },
    tick = function(st) return st.ticking and data().tick or nil end,
    State = state,
    active = function(st) return st.why == "fight" or st.why == "calm" end,
    Build = build,
    Paint = function(layer, st) paint(layer, st) end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = function(i, st) return tip(i, st) end,
    opts = {
        steps("keep", "widget.drr_keep_opt", { 0, 1, 3, 5, 8 }, data().keep),
        steps("soon", "widget.drr_soon_opt", { 2, 3, 4 }, data().soon),
        { key = "calm", label = "widget.drr_calm", values = {
            { v = nil, label = "widget.drr_calm_num" }, { v = "hide", label = "widget.drr_calm_hide" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.druidRestoRejuvLoaded = true

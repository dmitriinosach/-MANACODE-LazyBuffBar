local _, ns = ...
local function data()
    return ns.widgetData.rogue_upkeep
end
local RANK = { bad = 5, none = 4, soon = 3, ok = 2, off = 1, hide = 0 }
local function isRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end
local function setNow()
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local d = data()
    return (v and d.sets[v]) or d.sets.assassination
end
local function keys(opt)
    local out = {}
    for _, k in ipairs(setNow()) do
        if not (opt and opt["c_" .. k] == false) then out[#out + 1] = k end
    end
    return out
end
local function rowSize(opt)
    return math.max(1, #keys(opt)), 1
end
local function avail()
    if not isRogue() then return false end
    for _, k in ipairs(setNow()) do
        if ns.IsLearned(data().cells[k].id) then return true end
    end
    return false
end
local bleedNames
local function bleeds()
    if bleedNames then return bleedNames end
    local out, seen = {}, {}
    for _, id in ipairs(data().bleeds) do
        local n = GetSpellInfo(id)
        if n and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    bleedNames = out
    return out
end
local function bleedOn(now)
    for _, id in ipairs(data().mine) do
        local n = GetSpellInfo(id)
        if n and UnitAura("target", n, nil, "HARMFUL|PLAYER") then return true end
    end
    local R = ns.Raid
    if not R then return false end
    local names = bleeds()
    R.WatchEnemy("rogue_upkeep", names)
    R.Touch()
    local e = R.Enemy("target")
    if not (e and not e.dead and e.guid == UnitGUID("target")) then return false end
    for _, n in ipairs(names) do
        local v = e.harm[n]
        if v and (v == 0 or v > now) then return true end
    end
    return false
end
local function readCell(k, ctx)
    local c = data().cells[k]
    local spell, _, icon = GetSpellInfo(c.id)
    local aura = GetSpellInfo(c.aura)
    local x = { key = k, spell = spell, name = aura or spell, icon = icon, has = false, left = 0, glow = false }
    if not (spell and ns.IsLearned(c.id)) then
        x.why, x.verdict = "none", "hide"
        return x
    end
    local onTarget = c.unit == "target"
    if onTarget and not ctx.foe then
        x.why, x.verdict = "notarget", "off"
        return x
    end
    local n, _, _, _, _, _, expires = UnitAura(c.unit, aura, nil, onTarget and "HARMFUL|PLAYER" or "HELPFUL|PLAYER")
    if n then
        x.has = true
        x.left = (expires and expires > 0) and math.max(0, expires - ctx.now) or 0
    end
    local soon = (ctx.over and c.soon > 0 and not c.keep) and ctx.over or c.soon
    local low = x.has and soon > 0 and x.left > 0 and x.left <= soon
    if not ctx.fight then
        x.why, x.verdict = "ooc", "off"
    elseif x.has and not low then
        x.why, x.verdict = "ok", "ok"
    elseif c.bleed and not ctx.foe then
        x.why, x.verdict = "notarget", "off"
    elseif c.bleed and not ctx.bleed then
        x.why, x.verdict = "nobleed", "bad"
    elseif x.has then
        x.why, x.verdict = "low", "soon"
    elseif c.optional then
        x.why, x.verdict = "nobuff", "off"
    else
        x.why, x.verdict = "missing", "none"
    end
    x.glow = (x.verdict == "soon" or x.verdict == "none") and (not c.finisher or ctx.combo > 0)
    return x
end
local function sum(st)
    st.any, st.live, st.worst = false, false, nil
    local best = -1
    for i, c in ipairs(st.cells) do
        if c.verdict ~= "hide" then st.any = true end
        if c.has and c.left > 0 then st.live = true end
        local r = RANK[c.verdict] or 0
        if r > best then
            best = r
            st.worst = i
        end
    end
end
local function state(opt)
    local d = data()
    local st = { cells = {}, fight = UnitAffectingCombat("player") and true or false, combo = 0 }
    local list = isRogue() and keys(opt) or {}
    local now = GetTime()
    local foe = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and true or false
    local ctx = { now = now, fight = st.fight, foe = foe, over = opt and opt.soon, bleed = false }
    st.combo = foe and (GetComboPoints("player", "target") or 0) or 0
    ctx.combo = st.combo
    for _, k in ipairs(list) do
        local c = d.cells[k]
        if c.bleed and foe and ns.IsLearned(c.id) then ctx.bleed = bleedOn(now) end
    end
    for i, k in ipairs(list) do st.cells[i] = readCell(k, ctx) end
    sum(st)
    return st
end
local function build(layer, view, opt)
    local s, gap = layer.h, layer.gap or 2
    local n = view == "one" and 1 or rowSize(opt)
    layer.tiles, layer.looks = {}, {}
    for i = 1, n do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + gap), 0, s)
        layer.looks[i] = {}
    end
end
local function look(k, c)
    local S = ns.STATE
    local W = ns.Widget
    local v = c and c.verdict or "hide"
    local dim = data().dim
    k.icon = c and c.icon
    k.grey = v == "none" or v == "off"
    k.alpha = (v == "hide" and 0) or ((v == "none" or v == "off") and dim) or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or ((v == "none" or v == "bad") and S.bad) or nil
    k.text = (c and c.has and c.left > 0 and v ~= "hide") and W.Left(c.left) or ""
    k.textColor = v == "soon" and S.soon or S.text
    k.mark = v == "bad" and "!" or nil
    k.markColor = S.bad
    k.glow = c and c.glow and v ~= "hide" or false
end
local function paint(layer, st, view)
    if view == "one" then
        local c = st.worst and st.cells[st.worst]
        local k = layer.looks[1]
        look(k, c)
        if c and c.verdict ~= "hide" then
            local S = ns.STATE
            k.mark = ns.T("widget.rogue_up_m_" .. c.key)
            k.markColor = (c.verdict == "bad" and S.bad) or (c.verdict == "soon" and S.soon) or S.text
        end
        ns.WTile.Paint(layer.tiles[1], k)
        return
    end
    for i, t in ipairs(layer.tiles) do
        look(layer.looks[i], st.cells[i])
        ns.WTile.Paint(t, layer.looks[i])
    end
end
local cellsBy = {}
local function cells(view, opt)
    local n = view == "one" and 0 or rowSize(opt)
    local key = view .. "/" .. n
    local list = cellsBy[key]
    if list then return list end
    if view == "one" then
        list = { { l = 0, t = 0, r = 1, b = 1 } }
    else
        list = {}
        for i = 1, n do
            list[i] = { cx = i - 1, cy = 0, attrs = function(st)
                local c = st.cells[i]
                if not (c and c.spell and c.verdict ~= "hide") then return {} end
                return { type = "spell", spell = c.spell }
            end }
        end
    end
    cellsBy[key] = list
    return list
end
local WHY = {
    missing = "widget.rogue_up_missing", nobleed = "widget.rogue_up_nobleed", notarget = "widget.rogue_up_notarget",
    nobuff = "widget.rogue_up_nobuff",
}
local function tip(i, st, view)
    local c = st.cells[view == "one" and (st.worst or 0) or i]
    if not c or c.verdict == "hide" then return nil end
    if c.why == "low" then return c.name, ns.T("widget.rogue_up_low", ns.Widget.Left(c.left)) end
    local key = WHY[c.why]
    if not key then return nil end
    return c.name, ns.T(key)
end
local DEMO = {
    solo  = { snd = { true, 14, "ooc", "off" } },
    party = { snd = { true, 9, "ok", "ok" }, rup = { true, 1.5, "low", "soon", true }, hfb = { true, 42, "ok", "ok" },
              env = { false, 0, "nobuff", "off" }, hemo = { true, 11, "ok", "ok" } },
    raid  = { snd = { true, 2, "low", "soon", true }, rup = { false, 0, "missing", "none", true },
              hfb = { false, 0, "nobleed", "bad" }, env = { true, 2, "ok", "ok" }, hemo = { false, 0, "missing", "none", true } },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local d = data()
    local st = { cells = {}, fight = scene.size ~= "solo", combo = 4 }
    for i, k in ipairs(keys(scene.opt)) do
        local c = d.cells[k]
        local spell, _, icon = GetSpellInfo(c.id)
        local q = p[k] or { false, 0, st.fight and "missing" or "ooc", st.fight and "none" or "off" }
        st.cells[i] = { key = k, spell = spell, name = GetSpellInfo(c.aura) or spell, icon = icon, has = q[1], left = q[2],
            why = q[3], verdict = q[4], glow = q[5] and true or false }
    end
    sum(st)
    return st
end
local function showChecks()
    local out = {}
    for i, k in ipairs(setNow()) do out[i] = { key = "c_" .. k, def = true, label = "widget.rogue_up_c_" .. k } end
    return out
end
local function soonValues()
    local out = { { v = nil, label = "widget.rogue_up_soon_auto" } }
    for _, s in ipairs(data().soons) do out[#out + 1] = { v = s, text = ns.Widget.Left(s) } end
    return out
end
ns.Widget.Register("rogue_upkeep", {
    info = { text = "widget.rogue_upkeep_info", demo = demo },
    icon = 6774,
    label = "widget.rogue_upkeep",
    class = "ROGUE",
    views = { row = rowSize, one = { w = 1, h = 1 } },
    order = { "row", "one" },
    view = "row",
    covers = { "spell:6774", "spell:48672", "spell:51662", "spell:57993", "spell:48660" },
    avail = avail,
    events = {
        UNIT_AURA = { player = true, target = true }, UNIT_COMBO_POINTS = "player", PLAYER_TARGET_CHANGED = true,
        PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return st.live and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    cells = cells,
    active = function(st, opt)
        if not st.any then return false end
        return st.fight or not (opt and opt.ooc == "hide")
    end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.rogue_up_show", kind = "checks", checks = showChecks },
        { key = "soon", label = "widget.rogue_up_soon", values = soonValues },
        { key = "ooc", label = "widget.rogue_up_ooc", values = {
            { v = nil, label = "widget.rogue_up_ooc_dim" }, { v = "hide", label = "widget.rogue_up_ooc_hide" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("rogue_upkeep") end)
end
ns.rogueUpkeepWidgetLoaded = true

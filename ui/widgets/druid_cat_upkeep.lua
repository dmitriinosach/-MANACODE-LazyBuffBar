local _, ns = ...
local function data()
    return ns.widgetData.druid_cat_upkeep
end
local RANK = { none = 4, soon = 3, ok = 2, off = 1, hide = 0 }
local function isDruid()
    local _, class = UnitClass("player")
    return class == "DRUID"
end
local function keys(opt)
    local out = {}
    for _, k in ipairs(data().order) do
        if not (opt and opt["c_" .. k] == false) then out[#out + 1] = k end
    end
    return out
end
local function rowSize(opt)
    return math.max(1, #keys(opt)), 1
end
local function avail()
    return isDruid() and ns.IsLearned(data().cells.roar.id)
end
local function inCat()
    local want = GetSpellInfo(data().form)
    if not want then return false end
    local cur = GetShapeshiftForm() or 0
    if cur == 0 then return false end
    local _, name = GetShapeshiftFormInfo(cur)
    return name == want
end
local function readAura(c)
    local harm = c.unit == "target"
    local mine = harm and "HARMFUL|PLAYER" or "HELPFUL|PLAYER"
    for _, id in ipairs(c.auras) do
        local want = GetSpellInfo(id)
        if want then
            local n, _, _, _, _, _, expires = UnitAura(c.unit, want, nil, mine)
            if n then return { has = true, expires = expires or 0, name = n, foreign = false } end
        end
    end
    if c.any then
        for _, id in ipairs(c.auras) do
            local want = GetSpellInfo(id)
            if want then
                local n, _, _, _, _, _, expires, caster = UnitAura(c.unit, want, nil, "HARMFUL")
                if n and caster ~= "player" then return { has = true, expires = expires or 0, name = n, foreign = true } end
            end
        end
    end
    return { has = false, expires = 0, foreign = false }
end
local function readCell(k, ctx)
    local c = data().cells[k]
    local spell, _, icon = GetSpellInfo(c.id)
    local x = { key = k, spell = spell, name = spell, icon = icon, has = false, left = 0, expires = 0, foreign = false,
        desync = false, glow = false }
    if not (spell and ns.IsLearned(c.id)) then
        x.why, x.verdict = "none", "hide"
        return x
    end
    local onTarget = c.unit == "target"
    if not onTarget or ctx.foe then
        local a = readAura(c)
        if a.has then
            x.has, x.expires, x.foreign, x.name = true, a.expires, a.foreign, a.name
            x.left = a.expires > 0 and math.max(0, a.expires - ctx.now) or 0
        end
    end
    local low = x.has and not x.foreign and c.soon > 0 and x.left > 0 and x.left <= c.soon
    if not ctx.fight then
        x.why, x.verdict = "ooc", "off"
    elseif not ctx.cat then
        x.why, x.verdict = "noform", "off"
    elseif onTarget and not ctx.foe then
        x.why, x.verdict = "notarget", "off"
    elseif x.foreign then
        x.why, x.verdict = "foreign", "ok"
    elseif x.has and not low then
        x.why, x.verdict = "ok", "ok"
    elseif x.has then
        x.why, x.verdict = "low", "soon"
    else
        x.why, x.verdict = "missing", "none"
    end
    return x
end
local function glowOf(c, combo)
    if not (c.verdict == "soon" or c.verdict == "none") or c.foreign then return false end
    local d = data()
    local need = d.cells[c.key].combo
    if need and combo < need then return false end
    if c.desync then return d.roarBase + d.roarPer * combo > c.left end
    return true
end
local function desync(st, ctx, opt)
    local lim = opt and opt.desync
    if lim == nil then lim = data().desync end
    if lim <= 0 or not (ctx.fight and ctx.cat and ctx.foe) then return end
    local roar
    for _, c in ipairs(st.cells) do
        if c.key == "roar" then roar = c end
    end
    if not (roar and roar.verdict == "ok" and roar.expires > 0) then return end
    local rip = readAura(data().cells.rip)
    if not (rip.has and rip.expires > 0) then return end
    local gap = math.abs(roar.expires - rip.expires)
    if gap > lim then return end
    st.gap = gap
    roar.desync, roar.why, roar.verdict = true, "desync", "soon"
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
    local st = { cells = {}, fight = UnitAffectingCombat("player") and true or false, cat = false, combo = 0 }
    local list = isDruid() and keys(opt) or {}
    local foe = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and true or false
    st.cat = isDruid() and inCat() or false
    st.combo = foe and (GetComboPoints("player", "target") or 0) or 0
    local ctx = { now = GetTime(), fight = st.fight, foe = foe, cat = st.cat, combo = st.combo }
    for i, k in ipairs(list) do st.cells[i] = readCell(k, ctx) end
    desync(st, ctx, opt)
    for _, c in ipairs(st.cells) do c.glow = glowOf(c, st.combo) end
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
    local v = c and c.verdict or "hide"
    k.icon = c and c.icon
    k.grey = v == "none" or v == "off"
    k.alpha = (v == "hide" and 0) or ((v == "none" or v == "off") and data().dim) or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "none" and S.bad) or nil
    k.text = (c and c.has and c.left > 0 and v ~= "hide") and ns.Widget.Left(c.left) or ""
    k.textColor = v == "soon" and S.soon or S.text
    local mark = c and v ~= "hide" and ((c.desync and "desync") or (c.foreign and "foreign"))
    k.mark = mark and ns.T("widget.druid_cat_up_m_" .. mark) or nil
    k.markColor = c and c.desync and S.soon or S.text
    k.glow = c and c.glow and v ~= "hide" or false
end
local function paint(layer, st, view)
    if view == "one" then
        local c = st.worst and st.cells[st.worst]
        local k = layer.looks[1]
        look(k, c)
        if c and c.verdict ~= "hide" then
            local S = ns.STATE
            k.mark = ns.T("widget.druid_cat_up_m_" .. c.key)
            k.markColor = (c.verdict == "none" and S.bad) or (c.verdict == "soon" and S.soon) or S.text
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
    missing = "widget.druid_cat_up_missing", notarget = "widget.druid_cat_up_notarget", noform = "widget.druid_cat_up_noform",
}
local function tip(i, st, view)
    local c = st.cells[view == "one" and (st.worst or 0) or i]
    if not c or c.verdict == "hide" then return nil end
    local W = ns.Widget
    if c.why == "low" then return c.name, ns.T("widget.druid_cat_up_low", W.Left(c.left)) end
    if c.why == "desync" then return c.name, ns.T("widget.druid_cat_up_desync", W.Left(st.gap or 0)) end
    if c.why == "foreign" then return c.name, ns.T("widget.druid_cat_up_foreign", c.name or "") end
    local key = WHY[c.why]
    if not key then return nil end
    return c.name, ns.T(key)
end
local DEMO = {
    solo  = { roar = { true, 24, "ooc", "off" } },
    party = { roar = { true, 15, "desync", "soon", true, false, true }, rip = { true, 13, "ok", "ok" },
              rake = { true, 5, "ok", "ok" }, mangle = { true, 48, "foreign", "ok", false, true } },
    raid  = { roar = { true, 2, "low", "soon", true }, rip = { false, 0, "missing", "none", true },
              rake = { false, 0, "missing", "none", true }, mangle = { true, 31, "ok", "ok" } },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local d = data()
    local fight = scene.size ~= "solo"
    local st = { cells = {}, fight = fight, cat = true, combo = 5, gap = 2 }
    for i, k in ipairs(keys(scene.opt)) do
        local spell, _, icon = GetSpellInfo(d.cells[k].id)
        local q = p[k] or { false, 0, fight and "missing" or "ooc", fight and "none" or "off" }
        st.cells[i] = { key = k, spell = spell, name = spell, icon = icon, has = q[1], left = q[2], expires = 0, why = q[3],
            verdict = q[4], glow = q[5] and true or false, foreign = q[6] and true or false, desync = q[7] and true or false }
    end
    sum(st)
    return st
end
local function showChecks()
    local out = {}
    for i, k in ipairs(data().order) do out[i] = { key = "c_" .. k, def = true, label = "widget.druid_cat_up_c_" .. k } end
    return out
end
local function desyncValues()
    local d = data()
    local out = {}
    for _, s in ipairs(d.desyncs) do
        if s == 0 then
            out[#out + 1] = { v = 0, label = "widget.druid_cat_up_desync_off" }
        else
            out[#out + 1] = { v = s ~= d.desync and s or nil, text = ns.Widget.Left(s) }
        end
    end
    return out
end
ns.Widget.Register("druid_cat_upkeep", {
    info = { text = "widget.druid_cat_upkeep_info", demo = demo },
    icon = 52610,
    label = "widget.druid_cat_upkeep",
    class = "DRUID",
    views = { row = rowSize, one = { w = 1, h = 1 } },
    order = { "row", "one" },
    view = "row",
    covers = { "spell:52610", "spell:49800", "spell:48574", "spell:48566" },
    avail = avail,
    events = {
        UNIT_AURA = { player = true, target = true }, UNIT_COMBO_POINTS = "player", PLAYER_TARGET_CHANGED = true,
        UPDATE_SHAPESHIFT_FORM = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true,
        PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
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
        { key = "show", label = "widget.druid_cat_up_show", kind = "checks", checks = showChecks },
        { key = "desync", label = "widget.druid_cat_up_desync_opt", values = desyncValues },
        { key = "ooc", label = "widget.druid_cat_up_ooc", values = {
            { v = nil, label = "widget.druid_cat_up_ooc_dim" }, { v = "hide", label = "widget.druid_cat_up_ooc_hide" },
        } },
    },
})
ns.druidCatUpkeepWidgetLoaded = true

local _, ns = ...
ns.Legacy = {}
local L = ns.Legacy
L.PLACE_FIELDS = { "point", "scale", "pad", "gap", "alpha", "idle", "fight", "plate", "digits" }
L.ROLE_OF = {
    personal = "self", flask = "item", food = "food", raid = "raid", potion = "item", want = "want",
    proc = "proc", cd = "cd", gear = "gear", dot = "dot",
}
function L.RoleOf(group, e)
    if e and e.hand then return "weapon" end
    if e and e.ally then return "ally" end
    return L.ROLE_OF[group] or group
end
function L.BarKey(bc)
    return bc.preset or tostring(bc.id)
end
function L.Bars(P)
    local out = {}
    for _, bc in ipairs(type(P.bars) == "table" and P.bars or {}) do
        if type(bc.groups) == "table" and #bc.groups > 0 then out[#out + 1] = bc end
    end
    return out
end
function L.Pick(P, s, cat, key)
    local p = P.pick and P.pick[s]
    if not p then return nil end
    local v = p[cat .. "|" .. key]
    if v == nil then v = p[key] end
    return v
end
function L.CdHidden(P, s, cat, key)
    local p = P.cdHide and P.cdHide[s]
    if not p then return false end
    local v = p[cat .. "|" .. key]
    if v == nil then v = p[key] end
    return v and true or false
end
local function filled(t)
    return type(t) == "table" and next(t) ~= nil
end
function L.SpecTraces(P, s)
    if filled(P.pick and P.pick[s]) or filled(P.order and P.order[s]) or filled(P.cdHide and P.cdHide[s]) then return true end
    if filled(P.myProcs and P.myProcs[s]) or filled(P.myTrack and P.myTrack[s]) then return true end
    for _, bc in ipairs(L.Bars(P)) do
        if bc.off and bc.off[s] then return true end
    end
    return false
end
local function sameList(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end
local function recipeBars()
    local out = {}
    for _, rb in ipairs(ns.presetRecipe.blocks) do
        if not rb.spare then out[#out + 1] = rb end
    end
    return out
end
local function oldGroups(rb)
    local out = {}
    for i, g in ipairs(rb.groups) do out[i] = g end
    if rb.key == "buffs" then out[#out + 1] = "want" end
    return out
end
function L.BarsDiffer(P)
    local bars = L.Bars(P)
    if #bars == 0 then return false end
    local recipe = recipeBars()
    if #bars ~= #recipe then return true end
    for i, bc in ipairs(bars) do
        local d = recipe[i]
        if L.BarKey(bc) ~= d.key or (bc.perRow or 0) ~= 0 or bc.name then return true end
        if not sameList(bc.groups or {}, d.groups) and not sameList(bc.groups or {}, oldGroups(d)) then return true end
    end
    return false
end
function L.HasPlaces(P)
    for _, bc in ipairs(L.Bars(P)) do
        for _, f in ipairs(L.PLACE_FIELDS) do
            if bc[f] ~= nil then return true end
        end
    end
    return false
end
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
function L.Places(P)
    local out = {}
    for _, bc in ipairs(L.Bars(P)) do
        local pl = {}
        for _, f in ipairs(L.PLACE_FIELDS) do
            if bc[f] ~= nil then pl[f] = copy(bc[f]) end
        end
        if next(pl) then out[L.BarKey(bc)] = pl end
    end
    return out
end
function L.On(P, s, group, e)
    if P and s then
        local v = L.Pick(P, s, group, e._key)
        if v ~= nil then return v and true or false end
    end
    return e._on and true or false
end
function L.Ordered(P, s, group, entries)
    local o = P and s and type(P.order) == "table" and type(P.order[s]) == "table" and P.order[s][group]
    if type(o) ~= "table" or #entries < 2 then return entries end
    local rank, base, out = {}, {}, {}
    for i, k in ipairs(o) do rank[k] = i end
    for i, e in ipairs(entries) do
        base[e] = i
        out[i] = e
    end
    table.sort(out, function(a, b)
        local ra, rb = rank[a._key], rank[b._key]
        if ra and rb then return ra < rb end
        if ra ~= rb then return ra ~= nil end
        return base[a] < base[b]
    end)
    return out
end
function L.GroupItems(map, group, items, P, s)
    if group == "want" then
        local keys = ns.Incoming and ns.Incoming.Keys and ns.Incoming.Keys()
        items[#items + 1] = { k = "want", role = "want", w = math.max(1, #(keys or {})) }
        return
    end
    local sec = map[group]
    for _, e in ipairs(L.Ordered(P, s, group, (sec and sec.entries) or {})) do
        if L.On(P, s, group, e) then
            local it = { k = e._key, role = L.RoleOf(group, e) }
            if e.excess or (P and s and L.CdHidden(P, s, group, e._key)) then it.show = "on" end
            items[#items + 1] = it
        end
    end
end
L.REMIND_KEYS = { "formAlert", "formAlertScale", "formAlertIdle", "formAlertFight", "formAlertColor", "formAlertNoLabel", "formAlertOff" }
local REMIND_RATIO = 56 / 32
local REMIND_SCALE = 0.7
function L.Remind(r)
    local any = false
    for _, k in ipairs(L.REMIND_KEYS) do
        if r[k] ~= nil then any = true end
    end
    if not any then return nil end
    local out = {}
    if r.formAlertScale ~= nil then
        out.scale = math.floor((tonumber(r.formAlertScale) or REMIND_SCALE) * REMIND_RATIO * 100 + 0.5) / 100
    end
    local p = r.formAlert
    if type(p) == "table" and p[1] then
        out.point = { p[1], p[2], math.floor((tonumber(p[3]) or 0) / REMIND_RATIO + 0.5), math.floor((tonumber(p[4]) or 0) / REMIND_RATIO + 0.5) }
    end
    if type(r.formAlertIdle) == "number" then out.idle = r.formAlertIdle end
    if type(r.formAlertFight) == "number" then out.fight = r.formAlertFight end
    local c = r.formAlertColor
    if type(c) == "table" and c[1] then out.color = { c[1], c[2], c[3] } end
    if r.formAlertNoLabel then out.noLabel = true end
    if r.formAlertOff then out.off = true end
    return out
end
function L.Build(P, s, map)
    local blocks, gone, seen = {}, {}, {}
    for _, bc in ipairs(L.Bars(P)) do
        local items = {}
        for _, g in ipairs(bc.groups or {}) do
            L.GroupItems(map, g, items, P, s)
            local sec = map[g]
            for _, e in ipairs((sec and sec.entries) or {}) do
                if L.Pick(P, s, g, e._key) == false and not seen[g .. "|" .. e._key] then
                    seen[g .. "|" .. e._key] = true
                    gone[#gone + 1] = { k = e._key, role = L.RoleOf(g, e) }
                end
            end
        end
        local b = { key = L.BarKey(bc), name = bc.name, items = items }
        if bc.off and bc.off[s] then b.off = true end
        b.cols, b.rows = ns.Grid.Pack(items, bc.perRow or 0)
        for _, f in ipairs(L.PLACE_FIELDS) do
            if bc[f] ~= nil then b[f] = copy(bc[f]) end
        end
        blocks[#blocks + 1] = b
    end
    return blocks, gone
end
ns.legacyLoaded = true

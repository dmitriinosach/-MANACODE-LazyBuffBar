local _, ns = ...
local C = {}
ns.Cds = C
local VERDICT = { act = "ok", ready = "ok", cd = "off", lock = "bad", idle = "off" }
local function data()
    return ns.widgetData.cds
end
function C.Entry(key)
    return data().spells[key]
end
local function classOf()
    local _, class = UnitClass("player")
    return class or ""
end
local function classSets(kind)
    local sets = data().sets[kind]
    return sets and sets[classOf()] or nil
end
function C.Set(kind)
    local cs = classSets(kind)
    local v = ns.CurrentVariant and ns.CurrentVariant()
    return (cs and v and cs[v]) or {}
end
function C.Width(kind)
    local n = #C.Set(kind)
    if n < 1 then return 1 end
    return n
end
function C.ClassKeys(kind)
    local keys, first, after, indeg = {}, {}, {}, {}
    local cs = classSets(kind)
    local order = ns.specs and ns.specs[classOf()] and ns.specs[classOf()].order or {}
    for _, v in ipairs(order) do
        local prev
        for _, key in ipairs((cs and cs[v]) or {}) do
            local e = C.Entry(key)
            if e and not e.raid then
                if not first[key] then
                    keys[#keys + 1] = key
                    first[key], after[key], indeg[key] = #keys, {}, 0
                end
                if prev and not after[prev][key] then
                    after[prev][key] = true
                    indeg[key] = indeg[key] + 1
                end
                prev = key
            end
        end
    end
    local out, done = {}, {}
    while #out < #keys do
        local pick
        for _, key in ipairs(keys) do
            if not done[key] and indeg[key] == 0 then pick = key; break end
        end
        if not pick then
            for _, key in ipairs(keys) do
                if not done[key] then pick = key; break end
            end
        end
        done[pick] = true
        out[#out + 1] = pick
        for nxt in pairs(after[pick]) do indeg[nxt] = indeg[nxt] - 1 end
    end
    return out
end
function C.InSet(kind, key)
    for _, k in ipairs(C.Set(kind)) do
        if k == key then return true end
    end
    return false
end
local function learnedId(e)
    if ns.IsLearned(e.id) then return e.id end
    for _, id in ipairs(e.alt or {}) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
local function castable(e)
    if e.raid and e.class ~= classOf() then return false end
    return learnedId(e) ~= nil
end
function C.Known(key)
    local e = C.Entry(key)
    if not e then return false end
    if e.raid then return true end
    return learnedId(e) ~= nil
end
local function shownId(e)
    local id = castable(e) and learnedId(e) or nil
    if id then return id end
    if e.faction then
        local f = UnitFactionGroup("player")
        if f and e.faction[f] then return e.faction[f] end
    end
    return e.id
end
function C.Name(key)
    local e = C.Entry(key)
    if not e then return nil end
    return (GetSpellInfo(shownId(e)))
end
function C.Avail(kind)
    for _, key in ipairs(C.Set(kind)) do
        local e = C.Entry(key)
        if e and castable(e) and (not e.raid) then return true end
    end
    return false
end
function C.Covers(kind)
    local out, seen = {}, {}
    for _, byClass in pairs(data().sets[kind] or {}) do
        for _, keys in pairs(byClass) do
            for _, key in ipairs(keys) do
                local e = C.Entry(key)
                if e and not seen[key] then
                    seen[key] = true
                    out[#out + 1] = "spell:" .. e.id
                    for _, id in ipairs(e.alt or {}) do out[#out + 1] = "spell:" .. id end
                end
            end
        end
    end
    table.sort(out)
    return out
end
function C.Icon(kind)
    local cs = classSets(kind)
    local order = ns.specs and ns.specs[classOf()] and ns.specs[classOf()].order or {}
    for _, v in ipairs(order) do
        local key = cs and cs[v] and cs[v][1]
        local e = key and C.Entry(key)
        if e and not e.raid then return e.id end
    end
    return data().icon[kind]
end
local auraNames = {}
local lockNames = {}
local function namesOf(ids)
    local out = {}
    for _, id in ipairs(ids) do
        local n = GetSpellInfo(id)
        if n then out[#out + 1] = n end
    end
    return out
end
local function auraList(key, e)
    local l = auraNames[key]
    if not l then
        l = namesOf(e.aura or { e.id })
        auraNames[key] = l
    end
    return l
end
local function lockList(key, e)
    local l = lockNames[key]
    if not l then
        l = {}
        local hidden = data().hidden or {}
        for i, id in ipairs(e.lock or {}) do
            l[i] = (not hidden[id] and GetSpellInfo(id)) or ""
        end
        lockNames[key] = l
    end
    return l
end
local function scanHarm(unit, exps, durs)
    wipe(exps)
    wipe(durs)
    local now = GetTime()
    for i = 1, 40 do
        local n, _, _, _, _, dur, exp = UnitAura(unit, i, "HARMFUL")
        if not n then break end
        exp = exp or 0
        if (exp == 0 or exp > now) and exps[n] == nil then exps[n], durs[n] = exp, dur or 0 end
    end
end
local targetExp = {}
local targetDur = {}
local function lockUnit(e)
    if e.lockOn ~= "target" then return "player", true end
    if not (UnitExists("target") and UnitCanAssist("player", "target")) then return nil, false end
    if UnitIsUnit("target", "player") then return "player", true end
    return "target", false
end
local function lockOf(key, e, now, exps, durs, mine)
    local names = lockList(key, e)
    local hidden = data().hidden or {}
    local bn, bx, bd
    for i, id in ipairs(e.lock or {}) do
        local n, x, d = names[i], nil, nil
        local h = hidden[id]
        if h then
            if mine then
                n = GetSpellInfo(h.cast)
                local s, cd = GetSpellCooldown(n or h.cast)
                if s and cd and cd > data().gcd and s + h.sec > now then x, d = s + h.sec, h.sec end
            end
        elseif n ~= "" then
            x, d = exps[n], durs[n]
        end
        if x and (not bx or bx ~= 0 and (x == 0 or x > bx)) then bn, bx, bd = n, x, d end
    end
    return bn, bx, bd
end
local helpExp = {}
local helpDur = {}
local mineExp = {}
local mineDur = {}
local harmExp = {}
local harmDur = {}
local function scanInto(filter, anyExp, anyDur, myExp, myDur)
    wipe(anyExp)
    wipe(anyDur)
    if myExp then
        wipe(myExp)
        wipe(myDur)
    end
    local now = GetTime()
    for i = 1, 40 do
        local n, _, _, _, _, dur, exp, caster = UnitAura("player", i, filter)
        if not n then break end
        exp = exp or 0
        if exp == 0 or exp > now then
            if anyExp[n] == nil then anyExp[n], anyDur[n] = exp, dur or 0 end
            if myExp and caster == "player" and myExp[n] == nil then myExp[n], myDur[n] = exp, dur or 0 end
        end
    end
end
local function firstOf(names, exps, durs)
    for _, n in ipairs(names) do
        local x = exps[n]
        if x then return x, durs[n] end
    end
    return nil, nil
end
local NAMED = { "target", "focus", "mouseover" }
local sentTo = {}
local extOn = {}
local extByName
local function extNames()
    if extByName then return extByName end
    extByName = {}
    for key, e in pairs(data().spells) do
        if e.ext then
            local ids = { e.id }
            for _, id in ipairs(e.alt or {}) do ids[#ids + 1] = id end
            for _, id in ipairs(ids) do
                local n = GetSpellInfo(id)
                if n then
                    local l = extByName[n] or {}
                    l[#l + 1] = key
                    extByName[n] = l
                end
            end
        end
    end
    return extByName
end
local function unitNamed(name)
    local u = ns.Units.Resolve("name:" .. name)
    if u then return u end
    for _, t in ipairs(NAMED) do
        if UnitName(t) == name then return t end
    end
    return nil
end
local function mineOn(unit, names)
    local now = GetTime()
    for i = 1, 40 do
        local n, _, _, _, _, dur, exp = UnitAura(unit, i, "HELPFUL|PLAYER")
        if not n then return nil end
        exp = exp or 0
        if exp == 0 or exp > now then
            for _, want in ipairs(names) do
                if n == want then return exp, dur or 0 end
            end
        end
    end
    return nil
end
function C.ExtTarget(key)
    local on = extOn[key]
    return on and on.name or nil
end
local castEvents = CreateFrame("Frame")
castEvents:RegisterEvent("UNIT_SPELLCAST_SENT")
castEvents:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
castEvents:SetScript("OnEvent", function(_, event, unit, spell, _, target)
    if unit ~= "player" or not spell then return end
    local keys = extNames()[spell]
    if not keys then return end
    if event == "UNIT_SPELLCAST_SENT" then
        sentTo[spell] = target or ""
        return
    end
    local name = (sentTo[spell] or ""):match("^([^%-]+)")
    sentTo[spell] = nil
    if name == UnitName("player") then name = nil end
    for _, key in ipairs(keys) do
        extOn[key] = name and { name = name, at = GetTime() } or nil
    end
    ns.Widget.Poke("cds_burst", 0.3)
    ns.Widget.Poke("cds_defs", 0.3)
end)
local function cellOf(key, e, now)
    local id = shownId(e)
    local name, _, icon = GetSpellInfo(id)
    local c = { key = key, name = name, icon = icon }
    local d = data()
    if e.debuff then
        local dn = GetSpellInfo(e.debuff) or ""
        local x = harmExp[dn]
        if x then
            c.s = "cd"
            if x > 0 then c.left, c.dur = x - now, harmDur[dn] end
        else
            c.s = "ready"
        end
        c.verdict = VERDICT[c.s]
        return c
    end
    if castable(e) then c.cast = name end
    local exp, dur
    if e.raid then
        exp, dur = firstOf(auraList(key, e), helpExp, helpDur)
    else
        exp, dur = firstOf(auraList(key, e), mineExp, mineDur)
    end
    local on = e.ext and not exp and extOn[key]
    if on and now - on.at <= e.ext then
        local u = unitNamed(on.name)
        if u then exp, dur = mineOn(u, auraList(key, e)) end
        if exp then c.on = on.name end
    end
    local start, cdDur = 0, 0
    if c.cast then
        local s1, d1 = GetSpellCooldown(c.cast)
        start, cdDur = s1 or 0, d1 or 0
    end
    if not exp and e.last and cdDur > d.gcd and start + e.last > now then
        exp, dur = start + e.last, e.last
    end
    if exp then
        c.s = "act"
        if exp > 0 then c.left, c.dur = exp - now, dur end
        c.verdict = (c.left and c.left < d.soon) and "soon" or "ok"
        return c
    end
    local cdLeft = (cdDur > d.gcd) and (start + cdDur - now) or nil
    if cdLeft and cdLeft <= 0 then cdLeft = nil end
    local lname, lexp, ldur
    local lu, mine = lockUnit(e)
    if lu == "player" then
        lname, lexp, ldur = lockOf(key, e, now, harmExp, harmDur, mine)
    elseif lu then
        scanHarm(lu, targetExp, targetDur)
        lname, lexp, ldur = lockOf(key, e, now, targetExp, targetDur, mine)
    end
    local lockLeft = lexp and (lexp > 0 and lexp - now or 0) or nil
    if lexp and (lexp == 0 or lockLeft > (cdLeft or 0)) then
        c.s = "lock"
        if lexp > 0 then c.left, c.dur = lockLeft, ldur end
        c.lockName = lname
    elseif cdLeft then
        c.s, c.left, c.dur = "cd", cdLeft, cdDur
    elseif c.cast then
        c.s = "ready"
    else
        c.s = "idle"
    end
    c.verdict = VERDICT[c.s]
    return c
end
local function shown(key, e, opt)
    if e.raid then return opt.hero ~= "off" end
    if opt["off_" .. key] then return false end
    return learnedId(e) ~= nil
end
function C.State(kind, opt)
    opt = opt or {}
    scanInto("HELPFUL", helpExp, helpDur, mineExp, mineDur)
    scanInto("HARMFUL", harmExp, harmDur)
    local now = GetTime()
    local keys = C.Set(kind)
    local st = { kind = kind, n = C.Width(kind), cells = {}, total = 0, ready = 0, active = 0 }
    for _, key in ipairs(keys) do
        local e = C.Entry(key)
        if e and shown(key, e, opt) then
            local c = cellOf(key, e, now)
            st.cells[#st.cells + 1] = c
            if c.cast then
                st.total = st.total + 1
                if c.s == "ready" then st.ready = st.ready + 1 end
            end
            if c.s == "act" then st.active = st.active + 1 end
        end
    end
    st.open = st.active > 0
    st.full = st.total > 0 and st.ready == st.total and not st.open
    local firstReady, soonest, soonLeft
    for i, c in ipairs(st.cells) do
        if c.s == "act" and not st.best then st.best = i end
        if c.s == "ready" and not firstReady then firstReady = i end
        if (c.s == "cd" or c.s == "lock") and c.left and (not soonLeft or c.left < soonLeft) then soonest, soonLeft = i, c.left end
    end
    st.best = st.best or firstReady or soonest
    if st.open then
        st.verdict = st.cells[st.best].verdict
    elseif st.full then
        st.verdict = "full"
    else
        st.verdict = "off"
    end
    return st
end
local lockedByName
local ownExp = {}
local ownDur = {}
function C.LockFor(spell)
    if not spell then return nil end
    if not lockedByName then
        lockedByName = {}
        for key, e in pairs(data().spells) do
            if e.lock and not e.raid then
                local n = GetSpellInfo(e.id)
                if n then lockedByName[n] = key end
            end
        end
    end
    local key = lockedByName[spell]
    if not key then return nil end
    local e = data().spells[key]
    local lu, mine = lockUnit(e)
    if not lu then return nil end
    local now = GetTime()
    scanHarm(lu, ownExp, ownDur)
    local name, exp, dur = lockOf(key, e, now, ownExp, ownDur, mine)
    if not exp then return nil end
    if exp == 0 then return name, nil, nil end
    return name, exp - now, dur
end
ns.cdsLoaded = true

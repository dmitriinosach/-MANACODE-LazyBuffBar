local _, ns = ...
local P = {}
ns.Pet = P
local function data()
    return ns.widgetData.pet
end
local function classOf()
    local _, class = UnitClass("player")
    return class or ""
end
local function nameOf(id)
    if not id then return nil end
    return (GetSpellInfo(id))
end
local function iconOf(id)
    if not id then return nil end
    local _, _, icon = GetSpellInfo(id)
    return icon
end
local function base()
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local info = v and ns.SpecInfo and ns.SpecInfo(classOf(), v)
    return (info and info.base) or (type(v) == "string" and v) or nil
end
function P.Class()
    return data().classes[classOf()]
end
function P.Demon(key)
    if not key then return nil end
    for _, d in ipairs(data().demons) do
        if d.key == key then return d end
    end
    return nil
end
function P.Avail()
    local c = P.Class()
    if not c then return false end
    if c.talent then
        if not ns.IsLearned(c.talent) then return false end
        if c.base and base() ~= c.base and not ns.IsTalent(c.talent) then return false end
    end
    if c.demons then
        for _, d in ipairs(data().demons) do
            if ns.IsLearned(d.summon) then return true end
        end
        return false
    end
    return ns.IsLearned(c.summon)
end
local sigNames
local function sigs()
    if sigNames then return sigNames end
    sigNames = {}
    for _, d in ipairs(data().demons) do
        for _, id in ipairs(d.sig) do
            local n = GetSpellInfo(id)
            if n then sigNames[n] = d.key end
        end
    end
    return sigNames
end
local kindGuid = false
local kindKey
local lastKind
local lostDead = false
function P.Kind()
    local c = P.Class()
    if not (c and c.demons) or not UnitExists("pet") then return nil end
    local g = UnitGUID("pet")
    if g ~= nil and g == kindGuid then return kindKey end
    local s = sigs()
    for i = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, _, _, isToken = GetPetActionInfo(i)
        if name and not isToken and s[name] then
            kindGuid, kindKey = g or false, s[name]
            return kindKey
        end
    end
    return nil
end
function P.Expected(opt)
    local c = P.Class()
    if not (c and c.demons) then return nil, "none" end
    local e = opt and opt.expect
    if e == "any" then return nil, "any" end
    local d = P.Demon(e)
    if d and ns.IsLearned(d.summon) then return e, "opt" end
    local k = data().spec[base() or ""]
    d = P.Demon(k)
    if d and ns.IsLearned(d.summon) then return k, "spec" end
    return nil, "any"
end
local function demonSummon(expect)
    local d = P.Demon(expect)
    if d then return d.summon end
    d = P.Demon(lastKind)
    if d and ns.IsLearned(d.summon) then return d.summon end
    for _, x in ipairs(data().demons) do
        if ns.IsLearned(x.summon) then return x.summon end
    end
    return data().demons[1].summon
end
local function cdLeft(id)
    if not id then return nil end
    local start, dur = GetSpellCooldown(id)
    if not (start and dur) or start <= 0 or dur <= data().gcd then return nil end
    local left = start + dur - GetTime()
    return left > 0 and left or nil
end
local function offWhy(exists)
    if UnitIsDeadOrGhost("player") then return "dead" end
    if UnitInVehicle and UnitInVehicle("player") then return "mount" end
    if UnitOnTaxi and UnitOnTaxi("player") then return "mount" end
    if not exists and IsMounted and IsMounted() then return "mount" end
    return nil
end
local function needOf(st, key)
    local v = st.verdict
    if key == "revive" then return (v == "none" and st.dead) and "none" or nil end
    if key == "summon" then
        if v == "bad" then return "bad" end
        if v == "none" and not (st.dead and st.revive) then return "none" end
        return nil
    end
    if key == "fel" then return (v == "none" or v == "bad") and v or nil end
    if key == "heal" then return (st.alive and st.low) and "soon" or nil end
    return nil
end
local function macroOf(c, st)
    local s = st.summon
    if not s then return nil end
    if c.revive and st.revive then
        local first = "/cast [target=pet,dead] " .. st.revive .. "; [nopet] " .. s
        if st.heal then first = first .. "; " .. st.heal end
        return first .. "\n/cast [nopet] " .. st.revive
    end
    if c.demons then
        if st.verdict == "bad" then return "/cast " .. s end
        return "/cast [nopet] " .. s
    end
    if st.heal then return "/cast [nopet] " .. s .. "; " .. st.heal end
    return "/cast [nopet] " .. s
end
function P.State(opt)
    opt = opt or {}
    local c = P.Class() or { row = {} }
    local d = data()
    local st = { exists = UnitExists("pet") and true or false, alive = false, dead = false, hp = 0, low = false, cells = {} }
    if st.exists then
        local hp, mx = UnitHealth("pet") or 0, UnitHealthMax("pet") or 0
        st.dead = (UnitIsDead("pet") or hp <= 0) and true or false
        st.alive = not st.dead
        if st.alive then
            st.hp = mx > 0 and math.floor(hp * 100 / mx) or 100
            st.name = UnitName("pet")
        end
    elseif c.revive then
        st.dead = lostDead
    end
    if c.happy and st.alive then st.happy, st.dmg = GetPetHappiness() end
    st.expect, st.source = P.Expected(opt)
    if c.demons and st.alive then st.kind = P.Kind() end
    st.low = st.alive and st.hp < (opt.low or d.low)
    st.summonId = c.demons and demonSummon(st.expect) or c.summon
    st.summon = nameOf(st.summonId)
    st.revive = c.revive and nameOf(c.revive) or nil
    st.heal = (c.heal and ns.IsLearned(c.heal)) and nameOf(c.heal) or nil
    st.why = offWhy(st.exists)
    if st.why then
        st.verdict = "off"
        st.icon = (st.alive and st.kind and iconOf(P.Demon(st.kind).summon)) or iconOf(st.summonId)
    elseif not st.alive then
        st.verdict = "none"
        local act = (st.dead and c.revive) or st.summonId
        st.icon = iconOf(act)
        st.cd = cdLeft(act)
    else
        local kind = P.Demon(st.kind)
        if c.demons and st.expect and st.kind ~= st.expect then
            st.verdict = "bad"
            st.want = iconOf(P.Demon(st.expect).summon)
        elseif st.low or st.happy == 1 then
            st.verdict = "soon"
        else
            st.verdict = "ok"
        end
        if kind then
            st.icon = iconOf(kind.summon)
        elseif c.happy then
            st.icon = (GetPetIcon and GetPetIcon()) or iconOf(st.summonId)
        elseif st.verdict ~= "bad" then
            st.icon = iconOf(st.summonId)
        end
    end
    st.macro = macroOf(c, st)
    for i, e in ipairs(c.row or {}) do
        local id = e.id or st.summonId
        local known = (id and ns.IsLearned(id)) and true or false
        st.cells[i] = {
            key = e.key, id = id, name = nameOf(id), icon = iconOf(id), known = known,
            cd = known and cdLeft(id) or nil, need = known and needOf(st, e.key) or nil,
        }
    end
    return st
end
function P.Active(st, opt)
    if opt and opt.when == "need" then
        local v = st.verdict
        return v == "none" or v == "bad" or v == "soon"
    end
    return true
end
function P.Covers()
    local out, seen = {}, {}
    local function add(id)
        if id and not seen[id] then
            seen[id] = true
            out[#out + 1] = id
        end
    end
    for _, c in pairs(data().classes) do
        add(c.summon)
        add(c.revive)
    end
    for _, d in ipairs(data().demons) do add(d.summon) end
    table.sort(out)
    for i, id in ipairs(out) do out[i] = "spell:" .. id end
    return out
end
local function remember()
    if not UnitExists("pet") then return end
    lostDead = (UnitIsDead("pet") or (UnitHealth("pet") or 1) <= 0) and true or false
    local k = P.Kind()
    if k then lastKind = k end
end
local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("PET_BAR_UPDATE")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_HEALTH" then
        if unit == "pet" then remember() end
        return
    end
    if event == "UNIT_PET" and unit ~= "player" then return end
    kindGuid = false
    remember()
    ns.Widget.Poke("pet")
end)
ns.petLoaded = true

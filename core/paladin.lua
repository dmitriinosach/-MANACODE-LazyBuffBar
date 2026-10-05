local ADDON, ns = ...
ns.BLESSINGS = {
    { key = "kings",  great = 25898, plain = 20217 },
    { key = "might",  great = 48934, plain = 48932 },
    { key = "wisdom", great = 48938, plain = 48936 },
    { key = "sanct",  great = 25899, plain = 20911 },
}
function ns.BlessingOf(id)
    local name = id and GetSpellInfo(id)
    if not name then return nil end
    for _, b in ipairs(ns.BLESSINGS) do
        if GetSpellInfo(b.great) == name then return b end
    end
    return nil
end
local function who()
    return UnitName("player") or "?"
end
function ns.MyBlessing()
    local by = LazyBuffBarDB and LazyBuffBarDB.blessing
    return by and by[who()] or nil
end
function ns.SetMyBlessing(key)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.blessing = LazyBuffBarDB.blessing or {}
    LazyBuffBarDB.blessing[who()] = key
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function ns.BlessingSymbols()
    local _, class = UnitClass("player")
    local s = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
    local r = s and s.raidReagents and s.raidReagents[1]
    if not (r and r.item and GetItemCount) then return 0 end
    return GetItemCount(r.item) or 0
end
function ns.BlessingWantsPlain()
    local by = LazyBuffBarDB and LazyBuffBarDB.plain
    return (by and by[who()]) and true or false
end
function ns.SetBlessingWantsPlain(v)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.plain = LazyBuffBarDB.plain or {}
    LazyBuffBarDB.plain[who()] = v and true or nil
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function ns.BlessingIsGreat(b)
    if not b or not ns.IsLearned(b.great) then return false end
    if ns.BlessingWantsPlain() then return false end
    return ns.BlessingSymbols() > 0
end
local function castable(unit, spell)
    if not UnitExists(unit) or not UnitIsConnected(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end
    if IsSpellInRange then return IsSpellInRange(spell, unit) == 1 end
    return true
end
local function auraEntry(b, great)
    if great then return { id = b.great } end
    return { id = b.great, alt = { b.plain } }
end
function ns.NextBlessingCast(b)
    if not b then return nil, nil, false, nil end
    local great = ns.BlessingIsGreat(b)
    local id = great and b.great or b.plain
    local spell = GetSpellInfo(id)
    if not spell or not ns.IsLearned(id) then return nil, nil, great, nil end
    local e = auraEntry(b, great)
    local units = ns.GroupUnits()
    if #units == 0 then units = { "player" } end
    for _, unit in ipairs(units) do
        if castable(unit, spell) and not ns.UnitHasBuff(unit, e) then
            return unit, spell, great, (select(2, UnitClass(unit)))
        end
    end
    return nil, spell, great, nil
end
ns.PALADIN_AURAS = { 48942, 54043, 19746, 32223, 48943, 48945, 48947 }
local auraById
local function auraNames()
    if auraById then return auraById end
    auraById = {}
    for _, id in ipairs(ns.PALADIN_AURAS) do
        local n = GetSpellInfo(id)
        if n then auraById[n] = id end
    end
    return auraById
end
function ns.MyAura()
    local by = auraNames()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster = UnitBuff("player", i)
        if not name then break end
        if caster == "player" and by[name] then return by[name], name end
    end
    return nil, nil
end
local function firstKnownAura()
    for _, id in ipairs(ns.PALADIN_AURAS) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
function ns.PaladinAuraEntry()
    local _, class = UnitClass("player")
    if class ~= "PALADIN" then return nil end
    local id = ns.MyAura()
    local on = id ~= nil
    id = id or firstKnownAura()
    if not id then return nil end
    return { id = id, slot = "aura", state = on, noAction = true }
end
ns.paladinLoaded = true

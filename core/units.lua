local _, ns = ...
ns.Units = {}
local U = ns.Units
U.LIST = { "player", "target", "focus", "targettarget", "pet", "boss", "tank", "tank2" }
local DIRECT = { player = true, target = true, focus = true, targettarget = true, pet = true }
U.TANK_AURAS = { 25780, 71, 5487, 9634, 48263 }
local TANK_SET = {}
for _, id in ipairs(U.TANK_AURAS) do TANK_SET[id] = true end
local TANK_CLASS = { WARRIOR = true, PALADIN = true, DRUID = true, DEATHKNIGHT = true }
local BOSS_FALLBACK = { "target", "focus" }
local ROSTER_DELAY = 0.5
local AURA_EVERY = 3
local REFRESH_EVERY = 5
local tanks = {}
local tankHow = {}
local names = {}
local namesDirty = true
local auraUnits = {}
local byAura = false
local computed = false
local lastAt = 0
local due
local wanted = {}
local wantName = false
local listeners = {}
function U.Valid(l)
    if type(l) ~= "string" then return false end
    if DIRECT[l] or l == "boss" or l == "tank" or l == "tank2" then return true end
    return l:match("^name:.+") ~= nil
end
local function members()
    local out = {}
    local n = GetNumRaidMembers()
    if n > 0 then
        for i = 1, n do out[i] = "raid" .. i end
        return out
    end
    out[1] = "player"
    for i = 1, GetNumPartyMembers() do out[#out + 1] = "party" .. i end
    return out
end
local function tankAura(unit)
    for i = 1, 40 do
        local n, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, i, "HELPFUL")
        if not n then return false end
        if id and TANK_SET[id] then return true end
    end
    return false
end
local function assignment(raid, i, unit)
    if raid then
        local role = select(10, GetRaidRosterInfo(i))
        return role
    end
    if not GetPartyAssignment then return nil end
    if GetPartyAssignment("MAINTANK", unit) then return "MAINTANK" end
    if GetPartyAssignment("MAINASSIST", unit) then return "MAINASSIST" end
    return nil
end
local function add(pick, how, unit, src)
    if #pick >= 2 then return end
    for _, u in ipairs(pick) do
        if u == unit then return end
    end
    pick[#pick + 1] = unit
    how[#how + 1] = src
end
local function rebuildNames()
    wipe(names)
    for _, u in ipairs(members()) do
        local n = UnitName(u)
        if n and names[n] == nil then names[n] = u end
    end
    local me = UnitName("player")
    if me and names[me] == nil then names[me] = "player" end
    namesDirty = false
end
local function compute()
    local list = members()
    local raid = GetNumRaidMembers() > 0
    local pick, how, assist = {}, {}, nil
    for i, u in ipairs(list) do
        local a = assignment(raid, i, u)
        if a == "MAINTANK" then add(pick, how, u, "assigned") elseif a == "MAINASSIST" and not assist then assist = u end
    end
    if assist then add(pick, how, assist, "assigned") end
    if #pick < 2 and UnitGroupRolesAssigned then
        for _, u in ipairs(list) do
            local isTank = UnitGroupRolesAssigned(u)
            if isTank then add(pick, how, u, "role") end
        end
    end
    wipe(auraUnits)
    byAura = #pick < 2
    if byAura then
        for _, u in ipairs(list) do
            local _, class = UnitClass(u)
            if class and TANK_CLASS[class] then
                auraUnits[u] = true
                if #pick < 2 and tankAura(u) then add(pick, how, u, "aura") end
            end
        end
    end
    for _, src in ipairs(how) do
        if src == "aura" then byAura = true end
    end
    local changed = tanks[1] ~= pick[1] or tanks[2] ~= pick[2]
    for i = 1, 2 do
        if tanks[i] and pick[i] and UnitName(tanks[i]) ~= UnitName(pick[i]) then changed = true end
    end
    tanks[1], tanks[2], tankHow[1], tankHow[2] = pick[1], pick[2], how[1], how[2]
    computed = true
    lastAt = GetTime()
    rebuildNames()
    return changed
end
local function fire()
    for _, fn in ipairs(listeners) do fn() end
end
local function needed()
    return (wanted.tank or wanted.tank2 or wantName) and true or false
end
local driver = CreateFrame("Frame")
driver:Hide()
local function schedule(at)
    if not due or at < due then due = at end
    if needed() then driver:Show() end
end
driver:SetScript("OnUpdate", function(self)
    if not needed() then self:Hide(); return end
    local now = GetTime()
    if due and now >= due then
        due = nil
        if compute() then fire() end
    end
    if due then return end
    if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) and not InCombatLockdown() then
        due = lastAt + REFRESH_EVERY
    else
        self:Hide()
    end
end)
local events = CreateFrame("Frame")
for _, e in ipairs({ "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "PARTY_LEADER_CHANGED", "PLAYER_ENTERING_WORLD",
                     "PLAYER_REGEN_ENABLED", "UNIT_AURA" }) do
    events:RegisterEvent(e)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        if not (byAura and auraUnits[unit]) or InCombatLockdown() then return end
        local now = GetTime()
        schedule(math.max(now, lastAt + AURA_EVERY))
        return
    end
    if event ~= "PLAYER_REGEN_ENABLED" then namesDirty = true end
    schedule(GetTime() + (event == "PLAYER_REGEN_ENABLED" and 0 or ROSTER_DELAY))
end)
local function isBoss(unit)
    if not UnitExists(unit) then return false end
    local c = UnitClassification and UnitClassification(unit)
    if c == "worldboss" then return true end
    return (c == "elite" or c == "rareelite") and UnitLevel(unit) == -1
end
local function bossUnit()
    for i = 1, 4 do
        if UnitExists("boss" .. i) then return "boss" .. i end
    end
    for _, u in ipairs(BOSS_FALLBACK) do
        if isBoss(u) then return u end
    end
    return nil
end
function U.Resolve(l)
    if not l then return nil end
    if DIRECT[l] then return UnitExists(l) and l or nil end
    if l == "boss" then return bossUnit() end
    if l == "tank" or l == "tank2" then
        if not computed then compute() end
        local u = tanks[l == "tank" and 1 or 2]
        return (u and UnitExists(u)) and u or nil
    end
    local name = type(l) == "string" and l:match("^name:(.+)$")
    if name then
        if namesDirty then rebuildNames() end
        local u = names[name]
        return (u and UnitExists(u)) and u or nil
    end
    return nil
end
function U.How(l)
    if l == "tank" then return tankHow[1] end
    if l == "tank2" then return tankHow[2] end
    return nil
end
function U.Want(set)
    local had = wanted.tank or wanted.tank2
    wipe(wanted)
    wantName = false
    for l in pairs(set or {}) do
        wanted[l] = true
        if l:match("^name:") then wantName = true end
    end
    if not needed() then driver:Hide(); return end
    if (wanted.tank or wanted.tank2) and (not computed or (due and not had)) then
        due = nil
        if compute() then fire() end
    end
    if due or GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then driver:Show() end
end
function U.OnChange(fn)
    listeners[#listeners + 1] = fn
end
function U.Names()
    local out, seen = {}, {}
    local me = UnitName("player")
    for _, u in ipairs(members()) do
        local n = u ~= "player" and UnitName(u) or nil
        if n and n ~= me and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    table.sort(out)
    return out
end
function U.Label(l)
    local name = l:match("^name:(.+)$")
    if name then return name end
    return ns.T("unit." .. l)
end
function U.Tip(l)
    local u = U.Resolve(l)
    local name = l:match("^name:(.+)$")
    if not u then
        if name then return ns.T("unit.none.name", name), false end
        return ns.T("unit.none." .. l), false
    end
    if name or l == "player" then return ns.T("unit.on", U.Label(l)), true end
    return ns.T("unit.on_named", U.Label(l), UnitName(u) or "?"), true
end

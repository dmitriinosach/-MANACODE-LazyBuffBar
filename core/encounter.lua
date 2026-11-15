local _, ns = ...
ns.Encounter = {}
local E = ns.Encounter
E.EVERY = 1
local NEAR = { "boss1", "boss2", "boss3", "boss4", "target", "focus" }
local RAID_T = {}
for i = 1, 40 do RAID_T[i] = "raid" .. i .. "target" end
local PARTY_T = {}
for i = 1, 4 do PARTY_T[i] = "party" .. i .. "target" end
local npcBoss
local spellBoss
local raidOfMap
local current
local zone
local wantRaid = {}
local fighting = InCombatLockdown() and true or false
local listeners = {}
E.scans = 0
local function build()
    npcBoss, spellBoss, raidOfMap = {}, {}, {}
    for _, r in ipairs(ns.encRaids or {}) do raidOfMap[r.map] = r.key end
    for key, b in pairs(ns.encBosses or {}) do
        for _, id in ipairs(b.npc) do npcBoss[id] = key end
        for _, id in ipairs(b.spells) do spellBoss[id] = key end
    end
end
function E.NpcOf(guid)
    if type(guid) ~= "string" or #guid ~= 18 or strsub(guid, 1, 4) ~= "0xF1" then return nil end
    local kind = strsub(guid, 5, 5)
    if kind ~= "3" and kind ~= "5" then return nil end
    local id = tonumber(strsub(guid, 7, 12), 16)
    if id and id > 0 then return id end
    return nil
end
function E.BossOfNpc(id)
    if not npcBoss then build() end
    return id and npcBoss[id] or nil
end
local altsRead = false
local function readAlts()
    altsRead = true
    local src = ns.catalogDB
    if type(src) ~= "string" then return end
    for line in src:gmatch("[^\r\n]+") do
        if line:find("sub=boss:", 1, true) then
            local key = spellBoss[tonumber(line:match("^(%d+) ")) or 0]
            local alt = key and line:match(" alt=(%S+)")
            for w in (alt or ""):gmatch("[^,]+") do
                local n = tonumber(w)
                if n and spellBoss[n] == nil then spellBoss[n] = key end
            end
        end
    end
end
function E.BossOfSpell(id)
    if not id then return nil end
    if not spellBoss then build() end
    local v = spellBoss[id]
    if v ~= nil then return v or nil end
    if not altsRead then readAlts() end
    v = spellBoss[id]
    if v == nil then spellBoss[id] = false end
    return v or nil
end
function E.OfRef(k)
    local id = tonumber(tostring(k or ""):match("^spell:(%d+)$"))
    return id and E.BossOfSpell(id) or nil
end
function E.RaidOf(key)
    local b = ns.encBosses and ns.encBosses[key]
    return b and b.raid or nil
end
function E.Raids()
    return ns.encRaids or {}
end
function E.Bosses(raid)
    for _, r in ipairs(ns.encRaids or {}) do
        if r.key == raid then return r.bosses end
    end
    return {}
end
function E.Name(key)
    return ns.T("enc.boss." .. key)
end
function E.RaidName(raid)
    return ns.T("enc.raid." .. raid)
end
function E.Current()
    return current
end
function E.Active(key)
    return key ~= nil and current == key
end
function E.Zone()
    return zone
end
function E.OnChange(fn)
    listeners[#listeners + 1] = fn
end
local function set(key)
    if key == current then return end
    local old = current
    current = key
    for _, fn in ipairs(listeners) do fn(key, old) end
end
local function bossOn(unit)
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then return nil end
    local id = E.NpcOf(UnitGUID(unit))
    return id and npcBoss[id] or nil
end
function E.Scan()
    if not npcBoss then build() end
    E.scans = E.scans + 1
    for _, u in ipairs(NEAR) do
        local key = bossOn(u)
        if key then return key end
    end
    local n, list = GetNumRaidMembers(), RAID_T
    if n == 0 then n, list = GetNumPartyMembers(), PARTY_T end
    for i = 1, math.min(n, #list) do
        local key = bossOn(list[i])
        if key then return key end
    end
    return nil
end
local ticker = CreateFrame("Frame")
ticker:Hide()
local acc = 0
function E.Step()
    if current and fighting then return end
    local found = E.Scan()
    if found then
        set(found)
    elseif current and not fighting then
        set(nil)
    end
end
local function refresh()
    if zone and wantRaid[zone] then
        if not ticker:IsShown() then
            acc = E.EVERY
            ticker:Show()
        end
        return
    end
    ticker:Hide()
    set(nil)
end
ticker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < E.EVERY then return end
    acc = 0
    E.Step()
end)
function E.Want(bosses)
    wipe(wantRaid)
    for key in pairs(bosses or {}) do
        local raid = E.RaidOf(key)
        if raid then wantRaid[raid] = true end
    end
    refresh()
end
function E.Scanning()
    return ticker:IsShown() and true or false
end
local function readZone()
    local inside, kind = IsInInstance()
    if not inside or kind ~= "raid" then return nil end
    if WorldMapFrame and WorldMapFrame:IsShown() then return zone end
    if not raidOfMap then build() end
    SetMapToCurrentZone()
    return raidOfMap[GetMapInfo() or ""]
end
local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
    events:RegisterEvent(e)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        fighting = true
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        fighting = false
        if ticker:IsShown() then E.Step() end
        return
    end
    zone = readZone()
    refresh()
end)
ns.encounterLoaded = true

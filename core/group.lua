local ADDON, ns = ...
ns.Group = ns.Group or {}
local FRESH = 1
local counts = {}
local dirty = true
local stamp = 0
local listeners = {}
local CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}
local fake
local function scan()
    wipe(counts)
    stamp = GetTime()
    local raid = GetNumRaidMembers() or 0
    if raid > 0 then
        for i = 1, raid do
            local _, _, _, _, _, file, _, online = GetRaidRosterInfo(i)
            if file and online then counts[file] = (counts[file] or 0) + 1 end
        end
        dirty = false
        return
    end
    local own = ns.PlayerClass()
    if own then counts[own] = 1 end
    for i = 1, (GetNumPartyMembers() or 0) do
        local unit = "party" .. i
        local _, file = UnitClass(unit)
        if file and UnitIsConnected(unit) then counts[file] = (counts[file] or 0) + 1 end
    end
    dirty = false
end
function ns.Group.Count(class)
    if fake then return fake[class] or 0 end
    if dirty or (GetTime() - stamp) > FRESH then scan() end
    return counts[class] or 0
end
function ns.Group.Fake()
    return fake
end
function ns.Group.SetFake(roster)
    fake = roster
    dirty = true
    for _, fn in ipairs(listeners) do fn() end
end
function ns.Group.MakeFake(size, even)
    local out = {}
    local own = ns.PlayerClass()
    out[own] = 1
    local left = size - 1
    if even then
        for _, class in ipairs(CLASSES) do
            if left <= 0 then break end
            if class ~= own then
                out[class] = (out[class] or 0) + 1
                left = left - 1
            end
        end
    end
    while left > 0 do
        local class = CLASSES[math.random(#CLASSES)]
        out[class] = (out[class] or 0) + 1
        left = left - 1
    end
    return out
end
function ns.Group.Foreign(class)
    if class == ns.PlayerClass() then return 0 end
    return ns.Group.Count(class)
end
function ns.Group.Others(class)
    local n = ns.Group.Count(class)
    if class == ns.PlayerClass() then n = n - 1 end
    return n > 0 and n or 0
end
function ns.Group.OthersAny(classes)
    local n = 0
    for _, class in ipairs(classes) do n = n + ns.Group.Others(class) end
    return n
end
function ns.Group.ForeignAny(classes)
    local n = 0
    for _, class in ipairs(classes) do n = n + ns.Group.Foreign(class) end
    return n
end
function ns.Group.Roster()
    if fake then return fake end
    if dirty or (GetTime() - stamp) > FRESH then scan() end
    return counts
end
function ns.Group.OnChange(fn)
    listeners[#listeners + 1] = fn
end
local f = CreateFrame("Frame")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    dirty = true
    for _, fn in ipairs(listeners) do fn() end
end)
ns.groupLoaded = true

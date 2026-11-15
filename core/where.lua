local _, ns = ...
ns.dungeons = ns.dungeons or {}
local AREA_INSTANCE = { IcecrownCitadel = "icc" }
local EVERY = 1
local checkedAt = 0
local near = false
local function currentInstance()
    if not IsInInstance() then return nil end
    if WorldMapFrame and WorldMapFrame:IsShown() then return nil end
    SetMapToCurrentZone()
    return AREA_INSTANCE[GetMapInfo() or ""]
end
local function readPosition()
    local floor = GetCurrentMapDungeonLevel()
    local x, y = GetPlayerMapPosition("player")
    if not x or (x == 0 and y == 0) then return nil end
    return floor, x, y
end
local function cropDist(crop, x, y)
    if x < crop[1] or x > crop[2] or y < crop[3] or y > crop[4] then return nil end
    local dx, dy = x - (crop[1] + crop[2]) / 2, y - (crop[3] + crop[4]) / 2
    return dx * dx + dy * dy
end
function ns.NearBoss()
    local now = GetTime()
    if now - checkedAt < EVERY then return near end
    checkedAt, near = now, false
    local d = ns.dungeons[currentInstance() or ""]
    if not d then return false end
    local floor, mx, my = readPosition()
    if not floor then return false end
    local best, bestD
    for _, loc in pairs(d.loc) do
        local m = d.maps[loc.map]
        local c = loc.calib or (m and m.calib)
        if m and c and (m.floor or 0) == (floor or 0) then
            local dist = cropDist(loc.crop, c.ax * mx + c.bx, c.ay * my + c.by)
            if dist and (not bestD or dist < bestD) then best, bestD = loc, dist end
        end
    end
    near = (best and best.kind == "boss") and true or false
    return near
end
ns.whereLoaded = true

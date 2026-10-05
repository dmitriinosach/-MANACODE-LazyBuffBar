local ADDON, ns = ...
ns.dungeons = ns.dungeons or {}
local abs, floor_ = math.abs, math.floor
local function calibKey(area, floor) return (area or "?") .. ":" .. (floor or 0) end
function ns.GetCalib(area, floor)
    local sv = LazyBuffBarDB and LazyBuffBarDB.mapCalib and LazyBuffBarDB.mapCalib[calibKey(area, floor)]
    if sv then return sv end
    for _, d in pairs(ns.dungeons) do
        for _, m in ipairs(d.maps or {}) do
            if m.area == area and (m.floor or 0) == (floor or 0) then return m.calib end
        end
    end
    return nil
end
function ns.ToCanvas(area, floor, x, y)
    local c = ns.GetCalib(area, floor)
    if not c then return nil end
    return c.ax * x + c.bx, c.ay * y + c.by
end
function ns.LocMap(inst, key)
    local d = ns.dungeons[inst]
    local loc = d and d.loc and d.loc[key]
    if not loc or not loc.map then return nil end
    return d.maps and d.maps[loc.map], loc
end
function ns.YardsToCanvas(area, floor, yards)
    local sc = ns.mapScale and ns.mapScale[area]
    sc = sc and sc[floor or 0]
    if not sc or not sc.w or sc.w <= 0 then return nil end
    local c = ns.GetCalib(area, floor)
    if not c then return nil end
    return yards / sc.w * c.ax
end
local cache = { t = 0, res = nil }
local function readPosition()
    if WorldMapFrame and WorldMapFrame:IsShown() then return nil end
    SetMapToCurrentZone()
    local floor = GetCurrentMapDungeonLevel()
    local x, y = GetPlayerMapPosition("player")
    if not x or (x == 0 and y == 0) then return nil end
    return floor, x, y
end
local function inCrop(loc, m, floor, cx, cy)
    if not loc.crop or not m then return false end
    if (m.floor or 0) ~= (floor or 0) then return false end
    local c = loc.crop
    return cx >= c[1] and cx <= c[2] and cy >= c[3] and cy <= c[4]
end
local function cropCenterDist(loc, cx, cy)
    local c = loc.crop
    local dx, dy = cx - (c[1] + c[2]) / 2, cy - (c[3] + c[4]) / 2
    return dx * dx + dy * dy
end
function ns.SpanProgress(loc, cx, cy)
    local s = loc.span
    if not s or not s.from or not s.to then return nil end
    local vx, vy = s.to.x - s.from.x, s.to.y - s.from.y
    local len2 = vx * vx + vy * vy
    if len2 <= 0 then return nil end
    local t = ((cx - s.from.x) * vx + (cy - s.from.y) * vy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return t
end
function ns.WhereAmI()
    local now = GetTime()
    if now - cache.t < 1 then return cache.res end
    cache.t = now
    cache.res = nil
    if not IsInInstance() then return nil end
    local inst = ns.CurrentInstance()
    local d = inst and ns.dungeons[inst]
    if not d then return nil end
    local floor, mx, my = readPosition()
    if not floor then return cache.res end
    local area
    for _, m in ipairs(d.maps or {}) do
        if (m.floor or 0) == (floor or 0) then area = m.area break end
    end
    if not area then return cache.res end
    local cx, cy = ns.ToCanvas(area, floor, mx, my)
    local res = { inst = inst, floor = floor, x = cx, y = cy }
    local best, bestD
    for key, loc in pairs(d.loc or {}) do
        local m = d.maps and loc.map and d.maps[loc.map]
        local px, py = cx, cy
        if loc.calib then
            px = loc.calib.ax * mx + loc.calib.bx
            py = loc.calib.ay * my + loc.calib.by
        end
        if px and inCrop(loc, m, floor, px, py) then
            local dist = cropCenterDist(loc, px, py)
            if not bestD or dist < bestD then best, bestD = key, dist end
        end
    end
    if not cx and not best then return cache.res end
    if best then
        local loc = d.loc[best]
        res.loc = best
        res.kind = loc.kind
        if loc.calib then
            local lc = loc.calib
            res.x, res.y = lc.ax * mx + lc.bx, lc.ay * my + lc.by
            cx, cy = res.x, res.y
        end
        if cx then res.progress = ns.SpanProgress(loc, cx, cy) end
    end
    cache.res = res
    return res
end
ns.whereLoaded = true

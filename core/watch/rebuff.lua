local ADDON, ns = ...
local ID = "rebuff"
local EVERY = 3
local BUFF_EVERY = 5
local LOW_MIN = 5
local BOSS_MIN = 10
local DEFAULT_MIN = 5
local MIN_MIN, MAX_MIN, STEP = 1, 15, 1
local inCombat = false
local buffAt = 0
local forced = false
local wasDead = {}
local saidAt = {}
local cachedFor
local cached = {}
local function repeatMinutes()
    local db = ns.WatchDB()
    local v = db and db.rebuff
    if type(v) ~= "number" then return DEFAULT_MIN end
    if v < MIN_MIN then return MIN_MIN end
    if v > MAX_MIN then return MAX_MIN end
    return v
end
local function setRepeatMinutes(v)
    local db = ns.WatchDB()
    if not db then return end
    if v < MIN_MIN then v = MIN_MIN elseif v > MAX_MIN then v = MAX_MIN end
    db.rebuff = v
end
local function due(key)
    local now = GetTime()
    local at = saidAt[key]
    if at and now - at < repeatMinutes() * 60 then return false end
    saidAt[key] = now
    return true
end
local function myBuffs()
    local prof = ns.BarProfile()
    if prof ~= cachedFor then
        cachedFor = prof
        local _, class = UnitClass("player")
        local spec = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
        cached = {}
        for _, e in ipairs(ns.OnlyLearned(ns.BuffEntries(spec and spec.raidBuffs))) do
            if not e.single and not e.soft then cached[#cached + 1] = e end
        end
    end
    if #cached == 0 then return nil end
    return cached
end
local function nearBoss()
    local w = ns.WhereAmI()
    return (w and w.kind == "boss") and true or false
end
local function tellLeft(e, mins, boss)
    local buff = GetSpellInfo(e.id)
    if not buff then return end
    if not due("left:" .. e.id) then return end
    ns.Notify{
        title = ns.T("notify.watch.rebuff.title"),
        text  = ns.T(boss and "notify.watch.rebuff.boss" or "notify.watch.rebuff.low",
                     buff, mins),
        key   = "watch.rebuff.left." .. e.id,
    }
end
local function tellNone(e)
    local buff = GetSpellInfo(e.id)
    if not buff then return end
    if not due("none:" .. e.id) then return end
    ns.Notify{
        title = ns.T("notify.watch.rebuff.title"),
        text  = ns.T("notify.watch.rebuff.none", buff),
        key   = "watch.rebuff.none." .. e.id,
    }
end
local function checkBuffs()
    local list = myBuffs()
    if not list then return end
    local raid = forced or ns.InRaidInstance()
    for _, e in ipairs(list) do
        local n, total, left = ns.GroupBuffNumbers(e)
        if total > 0 then
            if left then
                if left < LOW_MIN * 60 then
                    tellLeft(e, LOW_MIN, false)
                elseif left < BOSS_MIN * 60 and nearBoss() then
                    tellLeft(e, BOSS_MIN, true)
                end
            elseif n == 0 and raid then
                tellNone(e)
            end
        end
    end
end
local function tellRes(who, e)
    local buff = GetSpellInfo(e.id)
    if not buff then return end
    if not due("res:" .. who .. ":" .. e.id) then return end
    ns.Notify{
        title = ns.T("notify.watch.rebuff.title"),
        text  = ns.T("notify.watch.rebuff.res", who, buff),
        key   = "watch.rebuff.res." .. who .. "." .. e.id,
    }
end
local function revived(unit)
    local list = myBuffs()
    if not list then return end
    local who = UnitName(unit)
    if not who then return end
    for _, e in ipairs(list) do
        local names = ns.BuffNameSet(e)
        local has = false
        for a = 1, 40 do
            local n = UnitBuff(unit, a)
            if not n then break end
            if names[n] then has = true break end
        end
        if not has then tellRes(who, e) end
    end
end
local function probe()
    wipe(saidAt)
    forced = true
    checkBuffs()
    forced = false
    revived("player")
end
local function scanAlive(units)
    for _, unit in ipairs(units) do
        if UnitIsConnected(unit) then
            local dead = UnitIsDeadOrGhost(unit) and true or false
            if inCombat and wasDead[unit] and not dead then revived(unit) end
            wasDead[unit] = dead
        else
            wasDead[unit] = nil
        end
    end
end
local function onTick()
    local units = ns.GroupUnits()
    if #units == 0 then
        if next(wasDead) then wipe(wasDead) end
        return
    end
    scanAlive(units)
    local now = GetTime()
    if now - buffAt < BUFF_EVERY then return end
    buffAt = now
    checkBuffs()
end
local function onEvent(event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        wipe(saidAt)
        buffAt = GetTime()
        checkBuffs()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    else
        wipe(wasDead)
    end
end
ns.RegisterWatcher{
    id       = ID,
    order    = 30,
    events   = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "RAID_ROSTER_UPDATE" },
    every    = EVERY,
    enabled  = function() return ns.WatchEnabled(ID) end,
    onEvent  = onEvent,
    onTick   = onTick,
    probe    = probe,
    labelKey = "notify.watch.rebuff.label",
    checkKey = "notify.watch.rebuff.check",
    noteKey  = "notify.watch.rebuff.note",
    knobs    = {
        { kind = "range", labelKey = "notify.watch.rebuff.every",
          noteKey = "notify.watch.rebuff.every_note",
          min = MIN_MIN, max = MAX_MIN, step = STEP,
          get = repeatMinutes, set = setRepeatMinutes },
    },
}
ns.watchRebuffLoaded = true

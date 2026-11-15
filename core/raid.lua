local _, ns = ...
local R = {}
ns.Raid = R
R.cfg = { step = 0.15, per = 4, perFight = 2, sweep = 5, keep = 10 }
local roster = {}
local byUnit = {}
local byGuid = {}
local subs = {}
local anyNames = {}
local ownNames = {}
local ranges = {}
local esubs = {}
local harmAny = {}
local harmOwn = {}
local enemies = {}
local enemyByUnit = {}
local ENEMY_UNITS = { "target", "focus", "boss1", "boss2", "boss3", "boss4" }
local ENEMY_SET = {}
for _, u in ipairs(ENEMY_UNITS) do ENEMY_SET[u] = true end
local listeners = {}
local built = false
local rosterDirty = true
local enemyDirty = false
local enemyOn = false
local inRaid = false
local grouped = false
local cursor = 0
local acc = 0
local wanted = -1e9
local sweepAt = 0
local version = 0
local steps = 0
local sized = -1
local function union(from)
    local any, own, sa, so = {}, {}, {}, {}
    for _, w in pairs(from) do
        local out, seen = any, sa
        if w.mine then out, seen = own, so end
        for _, n in ipairs(w.names) do
            if not seen[n] then
                seen[n] = true
                out[#out + 1] = n
            end
        end
    end
    table.sort(any)
    table.sort(own)
    return any, own
end
local function read(m)
    m.dirty, m.hot, m.seen = false, false, true
    local unit = m.unit
    local off = not UnitIsConnected(unit)
    local dead = (not off and UnitIsDeadOrGhost(unit)) and true or false
    local changed = m.off ~= off or m.dead ~= dead
    m.off, m.dead = off, dead
    local live = not off and not dead
    local other = live and m.click ~= "player"
    for key, spell in pairs(ranges) do
        local out = false
        if other then
            if spell then out = IsSpellInRange(spell, unit) ~= 1
            else out = not (UnitInRange and UnitInRange(unit)) end
            out = out and true or false
        end
        if m.out[key] ~= out then
            m.out[key] = out
            changed = true
        end
    end
    for i = 1, #anyNames do
        local name = anyNames[i]
        local e = false
        if live then
            local n, _, _, _, _, _, expires = UnitBuff(unit, name)
            if n then e = expires or 0 end
        end
        if m.aura[name] ~= e then
            m.aura[name] = e
            changed = true
        end
    end
    for i = 1, #ownNames do
        local name = ownNames[i]
        local e, c = false, 0
        if live then
            local n, _, _, count, _, _, expires = UnitBuff(unit, name, nil, "PLAYER")
            if n then e, c = expires or 0, count or 0 end
        end
        if m.own[name] ~= e or (m.cnt[name] or 0) ~= c then
            m.own[name], m.cnt[name] = e, c
            changed = true
        end
    end
    return changed
end
local function rebuild(full)
    rosterDirty, built = false, true
    local units, raid = ns.GroupUnits()
    grouped = #units > 0
    if not grouped then units = { "player" } end
    inRaid = raid and true or false
    local old = byGuid
    byGuid, byUnit, roster = {}, {}, {}
    for i, unit in ipairs(units) do
        local guid = UnitGUID(unit)
        if guid and not byGuid[guid] then
            local m = old[guid] or { guid = guid, aura = {}, own = {}, cnt = {}, out = {} }
            local name, realm = UnitName(unit)
            local _, class = UnitClass(unit)
            m.unit, m.pos, m.name = unit, i, name or unit
            m.click = UnitIsUnit(unit, "player") and "player" or ((realm and realm ~= "") and (m.name .. "-" .. realm) or m.name)
            m.class = class or "WARRIOR"
            m.sub, m.zone = 1, nil
            if inRaid then
                local _, _, sub, _, _, _, zone = GetRaidRosterInfo(i)
                m.sub, m.zone = sub or 1, zone
            end
            m.dirty = true
            byGuid[guid], byUnit[unit] = m, m
            if m.click == "player" then byUnit.player = m end
            roster[#roster + 1] = m
        end
    end
    cursor = 0
    if full then
        for _, m in ipairs(roster) do read(m) end
        sweepAt = GetTime() + R.cfg.sweep
    end
    version = version + 1
end
local function take(budget)
    local n, changed = 0, false
    for _, m in ipairs(roster) do
        if n >= budget then break end
        if m.hot or (m.dirty and not m.seen) then
            n = n + 1
            if read(m) then changed = true end
        end
    end
    local count = #roster
    for _ = 1, count do
        if n >= budget then break end
        cursor = cursor % count + 1
        local m = roster[cursor]
        if m.dirty then
            n = n + 1
            if read(m) then changed = true end
        end
    end
    return changed
end
local function readEnemy(e)
    e.dirty = false
    local unit = e.unit
    local dead = UnitIsDeadOrGhost(unit) and true or false
    local changed = e.dead ~= dead
    e.dead = dead
    for i = 1, #harmAny do
        local name = harmAny[i]
        local v = false
        local n, _, _, _, _, _, expires = UnitDebuff(unit, name)
        if n then v = expires or 0 end
        if e.harm[name] ~= v then
            e.harm[name] = v
            changed = true
        end
    end
    for i = 1, #harmOwn do
        local name = harmOwn[i]
        local v = false
        local n, _, _, _, _, _, expires = UnitDebuff(unit, name, nil, "PLAYER")
        if n then v = expires or 0 end
        if e.own[name] ~= v then
            e.own[name] = v
            changed = true
        end
    end
    return changed
end
local function rebuildEnemies()
    enemyDirty = false
    local old = {}
    for _, e in ipairs(enemies) do old[e.guid] = e end
    local before = #enemies
    local same = true
    enemies, enemyByUnit = {}, {}
    local seen = {}
    for _, unit in ipairs(ENEMY_UNITS) do
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local guid = UnitGUID(unit)
            if guid then
                local e = seen[guid]
                if not e then
                    e = old[guid]
                    if not e then
                        e = { guid = guid, harm = {}, own = {}, dead = false }
                        same = false
                    end
                    e.unit, e.name, e.dirty = unit, UnitName(unit) or unit, true
                    seen[guid] = e
                    enemies[#enemies + 1] = e
                end
                enemyByUnit[unit] = e
            end
        end
    end
    return not same or before ~= #enemies
end
local scan = CreateFrame("Frame")
scan:Hide()
local function tell()
    version = version + 1
    for _, fn in ipairs(listeners) do fn() end
end
local function onUpdate(self, elapsed)
    acc = acc + (elapsed or 0)
    local c = R.cfg
    if acc < c.step then return end
    acc = 0
    local now = GetTime()
    if now - wanted > c.keep then
        self:Hide()
        return
    end
    steps = steps + 1
    local fight = InCombatLockdown() and true or false
    local changed = false
    if rosterDirty then
        rebuild(not fight)
        changed = true
    end
    if not fight and now >= sweepAt then
        sweepAt = now + c.sweep
        for _, m in ipairs(roster) do m.dirty = true end
    end
    if take(fight and c.perFight or c.per) then changed = true end
    if enemyOn then
        if enemyDirty and rebuildEnemies() then changed = true end
        for _, e in ipairs(enemies) do
            if e.dirty and readEnemy(e) then changed = true end
        end
    end
    if changed then tell() end
end
scan:SetScript("OnUpdate", onUpdate)
scan:RegisterEvent("UNIT_AURA")
scan:RegisterEvent("RAID_ROSTER_UPDATE")
scan:RegisterEvent("PARTY_MEMBERS_CHANGED")
scan:RegisterEvent("PLAYER_ENTERING_WORLD")
scan:RegisterEvent("PLAYER_REGEN_ENABLED")
scan:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        local m = byUnit[unit or ""]
        if m then m.dirty, m.hot = true, true end
        local e = enemyOn and enemyByUnit[unit or ""]
        if e then e.dirty = true end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        sweepAt = 0
        return
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        enemyDirty = true
        return
    end
    rosterDirty = true
    if event == "PLAYER_ENTERING_WORLD" then enemyDirty = true end
end)
local function rereadAll()
    local fight = InCombatLockdown()
    for _, m in ipairs(roster) do
        if fight or not m.seen then m.dirty = true else read(m) end
    end
    version = version + 1
end
local function sameList(a, b)
    if a == b then return true end
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end
function R.Watch(owner, names, mine)
    mine = mine and true or false
    local w = subs[owner]
    if w and w.mine == mine and sameList(w.names, names) then return end
    subs[owner] = { names = names, mine = mine }
    local any, own = union(subs)
    if sameList(any, anyNames) and sameList(own, ownNames) then return end
    anyNames, ownNames = any, own
    rereadAll()
end
function R.Range(key, spell)
    local v = spell or false
    if ranges[key] == v then return end
    ranges[key] = v
    rereadAll()
end
function R.WatchEnemy(owner, names, mine)
    mine = mine and true or false
    local w = esubs[owner]
    if w and w.mine == mine and sameList(w.names, names) then return end
    esubs[owner] = { names = names, mine = mine }
    harmAny, harmOwn = union(esubs)
    if not enemyOn then
        enemyOn = true
        scan:RegisterEvent("PLAYER_TARGET_CHANGED")
        scan:RegisterEvent("PLAYER_FOCUS_CHANGED")
        scan:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
    rebuildEnemies()
    for _, e in ipairs(enemies) do readEnemy(e) end
    version = version + 1
end
function R.OnChange(fn)
    listeners[#listeners + 1] = fn
end
function R.Touch()
    wanted = GetTime()
    local size = (GetNumRaidMembers() or 0) * 100 + (GetNumPartyMembers() or 0)
    if size ~= sized then
        sized = size
        rosterDirty = true
    end
    if not built or (rosterDirty and not InCombatLockdown()) then rebuild(not InCombatLockdown()) end
    if not scan:IsShown() then
        acc = 0
        scan:Show()
    end
end
function R.Roster()
    return roster
end
function R.Member(unit)
    return byUnit[unit]
end
function R.Enemies()
    return enemies
end
function R.Enemy(unit)
    return enemyByUnit[unit]
end
function R.InRaid()
    return inRaid
end
function R.Grouped()
    return grouped
end
function R.Version()
    return version
end
function R.Awake()
    return scan:IsShown() and true or false
end
function R.Steps()
    return steps
end
function R.End(m, names)
    local a = m.aura
    for i = 1, #names do
        local e = a[names[i]]
        if e then return e end
    end
    return false
end
function R.Own(m, names)
    for i = 1, #names do
        local e = m.own[names[i]]
        if e then return e, m.cnt[names[i]] or 0 end
    end
    return false, 0
end
function R.Scope()
    local inside, kind = IsInInstance()
    if not inside then return nil end
    if kind == "party" then return { max = 5 } end
    if kind ~= "raid" then return nil end
    local diff = GetInstanceDifficulty and GetInstanceDifficulty() or 2
    return { zone = inRaid and GetRealZoneText() or nil, max = (diff == 1 or diff == 3) and 10 or 25 }
end
function R.Count(names, range, skip, soon, scope, lines, now)
    now = now or GetTime()
    local s = { n = 0, can = 0, total = 0, missN = 0, lowN = 0, goneN = 0, miss = {}, low = {}, gone = {} }
    local zone, max = scope and scope.zone, scope and scope.max
    for _, m in ipairs(roster) do
        if m.seen and not (skip and skip[m.class]) and (not zone or m.zone == zone or m.click == "player")
            and (not max or s.total < max) then
            s.total = s.total + 1
            local reachable = not m.off and not m.dead and not (range and m.out[range])
            if reachable then s.can = s.can + 1 end
            local e = R.End(m, names)
            if e and (e == 0 or e > now) then
                s.n = s.n + 1
                if e > 0 then
                    local left = e - now
                    if not s.min or left < s.min then s.min = left end
                    if left < soon then
                        s.lowN = s.lowN + 1
                        if #s.low < lines then s.low[#s.low + 1] = m end
                    end
                end
            elseif reachable then
                s.missN = s.missN + 1
                if #s.miss < lines then s.miss[#s.miss + 1] = m end
            else
                s.goneN = s.goneN + 1
                if #s.gone < lines then s.gone[#s.gone + 1] = m end
            end
        end
    end
    if s.total == 0 then s.verdict = "off"
    elseif s.missN > 0 then s.verdict = "none"
    elseif s.lowN > 0 then s.verdict = "soon"
    else s.verdict = "ok" end
    return s
end
ns.raidLoaded = true

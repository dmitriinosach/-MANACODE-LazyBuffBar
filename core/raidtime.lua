local _, ns = ...
ns.RaidTime = {}
local R = ns.RaidTime
local RESUME = 1800
local BOSS_UNITS = { "target", "focus", "boss1", "boss2", "boss3", "boss4" }
local run
local fightAt
local function char()
    return ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char() or nil
end
local function where()
    local inside, kind = IsInInstance()
    if not inside or (kind ~= "party" and kind ~= "raid") then return nil end
    return tostring(GetRealZoneText() or "?") .. "#" .. tostring(GetInstanceDifficulty and GetInstanceDifficulty() or 1)
end
local function isBoss(u)
    if not UnitExists(u) then return false end
    local E = ns.Encounter
    if E and E.Zone() then return E.BossOfNpc(E.NpcOf(UnitGUID(u))) ~= nil end
    return UnitClassification(u) == "worldboss" or UnitLevel(u) == -1
end
local function bossNear()
    if ns.Encounter and ns.Encounter.Current() then return true end
    for _, u in ipairs(BOSS_UNITS) do
        if isBoss(u) then return true end
    end
    return false
end
local function keep(r)
    run = r
    local c = char()
    if c then c.raidtime = r end
end
local function poke()
    if ns.Widget and ns.Widget.Poke then ns.Widget.Poke("raidtime") end
end
local function fightStart()
    fightAt = time()
    if not run then return end
    run.pull = run.pull or fightAt
    if not run.boss and bossNear() then run.boss = fightAt end
end
local function sync()
    local key = where()
    if key then
        if not run then
            local saved = char() and char().raidtime
            if type(saved) == "table" and saved.zone == key and time() - (saved.seen or 0) < RESUME then
                run = saved
            end
        end
        if not run or run.zone ~= key then keep({ zone = key, enter = time() }) end
        run.seen = nil
        if InCombatLockdown() and not fightAt then fightStart() end
    elseif run and not UnitIsDeadOrGhost("player") then
        keep(nil)
        fightAt = nil
    end
end
function R.State(opt)
    local st = { secs = 0, run = false }
    if not run then return st end
    local from = opt and opt.from
    if from == "boss" then st.from = run.boss
    elseif from == "pull" then st.from = run.pull
    else st.from = run.enter end
    if not st.from then return st end
    local now = time()
    if opt and opt.till == "fight" and not fightAt then st.to = math.max(st.from, run.last or st.from) end
    st.secs = math.max(0, (st.to or now) - st.from)
    st.run = st.to == nil
    return st
end
function R.Run()
    return run
end
function R.Reset()
    run, fightAt = nil, nil
end
local function onEncounter(key)
    if not (key and run and fightAt and not run.boss) then return end
    run.boss = fightAt
    poke()
end
local hooked = false
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED", "PLAYER_LOGOUT" }) do ev:RegisterEvent(e) end
ev:SetScript("OnEvent", function(_, event)
    if not hooked and ns.Encounter then
        hooked = true
        ns.Encounter.OnChange(onEncounter)
    end
    if event == "PLAYER_LOGOUT" then
        if run then run.seen = time() end
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        fightStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if run and fightAt then run.last = time() end
        fightAt = nil
    elseif event == "PLAYER_TARGET_CHANGED" then
        if not (run and fightAt and not run.boss and bossNear()) then return end
        run.boss = fightAt
    else
        sync()
    end
    poke()
end)
ns.raidtimeLoaded = true

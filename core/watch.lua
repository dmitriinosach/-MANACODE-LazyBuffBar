local ADDON, ns = ...
local TICK = 1
local OWN = { PLAYER_LOGIN = true }
local list = {}
local byId = {}
local byEvent = {}
local ticked = {}
local subscribed = {}
local nextAt = {}
local acc = 0
local ticking = false
local frame = CreateFrame("Frame")
function ns.WatchDB()
    if type(LazyBuffBarDB) ~= "table" then return nil end
    LazyBuffBarDB.watch = LazyBuffBarDB.watch or {}
    local db = LazyBuffBarDB.watch
    db.on = db.on or {}
    return db
end
function ns.WatchEnabled(id)
    local db = ns.WatchDB()
    local v = db and db.on[id]
    if v == nil then return true end
    return v and true or false
end
function ns.SetWatchEnabled(id, on)
    local db = ns.WatchDB()
    if not db then return end
    db.on[id] = on and true or false
    ns.WatchRefresh()
end
local function isOn(w)
    if not w.enabled then return true end
    return w.enabled() and true or false
end
local function onUpdate(_, elapsed)
    acc = acc + elapsed
    if acc < TICK then return end
    acc = 0
    local now = GetTime()
    for i = 1, #ticked do
        local w = ticked[i]
        if isOn(w) then
            local due = nextAt[w]
            if not due or now >= due then
                nextAt[w] = now + w.every
                w.onTick()
            end
        else
            nextAt[w] = nil
        end
    end
end
function ns.WatchRefresh()
    for event, subs in pairs(byEvent) do
        local want = false
        for i = 1, #subs do
            if isOn(subs[i]) then
                want = true
                break
            end
        end
        if want and not subscribed[event] then
            frame:RegisterEvent(event)
            subscribed[event] = true
        elseif not want and subscribed[event] then
            if not OWN[event] then frame:UnregisterEvent(event) end
            subscribed[event] = nil
        end
    end
    local wantTick = false
    for i = 1, #ticked do
        if isOn(ticked[i]) then
            wantTick = true
            break
        end
    end
    if wantTick and not ticking then
        acc = 0
        frame:SetScript("OnUpdate", onUpdate)
        ticking = true
    elseif not wantTick and ticking then
        frame:SetScript("OnUpdate", nil)
        ticking = false
    end
end
function ns.RegisterWatcher(w)
    if type(w) ~= "table" then return end
    if type(w.id) ~= "string" or w.id == "" or byId[w.id] then return end
    w.order = w.order or 100
    byId[w.id] = w
    list[#list + 1] = w
    table.sort(list, function(a, b)
        if a.order == b.order then return a.id < b.id end
        return a.order < b.order
    end)
    if w.onEvent then
        for _, event in ipairs(w.events or {}) do
            local subs = byEvent[event]
            if not subs then
                subs = {}
                byEvent[event] = subs
            end
            subs[#subs + 1] = w
        end
    end
    if w.onTick and type(w.every) == "number" and w.every > 0 then
        ticked[#ticked + 1] = w
    end
    ns.WatchRefresh()
end
function ns.Watchers()
    return list
end
function ns.InRaidInstance()
    local inside, kind = IsInInstance()
    return (inside and kind == "raid") and true or false
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then ns.WatchRefresh() end
    local subs = byEvent[event]
    if not subs then return end
    for i = 1, #subs do
        local w = subs[i]
        if isOn(w) then w.onEvent(event, ...) end
    end
end)
frame:RegisterEvent("PLAYER_LOGIN")
ns.watchLoaded = true

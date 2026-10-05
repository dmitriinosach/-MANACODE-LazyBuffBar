local ADDON, ns = ...
local function copyMissing(from, to)
    for k, v in pairs(from) do
        if to[k] == nil then
            if type(v) == "table" then
                to[k] = {}
                copyMissing(v, to[k])
            else
                to[k] = v
            end
        end
    end
end
local function migrate()
    if LazyBuffBarDB.migrated then return end
    LazyBuffBarDB.migrated = true
    if type(htpDB) ~= "table" then return end
    if type(htpDB.buffbar) == "table" then
        copyMissing(htpDB.buffbar, LazyBuffBarDB)
        LazyBuffBarDB.show = nil
    end
    if type(htpDB.mapCalib) == "table" then
        LazyBuffBarDB.mapCalib = LazyBuffBarDB.mapCalib or {}
        copyMissing(htpDB.mapCalib, LazyBuffBarDB.mapCalib)
    end
    if LazyBuffBarDB.skin == nil then LazyBuffBarDB.skin = htpDB.skin end
end
local function placeGroup(key)
    local bars = LazyBuffBarDB.bars
    if not bars then return end
    for _, bc in ipairs(bars) do
        for _, k in ipairs(bc.groups or {}) do
            if k == key then return end
        end
    end
    local first = bars[1]
    if first and first.groups then tinsert(first.groups, key) end
end
function ns.InitDB()
    if type(LazyBuffBarDB) ~= "table" then LazyBuffBarDB = {} end
    migrate()
    if LazyBuffBarDB.show == nil then LazyBuffBarDB.show = true end
    if LazyBuffBarDB.locked == nil then LazyBuffBarDB.locked = false end
    LazyBuffBarDB.pick = LazyBuffBarDB.pick or {}
    if not LazyBuffBarDB.wantPlaced then
        LazyBuffBarDB.wantPlaced = true
        placeGroup("want")
    end
end
local function command(arg)
    local word, rest = (arg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local bar = ns.buffbar
    if word == "lock" then
        bar:SetLocked(not bar:IsLocked())
        ns.say(bar:IsLocked() and "Панель зафиксирована." or "Панель разблокирована.")
    elseif word == "settings" then
        ns.Settings.Toggle()
    elseif word == "options" then
        ns.OpenOptions()
    elseif word == "char" then
        if ns.Profile.SetOwn(not ns.Profile.IsOwn()) then
            ns.say(ns.T(ns.Profile.IsOwn() and "profile.now_own" or "profile.now_shared"))
        end
    elseif word == "reset" then
        bar:ResetBars()
    elseif word == "why" then
        for _, line in ipairs(ns.Incoming.Explain()) do ns.say(line) end
    elseif word == "fake" then
        ns.Incoming.Fake(rest)
    elseif word == "scale" then
        local idx, num = rest:match("^(%d+)%s+(%S+)$")
        if idx and tonumber(num) then
            bar:SetScale(tonumber(num), tonumber(idx))
            return
        end
        local v = tonumber(rest)
        if not v then
            local shown = bar:Panels()
            if #shown == 0 then
                ns.say(("Масштаб полос: %d%%."):format(bar:GetScale(1) * 100 + 0.5))
                return
            end
            for _, p in ipairs(shown) do
                ns.say(("Масштаб полосы %d: %d%%."):format(p.id, bar:GetScale(p.id) * 100 + 0.5))
            end
            return
        end
        bar:SetScale(v)
    else
        bar:SetShown(not bar:IsShown())
        ns.say(bar:IsShown() and "Панель показана." or "Панель скрыта.")
    end
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    ns.ApplyLocale()
    ns.InitDB()
    ns.buffbar:Init()
    ns.BuildOptions()
    ns.Chrome.Init()
end)
SLASH_LAZYBUFFBAR1 = "/lbb"
SLASH_LAZYBUFFBAR2 = "/lazybuffbar"
SlashCmdList["LAZYBUFFBAR"] = command
ns.initLoaded = true

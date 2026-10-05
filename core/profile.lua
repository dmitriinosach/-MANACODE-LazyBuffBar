local ADDON, ns = ...
ns.Profile = {}
local SHARED = { mapCalib = true, migrated = true }
local account
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
local function char()
    if type(LazyBuffBarCharDB) ~= "table" then LazyBuffBarCharDB = {} end
    return LazyBuffBarCharDB
end
local function accountCopy()
    local out = {}
    for k, v in pairs(account) do
        if not SHARED[k] then out[k] = copy(v) end
    end
    return out
end
local function pointGlobal()
    local c = char()
    if not c.own then
        LazyBuffBarDB = account
        return
    end
    if type(c.db) ~= "table" then c.db = accountCopy() end
    for k in pairs(SHARED) do c.db[k] = account[k] end
    LazyBuffBarDB = c.db
end
local function release()
    local c = char()
    if c.own and type(c.db) == "table" then
        for k in pairs(SHARED) do
            if c.db[k] ~= nil then account[k] = c.db[k] end
            c.db[k] = nil
        end
    end
    LazyBuffBarDB = account
end
local function reapply()
    if ns.InitDB then ns.InitDB() end
    if ns.Incoming and ns.Incoming.Forget then ns.Incoming.Forget() end
    ns.RepaintTheme()
    if ns.buffbar and ns.buffbar.Apply then ns.buffbar:Apply() end
    if ns.Chrome and ns.Chrome.Apply then ns.Chrome.Apply() end
    if ns.BarMenu and ns.BarMenu.Refresh then ns.BarMenu.Refresh() end
    if ns.Settings and ns.Settings.Refresh then ns.Settings.Refresh() end
end
function ns.Profile.IsOwn()
    return char().own and true or false
end
function ns.Profile.HasOwn()
    return type(char().db) == "table"
end
function ns.Profile.SetOwn(on)
    if not account then return false end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    on = on and true or false
    if on == ns.Profile.IsOwn() then return true end
    release()
    char().own = on or nil
    pointGlobal()
    reapply()
    return true
end
function ns.Profile.TakeShared()
    if not (account and ns.Profile.IsOwn()) then return false end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    char().db = accountCopy()
    pointGlobal()
    reapply()
    return true
end
function ns.Profile.MakeShared()
    if not (account and ns.Profile.IsOwn()) then return false end
    for k in pairs(account) do
        if not SHARED[k] then account[k] = nil end
    end
    for k, v in pairs(LazyBuffBarDB) do
        if not SHARED[k] then account[k] = copy(v) end
    end
    return true
end
function ns.Profile.Char()
    return char()
end
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGOUT" then
        if account then release() end
        return
    end
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    account = (type(LazyBuffBarDB) == "table") and LazyBuffBarDB or {}
    account.procAt = nil
    pointGlobal()
end)
ns.profileLoaded = true

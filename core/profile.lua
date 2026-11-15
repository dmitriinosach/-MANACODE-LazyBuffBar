local _, ns = ...
local ADDON = ...
ns.Profile = {}
local DEFAULT = "default"
local FORMAT = 3
local CHAR_KEYS = {
    minimapAngle = true, settingsPos = true, settingsTab = true, optionsPos = true, optionsTab = true, editBarPos = true,
    settingsScale = true, barMenuScale = true, settingsSize = true, barMenuW = true,
}
local LEGACY_KEYS = { bars = true, pick = true, order = true, cdHide = true, myProcs = true, myTrack = true, moved = true, nextBar = true }
local DROPPED_KEYS = { "procAt", "mapCalib", "migrated" }
local root
local char
local liveName
local pending = false
local waiter = CreateFrame("Frame")
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
local function settingsCopy(src)
    local out = {}
    for k, v in pairs(src) do
        if not CHAR_KEYS[k] then out[k] = copy(v) end
    end
    return out
end
local function who()
    return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end
local function uniqueName(base)
    if not root.profiles[base] then return base end
    local n = 2
    while root.profiles[base .. " (" .. n .. ")"] do n = n + 1 end
    return base .. " (" .. n .. ")"
end
local function rename(from, to)
    root.profiles[to], root.profiles[from] = root.profiles[from], nil
    for _, u in pairs(root.users) do
        if u[1] == from then u[1] = to end
        if u[2] == from then u[2] = to end
    end
end
local function takeCharKeys(src)
    for k in pairs(CHAR_KEYS) do
        if char[k] == nil then char[k] = src[k] end
        src[k] = nil
    end
    return src
end
local function has(list, id)
    for _, v in ipairs(list) do
        if v == id then return true end
    end
    return false
end
local function migrateBlocks()
    local top = 0
    root.custom = root.custom or {}
    for _, p in pairs(root.profiles) do
        for _, bc in ipairs(type(p.bars) == "table" and p.bars or {}) do
            local n = type(bc.id) == "string" and tonumber(bc.id:match("^b(%d+)$"))
            if n and n > top then top = n end
            if type(bc.groups) == "table" then root.legacyBars = true end
        end
        for spec, list in pairs(type(p.myProcs) == "table" and p.myProcs or {}) do
            local dst = root.custom[spec] or {}
            root.custom[spec] = dst
            for _, id in ipairs(type(list) == "table" and list or {}) do
                if not has(dst, id) then dst[#dst + 1] = id end
            end
        end
    end
    if not next(root.custom) then root.custom = nil end
    if (tonumber(root.nextBlock) or 1) <= top then root.nextBlock = top + 1 end
end
local function migrateAccount()
    if type(root.profiles) == "table" then
        if type(root.users) ~= "table" then root.users = {} end
        local old = ns.LEGACY_DEFAULT_PROFILE
        if (root.format or 1) < 2 and old and root.profiles[old] then
            if root.profiles[DEFAULT] then rename(DEFAULT, uniqueName(DEFAULT)) end
            rename(old, DEFAULT)
        end
        if (root.format or 1) < 3 then migrateBlocks() end
        root.format = FORMAT
        root.legacyShared = nil
        return
    end
    local shared = {}
    for k, v in pairs(root) do shared[k] = v end
    for k in pairs(shared) do root[k] = nil end
    root.profiles = { [DEFAULT] = takeCharKeys(shared) }
    root.users = {}
    root.format = FORMAT
end
local function migrateChar()
    local me = who()
    if root.users[me] then return end
    local db = type(char.db) == "table" and char.db or nil
    if char.own and db then
        local name = uniqueName(UnitName("player") or "?")
        root.profiles[name] = takeCharKeys(db)
        root.users[me] = { name, name }
    else
        root.users[me] = { DEFAULT, DEFAULT }
    end
    char.own, char.db = nil, nil
end
local function assigned(slot)
    local u = root.users[who()]
    local name = u and u[slot]
    if not (name and root.profiles[name]) then name = DEFAULT end
    return name
end
local function point(name)
    root.profiles[DEFAULT] = root.profiles[DEFAULT] or {}
    if not root.profiles[name] then name = DEFAULT end
    local p = root.profiles[name]
    for k in pairs(CHAR_KEYS) do p[k] = char[k] end
    LazyBuffBarDB = p
    liveName = name
end
local function release()
    local p = liveName and root.profiles[liveName]
    if p then
        for k in pairs(CHAR_KEYS) do
            char[k] = p[k]
            p[k] = nil
        end
    end
    LazyBuffBarDB = root
    liveName = nil
end
local function reapply()
    if ns.InitDB then ns.InitDB() end
    if ns.Incoming and ns.Incoming.Forget then ns.Incoming.Forget() end
    if ns.RepaintTheme then ns.RepaintTheme() end
    if ns.buffbar and ns.buffbar.Apply then ns.buffbar:Apply() end
    if ns.Chrome and ns.Chrome.Apply then ns.Chrome.Apply() end
    if ns.PanelCard and ns.PanelCard.Refresh then ns.PanelCard.Refresh() end
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
end
local function canChange()
    if not root then return false end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    return true
end
function ns.Profile.SyncSpec(silent)
    if not root then return end
    local want = assigned(ns.ActiveSlot())
    if want == liveName then return end
    if InCombatLockdown() then
        pending = true
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    release()
    point(want)
    if not silent then reapply() end
end
function ns.Profile.Current()
    return liveName or DEFAULT
end
function ns.Profile.For(slot)
    return assigned(slot)
end
function ns.Profile.Default()
    return DEFAULT
end
function ns.Profile.Label(name)
    if name == DEFAULT then return ns.T("profile.default") end
    return tostring(name)
end
function ns.Profile.List()
    local out = {}
    for name in pairs(root.profiles) do
        local users = {}
        for key, u in pairs(root.users) do
            local short = key:match("^(.-) %- ") or key
            if u[1] == name and u[2] == name then
                users[#users + 1] = short
            elseif u[1] == name then
                users[#users + 1] = short .. ns.T("profile.user_main")
            elseif u[2] == name then
                users[#users + 1] = short .. ns.T("profile.user_second")
            end
        end
        table.sort(users)
        out[#out + 1] = { name = name, label = ns.Profile.Label(name), users = users }
    end
    table.sort(out, function(a, b)
        if a.name == DEFAULT then return true end
        if b.name == DEFAULT then return false end
        return a.name < b.name
    end)
    return out
end
function ns.Profile.Assign(slot, name)
    if not root.profiles[name] or not canChange() then return false end
    local me = who()
    root.users[me] = root.users[me] or { DEFAULT, DEFAULT }
    root.users[me][slot] = name
    ns.Profile.SyncSpec()
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
    return true
end
function ns.Profile.New(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$")
    if name == "" then return false, "empty" end
    if root.profiles[name] or name == ns.T("profile.default") or name == DEFAULT
        or name == ns.LEGACY_DEFAULT_PROFILE then return false, "exists" end
    if not canChange() then return false end
    root.profiles[name] = settingsCopy(LazyBuffBarDB)
    ns.Profile.Assign(ns.ActiveSlot(), name)
    return true
end
function ns.Profile.CopyFrom(name)
    local src = root.profiles[name]
    if not src or name == liveName or not canChange() then return false end
    local p = LazyBuffBarDB
    for k in pairs(p) do
        if not CHAR_KEYS[k] then p[k] = nil end
    end
    for k, v in pairs(settingsCopy(src)) do p[k] = v end
    reapply()
    return true
end
function ns.Profile.Reset()
    if not canChange() then return false end
    local p = LazyBuffBarDB
    for k in pairs(p) do
        if not CHAR_KEYS[k] and not LEGACY_KEYS[k] then p[k] = nil end
    end
    reapply()
    return true
end
function ns.Profile.Delete(name)
    if name == DEFAULT or not root.profiles[name] or not canChange() then return false end
    local wasLive = name == liveName
    if wasLive then release() end
    root.profiles[name] = nil
    for _, u in pairs(root.users) do
        if u[1] == name then u[1] = DEFAULT end
        if u[2] == name then u[2] = DEFAULT end
    end
    if wasLive then
        point(assigned(ns.ActiveSlot()))
        reapply()
    elseif ns.Options and ns.Options.Refresh then
        ns.Options.Refresh()
    end
    return true
end
function ns.Profile.Loaded()
    return root ~= nil
end
function ns.Profile.Root()
    return root
end
function ns.Profile.Live()
    return liveName and root and root.profiles[liveName] or nil
end
function ns.Profile.Char()
    if type(char) ~= "table" then
        if type(LazyBuffBarCharDB) ~= "table" then LazyBuffBarCharDB = {} end
        char = LazyBuffBarCharDB
    end
    return char
end
waiter:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if not pending then return end
    pending = false
    ns.Profile.SyncSpec()
end)
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGOUT" then
        if root then release() end
        return
    end
    if event == "PLAYER_LOGIN" then
        if not root then return end
        release()
        migrateChar()
        point(assigned(ns.ActiveSlot()))
        return
    end
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    root = (type(LazyBuffBarDB) == "table") and LazyBuffBarDB or {}
    ns.Profile.Char()
    for _, k in ipairs(DROPPED_KEYS) do root[k] = nil end
    migrateAccount()
    point(DEFAULT)
end)
ns.profileLoaded = true

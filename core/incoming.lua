local _, ns = ...
ns.Incoming = ns.Incoming or {}
local FAKE_SIZE = 25
local names = {}
local function spellName(id)
    if names[id] == nil then
        names[id] = GetSpellInfo(id) or false
    end
    return names[id] or nil
end
local function entryOf(buff, key)
    local alt
    for i = 2, #buff.auras do
        alt = alt or {}
        alt[#alt + 1] = buff.auras[i]
    end
    return { id = buff.auras[1], alt = alt, noAction = true,
             soft = buff.maybe and true or nil, want = buff, wkey = key }
end
local function scope(variant)
    if not variant then return ns.BarProfile() end
    return ns.PlayerClass() .. "/" .. variant
end
local derived = {}
local told = {}
local function gap(key)
    if told[key] then return end
    told[key] = true
    ns.say(ns.T("want.gap", key))
end
local function fits(buff, p, role)
    local need = buff.need
    if not need then return true end
    if need == "tank" then return role == "tank" end
    return p[need] and true or false
end
local function harvest(list, out)
    if type(list) ~= "table" then return end
    for _, item in ipairs(list) do
        if type(item) == "number" then
            local name = spellName(item)
            if name then out[name] = true end
        elseif type(item) == "table" then
            if item.id then
                local name = spellName(item.id)
                if name then out[name] = true end
            end
            if type(item.alt) == "table" then
                for _, id in ipairs(item.alt) do
                    local name = spellName(id)
                    if name then out[name] = true end
                end
            end
        end
    end
end
local function ownNames(variant)
    local out = {}
    local _, class = UnitClass("player")
    local s = ns.SpecData(ns.rotation, class, variant or ns.CurrentVariant())
    if not s then return out end
    harvest(ns.OnlyLearned(ns.BuffEntries(s.buffs)), out)
    harvest(ns.OnlyLearned(ns.BuffEntries(s.raidBuffs)), out)
    return out
end
local function handsOut(buff, mine)
    for _, id in ipairs(buff.auras) do
        local name = spellName(id)
        if name and mine[name] then return true end
    end
    return false
end
local function foreign(from)
    local own = ns.PlayerClass()
    for _, class in ipairs(from) do
        if class ~= own then return true end
    end
    return false
end
local function ownAlready(p, key)
    if not p.own then return false end
    for _, k in ipairs(p.own) do
        if k == key then return true end
    end
    return false
end
local function verdict(buff, p, role, key, mine)
    if not fits(buff, p, role) then return "need" end
    if ownAlready(p, key) then return "own_pass" end
    if buff.mutual then return "ok" end
    if not foreign(buff.from) then return "own_class" end
    if handsOut(buff, mine) then return "own_give" end
    return "ok"
end
local function givers(buff)
    if buff.mutual then return ns.Group.OthersAny(buff.from) end
    return ns.Group.ForeignAny(buff.from)
end
local function profile(variant)
    local byClass = ns.profiles[ns.PlayerClass()]
    return byClass and byClass[variant or ns.CurrentVariant() or ""] or nil
end
function ns.Incoming.Keys(variant)
    local at = scope(variant)
    if derived[at] then return derived[at] end
    local p = profile(variant)
    if not p then return nil end
    local role = variant and ns.RoleOf(ns.PlayerClass(), variant) or ns.PlayerRole()
    local mine = ownNames(variant)
    local list = {}
    for _, key in ipairs(ns.incomingOrder) do
        local buff = ns.incoming[key]
        if not buff then
            gap(key)
        elseif not buff.passive and verdict(buff, p, role, key, mine) == "ok" then
            list[#list + 1] = key
        end
    end
    derived[at] = list
    return list
end
function ns.Incoming.Forget()
    for k in pairs(derived) do derived[k] = nil end
end
function ns.Incoming.Panel(variant)
    local out = {}
    local healer = (variant and ns.RoleOf(ns.PlayerClass(), variant) or ns.PlayerRole()) == "heal"
    for _, key in ipairs(ns.Incoming.Keys(variant) or {}) do
        local buff = ns.incoming[key]
        if buff and not buff.maybe and (not buff.extra or (buff.heal and healer)) then out[#out + 1] = key end
    end
    return out
end
function ns.Incoming.KeyOf(ref)
    if ns.incoming[ref] then return ref end
    local id = tonumber(tostring(ref):match("^spell:(%d+)$"))
    if not id then return nil end
    for _, key in ipairs(ns.incomingOrder) do
        local buff = ns.incoming[key]
        if buff and buff.auras[1] == id then return key end
    end
    return nil
end
function ns.Incoming.Entry(ref)
    local key = ns.Incoming.KeyOf(ref)
    local buff = key and ns.incoming[key]
    if not buff then return nil, false end
    local e = entryOf(buff, key)
    e._key, e._cat, e._on = ns.EntryKey("spell", e), "want", true
    local live = (buff.mutual and ns.Group.OthersAny(buff.from) or ns.Group.ForeignAny(buff.from)) > 0
    if not live then e.soft = true end
    return e, live
end
local rows = {}
function ns.Incoming.List()
    for i = #rows, 1, -1 do rows[i] = nil end
    local keys = ns.Incoming.Keys()
    if not keys then return rows end
    for _, key in ipairs(keys) do
        local buff = ns.incoming[key]
        if not buff then
            gap(key)
        else
            local n = givers(buff)
            if n > 0 then
                rows[#rows + 1] = { key = key, buff = buff, givers = n }
            end
        end
    end
    return rows
end
function ns.IncomingSections(all)
    local entries = {}
    for _, row in ipairs(ns.Incoming.List()) do
        entries[#entries + 1] = entryOf(row.buff, row.key)
    end
    entries = ns.PickEntries("want", "spell", entries, all)
    if #entries == 0 then return {} end
    return { { key = "want", kind = "spell", entries = entries } }
end
function ns.Incoming.Givers(buff)
    local parts
    for _, class in ipairs(buff.from) do
        local n = buff.mutual and ns.Group.Others(class) or ns.Group.Foreign(class)
        if n > 0 then
            local label = ns.ClassName(class) or class
            if n > 1 then label = label .. " " .. n end
            parts = parts and (parts .. ", " .. label) or label
        end
    end
    return parts or ""
end
function ns.Incoming.SetFake(on)
    ns.Group.SetFake(on and ns.Group.MakeFake(FAKE_SIZE, true) or nil)
end
function ns.Incoming.IsFake()
    return ns.Group.Fake() ~= nil
end
ns.Group.OnChange(function()
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end)
local talents = CreateFrame("Frame")
talents:RegisterEvent("PLAYER_TALENT_UPDATE")
talents:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
talents:RegisterEvent("SPELLS_CHANGED")
talents:SetScript("OnEvent", ns.Incoming.Forget)
ns.incomingCoreLoaded = true

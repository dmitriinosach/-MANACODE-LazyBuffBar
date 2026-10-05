local ADDON, ns = ...
ns.Incoming = ns.Incoming or {}
local names = {}
local function spellName(id)
    if names[id] == nil then
        names[id] = GetSpellInfo(id) or false
    end
    return names[id] or nil
end
local function entryOf(buff)
    local alt
    for i = 2, #buff.auras do
        alt = alt or {}
        alt[#alt + 1] = buff.auras[i]
    end
    return { id = buff.auras[1], alt = alt, noAction = true,
             soft = buff.maybe and true or nil, want = buff }
end
local function scope()
    return ns.BarProfile()
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
local function ownNames()
    local out = {}
    local _, class = UnitClass("player")
    local s = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
    if not s then return out end
    harvest(s.buffs, out)
    harvest(s.raidBuffs, out)
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
local function profile()
    local byClass = ns.profiles[ns.PlayerClass()]
    return byClass and byClass[ns.CurrentVariant() or ""] or nil
end
function ns.Incoming.Keys()
    local at = scope()
    if derived[at] then return derived[at] end
    local p = profile()
    if not p then return nil end
    local role = ns.PlayerRole()
    local mine = ownNames()
    local list = {}
    for _, key in ipairs(ns.incomingOrder) do
        local buff = ns.incoming[key]
        if not buff then
            gap(key)
        elseif verdict(buff, p, role, key, mine) == "ok" then
            list[#list + 1] = key
        end
    end
    derived[at] = list
    return list
end
function ns.Incoming.Forget()
    for k in pairs(derived) do derived[k] = nil end
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
    local hide = (LazyBuffBarDB and LazyBuffBarDB.hide) or {}
    if not all and hide.want then return {} end
    local entries = {}
    for _, row in ipairs(ns.Incoming.List()) do
        entries[#entries + 1] = entryOf(row.buff)
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
function ns.Incoming.RosterLine()
    local own = ns.PlayerClass()
    local out
    for class, n in pairs(ns.Group.Roster()) do
        local label = ns.ClassName(class) or class
        if class == own then label = label .. " " .. ns.T("want.why.you") end
        if n > 1 then label = label .. " " .. n end
        out = out and (out .. ", " .. label) or label
    end
    return out or "?"
end
local function seen(buff)
    for _, id in ipairs(buff.auras) do
        local name = spellName(id)
        if name and ns.HasBuff(name) then return true end
    end
    return false
end
function ns.Incoming.Explain()
    local out = {}
    local class = ns.PlayerClass()
    out[#out + 1] = ns.T("want.why.head", ns.ClassName(class) or class,
                         tostring(ns.CurrentVariant() or "?"), ns.PlayerRole())
    out[#out + 1] = ns.T("want.why.group", ns.Incoming.RosterLine())
    if ns.Group.Fake() then out[#out + 1] = ns.T("want.fake.why") end
    local p = profile()
    if not p then
        out[#out + 1] = ns.T("want.why.nospec")
        return out
    end
    local role = ns.PlayerRole()
    local mine = ownNames()
    for _, key in ipairs(ns.incomingOrder) do
        local buff = ns.incoming[key]
        if buff then
            local name = spellName(buff.auras[1]) or key
            local code = verdict(buff, p, role, key, mine)
            if code ~= "ok" then
                out[#out + 1] = ns.T("want.why." .. code, name)
            elseif givers(buff) < 1 then
                out[#out + 1] = ns.T("want.why.nobody", name)
            elseif seen(buff) then
                out[#out + 1] = ns.T("want.why.have", name)
            else
                out[#out + 1] = ns.T("want.why.miss", name, ns.Incoming.Givers(buff))
            end
        end
    end
    return out
end
function ns.Incoming.Fake(arg)
    local rest = string.lower(string.gsub(arg or "", "^%s*(.-)%s*$", "%1"))
    if rest == "off" then
        ns.Group.SetFake(nil)
        ns.say(ns.T("want.fake.off"))
        return
    end
    local even = true
    if string.sub(rest, 1, 3) == "rnd" then
        even = false
        rest = string.gsub(string.sub(rest, 4), "^%s*", "")
    end
    local size = tonumber(rest) or 25
    if size < 1 then size = 1 end
    if size > 40 then size = 40 end
    ns.Group.SetFake(ns.Group.MakeFake(size, even))
    ns.say(ns.T("want.fake.on", size))
    ns.say(ns.T("want.fake.list", ns.Incoming.RosterLine()))
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

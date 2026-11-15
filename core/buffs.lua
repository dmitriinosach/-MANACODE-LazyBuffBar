local _, ns = ...
function ns.HasBuff(name)
    if not name then return false end
    for i = 1, 40 do
        local n = UnitBuff("player", i)
        if not n then break end
        if n == name then return true end
    end
    return false
end
function ns.BuffNameSet(e)
    if type(e) ~= "table" then e = { id = e } end
    local set = {}
    local n = e.id and GetSpellInfo(e.id)
    if n then set[n] = true end
    for _, id in ipairs(e.alt or {}) do
        local an = GetSpellInfo(id)
        if an then set[an] = true end
    end
    return set
end
function ns.ActiveBuffName(e)
    local set = ns.BuffNameSet(e)
    for i = 1, 40 do
        local n = UnitBuff("player", i)
        if not n then break end
        if set[n] then return n end
    end
    return nil
end
function ns.UnitHasBuff(unit, e)
    if not unit or not UnitExists(unit) then return false end
    local set = ns.BuffNameSet(e)
    for i = 1, 40 do
        local n = UnitBuff(unit, i)
        if not n then break end
        if set[n] then return true end
    end
    return false
end
function ns.BuffLeft(name)
    if not name then return nil end
    for i = 1, 40 do
        local n, _, _, count, _, duration, expires = UnitBuff("player", i)
        if not n then break end
        if n == name then
            if not expires or expires == 0 then return 0, nil, nil, count end
            return expires - GetTime(), duration, expires - (duration or 0), count
        end
    end
    return nil
end
local groupBuffs = {}
function ns.GroupBuffReset()
    for _, g in pairs(groupBuffs) do g.ver = -1 end
end
function ns.GroupUnits()
    local out = {}
    local nr = (GetNumRaidMembers and GetNumRaidMembers()) or 0
    if nr > 0 then
        for i = 1, nr do out[i] = "raid" .. i end
        return out, true
    end
    local np = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if np == 0 then return out, false end
    out[1] = "player"
    for i = 1, np do out[i + 1] = "party" .. i end
    return out, false
end
local function groupCount(g)
    local R = ns.Raid
    g.ver = R.Version()
    g.n, g.minEnd, g.charges = 0, nil, nil
    local roster = R.Roster()
    g.total = R.Grouped() and #roster or 0
    if g.total == 0 then return end
    local b = ns.BlessingOf and ns.BlessingOf(g.id)
    local skip = b and ns.IsLearned(b.great) and ns.BlessSkip(b.key) or nil
    for _, m in ipairs(roster) do
        local e, c
        if skip and skip[m.class] then
            g.total = g.total - 1
        elseif g.single then
            e, c = R.Own(m, g.names)
        else
            e = R.End(m, g.names)
        end
        if e then
            g.n = g.n + 1
            if e > 0 and (not g.minEnd or e < g.minEnd) then g.minEnd = e end
            if c and c > 0 then g.charges = c end
        end
    end
end
function ns.GroupBuffNumbers(e)
    local id = (type(e) == "table") and e.id or e
    if not id or not GetSpellInfo(id) then return 0, 0, nil end
    local R = ns.Raid
    if not R then return 0, 0, nil end
    local single = (type(e) == "table" and e.single) and true or false
    local key = (single and "s" or "g") .. id
    local g = groupBuffs[key]
    if not g then
        local names = {}
        local set = ns.BuffNameSet(e)
        local b = ns.BlessingOf and ns.BlessingOf(id)
        local plain = b and GetSpellInfo(b.plain)
        if plain then set[plain] = true end
        for n in pairs(set) do names[#names + 1] = n end
        table.sort(names)
        g = { names = names, single = single, ver = -1, n = 0, total = 0, id = id }
        groupBuffs[key] = g
        R.Watch("entry:" .. key, names, single)
    end
    R.Touch()
    if g.ver ~= R.Version() then groupCount(g) end
    local min = g.minEnd and math.max(0, g.minEnd - GetTime()) or nil
    if single then return g.n, (g.total > 0) and 1 or 0, min, g.charges end
    return g.n, g.total, min
end
local learned
local learnedOk
local talRank
local function rebuildLearned()
    local set, n = {}, 0
    local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    for tab = 1, tabs do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
            local name = GetSpellName and GetSpellName(i, BOOKTYPE_SPELL or "spell")
            if name then set[name] = true; n = n + 1 end
        end
    end
    learned, learnedOk = set, n > 0
    talRank = nil
    if GetNumTalentTabs and GetTalentInfo and GetNumTalents and ns.TalentsKnown() then
        talRank = {}
        local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
        for tab = 1, GetNumTalentTabs() do
            for i = 1, GetNumTalents(tab) do
                local tname, _, _, _, rank = GetTalentInfo(tab, i, false, false, group)
                if tname then talRank[tname] = rank or 0 end
            end
        end
    end
end
function ns.IsLearned(id)
    if not id then return false end
    local name = GetSpellInfo(id)
    if not name then return true end
    if not learned then rebuildLearned() end
    local r = talRank and talRank[name]
    if r ~= nil then return r > 0 end
    if not learnedOk then return true end
    return learned[name] == true
end
function ns.IsTalent(id)
    local name = id and GetSpellInfo(id)
    if not name then return false end
    if not learned then rebuildLearned() end
    return (talRank and talRank[name] ~= nil) and true or false
end
local function onlyLearned(entries)
    local out = {}
    for _, e in ipairs(entries or {}) do
        if e.needs == true or ns.IsLearned(e.needs or e.id) then
            out[#out + 1] = e
        elseif e.id then
            ns.Avail.Drop(ns.EntryKey("spell", e))
        end
    end
    return out
end
ns.OnlyLearned = onlyLearned
local book = CreateFrame("Frame")
local TALENT_TICK = 1.0
local talentAcc = 0
local poll
local function forgetSpec()
    learned = nil
    ns.Avail.Reset()
    if ns.Incoming and ns.Incoming.Forget then ns.Incoming.Forget() end
    if ns.Profile and ns.Profile.SyncSpec then ns.Profile.SyncSpec() end
    if ns.Preset and ns.Preset.Sync then ns.Preset.Sync() end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    if not ns.TalentsKnown() then book:SetScript("OnUpdate", poll) end
    if ns.Options and ns.Options.Refresh then ns.Options.Refresh() end
end
function poll(self, elapsed)
    talentAcc = talentAcc + elapsed
    if talentAcc < TALENT_TICK then return end
    talentAcc = 0
    if not ns.TalentsKnown() then return end
    self:SetScript("OnUpdate", nil)
    forgetSpec()
end
book:RegisterEvent("SPELLS_CHANGED")
book:RegisterEvent("LEARNED_SPELL_IN_TAB")
book:RegisterEvent("PLAYER_TALENT_UPDATE")
book:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
book:SetScript("OnEvent", function() forgetSpec() end)
ns.ForgetSpec = forgetSpec
book:SetScript("OnUpdate", poll)
function ns.BuffEntries(list)
    local e = {}
    for _, v in ipairs(list or {}) do
        if type(v) == "table" then e[#e + 1] = v else e[#e + 1] = { id = v } end
    end
    return e
end
function ns.ItemEntries(list)
    local e = {}
    for _, v in ipairs(list or {}) do
        if type(v) == "table" then e[#e + 1] = v else e[#e + 1] = { item = v } end
    end
    return e
end
function ns.FoodAuraEntries(list)
    for _, v in ipairs(list or {}) do
        if type(v) == "table" and v.aura then
            return { { id = v.aura, noAction = true, tipKind = "food" } }
        end
    end
    return {}
end
function ns.EntryKey(kind, e)
    if e.slot then return "slot:" .. e.slot end
    if e.hand then return "weapon:" .. e.hand end
    if kind == "item" then return "item:" .. (e.item or 0) end
    if e.byName and not e.id then return "name:" .. e.byName end
    return "spell:" .. (e.id or 0)
end
function ns.BarProfile()
    local _, class = UnitClass("player")
    return (class or "?") .. "/" .. tostring(ns.CurrentVariant and ns.CurrentVariant() or "?")
end
function ns.PlayerRole()
    local _, class = UnitClass("player")
    return ns.RoleOf(class, ns.CurrentVariant and ns.CurrentVariant())
end
ns.ROLE_PRESET = {
    dd   = { dot = true  },
    heal = { dot = false },
    tank = { dot = false },
}
function ns.BarPicked(cat, entry, role)
    if entry and entry.off then return false end
    local preset = ns.ROLE_PRESET[role or ns.PlayerRole()]
    local d = preset and preset[cat]
    if d ~= nil then return d end
    return true
end
function ns.PickEntries(cat, kind, entries, all, role)
    local out = {}
    for _, e in ipairs(entries or {}) do
        local key = ns.EntryKey(kind, e)
        local on = ns.BarPicked(cat, e, role)
        if on or all then
            local c = {}
            for k, v in pairs(e) do c[k] = v end
            c._key, c._cat, c._on = key, cat, on
            out[#out + 1] = c
        end
    end
    return out
end
function ns.RoleOf(class, v)
    local info = ns.SpecInfo and ns.SpecInfo(class, v)
    return (info and info.role) or "dd"
end
function ns.BarSections(all, v)
    local _, class = UnitClass("player")
    v = v or ns.CurrentVariant()
    local s = ns.SpecData(ns.rotation, class, v)
    if not s then return {} end
    local out = {}
    local role = ns.RoleOf(class, v)
    local function section(key, kind, entries)
        entries = ns.PickEntries(key, kind, entries, all, role)
        if #entries > 0 then
            out[#out + 1] = { key = key, kind = kind, entries = entries }
        end
    end
    if s.buffs or s.weapon then
        local own = onlyLearned(ns.BuffEntries(s.buffs))
        local aura = ns.PaladinAuraEntry and ns.PaladinAuraEntry()
        if aura then tinsert(own, 1, aura) end
        for _, e in ipairs(ns.WeaponEntries(s.weapon)) do own[#own + 1] = e end
        section("personal", "spell", own)
    end
    if s.flask then
        local fl = { s.flask }
        if ns.IsAlchemist and ns.IsAlchemist() then
            fl[#fl + 1] = { item = 47499, aura = 67019 }
        end
        section("flask", "item", fl)
    end
    if s.food      then section("food",     "spell", ns.FoodAuraEntries(s.food)) end
    if s.raidBuffs then section("raid",     "spell", onlyLearned(ns.BuffEntries(s.raidBuffs))) end
    if s.potions then
        local pots = {}
        for _, e in ipairs(ns.ItemEntries(s.potions)) do
            if not e.needs or ns.IsLearned(e.needs) then
                e.buff = e.buff or (ns.potionBuffs and ns.potionBuffs[e.item]) or nil
                pots[#pots + 1] = e
            else
                ns.Avail.Drop(ns.EntryKey("item", e))
            end
        end
        section("potion", "item", pots)
    end
    return out
end
function ns.IsAlchemist()
    if GetItemCount and GetItemCount(47499) > 0 then return true end
    local alchemy = GetSpellInfo(2259)
    for i = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
        local name = GetSkillLineInfo(i)
        if alchemy and name == alchemy then return true end
    end
    return false
end
ns.buffsLoaded = true

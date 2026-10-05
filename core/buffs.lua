local ADDON, ns = ...
function ns.HasBuff(name)
    if not name then return false end
    for i = 1, 40 do
        local n = UnitBuff("player", i)
        if not n then break end
        if n == name then return true end
    end
    return false
end
local function unitHasAny(unit, names)
    for i = 1, 40 do
        local n = UnitBuff(unit, i)
        if not n then break end
        if names[n] then return true end
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
local function scanAura(unit, e, fn)
    if not unit or not UnitExists(unit) then return false end
    local set = ns.BuffNameSet(e)
    for i = 1, 40 do
        local n = fn(unit, i)
        if not n then break end
        if set[n] then return true end
    end
    return false
end
function ns.UnitHasBuff(unit, e)
    return scanAura(unit, e, UnitBuff)
end
function ns.UnitHasDebuff(unit, e)
    return scanAura(unit, e, UnitDebuff)
end
function ns.BuffLeft(name)
    if not name then return nil end
    for i = 1, 40 do
        local n, _, _, _, _, duration, expires = UnitBuff("player", i)
        if not n then break end
        if n == name then
            if not expires or expires == 0 then return 0 end
            return expires - GetTime(), duration, expires - (duration or 0)
        end
    end
    return nil
end
local SCAN_EVERY = 1.0
local groupBuffs = {}
local groupTotal = 0
local scanAt     = -1
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
local function groupScan()
    local units = ns.GroupUnits()
    groupTotal = #units
    for _, g in pairs(groupBuffs) do
        g.n, g.min, g.seen = 0, nil, nil
        g.mine, g.minMine, g.seenMine = 0, nil, nil
    end
    if groupTotal == 0 then return end
    local now = GetTime()
    for _, unit in ipairs(units) do
        for a = 1, 40 do
            local n, _, _, _, _, _, expires, caster = UnitBuff(unit, a)
            if not n then break end
            for _, g in pairs(groupBuffs) do
                if g.names[n] then
                    if g.seen ~= unit then g.seen = unit; g.n = g.n + 1 end
                    local left = (expires and expires > 0) and (expires - now) or nil
                    if left and (not g.min or left < g.min) then g.min = left end
                    if caster == "player" then
                        if g.seenMine ~= unit then g.seenMine = unit; g.mine = g.mine + 1 end
                        if left and (not g.minMine or left < g.minMine) then g.minMine = left end
                    end
                end
            end
        end
    end
end
function ns.GroupBuffNumbers(e)
    local id = (type(e) == "table") and e.id or e
    if not id or not GetSpellInfo(id) then return 0, 0, nil end
    local now = GetTime()
    local g = groupBuffs[id]
    if not g then
        g = { names = ns.BuffNameSet(e), n = 0, mine = 0 }
        groupBuffs[id] = g
        scanAt = -1
    end
    if now - scanAt >= SCAN_EVERY then
        scanAt = now
        groupScan()
    end
    if type(e) == "table" and e.single then
        return g.mine or 0, (groupTotal > 0) and 1 or 0, g.minMine
    end
    return g.n or 0, groupTotal, g.min
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
    talRank = {}
    if GetNumTalentTabs and GetTalentInfo and GetNumTalents then
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
local function onlyLearned(entries)
    local out = {}
    for _, e in ipairs(entries or {}) do
        if e.needs == true or ns.IsLearned(e.needs or e.id) then out[#out + 1] = e end
    end
    return out
end
ns.OnlyLearned = onlyLearned
local function forgetSpec()
    learned = nil
    if ns.Incoming and ns.Incoming.Forget then ns.Incoming.Forget() end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
local book = CreateFrame("Frame")
book:RegisterEvent("SPELLS_CHANGED")
book:RegisterEvent("LEARNED_SPELL_IN_TAB")
book:RegisterEvent("PLAYER_TALENT_UPDATE")
book:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
book:SetScript("OnEvent", forgetSpec)
local TALENT_TICK = 1.0
local talentAcc = 0
book:SetScript("OnUpdate", function(self, elapsed)
    talentAcc = talentAcc + elapsed
    if talentAcc < TALENT_TICK then return end
    talentAcc = 0
    if not ns.TalentsKnown() then return end
    self:SetScript("OnUpdate", nil)
    forgetSpec()
end)
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
function ns.BuffIds(list)
    local ids = {}
    for _, v in ipairs(list or {}) do
        ids[#ids + 1] = (type(v) == "table") and v.id or v
    end
    return ids
end
function ns.CountGroupBuffed(buffs)
    local units, inRaid = ns.GroupUnits()
    local total = #units
    if total == 0 then return 0, nil, inRaid end
    local names = {}
    for _, e in ipairs(ns.BuffEntries(buffs)) do
        for nm in pairs(ns.BuffNameSet(e)) do names[nm] = true end
    end
    if not next(names) then return 0, total, inRaid end
    local n = 0
    for _, unit in ipairs(units) do
        if unitHasAny(unit, names) then n = n + 1 end
    end
    return n, total, inRaid
end
function ns.PlayerTrackedBuffs()
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant()
    local s = ns.SpecData(ns.rotation, class, v)
    return s and s.buffs and ns.BuffIds(s.buffs) or nil
end
function ns.EntryKey(kind, e)
    if e.slot then return "slot:" .. e.slot end
    if kind == "item" then return "item:" .. (e.item or 0) end
    return "spell:" .. (e.id or 0)
end
function ns.BarProfile()
    local _, class = UnitClass("player")
    return (class or "?") .. "/" .. tostring(ns.CurrentVariant and ns.CurrentVariant() or "?")
end
function ns.PlayerRole()
    local _, class = UnitClass("player")
    local info = ns.SpecInfo and ns.SpecInfo(class, ns.CurrentVariant and ns.CurrentVariant())
    return (info and info.role) or "dd"
end
ns.ROLE_PRESET = {
    dd   = { dot = true  },
    heal = { dot = false },
    tank = { dot = false },
}
function ns.BarPicked(cat, key, entry)
    local pick = LazyBuffBarDB and LazyBuffBarDB.pick
    local p = pick and pick[ns.BarProfile()]
    local v = p and p[key]
    if v ~= nil then return v end
    if entry and entry.off then return false end
    local preset = ns.ROLE_PRESET[ns.PlayerRole()]
    local d = preset and preset[cat]
    if d ~= nil then return d end
    return true
end
function ns.SetBarPicked(key, on)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.pick = LazyBuffBarDB.pick or {}
    local prof = ns.BarProfile()
    LazyBuffBarDB.pick[prof] = LazyBuffBarDB.pick[prof] or {}
    LazyBuffBarDB.pick[prof][key] = on and true or false
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function ns.ResetBarPicks()
    if LazyBuffBarDB and LazyBuffBarDB.pick then
        LazyBuffBarDB.pick[ns.BarProfile()] = nil
    end
    if LazyBuffBarDB and LazyBuffBarDB.order then
        LazyBuffBarDB.order[ns.BarProfile()] = nil
    end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
local function savedOrder(cat)
    local o = LazyBuffBarDB and LazyBuffBarDB.order
    local p = o and o[ns.BarProfile()]
    return p and p[cat] or nil
end
function ns.SetBarOrder(cat, keys)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.order = LazyBuffBarDB.order or {}
    local p = ns.BarProfile()
    LazyBuffBarDB.order[p] = LazyBuffBarDB.order[p] or {}
    LazyBuffBarDB.order[p][cat] = keys
end
local function applyOrder(cat, out)
    local list = savedOrder(cat)
    if not list or #out < 2 then return out end
    local rank, base = {}, {}
    for i, k in ipairs(list) do rank[k] = i end
    for i, e in ipairs(out) do base[e] = i end
    table.sort(out, function(a, b)
        local ra, rb = rank[a._key], rank[b._key]
        if ra and rb then return ra < rb end
        if ra ~= rb then return ra ~= nil end
        return base[a] < base[b]
    end)
    return out
end
function ns.PickEntries(cat, kind, entries, all)
    local out = {}
    for _, e in ipairs(entries or {}) do
        local key = ns.EntryKey(kind, e)
        local on = ns.BarPicked(cat, key, e)
        if on or all then
            local c = {}
            for k, v in pairs(e) do c[k] = v end
            c._key, c._cat, c._on = key, cat, on
            out[#out + 1] = c
        end
    end
    return applyOrder(cat, out)
end
function ns.BarSections(all)
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant()
    local s = ns.SpecData(ns.rotation, class, v)
    if not s then return {} end
    local hide = (LazyBuffBarDB and LazyBuffBarDB.hide) or {}
    local out = {}
    local function section(key, kind, entries, hideKey)
        entries = ns.PickEntries(key, kind, entries, all)
        if #entries > 0 and (all or not hide[hideKey or key]) then
            out[#out + 1] = { key = key, kind = kind, entries = entries }
        end
    end
    local function idsToEntries(ids)
        return ns.BuffEntries(ids)
    end
    if s.buffs then
        local own = onlyLearned(idsToEntries(s.buffs))
        local aura = ns.PaladinAuraEntry and ns.PaladinAuraEntry()
        if aura then tinsert(own, 1, aura) end
        section("personal", "spell", own)
    end
    if s.flask then
        local fl = { s.flask }
        if ns.IsAlchemist and ns.IsAlchemist() then
            fl[#fl + 1] = { item = 47499, aura = 67019 }
        end
        section("flask", "item", fl, "personal")
    end
    if s.food      then section("food",     "spell", ns.FoodAuraEntries(s.food), "personal") end
    if s.raidBuffs then section("raid",     "spell", onlyLearned(idsToEntries(s.raidBuffs))) end
    if s.potions   then section("potion",   "item",  ns.ItemEntries(s.potions)) end
    return out
end
function ns.IsAlchemist()
    if GetItemCount and GetItemCount(47499) > 0 then return true end
    for i = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
        local name = GetSkillLineInfo(i)
        if name == "Алхимия" then return true end
    end
    return false
end
ns.BAR_CATEGORIES = {
    { key = "personal", label = "личные" },
    { key = "raid",     label = "рейд" },
    { key = "potion",   label = "препоты" },
}
function ns.BarCategoryShown(key)
    local hide = LazyBuffBarDB and LazyBuffBarDB.hide
    return not (hide and hide[key])
end
function ns.SetBarCategoryShown(key, shown)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.hide = LazyBuffBarDB.hide or {}
    LazyBuffBarDB.hide[key] = (not shown) and true or nil
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
ns.buffsLoaded = true

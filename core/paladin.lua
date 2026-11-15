local _, ns = ...
ns.BLESSINGS = {
    { key = "kings",  great = 25898, plain = 20217 },
    { key = "might",  great = 48934, plain = 48932 },
    { key = "wisdom", great = 48938, plain = 48936 },
    { key = "sanct",  great = 25899, plain = 20911 },
}
function ns.BlessingOf(id)
    local name = id and GetSpellInfo(id)
    if not name then return nil end
    for _, b in ipairs(ns.BLESSINGS) do
        if GetSpellInfo(b.great) == name then return b end
    end
    return nil
end
local function who()
    return UnitName("player") or "?"
end
function ns.MyBlessing()
    local by = LazyBuffBarDB and LazyBuffBarDB.blessing
    return by and by[who()] or nil
end
function ns.SetMyBlessing(key)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.blessing = LazyBuffBarDB.blessing or {}
    LazyBuffBarDB.blessing[who()] = key
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function ns.BlessingSymbols()
    local _, class = UnitClass("player")
    local s = ns.SpecData(ns.rotation, class, ns.CurrentVariant())
    local r = s and s.raidReagents and s.raidReagents[1]
    if not (r and r.item and GetItemCount) then return 0 end
    return GetItemCount(r.item) or 0
end
function ns.BlessingWantsPlain()
    local by = LazyBuffBarDB and LazyBuffBarDB.plain
    return (by and by[who()]) and true or false
end
function ns.SetBlessingWantsPlain(v)
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.plain = LazyBuffBarDB.plain or {}
    LazyBuffBarDB.plain[who()] = v and true or nil
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function ns.BlessingIsGreat(b)
    if not b or not ns.IsLearned(b.great) then return false end
    if ns.BlessingWantsPlain() then return false end
    return ns.BlessingSymbols() > 0
end
ns.BlessPP = {}
local PP = ns.BlessPP
local ppKey
local ppFor
local ppSkips = {}
function PP.Rules(key)
    if not (ppFor and ppFor[key]) then return false end
    local hand = LazyBuffBarDB and LazyBuffBarDB.blessPPHand
    hand = hand and hand[who()]
    return not (hand and hand[key])
end
function ns.BlessSkip(key)
    if PP.Rules(key) then
        local set = ppSkips[key]
        return (set and next(set)) and set or nil
    end
    local by = LazyBuffBarDB and LazyBuffBarDB.blessSkip
    local mine = by and by[who()]
    local set = (mine and mine[key]) or ns.blessData.skip[key]
    return (set and next(set)) and set or nil
end
function ns.SetBlessSkip(key, class, off)
    if InCombatLockdown() then return false end
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.blessSkip = LazyBuffBarDB.blessSkip or {}
    local by = LazyBuffBarDB.blessSkip
    by[who()] = by[who()] or {}
    local set = {}
    for c in pairs(ns.BlessSkip(key) or {}) do set[c] = true end
    set[class] = off and true or nil
    by[who()][key] = set
    if PP.Rules(key) then
        LazyBuffBarDB.blessPPHand = LazyBuffBarDB.blessPPHand or {}
        local hand = LazyBuffBarDB.blessPPHand
        hand[who()] = hand[who()] or {}
        hand[who()][key] = true
    end
    if ns.GroupBuffReset then ns.GroupBuffReset() end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    return true
end
local function auraEntry(b, great)
    if great then return { id = b.great } end
    return { id = b.great, alt = { b.plain } }
end
local LOW = 300
local HOLD = 3
local FAR = 9
local sent = {}
local aimed
local aimedAt = 0
local sentName
local function auraLeft(unit, set)
    for i = 1, 40 do
        local n, _, _, _, _, _, expires, caster = UnitBuff(unit, i)
        if not n then break end
        if set[n] then
            local left = (expires and expires > 0) and (expires - GetTime()) or 0
            return left, caster == "player"
        end
    end
    return nil, nil
end
local function tierOf(unit, spell)
    if UnitIsUnit(unit, "player") then return 0 end
    if IsSpellInRange and IsSpellInRange(spell, unit) ~= 1 then return FAR end
    if CheckInteractDistance then
        if CheckInteractDistance(unit, 3) then return 1 end
        if CheckInteractDistance(unit, 4) then return 2 end
    end
    return 3
end
local function held(unit, class, great, now)
    local g = UnitGUID and UnitGUID(unit)
    if g and (sent["u:" .. g] or 0) > now then return true end
    return great and class and (sent["c:" .. class] or 0) > now or false
end
function ns.BlessingTargets(b, skip)
    local out = {}
    if not b then return out, nil, false end
    skip = skip or ns.BlessSkip(b.key)
    local great = ns.BlessingIsGreat(b)
    local id = great and b.great or b.plain
    local spell = GetSpellInfo(id)
    if not spell or not ns.IsLearned(id) then return out, nil, great end
    local set = ns.BuffNameSet(auraEntry(b, great))
    local units = ns.GroupUnits()
    if #units == 0 then units = { "player" } end
    local now = GetTime()
    for _, unit in ipairs(units) do
        local _, class = UnitClass(unit)
        if UnitExists(unit) and not (skip and class and skip[class]) then
            local t = { unit = unit, name = UnitName(unit) or unit, class = class or "?", tier = FAR }
            if not UnitIsConnected(unit) then
                t.state = "off"
            elseif UnitIsDeadOrGhost(unit) then
                t.state = "dead"
            else
                t.left, t.mine = auraLeft(unit, set)
                t.tier = tierOf(unit, spell)
                if t.left and (t.left == 0 or t.left >= LOW) then
                    t.state = "has"
                elseif held(unit, class, great, now) then
                    t.state = "sent"
                elseif t.tier == FAR then
                    t.state = "far"
                else
                    t.state = t.left and "low" or "need"
                end
            end
            out[#out + 1] = t
        end
    end
    return out, spell, great
end
local RANK = { need = 1, low = 2, far = 3, dead = 4 }
local function before(a, b)
    local ra, rb = RANK[a.state], RANK[b.state]
    if ra ~= rb then return ra < rb end
    if a.tier ~= b.tier then return a.tier < b.tier end
    return a.pos < b.pos
end
local function plainQueue(targets)
    local q = {}
    for i, t in ipairs(targets) do
        if RANK[t.state] then q[#q + 1] = { unit = t.unit, class = t.class, state = t.state, tier = t.tier, pos = i } end
    end
    table.sort(q, before)
    return q
end
local function classStep(targets, c)
    local need, low, far, dead, rep
    for i, t in ipairs(targets) do
        if t.class == c then
            local s = t.state
            if s == "need" then need = true elseif s == "low" then low = true
            elseif s == "far" then far = far or { t = t, pos = i }
            elseif s == "dead" then dead = dead or { t = t, pos = i } end
            if t.tier < FAR and (s == "need" or s == "low" or s == "has") and (not rep or t.tier < rep.t.tier) then
                rep = { t = t, pos = i }
            end
        end
    end
    local state, pick
    if (need or low) and rep then state, pick = need and "need" or "low", rep
    elseif far then state, pick = "far", far
    elseif dead then state, pick = "dead", dead end
    if not pick then return nil end
    return { unit = pick.t.unit, class = c, state = state, tier = pick.t.tier, pos = pick.pos }
end
local function greatQueue(targets)
    local seen, q = {}, {}
    for _, t in ipairs(targets) do
        if not seen[t.class] then
            seen[t.class] = true
            local step = classStep(targets, t.class)
            if step then q[#q + 1] = step end
        end
    end
    table.sort(q, before)
    return q
end
function ns.BlessingQueue(b, skip)
    local targets, spell, great = ns.BlessingTargets(b, skip)
    if not spell then return {}, nil, great, targets end
    local q = great and greatQueue(targets) or plainQueue(targets)
    return q, spell, great, targets
end
function ns.BlessingClickQueue(q)
    local out = {}
    for _, s in ipairs(q) do
        if s.state ~= "far" then out[#out + 1] = s end
    end
    return out
end
function ns.NextBlessingCast(b)
    local q, spell, great = ns.BlessingQueue(b)
    local s = q[1]
    if not spell or not s or (s.state ~= "need" and s.state ~= "low") then return nil, spell, great, nil end
    return s.unit, spell, great, s.class
end
local SHOW = { need = 1, low = 2, far = 3, dead = 4, sent = 5, off = 6, has = 7 }
local function rowBefore(a, b)
    if SHOW[a.state] ~= SHOW[b.state] then return SHOW[a.state] < SHOW[b.state] end
    if a.state == "has" and (a.left or 0) ~= (b.left or 0) then
        if (a.left or 0) == 0 then return false end
        if (b.left or 0) == 0 then return true end
        return a.left < b.left
    end
    return a.pos < b.pos
end
local function classRow(targets, c, pos)
    local row = { label = (ns.CLASS_NAME and ns.CLASS_NAME[c]) or c, class = c, have = 0, total = 0, miss = {}, pos = pos }
    local sentAll, any = true, false
    for _, t in ipairs(targets) do
        if t.class == c and t.state ~= "off" then
            row.total = row.total + 1
            if t.state == "has" or t.state == "low" then
                row.have = row.have + 1
                if t.left and t.left > 0 and (not row.left or t.left < row.left) then row.left = t.left end
            end
            if RANK[t.state] then row.miss[#row.miss + 1] = t.name end
            if t.state ~= "sent" then sentAll = false end
            any = true
        end
    end
    local step = classStep(targets, c)
    if step then
        row.state, row.unit = step.state, step.unit
    elseif not any then
        row.state = "off"
    elseif sentAll then
        row.state = "sent"
    else
        row.state = "has"
    end
    return row
end
function ns.BlessingRows(b)
    local targets, spell, great = ns.BlessingTargets(b)
    local rows = {}
    if not spell then return rows, nil, great end
    if great then
        local seen = {}
        for i, t in ipairs(targets) do
            if not seen[t.class] then
                seen[t.class] = true
                rows[#rows + 1] = classRow(targets, t.class, i)
            end
        end
    else
        for i, t in ipairs(targets) do
            rows[#rows + 1] = { label = t.name, class = t.class, state = t.state, left = t.left, unit = t.unit, pos = i }
        end
    end
    table.sort(rows, rowBefore)
    return rows, spell, great
end
function ns.BlessingSnapshot(b, skip)
    local targets, spell, great = ns.BlessingTargets(b, skip)
    local classes = {}
    if not spell then return {}, nil, great, targets, classes end
    local q = great and greatQueue(targets) or plainQueue(targets)
    for i, t in ipairs(targets) do
        if not classes[t.class] then classes[t.class] = classRow(targets, t.class, i) end
    end
    return q, spell, great, targets, classes
end
local blessNames
local function isBlessing(spell)
    if not spell then return false end
    if not blessNames then
        blessNames = {}
        for _, b in ipairs(ns.BLESSINGS) do
            for _, id in ipairs({ b.great, b.plain }) do
                local n = GetSpellInfo(id)
                if n then blessNames[n] = true end
            end
        end
    end
    return blessNames[spell] == true
end
local function unitByName(name)
    if not name or name == "" then return nil end
    local units = ns.GroupUnits()
    if #units == 0 then units = { "player" } end
    for _, unit in ipairs(units) do
        local n, realm = UnitName(unit)
        if n == name or (realm and realm ~= "" and (n .. "-" .. realm) == name) then return unit end
    end
    if UnitName("player") == name then return "player" end
    return nil
end
function ns.BlessingAimed(unit)
    aimed, aimedAt = unit, GetTime()
end
local blessListeners = {}
function ns.OnBlessingChange(fn)
    blessListeners[#blessListeners + 1] = fn
end
local dirty = false
local function isGreat(spell)
    for _, x in ipairs(ns.BLESSINGS) do
        if GetSpellInfo(x.great) == spell then return true end
    end
    return false
end
local function commit(spell)
    local unit = unitByName(sentName)
    if not unit and aimed and GetTime() - aimedAt < 2 then unit = aimed end
    sentName, aimed = nil, nil
    if not unit then return end
    local now = GetTime()
    for k, v in pairs(sent) do
        if v <= now then sent[k] = nil end
    end
    local till = now + HOLD
    local g = UnitGUID and UnitGUID(unit)
    if g then sent["u:" .. g] = till end
    local _, class = UnitClass(unit)
    if class and isGreat(spell) then sent["c:" .. class] = till end
end
local reset = false
local auraMark = {}
local markKey
local markNames
local function namesOf(key)
    if markKey == key and markNames then return markNames end
    auraMark, markKey, markNames = {}, key, {}
    for _, b in ipairs(ns.BLESSINGS) do
        if b.key == key then
            for _, id in ipairs({ b.great, b.plain }) do
                local n = GetSpellInfo(id)
                if n then markNames[n] = true end
            end
        end
    end
    return markNames
end
local function blessMoved(unit, key)
    local names = namesOf(key)
    local mark = ""
    for i = 1, 40 do
        local n, _, _, _, _, _, expires, caster = UnitBuff(unit, i)
        if not n then break end
        if names[n] then
            mark = n .. (caster == "player" and "+" or "-") .. math.floor(expires or 0)
            break
        end
    end
    if auraMark[unit] == mark then return false end
    auraMark[unit] = mark
    return true
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("UNIT_SPELLCAST_SENT")
watch:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watch:RegisterEvent("UNIT_SPELLCAST_FAILED")
watch:RegisterEvent("UNIT_AURA")
watch:RegisterEvent("PARTY_MEMBERS_CHANGED")
watch:RegisterEvent("RAID_ROSTER_UPDATE")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:SetScript("OnEvent", function(_, event, unit, spell, _, target)
    local key = ns.MyBlessing()
    if not key then return end
    if event == "UNIT_AURA" then
        if unit and (unit == "player" or unit:find("^party%d") or unit:find("^raid%d"))
            and blessMoved(unit, key) then dirty = true end
        return
    end
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then dirty = true; return end
    if event == "PLAYER_REGEN_ENABLED" then dirty, reset = true, true; return end
    if unit ~= "player" or not isBlessing(spell) then return end
    if event == "UNIT_SPELLCAST_SENT" then
        sentName = target
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        commit(spell)
        dirty = true
    else
        sentName = nil
        dirty, reset = true, true
    end
end)
local EVERY = 1
local SOON = 0.1
local acc, since = 0, 0
watch:SetScript("OnUpdate", function(_, elapsed)
    acc, since = acc + elapsed, since + elapsed
    if not ns.MyBlessing() then return end
    if (dirty and since >= SOON) or acc >= EVERY then
        local again = reset
        dirty, reset, acc, since = false, false, 0, 0
        for _, fn in ipairs(blessListeners) do fn(again) end
    end
end)
ns.BlessClick = {}
ns.BlessClick.PRE = [[
local n = self:GetAttribute("bq-n")
if not n then return end
if IsAltKeyDown() then return false end
if button == "RightButton" then
    if PlayerInCombat() then
        local i = (self:GetAttribute("bq-i") or 1) - 1
        self:SetAttribute("bq-i", i < 1 and 1 or i)
    end
    return
end
if button ~= "LeftButton" then return end
local i = self:GetAttribute("bq-i") or 1
while i <= n do
    local u = self:GetAttribute("bq-" .. i)
    if u and UnitExists(u) and not UnitIsDead(u) and not UnitIsGhost(u) then
        self:SetAttribute("unit", u)
        self:SetAttribute("bq-i", i)
        return nil, "sent"
    end
    i = i + 1
end
self:SetAttribute("bq-i", n + 1)
return false
]]
ns.BlessClick.POST = [[
if message == "sent" then self:SetAttribute("bq-i", (self:GetAttribute("bq-i") or 1) + 1) end
]]
function ns.BlessClick.Next(c)
    local n = c and c:GetAttribute("bq-n")
    if not n then return nil end
    for i = c:GetAttribute("bq-i") or 1, n do
        local u = c:GetAttribute("bq-" .. i)
        if u and UnitExists(u) and not UnitIsDeadOrGhost(u) then return u, i, n end
    end
    return nil
end
function ns.BlessClick.Write(c, q, spell)
    local sig = q and #q > 0 and spell or nil
    if sig then
        local parts = { spell }
        for i, s in ipairs(q) do parts[i + 1] = s.unit end
        sig = table.concat(parts, " ")
    end
    if c._bqSig == sig then
        local n, i = c:GetAttribute("bq-n"), c:GetAttribute("bq-i")
        if n and i and i > n then c:SetAttribute("bq-i", 1) end
        return
    end
    local n = sig and #q or 0
    for i = 1, math.max(n, c._bqN or 0) do
        c:SetAttribute("bq-" .. i, i <= n and q[i].unit or nil)
    end
    c:SetAttribute("bq-n", n > 0 and n or nil)
    c:SetAttribute("bq-i", n > 0 and 1 or nil)
    c._bqSig, c._bqN = sig, n
end
ns.PALADIN_AURAS ={ 48942, 54043, 19746, 32223, 48943, 48945, 48947 }
local auraById
local function auraNames()
    if auraById then return auraById end
    auraById = {}
    for _, id in ipairs(ns.PALADIN_AURAS) do
        local n = GetSpellInfo(id)
        if n then auraById[n] = id end
    end
    return auraById
end
function ns.MyAura()
    local by = auraNames()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster = UnitBuff("player", i)
        if not name then break end
        if caster == "player" and by[name] then return by[name], name end
    end
    return nil, nil
end
local function firstKnownAura()
    for _, id in ipairs(ns.PALADIN_AURAS) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
function ns.PaladinAuraEntry()
    local _, class = UnitClass("player")
    if class ~= "PALADIN" then return nil end
    local id = ns.MyAura()
    local on = id ~= nil
    id = id or firstKnownAura()
    if not id then return nil end
    return { id = id, slot = "aura", state = on, noAction = true }
end
local PP_ADDON = "PallyPower"
local PP_TABLE = "PallyPower_Assignments"
local PP_PREFIX = "PLPWR"
local PP_DELAY = 0.3
local PP_BLESS = { [1] = "wisdom", [2] = "might", [3] = "kings", [4] = "sanct" }
local PP_CLASS = { "WARRIOR", "ROGUE", "PRIEST", "DRUID", "PALADIN", "HUNTER", "MAGE", "WARLOCK", "SHAMAN", "DEATHKNIGHT" }
function PP.Loaded()
    local _, class = UnitClass("player")
    return class == "PALADIN" and IsAddOnLoaded ~= nil and IsAddOnLoaded(PP_ADDON) and true or false
end
function PP.On()
    local off = LazyBuffBarDB and LazyBuffBarDB.blessPPOff
    return not (off and off[who()])
end
function PP.Key()
    return ppKey
end
local function byKey(k)
    for _, b in ipairs(ns.BLESSINGS) do
        if b.key == k then return b end
    end
end
local function ppRead()
    if not (PP.Loaded() and PP.On()) then return nil end
    if (GetNumRaidMembers() or 0) == 0 and (GetNumPartyMembers() or 0) == 0 then return nil end
    local all = _G[PP_TABLE]
    local mine = type(all) == "table" and all[who()]
    if type(mine) ~= "table" then return nil end
    local present = {}
    for _, u in ipairs(ns.GroupUnits()) do
        local _, c = UnitClass(u)
        if c then present[c] = true end
    end
    local forMe, sig = {}, {}
    local here, any = {}, {}
    for i, c in ipairs(PP_CLASS) do
        local n = tonumber(mine[i]) or 0
        sig[i] = n
        local k = PP_BLESS[n]
        if k and ns.IsLearned(byKey(k).plain) then
            forMe[k] = forMe[k] or {}
            forMe[k][c] = true
            any[k] = (any[k] or 0) + 1
            if present[c] then here[k] = (here[k] or 0) + 1 end
        end
    end
    local best, bestN
    for _, count in ipairs({ here, any }) do
        for _, b in ipairs(ns.BLESSINGS) do
            local n = count[b.key]
            if n and (not bestN or n > bestN) then best, bestN = b.key, n end
        end
        if best then break end
    end
    return best, forMe, table.concat(sig, ",")
end
function PP.Sync()
    local key, forMe, sig = ppRead()
    ppKey, ppFor = key, forMe
    wipe(ppSkips)
    for k, set in pairs(forMe or {}) do
        local skip = {}
        for _, c in ipairs(PP_CLASS) do
            if not set[c] then skip[c] = true end
        end
        ppSkips[k] = skip
    end
    if sig then
        LazyBuffBarDB = LazyBuffBarDB or {}
        LazyBuffBarDB.blessPP = LazyBuffBarDB.blessPP or {}
        if LazyBuffBarDB.blessPP[who()] ~= sig then
            LazyBuffBarDB.blessPP[who()] = sig
            if LazyBuffBarDB.blessPPHand then LazyBuffBarDB.blessPPHand[who()] = nil end
            if key and key ~= ns.MyBlessing() then
                LazyBuffBarDB.blessing = LazyBuffBarDB.blessing or {}
                LazyBuffBarDB.blessing[who()] = key
            end
        end
    end
    if ns.GroupBuffReset then ns.GroupBuffReset() end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
function PP.Set(on)
    if InCombatLockdown() then return false end
    LazyBuffBarDB = LazyBuffBarDB or {}
    LazyBuffBarDB.blessPPOff = LazyBuffBarDB.blessPPOff or {}
    LazyBuffBarDB.blessPPOff[who()] = (not on) and true or nil
    PP.Sync()
    return true
end
local ppWait
local ppFrame = CreateFrame("Frame")
ppFrame:Hide()
ppFrame:SetScript("OnUpdate", function(self, elapsed)
    ppWait = (ppWait or 0) - (elapsed or 0)
    if ppWait > 0 then return end
    self:Hide()
    ns.DeferKey("bless.pp", PP.Sync)
end)
local function ppLater()
    ppWait = PP_DELAY
    ppFrame:Show()
end
local ppHooked = false
ppFrame:RegisterEvent("PLAYER_LOGIN")
ppFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ppFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
ppFrame:RegisterEvent("RAID_ROSTER_UPDATE")
ppFrame:RegisterEvent("CHAT_MSG_ADDON")
ppFrame:SetScript("OnEvent", function(_, event, prefix)
    if event == "CHAT_MSG_ADDON" and prefix ~= PP_PREFIX then return end
    if not PP.Loaded() then return end
    if event == "PLAYER_LOGIN" and not ppHooked then
        ppHooked = true
        for _, fname in ipairs({ "PallyPowerGridButton_OnClick", "PallyPowerGridButton_OnMouseWheel" }) do
            if type(_G[fname]) == "function" then hooksecurefunc(fname, ppLater) end
        end
    end
    ppLater()
end)
ns.paladinLoaded = true

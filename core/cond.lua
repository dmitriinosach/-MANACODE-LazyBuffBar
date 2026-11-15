local _, ns = ...
ns.Cond = {}
local C = ns.Cond
C.KEYS = {
    spec = { 1, 2 },
    combat = { "in", "out" },
    where = { "raid", "party", "arena", "pvp", "world" },
    group = { "group", "solo" },
}
C.ORDER = { "spec", "combat", "where", "group" }
local INSTANCE = { raid = "raid", party = "party", arena = "arena", pvp = "pvp" }
function C.InCombat()
    return (InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player"))) and true or false
end
function C.Now()
    local _, kind = IsInInstance()
    local grouped = (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0
    return {
        spec = ns.ActiveSlot(),
        combat = C.InCombat() and "in" or "out",
        where = INSTANCE[kind or ""] or "world",
        group = grouped and "group" or "solo",
    }
end
function C.Has(cond, field, key)
    local set = cond and cond[field]
    if set == nil then return true end
    return set[key] and true or false
end
function C.Limits(cond, field)
    return (cond and cond[field]) ~= nil
end
function C.Allows(cond, skip, now)
    if not cond then return true end
    now = now or C.Now()
    for _, field in ipairs(C.ORDER) do
        if field ~= skip and not C.Has(cond, field, now[field]) then return false end
    end
    return true
end
function C.With(cond, field, key, on)
    local keys = C.KEYS[field]
    if not keys then return cond end
    local set = {}
    local n = 0
    for _, k in ipairs(keys) do
        local v = C.Has(cond, field, k)
        if k == key then v = on and true or false end
        if v then
            set[k] = true
            n = n + 1
        end
    end
    if n == 0 then return cond end
    local out = {}
    for f, s in pairs(cond or {}) do
        if f ~= field then out[f] = s end
    end
    if n < #keys then out[field] = set end
    if next(out) == nil then return nil end
    return out
end
function C.Driver(cond)
    local set = cond and cond.combat
    if not set then return nil end
    if set["in"] and not set.out then return "[combat] show; hide" end
    if set.out and not set["in"] then return "[nocombat] show; hide" end
    return nil
end
function C.Combine(cond, inner)
    local set = cond and cond.combat
    if set then
        if set["in"] and not set.out then return "[nocombat] hide; " .. inner end
        if set.out and not set["in"] then return "[combat] hide; " .. inner end
    end
    return inner
end
local function anyCond()
    if not (ns.Preset and ns.Preset.Blocks and ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return false end
    for _, b in ipairs(ns.Preset.Blocks()) do
        if b.cond then return true end
    end
    return false
end
local last
local function recheck()
    if not anyCond() then
        last = nil
        return
    end
    local now = C.Now()
    if last and last.spec == now.spec and last.where == now.where and last.group == now.group then return end
    last = now
    ns.DeferKey("panel.cond", function()
        if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    end)
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then last = nil end
    recheck()
end)
function C.Last()
    return last
end
C.RULE_UNITS = { "player", "target", "focus", "tank" }
C.RULE_TYPES = { "hp", "power" }
C.RULE_OPS = { "<", ">" }
C.RULE_MIN = 1
C.RULE_MAX = 99
C.RULE_STEP = 5
C.RULE_LIMIT = 6
local RULE_EVENTS = {
    hp = { "UNIT_HEALTH", "UNIT_MAXHEALTH" },
    power = { "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER", "UNIT_MAXMANA", "UNIT_MAXRAGE",
              "UNIT_MAXENERGY", "UNIT_MAXFOCUS", "UNIT_MAXRUNIC_POWER", "UNIT_DISPLAYPOWER" },
}
local UNIT_SWAP = { target = "PLAYER_TARGET_CHANGED", focus = "PLAYER_FOCUS_CHANGED" }
local function member(list, v)
    for _, x in ipairs(list) do
        if x == v then return true end
    end
    return false
end
function C.NewRule()
    return { u = "target", t = "hp", op = "<", v = 20 }
end
function C.CleanRule(rule)
    if type(rule) ~= "table" then return nil end
    if not (member(C.RULE_UNITS, rule.u) and member(C.RULE_TYPES, rule.t) and member(C.RULE_OPS, rule.op)) then return nil end
    local v = tonumber(rule.v)
    if not v then return nil end
    v = math.floor(v + 0.5)
    if v < C.RULE_MIN then v = C.RULE_MIN end
    if v > C.RULE_MAX then v = C.RULE_MAX end
    return { u = rule.u, t = rule.t, op = rule.op, v = v }
end
function C.CleanRules(rules)
    if type(rules) ~= "table" then return nil end
    local out = {}
    for _, r in ipairs(rules) do
        local c = C.CleanRule(r)
        if c and #out < C.RULE_LIMIT then out[#out + 1] = c end
    end
    if #out == 0 then return nil end
    return out
end
function C.Value(t, u)
    local unit = ns.Units and ns.Units.Resolve(u)
    if not unit or UnitIsDeadOrGhost(unit) then return nil end
    if t == "hp" then
        local m = UnitHealthMax(unit)
        if not m or m <= 0 then return nil end
        return (UnitHealth(unit) or 0) * 100 / m
    end
    local kind = UnitPowerType(unit)
    local m = UnitPowerMax(unit, kind)
    if not m or m <= 0 then return nil end
    return (UnitPower(unit, kind) or 0) * 100 / m
end
function C.Pass(rule)
    local v = C.Value(rule.t, rule.u)
    if not v then return false end
    if rule.op == "<" then return v < rule.v end
    return v > rule.v
end
function C.RulesPass(rules)
    if not rules then return true end
    for _, r in ipairs(rules) do
        if not C.Pass(r) then return false end
    end
    return true
end
function C.WithRule(rules, i, rule)
    local out = {}
    for n, r in ipairs(rules or {}) do
        if n ~= i then
            out[#out + 1] = r
        elseif rule then
            out[#out + 1] = rule
        end
    end
    if not i and rule then out[#out + 1] = rule end
    return C.CleanRules(out)
end
function C.WithRules(cond, rules)
    local out = {}
    for f, s in pairs(cond or {}) do
        if f ~= "rules" then out[f] = s end
    end
    out.rules = C.CleanRules(rules)
    if next(out) == nil then return nil end
    return out
end
function C.AllowsAll(cond)
    if not cond then return true end
    return C.Allows(cond) and C.RulesPass(cond.rules)
end
local lists = {}
local passed = {}
local ruleUnits = {}
local tokens = {}
local registered = {}
local stale = false
local listeners = {}
local hooked = false
local rf = CreateFrame("Frame")
local function remap()
    wipe(tokens)
    for l in pairs(ruleUnits) do
        if l == "player" or UNIT_SWAP[l] then
            tokens[l] = true
        else
            local u = ns.Units and ns.Units.Resolve(l)
            if u then tokens[u] = true end
        end
    end
end
local function subscribe(want)
    for e in pairs(registered) do
        if not want[e] then
            rf:UnregisterEvent(e)
            registered[e] = nil
        end
    end
    for e in pairs(want) do
        if not registered[e] then
            rf:RegisterEvent(e)
            registered[e] = true
        end
    end
end
rf:SetScript("OnEvent", function(_, event, unit)
    if UNIT_SWAP.target == event or UNIT_SWAP.focus == event then
        stale = true
        return
    end
    if tokens[unit or ""] then stale = true end
end)
function C.Watch(all)
    lists = {}
    for _, r in ipairs(all or {}) do
        if r and #r > 0 then lists[#lists + 1] = r end
    end
    wipe(passed)
    wipe(ruleUnits)
    local want = {}
    for _, r in ipairs(lists) do
        for _, rule in ipairs(r) do
            ruleUnits[rule.u] = true
            for _, e in ipairs(RULE_EVENTS[rule.t] or {}) do want[e] = true end
            if UNIT_SWAP[rule.u] then want[UNIT_SWAP[rule.u]] = true end
        end
    end
    if ruleUnits.tank and not hooked and ns.Units then
        hooked = true
        ns.Units.OnChange(function()
            if next(ruleUnits) then
                remap()
                stale = true
            end
        end)
    end
    subscribe(want)
    remap()
    for i, r in ipairs(lists) do passed[i] = C.RulesPass(r) end
    stale = false
end
function C.RuleUnits()
    return ruleUnits
end
function C.Watched()
    return registered, tokens
end
function C.OnRules(fn)
    listeners[#listeners + 1] = fn
end
function C.Flush()
    if not stale then return false end
    stale = false
    local changed = false
    for i, r in ipairs(lists) do
        local p = C.RulesPass(r)
        if passed[i] ~= p then
            passed[i] = p
            changed = true
        end
    end
    if changed then
        for _, fn in ipairs(listeners) do fn() end
    end
    return changed
end
ns.condLoaded = true

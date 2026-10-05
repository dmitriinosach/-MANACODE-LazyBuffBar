local ADDON, ns = ...
local GCD = 1.5
local function specTrack()
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant()
    local s = ns.SpecData(ns.rotation, class, v)
    return s and s.track or nil
end
local function trinketEntries()
    return ns.Trinket.Entries()
end
local function racialEntries()
    local _, class = UnitClass("player")
    local bonus = ns.RaceBonus and ns.RaceBonus(class)
    local out = {}
    for _, id in ipairs(bonus and bonus.spells or {}) do out[#out + 1] = { id = id } end
    return out
end
function ns.TrackSections(all)
    local t = specTrack()
    local hide = (LazyBuffBarDB and LazyBuffBarDB.hide) or {}
    local out = {}
    local function section(key, kind, entries)
        entries = ns.PickEntries(key, kind, entries, all)
        if #entries > 0 and (all or not hide[key]) then
            out[#out + 1] = { key = key, kind = kind, entries = entries }
        end
    end
    section("proc", "aura",   t and ns.OnlyLearned(t.procs))
    section("cd",   "spell",  t and ns.OnlyLearned(t.cds))
    local gear = trinketEntries()
    for _, e in ipairs(racialEntries()) do gear[#gear + 1] = e end
    section("gear", "mixed",  gear)
    section("dot",  "debuff", t and ns.OnlyLearned(t.dots))
    return out
end
ns.TRACK_CATEGORIES = {
    { key = "proc", label = "Проки" },
    { key = "cd",   label = "Кулдауны" },
    { key = "gear", label = "Аксессуары и расовые" },
    { key = "dot",  label = "Доты на цели" },
}
function ns.HasTrack(...)
    local t = ...
    if select('#', ...) == 0 then t = specTrack() end
    return (t and ((t.procs and #t.procs > 0) or (t.cds and #t.cds > 0)
                   or (t.dots and #t.dots > 0))) and true or false
end
local function auraByName(unit, name, filter)
    if not name or not UnitExists(unit) then return nil end
    for i = 1, 40 do
        local n, _, _, count, _, duration, expires = UnitAura(unit, i, filter)
        if not n then break end
        if n == name then
            local left = expires and expires > 0 and (expires - GetTime()) or 0
            return { left = left, duration = duration or 0, stacks = count }
        end
    end
    return nil
end
function ns.TrackState(kind, entry)
    if kind == "mixed" then kind = entry.slot and "item" or "spell" end
    if kind == "item" then return ns.Trinket.State(entry) end
    local name, _, icon = GetSpellInfo(entry.id)
    if kind == "spell" then
        local start, duration = GetSpellCooldown(name or entry.id)
        local onCd = duration and duration > GCD
        local noMana, far
        if name and not onCd then
            noMana = select(2, IsUsableSpell(name)) and true or nil
            far = (UnitExists("target") and IsSpellInRange(name, "target") == 0) or nil
        end
        return {
            icon = icon, name = name, spell = entry.id,
            active = not onCd,
            start = start, duration = duration,
            left = onCd and (start + duration - GetTime()) or nil,
            noMana = noMana, far = far,
        }
    end
    if kind == "aura" then
        local a = auraByName("player", name, "HELPFUL")
        return {
            icon = icon, name = name, spell = entry.id,
            active = a ~= nil,
            left = a and a.left, duration = a and a.duration, stacks = a and a.stacks,
        }
    end
    local a = auraByName("target", name, "HARMFUL|PLAYER")
    return {
        icon = icon, name = name, spell = entry.id,
        active = a ~= nil,
        left = a and a.left, duration = a and a.duration, stacks = a and a.stacks,
    }
end
ns.trackLoaded = true

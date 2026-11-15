local _, ns = ...
local GCD = 1.5
local RANGE_EVERY = 0.25
local function specTrack(v)
    local _, class = UnitClass("player")
    v = v or ns.CurrentVariant()
    local s = ns.SpecData(ns.rotation, class, v)
    return s and s.track or nil
end
local function trinketEntries()
    return ns.Trinket.Entries()
end
function ns.RaceBonus(class, race)
    if not race then
        local _, token = UnitRace("player")
        race = token
    end
    local out = {}
    for _, e in ipairs((race and ns.racials and ns.racials[race]) or {}) do
        if not e.classes or (class and e.classes[class]) then out[#out + 1] = e end
    end
    return out
end
local function racialEntries()
    local _, class = UnitClass("player")
    local out = {}
    for _, e in ipairs(ns.OnlyLearned(ns.RaceBonus(class))) do
        out[#out + 1] = { id = e.id, off = e.off }
    end
    return out
end
local lookByName
function ns.ProcLook(entry)
    local t = ns.procLook
    if not (t and entry and entry.id) then return nil end
    local r = t[entry.id]
    if r then return r end
    if not lookByName then
        lookByName = {}
        for id, look in pairs(t) do
            local ids = { id }
            for _, x in ipairs(look.ids or {}) do ids[#ids + 1] = x end
            for _, x in ipairs(ids) do
                local n = GetSpellInfo(x)
                if n and not lookByName[n] then lookByName[n] = look end
            end
        end
    end
    local n = GetSpellInfo(entry.id)
    return n and lookByName[n] or nil
end
function ns.ProcGlows(entry, st)
    if not (st and st.active) then return false end
    local look = ns.ProcLook(entry)
    if not look or look.glow == nil then return true end
    if look.glow == false then return false end
    return (st.stacks or 0) >= look.glow
end
function ns.ProcShow(entry, show)
    if show ~= nil then return show end
    local look = ns.ProcLook(entry)
    return look and look.show or nil
end
ns.MyProcs = {}
local function myStore(create)
    local d = LazyBuffBarDB
    if type(d) ~= "table" then return nil end
    local p = ns.BarProfile()
    if create then
        d.myProcs = d.myProcs or {}
        d.myProcs[p] = d.myProcs[p] or {}
    end
    return d.myProcs and d.myProcs[p]
end
local function builtinProcs()
    local set = {}
    local t = specTrack()
    for _, e in ipairs((t and t.procs) or {}) do
        local id = type(e) == "table" and e.id or e
        if id then set[id] = true end
    end
    return set
end
function ns.MyProcs.List()
    return myStore() or {}
end
function ns.MyProcs.Tracked(id)
    if builtinProcs()[id] then return true end
    for _, v in ipairs(ns.MyProcs.List()) do
        if v == id then return true end
    end
    return false
end
function ns.MyProcs.Resolve(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    local n = tonumber(text)
    if n then return GetSpellInfo(n) and n or nil end
    local link = GetSpellLink and GetSpellLink(text)
    local id = link and tonumber(link:match("spell:(%d+)"))
    if id then return id end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end
        if name == text and spellId then return spellId end
    end
    return nil
end
function ns.MyProcs.Add(id)
    if ns.MyProcs.Tracked(id) then return false, "tracked" end
    local list = myStore(true)
    list[#list + 1] = id
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    return true
end
function ns.MyProcs.Remove(id)
    local list = myStore()
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == id then table.remove(list, i) end
    end
    if #list == 0 then LazyBuffBarDB.myProcs[ns.BarProfile()] = nil end
    if LazyBuffBarDB.myProcs and not next(LazyBuffBarDB.myProcs) then LazyBuffBarDB.myProcs = nil end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
local OWN_GROUP = { cd = "cd", dot = "dot", harm = "proc", proc = "proc" }
local function refStore(create)
    local d = LazyBuffBarDB
    if type(d) ~= "table" then return nil end
    local p = ns.BarProfile()
    if create then
        d.myTrack = d.myTrack or {}
        d.myTrack[p] = d.myTrack[p] or {}
    end
    return d.myTrack and d.myTrack[p]
end
local function splitRef(k)
    local id = tonumber(tostring(k):match("^spell:(%d+)$"))
    if id then return id, nil end
    local name = tostring(k):match("^name:(.+)$")
    return nil, name
end
function ns.MyProcs.Entries()
    local out = {}
    for _, id in ipairs(ns.MyProcs.List()) do
        out[#out + 1] = { k = "spell:" .. id, role = "proc", id = id }
    end
    for _, r in ipairs(refStore() or {}) do
        local id, name = splitRef(r.k)
        out[#out + 1] = { k = r.k, role = r.role, id = id, name = name }
    end
    return out
end
function ns.MyProcs.GroupOf(role)
    return OWN_GROUP[role]
end
function ns.MyProcs.AddRef(k, role)
    if not OWN_GROUP[role] then return false, "role" end
    local id, name = splitRef(k)
    if not id and not name then return false, "role" end
    if role == "proc" and id then return ns.MyProcs.Add(id) end
    for _, r in ipairs(refStore() or {}) do
        if r.k == k and r.role == role then return false, "tracked" end
    end
    local list = refStore(true)
    list[#list + 1] = { k = k, role = role }
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    return true
end
function ns.MyProcs.RemoveRef(k, role)
    local id = splitRef(k)
    if role == "proc" and id then return ns.MyProcs.Remove(id) end
    local list = refStore()
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].k == k and list[i].role == role then table.remove(list, i) end
    end
    local p = ns.BarProfile()
    if #list == 0 then LazyBuffBarDB.myTrack[p] = nil end
    if LazyBuffBarDB.myTrack and not next(LazyBuffBarDB.myTrack) then LazyBuffBarDB.myTrack = nil end
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
local function ownEntry(r)
    local id, name = splitRef(r.k)
    return { id = id, byName = name, harm = (r.role == "harm") or nil, mine = true }
end
local function ownOf(role)
    local out = {}
    for _, r in ipairs(refStore() or {}) do
        if r.role == role then out[#out + 1] = ownEntry(r) end
    end
    return out
end
local PROC_MAX = 120
local CURRENT_MAX = 10
function ns.MyProcs.Current()
    local out, seen = {}, {}
    for i = 1, 40 do
        local name, _, icon, _, _, duration, expires, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end
        local short = duration and duration > 0 and duration <= PROC_MAX
        if short and spellId and not seen[spellId] and not ns.MyProcs.Tracked(spellId) then
            seen[spellId] = true
            out[#out + 1] = { id = spellId, name = name, icon = icon, left = expires - GetTime() }
        end
    end
    table.sort(out, function(a, b) return a.left < b.left end)
    for i = #out, CURRENT_MAX + 1, -1 do out[i] = nil end
    return out
end
function ns.TrackSections(all, v)
    local t = specTrack(v)
    local out = {}
    local _, class = UnitClass("player")
    local role = ns.RoleOf(class, v or ns.CurrentVariant())
    local function section(key, kind, entries)
        entries = ns.PickEntries(key, kind, entries, all, role)
        if #entries > 0 then
            out[#out + 1] = { key = key, kind = kind, entries = entries }
        end
    end
    local procs = (t and ns.OnlyLearned(t.procs)) or {}
    local builtin = builtinProcs()
    for _, id in ipairs(ns.MyProcs.List()) do
        if not builtin[id] then procs[#procs + 1] = { id = id, mine = true } end
    end
    for _, role in ipairs({ "proc", "harm" }) do
        for _, e in ipairs(ownOf(role)) do procs[#procs + 1] = e end
    end
    local cds = (t and ns.OnlyLearned(t.cds)) or {}
    for _, e in ipairs(ownOf("cd")) do cds[#cds + 1] = e end
    local dots = (t and ns.OnlyLearned(t.dots)) or {}
    for _, e in ipairs(ownOf("dot")) do dots[#dots + 1] = e end
    section("proc", "aura",   procs)
    section("cd",   "spell",  cds)
    local gear = trinketEntries()
    for _, e in ipairs(racialEntries()) do gear[#gear + 1] = e end
    section("gear", "mixed",  gear)
    section("dot",  "debuff", dots)
    return out
end
local FILTER = { player = "HELPFUL", target = "HARMFUL|PLAYER", harm = "HARMFUL" }
local UNIT_OF = { harm = "player" }
local auras = { player = {}, target = {}, harm = {} }
local lists = { player = {}, target = {}, harm = {} }
local stale = { player = true, target = true, harm = true }
local function rescan(key)
    local set, list = auras[key], lists[key]
    wipe(set)
    wipe(list)
    stale[key] = false
    local unit = UNIT_OF[key] or key
    if not UnitExists(unit) then return end
    local filter = FILTER[key]
    local see = ns.Catalog and ns.Catalog.See
    for i = 1, 40 do
        local n, _, _, count, _, duration, expires, caster, _, _, spellId = UnitAura(unit, i, filter)
        if not n then break end
        local a = { name = n, id = spellId, expires = expires or 0, duration = duration or 0, stacks = count }
        list[#list + 1] = a
        if not set[n] then set[n] = a end
        if see and spellId then see(key, spellId, caster) end
    end
end
local function expired(a)
    return a.expires > 0 and a.expires <= GetTime()
end
local function snapOf(a)
    if not a or expired(a) then return nil end
    local left = (a.expires > 0) and (a.expires - GetTime()) or 0
    local start = (left > 0 and a.duration > 0) and (a.expires - a.duration) or nil
    return { left = left, duration = a.duration, start = start, stacks = a.stacks }
end
local function auraByName(unit, name)
    if not name then return nil end
    if stale[unit] then rescan(unit) end
    return snapOf(auras[unit][name])
end
local SCAN = { help = { "HELPFUL" }, harm = { "HARMFUL" }, mine = { "HARMFUL|PLAYER" }, any = { "HELPFUL", "HARMFUL" },
               ally = { "HELPFUL|PLAYER" } }
local TOT_EVERY = 0.3
local extra = {}
local wanted = {}
local watched = {}
local function watchAs(real, key)
    watched[real] = watched[real] or {}
    watched[real][key] = true
    if real ~= "player" and UnitIsUnit(real, "player") then
        watched.player = watched.player or {}
        watched.player[key] = true
    end
end
local function remap()
    wipe(watched)
    for key, sec in pairs(extra) do
        local real = ns.Units.Resolve(sec.l)
        if real then watchAs(real, key) end
    end
end
local function staleOf(l)
    for _, sec in pairs(extra) do
        if sec.l == l then sec.stale = true end
    end
end
local function rescanExtra(sec, real)
    wipe(sec.set)
    wipe(sec.list)
    sec.stale = false
    sec.real = real
    sec.guid = real and UnitGUID(real) or nil
    if not real then return end
    for _, filter in ipairs(SCAN[sec.f]) do
        for i = 1, 40 do
            local n, _, _, count, _, duration, expires, caster, _, _, spellId = UnitAura(real, i, filter)
            if not n then break end
            local a = { name = n, id = spellId, expires = expires or 0, duration = duration or 0, stacks = count,
                        caster = caster }
            sec.list[#sec.list + 1] = a
            if not sec.set[n] then sec.set[n] = a end
        end
    end
end
local function extraByName(l, f, name)
    local key = l .. "|" .. f
    local sec = extra[key]
    local real = ns.Units.Resolve(l)
    if not sec then
        sec = { l = l, f = f, set = {}, list = {}, stale = true }
        extra[key] = sec
        if real then watchAs(real, key) end
    elseif real ~= sec.real then
        remap()
    end
    if sec.stale or real ~= sec.real or (real and UnitGUID(real) ~= sec.guid) then rescanExtra(sec, real) end
    if not real then return nil, true end
    if not name then return nil, false end
    return snapOf(sec.set[name]), false
end
local poll = CreateFrame("Frame")
poll:Hide()
local pollAcc = 0
poll:SetScript("OnUpdate", function(_, elapsed)
    pollAcc = pollAcc + elapsed
    if pollAcc < TOT_EVERY then return end
    pollAcc = 0
    staleOf("targettarget")
end)
ns.Auras = {}
function ns.Auras.Stale(unit)
    if unit == "player" then stale.harm = true end
    if unit ~= "harm" and stale[unit] ~= nil then stale[unit] = true end
    local w = watched[unit]
    if w then
        for key in pairs(w) do
            local sec = extra[key]
            if sec then sec.stale = true end
        end
    end
end
function ns.Auras.Want(set)
    wipe(wanted)
    for l in pairs(set or {}) do
        if ns.Units.Valid(l) then wanted[l] = true end
    end
    for key, sec in pairs(extra) do
        if not wanted[sec.l] then extra[key] = nil end
    end
    ns.Units.Want(wanted)
    if wanted.targettarget then poll:Show() else poll:Hide() end
    remap()
end
function ns.Auras.Wanted()
    return wanted
end
ns.Units.OnChange(function()
    if next(extra) then remap() end
end)
function ns.Auras.Player(ids, name)
    if not ids and not name then return nil end
    if stale.player then rescan("player") end
    for _, a in ipairs(lists.player) do
        local hit
        if ids and a.id then hit = ids[a.id] elseif ids then hit = ids[a.name] end
        if (hit or (name and a.name == name)) and not expired(a) then return a.expires, a.duration, a.stacks end
    end
    return nil
end
local watch = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_AURA", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_PET", "UNIT_TARGET",
                     "INSTANCE_ENCOUNTER_ENGAGE_UNIT" }) do
    watch:RegisterEvent(e)
end
local MOVED = {
    PLAYER_TARGET_CHANGED = { "target", "targettarget", "boss" },
    PLAYER_FOCUS_CHANGED = { "focus", "boss" },
    UNIT_PET = { "pet" },
    INSTANCE_ENCOUNTER_ENGAGE_UNIT = { "boss" },
}
watch:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        ns.Auras.Stale(unit)
        return
    end
    if event == "PLAYER_TARGET_CHANGED" then ns.Auras.Stale("target") end
    if not next(extra) then return end
    if event == "UNIT_TARGET" then
        if unit == "target" then staleOf("targettarget") end
        return
    end
    if event == "UNIT_PET" and unit ~= "player" then return end
    for _, l in ipairs(MOVED[event]) do staleOf(l) end
    remap()
end)
local reach = {}
local function reachOf(name)
    local now = GetTime()
    local r = reach[name]
    if r and now - r.at < RANGE_EVERY then return r.noMana, r.far end
    r = r or {}
    reach[name] = r
    r.at = now
    r.noMana = select(2, IsUsableSpell(name)) and true or nil
    r.far = (UnitExists("target") and IsSpellInRange(name, "target") == 0) or nil
    return r.noMana, r.far
end
local ACT_EVERY = 0.09
local acts = {}
local causeByName
function ns.ActCause(entry)
    if not entry then return nil end
    local list = ns.actCauses or {}
    if entry.id and list[entry.id] then return list[entry.id] end
    if not causeByName then
        causeByName = {}
        for id, c in pairs(list) do
            local n = GetSpellInfo(id)
            if n then causeByName[n] = c end
        end
    end
    local name = entry.id and GetSpellInfo(entry.id) or entry.byName
    return name and causeByName[name] or nil
end
local function causeOn(c, u)
    if c.kind == "dispel" then
        local foe = UnitCanAttack("player", u) and true or false
        local types = c.types or {}
        local read = foe and UnitBuff or UnitDebuff
        for i = 1, 40 do
            local n, _, _, _, t = read(u, i)
            if not n then return false end
            if t and types[t] then return true end
        end
        return false
    end
    if c.kind == "mana" then
        return UnitPowerType(u) == 0 and (UnitPower(u) or 0) > 0
    end
    local kind = ns.creatureKinds and ns.creatureKinds[UnitCreatureType(u) or ""]
    if c.kind == "undead" then return kind == "undead" end
    return kind == "undead" or kind == "demon"
end
local CHECK_DIRECT = { target = true, focus = true, player = true }
local function actUnit(name, check, l)
    if CHECK_DIRECT[check] then
        if UnitExists(check) then return true, check end
        return false, nil, check
    end
    if check == "unit" then
        l = l or "tank"
        local u = ns.Units.Resolve(l)
        if u then return true, u end
        return false, nil, l
    end
    local harm = IsHarmfulSpell and IsHarmfulSpell(name) and true or false
    local help = IsHelpfulSpell and IsHelpfulSpell(name) and true or false
    local has = UnitExists("target") and true or false
    if harm and not help then
        return has and UnitCanAttack("player", "target") and true or false, "target"
    end
    if help and not harm then
        if has and UnitCanAssist("player", "target") then return true, "target" end
        return true, nil
    end
    return true, has and "target" or nil
end
local function actOf(name, entry, item)
    local check = item and item.check
    local l = check == "unit" and entry.unit or nil
    local c = item and item.cause and ns.ActCause(entry) or nil
    local key = name .. "|" .. (check or "") .. "|" .. (l or "") .. (c and "|c" or "")
    local now = GetTime()
    local r = acts[key]
    if r and now - r.at < ACT_EVERY then return r end
    r = r or {}
    acts[key] = r
    r.at = now
    r.noTarget, r.gone, r.wrong, r.noCause, r.noMana, r.unusable, r.far = nil, nil, nil, nil, nil, nil, nil
    r.cause = c and c.kind or nil
    local ranged = SpellHasRange and SpellHasRange(name) and true or false
    local ok, unit, gone = actUnit(name, check, l)
    if (ranged or check) and not ok then
        r.noTarget, r.gone = true, gone
        return r
    end
    if ranged then
        local inRange = unit and IsSpellInRange(name, unit)
        if unit and inRange == nil then
            r.noTarget, r.wrong = true, true
            return r
        end
        r.far = (inRange == 0) or nil
    end
    if c and not causeOn(c, unit or "player") then
        r.noCause, r.far = true, nil
        return r
    end
    local usable, nomana = IsUsableSpell(name)
    if not usable then
        r.noMana = nomana and true or nil
        r.unusable = (not nomana) or nil
        r.far = nil
    end
    return r
end
function ns.TrackState(kind, entry, item)
    if kind == "mixed" then kind = (entry.slot or entry.item) and "item" or "spell" end
    if kind == "item" then return ns.Trinket.State(entry) end
    local name, _, icon
    if entry.id then name, _, icon = GetSpellInfo(entry.id) else name = entry.byName end
    if kind == "spell" then
        local start, duration = GetSpellCooldown(name or entry.id)
        local onCd = duration and duration > GCD
        local lockName, lockLeft, lockDur
        if ns.Cds and ns.Cds.LockFor then lockName, lockLeft, lockDur = ns.Cds.LockFor(name) end
        local cdLeft = onCd and (start + duration - GetTime()) or 0
        if lockName and (not lockLeft or lockLeft > cdLeft) then
            local now = GetTime()
            return {
                icon = icon, name = name, spell = entry.id, active = false, dim = true,
                start = lockLeft and (now + lockLeft - lockDur) or nil, duration = lockLeft and lockDur or nil, left = lockLeft,
                locked = lockName,
            }
        end
        local up = name and ns.Catalog and ns.Catalog.UpId and ns.Catalog.UpId(entry.id) and auraByName("player", name)
        if up then
            return {
                icon = icon, name = name, spell = entry.id, active = true, up = true,
                start = up.start, duration = up.duration, left = up.left,
            }
        end
        local noMana, far, unusable, noTarget, noCause, act
        if name and not onCd then
            if entry.act then
                act = actOf(name, entry, item)
                noMana, far, unusable, noTarget, noCause = act.noMana, act.far, act.unusable, act.noTarget, act.noCause
            else
                noMana, far = reachOf(name)
            end
        end
        return {
            icon = icon, name = name, spell = entry.id,
            active = not onCd,
            start = start, duration = duration,
            left = onCd and (start + duration - GetTime()) or nil,
            noMana = noMana, far = far, unusable = unusable, noTarget = noTarget, noCause = noCause, act = act,
        }
    end
    local unit = entry.unit
    if entry.ally and not unit then unit = "tank" end
    local a, missing
    if entry.ally then
        a, missing = extraByName(unit, (entry.harm or kind ~= "aura") and "mine" or "ally", name)
    elseif unit and unit ~= ((kind == "aura") and "player" or "target") then
        local f = (kind ~= "aura" and "mine") or (unit == "boss" and "any") or (entry.harm and "harm") or "help"
        a, missing = extraByName(unit, f, name)
    else
        local key = (kind ~= "aura" and "target") or (entry.harm and "harm") or "player"
        a = auraByName(key, name)
        missing = unit ~= nil and not UnitExists(unit)
    end
    return {
        icon = icon, name = name, spell = entry.id,
        active = a ~= nil,
        start = a and a.start, left = a and a.left, duration = a and a.duration, stacks = a and a.stacks,
        unit = unit, noUnit = missing or nil,
    }
end
ns.trackLoaded = true

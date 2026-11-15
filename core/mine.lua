local _, ns = ...
local M = {}
ns.Mine = M
local HARM_MINE, HELP_MINE = "HARMFUL|PLAYER", "HELPFUL|PLAYER"
local MAX_AURAS = 40
local function data()
    return ns.widgetData.mine
end
local sets = {}
function M.Set()
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local key = tostring(class) .. "/" .. tostring(v)
    local s = sets[key]
    if s ~= nil then return s or nil end
    local raw = ns.SpecData(data().sets, class or "", v)
    if not (raw and raw.auras and #raw.auras > 0) then
        sets[key] = false
        return nil
    end
    s = { help = raw.help and true or false, list = {}, byName = {}, off = raw.off or {}, has = {} }
    s.unit = raw.unit or (s.help and "tank" or "target")
    for i, k in ipairs(raw.auras) do
        local a = data().auras[k]
        local name, _, icon = GetSpellInfo(a.id)
        local castId = (a.cast ~= false) and (a.cast or a.id) or nil
        s.list[i] = { key = k, def = a, name = name, icon = icon, castId = castId,
                      cast = castId and (GetSpellInfo(castId)) or nil }
        if name then s.byName[name] = k end
        for _, alt in ipairs(a.alt or {}) do
            local an = GetSpellInfo(alt)
            if an and not s.byName[an] then s.byName[an] = k end
        end
        s.has[k] = true
    end
    sets[key] = s
    return s
end
function M.Rows()
    local s = M.Set()
    if not s then return 1 end
    return math.max(1, math.min(#s.list, data().rows))
end
local function learned(info)
    local learn = info.def.learn
    if learn == false then return true end
    if type(learn) == "table" then
        for _, id in ipairs(learn) do
            if ns.IsLearned(id) then return true end
        end
        return false
    end
    return ns.IsLearned(learn or info.castId or info.def.id)
end
function M.Shown(info, set, opt)
    local v = opt and opt["a_" .. info.key]
    local on
    if v == "off" then on = false elseif v == "on" then on = true else on = not set.off[info.key] end
    return on and learned(info)
end
function M.Avail()
    local s = M.Set()
    if not s then return false end
    for _, info in ipairs(s.list) do
        if learned(info) then return true end
    end
    return false
end
function M.CastTime(id)
    if not id then return 0 end
    local _, _, _, _, _, _, ms = GetSpellInfo(id)
    return (tonumber(ms) or 0) / 1000
end
function M.Window(info)
    local a = info.def
    if a.calm and ns.IsTalent(a.calm) and ns.IsLearned(a.calm) then return 0 end
    if a.soon then return a.soon end
    return math.max(M.CastTime(info.castId), a.tick or 0)
end
function M.ClickUnit(l)
    if l == "target" or l == "focus" then return l end
    return ns.Units.Resolve(l)
end
function M.Unit(set, l)
    local u = ns.Units.Resolve(l)
    if not u or UnitIsDeadOrGhost(u) then return nil end
    local hostile = UnitCanAttack("player", u) and true or false
    if hostile == set.help then return nil end
    return u
end
local cache = {}
local cached = 0
local stamp = 0
local cacheSet
local peak = {}
local liveAt = nil
local LIVE_FOR = 3
local function alive()
    return liveAt ~= nil and GetTime() - liveAt <= LIVE_FOR
end
local static = {}
for _, u in ipairs(data().tokens) do static[u] = true end
local tanks = {}
local function onTanks()
    wipe(tanks)
    for _, l in ipairs({ "tank", "tank2" }) do
        local u = ns.Units.Resolve(l)
        if u then tanks[#tanks + 1] = u end
    end
end
local function drop(guid)
    if cache[guid] then
        cache[guid] = nil
        cached = cached - 1
    end
end
local function newMark(guid)
    if cached >= data().cache then
        local old, at
        for g, e in pairs(cache) do
            if not at or e.at < at then old, at = g, e.at end
        end
        if old then drop(old) end
    end
    local e = { guid = guid, at = GetTime(), auras = {} }
    cache[guid] = e
    cached = cached + 1
    return e
end
local function syncSet(set)
    if cacheSet == set then return end
    cacheSet = set
    wipe(cache)
    wipe(peak)
    cached = 0
end
function M.Scan(token, set)
    local guid = UnitGUID(token)
    if not guid then return false end
    syncSet(set)
    stamp = stamp + 1
    local e = cache[guid]
    local changed = false
    local filter = set.help and HELP_MINE or HARM_MINE
    for i = 1, MAX_AURAS do
        local name, _, _, count, _, dur, exp = UnitAura(token, i, filter)
        if not name then break end
        local k = set.byName[name]
        if k then
            if not e then
                e = newMark(guid)
                changed = true
            end
            local r = e.auras[k]
            if not r then
                r = {}
                e.auras[k] = r
                changed = true
            end
            count, dur, exp = count or 0, dur or 0, exp or 0
            if count > (peak[k] or 0) then peak[k] = count end
            if r.exp ~= exp or r.count ~= count or r.dur ~= dur then
                r.exp, r.count, r.dur = exp, count, dur
                changed = true
            end
            r.stamp = stamp
        end
    end
    if e then
        e.name = UnitName(token) or e.name
        e.at = GetTime()
        for k, r in pairs(e.auras) do
            if r.stamp ~= stamp then
                e.auras[k] = nil
                changed = true
            end
        end
        if next(e.auras) == nil then drop(guid) end
    end
    return changed
end
local function prune(now)
    for guid, e in pairs(cache) do
        for k, r in pairs(e.auras) do
            if r.exp > 0 and r.exp <= now then e.auras[k] = nil end
        end
        if next(e.auras) == nil then drop(guid) end
    end
end
function M.Cached()
    return cached
end
function M.Reset()
    wipe(cache)
    wipe(peak)
    cached = 0
    cacheSet = nil
end
local function findAny(token, name, filter, foreign)
    if not name then return nil end
    for i = 1, MAX_AURAS do
        local n, _, _, _, _, _, exp, caster = UnitAura(token, i, filter)
        if not n then return nil end
        if n == name and not (foreign and caster == "player") then
            local left = (exp and exp > 0) and (exp - GetTime()) or 0
            return left, caster
        end
    end
    return nil
end
local function verdictOf(info, rec, now, win)
    if not rec then return "none", nil end
    local left = rec.exp > 0 and (rec.exp - now) or nil
    if left and left <= 0 then return "none", nil end
    if left and left <= win then return "soon", left end
    local low = info.def.low
    if low and rec.count > 0 and rec.count <= low then return "soon", left end
    return "ok", left
end
local RANK = { none = 1, bad = 2, soon = 3, ok = 4, off = 5 }
local function pickTop(st)
    local best, bk, bl
    for i, c in ipairs(st.auras) do
        local k = RANK[c.verdict] + (c.info.cast and 0 or 0.5)
        local l = c.left or 0
        if not best or k < bk or (k == bk and l < bl) then best, bk, bl = i, k, l end
        if c.verdict == "ok" or c.verdict == "soon" then st.up = st.up + 1 end
    end
    st.top = best
    local c = best and st.auras[best]
    if not (c and st.unit) then
        st.verdict = "off"
    elseif c.verdict == "ok" then
        st.verdict = "full"
    else
        st.verdict = c.verdict
    end
end
local vis = {}
local function refreshVisible(token)
    wipe(vis)
    for _, u in ipairs(data().tokens) do
        local g = UnitGUID(u)
        if g and not vis[g] then vis[g] = u end
    end
    for _, u in ipairs(tanks) do
        local g = UnitGUID(u)
        if g and not vis[g] then vis[g] = u end
    end
    if token then
        local g = UnitGUID(token)
        if g then vis[g] = token end
    end
end
local function rowBefore(a, b)
    if a.cur ~= b.cur then return a.cur end
    local la, lb = a.left or math.huge, b.left or math.huge
    if la ~= lb then return la < lb end
    return a.guid < b.guid
end
local function rowsOf(st, now)
    local list = {}
    local wguid = st.unit and UnitGUID(st.unit)
    for guid, e in pairs(cache) do
        local r = { guid = guid, name = e.name, cur = guid == wguid, seen = vis[guid] ~= nil, marks = {} }
        local any = false
        for i, c in ipairs(st.auras) do
            local v, left = verdictOf(c.info, e.auras[c.key], now, c.window)
            r.marks[i] = v
            if v ~= "none" then any = true end
            if left and (not r.left or left < r.left) then r.left = left end
        end
        if any or r.cur then list[#list + 1] = r end
    end
    if wguid and not cache[wguid] and #st.auras > 0 then
        local r = { guid = wguid, name = st.who, cur = true, seen = true, marks = {} }
        for i = 1, #st.auras do r.marks[i] = "none" end
        list[#list + 1] = r
    end
    table.sort(list, rowBefore)
    for i = #list, data().targets.rows + 1, -1 do list[i] = nil end
    st.rows = list
end
function M.Units(opt)
    local set = M.Set()
    local l = (opt and opt.unit) or (set and set.unit)
    if l == "tank" or l == "tank2" then return { l } end
    return nil
end
function M.State(opt)
    opt = opt or {}
    liveAt = GetTime()
    local st = { auras = {}, rows = {}, up = 0, verdict = "off", help = false }
    local set = M.Set()
    if not set then return st end
    syncSet(set)
    st.help = set.help
    st.l = opt.unit or set.unit
    if st.l == "tank" or st.l == "tank2" then onTanks() end
    st.token = M.ClickUnit(st.l)
    local u = M.Unit(set, st.l)
    st.unit = u
    st.who = u and UnitName(u) or nil
    local now = GetTime()
    prune(now)
    if u then M.Scan(u, set) end
    local e = u and cache[UnitGUID(u) or ""]
    for _, info in ipairs(set.list) do
        if M.Shown(info, set, opt) then
            local max = info.def.max and math.max(info.def.max, peak[info.key] or 0) or nil
            local c = { key = info.key, info = info, max = max, window = M.Window(info), count = 0 }
            if u then
                local rec = e and e.auras[info.key]
                c.verdict, c.left = verdictOf(info, rec, now, c.window)
                if rec then c.dur, c.count = rec.dur, rec.count end
                if c.verdict == "none" and info.def.block then
                    local bn = GetSpellInfo(info.def.block)
                    local left = findAny(u, bn, "HARMFUL", false)
                    if left then c.verdict, c.block, c.blockLeft = "off", bn, left end
                end
                if c.verdict == "none" and info.def.unique then
                    local left, caster = findAny(u, info.name, set.help and "HELPFUL" or "HARMFUL", true)
                    if left then
                        c.verdict, c.left = "bad", (left > 0) and left or nil
                        c.by = caster and UnitName(caster) or nil
                    end
                end
            else
                c.verdict = "off"
            end
            st.auras[#st.auras + 1] = c
        end
    end
    pickTop(st)
    refreshVisible(u)
    rowsOf(st, now)
    return st
end
function M.Active(st, view)
    if view == "targets" then return #st.rows > 0 end
    return st.unit ~= nil and #st.auras > 0
end
function M.Attrs(st, i)
    local c = st and st.auras[i]
    if not (c and c.info.cast and st.token) then return {} end
    return { type = "spell", spell = c.info.cast, unit = st.token }
end
local function watched(unit)
    if not unit then return false end
    if static[unit] then return true end
    for _, u in ipairs(tanks) do
        if u == unit then return true end
    end
    return false
end
ns.Units.OnChange(function()
    onTanks()
    if alive() then ns.Widget.Poke("mine") end
end)
local f = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_AURA", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UPDATE_MOUSEOVER_UNIT",
                     "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "PLAYER_ENTERING_WORLD" }) do
    f:RegisterEvent(e)
end
f:SetScript("OnEvent", function(_, event, unit)
    if not alive() then return end
    local set = M.Set()
    if not set then return end
    local changed = false
    if event == "UNIT_AURA" then
        if not watched(unit) then return end
        changed = M.Scan(unit, set)
    elseif event == "PLAYER_TARGET_CHANGED" then
        changed = M.Scan("target", set)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        changed = M.Scan("focus", set)
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        changed = M.Scan("mouseover", set)
    else
        onTanks()
        for i = 1, 4 do
            if M.Scan("boss" .. i, set) then changed = true end
        end
    end
    if changed then ns.Widget.Poke("mine") end
end)
ns.mineLoaded = true

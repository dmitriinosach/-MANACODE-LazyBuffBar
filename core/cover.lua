local _, ns = ...
local C = {}
ns.Cover = C
local NOBODY = {}
local function hollow()
    local function nop() end
    local function no() return false end
    return {
        OnChange = nop, Watch = nop, Range = nop, Touch = nop, Scope = nop,
        Roster = function() return NOBODY end,
        InRaid = no, Awake = no, End = no,
        Version = function() return 0 end,
        Count = function()
            return { n = 0, can = 0, total = 0, missN = 0, lowN = 0, goneN = 0, miss = {}, low = {}, gone = {}, verdict = "off" }
        end,
    }
end
local R = ns.Raid or hollow()
local infos = {}
local tracks = {}
local subscribed
local OWN = { "cover", "raidbuffs" }
local function data()
    return ns.widgetData.cover
end
function C.Buffs()
    local _, class = UnitClass("player")
    class = class or ""
    local list = infos[class]
    if list then return list end
    list = {}
    for i, e in ipairs(data().classes[class] or {}) do
        local b = { key = e.key, group = e.group, single = e.single, reagent = e.reagent, need = e.need, list = {},
            watch = e.watch ~= false }
        local seen = {}
        for _, id in ipairs({ e.group, e.single }) do
            local n, _, icon = GetSpellInfo(id)
            if n and not seen[n] then
                seen[n] = true
                b.list[#b.list + 1] = n
            end
            if id == e.group then b.gname, b.icon = n, icon end
            if id == e.single then
                b.sname = n
                b.icon = b.icon or icon
            end
        end
        for _, id in ipairs(e.alt or {}) do
            local n = GetSpellInfo(id)
            if n and not seen[n] then
                seen[n] = true
                b.list[#b.list + 1] = n
            end
        end
        list[i] = b
    end
    infos[class] = list
    return list
end
function C.Get(key)
    for _, b in ipairs(C.Buffs()) do
        if b.key == key then return b end
    end
    return nil
end
function C.Known(b)
    return (b.group and ns.IsLearned(b.group)) and true or false, ns.IsLearned(b.single) and true or false
end
function C.Avail()
    for _, b in ipairs(C.Buffs()) do
        local g, s = C.Known(b)
        if g or s then return true end
    end
    return false
end
local function probe()
    local b = C.Buffs()[1]
    return b and (b.sname or b.gname) or nil
end
R.OnChange(function()
    if not ns.Widget then return end
    for _, o in ipairs(OWN) do ns.Widget.Poke(o) end
    for owner, t in pairs(tracks) do
        ns.Widget.Poke(owner)
        for _, o in ipairs(t.also or {}) do ns.Widget.Poke(o) end
    end
end)
function C.Touch()
    local _, class = UnitClass("player")
    class = class or ""
    if subscribed ~= class then
        subscribed = class
        local names, seen = {}, {}
        for _, b in ipairs(C.Buffs()) do
            for _, n in ipairs(b.list) do
                if not seen[n] then
                    seen[n] = true
                    names[#names + 1] = n
                end
            end
        end
        R.Watch("cover", names)
        R.Range("cover", probe())
    end
    R.Touch()
end
function C.Roster()
    return R.Roster()
end
function C.InRaid()
    return R.InRaid()
end
function C.Version()
    return R.Version()
end
function C.Awake()
    return R.Awake()
end
function C.Far(m)
    return (m.dead or m.out.cover) and true or false
end
local function counted(m, need)
    return m.seen and not m.off and (not need or need[m.class]) and true or false
end
local function reach(m)
    return not m.dead and not m.out.cover
end
function C.HasReagent(b)
    local r = b.reagent
    if not r then return true end
    if type(r) ~= "table" then r = { r } end
    for _, id in ipairs(r) do
        if (GetItemCount(id) or 0) > 0 then return true end
    end
    return false
end
function C.Reagents(b)
    local r = b.reagent
    local out, sum = {}, 0
    if not r then return out, sum end
    if type(r) ~= "table" then r = { r } end
    for i, id in ipairs(r) do
        local n = GetItemCount(id) or 0
        out[i] = { id = id, n = n }
        sum = sum + n
    end
    return out, sum
end
function C.Watched(b, opt)
    local v = opt and opt["w_" .. b.key]
    if v == nil then return b.watch end
    return v and true or false
end
local function pickNext(s, b, opt, need, soon, now)
    local gk, sk = C.Known(b)
    local wantMiss = s.missN > s.farN
    local best, bestSub, bestN, bestLeft
    local subs = {}
    for _, m in ipairs(R.Roster()) do
        if counted(m, need) and reach(m) then
            local e = R.End(m, b.list)
            local missing = not e or (e > 0 and e <= now)
            local low = not missing and e > 0 and (e - now) < soon
            if (wantMiss and missing) or (not wantMiss and low) then
                subs[m.sub] = (subs[m.sub] or 0) + 1
                if not wantMiss and (not bestLeft or e - now < bestLeft) then best, bestLeft = m, e - now end
                if wantMiss and not best then best = m end
            end
        end
    end
    if not best then return end
    local canGroup = gk and C.HasReagent(b)
    local mode = opt.cast
    if canGroup and R.InRaid() and mode ~= "single" then
        for sub, k in pairs(subs) do
            if not bestN or k > bestN or (k == bestN and sub < bestSub) then bestSub, bestN = sub, k end
        end
        for _, m in ipairs(R.Roster()) do
            local e = R.End(m, b.list)
            local missing = not e or (e > 0 and e <= now)
            if m.sub == bestSub and counted(m, need) and reach(m) and (missing or not wantMiss) then
                best = m
                break
            end
        end
    else
        bestN = 0
        for _, k in pairs(subs) do bestN = bestN + k end
    end
    local group
    if mode == "single" then group = false
    elseif mode == "group" then group = canGroup
    else group = canGroup and (bestN >= data().group or not sk) end
    if not group and not sk then return end
    s.next, s.group = best, group and true or false
    s.spell = group and b.gname or b.sname
end
function C.Summary(b, opt, now)
    opt = opt or {}
    now = now or GetTime()
    local d = data()
    local need = b.need and d.needs[b.need] or nil
    local soon = opt.soon or d.soon
    local gk, sk = C.Known(b)
    local s = { key = b.key, icon = b.icon, n = 0, total = 0, missN = 0, farN = 0, can = 0, lowN = 0, list = {}, gone = {},
        low = {}, group = false, single = sk and b.sname or nil, known = (gk or sk) and true or false }
    if not (gk or sk) then
        s.verdict = "off"
        return s
    end
    local lines = opt.lines or d.lines
    for _, m in ipairs(R.Roster()) do
        if counted(m, need) then
            s.total = s.total + 1
            local e = R.End(m, b.list)
            local has = e and (e == 0 or e > now)
            if m.click == "player" then s.me = has and (e > 0 and e - now or 0) or false end
            if has then
                s.n = s.n + 1
                if e > 0 then
                    if not s.min or e - now < s.min then s.min, s.minWho = e - now, m end
                    if e - now < soon then
                        s.lowN = s.lowN + 1
                        if #s.low < lines then s.low[#s.low + 1] = m end
                    end
                end
            else
                s.missN = s.missN + 1
                if reach(m) then
                    if #s.list < lines then s.list[#s.list + 1] = m end
                else
                    s.farN = s.farN + 1
                    s.farWho = s.farWho or m
                    if #s.gone < lines then s.gone[#s.gone + 1] = m end
                end
            end
        end
    end
    s.can = s.missN - s.farN
    for _, m in ipairs(s.gone) do
        if #s.list < lines then s.list[#s.list + 1] = m end
    end
    if s.total == 0 then s.verdict = "off"
    elseif s.missN > 0 then s.verdict = "none"
    elseif s.min and s.min < soon then s.verdict = "soon"
    else s.verdict = "ok" end
    if s.verdict == "none" or s.verdict == "soon" then pickNext(s, b, opt, need, soon, now) end
    return s
end
local RANK = { none = 1, soon = 2, ok = 3, off = 4 }
local function worse(a, b)
    if RANK[a.verdict] ~= RANK[b.verdict] then return RANK[a.verdict] < RANK[b.verdict] end
    if a.verdict == "none" then return a.missN > b.missN end
    if a.verdict == "soon" then return (a.min or 0) < (b.min or 0) end
    return false
end
function C.State(opt)
    opt = opt or {}
    C.Touch()
    local now = GetTime()
    local st = { buffs = {}, pick = 1, worst = 1, need = false, pickNeed = false, fixed = false, raid = R.InRaid() }
    local list = C.Buffs()
    local any = false
    for _, b in ipairs(list) do
        if C.Watched(b, opt) then any = true end
    end
    local first
    for i, b in ipairs(list) do
        local s = C.Summary(b, opt, now)
        st.buffs[i] = s
        if not any or C.Watched(b, opt) then
            if s.verdict == "none" or s.verdict == "soon" then st.need = true end
            if not first then first, st.worst = i, i elseif worse(s, st.buffs[st.worst]) then st.worst = i end
        end
        if b.key == opt.buff then st.pick = i end
    end
    st.fixed = (opt.buff and C.Get(opt.buff)) and true or false
    if not st.fixed then st.pick = st.worst end
    local p = st.buffs[st.pick]
    st.pickNeed = p ~= nil and (p.verdict == "none" or p.verdict == "soon")
    return st
end
function C.Active(st, opt)
    if opt and opt.when == "need" then
        if opt.buff and C.Get(opt.buff) then return st.pickNeed end
        return st.need
    end
    return true
end
function C.Track(owner, list, range, also)
    local t = tracks[owner]
    if t and t.list == list and t.range == range then return end
    local by, names = {}, {}
    for _, e in ipairs(list) do
        by[e.key] = e.names
        for _, n in ipairs(e.names) do names[#names + 1] = n end
    end
    tracks[owner] = { list = list, range = range, also = also, by = by }
    local spell
    for _, tr in pairs(tracks) do spell = spell or tr.range end
    R.Watch("track:" .. owner, names)
    R.Range("track", spell)
end
function C.Scope()
    return R.Scope()
end
function C.TrackSummary(owner, key, skip, soon, scope, lines, now)
    local t = tracks[owner]
    return R.Count(t and t.by[key] or {}, "track", skip, soon, scope, lines, now)
end
ns.coverLoaded = true

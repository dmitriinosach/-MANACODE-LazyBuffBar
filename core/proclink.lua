local _, ns = ...
ns.ProcLink = {}
local L = ns.ProcLink
local byId
local byName
local sets = {}
local function add(t, k, row)
    local list = t[k]
    if not list then
        list = {}
        t[k] = list
    end
    for _, r in ipairs(list) do
        if r == row then return end
    end
    list[#list + 1] = row
end
local function index()
    byId, byName = {}, {}
    for _, rows in pairs(ns.procLinks or {}) do
        for _, row in ipairs(rows) do
            local set = {}
            for _, id in ipairs(row.procs) do
                set[id] = true
                local n = GetSpellInfo(id)
                if n then set[n] = true end
            end
            sets[row] = set
            for _, id in ipairs(row.spells) do
                add(byId, id, row)
                local n = GetSpellInfo(id)
                if n then add(byName, n, row) end
            end
        end
    end
end
function L.Of(entry)
    if not entry or not entry.id then return nil end
    local c = entry._plink
    if c ~= nil then return c or nil end
    if not byId then index() end
    local rows = byId[entry.id]
    if not rows then
        local n = GetSpellInfo(entry.id)
        rows = n and byName[n] or nil
    end
    entry._plink = rows or false
    return rows
end
function L.State(rows)
    local lit, stacks = false, nil
    for _, row in ipairs(rows) do
        local exp, _, n = ns.Auras.Player(sets[row])
        if exp then
            n = (n and n > 0) and n or 1
            local need = row.need or 1
            local ok = n >= need
            if ok then lit = true end
            if (need > 1 or n > 1) and (stacks == nil or ok) then stacks = n end
        end
    end
    return lit, stacks
end
function L.Count(class)
    local rows = ns.procLinks and ns.procLinks[class or ""]
    return rows and #rows or 0
end
ns.procLinkLoaded = true

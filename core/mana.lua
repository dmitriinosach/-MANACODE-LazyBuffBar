local _, ns = ...
local M = {}
ns.Mana = M
local function data()
    return ns.widgetData.mana
end
local ts = {}
local vs = {}
local listening = false
local MANA = 0
local MERGE = 0.25
local fr = CreateFrame("Frame")
local function push()
    local now = GetTime()
    local v = UnitPower("player", MANA) or 0
    local n = #ts
    if n > 0 and now - ts[n] < MERGE then
        vs[n] = v
        return
    end
    ts[n + 1], vs[n + 1] = now, v
    local edge = now - data().window
    while #ts > 2 and ts[2] <= edge do
        table.remove(ts, 1)
        table.remove(vs, 1)
    end
end
fr:SetScript("OnEvent", function(_, _, unit)
    if unit == "player" then push() end
end)
function M.Start()
    if listening then return end
    listening = true
    fr:RegisterEvent("UNIT_MANA")
    fr:RegisterEvent("UNIT_MAXMANA")
    push()
end
function M.Left(now)
    now = now or GetTime()
    local n = #ts
    if n == 0 then return nil end
    local d = data()
    local edge = now - d.window
    local base = 1
    for i = 1, n do
        if ts[i] <= edge then base = i end
    end
    local span = now - ts[base]
    if span > d.window then span = d.window end
    if span < d.minSpan then return nil end
    local cur = UnitPower("player", MANA) or 0
    local rate = (vs[base] - cur) / span
    if rate <= 0 then return nil end
    return cur / rate
end
function M.Reset()
    ts, vs = {}, {}
end
function M.Sources()
    local _, class = UnitClass("player")
    local out = {}
    for _, s in ipairs(data().classes[class or ""] or {}) do out[#out + 1] = s end
    out[#out + 1] = data().potion
    return out
end
function M.Avail()
    local _, class = UnitClass("player")
    return data().classes[class or ""] ~= nil
end
local function known(s)
    if not s.id then return true end
    if ns.IsLearned(s.id) then return true end
    for _, id in ipairs(s.alt or {}) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function cellOf(s)
    local d = data()
    local c = { key = s.key, known = known(s), self = s.self, cd = 0, nomana = false }
    if not c.known then
        c.verdict = "hide"
        return c
    end
    if s.id then
        local name, _, icon = GetSpellInfo(s.id)
        c.name, c.icon = name, icon
        if name then
            c.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(name))
            local usable, nomana = IsUsableSpell(name)
            c.nomana = (not usable and nomana) and true or false
        end
        c.verdict = c.cd > 0 and "off" or "ok"
        return c
    end
    local pick, count = nil, 0
    for _, id in ipairs(s.items) do
        local n = GetItemCount(id) or 0
        if n > 0 then
            pick, count = id, n
            break
        end
    end
    c.item, c.count = pick, count
    c.icon = GetItemIcon(pick or s.items[1])
    if pick then c.cd = ns.WTile.Left(d.gcd, GetItemCooldown(pick)) end
    if not pick then c.verdict = "none" elseif c.cd > 0 then c.verdict = "off" else c.verdict = "ok" end
    return c
end
function M.State()
    M.Start()
    local d = data()
    local cur, max = UnitPower("player", MANA) or 0, UnitPowerMax("player", MANA) or 0
    local st = { cur = cur, max = max, pct = max > 0 and cur / max or 0, cells = {} }
    st.left = M.Left()
    for i, s in ipairs(M.Sources()) do st.cells[i] = cellOf(s) end
    if st.pct < d.crit then st.verdict = "bad" elseif st.pct < d.low then st.verdict = "soon" else st.verdict = "ok" end
    return st
end
function M.Click(c)
    if not (c and c.known) then return {} end
    if c.name then
        if c.self then return { type = "spell", spell = c.name, unit = "player" } end
        return { type = "spell", spell = c.name }
    end
    if c.item then return { type = "item", item = "item:" .. c.item } end
    return {}
end
ns.manaLoaded = true

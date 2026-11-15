local _, ns = ...
ns.Library = {}
local L = ns.Library
local G = ns.Grid
local STRIP = { key = true, point = true, off = true, name = true }
local PREFIX = { account = "l", char = "c" }
local FACTORY = "f:"
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
local function home(scope)
    if scope == "char" then return ns.Profile.Char() end
    return ns.Profile.Root()
end
local function store(scope)
    local h = home(scope)
    h.library = h.library or {}
    for _, rec in ipairs(h.library) do rec.at = nil end
    return h.library
end
local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$")
end
local function strip(b)
    local out = {}
    for k, v in pairs(b) do
        if not STRIP[k] then out[k] = copy(v) end
    end
    out.items = out.items or {}
    out.cols = out.cols or 1
    out.rows = out.rows or 1
    return out
end
function L.NextId(scope)
    local h = home(scope)
    local pre = PREFIX[scope] or "l"
    local n = math.floor(tonumber(h.nextLib) or 1)
    if n < 1 then n = 1 end
    local taken = {}
    for _, rec in ipairs(store(scope)) do taken[rec.id] = true end
    while taken[pre .. n] do n = n + 1 end
    h.nextLib = n + 1
    return pre .. n
end
local function scopeOf(id)
    local pre = tostring(id or ""):sub(1, 1)
    for scope, p in pairs(PREFIX) do
        if p == pre then return scope end
    end
    return nil
end
local function recordOf(id)
    local scope = scopeOf(id)
    if not scope then return nil end
    for i, rec in ipairs(store(scope)) do
        if rec.id == id then return rec, i, scope end
    end
    return nil
end
local function fighting()
    if not InCombatLockdown() then return false end
    ns.say(ns.T("bar.combat"))
    return true
end
function L.Save(key, name, scope)
    if fighting() then return false end
    local b = ns.Preset.Block(key)
    if not b then return false end
    scope = PREFIX[scope] and scope or "char"
    name = trim(name)
    if name == "" then name = ns.Preset.BlockName(b) end
    local live = ns.Preset.Active()
    local st = store(scope)
    local rec = { id = L.NextId(scope), name = name, class = live.class, spec = live.spec, block = strip(b) }
    st[#st + 1] = rec
    return rec.id
end
function L.Rename(id, name)
    name = trim(name)
    local rec = recordOf(id)
    if not rec or name == "" then return false end
    rec.name = name
    return true
end
function L.Delete(id)
    local _, i, scope = recordOf(id)
    if not i then return false end
    tremove(store(scope), i)
    return true
end
local function entryOf(rec, scope)
    return { id = rec.id, name = rec.name, class = rec.class, spec = rec.spec, scope = scope, block = rec.block, factory = false }
end
function L.List()
    local out = {}
    for _, scope in ipairs({ "char", "account" }) do
        for _, rec in ipairs(store(scope)) do out[#out + 1] = entryOf(rec, scope) end
    end
    table.sort(out, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    return out
end
local function factoryBlocks(v)
    return ns.Preset.Expand(ns.PlayerClass() .. "/" .. v).blocks
end
local function factoryEntry(v, b, i)
    return { id = FACTORY .. v .. "/" .. b.key, name = ns.Preset.BlockName(b, i), class = ns.PlayerClass(), spec = v,
             scope = "factory", block = strip(b), factory = true }
end
function L.Factory()
    local out = {}
    local c = ns.specs[ns.PlayerClass()]
    for _, v in ipairs((c and c.order) or {}) do
        for i, b in ipairs(factoryBlocks(v)) do out[#out + 1] = factoryEntry(v, b, i) end
    end
    return out
end
function L.Get(id)
    id = tostring(id or "")
    local rec, _, scope = recordOf(id)
    if rec then return entryOf(rec, scope) end
    local v, key = id:match("^f:([^/]+)/(.+)$")
    local c = ns.specs[ns.PlayerClass()]
    if not (v and c and c.variants[v]) then return nil end
    for i, b in ipairs(factoryBlocks(v)) do
        if b.key == key then return factoryEntry(v, b, i) end
    end
    return nil
end
function L.Put(id, rect)
    local e = L.Get(id)
    if not e then return false end
    if fighting() then return false end
    local b = copy(e.block)
    b.name = e.name
    return ns.Preset.AddBlock(b, rect)
end
function L.Icon(k)
    k = tostring(k or "")
    local id = tonumber(k:match("^spell:(%d+)$"))
    if id then return (select(3, GetSpellInfo(id))) end
    id = tonumber(k:match("^item:(%d+)$"))
    if id then return GetItemIcon and GetItemIcon(id) or nil end
    local slot = tonumber(k:match("^slot:(%d+)$"))
    if slot then return GetInventoryItemTexture("player", slot) end
    local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(k)
    local d = name and ns.Widget.Get(name)
    if d then
        if type(d.icon) == "number" then return (select(3, GetSpellInfo(d.icon))) end
        if type(d.icon) == "string" then return d.icon end
    end
    return nil
end
function L.Icons(block)
    local out = {}
    for _, it in ipairs(block.items or {}) do
        local w, h = G.Size(it)
        out[#out + 1] = { x = it.x or 1, y = it.y or 1, w = w, h = h, tex = L.Icon(it.k) }
    end
    return out
end
function L.Where(e)
    local where = ns.T("library.where", ns.ClassName(e.class), ns.LocalName(ns.SpecInfo(e.class, e.spec)) or tostring(e.spec))
    if e.scope == "account" then return ns.T("library.shared_fmt", where) end
    return where
end
ns.libraryLoaded = true

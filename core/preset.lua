local _, ns = ...
ns.Preset = {}
local P = ns.Preset
local G = ns.Grid
local PLACE = { point = true, scale = true, pad = true, gap = true, alpha = true, idle = true, fight = true,
                plate = true, round = true, plateRound = true, absent = true, digits = true, seps = true, sepLook = true, style = true }
local BLOCK_FIELDS = { name = true, off = true, cond = true }
local ITEM_FIELDS = { show = true, role = true, view = true, opt = true, unit = true, rules = true, style = true, foodIcon = true,
                      procLink = true, check = true, cause = true }
local LIVE_FIELDS = { show = true, view = true, foodIcon = true, procLink = true, check = true, cause = true }
local CAT_OF = { self = "personal", weapon = "personal", food = "food", raid = "raid", want = "want", item = "flask",
                 proc = "proc", harm = "proc", ally = "proc", cd = "cd", gear = "gear", dot = "dot" }
local TARGET_ROLE = { dot = true, harm = true, ally = true }
local KIND_OF = { self = "spell", weapon = "spell", food = "spell", raid = "spell", item = "item", proc = "aura",
                  harm = "aura", ally = "aura", cd = "spell", dot = "debuff", gear = "mixed" }
local live
local liveId
local liveStored = false
local dirty = true
local said = false
local secMap = {}
local secAt
local liveSpec
local edits = 0
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
local function root()
    return ns.Profile.Root()
end
local function char()
    return ns.Profile.Char()
end
local function store()
    local r = root()
    r.presets = r.presets or {}
    return r.presets
end
local function isFactory(id)
    local cls, v = tostring(id):match("^(%u+)/(.+)$")
    local c = cls and ns.specs and ns.specs[cls]
    return (c and c.variants[v]) and true or false
end
local function exists(id)
    if type(id) ~= "string" then return false end
    return isFactory(id) or store()[id] ~= nil
end
local function specOf(group)
    local c = char()
    if not ns.TalentsKnown() and c.lastSpec and c.lastSpec[group] then return c.lastSpec[group] end
    local _, class = UnitClass("player")
    return (class or "?") .. "/" .. tostring(ns.CurrentVariant(group))
end
local function sections(spec)
    local cur = ns.BarProfile()
    spec = spec or cur
    local now = GetTime()
    if secAt ~= now then secMap, secAt = {}, now end
    if secMap[spec] then return secMap[spec] end
    local v = (spec ~= cur) and spec:match("^%u+/(.+)$") or nil
    local m = {}
    for _, s in ipairs(ns.BarSections(true, v)) do m[s.key] = s end
    for _, s in ipairs(ns.TrackSections(true, v)) do m[s.key] = s end
    for _, s in ipairs(ns.IncomingSections(true)) do m[s.key] = s end
    secMap[spec] = m
    return m
end
local function hasRef(items, k)
    for _, it in ipairs(items) do
        if it.k == k then return true end
    end
    return false
end
local function sizeWidget(it)
    local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(it.k)
    local d = name and ns.Widget.Get(name)
    if not d then return it end
    if d.migrate then d.migrate(it) end
    if d.seed then d.seed(it) end
    it.view = ns.Widget.ViewOf(name, it.view)
    local w, h = ns.Widget.Size(name, it.view, it.opt)
    it.w = w > 1 and w or nil
    it.h = h > 1 and h or nil
    return it
end
local function coveredBy(items)
    local out = {}
    for _, it in ipairs(items) do
        local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(it.k)
        local d = name and ns.Widget.Get(name)
        for _, r in ipairs(d and d.covers or {}) do out[r] = true end
    end
    return out
end
local function installWorn(ench, u)
    if not u.preset then return false end
    local link = GetInventoryItemLink("player", u.slot)
    return link ~= nil and ns.Trinket.LinkFields(link)[2] == ench
end
local function installSlots(cls, v)
    local info = cls and ns.SpecInfo(cls, v)
    local role = info and info.role
    local out = {}
    for ench, u in pairs(ns.gearUse or {}) do
        if role and u.preset == role and installWorn(ench, u) then out[#out + 1] = u.slot end
    end
    table.sort(out)
    return out
end
local function installSign()
    local out = {}
    for ench, u in pairs(ns.gearUse or {}) do
        if installWorn(ench, u) then out[#out + 1] = u.slot .. ":" .. ench end
    end
    table.sort(out)
    return table.concat(out, ",")
end
local function factoryGear(k)
    if not k:match("^slot:") then return true end
    local e = ns.Trinket.ForRef(k)
    return (e and e.use) and true or false
end
local REMIND_KEY = "remind"
local REMIND_PLACE = { "point", "scale", "idle", "fight" }
local besideAll
function P.Expand(s)
    s = s or ns.BarProfile()
    local recipe = ns.presetRecipe
    local map = sections(s)
    local cls, v = s:match("^(%u+)/(.+)$")
    local out = { class = cls or "?", spec = v or s, base = s, rev = recipe.rev, blocks = {}, gone = {} }
    local extra = recipe.spec and recipe.spec[s]
    local puts = {}
    for _, put in ipairs((extra and extra.put) or {}) do
        local it = copy(put)
        it.role = it.role or "widget"
        puts[#puts + 1] = sizeWidget(it)
    end
    local covered = coveredBy(puts)
    for _, it in ipairs(puts) do covered[it.k] = true end
    for _, rb in ipairs(recipe.blocks) do
        local items = {}
        for _, it in ipairs(puts) do
            if it.block == rb.key then
                it.block = nil
                items[#items + 1] = it
            end
        end
        for _, g in ipairs(rb.groups) do
            local rest = {}
            if g == "gear" then
                items[#items + 1] = { k = "slot:13", role = "gear", onlyUse = true }
                items[#items + 1] = { k = "slot:14", role = "gear", onlyUse = true }
                for _, slot in ipairs(installSlots(cls, v)) do
                    items[#items + 1] = { k = "slot:" .. slot, role = "gear" }
                end
            end
            if g == "expect" then
                for _, key in ipairs(ns.Incoming.Panel(v)) do
                    rest[#rest + 1] = { k = "want:" .. key, role = "want" }
                end
            else
                ns.Legacy.GroupItems(map, g, rest)
            end
            for _, it in ipairs(rest) do
                if not covered[it.k] and (g ~= "gear" or (not hasRef(items, it.k) and factoryGear(it.k))) then items[#items + 1] = it end
            end
        end
        if not (rb.spare and #items == 0) then
            local b = { key = rb.key, items = items, point = copy(rb.point), scale = rb.scale, idle = rb.idle, fight = rb.fight }
            b.cols, b.rows = G.Pack(items, rb.cols or 0)
            out.blocks[#out.blocks + 1] = b
        end
    end
    besideAll(out.blocks, nil)
    return out
end
local function bind(group, s, id)
    local c = char()
    c.bind = c.bind or {}
    c.bind[group] = { id = id, spec = s }
    c.last = c.last or {}
    c.last[s] = id
    local r = root()
    r.bind = r.bind or {}
    r.bind[s] = id
end
local function bound(group, s)
    local c = char()
    local b = c.bind and c.bind[group]
    if b and b.spec == s and exists(b.id) then return b.id end
    local last = c.last and c.last[s]
    if exists(last) then return last end
    local r = root().bind and root().bind[s]
    if exists(r) then return r end
    return s
end
local function nameOf(rec, id)
    if rec and rec.name then return rec.name end
    local cls, v = tostring(id):match("^(%u+)/(.+)$")
    local base = rec and rec.base
    if not cls and base then cls, v = base:match("^(%u+)/(.+)$") end
    local info = cls and ns.SpecInfo(cls, v)
    return ns.LocalName(info) or tostring(id)
end
local function migrate(s, group)
    if not root().legacyBars then return end
    local c = char()
    c.moved = c.moved or {}
    if c.moved[s] then return end
    local Pr = ns.Profile.Live()
    if not Pr then return end
    c.moved[s] = true
    Pr.moved = Pr.moved or {}
    local id = Pr.moved[s]
    if id and exists(id) then
        bind(group, s, id)
        return
    end
    local content = ns.Legacy.SpecTraces(Pr, s) or ns.Legacy.BarsDiffer(Pr)
    local places = ns.Legacy.HasPlaces(Pr)
    if not content and not places then return end
    local st = store()
    local isDefault = ns.Profile.Current() == ns.Profile.Default()
    local rec = st[s]
    local rev = ns.presetRecipe.rev
    local cls, v = s:match("^(%u+)/(.+)$")
    if content then
        local blocks, gone = ns.Legacy.Build(Pr, s, sections())
        local new = { class = cls, spec = v, base = s, rev = rev, blocks = blocks, gone = gone }
        if isDefault and not (rec and rec.blocks) then
            id = s
            new.places = nil
        else
            id = P.NextId()
            new.name = nameOf(nil, s) .. " — " .. ns.Profile.Label(ns.Profile.Current())
        end
        st[id] = new
    else
        local pl = ns.Legacy.Places(Pr)
        if isDefault and not (rec and rec.blocks) then
            id = s
            rec = rec or { class = cls, spec = v, base = s, rev = rev }
            rec.places = rec.places or {}
            for k, x in pairs(pl) do rec.places[k] = x end
            st[id] = rec
        else
            id = P.NextId()
            st[id] = { class = cls, spec = v, base = s, rev = rev, places = pl,
                       name = nameOf(nil, s) .. " — " .. ns.Profile.Label(ns.Profile.Current()) }
        end
    end
    Pr.moved[s] = id
    bind(group, s, id)
end
local function hasRemind(s)
    local extra = ns.presetRecipe.spec and ns.presetRecipe.spec[s]
    for _, put in ipairs((extra and extra.put) or {}) do
        if put.block == REMIND_KEY then return true end
    end
    return false
end
local function blockIn(rec, key)
    for _, b in ipairs(rec.blocks) do
        if b.key == key then return b end
    end
    return nil
end
local function migrateRemind(s)
    local Pr = ns.Profile.Live()
    local old = Pr and ns.Legacy.Remind(Pr)
    if not old or not hasRemind(s) then return end
    local r = root()
    r.remindMoved = r.remindMoved or {}
    if r.remindMoved[s] then return end
    r.remindMoved[s] = true
    local st = store()
    local rec = st[s]
    local cls, v = s:match("^(%u+)/(.+)$")
    local content = (old.color or old.noLabel or old.off) and true or false
    if not (rec and rec.blocks) then
        rec = rec or { class = cls, spec = v, base = s, rev = ns.presetRecipe.rev }
        rec.places = rec.places or {}
        local pl = rec.places[REMIND_KEY] or {}
        for _, f in ipairs(REMIND_PLACE) do
            if old[f] ~= nil then pl[f] = copy(old[f]) end
        end
        if next(pl) then rec.places[REMIND_KEY] = pl end
        st[s] = rec
        if not content then return end
        local x = P.Expand(s)
        for _, b in ipairs(x.blocks) do
            local p = rec.places[b.key]
            for k, val in pairs(p or {}) do b[k] = copy(val) end
        end
        besideAll(x.blocks, rec.places)
        rec.blocks, rec.gone, rec.places = x.blocks, rec.gone or x.gone, nil
    end
    local b = blockIn(rec, REMIND_KEY)
    if not b then
        if old.off then return end
        b = blockIn(P.Expand(s), REMIND_KEY)
        if not b then return end
        rec.blocks[#rec.blocks + 1] = b
    end
    for _, f in ipairs(REMIND_PLACE) do
        if old[f] ~= nil then b[f] = copy(old[f]) end
    end
    if old.off then b.off = true end
    for _, it in ipairs(b.items) do
        if ns.Widget.NameOf(it.k) == "mode" then
            local opt = copy(it.opt or {})
            if old.color then opt.color = copy(old.color) end
            if old.noLabel then opt.label = nil end
            it.opt = next(opt) and opt or nil
        end
    end
end
function P.NextId()
    local r = root()
    local n = math.floor(tonumber(r.nextPreset) or 1)
    if n < 1 then n = 1 end
    while store()["u" .. n] do n = n + 1 end
    r.nextPreset = n + 1
    return "u" .. n
end
local function newKey(rec)
    local r = root()
    local n = math.floor(tonumber(r.nextBlock) or 1)
    if n < 1 then n = 1 end
    local function taken(key)
        for _, b in ipairs(rec.blocks) do
            if b.key == key then return true end
        end
        return false
    end
    while taken("b" .. n) do n = n + 1 end
    r.nextBlock = n + 1
    return "b" .. n
end
local function rebuild()
    local group = ns.ActiveSlot()
    local s = specOf(group)
    local id = bound(group, s)
    local rec = store()[id]
    local from = (rec and rec.base) or (isFactory(id) and id) or s
    if not isFactory(from) or from:match("^(%u+)/") ~= s:match("^(%u+)/") then from = s end
    liveSpec = from
    if rec and rec.blocks then
        live, liveStored = rec, true
    else
        live = P.Expand(from)
        liveStored = false
        if rec then
            live.name = rec.name
            live.base = rec.base or id
            for _, b in ipairs(live.blocks) do
                local pl = rec.places and rec.places[b.key]
                if pl then
                    for k, x in pairs(pl) do b[k] = copy(x) end
                end
            end
            besideAll(live.blocks, rec.places)
        end
    end
    liveId = id
    dirty = false
end
local synced = false
local function stripPics(items)
    for _, it in ipairs(items or {}) do it.tex = nil end
end
local function dropPics()
    local r = root()
    if r.picsDropped then return end
    r.picsDropped = true
    for _, rec in pairs(r.presets or {}) do
        for _, b in ipairs(type(rec) == "table" and rec.blocks or {}) do stripPics(b.items) end
    end
    for _, e in ipairs(type(r.library) == "table" and r.library or {}) do
        stripPics(type(e) == "table" and e.block and e.block.items or nil)
    end
end
local VIEWS_REV = 6
local BLESS_GONE = { ["widget:blessings"] = true, ["widget:blessings_icons"] = true }
local BLESS_WATCH = { "kings", "might", "wisdom" }
local function blessButtons(items, it, cls)
    local out = {}
    if cls ~= "PALADIN" or not (it.x and it.y) then return out end
    local watch = type(it.opt) == "table" and type(it.opt.watch) == "table" and it.opt.watch or BLESS_WATCH
    local want = {}
    for _, k in ipairs(watch) do want[k] = true end
    local w, h = G.Size(it)
    for _, b in ipairs(ns.BLESSINGS) do
        local k = "spell:" .. b.great
        if want[b.key] and not hasRef(items, k) and #out < w * h then
            local n = #out
            out[n + 1] = { k = k, role = "raid", x = it.x + n % w, y = it.y + math.floor(n / w) }
        end
    end
    return out
end
local THREAT_GONE = {
    ["widget:rogue_threat"] = function(o)
        local at = tonumber(o.warn)
        return { at = (at and at ~= 80) and at or nil, show = o.when ~= "high" and "always" or nil, spell = o.spell }
    end,
    ["widget:warlock_threat"] = function(o)
        return { at = o.at, show = o.show, unit = o.unit }
    end,
}
local function threatMoved(it)
    local opt = THREAT_GONE[it.k](type(it.opt) == "table" and it.opt or {})
    it.k = "widget:threat"
    it.opt = next(opt) and opt or nil
    if it.view == "wide" then it.view = "bar" end
    sizeWidget(it)
end
local function moveItems(items, cls)
    if type(items) ~= "table" then return end
    local i = 1
    while i <= #items do
        local it = items[i]
        if type(it) == "table" and THREAT_GONE[it.k] then threatMoved(it) end
        if type(it) == "table" and BLESS_GONE[it.k] then
            table.remove(items, i)
            local new = blessButtons(items, it, cls)
            for j, b in ipairs(new) do table.insert(items, i + j - 1, b) end
            i = i + #new
        else
            i = i + 1
        end
    end
    for _, it in ipairs(items) do
        local name = ns.Widget.NameOf(it.k)
        local d = name and ns.Widget.Get(name)
        if d and d.migrate and d.migrate(it) then sizeWidget(it) end
    end
end
local function moveBlock(block, cls)
    if type(block) ~= "table" then return end
    moveItems(block.items, cls)
    if cls ~= "WARLOCK" then return end
    local expanded, ordered, old = {}, {}, {}
    for _, it in ipairs(block.items or {}) do
        ordered[#ordered + 1] = it
        old[it] = { it.x, it.y }
        if it.k == "widget:mode" and it.view == "row" and (it.w or 1) == 2 then
            it.w = 3
            expanded[#expanded + 1] = it
        end
    end
    if #expanded == 0 then return end
    table.sort(ordered, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    local cols, rows = G.Pack(ordered, math.max(3, block.cols or 1))
    if rows <= G.MAX_ROWS then
        block.cols, block.rows = cols, rows
        return
    end
    for _, it in ipairs(ordered) do it.x, it.y = old[it][1], old[it][2] end
    for _, it in ipairs(expanded) do it.view, it.w, it.h = "one", nil, nil end
end
local function moveLibrary(list)
    for _, e in ipairs(type(list) == "table" and list or {}) do
        if type(e) == "table" then moveBlock(e.block, e.class) end
    end
end
local function moveViews()
    local r, c = root(), char()
    if (tonumber(r.viewsMoved) or 0) < VIEWS_REV then
        r.viewsMoved = VIEWS_REV
        for _, rec in pairs(r.presets or {}) do
            for _, b in ipairs(type(rec) == "table" and rec.blocks or {}) do moveBlock(b, rec.class) end
        end
        moveLibrary(r.library)
    end
    if (tonumber(c.viewsMoved) or 0) < VIEWS_REV then
        c.viewsMoved = VIEWS_REV
        moveLibrary(c.library)
    end
end
local function syncNow()
    dropPics()
    moveViews()
    local group = ns.ActiveSlot()
    if not ns.TalentsKnown() then return end
    local s = specOf(group)
    local c = char()
    c.lastSpec = c.lastSpec or {}
    c.lastSpec[group] = s
    migrate(s, group)
    migrateRemind(s)
    local b = c.bind and c.bind[group]
    if not (b and b.spec == s and exists(b.id)) then bind(group, s, bound(group, s)) end
    synced = true
end
local function ensure()
    if live and not dirty then return end
    if not synced and ns.Profile.Loaded() and not InCombatLockdown() then syncNow() end
    rebuild()
end
local function invalidate()
    dirty = true
    secAt = nil
end
function P.Invalidate(full)
    invalidate()
    if full then live = nil end
end
function P.Active()
    ensure()
    return live
end
function P.Id()
    ensure()
    return liveId
end
function P.Edits()
    return edits
end
local function stateOf(id)
    if isFactory(id) then
        local rec = store()[id]
        return (rec and rec.blocks) and "edited" or "factory"
    end
    return "own"
end
function P.State()
    ensure()
    return stateOf(liveId)
end
function P.Blocks()
    ensure()
    return live.blocks
end
function P.Block(key)
    for _, b in ipairs(P.Blocks()) do
        if b.key == key then return b end
    end
    return nil
end
function P.ItemAt(key, x, y)
    local b = P.Block(key)
    return b and G.ItemAt(b, x, y) or nil
end
function P.BlockName(block, i)
    if block.name then return block.name end
    if ns.L["bar.preset_" .. block.key] then return ns.T("bar.preset_" .. block.key) end
    if not i then
        for j, b in ipairs(P.Blocks()) do
            if b == block then i = j end
        end
    end
    return ns.T("bar.default_name", i or 0)
end
local function gearRef(k)
    return k:match("^slot:") or k:match("^meta") or k:match("^ench:") or k:match("^set:") or false
end
local function withUnit(e, unit)
    if not unit or e.unit == unit then return e end
    local out = {}
    for k, v in pairs(e) do out[k] = v end
    out.unit = unit
    return out
end
local function resolve(item)
    local k = tostring(item.k or "")
    if k == "want" or k:match("^want:") then return { k = k }, "want", "want" end
    if k:match("^widget:") then return nil, "widget", "widget" end
    if item.role == "gear" and (gearRef(k) or k:match("^item:")) then
        local e = ns.Trinket.ForRef(k)
        if item.onlyUse and not (e and e.use) then e = ns.Trinket.Passive(k) end
        return e, "mixed", "gear"
    end
    local map = sections(liveSpec)
    local function find(c)
        local sec = map[c]
        for _, e in ipairs((sec and sec.entries) or {}) do
            if e._key == k then return e, sec.kind, c end
        end
        return nil
    end
    local cat = CAT_OF[item.role]
    local e, kind, c
    if cat then e, kind, c = find(cat) end
    if not e and item.role == "item" then e, kind, c = find("potion") end
    if not e and not TARGET_ROLE[item.role] then
        for key in pairs(map) do
            e, kind, c = find(key)
            if e then break end
        end
    end
    if e then return e, kind, c end
    kind = KIND_OF[item.role] or "spell"
    if ns.Avail.Dropped(k) then return nil, kind, cat or "personal" end
    local harm, ally = (item.role == "harm") or nil, (item.role == "ally") or nil
    local unit = ally and "tank" or nil
    local id = tonumber(k:match("^spell:(%d+)$"))
    if id then return { id = id, harm = harm, ally = ally, unit = unit, mine = true, act = item.act }, kind, cat or "personal" end
    local iid = tonumber(k:match("^item:(%d+)$"))
    if iid then return { item = iid, mine = true }, "item", cat or "flask" end
    local name = k:match("^name:(.+)$")
    if name then return { byName = name, harm = harm, ally = ally, unit = unit, mine = true }, "aura", "proc" end
    return nil, kind, cat or "personal"
end
function P.Resolve(item)
    local e, kind, cat = resolve(item)
    if e and item.unit then
        e = withUnit(e, item.unit)
    elseif e and e.act and item.check == "unit" then
        e = withUnit(e, "tank")
    end
    return e, kind, cat
end
local function fighting()
    if not InCombatLockdown() then return false end
    if not said then
        said = true
        ns.say(ns.T("bar.combat"))
    end
    return true
end
local function repaint()
    if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
end
local function materialize()
    ensure()
    if liveStored then return live end
    local st = store()
    local rec = st[liveId] or { class = live.class, spec = live.spec }
    rec.base = rec.base or live.base
    rec.rev = rec.rev or live.rev
    rec.blocks = live.blocks
    rec.gone = rec.gone or live.gone or {}
    rec.places = nil
    st[liveId] = rec
    live, liveStored = rec, true
    return rec
end
local function edit(fn, live)
    if not live and fighting() then return false end
    local rec = materialize()
    local r = fn(rec)
    edits = edits + 1
    secAt = nil
    repaint()
    return r
end
local function blockOf(rec, key)
    for i, b in ipairs(rec.blocks) do
        if b.key == key then return b, i end
    end
    return nil
end
local function scaleOf(b)
    return b.scale or (LazyBuffBarDB and LazyBuffBarDB.scale) or 1
end
local function geoOf(b)
    local pad = b.pad or (ns.Look and ns.Look.BAR.pad.def) or 1
    local gap = b.gap or (ns.Look and ns.Look.BAR.gap.def) or 4
    return G.Geo(pad, gap)
end
function P.Rect(b)
    if not b.point then return nil end
    local w, h = G.Pixels(geoOf(b), b.cols, b.rows)
    return G.Anchor(b.point, w, h, scaleOf(b), UIParent:GetWidth(), UIParent:GetHeight())
end
local BESIDE_GAP = 4
besideAll = function(blocks, places)
    for _, rb in ipairs(ns.presetRecipe.blocks) do
        local pl = places and places[rb.key]
        if rb.beside and not (pl and pl.point) then
            local b, n
            for _, x in ipairs(blocks) do
                if x.key == rb.key then b = x elseif x.key == rb.beside then n = x end
            end
            local r = b and n and P.Rect(n)
            if r then
                local s = scaleOf(b)
                local o = G.Anchor({ "CENTER", n.point[2], 0, 0 }, 0, 0, 1, UIParent:GetWidth(), UIParent:GetHeight())
                b.point = { "TOPLEFT", n.point[2], (r.r + BESIDE_GAP * scaleOf(n) - o.l) / s, (r.t - o.b) / s }
            end
        end
    end
end
local function followerOf(blocks, b)
    local rect = P.Rect(b)
    if not rect then return nil end
    for _, rb in ipairs(ns.presetRecipe.blocks) do
        if rb.beside == b.key then
            for _, x in ipairs(blocks) do
                local r = x.key == rb.key and not x.off and P.Rect(x)
                if r and math.abs(r.l - rect.r - BESIDE_GAP * scaleOf(b)) < 1 and r.t > rect.b and r.b < rect.t then return x end
            end
        end
    end
    return nil
end
function P.Follower(key)
    local b = P.Block(key)
    local f = b and followerOf(P.Blocks(), b)
    local r = f and P.Rect(f)
    if not r then return nil, 0 end
    return f.key, r.r - r.l + BESIDE_GAP * scaleOf(b)
end
local function others(rec, skip, skip2)
    local out = {}
    for _, b in ipairs(rec.blocks) do
        if b ~= skip and b ~= skip2 and not b.off then
            local r = P.Rect(b)
            if r then out[#out + 1] = r end
        end
    end
    return out
end
local function bounds()
    return { l = 0, t = UIParent:GetHeight(), r = UIParent:GetWidth(), b = 0 }
end
local function room(rec, b, rect)
    local f = followerOf(rec.blocks, b)
    local fr = f and P.Rect(f)
    local maxW, maxH, upH = G.Room(rect, others(rec, b, f), bounds())
    if fr then maxW = maxW - (fr.r - fr.l + BESIDE_GAP * scaleOf(b)) end
    return maxW, maxH, upH, f
end
local function follow(b, f)
    local nr, fr = P.Rect(b), f and P.Rect(f)
    if nr and fr then f.point = G.PointFor(G.Shift(fr, nr.r + BESIDE_GAP * scaleOf(b) - fr.l, 0), scaleOf(f)) end
end
local function grow(rec, b, w, h)
    local s = scaleOf(b)
    local geo = geoOf(b)
    local rect = P.Rect(b)
    local rowPx, colPx = geo.dy * h * s, geo.dx * w * s
    local maxW, maxH, upH, f = math.huge, math.huge, math.huge, nil
    if rect then maxW, maxH, upH, f = room(rec, b, rect) end
    local bw, bh = G.Pixels(geo, b.cols, b.rows)
    if b.rows + h <= G.MAX_ROWS and bh * s + rowPx <= maxH then
        b.rows = b.rows + h
        return G.FreeCell(b, w, h)
    end
    if b.rows + h <= G.MAX_ROWS and bh * s + rowPx <= upH then
        for _, it in ipairs(b.items) do it.y = it.y + h end
        b.rows = b.rows + h
        if rect then b.point = G.PointFor(G.Shift(rect, 0, rowPx), s) end
        return G.FreeCell(b, w, h)
    end
    if b.cols + w <= G.MAX_COLS and bw * s + colPx <= maxW then
        b.cols = b.cols + w
        follow(b, f)
        return G.FreeCell(b, w, h)
    end
    local nb = { key = newKey(rec), cols = w, rows = h, items = {}, scale = b.scale, pad = b.pad, gap = b.gap }
    if rect then
        local nw, nh = G.Pixels(geo, w, h)
        local want = { l = rect.r, t = rect.t, r = rect.r + nw * s, b = rect.t - nh * s }
        nb.point = G.PointFor(G.FreeSpot(want, others(rec), bounds()), s)
    end
    rec.blocks[#rec.blocks + 1] = nb
    return 1, 1, nb.key
end
local function roomFor(rec, b, cols, rows)
    if cols <= b.cols and rows <= b.rows then return true end
    if cols > G.MAX_COLS or rows > G.MAX_ROWS then return false end
    local rect = P.Rect(b)
    if not rect then return true end
    local s = scaleOf(b)
    local maxW, maxH = room(rec, b, rect)
    local nw, nh = G.Pixels(geoOf(b), math.max(cols, b.cols), math.max(rows, b.rows))
    return nw * s <= maxW + 1e-6 and nh * s <= maxH + 1e-6
end
local function growTo(rec, b, cols, rows)
    if not roomFor(rec, b, cols, rows) then return false end
    local f = followerOf(rec.blocks, b)
    b.cols, b.rows = math.max(b.cols, cols), math.max(b.rows, rows)
    follow(b, f)
    return true
end
local function probeRect(rec, b, x, y, w, h, skip, skip2)
    local out, busy = G.Blockers(b, x, y, w, h, skip, skip2)
    if #busy > 0 or x < 1 or y < 1 then return "blocked", busy end
    if not out then return "fits", busy end
    if roomFor(rec, b, x + w - 1, y + h - 1) then return "grow", busy end
    return "blocked", busy
end
local function putItem(rec, b, item, x, y)
    sizeWidget(item)
    local w, h = G.Size(item)
    local key = b.key
    local kind = (x and y) and probeRect(rec, b, x, y, w, h) or "blocked"
    if kind == "fits" or (kind == "grow" and growTo(rec, b, x + w - 1, y + h - 1)) then
        item.x, item.y = x, y
    else
        x, y = G.FreeCell(b, w, h)
        if not x then
            local nk
            x, y, nk = grow(rec, b, w, h)
            if nk then b, key = blockOf(rec, nk), nk end
        end
        if not x then return nil end
        item.x, item.y = x, y
    end
    b.items[#b.items + 1] = item
    return x, y, key
end
local function prune(rec, b)
    if #b.items > 0 then return end
    if #rec.blocks > 1 then
        for i, x in ipairs(rec.blocks) do
            if x == b then tremove(rec.blocks, i) end
        end
    else
        b.cols, b.rows = 1, 1
    end
end
local function ungone(rec, it)
    local n = 0
    for i = #(rec.gone or {}), 1, -1 do
        local g = rec.gone[i]
        if g.k == it.k and g.role == it.role and g.unit == it.unit then
            tremove(rec.gone, i)
            n = n + 1
        end
    end
    return n
end
local function toGone(rec, it)
    rec.gone = rec.gone or {}
    for _, g in ipairs(rec.gone) do
        if g.k == it.k and g.role == it.role and g.unit == it.unit then return end
    end
    rec.gone[#rec.gone + 1] = { k = it.k, role = it.role, unit = it.unit }
end
function P.Add(key, item, x, y)
    if InCombatLockdown() then
        ns.Defer(function() P.Add(key, item, x, y) end)
        if not said then
            said = true
            ns.say(ns.T("bar.later"))
        end
        return nil
    end
    local rx, ry, rk
    edit(function(rec)
        local b = blockOf(rec, key) or rec.blocks[1]
        if not b then return end
        rx, ry, rk = putItem(rec, b, copy(item), x, y)
        if rx then ungone(rec, item) end
    end)
    return rx, ry, rk
end
local function swapMate(rec, it, b, tb, tx, ty)
    local o = G.ItemAt(tb, tx, ty)
    if not o or o == it or o.x ~= tx or o.y ~= ty then return nil end
    local w, h = G.Size(it)
    local ow, oh = G.Size(o)
    if not G.Fits(tb, tx, ty, w, h, it, o) then return nil end
    if not G.Fits(b, it.x, it.y, ow, oh, it, o) then return nil end
    return o
end
function P.Probe(key, x, y, toKey, tx, ty)
    ensure()
    local b = blockOf(live, key)
    local it = b and G.ItemAt(b, x, y)
    local tb = toKey and blockOf(live, toKey) or b
    if not (it and tb) then return "blocked", {} end
    if tb == b and tx == it.x and ty == it.y then return "same", {} end
    local w, h = G.Size(it)
    local kind, busy = probeRect(live, tb, tx, ty, w, h, tb == b and it or nil)
    if kind ~= "blocked" then return kind, busy end
    if swapMate(live, it, b, tb, tx, ty) then return "swap", {} end
    return "blocked", busy
end
function P.ProbeAdd(key, x, y, w, h)
    ensure()
    local b = blockOf(live, key)
    if not b then return "blocked", {} end
    return probeRect(live, b, x, y, w or 1, h or 1)
end
function P.Move(key, x, y, toKey, tx, ty)
    return edit(function(rec)
        local b = blockOf(rec, key)
        local it = b and G.ItemAt(b, x, y)
        if not it then return false end
        local tb = toKey and blockOf(rec, toKey) or b
        if not tb then return false end
        local w, h = G.Size(it)
        local function relocate(e, from, to, nx, ny)
            if from ~= to then
                for i, z in ipairs(from.items) do
                    if z == e then tremove(from.items, i) end
                end
                to.items[#to.items + 1] = e
            end
            e.x, e.y = nx, ny
        end
        local kind = probeRect(rec, tb, tx, ty, w, h, tb == b and it or nil)
        if kind == "fits" or (kind == "grow" and growTo(rec, tb, tx + w - 1, ty + h - 1)) then
            relocate(it, b, tb, tx, ty)
            prune(rec, b)
            return true
        end
        local o = swapMate(rec, it, b, tb, tx, ty)
        if not o then return false end
        local ox, oy = it.x, it.y
        relocate(it, b, tb, tx, ty)
        relocate(o, tb, b, ox, oy)
        return true
    end)
end
function P.Remove(key, x, y, forget)
    return edit(function(rec)
        local b = blockOf(rec, key)
        local it = b and G.ItemAt(b, x, y)
        if not it then return false end
        for i, z in ipairs(b.items) do
            if z == it then tremove(b.items, i) end
        end
        if not forget then toGone(rec, it) end
        prune(rec, b)
        return true
    end)
end
function P.TakeBlock(key, forget)
    local snap
    edit(function(rec)
        local b, i = blockOf(rec, key)
        if not b or #rec.blocks < 2 then return false end
        snap = { block = copy(b), index = i }
        if not forget then
            for _, it in ipairs(b.items) do toGone(rec, it) end
        end
        tremove(rec.blocks, i)
        return true
    end)
    return snap
end
function P.PutBlock(snap)
    return edit(function(rec)
        local b = copy(snap.block)
        if blockOf(rec, b.key) then return false end
        local gone = rec.gone or {}
        for _, it in ipairs(b.items) do
            for i = #gone, 1, -1 do
                local g = gone[i]
                if g.k == it.k and g.role == it.role and g.unit == it.unit then
                    tremove(gone, i)
                    break
                end
            end
        end
        tinsert(rec.blocks, math.min(snap.index, #rec.blocks + 1), b)
        return true
    end) and true or false
end
function P.RemoveBlock(key)
    return edit(function(rec)
        local b, i = blockOf(rec, key)
        if not b or #b.items > 0 or #rec.blocks < 2 then return false end
        tremove(rec.blocks, i)
        return true
    end) and true or false
end
function P.SetView(key, x, y, view)
    local busy = {}
    local ok = edit(function(rec)
        local b = blockOf(rec, key)
        local it = b and G.ItemAt(b, x, y)
        local name = it and ns.Widget.NameOf(it.k)
        if not (name and ns.Widget.Get(name)) then return false end
        view = ns.Widget.ViewOf(name, view)
        local w, h = ns.Widget.Size(name, view, it.opt)
        local kind, cells = probeRect(rec, b, it.x, it.y, w, h, it)
        if kind == "blocked" or (kind == "grow" and not growTo(rec, b, it.x + w - 1, it.y + h - 1)) then
            busy = cells
            return false
        end
        it.view = view
        sizeWidget(it)
        return true
    end)
    return ok and true or false, busy
end
function P.Set(key, x, y, field, v)
    if not ITEM_FIELDS[field] then return false end
    if field == "unit" and v ~= nil and not ns.Units.Valid(v) then return false end
    if field == "rules" then v = ns.Cond.CleanRules(v) end
    local live = LIVE_FIELDS[field] or false
    if field == "view" then
        local cur = P.ItemAt(key, x, y)
        if cur and tostring(cur.k):match("^widget:") then return (P.SetView(key, x, y, v)) end
    end
    return edit(function(rec)
        local b = blockOf(rec, key)
        local it = b and G.ItemAt(b, x, y)
        if not it then return false end
        it[field] = v
        return true
    end, live)
end
local function chain(b, wd, list, dx, dy)
    local set = {}
    for _, a in ipairs(list) do set[a] = true end
    local i = 1
    while i <= #list do
        local a = list[i]
        local aw, ah = G.Size(a)
        local nx, ny = a.x + dx, a.y + dy
        for _, o in ipairs(b.items) do
            if o ~= wd and not set[o] then
                local ow, oh = G.Size(o)
                if nx < o.x + ow and o.x < nx + aw and ny < o.y + oh and o.y < ny + ah then
                    set[o] = true
                    list[#list + 1] = o
                end
            end
        end
        i = i + 1
    end
end
local function clean(b)
    for i, a in ipairs(b.items) do
        if a.x < 1 or a.y < 1 then return false end
        local aw, ah = G.Size(a)
        for j = i + 1, #b.items do
            local o = b.items[j]
            local ow, oh = G.Size(o)
            if a.x < o.x + ow and o.x < a.x + aw and a.y < o.y + oh and o.y < a.y + ah then return false end
        end
    end
    return true
end
local function push(b, wd, horiz, d)
    local w, h = G.Size(wd)
    local list = {}
    for _, o in ipairs(b.items) do
        if o ~= wd then
            local ow, oh = G.Size(o)
            if horiz then
                if o.x >= wd.x + w and o.y < wd.y + h and o.y + oh > wd.y then list[#list + 1] = o end
            elseif o.y >= wd.y + h and o.x < wd.x + w and o.x + ow > wd.x then list[#list + 1] = o end
        end
    end
    local dx, dy = horiz and d or 0, horiz and 0 or d
    chain(b, wd, list, dx, dy)
    for _, o in ipairs(list) do o.x, o.y = o.x + dx, o.y + dy end
end
local function places(b)
    local out = {}
    for i, o in ipairs(b.items) do out[i] = { o, o.x, o.y, o.w, o.h } end
    return out
end
local function restore(saved)
    for _, s in ipairs(saved) do s[1].x, s[1].y, s[1].w, s[1].h = s[2], s[3], s[4], s[5] end
end
local function resizeItem(rec, b, it, nw, nh)
    local w, h = G.Size(it)
    local saved = places(b)
    local cols0, rows0 = b.cols, b.rows
    for _, pass in ipairs({ { true, nw - w }, { false, nh - h } }) do
        local horiz, d = pass[1], pass[2]
        if d ~= 0 then
            local before = places(b)
            if d < 0 then
                if horiz then it.w = nw > 1 and nw or nil else it.h = nh > 1 and nh or nil end
                push(b, it, horiz, d)
                if not clean(b) then
                    restore(before)
                    if horiz then it.w = nw > 1 and nw or nil else it.h = nh > 1 and nh or nil end
                end
            else
                push(b, it, horiz, d)
                if horiz then it.w = nw > 1 and nw or nil else it.h = nh > 1 and nh or nil end
            end
        end
    end
    local cols, rows = G.MinSize(b)
    if not clean(b) or ((cols > b.cols or rows > b.rows) and not growTo(rec, b, cols, rows)) then
        local busy = {}
        for _, o in ipairs(b.items) do
            local ow, oh = G.Size(o)
            if o ~= it and (o.x + ow - 1 > G.MAX_COLS or o.y + oh - 1 > G.MAX_ROWS or o.x + ow - 1 > cols0 or o.y + oh - 1 > rows0) then
                for _, s in ipairs(saved) do
                    if s[1] == o then busy[#busy + 1] = { x = math.min(s[2], cols0), y = math.min(s[3], rows0) } end
                end
            end
        end
        restore(saved)
        b.cols, b.rows = cols0, rows0
        return false, busy
    end
    if b.cols > cols0 or b.rows > rows0 then b.grown = b.grown or { cols = cols0, rows = rows0 } end
    local g = b.grown
    if g then
        b.cols = math.min(b.cols, math.max(cols, g.cols))
        b.rows = math.min(b.rows, math.max(rows, g.rows))
        if b.cols <= g.cols and b.rows <= g.rows then b.grown = nil end
    end
    return true, {}
end
function P.SetOpt(key, x, y, optKey, v)
    local busy = {}
    local ok = edit(function(rec)
        local b = blockOf(rec, key)
        local it = b and G.ItemAt(b, x, y)
        local name = it and ns.Widget.NameOf(it.k)
        if not name then return false end
        local opt = copy(it.opt or {})
        opt[optKey] = v
        if next(opt) == nil then opt = nil end
        if ns.Widget.Get(name) then
            local nw, nh = ns.Widget.Size(name, it.view, opt)
            local w, h = G.Size(it)
            if nw ~= w or nh ~= h then
                local done
                done, busy = resizeItem(rec, b, it, nw, nh)
                if not done then return false end
            end
        end
        it.opt = opt
        return true
    end)
    return ok and true or false, busy
end
function P.NewBlock(item, rect, src)
    return edit(function(rec)
        local sb, moving
        if src then
            sb = blockOf(rec, src.key)
            moving = sb and G.ItemAt(sb, src.x, src.y)
            if not moving then return false end
            item = moving
        end
        local w, h = 1, 1
        if item and not moving then item = sizeWidget(copy(item)) end
        if item then w, h = G.Size(item) end
        local b = { key = newKey(rec), cols = w, rows = h, items = {} }
        if sb then b.scale, b.pad, b.gap = sb.scale, sb.pad, sb.gap end
        if moving then
            for i, z in ipairs(sb.items) do
                if z == moving then tremove(sb.items, i) end
            end
            moving.x, moving.y = 1, 1
            b.items[1] = moving
        elseif item then
            local it = copy(item)
            it.x, it.y = 1, 1
            b.items[1] = it
            ungone(rec, it)
        end
        local s = scaleOf(b)
        local pw, ph = G.Pixels(geoOf(b), w, h)
        local all = others(rec, (sb and #sb.items == 0) and sb or nil)
        if not rect then
            local low
            for _, r in ipairs(all) do
                if not low or r.b < low.b then low = r end
            end
            if low then rect = { l = low.l, t = low.b - 24 * s } end
        end
        if rect then
            local want = { l = rect.l, t = rect.t, r = rect.l + pw * s, b = rect.t - ph * s }
            b.point = G.PointFor(G.FreeSpot(want, all, bounds()), s)
        end
        rec.blocks[#rec.blocks + 1] = b
        if sb then prune(rec, sb) end
        return b.key
    end)
end
function P.AddBlock(block, rect)
    return edit(function(rec)
        local b = copy(block)
        b.key = newKey(rec)
        b.point, b.off = nil, nil
        b.items = b.items or {}
        local cols, rows = 1, 1
        for _, it in ipairs(b.items) do
            sizeWidget(it)
            it.x, it.y = it.x or 1, it.y or 1
            local w, h = G.Size(it)
            cols, rows = math.max(cols, it.x + w - 1), math.max(rows, it.y + h - 1)
            ungone(rec, it)
        end
        b.cols = math.min(G.MAX_COLS, math.max(tonumber(b.cols) or 1, cols))
        b.rows = math.min(G.MAX_ROWS, math.max(tonumber(b.rows) or 1, rows))
        local s = scaleOf(b)
        local pw, ph = G.Pixels(geoOf(b), b.cols, b.rows)
        local l = rect and rect.l or (UIParent:GetWidth() - pw * s) / 2
        local t = rect and rect.t or (UIParent:GetHeight() + ph * s) / 2
        local want = { l = l, t = t, r = l + pw * s, b = t - ph * s }
        b.point = G.PointFor(G.FreeSpot(want, others(rec), bounds()), s)
        rec.blocks[#rec.blocks + 1] = b
        return b.key
    end)
end
function P.Resize(key, cols, rows)
    return edit(function(rec)
        local b = blockOf(rec, key)
        if not b then return false end
        local mc, mr = G.MinSize(b)
        if cols < mc or rows < mr or cols > G.MAX_COLS or rows > G.MAX_ROWS then return false end
        local f = followerOf(rec.blocks, b)
        b.cols, b.rows, b.grown = cols, rows, nil
        follow(b, f)
        return true
    end)
end
function P.SetBlock(key, field, v)
    if BLOCK_FIELDS[field] then
        return edit(function(rec)
            local b = blockOf(rec, key)
            if not b then return false end
            b[field] = v
            return true
        end)
    end
    if not PLACE[field] then return false end
    if fighting() then return false end
    local b = P.Block(key)
    if not b then return false end
    b[field] = v
    if not liveStored then
        local st = store()
        local rec = st[liveId] or { class = live.class, spec = live.spec, base = live.base, rev = live.rev }
        rec.places = rec.places or {}
        rec.places[key] = rec.places[key] or {}
        rec.places[key][field] = copy(v)
        st[liveId] = rec
    end
    if field ~= "point" then repaint() end
    return true
end
function P.Restore(ref, role, key, x, y)
    local rx, ry, rk
    edit(function(rec)
        local it
        for i, g in ipairs(rec.gone or {}) do
            if g.k == ref and (role == nil or g.role == role) then
                it = tremove(rec.gone, i)
                break
            end
        end
        if not it then return end
        local b = (key and blockOf(rec, key)) or rec.blocks[1]
        rx, ry, rk = putItem(rec, b, { k = it.k, role = it.role, unit = it.unit }, x, y)
    end)
    return rx, ry, rk
end
function P.Gone()
    ensure()
    return live.gone or {}
end
function P.Label(id)
    return nameOf(store()[id], id)
end
function P.List(class)
    class = class or ns.PlayerClass()
    local out = {}
    local c = ns.specs[class]
    for _, v in ipairs((c and c.order) or {}) do
        local id = class .. "/" .. v
        out[#out + 1] = { id = id, label = P.Label(id), spec = v, state = stateOf(id), own = false }
    end
    local own = {}
    for id, rec in pairs(store()) do
        if rec.class == class and not isFactory(id) then
            own[#own + 1] = { id = id, label = P.Label(id), spec = rec.spec, state = "own", own = true }
        end
    end
    table.sort(own, function(a, b)
        if a.label ~= b.label then return a.label < b.label end
        return a.id < b.id
    end)
    for _, e in ipairs(own) do out[#out + 1] = e end
    return out
end
function P.Select(group, id)
    if not exists(id) then return false end
    if InCombatLockdown() then
        ns.DeferKey("preset.select." .. group, function() P.Select(group, id) end)
        if not said then
            said = true
            ns.say(ns.T("bar.later"))
        end
        return false
    end
    bind(group, specOf(group), id)
    if group == ns.ActiveSlot() then
        invalidate()
        repaint()
    end
    return true
end
function P.SaveAs(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$")
    if name == "" or fighting() then return false end
    ensure()
    local id = P.NextId()
    store()[id] = { class = live.class, spec = live.spec, name = name, base = live.base, rev = live.rev,
                    blocks = copy(live.blocks), gone = copy(live.gone or {}) }
    if isFactory(liveId) then store()[liveId] = nil end
    bind(ns.ActiveSlot(), specOf(ns.ActiveSlot()), id)
    invalidate()
    repaint()
    return id
end
function P.Rename(id, name)
    name = tostring(name or ""):match("^%s*(.-)%s*$")
    local rec = store()[id]
    if not rec or isFactory(id) or name == "" then return false end
    rec.name = name
    return true
end
function P.Delete(id)
    local rec = store()[id]
    if not rec or isFactory(id) then return false end
    ensure()
    if liveId == id and fighting() then return false end
    store()[id] = nil
    local c = char()
    for _, b in pairs(c.bind or {}) do
        if b.id == id then b.id = b.spec end
    end
    for s, x in pairs(c.last or {}) do
        if x == id then c.last[s] = nil end
    end
    for s, x in pairs(root().bind or {}) do
        if x == id then root().bind[s] = nil end
    end
    if liveId == id then
        invalidate()
        repaint()
    end
    return true
end
function P.Reset(s)
    s = s or P.Bound()
    if not isFactory(s) or fighting() then return false end
    store()[s] = nil
    if liveId == s then
        invalidate()
        repaint()
    end
    return true
end
function P.SpecOf(group)
    return specOf(group or ns.ActiveSlot())
end
function P.Bound(group)
    group = group or ns.ActiveSlot()
    return bound(group, specOf(group))
end
function P.StateOf(id)
    return stateOf(id)
end
function P.Sync()
    if not (ns.Profile and ns.Profile.Loaded()) then return end
    if InCombatLockdown() then
        ns.DeferKey("preset", function()
            P.Sync()
            repaint()
        end)
        return
    end
    syncNow()
    invalidate()
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_LOGIN")
local signed
f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        said = false
        return
    end
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        signed = installSign()
        if not liveStored then invalidate() end
        return
    end
    if event == "UNIT_INVENTORY_CHANGED" then
        if unit ~= "player" then return end
        local sign = installSign()
        if sign ~= signed then
            signed = sign
            if not liveStored then invalidate() end
        end
        return
    end
    live, liveId, liveStored, synced = nil, nil, false, false
    invalidate()
end)
ns.presetLoaded = true

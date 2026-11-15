local _, ns = ...
ns.Catalog = {}
local C = ns.Catalog
C.SEEN_MAX = 300
local SEEN_KEEP = 270
local SEEN_TOUCH = 60
C.GROUP_MAX = 300
C.RECENT_BROWSE = 12
local BROWSE = { mine = true, general = true, preset = true, rec = true, recent = true }
local NAME_MIN = 3
C.CATS = { "mine", "general", "preset", "rec", "recent", "rest" }
local CAT_RANK = { own = 0, mine = 1, general = 2, preset = 3, rec = 4, recent = 5, rest = 6 }
C.SCOPES = { "spec", "items", "char", "all" }
C.FILTERS = { "mine", "all" }
local SCOPE_PASS = {
    spec  = { spec = true, every = true },
    items = { items = true, every = true },
    char  = { spec = true, char = true, items = true, every = true },
    mine  = { spec = true, items = true, every = true },
}
local WEAR_SLOTS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
local TRINKET_SLOT = { [13] = true, [14] = true }
C.TAGS ={ "ability", "talent", "proc", "target", "raid", "form", "consumable", "gear", "boss", "class", "widget", "pvp" }
local TAG_CODE = { a = "ability", t = "talent", p = "proc", d = "target", r = "raid", f = "form", x = "consumable",
                   g = "gear", b = "boss", v = "pvp", o = "class", w = "widget", n = "perm", u = "up", h = "hidden",
                   l = "onAlly" }
local CLASS_OF = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DRUID" }
local FAMILY = { self = "aura", proc = "aura", raid = "aura", item = "aura", harm = "aura", gear = "aura",
                 cd = "cd", act = "cd", dot = "dot", weapon = "weapon", widget = "widget", tbuff = "tbuff", pet = "pet" }
local ROLE_GROUPS = {
    cd     = { cd = true, gear = true },
    act    = { cd = true },
    dot    = { dot = true },
    proc   = { proc = true, gear = true },
    self   = { personal = true, proc = true },
    raid   = { raid = true, want = true, proc = true },
    item   = { flask = true, potion = true, food = true, proc = true },
    harm   = { proc = true },
    gear   = { gear = true, proc = true },
    weapon = { personal = true },
    tbuff  = { proc = true },
}
local ALLY_ROWS = { tbuff = true, dot = true }
local GROUP_ROLE = { personal = "self", raid = "raid", flask = "item", potion = "item", food = "item", want = "raid",
                     proc = "proc", cd = "cd", gear = "cd", dot = "dot" }
local OWN_ROLE = { cd = "cd", act = "cd", dot = "dot", harm = "harm", proc = "proc", self = "proc", raid = "proc", item = "proc", gear = "proc",
                   tbuff = "ally" }
local function onBoss(row)
    return row ~= nil and row.where == "t" and row.tags ~= nil and row.tags.boss == true
end
function C.UnitOf(row)
    if not row then return nil end
    if row.need and row.need.u == "Tank" then return "tank" end
    if onBoss(row) then return "boss" end
    if C.Roles(row)[1] == "tbuff" then return "tank" end
    return nil
end
local function placeRole(hit)
    if onBoss(hit.row) and (hit.role == "tbuff" or hit.role == "dot") then
        return hit.role == "dot" and "harm" or "proc"
    end
    if hit.role == "widget" then
        local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(hit.ref)
        return (name and ns.Widget.Get(name)) and "widget" or nil
    end
    return OWN_ROLE[hit.role]
end
local TRACK_ROLE = { proc = true, harm = true, ally = true, cd = true, dot = true, gear = true }
local MINE_ROLES = { cd = true, act = true, proc = true, dot = true, self = true, weapon = true, tbuff = true, pet = true }
local db
local names
local function altList(s, row)
    for w in s:gmatch("[^,]+") do
        local n = tonumber(w)
        if n then
            row.alt = row.alt or {}
            row.alt[#row.alt + 1] = n
        else
            local i = tonumber(w:match("^i(%d+)$"))
            if i then
                row.altItems = row.altItems or {}
                row.altItems[#row.altItems + 1] = i
            end
        end
    end
end
local function needSet(s)
    local out = {}
    for w in s:gmatch("[^,]+") do
        local code, rest = w:sub(1, 1), w:sub(2)
        out[code] = rest ~= "" and rest or true
    end
    return out
end
local function source(row, w)
    if w == "-" then return true end
    if w == "b" or w == "r" or w == "R" then row.src, row.srcKind = w, w; return true end
    local k, id = w:match("^([tsieS])(%d+)")
    if not k then return false end
    row.src, row.srcKind, row.srcId = w, k, tonumber(id)
    if k == "S" then row.srcN = tonumber(w:match(":(%d+)$")) end
    return true
end
local function tagWord(row, w)
    if w == "-" then row.tags = row.tags or {}; return true end
    if not w:match("^%l+$") then return false end
    for ch in w:gmatch(".") do
        if not TAG_CODE[ch] then return false end
    end
    row.tags = {}
    for ch in w:gmatch(".") do row.tags[TAG_CODE[ch]] = true end
    return true
end
local function option(row, key, v)
    if key == "rec" then
        row.rec = {}
        for w in v:gmatch("[^,]+") do row.rec[#row.rec + 1] = w end
    elseif key == "alt" then
        altList(v, row)
    elseif key == "sub" then
        row.sub = v
    elseif key == "w" then
        for w in v:gmatch("[^,]+") do
            local want = w:match("^want:(.+)$")
            if want then row.want = row.want or want end
            if not w:find(":", 1, true) then
                row.widgets = row.widgets or {}
                row.widgets[#row.widgets + 1] = w
            end
        end
    elseif key == "need" then
        row.need = needSet(v)
    end
end
function C.ParseLine(line)
    local words = {}
    for w in tostring(line or ""):gmatch("%S+") do words[#words + 1] = w end
    local ref, kind = words[1], words[2]
    if not ref or not kind or not kind:match("^%a$") then return nil end
    local itemId = ref:match("^i(%d+)$")
    local id = tonumber(itemId or ref)
    if not id then return nil end
    local row = { id = id, item = itemId and true or nil, kind = kind, where = "s", cls = 0 }
    local w = words[3]
    if w and w:match("^%l$") then row.where = w end
    local c = words[4]
    if c then
        local cls, tab = c:match("^(%d+)%.(%d+)$")
        if cls then
            row.cls, row.tab = tonumber(cls), tonumber(tab)
        else
            row.cls = tonumber(c) or 0
        end
    end
    for i = 5, #words do
        local x = words[i]
        local key, v = x:match("^(%a+)=(.*)$")
        if key then
            option(row, key, v)
        elseif not (i == 5 and source(row, x)) and not (i == 6 and tagWord(row, x)) then
            if x:match("^[%+=a]?%d[%d,]*$") and x:find(",", 1, true) then
                altList(x:gsub("^[%+=a]", ""), row)
            elseif i == 5 and x:match("^[1-3]$") then
                row.tab = tonumber(x)
            elseif x:match("^%a+$") then
                row.sub = x
            end
        end
    end
    if row.tab == 0 then row.tab = nil end
    return row
end
local function index(map, key, row)
    local l = map[key]
    if not l then l = {}; map[key] = l end
    l[#l + 1] = row
end
function C.Ensure()
    if db then return db end
    db = { rows = {}, byId = {}, byAura = {}, byItem = {}, byClass = {}, widgets = {}, widgetOrder = {}, up = {} }
    local src = ns.catalogDB
    if type(src) == "string" then
        for line in src:gmatch("[^\r\n]+") do
            local row = C.ParseLine(line)
            if row then
                db.rows[#db.rows + 1] = row
                if row.item then
                    index(db.byItem, row.id, row)
                else
                    index(db.byId, row.id, row)
                    index(db.byAura, row.id, row)
                    for _, a in ipairs(row.alt or {}) do index(db.byAura, a, row) end
                end
                index(db.byClass, row.cls, row)
                for _, name in ipairs(row.widgets or {}) do
                    if not db.widgets[name] then db.widgetOrder[#db.widgetOrder + 1] = name end
                    index(db.widgets, name, row)
                end
            end
        end
    end
    for _, row in ipairs(db.rows) do
        if row.kind == "r" and row.cls ~= 0 and row.want then
            for _, a in ipairs(row.alt or {}) do
                for _, x in ipairs(db.byId[a] or {}) do
                    if x ~= row and x.kind == "r" and x.cls == row.cls and not x.want then x.pairGroup = row.id end
                end
            end
        end
        if row.kind == "c" and row.tags and row.tags.up then
            db.up[row.id] = true
            for _, a in ipairs(row.alt or {}) do db.up[a] = true end
        end
    end
    for _, row in ipairs(db.rows) do
        if (row.kind == "b" or row.kind == "f") and row.where == "s" and not row.item and db.up[row.id] then row.underCd = true end
    end
    return db
end
function C.RowFor(id)
    local _, class = UnitClass("player")
    local common
    for _, r in ipairs(C.Ensure().byId[id] or {}) do
        if r.cls ~= 0 and CLASS_OF[r.cls] == class then return r, true end
        if r.cls == 0 and not common then common = r end
    end
    return common, false
end
function C.UpId(id)
    return id ~= nil and C.Ensure().up[id] == true
end
function C.Reset()
    db, names = nil, nil
    C.Forget()
end
local function sourceName(key)
    if not names then
        names = {}
        if type(ns.catalogNames) == "string" then
            for k, ru, en in ns.catalogNames:gmatch("(%S+) ([^|\r\n]*)|([^\r\n]*)") do names[k] = { ru, en } end
        end
    end
    local t = names[key]
    if not t then return nil end
    local v = (ns.CurrentLocale() == "ruRU") and t[1] or t[2]
    if v == nil or v == "" then v = t[1] end
    return v
end
function C.SourceName(key)
    return sourceName(key)
end
local function itemName(id)
    local name = GetItemInfo(id)
    if name then return name end
    return sourceName("i" .. id) or ns.T("catalog.item_n", id)
end
function C.FoodItem(spellId)
    if not spellId then return nil end
    for _, r in ipairs(C.Ensure().byAura[spellId] or {}) do
        if r.sub and r.sub:match("^food") and r.srcKind == "i" and r.srcId then return r.srcId end
    end
    return nil
end
function C.FoodName(spellId)
    local id = C.FoodItem(spellId)
    return id and itemName(id) or nil
end
function C.FoodLabel(spellId)
    local id = C.FoodItem(spellId)
    if not id then return nil end
    local icon = GetItemIcon and GetItemIcon(id)
    if icon then return "|T" .. icon .. ":14:14|t " .. itemName(id) end
    return itemName(id)
end
local function rowName(row)
    if row.name then return row.name end
    local name
    if row.item then
        name = itemName(row.id)
    else
        name = GetSpellInfo(row.id)
        if not name then
            row.missing = true
            name = ns.T("catalog.spell_n", row.id)
        end
    end
    row.name = name
    row.fold = ns.Fold(name)
    return name
end
local function rowIcon(row)
    if row.item then return GetItemIcon and GetItemIcon(row.id) or nil end
    local _, _, icon = GetSpellInfo(row.id)
    return icon
end
local function rowSrc(row)
    if row.srcText ~= nil then return row.srcText or nil end
    local k, id = row.srcKind, row.srcId
    local text
    if k == "t" then
        text = ns.T("catalog.src.talent", GetSpellInfo(id) or ("#" .. id))
    elseif k == "s" then
        local n = GetSpellInfo(id)
        if n and n ~= rowName(row) then text = ns.T("catalog.src.spell", n) end
    elseif k == "i" then
        if not (row.item and row.id == id) then text = itemName(id) end
    elseif k == "S" then
        text = ns.T("catalog.src.set", sourceName("S" .. id) or ("#" .. id), row.srcN or 0)
    elseif k == "e" then
        text = sourceName("e" .. id) or ns.T("catalog.src.ench")
    elseif k == "r" then
        text = ns.T("catalog.src.race")
    end
    row.srcText = text or false
    row.srcFold = text and ns.Fold(text) or nil
    return text
end
function C.Roles(row)
    if row.item then return { row.kind == "x" and "item" or "gear" } end
    if row.underCd then return {} end
    local k, w = row.kind, row.where
    if k == "b" and row.sub == "weapon" then return { "weapon" } end
    if k == "c" then return { "cd" } end
    if k == "a" then return { "act" } end
    if k == "b" or k == "f" then
        if w == "t" or w == "a" then return { "tbuff" } end
        if w == "p" then return { "pet" } end
        return { "self" }
    end
    if k == "r" then return { "raid" } end
    if k == "d" then return { (w == "t" or w == "a") and "dot" or "harm" } end
    if k == "x" then return { "item" } end
    if w == "t" then return { "dot" } end
    if w == "a" then return { "tbuff" } end
    if w == "p" then return { "pet" } end
    return { "proc" }
end
local function tagsOf(row, role, class)
    local t = {}
    if role == "widget" then t.widget = true; return t end
    if role == "dot" and not (row and row.where == "a") then t.target = true end
    if not row then
        if role == "cd" or role == "act" then t.ability = true end
        return t
    end
    if row.tags then
        for k, v in pairs(row.tags) do t[k] = v end
    else
        local k, sk = row.kind, row.srcKind
        if k == "c" or k == "a" or sk == "b" then t.ability = true end
        if sk == "t" then t.talent = true end
        if k == "p" then t.proc = true end
        if row.where == "t" then t.target = true end
        if k == "r" or row.where == "g" then t.raid = true end
        if k == "f" then t.form = true end
        if k == "x" then t.consumable = true end
        if k == "g" or row.item then t.gear = true end
    end
    if row.cls ~= 0 and CLASS_OF[row.cls] ~= class then t.class = true end
    if row.widgets then t.widget = true end
    return t
end
local ROLE_ORDER = { "cd", "act", "self", "raid", "proc", "harm", "dot", "ally", "gear", "item" }
function C.RolesOf(k, current)
    local set = {}
    if current then set[current] = true end
    local base = C.Ensure()
    local id = tonumber(tostring(k):match("^spell:(%d+)$"))
    local iid = tonumber(tostring(k):match("^item:(%d+)$"))
    local rows = {}
    if id then
        for _, r in ipairs(base.byId[id] or {}) do rows[#rows + 1] = r end
        for _, r in ipairs(base.byAura[id] or {}) do rows[#rows + 1] = r end
    elseif iid then
        for _, r in ipairs(base.byItem[iid] or {}) do rows[#rows + 1] = r end
    end
    for _, row in ipairs(rows) do
        for _, r in ipairs(C.Roles(row)) do
            local own = placeRole({ row = row, role = r })
            if own == "proc" and (current == "self" or current == "raid") and (r == "self" or r == "raid") then own = current end
            if own then set[own] = true end
        end
    end
    local out = {}
    local listed = false
    for _, r in ipairs(ROLE_ORDER) do
        if set[r] then out[#out + 1] = r end
        if r == current then listed = true end
    end
    if current and not listed then out[#out + 1] = current end
    return out
end
local function isWorn(ctx, id)
    return id ~= nil and ctx.worn[id] == true
end
local function alienNeed(row, ctx)
    local need = row and row.need
    if not need then return false end
    if type(need.r) == "string" and ctx.race and need.r ~= ctx.race then return true end
    return type(need.f) == "string" and ctx.faction ~= nil and need.f ~= ctx.faction
end
function C.Warn(row, role, ctx)
    if not row then return nil end
    if row.missing then return "missing" end
    local need = row.need
    local cls = CLASS_OF[row.cls]
    local alien = cls and cls ~= ctx.class
    if alien and ((need and (need.c or need.S)) or (not need and MINE_ROLES[role])) then
        return (need and need.S or row.srcKind == "S") and "set" or "class"
    end
    if row.tab and ctx.tab and row.tab ~= ctx.tab and ((need and need.t) or (not need and row.srcKind == "t")) then
        return "spec"
    end
    if need and type(need.r) == "string" and ctx.race and need.r ~= ctx.race then return "race" end
    if need and type(need.f) == "string" and ctx.faction and need.f ~= ctx.faction then return "faction" end
    if need and need.w then
        local id = row.item and row.id or (row.srcKind == "i" and row.srcId) or nil
        if id and not isWorn(ctx, id) then return "worn" end
    end
    if role == "dot" and (row.kind == "b" or row.kind == "r" or row.kind == "f" or row.kind == "x") then return "buff" end
    if (role == "proc" or role == "self") and row.kind == "d" then return "debuff" end
    return nil
end
local function score(hay, q)
    if not hay then return nil end
    local p = hay:find(q, 1, true)
    if not p then return nil end
    if p == 1 then return 0 end
    while p do
        if hay:sub(p - 1, p - 1):match("[%s%-%(%):,\"'\171]") then return 1 end
        p = hay:find(q, p + 1, true)
    end
    return 2
end
local roleFold = {}
local function roleText(key)
    return ns.T("catalog.role." .. key)
end
local function roleFolded(key)
    local f = roleFold[key]
    if not f then
        f = ns.Fold(roleText(key))
        roleFold[key] = f
    end
    return f
end
local function roleKey(row, role)
    if role == "cd" and row and row.tags and row.tags.up then return "cdup" end
    if role == "self" and row and row.tags and row.tags.perm then return "perm" end
    if role == "self" and row and row.kind == "f" then return "form" end
    return role
end
local function parseQuery(q)
    q = tostring(q or "")
    local out = {}
    out.spell = tonumber(q:match("|Hspell:(%d+)") or q:match("^%s*#(%d+)%s*$"))
    out.item = tonumber(q:match("|Hitem:(%d+)"))
    local text = q
    if q:find("|H", 1, true) then
        out.link = q
        text = q:match("|h%[(.-)%]|h") or ""
    end
    out.text = text:gsub("^%s+", ""):gsub("%s+$", "")
    out.fold = ns.Fold(out.text)
    if out.spell and not out.link then out.fold = "" end
    return out
end
local ITEM_GROUP = { self = "personal", weapon = "personal", food = "food", raid = "raid", want = "want", item = "flask",
                     proc = "proc", ally = "proc", cd = "cd", gear = "gear", dot = "dot" }
local function takePreset(ctx)
    if not (ns.Preset and ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return end
    for _, b in ipairs(ns.Preset.Blocks()) do
        for _, it in ipairs(b.items or {}) do
            ctx.items[#ctx.items + 1] = { k = it.k, role = it.role, key = b.key, x = it.x, y = it.y }
        end
    end
    for _, g in ipairs(ns.Preset.Gone()) do ctx.gone[#ctx.gone + 1] = g end
end
local function context()
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local info = ns.SpecInfo and ns.SpecInfo(class, v)
    local _, race = UnitRace("player")
    local faction = UnitFactionGroup("player")
    local worn, slotOf = ns.Avail.Worn()
    local ctx = { class = class, variant = v, role = (info and info.role) or "dd", tab = info and info.tab,
                  race = race, faction = faction and faction:sub(1, 1) or nil,
                  placed = {}, entries = {}, items = {}, gone = {}, seen = {}, worn = worn, slotOf = slotOf }
    local function take(list)
        for _, sec in ipairs(list or {}) do
            for _, e in ipairs(sec.entries) do
                local id = (not e.slot and not e.hand) and (e.aura or e.id) or nil
                if (id or e.byName) and e._key then
                    local p = { group = sec.key, key = e._key, ally = e.ally }
                    if id then
                        local l = ctx.placed[id]
                        if not l then l = {}; ctx.placed[id] = l end
                        l[#l + 1] = p
                        for _, a in ipairs(e.alt or {}) do
                            ctx.placed[a] = ctx.placed[a] or {}
                            table.insert(ctx.placed[a], p)
                        end
                    end
                    ctx.entries[#ctx.entries + 1] = { e = e, id = id, group = sec.key, p = p }
                end
            end
        end
    end
    take(ns.BarSections and ns.BarSections(true))
    take(ns.TrackSections and ns.TrackSections(true))
    take(ns.IncomingSections and ns.IncomingSections(true))
    takePreset(ctx)
    local char = ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char()
    if char and type(char.seen) == "table" then ctx.seen = char.seen end
    ctx.put = {}
    for i, p in ipairs((char and type(char.catalogPut) == "table" and char.catalogPut) or {}) do
        if type(p) == "table" and p.k and not ctx.put[p.k] then ctx.put[p.k] = i end
    end
    return ctx
end
local function fits(itemRole, role)
    if itemRole == role then return true end
    if itemRole == "ally" then return ALLY_ROWS[role] == true end
    local groups = ROLE_GROUPS[role]
    if not groups then return false end
    local g = ITEM_GROUP[itemRole]
    if g and groups[g] then return true end
    return (itemRole == "item" and groups.potion) and true or false
end
local function findIn(list, keys, role)
    for _, it in ipairs(list) do
        for _, k in ipairs(keys) do
            if it.k == k and fits(it.role, role) then return it end
        end
    end
    return nil
end
local function registryFor(ctx, hit)
    local groups = ROLE_GROUPS[hit.role]
    if not groups then return nil end
    if not hit.id then
        for _, x in ipairs(ctx.entries) do
            if hit.byName and x.e.byName == hit.byName and groups[x.group] then return x.p end
        end
        return nil
    end
    local best
    for _, p in ipairs(ctx.placed[hit.id] or {}) do
        local ok = groups[p.group]
        if ALLY_ROWS[hit.role] then ok = (p.ally and true) or (hit.role ~= "tbuff" and ok) end
        if ok then
            if findIn(ctx.items, { p.key }, hit.role) then return p end
            best = best or p
        end
    end
    return best
end
local function placedFor(ctx, hit)
    local reg = registryFor(ctx, hit)
    local keys = { hit.ref }
    if hit.byName then keys[#keys + 1] = "name:" .. hit.byName end
    if hit.item and ctx.slotOf[hit.item] then keys[#keys + 1] = ctx.slotOf[hit.item] end
    if hit.row and hit.row.want then keys[#keys + 1] = "want:" .. hit.row.want end
    if reg then
        keys[#keys + 1] = reg.key
        if reg.group == "want" then
            keys[#keys + 1] = "want:" .. reg.key
            keys[#keys + 1] = "want"
        end
    end
    local role = onBoss(hit.row) and placeRole(hit) or hit.role
    local it = findIn(ctx.items, keys, role)
    local gone = (not it) and findIn(ctx.gone, keys, role) or nil
    if not (reg or it or gone) then return nil end
    return { group = reg and reg.group, key = reg and reg.key, ally = reg and reg.ally, on = it ~= nil, item = it,
             gone = gone }
end
local function condition(cond, ctx)
    local prof = ns.profiles and ns.profiles[ctx.class] and ns.profiles[ctx.class][ctx.variant] or {}
    for w in cond:gmatch("[^+]+") do
        if w == "dd" or w == "tank" or w == "heal" then
            if ctx.role ~= w then return false end
        elseif not prof[w] then
            return false
        end
    end
    return true
end
local function recToken(r, row, ctx)
    if r == "*" then return true end
    local n = tonumber(r)
    if n then return CLASS_OF[n] == ctx.class end
    local cls, var = r:match("^(%d+):(.+)$")
    if cls then return CLASS_OF[tonumber(cls)] == ctx.class and var == ctx.variant end
    local c2, cond = r:match("^(%d*)@(.+)$")
    if cond then
        if c2 ~= "" and CLASS_OF[tonumber(c2)] ~= ctx.class then return false end
        return condition(cond, ctx)
    end
    if row.cls ~= 0 and CLASS_OF[row.cls] ~= ctx.class then return false end
    return r == ctx.variant
end
local function recommended(row, ctx)
    if row.item or (row.need and row.need.w) then
        local id = row.item and row.id or (row.srcKind == "i" and row.srcId) or nil
        if id and isWorn(ctx, id) then return true end
    end
    if row.rec then
        for _, r in ipairs(row.rec) do
            if recToken(r, row, ctx) then return true end
        end
        return false
    end
    return CLASS_OF[row.cls] == ctx.class and row.tab ~= nil and row.tab == ctx.tab
end
local function hitKey(ref, role)
    return ref .. "|" .. (FAMILY[role] or role)
end
local function makeHit(row, id, role, ctx)
    local name, icon, item
    if row then
        name, icon = rowName(row), rowIcon(row)
        if row.item then item = row.id end
    elseif id then
        local n, _, ic = GetSpellInfo(id)
        name, icon = n or ns.T("catalog.spell_n", id), ic
    end
    local sid = (not item) and (id or (row and row.id)) or nil
    local ref = item and ("item:" .. item) or ("spell:" .. tostring(sid))
    return {
        key = hitKey(ref, role), ref = ref, role = role, id = sid, item = item,
        name = name or "?", icon = icon, roleText = roleText(roleKey(row, role)),
        src = row and rowSrc(row) or nil, tags = tagsOf(row, role, ctx.class),
        warn = C.Warn(row, role, ctx), w = 1, h = 1, row = row, score = 4, foreign = alienNeed(row, ctx) or nil,
    }
end
local function match(hit, q)
    if q.spell and not q.link then
        if hit.id == q.spell then return 0 end
        for _, a in ipairs((hit.row and hit.row.alt) or {}) do
            if a == q.spell then return 0 end
        end
        for _, a in ipairs(hit.twins or {}) do
            if a == q.spell then return 0 end
        end
        return nil
    end
    if q.fold == "" then return 4 end
    local best = score(hit.fold, q.fold)
    local b = hit.bossFold and score(hit.bossFold, q.fold)
    if b and (not best or b + 3 < best) then best = b + 3 end
    local s = score(hit.row and hit.row.srcFold or (hit.src and ns.Fold(hit.src)), q.fold)
    if s and (not best or s + 3 < best) then best = s + 3 end
    s = score(roleFolded(roleKey(hit.row, hit.role)), q.fold)
    if s and (not best or s + 3 < best) then best = s + 3 end
    return best
end
local function tagged(hit, tags)
    if not tags then return true end
    for t, on in pairs(tags) do
        if on and not hit.tags[t] then return false end
    end
    return true
end
local function anyTag(tags)
    if not tags then return false end
    for _, on in pairs(tags) do if on then return true end end
    return false
end
local function widgetSize(name, def)
    if def then return ns.Widget.Size(name) end
    return 1, 1
end
local function widgetTitle(name, def)
    if def and def.title then return def.title end
    if def and def.label and ns.L[def.label] then return ns.T(def.label) end
    local key = "catalog.widget." .. name
    if ns.L[key] then return ns.T(key) end
    return name
end
local function widgetHit(name, rows, def, ctx)
    local covers, cls = {}, nil
    for _, row in ipairs(rows) do
        covers[(row.item and "item:" or "spell:") .. row.id] = true
        if cls == nil then cls = row.cls elseif cls ~= row.cls then cls = 0 end
    end
    for _, r in ipairs((def and def.covers) or {}) do covers[type(r) == "number" and ("spell:" .. r) or r] = true end
    local class = (def and def.class) or (cls and cls ~= 0 and CLASS_OF[cls]) or nil
    local avail = class ~= nil and class == ctx.class
    if def and type(def.avail) == "function" then
        local ok, v = pcall(def.avail)
        avail = ok and v and true or false
    end
    local icon = def and def.icon
    if type(icon) == "number" then icon = select(3, GetSpellInfo(icon)) end
    if not icon and rows[1] then icon = rowIcon(rows[1]) end
    local w, h = widgetSize(name, def)
    local ref = "widget:" .. name
    local warn = (class and class ~= ctx.class) and "class" or nil
    local watch = (def and def.watchOnly and class and class ~= ctx.class) and true or false
    if watch then avail, warn = false, nil end
    return {
        key = hitKey(ref, "widget"), ref = ref, role = "widget", name = widgetTitle(name, def), icon = icon,
        roleText = roleText(watch and "watch" or "widget"), tags = { widget = true }, w = w, h = h, covers = covers,
        avail = avail, warn = warn,
        personal = (def and def.personal) and true or nil, general = (def and def.general) and true or nil,
        views = def and #ns.Widget.Views(name) or 0,
        many = (def and def.many) and true or nil,
    }
end
local function categorize(ctx, hit)
    if hit.role == "widget" then
        hit.onBlock = (not hit.many and findIn(ctx.items, { hit.ref }, "widget")) and true or nil
        if hit.onBlock then return "preset" end
        if hit.personal and hit.avail then return "mine" end
        if hit.general and hit.avail then return "general" end
        return hit.avail and "rec" or "rest"
    end
    local p = placedFor(ctx, hit)
    hit.onBlock = (p and p.on) or nil
    if hit.own then return "own" end
    if p and (p.on or p.gone) then return "preset" end
    if p then return "rec" end
    if hit.role ~= "act" and hit.row and recommended(hit.row, ctx) then return "rec" end
    local s = hit.id and ctx.seen[hit.id]
    if s then
        hit.seenAt = type(s) == "table" and s.t or nil
        return "recent"
    end
    return "rest"
end
local seenNames = {}
local function resolveName(text, fold)
    local id = ns.MyProcs and ns.MyProcs.Resolve and ns.MyProcs.Resolve(text)
    if id then return id end
    for _, unit in ipairs({ "player", "target" }) do
        for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
            for i = 1, 40 do
                local n, _, _, _, _, _, _, _, _, _, sid = UnitAura(unit, i, filter)
                if not n then break end
                if sid and ns.Fold(n) == fold then return sid end
            end
        end
    end
    local char = ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char()
    for sid in pairs((char and type(char.seen) == "table" and char.seen) or {}) do
        local n = seenNames[sid]
        if n == nil then
            local name = GetSpellInfo(sid)
            n = name and ns.Fold(name) or false
            seenNames[sid] = n
        end
        if n and n == fold then return sid end
    end
    return nil
end
local function itemHit(id, link, ctx)
    local spell = GetItemSpell(link or ("item:" .. id))
    return {
        key = hitKey("item:" .. id, "gear"), ref = "item:" .. id, role = "gear", item = id, name = itemName(id),
        icon = GetItemIcon and GetItemIcon(id), roleText = roleText("gear"), tags = { gear = true },
        w = 1, h = 1, own = true, cat = "own", score = 0, byName = spell,
        src = spell and ns.T("catalog.src.use", spell) or nil, warn = (not ctx.worn[id]) and "worn" or nil,
    }
end
function C.ItemHit(id, link)
    return itemHit(id, link, context())
end
local GCD = 1.5
local function bookRole(id)
    local f = ns.Facts and ns.Facts.Of and ns.Facts.Of(id)
    if f and type(f.cd) == "number" and f.cd > GCD then return "cd" end
    return "act"
end
local function ownHits(hits, ctx, q, seen)
    local function add(id, name, role, note)
        local ref = id and ("spell:" .. id) or ("name:" .. name)
        local key = hitKey(ref, role)
        if seen[key] then return end
        seen[key] = true
        local h
        if id then
            h = makeHit(nil, id, role, ctx)
            if not GetSpellInfo(id) then h.warn = "missing" end
        else
            h = { key = key, ref = ref, role = role, byName = name, name = name, roleText = roleText(role),
                  tags = tagsOf(nil, role, ctx.class), w = 1, h = 1 }
        end
        h.own, h.cat, h.score, h.src = true, "own", 0, note
        local p = placedFor(ctx, h)
        h.onBlock = (p and p.on) or nil
        hits[#hits + 1] = h
    end
    if q.spell then
        add(q.spell, nil, "proc", ns.T("catalog.own"))
        add(q.spell, nil, "dot", ns.T("catalog.own"))
        if IsSpellKnown and IsSpellKnown(q.spell) then add(q.spell, nil, "cd", ns.T("catalog.own")) end
        return
    end
    if q.item then
        local key = hitKey("item:" .. q.item, "gear")
        if seen[key] then return end
        seen[key] = true
        local h = itemHit(q.item, q.link, ctx)
        local p = placedFor(ctx, h)
        h.onBlock = (p and p.on) or nil
        hits[#hits + 1] = h
        return
    end
    if #q.text < NAME_MIN or q.text:sub(1, 1) == "#" then return end
    local id = resolveName(q.text, q.fold)
    if id then
        add(id, nil, "proc", ns.T("catalog.byname_found"))
        add(id, nil, "dot", ns.T("catalog.byname_found"))
    else
        add(nil, q.text, "proc", ns.T("catalog.byname"))
        add(nil, q.text, "dot", ns.T("catalog.byname"))
    end
end
local snap
local function readBook(o)
    local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    local book = BOOKTYPE_SPELL or "spell"
    local byName = {}
    for tab = 1, tabs do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for i = (offset or 0) + 1, (offset or 0) + (count or 0) do
            local name = GetSpellName(i, book)
            if name then
                o.bookOk = true
                local fold = ns.Fold(name)
                o.bookNames[fold] = true
                local link = GetSpellLink and GetSpellLink(i, book)
                local id = link and tonumber(link:match("spell:(%d+)"))
                if id then o.book[id] = true end
                local passive = IsPassiveSpell and IsPassiveSpell(i, book)
                if id and not passive and (tab > 1 or tabs == 1) then
                    local at = byName[fold]
                    if at then
                        if id > at.id then at.id = id end
                    else
                        at = { id = id, name = name }
                        byName[fold] = at
                        o.bookList[#o.bookList + 1] = at
                    end
                end
            end
        end
    end
end
local function readTalents(o)
    o.group = (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    if not (GetNumTalentTabs and GetNumTalents and GetTalentInfo) then return end
    local groups = (GetNumTalentGroups and GetNumTalentGroups()) or 1
    for g = 1, math.max(groups, 1) do
        local t = {}
        o.tal[g] = t
        for tab = 1, GetNumTalentTabs() do
            for i = 1, GetNumTalents(tab) do
                local name, _, _, _, rank = GetTalentInfo(tab, i, false, false, g)
                if name then t[ns.Fold(name)] = rank or 0 end
            end
        end
    end
end
local function linkItem(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
local function readItems(o)
    for _, slot in ipairs(WEAR_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        local id = linkItem(link)
        if id then o.wornAll[id] = true end
        if id and (TRINKET_SLOT[slot] or GetItemSpell(link)) then o.worn[id] = link end
    end
    if not (GetContainerNumSlots and GetContainerItemLink) then return end
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local link = GetContainerItemLink(bag, slot)
            local id = linkItem(link)
            if id and not o.worn[id] and not o.bag[id] and GetItemSpell(link) then o.bag[id] = link end
        end
    end
end
local originData
function C.Forget()
    snap = nil
    originData = nil
end
local forget = CreateFrame("Frame")
for _, e in ipairs({ "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED",
                     "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "SKILL_LINES_CHANGED" }) do
    forget:RegisterEvent(e)
end
forget:SetScript("OnEvent", C.Forget)
local function owned()
    if snap then return snap end
    snap = { book = {}, bookNames = {}, bookList = {}, bookOk = false, tal = {}, group = 1, worn = {}, bag = {}, wornAll = {} }
    readBook(snap)
    readTalents(snap)
    readItems(snap)
    return snap
end
local function talentLevel(name)
    if not name then return nil end
    local o = owned()
    local fold = ns.Fold(name)
    local r = o.tal[o.group] and o.tal[o.group][fold]
    if r and r > 0 then return "spec" end
    for g, t in pairs(o.tal) do
        if g ~= o.group and (t[fold] or 0) > 0 then return "char" end
    end
    return nil
end
local function inBook(id, name)
    local o = owned()
    if not o.bookOk then return true end
    if id and o.book[id] then return true end
    return name ~= nil and o.bookNames[ns.Fold(name)] == true
end
local function spellLevel(id)
    if not id then return nil end
    local name = GetSpellInfo(id)
    local t = talentLevel(name)
    if t then return t end
    if inBook(id, name) then return "spec" end
    return nil
end
local function haveItem(id)
    if not id then return false end
    local o = owned()
    if o.wornAll[id] or o.bag[id] then return true end
    return ((GetItemCount and GetItemCount(id)) or 0) > 0
end
local function rowItems(row)
    if row.item and haveItem(row.id) then return true end
    if row.srcKind == "i" and haveItem(row.srcId) then return true end
    for _, i in ipairs(row.altItems or {}) do
        if haveItem(i) then return true end
    end
    return false
end
local SKILL_SPELL = { Eng = 4036, Alch = 2259, Bs = 2018, Ench = 7411, Ins = 45357, Jc = 25229, Lw = 2108, Tail = 3908,
                      Herb = 2366, Min = 2575, Skin = 8613 }
local function hasSkill(code)
    local id = type(code) == "string" and SKILL_SPELL[code]
    if not id then return true end
    local o = owned()
    if o.skills == nil then
        o.skills = {}
        for i = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
            local name = GetSkillLineInfo(i)
            if name then o.skills[name] = true end
        end
    end
    local name = GetSpellInfo(id)
    return name ~= nil and o.skills[name] == true
end
local function setWorn(row)
    local need = row.need
    local set = (row.srcKind == "S" and row.srcId) or (need and tonumber(need.S)) or nil
    local items = set and ns.gearSetItems and ns.gearSetItems[set]
    if not items then return false end
    local worn = owned().wornAll
    for _, id in ipairs(items) do
        if worn[id] then return true end
    end
    return false
end
local function itemRow(row)
    local k = row.srcKind
    return row.item or k == "i" or k == "S" or k == "e" or (row.need ~= nil and (row.need.w ~= nil or row.need.S ~= nil))
end
local function rowLevel(row, ctx)
    if row.tags and row.tags.boss and row.sub and row.sub:match("^boss:") then return "boss" end
    local need = row.need
    if alienNeed(row, ctx) then return "all" end
    if row.srcKind == "r" or (need and need.r) then return "every" end
    if need and need.p then return hasSkill(need.p) and "every" or "all" end
    local cls = CLASS_OF[row.cls]
    if cls and cls ~= ctx.class then return "all" end
    if itemRow(row) then
        if rowItems(row) or setWorn(row) then return "items" end
        if row.srcKind == "e" and ns.Avail.HasEnchant(row.srcId) then return "items" end
        if row.srcKind == "S" and cls then return "char" end
        return "all"
    end
    if not cls then return "all" end
    local k = row.srcKind
    if k == "b" then return spellLevel(row.id) or "all" end
    if k == "t" or k == "s" then return spellLevel(row.srcId) or "all" end
    if owned().book[row.id] then return "spec" end
    if row.tab and ctx.tab and row.tab ~= ctx.tab then return "char" end
    return "spec"
end
local function passScope(level, opt, tags)
    if not level then return true end
    if level == "boss" then return (opt.scope or "all") == "all" or (tags ~= nil and tags.boss == true) end
    local pass = SCOPE_PASS[opt.scope or "all"]
    if not pass then return true end
    return pass[level] == true
end
function C.ForeignForm(h)
    local row = h.row
    return h.role ~= "widget" and row ~= nil and row.kind == "f" and h.tags.class == true and not h.tags.raid
end
function C.Hidden(h)
    return C.ForeignForm(h) or h.foreign == true
end
local function before(a, b)
    if a.score ~= b.score then return a.score < b.score end
    local wa, wb = a.warn and 1 or 0, b.warn and 1 or 0
    if wa ~= wb then return wa < wb end
    if a.cat == "recent" and (a.seenAt or 0) ~= (b.seenAt or 0) then return (a.seenAt or 0) > (b.seenAt or 0) end
    if a.name ~= b.name then return a.name < b.name end
    return a.key < b.key
end
local function widgetsFirst(list)
    local out, used = {}, {}
    for _, w in ipairs(list) do
        if w.role == "widget" and not used[w] then
            used[w] = true
            out[#out + 1] = w
            for _, h in ipairs(list) do
                if not used[h] and h.role ~= "widget" and w.covers[h.ref] then
                    used[h] = true
                    out[#out + 1] = h
                end
            end
        end
    end
    for _, h in ipairs(list) do
        if not used[h] then out[#out + 1] = h end
    end
    return out
end
local function bossPass(h, opt, tags)
    if not (tags and tags.boss) then return true end
    if not h.boss then return false end
    if opt.boss then return h.boss == opt.boss end
    if opt.raid then return ns.Encounter.RaidOf(h.boss) == opt.raid end
    return true
end
local function bagHit(id, link, ctx)
    local equip = select(9, GetItemInfo(link))
    if equip and equip ~= "" then
        local h = itemHit(id, link, ctx)
        h.own, h.cat, h.score = nil, nil, 4
        return h
    end
    local spell = GetItemSpell(link)
    return {
        key = hitKey("item:" .. id, "item"), ref = "item:" .. id, role = "item", item = id, name = itemName(id),
        icon = GetItemIcon and GetItemIcon(id), roleText = roleText("item"), tags = { consumable = true },
        w = 1, h = 1, score = 4, src = spell and ns.T("catalog.src.use", spell) or nil,
    }
end
local WANT_ORDER = { stamina = 1, wild = 2, kings = 2, spirit = 3, intellect = 4, shadow_prot = 5 }
local function bookAt()
    local at = { id = {}, fold = {} }
    for i, b in ipairs(owned().bookList) do
        at.id[b.id] = i
        at.fold[ns.Fold(b.name)] = at.fold[ns.Fold(b.name)] or i
    end
    return at
end
local function placeIn(at, row, id, fold)
    local i = id and at.id[id]
    if not i and row then
        for _, a in ipairs(row.alt or {}) do
            i = at.id[a]
            if i then break end
        end
        if not i and row.srcId then i = at.id[row.srcId] end
    end
    if not i and fold then i = at.fold[fold] end
    return i
end
local function orderHit(h, at)
    local row = h.row
    local lead = row
    if row and row.pairGroup then
        for _, x in ipairs(C.Ensure().byId[row.pairGroup] or {}) do
            if x.kind == "r" then lead = x; break end
        end
        h.pairSub = 1
    end
    h.fn = lead and lead.want and WANT_ORDER[lead.want] or nil
    if lead and lead ~= row then
        h.bookAt = placeIn(at, lead, lead.id, lead.fold)
        h.lead = rowName(lead)
    else
        h.bookAt = placeIn(at, row, h.id, h.fold)
    end
end
local function formFamily(rows)
    for _, row in ipairs(rows or {}) do
        if row.kind == "f" then return true end
    end
    return false
end
local function seenJunk(h)
    return h.seenOnly == true or (h.row ~= nil and h.row.srcKind == "R")
end
local function twinKey(h)
    if h.role == "widget" or h.item or not h.id then return nil end
    local cls = (h.row and h.row.cls) or 0
    return (h.fold or "") .. "|" .. (FAMILY[h.role] or h.role) .. "|" .. cls .. "|" .. tostring(h.boss)
end
local function mergeTwins(hits)
    local lead = {}
    for _, h in ipairs(hits) do
        local k = twinKey(h)
        if k then
            local rank = (h.onBlock and 0) or (seenJunk(h) and 2) or 1
            local l = lead[k]
            if not l or rank < l.rank then lead[k] = { h = h, rank = rank } end
        end
    end
    local out = {}
    for _, h in ipairs(hits) do
        local k = twinKey(h)
        local l = k and lead[k]
        if l and l.h ~= h and seenJunk(h) and not h.onBlock then
            l.h.twins = l.h.twins or {}
            l.h.twins[#l.h.twins + 1] = h.id
        else
            out[#out + 1] = h
        end
    end
    return out
end
function C.Loose(h)
    return h.seenOnly == true or h.bossLoose == true
end
function C.Search(q, tags, opt)
    opt = opt or {}
    local base = C.Ensure()
    local ctx = context()
    local query = parseQuery(q)
    local scoped = opt.scope ~= nil and opt.scope ~= "all"
    local browse = query.fold == "" and not query.spell and not query.item and not anyTag(tags) and not scoped and not opt.flat
    local named = query.fold ~= "" or query.spell or query.item
    local hits, seen = {}, {}
    local at = bookAt()
    local exact = false
    local coveredId, coveredName = {}, {}
    local function offer(h)
        if seen[h.key] then return end
        if not passScope(h.level, opt, tags) or not bossPass(h, opt, tags) then return end
        if not named and not opt.flat and C.Hidden(h) then return end
        seen[h.key] = true
        if h.fold == nil then h.fold = (h.row and h.row.fold) or ns.Fold(h.name) end
        if query.fold ~= "" and h.fold == query.fold then exact = true end
        local s = match(h, query)
        if not s or not tagged(h, tags) then return end
        h.score = s
        h.cat = categorize(ctx, h)
        h.putAt = ctx.put[h.key]
        if h.cat == "rest" and h.wornHit then h.cat = "rec" end
        if browse and not BROWSE[h.cat] then return end
        orderHit(h, at)
        hits[#hits + 1] = h
    end
    for _, x in ipairs(ctx.entries) do
        local role = GROUP_ROLE[x.group] or "proc"
        if x.group == "proc" and x.e.harm then role = "harm" end
        if x.e.ally then role = x.e.harm and "dot" or "tbuff" end
        local h
        if x.id then
            local row, id = nil, x.id
            for _, r in ipairs(base.byId[x.id] or {}) do
                if FAMILY[C.Roles(r)[1]] == FAMILY[role] then row = r; break end
            end
            if not row then
                for _, r in ipairs(base.byAura[x.id] or {}) do
                    if FAMILY[C.Roles(r)[1]] == FAMILY[role] then row = r; break end
                end
                if row then
                    id = row.id
                    ctx.placed[id] = ctx.placed[id] or {}
                    table.insert(ctx.placed[id], x.p)
                end
            end
            h = makeHit(row, id, role, ctx)
        else
            local ref = "name:" .. x.e.byName
            h = { key = hitKey(ref, role), ref = ref, role = role, byName = x.e.byName, name = x.e.byName,
                  roleText = roleText(role), tags = tagsOf(nil, role, ctx.class), w = 1, h = 1, score = 4 }
        end
        if x.id then coveredId[x.id] = true end
        coveredName[h.fold or ns.Fold(h.name)] = true
        h.level = "spec"
        offer(h)
    end
    for _, row in ipairs(base.rows) do
        rowName(row)
        rowSrc(row)
        if not row.item then
            coveredId[row.id] = true
            coveredName[row.fold] = true
        end
        local level = rowLevel(row, ctx)
        local enc = level == "boss" and ns.Encounter.BossOfSpell(row.id) or nil
        local loose = (level == "boss" and not enc) or (row.tags ~= nil and row.tags.boss == true and level ~= "boss")
        do
            for _, role in ipairs(C.Roles(row)) do
                local ref = (row.item and "item:" or "spell:") .. row.id
                if not seen[hitKey(ref, role)] then
                    local h = makeHit(row, row.id, role, ctx)
                    h.level = level
                    if level == "char" and (not h.warn or h.warn == "spec") and not itemRow(row) then h.warn = "branch" end
                    if enc then
                        h.boss = enc
                        h.bossFold = ns.Fold(ns.Encounter.Name(enc))
                        h.roleText = ns.T("catalog.role_boss_of", ns.Encounter.Name(enc))
                        h.src = (not opt.boss) and ns.Encounter.RaidName(ns.Encounter.RaidOf(enc)) or nil
                    elseif loose then
                        h.bossLoose = true
                        if level == "boss" then h.roleText = roleText("boss") end
                    end
                    offer(h)
                end
            end
        end
    end
    local mine = owned()
    for _, b in ipairs(mine.bookList) do
        local fold = ns.Fold(b.name)
        if not coveredId[b.id] and not coveredName[fold] then
            local h = makeHit(nil, b.id, bookRole(b.id), ctx)
            h.level = "spec"
            offer(h)
        end
    end
    for id, link in pairs(mine.worn) do
        local h = itemHit(id, link, ctx)
        h.own, h.cat, h.score, h.level, h.wornHit = nil, nil, 4, "items", true
        offer(h)
    end
    for id, link in pairs(mine.bag) do
        local h = bagHit(id, link, ctx)
        h.level = "items"
        offer(h)
    end
    for id, s in pairs(ctx.seen) do
        if type(id) == "number" and not base.byAura[id] then
            local role = (s.w == "t" and "dot") or (s.w == "h" and "harm") or "proc"
            if not seen[hitKey("spell:" .. id, role)] then
                local h = makeHit(nil, id, role, ctx)
                h.level = (type(s) == "table" and s.m) and "spec" or "char"
                h.seenOnly = true
                offer(h)
            end
        end
    end
    hits = mergeTwins(hits)
    local defs = {}
    for _, name in ipairs((ns.Widget and ns.Widget.List and ns.Widget.List()) or {}) do
        defs[name] = ns.Widget.Get(name)
    end
    local widgets, order = {}, {}
    for _, name in ipairs(base.widgetOrder) do order[#order + 1] = name end
    for name in pairs(defs) do
        if not base.widgets[name] then order[#order + 1] = name end
    end
    for _, name in ipairs(order) do
        local h = widgetHit(name, base.widgets[name] or {}, defs[name], ctx)
        widgets[#widgets + 1] = h
        seen[h.key] = true
        h.fold = ns.Fold(h.name)
        local s = match(h, query)
        if not s then
            for _, x in ipairs(hits) do
                if h.covers[x.ref] and not C.Hidden(x) and (not s or x.score < s) then s = x.score end
            end
        end
        h.level = (h.avail and "spec") or (h.warn == nil and "char") or "all"
        if h.warn == "class" and not defs[name] and formFamily(base.widgets[name]) then s = nil end
        if not defs[name] then s = nil end
        if s and tagged(h, tags) and passScope(h.level, opt, tags) then
            h.score = s
            h.cat = categorize(ctx, h)
            h.putAt = ctx.put[h.key]
            if not (browse and not BROWSE[h.cat]) then hits[#hits + 1] = h end
        end
    end
    local own = {}
    if not exact or query.spell or query.item then ownHits(own, ctx, query, seen) end
    for _, w in ipairs(widgets) do
        if w.cat and w.score and not w.onBlock then
            for _, h in ipairs(hits) do
                if h ~= w and w.covers[h.ref] and h.cat ~= "preset" and CAT_RANK[h.cat] < CAT_RANK[w.cat] then w.cat = h.cat end
            end
        end
    end
    local byCat = {}
    for _, cat in ipairs(C.CATS) do byCat[cat] = {} end
    for _, h in ipairs(hits) do
        local l = byCat[h.cat]
        if l then l[#l + 1] = h end
    end
    local out = { groups = {}, counts = {}, total = 0 }
    local ownFirst = query.spell or query.item
    if #own > 0 and ownFirst then out.groups[1] = { cat = "own", rows = own, count = #own } end
    for _, cat in ipairs(C.CATS) do
        local l = byCat[cat]
        table.sort(l, before)
        l = widgetsFirst(l)
        local n = #l
        local cap = (opt.flat and n) or ((browse and cat == "recent") and C.RECENT_BROWSE) or C.GROUP_MAX
        for i = n, cap + 1, -1 do l[i] = nil end
        out.counts[cat] = n
        out.total = out.total + n
        if n > 0 then out.groups[#out.groups + 1] = { cat = cat, rows = l, count = n } end
    end
    if #own > 0 and not ownFirst then out.groups[#out.groups + 1] = { cat = "own", rows = own, count = #own } end
    return out
end
function C.PassScope(level, scope)
    return passScope(level, { scope = scope }, nil)
end
C.GROUPS = {
    { key = "perm" },
    { key = "forms" },
    { key = "seals", cls = { PALADIN = true } },
    { key = "totems", cls = { SHAMAN = true } },
    { key = "armor", cls = { MAGE = true, WARLOCK = true } },
    { key = "shield", cls = { PRIEST = true, MAGE = true, WARLOCK = true, SHAMAN = true, DEATHKNIGHT = true, PALADIN = true } },
    { key = "weapon", cls = { SHAMAN = true } },
    { key = "poisons", cls = { ROGUE = true } },
    { key = "stones", cls = { WARLOCK = true } },
    { key = "pet", cls = { HUNTER = true, WARLOCK = true, DEATHKNIGHT = true } },
    { key = "curse", cls = { WARLOCK = true } },
    { key = "judgement", cls = { PALADIN = true } },
    { key = "self" },
    { key = "ally" },
    { key = "cd" },
    { key = "target" },
    { key = "proc" },
    { key = "act", fold = true },
}
local CLASS_W = { "seals", "judgement", "totems", "poisons", "stones", "curse", "armor", "pet" }
local function groupFor(key, class)
    for _, g in ipairs(C.GROUPS) do
        if g.key == key then return g.cls == nil or (class ~= nil and g.cls[class] == true) end
    end
    return false
end
local function formTwin(row)
    for _, x in ipairs(C.Ensure().byId[row.id] or {}) do
        if x.underCd and x.kind == "f" then return true end
    end
    return false
end
local PERM_ROLES = { self = true, raid = true }
function C.Perm(h)
    local row = h and h.row
    return h.role ~= "widget" and row ~= nil and row.tags ~= nil and row.tags.perm == true and PERM_ROLES[h.role] == true
end
function C.WidgetSec(h)
    if h.general then return "widgets.general" end
    if h.avail then return "widgets.mine" end
    return "widgets.other"
end
function C.GroupsOf(h, class)
    if h.role == "widget" then return {} end
    local row, r = h.row, h.role
    local tags = (row and row.tags) or {}
    if tags.hidden then return {} end
    local up = r == "cd" and tags.up == true
    local cg = C.Perm(h) and "perm" or nil
    local ws = {}
    if row and not cg then
        for _, w in ipairs(row.widgets or {}) do ws[w] = true end
        for _, k in ipairs(CLASS_W) do
            if ws[k] and groupFor(k, class) then cg = k; break end
        end
        if not cg and row.sub == "shield" and groupFor("shield", class) then cg = "shield" end
        if not cg and (r == "weapon" or row.sub == "weapon") and groupFor("weapon", class) then cg = "weapon" end
        if not cg and (row.kind == "f" or ws.forms) and r ~= "cd" and r ~= "proc" then cg = "forms" end
        if not cg and up and formTwin(row) then cg = "forms" end
    end
    if not cg and r == "pet" and groupFor("pet", class) then cg = "pet" end
    local out = {}
    local function add(g)
        for _, x in ipairs(out) do if x == g then return end end
        out[#out + 1] = g
    end
    if cg then add(cg) end
    if cg == "shield" and row.where == "a" then add("ally") end
    if r == "cd" then
        add("cd")
        if up then add("self") end
    elseif r == "harm" and row and (row.srcKind == "s" or row.srcKind == "t") then
        add("cd")
    elseif r == "proc" or r == "harm" then
        add("proc")
    elseif r == "dot" and not (row and row.where == "a") then
        add("target")
    elseif not cg then
        if r == "act" then
            add("act")
        elseif r == "dot" then
            add("ally")
        elseif r == "self" or r == "weapon" or r == "pet" then
            add("self")
            if row and row.where == "g" and row.kind ~= "f" then add("ally") end
        elseif r == "tbuff" then
            if row and row.where == "a" and row.kind == "b" and row.srcKind == "b" and not (row.tab and ws.tank) then add("self") end
            add("ally")
            if row and row.kind == "p" then add("proc") end
        elseif r == "raid" then
            if row and row.pairGroup then add("self") end
            add("ally")
        end
    end
    if tags.onAlly then add("ally") end
    return out
end
local function groupBefore(a, b)
    local fa, fb = a.fn or 9, b.fn or 9
    if fa ~= fb then return fa < fb end
    local ba, bb = a.bookAt or 9999, b.bookAt or 9999
    if ba ~= bb then return ba < bb end
    local la, lb = a.lead or a.name or "", b.lead or b.name or ""
    if la ~= lb then return la < lb end
    local pa, pb = a.pairSub or 0, b.pairSub or 0
    if pa ~= pb then return pa < pb end
    if a.name ~= b.name then return (a.name or "") < (b.name or "") end
    return (a.key or "") < (b.key or "")
end
do
    local TREE = {
        { key = "my", groups = true },
        { key = "raid", tag = "raid", anyScope = true },
        { key = "consumable", tag = "consumable" },
        { key = "gear", tag = "gear" },
        { key = "widgets", kids = { { key = "widgets.mine" }, { key = "widgets.general" }, { key = "widgets.other" } } },
        { key = "boss", bosses = true },
        { key = "preset", anyScope = true },
        { key = "recent", anyScope = true },
        { key = "pvp", tag = "pvp" },
        { key = "class" },
        { key = "other" },
    }
    local STATE_LEAF = { preset = true, recent = true }
    local ITEM_ROLES = { item = true, gear = true }
    local NOT_BUTTON = { act = true, dot = true, harm = true, proc = true }
    local function mineClass(h)
        if h.role == "widget" or h.tags.class or h.boss or ITEM_ROLES[h.role] or h.foreign or h.seenOnly then return false end
        local row = h.row
        return row == nil or row.cls ~= 0 or row.srcKind == "r"
    end
    local function inLeaf(key, tag, h)
        local w = h.role == "widget"
        if key == "widgets.mine" or key == "widgets.general" or key == "widgets.other" then return w and C.WidgetSec(h) == key end
        if key == "preset" then return h.onBlock == true end
        if key == "recent" then return h.putAt ~= nil end
        if key == "other" then
            return not w and h.tags.class ~= true and h.row ~= nil and h.row.tags ~= nil and h.row.tags.hidden == true
        end
        if key == "class" then return not w and h.tags.class == true end
        if key == "my.talent" then
            return mineClass(h) and h.tags.talent == true and not NOT_BUTTON[h.role] and h.row ~= nil and h.row.srcKind == "b"
        end
        if tag then return not w and not h.boss and h.tags[tag] == true end
        return false
    end
    function C.Sections(hits, opt)
        opt = opt or {}
        local out = { list = {}, byKey = {} }
        local raidOf = {}
        local class = opt.class
        if not class then
            local _, c = UnitClass("player")
            class = c
        end
        local function node(key, depth, parent)
            local s = { key = key, depth = depth, parent = parent, kids = {}, hits = {}, n = 0, all = 0 }
            out.list[#out.list + 1] = s
            out.byKey[key] = s
            if parent then
                local p = out.byKey[parent]
                p.kids[#p.kids + 1] = key
            end
            return s
        end
        local leaves = {}
        for _, t in ipairs(TREE) do
            local top = node(t.key, 0, nil)
            top.anyScope = t.anyScope
            if t.groups then
                for _, g in ipairs(C.GROUPS) do
                    if g.cls == nil or (class and g.cls[class]) then
                        local s = node("my." .. g.key, 1, t.key)
                        s.group, s.fold = g.key, g.fold
                    end
                end
                node("my.talent", 1, t.key)
                leaves[#leaves + 1] = { key = "my.talent" }
            elseif t.kids then
                for _, k in ipairs(t.kids) do
                    node(k.key, 1, t.key)
                    leaves[#leaves + 1] = { key = k.key, tag = k.tag }
                end
            elseif t.bosses then
                top.anyScope = true
                for _, r in ipairs(opt.raids or {}) do
                    local rk = "boss." .. r.key
                    local rs = node(rk, 1, "boss")
                    rs.raid, rs.anyScope = r.key, true
                    for _, b in ipairs(r.bosses or {}) do
                        local bs = node(rk .. "." .. b, 2, rk)
                        bs.raid, bs.boss, bs.anyScope = r.key, b, true
                        raidOf[b] = r.key
                    end
                end
            else
                leaves[#leaves + 1] = { key = t.key, tag = t.tag }
            end
        end
        local function put(key, h, pass, seen, leafOnly)
            while key and not seen[key] do
                seen[key] = true
                local s = out.byKey[key]
                s.all = s.all + 1
                if pass or s.anyScope then
                    s.n = s.n + 1
                    s.hits[#s.hits + 1] = h
                end
                key = (not leafOnly) and s.parent or nil
            end
        end
        for _, h in ipairs(hits) do
            local pass = C.PassScope(h.level, opt.scope)
            local seen = {}
            local hide = (not opt.forms and C.Hidden(h)) or C.Loose(h)
            local tucked = h.role ~= "widget" and h.row ~= nil and h.row.tags ~= nil and h.row.tags.hidden == true
            for _, l in ipairs(leaves) do
                local shut = (hide and not STATE_LEAF[l.key])
                    or (tucked and not STATE_LEAF[l.key] and l.key ~= "class" and l.key ~= "other")
                if inLeaf(l.key, l.tag, h) and not shut then put(l.key, h, pass, seen) end
            end
            if mineClass(h) and not tucked and not C.Loose(h) then
                for _, g in ipairs(C.GroupsOf(h, class)) do
                    local key = "my." .. g
                    local s = out.byKey[key]
                    if s then put(key, h, pass, seen, s.fold) end
                end
            end
            if h.boss then
                local rk = raidOf[h.boss]
                if rk and out.byKey["boss." .. rk .. "." .. h.boss] then
                    put("boss." .. rk .. "." .. h.boss, h, pass, seen)
                else
                    put("boss", h, pass, seen)
                end
            end
        end
        table.sort(out.byKey.recent.hits, function(a, b)
            if a.putAt ~= b.putAt then return a.putAt < b.putAt end
            return a.key < b.key
        end)
        local my = out.byKey.my
        my.groups = {}
        for i = #my.kids, 1, -1 do
            local s = out.byKey[my.kids[i]]
            if s.all == 0 then
                table.remove(my.kids, i)
                out.byKey[s.key] = nil
                for j = #out.list, 1, -1 do
                    if out.list[j] == s then table.remove(out.list, j) end
                end
            end
        end
        for _, k in ipairs(my.kids) do
            local s = out.byKey[k]
            if s.group then
                table.sort(s.hits, groupBefore)
                my.groups[#my.groups + 1] = s
            end
        end
        return out
    end
    function C.SectionOf(s, h)
        for _, x in ipairs(s.list) do
            if #x.kids == 0 and x.key ~= "boss" then
                for _, y in ipairs(x.hits) do
                    if y == h or y.key == h.key then return x.key end
                end
            end
        end
        return nil
    end
end
function C.SectionLabel(s, key)
    local x = s and s.byKey[key]
    if x and x.boss then return ns.Encounter.Name(x.boss) end
    if x and x.raid then return ns.Encounter.RaidName(x.raid) end
    if key == "widgets.mine" then
        local name = UnitClass("player")
        if name then return name end
    end
    local id = key:gsub("%.", "_")
    return ns.T("picker.lib.sec." .. id)
end
local ORIGIN_SKIP = { preset = true, recent = true, boss = true }
local ORIGIN_ROLE = { want = "raid", raid = "raid", gear = "gear", item = "consumable", food = "consumable", widget = "widgets" }
local function originBase()
    if originData then return originData end
    local hits = {}
    for _, g in ipairs(C.Search("", nil, { scope = "all", flat = true }).groups) do
        for _, h in ipairs(g.rows) do hits[#hits + 1] = h end
    end
    local o = { hits = hits, byRef = {}, byId = {}, secOf = {} }
    o.sections = C.Sections(hits, { scope = "all", raids = ns.Encounter.Raids(), forms = true })
    for _, h in ipairs(hits) do
        index(o.byRef, h.ref, h)
        if h.id then
            index(o.byId, h.id, h)
            for _, a in ipairs((h.row and h.row.alt) or {}) do index(o.byId, a, h) end
        end
    end
    for _, x in ipairs(o.sections.list) do
        if #x.kids == 0 and not ORIGIN_SKIP[x.key] then
            for _, h in ipairs(x.hits) do o.secOf[h] = o.secOf[h] or x.key end
        end
    end
    originData = o
    return o
end
local function originHit(o, item)
    local k = tostring(item.k or "")
    local wk = k:match("^want:(.+)$")
    if wk then
        local key = ns.Incoming and ns.Incoming.KeyOf(wk)
        local buff = key and ns.incoming[key]
        for _, id in ipairs((buff and buff.auras) or {}) do
            for _, h in ipairs(o.byId[id] or {}) do
                if h.role == "raid" and o.secOf[h] then return h end
            end
        end
        return nil
    end
    local list = o.byRef[k]
    if not list then
        local id = tonumber(k:match("^spell:(%d+)$"))
        list = id and o.byId[id] or nil
    end
    local first
    for _, h in ipairs(list or {}) do
        if o.secOf[h] then
            if fits(item.role, h.role) or item.role == h.role then return h end
            first = first or h
        end
    end
    return first
end
function C.Origin(item)
    if type(item) ~= "table" or not item.k then return nil end
    local o = originBase()
    local hit = tostring(item.k) ~= "want" and originHit(o, item) or nil
    local sec = hit and o.secOf[hit] or ORIGIN_ROLE[item.role] or "my"
    if not o.sections.byKey[sec] then sec = "my" end
    local parts = {}
    local k = sec
    while k do
        table.insert(parts, 1, C.SectionLabel(o.sections, k))
        k = o.sections.byKey[k] and o.sections.byKey[k].parent
    end
    local row = hit and hit.row
    if (sec == "raid" or sec == "class") and row and row.cls ~= 0 and CLASS_OF[row.cls] then
        parts[#parts + 1] = ns.ClassName(CLASS_OF[row.cls]) or CLASS_OF[row.cls]
    end
    return { sec = sec, key = hit and hit.key or nil, text = table.concat(parts, ns.T("card.origin_sep")) }
end
local function itemFor(hit, p)
    local wk = hit.role == "raid" and hit.row and hit.row.want
    if wk and ns.incoming and ns.incoming[wk] and (hit.tags.class or (p and p.group == "want")) then
        return { k = "want:" .. wk, role = "want" }
    end
    if p and p.key then
        if p.group == "want" then return { k = "want:" .. p.key, role = "want" } end
        return { k = p.key, role = p.ally and "ally" or ns.Legacy.RoleOf(p.group) }
    end
    local role = placeRole(hit)
    if not role then return nil end
    if role == "widget" then return { k = hit.ref, role = "widget", view = hit.view } end
    if hit.item and not hit.id then
        if hit.role == "gear" then return { k = "item:" .. hit.item, role = "gear" } end
        if hit.role == "item" then return { k = "item:" .. hit.item, role = "item" } end
        return nil
    end
    local unit = C.UnitOf(hit.row) or (role == "ally" and "tank" or nil) or (C.ForeignForm(hit) and "target" or nil)
    if hit.id then return { k = "spell:" .. hit.id, role = role, unit = unit, act = (hit.role == "act") or nil } end
    if hit.byName then return { k = "name:" .. hit.byName, role = role, unit = unit } end
    return nil
end
function C.Item(hit)
    if not placeRole(hit) then return nil end
    return itemFor(hit, placedFor(context(), hit))
end
local function blockFor(role, target)
    local Pr = ns.Preset
    if type(target) == "string" and Pr.Block(target) then return target end
    local want = TRACK_ROLE[role] and "track" or "buffs"
    if Pr.Block(want) then return want end
    local blocks = Pr.Blocks()
    for _, b in ipairs(blocks) do
        for _, it in ipairs(b.items) do
            if it.role == role then return b.key end
        end
    end
    return blocks[1] and blocks[1].key or nil
end
function C.Where(hit, target)
    if not placeRole(hit) then return nil end
    local p = placedFor(context(), hit)
    local key
    local on = p and p.on and not hit.many
    if on then
        key = p.item.key
    else
        local item = itemFor(hit, p)
        if not item then return nil end
        key = blockFor(item.role, target)
    end
    local b = key and ns.Preset.Block(key)
    return { block = key, barName = b and ns.Preset.BlockName(b) or nil, placed = on or nil }
end
function C.DeferKey(hit)
    return "catalog:" .. hit.key .. ":" .. hit.role
end
function C.Place(hit, target, cx, cy)
    if not placeRole(hit) then return false, "grid" end
    if InCombatLockdown() then
        ns.DeferKey(C.DeferKey(hit), function() C.Place(hit, target, cx, cy) end)
        return false, "later"
    end
    local p = placedFor(context(), hit)
    if p and p.on and not hit.many then return false, "already", p.item.key, p.item.x, p.item.y end
    local item = itemFor(hit, p)
    if not item then return false, "grid" end
    local key = blockFor(item.role, target)
    if not key then return false, "full" end
    if key ~= target then cx, cy = nil, nil end
    if p and p.gone then
        local x, y, k = ns.Preset.Restore(p.gone.k, p.gone.role, key, cx, cy)
        if x then
            C.NotePut(hit)
            return true, "on", k, x, y
        end
    end
    local x, y, k = ns.Preset.Add(key, item, cx, cy)
    if not x then return false, "full" end
    C.NotePut(hit)
    return true, "added", k, x, y
end
C.RECENT_PUT = 40
function C.NotePut(hit)
    if not (hit and hit.key and ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return end
    local char = ns.Profile.Char()
    if type(char.catalogPut) ~= "table" then char.catalogPut = {} end
    local list = char.catalogPut
    for i = #list, 1, -1 do
        if type(list[i]) ~= "table" or list[i].k == hit.key then table.remove(list, i) end
    end
    table.insert(list, 1, { k = hit.key, t = time() })
    for i = #list, C.RECENT_PUT + 1, -1 do list[i] = nil end
    originData = nil
end
local seenFor
local seenN = 0
local SEEN_W = { player = "p", harm = "h", target = "t" }
local function prune(s)
    local list = {}
    for id, e in pairs(s) do list[#list + 1] = { id = id, t = type(e) == "table" and e.t or 0 } end
    table.sort(list, function(a, b) return a.t < b.t end)
    local n = #list
    local i = 1
    while n > SEEN_KEEP and list[i] do
        s[list[i].id] = nil
        n = n - 1
        i = i + 1
    end
    seenN = n
end
function C.See(key, id, caster)
    local w = SEEN_W[key]
    if not w or not id then return end
    if not (ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return end
    local char = ns.Profile.Char()
    if type(char.seen) ~= "table" then char.seen = {} end
    local s = char.seen
    if s ~= seenFor then
        seenFor, seenN = s, 0
        for _ in pairs(s) do seenN = seenN + 1 end
    end
    local now = time()
    local e = s[id]
    if e then
        if type(e) == "table" and now - (e.t or 0) >= SEEN_TOUCH then e.t = now end
        return
    end
    s[id] = { w = w, m = (caster == "player") or nil, t = now }
    seenN = seenN + 1
    if seenN > C.SEEN_MAX then prune(s) end
end
ns.catalogLoaded = true

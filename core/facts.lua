local _, ns = ...
ns.Facts = {}
local F = ns.Facts
local NUM = "([%d%.,]+)"
local UNIT = "([^%s%d%(%)]+)"
local UNITS = {
    ["с"] = 1, ["сек"] = 1, ["секунд"] = 1, ["секунды"] = 1, ["секунду"] = 1, ["секунда"] = 1,
    ["мин"] = 60, ["минут"] = 60, ["минуты"] = 60, ["минуту"] = 60, ["минута"] = 60,
    ["ч"] = 3600, ["час"] = 3600, ["часа"] = 3600, ["часов"] = 3600,
    s = 1, sec = 1, secs = 1, second = 1, seconds = 1, seg = 1, segundo = 1, segundos = 1,
    min = 60, mins = 60, minute = 60, minutes = 60, minuto = 60, minutos = 60,
    h = 3600, hr = 3600, hrs = 3600, hour = 3600, hours = 3600, hora = 3600, horas = 3600,
}
local TIPS = {
    ruRU = {
        cd = { "^Восстановление:? #N #U$", "^Перезарядка:? #N #U$" },
        itemCd = { "%(Восстановление:? #N #U%)" },
        durLine = { "^Длительность:? #N #U" },
        dur = { "на #N #U", "в течение #N #U" },
        skip = { "восстановлен", "перезаряд", "время", "длительност" },
        instant = { "^Мгновенное действие$", "^Мгновенное$", "^Мгновенно$" },
        channel = { "^Поддерживаемое$", "^Поддерживаемое заклинание$", "^Направляемое$" },
        stacks = { "до #N раз" },
        charges = { "^#N заряд", "^Зарядов:? #N$" },
        use = { "^Использование:", "^Если на персонаже:", "^Вероятность при попадании:" },
    },
    enUS = {
        cd = { "^#N #U cooldown$", "^Cooldown:? #N #U$" },
        itemCd = { "%(#N #U [Cc]ooldown%)" },
        durLine = { "^Duration:? #N #U" },
        dur = { "for #N #U", "over #N #U", "[Ll]asts #N #U" },
        skip = { "cooldown" },
        instant = { "^Instant$", "^Instant cast$" },
        channel = { "^Channeled$" },
        stacks = { "up to #N times" },
        charges = { "^#N [Cc]harges?$" },
        use = { "^Use:", "^Equip:", "^Chance on hit:" },
    },
    esES = {
        cd = { "^[Rr]eutilización:? #N #U$", "^[Rr]eutilización de #N #U$", "^#N #U de reutilización$",
               "^[Tt]iempo de reutilización:? #N #U$" },
        itemCd = { "%(#N #U de reutilización%)", "%([Rr]eutilización:? #N #U%)", "%([Rr]eutilización de #N #U%)" },
        durLine = { "^Duración:? #N #U" },
        dur = { "durante #N #U" },
        skip = { "reutilizaci" },
        instant = { "^Instantáneo$", "^Instantánea$", "^Lanzamiento instantáneo$" },
        channel = { "^Canalizado$", "^Canalizada$" },
        stacks = { "hasta #N veces" },
        charges = { "^#N cargas?$" },
        use = { "^Uso:", "^Equipar:", "^Probabilidad al acertar:" },
    },
}
local ALIAS = { enGB = "enUS", esMX = "esES" }
local RULE_KINDS = { "cd", "itemCd", "durLine", "dur", "instant", "channel", "stacks", "charges", "use" }
local ROLE_KIND = { cd = "cd", act = "cd", dot = "debuff", harm = "debuff", proc = "proc", self = "buff", raid = "buff",
                    weapon = "buff", want = "buff", food = "item", item = "item" }
local LETTER_KIND = { c = "cd", a = "cd", b = "buff", r = "buff", f = "buff", p = "proc", d = "debuff", x = "item", g = "item" }
local POWER = { [-2] = "facts.health", [0] = "facts.mana", [1] = "facts.rage", [2] = "facts.focus",
                [3] = "facts.energy", [6] = "facts.runic" }
local EMPTY = {}
local cache = {}
local cacheFor
local rules
local tip = CreateFrame("GameTooltip", "LazyBuffBarFactsTip", nil, "GameTooltipTemplate")
local function fill(p)
    return (p:gsub("#N", function() return NUM end):gsub("#U", function() return UNIT end))
end
local function escape(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end
local function fromFormat(fmt, mul, anchored)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    fmt = fmt:gsub("|4[^;]*;", "\1")
    local out, pos = {}, 1
    while true do
        local s, e, spec = fmt:find("%%[%-%d%.%$]*([dfgs])", pos)
        out[#out + 1] = (escape(fmt:sub(pos, (s or 0) - 1)):gsub("\1", "%%S+"))
        if not s then break end
        out[#out + 1] = (spec == "s" and not mul) and (NUM .. " " .. UNIT) or NUM
        pos = e + 1
    end
    local p = table.concat(out)
    return { p = anchored and ("^" .. p .. "$") or p, mul = mul }
end
local function literal(s, whole)
    if type(s) ~= "string" or s == "" then return nil end
    return { p = "^" .. escape(s) .. (whole and "$" or "") }
end
local function build(code)
    local base = TIPS[ALIAS[code] or code] or TIPS.enUS
    local r = { skip = base.skip or {} }
    for _, kind in ipairs(RULE_KINDS) do
        local list = {}
        for _, p in ipairs(base[kind] or {}) do list[#list + 1] = { p = fill(p) } end
        r[kind] = list
    end
    local function add(kind, rule)
        if rule then table.insert(r[kind], 1, rule) end
    end
    add("cd", fromFormat(SPELL_RECAST_TIME_SEC, 1, true))
    add("cd", fromFormat(SPELL_RECAST_TIME_MIN, 60, true))
    add("cd", fromFormat(SPELL_RECAST_TIME_HOURS, 3600, true))
    add("itemCd", fromFormat(ITEM_COOLDOWN_TOTAL, nil, false))
    add("instant", literal(SPELL_CAST_TIME_INSTANT, true))
    add("instant", literal(SPELL_CAST_TIME_INSTANT_NO_MANA, true))
    add("channel", literal(SPELL_CAST_CHANNELED, true))
    add("charges", fromFormat(ITEM_SPELL_CHARGES, 1, true))
    add("use", literal(ITEM_SPELL_TRIGGER_ONUSE, false))
    add("use", literal(ITEM_SPELL_TRIGGER_ONEQUIP, false))
    add("use", literal(ITEM_SPELL_TRIGGER_ONPROC, false))
    return r
end
local function number(a)
    if not a then return nil end
    local s = tostring(a):gsub("[%.,]+$", "")
    s = s:gsub(",", ".")
    return tonumber(s)
end
local function seconds(a, u, mul)
    local n = number(a)
    if not n or n <= 0 then return nil end
    local k = mul
    if not k then
        local w = ns.Lower(u):gsub("[%.,:;]+$", "")
        k = UNITS[w]
    end
    return k and n * k or nil
end
local function skipped(text, s, stems)
    if not stems or #stems == 0 then return false end
    local before = text:sub(math.max(1, s - 90), s - 1)
    before = ns.Lower(before:match("[%.!?]%s+([^%.!?]*)$") or before)
    for _, w in ipairs(stems) do
        if before:find(w, 1, true) then return true end
    end
    return false
end
local function collect(text, list, out, stems, count)
    if not text then return end
    for _, rule in ipairs(list) do
        local init, once = 1, rule.p:sub(1, 1) == "^"
        while true do
            local s, e, a, b = text:find(rule.p, init)
            if not s then break end
            local v
            if count then v = number(a) else v = seconds(a, b, rule.mul) end
            if v and not skipped(text, s, stems) then out[#out + 1] = v end
            if once or e < init then break end
            init = e + 1
        end
    end
end
local function any(text, list)
    if not text then return false end
    for _, rule in ipairs(list) do
        if text:find(rule.p) then return true end
    end
    return false
end
local function one(list)
    local v = list[1]
    for i = 2, #list do
        if list[i] ~= v then return nil end
    end
    return v
end
local function clean(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end
local function read(link)
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink(link)
    local name, out = tip:GetName(), {}
    for i = 1, tip:NumLines() or 0 do
        local l, r = _G[name .. "TextLeft" .. i], _G[name .. "TextRight" .. i]
        local right = r and r:IsShown() and clean(r:GetText()) or nil
        out[i] = { l and clean(l:GetText()) or false, right or false }
    end
    tip:Hide()
    return out
end
local function texts(rows, side)
    local out = {}
    for i = 2, #rows do
        local s = rows[i][side]
        if s then
            for part in s:gmatch("[^\n]+") do out[#out + 1] = part end
        end
    end
    return out
end
local function parseSpell(rows)
    local out = {}
    local L, R = texts(rows, 1), texts(rows, 2)
    local cds, explicit, durs, stacks, charges = {}, {}, {}, {}, {}
    for _, list in ipairs({ L, R }) do
        for _, s in ipairs(list) do
            collect(s, rules.cd, cds)
            if any(s, rules.instant) then out.instant = true end
            if any(s, rules.channel) then out.channel = true end
        end
    end
    for _, s in ipairs(L) do
        collect(s, rules.durLine, explicit)
        collect(s, rules.dur, durs, rules.skip)
        collect(s, rules.stacks, stacks, nil, true)
        collect(s, rules.charges, charges, nil, true)
    end
    out.cd = one(cds)
    if #explicit > 0 then out.dur = one(explicit) else out.dur = one(durs) end
    out.stacks, out.charges = one(stacks), one(charges)
    return out
end
local function parseItem(rows)
    local cds, durs, stacks, charges = {}, {}, {}, {}
    for i = 2, #rows do
        local s = rows[i][1]
        if s then
            if any(s, rules.use) then
                collect(s, rules.itemCd, cds)
                local body = s:gsub("%b()", "")
                collect(body, rules.dur, durs, rules.skip)
                collect(body, rules.stacks, stacks, nil, true)
            end
            collect(s, rules.charges, charges, nil, true)
        end
    end
    return { cd = one(cds), dur = one(durs), stacks = one(stacks), charges = one(charges) }
end
local function fresh()
    local code = tostring(GetLocale())
    local key = code .. "/" .. tostring(ns.CurrentLocale and ns.CurrentLocale() or "")
    if key == cacheFor and rules then return end
    wipe(cache)
    cacheFor = key
    rules = build(code)
end
local function tipOf(kind, id)
    local key = kind .. ":" .. id
    local hit = cache[key]
    if hit then return hit end
    if kind == "item" then
        local name = GetItemInfo(id)
        if not name then return nil end
    end
    local rows = read(key)
    if kind == "item" then hit = parseItem(rows) else hit = parseSpell(rows) end
    cache[key] = hit
    return hit
end
local function num(x)
    local r = math.floor(x * 10 + 0.5) / 10
    local s
    if r == math.floor(r) then s = tostring(math.floor(r)) else s = string.format("%.1f", r) end
    return (s:gsub("%.", ns.T("facts.dot")))
end
function F.Time(s)
    if not s or s <= 0 then return nil end
    if s < 60 then return ns.T("facts.sec", num(s)) end
    if s >= 3600 and s % 360 == 0 then return ns.T("facts.hour", num(s / 3600)) end
    if s % 6 == 0 or s >= 600 then return ns.T("facts.min", num(s / 60)) end
    return ns.T("facts.sec", num(s))
end
local function costText(cost, ptype, funnel)
    local key = POWER[ptype or 0]
    if not cost or cost <= 0 or not key then return nil end
    if (ptype == 1 or ptype == 6) and cost > 100 then cost = cost / 10 end
    local text
    if ptype == 0 then
        local max = UnitPowerMax and UnitPowerMax("player", 0)
        if type(max) == "number" and max > 0 then
            local pct = cost / max * 100
            if pct >= 10 then pct = math.floor(pct + 0.5) end
            text = ns.T("facts.mana_pct", num(pct))
        end
    end
    text = text or ns.T(key, num(cost))
    if funnel then text = ns.T("facts.per_sec", text) end
    return text
end
local function procOf(id)
    return (ns.Trinket and ns.Trinket.Proc and ns.Trinket.Proc(id)) or (ns.gearRelics and ns.gearRelics[id])
        or (ns.gearItems and ns.gearItems[id]) or nil
end
local function catalogKind(id, isItem)
    local C = ns.Catalog
    local db = C and C.Ensure and C.Ensure()
    local list = db and (isItem and db.byItem or db.byId)
    local row = list and list[id] and list[id][1]
    return row and LETTER_KIND[row.kind] or nil
end
local function fromGear(e)
    local kind = "item"
    if not e.use and e.proc then kind = "proc" end
    return { item = e.item, proc = e.proc, kind = kind }
end
local function fromRef(k, role)
    local id = tonumber(k:match("^spell:(%d+)$"))
    if id then return { spell = id, kind = ROLE_KIND[role] or catalogKind(id) } end
    id = tonumber(k:match("^item:(%d+)$"))
    local gear = role == "gear" or k:match("^slot:") or k:match("^meta") or k:match("^ench:") or k:match("^set:")
    if gear and ns.Trinket and ns.Trinket.ForRef then
        local e = ns.Trinket.ForRef(k)
        if e then return fromGear(e) end
    end
    if id then
        local p = procOf(id)
        return { item = id, proc = p, kind = ROLE_KIND[role] or (p and "proc") or catalogKind(id, true) or "item" }
    end
    return nil
end
local function source(x)
    local t = type(x)
    if t == "number" then return { spell = x, kind = catalogKind(x) } end
    if t == "string" then return fromRef(x, nil) end
    if t ~= "table" then return nil end
    if type(x.k) == "string" then return fromRef(x.k, x.role) end
    if type(x.kind) == "string" and LETTER_KIND[x.kind] and type(x.id) == "number" then
        if x.item == true then return { item = x.id, kind = LETTER_KIND[x.kind] } end
        return { spell = x.id, kind = LETTER_KIND[x.kind] }
    end
    if x.proc or x.slot then return fromGear(x) end
    if type(x.item) == "number" then return { item = x.item, proc = procOf(x.item), kind = "item" } end
    if type(x.id) == "number" then return { spell = x.id, kind = x.harm and "debuff" or catalogKind(x.id) } end
    return nil
end
function F.Of(x)
    fresh()
    local out = {}
    local src = source(x)
    if not src then return out end
    out.kind = src.kind
    if src.spell then
        local name, _, _, cost, funnel, ptype, castMs, _, maxRange = GetSpellInfo(src.spell)
        local t = tipOf("spell", src.spell) or EMPTY
        if name and src.kind ~= "proc" and src.kind ~= "item" then
            out.cost = costText(cost, ptype, funnel)
            if type(castMs) == "number" and castMs > 0 then
                out.cast = F.Time(castMs / 1000)
            elseif t.channel then
                out.cast = ns.T("facts.channel")
            elseif t.instant then
                out.cast = ns.T("facts.instant")
            end
            if type(maxRange) == "number" and maxRange > 0 then out.range = ns.T("facts.range", num(maxRange)) end
        end
        out.cd, out.dur, out.charges, out.stacks = t.cd, t.dur, t.charges, t.stacks
    end
    if src.item then
        local t = tipOf("item", src.item) or EMPTY
        out.cd, out.dur, out.charges, out.stacks = t.cd, t.dur, t.charges, t.stacks
    end
    local p = src.proc
    if p then
        out.icd = p.icd
        local aura = p.auras and p.auras[1]
        if aura then
            local a = tipOf("spell", aura) or EMPTY
            out.dur = out.dur or a.dur
            out.stacks = out.stacks or a.stacks
        end
    end
    return out
end
function F.Line(x)
    local f = F.Of(x)
    local parts = {}
    if f.cost then parts[#parts + 1] = f.cost end
    if f.cd then parts[#parts + 1] = ns.T("facts.cd", F.Time(f.cd)) end
    if f.icd then parts[#parts + 1] = ns.T("facts.icd", F.Time(f.icd)) end
    if f.dur then parts[#parts + 1] = ns.T("facts.dur", F.Time(f.dur)) end
    if f.charges then parts[#parts + 1] = ns.T("facts.charges", math.floor(f.charges)) end
    if f.stacks then parts[#parts + 1] = ns.T("facts.stacks", math.floor(f.stacks)) end
    if #parts == 0 then return nil end
    return table.concat(parts, ns.T("facts.sep"))
end
function F.Reset()
    wipe(cache)
    cacheFor = nil
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_TALENT_UPDATE")
watch:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
watch:SetScript("OnEvent", F.Reset)
ns.factsLoaded = true

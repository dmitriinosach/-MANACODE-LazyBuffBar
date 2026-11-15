local _, ns = ...
local KEY = "rogue_sub_prep"
local function data()
    return ns.widgetData.rogue_sub_prep
end
local function set()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
local function avail()
    local s = set()
    return s ~= nil and ns.IsLearned(s.spell)
end
local function glyphed(id)
    if not id then return false end
    for i = 1, data().glyphs do
        local on, _, gid = GetGlyphSocketInfo(i)
        if on and gid == id then return true end
    end
    return false
end
local function mainKey(id)
    return "m" .. id
end
local function isMain(s, id, opt)
    local v = opt and opt[mainKey(id)]
    if v ~= nil then return v and true or false end
    for _, m in ipairs(s.main) do
        if m == id then return true end
    end
    return false
end
local function read(s, id, opt)
    if not ns.IsLearned(id) then return nil end
    local name, _, icon = GetSpellInfo(id)
    if not name then return nil end
    return { id = id, name = name, icon = icon, left = ns.WTile.Left(data().gcd, GetSpellCooldown(name)), main = isMain(s, id, opt) }
end
local function state(opt)
    local s = set()
    local st = { cd = 0, back = {}, row = {}, count = 0, mainLeft = 0, any = false }
    if s and ns.IsLearned(s.spell) then
        local name, _, icon = GetSpellInfo(s.spell)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.why, st.verdict = "none", "off"
        return st
    end
    st.cd = ns.WTile.Left(data().gcd, GetSpellCooldown(st.spell))
    local function add(id)
        local b = read(s, id, opt)
        if not b then return end
        st.back[#st.back + 1] = b
        if b.left > 0 then
            st.count = st.count + 1
            st.any = true
            if b.main and b.left > st.mainLeft then st.mainLeft = b.left end
        end
    end
    for _, id in ipairs(s.main) do add(id) end
    for _, id in ipairs(s.minor) do add(id) end
    if glyphed(s.glyph) then
        for _, id in ipairs(s.glyphed) do add(id) end
    end
    for i, id in ipairs(s.row) do
        for _, b in ipairs(st.back) do
            if b.id == id then st.row[i] = b end
        end
    end
    if st.cd > 0 then
        st.any = true
        st.why, st.verdict = "cd", "cd"
    elseif st.mainLeft > data().big then
        st.why, st.verdict = "big", "ok"
    elseif st.count > 0 then
        st.why, st.verdict = "small", "ok"
    else
        st.why, st.verdict = "empty", "off"
    end
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    local n = view == "row" and 1 + #((set() or data().classes.ROGUE).row) or 1
    layer.tiles, layer.looks = {}, {}
    for i = 1, n do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + gap), 0, s)
        layer.looks[i] = {}
    end
end
local function paint(layer, st)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.looks[1]
    k.icon = st.icon
    k.grey = v == "cd"
    k.alpha = v == "off" and d.dim or 1
    k.edge = st.why == "big" and S.ok or nil
    k.glow = st.why == "big"
    k.text = v == "cd" and W.Left(st.cd) or ""
    k.corner = v == "ok" and tostring(st.count) or nil
    ns.WTile.Paint(layer.tiles[1], k)
    for i = 2, #layer.tiles do
        local b = st.row[i - 1]
        local x = layer.looks[i]
        x.icon = b and b.icon
        x.alpha = b and 1 or 0
        x.grey = b ~= nil and b.left > 0
        x.text = b and W.Left(b.left) or ""
        x.edge = (b and b.main and b.left > d.big and v ~= "cd") and S.ok or nil
        ns.WTile.Paint(layer.tiles[i], x)
    end
end
local cellsBy = {}
local function cells(view)
    local list = cellsBy[view]
    if list then return list end
    list = { { cx = 0, cy = 0, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end } }
    if view == "row" then
        local s = set() or data().classes.ROGUE
        for i = 1, #s.row do
            list[#list + 1] = { cx = i, cy = 0, attrs = function(st)
                local b = st.row[i]
                if not b then return {} end
                return { type = "spell", spell = b.name }
            end }
        end
    end
    cellsBy[view] = list
    return list
end
local function clock(sec)
    local t = math.floor(sec + 0.5)
    return string.format("%d:%02d", math.floor(t / 60), t % 60)
end
local function tip(i, st)
    if not st.spell then return nil end
    if i > 1 then
        local b = st.row[i - 1]
        return b and b.name or nil
    end
    if st.count == 0 then return st.spell, ns.T("widget.rogue_sp_nothing") end
    local parts = {}
    for _, b in ipairs(st.back) do
        if b.left > 0 then parts[#parts + 1] = b.name .. " " .. clock(b.left) end
    end
    return st.spell, ns.T("widget.rogue_sp_back", table.concat(parts, ", "))
end
local DEMO = {
    solo  = { "empty", "off", 0, {} },
    party = { "small", "ok", 0, { [4] = 50 } },
    raid  = { "big", "ok", 0, { 130, 18, nil, 90 } },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local s = data().classes.ROGUE
    local name, _, icon = GetSpellInfo(s.spell)
    local st = { spell = name, icon = icon, why = p[1], verdict = p[2], cd = p[3], back = {}, row = {}, count = 0, mainLeft = 0 }
    local ids = {}
    for _, id in ipairs(s.main) do ids[#ids + 1] = id end
    for _, id in ipairs(s.minor) do ids[#ids + 1] = id end
    for n, id in ipairs(ids) do
        local bn, _, bi = GetSpellInfo(id)
        local b = { id = id, name = bn, icon = bi, left = p[4][n] or 0, main = n <= #s.main }
        st.back[n] = b
        if b.left > 0 then st.count = st.count + 1 end
        for r, rid in ipairs(s.row) do
            if rid == id then st.row[r] = b end
        end
    end
    return st
end
local function mainChecks()
    local s = set() or data().classes.ROGUE
    local out = {}
    local function add(id, def)
        out[#out + 1] = { key = mainKey(id), def = def, label = "widget.rogue_sp_c_" .. id }
    end
    for _, id in ipairs(s.main) do add(id, true) end
    for _, id in ipairs(s.minor) do add(id, false) end
    return out
end
local function rowSize()
    local s = set() or data().classes.ROGUE
    return 1 + #s.row, 1
end
ns.Widget.Register(KEY, {
    info = { text = "widget.rogue_sub_prep_info", demo = demo },
    icon = 14185,
    label = "widget.rogue_sub_prep",
    class = "ROGUE",
    views = { one = { w = 1, h = 1 }, row = rowSize },
    order = { "one", "row" },
    view = "one",
    covers = { "spell:14185" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        GLYPH_ADDED = true, GLYPH_REMOVED = true, GLYPH_UPDATED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if st.any then return data().tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = cells,
    Tip = tip,
    active = function(st) return st.spell ~= nil end,
    opts = {
        { key = "main", label = "widget.rogue_sp_main", kind = "checks", checks = mainChecks },
    },
})
ns.rogueSubPrepWidgetLoaded = true

local _, ns = ...
local NAME = "druid_bloom"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local DOT_PART = 0.14
local function data()
    return ns.widgetData.druid_bloom
end
local NAMES = {}
local TANKS = { "tank", "tank2" }
local RANK = { none = 4, soon = 3, bad = 2, ok = 1, off = 0 }
local function avail()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return false end
    local d = data()
    if ns.IsLearned(d.id) then return true end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function tanksOf(opt)
    return (opt and opt.tanks == 1) and 1 or 2
end
local function judge(c, need, soon)
    if c.why == "none" or c.why == "dead" then c.verdict = "off"
    elseif c.why == "far" then c.verdict = "bad"
    elseif c.left <= 0 then c.why, c.verdict = "no", "none"
    elseif c.stacks < need then c.why, c.verdict = "low", "none"
    elseif c.left <= soon then c.why, c.verdict = "soon", "soon"
    else c.why, c.verdict = "ok", "ok" end
end
local function sum(st)
    st.any, st.ticking = false, false
    st.worst = st.cells[1]
    for _, c in ipairs(st.cells) do
        if c.why ~= "none" then st.any = true end
        if c.left > 0 then st.ticking = true end
        if RANK[c.verdict] > RANK[st.worst.verdict] then st.worst = c end
    end
end
local function state(opt)
    local d = data()
    local st = { cells = {}, need = (opt and opt.need) or d.need, max = d.max }
    local soon = (opt and opt.soon) or d.soon
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    local R, U = ns.Raid, ns.Units
    if st.spell and R then
        NAMES[1] = st.spell
        R.Watch(NAME, NAMES, true)
        R.Range(NAME, st.spell)
        R.Touch()
    end
    local now = GetTime()
    for i = 1, tanksOf(opt) do
        local c = { left = 0, stacks = 0, why = "none" }
        local unit = st.spell and U and U.Resolve(TANKS[i])
        local m = unit and R and R.Member(unit)
        if m then
            c.who, c.class, c.click = m.name, m.class, m.click
            if m.off or m.dead then
                c.why = "dead"
            else
                local e, n = R.Own(m, NAMES)
                if e and (e == 0 or e > now) then
                    c.left = e > 0 and (e - now) or d.soon + 1
                    c.stacks = math.max(n or 0, 1)
                end
                c.why = m.out[NAME] and "far" or "on"
            end
        end
        judge(c, st.need, soon)
        st.cells[i] = c
    end
    sum(st)
    return st
end
local function build(layer, view, opt)
    local s = layer.cell or layer.h
    local d = data()
    layer.tiles, layer.looks, layer.dots = {}, {}, {}
    local n = view == "one" and 1 or tanksOf(opt)
    local dot = math.max(3, math.floor(s * DOT_PART + 0.5))
    for i = 1, n do
        local x = view == "pair" and (i - 1) * (s + (layer.gap or 2)) or 0
        local y = view == "col" and (i - 1) * (s + (layer.gapY or 2)) or 0
        local t = ns.WTile.New(layer, x, y, s)
        layer.tiles[i], layer.looks[i], layer.dots[i] = t, {}, {}
        for j = 1, d.max do
            local p = t.pulse:GetParent():CreateTexture(nil, "OVERLAY")
            p:SetTexture(WHITE)
            p:SetWidth(dot)
            p:SetHeight(dot)
            p:SetPoint("BOTTOMLEFT", t.edge, "BOTTOMLEFT", 2 + (j - 1) * (dot + 1), 2)
            layer.dots[i][j] = p
        end
    end
end
local function paintCell(layer, i, c, st)
    local S = ns.STATE
    local W = ns.Widget
    local v = c.verdict
    local k = layer.looks[i]
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = v == "off" and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "none" and S.none) or (v == "bad" and S.bad) or nil
    k.text = (c.left > 0 and v ~= "off") and W.Left(c.left) or ""
    k.textColor = v == "soon" and S.soon or S.text
    k.mark = c.why == "far" and ns.T("widget.db_far") or nil
    k.markColor = S.bad
    k.glow = v == "soon"
    ns.WTile.Paint(layer.tiles[i], k)
    local full = c.stacks >= st.need
    for j, p in ipairs(layer.dots[i]) do
        local on = v ~= "off" and j <= c.stacks
        W.Alpha(p, on and 1 or 0)
        W.Color(p, full and S.stack or S.none)
    end
end
local function paint(layer, st, view)
    if view == "one" then
        paintCell(layer, 1, st.worst, st)
        return
    end
    for i in ipairs(layer.tiles) do
        if st.cells[i] then paintCell(layer, i, st.cells[i], st) end
    end
end
local function castOn(i)
    return function(st)
        local c = st.cells[i]
        if not (st.spell and c and c.click) then return {} end
        return { type = "spell", spell = st.spell, unit = c.click }
    end
end
local function castTarget(st)
    if not st.spell then return {} end
    return { type = "spell", spell = st.spell }
end
local A1, A2 = castOn(1), castOn(2)
local CELLS = {
    pair1 = { { cx = 0, cy = 0, attrs = A1 } },
    pair2 = { { cx = 0, cy = 0, attrs = A1 }, { cx = 1, cy = 0, attrs = A2 } },
    col1  = { { cx = 0, cy = 0, attrs = A1 } },
    col2  = { { cx = 0, cy = 0, attrs = A1 }, { cx = 0, cy = 1, attrs = A2 } },
    one   = { { cx = 0, cy = 0, attrs = castTarget } },
}
local function word(c)
    local S = ns.STATE
    if c.why == "dead" then return ns.T("widget.db_dead"), S.mute end
    if c.why == "far" then return ns.T("widget.db_far"), S.bad end
    if c.left <= 0 then return ns.T("widget.db_no"), S.none end
    return ns.T("widget.db_on", c.stacks, c.left), (c.verdict == "ok" and S.ok) or (c.verdict == "soon" and S.soon) or S.none
end
local function tip(st, view)
    if not st.spell then return nil end
    local rows = {}
    for _, c in ipairs(st.cells) do
        if c.who then
            local r, rc = word(c)
            rows[#rows + 1] = { l = c.who, r = r, lc = ns.WTile.ClassColor(c.class), rc = rc }
        else
            rows[#rows + 1] = { l = ns.T("widget.db_notank"), lc = ns.STATE.mute }
        end
    end
    return st.spell, ns.T(view == "one" and "widget.db_click_target" or "widget.db_click"), rows
end
local DEMO = {
    solo  = {},
    party = { { "WARRIOR", 3, 5.2 } },
    raid  = { { "PALADIN", 3, 6.1 }, { "DEATHKNIGHT", 3, 1.5 } },
}
local function demo(scene)
    local d = data()
    local opt = scene.opt or {}
    local name, _, icon = GetSpellInfo(d.id)
    local st = { spell = name, icon = icon, cells = {}, need = opt.need or d.need, max = d.max }
    local list = DEMO[scene.size] or DEMO.raid
    for i = 1, tanksOf(opt) do
        local p = list[i]
        local c = { left = 0, stacks = 0, why = "none" }
        if p then
            local who = ns.T("widget.bless_demo_name", i)
            c.who, c.class, c.click, c.stacks, c.left, c.why = who, p[1], who, p[2], p[3], "on"
        end
        judge(c, st.need, opt.soon or d.soon)
        st.cells[i] = c
    end
    sum(st)
    return st
end
local function steps(key, label, def)
    local values = {}
    for n = 1, 3 do values[n] = { v = n ~= def and n or nil, text = tostring(n) } end
    return { key = key, label = label, values = values }
end
ns.Widget.Register(NAME, {
    info = { text = "widget.druid_bloom_info", demo = demo },
    icon = 48451,
    label = "widget.druid_bloom",
    class = "DRUID",
    views = {
        pair = function(opt) return tanksOf(opt), 1 end,
        one  = { w = 1, h = 1 },
        col  = function(opt) return 1, tanksOf(opt) end,
    },
    order = { "pair", "one", "col" },
    view = "pair",
    covers = { "spell:48451" },
    avail = avail,
    units = function() return TANKS end,
    events = {
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_ENTERING_WORLD = true, SPELLS_CHANGED = true,
    },
    tick = function(st) return st.ticking and data().tick or nil end,
    State = state,
    active = function(st) return st.spell ~= nil and st.any end,
    Build = build,
    Paint = paint,
    cells = function(view, opt)
        if view == "one" then return CELLS.one end
        return CELLS[(view == "col" and "col" or "pair") .. tanksOf(opt)]
    end,
    Tip = function(_, st, view) return tip(st, view) end,
    opts = {
        { key = "tanks", label = "widget.db_tanks", values = { { v = 1, text = "1" }, { v = nil, text = "2" } } },
        steps("need", "widget.db_need", data().need),
        steps("soon", "widget.db_soon", data().soon),
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(NAME) end)
end
if ns.Units and ns.Units.OnChange then
    ns.Units.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.druidBloomLoaded = true

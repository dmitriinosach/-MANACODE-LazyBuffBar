local _, ns = ...
local function data()
    return ns.widgetData.rez
end
local function build(layer)
    layer.tile = ns.WTile.New(layer, 0, 0, layer.h)
    layer.look = {}
end
local function paint(layer, st)
    local S = ns.STATE
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = st.why == "fight" and d.dim or 1
    k.tint = st.why == "res" and d.tint or nil
    k.edge = (v == "ok" and S.ok) or (v == "bad" and S.bad) or nil
    k.text = st.n > 0 and tostring(st.n) or ""
    k.textColor = v == "bad" and S.bad or S.text
    k.mark = (st.next and st.next.ghost) and ns.T("widget.rz_ghost_mark") or nil
    k.markColor = S.mute
    ns.WTile.Paint(layer.tile, k)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st) return ns.Rez.Click(st) end },
}
local function markOf(d)
    local S = ns.STATE
    if d.ghost then return ns.T("widget.rz_ghost"), S.mute end
    if d.far then return ns.T("widget.rz_far"), S.bad end
    if d.tank then return ns.T("widget.rz_tank"), S.text end
    return nil, nil
end
local function tip(st)
    if not ns.Rez.Active(st) then return nil end
    local line
    if st.why == "fight" then line = ns.T("widget.rz_fight")
    elseif st.why == "res" then line = ns.T("widget.rz_nomana")
    elseif st.why == "ghost" then line = ns.T("widget.rz_all_ghost") end
    local rows, lines = {}, data().lines
    for i, dd in ipairs(st.list) do
        if i > lines then
            rows[#rows + 1] = { l = ns.T("widget.rz_more", st.n - lines), lc = ns.STATE.mute }
            break
        end
        local r, rc = markOf(dd)
        rows[#rows + 1] = { l = dd.name, r = r, lc = ns.WTile.ClassColor(dd.class), rc = rc }
    end
    return st.spell or ns.T("widget.rez"), line, rows
end
local DEMO = {
    solo  = {},
    party = { { "WARRIOR", true, false, false } },
    raid  = { { "WARRIOR", true, false, false }, { "MAGE", false, false, false },
              { "ROGUE", false, true, false }, { "HUNTER", false, false, true } },
}
local function demo(scene)
    local e = data().classes[scene.class] or data().classes.PRIEST
    local name, _, icon = GetSpellInfo(e.id)
    local st = { spell = name, icon = icon, list = {}, fight = scene.fight and true or false, self = false, nomana = false, grouped = true }
    for i, p in ipairs(DEMO[scene.size] or DEMO.raid) do
        local prio = (p[4] and 3) or (p[2] and 0) or (p[3] and 2) or 1
        local who = ns.T("widget.bless_demo_name", i)
        st.list[i] = { name = who, class = p[1], click = who, unit = "raid" .. i, pos = i, tank = p[2], far = p[3], ghost = p[4], prio = prio }
    end
    st.n, st.next = #st.list, st.list[1]
    if st.n == 0 then st.why, st.verdict = "idle", "off"
    elseif st.fight then st.why, st.verdict = "fight", "off"
    else st.why, st.verdict = "go", "ok" end
    return st
end
local function coverList()
    local out = {}
    for _, e in pairs(data().classes) do
        out[#out + 1] = "spell:" .. e.id
        for _, id in ipairs(e.alt) do out[#out + 1] = "spell:" .. id end
    end
    table.sort(out)
    return out
end
ns.Widget.Register("rez", {
    info = { text = "widget.rez_info", fight = true, demo = demo },
    icon = 48171,
    label = "widget.rez",
    views = { one = { w = 1, h = 1 } },
    order = { "one" },
    view = "one",
    covers = coverList(),
    avail = function() return ns.Rez.Avail() end,
    units = function() return { "tank", "tank2" } end,
    events = {
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true, PLAYER_ENTERING_WORLD = true,
        SPELLS_CHANGED = true, SPELL_UPDATE_USABLE = true,
    },
    tick = function(st) return ns.Rez.Tick(st) end,
    State = function() return ns.Rez.State() end,
    active = function(st) return ns.Rez.Active(st) end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return tip(st) end,
})
ns.rezWidgetLoaded = true

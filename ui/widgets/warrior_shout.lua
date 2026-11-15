local _, ns = ...
local NAME = "war_shout"
local KINDS = { "battle", "command" }
local REST = { battle = "command", command = "battle" }
local function data()
    return ns.widgetData.war_shout
end
local WATCH = {}
local LIST = { battle = {}, command = {} }
local function learned(id)
    return ns.IsLearned(id) and true or false
end
local function avail()
    local _, class = UnitClass("player")
    if class ~= "WARRIOR" then return false end
    local d = data()
    return learned(d.battle) or learned(d.command)
end
local function auraOf(name)
    if not name then return nil end
    local found, _, _, _, _, _, expires, caster = UnitBuff("player", name)
    if not found then return nil end
    expires = tonumber(expires) or 0
    local left = expires > 0 and (expires - GetTime()) or 0
    return { left = left > 0 and left or 0, mine = caster == "player", by = caster and UnitName(caster) or nil }
end
local function judge(on, pick, might, soon)
    local b, c = on.battle, on.command
    local want, spare = pick, false
    if want ~= "battle" and want ~= "command" then
        local taken = might or (b and not b.mine) or false
        want = (taken or (c and c.mine)) and "command" or "battle"
        spare = (taken and c and not c.mine) and true or false
    end
    local a, rest = on[want], REST[want]
    if a and a.mine then
        return want, want, (a.left > 0 and a.left < soon) and "soon" or "ok", "mine"
    elseif spare then
        return want, want, "off", "spare"
    elseif a then
        return want, want, "off", "held"
    elseif on[rest] and on[rest].mine then
        return want, rest, "bad", "other"
    end
    return want, want, "none", "none"
end
local function namesOf(list)
    local out = {}
    for i, m in ipairs(list) do out[i] = m.name end
    return out
end
local function state(opt)
    local d = data()
    local st = { names = {}, icons = {}, on = {}, n = 0, total = 0, miss = {}, gone = {} }
    for _, k in ipairs(KINDS) do
        local name, _, icon = GetSpellInfo(d[k])
        st.names[k], st.icons[k] = name, icon
        st.on[k] = auraOf(name)
    end
    for _, id in ipairs(d.might) do
        local a = auraOf(GetSpellInfo(id))
        if a then st.might = a.by or "" end
    end
    local pick = opt and opt.shout
    if not learned(d.command) then pick = "battle" elseif not learned(d.battle) then pick = "command" end
    st.want, st.show, st.verdict, st.why = judge(st.on, pick, st.might ~= nil, d.soon)
    st.cast = st.names[st.want]
    local R = ns.Raid
    if R and st.names.battle and st.names.command then
        if not WATCH[1] then
            WATCH[1], WATCH[2] = st.names.battle, st.names.command
            LIST.battle[1], LIST.command[1] = st.names.battle, st.names.command
        end
        R.Watch(NAME, WATCH)
        R.Range(NAME)
        R.Touch()
        local c = R.Count(LIST[st.want], NAME, nil, d.soon, R.Scope(), d.lines)
        st.n, st.total = c.n, c.total
        st.miss, st.gone = namesOf(c.miss), namesOf(c.gone)
    end
    st.count = st.total > 1 and not (opt and opt.count == "off")
    return st
end
local function look(st, kind, k, solo)
    local S = ns.STATE
    local d = data()
    local v = st.verdict
    local a = st.on[kind]
    k.icon = st.icons[kind]
    k.glow = false
    k.corner, k.cornerColor = nil, S.text
    if kind ~= st.show then
        local want = kind == st.want
        k.grey, k.alpha = want, want and 1 or d.other
        k.edge = want and S.none or nil
        k.text, k.textColor = "", S.text
        return
    end
    k.grey = v == "none"
    k.alpha = v == "off" and d.dim or 1
    k.edge = (v ~= "off") and S[v] or nil
    k.text = (a and a.left > 0) and ns.Widget.Left(a.left) or ""
    k.textColor = v == "soon" and S.soon or S.text
    if st.count and (solo or kind == st.want) then
        k.corner = ns.T("widget.td_stacks", st.n, st.total)
        k.cornerColor = st.n < st.total and S.soon or S.text
    end
end
local function build(layer, view)
    local s = layer.h
    layer.tiles, layer.looks = {}, {}
    local n = view == "pair" and #KINDS or 1
    for i = 1, n do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + (layer.gap or 2)), 0, s)
        layer.looks[i] = {}
    end
end
local function paint(layer, st, view)
    if view ~= "pair" then
        look(st, st.show, layer.looks[1], true)
        ns.WTile.Paint(layer.tiles[1], layer.looks[1])
        return
    end
    for i, kind in ipairs(KINDS) do
        look(st, kind, layer.looks[i], false)
        ns.WTile.Paint(layer.tiles[i], layer.looks[i])
    end
end
local function click(name)
    if not name then return {} end
    return { type = "spell", spell = name }
end
local ONE = { { l = 0, t = 0, r = 1, b = 1, attrs = function(st) return click(st.cast) end } }
local PAIR = {
    { cx = 0, cy = 0, attrs = function(st) return click(st.names.battle) end },
    { cx = 1, cy = 0, attrs = function(st) return click(st.names.command) end },
}
local function rows(st, btn)
    local S = ns.STATE
    local T = ns.T
    local out = {}
    local want = st.names[st.want] or "?"
    local a = st.on[st.want]
    if st.why == "mine" then
        out[1] = { l = T("widget.ws_mine", want), r = ns.Widget.Left(a.left), rc = S[st.verdict] }
    elseif st.why == "held" then
        out[1] = { l = T("widget.ws_held", want, a.by or "?"), lc = S.mute }
    elseif st.why == "spare" then
        out[1] = { l = T("widget.ws_spare"), lc = S.mute }
    elseif st.why == "other" then
        out[1] = { l = T("widget.ws_other", st.names[st.show] or "?", want), lc = S.bad }
    else
        out[1] = { l = T("widget.ws_none", want), lc = S.none }
    end
    if st.might then
        out[#out + 1] = { l = T("widget.ws_might", st.might ~= "" and st.might or "?", st.names.battle or "?") }
    end
    local b = st.on.battle
    if st.want == "command" and b and not b.mine then
        out[#out + 1] = { l = T("widget.ws_held", st.names.battle or "?", b.by or "?") }
    end
    if st.total > 1 then
        out[#out + 1] = { l = T("widget.ws_count", want), r = T("widget.td_stacks", st.n, st.total) }
    end
    if #st.miss > 0 then out[#out + 1] = { l = T("widget.ws_miss", table.concat(st.miss, ", ")), lc = S.none } end
    if #st.gone > 0 then out[#out + 1] = { l = T("widget.ws_gone", table.concat(st.gone, ", ")), lc = S.mute } end
    local armed = btn and btn.attrs and btn.attrs.spell
    if armed and st.cast and armed ~= st.cast then
        out[#out + 1] = { l = T("widget.ws_later", armed), lc = S.soon }
    end
    return out
end
local DEMO = {
    solo  = { nil, 0, false, 0, 1 },
    party = { "battle", 105, false, 5, 5 },
    raid  = { "command", 14, true, 23, 25 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local st = { names = {}, icons = {}, on = {}, n = p[4], total = p[5], miss = {}, gone = {} }
    for _, k in ipairs(KINDS) do
        local name, _, icon = GetSpellInfo(d[k])
        st.names[k], st.icons[k] = name, icon
    end
    if p[1] then st.on[p[1]] = { left = p[2], mine = true } end
    if p[3] then st.might = ns.T("widget.bless_demo_name", 1) end
    st.want, st.show, st.verdict, st.why = judge(st.on, scene.opt and scene.opt.shout, p[3], d.soon)
    st.cast = st.names[st.want]
    st.count = st.total > 1 and not (scene.opt and scene.opt.count == "off")
    return st
end
local function shoutName(kind)
    return GetSpellInfo(data()[kind]) or kind
end
ns.Widget.Register(NAME, {
    info = { text = "widget.war_shout_info", demo = demo },
    icon = data().battle,
    label = "widget.war_shout",
    class = "WARRIOR",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "one",
    covers = { "spell:" .. data().battle, "spell:" .. data().command },
    avail = avail,
    events = {
        UNIT_AURA = "player", SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true, PLAYER_REGEN_ENABLED = true,
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
    },
    tick = function(st)
        local a = st.on[st.show]
        if a and a.left > 0 then return a.left <= 61 and data().tick or data().slow end
        return st.count and data().slow or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function(view) return view == "pair" and PAIR or ONE end,
    Tip = function(_, st, view, _, btn)
        return ns.T("widget.war_shout"), nil, rows(st, view ~= "pair" and btn or nil)
    end,
    opts = {
        { key = "shout", label = "widget.ws_pick", values = function()
            return {
                { v = nil, label = "widget.ws_auto" },
                { v = "battle", text = shoutName("battle") },
                { v = "command", text = shoutName("command") },
            }
        end },
        { key = "count", label = "widget.ws_num", values = {
            { v = nil, label = "widget.ws_num_on" }, { v = "off", label = "widget.ws_num_off" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.warShoutWidgetLoaded = true

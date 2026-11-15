local _, ns = ...
local NAME = "druid_eclipse"
local SCAN = 40
local function data()
    return ns.widgetData.druid_eclipse
end
local procAt = {}
local function inFight()
    return (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
end
local function avail()
    local _, class = UnitClass("player")
    return class == "DRUID" and ns.IsLearned(data().talent)
end
local function byIndex(solar, lunar)
    local out = {}
    for i = 1, SCAN do
        local n, _, _, _, _, dur, exp, _, _, _, id = UnitBuff("player", i)
        if not n then break end
        if id == solar or id == lunar then out[id] = { dur or 0, exp or 0 } end
    end
    return out
end
local function side(key, found, now)
    local d = data()
    local e = d[key]
    local name, _, icon = GetSpellInfo(e.aura)
    local s = { key = key, name = name, icon = icon, left = 0, icd = 0, verdict = "none" }
    local dur, exp
    if found then
        local f = found[e.aura]
        if f then dur, exp = f[1], f[2] end
    elseif name then
        local n, _, _, _, _, du, ex = UnitBuff("player", name)
        if n then dur, exp = du or 0, ex or 0 end
    end
    if exp then
        s.left = exp > now and (exp - now) or 0.01
        if exp > 0 then procAt[key] = exp - (dur > 0 and dur or d.dur) end
        s.verdict = s.left <= d.soon and "soon" or "ok"
    elseif procAt[key] then
        local icd = procAt[key] + d.icd - now
        if icd > 0 then s.icd, s.verdict = icd, "off" end
    end
    return s
end
local function judge(st, first)
    local d = data()
    local sun, moon = st.solar, st.lunar
    local id
    if moon.left > 0 then
        st.on, st.why, st.num, st.verdict, id = "lunar", "on", moon.left, moon.verdict, d.lunar.cast
    elseif sun.left > 0 then
        st.on, st.why, st.num, st.verdict, id = "solar", "on", sun.left, sun.verdict, d.solar.cast
    elseif sun.icd > 0 and moon.icd > 0 then
        st.why, st.verdict = "wait", "off"
        st.num = math.min(sun.icd, moon.icd)
        id = sun.icd < moon.icd and d.solar.catch or d.lunar.catch
    else
        st.why, st.verdict, st.num = "catch", "none", 0
        if moon.icd > 0 then id = d.solar.catch
        elseif sun.icd > 0 then id = d.lunar.catch
        else id = first == "solar" and d.solar.catch or d.lunar.catch end
    end
    local name, _, icon = GetSpellInfo(id)
    st.cast, st.castIcon = name, icon
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { known = avail(), fight = inFight(), glow = (opt and opt.glow) and true or false }
    local found
    if GetSpellInfo(d.solar.aura) == GetSpellInfo(d.lunar.aura) then found = byIndex(d.solar.aura, d.lunar.aura) end
    st.solar = side("solar", found, now)
    st.lunar = side("lunar", found, now)
    judge(st, opt and opt.first)
    return st
end
local function moving(st)
    return st.solar.left > 0 or st.lunar.left > 0 or st.solar.icd > 0 or st.lunar.icd > 0
end
local function build(layer, view)
    local s = layer.cell or layer.h
    layer.tiles, layer.looks = {}, {}
    local n = view == "one" and 1 or 2
    for i = 1, n do
        local x = view == "wheel" and (i - 1) * (s + (layer.gap or 2)) or 0
        local y = view == "col" and (i - 1) * (s + (layer.gapY or 2)) or 0
        layer.tiles[i] = ns.WTile.New(layer, x, y, s)
        layer.looks[i] = {}
    end
end
local function edgeOf(verdict)
    local S = ns.STATE
    return (verdict == "ok" and S.ok) or (verdict == "soon" and S.soon) or nil
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    if view == "one" then
        local k = layer.looks[1]
        local wait = st.why == "wait"
        k.icon = st.castIcon
        k.grey = wait
        k.alpha = wait and d.dim or 1
        k.edge = edgeOf(st.verdict)
        k.text = st.num > 0 and W.Left(st.num) or ""
        k.textColor = wait and S.mute or (st.verdict == "soon" and S.soon or S.text)
        k.glow = st.glow and st.why == "on"
        ns.WTile.Paint(layer.tiles[1], k)
        return
    end
    for i, key in ipairs(d.order) do
        local h = st[key]
        local k = layer.looks[i]
        local off = h.verdict == "off"
        k.icon = h.icon
        k.grey = off
        k.alpha = off and d.dim or 1
        k.edge = edgeOf(h.verdict)
        k.text = (h.left > 0 and W.Left(h.left)) or (off and W.Left(h.icd)) or ""
        k.textColor = off and S.mute or (h.verdict == "soon" and S.soon or S.text)
        k.glow = st.glow and h.left > 0
        ns.WTile.Paint(layer.tiles[i], k)
    end
end
local CELLS = {
    wheel = { { cx = 0, cy = 0 }, { cx = 1, cy = 0 } },
    col   = { { cx = 0, cy = 0 }, { cx = 0, cy = 1 } },
    one   = { { cx = 0, cy = 0 } },
}
local function word(h)
    local S = ns.STATE
    if h.left > 0 then return ns.T("widget.de_on", ns.Widget.Left(h.left)), h.verdict == "soon" and S.soon or S.ok end
    if h.icd > 0 then return ns.T("widget.de_icd", ns.Widget.Left(h.icd)), S.mute end
    return ns.T("widget.de_ready"), S.text
end
local function tip(st)
    if not st.known then return nil end
    local rows = {}
    for _, key in ipairs(data().order) do
        local h = st[key]
        local r, rc = word(h)
        rows[#rows + 1] = { l = h.name or key, r = r, rc = rc }
    end
    if st.cast then
        rows[#rows + 1] = { l = ns.T(st.why == "on" and "widget.de_cast" or "widget.de_catch", st.cast) }
    end
    return GetSpellInfo(data().talent) or ns.T("widget.druid_eclipse"), nil, rows
end
local DEMO = { solo = { 0, 0, 0, 0 }, party = { 0, 0, 11, 0 }, raid = { 2, 0, 0, 17 } }
local function demoSide(key, left, icd)
    local d = data()
    local name, _, icon = GetSpellInfo(d[key].aura)
    local v = (left > 0 and (left <= d.soon and "soon" or "ok")) or (icd > 0 and "off") or "none"
    return { key = key, name = name, icon = icon, left = left, icd = icd, verdict = v }
end
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local opt = scene.opt or {}
    local st = { known = true, fight = true, glow = opt.glow and true or false }
    st.solar = demoSide("solar", p[1], p[2])
    st.lunar = demoSide("lunar", p[3], p[4])
    judge(st, opt.first)
    return st
end
ns.Widget.Register(NAME, {
    info = { text = "widget.druid_eclipse_info", demo = demo },
    icon = 48525,
    label = "widget.druid_eclipse",
    class = "DRUID",
    views = { wheel = { w = 2, h = 1 }, one = { w = 1, h = 1 }, col = { w = 1, h = 2 } },
    order = { "wheel", "one", "col" },
    view = "wheel",
    covers = { "spell:48517", "spell:48518" },
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return moving(st) and data().tick or nil end,
    State = state,
    active = function(st) return st.known and (st.fight or moving(st)) end,
    Build = build,
    Paint = paint,
    cells = function(view) return CELLS[view] or CELLS.wheel end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "first", label = "widget.de_first", values = {
            { v = nil, label = "widget.de_lunar" }, { v = "solar", label = "widget.de_solar" },
        } },
        { key = "glow", label = "widget.de_glow", values = {
            { v = nil, label = "widget.de_no" }, { v = true, label = "widget.de_yes" },
        } },
    },
})
ns.druidEclipseLoaded = true

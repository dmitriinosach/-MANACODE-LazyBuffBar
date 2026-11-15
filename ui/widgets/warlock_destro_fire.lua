local _, ns = ...
local KEY = "warlock_destro_fire"
local function data()
    return ns.widgetData.warlock_destro_fire
end
local cache
local function names()
    if cache then return cache end
    local d = data()
    local immo, _, iIcon = GetSpellInfo(d.immo)
    if not immo then return nil end
    local conf, _, cIcon = GetSpellInfo(d.conf)
    local chaos, _, hIcon = GetSpellInfo(d.chaos)
    local flame = GetSpellInfo(d.flame) or ""
    cache = {
        immo = immo, conf = conf or "", chaos = chaos or "", flame = flame, imp = GetSpellInfo(d.imp) or "",
        flow = GetSpellInfo(d.flow) or "", iIcon = iIcon, cIcon = cIcon, hIcon = hIcon, watch = { immo, flame },
    }
    return cache
end
local function avail()
    if ns.PlayerClass() ~= "WARLOCK" then return false end
    local d = data()
    return ns.IsLearned(d.immo) and ns.IsLearned(d.conf)
end
local function hung(name)
    if name == "" then return false end
    local e = ns.Raid and ns.Raid.Enemy("target")
    if e and not e.dirty and e.guid == UnitGUID("target") then return e.own[name] or false end
    local o, _, _, _, _, _, x = UnitDebuff("target", name, nil, "PLAYER")
    return o and (tonumber(x) or 0) or false
end
local function on(v, now)
    return (v and (v == 0 or v > now)) and true or false
end
local function buff(name, now)
    if name == "" then return false, 0, 0 end
    local n, _, _, count, _, _, x = UnitBuff("player", name)
    if not n then return false, 0, 0 end
    x = tonumber(x) or 0
    return true, tonumber(count) or 0, x > now and (x - now) or 0
end
local function firstOf(st)
    if st.fire ~= "ok" then return "fire" end
    if st.conf == "ok" or st.conf == "gold" then return "conf" end
    if st.chaos == "ok" or st.chaos == "gold" then return "chaos" end
    if st.chaos == "off" and (st.conf ~= "off" or st.chaosCd < st.confCd) then return "chaos" end
    return "conf"
end
local function judge(st, opt)
    if st.fireLeft > 0 and st.fireLeft <= st.win then
        st.fire = "soon"
    end
    local fireOn = st.fire ~= "none"
    if st.confCd > 0 then
        st.conf = "off"
    elseif not (fireOn or st.flame) then
        st.conf = "wait"
    elseif st.fb then
        st.conf = "gold"
    else
        st.conf = "ok"
    end
    if st.chaos ~= "gone" then
        st.chaos = (st.chaosCd > 0 and "off") or (st.imp and "gold") or "ok"
    end
    st.shown = st.live or (opt and opt.show == "all") or false
    st.first = firstOf(st)
end
local function state(opt)
    local d = data()
    local st = {
        live = false, shown = false, fight = UnitAffectingCombat("player") and true or false, fire = "none",
        fireLeft = 0, win = d.cast, flame = false, conf = "wait", confCd = 0, chaos = "off", chaosCd = 0,
        fb = false, fbKnown = false, imp = false, impLeft = 0, flow = 0, flowLeft = 0,
        num = not (opt and opt.num == "off"), first = "fire",
    }
    local n = names()
    if not n then return st end
    local now = GetTime()
    local _, _, _, _, _, _, ms = GetSpellInfo(n.immo)
    ms = (tonumber(ms) or 0) / 1000
    if ms > 0 then st.win = ms end
    st.live = (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")) and true or false
    if st.live then
        local R = ns.Raid
        if R then
            R.WatchEnemy(KEY, n.watch, true)
            R.Touch()
        end
        local v = hung(n.immo)
        if on(v, now) then
            st.fire = "ok"
            st.fireLeft = v > 0 and (v - now) or 0
        end
        st.flame = on(hung(n.flame), now)
    end
    st.fbKnown = ns.IsTalent(d.fb) and ns.IsLearned(d.fb)
    st.fb = st.fbKnown and not (opt and opt.fb == "off") and st.fire ~= "none" and st.fireLeft > 0
        and st.fireLeft <= d.fbLeft
    st.confCd = ns.WTile.Left(d.gcd, GetSpellCooldown(n.conf))
    if ns.IsLearned(d.chaos) then
        st.chaosCd = ns.WTile.Left(d.gcd, GetSpellCooldown(n.chaos))
    else
        st.chaos = "gone"
    end
    st.imp, _, st.impLeft = buff(n.imp, now)
    local fl, cnt, left = buff(n.flow, now)
    if fl then st.flow, st.flowLeft = math.max(1, cnt), left end
    judge(st, opt)
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    layer.tiles, layer.looks = {}, {}
    local count = view == "row" and 3 or 1
    for i = 1, count do
        layer.tiles[i] = ns.WTile.New(layer, (i - 1) * (s + gap), 0, s)
        layer.looks[i] = {}
    end
end
local function lookFire(k, st)
    local S = ns.STATE
    local n = names()
    local v = st.fire
    k.icon = n and n.iIcon
    local miss = v == "none" and st.fight and st.live
    k.grey = v == "none" and not miss
    k.alpha = 1
    k.edge = (v == "soon" and S.soon) or (miss and S.bad) or nil
    k.text = st.fireLeft > 0 and ns.Widget.Left(st.fireLeft) or ""
    k.textColor = v == "soon" and S.soon or S.text
    k.glow = false
end
local function lookConf(k, st)
    local S = ns.STATE
    local n = names()
    local v = st.conf
    k.icon = n and n.cIcon
    k.grey = v == "off"
    k.alpha = v == "wait" and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "gold" and S.full) or nil
    k.text = v == "off" and ns.Widget.Left(st.confCd) or ""
    k.textColor = S.text
    k.glow = false
end
local function lookChaos(k, st)
    local S = ns.STATE
    local n = names()
    local v = st.chaos
    k.icon = n and n.hIcon
    k.grey = v == "off"
    k.alpha = v == "gone" and 0 or 1
    k.edge = (v == "ok" and S.ok) or (v == "gold" and S.full) or nil
    k.text = v == "off" and ns.Widget.Left(st.chaosCd) or ""
    k.textColor = S.text
    k.glow = v == "gold"
end
local LOOK = { fire = lookFire, conf = lookConf, chaos = lookChaos }
local ROW = { "fire", "conf", "chaos" }
local function paint(layer, st, view)
    local S = ns.STATE
    local flow = (st.num and st.flow > 0) and tostring(st.flow) or nil
    for i, t in ipairs(layer.tiles) do
        local cell = view == "row" and ROW[i] or st.first
        local k = layer.looks[i]
        LOOK[cell](k, st)
        k.corner = (view ~= "row" or cell == "chaos") and st.chaos ~= "gone" and flow or nil
        k.cornerColor = S.full
        ns.WTile.Paint(t, k)
    end
end
local attrCache = {}
local EMPTY = {}
local function click(field)
    return function(st)
        if field == "chaos" and st and st.chaos == "gone" then return EMPTY end
        local n = names()
        local name = n and n[field]
        if not name or name == "" then return EMPTY end
        local a = attrCache[name]
        if not a then
            a = { type = "spell", spell = name }
            attrCache[name] = a
        end
        return a
    end
end
local CELLS = {
    row = {
        { cx = 0, cy = 0, attrs = click("immo") },
        { cx = 1, cy = 0, attrs = click("conf") },
        { cx = 2, cy = 0, attrs = click("chaos") },
    },
    one = { { cx = 0, cy = 0 } },
}
local function tenths(x)
    return (string.format("%.1f", math.floor(x * 10 + 0.5) / 10):gsub("%.", ns.T("widget.wdf_dec")))
end
local function rows(st)
    local S = ns.STATE
    local W = ns.Widget
    local n = names()
    local out = {}
    if not n then return out end
    if not st.live then
        out[#out + 1] = { l = ns.T("widget.wdf_no_target"), lc = S.mute }
    elseif st.fire == "none" then
        out[#out + 1] = { l = n.immo, r = ns.T("widget.wdf_none"), rc = st.fight and S.bad or S.mute }
    else
        local left = st.fireLeft > 0 and W.Left(st.fireLeft) or ns.T("widget.wdf_up")
        out[#out + 1] = { l = n.immo, r = ns.T("widget.wdf_fire", left, tenths(st.win)), rc = st.fire == "soon" and S.soon or nil }
    end
    local conf = (st.conf == "off" and ns.T("widget.wdf_cd", W.Left(st.confCd)))
        or (st.conf == "wait" and ns.T("widget.wdf_need")) or ns.T("widget.wdf_ready")
    out[#out + 1] = { l = n.conf, r = conf, rc = (st.conf == "ok" and S.ok) or (st.conf == "gold" and S.full) or S.mute }
    if st.fb then out[#out + 1] = { l = ns.T("widget.wdf_fb_on"), lc = S.full } end
    if st.chaos ~= "gone" then
        local chaos = st.chaos == "off" and ns.T("widget.wdf_cd", W.Left(st.chaosCd)) or ns.T("widget.wdf_ready")
        out[#out + 1] = { l = n.chaos, r = chaos, rc = (st.chaos == "ok" and S.ok) or (st.chaos == "gold" and S.full) or S.mute }
    end
    if st.imp then
        out[#out + 1] = { l = n.imp, r = ns.T("widget.wdf_imp", W.Left(st.impLeft)), rc = S.full }
    end
    if st.flow > 0 then
        out[#out + 1] = { l = n.flow, r = ns.T("widget.wdf_flow", st.flow, W.Left(st.flowLeft)) }
        out[#out + 1] = { l = ns.T("widget.wdf_flow_use"), lc = S.mute }
    end
    return out
end
local TITLE = { fire = "immo", conf = "conf", chaos = "chaos" }
local function tip(i, st, view)
    local n = names()
    if not n then return nil end
    local cell = view == "row" and ROW[i] or st.first
    if cell == "chaos" and st.chaos == "gone" then return nil end
    return n[TITLE[cell]], nil, rows(st)
end
local DEMO = {
    solo  = { "none", 0, false, 0, 0, false, 0, false },
    party = { "ok", 11, false, 0, 6, false, 0, true },
    raid  = { "ok", 1.2, false, 0, 0, true, 3, true },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local opt = scene.opt or {}
    local st = {
        live = true, fight = p[8] or scene.fight, fire = p[1], fireLeft = p[2], win = d.cast, flame = p[3],
        conf = "wait", confCd = p[4], chaos = "off", chaosCd = p[5], fbKnown = true, imp = p[6], impLeft = p[6] and 6 or 0,
        flow = p[7], flowLeft = p[7] > 0 and 11 or 0, num = opt.num ~= "off",
    }
    st.fb = opt.fb ~= "off" and st.fire ~= "none" and st.fireLeft > 0 and st.fireLeft <= d.fbLeft
    judge(st, opt)
    return st
end
ns.Widget.Register(KEY, {
    info = { text = "widget.warlock_destro_fire_info", demo = demo },
    icon = 17962,
    label = "widget.warlock_destro_fire",
    class = "WARLOCK",
    views = { row = { w = 3, h = 1 }, one = { w = 1, h = 1 } },
    order = { "row", "one" },
    view = "row",
    covers = { "spell:47811", "spell:17962", "spell:59172", "spell:54277", "spell:47283" },
    avail = avail,
    events = {
        UNIT_AURA = { player = true, target = true }, PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not st.shown then return nil end
        if st.fireLeft > 0 or st.confCd > 0 or st.chaosCd > 0 or st.imp or st.flow > 0 then return data().tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.shown end,
    cells = function(view) return CELLS[view] or CELLS.row end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.wdf_show", values = {
            { v = nil, label = "widget.wdf_with_target" }, { v = "all", label = "widget.wdf_always" },
        } },
        { key = "fb", label = "widget.wdf_fb", values = {
            { v = nil, label = "widget.wdf_mark" }, { v = "off", label = "widget.wdf_no" },
        } },
        { key = "num", label = "widget.wdf_num", values = {
            { v = nil, label = "widget.wdf_digit" }, { v = "off", label = "widget.wdf_no" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.warlockDestroFireWidgetLoaded = true

local _, ns = ...
local MINI_PART = 0.45
local function data()
    return ns.widgetData.warlock_curse
end
local KEYS = { "el", "agony", "doom" }
local cache
local function names()
    if cache then return cache end
    local d = data()
    local n = { icon = {}, any = {}, own = {} }
    for _, k in ipairs(KEYS) do
        local name, _, icon = GetSpellInfo(d[k])
        if not name then return nil end
        n[k], n.icon[k] = name, icon
        n.own[#n.own + 1] = name
    end
    local cat = ns.widgetData.tdebuff and ns.widgetData.tdebuff.cats.spell
    local seen = {}
    for _, e in ipairs(cat and cat.list or {}) do
        local name = GetSpellInfo(e.id)
        if name and not seen[name] then
            seen[name] = true
            n.any[#n.any + 1] = name
        end
    end
    cache = n
    return n
end
local function avail()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return false end
    local d = data()
    return ns.IsLearned(d.el) or ns.IsLearned(d.agony) or ns.IsLearned(d.doom)
end
local function primary(opt)
    local d = data()
    local k = opt and opt.dmg
    if k ~= "agony" and k ~= "doom" then
        local v = ns.CurrentVariant and ns.CurrentVariant()
        k = d.spec[v or ""] or "agony"
    end
    if k == "doom" and not ns.IsLearned(d.doom) then k = "agony" end
    return k
end
local function unitOf(opt)
    local l = opt and opt.unit or "target"
    if l == "target" or l == "focus" then return l end
    return ns.Units and ns.Units.Resolve(l) or nil
end
local BOSS_CAST = "/cast [target=boss1,harm,nodead][target=boss2,harm,nodead][target=boss3,harm,nodead][target=boss4,harm,nodead][] %s"
local function castAttrs(opt, spell, b, out)
    local l = opt and opt.unit
    if l == "boss" then
        out["type" .. b], out["macrotext" .. b] = "macro", BOSS_CAST:format(spell)
        return out
    end
    out["type" .. b], out["spell" .. b] = "spell", spell
    if l == "focus" then out.unit = "focus" end
    return out
end
local function isBoss(unit)
    return UnitClassification(unit) == "worldboss" or UnitLevel(unit) == -1
end
local function on(v, now)
    return (v and (v == 0 or v > now)) and true or false
end
local function judge(st)
    if st.wait or not st.want then
        st.verdict = "off"
    elseif st.cur == st.want then
        st.verdict = (st.left > 0 and st.left < data().soon[st.want]) and "soon" or "ok"
    elseif st.cur then
        st.verdict = "bad"
    else
        st.verdict = "none"
    end
end
local function state(opt)
    local d = data()
    local n = names()
    local prim = primary(opt)
    local st = { live = false, wait = false, prim = prim, dmg = prim, rmb = false, left = 0, doomCd = 0, verdict = "off" }
    local R = ns.Raid
    if not (n and R) then return st end
    R.WatchEnemy("warlock_curse", n.any, false)
    R.WatchEnemy("warlock_curse.own", n.own, true)
    R.Touch()
    local u = unitOf(opt)
    st.unit = u
    if not (u and UnitExists(u) and UnitCanAttack("player", u)) or UnitIsDeadOrGhost(u) then return st end
    st.live = true
    st.doomCd = ns.WTile.Left(d.gcd, GetSpellCooldown(n.doom))
    local e = R.Enemy(u)
    if not e or e.guid ~= UnitGUID(u) then
        st.wait = true
        return st
    end
    local now = GetTime()
    for _, k in ipairs(KEYS) do
        local v = e.own[n[k]]
        if on(v, now) then
            st.cur = k
            st.left = v > 0 and (v - now) or 0
            break
        end
    end
    for _, name in ipairs(n.any) do
        if on(e.harm[name], now) and not (name == n.el and st.cur == "el") then
            st.other = name
            break
        end
    end
    if st.cur == "agony" or st.cur == "doom" then
        st.dmg = st.cur
    elseif prim == "doom" and not (isBoss(u) and st.doomCd == 0) then
        st.dmg = "agony"
    end
    st.rmb = st.dmg ~= prim
    local mode = opt and opt.el
    local el = mode == "mine" or (mode ~= "never" and not st.other)
    st.want = el and "el" or st.dmg
    judge(st)
    return st
end
local function edgeOf(verdict)
    local S = ns.STATE
    return (verdict == "ok" and S.ok) or (verdict == "soon" and S.soon) or (verdict == "none" and S.none) or (verdict == "bad" and S.bad) or nil
end
local function build(layer, view)
    local s = layer.h
    layer.tiles = { ns.WTile.New(layer, 0, 0, s) }
    layer.looks = { {} }
    if view == "pair" then
        layer.tiles[2] = ns.WTile.New(layer, s + (layer.gap or 2), 0, s)
        layer.looks[2] = {}
        return
    end
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.mini = top:CreateTexture(nil, "OVERLAY")
    layer.mini:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", -1, 1)
    layer.mini:SetWidth(s * MINI_PART)
    layer.mini:SetHeight(s * MINI_PART)
end
local function look(k, st, key, n)
    local S = ns.STATE
    local need = st.want == key
    local hung = st.cur == key
    k.icon = n.icon[key]
    k.alpha = (need or hung) and 1 or data().dim
    k.edge = need and edgeOf(st.verdict) or nil
    k.text = (hung and st.left > 0) and ns.Widget.Left(st.left) or ""
    k.textColor = (not need and S.bad) or (st.verdict == "soon" and S.soon) or S.text
end
local function paint(layer, st, view)
    local n = names()
    if not n then return end
    local W = ns.Widget
    if view == "pair" then
        local a, b = layer.looks[1], layer.looks[2]
        look(a, st, "el", n)
        look(b, st, st.dmg, n)
        b.mark = st.rmb and ns.T("widget.wc_rmb") or nil
        b.markColor = ns.STATE.soon
        ns.WTile.Paint(layer.tiles[1], a)
        ns.WTile.Paint(layer.tiles[2], b)
        return
    end
    local k = layer.looks[1]
    local key = st.want or st.prim
    look(k, st, key, n)
    if not st.want then k.alpha = data().dim end
    ns.WTile.Paint(layer.tiles[1], k)
    local wrong = st.verdict == "bad" and st.cur
    W.Tex(layer.mini, wrong and n.icon[wrong] or nil)
    W.Alpha(layer.mini, wrong and 1 or 0)
end
local PAIR = {
    { cx = 0, cy = 0, attrs = function(_, opt)
        local n = names()
        if not n then return {} end
        return castAttrs(opt, n.el, "", {})
    end },
    { cx = 1, cy = 0, clicks = "AnyUp", attrs = function(_, opt)
        local n = names()
        if not n then return {} end
        local p = primary(opt)
        return castAttrs(opt, n[p == "doom" and "agony" or "doom"], "2", castAttrs(opt, n[p], "1", {}))
    end },
}
local NONE = {}
local function tip(st)
    local n = names()
    if not (n and st.live and st.want) then return nil end
    local S = ns.STATE
    local rows = {}
    if st.other then
        local who = st.unit and select(8, UnitDebuff(st.unit, st.other))
        local name = who and UnitName(who)
        rows[1] = { l = ns.T("widget.wc_cat"), r = name and ns.T("widget.wc_by", st.other, name) or st.other, rc = S.ok }
    elseif st.cur == "el" then
        rows[1] = { l = ns.T("widget.wc_cat"), r = ns.T("widget.wc_me"), rc = S.ok }
    else
        rows[1] = { l = ns.T("widget.wc_cat"), r = ns.T("widget.wc_nobody"), rc = S.bad }
    end
    if st.cur then
        rows[#rows + 1] = { l = ns.T("widget.wc_mine"), r = n[st.cur] .. " " .. ns.Widget.Left(st.left),
            rc = st.cur == st.want and S.text or S.bad }
    end
    local line = ns.T("widget.wc_cast", n[st.want])
    if st.rmb and st.want ~= "el" then line = line .. " " .. ns.T("widget.wc_rmb_tip") end
    return ns.T("widget.warlock_curse"), line, rows
end
local DEMO = { solo = { false, nil, 0 }, party = { false, "el", 240 }, raid = { true, "dmg", 1 } }
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local prim = primary(scene.opt)
    local n = names()
    local st = { live = true, wait = false, prim = prim, dmg = prim, rmb = false, left = p[3], doomCd = 0, unit = "target" }
    st.cur = p[2] == "dmg" and prim or p[2]
    st.other = (p[1] and n) and n.any[2] or nil
    st.want = p[1] and prim or "el"
    judge(st)
    return st
end
local function dmgValues()
    local n = names()
    return {
        { v = nil, label = "widget.wc_by_spec" },
        { v = "agony", text = n and n.agony or "agony" },
        { v = "doom", text = n and n.doom or "doom" },
    }
end
ns.Widget.Register("warlock_curse", {
    info = { text = "widget.warlock_curse_info", demo = demo },
    icon = 47865,
    label = "widget.warlock_curse",
    class = "WARLOCK",
    views = { pair = { w = 2, h = 1 }, one = { w = 1, h = 1 } },
    order = { "pair", "one" },
    view = "pair",
    covers = { "spell:47864", "spell:47865", "spell:47867" },
    avail = avail,
    events = {
        UNIT_AURA = { target = true, focus = true, boss1 = true, boss2 = true, boss3 = true, boss4 = true },
        PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true, INSTANCE_ENCOUNTER_ENGAGE_UNIT = true,
        SPELL_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true,
        PLAYER_REGEN_ENABLED = true,
    },
    tick = function(st) return (st.live and (st.cur or st.wait or (st.prim == "doom" and st.doomCd > 0))) and data().tick or nil end,
    State = state,
    active = function(st) return st.live end,
    Build = build,
    Paint = paint,
    cells = function(view) return view == "pair" and PAIR or NONE end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "el", label = "widget.wc_el", values = {
            { v = nil, label = "widget.wc_auto" }, { v = "mine", label = "widget.wc_el_mine" }, { v = "never", label = "widget.wc_el_never" },
        } },
        { key = "dmg", label = "widget.wc_dmg", values = dmgValues },
        { key = "unit", label = "widget.mine_unit", values = {
            { v = nil, label = "unit.target" }, { v = "focus", label = "unit.focus" }, { v = "boss", label = "unit.boss" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("warlock_curse") end)
end
ns.warlockCurseWidgetLoaded = true

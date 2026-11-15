local _, ns = ...
local PAD = 2
local LINE_PART = 0.3
local function data()
    return ns.widgetData.warlock_affli_snap
end
local cache
local function names()
    if cache then return cache end
    local d = data()
    local corr, _, icon = GetSpellInfo(d.corr)
    if not corr then return nil end
    local n = { corr = corr, icon = icon, mods = {} }
    for i, m in ipairs(d.mods) do n.mods[i] = GetSpellInfo(m.id) or "" end
    cache = n
    return n
end
local function power()
    local n = names()
    if not n then return nil end
    local d = data()
    local sp = GetSpellBonusDamage(d.school) or 0
    local crit = GetSpellCritChance(d.school) or 0
    local m, on = 1, {}
    for i, mod in ipairs(d.mods) do
        local name = n.mods[i]
        if name ~= "" and UnitBuff("player", name) then
            m = m * (1 + mod.pct / 100)
            on[#on + 1] = name
        end
    end
    return { p = (d.base + d.coef * sp) * (1 + crit / 100 * d.crit) * m, sp = sp, crit = crit, m = m, on = on }
end
local snaps = {}
local pending
local pendingTo = ""
local NAMED = { "target", "focus", "mouseover", "boss1", "boss2", "boss3", "boss4" }
local function guidNamed(name)
    if name == "" then return UnitGUID("target") end
    local short = name:match("^([^%-]*)")
    for _, u in ipairs(NAMED) do
        local un = UnitName(u)
        if (un == name or un == short) and UnitCanAttack("player", u) then return UnitGUID(u) end
    end
    return nil
end
local function keep(guid, s)
    snaps[guid] = s
    local count, old, oldT = 0, nil, nil
    for g, x in pairs(snaps) do
        count = count + 1
        if not oldT or x.t < oldT then old, oldT = g, x.t end
    end
    if count > data().keep and old then snaps[old] = nil end
end
local casts = CreateFrame("Frame")
casts:RegisterEvent("UNIT_SPELLCAST_SENT")
casts:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
casts:SetScript("OnEvent", function(_, event, unit, spell, _, target)
    if unit ~= "player" then return end
    local n = names()
    if not (n and spell == n.corr) then return end
    if event == "UNIT_SPELLCAST_SENT" then
        pending, pendingTo = power(), target or ""
        return
    end
    local s = pending or power()
    local guid = guidNamed(pendingTo)
    pending, pendingTo = nil, ""
    if not (s and guid) then return end
    s.t = GetTime()
    keep(guid, s)
    ns.Widget.Poke("warlock_affli_snap")
end)
local function avail()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return false end
    if not ns.IsLearned(data().corr) then return false end
    return (ns.CurrentVariant and ns.CurrentVariant()) == "affli"
end
local function unitOf(opt)
    local l = opt and opt.unit or "target"
    if l == "target" or l == "focus" then return l end
    return ns.Units and ns.Units.Resolve(l) or nil
end
local function on(v, now)
    return (v and (v == 0 or v > now)) and true or false
end
local function judge(st)
    if not st.live then
        st.verdict = "none"
    elseif not (st.snap and st.now) then
        st.verdict = "off"
    elseif st.diff >= st.thr then
        st.verdict = "soon"
    elseif -st.diff >= st.thr then
        st.verdict = "full"
    else
        st.verdict = "ok"
    end
end
local function diffOf(a, b)
    if b.p <= 0 then return 0 end
    local x = (a.p / b.p - 1) * 100
    return x >= 0 and math.floor(x + 0.5) or -math.floor(-x + 0.5)
end
local function state(opt)
    local d = data()
    local st = { live = false, diff = 0, thr = (opt and opt.thr) or d.thr, verdict = "none" }
    local n = names()
    local R = ns.Raid
    if not n then return st end
    if R then
        R.WatchEnemy("warlock_affli_snap", { n.corr }, true)
        R.Touch()
    end
    local u = unitOf(opt)
    st.unit = u
    if not (u and UnitExists(u) and UnitCanAttack("player", u)) or UnitIsDeadOrGhost(u) then return st end
    local guid = UnitGUID(u)
    local e = R and R.Enemy(u)
    local hung = e and e.guid == guid and on(e.own[n.corr], GetTime())
    if not hung then hung = UnitDebuff(u, n.corr, nil, "PLAYER") and true or false end
    if not hung then
        local old = guid and snaps[guid]
        if old and GetTime() - old.t > d.grace then snaps[guid] = nil end
        return st
    end
    st.live = true
    st.snap = guid and snaps[guid] or nil
    st.now = power()
    if st.snap and st.now then st.diff = diffOf(st.now, st.snap) end
    judge(st)
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local x = s + (layer.gap or 2)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", x, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    local px = math.max(8, math.floor(s * LINE_PART + 0.5))
    layer.was = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.was:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.was:SetJustifyH("LEFT")
    layer.cur = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.cur:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.cur:SetJustifyH("LEFT")
    for _, fs in ipairs({ layer.was, layer.cur }) do
        local file, _, flags = fs:GetFont()
        if file then fs:SetFont(file, px, flags or "") end
    end
end
local function line(x)
    if not x then return "?" end
    local s = ns.T("widget.was_line", math.floor(x.p + 0.5), math.floor(x.crit + 0.5))
    if x.m > 1.0001 then s = s .. " " .. ns.T("widget.was_mult", x.m) end
    return s
end
local function signed(d)
    return d >= 0 and ns.T("widget.was_plus", d) or ns.T("widget.was_minus", -d)
end
local function paint(layer, st, view)
    local n = names()
    if not n then return end
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    k.icon = n.icon
    k.grey = v == "off"
    k.alpha = (v == "ok" or v == "none") and data().dim or 1
    k.edge = (v == "soon" and S.soon) or (v == "full" and S.full) or nil
    k.text = (v == "soon" or v == "full") and signed(st.diff) or ""
    k.textColor = v == "full" and S.full or S.soon
    k.corner = v == "off" and "?" or nil
    k.cornerColor = S.text
    k.glow = v == "soon"
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    local live = st.live
    W.Text(layer.was, live and line(st.snap) or "")
    W.Color(layer.was, v == "full" and S.full or (v == "off" and S.mute) or S.text)
    W.Text(layer.cur, live and line(st.now) or "")
    W.Color(layer.cur, v == "soon" and S.soon or S.text)
end
local attrCache = {}
local BOSS_CAST = "/cast [target=boss1,harm,nodead][target=boss2,harm,nodead][target=boss3,harm,nodead][target=boss4,harm,nodead][] %s"
local CELLS = {
    { cx = 0, cy = 0, attrs = function(_, opt)
        local n = names()
        if not n then return {} end
        local l = (opt and opt.unit) or "target"
        local a = attrCache[l]
        if a then return a end
        if l == "boss" then
            a = { type = "macro", macrotext = BOSS_CAST:format(n.corr) }
        else
            a = { type = "spell", spell = n.corr, unit = l == "focus" and "focus" or nil }
        end
        attrCache[l] = a
        return a
    end },
}
local function tipLine(x)
    local s = ns.T("widget.was_tip_line", math.floor(x.p + 0.5), math.floor(x.sp + 0.5), x.crit)
    if #x.on > 0 then s = s .. " " .. ns.T("widget.was_mult", x.m) .. " (" .. table.concat(x.on, ", ") .. ")" end
    return s
end
local function tip(st)
    if not st.live then return nil end
    local S = ns.STATE
    local rows = {}
    rows[1] = { l = ns.T("widget.was_snap"), r = st.snap and tipLine(st.snap) or "?", rc = st.snap and S.text or S.mute }
    if st.now then rows[2] = { l = ns.T("widget.was_now"), r = tipLine(st.now) } end
    if st.snap and st.now then
        local c = (st.verdict == "soon" and S.soon) or (st.verdict == "full" and S.full) or S.text
        rows[#rows + 1] = { l = ns.T("widget.was_diff"), r = signed(st.diff), rc = c }
    end
    local key = (st.verdict == "soon" and "widget.was_do_recast") or (st.verdict == "full" and "widget.was_do_keep")
        or (st.verdict == "off" and "widget.was_do_unknown") or "widget.was_do_ok"
    return ns.T("widget.warlock_affli_snap"), ns.T(key), rows
end
local function fake(p, sp, crit, m)
    return { p = p, sp = sp, crit = crit, m = m, on = {}, t = 0 }
end
local DEMO = {
    solo  = { fake(4410, 2775, 21, 1), fake(4440, 2790, 21, 1) },
    party = { fake(4410, 2775, 21, 1), fake(4880, 2775, 21, 1.1) },
    raid  = { fake(8820, 2775, 21, 2), fake(4410, 2775, 21, 1) },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local thr = (scene.opt and scene.opt.thr) or data().thr
    local st = { live = true, unit = "target", snap = p[1], now = p[2], thr = thr }
    st.diff = diffOf(p[2], p[1])
    judge(st)
    return st
end
local function thrValues()
    local d = data()
    local out = {}
    for _, t in ipairs(d.thrs) do
        out[#out + 1] = { v = t ~= d.thr and t or nil, text = ns.T("widget.was_pct", t) }
    end
    return out
end
ns.Widget.Register("warlock_affli_snap", {
    info = { text = "widget.warlock_affli_snap_info", demo = demo },
    icon = 47813,
    label = "widget.warlock_affli_snap",
    class = "WARLOCK",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_DAMAGE_DONE_MODS = true, COMBAT_RATING_UPDATE = true,
        PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true, INSTANCE_ENCOUNTER_ENGAGE_UNIT = true,
        SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true,
    },
    State = state,
    active = function(st) return st.live end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "thr", label = "widget.was_thr", values = thrValues },
        { key = "unit", label = "widget.mine_unit", values = {
            { v = nil, label = "unit.target" }, { v = "focus", label = "unit.focus" }, { v = "boss", label = "unit.boss" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("warlock_affli_snap") end)
end
ns.warlockAffliSnapWidgetLoaded = true

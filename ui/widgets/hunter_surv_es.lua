local _, ns = ...
local KEY = "hunter_surv_es"
local DOT_PART = 0.2
local MANA = { 0.45, 0.55, 1, 1 }
local function data()
    return ns.widgetData.hunter_surv_es
end
local function avail()
    if ns.PlayerClass() ~= "HUNTER" then return false end
    return ns.IsLearned(data().es)
end
local procAt
local function tenths(x)
    return (string.format("%.1f", math.floor(x * 10 + 0.5) / 10):gsub("%.", ns.T("widget.h_dec")))
end
local function range(name)
    if not name then return nil end
    return IsSpellInRange(name, "target")
end
local function reach(st)
    if range(st.spell) == 0 then
        if range(GetSpellInfo(data().melee)) == 1 then return "close", "bad" end
        return "far", "bad"
    end
    local usable, noMana = IsUsableSpell(st.spell)
    if not usable and not noMana then return "no", "off" end
    if not usable and st.charges == 0 then return "oom", "bad" end
    if st.charges > 0 then return "lnl", "ok" end
    return "go", "ok"
end
local function state(opt)
    local d = data()
    local st = { charges = 0, lnlLeft = 0, dot = 0, cd = 0, target = false }
    if avail() then
        local name, _, icon = GetSpellInfo(d.es)
        st.spell, st.icon = name, icon
    end
    local lname, _, licon = GetSpellInfo(d.lnl)
    st.lnlName, st.lnlIcon = lname, licon
    if not st.spell then
        st.why, st.verdict = "gone", "off"
        return st
    end
    local now = GetTime()
    if lname then
        local found, _, _, count, _, dur, expires = UnitBuff("player", lname)
        if found then
            st.charges = math.max(1, math.min(d.charges, tonumber(count) or 0))
            expires, dur = tonumber(expires) or 0, tonumber(dur) or 0
            st.lnlLeft = expires > now and (expires - now) or 0
            if expires > 0 and dur > 0 then procAt = expires - dur end
        end
    end
    if procAt then st.icdLeft = math.max(0, procAt + d.icd - now) end
    st.target = (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")) and true or false
    if st.target then
        local found, _, _, _, _, _, expires = UnitDebuff("target", st.spell, nil, "PLAYER")
        expires = tonumber(expires) or 0
        if found and expires > now then st.dot = expires - now end
    end
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
    local keep = not (opt and opt.keep == "off")
    if not st.target then
        st.why, st.verdict = "none", "off"
    elseif st.charges == 0 and st.cd > 0 then
        st.why, st.verdict = "cd", "off"
    elseif keep and st.dot > 0 then
        st.why, st.verdict = "tick", "soon"
    else
        st.why, st.verdict = reach(st)
    end
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 4)
    local ds = math.max(3, math.floor(s * DOT_PART))
    layer.dots = {}
    for i = 1, data().charges do
        local t = top:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetWidth(ds)
        t:SetHeight(ds)
        t:SetPoint("TOP", layer.tile.edge, "TOP", (i - 1.5) * (ds + 2), -2)
        t:SetAlpha(0)
        t.lbbAlpha = 0
        layer.dots[i] = t
    end
    if view == "wide" then
        layer.ltile = ns.WTile.New(layer, s + gap, 0, s)
        layer.llook = {}
    end
end
local SHORT = { far = "widget.hse_far_s", close = "widget.hse_close_s" }
local function edgeOf(st)
    local S = ns.STATE
    local y = st.why
    if y == "go" then return S.ok end
    if y == "lnl" then return S.full end
    if y == "tick" then return S.soon end
    if y == "far" or y == "close" then return S.bad end
    return nil
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local y = st.why
    local k = layer.look
    k.icon = st.icon
    k.grey = y == "cd" or y == "no"
    k.alpha = (y == "none" or y == "gone") and d.dim or 1
    k.tint = y == "oom" and MANA or nil
    k.edge = edgeOf(st)
    k.glow = y == "lnl"
    if y == "cd" then
        k.text, k.textColor = W.Left(st.cd), S.text
    elseif y == "tick" then
        k.text, k.textColor = tenths(st.dot), S.soon
    else
        k.text, k.textColor = "", S.text
    end
    k.corner = SHORT[y] and ns.T(SHORT[y]) or nil
    k.cornerColor = S.bad
    ns.WTile.Paint(layer.tile, k)
    for i, t in ipairs(layer.dots) do
        W.Alpha(t, st.charges > 0 and 1 or 0)
        W.Color(t, i <= st.charges and S.full or S.mute)
    end
    if view ~= "wide" then return end
    local m = layer.llook
    local on = st.charges > 0
    local icd = not on and (st.icdLeft or 0) > 0
    m.icon = st.lnlIcon
    m.grey = not on
    m.alpha = (on or icd) and 1 or d.dim
    m.edge = on and S.full or nil
    m.text = on and tostring(st.charges) or ""
    m.textColor = S.full
    m.corner = on and W.Left(st.lnlLeft) or (icd and W.Left(st.icdLeft) or nil)
    m.cornerColor = S.text
    ns.WTile.Paint(layer.ltile, m)
end
local function click(st)
    if not st.spell then return {} end
    return { type = "spell", spell = st.spell }
end
local CELLS = {
    one = { { cx = 0, cy = 0, attrs = click } },
    wide = { { cx = 0, cy = 0, attrs = click }, { cx = 1, cy = 0 } },
}
local NOTE = {
    none = "widget.hse_none", cd = "widget.hse_cd", tick = "widget.hse_tick", lnl = "widget.hse_lnl",
    go = "widget.hse_go", far = "widget.hse_far", close = "widget.hse_close", oom = "widget.hse_oom",
    no = "widget.hse_cant",
}
local function nextRow(st)
    local S = ns.STATE
    if st.charges > 0 then return { l = ns.T("widget.hse_next"), r = ns.T("widget.hse_next_now"), rc = S.full } end
    if not st.icdLeft then return { l = ns.T("widget.hse_next"), r = ns.T("widget.hse_next_unknown"), rc = S.mute } end
    if st.icdLeft > 0 then return { l = ns.T("widget.hse_next"), r = ns.Widget.Left(st.icdLeft) } end
    return { l = ns.T("widget.hse_next"), r = ns.T("widget.hse_next_any"), rc = S.ok }
end
local function tip(i, st, view)
    if not st.spell then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    if not (view == "wide" and i == 2) then
        local y = st.why
        local c = edgeOf(st) or (y == "oom" and MANA) or S.mute
        if y == "cd" then
            rows[#rows + 1] = { l = ns.T(NOTE.cd), r = W.Left(st.cd) }
        elseif NOTE[y] then
            rows[#rows + 1] = { l = ns.T(NOTE[y]), lc = c }
        end
    end
    if st.charges > 0 then
        rows[#rows + 1] = { l = ns.T("widget.hse_charges"), r = ns.T("widget.hse_charges_left", st.charges, W.Left(st.lnlLeft)), rc = S.full }
    end
    if st.dot > 0 then
        rows[#rows + 1] = { l = ns.T("widget.hse_dot"), r = ns.T("widget.hse_sec", tenths(st.dot)), rc = S.soon }
        if st.charges > 0 or st.cd == 0 then rows[#rows + 1] = { l = ns.T("widget.hse_cut"), lc = S.soon } end
    end
    rows[#rows + 1] = nextRow(st)
    if view == "wide" and i == 2 then return st.lnlName, nil, rows end
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { "go", "ok", 0, 0, 0, 0, 0 },
    party = { "lnl", "ok", 2, 10, 0, 0, 20 },
    raid  = { "tick", "soon", 1, 7, 1.2, 0, 17 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.es)
    local lname, _, licon = GetSpellInfo(d.lnl)
    return {
        spell = name, icon = icon, lnlName = lname, lnlIcon = licon, why = p[1], verdict = p[2], charges = p[3],
        lnlLeft = p[4], dot = p[5], cd = p[6], icdLeft = p[7], target = true,
    }
end
ns.Widget.Register(KEY, {
    info = { text = "widget.hunter_surv_es_info", demo = demo },
    icon = 60053,
    label = "widget.hunter_surv_es",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:60053", "spell:56453" },
    avail = avail,
    events = {
        UNIT_AURA = { player = true, target = true }, PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true,
        SPELL_UPDATE_USABLE = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        local d = data()
        if st.why == "gone" then return nil end
        if st.dot > 0 then return d.fast end
        if st.target or st.charges > 0 or st.cd > 0 or (st.icdLeft or 0) > 0 then return d.tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        if opt and opt.show == "lnl" then return st.charges > 0 end
        return true
    end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "keep", label = "widget.hse_keep", values = {
            { v = nil, label = "widget.hse_yes" }, { v = "off", label = "widget.hse_no" },
        } },
        { key = "show", label = "widget.hse_show", values = {
            { v = nil, label = "widget.hse_always" }, { v = "lnl", label = "widget.hse_only_lnl" },
        } },
    },
})
ns.hunterSurvEsWidgetLoaded = true

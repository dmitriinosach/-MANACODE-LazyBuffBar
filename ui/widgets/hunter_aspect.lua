local _, ns = ...
local KEY = "hunter_aspect"
local MANA = 0
local KINDS = { "main", "travel", "other" }
local function data()
    return ns.widgetData.hunter_aspect
end
local function avail()
    local _, class = UnitClass("player")
    return class == "HUNTER"
end
local function spellOf(id)
    local name, _, icon = GetSpellInfo(id)
    return { name = name, icon = icon, known = name ~= nil and ns.IsLearned(id) }
end
local function mainOf()
    local d = data()
    for _, id in ipairs(d.main) do
        local s = spellOf(id)
        if s.known then return s end
    end
    return spellOf(d.main[1])
end
local function worn(list)
    for _, id in ipairs(list) do
        local name, _, icon = GetSpellInfo(id)
        if name and UnitBuff("player", name, nil, "PLAYER") then return name, icon end
    end
    return nil
end
local function state(opt)
    local d = data()
    local st = { viper = spellOf(d.viper), main = mainOf(), show = (opt and opt.show == "need") and "need" or "always" }
    local cur, max = UnitPower("player", MANA) or 0, UnitPowerMax("player", MANA) or 0
    st.pct = max > 0 and math.floor(cur * 100 / max) or 0
    if ns.Mana then
        ns.Mana.Start()
        st.left = ns.Mana.Left()
    end
    if st.viper.name and UnitBuff("player", st.viper.name, nil, "PLAYER") then
        st.kind, st.name, st.icon = "viper", st.viper.name, st.viper.icon
    else
        for _, kind in ipairs(KINDS) do
            local name, icon = worn(d[kind])
            if name then
                st.kind, st.name, st.icon = (kind == "main") and "dps" or kind, name, icon
                break
            end
        end
    end
    st.icon = st.icon or st.main.icon
    local low, back = (opt and opt.low) or d.low, (opt and opt.back) or d.back
    if UnitIsDeadOrGhost("player") then
        st.why, st.verdict = "dead", "off"
    elseif not st.kind then
        st.why, st.verdict, st.want = "none", "bad", "main"
    elseif st.kind == "travel" and UnitAffectingCombat("player") then
        st.why, st.verdict, st.want = "travel", "bad", "main"
    elseif st.kind == "viper" then
        if st.pct >= back then
            st.why, st.verdict, st.want = "back", "soon", "main"
        else
            st.why, st.verdict = "ok", "ok"
        end
    elseif st.viper.known and st.pct < low then
        st.why, st.verdict, st.want = "low", "soon", "viper"
    else
        st.why, st.verdict = "ok", "ok"
    end
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s = layer.h
    if view ~= "pair" then
        layer.tile = ns.WTile.New(layer, 0, 0, s)
        layer.look = {}
        return
    end
    layer.tiles = { ns.WTile.New(layer, 0, 0, s), ns.WTile.New(layer, s + (layer.gap or 2), 0, s) }
    layer.looks = { {}, {} }
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 3)
    layer.pct = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    fontSize(layer.pct, s * data().pctFont)
    layer.pct:SetPoint("BOTTOM", layer, "BOTTOM", 0, 1)
end
local function pctInk(st)
    local S = ns.STATE
    if st.verdict == "soon" then return S.soon end
    if st.verdict == "bad" then return S.bad end
    if st.kind == "viper" then return data().blue end
    return S.text
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local pct = st.pct .. "%"
    local edge = (v == "soon" and S.soon) or (v == "bad" and S.bad) or nil
    if view ~= "pair" then
        local k = layer.look
        k.icon = st.icon
        k.grey = not st.kind or v == "off"
        k.alpha = v == "off" and d.dim or 1
        k.edge = edge
        k.corner = pct
        k.cornerColor = pctInk(st)
        ns.WTile.Paint(layer.tile, k)
        return
    end
    for i, t in ipairs(layer.tiles) do
        local viper = i == 1
        local s = viper and st.viper or st.main
        local on = (viper and st.kind == "viper") or (not viper and st.kind == "dps")
        local need = st.want == (viper and "viper" or "main") and v ~= "off"
        local k = layer.looks[i]
        k.icon = s.icon
        k.grey = not s.known or v == "off"
        k.alpha = (on or need) and 1 or d.dim
        k.edge = need and edge or nil
        k.glow = need
        ns.WTile.Paint(t, k)
    end
    W.Text(layer.pct, pct)
    W.Color(layer.pct, pctInk(st))
end
local function macro(s)
    if not (s.known and s.name) then return nil end
    return "/cast !" .. s.name
end
local ONE = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp", attrs = function(st)
        local out = {}
        local a, b = macro(st.viper), macro(st.main)
        if a then out.type1, out.macrotext1 = "macro", a end
        if b then out.type2, out.macrotext2 = "macro", b end
        return out
    end },
}
local PAIR = {
    { cx = 0, cy = 0, attrs = function(st)
        local m = macro(st.viper)
        return m and { type = "macro", macrotext = m } or {}
    end },
    { cx = 1, cy = 0, attrs = function(st)
        local m = macro(st.main)
        return m and { type = "macro", macrotext = m } or {}
    end },
}
local ADVICE = { low = "widget.ha_low", back = "widget.ha_back", none = "widget.ha_none", travel = "widget.ha_travel" }
local function tip(_, st)
    local S = ns.STATE
    local rows = { { l = ns.T("widget.ha_mana"), r = st.pct .. "%", rc = pctInk(st) } }
    if st.left then
        rows[#rows + 1] = { l = ns.T("widget.ha_left", ns.Widget.Left(st.left)), lc = S.mute }
    end
    if ADVICE[st.why] then
        local name = (st.want == "viper" and st.viper.name) or st.main.name or ""
        rows[#rows + 1] = { l = ns.T(ADVICE[st.why], name), lc = st.verdict == "bad" and S.bad or S.soon }
    end
    return st.name or ns.T("widget.ha_noaspect"), nil, rows
end
local DEMO = {
    solo  = { "dps", 92, "ok", "ok" },
    party = { "dps", 12, "low", "soon", "viper" },
    raid  = { "viper", 74, "back", "soon", "main" },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local vn, _, vi = GetSpellInfo(d.viper)
    local mn, _, mi = GetSpellInfo(d.main[1])
    local viper = p[1] == "viper"
    return { kind = p[1], name = viper and vn or mn, icon = viper and vi or mi, pct = p[2], why = p[3], verdict = p[4],
             want = p[5], viper = { name = vn, icon = vi, known = true }, main = { name = mn, icon = mi, known = true },
             show = "always" }
end
local function percents(list, def)
    local out = {}
    for i, n in ipairs(list) do
        local v = n
        if n == def then v = nil end
        out[i] = { v = v, text = n .. "%" }
    end
    return out
end
ns.Widget.Register(KEY, {
    info = { text = "widget.hunter_aspect_info", demo = demo },
    icon = 34074,
    label = "widget.hunter_aspect",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "one",
    covers = { "spell:34074", "spell:61847", "spell:27044" },
    avail = avail,
    events = {
        UNIT_AURA = "player", UNIT_MANA = "player", UNIT_MAXMANA = "player", PLAYER_DEAD = true, PLAYER_ALIVE = true,
        PLAYER_UNGHOST = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true,
        PLAYER_ENTERING_WORLD = true,
    },
    State = state,
    active = function(st) return st.show == "always" or st.verdict == "soon" or st.verdict == "bad" end,
    Build = build,
    Paint = paint,
    cells = function(view) return view == "pair" and PAIR or ONE end,
    Tip = tip,
    opts = {
        { key = "low", label = "widget.ha_opt_low", values = function() return percents(data().lows, data().low) end },
        { key = "back", label = "widget.ha_opt_back", values = function() return percents(data().backs, data().back) end },
        { key = "show", label = "widget.ha_show", values = {
            { v = nil, label = "widget.ha_show_always" }, { v = "need", label = "widget.ha_show_need" },
        } },
    },
})
ns.hunterAspectWidgetLoaded = true

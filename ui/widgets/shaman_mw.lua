local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLOW_TEX = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SPAN = 1.9
local PAD = 3
local function data()
    return ns.widgetData.shaman_mw
end
local function avail()
    local _, class = UnitClass("player")
    return class == "SHAMAN" and ns.IsLearned(data().talent)
end
local function spellOf(opt)
    local want = opt and opt.spell
    for _, id in ipairs(data().spells) do
        if id == want then return id end
    end
    return data().spells[1]
end
local function verdictOf(stacks, thr, left)
    if stacks <= 0 then return "none" end
    if stacks < thr then return "mute" end
    if left > 0 and left < data().burn then return "bad" end
    return "full"
end
local function state(opt)
    local d = data()
    local st = { stacks = 0, max = d.max, left = 0, cd = 0 }
    st.thr = (opt and opt.min) or d.max
    st.always = (opt and opt.show == "always") and true or false
    local name, _, icon = GetSpellInfo(d.aura)
    st.name, st.icon = name, icon
    local sname, _, sicon = GetSpellInfo(spellOf(opt))
    st.spell, st.spellIcon = sname, sicon
    st.chain = GetSpellInfo(d.chain)
    if name then
        local got, _, _, count, _, _, expires = UnitAura("player", name)
        if got then
            st.stacks = (count and count > 0) and count or 1
            if expires and expires > 0 then st.left = math.max(0, expires - GetTime()) end
        end
    end
    if st.spell then st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell)) end
    st.verdict = verdictOf(st.stacks, st.thr, st.left)
    return st
end
local function box(layer, w, h)
    local o = { glowing = false }
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    o.edge:SetWidth(w)
    o.edge:SetHeight(h)
    local bg = layer:CreateTexture(nil, "ARTWORK")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    bg:SetVertexColor(0, 0, 0, 0.6)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(o.edge)
    o.pips = ns.Gauge.New(top, "pips", { w = w - 2 * PAD, h = math.floor(h * 0.4), max = data().max,
        color = ns.STATE.mute, full = ns.STATE.full, gap = 2, flash = false })
    o.pips:Frame():SetPoint("TOP", o.edge, "TOP", 0, -PAD)
    o.left = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.left:SetPoint("BOTTOM", o.edge, "BOTTOM", 0, PAD)
    o.pulse = CreateFrame("Frame", nil, top)
    o.pulse:SetAllPoints(o.edge)
    local g = o.pulse:CreateTexture(nil, "OVERLAY")
    g:SetTexture(GLOW_TEX)
    g:SetBlendMode("ADD")
    g:SetWidth(w + h * (GLOW_SPAN - 1))
    g:SetHeight(h * GLOW_SPAN)
    g:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    local c = ns.STATE.full
    g:SetVertexColor(c[1], c[2], c[3])
    o.pulse:Hide()
    return o
end
local function build(layer, view)
    local s = layer.h
    layer.look = {}
    if view == "one" then
        layer.tile = ns.WTile.New(layer, 0, 0, s)
        return
    end
    local gap = layer.gap or 2
    layer.box = box(layer, view == "btn" and (2 * s + gap) or layer.w, s)
    if view == "btn" then layer.tile = ns.WTile.New(layer, 2 * (s + gap), 0, s) end
end
local function edgeOf(v)
    local S = ns.STATE
    return (v == "mute" and S.mute) or (v == "full" and S.full) or (v == "bad" and S.bad) or nil
end
local function paintBox(o, st, glow)
    local S = ns.STATE
    local W = ns.Widget
    local edge = edgeOf(st.verdict)
    W.Color(o.edge, edge or S.off)
    W.Alpha(o.edge, edge and 1 or 0)
    local c = (st.verdict == "bad" and S.bad) or (st.verdict == "full" and S.full) or S.mute
    if o.c ~= c then
        o.c = c
        o.pips:SetColor(c[1], c[2], c[3], c[4], false)
        o.pips:SetColor(c[1], c[2], c[3], c[4], true)
    end
    o.pips:Set(st.stacks, st.max)
    W.Text(o.left, st.stacks > 0 and W.Left(st.left) or "")
    W.Color(o.left, st.verdict == "bad" and S.bad or S.text)
    if glow ~= o.glowing then
        o.glowing = glow
        if glow then o.pulse:Show() else o.pulse:Hide() end
        ns.Anim.Pulse(o.pulse, glow)
    end
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local hot = v == "full" or v == "bad"
    local k = layer.look
    if view == "one" then
        k.icon = st.icon
        k.grey = st.stacks == 0
        k.alpha = st.stacks == 0 and data().dim or 1
        k.edge = edgeOf(v)
        k.text = st.stacks > 0 and tostring(st.stacks) or ""
        k.textColor = hot and S.full or S.text
        k.corner = st.stacks > 0 and W.Left(st.left) or nil
        k.cornerColor = v == "bad" and S.bad or S.text
        k.glow = hot
        ns.WTile.Paint(layer.tile, k)
        return
    end
    paintBox(layer.box, st, hot and view ~= "btn")
    if view ~= "btn" then return end
    k.icon = st.spellIcon
    k.grey = st.cd > 0
    k.alpha = 1
    k.edge = hot and edgeOf(v) or nil
    k.text = st.cd > 0 and W.Left(st.cd) or ""
    k.glow = hot
    ns.WTile.Paint(layer.tile, k)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell, ["shift-type1"] = "spell", ["shift-spell1"] = st.chain }
    end },
}
local DEMO = { solo = { 2, 24 }, party = { 5, 18 }, raid = { 5, 3 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local opt = scene.opt or {}
    local name, _, icon = GetSpellInfo(d.aura)
    local sname, _, sicon = GetSpellInfo(spellOf(opt))
    local st = { name = name, icon = icon, stacks = p[1], max = d.max, left = p[2], cd = 0,
        spell = sname, spellIcon = sicon, chain = GetSpellInfo(d.chain), always = false }
    st.thr = opt.min or d.max
    st.verdict = verdictOf(st.stacks, st.thr, st.left)
    return st
end
local function spellValues()
    local out = {}
    for i, id in ipairs(data().spells) do
        out[i] = { v = i > 1 and id or nil, text = GetSpellInfo(id) or ("#" .. id) }
    end
    return out
end
ns.Widget.Register("shaman_mw", {
    info = { text = "widget.shaman_mw_info", demo = demo },
    icon = 53817,
    label = "widget.shaman_mw",
    class = "SHAMAN",
    views = { one = { w = 1, h = 1 }, pips = { w = 2, h = 1 }, btn = { w = 3, h = 1 } },
    order = { "one", "pips", "btn" },
    view = "pips",
    covers = { "spell:53817" },
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_TALENT_UPDATE = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
        SPELL_UPDATE_COOLDOWN = true,
    },
    tick = function(st) return (st.stacks > 0 or st.cd > 0) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.stacks > 0 or st.always end,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if not st.name then return nil end
        local line = st.stacks > 0 and ns.T("widget.smw_tip", st.stacks, st.max, math.ceil(st.left))
            or ns.T("widget.smw_zero")
        local rows = st.spell and { { l = ns.T("widget.smw_click", st.spell, st.chain or "?") } } or nil
        return st.name, line, rows
    end,
    opts = {
        { key = "spell", label = "widget.smw_spell", values = spellValues },
        { key = "min", label = "widget.smw_min", values = { { v = nil, text = "5" }, { v = 4, text = "4" } } },
        { key = "show", label = "widget.smw_show",
          values = { { v = nil, label = "widget.smw_show_stacks" }, { v = "always", label = "widget.smw_show_always" } } },
    },
})
ns.shamanMwWidgetLoaded = true

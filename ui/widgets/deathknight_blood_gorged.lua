local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "dk_gorged"
local function data()
    return ns.widgetData.dk_gorged
end
local ranks = {}
local function talentRank(id)
    local r = ranks[id]
    if r then return r end
    local d = data()
    local name = GetSpellInfo(id)
    local group = ns.ActiveSlot and ns.ActiveSlot() or nil
    r = 0
    for i = 1, (name and GetNumTalents and GetNumTalents(d.tab)) or 0 do
        local n, _, _, _, got = GetTalentInfo(d.tab, i, false, false, group)
        if n == name then
            r = tonumber(got) or 0
            break
        end
    end
    if r > 0 or (ns.TalentsKnown and ns.TalentsKnown()) then ranks[id] = r end
    return r
end
local talents = CreateFrame("Frame")
talents:RegisterEvent("PLAYER_TALENT_UPDATE")
talents:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
talents:RegisterEvent("CHARACTER_POINTS_CHANGED")
talents:SetScript("OnEvent", function()
    for k in pairs(ranks) do ranks[k] = nil end
    ns.Widget.Poke(KEY)
end)
local function avail()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT" and talentRank(data().talent) > 0
end
local function clickOf()
    for _, c in ipairs(data().clicks) do
        if ns.IsLearned(c.id) then
            local name, _, icon = GetSpellInfo(c.id)
            if name then return c, name, icon end
        end
    end
    return nil
end
local function warnAt(opt)
    local w = opt and opt.warn
    if w == "off" then return nil end
    return tonumber(w) or data().warn
end
local function verdictOf(st, opt)
    if not st.fight or st.rank == 0 then return "off" end
    if st.hp <= data().line then return "bad" end
    local at = warnAt(opt)
    if st.hyst and at and st.eta <= at then return "soon" end
    return "ok"
end
local function healOf(c)
    if not c or c.heal <= 0 then return 0 end
    local r = c.talent and talentRank(c.talent) or 0
    return c.heal * 100 * (1 + (c.per or 0) * r)
end
local function state(opt)
    local d = data()
    local st = { rank = 0, bonus = 0, hp = 100, fight = false, hyst = false, eta = 0, heal = 0, grow = 0, cd = 0,
                 ready = false }
    local _, class = UnitClass("player")
    if class == "DEATHKNIGHT" then st.rank = talentRank(d.talent) end
    st.bonus = st.rank * d.per
    local c, name, icon = clickOf()
    st.spell = name
    st.icon = icon or select(3, GetSpellInfo(d.talent))
    st.heal = healOf(c)
    st.grow = c and c.grow or 0
    local max = UnitHealthMax("player") or 0
    st.hp = max > 0 and ((UnitHealth("player") or 0) * 100 / max) or 100
    st.fight = (UnitAffectingCombat("player") and not UnitIsDeadOrGhost("player")) and true or false
    local hname = GetSpellInfo(d.hysteria)
    st.hyst = (hname and UnitAura("player", hname, nil, "HELPFUL")) and true or false
    if st.hyst and st.hp > d.line then st.eta = (st.hp - d.line) / d.drain end
    st.verdict = verdictOf(st, opt)
    if st.verdict == "bad" and st.spell then
        st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
        st.ready = st.cd == 0 and IsUsableSpell(st.spell) and true or false
    end
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s = layer.h
    local S = ns.STATE
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 3)
    layer.num = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(layer.num, s * 0.32)
    if view ~= "bar" then
        layer.num:SetPoint("BOTTOM", layer.tile.edge, "BOTTOM", 0, 2)
        return
    end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.num:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    local bw = math.max(8, layer.w - s - gap - 2 * PAD)
    local bh = math.max(4, math.floor(s * 0.3))
    layer.shade = ns.Gauge.New(layer, "bar", { w = bw, h = bh, max = 100, color = { 1, 1, 1, 0.3 }, flash = false })
    layer.shade:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw, h = bh, max = 100, color = S.ok, bg = { 0, 0, 0, 0 },
        ticks = { data().line }, flash = false })
    layer.bar:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.bar:Frame():SetFrameLevel(layer.shade:Frame():GetFrameLevel() + 1)
end
local EDGE = { soon = ns.STATE.soon, bad = ns.STATE.bad }
local function label(st)
    local S = ns.STATE
    local v = st.verdict
    if v == "bad" then return math.floor(st.hp) .. "%", S.bad end
    if v == "soon" then return ns.Widget.Left(math.max(1, st.eta)), S.soon end
    if v == "ok" then return "+" .. st.bonus .. "%", S.text end
    return "", S.text
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = v == "off" and data().dim or 1
    k.edge = EDGE[v]
    k.glow = v == "bad" and st.ready
    ns.WTile.Paint(layer.tile, k)
    local text, ink = label(st)
    W.Text(layer.num, text)
    W.Color(layer.num, ink)
    if view ~= "bar" then return end
    local hp = math.floor(st.hp + 0.5)
    local c = (v == "bad" and S.bad) or (v == "soon" and S.soon) or S.ok
    layer.bar:SetColor(c[1], c[2], c[3], c[4] or 1)
    layer.bar:Set(hp)
    local lift = (st.hp + st.heal) / (1 + (st.grow or 0))
    layer.shade:Set((v == "bad" or v == "soon") and math.min(100, math.floor(lift + 0.5)) or 0)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell, unit = "player" }
    end },
}
local function tip(_, st)
    if st.rank == 0 then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local title = GetSpellInfo(d.talent) or ns.T("widget.dk_gorged")
    local on = st.hp > d.line
    local rows = {
        { l = ns.T("widget.gg_rank", st.rank, d.ranks), r = ns.T("widget.gg_bonus", st.bonus),
          rc = on and S.ok or S.mute },
        { l = ns.T("widget.gg_hp"), r = ns.T("widget.gg_line", math.floor(st.hp), d.line), rc = on and nil or S.bad },
    }
    if st.hyst then
        rows[#rows + 1] = { l = GetSpellInfo(d.hysteria) or "", r = on and ns.T("widget.gg_in", W.Left(math.max(1, st.eta)))
            or "", rc = st.verdict == "soon" and S.soon or nil }
    end
    if st.spell then
        local cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
        local right = cd > 0 and W.Left(cd) or ns.T("widget.gg_ready")
        if st.heal > 0 then right = ns.T("widget.gg_heal", math.floor(st.heal + 0.5), right) end
        rows[#rows + 1] = { l = st.spell, r = right, rc = cd > 0 and S.mute or nil }
    end
    if not st.fight then rows[#rows + 1] = { l = ns.T("widget.gg_calm"), lc = S.mute } end
    rows[#rows + 1] = { l = ns.T("widget.gg_note"), lc = S.mute }
    return title, nil, rows
end
local DEMO = { solo = { 92, false, false }, party = { 79, true, false }, raid = { 64, false, true } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local c = d.clicks[1]
    local name, _, icon = GetSpellInfo(c.id)
    local st = { rank = 5, bonus = 5 * d.per, hp = p[1], fight = true, hyst = p[2], eta = 0, spell = name, icon = icon,
                 heal = c.heal * 100, grow = c.grow or 0, cd = 0, ready = p[3] }
    if st.hyst then st.eta = (st.hp - d.line) / d.drain end
    st.verdict = verdictOf(st, scene.opt)
    return st
end
local function warnValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.warns) do
        out[#out + 1] = { v = (n ~= d.warn) and n or nil, text = ns.T("widget.gg_sec", n) }
    end
    out[#out + 1] = { v = "off", label = "widget.gg_never" }
    return out
end
ns.Widget.Register(KEY, {
    info = { text = "widget.dk_gorged_info", demo = demo },
    icon = 61158,
    label = "widget.dk_gorged",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, bar = { w = 2, h = 1 } },
    order = { "one", "bar" },
    view = "one",
    avail = avail,
    events = {
        UNIT_HEALTH = "player", UNIT_MAXHEALTH = "player", UNIT_AURA = "player", PLAYER_REGEN_ENABLED = true,
        PLAYER_REGEN_DISABLED = true, SPELL_UPDATE_COOLDOWN = true, RUNE_POWER_UPDATE = true, PLAYER_TALENT_UPDATE = true,
        SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true, PLAYER_DEAD = true, PLAYER_UNGHOST = true, PLAYER_ALIVE = true,
    },
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    active = function(st, opt)
        if st.verdict == "off" then return false end
        if st.verdict == "ok" then return (opt and opt.show) == "always" end
        return true
    end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.gg_show", values = {
            { v = nil, label = "widget.gg_show_low" }, { v = "always", label = "widget.gg_show_always" },
        } },
        { key = "warn", label = "widget.gg_warn", values = warnValues },
    },
})
ns.dkGorgedWidgetLoaded = true

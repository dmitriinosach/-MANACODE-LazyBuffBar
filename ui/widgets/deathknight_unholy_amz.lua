local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "dk_amz"
local function data()
    return ns.widgetData.dk_amz
end
local NAMES = {}
local NOBODY = {}
local zone = { start = 0, seen = false }
local function avail()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT" and ns.IsLearned(data().id)
end
local function tenth(x)
    return (string.format("%.1f", math.floor(x * 10 + 0.5) / 10):gsub("%.", ns.T("widget.h_dec")))
end
local function verdictOf(st)
    if st.left > 0 then return "full" end
    if st.dead then return "off" end
    if st.cd > 0 then return "none" end
    return "text"
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { cd = 0, left = 0, n = 0, of = 0, out = 0, miss = NOBODY,
                 dead = (UnitIsDeadOrGhost("player") or UnitInVehicle("player")) and true or false,
                 fight = UnitAffectingCombat("player") and true or false,
                 show = (opt and opt.count == "out") and "out" or "in" }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.verdict = "off"
        return st
    end
    local R = ns.Raid
    local aura = GetSpellInfo(d.aura)
    if R and aura then
        NAMES[1] = aura
        R.Watch(KEY, NAMES)
    end
    local start, dur = GetSpellCooldown(st.spell)
    local on = start and dur and start > 0 and dur > d.short
    if on and start ~= zone.start then
        zone.start, zone.seen, zone.pop = start, false, nil
    end
    if on and start + d.last > now and not zone.pop then
        if R and aura then
            R.Touch()
            local c = R.Count(NAMES, nil, nil, 0, R.Scope(), d.lines, now)
            st.n, st.of, st.out, st.miss = c.n, c.can, c.missN, c.miss
        end
        if st.n > 0 then
            zone.seen = true
        elseif zone.seen then
            zone.pop = now
        end
        if not zone.pop then st.left = start + d.last - now end
    end
    if on then
        if st.left <= 0 then st.cd = math.max(0, start + dur - now) end
        if zone.pop then
            st.held = zone.pop - zone.start
        elseif zone.seen and st.left <= 0 then
            st.held = d.last
        end
    end
    st.verdict = verdictOf(st)
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.count = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    layer.count:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.count:SetJustifyH("LEFT")
    local bw = math.max(8, layer.w - s - gap - 2 * PAD)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw, h = math.max(4, math.floor(s * 0.25)), max = data().last,
        color = ns.STATE.full, flash = false })
    layer.bar:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
end
local function shortCount(st)
    return tostring(st.show == "out" and st.out or st.n)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "none" or v == "off"
    k.alpha = v == "off" and d.dim or 1
    k.edge = v == "full" and S.full or nil
    if v == "full" then
        k.text, k.textColor = W.Left(st.left), S.full
    elseif st.cd > 0 then
        k.text, k.textColor = W.Left(st.cd), S.text
    else
        k.text, k.textColor = "", S.text
    end
    k.corner = (v == "full" and view ~= "wide") and shortCount(st) or nil
    k.cornerColor = (st.show == "out" and st.out > 0) and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    if v == "full" then
        W.Text(layer.count, st.show == "out" and ns.T("widget.amz_out_n", st.out) or (st.n .. "/" .. st.of))
        W.Color(layer.count, (st.show == "out" and st.out > 0) and S.soon or S.text)
        layer.bar:Set(st.left, d.last)
    else
        W.Text(layer.count, st.held and ns.T("widget.amz_held_short", tenth(st.held), d.last) or "")
        W.Color(layer.count, S.mute)
        layer.bar:Set(0, d.last)
    end
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local function tip(_, st)
    if not st.spell then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local rows = {}
    if st.left > 0 then
        rows[#rows + 1] = { l = ns.T("widget.amz_left"), r = W.Left(st.left), rc = S.full }
        rows[#rows + 1] = { l = ns.T("widget.amz_in"), r = ns.T("widget.amz_of", st.n, st.of) }
        if st.out > 0 then
            rows[#rows + 1] = { l = ns.T("widget.amz_miss"), r = tostring(st.out), rc = S.soon }
            for _, m in ipairs(st.miss) do
                rows[#rows + 1] = { l = "  " .. m.name, lc = ns.WTile.ClassColor(m.class) }
            end
            if st.out > #st.miss then rows[#rows + 1] = { l = ns.T("widget.amz_more", st.out - #st.miss), lc = S.mute } end
        end
    end
    if st.held then
        rows[#rows + 1] = { l = ns.T("widget.amz_held"), r = ns.T("widget.amz_held_of", tenth(st.held), d.last),
            rc = st.held < d.last and S.soon or S.text }
    end
    if st.left <= 0 and st.cd > 0 then rows[#rows + 1] = { l = ns.T("widget.amz_cd"), r = W.Left(st.cd) } end
    if st.dead then rows[#rows + 1] = { l = ns.T("widget.amz_dead"), lc = S.mute } end
    if st.verdict == "text" then rows[#rows + 1] = { l = ns.T("widget.amz_ready"), lc = S.mute } end
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { 0, 0, 0, 0 },
    party = { 6, 4, 5, 0 },
    raid  = { 0, 0, 0, 96, 6.2 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local st = { spell = name, icon = icon, left = p[1], n = p[2], of = p[3], out = p[3] - p[2], miss = NOBODY, cd = p[4],
                 held = p[5], dead = false, fight = true, show = (scene.opt and scene.opt.count == "out") and "out" or "in" }
    st.verdict = verdictOf(st)
    return st
end
ns.Widget.Register(KEY, {
    info = { text = "widget.dk_amz_info", demo = demo },
    icon = 51052,
    label = "widget.dk_amz",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:51052" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, PLAYER_DEAD = true, PLAYER_ALIVE = true,
        PLAYER_UNGHOST = true, UNIT_ENTERED_VEHICLE = "player", UNIT_EXITED_VEHICLE = "player",
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
    },
    tick = function(st)
        local d = data()
        if st.left > 0 then return math.min(d.fast, st.left + 0.01) end
        if st.cd > 0 then return d.slow end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    active = function(st, opt) return not (opt and opt.show == "fight" and not st.fight and st.left <= 0) end,
    Tip = tip,
    opts = {
        { key = "count", label = "widget.amz_count", values = {
            { v = nil, label = "widget.amz_count_in" }, { v = "out", label = "widget.amz_count_out" },
        } },
        { key = "show", label = "widget.dk_show", values = {
            { v = nil, label = "widget.dk_show_always" }, { v = "fight", label = "widget.dk_show_fight" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function()
        if zone.start > 0 and not zone.pop and GetTime() < zone.start + data().last then ns.Widget.Poke(KEY) end
    end)
end
ns.dkAmzWidgetLoaded = true

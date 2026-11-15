local _, ns = ...
local KEY = "hunter_mm_chimera"
local function data()
    return ns.widgetData.hunter_mm_chimera
end
local function avail()
    if ns.PlayerClass() ~= "HUNTER" then return false end
    return ns.IsLearned(data().chimera)
end
local function enemy()
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and true or false
end
local function mine(id)
    local name = GetSpellInfo(id)
    if not name then return false, 0 end
    local found, _, _, _, _, _, expires = UnitAura("target", name, nil, "HARMFUL|PLAYER")
    if not found then return false, 0 end
    expires = tonumber(expires) or 0
    if expires <= 0 then return true, math.huge end
    return true, math.max(0, expires - GetTime())
end
local function state()
    local d = data()
    local cname, _, cicon = GetSpellInfo(d.chimera)
    local sname, _, sicon = GetSpellInfo(d.sting)
    local st = { chimera = cname, chimeraIcon = cicon, sting = sname, stingIcon = sicon, cd = 0, left = 0,
                 why = "idle", verdict = "off" }
    st.fight = UnitAffectingCombat("player") and true or false
    if cname then st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(cname)) end
    if not enemy() then return st end
    local found, left = mine(d.sting)
    if found then
        st.left = left
        if left >= st.cd + d.margin then
            st.why, st.verdict = "ok", "ok"
        else
            st.why, st.verdict = "soon", "soon"
        end
        return st
    end
    for _, id in ipairs(d.other) do
        if mine(id) then
            local n, _, icon = GetSpellInfo(id)
            st.badName, st.badIcon = n, icon
            st.why, st.verdict = "bad", "bad"
            return st
        end
    end
    if st.fight then
        st.why, st.verdict = "none", "none"
    else
        st.why, st.verdict = "off", "off"
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "pair" then return end
    layer.tile2 = ns.WTile.New(layer, s + (layer.gap or 2), 0, s)
    layer.look2 = {}
end
local function stingLeft(st)
    if st.left == math.huge then return "" end
    return ns.Widget.Left(st.left)
end
local function stingLook(k, st, center)
    local S = ns.STATE
    local y = st.why
    local timed = y == "ok" or y == "soon"
    local num = timed and stingLeft(st) or ""
    k.icon = (y == "bad" and st.badIcon) or st.stingIcon
    k.grey = y == "none" or y == "off" or y == "idle"
    k.alpha = (y == "off" or y == "idle") and data().dim or 1
    k.tint = nil
    k.edge = (y == "ok" and S.ok) or (y == "soon" and S.soon) or ((y == "bad" or y == "none") and S.bad) or nil
    k.glow = y == "soon"
    k.mark = nil
    if center then
        k.text = y == "none" and "!" or num
        k.textColor = (y == "none" and S.none) or (y == "soon" and S.soon) or S.text
        k.corner = nil
    else
        k.text = y == "none" and "!" or ""
        k.textColor = S.none
        k.corner = num
        k.cornerColor = y == "soon" and S.soon or S.text
    end
end
local function chimeraLook(k, st)
    local S = ns.STATE
    local y = st.why
    local live = y == "ok" or y == "soon"
    k.icon = st.chimeraIcon
    k.grey = false
    k.alpha = (y == "idle" or y == "off") and data().dim or 1
    k.tint = nil
    k.edge = (live and st.cd <= 0) and S.ok or nil
    k.glow = false
    k.text = (y ~= "idle" and st.cd > 0) and ns.Widget.Left(st.cd) or ""
    k.textColor = S.text
    k.mark, k.corner = nil, nil
end
local function paint(layer, st, view)
    local k = layer.look
    if view == "pair" then
        stingLook(k, st, true)
        ns.WTile.Paint(layer.tile, k)
        chimeraLook(layer.look2, st)
        ns.WTile.Paint(layer.tile2, layer.look2)
        return
    end
    local y = st.why
    if y == "bad" or y == "none" or y == "off" then
        stingLook(k, st, false)
    else
        chimeraLook(k, st)
        if y == "ok" or y == "soon" then
            local S = ns.STATE
            k.corner = stingLeft(st)
            k.cornerColor = y == "soon" and S.soon or S.text
            if y == "soon" then k.edge, k.glow = S.soon, true end
        end
    end
    ns.WTile.Paint(layer.tile, k)
end
local CELLS = {
    one = {
        { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
            if not (st.chimera and st.sting) then return {} end
            return { type = "macro", macrotext = "/cast [mod:shift] " .. st.sting .. "; " .. st.chimera }
        end },
    },
    pair = {
        { cx = 0, cy = 0, attrs = function(st)
            if not st.sting then return {} end
            return { type = "spell", spell = st.sting }
        end },
        { cx = 1, cy = 0, attrs = function(st)
            if not st.chimera then return {} end
            return { type = "spell", spell = st.chimera }
        end },
    },
}
local function tip(_, st)
    local S = ns.STATE
    local W = ns.Widget
    local y = st.why
    local row
    if y == "soon" then
        row = { l = ns.T("widget.hmc_tip_soon", stingLeft(st), st.cd > 0 and W.Left(st.cd) or ns.T("widget.hmc_ready")), lc = S.soon }
    elseif y == "bad" then
        row = { l = ns.T("widget.hmc_tip_bad", st.badName or ""), lc = S.bad }
    elseif y == "none" then
        row = { l = ns.T("widget.hmc_tip_none"), lc = S.bad }
    else
        return nil
    end
    return st.chimera, nil, { row }
end
local DEMO = {
    solo  = { "ok", 12, 4, false },
    party = { "soon", 3, 6, true },
    raid  = { "none", 0, 0, true },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local cname, _, cicon = GetSpellInfo(d.chimera)
    local sname, _, sicon = GetSpellInfo(d.sting)
    return { chimera = cname, chimeraIcon = cicon, sting = sname, stingIcon = sicon, left = p[2], cd = p[3],
             fight = p[4], why = p[1], verdict = p[1] }
end
ns.Widget.Register(KEY, {
    info = { text = "widget.hunter_mm_chimera_info", demo = demo },
    icon = 53209,
    label = "widget.hunter_mm_chimera",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "pair",
    covers = { "spell:53209" },
    avail = avail,
    events = {
        UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        local d = data()
        if st.why == "idle" then return nil end
        if st.why == "soon" and st.left < d.hurry then return d.fast end
        if st.cd > 0 or ((st.why == "ok" or st.why == "soon") and st.left ~= math.huge) then return d.tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        local show = opt and opt.show
        if show == "always" then return true end
        if st.why == "idle" then return false end
        if show == "fight" then return st.fight end
        return true
    end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.hmc_show", values = {
            { v = nil, label = "widget.hmc_target" }, { v = "fight", label = "widget.hmc_fight" },
            { v = "always", label = "widget.hmc_always" },
        } },
    },
})
ns.hunterMmChimeraWidgetLoaded = true

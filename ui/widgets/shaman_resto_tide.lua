local _, ns = ...
local NAME = "shaman_resto_tide"
local function data()
    return ns.widgetData.shaman_resto_tide
end
local function avail()
    if ns.PlayerClass() ~= "SHAMAN" then return false end
    local d = data()
    if ns.IsLearned(d.id) then return true end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function fight()
    return (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
end
local function judge(st)
    if not st.spell then
        st.verdict, st.rv, st.wv = "off", "off", "off"
        return
    end
    if not st.talent then st.wv = "none"
    elseif not st.fight then st.wv = "calm"
    elseif st.waves > 0 then st.wv = (st.wLeft > 0 and st.wLeft <= st.burn) and "soon" or "ok"
    else st.wv = "mute" end
    if not st.fight then st.rv = "calm" else st.rv = st.ready and "full" or "mute" end
    if not st.fight then st.verdict = "calm"
    elseif st.wv == "soon" then st.verdict = "soon"
    elseif st.rv == "full" then st.verdict = "full"
    elseif st.wv == "ok" then st.verdict = "ok"
    else st.verdict = "mute" end
end
local function blank(opt, f)
    local d = data()
    return {
        talent = false, waves = 0, wLeft = 0, cd = 0, cdDur = 0, ready = true, fight = f,
        shown = f or (opt and opt.show == "always") and true or false,
        burn = (opt and opt.burn) or d.burn, gear = not (opt and opt.gear == "off"),
        relic = false, stacks = 0, sLeft = 0, t10 = false, tLeft = 0, to = opt and opt.to,
    }
end
local function names(st)
    local d = data()
    local name, _, icon = GetSpellInfo(d.id)
    st.spell, st.icon = name, icon
    local wName, _, wIcon = GetSpellInfo(d.wave)
    st.wSpell, st.wIcon = wName, wIcon
    st.lSpell = GetSpellInfo(d.lesser)
    st.wName = GetSpellInfo(d.waves)
end
local function buff(id, now)
    local n = GetSpellInfo(id)
    if not n then return false, 0, 0 end
    local found, _, _, count, _, _, expires = UnitBuff("player", n)
    if not found then return false, 0, 0 end
    expires = tonumber(expires) or 0
    return true, tonumber(count) or 0, expires > 0 and math.max(0, expires - now) or 0
end
local function state(opt)
    local d = data()
    local st = blank(opt, fight())
    if avail() then names(st) end
    if not st.spell then
        judge(st)
        return st
    end
    if st.to == "tank" and ns.Raid then ns.Raid.Touch() end
    local now = GetTime()
    st.talent = ns.IsLearned(d.talent)
    if st.talent then
        local on, count, left = buff(d.waves, now)
        if on then
            st.waves = math.min(d.charges, math.max(1, count))
            st.wLeft = left
        end
    end
    local start, dur = GetSpellCooldown(st.spell)
    st.cd = ns.WTile.Left(d.gcd, start, dur)
    if st.cd > 0 then st.cdStart, st.cdDur = start, dur end
    st.ready = st.cd <= 0
    if st.gear then
        st.relic = GetInventoryItemID("player", d.relic.slot) == d.relic.item
        if st.relic then
            local on, count, left = buff(d.relic.aura, now)
            if on then st.stacks, st.sLeft = math.max(1, count), left end
        end
        st.t10, _, st.tLeft = buff(d.t10, now)
    end
    judge(st)
    return st
end
local function build(layer, view)
    local d = data()
    local S = ns.STATE
    local s, gap = layer.h, layer.gap or 2
    layer.look, layer.mlook = {}, {}
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.ringBox = CreateFrame("Frame", nil, layer)
    layer.ringBox:SetPoint("TOPLEFT", layer, "TOPLEFT", 1, -1)
    layer.ringBox:SetWidth(s - 2)
    layer.ringBox:SetHeight(s - 2)
    layer.ringBox:SetFrameLevel(layer:GetFrameLevel() + 1)
    layer.ring = ns.Gauge.New(layer.ringBox, "ring", { w = s - 2, h = s - 2, max = 1, color = d.ring, off = d.ringOff, flash = false })
    layer.ring:Frame():SetAllPoints(layer.ringBox)
    layer.ringBox:SetAlpha(0)
    layer.ringBox.lbbAlpha = 0
    if view == "pair" then layer.mtile = ns.WTile.New(layer, s + gap, 0, s) end
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 3)
    local ph = math.max(3, math.floor(s * 0.14))
    local pw = view == "pair" and (s - 10) or math.floor(s * 0.5)
    layer.pips = ns.Gauge.New(top, "pips", { w = pw, h = ph, max = d.charges, color = S.ok, off = S.off, gap = 2, flash = false })
    if view == "pair" then
        layer.pips:Frame():SetPoint("BOTTOM", layer.mtile.edge, "BOTTOM", 0, 3)
    else
        layer.pips:Frame():SetPoint("BOTTOMLEFT", layer.tile.edge, "BOTTOMLEFT", 3, 3)
    end
end
local function paintRing(layer, st)
    local g = layer.ring
    if st.cdStart then
        g:Run(st.cdStart, st.cdDur, 1)
    else
        g:Run(nil)
        g:Set(0, 1)
    end
    ns.Widget.Alpha(layer.ringBox, st.cdStart and 1 or 0)
end
local function pulse(layer, fs, on)
    if layer.pulsing == on then return end
    layer.pulsing = on
    ns.Anim.Pulse(fs, on)
end
local function paintPips(layer, st, v)
    local S = ns.STATE
    local g = layer.pips
    local c = (v == "soon" and S.soon) or (v == "ok" and S.ok) or S.mute
    g:SetColor(c[1], c[2], c[3], c[4])
    g:Set(st.waves, data().charges)
    ns.Widget.Alpha(g:Frame(), st.talent and (st.wv == "calm" and data().calm or 1) or 0)
end
local EDGE = { full = ns.STATE.full, ok = ns.STATE.ok, soon = ns.STATE.soon }
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local one = view ~= "pair"
    paintRing(layer, st)
    local mark = (st.gear and st.t10) and ns.T("widget.srt_t10_mark") or nil
    local wText = st.waves > 0 and W.Left(st.wLeft) or ""
    local k = layer.look
    k.icon = st.icon
    k.grey = st.rv == "off" or st.rv == "mute"
    k.alpha = (st.rv == "off" and d.dim) or (st.rv == "calm" and d.calm) or 1
    k.edge = one and EDGE[st.verdict] or EDGE[st.rv]
    k.corner = (st.gear and st.stacks > 0) and tostring(st.stacks) or nil
    k.cornerColor = st.stacks >= d.relic.max and S.stack or S.text
    k.mark = one and mark or nil
    k.markColor = S.full
    k.text = one and wText or ""
    k.textColor = st.wv == "soon" and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if one then
        paintPips(layer, st, st.wv)
        pulse(layer, layer.tile.text, st.wv == "soon")
        return
    end
    local m = layer.mlook
    local wv = st.wv
    local has = st.talent and wv ~= "off"
    m.icon = st.wIcon
    m.grey = wv == "mute"
    m.alpha = (not has and 0) or (wv == "mute" and d.dim) or (wv == "calm" and d.calm) or 1
    m.edge = has and EDGE[wv] or nil
    m.text = has and wText or ""
    m.textColor = wv == "soon" and S.soon or S.text
    m.mark = has and mark or nil
    m.markColor = S.full
    ns.WTile.Paint(layer.mtile, m)
    paintPips(layer, st, wv)
    pulse(layer, layer.mtile.text, wv == "soon")
end
local function unitOf(opt)
    local to = opt and opt.to
    if to == "focus" then return "focus" end
    if to ~= "tank" then return nil end
    local u = ns.Units and ns.Units.Resolve("tank")
    if not u then return nil end
    local m = ns.Raid and ns.Raid.Member(u)
    return (m and m.click) or u
end
local CELLS = {
    one = {
        { cx = 0, cy = 0, clicks = "AnyUp", attrs = function(st, opt)
            if not st.spell then return {} end
            return { type = "spell", spell = st.spell, unit = unitOf(opt), type2 = "spell", spell2 = st.spell, unit2 = "focus" }
        end },
    },
}
CELLS.pair = {
    CELLS.one[1],
    { cx = 1, cy = 0, attrs = function(st)
        if not (st.talent and st.wSpell) then return {} end
        return { type = "spell", spell = st.wSpell, ["shift-type1"] = "spell", ["shift-spell1"] = st.lSpell }
    end },
}
local function wavesLine(st)
    if not st.talent then return ns.T("widget.srt_notalent") end
    if st.waves <= 0 then return ns.T("widget.srt_nowaves") end
    return ns.T("widget.srt_waves", st.waves, ns.Widget.Left(st.wLeft))
end
local function gearRows(rows, st)
    if not st.gear then return end
    local d = data()
    local S = ns.STATE
    if st.relic then
        local aura = GetSpellInfo(d.relic.aura) or ""
        rows[#rows + 1] = st.stacks > 0
            and { l = aura, r = ns.T("widget.srt_stacks", st.stacks, d.relic.max, ns.Widget.Left(st.sLeft)) }
            or { l = aura, r = ns.T("widget.srt_nostacks"), rc = S.mute }
    end
    if st.t10 then
        rows[#rows + 1] = { l = GetSpellInfo(d.t10) or "", r = ns.T("widget.srt_t10", ns.Widget.Left(st.tLeft)), lc = S.full }
    end
end
local function toLabel(st)
    if st.to == "tank" then return ns.T("widget.srt_to_tank") end
    if st.to == "focus" then return ns.T("widget.srt_to_focus") end
    return ns.T("widget.srt_to_target")
end
local function tip(i, st, view)
    if not st.spell then return nil end
    local S = ns.STATE
    local d = data()
    if view == "pair" and i == 2 then
        local rows = {}
        if st.talent then
            rows[#rows + 1] = { l = ns.T("widget.srt_waves_hint", st.wSpell or "", st.lSpell or "") }
            if st.gear and st.t10 then
                rows[#rows + 1] = { l = GetSpellInfo(d.t10) or "", r = ns.T("widget.srt_t10", ns.Widget.Left(st.tLeft)), lc = S.full }
            end
            rows[#rows + 1] = { l = ns.T("widget.srt_click_wave", st.wSpell or "", st.lSpell or ""), lc = S.mute }
        end
        return st.wName, wavesLine(st), rows
    end
    local rows = {
        { l = st.wName or "", r = st.talent and (st.waves > 0 and (st.waves .. "/" .. d.charges .. "  " .. ns.Widget.Left(st.wLeft))
            or ns.T("widget.srt_none")) or ns.T("widget.srt_off"), rc = (st.wv == "soon" and S.soon) or (st.waves > 0 and S.text) or S.mute },
    }
    if st.talent then rows[#rows + 1] = { l = ns.T("widget.srt_waves_hint", st.wSpell or "", st.lSpell or "") } end
    rows[#rows + 1] = { l = ns.T("widget.srt_chain", GetSpellInfo(d.chain) or "") }
    gearRows(rows, st)
    rows[#rows + 1] = { l = ns.T("widget.srt_click_rt", toLabel(st)), lc = S.mute }
    local line = st.ready and ns.T("widget.srt_ready") or ns.T("widget.srt_cd", ns.Widget.Left(st.cd))
    return st.spell, line, rows
end
local DEMO = {
    solo  = { false, 0, 0, 0, 0, false },
    party = { true, 2, 12, 0, 2, false },
    raid  = { true, 1, 2, 4, 3, true },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local st = blank(scene.opt, p[1])
    names(st)
    st.talent, st.waves, st.wLeft = true, p[2], p[3]
    st.cd, st.ready = p[4], p[4] <= 0
    if p[4] > 0 then
        st.cdDur = d.cd
        st.cdStart = GetTime() - (d.cd - p[4])
    end
    st.relic, st.stacks, st.sLeft = st.gear, st.gear and p[5] or 0, 11
    st.t10, st.tLeft = st.gear and p[6], 7
    judge(st)
    return st
end
local BURNS = {}
for i, n in ipairs(ns.widgetData.shaman_resto_tide.burns) do
    BURNS[i] = { v = n ~= ns.widgetData.shaman_resto_tide.burn and n or nil, text = tostring(n) }
end
ns.Widget.Register(NAME, {
    info = { text = "widget.shaman_resto_tide_info", demo = demo },
    icon = 61301,
    label = "widget.shaman_resto_tide",
    class = "SHAMAN",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "pair",
    covers = { "spell:61301", "spell:53390" },
    avail = avail,
    units = function(opt)
        if opt and opt.to == "tank" then return { "tank" } end
        return nil
    end,
    events = {
        UNIT_AURA = "player", SPELL_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        PLAYER_ENTERING_WORLD = true, PLAYER_EQUIPMENT_CHANGED = true,
    },
    tick = function(st)
        if not (st.shown and st.spell) then return nil end
        local t = data().tick
        if st.cd > 0 then return math.min(t, st.cd + 0.05) end
        if st.waves > 0 then return t end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.spell ~= nil and st.shown end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "to", label = "widget.srt_to", values = {
            { v = nil, label = "widget.srt_to_target" }, { v = "tank", label = "widget.srt_to_tank" },
            { v = "focus", label = "widget.srt_to_focus" },
        } },
        { key = "show", label = "widget.srt_show", values = {
            { v = nil, label = "widget.srt_show_fight" }, { v = "always", label = "widget.srt_show_always" },
        } },
        { key = "burn", label = "widget.srt_burn", values = BURNS },
        { key = "gear", label = "widget.srt_gear", values = {
            { v = nil, label = "widget.srt_yes" }, { v = "off", label = "widget.srt_no" },
        } },
    },
})
if ns.Units then
    ns.Units.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.shamanRestoTideWidgetLoaded = true

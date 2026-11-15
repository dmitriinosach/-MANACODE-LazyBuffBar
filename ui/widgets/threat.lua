local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function data()
    return ns.widgetData.threat
end
local function choices()
    local d = data()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local out = {}
    for _, list in ipairs({ d.classes[class or ""] or {}, d.races[race or ""] or {} }) do
        for _, e in ipairs(list) do
            if ns.IsLearned(e.id) then out[#out + 1] = e end
        end
    end
    return out
end
local function pick(opt)
    local list = choices()
    local want = opt and opt.spell
    for _, e in ipairs(list) do
        if e.id == want then return e end
    end
    return list[1]
end
local function tankSpec()
    local _, class = UnitClass("player")
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local info = v and ns.SpecInfo and ns.SpecInfo(class, v)
    return (info and info.role == "tank") and true or false
end
local function shared()
    return (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0 or (UnitExists("pet") and true or false)
end
local function unitOf(opt)
    local l = opt and opt.unit or "target"
    if l == "target" or l == "focus" then return l end
    return ns.Units and ns.Units.Resolve(l) or nil
end
local RAID, PARTY = {}, {}
for i = 1, 40 do RAID[i] = "raid" .. i end
for i = 1, 4 do PARTY[i] = "party" .. i end
local function second(st, mob)
    local raid = GetNumRaidMembers() or 0
    local list, n = RAID, raid
    if raid == 0 then list, n = PARTY, GetNumPartyMembers() or 0 end
    local best, who = -1, nil
    for i = 1, n do
        local u = list[i]
        if UnitExists(u) and not UnitIsUnit(u, "player") then
            local _, _, p = UnitDetailedThreatSituation(u, mob)
            if p and p > best then best, who = p, u end
        end
    end
    if who then st.second, st.secondName = math.floor(best + 0.5), UnitName(who) end
end
local TANKS = { "tank", "tank2" }
local TARGET_OF = { target = "targettarget", focus = "focustarget", boss1 = "boss1target", boss2 = "boss2target",
                    boss3 = "boss3target", boss4 = "boss4target" }
local function otherTank(mob)
    local tt = TARGET_OF[mob]
    if not (tt and UnitExists(tt)) or UnitIsUnit(tt, "player") or not ns.Units then return false end
    for _, l in ipairs(TANKS) do
        local u = ns.Units.Resolve(l)
        if u and UnitIsUnit(u, tt) then return true end
    end
    return false
end
local function judge(st)
    local d = data()
    st.ready = st.spell ~= nil and st.cd <= 0 and (st.reagent == nil or st.reagent > 0)
    if not st.live then
        st.verdict = "off"
    elseif st.mode == "tank" then
        if not st.tanking then st.verdict = st.other and "ok" or "bad"
        elseif st.status == 2 or (st.second or 0) >= st.at then st.verdict = "soon"
        else st.verdict = "ok" end
        st.num = st.tanking and (st.second or 0) or st.pct
    else
        if st.tanking or st.pct >= d.bad then st.verdict = "bad"
        elseif st.pct >= st.at then st.verdict = "soon"
        else st.verdict = "ok" end
        st.num = st.pct
    end
end
local function state(opt)
    local d = data()
    local st = { mode = tankSpec() and "tank" or "dps", cd = 0, ready = false, live = false, tanking = false,
                 solo = not shared(), fight = UnitAffectingCombat("player") and true or false,
                 at = (opt and opt.at) or d.at }
    local e = st.mode == "dps" and pick(opt) or nil
    if e then
        local name, _, icon = GetSpellInfo(e.id)
        st.spell, st.icon, st.on = name, icon, e.on
        if name then st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(name)) end
        if e.reagent then st.reagent = GetItemCount(e.reagent) or 0 end
        if e.on == "tank" then st.unit = ns.Units and ns.Units.Resolve("tank") or nil
        elseif e.on == "player" then st.unit = "player" end
    end
    if not st.icon then st.icon = select(3, GetSpellInfo(d.icons[st.mode == "tank" and "tank" or "none"])) end
    local u = unitOf(opt)
    if not st.solo and u and UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDeadOrGhost(u) and UnitAffectingCombat(u) then
        local tanking, status, pct = UnitDetailedThreatSituation("player", u)
        if status then
            st.live, st.tanking, st.status = true, tanking and true or false, status
            st.pct = math.floor((pct or 0) + 0.5)
            if st.mode == "tank" then
                if st.tanking then second(st, u) else st.other = otherTank(u) end
            end
        end
    end
    judge(st)
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    layer.look = {}
    if view ~= "bar" then
        layer.tile = ns.WTile.New(layer, 0, 0, s)
        return
    end
    local bw = layer.w - s - gap
    layer.tile = ns.WTile.New(layer, bw + gap, 0, s)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    bg:SetWidth(bw)
    bg:SetHeight(s)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw - 2, h = s - 2, max = 100, color = data().bar.ok, flash = false })
    layer.bar:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", 1, -1)
    local top = CreateFrame("Frame", nil, layer.bar:Frame())
    top:SetAllPoints(layer.bar:Frame())
    layer.num = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    layer.num:SetPoint("CENTER", top, "CENTER", 0, 0)
end
local function tone(v)
    local S = ns.STATE
    return (v == "bad" and S.bad) or (v == "soon" and S.soon) or (v == "ok" and S.text) or S.mute
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local wide = view == "bar"
    local k = layer.look
    k.icon = st.icon
    k.grey = st.spell ~= nil and not st.ready
    k.alpha = (not st.live and d.dim) or ((not wide and st.num) and d.under) or 1
    k.edge = (v == "bad" and S.bad) or (v == "soon" and S.soon) or nil
    k.glow = v == "bad" and st.ready
    local left = st.cd > 0 and W.Left(st.cd) or nil
    local dry = st.reagent == 0 and "0" or nil
    if wide then
        k.text, k.textColor = left or "", S.text
        k.corner = dry
    else
        k.text, k.textColor = st.num and tostring(st.num) or "", tone(v)
        k.corner = left or dry
    end
    k.cornerColor = (k.corner == dry) and S.bad or S.text
    ns.WTile.Paint(layer.tile, k)
    if not wide then return end
    local c = d.bar[st.live and v or "off"] or d.bar.ok
    layer.bar:Set(st.num and math.min(st.num, 100) or 0, 100)
    layer.bar:SetColor(c[1], c[2], c[3], c[4])
    W.Text(layer.num, st.num and (st.num .. "%") or "")
    W.Color(layer.num, S.text)
end
local NOATTR = {}
local attrCache = {}
local function click(st)
    if not st.spell then return NOATTR end
    local key = st.spell .. "|" .. (st.unit or "")
    local a = attrCache[key]
    if not a then
        a = { type = "spell", spell = st.spell, unit = st.unit }
        attrCache[key] = a
    end
    return a
end
local CELLS = {
    one = { { l = 0, t = 0, r = 1, b = 1, attrs = click } },
    bar = { { cx = 0, cy = 0 }, { cx = 1, cy = 0, attrs = click } },
}
local function tip(_, st)
    local S = ns.STATE
    local T = ns.T
    local rows = {}
    if not st.live then
        rows[1] = { l = T(st.solo and "widget.th_solo" or "widget.th_none"), lc = S.mute }
    elseif st.mode == "tank" then
        local key = (st.tanking and "widget.th_hold") or (st.other and "widget.th_other") or "widget.th_lost"
        rows[1] = { l = T(key), lc = st.verdict == "bad" and S.bad or S.ok }
        if st.secondName then rows[2] = { l = T("widget.th_next", st.secondName), r = st.second .. "%", lc = tone(st.verdict) } end
    else
        rows[1] = { l = T("widget.th_pct"), r = st.pct .. "%", lc = tone(st.verdict) }
        if st.tanking then
            rows[2] = { l = T("widget.th_on_me"), lc = S.bad }
        else
            rows[2] = { l = T("widget.th_left"), r = math.max(0, 100 - st.pct) .. "%" }
        end
    end
    if st.spell then
        local r = (st.cd > 0 and ns.Widget.Left(st.cd)) or (st.reagent == 0 and T("widget.th_noreagent")) or T("widget.th_ready")
        rows[#rows + 1] = { l = st.spell, r = r, rc = st.ready and S.ok or S.soon }
    end
    return T("widget.threat"), nil, rows
end
local DEMO = { solo = { nil, 0 }, party = { 82, 0 }, raid = { 97, 0 } }
local function demo(scene)
    local d = data()
    local list = d.classes[scene.class] or d.classes.ROGUE
    local name, _, icon = GetSpellInfo(list[1].id)
    local p = DEMO[scene.size] or DEMO.raid
    local st = { mode = "dps", spell = name, icon = icon, cd = p[2], live = p[1] ~= nil, tanking = false,
                 solo = p[1] == nil, fight = scene.fight, pct = p[1], status = p[1] and 0 or nil,
                 reagent = list[1].reagent and 12 or nil, at = (scene.opt and scene.opt.at) or d.at }
    if scene.fight and scene.t > 3 and st.live then
        st.pct = math.floor(st.pct / 2)
        st.cd = math.max(1, 30 - scene.t)
    end
    judge(st)
    return st
end
local function atValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.ats) do out[#out + 1] = { v = n ~= d.at and n or nil, text = n .. "%" } end
    return out
end
local function spellValues()
    local out = {}
    for i, e in ipairs(choices()) do out[#out + 1] = { v = i > 1 and e.id or nil, text = GetSpellInfo(e.id) or ("#" .. e.id) } end
    return out
end
local function coverList()
    local out = {}
    for _, id in ipairs(data().covers) do out[#out + 1] = "spell:" .. id end
    return out
end
local ENEMY = { target = true, focus = true, boss1 = true, boss2 = true, boss3 = true, boss4 = true }
local TANK = { "tank" }
ns.Widget.Register("threat", {
    info = { text = "widget.threat_info", fight = true, demo = demo },
    icon = 586,
    label = "widget.threat",
    general = true,
    views = { one = { w = 1, h = 1 }, bar = { w = 2, h = 1 } },
    order = { "one", "bar" },
    view = "one",
    alias = function(view) return view == "wide" and "bar" or view end,
    covers = coverList(),
    avail = function() return true end,
    units = function()
        if tankSpec() then return TANKS end
        for _, e in ipairs(choices()) do
            if e.on == "tank" then return TANK end
        end
        return nil
    end,
    events = {
        UNIT_THREAT_LIST_UPDATE = ENEMY, UNIT_THREAT_SITUATION_UPDATE = "player", PLAYER_TARGET_CHANGED = true,
        PLAYER_FOCUS_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, SPELL_UPDATE_COOLDOWN = true,
        BAG_UPDATE = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true, PARTY_MEMBERS_CHANGED = true,
        RAID_ROSTER_UPDATE = true, UNIT_PET = "player", PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
    },
    delay = { PARTY_MEMBERS_CHANGED = 1, RAID_ROSTER_UPDATE = 1 },
    tick = function(st) return st.cd > 0 and data().tick or nil end,
    State = state,
    active = function(st, opt)
        local show = opt and opt.show
        if show == "always" then return true end
        if show == "fight" then return st.fight end
        return st.verdict == "soon" or st.verdict == "bad"
    end,
    Build = build,
    Paint = paint,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.th_show", values = {
            { v = nil, label = "widget.th_from" }, { v = "always", label = "widget.th_always" },
            { v = "fight", label = "widget.th_fight" },
        } },
        { key = "at", label = "widget.th_at", values = atValues },
        { key = "unit", label = "widget.mine_unit", values = {
            { v = nil, label = "unit.target" }, { v = "focus", label = "unit.focus" }, { v = "boss", label = "unit.boss" },
        } },
        { key = "spell", label = "widget.th_spell", when = function() return #choices() > 1 end, values = spellValues },
    },
})
ns.threatWidgetLoaded = true

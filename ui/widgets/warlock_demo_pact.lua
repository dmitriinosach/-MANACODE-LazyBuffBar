local _, ns = ...
local MINI_PART = 0.45
local TIP = "LazyBuffBarPactTip"
local MIN_TICK = 0.1
local function data()
    return ns.widgetData.warlock_demo_pact
end
local NAMES = {}
local idleSince
local scan
local function avail()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" or not ns.IsLearned(data().talent) then return false end
    local v = ns.CurrentVariant and ns.CurrentVariant()
    return v == nil or v == "demo"
end
local function summonIcon()
    local P = ns.widgetData.pet
    local want = P and P.spec and P.spec.demo
    for _, d in ipairs((P and P.demons) or {}) do
        if d.key == want then return (select(3, GetSpellInfo(d.summon))) end
    end
    return nil
end
local function judge(st, soon)
    local alive = st.pet == "attack" or st.pet == "idle"
    if not (st.fight and alive) then
        st.pv, st.verdict = "off", "off"
        return
    end
    if st.mine then
        st.pv = (st.left > 0 and st.left < soon) and "soon" or "ok"
    elseif st.other then
        st.pv = "ok"
    else
        st.pv = "none"
    end
    st.verdict = st.idle >= data().idle and "bad" or st.pv
end
local function byMine(caster)
    if not caster then return false end
    if caster == "pet" or caster == "player" then return true end
    return UnitIsUnit(caster, "pet") and true or false
end
local function state(opt)
    local d = data()
    local aura, _, icon = GetSpellInfo(d.aura)
    local st = { aura = aura, icon = icon, mine = false, other = false, left = 0, idle = 0, hostile = false, grouped = false,
                 click = not (opt and opt.click == "none") }
    st.fight = UnitAffectingCombat("player") and true or false
    if not UnitExists("pet") then
        st.pet = "none"
    elseif UnitIsDeadOrGhost("pet") then
        st.pet = "dead"
    else
        st.pet = IsPetAttackActive() and "attack" or "idle"
    end
    st.petIcon = (st.pet ~= "none" and GetPetIcon()) or summonIcon()
    local now = GetTime()
    if aura then
        local n, _, _, _, _, _, expires, caster = UnitBuff("player", aura)
        if n then
            st.mine = byMine(caster)
            st.other = not st.mine
            st.left = (expires and expires > now) and (expires - now) or 0
        end
    end
    st.hostile = (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")) and true or false
    if st.fight and st.pet == "idle" and st.hostile then
        idleSince = idleSince or now
        st.idle = now - idleSince
    else
        idleSince = nil
    end
    st.grouped = ((GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0)
    local R = ns.Raid
    if aura and R and st.grouped then
        NAMES[1] = aura
        R.Watch("warlock_demo_pact", NAMES, false)
        R.Touch()
    end
    judge(st, (opt and opt.soon) or d.soon)
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view == "wide" then
        layer.pet = ns.WTile.New(layer, s + (layer.gap or 2), 0, s)
        layer.petLook = {}
        return
    end
    local m = math.floor(s * MINI_PART + 0.5)
    layer.mini = layer:CreateTexture(nil, "OVERLAY")
    layer.mini:SetWidth(m)
    layer.mini:SetHeight(m)
    layer.mini:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", -1, 1)
    layer.mini:SetAlpha(0)
end
local function edgeOf(v)
    local S = ns.STATE
    return (v == "soon" and S.soon) or (v == "none" and S.none) or (v == "bad" and S.bad) or nil
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local off = st.verdict == "off"
    local dim = off and data().dim or 1
    local wide = view == "wide"
    local k = layer.look
    k.icon = st.icon
    k.grey = off
    k.alpha = dim
    k.edge = edgeOf(wide and st.pv or st.verdict)
    k.text = st.pv == "soon" and W.Left(st.left) or ""
    k.textColor = S.soon
    ns.WTile.Paint(layer.tile, k)
    if not wide then
        local bad = st.verdict == "bad"
        if bad then W.Tex(layer.mini, st.petIcon or ns.QMARK) end
        W.Alpha(layer.mini, bad and 1 or 0)
        return
    end
    local p = layer.petLook
    p.icon = st.petIcon
    p.grey = off or st.pet == "none" or st.pet == "dead"
    p.alpha = dim
    p.edge = st.verdict == "bad" and S.bad or nil
    ns.WTile.Paint(layer.pet, p)
end
local ATTACK = { type = "macro", macrotext = "/petattack" }
local NONE = {}
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(_, opt)
        return (opt and opt.click == "none") and NONE or ATTACK
    end },
}
local function power(aura)
    for i = 1, 40 do
        local n = UnitBuff("player", i)
        if not n then return nil end
        if n == aura then
            if not scan then scan = CreateFrame("GameTooltip", TIP, nil, "GameTooltipTemplate") end
            scan:SetOwner(WorldFrame, "ANCHOR_NONE")
            scan:ClearLines()
            scan:SetUnitBuff("player", i)
            local fs = _G[TIP .. "TextLeft2"]
            local text = fs and fs:GetText()
            return text and tonumber(text:match("(%d+)")) or nil
        end
    end
    return nil
end
local function rival()
    for _, id in ipairs(data().rival) do
        local name = GetSpellInfo(id)
        if name and UnitBuff("player", name) then return true end
    end
    return false
end
local PET = { attack = "widget.wdp_pet_attack", idle = "widget.wdp_pet_idle", none = "widget.wdp_pet_none", dead = "widget.wdp_pet_dead" }
local function tip(st)
    if not st.aura then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    local holder = (st.mine and "widget.wdp_mine") or (st.other and "widget.wdp_other") or "widget.wdp_nobody"
    rows[1] = { l = ns.T("widget.wdp_holder"), r = ns.T(holder), rc = (st.mine or st.other) and S.text or S.mute }
    if st.left > 0 then
        rows[#rows + 1] = { l = ns.T("widget.wdp_left"), r = W.Left(st.left), rc = st.pv == "soon" and S.soon or S.text }
    end
    local sp = (st.mine or st.other) and power(st.aura)
    if sp then rows[#rows + 1] = { l = ns.T("widget.wdp_gives"), r = ns.T("widget.wdp_sp", sp) } end
    rows[#rows + 1] = { l = ns.T("widget.wdp_pet"), r = ns.T(PET[st.pet]), rc = st.verdict == "bad" and S.bad or S.text }
    local R = ns.Raid
    if st.grouped and R then
        NAMES[1] = st.aura
        local c = R.Count(NAMES, nil, nil, 0, R.Scope(), 0)
        if c.total > 0 then rows[#rows + 1] = { l = ns.T("widget.wdp_under"), r = c.n .. "/" .. c.total } end
    end
    if rival() then rows[#rows + 1] = { l = ns.T("widget.wdp_rival"), lc = S.mute } end
    local line
    if st.verdict == "bad" then
        line = ns.T(st.click and "widget.wdp_idle_click" or "widget.wdp_idle_tip")
    elseif st.verdict == "none" then
        line = ns.T("widget.wdp_none_tip")
    elseif st.verdict == "off" and not st.fight and not (st.mine or st.other) then
        line = ns.T("widget.wdp_off_tip")
    end
    return st.aura, line, rows
end
local DEMO = { solo = { true, 38, "attack" }, party = { true, 9, "attack" }, raid = { false, 0, "idle" } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local aura, _, icon = GetSpellInfo(d.aura)
    local st = { aura = aura, icon = icon, petIcon = summonIcon(), mine = p[1], other = false, left = p[2], fight = true,
                 pet = p[3], hostile = true, idle = p[3] == "idle" and d.idle or 0, grouped = scene.size ~= "solo",
                 click = not (scene.opt and scene.opt.click == "none") }
    judge(st, (scene.opt and scene.opt.soon) or d.soon)
    return st
end
local function soonValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.soons) do
        out[#out + 1] = { v = n ~= d.soon and n or nil, text = ns.T("time.seconds", n) }
    end
    return out
end
local function tick(st)
    if not st.fight then return nil end
    local d = data()
    if st.pet == "idle" and st.hostile and st.idle < d.idle then return math.max(MIN_TICK, d.idle - st.idle) end
    return (st.mine or st.pet == "idle") and d.tick or nil
end
ns.Widget.Register("warlock_demo_pact", {
    info = { text = "widget.warlock_demo_pact_info", demo = demo },
    icon = 48090,
    label = "widget.warlock_demo_pact",
    class = "WARLOCK",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:48090" },
    avail = avail,
    events = {
        UNIT_AURA = "player", UNIT_PET = "player", UNIT_HEALTH = "pet", PET_ATTACK_START = true, PET_ATTACK_STOP = true,
        PLAYER_TARGET_CHANGED = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = tick,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "soon", label = "widget.wdp_soon", values = soonValues },
        { key = "click", label = "widget.wdp_click", values = {
            { v = nil, label = "widget.wdp_attack" }, { v = "none", label = "widget.wdp_noclick" },
        } },
    },
})
ns.warlockDemoPactWidgetLoaded = true

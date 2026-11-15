local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "bm_pettarget"
local function data()
    return ns.widgetData.bm_pettarget
end
local function petClass()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
local function avail()
    local c = petClass()
    return c ~= nil and ns.IsLearned(c.call)
end
local function petSlot(name)
    for i = 1, data().petSlots do
        local n, _, _, _, _, _, on = GetPetActionInfo(i)
        if n == name then return i, on and true or false end
    end
    return nil, false
end
local function otherTank()
    if (GetNumRaidMembers() or 0) == 0 and (GetNumPartyMembers() or 0) == 0 then return false end
    local u = ns.Units and ns.Units.Resolve("tank")
    return u ~= nil and not UnitIsUnit(u, "player")
end
local idleSince
local function state(opt)
    local c = petClass()
    local st = { why = "none", verdict = "off", fight = false, hot = false }
    if not c then return st end
    local name, _, icon = GetSpellInfo(c.taunt)
    st.growl, st.growlIcon = name, icon
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
        idleSince = nil
        st.why = "nopet"
        return st
    end
    st.pet, st.petIcon = UnitName("pet"), GetPetIcon and GetPetIcon() or nil
    if UnitIsDeadOrGhost("player") then
        idleSince = nil
        st.why = "dead"
        return st
    end
    local enemy = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local fight = enemy and UnitAffectingCombat("player") and true or false
    local has = UnitExists("pettarget") and not UnitIsDeadOrGhost("pettarget")
    if fight and not has then
        idleSince = idleSince or GetTime()
    else
        idleSince = nil
    end
    local auto = false
    if name then st.slot, auto = petSlot(name) end
    if auto and not (opt and opt.growl == "off") and otherTank() then
        st.why, st.verdict = "growl", "bad"
        st.hot = UnitAffectingCombat("player") and true or false
        return st
    end
    if not fight then
        st.why = "calm"
        return st
    end
    st.fight, st.mine = true, UnitName("target")
    if not has then
        st.left = data().grace - (GetTime() - idleSince)
        if st.left > 0 then
            st.why = "wait"
        else
            st.why, st.verdict = "idle", "bad"
        end
        return st
    end
    st.whom = UnitName("pettarget")
    if UnitIsUnit("pettarget", "target") then
        st.why, st.verdict = "on", "ok"
    else
        st.why, st.verdict = "other", "soon"
    end
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.note = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSize(layer.note, s * 0.3)
    layer.note:SetPoint("LEFT", bg, "LEFT", PAD, 0)
    layer.note:SetPoint("RIGHT", bg, "RIGHT", -PAD, 0)
    layer.note:SetJustifyH("LEFT")
end
local function ink(st)
    local S = ns.STATE
    local v = st.verdict
    if v == "bad" then return S.bad end
    if v == "soon" then return S.soon end
    if v == "ok" then return S.ok end
    return nil
end
local function note(st)
    local y = st.why
    if y == "growl" then return ns.T("widget.bmpt_n_growl", st.growl or "") end
    if y == "idle" then return ns.T("widget.bmpt_n_idle") end
    if y == "other" then return ns.T("widget.bmpt_n_other", st.whom or "") end
    if y == "on" then return ns.T("widget.bmpt_n_on") end
    return ""
end
local function paint(layer, st, view)
    local W = ns.Widget
    local y = st.why
    local c = ink(st)
    local k = layer.look
    if y == "growl" then
        k.icon = st.growlIcon
    elseif y == "idle" then
        k.icon = data().attack
    else
        k.icon = st.petIcon or st.growlIcon
    end
    k.edge = c
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.note, note(st))
    W.Color(layer.note, c or ns.STATE.text)
end
local function offMacro(st)
    if not st.growl then return nil end
    if SecureCmdList and SecureCmdList.PET_AUTOCASTOFF then return "/petautocastoff " .. st.growl end
    if st.why == "growl" and st.slot then return "/click PetActionButton" .. st.slot .. " RightButton" end
    return nil
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp", attrs = function(st)
        local out = { type = "macro", macrotext = "/petattack" }
        local off = offMacro(st)
        if off then out.type2, out.macrotext2 = "macro", off end
        return out
    end },
}
local SAY = { growl = "widget.bmpt_t_growl", idle = "widget.bmpt_t_idle", other = "widget.bmpt_t_other",
              on = "widget.bmpt_t_on", wait = "widget.bmpt_t_wait" }
local function hasBuff(unit, id)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, sid = UnitBuff(unit, i)
        if not name then return false end
        if sid == id then return true end
    end
    return false
end
local function tip(_, st)
    if not st.pet then return nil end
    local S = ns.STATE
    local d = data()
    local y = st.why
    local rows = {}
    if st.fight then
        rows[#rows + 1] = { l = ns.T("widget.bmpt_pet_target"), r = st.whom or ns.T("widget.bmpt_nobody") }
        rows[#rows + 1] = { l = ns.T("widget.bmpt_my_target"), r = st.mine or ns.T("widget.bmpt_nobody") }
    end
    if y == "idle" and hasBuff("player", d.kill) then
        rows[#rows + 1] = { l = ns.T("widget.bmpt_kill"), lc = S.soon }
    end
    if (y == "idle" or y == "other") and hasBuff("pet", d.fury) then
        rows[#rows + 1] = { l = ns.T("widget.bmpt_fury"), lc = S.soon }
    end
    if y == "growl" then
        rows[#rows + 1] = { l = ns.T("widget.bmpt_growl_fix", st.growl or ""), lc = S.bad }
    end
    rows[#rows + 1] = { l = ns.T("widget.bmpt_click"), lc = S.mute }
    return st.pet, SAY[y] and ns.T(SAY[y], st.growl or "") or nil, rows
end
local DEMO = {
    solo  = { "idle", "bad" },
    party = { "growl", "bad" },
    raid  = { "other", "soon", "widget.bmpt_demo_add" },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local c = data().classes[scene.class] or data().classes.HUNTER
    local name, _, icon = GetSpellInfo(c.taunt)
    return { growl = name, growlIcon = icon, pet = ns.T("widget.bmpt_demo_pet"), why = p[1], verdict = p[2],
             fight = p[1] ~= "growl", whom = p[3] and ns.T(p[3]) or nil, mine = ns.T("widget.bmpt_demo_boss") }
end
ns.Widget.Register(KEY, {
    info = { text = "widget.bm_pettarget_info", demo = demo },
    icon = 2649,
    label = "widget.bm_pettarget",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = avail,
    units = function() return { "tank" } end,
    events = {
        UNIT_TARGET = "pet", PLAYER_TARGET_CHANGED = true, UNIT_PET = "player", PET_BAR_UPDATE = true,
        PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, RAID_ROSTER_UPDATE = true,
        PARTY_MEMBERS_CHANGED = true, SPELLS_CHANGED = true, PLAYER_DEAD = true, PLAYER_ALIVE = true,
        PLAYER_UNGHOST = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if st.hot then return data().tick end
        if not st.fight then return nil end
        if st.why == "wait" then return math.min(data().tick, st.left + data().edge) end
        return data().tick
    end,
    active = function(st, opt)
        local v = st.verdict
        return v == "bad" or v == "soon" or (v == "ok" and opt ~= nil and opt.show == "all")
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.bmpt_show", values = {
            { v = nil, label = "widget.bmpt_show_bad" }, { v = "all", label = "widget.bmpt_show_all" },
        } },
        { key = "growl", label = "widget.bmpt_growl", values = {
            { v = nil, label = "widget.bmpt_growl_on" }, { v = "off", label = "widget.bmpt_growl_off" },
        } },
    },
})
if ns.Units then
    ns.Units.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.hunterBmPetTargetWidgetLoaded = true

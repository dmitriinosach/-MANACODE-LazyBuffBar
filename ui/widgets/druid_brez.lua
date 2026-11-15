local _, ns = ...
local NAME = "druid_brez"
local NAME_PAD = 3
local function data()
    return ns.widgetData.druid_brez
end
local function entry()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
local function known()
    local e = entry()
    if not e then return nil end
    if ns.IsLearned(e.id) then return e.id end
    for _, id in ipairs(e.alt) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
local function inFight()
    return (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
end
local function before(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    if a.far ~= b.far then return b.far end
    return a.pos < b.pos
end
local function judge(st)
    table.sort(st.list, before)
    st.n, st.next = #st.list, st.list[1]
    st.tank, st.heal = false, false
    for _, d in ipairs(st.list) do
        if d.tank then st.tank = true end
        if d.heal then st.heal = true end
    end
    if not st.spell then st.why, st.verdict = "none", "off"
    elseif st.self then st.why, st.verdict = "self", "off"
    elseif st.n == 0 then st.why, st.verdict = "idle", "off"
    elseif not (st.fight or st.always) then st.why, st.verdict = "calm", "off"
    elseif st.noseed then st.why, st.verdict = "seed", "bad"
    elseif st.cd > 0 then st.why, st.verdict = "cd", st.cd < data().soon and "soon" or "off"
    else st.why, st.verdict = "go", "ok" end
end
local function prioOf(tank, heal, ghost)
    return ((tank and 0) or (heal and 1) or 2) + (ghost and 10 or 0)
end
local function state(opt)
    local e = entry()
    local st = { list = {}, cd = 0, seeds = 0, noseed = false, fight = inFight(),
        always = (opt and opt.always) and true or false, self = UnitIsDeadOrGhost("player") and true or false }
    local id = known()
    if id then
        local name, _, icon = GetSpellInfo(id)
        st.spell, st.icon = name, icon
    end
    local R = ns.Raid
    if st.spell and R then
        R.Touch()
        for _, m in ipairs(R.Roster()) do
            if m.seen and m.dead and not m.off and m.click ~= "player" then
                local d = { name = m.name, class = m.class, pos = m.pos }
                d.tank = ns.Rez.IsTank(m)
                d.heal = (not d.tank and UnitGroupRolesAssigned and select(2, UnitGroupRolesAssigned(m.unit))) and true or false
                d.ghost = UnitIsGhost(m.unit) and true or false
                d.far = not d.ghost and IsSpellInRange(st.spell, m.unit) == 0
                d.prio = prioOf(d.tank, d.heal, d.ghost)
                st.list[#st.list + 1] = d
            end
        end
    end
    if st.spell then
        st.cd = ns.WTile.Left(data().gcd, GetSpellCooldown(st.spell))
        st.seeds = (e and e.reagent and GetItemCount(e.reagent)) or 0
        local usable, nomana = IsUsableSpell(st.spell)
        st.noseed = (st.cd <= 0 and not usable and not nomana and st.seeds == 0 and e.reagent ~= nil) and true or false
    end
    judge(st)
    return st
end
local HIDDEN = { none = true, self = true, idle = true, calm = true }
local function clock(sec)
    local s = math.floor(sec + 0.5)
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "name" then return end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -NAME_PAD, -NAME_PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", NAME_PAD, NAME_PAD)
    layer.sub:SetJustifyH("LEFT")
end
local function markOf(d)
    local S = ns.STATE
    if d.ghost then return ns.T("widget.dr_ghost"), S.mute end
    if d.far then return ns.T("widget.dr_far"), S.bad end
    if d.tank then return ns.T("widget.dr_tank"), S.text end
    if d.heal then return ns.T("widget.dr_heal"), S.text end
    return nil, nil
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    local cd = st.why == "cd"
    k.icon = st.icon
    k.grey = cd and v == "off"
    k.alpha = (cd and v == "off") and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "bad" and S.bad) or nil
    k.text = st.n > 0 and tostring(st.n) or ""
    k.textColor = S.text
    k.mark = (st.tank and ns.T("widget.dr_tank_mark")) or (st.heal and ns.T("widget.dr_heal_mark")) or nil
    k.markColor = S.full
    k.corner = (st.why == "seed" and "0") or (cd and clock(st.cd)) or nil
    k.cornerColor = (st.why == "seed" and S.bad) or (v == "soon" and S.soon) or S.text
    k.glow = v == "ok" and st.tank
    ns.WTile.Paint(layer.tile, k)
    if view ~= "name" then return end
    local d = st.next
    local mark, mc = nil, nil
    if d then mark, mc = markOf(d) end
    W.Text(layer.who, d and d.name or "")
    W.Color(layer.who, d and ns.WTile.ClassColor(d.class) or S.text)
    W.Text(layer.sub, mark or "")
    W.Color(layer.sub, mc or S.text)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "macro", macrotext = "/cast [target=mouseover,help,dead][help,dead] " .. st.spell }
    end },
}
local function tip(st)
    if HIDDEN[st.why] then return nil end
    local S = ns.STATE
    local rows, lines = {}, data().lines
    for i, d in ipairs(st.list) do
        if i > lines then
            rows[#rows + 1] = { l = ns.T("widget.dr_more", st.n - lines), lc = S.mute }
            break
        end
        local r, rc = markOf(d)
        rows[#rows + 1] = { l = d.name, r = r, lc = ns.WTile.ClassColor(d.class), rc = rc }
    end
    if st.cd > 0 then rows[#rows + 1] = { l = ns.T("widget.dr_cd"), r = clock(st.cd), rc = st.verdict == "soon" and S.soon or S.text } end
    local e = entry()
    if e and e.reagent then
        rows[#rows + 1] = { l = GetItemInfo(e.reagent) or ns.T("widget.dr_seeds"), r = tostring(st.seeds), rc = st.noseed and S.bad or S.text }
    end
    return st.spell, ns.T("widget.dr_click"), rows
end
local DEMO = {
    solo  = { {}, 0 },
    party = { { { "WARRIOR", true, false, false } }, 0 },
    raid  = { { { "PRIEST", false, true, false }, { "MAGE", false, false, false }, { "ROGUE", false, false, true } }, 45 },
}
local function demo(scene)
    local e = data().classes[scene.class] or data().classes.DRUID
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(e.id)
    local st = { spell = name, icon = icon, list = {}, fight = true, always = false, self = false, seeds = 4, noseed = false }
    st.cd = math.max(0, p[2] - (scene.fight and scene.t or 0))
    for i, x in ipairs(p[1]) do
        st.list[i] = { name = ns.T("widget.bless_demo_name", i), class = x[1], pos = i, tank = x[2], heal = x[3], far = x[4],
            ghost = false, prio = prioOf(x[2], x[3], false) }
    end
    judge(st)
    return st
end
local function coverList()
    local out = {}
    for _, e in pairs(data().classes) do
        out[#out + 1] = "spell:" .. e.id
    end
    table.sort(out)
    return out
end
ns.Widget.Register(NAME, {
    info = { text = "widget.druid_brez_info", fight = true, demo = demo },
    icon = 48477,
    label = "widget.druid_brez",
    views = { one = { w = 1, h = 1 }, name = { w = 2, h = 1 } },
    order = { "one", "name" },
    view = "one",
    covers = coverList(),
    avail = function() return known() ~= nil end,
    units = function() return { "tank", "tank2" } end,
    events = {
        SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true, BAG_UPDATE = true,
        PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true, PLAYER_ENTERING_WORLD = true, SPELLS_CHANGED = true,
    },
    tick = function(st) return not HIDDEN[st.why] and data().tick or nil end,
    State = state,
    active = function(st) return not HIDDEN[st.why] end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "always", label = "widget.dr_always", values = {
            { v = nil, label = "widget.dr_no" }, { v = true, label = "widget.dr_yes" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.druidBrezLoaded = true

local _, ns = ...
local NAME_PAD = 3
local MAX_AURAS = 40
local CHAR_KEY = "mageFocus"
local function data()
    return ns.widgetData.mage_focus
end
local NAMES = {}
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    return ns.IsLearned(data().id)
end
local function char()
    return ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char() or nil
end
local function remember(name)
    local c = char()
    if c and c[CHAR_KEY] ~= name then c[CHAR_KEY] = name end
end
local function letters(s, n)
    local count = 0
    for i = 1, #s do
        local b = s:byte(i)
        if b < 128 or b >= 192 then
            count = count + 1
            if count > n then return s:sub(1, i - 1) end
        end
    end
    return s
end
local function targetOf(opt, st)
    local who = opt and opt.who
    if who == "name" and opt.name and opt.name ~= "" then return opt.name end
    if who == "focus" then return "focus" end
    if who == nil then
        if st.click then return st.click end
        local c = char()
        local last = c and c[CHAR_KEY]
        if type(last) == "string" and last ~= "" and ns.Raid then
            for _, m in ipairs(ns.Raid.Roster()) do
                if m.click == last then return last end
            end
        end
    end
    return nil
end
local function macroOf(spell, target)
    if target then return "/cast [target=" .. target .. ",help,nodead] " .. spell end
    return "/cast [target=focus,help,nodead][help,nodead] " .. spell
end
local function readSelf(st)
    local d = data()
    local now = GetTime()
    for i = 1, MAX_AURAS do
        local n, _, _, _, _, _, expires, caster, _, _, id = UnitBuff("player", i)
        if not n then break end
        id = tonumber(id)
        if id == d.back then
            expires = tonumber(expires) or 0
            st.back = expires > 0 and math.max(0, expires - now) or 0
        elseif id == d.id and caster and not UnitIsUnit(caster, "player") then
            st.from = UnitName(caster)
        end
    end
end
local function held(unit)
    local id = data().id
    for i = 1, MAX_AURAS do
        local n, _, _, _, _, _, expires, caster, _, _, sid = UnitBuff(unit, i, "PLAYER")
        if not n then return nil end
        if tonumber(sid) == id and caster == "player" then return tonumber(expires) or 0 end
    end
    return nil
end
local function state(opt)
    local d = data()
    local name, _, icon = GetSpellInfo(d.id)
    local st = {
        spell = name, icon = icon, grouped = false, left = 0, back = 0,
        fight = UnitAffectingCombat("player") and true or false,
        edgeBack = not (opt and opt.proc == "off"), always = (opt and opt.show == "always") and true or false,
    }
    local R = ns.Raid
    if name and R then
        NAMES[1] = name
        R.Watch("mage_focus", NAMES, true)
        R.Touch()
        st.grouped = R.Grouped() and true or false
        local now = GetTime()
        for _, m in ipairs(R.Roster()) do
            if m.click ~= "player" then
                local e = R.Own(m, NAMES) and held(m.unit)
                if e and (e == 0 or e > now) then
                    st.who, st.class, st.click = m.name, m.class, m.click
                    st.left = e > 0 and (e - now) or 0
                    break
                end
            end
        end
    end
    readSelf(st)
    if st.click then remember(st.click) end
    if name then
        st.target = targetOf(opt, st)
        st.macro = macroOf(name, st.target)
    end
    if not (name and st.grouped) then
        st.why, st.verdict = "solo", "off"
    elseif not st.who then
        st.why, st.verdict = "none", "none"
    elseif not st.fight and st.left > 0 and st.left < d.soon then
        st.why, st.verdict = "soon", "soon"
    else
        st.why, st.verdict = "on", "ok"
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -NAME_PAD, -NAME_PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", NAME_PAD, NAME_PAD)
    layer.sub:SetJustifyH("LEFT")
    layer.back = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.back:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -NAME_PAD, NAME_PAD)
    layer.back:SetJustifyH("RIGHT")
end
local function edgeOf(st)
    local S = ns.STATE
    if st.back > 0 and st.edgeBack and st.why ~= "solo" then return S.full end
    if st.why == "none" then return S.none end
    if st.why == "soon" then return S.soon end
    return nil
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local on = st.why == "on" or st.why == "soon"
    local back = st.back > 0 and st.edgeBack
    local k = layer.look
    k.icon = st.icon
    k.alpha = (st.why == "solo") and d.dim or 1
    k.edge = edgeOf(st)
    k.mark = (view ~= "wide" and on) and letters(st.who, d.letters) or nil
    k.markColor = ns.WTile.ClassColor(st.class)
    if view ~= "wide" and back then
        k.corner, k.cornerColor = W.Left(st.back), S.full
    elseif view ~= "wide" and st.why == "soon" then
        k.corner, k.cornerColor = W.Left(st.left), S.soon
    else
        k.corner, k.cornerColor = nil, S.text
    end
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.who, on and st.who or (st.why == "none" and ns.T("widget.mgf_nobody") or ""))
    W.Color(layer.who, on and ns.WTile.ClassColor(st.class) or (st.why == "none" and S.none or S.text))
    W.Text(layer.sub, (on and st.left > 0) and W.Left(st.left) or "")
    W.Color(layer.sub, st.why == "soon" and S.soon or S.text)
    W.Text(layer.back, back and W.Left(st.back) or "")
    W.Color(layer.back, S.full)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.macro then return {} end
        return { type = "macro", macrotext = st.macro }
    end },
}
local function tip(_, st)
    if st.why == "solo" then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    if st.who then
        rows[#rows + 1] = { l = st.who, r = W.Left(st.left), lc = ns.WTile.ClassColor(st.class),
            rc = st.why == "soon" and S.soon or nil }
    else
        rows[#rows + 1] = { l = ns.T("widget.mgf_nobody"), lc = S.none }
    end
    if st.back > 0 then
        rows[#rows + 1] = { l = ns.T("widget.mgf_back"), r = W.Left(st.back), lc = S.full }
    else
        rows[#rows + 1] = { l = ns.T("widget.mgf_back"), r = ns.T("widget.td_none"), lc = S.mute }
    end
    if st.from then rows[#rows + 1] = { l = ns.T("widget.mgf_from", st.from) } end
    local to = (st.target == "focus" and ns.T("widget.mgf_focus")) or st.target or ns.T("widget.mgf_focus_or_target")
    rows[#rows + 1] = { l = ns.T("widget.mgf_click", to), lc = S.mute }
    return st.spell, nil, rows
end
local DEMO = { solo = { "solo" }, party = { "on", "WARLOCK", 24, 7 }, raid = { "none" } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local st = {
        spell = name, icon = icon, grouped = p[1] ~= "solo", left = (p[3] or 0) * 60, back = p[4] or 0,
        fight = scene.fight, edgeBack = not (scene.opt and scene.opt.proc == "off"),
        always = (scene.opt and scene.opt.show == "always") and true or false, why = p[1],
    }
    st.verdict = (p[1] == "on" and "ok") or (p[1] == "solo" and "off") or p[1]
    if p[2] then st.who, st.class = ns.T("widget.bless_demo_name", 2), p[2] end
    return st
end
ns.Widget.Register("mage_focus", {
    info = { text = "widget.mage_focus_info", demo = demo },
    icon = 54646,
    label = "widget.mage_focus",
    class = "MAGE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:54646" },
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_FOCUS_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        SPELLS_CHANGED = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if st.back > 0 then return data().tick end
        return st.who and data().slow or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st)
        if st.why == "solo" then return false end
        return st.always or st.why == "none" or st.why == "soon"
    end,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.mgf_show", values = {
            { v = nil, label = "widget.mgf_when" }, { v = "always", label = "widget.mgf_always" },
        } },
        { key = "proc", label = "widget.mgf_proc", values = {
            { v = nil, label = "widget.mgf_edge" }, { v = "off", label = "widget.mgf_noedge" },
        } },
        { key = "who", label = "widget.mgf_who", values = {
            { v = nil, label = "widget.mgf_auto" }, { v = "focus", label = "widget.mgf_focus" },
            { v = "name", label = "widget.mgf_byname" },
        } },
        { key = "name", label = "widget.mgf_name", kind = "text", max = 30, ghost = "widget.mgf_name_ghost",
          when = function(item) return item and item.opt and item.opt.who == "name" end },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("mage_focus") end)
end
ns.mageFocusWidgetLoaded = true

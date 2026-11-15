local _, ns = ...
local KEY = "druid_balance_innervate"
local CHAR_KEY = "innervateTo"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local MANA = 0
local function data()
    return ns.widgetData.druid_balance_innervate
end
local NAMES = {}
local function avail()
    return ns.PlayerClass() == "DRUID" and ns.IsLearned(data().id)
end
local function char()
    return ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char() or nil
end
local function remember(name)
    local c = char()
    if c and c[CHAR_KEY] ~= name then c[CHAR_KEY] = name end
end
local function last()
    local c = char()
    local n = c and c[CHAR_KEY]
    return (type(n) == "string" and n ~= "") and n or nil
end
local function letters(s, n)
    local out, count, i = {}, 0, 1
    while i <= #s do
        local b = s:byte(i)
        local len = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
        count = count + 1
        if count > n then break end
        out[#out + 1] = s:sub(i, i + len - 1)
        i = i + len
    end
    return table.concat(out)
end
local function giveOf()
    local d = data()
    return math.floor(d.base * d.pct + 0.5)
end
local function find(name)
    for _, m in ipairs(ns.Raid.Roster()) do
        if m.click ~= "player" and (m.name == name or m.click == name) then return m end
    end
    return nil
end
local function focused()
    if not UnitExists("focus") or UnitIsUnit("focus", "player") then return nil, nil end
    local guid = UnitGUID("focus")
    for _, m in ipairs(ns.Raid.Roster()) do
        if m.guid == guid and m.click ~= "player" then return m, nil end
    end
    if UnitIsPlayer("focus") and UnitCanAssist("player", "focus") then return nil, UnitName("focus") end
    return nil, nil
end
local function chosen(opt)
    local who = opt and opt.who
    if who == "name" then
        local n = type(opt.name) == "string" and opt.name:match("^[^%s%[%];,]+") or nil
        if not n then return nil, nil, "focus" end
        local m = find(n)
        return m, not m and n or nil, m and m.click or n
    end
    if who == nil then
        local n = last()
        local m = n and find(n)
        if m then return m, nil, m.click end
    end
    local m, away = focused()
    return m, away, "focus"
end
local function macroOf(spell, target)
    return "/cast [target=" .. target .. ",help,nodead] " .. spell
end
local function needs(opt, st, pct)
    local at = opt and opt.when and data().low[opt.when]
    if at then return pct < at end
    return st.lack >= st.give
end
local function readMana(st, m)
    if m.dead or m.off then return end
    if UnitPowerType(m.unit) ~= MANA then return end
    local max = UnitPowerMax(m.unit, MANA) or 0
    if max <= 0 then return end
    local cur = UnitPower(m.unit, MANA) or 0
    st.mana, st.max = cur, max
    st.pct = math.floor(cur * 100 / max + 0.5)
    st.lack = math.max(0, max - cur)
end
local function state(opt)
    local d = data()
    local st = {
        grouped = false, cd = 0, left = 0, mana = 0, max = 0, pct = 0, lack = 0, give = giveOf(),
        fight = UnitAffectingCombat("player") and true or false,
    }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    local R = ns.Raid
    if not (st.spell and R) then
        st.why, st.verdict = "gone", "off"
        return st
    end
    NAMES[1] = st.spell
    R.Watch(KEY, NAMES, true)
    R.Range(KEY, st.spell)
    R.Touch()
    st.grouped = R.Grouped() and true or false
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
    local now = GetTime()
    local holder
    for _, m in ipairs(R.Roster()) do
        if m.click ~= "player" then
            local e = R.Own(m, NAMES)
            if e and (e == 0 or e > now) then
                holder = m
                st.left = e > 0 and (e - now) or 0
                break
            end
        end
    end
    if holder then remember(holder.click) end
    local m, away, target = chosen(opt)
    st.target = target
    st.macro = macroOf(st.spell, target)
    if not st.grouped then
        st.why, st.verdict = "solo", "off"
        return st
    end
    m = holder or m
    if not m then
        st.who = away
        st.why, st.verdict = away and "away" or "nobody", "off"
        return st
    end
    st.who, st.class = m.name, m.class
    readMana(st, m)
    if holder then
        st.why, st.verdict = "on", "ok"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "off"
    elseif m.dead then
        st.why, st.verdict = "dead", st.fight and "bad" or "off"
    elseif m.off then
        st.why, st.verdict = "off", "bad"
    elseif st.max <= 0 then
        st.why, st.verdict = "nomana", "bad"
    elseif m.out[KEY] then
        st.why, st.verdict = "far", st.fight and "bad" or "text"
    elseif st.fight and needs(opt, st, st.pct) then
        st.why, st.verdict = "soon", "soon"
    else
        st.why, st.verdict = "ready", "text"
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
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.who:SetJustifyH("LEFT")
    local bw = math.max(8, layer.w - s - gap - 2 * PAD)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw, h = math.max(4, math.floor(s * 0.3)), max = 100, color = data().bar,
        flash = false })
    layer.bar:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
end
local MARK = { dead = "widget.dbi_m_dead", off = "widget.dbi_m_off", nomana = "widget.dbi_m_nomana", far = "widget.dbi_m_far" }
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = v == "off" and d.dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "bad" and S.bad) or nil
    k.glow = v == "soon"
    if v == "ok" then
        k.text = st.left > 0 and W.Left(st.left) or ""
    elseif st.why == "cd" then
        k.text = W.Left(st.cd)
    else
        k.text = ""
    end
    k.textColor = S.text
    local ink = ns.WTile.ClassColor(st.class)
    if v == "bad" then
        k.mark, k.markColor = ns.T(MARK[st.why]), S.bad
    elseif view ~= "wide" and st.who and v ~= "off" then
        k.mark, k.markColor = letters(st.who, d.letters), ink
    else
        k.mark, k.markColor = nil, S.text
    end
    local shown = st.max > 0 and (v == "soon" or v == "text" or st.why == "far")
    k.corner = shown and (st.pct .. "%") or nil
    k.cornerColor = v == "soon" and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.who, st.who or ns.T("widget.dbi_nobody"))
    W.Color(layer.who, st.who and ink or S.mute)
    layer.bar:Set(st.max > 0 and st.pct or 0)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.macro then return {} end
        return { type = "macro", macrotext = st.macro }
    end },
}
local WHY = {
    nobody = "widget.dbi_why_nobody", away = "widget.dbi_why_away", dead = "widget.dbi_why_dead",
    off = "widget.dbi_why_off", nomana = "widget.dbi_why_nomana", far = "widget.dbi_why_far",
    soon = "widget.dbi_why_soon",
}
local function tip(_, st)
    if not st.spell or st.why == "solo" then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    rows[#rows + 1] = { l = ns.T("widget.dbi_to"), r = st.who or ns.T("widget.dbi_nobody"),
        rc = st.who and ns.WTile.ClassColor(st.class) or S.mute }
    if st.max > 0 then
        rows[#rows + 1] = { l = ns.T("widget.dbi_mana"), r = ns.T("widget.dbi_mana_of", st.mana, st.max, st.pct) }
        rows[#rows + 1] = { l = ns.T("widget.dbi_lack"), r = tostring(st.lack),
            rc = st.lack >= st.give and S.soon or nil }
    end
    rows[#rows + 1] = { l = ns.T("widget.dbi_give"), r = ns.T("widget.dbi_give_n", st.give), lc = S.mute, rc = S.mute }
    if st.why == "on" then
        rows[#rows + 1] = { l = ns.T("widget.dbi_on"), r = W.Left(st.left), rc = S.ok }
    elseif st.cd > 0 then
        rows[#rows + 1] = { l = ns.T("widget.dbi_cd"), r = W.Left(st.cd) }
    end
    if WHY[st.why] then
        rows[#rows + 1] = { l = ns.T(WHY[st.why]), lc = (st.verdict == "bad" and S.bad) or (st.verdict == "soon" and S.soon) or S.mute }
    end
    local to = st.target == "focus" and ns.T("widget.dbi_focus") or st.target
    rows[#rows + 1] = { l = ns.T(st.fight and "widget.dbi_click_fight" or "widget.dbi_click", to), lc = S.mute }
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { "solo", "off" },
    party = { "ready", "text", "PRIEST", 22, 0, 0 },
    raid  = { "on", "ok", "SHAMAN", 41, 7, 173 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local max = 30000
    local pct = p[4] or 0
    local st = {
        spell = name, icon = icon, grouped = p[1] ~= "solo", fight = scene.fight and true or false,
        cd = p[6] or 0, left = p[5] or 0, give = giveOf(), max = p[3] and max or 0, pct = pct,
        mana = math.floor(max * pct / 100), why = p[1], verdict = p[2], target = "focus",
    }
    st.lack = st.max - st.mana
    if p[3] then st.who, st.class = ns.T("widget.bless_demo_name", 2), p[3] end
    if st.why == "ready" and st.fight then st.why, st.verdict = "soon", "soon" end
    return st
end
ns.Widget.Register(KEY, {
    info = { text = "widget.druid_balance_innervate_info", demo = demo, fight = true },
    icon = 29166,
    label = "widget.druid_balance_innervate",
    class = "DRUID",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:29166" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, PLAYER_FOCUS_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        SPELLS_CHANGED = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not (st.spell and st.grouped) then return nil end
        return (st.who or st.cd > 0) and data().tick or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        if not (st.spell and st.grouped) then return false end
        if opt and opt.show == "ready" then return st.cd <= 0 and st.why ~= "on" end
        return true
    end,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "who", label = "widget.dbi_who", values = {
            { v = nil, label = "widget.dbi_auto" }, { v = "focus", label = "widget.dbi_focus" },
            { v = "name", label = "widget.dbi_byname" },
        } },
        { key = "name", label = "widget.dbi_name", kind = "text", max = 30, ghost = "widget.dbi_name_ghost",
          when = function(item) return item and item.opt and item.opt.who == "name" end },
        { key = "when", label = "widget.dbi_when", values = {
            { v = nil, label = "widget.dbi_when_give" }, { v = "half", label = "widget.dbi_when_half" },
            { v = "third", label = "widget.dbi_when_third" },
        } },
        { key = "show", label = "widget.dbi_show", values = {
            { v = nil, label = "widget.dbi_always" }, { v = "ready", label = "widget.dbi_ready" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.druidBalanceInnervateLoaded = true

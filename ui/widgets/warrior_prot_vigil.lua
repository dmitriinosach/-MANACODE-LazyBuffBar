local _, ns = ...
local KEY = "war_vigil"
local PAD = 3
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function data()
    return ns.widgetData.war_vigil
end
local NAMES = {}
local TANKS = { "tank", "tank2" }
local function avail()
    if ns.PlayerClass() ~= "WARRIOR" then return false end
    return ns.IsLearned(data().spell) and true or false
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
local function memberOf(unit)
    local R = ns.Raid
    if not (unit and UnitExists(unit)) or UnitIsUnit(unit, "player") then return nil end
    local m = R.Member(unit)
    if m then return m end
    for _, r in ipairs(R.Roster()) do
        if r.click ~= "player" and UnitIsUnit(r.unit, unit) then return r end
    end
    return nil
end
local function wanted(opt)
    local to = opt and opt.to
    if to == "any" then return nil end
    if to == "focus" then return memberOf("focus") end
    if to == "name" then
        local nick = opt.name
        if not nick or nick == "" then return nil end
        for _, r in ipairs(ns.Raid.Roster()) do
            if r.click ~= "player" and (r.name == nick or r.click == nick) then return r end
        end
        return nil
    end
    local U = ns.Units
    if not U then return nil end
    for _, l in ipairs(TANKS) do
        local m = memberOf(U.Resolve(l))
        if m then return m, U.How(l) end
    end
    return nil
end
local function down(m)
    return (UnitIsDeadOrGhost(m.unit) or not UnitIsConnected(m.unit)) and true or false
end
local function state(opt)
    local d = data()
    local to = (opt and opt.to) or "tank2"
    local st = { to = to, lost = false, left = 0, always = not (opt and opt.show == "bad"), nick = opt and opt.name }
    if avail() then
        local name, _, icon = GetSpellInfo(d.spell)
        st.spell, st.icon = name, icon
    end
    local R = ns.Raid
    if not (st.spell and R) then
        st.why, st.verdict = "gone", "off"
        return st
    end
    NAMES[1] = st.spell
    R.Watch(KEY, NAMES, true)
    R.Touch()
    if not R.Grouped() then
        st.why, st.verdict = "solo", "off"
        return st
    end
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
    local want, how = wanted(opt)
    st.lost = to ~= "any" and not want
    if want then
        st.want, st.wantClass, st.how = want.name, want.class, how
        st.click = to == "focus" and "focus" or want.click
    elseif holder then
        st.click = holder.click
    end
    if holder then st.who, st.class = holder.name, holder.class end
    if want and down(want) then
        st.why, st.verdict = "wdead", "off"
    elseif not holder then
        st.why, st.verdict = "none", "none"
    elseif want and holder.guid ~= want.guid then
        st.why, st.verdict = "other", "bad"
    elseif st.left > 0 and st.left < d.soon then
        st.why, st.verdict = "soon", "soon"
    else
        st.why, st.verdict = "on", "ok"
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
    if view ~= "name" then
        local top = CreateFrame("Frame", nil, layer)
        top:SetAllPoints(layer)
        top:SetFrameLevel(layer:GetFrameLevel() + 3)
        layer.short = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fontSize(layer.short, s * 0.28)
        layer.short:SetPoint("BOTTOM", layer.tile.edge, "BOTTOM", 0, 2)
        return
    end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.left = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.left:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.left:SetJustifyH("RIGHT")
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.who:SetPoint("TOPRIGHT", layer.left, "TOPLEFT", -PAD, 0)
    layer.who:SetJustifyH("LEFT")
    layer.note = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.note:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.note:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -PAD, PAD)
    layer.note:SetJustifyH("LEFT")
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local y = st.why
    local held = y == "on" or y == "soon" or y == "other"
    local k = layer.look
    k.icon = st.icon
    k.grey = not held
    k.alpha = st.verdict == "off" and d.dim or 1
    k.edge = (y == "none" and S.none) or (y == "other" and S.soon) or nil
    k.text = (view ~= "name" and y == "soon") and W.Left(st.left) or ""
    k.textColor = S.soon
    ns.WTile.Paint(layer.tile, k)
    local ink = held and ns.WTile.ClassColor(st.class) or S.text
    if view ~= "name" then
        W.Text(layer.short, held and letters(st.who, d.letters) or "")
        W.Color(layer.short, ink)
        return
    end
    W.Text(layer.who, held and st.who or (y == "none" and ns.T("widget.wv_nobody") or ""))
    W.Color(layer.who, held and ink or S.none)
    W.Text(layer.left, (held and st.left > 0) and W.Left(st.left) or "")
    W.Color(layer.left, y == "soon" and S.soon or S.text)
    W.Text(layer.note, (y == "other" and st.want) and ns.T("widget.wv_to_short", st.want) or "")
    W.Color(layer.note, S.soon)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell, unit = st.click }
    end },
}
local LOST = { tank2 = "widget.wv_lost_tank", focus = "widget.wv_lost_focus", name = "widget.wv_lost_name" }
local function tip(_, st, _, _, btn)
    if not st.spell or st.why == "solo" then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local T = ns.T
    local rows = {}
    if st.who then
        rows[#rows + 1] = { l = T("widget.wv_on", st.who), r = st.left > 0 and W.Left(st.left) or nil,
            lc = ns.WTile.ClassColor(st.class), rc = st.why == "soon" and S.soon or nil }
    else
        rows[#rows + 1] = { l = T("widget.wv_nobody"), lc = S.none }
    end
    if st.want then
        local l = st.to == "tank2" and T("widget.wv_tank2") or T("widget.wv_want")
        rows[#rows + 1] = { l = l, r = st.want, rc = ns.WTile.ClassColor(st.wantClass) }
        if st.how then rows[#rows + 1] = { l = T("card.how_" .. st.how), lc = S.mute } end
    elseif st.lost then
        rows[#rows + 1] = { l = T(LOST[st.to], st.nick or "?"), lc = S.mute }
    end
    if st.why == "other" then
        rows[#rows + 1] = { l = T("widget.wv_move", st.who, st.want), lc = S.soon }
    elseif st.why == "wdead" then
        rows[#rows + 1] = { l = T("widget.wv_wdead", st.want), lc = S.mute }
    end
    rows[#rows + 1] = { l = T("widget.wv_why"), lc = S.mute }
    local a = btn and btn.attrs
    if a and a.spell and (a.unit or "") ~= (st.click or "") and InCombatLockdown() then
        rows[#rows + 1] = { l = T("widget.wv_later"), lc = S.soon }
    end
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { "solo", "off" },
    party = { "on", "ok", "PALADIN", "PALADIN", 24 },
    raid  = { "other", "bad", "ROGUE", "DEATHKNIGHT", 12 },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(data().spell)
    local st = { spell = name, icon = icon, to = (scene.opt and scene.opt.to) or "tank2", lost = false,
        left = (p[5] or 0) * 60, why = p[1], verdict = p[2], always = not (scene.opt and scene.opt.show == "bad") }
    if p[3] then
        st.who, st.class = ns.T("widget.bless_demo_name", p[1] == "on" and 2 or 1), p[3]
        st.want, st.wantClass = ns.T("widget.bless_demo_name", 2), p[4]
    end
    return st
end
ns.Widget.Register(KEY, {
    info = { text = "widget.war_vigil_info", demo = demo },
    icon = 50720,
    label = "widget.war_vigil",
    class = "WARRIOR",
    views = { one = { w = 1, h = 1 }, name = { w = 2, h = 1 } },
    order = { "one", "name" },
    view = "one",
    covers = { "spell:50720" },
    avail = avail,
    units = function(opt)
        if opt and opt.to then return nil end
        return TANKS
    end,
    events = {
        SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true, PLAYER_FOCUS_CHANGED = true,
        PLAYER_REGEN_ENABLED = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true,
        UNIT_SPELLCAST_SUCCEEDED = "player",
    },
    tick = function(st)
        if st.why == "gone" or st.why == "solo" then return nil end
        if st.who and st.left > 0 and st.left <= data().soon then return data().fast end
        return data().tick
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st)
        if st.verdict == "off" then return false end
        return st.always or (st.verdict ~= "ok" and st.verdict ~= "soon")
    end,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "to", label = "widget.wv_to", values = {
            { v = nil, label = "widget.wv_to_tank2" }, { v = "focus", label = "widget.wv_to_focus" },
            { v = "name", label = "widget.wv_to_name" }, { v = "any", label = "widget.wv_to_any" },
        } },
        { key = "name", label = "widget.wv_name", kind = "text", max = 30, ghost = "widget.wv_name_ghost",
          when = function(item) return item and item.opt and item.opt.to == "name" end },
        { key = "show", label = "widget.wv_show", values = {
            { v = nil, label = "widget.wv_always" }, { v = "bad", label = "widget.wv_when" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(KEY) end)
end
if ns.Units then
    ns.Units.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.warVigilWidgetLoaded = true

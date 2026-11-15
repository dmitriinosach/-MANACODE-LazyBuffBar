local _, ns = ...
local NAME_PAD = 3
local USE = "/use [target=mouseover,help,nodead][help,nodead][target=focus,help,nodead][target=player] item:%d"
local function data()
    return ns.widgetData.warlock_stone
end
local NAMES = {}
local function avail()
    local _, class = UnitClass("player")
    return class == "WARLOCK" and ns.IsLearned(data().create)
end
local function judge(st, soon)
    if st.who then
        st.why = "on"
        st.verdict = (st.left > 0 and st.left < soon * 60) and "soon" or "ok"
    elseif st.taken and st.item and st.cd <= 0 then
        st.why, st.verdict = "taken", "bad"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "off"
    elseif st.item then
        st.why, st.verdict = "put", "none"
    elseif st.shards > 0 then
        st.why, st.verdict = "make", "soon"
    else
        st.why, st.verdict = "empty", "off"
    end
end
local function state(opt)
    local d = data()
    local st = { stones = 0, shards = 0, cd = 0, left = 0, others = {}, grouped = false }
    local aura, _, icon = GetSpellInfo(d.aura)
    local make, _, makeIcon = GetSpellInfo(d.create)
    st.aura, st.icon, st.make, st.makeIcon = aura, icon, make, makeIcon
    for _, id in ipairs(d.items) do
        local c = GetItemCount(id) or 0
        if c > 0 then
            st.item = st.item or id
            st.stones = st.stones + c
        end
    end
    st.shards = GetItemCount(d.shard) or 0
    st.cd = ns.WTile.Left(1.5, GetItemCooldown(st.item or d.items[1]))
    local R = ns.Raid
    if aura and R then
        NAMES[1] = aura
        R.Watch("warlock_stone", NAMES, false)
        R.Watch("warlock_stone.own", NAMES, true)
        R.Touch()
        st.grouped = R.Grouped()
        local now = GetTime()
        local tguid = (UnitExists("target") and not UnitCanAttack("player", "target")) and UnitGUID("target") or nil
        local best
        for _, m in ipairs(R.Roster()) do
            local e = R.Own(m, NAMES)
            if e and (e == 0 or e > now) then
                if not best or e == 0 or e > best then
                    best = e
                    st.who, st.class = m.name, m.class
                    st.left = e > 0 and (e - now) or 0
                end
            else
                local a = R.End(m, NAMES)
                if a and (a == 0 or a > now) then
                    st.others[#st.others + 1] = { name = m.name, class = m.class, unit = m.unit }
                    if m.guid == tguid then st.taken = m.name end
                end
            end
        end
    end
    judge(st, opt and opt.soon or d.soon)
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -NAME_PAD, -NAME_PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", NAME_PAD, NAME_PAD)
    layer.sub:SetJustifyH("LEFT")
end
local HINT = { taken = "widget.ws_taken", cd = "widget.ws_cd", put = "widget.ws_put", make = "widget.ws_make", empty = "widget.ws_empty" }
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local why = st.why
    local wide = view == "wide"
    local k = layer.look
    local time = (why == "on" and st.left > 0 and W.Left(st.left)) or (why == "cd" and W.Left(st.cd)) or ""
    k.icon = why == "make" and st.makeIcon or st.icon
    k.grey = v == "off"
    k.alpha = v == "off" and data().dim or 1
    k.edge = (v == "ok" and S.ok) or (v == "soon" and S.soon) or (v == "none" and S.none) or (v == "bad" and S.bad) or nil
    k.text = wide and "" or time
    k.textColor = (why == "on" and v == "soon") and S.soon or S.text
    k.mark = (why == "taken" and not wide) and ns.T("widget.ws_taken") or nil
    k.markColor = S.bad
    k.corner = why == "empty" and "0" or nil
    k.cornerColor = S.bad
    ns.WTile.Paint(layer.tile, k)
    if not wide then return end
    local on = why == "on"
    W.Text(layer.who, on and st.who or ns.T(HINT[why]))
    W.Color(layer.who, (on and ns.WTile.ClassColor(st.class)) or (v == "bad" and S.bad) or (v == "off" and S.mute) or S.text)
    W.Text(layer.sub, time)
    W.Color(layer.sub, (on and v == "soon") and S.soon or S.text)
end
local attrCache = {}
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        local key = st.item and ("i" .. st.item) or (st.make and "make") or "none"
        local a = attrCache[key]
        if a then return a end
        if st.item then a = { type = "macro", macrotext = USE:format(st.item) }
        elseif st.make then a = { type = "spell", spell = st.make }
        else a = {} end
        attrCache[key] = a
        return a
    end },
}
local LINE = { taken = "widget.ws_taken_tip", make = "widget.ws_make_tip", empty = "widget.ws_empty_tip" }
local function tip(st)
    if not st.aura then return nil end
    local S = ns.STATE
    local rows = {}
    if st.who then
        rows[1] = { l = st.who, r = st.left > 0 and ns.Widget.Left(st.left) or ns.T("widget.ws_mine"), lc = ns.WTile.ClassColor(st.class) }
    end
    local lines = data().lines
    for i, o in ipairs(st.others) do
        if i > lines then break end
        local by = select(8, UnitBuff(o.unit, st.aura))
        rows[#rows + 1] = { l = o.name, r = by and UnitName(by) or ns.T("widget.ws_other"), lc = ns.WTile.ClassColor(o.class), rc = S.mute }
    end
    rows[#rows + 1] = { l = ns.T("widget.ws_stones"), r = tostring(st.stones), rc = st.stones > 0 and S.text or S.mute }
    rows[#rows + 1] = { l = ns.T("widget.ws_shards"), r = tostring(st.shards), rc = st.shards > 0 and S.text or S.bad }
    if st.cd > 0 then rows[#rows + 1] = { l = ns.T("widget.ws_cd"), r = ns.Widget.Left(st.cd) } end
    return st.aura, LINE[st.why] and ns.T(LINE[st.why], st.taken) or nil, rows
end
local DEMO = { solo = {}, party = { "PRIEST", 720, 0 }, raid = { "PALADIN", 90, 1 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local aura, _, icon = GetSpellInfo(d.aura)
    local make, _, makeIcon = GetSpellInfo(d.create)
    local st = { aura = aura, icon = icon, make = make, makeIcon = makeIcon, item = d.items[1], stones = 1, shards = 12, cd = 0, left = 0,
                 others = {}, grouped = scene.size ~= "solo" }
    if p[1] then
        st.who, st.class, st.left = ns.T("widget.bless_demo_name", 1), p[1], p[2]
        if p[3] > 0 then st.others[1] = { name = ns.T("widget.bless_demo_name", 2), class = "DRUID", unit = "raid2" } end
    end
    judge(st, scene.opt and scene.opt.soon or d.soon)
    return st
end
local function soonValues()
    local d = data().soon
    local out = {}
    for _, n in ipairs({ 1, 2, 5 }) do
        out[#out + 1] = { v = n ~= d and n or nil, text = ns.T("time.minutes", n) }
    end
    return out
end
ns.Widget.Register("warlock_stone", {
    info = { text = "widget.warlock_stone_info", demo = demo },
    icon = 47883,
    label = "widget.warlock_stone",
    class = "WARLOCK",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:47883", "spell:47884" },
    avail = avail,
    events = {
        BAG_UPDATE = true, BAG_UPDATE_COOLDOWN = true, PLAYER_TARGET_CHANGED = true, RAID_ROSTER_UPDATE = true,
        PARTY_MEMBERS_CHANGED = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.who or st.cd > 0) and data().tick or nil end,
    State = state,
    active = function(st, opt) return not (opt and opt.show == "group") or st.grouped end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return tip(st) end,
    opts = {
        { key = "soon", label = "widget.ws_soon", values = soonValues },
        { key = "show", label = "widget.ws_show", values = {
            { v = nil, label = "widget.ws_always" }, { v = "group", label = "widget.ws_group" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("warlock_stone") end)
end
ns.warlockStoneWidgetLoaded = true

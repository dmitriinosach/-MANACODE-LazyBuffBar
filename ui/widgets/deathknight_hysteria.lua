local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "dk_hysteria"
local function data()
    return ns.widgetData.dk_hysteria
end
local NAMES = {}
local function avail()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT" and ns.IsLearned(data().id)
end
local function marked()
    local db = LazyBuffBarCharDB
    local n = type(db) == "table" and db.dkHysteria or nil
    return (type(n) == "string" and n ~= "") and n or nil
end
local function mark(name)
    if type(LazyBuffBarCharDB) ~= "table" then LazyBuffBarCharDB = {} end
    LazyBuffBarCharDB.dkHysteria = name
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
local function macroOf(opt, spell)
    local mode = opt and opt.who
    if mode == "self" then return "/cast [@player] " .. spell end
    if mode == "mark" then
        local n = marked()
        if not n then return "/cast [@player] " .. spell end
        return "/cast [@" .. n .. ",help,nodead][@player] " .. spell
    end
    return "/cast [@focus,help,nodead][@player] " .. spell
end
local function chosen(opt)
    local R = ns.Raid
    local mode = opt and opt.who
    local me = R.Member("player")
    if mode == "self" then return me, nil, false end
    if mode == "mark" then
        local n = marked()
        if not n then return me, nil, true end
        for _, m in ipairs(R.Roster()) do
            if m.name == n or m.click == n then return m, nil, false end
        end
        return nil, n, false
    end
    if not UnitExists("focus") then return me, nil, true end
    local guid = UnitGUID("focus")
    for _, m in ipairs(R.Roster()) do
        if m.guid == guid then return m, nil, false end
    end
    if not UnitCanAssist("player", "focus") then return me, nil, true end
    return nil, UnitName("focus"), false
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { cd = 0, hp = 0, left = 0, self = false }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    local R = ns.Raid
    if not (st.spell and R) then
        st.why, st.verdict = "gone", "off"
        return st
    end
    st.macro = macroOf(opt, st.spell)
    NAMES[1] = st.spell
    R.Watch(KEY, NAMES, true)
    R.Range(KEY, st.spell)
    R.Touch()
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
    local m, other, alone = chosen(opt)
    st.self = alone
    if not m then
        st.who, st.why, st.verdict = other, "nogroup", "off"
        return st
    end
    st.who, st.class = m.name, m.class
    local max = UnitHealthMax(m.unit) or 0
    st.hp = max > 0 and math.floor((UnitHealth(m.unit) or 0) * 100 / max + 0.5) or 0
    local e = R.Own(m, NAMES)
    if e and (e == 0 or e > now) then
        st.left = e > 0 and (e - now) or 0
        st.why, st.verdict = "on", "full"
    elseif m.off then
        st.why, st.verdict = "gone", "off"
    elseif m.dead then
        st.why, st.verdict = "dead", "off"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "none"
    elseif m.out[KEY] then
        st.why, st.verdict = "far", "bad"
    elseif UnitAffectingCombat(m.unit) then
        st.why, st.verdict = "fight", "ok"
    else
        st.why, st.verdict = "calm", "text"
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
    if view ~= "wide" then
        local top = CreateFrame("Frame", nil, layer)
        top:SetAllPoints(layer)
        top:SetFrameLevel(layer:GetFrameLevel() + 3)
        layer.short = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fontSize(layer.short, s * 0.28)
        layer.short:SetPoint("BOTTOM", layer.tile.edge, "BOTTOM", 0, 2)
        return
    end
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
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw, h = math.max(4, math.floor(s * 0.3)), max = 100, color = ns.STATE.ok,
        flash = false })
    layer.bar:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
end
local EDGE = { ok = ns.STATE.ok, bad = ns.STATE.bad }
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "none" or v == "off"
    k.alpha = v == "off" and d.dim or 1
    k.edge = EDGE[v]
    if v == "full" then
        k.text, k.textColor = st.left > 0 and W.Left(st.left) or "", S.full
    elseif v == "none" then
        k.text, k.textColor = W.Left(st.cd), S.text
    else
        k.text, k.textColor = "", S.text
    end
    ns.WTile.Paint(layer.tile, k)
    local name = st.who or ""
    local ink = st.who and ns.WTile.ClassColor(st.class) or S.text
    if view ~= "wide" then
        W.Text(layer.short, letters(name, d.letters))
        W.Color(layer.short, ink)
        return
    end
    W.Text(layer.who, name)
    W.Color(layer.who, ink)
    layer.bar:Set(st.who and st.verdict ~= "off" and st.hp or 0)
end
local function remember(b, button)
    local h = b.host
    if button ~= "RightButton" or not h or h.edit or InCombatLockdown() then return end
    if not (UnitExists("target") and UnitIsPlayer("target") and UnitCanAssist("player", "target")) then return end
    local n, realm = UnitName("target")
    if not n then return end
    mark((realm and realm ~= "") and (n .. "-" .. realm) or n)
    if (h.opt and h.opt.who) ~= "mark" then
        local at = h.addr
        if at and ns.buffbar and ns.buffbar.SetWidgetOpt then
            ns.buffbar:SetWidgetOpt(at[1], at[2], at[3], "who", "mark")
        else
            local o = {}
            for key, val in pairs(h.opt or {}) do o[key] = val end
            o.who = "mark"
            ns.Widget.SetOpt(h, o)
        end
    end
    ns.Widget.Poke(KEY)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp",
      attrs = function(st)
          if not st.macro then return {} end
          return { type1 = "macro", macrotext1 = st.macro }
      end,
      post = remember },
}
local WHY = { far = "widget.hy_far", dead = "widget.hy_dead", gone = "widget.hy_gone", nogroup = "widget.hy_nogroup",
              calm = "widget.hy_calm" }
local function tip(_, st)
    if not st.spell then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    if st.who then
        rows[#rows + 1] = { l = ns.T("widget.hy_who"), r = st.who, rc = ns.WTile.ClassColor(st.class) }
        if st.verdict ~= "off" then rows[#rows + 1] = { l = ns.T("widget.hy_hp"), r = st.hp .. "%" } end
    end
    if st.left > 0 then rows[#rows + 1] = { l = ns.T("widget.hy_on"), r = W.Left(st.left), rc = S.full } end
    if WHY[st.why] then rows[#rows + 1] = { l = ns.T(WHY[st.why]), lc = st.verdict == "bad" and S.bad or S.mute } end
    if st.self then rows[#rows + 1] = { l = ns.T("widget.hy_self"), lc = S.mute } end
    rows[#rows + 1] = { l = ns.T("widget.hy_cost"), lc = S.mute }
    rows[#rows + 1] = { l = ns.T("widget.hy_rmb"), lc = S.mute }
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { "calm", "text", "DEATHKNIGHT", 100, 0, 0 },
    party = { "fight", "ok", "ROGUE", 92, 0, 0 },
    raid  = { "on", "full", "WARRIOR", 71, 18, 0 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    return { spell = name, icon = icon, cd = p[6], who = ns.T("widget.bless_demo_name", 3), class = p[3], self = false,
             hp = p[4], left = p[5], why = p[1], verdict = p[2] }
end
ns.Widget.Register(KEY, {
    info = { text = "widget.dk_hysteria_info", demo = demo },
    icon = 49016,
    label = "widget.dk_hysteria",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:49016" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, PLAYER_FOCUS_CHANGED = true, UNIT_HEALTH = { player = true, focus = true },
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        return (st.cd > 0 or st.left > 0 or st.why == "fight") and data().tick or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Caption = function(_, opt)
        local n = (opt and opt.who == "mark") and marked() or nil
        return n and ns.T("widget.hy_marked", n) or nil
    end,
    Tip = tip,
    opts = {
        { key = "who", label = "widget.hy_whom", values = {
            { v = nil, label = "widget.hy_focus" }, { v = "mark", label = "widget.hy_mark" }, { v = "self", label = "widget.hy_me" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.dkHysteriaWidgetLoaded = true

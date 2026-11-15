local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "hunter_md"
local function data()
    return ns.widgetData.hunter_md
end
local function spell()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
local function avail()
    local s = spell()
    return s ~= nil and ns.IsLearned(s.id)
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
local function orderOf(opt)
    local d = data()
    return d.order[opt and opt.who or "auto"] or d.order.auto
end
local function petOn(opt)
    return not (opt and opt.pet == "off")
end
local function address(unit)
    local name, realm = UnitName(unit)
    if not name or name == "" or name == UNKNOWNOBJECT then return unit end
    return (realm and realm ~= "") and (name .. "-" .. realm) or name
end
local function candidates(opt)
    local list, parts = {}, {}
    for _, l in ipairs(orderOf(opt)) do
        local u = ns.Units.Resolve(l)
        if u and not UnitIsUnit(u, "player") and UnitCanAssist("player", u) then
            list[#list + 1] = { unit = u, via = l, dead = UnitIsDeadOrGhost(u) and true or false }
        end
        if l == "focus" then
            parts[#parts + 1] = "[@focus,help,nodead]"
        elseif u and not UnitIsUnit(u, "player") then
            parts[#parts + 1] = "[@" .. address(u) .. ",help,nodead]"
        end
    end
    if petOn(opt) then
        parts[#parts + 1] = "[@pet,exists,nodead]"
        if UnitExists("pet") then
            list[#list + 1] = { unit = "pet", via = "pet", dead = UnitIsDeadOrGhost("pet") and true or false }
        end
    end
    return list, table.concat(parts)
end
local function buffs(s)
    local now = GetTime()
    local armed, xfer
    for i = 1, 40 do
        local name, _, _, _, _, _, expires, _, _, _, id = UnitBuff("player", i)
        if not name then break end
        if id == s.xfer or id == s.armed then
            local left = (expires and expires > now) and (expires - now) or 0
            if id == s.xfer then xfer = left else armed = left end
        end
    end
    return armed, xfer
end
local function state(opt)
    local d = data()
    local s = spell()
    local st = { cd = 0, left = 0 }
    if s and avail() then
        local name, _, icon = GetSpellInfo(s.id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.why, st.verdict = "gone", "off"
        return st
    end
    local list, conds = candidates(opt)
    st.macro = "/cast " .. (conds ~= "" and (conds .. " ") or "") .. st.spell
    local pick
    for _, c in ipairs(list) do
        if not c.dead then pick = c; break end
    end
    pick = pick or list[1]
    if pick then
        st.who, st.via = UnitName(pick.unit), pick.via
        if pick.via ~= "pet" then
            local _, class = UnitClass(pick.unit)
            st.class = class
        end
        st.how = ns.Units.How(pick.via)
    end
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
    local armed, xfer = buffs(s)
    if UnitIsDeadOrGhost("player") then
        st.why, st.verdict = "me", "off"
    elseif xfer then
        st.why, st.verdict, st.left = "xfer", "ok", xfer
    elseif armed then
        st.why, st.verdict, st.left = "armed", "ok", armed
    elseif not pick then
        st.why, st.verdict = "none", "off"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "soon"
    elseif pick.dead then
        st.why, st.verdict = "dead", "bad"
    elseif IsSpellInRange(st.spell, pick.unit) == 0 then
        st.why, st.verdict = "far", "bad"
    else
        st.why, st.verdict = "go", "ok"
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
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.who:SetJustifyH("LEFT")
    layer.note = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.note:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.note:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -PAD, PAD)
    layer.note:SetJustifyH("LEFT")
end
local NOTE = { go = "widget.hm_go", xfer = "widget.hm_xfer", far = "widget.hm_far", dead = "widget.hm_dead",
               none = "widget.hm_none_short", me = "widget.hm_dead" }
local function ink(st)
    local S = ns.STATE
    local y = st.why
    if y == "go" then return S.ok end
    if y == "armed" or y == "xfer" then return S.full end
    if y == "cd" then return S.soon end
    if y == "dead" or y == "far" then return S.bad end
    return S.mute
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local y = st.why
    local off = st.verdict == "off"
    local c = ink(st)
    local k = layer.look
    k.icon = st.icon
    k.grey = y == "cd" or off
    k.alpha = off and data().dim or 1
    k.tint = y == "xfer" and S.full or nil
    k.edge = (y ~= "cd" and not off) and c or nil
    if y == "armed" or y == "xfer" then
        k.text = W.Left(st.left)
    elseif y == "cd" then
        k.text = W.Left(st.cd)
    else
        k.text = ""
    end
    k.textColor = c
    ns.WTile.Paint(layer.tile, k)
    local name = st.who or ""
    local nameInk = st.who and ns.WTile.ClassColor(st.class) or S.text
    if view ~= "wide" then
        W.Text(layer.short, letters(name, data().letters))
        W.Color(layer.short, nameInk)
        return
    end
    W.Text(layer.who, name)
    W.Color(layer.who, nameInk)
    W.Text(layer.note, NOTE[y] and ns.T(NOTE[y]) or k.text)
    W.Color(layer.note, c)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.macro then return {} end
        return { type = "macro", macrotext = st.macro }
    end },
}
local VIA = { focus = "widget.hm_focus", tank = "widget.hm_tank", tank2 = "widget.hm_tank2", pet = "widget.hm_via_pet" }
local function tip(_, st, _, _, btn)
    if not st.spell then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    if st.who then
        rows[#rows + 1] = { l = ns.T("widget.hm_whom"), r = st.who, rc = ns.WTile.ClassColor(st.class) }
        local via = ns.T(VIA[st.via])
        if st.how then via = via .. ns.T("facts.sep") .. ns.T("card.how_" .. st.how) end
        rows[#rows + 1] = { l = via, lc = S.mute }
    end
    local y = st.why
    if y == "xfer" then
        rows[#rows + 1] = { l = ns.T("widget.hm_xfer_left", W.Left(st.left)), lc = S.full }
    elseif y == "armed" then
        rows[#rows + 1] = { l = ns.T("widget.hm_armed", W.Left(st.left)), lc = S.full }
    elseif y == "cd" then
        rows[#rows + 1] = { l = ns.T("widget.hm_cd", W.Left(st.cd)), lc = S.soon }
    elseif y == "none" then
        rows[#rows + 1] = { l = ns.T("widget.hm_none"), lc = S.mute }
    elseif NOTE[y] then
        rows[#rows + 1] = { l = ns.T(NOTE[y]), lc = ink(st) }
    end
    local written = btn and btn.attrs and btn.attrs.macrotext
    if written and st.macro and written ~= st.macro and InCombatLockdown() then
        rows[#rows + 1] = { l = ns.T("widget.hm_later"), lc = S.soon }
    end
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { "go", "ok", nil, "pet", 0, 0 },
    party = { "armed", "ok", "WARRIOR", "focus", 22, 0 },
    raid  = { "cd", "soon", "PALADIN", "tank", 0, 14 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local s = d.classes[scene.class] or d.classes.HUNTER
    local name, _, icon = GetSpellInfo(s.id)
    local who = p[4] == "pet" and ns.T("widget.hm_petname") or ns.T("widget.bless_demo_name", 2)
    return { spell = name, icon = icon, cd = p[6], left = p[5], who = who, class = p[3], via = p[4], why = p[1], verdict = p[2] }
end
local function coverList()
    local out = {}
    for _, s in pairs(data().classes) do out[#out + 1] = "spell:" .. s.id end
    table.sort(out)
    return out
end
ns.Widget.Register(KEY, {
    info = { text = "widget.hunter_md_info", demo = demo },
    icon = 34477,
    label = "widget.hunter_md",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = coverList(),
    avail = avail,
    units = function(opt)
        local out = {}
        for _, l in ipairs(orderOf(opt)) do
            if l ~= "focus" then out[#out + 1] = l end
        end
        return out
    end,
    events = {
        SPELL_UPDATE_COOLDOWN = true, UNIT_AURA = "player", PLAYER_FOCUS_CHANGED = true, UNIT_PET = "player",
        RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, SPELLS_CHANGED = true, PLAYER_DEAD = true,
        PLAYER_ALIVE = true, PLAYER_UNGHOST = true, PLAYER_REGEN_ENABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        local y = st.why
        if y == "xfer" then return data().fast end
        if y == "gone" or y == "me" or y == "none" then return nil end
        return data().tick
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "who", label = "widget.hm_whom", values = {
            { v = nil, label = "widget.hm_auto" }, { v = "tank", label = "widget.hm_tank" },
            { v = "tank2", label = "widget.hm_tank2" }, { v = "focus", label = "widget.hm_focus" },
        } },
        { key = "pet", label = "widget.hm_pet", values = {
            { v = nil, label = "widget.hm_on" }, { v = "off", label = "widget.hm_off" },
        } },
    },
})
if ns.Units then
    ns.Units.OnChange(function() ns.Widget.Poke(KEY) end)
end
ns.hunterMdWidgetLoaded = true

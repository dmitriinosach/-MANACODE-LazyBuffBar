local _, ns = ...
local PAD = 3
local NAME_PART = 0.3
local function data()
    return ns.widgetData.rogue_tricks
end
local function spells()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
local function avail()
    local s = spells()
    return s ~= nil and ns.IsLearned(s.spell)
end
local function friend(unit)
    return UnitExists(unit) and not UnitCanAttack("player", unit) and not UnitIsUnit(unit, "player") and true or false
end
local function clickName(unit)
    local name, realm = UnitName(unit)
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end
local function recipient(to)
    local U = ns.Units
    if to == nil or to == "tank2" then
        local l = to or "tank"
        local u = U and U.Resolve(l)
        if u and friend(u) then return u, U.How(l), clickName(u) end
        if to then return nil end
    end
    if to == nil or to == "focus" then
        if friend("focus") then return "focus", "focus", "focus" end
        return nil
    end
    if to == "tt" and friend("targettarget") then return "targettarget", "tt", "targettarget" end
    return nil
end
local function myAuras(s, now)
    local armed, transfer = 0, 0
    for i = 1, data().auraMax do
        local n, _, _, _, _, _, expires, _, _, _, id = UnitAura("player", i, "HELPFUL")
        if not n then break end
        if id == s.armed or id == s.transfer then
            local left = (expires and expires > 0) and math.max(0, expires - now) or 0.01
            if id == s.transfer then transfer = left else armed = left end
        end
    end
    return armed, transfer
end
local function state(opt)
    local s = spells()
    local st = { cd = 0, armed = 0, transfer = 0, fight = UnitAffectingCombat("player") and true or false }
    if s and ns.IsLearned(s.spell) then
        local name, _, icon = GetSpellInfo(s.spell)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.why, st.verdict = "none", "off"
        return st
    end
    st.cd = ns.WTile.Left(data().gcd, GetSpellCooldown(st.spell))
    st.armed, st.transfer = myAuras(s, GetTime())
    local u, how, click = recipient(opt and opt.to)
    if u then
        st.who, st.how, st.click = UnitName(u), how, click
        local _, c = UnitClass(u)
        st.whoClass = c
    end
    local grouped = (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0
    if st.transfer > 0 then
        st.why, st.verdict = "transfer", "act"
    elseif st.armed > 0 then
        st.why, st.verdict = "armed", "act"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "soon"
    elseif not grouped then
        st.why, st.verdict = "solo", "off"
    elseif not u then
        st.why, st.verdict = "nobody", "off"
    elseif UnitIsDeadOrGhost(u) then
        st.why, st.verdict = "dead", "bad"
    elseif IsSpellInRange(st.spell, u) == 0 then
        st.why, st.verdict = "far", "bad"
    else
        st.why, st.verdict = "ready", "ok"
    end
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then
        local top = CreateFrame("Frame", nil, layer)
        top:SetAllPoints(layer.tile.edge)
        top:SetFrameLevel(layer:GetFrameLevel() + 3)
        layer.nm = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        layer.nm:SetPoint("TOPLEFT", layer.tile.edge, "TOPLEFT", 1, -1)
        layer.nm:SetPoint("TOPRIGHT", layer.tile.edge, "TOPRIGHT", -1, -1)
        layer.nm:SetHeight(math.max(8, math.floor(s * NAME_PART + 0.5)))
        layer.nm:SetJustifyH("CENTER")
        local file, _, flags = layer.nm:GetFont()
        if file then layer.nm:SetFont(file, math.max(7, math.floor(s * NAME_PART - 1)), flags ~= "" and flags or "OUTLINE") end
        return
    end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.nm = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.nm:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.nm:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.nm:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD + 2)
    layer.sub:SetJustifyH("LEFT")
    local w = layer.w - s - gap
    layer.bar = ns.Gauge.New(layer, "bar", { w = w, h = 2, max = 1, color = data().bar, flash = false })
    layer.bar.fr:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
end
local WHY = {
    transfer = "widget.rogue_tr_transfer", armed = "widget.rogue_tr_armed", cd = "widget.rogue_tr_cd",
    solo = "widget.rogue_tr_solo", nobody = "widget.rogue_tr_nobody", dead = "widget.rogue_tr_dead",
    far = "widget.rogue_tr_far", ready = "widget.rogue_tr_ready",
}
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    local act = v == "act"
    k.icon = st.icon
    k.grey = st.cd > 0 and not act
    k.alpha = v == "off" and data().dim or 1
    k.edge = ((v == "ok" or act) and S.ok) or (v == "bad" and S.bad) or nil
    k.text = (st.transfer > 0 and W.Left(st.transfer)) or (st.cd > 0 and not act and W.Left(st.cd)) or ""
    k.textColor = st.transfer > 0 and S.ok or S.text
    k.corner = (st.armed > 0 and st.transfer == 0) and W.Left(st.armed) or nil
    k.glow = st.why == "armed"
    ns.WTile.Paint(layer.tile, k)
    W.Text(layer.nm, st.who or "")
    W.Color(layer.nm, st.who and ns.WTile.ClassColor(st.whoClass) or S.text)
    if view ~= "wide" then return end
    local key = WHY[st.why]
    W.Text(layer.sub, key and ns.T(key, W.Left(st.cd)) or "")
    W.Color(layer.sub, (v == "bad" and S.bad) or (act and S.ok) or (v == "soon" and S.soon) or S.text)
    layer.bar:Set(st.transfer > 0 and math.min(1, st.transfer / data().dur) or 0, 1)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell, unit = st.click }
    end },
}
local function tip(_, st)
    if not st.spell then return nil end
    local parts = {}
    if st.who then
        parts[1] = ns.T("widget.rogue_tr_to", st.who, ns.T("widget.rogue_tr_how_" .. (st.how or "tank")))
    end
    local key = WHY[st.why]
    if key and st.why ~= "ready" then parts[#parts + 1] = ns.T(key, ns.Widget.Left(st.cd)) end
    if #parts == 0 then return nil end
    return st.spell, table.concat(parts, "\n")
end
local DEMO = {
    solo  = { "solo", "off", 0, 0, 0 },
    party = { "ready", "ok", 0, 0, 0, "WARRIOR" },
    raid  = { "transfer", "act", 0, 0, 4, "PALADIN" },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local s = data().classes.ROGUE
    local name, _, icon = GetSpellInfo(s.spell)
    local st = { spell = name, icon = icon, why = p[1], verdict = p[2], cd = p[3], armed = p[4], transfer = p[5], fight = false }
    if p[6] then st.who, st.whoClass, st.how = ns.T("widget.bless_demo_name", 1), p[6], "role" end
    return st
end
local function units(opt)
    local to = opt and opt.to
    if to == "tank2" then return { "tank2" } end
    if to == nil then return { "tank" } end
    return {}
end
ns.Widget.Register("rogue_tricks", {
    info = { text = "widget.rogue_tricks_info", demo = demo },
    icon = 57934,
    label = "widget.rogue_tricks",
    class = "ROGUE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:57934" },
    avail = avail,
    units = units,
    events = {
        UNIT_AURA = "player", SPELL_UPDATE_COOLDOWN = true, PLAYER_FOCUS_CHANGED = true, PLAYER_TARGET_CHANGED = true,
        UNIT_TARGET = "target", PARTY_MEMBERS_CHANGED = true, RAID_ROSTER_UPDATE = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not st.spell then return nil end
        if st.cd > 0 or st.verdict == "act" or st.fight or st.who then return data().tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "to", label = "widget.rogue_tr_opt", values = {
            { v = nil, label = "widget.rogue_tr_to_tank" }, { v = "tank2", label = "widget.rogue_tr_to_tank2" },
            { v = "focus", label = "widget.rogue_tr_to_focus" }, { v = "tt", label = "widget.rogue_tr_to_tt" },
        } },
    },
})
if ns.Units and ns.Units.OnChange then
    ns.Units.OnChange(function() ns.Widget.Poke("rogue_tricks") end)
end
ns.rogueTricksWidgetLoaded = true

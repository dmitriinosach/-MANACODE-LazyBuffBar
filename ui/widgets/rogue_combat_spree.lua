local _, ns = ...
local KEY = "rogue_combat_spree"
local PAD = 3
local BAR_PART = 0.3
local function data()
    return ns.widgetData.rogue_combat_spree
end
local function avail()
    local _, class = UnitClass("player")
    return class == "ROGUE" and ns.IsLearned(data().spree)
end
local energy = CreateFrame("Frame")
local watching = false
energy:SetScript("OnEvent", function(_, _, unit)
    if unit == "player" then ns.Widget.Poke(KEY) end
end)
local function watchEnergy(on)
    if on == watching then return end
    watching = on
    if on then energy:RegisterEvent("UNIT_ENERGY") else energy:UnregisterEvent("UNIT_ENERGY") end
end
local function leftOf(expires, now)
    if expires and expires > 0 then return math.max(0.01, expires - now) end
    return 0.01
end
local function myAuras(spreeName, now)
    local d = data()
    local spree, spreeDur, ar, snd = 0, 0, 0, 0
    for i = 1, d.auraMax do
        local n, _, _, _, _, dur, expires, _, _, _, sid = UnitAura("player", i, "HELPFUL")
        if not n then break end
        if sid == d.spree or sid == d.spreeAura or n == spreeName then
            if spree == 0 then spree, spreeDur = leftOf(expires, now), dur or 0 end
        elseif sid == d.ar then
            ar = leftOf(expires, now)
        elseif sid == d.snd or sid == d.sndAlt then
            snd = (expires and expires > 0) and math.max(0.01, expires - now) or 999
        end
    end
    return spree, spreeDur, ar, snd
end
local function enemy()
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and true or false
end
local function far(spell)
    local r = IsSpellInRange(spell, "target")
    if r == 0 then return true end
    if r == nil then return not CheckInteractDistance("target", data().range) end
    return false
end
local function capOf(opt, max)
    local v = opt and opt.cap
    if v == "any" then return nil end
    if type(v) == "number" then return v end
    local d = data()
    return max > 0 and (max - d.spare) or d.capFallback
end
local function state(opt)
    local d = data()
    local st = { cd = 0, cdStart = 0, cdDur = 0, left = 0, dur = d.dur, ar = 0, snd = -1, energy = 0, max = 0,
        fight = UnitAffectingCombat("player") and true or false }
    if ns.IsLearned(d.spree) then
        local name, _, icon = GetSpellInfo(d.spree)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        watchEnergy(false)
        st.why, st.verdict = "none", "off"
        return st
    end
    st.arIcon = select(3, GetSpellInfo(d.ar))
    local now = GetTime()
    local start, cdDur = GetSpellCooldown(st.spell)
    st.cd = ns.WTile.Left(d.gcd, start, cdDur)
    if st.cd > 0 then st.cdStart, st.cdDur = start, cdDur end
    local left, dur, ar, snd = myAuras(st.spell, now)
    st.left, st.ar = left, ar
    if dur > 0 then st.dur = dur end
    if not (opt and opt.snd == false) and (ns.IsLearned(d.snd) or ns.IsLearned(d.sndAlt)) then st.snd = snd end
    st.energy = UnitPower("player", d.power) or 0
    st.max = UnitPowerMax("player", d.power) or 0
    st.cap = capOf(opt, st.max)
    if st.left > 0 then
        st.why, st.verdict = "spree", "act"
    elseif not st.fight then
        st.why, st.verdict = "ooc", "off"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "cd"
    elseif not enemy() then
        st.why, st.verdict = "notarget", "off"
    elseif st.ar > 0 and not (opt and opt.ar == false) then
        st.why, st.verdict = "ar", "soon"
    elseif st.cap and st.energy > st.cap then
        st.why, st.verdict = "energy", "soon"
    elseif st.snd >= 0 and st.snd <= d.sndMin then
        st.why, st.verdict = "snd", "soon"
    elseif far(st.spell) then
        st.why, st.verdict = "far", "soon"
    else
        st.why, st.verdict = "ready", "ok"
    end
    watchEnergy(st.verdict == "ok" or st.verdict == "soon")
    return st
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    local cdf = CreateFrame("Cooldown", nil, layer)
    cdf:SetAllPoints(layer.tile.icon)
    cdf.noCooldownCount = true
    layer.cdf, layer.cdS, layer.cdD = cdf, 0, 0
    layer.tile.text:GetParent():SetFrameLevel(cdf:GetFrameLevel() + 1)
    if view ~= "wide" then return end
    local rw = layer.w - s - gap
    local ef = CreateFrame("Frame", nil, layer)
    ef:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    ef:SetWidth(rw)
    ef:SetHeight(s)
    local bg = ef:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints(ef)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.sub = ef:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.sub:SetPoint("TOPLEFT", ef, "TOPLEFT", PAD, -PAD)
    layer.sub:SetPoint("TOPRIGHT", ef, "TOPRIGHT", -PAD, -PAD)
    layer.sub:SetJustifyH("LEFT")
    local h = math.max(4, math.floor(s * BAR_PART + 0.5))
    layer.bar = ns.Gauge.New(ef, "bar", { w = rw, h = h, max = 1, color = data().bar, flash = false })
    layer.bar.fr:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 0)
    layer.ef = ef
    local af = CreateFrame("Frame", nil, layer)
    af:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    af:SetWidth(s)
    af:SetHeight(s)
    layer.arTile = ns.WTile.New(af, 0, 0, s)
    layer.arLook = {}
    layer.af = af
end
local marks = {}
local function markOf(cap)
    local m = marks[cap]
    if not m then
        m = { cap }
        marks[cap] = m
    end
    return m
end
local NO_MARKS = {}
local function line(st)
    local why = st.why
    if why == "ar" then return ns.T("widget.rogue_cs_ar", math.ceil(st.ar)) end
    if why == "energy" then return ns.T("widget.rogue_cs_energy", st.energy) end
    if why == "snd" then return ns.T("widget.rogue_cs_snd") end
    if why == "far" then return ns.T("widget.rogue_cs_far") end
    if why == "ready" then return ns.T("widget.rogue_cs_go", st.energy) end
    return ""
end
local function sweep(layer, st)
    if layer.cdS == st.cdStart and layer.cdD == st.cdDur then return end
    layer.cdS, layer.cdD = st.cdStart, st.cdDur
    layer.cdf:SetCooldown(st.cdStart, st.cdDur)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    local high = st.cap ~= nil and st.energy > st.cap
    k.icon = st.icon
    k.grey = v ~= "act" and st.cd > 0
    k.alpha = v == "off" and d.dim or 1
    k.edge = ((v == "act" or v == "ok") and S.ok) or (v == "soon" and S.soon) or nil
    k.glow = v == "ok"
    if v == "act" then
        k.text, k.textColor = W.Left(st.left), S.ok
    else
        k.text, k.textColor = st.cd > 0 and W.Left(st.cd) or "", S.text
    end
    if st.why == "ar" and view ~= "wide" then
        k.mark, k.markColor = tostring(math.ceil(st.ar)), S.soon
    elseif st.why == "snd" then
        k.mark, k.markColor = ns.T("widget.rogue_cs_snd_mark"), S.soon
    else
        k.mark, k.markColor = nil, nil
    end
    if (v == "ok" or v == "soon") and view ~= "wide" then
        k.corner, k.cornerColor = tostring(st.energy), high and S.soon or S.text
    else
        k.corner, k.cornerColor = nil, nil
    end
    ns.WTile.Paint(layer.tile, k)
    sweep(layer, st)
    if view ~= "wide" then return end
    local under = st.ar > 0
    W.Alpha(layer.af, under and 1 or 0)
    W.Alpha(layer.ef, under and 0 or 1)
    local a = layer.arLook
    a.icon = st.arIcon
    a.text, a.textColor = under and W.Left(st.ar) or "", S.soon
    a.edge = under and S.soon or nil
    ns.WTile.Paint(layer.arTile, a)
    W.Text(layer.sub, st.spell and tostring(st.energy) or "")
    W.Color(layer.sub, high and S.soon or S.text)
    local bar = layer.bar
    bar:SetTicks((st.cap and st.max > 0) and markOf(st.cap) or NO_MARKS)
    local c = high and d.barHigh or d.bar
    bar:SetColor(c[1], c[2], c[3], c[4])
    bar:Set(st.energy, st.max > 0 and st.max or 1)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local function tip(_, st)
    if not st.spell then return nil end
    local s = line(st)
    if s == "" then return nil end
    return st.spell, s
end
local DEMO = {
    solo  = { "ooc", "off", 100, 0 },
    party = { "ar", "soon", 40, 9 },
    raid  = { "ready", "ok", 30, 0 },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local d = data()
    local name, _, icon = GetSpellInfo(d.spree)
    local arIcon = select(3, GetSpellInfo(d.ar))
    return { spell = name, icon = icon, arIcon = arIcon, why = p[1], verdict = p[2], energy = p[3], max = 100,
        cap = capOf(scene.opt, 100), ar = p[4], snd = 12, cd = 0, cdStart = 0, cdDur = 0, left = 0, dur = d.dur,
        fight = p[2] ~= "off" }
end
local function capValues()
    local d = data()
    local max = UnitPowerMax("player", d.power) or 0
    local def = max > 0 and (max - d.spare) or d.capFallback
    local out = { { v = nil, text = tostring(def) } }
    for _, n in ipairs(d.caps) do
        if n ~= def then
            local at = #out + 1
            for i, x in ipairs(out) do
                if (x.v or def) > n then at = i break end
            end
            table.insert(out, at, { v = n, text = tostring(n) })
        end
    end
    out[#out + 1] = { v = "any", label = "widget.rogue_cs_cap_any" }
    return out
end
local WAIT = {
    { key = "ar", def = true, label = "widget.rogue_cs_wait_ar" },
    { key = "snd", def = true, label = "widget.rogue_cs_wait_snd" },
}
ns.Widget.Register(KEY, {
    info = { text = "widget.rogue_combat_spree_info", demo = demo },
    icon = 51690,
    label = "widget.rogue_combat_spree",
    class = "ROGUE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = avail,
    events = {
        UNIT_AURA = "player", UNIT_MAXENERGY = "player", SPELL_UPDATE_COOLDOWN = true, PLAYER_TARGET_CHANGED = true,
        PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not st.spell then return nil end
        if st.verdict == "act" or st.cd > 0 or st.ar > 0 or st.verdict == "ok" or st.verdict == "soon" then
            return data().tick
        end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    active = function(st, opt)
        if not st.spell then return false end
        if st.why == "ooc" or st.why == "notarget" then return not (opt and opt.ooc == "hide") end
        return true
    end,
    opts = {
        { key = "cap", label = "widget.rogue_cs_cap", values = capValues },
        { key = "wait", label = "widget.rogue_cs_wait", kind = "checks", checks = WAIT },
        { key = "ooc", label = "widget.rogue_cs_ooc", values = {
            { v = nil, label = "widget.rogue_cs_ooc_dim" }, { v = "hide", label = "widget.rogue_cs_ooc_hide" },
        } },
    },
})
ns.rogueCombatSpreeWidgetLoaded = true

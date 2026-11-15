local _, ns = ...
local KEY = "rogue_sub_dance"
local PAD = 3
local BAR_PART = 0.22
local function data()
    return ns.widgetData.rogue_sub_dance
end
local function avail()
    local _, class = UnitClass("player")
    return class == "ROGUE" and ns.IsLearned(data().dance)
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
local function myAura(id, now)
    for i = 1, data().auraMax do
        local n, _, _, _, _, dur, expires, _, _, _, sid = UnitAura("player", i, "HELPFUL")
        if not n then break end
        if sid == id then
            local left = (expires and expires > 0) and math.max(0.01, expires - now) or 0.01
            return left, dur or 0
        end
    end
    return 0, 0
end
local function state(opt)
    local d = data()
    local st = { cd = 0, left = 0, dur = 0, stealth = false, energy = 0, max = 0, amb = 0, premed = -1,
        thr = (opt and opt.save) or d.save, fight = UnitAffectingCombat("player") and true or false }
    if ns.IsLearned(d.dance) then
        local name, _, icon = GetSpellInfo(d.dance)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        watchEnergy(false)
        st.why, st.verdict = "none", "off"
        return st
    end
    local now = GetTime()
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.spell))
    st.left, st.dur = myAura(d.dance, now)
    if st.dur <= 0 then st.dur = d.dur end
    st.stealth = st.fight and IsStealthed() and true or false
    st.energy = UnitPower("player", d.power) or 0
    st.max = UnitPowerMax("player", d.power) or 0
    local _, _, _, cost = GetSpellInfo(d.ambush)
    if not cost or cost <= 0 then cost = d.ambushCost end
    st.amb = math.floor(st.energy / cost)
    if ns.IsLearned(d.premed) then st.premed = ns.WTile.Left(d.gcd, GetSpellCooldown(d.premed)) end
    if st.left > 0 then
        st.why, st.verdict = "win", "act"
    elseif st.stealth then
        st.why, st.verdict = "stealth", "act"
    elseif not st.fight then
        st.why, st.verdict = "ooc", "off"
    elseif st.cd > 0 then
        st.why, st.verdict = "cd", "cd"
    elseif st.energy < st.thr then
        st.why, st.verdict = "save", "soon"
    elseif st.premed > 0 and st.premed <= d.premedWait then
        st.why, st.verdict = "premed", "soon"
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
    if view ~= "wide" then return end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.sub:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.sub:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.sub:SetJustifyH("LEFT")
    local h = math.max(4, math.floor(s * BAR_PART + 0.5))
    layer.bar = ns.Gauge.New(layer, "bar", { w = layer.w - s - gap, h = h, max = 1, color = data().barWin, flash = false })
    layer.bar.fr:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
end
local marks = {}
local function markOf(thr)
    local m = marks[thr]
    if not m then
        m = { thr }
        marks[thr] = m
    end
    return m
end
local NO_MARKS = {}
local function line(st)
    local W = ns.Widget
    if st.why == "win" then return ns.T("widget.rogue_sd_amb", st.amb) end
    if st.why == "stealth" then return ns.T("widget.rogue_sd_stealth") end
    if st.why == "ready" then return ns.T("widget.rogue_sd_go") end
    if st.why == "save" then return ns.T("widget.rogue_sd_save", st.energy, st.thr) end
    if st.why == "premed" then return ns.T("widget.rogue_sd_premed", math.ceil(st.premed)) end
    if st.why == "cd" then return ns.T("widget.rogue_sd_cd", W.Left(st.cd)) end
    return ""
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "cd" or (v == "off" and st.cd > 0)
    k.alpha = v == "off" and d.dim or 1
    k.edge = ((v == "act" or v == "ok") and S.ok) or nil
    k.glow = v == "act" or v == "ok"
    if v == "act" then
        k.text, k.textColor = st.left > 0 and W.Left(st.left) or "", S.text
        k.corner = tostring(st.amb)
    elseif st.why == "save" then
        k.text, k.textColor, k.corner = tostring(st.energy), S.soon, nil
    elseif st.why == "premed" then
        k.text, k.textColor, k.corner = W.Left(st.premed), S.soon, nil
    else
        k.text, k.textColor, k.corner = st.cd > 0 and W.Left(st.cd) or "", S.text, nil
    end
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.sub, line(st))
    W.Color(layer.sub, (v == "act" or v == "ok") and S.ok or (v == "soon" and S.soon) or S.text)
    local bar = layer.bar
    if st.why == "win" then
        bar:SetTicks(NO_MARKS)
        local c = d.barWin
        bar:SetColor(c[1], c[2], c[3], c[4])
        bar:Set(st.left, st.dur)
    else
        bar:SetTicks(st.max > 0 and markOf(st.thr) or NO_MARKS)
        local c = (st.energy >= st.thr) and d.barWin or d.barSave
        bar:SetColor(c[1], c[2], c[3], c[4])
        bar:Set(st.energy, st.max > 0 and st.max or 1)
    end
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local function tip(_, st)
    if not st.spell then return nil end
    local why = st.why
    if why ~= "win" and why ~= "stealth" and why ~= "save" and why ~= "premed" then return nil end
    return st.spell, line(st)
end
local DEMO = {
    solo  = { "ooc", "off", 100, 0, 0 },
    party = { "save", "soon", 55, 0, 0 },
    raid  = { "win", "act", 85, 4, 56 },
}
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    local d = data()
    local name, _, icon = GetSpellInfo(d.dance)
    return { spell = name, icon = icon, why = p[1], verdict = p[2], energy = p[3], max = 100, left = p[4], dur = d.dur,
        cd = p[5], thr = (scene.opt and scene.opt.save) or d.save, amb = math.floor(p[3] / d.ambushCost), premed = 0,
        stealth = false, fight = p[2] ~= "off" }
end
local function saveValues()
    local d = data()
    local out = { { v = nil, text = tostring(d.save) } }
    for _, n in ipairs(d.saves) do
        local at = #out + 1
        for i, x in ipairs(out) do
            if (x.v or d.save) > n then at = i break end
        end
        table.insert(out, at, { v = n, text = tostring(n) })
    end
    return out
end
ns.Widget.Register(KEY, {
    info = { text = "widget.rogue_sub_dance_info", demo = demo },
    icon = 51713,
    label = "widget.rogue_sub_dance",
    class = "ROGUE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:51713" },
    avail = avail,
    events = {
        UNIT_AURA = "player", UPDATE_STEALTH = true, SPELL_UPDATE_COOLDOWN = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not st.spell then return nil end
        if st.verdict == "act" or st.cd > 0 or (st.fight and st.premed > 0) then return data().tick end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    active = function(st, opt)
        if not st.spell then return false end
        return st.fight or not (opt and opt.ooc == "hide")
    end,
    opts = {
        { key = "save", label = "widget.rogue_sd_save_opt", values = saveValues },
        { key = "ooc", label = "widget.rogue_sd_ooc", values = {
            { v = nil, label = "widget.rogue_sd_ooc_dim" }, { v = "hide", label = "widget.rogue_sd_ooc_hide" },
        } },
    },
})
ns.rogueSubDanceWidgetLoaded = true

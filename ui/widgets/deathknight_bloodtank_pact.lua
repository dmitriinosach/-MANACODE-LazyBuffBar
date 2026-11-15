local _, ns = ...
local NAME = "dk_pact"
local function data()
    return ns.widgetData.dk_pact
end
local function avail()
    if ns.PlayerClass() ~= "DEATHKNIGHT" then return false end
    return ns.IsLearned(data().pact) and true or false
end
local function master()
    local id = data().master
    return ns.IsTalent(id) and ns.IsLearned(id) and true or false
end
local function inFight()
    return (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
end
local function kilo(x)
    if x < 1000 then return tostring(math.floor(x + 0.5)) end
    local k = x / 1000
    if k >= 10 then return ns.T("widget.pa_k", tostring(math.floor(k + 0.5))) end
    local s = (string.format("%.1f", math.floor(k * 10 + 0.5) / 10):gsub("%.", ns.T("widget.h_dec")))
    return ns.T("widget.pa_k", s)
end
local function secs(sec)
    return tostring(math.ceil(sec - 0.001))
end
local function judge(st)
    if st.dead then
        st.why, st.verdict = "dead", "off"
    elseif st.pactCd > 0 or (not st.ghoul and st.raiseCd > 0) then
        st.why, st.verdict = "cd", "none"
        st.wait = math.max(st.pactCd, st.ghoul and 0 or st.raiseCd)
    elseif not st.ghoul and st.nodust then
        st.why, st.verdict = "dust", "bad"
    elseif st.rp < st.cost then
        st.why, st.verdict = "rp", "off"
    elseif not st.ghoul then
        st.why, st.verdict = "two", "soon"
    else
        st.why, st.verdict = "go", "ok"
    end
end
local function glowAt(opt)
    local g = opt and opt.glow
    if g == "off" then return nil end
    return tonumber(g) or data().glow
end
local function number(st, opt)
    local m = opt and opt.num
    if m == "none" then return "" end
    if m == "pct" then return math.floor(st.pct + 0.5) .. "%" end
    return kilo(st.heal)
end
local function finish(st, opt, max)
    local d = data()
    local mul = st.vamp and d.vampMul or 1
    st.heal = max * d.per * mul
    st.pct = d.per * 100 * mul
    judge(st)
    local at = glowAt(opt)
    st.glow = (st.verdict == "ok" and at and st.hp < at) and true or false
    st.label = number(st, opt)
end
local function costOf(d)
    local c = tonumber((select(4, GetSpellInfo(d.pact))))
    if not c or c <= 0 then return d.cost end
    if c > 150 then c = c / 10 end
    return math.floor(c + 0.5)
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { fight = inFight(), dead = UnitIsDeadOrGhost("player") and true or false, hp = 100, heal = 0, pct = 0,
                 vamp = false, rp = UnitPower("player", 6) or 0, cost = d.cost, pactCd = 0, raiseCd = 0, ghoul = false,
                 pet = false, left = 0, dust = 0, nodust = false, wait = 0, glow = false, label = "" }
    if avail() then
        local name, _, icon = GetSpellInfo(d.pact)
        local rname, _, ricon = GetSpellInfo(d.raise)
        st.spell, st.icon, st.raise, st.raiseIcon = name, icon, rname, ricon
    end
    if not (st.spell and st.raise) then
        st.spell, st.why, st.verdict = nil, "dead", "off"
        return st
    end
    st.cost = costOf(d)
    local ps, pd = GetSpellCooldown(st.spell)
    local rs, rd = GetSpellCooldown(st.raise)
    st.pactCd = ns.WTile.Left(d.gcd, ps, pd)
    st.raiseCd = ns.WTile.Left(d.gcd, rs, rd)
    if UnitExists("pet") then
        st.pet = not UnitIsDeadOrGhost("pet")
        st.ghoul = st.pet
    elseif not master() and rs and rd and rs > 0 and rd > d.gcd and now < rs + d.life then
        local eaten = ps and pd and ps > 0 and pd > d.gcd and ps >= rs
        if not eaten then
            st.ghoul = true
            st.left = rs + d.life - now
        end
    end
    st.dust = GetItemCount(d.dust) or 0
    if not st.ghoul and st.raiseCd <= 0 then
        local usable, nomana = IsUsableSpell(st.raise)
        st.nodust = (not usable and not nomana and st.dust == 0) and true or false
    end
    local vname = GetSpellInfo(d.vamp)
    st.vamp = (vname and UnitAura("player", vname, nil, "HELPFUL")) and true or false
    local max = UnitHealthMax("player") or 0
    local cur = UnitHealth("player") or 0
    st.hp = max > 0 and (cur * 100 / max) or 100
    finish(st, opt, max)
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
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 3)
    layer.num = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(layer.num, s * 0.32)
    layer.num:SetPoint("BOTTOM", layer.tile.edge, "BOTTOM", 0, 2)
    if view ~= "pair" then return end
    layer.ghoul = ns.WTile.New(layer, s + (layer.gap or 2), 0, s)
    layer.ghoulLook = {}
end
local EDGE = { ok = ns.STATE.ok, soon = ns.STATE.soon, bad = ns.STATE.bad }
local function paintGhoul(layer, st)
    local S = ns.STATE
    local W = ns.Widget
    local k = layer.ghoulLook
    local cd = not st.ghoul and st.raiseCd > 0
    k.icon = st.raiseIcon
    k.grey = cd
    k.alpha = cd and data().dim or 1
    k.edge = (st.ghoul and S.ok) or (st.why == "dust" and S.bad) or nil
    k.text = (st.left > 0 and secs(st.left)) or (cd and W.Left(st.raiseCd)) or ""
    k.textColor = S.text
    k.corner = st.why == "dust" and "0" or nil
    k.cornerColor = S.bad
    ns.WTile.Paint(layer.ghoul, k)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v, why = st.verdict, st.why
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "none"
    k.alpha = v == "none" and data().dim or 1
    k.tint = why == "rp" and data().tint or nil
    k.edge = EDGE[v]
    k.text = (why == "cd" and W.Left(st.wait)) or (why == "rp" and (math.floor(st.rp) .. "/" .. st.cost))
        or (why == "two" and "2") or ""
    k.textColor = v == "soon" and S.soon or S.text
    if why == "dust" then
        k.corner, k.cornerColor = "0", S.bad
    else
        k.corner, k.cornerColor = (view ~= "pair" and st.left > 0) and secs(st.left) or nil, S.text
    end
    k.glow = st.glow
    ns.WTile.Paint(layer.tile, k)
    W.Text(layer.num, v == "ok" and st.label or "")
    if view == "pair" then paintGhoul(layer, st) end
end
local function macro(st)
    if not (st.spell and st.raise) then return {} end
    return { type = "macro", macrotext = "/cast [nopet] " .. st.raise .. "\n/cast " .. st.spell }
end
local CELLS = {
    one = { { l = 0, t = 0, r = 1, b = 1, attrs = macro } },
    pair = {
        { cx = 0, cy = 0, attrs = macro },
        { cx = 1, cy = 0, attrs = function(st)
            if not st.raise then return {} end
            return { type = "spell", spell = st.raise }
        end },
    },
}
local function tip(_, st)
    if not st.spell or st.why == "dead" then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local rows = {
        { l = ns.T("widget.pa_heal"), r = ns.T("widget.pa_about", kilo(st.heal), math.floor(st.pct + 0.5)) },
    }
    local vname = GetSpellInfo(d.vamp)
    if vname and st.vamp then rows[#rows + 1] = { l = vname, r = ns.T("widget.pa_plus", math.floor((d.vampMul - 1) * 100 + 0.5)) } end
    local g
    if st.left > 0 then g = ns.T("widget.pa_ghoul_left", W.Left(st.left))
    elseif st.ghoul then g = ns.T("widget.pa_yes") else g = ns.T("widget.pa_no") end
    rows[#rows + 1] = { l = ns.T("widget.pa_ghoul"), r = g, rc = st.ghoul and S.ok or S.soon }
    rows[#rows + 1] = { l = st.raise, r = st.raiseCd > 0 and W.Left(st.raiseCd) or ns.T("widget.pa_ready"),
        rc = st.raiseCd > 0 and S.mute or nil }
    if st.nodust then
        rows[#rows + 1] = { l = GetItemInfo(d.dust) or ns.T("widget.pa_dust"), r = tostring(st.dust), rc = S.bad }
    end
    rows[#rows + 1] = { l = ns.T("widget.pa_rp"), r = ns.T("widget.pa_of", math.floor(st.rp), st.cost),
        rc = st.rp < st.cost and S.mute or nil }
    rows[#rows + 1] = { l = st.spell, r = st.pactCd > 0 and W.Left(st.pactCd) or ns.T("widget.pa_ready"),
        rc = st.pactCd > 0 and S.mute or nil }
    rows[#rows + 1] = { l = ns.T("widget.pa_click"), lc = S.mute }
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { 35, 34, 0, 146, 60 },
    party = { 60, false, 0, 0, 70 },
    raid  = { 80, false, 47, 0, 90 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.pact)
    local rname, _, ricon = GetSpellInfo(d.raise)
    local st = { spell = name, icon = icon, raise = rname, raiseIcon = ricon, fight = true, dead = false, hp = p[1],
                 vamp = false, rp = p[5], cost = d.cost, pactCd = p[3], raiseCd = p[4], ghoul = p[2] and true or false,
                 pet = false, left = p[2] or 0, dust = 5, nodust = false, wait = 0, glow = false, label = "" }
    finish(st, scene.opt, 30000)
    return st
end
local function glowValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.glows) do
        out[#out + 1] = { v = (n ~= d.glow) and n or nil, text = ns.T("widget.pa_pct", n) }
    end
    out[#out + 1] = { v = "off", label = "widget.pa_none" }
    return out
end
local READY = { ok = true, soon = true }
ns.Widget.Register(NAME, {
    info = { text = "widget.dk_pact_info", demo = demo },
    icon = 48743,
    label = "widget.dk_pact",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "one",
    covers = { "spell:48743", "spell:46584" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true, UNIT_PET = "player",
        UNIT_HEALTH = { player = true, pet = true }, UNIT_MAXHEALTH = "player", UNIT_RUNIC_POWER = "player",
        UNIT_AURA = "player", UNIT_SPELLCAST_SUCCEEDED = "player", BAG_UPDATE = true, PLAYER_REGEN_ENABLED = true,
        PLAYER_REGEN_DISABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true, PLAYER_DEAD = true, PLAYER_ALIVE = true,
        PLAYER_UNGHOST = true,
    },
    tick = function(st)
        if not st.spell then return nil end
        return (st.pactCd > 0 or st.raiseCd > 0 or st.left > 0) and data().tick or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function(view) return CELLS[view] or CELLS.one end,
    active = function(st, opt)
        if not st.spell or st.why == "dead" then return false end
        local m = opt and opt.show
        if m == "always" then return true end
        if m == "ready" then return READY[st.verdict] == true end
        return st.fight
    end,
    Tip = tip,
    opts = {
        { key = "num", label = "widget.pa_num", values = {
            { v = nil, label = "widget.pa_num_k" }, { v = "pct", label = "widget.pa_num_pct" }, { v = "none", label = "widget.pa_none" },
        } },
        { key = "glow", label = "widget.pa_glow", values = glowValues },
        { key = "show", label = "widget.pa_show", values = {
            { v = "always", label = "widget.pa_show_always" }, { v = nil, label = "widget.pa_show_fight" },
            { v = "ready", label = "widget.pa_show_ready" },
        } },
    },
})
ns.dkPactWidgetLoaded = true

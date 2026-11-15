local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local function data()
    return ns.widgetData.dk_strike
end
local NAMES = {}
local LEFT = {}
local KIND = {}
local function names()
    if NAMES[1] then return NAMES end
    local list = {}
    for i, id in ipairs(data().diseases) do
        list[i] = GetSpellInfo(id)
        if not list[i] then return nil end
    end
    for i, n in ipairs(list) do NAMES[i] = n end
    return NAMES
end
local rank
local talents = CreateFrame("Frame")
talents:RegisterEvent("PLAYER_TALENT_UPDATE")
talents:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
talents:RegisterEvent("CHARACTER_POINTS_CHANGED")
talents:SetScript("OnEvent", function() rank = nil end)
local function talentRank()
    if rank then return rank end
    local d = data()
    local name = GetSpellInfo(d.talent)
    local group = ns.ActiveSlot and ns.ActiveSlot() or nil
    rank = 0
    for i = 1, (name and GetNumTalents and GetNumTalents(d.tab)) or 0 do
        local n, _, _, _, r = GetTalentInfo(d.tab, i, false, false, group)
        if n == name then
            rank = tonumber(r) or 0
            break
        end
    end
    return rank
end
local function avail()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT" and ns.IsLearned(data().id)
end
local function pairWait(now)
    local d = data()
    for slot = 1, 6 do
        local start, dur, ready = GetRuneCooldown(slot)
        KIND[slot] = GetRuneType(slot)
        local l = 0
        if not ready and start and dur and start > 0 then l = start + dur - now end
        LEFT[slot] = l > 0 and l or 0
    end
    local best
    for i = 1, 6 do
        if d.frost[KIND[i] or 0] then
            for j = 1, 6 do
                if j ~= i and d.unholy[KIND[j] or 0] then
                    local w = math.max(LEFT[i], LEFT[j])
                    if not best or w < best then best = w end
                end
            end
        end
    end
    return best
end
local function onTarget(list, now)
    local out = {}
    local R = ns.Raid
    local e = R and R.Enemy("target")
    local guid = UnitGUID("target")
    for i, n in ipairs(list) do
        if e and e.guid == guid then
            local v = e.own[n]
            out[i] = (v and (v == 0 or v > now)) and true or false
        else
            out[i] = UnitDebuff("target", n, nil, "PLAYER") ~= nil
        end
    end
    return out
end
local function kilo(x)
    if x < 1000 then return tostring(math.floor(x + 0.5)) end
    local k = x / 1000
    local s = k < 10 and string.format("%.1f", math.floor(k * 10 + 0.5) / 10):gsub("%.", ns.T("widget.h_dec"))
        or tostring(math.floor(k + 0.5))
    return ns.T("widget.ds_k", s)
end
local function healOf(d, max, n, r, vamp)
    local h = max * d.per * n * (1 + d.talentPer * r)
    if vamp then h = h * d.vampMul end
    return h
end
local function verdictOf(st)
    if not st.target then return "off" end
    if st.wait > 0 then return "none" end
    if st.n == 0 then return "bad" end
    if st.deficit < st.heal then return "text" end
    if st.n == 1 then return "soon" end
    return "ok"
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
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { target = false, n = 0, of = d.third, dots = {}, heal = 0, pct = 0, hp = 100, deficit = 0, wait = 0,
                 rank = 0, vamp = false, glow = false, fight = UnitAffectingCombat("player") and true or false }
    if avail() then
        local name, _, icon = GetSpellInfo(d.id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.verdict = "off"
        return st
    end
    local max = UnitHealthMax("player") or 0
    local cur = UnitHealth("player") or 0
    st.hp = max > 0 and (cur * 100 / max) or 100
    st.deficit = math.max(0, max - cur)
    st.rank = talentRank()
    local vname = GetSpellInfo(d.vamp)
    st.vamp = (vname and UnitAura("player", vname, nil, "HELPFUL")) and true or false
    st.wait = pairWait(now) or 0
    st.target = (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")) and true or false
    local list = names()
    if st.target and list then
        local R = ns.Raid
        if R then
            R.WatchEnemy("dk_strike", list, true)
            R.Touch()
        end
        local on = onTarget(list, now)
        st.dots[1], st.dots[2] = on[1], on[2]
        st.dots[3] = (on[3] or on[4]) and true or false
        for i = 1, 3 do
            if st.dots[i] then st.n = st.n + 1 end
        end
        if st.dots[3] then st.of = d.third + 1 end
    end
    st.heal = healOf(d, max, st.n, st.rank, st.vamp)
    st.pct = max > 0 and (st.heal * 100 / max) or 0
    st.verdict = verdictOf(st)
    local at = glowAt(opt)
    st.glow = (st.verdict == "ok" and at and st.hp < at) and true or false
    st.label = number(st, opt)
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s = layer.h
    local S = ns.STATE
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    top:SetFrameLevel(layer:GetFrameLevel() + 3)
    layer.dots = ns.Gauge.New(top, "pips", { w = s - 8, h = math.max(3, math.floor(s * 0.14)), max = 3, color = S.ok,
        off = S.off, gap = 2, flash = false })
    layer.dots:Frame():SetPoint("TOP", layer.tile.edge, "TOP", 0, -3)
    layer.num = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(layer.num, s * 0.32)
    if view ~= "wide" then
        layer.num:SetPoint("BOTTOM", layer.tile.edge, "BOTTOM", 0, 2)
        return
    end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.num:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    local bw = math.max(8, layer.w - s - gap - 2 * PAD)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw, h = math.max(4, math.floor(s * 0.3)), max = 100, color = S.ok,
        flash = false })
    layer.bar:Frame():SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
end
local EDGE = { ok = ns.STATE.ok, soon = ns.STATE.soon, bad = ns.STATE.bad }
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "none" or v == "off"
    k.alpha = v == "off" and data().dim or 1
    k.edge = EDGE[v]
    k.text = v == "none" and W.Left(math.max(1, st.wait)) or ""
    k.textColor = S.text
    k.glow = st.glow
    ns.WTile.Paint(layer.tile, k)
    layer.dots:Set(st.n, st.of)
    W.Alpha(layer.dots:Frame(), st.target and 1 or 0)
    W.Text(layer.num, (v == "off" or v == "none") and "" or st.label)
    W.Color(layer.num, (v == "soon" and S.soon) or (v == "bad" and S.bad) or S.text)
    if view ~= "wide" then return end
    layer.bar:Set(math.floor(st.hp + 0.5))
    if st.target and st.heal > 0 then
        layer.bar:SetTicks({ math.min(100, math.floor(st.hp + st.pct + 0.5)) })
    else
        layer.bar:SetTicks(nil)
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
    if not st.target then return st.spell, ns.T("widget.ds_notarget") end
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local rows = {
        { l = ns.T("widget.ds_heal"), r = ns.T("widget.ds_about", kilo(st.heal), math.floor(st.pct + 0.5)) },
        { l = ns.T("widget.ds_dis"), r = ns.T("widget.ds_of", st.n, st.of), rc = (st.n == 0 and S.bad) or (st.n == 1 and S.soon) or nil },
    }
    local tname = GetSpellInfo(d.talent)
    if tname and st.rank > 0 then
        rows[#rows + 1] = { l = tname, r = "+" .. math.floor(st.rank * d.talentPer * 100 + 0.5) .. "%" }
    end
    local vname = GetSpellInfo(d.vamp)
    if vname and st.vamp then
        rows[#rows + 1] = { l = vname, r = "+" .. math.floor((d.vampMul - 1) * 100 + 0.5) .. "%" }
    end
    rows[#rows + 1] = { l = ns.T("widget.ds_runes"),
        r = st.wait > 0 and ns.T("widget.ds_in", W.Left(math.max(1, st.wait))) or ns.T("widget.ds_ready"),
        rc = st.wait > 0 and S.mute or nil }
    rows[#rows + 1] = { l = ns.T("widget.ds_lack"), r = kilo(st.deficit) }
    rows[#rows + 1] = { l = ns.T("widget.ds_note"), lc = S.mute }
    return st.spell, nil, rows
end
local DEMO = { solo = { 2, false, 40, 0 }, party = { 1, false, 70, 0 }, raid = { 3, true, 55, 3 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.id)
    local max = 30000
    local st = { spell = name, icon = icon, target = true, n = p[1], of = d.third + (p[2] and 1 or 0),
                 dots = { p[1] >= 1, p[1] >= 2, p[2] }, hp = p[3], deficit = max * (100 - p[3]) / 100, wait = p[4],
                 rank = 2, vamp = false, fight = true }
    st.heal = healOf(d, max, st.n, st.rank, st.vamp)
    st.pct = st.heal * 100 / max
    st.verdict = verdictOf(st)
    local at = glowAt(scene.opt)
    st.glow = (st.verdict == "ok" and at and st.hp < at) and true or false
    st.label = number(st, scene.opt)
    return st
end
local function glowValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.glows) do
        out[#out + 1] = { v = (n ~= d.glow) and n or nil, text = ns.T("widget.ds_pct", n) }
    end
    out[#out + 1] = { v = "off", label = "widget.ds_none" }
    return out
end
ns.Widget.Register("dk_strike", {
    info = { text = "widget.dk_strike_info", demo = demo },
    icon = 49924,
    label = "widget.dk_strike",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:49924" },
    avail = avail,
    events = {
        RUNE_POWER_UPDATE = true, RUNE_TYPE_UPDATE = true, UNIT_HEALTH = "player", UNIT_MAXHEALTH = "player",
        UNIT_AURA = "player", PLAYER_TARGET_CHANGED = true, PLAYER_TALENT_UPDATE = true, SPELLS_CHANGED = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if not st.spell then return nil end
        if st.wait > 0 then return data().tick end
        return (st.target and st.n > 0) and data().keep or nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    active = function(st, opt) return not (opt and opt.show == "fight" and not st.fight) end,
    Tip = tip,
    opts = {
        { key = "num", label = "widget.ds_num", values = {
            { v = nil, label = "widget.ds_num_k" }, { v = "pct", label = "widget.ds_num_pct" }, { v = "none", label = "widget.ds_none" },
        } },
        { key = "glow", label = "widget.ds_glow", values = glowValues },
        { key = "show", label = "widget.dk_show", values = {
            { v = nil, label = "widget.dk_show_always" }, { v = "fight", label = "widget.dk_show_fight" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("dk_strike") end)
end
ns.dkStrikeWidgetLoaded = true

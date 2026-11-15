local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local function data()
    return ns.widgetData.dk_summon
end
local function pick()
    for _, s in ipairs(data().spells) do
        if ns.IsLearned(s.id) then return s end
    end
    return nil
end
local function avail()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT" and pick() ~= nil
end
local function verdictOf(st)
    if st.left > 0 then return "full" end
    if st.cd > 0 then return "none" end
    if st.rp < st.cost then return "off" end
    if st.heroNeed and not st.hero then return "soon" end
    if st.n >= st.need then return "ok" end
    return "soon"
end
local function needOf(opt)
    local v = opt and opt.need
    if v == nil then return data().need end
    return tonumber(v) or data().need
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { cd = 0, left = 0, rp = UnitPower("player", 6) or 0, cost = d.cost, buffs = {}, n = 0, need = needOf(opt),
                 hero = false, heroNeed = (opt and opt.hero == "yes") and true or false }
    local s = avail() and pick() or nil
    if s then
        local name, _, icon = GetSpellInfo(s.id)
        st.spell, st.icon = name, icon
    end
    if not st.spell then
        st.verdict = "off"
        return st
    end
    local start, dur = GetSpellCooldown(st.spell)
    if start and dur and start > 0 and dur > d.gcd then
        if start + s.last > now then
            st.left = start + s.last - now
        else
            st.cd = math.max(0, start + dur - now)
        end
    end
    for _, id in ipairs(d.buffs) do
        local n = GetSpellInfo(id)
        local got, exp
        if n then
            local a, _, _, _, _, _, e = UnitAura("player", n, nil, "HELPFUL")
            got, exp = a, e
        end
        if got then
            st.buffs[#st.buffs + 1] = { name = n, left = (exp and exp > now) and (exp - now) or 0 }
            if id == d.hero[1] or id == d.hero[2] then st.hero = true end
        end
    end
    for _, slot in ipairs(d.slots) do
        local c = ns.Trinket and ns.Trinket.Cell(slot)
        if c and c.s == "act" then
            local n = c.item and GetItemInfo(c.item) or ("#" .. slot)
            st.buffs[#st.buffs + 1] = { name = n, left = c.left or 0 }
        end
    end
    st.n = #st.buffs
    st.verdict = verdictOf(st)
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
    local lamp = math.max(4, math.floor(s * 0.22))
    layer.lamps, layer.texts = {}, {}
    for i = 1, 2 do
        local y = (i == 1) and -PAD or -(s - PAD - lamp)
        local t = layer:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        t:SetWidth(lamp)
        t:SetHeight(lamp)
        t:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, y)
        layer.lamps[i] = t
        local fs = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        fs:SetPoint("LEFT", t, "RIGHT", 2, 0)
        fs:SetJustifyH("LEFT")
        layer.texts[i] = fs
    end
end
local EDGE = { ok = ns.STATE.ok, soon = ns.STATE.soon, full = ns.STATE.full }
local function countText(st)
    if st.need <= 0 then return tostring(st.n) end
    return st.n .. "/" .. st.need
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "none"
    k.alpha = v == "none" and d.dim or 1
    k.tint = v == "off" and d.tint or nil
    k.edge = EDGE[v]
    if v == "full" then
        k.text, k.textColor = W.Left(st.left), S.full
    elseif v == "none" then
        k.text, k.textColor = W.Left(st.cd), S.text
    elseif v == "off" then
        k.text, k.textColor = (view == "wide") and "" or (st.rp .. "/" .. st.cost), S.text
    elseif v == "soon" then
        k.text, k.textColor = (view == "wide") and "" or countText(st), S.soon
    else
        k.text, k.textColor = "", S.text
    end
    k.glow = v == "ok"
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    local rpOk = st.rp >= st.cost
    W.Color(layer.lamps[1], rpOk and S.ok or S.off)
    W.Text(layer.texts[1], st.rp .. "/" .. st.cost)
    W.Color(layer.texts[1], rpOk and S.text or S.mute)
    local enough = st.n >= st.need and not (st.heroNeed and not st.hero)
    W.Color(layer.lamps[2], enough and S.ok or S.soon)
    W.Text(layer.texts[2], ns.T("widget.sm_buffs", countText(st)))
    W.Color(layer.texts[2], enough and S.text or S.soon)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local function tip(_, st)
    if not st.spell then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    if st.left > 0 then
        rows[#rows + 1] = { l = ns.T("widget.sm_active"), r = W.Left(st.left), rc = S.full }
    end
    for _, b in ipairs(st.buffs) do
        rows[#rows + 1] = { l = b.name, r = b.left > 0 and W.Left(b.left) or "" }
    end
    if #st.buffs == 0 then rows[#rows + 1] = { l = ns.T("widget.sm_nobuff"), lc = S.mute } end
    if st.heroNeed and not st.hero then rows[#rows + 1] = { l = ns.T("widget.sm_nohero"), lc = S.soon } end
    rows[#rows + 1] = { l = ns.T("widget.sm_rp"), r = ns.T("widget.sm_of", st.rp, st.cost),
        rc = st.rp >= st.cost and S.text or S.mute }
    return st.spell, nil, rows
end
local DEMO = {
    solo  = { 42, {}, 0, 0 },
    party = { 80, { 53365 }, 0, 0 },
    raid  = { 70, { 2825, 53365 }, 0, 22 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local id = scene.class == "DEATHKNIGHT" and (pick() or d.spells[1]).id or d.spells[1].id
    local name, _, icon = GetSpellInfo(id)
    local st = { spell = name, icon = icon, cd = p[3], left = p[4], rp = p[1], cost = d.cost, buffs = {}, need = needOf(scene.opt),
                 hero = false, heroNeed = (scene.opt and scene.opt.hero == "yes") and true or false }
    for _, b in ipairs(p[2]) do
        st.buffs[#st.buffs + 1] = { name = GetSpellInfo(b) or ("#" .. b), left = 15 }
        if b == d.hero[1] then st.hero = true end
    end
    st.n = #st.buffs
    st.verdict = verdictOf(st)
    return st
end
local function needValues()
    local d = data()
    local out = {}
    for _, n in ipairs(d.needs) do
        local v = (n ~= d.need) and n or nil
        if n == 0 then
            out[#out + 1] = { v = v, label = "widget.sm_need_any" }
        else
            out[#out + 1] = { v = v, text = tostring(n) }
        end
    end
    return out
end
ns.Widget.Register("dk_summon", {
    info = { text = "widget.dk_summon_info", demo = demo },
    icon = 49206,
    label = "widget.dk_summon",
    class = "DEATHKNIGHT",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:49206", "spell:49028" },
    avail = avail,
    events = {
        SPELL_UPDATE_COOLDOWN = true, UNIT_RUNIC_POWER = "player", UNIT_AURA = "player", UNIT_SPELLCAST_SUCCEEDED = "player",
        UNIT_INVENTORY_CHANGED = "player", SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.cd > 0 or st.left > 0) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    active = function(st, opt) return not (opt and opt.show == "ready" and st.verdict == "none") end,
    Tip = tip,
    opts = {
        { key = "need", label = "widget.sm_need", values = needValues },
        { key = "hero", label = "widget.sm_hero", values = {
            { v = nil, label = "widget.sm_no" }, { v = "yes", label = "widget.sm_yes" },
        } },
        { key = "show", label = "widget.dk_show", values = {
            { v = nil, label = "widget.dk_show_always" }, { v = "ready", label = "widget.sm_show_ready" },
        } },
    },
})
ns.dkSummonWidgetLoaded = true

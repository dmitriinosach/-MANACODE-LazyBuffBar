local _, ns = ...
local NAME = "war_shatter"
local PAD = 3
local function data()
    return ns.widgetData.war_shatter
end
local cache
local function nameList(ids)
    local out = {}
    for _, id in ipairs(ids) do
        local n = GetSpellInfo(id)
        if n then out[#out + 1] = n end
    end
    return out
end
local function names()
    if cache then return cache end
    local d = data()
    local name, _, icon = GetSpellInfo(d.shatter)
    local stance = GetSpellInfo(d.stance)
    if not (name and stance) then return nil end
    cache = { shatter = name, icon = icon, stance = stance, hero = nameList(d.hero), sated = nameList(d.sated), watch = { name } }
    return cache
end
local function avail()
    if ns.PlayerClass() ~= "WARRIOR" then return false end
    return ns.IsLearned(data().shatter)
end
local function onMe(list, fn)
    for _, n in ipairs(list) do
        if fn("player", n) then return true end
    end
    return false
end
local function isBoss(unit)
    return UnitClassification(unit) == "worldboss" or UnitLevel(unit) == -1
end
local function on(v, now)
    return (v and (v == 0 or v > now)) and true or false
end
local function hung(name)
    local e = ns.Raid and ns.Raid.Enemy("target")
    if e and not e.dirty and e.guid == UnitGUID("target") then return e.harm[name] or false, e.own[name] or false end
    local a, _, _, _, _, _, ea = UnitDebuff("target", name)
    local o, _, _, _, _, _, eo = UnitDebuff("target", name, nil, "PLAYER")
    return a and (ea or 0) or false, o and (eo or 0) or false
end
local VERDICT = { idle = "off", mine = "ok", other = "off", cd = "off", stance = "off", small = "ok", wait = "ok", go = "full" }
local function state(opt)
    local d = data()
    local n = names()
    local st = { why = "idle", verdict = "off", left = 0, cd = 0, stance = false, hero = false, sated = false,
        open = false, ready = false, boss = false, go = false }
    if not n then return st end
    st.spell, st.icon = n.shatter, n.icon
    local idx = ns.Kick and ns.Kick.FormIndex(d.stance)
    st.stance = idx ~= nil and GetShapeshiftForm() == idx
    st.cd = ns.WTile.Left(d.gcd, GetSpellCooldown(n.shatter))
    st.hero = onMe(n.hero, UnitBuff)
    st.sated = (not st.hero) and onMe(n.sated, UnitDebuff)
    st.ready = (opt and opt.when == "ready") and true or false
    st.open = st.ready or st.hero or st.sated
    if not (UnitExists("target") and UnitCanAttack("player", "target")) or UnitIsDeadOrGhost("target") then return st end
    local R = ns.Raid
    if R then
        R.WatchEnemy(NAME, n.watch, false)
        R.WatchEnemy(NAME .. ".own", n.watch, true)
        R.Touch()
    end
    st.boss = isBoss("target")
    local fit = st.boss or (opt and opt.foe == "any") or false
    local now = GetTime()
    local any, own = hung(n.shatter)
    local mine = on(own, now)
    if mine or on(any, now) then
        local v = mine and own or any
        st.left = v > 0 and (v - now) or 0
        st.why = mine and "mine" or "other"
        if not mine then
            local caster = select(8, UnitDebuff("target", n.shatter))
            if caster then
                st.who = UnitName(caster)
                st.whoClass = select(2, UnitClass(caster))
            end
        end
    elseif st.cd > 0 then
        st.why = "cd"
    elseif not st.stance then
        st.why = "stance"
        st.go = st.open and fit
    elseif not fit then
        st.why = "small"
    elseif not st.open then
        st.why = "wait"
    else
        st.why = "go"
        st.go = true
    end
    st.verdict = VERDICT[st.why]
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    layer.flashed = false
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", PAD, -PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -PAD, -PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", PAD, PAD)
    layer.sub:SetJustifyH("LEFT")
end
local function clock(sec)
    if sec < 60 then return ns.Widget.Left(sec) end
    local m = math.floor(sec / 60)
    return string.format("%d:%02d", m, math.floor(sec - m * 60))
end
local WORD = { go = "widget.wsh_go", wait = "widget.wsh_wait_short", stance = "widget.wsh_stance_short", small = "widget.wsh_small_short" }
local function word(st)
    if st.why == "mine" then return ns.T("widget.wsh_mine") end
    if st.why == "other" then return st.who or "" end
    local k = WORD[st.why]
    return k and ns.T(k) or ""
end
local function wordColor(st)
    local S = ns.STATE
    if st.why == "mine" then return S.ok end
    if st.why == "go" then return S.full end
    if st.why == "other" then return ns.WTile.ClassColor(st.whoClass) end
    return S.mute
end
local function flash(layer, go)
    if go and not layer.flashed and ns.FX and ns.FX.Level() ~= "off" then
        local s = layer.h
        ns.FX.Shine(layer, s / 2, s / 2, s)
    end
    layer.flashed = go
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local why = st.why
    local k = layer.look
    k.icon = st.icon
    k.grey = why == "cd" or why == "stance"
    k.alpha = (why == "other" or why == "idle") and data().dim or 1
    k.edge = (why == "mine" and S.ok) or (st.go and S.full) or nil
    local timed = why == "mine" or why == "other"
    local num = (timed and W.Left(st.left)) or (why == "cd" and W.Left(st.cd)) or ""
    k.text = view ~= "wide" and num or ""
    k.textColor = (why == "cd" or why == "other") and S.mute or S.text
    ns.WTile.Paint(layer.tile, k)
    flash(layer, why == "go")
    if view ~= "wide" then return end
    W.Text(layer.who, word(st))
    W.Color(layer.who, wordColor(st))
    W.Text(layer.sub, (timed and W.Left(st.left)) or (why == "cd" and clock(st.cd)) or "")
    W.Color(layer.sub, why == "mine" and S.text or S.mute)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function()
        local n = names()
        if not n then return {} end
        local idx = ns.Kick and ns.Kick.FormIndex(data().stance)
        if not idx then return { type = "spell", spell = n.shatter } end
        return { type = "macro", macrotext = string.format("/cast [stance:%d] %s; %s", idx, n.shatter, n.stance) }
    end },
}
local function tip(_, st)
    if st.why == "idle" then return nil end
    local S = ns.STATE
    local why = st.why
    local rows = {}
    if why == "other" then
        rows[#rows + 1] = { l = st.who and ns.T("widget.wsh_by", st.who) or ns.T("widget.wsh_other"), lc = ns.WTile.ClassColor(st.whoClass) }
    end
    if why == "stance" then rows[#rows + 1] = { l = ns.T("widget.wsh_stance"), lc = S.mute } end
    if why == "small" then rows[#rows + 1] = { l = ns.T("widget.wsh_small"), lc = S.mute } end
    local ready = why == "go" or why == "wait" or why == "stance" or why == "small"
    if ready and not st.ready then
        if st.sated then
            rows[#rows + 1] = { l = ns.T("widget.wsh_gone") }
        elseif not st.hero then
            rows[#rows + 1] = { l = ns.T("widget.wsh_wait"), lc = S.mute }
        end
    end
    if ready then rows[#rows + 1] = { l = ns.T("widget.wsh_cast"), lc = S.mute } end
    return st.spell, nil, #rows > 0 and rows or nil
end
local DEMO = { solo = "wait", party = "go", raid = "other" }
local function demo(scene)
    local why = DEMO[scene.size] or "go"
    local name, _, icon = GetSpellInfo(data().shatter)
    local st = { spell = name, icon = icon, why = why, verdict = VERDICT[why], left = why == "other" and 7 or 0, cd = 0,
        stance = true, hero = why == "go", sated = false, open = why == "go", boss = true, go = why == "go",
        ready = (scene.opt and scene.opt.when == "ready") and true or false }
    if why == "other" then st.who, st.whoClass = ns.T("widget.bless_demo_name", 3), "WARRIOR" end
    return st
end
ns.Widget.Register(NAME, {
    info = { text = "widget.war_shatter_info", demo = demo },
    icon = 64382,
    label = "widget.war_shatter",
    class = "WARRIOR",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:64382" },
    avail = avail,
    events = {
        UNIT_AURA = { player = true, target = true }, PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true,
        UPDATE_SHAPESHIFT_FORM = true, UPDATE_SHAPESHIFT_FORMS = true, PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        if st.why == "idle" then return nil end
        local d = data()
        if st.left > 0 then return d.fast end
        if st.cd > 0 then return st.cd < d.minute and d.fast or d.slow end
        return nil
    end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.why ~= "idle" end,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "when", label = "widget.wsh_when", values = {
            { v = nil, label = "widget.wsh_hero" }, { v = "ready", label = "widget.wsh_ready" },
        } },
        { key = "foe", label = "widget.wsh_foe", values = {
            { v = nil, label = "widget.wsh_boss" }, { v = "any", label = "widget.wsh_any" },
        } },
    },
})
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke(NAME) end)
end
ns.warShatterWidgetLoaded = true

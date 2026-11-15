local _, ns = ...
local NAME = "mage_fire_aoe"
local RUN_PART = 0.14
local function data()
    return ns.widgetData.mage_fire_aoe
end
local ends = {}
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    return ns.IsLearned(data().ranks[1])
end
local function castName(id)
    local name, rank = GetSpellInfo(id)
    if not name then return nil end
    if rank and rank ~= "" then return name .. "(" .. rank .. ")" end
    return name
end
local function rankOf(name, rank)
    local d = data()
    local hit
    for i, id in ipairs(d.ranks) do
        local n, r = GetSpellInfo(id)
        if n == name then
            hit = hit or 1
            if (r or "") == (rank or "") then return i end
        end
    end
    return hit
end
local cdAt = {}
local function cdMoved(id)
    local name = GetSpellInfo(id)
    local start, dur = 0, 0
    if name then start, dur = GetSpellCooldown(name) end
    if not (start and dur) or dur <= data().gcd then start = 0 end
    if cdAt[id] == start then return false end
    cdAt[id] = start
    return true
end
local cast = CreateFrame("Frame")
local armed = false
cast:SetScript("OnEvent", function(_, event, unit, name, rank)
    local d = data()
    if event == "SPELL_UPDATE_COOLDOWN" then
        local a, b = cdMoved(d.wave), cdMoved(d.breath)
        if a or b then ns.Widget.Poke(NAME) end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        for k in pairs(ends) do ends[k] = nil end
        ns.Widget.Poke(NAME)
        return
    end
    if unit ~= "player" or not name then return end
    local i = rankOf(name, rank)
    if not i then return end
    ends[i] = GetTime() + d.last
    ns.Widget.Poke(NAME)
end)
local function arm()
    if armed then return end
    armed = true
    cast:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    cast:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    cast:RegisterEvent("PLAYER_ENTERING_WORLD")
end
local function warnOf(opt)
    local w = tonumber(opt and opt.warn)
    if w then return w end
    local _, _, _, _, _, _, ms = GetSpellInfo(data().ranks[1])
    local s = (tonumber(ms) or 0) / 1000
    return s > 0 and s or data().gcd
end
local function cdOf(id)
    local name, _, icon = GetSpellInfo(id)
    local c = { id = id, name = name, icon = icon, learned = ns.IsLearned(id), left = 0 }
    if c.learned and name then c.left = ns.WTile.Left(data().gcd, GetSpellCooldown(name)) end
    return c
end
local function state(opt)
    arm()
    local d = data()
    local now = GetTime()
    local st = {
        ranks = {}, second = not (opt and opt.second == "off"), burning = false, fs = false, fsLeft = 0,
        warn = warnOf(opt), fight = UnitAffectingCombat("player") and true or false, verdict = "none",
    }
    for i, id in ipairs(d.ranks) do
        if i == 1 or st.second then
            local name, rank, icon = GetSpellInfo(id)
            local r = { id = id, name = name, rank = rank, icon = icon, spell = castName(id), left = 0, verdict = "none" }
            local e = ends[i]
            if e and e > now then
                r.left = e - now
                r.start = e - d.last
                r.verdict = r.left <= st.warn and "soon" or "ok"
                st.burning = true
                if not st.latest or r.left > st.latest.left then st.latest = r end
            end
            st.ranks[#st.ranks + 1] = r
        end
    end
    local fname = GetSpellInfo(d.fs)
    st.fsName = fname
    if fname then
        local found, _, _, _, _, _, expires = UnitBuff("player", fname)
        if found then
            st.fs = true
            expires = tonumber(expires) or 0
            st.fsLeft = expires > 0 and math.max(0, expires - now) or 0
        end
    end
    st.wave, st.breath = cdOf(d.wave), cdOf(d.breath)
    st.cdBusy = st.wave.left > 0 or st.breath.left > 0
    if st.fs then
        st.verdict = "full"
    elseif st.latest then
        st.verdict = st.latest.verdict
    end
    return st
end
local function slotsOf(view, second)
    local out = { "r1" }
    if view == "one" then return out end
    if second then out[#out + 1] = "r2" end
    if view == "row" then
        out[#out + 1] = "wave"
        out[#out + 1] = "breath"
    end
    return out
end
local function secondOf(opt)
    return not (opt and opt.second == "off")
end
local function build(layer, view, opt)
    local s, gap = layer.h, layer.gap or 2
    layer.slots = {}
    for i, kind in ipairs(slotsOf(view, secondOf(opt))) do
        local x = (i - 1) * (s + gap)
        local slot = { kind = kind, look = {}, tile = ns.WTile.New(layer, x, 0, s) }
        if kind == "r1" or kind == "r2" then
            local w, h = s - 2, math.max(3, math.floor(s * RUN_PART))
            slot.box = CreateFrame("Frame", nil, layer)
            slot.box:SetPoint("TOPLEFT", layer, "TOPLEFT", x + 1, -1)
            slot.box:SetWidth(w)
            slot.box:SetHeight(h)
            slot.box:SetFrameLevel(layer:GetFrameLevel() + 1)
            slot.run = ns.Gauge.New(slot.box, "bar", { w = w, h = h, max = 1, color = data().gone, bg = data().left })
            slot.run:Frame():SetAllPoints(slot.box)
            slot.box:SetAlpha(0)
            slot.box.lbbAlpha = 0
        end
        layer.slots[i] = slot
    end
end
local function paintRank(slot, r, st, first)
    local S = ns.STATE
    local W = ns.Widget
    local on = r.left > 0
    local k = slot.look
    k.icon = r.icon
    k.alpha = (on or (first and st.fs)) and 1 or data().dim
    k.text = on and W.Left(r.left) or ""
    k.textColor = r.verdict == "soon" and S.soon or S.text
    local gold = first and st.fs
    k.edge = (gold and S.full) or (r.verdict == "soon" and S.soon) or nil
    k.glow = gold
    k.corner = gold and W.Left(st.fsLeft) or nil
    k.cornerColor = S.full
    ns.WTile.Paint(slot.tile, k)
    if on then
        slot.run:Run(r.start, data().last, 1)
    else
        slot.run:Run(nil)
        slot.run:Set(0, 1)
    end
    W.Alpha(slot.box, on and 1 or 0)
end
local function paintCd(slot, c)
    local k = slot.look
    k.icon = c.icon
    k.alpha = (not c.learned and 0) or (c.left > 0 and data().dim) or 1
    k.text = (c.learned and c.left > 0) and ns.Widget.Left(c.left) or ""
    k.textColor = ns.STATE.text
    ns.WTile.Paint(slot.tile, k)
end
local function paint(layer, st, view)
    for _, slot in ipairs(layer.slots) do
        local kind = slot.kind
        if kind == "r1" then
            paintRank(slot, (view == "one" and st.latest) or st.ranks[1], st, true)
        elseif kind == "r2" then
            paintRank(slot, st.ranks[2] or { left = 0, verdict = "none" }, st, false)
        elseif kind == "wave" then
            paintCd(slot, st.wave)
        else
            paintCd(slot, st.breath)
        end
    end
end
local ATTRS = {
    r1 = function(st)
        local r = st.ranks[1]
        return (r and r.spell) and { type = "spell", spell = r.spell } or {}
    end,
    r2 = function(st)
        local r = st.ranks[2]
        return (r and r.spell) and { type = "spell", spell = r.spell } or {}
    end,
    wave = function(st)
        return (st.wave.learned and st.wave.name) and { type = "spell", spell = st.wave.name } or {}
    end,
    breath = function(st)
        return (st.breath.learned and st.breath.name) and { type = "spell", spell = st.breath.name } or {}
    end,
}
local CELLS = {}
local function cellsOf(view, second)
    local key = view .. (second and "2" or "1")
    local list = CELLS[key]
    if list then return list end
    list = {}
    for i, kind in ipairs(slotsOf(view, second)) do
        list[i] = { cx = i - 1, cy = 0, slot = kind, attrs = ATTRS[kind] }
    end
    CELLS[key] = list
    return list
end
local function onTarget()
    if not (UnitExists("target") and UnitCanAttack("player", "target")) then return nil end
    local d = data()
    local hit = {}
    for i = 1, d.debuffs do
        local name, _, _, _, _, _, _, _, _, _, id = UnitAura("target", i, "HARMFUL|PLAYER")
        if not name then break end
        for k, rid in ipairs(d.ranks) do
            if id == rid then hit[k] = true end
        end
    end
    local out = {}
    for k, rid in ipairs(d.ranks) do
        if hit[k] then
            local name, rank = GetSpellInfo(rid)
            out[#out + 1] = (rank and rank ~= "") and rank or name
        end
    end
    return table.concat(out, ns.T("facts.sep"))
end
local function tip(i, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local c = cellsOf(view, st.second)[i]
    local kind = c and c.slot or "r1"
    if kind == "wave" or kind == "breath" then
        local cd = st[kind]
        if not cd.learned then return cd.name, ns.T("widget.mfa_unlearned") end
        return cd.name, cd.left > 0 and ns.T("widget.mfa_cd", W.Left(cd.left)) or ns.T("widget.mfa_ready")
    end
    local rows = {}
    for _, r in ipairs(st.ranks) do
        local label = (r.rank and r.rank ~= "") and r.rank or (r.name or "")
        if r.left > 0 then
            rows[#rows + 1] = { l = label, r = W.Left(r.left), rc = r.verdict == "soon" and S.soon or S.ok }
        else
            rows[#rows + 1] = { l = label, r = ns.T("widget.mfa_out"), lc = S.mute }
        end
    end
    if st.fsName and ns.IsLearned(data().talent) then
        rows[#rows + 1] = { l = st.fsName, r = st.fs and W.Left(st.fsLeft) or ns.T("widget.mfa_none"), lc = st.fs and S.full or S.mute }
    end
    local tgt = onTarget()
    if tgt then rows[#rows + 1] = { l = ns.T("widget.mfa_target"), r = tgt ~= "" and tgt or ns.T("widget.mfa_none") } end
    if st.fs then
        rows[#rows + 1] = { l = ns.T("widget.mfa_go_fs"), lc = S.full }
    elseif st.verdict == "soon" then
        rows[#rows + 1] = { l = ns.T("widget.mfa_go_soon"), lc = S.soon }
    end
    return st.ranks[1] and st.ranks[1].name, nil, rows
end
local DEMO = { solo = { 6, 0, 0, 0, 0 }, party = { 1.2, 6, 0, 18, 0 }, raid = { 3, 7, 8, 12, 0 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local now = GetTime()
    local opt = scene.opt or {}
    local st = {
        ranks = {}, second = secondOf(opt), burning = false, fs = p[3] > 0, fsLeft = p[3], warn = warnOf(opt),
        fight = scene.fight, verdict = "none", fsName = GetSpellInfo(d.fs),
    }
    for i, id in ipairs(d.ranks) do
        if i == 1 or st.second then
            local name, rank, icon = GetSpellInfo(id)
            local r = { id = id, name = name, rank = rank, icon = icon, spell = castName(id), left = p[i], verdict = "none" }
            if r.left > 0 then
                r.start = now - (d.last - r.left)
                r.verdict = r.left <= st.warn and "soon" or "ok"
                st.burning = true
                if not st.latest or r.left > st.latest.left then st.latest = r end
            end
            st.ranks[#st.ranks + 1] = r
        end
    end
    for k, key in ipairs({ "wave", "breath" }) do
        local name, _, icon = GetSpellInfo(d[key])
        st[key] = { id = d[key], name = name, icon = icon, learned = true, left = p[3 + k] }
    end
    st.cdBusy = st.wave.left > 0 or st.breath.left > 0
    st.verdict = (st.fs and "full") or (st.latest and st.latest.verdict) or "none"
    return st
end
ns.Widget.Register(NAME, {
    info = { text = "widget.mage_fire_aoe_info", demo = demo },
    icon = 42926,
    label = "widget.mage_fire_aoe",
    class = "MAGE",
    views = {
        one = { w = 1, h = 1 },
        pair = function(opt) return secondOf(opt) and 2 or 1, 1 end,
        row = function(opt) return secondOf(opt) and 4 or 3, 1 end,
    },
    order = { "one", "pair", "row" },
    view = "pair",
    covers = { "spell:42926", "spell:54741" },
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, SPELLS_CHANGED = true,
        PLAYER_TALENT_UPDATE = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.burning or st.fs or st.cdBusy) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        local show = opt and opt.show
        if show == "always" then return true end
        if show == "fight" then return st.fight end
        return st.burning or st.fs
    end,
    cells = function(view, opt) return cellsOf(view, secondOf(opt)) end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.mfa_show", values = {
            { v = nil, label = "widget.mfa_when" }, { v = "fight", label = "widget.mfa_fight" },
            { v = "always", label = "widget.mfa_always" },
        } },
        { key = "second", label = "widget.mfa_second", values = {
            { v = nil, label = "widget.mfa_yes" }, { v = "off", label = "widget.mfa_no" },
        } },
        { key = "warn", label = "widget.mfa_warn", values = function()
            local out = { { v = nil, label = "widget.mfa_cast" } }
            for _, n in ipairs(data().warns) do out[#out + 1] = { v = n, text = ns.T("time.seconds", n) } end
            return out
        end },
    },
})
ns.mageFireAoeWidgetLoaded = true

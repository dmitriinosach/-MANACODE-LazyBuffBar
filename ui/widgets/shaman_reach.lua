local _, ns = ...
local NAME_PAD = 3
local function data()
    return ns.widgetData.shaman_reach
end
local function avail()
    local _, class = UnitClass("player")
    return class == "SHAMAN"
end
local function callOf(opt)
    local want = opt and opt.call
    for _, id in ipairs(data().calls) do
        if id == want then return id end
    end
    return data().calls[1]
end
local function match(s, name, icon)
    for _, e in ipairs(data().slots[s] or {}) do
        local sname, _, sicon = GetSpellInfo(e.spell)
        if (sname and name:sub(1, #sname) == sname) or (icon and sicon and icon == sicon) then return e end
    end
    return nil
end
local function covered(e)
    for _, id in ipairs(e.alt or {}) do
        local name = GetSpellInfo(id)
        if name and UnitBuff("player", name) then return true end
    end
    return false
end
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { slots = {}, alive = 0, young = false, why = "ok", verdict = "ok" }
    st.always = (opt and opt.show == "always") and true or false
    local cname, _, cicon = GetSpellInfo(callOf(opt))
    st.call, st.callIcon = cname, cicon
    st.recall = GetSpellInfo(d.recall)
    local best
    for s = 1, 4 do
        local _, name, start, dur, icon = GetTotemInfo(s)
        local t = { up = false, left = 0, young = false, far = false, cover = false }
        if name and name ~= "" and start and dur and dur > 0 and start + dur > now then
            t.up, t.name, t.icon, t.left = true, name, icon, start + dur - now
            st.alive = st.alive + 1
            local e = match(s, name, icon)
            if e then
                t.aura = GetSpellInfo(e.aura)
                if now - start < d.grace then
                    t.young, st.young = true, true
                elseif t.aura and UnitBuff("player", t.aura) == nil then
                    t.cover = covered(e)
                    t.far = not t.cover
                end
            end
            if t.far and st.why ~= "far" then st.why, st.slot = "far", s end
            if st.why ~= "far" and (not best or t.left < best) then best, st.slot = t.left, s end
        end
        st.slots[s] = t
    end
    if st.why == "far" then
        st.verdict = "soon"
    elseif st.alive == 0 and (InCombatLockdown() or UnitAffectingCombat("player")) then
        st.why, st.verdict, st.slot = "none", "bad", nil
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.what = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.what:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.what:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -NAME_PAD, NAME_PAD)
    layer.what:SetJustifyH("LEFT")
    layer.what:SetJustifyV("MIDDLE")
end
local function caption(st)
    local t = st.slot and st.slots[st.slot]
    if st.why == "far" then return ns.T("widget.srch_far_on", t.aura or t.name) end
    if st.why == "none" then return ns.T("widget.srch_none") end
    if t then return t.name .. " " .. ns.Widget.Left(t.left) end
    return ""
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local t = st.slot and st.slots[st.slot]
    local k = layer.look
    local ok = st.why == "ok"
    k.icon = (st.why == "none" and st.callIcon) or (t and t.icon) or st.callIcon
    k.grey = ok and not t
    k.alpha = ok and data().dim or 1
    k.edge = (st.why == "far" and S.soon) or (st.why == "none" and S.bad) or nil
    k.mark = st.why == "far" and ns.T("widget.srch_far_mark") or nil
    k.markColor = S.soon
    k.text = (ok and t and view ~= "wide") and W.Left(t.left) or ""
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.what, caption(st))
    W.Color(layer.what, (st.why == "far" and S.soon) or (st.why == "none" and S.bad) or S.text)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, clicks = "AnyUp", attrs = function(st)
        if not st.call then return {} end
        return { type = "spell", spell = st.call, type2 = "spell", spell2 = st.recall }
    end },
}
local DEMO = {
    solo  = { "far", 2, 58643, 58646 },
    party = { "none" },
    raid  = { "far", 1, 57722, 57663 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local cname, _, cicon = GetSpellInfo(callOf(scene.opt))
    local st = { slots = {}, alive = 0, young = false, why = p[1], call = cname, callIcon = cicon,
        recall = GetSpellInfo(d.recall), always = false }
    for s = 1, 4 do st.slots[s] = { up = false, left = 0, young = false, far = false, cover = false } end
    if p[2] then
        local name, _, icon = GetSpellInfo(p[3])
        st.slots[p[2]] = { up = true, name = name, icon = icon, left = 200, aura = GetSpellInfo(p[4]), young = false, far = true, cover = false }
        st.slot, st.alive = p[2], 1
    end
    st.verdict = (p[1] == "far" and "soon") or (p[1] == "none" and "bad") or "ok"
    return st
end
local function slotLine(t)
    local S = ns.STATE
    local W = ns.Widget
    if not t.up then return ns.T("widget.srch_no"), S.mute end
    if t.far then return ns.T("widget.srch_far"), S.soon end
    if t.aura and not t.young and not t.cover then return ns.T("widget.srch_near", W.Left(t.left)), S.ok end
    return ns.T("widget.srch_up", W.Left(t.left)), S.text
end
local function callValues()
    local out = {}
    for i, id in ipairs(data().calls) do
        out[i] = { v = i > 1 and id or nil, text = GetSpellInfo(id) or ("#" .. id) }
    end
    return out
end
ns.Widget.Register("shaman_reach", {
    info = { text = "widget.shaman_reach_info", demo = demo },
    icon = 66842,
    label = "widget.shaman_reach",
    class = "SHAMAN",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = avail,
    events = {
        PLAYER_TOTEM_UPDATE = true, UNIT_AURA = "player", PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.young or (st.always and st.alive > 0)) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st) return st.why ~= "ok" or st.always end,
    cells = function() return CELLS end,
    Tip = function(_, st)
        local line = (st.why == "far" and ns.T("widget.srch_far_tip", st.slots[st.slot].aura or st.slots[st.slot].name)) or (st.why == "none" and ns.T("widget.srch_none_tip")) or nil
        local rows = {}
        for s = 1, 4 do
            local t = st.slots[s]
            local r, c = slotLine(t)
            rows[#rows + 1] = { l = t.name or ns.T("widget.srch_el" .. s), r = r, lc = c, rc = c }
        end
        if st.call then rows[#rows + 1] = { l = ns.T("widget.srch_click", st.call, st.recall or "?") } end
        return ns.T("widget.shaman_reach"), line, rows
    end,
    opts = {
        { key = "call", label = "widget.srch_call", values = callValues },
        { key = "show", label = "widget.srch_show",
          values = { { v = nil, label = "widget.srch_show_bad" }, { v = "always", label = "widget.srch_show_always" } } },
    },
})
ns.shamanReachWidgetLoaded = true

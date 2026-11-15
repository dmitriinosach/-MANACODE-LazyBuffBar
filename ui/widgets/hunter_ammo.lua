local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 3
local KEY = "hunter_ammo"
local function data()
    return ns.widgetData.hunter_ammo
end
local function avail()
    local _, class = UnitClass("player")
    return class == "HUNTER"
end
local function stock()
    local slot = data().slot
    local icon = GetInventoryItemTexture("player", slot)
    if not icon then return 0, nil end
    return GetInventoryItemCount("player", slot) or 0, icon
end
local dirty = false
local listening = false
local used = 0
local spent = 0
local t0
local c0 = 0
local fr = CreateFrame("Frame")
fr:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_DISABLED" then
        t0, c0 = GetTime(), (stock())
    elseif event == "PLAYER_REGEN_ENABLED" then
        if t0 then
            local d = c0 - (stock())
            if d > 0 then
                used = used + d
                spent = spent + (GetTime() - t0)
            end
        end
        t0 = nil
    elseif event ~= "UNIT_INVENTORY_CHANGED" or unit == "player" then
        if dirty then return end
        dirty = true
        ns.Widget.Poke(KEY, data().tick)
    end
end)
local function start()
    if listening then return end
    listening = true
    fr:RegisterEvent("BAG_UPDATE")
    fr:RegisterEvent("UNIT_INVENTORY_CHANGED")
    fr:RegisterEvent("PLAYER_REGEN_DISABLED")
    fr:RegisterEvent("PLAYER_REGEN_ENABLED")
end
local function rate(count)
    local u, s = used, spent
    if t0 then
        local d = c0 - count
        if d > 0 then u, s = u + d, s + (GetTime() - t0) end
    end
    if s < data().minFight or u <= 0 then return nil end
    return u * 60 / s
end
local function state(opt)
    local d = data()
    start()
    dirty = false
    local st = { need = false, count = 0, icon = d.icon, verdict = "ok", show = (opt and opt.show == "always") and "always" or "low" }
    local weapon = GetInventoryItemLink("player", d.ranged)
    if weapon then
        local _, _, _, _, _, _, _, _, loc = GetItemInfo(weapon)
        st.need = d.locs[loc or ""] and true or false
    end
    if not st.need then return st end
    local count, icon = stock()
    st.count, st.icon = count, icon or d.icon
    local link = icon and GetInventoryItemLink("player", d.slot)
    st.name = link and GetItemInfo(link) or nil
    st.rate = rate(count)
    if st.rate then st.mins = math.floor(count / st.rate) end
    local low = (opt and opt.low) or d.low
    if count < low * d.part then st.verdict = "bad" elseif count < low then st.verdict = "soon" end
    return st
end
local function short(n)
    if n < 1000 then return tostring(n) end
    if n < 10000 then return string.format("%.1fk", math.floor(n / 100) / 10) end
    return math.floor(n / 1000) .. "k"
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local d = data()
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.num = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    fontSize(layer.num, s * d.numFont)
    layer.num:SetPoint("TOP", bg, "TOP", 0, -PAD)
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSize(layer.sub, s * d.subFont)
    layer.sub:SetPoint("BOTTOM", bg, "BOTTOM", 0, PAD)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    local c = (v == "soon" and S.soon) or (v == "bad" and S.bad) or S.text
    local num = st.need and short(st.count) or ""
    local k = layer.look
    k.icon = st.icon
    k.edge = v ~= "ok" and c or nil
    k.text = view ~= "wide" and num or ""
    k.textColor = c
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.num, num)
    W.Color(layer.num, c)
    W.Text(layer.sub, st.mins and ns.T("widget.hn_mins", st.mins) or "")
    W.Color(layer.sub, S.mute)
end
local CELLS = { { l = 0, t = 0, r = 1, b = 1 } }
local function tip(_, st)
    if not st.need then return nil end
    local S = ns.STATE
    local c = (st.verdict == "soon" and S.soon) or (st.verdict == "bad" and S.bad) or S.text
    local rows = { { l = ns.T("widget.hn_have"), r = tostring(st.count), rc = c } }
    if st.count <= 0 then rows[#rows + 1] = { l = ns.T("widget.hn_empty"), lc = S.bad } end
    if st.rate then
        rows[#rows + 1] = { l = ns.T("widget.hn_rate"), r = ns.T("widget.hn_per_min", math.floor(st.rate + 0.5)) }
        rows[#rows + 1] = { l = ns.T("widget.hn_enough"), r = ns.T("widget.hn_mins", st.mins or 0) }
    end
    return st.name or ns.T("widget.hunter_ammo"), nil, rows
end
local DEMO = { solo = { 5200, "ok" }, party = { 1600, "soon", 55 }, raid = { 300, "bad", 55 } }
local function demo(scene)
    local p = DEMO[scene.size] or DEMO.raid
    return { need = true, count = p[1], icon = data().icon, verdict = p[2], rate = p[3],
             mins = p[3] and math.floor(p[1] / p[3]) or nil, show = "always" }
end
ns.Widget.Register(KEY, {
    info = { text = "widget.hunter_ammo_info", demo = demo },
    icon = data().icon,
    label = "widget.hunter_ammo",
    class = "HUNTER",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = avail,
    events = { PLAYER_ENTERING_WORLD = true },
    State = state,
    active = function(st) return st.need and (st.show == "always" or st.verdict ~= "ok") end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "low", label = "widget.hn_opt_low", values = function()
            local d = data()
            local out = {}
            for i, n in ipairs(d.lows) do
                local v = n
                if n == d.low then v = nil end
                out[i] = { v = v, text = tostring(n) }
            end
            return out
        end },
        { key = "show", label = "widget.hn_show", values = {
            { v = nil, label = "widget.hn_show_low" }, { v = "always", label = "widget.hn_show_always" },
        } },
    },
})
ns.hunterAmmoWidgetLoaded = true

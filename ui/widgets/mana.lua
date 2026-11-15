local _, ns = ...
local PCT_FONT = 0.4
local function data()
    return ns.widgetData.mana
end
local function rowSize()
    return 1 + #ns.Mana.Sources(), 1
end
local function slots(view)
    if view == "wide" then return 1 end
    return #ns.Mana.Sources()
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    bg:SetWidth(s)
    bg:SetHeight(s)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.pct = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    layer.pct:SetPoint("CENTER", bg, "CENTER", 0, 0)
    fontSize(layer.pct, s * PCT_FONT)
    layer.tiles, layer.looks = {}, {}
    for i = 1, slots(view) do
        layer.tiles[i] = ns.WTile.New(layer, i * (s + gap), 0, s)
        layer.looks[i] = {}
    end
end
local function paint(layer, st)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    W.Text(layer.pct, math.floor(st.pct * 100 + 0.5) .. "%")
    W.Color(layer.pct, S[st.verdict] or S.text)
    for i, t in ipairs(layer.tiles) do
        local c = st.cells[i]
        local k = layer.looks[i]
        local v = c and c.verdict or "hide"
        k.icon = c and c.icon
        k.grey = v == "off" or v == "none"
        k.alpha = (v == "hide" and 0) or ((v == "off" or v == "none") and d.dim) or 1
        k.tint = (c and c.nomana and v ~= "hide") and d.tint or nil
        k.edge = (v == "ok" and S.ok) or nil
        k.text = (c and c.cd > 0) and W.Left(c.cd) or ""
        k.corner = (c and c.count and v ~= "hide") and tostring(c.count) or nil
        k.cornerColor = v == "none" and S.none or S.text
        ns.WTile.Paint(t, k)
    end
end
local cellsBy = {}
local function cells(view)
    local list = cellsBy[view]
    if list then return list end
    list = { { cx = 0, cy = 0 } }
    for i = 1, slots(view) do
        list[#list + 1] = { cx = i, cy = 0, attrs = function(st) return ns.Mana.Click(st.cells[i]) end }
    end
    cellsBy[view] = list
    return list
end
local DEMO = { solo = { 0.92, nil, 0 }, party = { 0.48, 95, 0 }, raid = { 0.21, 34, 140 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local st = { cur = math.floor(p[1] * 20000), max = 20000, pct = p[1], left = p[2], cells = {} }
    for i, s in ipairs(d.classes.PRIEST) do
        local name, _, icon = GetSpellInfo(s.id)
        local cd = i == 1 and p[3] or 0
        st.cells[i] = { key = s.key, known = true, name = name, icon = icon, cd = cd, nomana = false, verdict = cd > 0 and "off" or "ok" }
    end
    st.cells[#st.cells + 1] = { key = "potion", known = true, item = d.potion.items[2], icon = GetItemIcon(d.potion.items[2]),
        count = 5, cd = 0, nomana = false, verdict = "ok" }
    if st.pct < d.crit then st.verdict = "bad" elseif st.pct < d.low then st.verdict = "soon" else st.verdict = "ok" end
    return st
end
local function coverList()
    local out = {}
    for _, list in pairs(data().classes) do
        for _, s in ipairs(list) do
            if s.id then out[#out + 1] = "spell:" .. s.id end
        end
    end
    table.sort(out)
    return out
end
ns.Widget.Register("mana", {
    info = { text = "widget.mana_info", demo = demo },
    icon = 34433,
    label = "widget.mana",
    views = { wide = { w = 2, h = 1 }, row = rowSize },
    order = { "wide", "row" },
    view = "wide",
    covers = coverList(),
    avail = function() return ns.Mana.Avail() end,
    events = {
        UNIT_MANA = "player", UNIT_MAXMANA = "player", SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true,
        BAG_UPDATE = true, BAG_UPDATE_COOLDOWN = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st)
        for _, c in ipairs(st.cells) do
            if c.cd > 0 then return data().tick end
        end
        return nil
    end,
    State = function() return ns.Mana.State() end,
    Build = build,
    Paint = paint,
    cells = cells,
    Tip = function(i, st)
        if i ~= 1 then return nil end
        if st.left then return ns.T("widget.mana"), ns.T("widget.mn_left", ns.Widget.Left(st.left)) end
        return ns.T("widget.mana"), ns.T("widget.mn_flat")
    end,
})
ns.manaWidgetLoaded = true

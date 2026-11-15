local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MINI = 0.45
local DOT = 0.22
local FILL_A = 0.45
local DIM_NONE = 0.4
local DIM_OFF = 0.3
local EDGE = ns.STATE
local WHITE_C = ns.STATE.text
local BLACK = { 0, 0, 0, 1 }
local HAPPY_C = { ns.STATE.none, ns.STATE.soon, ns.STATE.ok }
local function data()
    return ns.widgetData.pet
end
local function rowSize()
    local c = ns.Pet.Class()
    local n = c and #c.row or 0
    return math.max(1, n), 1
end
local function tile(parent, top, x, s)
    local o = {}
    o.edge = parent:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = parent:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    o.text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    o.text:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    return o
end
local function buildMain(layer, s, withFill)
    local o = {}
    local fill
    if withFill then
        fill = ns.Gauge.New(layer, "fill", { w = s - 2, h = s - 2, max = 100, color = EDGE.ok, flash = false })
        fill:Frame():SetPoint("BOTTOMLEFT", layer, "BOTTOMLEFT", 1, 1)
        fill:Frame():SetAlpha(FILL_A)
    end
    local top = CreateFrame("Frame", nil, fill and fill:Frame() or layer)
    top:SetAllPoints(layer)
    o.fill = fill
    o.tile = tile(layer, top, 0, s)
    local dot = math.max(4, math.floor(s * DOT))
    o.dot = top:CreateTexture(nil, "OVERLAY")
    o.dot:SetTexture(WHITE)
    o.dot:SetPoint("TOPRIGHT", o.tile.edge, "TOPRIGHT", -2, -2)
    o.dot:SetWidth(dot)
    o.dot:SetHeight(dot)
    local ms = math.floor(s * MINI)
    o.miniBg = top:CreateTexture(nil, "BACKGROUND")
    o.miniBg:SetTexture(WHITE)
    o.miniBg:SetPoint("BOTTOMRIGHT", o.tile.edge, "BOTTOMRIGHT", 0, 0)
    o.miniBg:SetWidth(ms + 2)
    o.miniBg:SetHeight(ms + 2)
    o.mini = top:CreateTexture(nil, "ARTWORK")
    o.mini:SetPoint("BOTTOMRIGHT", o.tile.edge, "BOTTOMRIGHT", -1, 1)
    o.mini:SetWidth(ms)
    o.mini:SetHeight(ms)
    return o
end
local function build(layer, view)
    local s = layer.cell or layer.h
    local gap = layer.gap or 2
    if view == "row" then
        local top = CreateFrame("Frame", nil, layer)
        top:SetAllPoints(layer)
        layer.tiles = {}
        local n = rowSize()
        for i = 1, n do layer.tiles[i] = tile(layer, top, (i - 1) * (s + gap), s) end
        return
    end
    if view == "bar" then
        local bg = layer:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(WHITE)
        bg:SetVertexColor(0, 0, 0, 0.35)
        bg:SetAllPoints(layer)
        layer.main = buildMain(layer, s, false)
        local x0 = s + gap
        local rw = layer.w - x0 - 2
        local c = ns.Pet.Class()
        if c and c.happy then
            local bh = math.floor(layer.h * 0.5)
            layer.bar = ns.Gauge.New(layer, "bar", { w = rw, h = bh, max = 100, color = EDGE.ok, text = true, flash = false })
            layer.bar:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", x0, -2)
            layer.pips = ns.Gauge.New(layer, "pips", { w = rw, h = layer.h - bh - 6, max = 3, color = EDGE.ok, gap = 2, flash = false })
            layer.pips:Frame():SetPoint("BOTTOMLEFT", layer, "BOTTOMLEFT", x0, 2)
        else
            layer.bar = ns.Gauge.New(layer, "bar", { w = rw, h = math.floor(layer.h * 0.6), max = 100, color = EDGE.ok, text = true, flash = false })
            layer.bar:Frame():SetPoint("LEFT", layer, "LEFT", x0, 0)
        end
        return
    end
    layer.main = buildMain(layer, s, true)
end
local function showIf(fr, on)
    if fr:IsShown() == on then return end
    if on then fr:Show() else fr:Hide() end
end
local function gaugeColor(g, c)
    g:SetColor(c[1], c[2], c[3], c[4])
end
local function paintTile(o, icon, verdict, dim, text)
    local W = ns.Widget
    W.Tex(o.icon, icon or ns.QMARK, dim ~= nil)
    W.Alpha(o.icon, dim or 1)
    local edge = verdict and verdict ~= "ok" and EDGE[verdict] or nil
    if edge then W.Color(o.edge, edge) end
    W.Alpha(o.edge, edge and 1 or 0)
    W.Text(o.text, text or "")
    W.Color(o.text, WHITE_C)
end
local function paintMain(o, st)
    local W = ns.Widget
    local v = st.verdict
    local dim = (v == "none" and DIM_NONE) or (v == "off" and DIM_OFF) or nil
    paintTile(o.tile, st.icon, v, dim, (v == "none" and st.cd) and W.Left(st.cd) or nil)
    if o.fill then
        o.fill:Set((st.alive and st.hp < 100 and v ~= "off") and st.hp or 0, 100)
        gaugeColor(o.fill, st.low and EDGE.soon or EDGE.ok)
    end
    local h = (st.alive and st.happy and st.happy < 3) and st.happy or nil
    if h then W.Color(o.dot, HAPPY_C[h]) end
    W.Alpha(o.dot, h and 1 or 0)
    local mini = v == "bad" and st.want or nil
    W.Tex(o.mini, mini or ns.QMARK, false)
    W.Alpha(o.mini, mini and 1 or 0)
    W.Color(o.miniBg, BLACK)
    W.Alpha(o.miniBg, mini and 1 or 0)
end
local function paint(layer, st, view)
    local W = ns.Widget
    if view == "row" then
        for i, o in ipairs(layer.tiles) do
            local c = st.cells[i]
            if c then
                local dim = (not c.known or st.verdict == "off") and DIM_OFF or nil
                paintTile(o, c.icon, c.need, dim, c.cd and W.Left(c.cd) or nil)
            end
        end
        return
    end
    paintMain(layer.main, st)
    if view ~= "bar" then return end
    local live = st.alive and st.verdict ~= "off"
    showIf(layer.bar:Frame(), live)
    if live then
        layer.bar:Set(st.hp, 100)
        gaugeColor(layer.bar, st.low and EDGE.soon or EDGE.ok)
    end
    if layer.pips then
        local h = live and st.happy or nil
        showIf(layer.pips:Frame(), h ~= nil)
        if h then
            gaugeColor(layer.pips, HAPPY_C[h] or EDGE.ok)
            layer.pips:Set(h, 3)
        end
    end
end
local MAIN_CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.macro then return {} end
        return { type = "macro", macrotext = st.macro }
    end },
}
local rowCells = {}
local function rowList()
    local _, class = UnitClass("player")
    local list = rowCells[class or ""]
    if list then return list end
    list = {}
    local n = rowSize()
    for i = 1, n do
        list[i] = { cx = i - 1, cy = 0, attrs = function(st)
            local c = st.cells[i]
            if not (c and c.known and c.name) then return {} end
            return { type = "spell", spell = c.name }
        end }
    end
    rowCells[class or ""] = list
    return list
end
local function demonLabel(key)
    if not key then return nil end
    return ns.T("widget.pet_d_" .. key)
end
local function mainLine(st)
    local v = st.verdict
    local W = ns.Widget
    if v == "off" then return ns.T(st.why == "dead" and "widget.pet_off_dead" or "widget.pet_off_mount") end
    if v == "none" then
        if st.dead and st.revive then return ns.T("widget.pet_dead", st.revive) end
        if st.cd then return ns.T("widget.pet_none_cd", st.summon or "?", W.Left(st.cd)) end
        return ns.T("widget.pet_none", st.summon or "?")
    end
    if v == "bad" then
        return ns.T("widget.pet_bad", demonLabel(st.kind) or st.name or "?", demonLabel(st.expect) or "?", st.summon or "?")
    end
    local line = ns.T("widget.pet_hp", st.hp)
    if st.happy then line = line .. " " .. ns.T("widget.pet_happy_" .. st.happy, st.dmg or 100) end
    if st.heal then line = line .. " " .. ns.T("widget.pet_click", st.heal) end
    return line
end
local function isWarlock()
    local c = ns.Pet.Class()
    return c ~= nil and c.demons == true
end
local function iconId()
    local c = ns.Pet.Class()
    if c and c.summon then return c.summon end
    if c and c.demons then return data().demons[1].summon end
    return data().classes.HUNTER.summon
end
ns.Widget.Register("pet", {
    icon = iconId(),
    label = "widget.pet",
    personal = true,
    views = { one = { w = 1, h = 1 }, bar = { w = 2, h = 1 }, row = function() return rowSize() end },
    order = { "one", "bar", "row" },
    view = "one",
    covers = ns.Pet.Covers(),
    avail = function() return ns.Pet.Avail() end,
    events = {
        UNIT_HEALTH = "pet", UNIT_MAXHEALTH = "pet", UNIT_HAPPINESS = true,
        UNIT_ENTERED_VEHICLE = "player", UNIT_EXITED_VEHICLE = "player",
        SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true,
    },
    tick = 1,
    State = function(opt) return ns.Pet.State(opt) end,
    active = function(st, opt) return ns.Pet.Active(st, opt) end,
    Build = build,
    Paint = paint,
    cells = function(view)
        if view == "row" then return rowList() end
        return MAIN_CELLS
    end,
    Tip = function(_, st, view)
        if view == "row" then return nil end
        local title = st.name or st.summon or ns.T("widget.pet")
        return title, mainLine(st)
    end,
    Caption = function(st)
        if st.source == "spec" then return ns.T("widget.pet_src_spec", demonLabel(st.expect) or "?") end
        if st.source == "opt" then return ns.T("widget.pet_src_opt") end
        return nil
    end,
    opts = {
        { key = "expect", label = "widget.pet_expect", when = isWarlock,
          values = function()
              local out = { { v = nil, label = "widget.pet_auto" }, { v = "any", label = "widget.pet_any" } }
              for _, d in ipairs(data().demons) do out[#out + 1] = { v = d.key, label = "widget.pet_d_" .. d.key } end
              return out
          end },
        { key = "low", label = "widget.pet_low",
          values = function()
              local out = {}
              for _, n in ipairs(data().lows) do
                  out[#out + 1] = { v = (n ~= data().low) and n or nil, text = ns.T("widget.pet_pct", n) }
              end
              return out
          end },
        { key = "when", label = "widget.pet_when", values = {
            { v = nil, label = "widget.pet_when_always" }, { v = "need", label = "widget.pet_when_need" },
        } },
    },
})
ns.petWidgetLoaded = true

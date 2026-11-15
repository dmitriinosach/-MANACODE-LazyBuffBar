local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLOW_TEX = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SPAN = 1.9
local FONT_PART = 0.4
local NAME_PAD = 3
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local function data()
    return ns.widgetData.kick
end
local WAIT = { cd = true, res = true, use = true, far = true }
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function tile(layer, x, s, withFill)
    local o = {}
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", x, 0)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = layer:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    local under = layer
    if withFill then
        o.fill = ns.Gauge.New(layer, "fill", { w = s - 2, h = s - 2, max = 1, color = data().fill, flash = false })
        o.fill:Frame():SetPoint("BOTTOMLEFT", o.edge, "BOTTOMLEFT", 1, 1)
        under = o.fill:Frame()
    end
    local top = CreateFrame("Frame", nil, under)
    top:SetAllPoints(o.edge)
    o.pulse = CreateFrame("Frame", nil, top)
    o.pulse:SetAllPoints(o.edge)
    local g = o.pulse:CreateTexture(nil, "OVERLAY")
    g:SetTexture(GLOW_TEX)
    g:SetBlendMode("ADD")
    g:SetWidth(s * GLOW_SPAN)
    g:SetHeight(s * GLOW_SPAN)
    g:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    local c = data().glow
    g:SetVertexColor(c[1], c[2], c[3])
    o.pulse:Hide()
    o.text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    o.text:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    fontSize(o.text, s * FONT_PART)
    return o
end
local function build(layer, view)
    local s, gap = layer.h, layer.gap or 2
    if view == "one" then
        layer.kick = tile(layer, 0, s, true)
        return
    end
    layer.kick = tile(layer, layer.w - s, s, false)
    if view == "short" then
        layer.cast = tile(layer, 0, s, true)
        return
    end
    local bw = layer.w - s - gap
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    bg:SetWidth(bw)
    bg:SetHeight(s)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.bar = ns.Gauge.New(layer, "bar", { w = bw - 2, h = s - 2, max = 1, color = data().bar.ok, flash = false })
    layer.bar:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", 1, -1)
    local top = CreateFrame("Frame", nil, layer.bar:Frame())
    top:SetAllPoints(layer.bar:Frame())
    layer.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.time:SetPoint("RIGHT", top, "RIGHT", -NAME_PAD, 0)
    layer.time:SetJustifyH("RIGHT")
    layer.name = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.name:SetPoint("LEFT", top, "LEFT", NAME_PAD, 0)
    layer.name:SetPoint("RIGHT", layer.time, "LEFT", -NAME_PAD, 0)
    layer.name:SetJustifyH("LEFT")
end
local function leftPart(c)
    if not c or c.total <= 0 then return 0 end
    local f = c.left / c.total
    if f < 0 then return 0 end
    if f > 1 then return 1 end
    return f
end
local function castTime(c)
    if not c then return "" end
    return string.format("%.1f", c.left)
end
local function tone(st)
    if st.cast and st.cast.lock then return "lock" end
    return st.verdict
end
local function paintKick(o, st)
    local W = ns.Widget
    local d = data()
    local v = st.verdict
    local lit = v == "ok" or v == "soon"
    W.Tex(o.icon, st.icon or ns.QMARK, not lit)
    W.Alpha(o.icon, lit and 1 or (WAIT[st.why] and d.dimWait or d.dimIdle))
    W.Color(o.edge, d.edge[v] or d.edge.off)
    W.Alpha(o.edge, (lit or st.cast) and 1 or 0)
    local go = v == "ok"
    if go ~= o.pulse:IsShown() then
        if go then o.pulse:Show() else o.pulse:Hide() end
    end
    ns.Anim.Pulse(o.pulse, go)
    W.Text(o.text, st.cd > 0 and W.Left(st.cd) or "")
    W.Color(o.text, v == "soon" and WARN_C or WHITE_C)
    if o.fill then
        local c = st.cast
        o.fill:Set((c and not c.lock) and leftPart(c) or 0, 1)
    end
end
local function paintCastTile(o, st)
    local W = ns.Widget
    local d = data()
    local c = st.cast
    W.Tex(o.icon, c and c.icon or ns.QMARK, not c or c.lock)
    W.Alpha(o.icon, c and 1 or 0)
    W.Color(o.edge, d.bar[tone(st)] or d.bar.off)
    W.Alpha(o.edge, c and 1 or 0)
    W.Text(o.text, castTime(c))
    W.Color(o.text, WHITE_C)
    o.fill:Set((c and not c.lock) and leftPart(c) or 0, 1)
    if o.pulse:IsShown() then o.pulse:Hide() end
end
local function paintBar(layer, st)
    local W = ns.Widget
    local c = st.cast
    local col = data().bar[tone(st)] or data().bar.off
    layer.bar:SetColor(col[1], col[2], col[3], col[4])
    local f = 0
    if c then f = c.channel and leftPart(c) or (1 - leftPart(c)) end
    layer.bar:Set(f, 1)
    W.Text(layer.name, c and c.name or "")
    W.Text(layer.time, castTime(c))
end
local function paint(layer, st, view)
    paintKick(layer.kick, st)
    if view == "short" then paintCastTile(layer.cast, st) end
    if view == "bar" then paintBar(layer, st) end
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(_, opt) return ns.Kick.Click(opt) end },
}
local function tipLine(st)
    local why, c = st.why, st.cast
    if why == "go" then return ns.T("widget.k_go", c and c.name or "?") end
    if why == "cd" then return ns.T(st.verdict == "soon" and "widget.k_soon" or "widget.k_late", ns.Widget.Left(st.cd)) end
    if why == "lock" then return ns.T("widget.k_lock", c and c.name or "?") end
    return ns.T("widget.k_" .. why)
end
local function coverList()
    local out = {}
    for _, list in pairs(data().classes) do
        for _, e in ipairs(list) do
            out[#out + 1] = "spell:" .. e.id
            for _, id in ipairs(e.alt or {}) do out[#out + 1] = "spell:" .. id end
        end
    end
    table.sort(out)
    return out
end
local first = ns.Kick.List()[1]
ns.Widget.Register("kick", {
    icon = first and first.id or 1766,
    label = "widget.kick",
    views = { one = { w = 1, h = 1 }, short = { w = 2, h = 1 }, bar = { w = 3, h = 1 } },
    order = { "one", "short", "bar" },
    view = "one",
    covers = coverList(),
    avail = function() return ns.Kick.Avail() end,
    events = {
        UNIT_SPELLCAST_START = "target", UNIT_SPELLCAST_STOP = "target", UNIT_SPELLCAST_FAILED = "target",
        UNIT_SPELLCAST_INTERRUPTED = "target", UNIT_SPELLCAST_DELAYED = "target",
        UNIT_SPELLCAST_CHANNEL_START = "target", UNIT_SPELLCAST_CHANNEL_STOP = "target", UNIT_SPELLCAST_CHANNEL_UPDATE = "target",
        UNIT_SPELLCAST_INTERRUPTIBLE = "target", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "target",
        PLAYER_TARGET_CHANGED = true, SPELL_UPDATE_COOLDOWN = true,
        UPDATE_SHAPESHIFT_FORM = true, UPDATE_SHAPESHIFT_FORMS = true, SPELLS_CHANGED = true,
        UNIT_PET = "player", PET_BAR_UPDATE = true, PET_BAR_UPDATE_COOLDOWN = true,
        PLAYER_DEAD = true, PLAYER_ALIVE = true, PLAYER_UNGHOST = true, PLAYER_ENTERING_WORLD = true,
        PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
    },
    tick = function(st) return ns.Kick.Tick(st) end,
    State = function(opt) return ns.Kick.State(opt) end,
    active = function(st) return ns.Kick.Active(st) end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st)
        if st.why == "idle" then return nil end
        return st.spell or ns.T("widget.kick"), tipLine(st)
    end,
    opts = {
        { key = "idle", label = "widget.k_show", values = {
            { v = nil, label = "widget.k_show_hide" }, { v = "dim", label = "widget.k_show_dim" },
        } },
        { key = "spell", label = "widget.k_spell", when = function() return #ns.Kick.Choices() > 1 end,
          values = function()
              local out = { { v = nil, label = "widget.k_auto" } }
              for _, e in ipairs(ns.Kick.Choices()) do out[#out + 1] = { v = e.id, text = GetSpellInfo(e.id) or ("#" .. e.id) } end
              return out
          end },
    },
})
ns.kickWidgetLoaded = true

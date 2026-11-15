local _, ns = ...
ns.Blocks = {}
local ICON = 32
local GRIP, GRIP_OUT, GRAB_STEP = 16, 4, 150
local STEP_FRAC = 0.25
local MAX_COLS, MAX_ROWS = 16, 8
local OVER_LEVEL = 15
local CLICK_ABOVE = 2
local DASH, DASH_GAP = 4, 3
local C_CELL = { 0.62, 0.64, 0.72 }
local CELL_ALPHA = 0.55
local PLUS_ALPHA = 0.55
local HOT_FILL = 0.08
local OVER_BG = 0.45
local CATCH_BG = 0.12
local SEL_PAD = 2
local CALL_RISE, CALL_GAP = 10, 4
local BLINK_SECS, BLINK_RATE, BLINK_LOW, BLINK_HIGH = 1.2, 9, 0.15, 0.6
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GRIP_UP = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"
local GRIP_HL = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight"
local GRIP_SHADE, GRIP_LIT = 0.85, 0.6
local function gold()
    local c = ns.EDIT.gold
    return c[1], c[2], c[3]
end
local selected
function ns.Blocks.Grid()
    return ns.Grid
end
local frames = {}
local byKey = {}
local hooks = { hover = {}, grab = {}, plus = {}, drop = {} }
local function cfg()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function locked()
    return cfg().locked and true or false
end
local function rectOf(fr)
    if not fr:GetLeft() then return nil end
    local l, t, r, b = ns.Snap.Rect(fr)
    return { l = l, t = t, r = r, b = b }
end
local function screen()
    return { l = 0, b = 0, r = UIParent:GetWidth(), t = UIParent:GetHeight() }
end
local function others(fr, skip)
    local fs, rs = {}, {}
    for _, f in pairs(byKey) do
        if f ~= fr and f ~= skip and f:IsShown() then
            local r = rectOf(f)
            if r then fs[#fs + 1] = f; rs[#rs + 1] = r end
        end
    end
    return fs, rs
end
local function placeOf(fr)
    if not fr._key then return nil end
    local i = ns.buffbar:BarIndex(fr._key)
    return i and ns.Preset.Blocks()[i] or nil, i
end
function ns.Blocks.SavePos(fr)
    local x, y = fr:GetLeft(), fr:GetTop()
    local key = fr._key
    if not (x and y and key) then return end
    local point = { "TOPLEFT", "BOTTOMLEFT", x, y }
    if InCombatLockdown() then
        ns.DeferKey(key .. ".pos", function() ns.Preset.SetBlock(key, "point", point) end)
        return
    end
    ns.Preset.SetBlock(key, "point", point)
end
function ns.Blocks.Rescale(fr, v)
    local x, y = fr:GetLeft(), fr:GetTop()
    local k = fr:GetEffectiveScale()
    fr:SetScale(v)
    if not (x and y) then return end
    local nk = fr:GetEffectiveScale()
    fr:ClearAllPoints()
    fr:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x * k / nk, y * k / nk)
    ns.Blocks.SavePos(fr)
end
local function settle(fr)
    ns.Blocks.SavePos(fr)
end
local function localPos(fr)
    local r = rectOf(fr)
    if not r then return nil end
    local cx, cy = GetCursorPosition()
    local u = UIParent:GetEffectiveScale()
    cx, cy = cx / u, cy / u
    if cx < r.l or cx > r.r or cy < r.b or cy > r.t then return nil end
    local k = fr:GetEffectiveScale() / u
    return (cx - r.l) / k, (r.t - cy) / k
end
local function cellUnder(fr)
    local lx, ly = localPos(fr)
    if not lx then return nil end
    local b = fr._block
    if not (b and fr._geo) then return fr._key, nil, nil end
    local x, y = ns.Blocks.Grid().CellAt(fr._geo, lx, ly)
    if x < 1 or y < 1 or x > b.cols or y > b.rows then return fr._key, nil, nil end
    return fr._key, x, y
end
function ns.Blocks.Under()
    for _, fr in pairs(byKey) do
        if fr:IsShown() then
            local key, x, y = cellUnder(fr)
            if key then return key, x, y end
        end
    end
    return nil
end
function ns.Blocks.Grab(fr)
    if not fr or locked() then return end
    ns.Blocks.GrabPanel(fr)
end
function ns.Blocks.GrabIcon(fr, x, y)
    if not fr then return end
    if locked() then
        if not IsAltKeyDown() or InCombatLockdown() or not (fr._key and x and y) then return end
        for _, fn in ipairs(hooks.grab) do
            if fn(fr._key, x, y, true) then return end
        end
        return
    end
    if fr._key and x and y then
        for _, fn in ipairs(hooks.grab) do
            if fn(fr._key, x, y) then return end
        end
    end
    ns.Blocks.GrabPanel(fr)
end
function ns.Blocks.ClickLevel(fr)
    return fr:GetFrameLevel() + OVER_LEVEL + CLICK_ABOVE
end
function ns.Blocks.Busy()
    if ns.Snap.Held() then return true end
    for _, fr in pairs(byKey) do
        if fr._moving or (fr.sizer and fr.sizer:IsActive()) or (fr.corner and fr.corner.scaling) then return true end
    end
    return false
end
function ns.Blocks.GrabPanel(fr)
    if not fr or locked() then return end
    local fs, rs = others(fr)
    local last = rectOf(fr)
    local grid = ns.Blocks.Grid()
    local function fit(l, t, r, b)
        if not last then return l, t end
        last = grid.Push(last, { l = l, t = t, r = r, b = b }, rs)
        return last.l, last.t
    end
    if ns.Snap.Begin(fr, fs, settle, fit) then return end
    if InCombatLockdown() then return end
    fr._moving = true
    fr:StartMoving()
end
function ns.Blocks.Drop(fr)
    if fr._moving then
        fr._moving = nil
        if InCombatLockdown() then return end
        fr:StopMovingOrSizing()
        settle(fr)
        return
    end
    ns.Snap.Finish(fr)
end
local function tipBelow(owner, fr)
    GameTooltip:SetOwner(owner, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", fr, "BOTTOMLEFT", 0, -6)
end
local function wheelAlpha(fr, delta)
    if locked() then return end
    local bc, i = placeOf(fr)
    if not i then return end
    local k = ns.Look.BAR.alpha
    local v = ns.Look.SetBar(i, "alpha", ns.Look.Bar(i, "alpha") + (delta > 0 and k.step or -k.step))
    fr:SetAlpha(v)
    tipBelow(fr, fr)
    GameTooltip:SetText(ns.T("look.alpha_now", ns.BarName(bc, i), ns.Look.Format("alpha", v)), 1, 1, 1, 1, true)
    GameTooltip:Show()
    if ns.PanelCard then ns.PanelCard.Refresh() end
end
local function openCard(fr)
    if locked() or not fr._key or not ns.PanelCard then return end
    if ns.Reorder and ns.Reorder.Active and ns.Reorder.Active() then return end
    GameTooltip:Hide()
    ns.PanelCard.Open(fr._key, fr)
end
local function nameOf(fr)
    local bc, i = placeOf(fr)
    return ns.BarName(bc, i)
end
local function steps(geo)
    local grid = ns.Blocks.Grid()
    geo = grid.Geo(geo.pad, geo.gap)
    local w1, h1 = grid.Pixels(geo, 1, 1)
    local w2, h2 = grid.Pixels(geo, 2, 2)
    return w1, h1, w2 - w1, h2 - h1
end
local function cellsFor(fr, w, h)
    local w1, h1, sx, sy = steps(fr._geo)
    return math.floor((w - w1) / sx + (1 - STEP_FRAC)) + 1, math.floor((h - h1) / sy + (1 - STEP_FRAC)) + 1
end
function ns.Blocks.MaxSizeOf(fr)
    local b = fr._block
    if not b then return MAX_COLS, MAX_ROWS end
    local grid = ns.Blocks.Grid()
    local mc, mr = grid.MinSize(b)
    local r = rectOf(fr)
    if not r then return MAX_COLS, MAX_ROWS end
    local fk, fw = ns.Preset.Follower(fr._key)
    local _, rs = others(fr, fk and byKey[fk])
    local maxW, maxH = grid.Room(r, rs, screen())
    maxW = maxW - fw
    local k = fr:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local w1, h1, sx, sy = steps(fr._geo)
    local xc = math.floor((maxW / k - w1) / sx + 1e-6) + 1
    local xr = math.floor((maxH / k - h1) / sy + 1e-6) + 1
    return math.max(mc, math.min(MAX_COLS, xc)), math.max(mr, math.min(MAX_ROWS, xr))
end
function ns.Blocks.MaxSize(key)
    local fr = byKey[key]
    if not fr then return MAX_COLS, MAX_ROWS end
    return ns.Blocks.MaxSizeOf(fr)
end
local function sizeLimits(fr)
    local grid = ns.Blocks.Grid()
    local mc, mr = grid.MinSize(fr._block)
    local xc, xr = ns.Blocks.MaxSizeOf(fr)
    local minW, minH = grid.Pixels(fr._geo, mc, mr)
    local maxW, maxH = grid.Pixels(fr._geo, xc, xr)
    return minW, minH, maxW, maxH
end
local function sizeSnap(fr, w, h)
    local grid = ns.Blocks.Grid()
    local mc, mr = grid.MinSize(fr._block)
    local xc, xr = ns.Blocks.MaxSizeOf(fr)
    local cols, rows = cellsFor(fr, w, h)
    cols = math.max(mc, math.min(xc, cols))
    rows = math.max(mr, math.min(xr, rows))
    return grid.Pixels(fr._geo, cols, rows)
end
local function sizeApply(fr, w, h)
    if not fr._key then return end
    local cols, rows = cellsFor(fr, w, h)
    ns.buffbar:Resize(fr._key, cols, rows)
end
local function stopScaling(g)
    g.scaling = false
    local key = g.key
    g.key = nil
    if key and byKey[key] == g.fr then ns.buffbar:SetScale(g.fr:GetScale(), key) end
end
local function startSize(fr)
    if locked() or not fr._block then return false end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    GameTooltip:Hide()
    return fr.sizer:Start()
end
local function sizeTip(g)
    local fr = g.fr
    tipBelow(g, fr)
    if ns.HelpTips() then
        GameTooltip:SetText(nameOf(fr), 1, 1, 1)
        GameTooltip:AddLine(ns.T("bar.size_drag"), 1, 1, 1, true)
        GameTooltip:AddLine(ns.T("bar.size_shift"), 1, 1, 1, true)
    else
        GameTooltip:SetText(ns.T("bar.size_short", nameOf(fr)), 1, 1, 1, 1, true)
    end
    GameTooltip:Show()
end
local function makeCorner(fr)
    local g = CreateFrame("Button", nil, fr)
    g.fr = fr
    g:SetWidth(GRIP)
    g:SetHeight(GRIP)
    g:SetFrameLevel(fr:GetFrameLevel() + 31)
    g:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", GRIP_OUT, -GRIP_OUT)
    local r, gr, b = gold()
    g.shade = g:CreateTexture(nil, "BACKGROUND")
    g.shade:SetTexture(GRIP_UP)
    g.shade:SetPoint("TOPLEFT", g, "TOPLEFT", 1, -1)
    g.shade:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", 1, -1)
    g.shade:SetVertexColor(0, 0, 0, GRIP_SHADE)
    g.tex = g:CreateTexture(nil, "ARTWORK")
    g.tex:SetTexture(GRIP_UP)
    g.tex:SetAllPoints(g)
    g.tex:SetVertexColor(r, gr, b, 1)
    g.lit = g:CreateTexture(nil, "OVERLAY")
    g.lit:SetTexture(GRIP_UP)
    g.lit:SetAllPoints(g)
    g.lit:SetBlendMode("ADD")
    g.lit:SetVertexColor(r, gr, b, GRIP_LIT)
    g.hl = g:CreateTexture(nil, "HIGHLIGHT")
    g.hl:SetTexture(GRIP_HL)
    g.hl:SetAllPoints(g.tex)
    g:SetScript("OnEnter", function(self) sizeTip(self) end)
    g:SetScript("OnLeave", function() GameTooltip:Hide() end)
    g:SetScript("OnMouseDown", function(self, button)
        if locked() or (button and button ~= "LeftButton") then return end
        if not IsShiftKeyDown() then
            startSize(self.fr)
            return
        end
        if InCombatLockdown() then
            if ns.say then ns.say(ns.T("bar.combat")) end
            return
        end
        self.scaling = true
        self.key = self.fr._key
        self.baseScale = self.fr:GetScale()
        self.baseY = select(2, GetCursorPosition())
    end)
    g:SetScript("OnMouseUp", function(self)
        if self.fr.sizer:IsActive() then
            self.fr.sizer:Finish()
            return
        end
        if self.scaling then stopScaling(self) end
    end)
    g:SetScript("OnUpdate", function(self)
        if not self.scaling then return end
        if self.key ~= self.fr._key or InCombatLockdown() or not IsMouseButtonDown("LeftButton") then
            stopScaling(self)
            return
        end
        local _, y = GetCursorPosition()
        local s = self.baseScale + (self.baseY - y) / GRAB_STEP
        if s < ns.BAR_SCALE.min then s = ns.BAR_SCALE.min elseif s > ns.BAR_SCALE.max then s = ns.BAR_SCALE.max end
        local b = placeOf(self.fr)
        if b then b.scale = s end
        ns.Blocks.Rescale(self.fr, s)
    end)
    g:Hide()
    return g
end
local function dashes(f, w, h)
    local list = f.dashes or {}
    f.dashes = list
    local n = 0
    local function dash(point, x, y, dw, dh)
        n = n + 1
        local t = list[n]
        if not t then
            t = f:CreateTexture(nil, "ARTWORK")
            t:SetTexture(WHITE)
            list[n] = t
        end
        t:SetWidth(dw)
        t:SetHeight(dh)
        t:ClearAllPoints()
        t:SetPoint(point, f, point, x, y)
        t:Show()
    end
    local step = DASH + DASH_GAP
    for x = 0, w - DASH, step do
        dash("TOPLEFT", x, 0, DASH, 1)
        dash("BOTTOMLEFT", x, 0, DASH, 1)
    end
    for y = 0, h - DASH, step do
        dash("TOPLEFT", 0, -y, 1, DASH)
        dash("TOPRIGHT", 0, -y, 1, DASH)
    end
    for i = n + 1, #list do list[i]:Hide() end
    return list
end
local function tintDashes(f, r, g, b, a)
    for _, t in ipairs(f.dashes or {}) do t:SetVertexColor(r, g, b, a) end
end
local function makeSelection(fr)
    local s = CreateFrame("Frame", nil, fr)
    s:SetFrameLevel(fr:GetFrameLevel() + OVER_LEVEL - 1)
    s:SetPoint("TOPLEFT", fr, "TOPLEFT", -(SEL_PAD + 1), SEL_PAD + 1)
    s:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", SEL_PAD + 1, -(SEL_PAD + 1))
    s:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    s:Hide()
    return s
end
local function paintSelection(fr)
    local s = fr.sel
    if not s then return end
    if selected and fr._key == selected and fr.over:IsShown() then
        local r, g, b = gold()
        s:SetBackdropBorderColor(r, g, b, 0.9)
        s:Show()
    else
        s:Hide()
    end
end
function ns.Blocks.Select(key)
    selected = key
    for _, fr in pairs(byKey) do paintSelection(fr) end
end
function ns.Blocks.Selected()
    return selected
end
local function makeCallout(fr)
    local c = CreateFrame("Frame", nil, fr)
    c:SetFrameLevel(fr:GetFrameLevel() + 29)
    c:SetWidth(1)
    c:SetHeight(1)
    c:SetPoint("BOTTOMLEFT", fr, "TOPRIGHT", -CALL_GAP, 0)
    c.rise = c:CreateTexture(nil, "ARTWORK")
    c.rise:SetTexture("Interface\\Buttons\\WHITE8X8")
    c.rise:SetWidth(1)
    c.rise:SetHeight(CALL_RISE)
    c.rise:SetPoint("BOTTOM", c, "BOTTOMLEFT", 0, 0)
    c.run = c:CreateTexture(nil, "ARTWORK")
    c.run:SetTexture("Interface\\Buttons\\WHITE8X8")
    c.run:SetHeight(1)
    c.run:SetPoint("BOTTOMLEFT", c.rise, "TOP", 0, 0)
    c.name = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.name:SetPoint("BOTTOMLEFT", c.run, "TOPLEFT", CALL_GAP, 1)
    c:Hide()
    return c
end
local function showCallout(fr)
    if locked() then return end
    local c = fr.callout
    c.name:SetText(nameOf(fr))
    c.run:SetWidth(c.name:GetStringWidth() + CALL_GAP * 2)
    local r, g, b = gold()
    c.rise:SetVertexColor(r, g, b, 0.8)
    c.run:SetVertexColor(r, g, b, 0.8)
    c.name:SetTextColor(r, g, b)
    c:Show()
end
function ns.Blocks.EnterIcon(fr)
    if fr and fr.callout and fr.over and fr.over:IsShown() then showCallout(fr) end
end
function ns.Blocks.LeaveIcon(fr)
    if fr and fr.callout then fr.callout:Hide() end
end
function ns.Blocks.OpenCard(fr)
    openCard(fr)
end
local function hoverTo(fr, key, x, y)
    if fr._hoverKey == key and fr._hoverX == x and fr._hoverY == y then return end
    fr._hoverKey, fr._hoverX, fr._hoverY = key, x, y
    for _, fn in ipairs(hooks.hover) do fn(key, x, y) end
end
local function stepBlink(fr, elapsed)
    local s = fr._blink
    s.t = s.t + elapsed
    if s.t >= BLINK_SECS then
        fr._blink = nil
        for _, t in ipairs(fr.blinks) do t:Hide() end
        return
    end
    local a = BLINK_LOW + (BLINK_HIGH - BLINK_LOW) * math.abs(math.sin(s.t * BLINK_RATE))
    for i = 1, s.n do fr.blinks[i]:SetAlpha(a) end
end
function ns.Blocks.Blink(key, cells)
    local fr = byKey[key]
    if not (fr and fr.over and fr._geo) then return end
    local grid = ns.Blocks.Grid()
    local c = ns.EDIT.bad
    for i, cell in ipairs(cells) do
        local t = fr.blinks[i]
        if not t then
            t = fr.over:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            t:SetWidth(ICON)
            t:SetHeight(ICON)
            fr.blinks[i] = t
        end
        local px, py = grid.CellXY(fr._geo, cell.x, cell.y)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", fr.over, "TOPLEFT", px, -py)
        t:SetVertexColor(c[1], c[2], c[3], 1)
        t:SetAlpha(BLINK_HIGH)
        t:Show()
    end
    for i = #cells + 1, #fr.blinks do fr.blinks[i]:Hide() end
    fr._blink = { t = 0, n = #cells }
end
function ns.Blocks.Blinking(key)
    local fr = byKey[key]
    return (fr and fr._blink) and true or false
end
local function itemOnCursor()
    return (GetCursorInfo and GetCursorInfo()) == "item"
end
local function dropItem(key, x, y)
    if not key or #hooks.drop == 0 or not itemOnCursor() then return false end
    for _, fn in ipairs(hooks.drop) do fn(key, x, y) end
    return true
end
local function wantCatch()
    return locked() and not InCombatLockdown() and #hooks.drop > 0 and itemOnCursor()
end
local function catchOn(fr, on)
    local o = fr.over
    if on then
        local r, g, b = gold()
        o.bg:SetTexture(r, g, b, CATCH_BG)
        o:SetFrameLevel(fr:GetFrameLevel() + OVER_LEVEL + CLICK_ABOVE + 2)
        o._catch = true
        o:Show()
    elseif o._catch then
        o._catch = nil
        o.bg:SetTexture(0, 0, 0, OVER_BG)
        o:SetFrameLevel(fr:GetFrameLevel() + OVER_LEVEL)
        o:Hide()
    end
end
local function makeOverlay(fr)
    local o = CreateFrame("Button", nil, fr)
    o.fr = fr
    o:SetAllPoints(fr)
    o:SetFrameLevel(fr:GetFrameLevel() + OVER_LEVEL)
    o.bg = o:CreateTexture(nil, "BACKGROUND")
    o.bg:SetAllPoints(o)
    o.bg:SetTexture(0, 0, 0, OVER_BG)
    o.hl = o:CreateTexture(nil, "HIGHLIGHT")
    o.hl:SetAllPoints(o)
    o.hl:SetTexture(1, 1, 1, 0.06)
    o:EnableMouseWheel(true)
    o:RegisterForDrag("LeftButton")
    o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    o:SetScript("OnDragStart", function(self) GameTooltip:Hide(); ns.Blocks.Grab(self.fr) end)
    o:SetScript("OnDragStop", function(self) ns.Blocks.Drop(self.fr) end)
    o:SetScript("OnClick", function(self)
        local key, x, y = cellUnder(self.fr)
        if dropItem(key or self.fr._key, x, y) then return end
        openCard(self.fr)
    end)
    o:SetScript("OnReceiveDrag", function(self)
        local key, x, y = cellUnder(self.fr)
        dropItem(key or self.fr._key, x, y)
    end)
    o:SetScript("OnMouseWheel", function(self, delta)
        if InCombatLockdown() then return end
        wheelAlpha(self.fr, delta)
    end)
    o:SetScript("OnEnter", function(self) showCallout(self.fr) end)
    o:SetScript("OnLeave", function(self)
        self.fr.callout:Hide()
        hoverTo(self.fr, nil, nil, nil)
    end)
    o:SetScript("OnUpdate", function(self, elapsed)
        if self.fr._blink then stepBlink(self.fr, elapsed or 0) end
        if not self:IsMouseOver() then return end
        if #hooks.hover > 0 then hoverTo(self.fr, cellUnder(self.fr)) end
    end)
    o:Hide()
    fr.over = o
    fr.cells = {}
    fr.holes = {}
    fr.blinks = {}
    fr.sel = makeSelection(fr)
    fr.callout = makeCallout(fr)
    fr.corner = makeCorner(fr)
    fr.sizer = ns.Sizer.New(fr, {
        limits = function() return sizeLimits(fr) end,
        snap = function(w, h) return sizeSnap(fr, w, h) end,
        label = function(w, h) return ns.T("bar.size_label", cellsFor(fr, w, h)) end,
        apply = function(w, h) sizeApply(fr, w, h) end,
        paint = function(tex, role)
            local r, g, b = gold()
            tex:SetTexture(r, g, b, role == "fill" and 0.08 or 0.9)
        end,
        text = function(fs) fs:SetTextColor(gold()) end,
    })
end
local function plusTone(c, hot)
    if hot then
        local r, g, b = gold()
        tintDashes(c, r, g, b, 1)
        c.text:SetTextColor(r, g, b)
        c.text:SetAlpha(1)
        c.fill:SetVertexColor(r, g, b, HOT_FILL)
        c.fill:Show()
    else
        tintDashes(c, C_CELL[1], C_CELL[2], C_CELL[3], CELL_ALPHA)
        c.text:SetTextColor(C_CELL[1], C_CELL[2], C_CELL[3])
        c.text:SetAlpha(PLUS_ALPHA)
        c.fill:Hide()
    end
end
local function cell(fr, n)
    local c = fr.cells[n]
    if not c then
        c = CreateFrame("Button", nil, fr.over)
        c.fr = fr
        c:SetWidth(ICON)
        c:SetHeight(ICON)
        c:SetFrameLevel(fr.over:GetFrameLevel() + 1)
        c.fill = c:CreateTexture(nil, "BACKGROUND")
        c.fill:SetTexture(WHITE)
        c.fill:SetAllPoints(c)
        c.fill:Hide()
        dashes(c, ICON, ICON)
        c.text = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        c.text:SetPoint("CENTER", c, "CENTER", 0, 0)
        c.text:SetText("+")
        c:RegisterForDrag("LeftButton")
        c:SetScript("OnDragStart", function(self) GameTooltip:Hide(); ns.Blocks.Grab(self.fr) end)
        c:SetScript("OnDragStop", function(self) ns.Blocks.Drop(self.fr) end)
        c:SetScript("OnClick", function(self)
            local key = self.fr._key
            if dropItem(key, self.cx, self.cy) then return end
            if not key or locked() then return end
            for _, fn in ipairs(hooks.plus) do fn(key, self.fr, self.cx, self.cy) end
        end)
        c:SetScript("OnReceiveDrag", function(self) dropItem(self.fr._key, self.cx, self.cy) end)
        c:SetScript("OnEnter", function(self)
            plusTone(self, true)
            showCallout(self.fr)
        end)
        c:SetScript("OnLeave", function(self)
            plusTone(self, false)
            self.fr.callout:Hide()
        end)
        fr.cells[n] = c
    end
    return c
end
local function drawCells(fr)
    local b, geo = fr._block, fr._geo
    local n = 0
    if b and geo then
        local grid = ns.Blocks.Grid()
        local busy = grid.Occupy(b)
        for y = 1, b.rows do
            for x = 1, b.cols do
                if not busy[(y - 1) * b.cols + x] then
                    n = n + 1
                    local c = cell(fr, n)
                    local px, py = grid.CellXY(geo, x, y)
                    c.cx, c.cy = x, y
                    c:ClearAllPoints()
                    c:SetPoint("TOPLEFT", fr.over, "TOPLEFT", px, -py)
                    plusTone(c, c:IsMouseOver() and true or false)
                    c:Show()
                end
            end
        end
    end
    for i = n + 1, #fr.cells do fr.cells[i]:Hide() end
end
local function hole(fr, n)
    local h = fr.holes[n]
    if not h then
        h = CreateFrame("Button", nil, fr.over)
        h.fr = fr
        h:SetFrameLevel(fr.over:GetFrameLevel() + 1)
        h:EnableMouse(true)
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        h.text:SetPoint("CENTER", h, "CENTER", 0, 0)
        h.text:SetJustifyH("CENTER")
        h:RegisterForDrag("LeftButton")
        h:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        h:SetScript("OnDragStart", function(self) GameTooltip:Hide(); ns.Blocks.GrabIcon(self.fr, self.cx, self.cy) end)
        h:SetScript("OnDragStop", function(self) ns.Blocks.Drop(self.fr) end)
        h:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                openCard(self.fr)
            elseif ns.EntryCard and ns.EntryCard.Open then
                ns.EntryCard.Open(self)
            end
        end)
        h:SetScript("OnEnter", function(self) showCallout(self.fr) end)
        h:SetScript("OnLeave", function(self) self.fr.callout:Hide() end)
        fr.holes[n] = h
    end
    return h
end
local function holeCaption(item, kind)
    if kind == "want" then return ns.T("bar.want_empty") end
    if kind == "widget" then
        local w = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(item.k)
        if w and ns.Widget.Get(w) then return ns.T("bar.widget_na", ns.WidgetLabel(w)) end
        return ns.T("bar.later_item", w and ns.WidgetLabel(w) or tostring(item.k))
    end
    return nil
end
local function holeIcon(item, kind)
    local w = kind == "widget" and ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(item.k)
    local d = w and ns.Widget.Get(w)
    local icon = d and d.icon
    if type(icon) == "number" then icon = (select(3, GetSpellInfo(icon))) end
    return icon or ns.QMARK
end
local function drawHoles(fr)
    local b, geo = fr._block, fr._geo
    local n = 0
    if b and geo and ns.buffbar and ns.buffbar.IconAt then
        local grid = ns.Blocks.Grid()
        for _, item in ipairs(b.items or {}) do
            local _, kind = ns.Preset.Resolve(item)
            local caption = holeCaption(item, kind)
            if caption and not ns.buffbar:IconAt(b.key, item.x, item.y) then
                n = n + 1
                local h = hole(fr, n)
                local w, hh = grid.Size(item)
                local px, py = grid.CellXY(geo, item.x, item.y)
                local qx, qy = grid.CellXY(geo, item.x + w - 1, item.y + hh - 1)
                h.cx, h.cy = item.x, item.y
                h._key, h._cx, h._cy, h._item, h._hole = b.key, item.x, item.y, item, caption
                h._icon = holeIcon(item, kind)
                h:ClearAllPoints()
                h:SetPoint("TOPLEFT", fr.over, "TOPLEFT", px, -py)
                h:SetWidth(qx + geo.icon - px)
                h:SetHeight(qy + geo.icon - py)
                dashes(h, qx + geo.icon - px, qy + geo.icon - py)
                tintDashes(h, C_CELL[1], C_CELL[2], C_CELL[3], CELL_ALPHA)
                h.text:SetWidth(qx + geo.icon - px - 4)
                h.text:SetText(caption)
                h:Show()
            end
        end
    end
    for i = n + 1, #fr.holes do fr.holes[i]:Hide() end
end
function ns.Blocks.Dress(fr, edit)
    if not fr.over then makeOverlay(fr) end
    if edit then
        catchOn(fr, false)
        fr.over:Show()
        drawCells(fr)
        drawHoles(fr)
        fr.corner:Show()
    else
        if wantCatch() then catchOn(fr, true) else catchOn(fr, false); fr.over:Hide() end
        fr.callout:Hide()
        for _, c in ipairs(fr.cells) do c:Hide() end
        for _, h in ipairs(fr.holes) do h:Hide() end
        fr.corner:Hide()
        if fr.sizer:IsActive() then fr.sizer:Cancel() end
    end
    paintSelection(fr)
end
local SEP_ALPHA = 0.35
local SEP_INSET = 4
local DOT_PERIODS = 32
local DOTS_V = "Interface\\AddOns\\ManaCode_LazyBuffBar\\media\\dotv"
local DOTS_H = "Interface\\AddOns\\ManaCode_LazyBuffBar\\media\\doth"
ns.Blocks.SEP_COLORS = { "white", "gold", "silver", "bronze", "red", "green", "blue", "purple", "black", "class" }
ns.Blocks.SEP_KINDS = { "solid", "fade", "dots" }
ns.Blocks.SEP_LIMITS = { wMin = 1, wMax = 3, aMin = 0.1, aMax = 1, aStep = 0.05, alpha = SEP_ALPHA }
function ns.Blocks.SepLook(raw)
    raw = type(raw) == "table" and raw or {}
    local L = ns.Blocks.SEP_LIMITS
    local w = math.floor(tonumber(raw.w) or 1)
    if w < L.wMin then w = L.wMin elseif w > L.wMax then w = L.wMax end
    local a = tonumber(raw.a) or SEP_ALPHA
    if a < L.aMin then a = L.aMin elseif a > L.aMax then a = L.aMax end
    local kind = (raw.kind == "fade" or raw.kind == "dots") and raw.kind or "solid"
    return { c = raw.c, w = w, a = a, inset = raw.len == "full" and 0 or SEP_INSET, kind = kind }
end
local function sepColor(c)
    if c == "class" then
        local _, class = UnitClass("player")
        local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if cc then return cc.r, cc.g, cc.b end
    end
    local p = c and ns.Style and ns.Style.COLORS and ns.Style.COLORS[c]
    if p then return p[1], p[2], p[3] end
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local tc = (t and t.tabbar and t.tabbar.sep) or { 1, 1, 1 }
    return tc[1], tc[2], tc[3]
end
ns.Blocks.SepColor = sepColor
local function seen(f)
    return (f and f:IsShown() and (f:GetAlpha() or 1) > 0.01) and true or false
end
function ns.Blocks.SepsSeen(fr)
    for i, ln in ipairs(fr.sepLines or {}) do
        local a = (seen(ln.a) and seen(ln.b)) and 1 or 0
        local t, t2 = fr.seps[i], fr.sepsB and fr.sepsB[i]
        if t:GetAlpha() ~= a then t:SetAlpha(a) end
        if t2 and t2:IsShown() and t2:GetAlpha() ~= a then t2:SetAlpha(a) end
    end
end
function ns.Blocks.SepsTick()
    for _, fr in pairs(frames) do
        if fr.sepLines and fr.sepLines[1] and fr:IsShown() then ns.Blocks.SepsSeen(fr) end
    end
end
local function sepTex(fr, list, i)
    local t = fr[list][i]
    if not t then
        t = fr:CreateTexture(nil, "ARTWORK")
        fr[list][i] = t
    end
    return t
end
local function fadeHalf(t, vert, first, r, g, b, a)
    t:SetTexture(WHITE)
    if vert then
        if first then
            t:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, 0)
        else
            t:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, a)
        end
    elseif first then
        t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, a)
    else
        t:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, 0)
    end
end
local function paintSeps(fr)
    local look = fr.sepLook or ns.Blocks.SepLook(nil)
    local r, g, b = sepColor(look.c)
    local base = ("%s|%.3f|%.3f|%.3f|%.3f|%d"):format(look.kind, r, g, b, look.a, look.w)
    for i, ln in ipairs(fr.sepLines or {}) do
        local t = fr.seps[i]
        local vert = ln.h > ln.w
        local len = vert and ln.h or ln.w
        local key = base .. (vert and "|v" or "|h") .. len
        if t._sk ~= key then
            t._sk = key
            if look.kind == "fade" then
                fadeHalf(t, vert, true, r, g, b, look.a)
                fadeHalf(fr.sepsB[i], vert, false, r, g, b, look.a)
            elseif look.kind == "dots" then
                local n = math.min(DOT_PERIODS, math.max(1, math.floor(len / (2 * look.w) + 0.5))) / DOT_PERIODS
                t:SetTexture(vert and DOTS_V or DOTS_H)
                if vert then t:SetTexCoord(0, 1, 0, n) else t:SetTexCoord(0, n, 0, 1) end
                t:SetVertexColor(r, g, b, look.a)
            else
                t:SetTexture(WHITE)
                t:SetVertexColor(r, g, b, look.a)
            end
        end
    end
end
function ns.Blocks.Seps(fr, lines, look)
    fr.seps = fr.seps or {}
    fr.sepsB = fr.sepsB or {}
    fr.sepLines = lines or {}
    fr.sepLook = look or ns.Blocks.SepLook(nil)
    local fade = fr.sepLook.kind == "fade"
    for i, ln in ipairs(fr.sepLines) do
        local t = sepTex(fr, "seps", i)
        local vert = ln.h > ln.w
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", fr, "TOPLEFT", ln.l, -ln.t)
        if fade then
            local t2 = sepTex(fr, "sepsB", i)
            local half = math.floor((vert and ln.h or ln.w) / 2)
            t:SetWidth(vert and ln.w or half)
            t:SetHeight(vert and half or ln.h)
            t2:ClearAllPoints()
            t2:SetPoint("TOPLEFT", fr, "TOPLEFT", ln.l + (vert and 0 or half), -(ln.t + (vert and half or 0)))
            t2:SetWidth(vert and ln.w or ln.w - half)
            t2:SetHeight(vert and ln.h - half or ln.h)
            t2:Show()
        else
            t:SetWidth(ln.w)
            t:SetHeight(ln.h)
            if fr.sepsB[i] then fr.sepsB[i]:Hide() end
        end
        t:Show()
    end
    for i = #fr.sepLines + 1, #fr.seps do fr.seps[i]:Hide() end
    for i = #fr.sepLines + 1, #fr.sepsB do fr.sepsB[i]:Hide() end
    paintSeps(fr)
    ns.Blocks.SepsSeen(fr)
end
function ns.Blocks.SepsTint(fr)
    if fr.sepLines and fr.sepLines[1] then paintSeps(fr) end
end
local function styleFrame(fr)
    fr:SetMovable(true)
    fr:EnableMouse(true)
    fr:SetClampedToScreen(true)
    fr:RegisterForDrag("LeftButton")
    fr:SetScript("OnDragStart", ns.Blocks.Grab)
    fr:SetScript("OnDragStop", ns.Blocks.Drop)
    fr:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then openCard(self) end
    end)
    fr:SetScript("OnMouseWheel", wheelAlpha)
    fr:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
function ns.Blocks.FrameAt(i)
    local fr = frames[i]
    if not fr then
        fr = CreateFrame("Frame", i == 1 and "LazyBuffBar" or ("LazyBuffBar" .. i), UIParent)
        ns.Layer(fr, "panel")
        fr._barIndex = i
        styleFrame(fr)
        frames[i] = fr
        if ns.buffbar and ns.buffbar.ApplyTheme then ns.buffbar:ApplyTheme() end
    end
    return fr
end
function ns.Blocks.Root()
    return ns.Blocks.FrameAt(1)
end
function ns.Blocks.Frames()
    return frames
end
function ns.Blocks.Drive(fr, macro)
    if fr._driver == macro then return end
    fr._driver = macro
    if macro then RegisterStateDriver(fr, "visibility", macro) else UnregisterStateDriver(fr, "visibility") end
end
function ns.Blocks.HideFrom(n)
    for i = n, #frames do
        if frames[i] then
            ns.Blocks.Drive(frames[i], nil)
            frames[i]:Hide()
            if frames[i]._key then byKey[frames[i]._key] = nil end
            frames[i]._key, frames[i]._block = nil, nil
        end
    end
end
function ns.Blocks.Bind(fr, i, block, geo)
    if fr._key and byKey[fr._key] == fr and fr._key ~= block.key then byKey[fr._key] = nil end
    fr._barIndex, fr._key, fr._block, fr._geo = i, block.key, block, geo
    byKey[block.key] = fr
end
function ns.Blocks.Unbind(fr)
    if fr._key and byKey[fr._key] == fr then byKey[fr._key] = nil end
    fr._key, fr._block = nil, nil
end
function ns.Blocks.Frame(key)
    return byKey[key]
end
function ns.Blocks.Block(key)
    local fr = byKey[key]
    return fr and fr._block or nil
end
function ns.Blocks.Geo(key)
    local fr = byKey[key]
    return fr and fr._geo or nil
end
function ns.Blocks.Rect(key)
    local fr = byKey[key]
    return fr and rectOf(fr) or nil
end
function ns.Blocks.Each()
    local k
    return function()
        local v
        k, v = next(byKey, k)
        return k, v
    end
end
function ns.Blocks.Rects()
    local _, rs = others(nil)
    return rs
end
function ns.Blocks.NewAt(item, px, py)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return nil
    end
    return ns.buffbar:NewBlock(item, { l = px, t = py })
end
function ns.Blocks.OnHover(fn) hooks.hover[#hooks.hover + 1] = fn end
function ns.Blocks.OnGrab(fn) hooks.grab[#hooks.grab + 1] = fn end
function ns.Blocks.OnPlus(fn) hooks.plus[#hooks.plus + 1] = fn end
function ns.Blocks.PlusAt(key, x, y)
    local fr = byKey[key]
    if not (fr and fr.cells) then return nil end
    for _, c in ipairs(fr.cells) do
        if c:IsShown() and c.cx == x and c.cy == y then return c end
    end
    return nil
end
function ns.Blocks.Holes(key)
    local fr = byKey[key]
    local out = {}
    for _, h in ipairs(fr and fr.holes or {}) do
        if h:IsShown() then out[#out + 1] = h end
    end
    return out
end
function ns.Blocks.HoleAt(key, x, y)
    local fr = byKey[key]
    if not (fr and fr.holes and x and y) then return nil end
    local grid = ns.Blocks.Grid()
    for _, h in ipairs(fr.holes) do
        if h:IsShown() and h._item then
            local w, hh = grid.Size(h._item)
            if x >= h._cx and x < h._cx + w and y >= h._cy and y < h._cy + hh then return h end
        end
    end
    return nil
end
function ns.Blocks.OnItemDrop(fn) hooks.drop[#hooks.drop + 1] = fn end
function ns.Blocks.DropItem(key, x, y)
    return dropItem(key, x, y)
end
function ns.Blocks.Catching(key)
    local fr = byKey[key]
    return (fr and fr.over and fr.over._catch and fr.over:IsShown()) and true or false
end
local cursor = CreateFrame("Frame")
cursor:RegisterEvent("CURSOR_UPDATE")
cursor:RegisterEvent("PLAYER_REGEN_DISABLED")
cursor:RegisterEvent("PLAYER_REGEN_ENABLED")
cursor:SetScript("OnEvent", function()
    if not locked() then return end
    local on = wantCatch()
    for _, fr in pairs(byKey) do
        if fr.over or on then
            if not fr.over then makeOverlay(fr) end
            catchOn(fr, on and fr:IsShown() and true or false)
        end
    end
end)
ns.blocksLoaded = true

local ADDON, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BTN_H = 22
local BTN_PAD = 24
local painters = {}
function ns.OnTheme(fn)
    painters[#painters + 1] = fn
end
function ns.RepaintTheme()
    for i = 1, #painters do painters[i]() end
end
function ns.SkinKey()
    return ns.window and ns.window:GetSkin()
end
function ns.SetSkin(key)
    if not (ns.themes and ns.themes[key]) then return end
    LazyBuffBarDB = LazyBuffBarDB or {}
    if LazyBuffBarDB.skin == key then return end
    LazyBuffBarDB.skin = key
    if ns.buffbar and ns.buffbar.ApplyTheme then
        ns.buffbar:ApplyTheme()
        ns.buffbar:Update()
    end
    ns.RepaintTheme()
end
function ns.Edge()
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local c = (t and t.tabbar and t.tabbar.underline) or { 1, 0.82, 0 }
    return c[1], c[2], c[3]
end
local C_TITLE = { 1, 1, 1 }
local C_BODY  = { 1, 0.82, 0 }
local C_DIM   = { 0.62, 0.62, 0.62 }
local function ownText(f)
    if f.text and f.text.GetText then return f.text:GetText() end
    if f.label and f.label.GetText then return f.label:GetText() end
    if f.GetText then return f:GetText() end
    return nil
end
function ns.TipShow(f)
    local body = f.tip
    local title = f.tipTitle
    if title == nil then title = ownText(f) end
    if title == false or title == "" then title = nil end
    if title and body and title == body then body = nil end
    if not title and not body and not f.tipDim then return end
    GameTooltip:SetOwner(f, f.tipAnchor or "ANCHOR_RIGHT")
    local first = true
    local function line(text, c)
        if first then
            GameTooltip:SetText(text, c[1], c[2], c[3], 1, true)
            first = false
        else
            GameTooltip:AddLine(text, c[1], c[2], c[3], true)
        end
    end
    if title then line(title, f.tipColor or C_TITLE) end
    if body then line(body, C_BODY) end
    if f.tipDim then line(f.tipDim, C_DIM) end
    GameTooltip:Show()
end
function ns.TipHide()
    GameTooltip:Hide()
end
function ns.ApplyDecor(frame, t)
    if not frame then return end
    local pool = frame.kitDecor
    if not pool then pool = {}; frame.kitDecor = pool end
    for _, tx in ipairs(pool) do tx:Hide() end
    local list = t and t.window and t.window.decor
    if not list then return end
    local n = 0
    local function take()
        n = n + 1
        local tx = pool[n]
        if not tx then
            tx = frame:CreateTexture(nil, "ARTWORK")
            pool[n] = tx
        end
        return tx
    end
    local function paint(tx, d)
        tx:SetTexture(d.tex or WHITE)
        tx:SetDrawLayer("ARTWORK")
        if d.grad then
            local g = d.grad
            local from, to = g.from, g.to
            tx:SetGradientAlpha(g.dir or "VERTICAL",
                                from[1], from[2], from[3], from[4],
                                to[1], to[2], to[3], to[4])
        elseif d.color then
            tx:SetVertexColor(d.color[1], d.color[2], d.color[3])
        else
            tx:SetVertexColor(1, 1, 1)
        end
        tx:SetAlpha(d.alpha or 1)
        tx:SetBlendMode(d.blend or "BLEND")
        tx:ClearAllPoints()
    end
    local function coords(tx, d, frac)
        local c = d.coord
        local l, r, top, bot = 0, 1, 0, 1
        if c then l, r, top, bot = c[1], c[2], c[3], c[4] end
        if frac and frac < 1 then bot = top + (bot - top) * frac end
        tx:SetTexCoord(l, r, top, bot)
    end
    local fw = frame:GetWidth() or 0
    local fh = frame:GetHeight() or 0
    for _, d in ipairs(list) do
        local pad = d.inset or 0
        if d.tile then
            local cell = d.tile
            local aw, ah = fw - pad * 2, fh - pad * 2
            local cols, rows = math.ceil(aw / cell), math.ceil(ah / cell)
            if cols < 1 then cols = 1 end
            if rows < 1 then rows = 1 end
            if cols * rows > 60 then rows = math.max(1, math.floor(60 / cols)) end
            local c = d.coord or { 0, 1, 0, 1 }
            for ky = 0, rows - 1 do
                local hh = math.min(cell, ah - ky * cell)
                for kx = 0, cols - 1 do
                    local ww = math.min(cell, aw - kx * cell)
                    if ww > 0 and hh > 0 then
                        local tx = take()
                        paint(tx, d)
                        tx:SetTexCoord(c[1], c[1] + (c[2] - c[1]) * ww / cell,
                                       c[3], c[3] + (c[4] - c[3]) * hh / cell)
                        tx:SetWidth(ww); tx:SetHeight(hh)
                        tx:SetPoint("TOPLEFT", frame, "TOPLEFT",
                                    pad + kx * cell, -(pad + ky * cell))
                        tx:Show()
                    end
                end
            end
        elseif d.tileY or d.tileAspect then
            local band = d.tileAspect and math.floor((fw - pad * 2) * d.tileAspect) or d.tileY
            if not band or band < 8 then band = 64 end
            local avail = fh - pad * 2
            local rows = math.ceil(avail / band)
            if rows < 1 then rows = 1 end
            if rows > 40 then rows = 40 end
            for k = 0, rows - 1 do
                local left = avail - k * band
                local hh = (left < band) and left or band
                if hh > 0 then
                    local tx = take()
                    paint(tx, d)
                    coords(tx, d, hh / band)
                    tx:SetWidth(fw - pad * 2); tx:SetHeight(hh)
                    tx:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -(pad + k * band))
                    tx:Show()
                end
            end
        else
            local tx = take()
            paint(tx, d)
            coords(tx, d)
            if d.h then
                tx:SetWidth(fw - pad * 2); tx:SetHeight(d.h)
                tx:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -(d.y or pad))
            else
                tx:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
                tx:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)
            end
            tx:Show()
        end
    end
end
local BTN_FALLBACK = {
    backdrop = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    },
    bg = { 0, 0, 0, 0.7 }, bgHover = { 0, 0, 0, 0.45 },
    bgActive = { 0.1, 0.3, 0.15, 0.95 }, bgOff = { 0, 0, 0, 0.75 },
    border = { 1, 0.82, 0, 0.65 }, borderHover = { 1, 0.82, 0, 1 },
    borderActive = { 1, 0.82, 0, 1 }, borderOff = { 0.45, 0.45, 0.45, 0.6 },
    text = { 0.75, 0.75, 0.75 }, textHover = { 1, 1, 1 },
    textActive = { 1, 1, 1 }, textOff = { 0.45, 0.45, 0.45 },
}
local function buttonSkin()
    local t = ns.CurrentTheme and ns.CurrentTheme()
    return (t and t.button) or BTN_FALLBACK
end
local function styleButton(b)
    local bt = buttonSkin()
    local bg, br, tc
    if b.btnDisabled and b.active then
        bg, br, tc = bt.bgActive, bt.borderActive, bt.textOff
    elseif b.btnDisabled then
        bg, br, tc = bt.bgOff, bt.borderOff, bt.textOff
    elseif b.active then
        bg, br, tc = bt.bgActive, bt.borderActive, bt.textActive
    elseif b.hovered then
        bg, br, tc = bt.bgHover, bt.borderHover, bt.textHover
    else
        bg, br, tc = bt.bg, bt.border, bt.text
    end
    b:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    b:SetBackdropBorderColor(br[1], br[2], br[3], br[4] or 1)
    b.text:SetTextColor(tc[1], tc[2], tc[3])
end
ns.StyleButton = styleButton
local buttons = {}
function ns.MakeButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(BTN_H)
    b:SetBackdrop(buttonSkin().backdrop)
    buttons[#buttons + 1] = b
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetFontString(b.text)
    b:SetPushedTextOffset(1, -1)
    function b:SetLabel(label)
        self.text:SetText(label)
        self:SetWidth(self.text:GetStringWidth() + BTN_PAD)
    end
    function b:SetActive(on)
        self.active = on and true or false
        styleButton(self)
    end
    function b:Enable()
        self.btnDisabled = nil
        styleButton(self)
    end
    function b:Disable()
        self.btnDisabled = true
        styleButton(self)
    end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        styleButton(self)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = false
        styleButton(self)
        ns.TipHide()
    end)
    b:SetScript("OnClick", function(self, button)
        if self.btnDisabled then return end
        if self.onClick then self.onClick(self, button) end
    end)
    styleButton(b)
    return b
end
local PANEL_FALLBACK = {
    backdrop = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    },
    bgColor = { 0, 0, 0, 0.6 }, borderColor = { 1, 1, 1, 1 },
}
local panels = {}
local function paintPanel(p)
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local th = (t and t.panel) or PANEL_FALLBACK
    p:SetBackdrop(th.backdrop or PANEL_FALLBACK.backdrop)
    local c = th.bgColor or PANEL_FALLBACK.bgColor
    local e = th.borderColor or PANEL_FALLBACK.borderColor
    p:SetBackdropColor(c[1], c[2], c[3], c[4] or 1)
    p:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
    if p.cap then p.cap:SetTextColor(ns.Edge()) end
end
ns.PaintPanel = paintPanel
function ns.MakePanel(parent, caption)
    local p = CreateFrame("Frame", nil, parent)
    panels[#panels + 1] = p
    if caption then
        p.cap = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        p.cap:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -9)
        p.cap:SetText(caption)
    end
    paintPanel(p)
    return p
end
local WIN_FALLBACK = {
    backdrop = {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    },
    bgColor = { 1, 1, 1, 1 }, borderColor = { 1, 1, 1, 1 },
}
local windows = {}
local function paintWindow(f)
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local th = (t and t.window) or WIN_FALLBACK
    f:SetBackdrop(th.backdrop or WIN_FALLBACK.backdrop)
    local c = th.bgColor or WIN_FALLBACK.bgColor
    local e = th.borderColor or WIN_FALLBACK.borderColor
    f:SetBackdropColor(c[1], c[2], c[3], c[4] or 1)
    f:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
    ns.ApplyDecor(f, t)
    if f.title then f.title:SetTextColor(ns.Edge()) end
end
ns.PaintWindow = paintWindow
function ns.MakeWindow(name, title)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, name)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetText(title)
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    windows[#windows + 1] = f
    paintWindow(f)
    f:Hide()
    return f
end
ns.OnTheme(function()
    for i = 1, #buttons do
        buttons[i]:SetBackdrop(buttonSkin().backdrop)
        styleButton(buttons[i])
    end
    for i = 1, #panels do paintPanel(panels[i]) end
    for i = 1, #windows do paintWindow(windows[i]) end
end)
ns.kitLoaded = true

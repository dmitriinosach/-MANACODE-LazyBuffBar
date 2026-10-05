local ADDON, ns = ...
ns.Chrome = {}
local BTN = 18
local BTN_GAP = 3
local GAP = 6
local PAD = 6
local TICK = 0.15
local FADE = 0.15
local GEAR = "Interface\\Icons\\INV_Misc_Gear_01"
local LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
local LOCK_COORD = { 0, 0.6875, 0, 0.84375 }
local groups = {}
local watcher
local acc = 0
local wasLocked
local function locked()
    return ns.buffbar and ns.buffbar:IsLocked() and true or false
end
local function tip(b, titleKey, tipKey)
    b.tipTitle = ns.T(titleKey)
    b.tip = ns.T(tipKey)
end
local function paintButton(b)
    if b.hovered then
        b.bg:SetTexture(1, 1, 1, 0.25)
    else
        b.bg:SetTexture(0, 0, 0, 0.4)
    end
end
local function iconButton(parent, texture, coord)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(BTN)
    b:SetHeight(BTN)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints(b)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.tex:SetTexture(texture)
    if coord then
        b.tex:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
    else
        b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        paintButton(self)
        ns.TipShow(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = false
        paintButton(self)
        ns.TipHide()
    end)
    paintButton(b)
    return b
end
local function edges(frame)
    local l, r = frame:GetLeft(), frame:GetRight()
    local b, t = frame:GetBottom(), frame:GetTop()
    if not l or not r or not b or not t then return nil, nil, nil, nil end
    local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return l * k, r * k, b * k, t * k
end
local function cursorOver(g, frame)
    local l, r, b, t = edges(frame)
    if not l then return false end
    local reach = g.tools:GetWidth() + GAP
    local padL = g.side < 0 and reach or PAD
    local padR = g.side > 0 and reach or PAD
    local scale = UIParent:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    mx, my = mx / scale, my / scale
    return mx >= l - padL and mx <= r + padR and my >= b - PAD and my <= t + PAD
end
local function place(g, frame)
    local l, r = edges(frame)
    local reach = g.tools:GetWidth() + GAP
    local toLeft = true
    if l and r then
        if l - reach < 0 then
            toLeft = false
        elseif r + reach > UIParent:GetWidth() then
            toLeft = true
        end
    end
    g.tools:ClearAllPoints()
    if toLeft then
        g.tools:SetPoint("RIGHT", frame, "LEFT", -GAP, 0)
    else
        g.tools:SetPoint("LEFT", frame, "RIGHT", GAP, 0)
    end
    g.side = toLeft and -1 or 1
end
local function show(g, on)
    if g.shown == on then return end
    g.shown = on
    if on then g.tools:Show() end
end
local function dress(g)
    local on = locked()
    g.lock.tex:SetDesaturated(not on)
    tip(g.lock, on and "chrome.unlock" or "chrome.lock",
        on and "chrome.unlock_tip" or "chrome.lock_tip")
end
local function shape(frame)
    local l, r, b, t = edges(frame)
    if not l then return "?" end
    return string.format("%d:%d:%d:%d", l, r, b, t)
end
local function build(id)
    local g = groups[id]
    if g then return g end
    g = { side = -1, shown = false, alpha = 0, shape = "" }
    g.tools = CreateFrame("Frame", nil, UIParent)
    g.tools:SetHeight(BTN)
    g.tools:SetWidth(BTN * 2 + BTN_GAP)
    g.tools:SetFrameStrata("HIGH")
    g.tools:SetAlpha(0)
    g.tools:Hide()
    local gear = iconButton(g.tools, GEAR)
    gear:SetPoint("LEFT", g.tools, "LEFT", 0, 0)
    gear:SetScript("OnClick", function()
        if ns.Settings then ns.Settings.Toggle() end
    end)
    tip(gear, "chrome.settings", "chrome.settings_tip")
    g.lock = iconButton(g.tools, LOCK, LOCK_COORD)
    g.lock:SetPoint("LEFT", gear, "RIGHT", BTN_GAP, 0)
    g.lock:SetScript("OnClick", function()
        if not ns.buffbar then return end
        ns.buffbar:SetLocked(not locked())
        ns.Chrome.Apply()
        if ns.Settings then ns.Settings.Refresh() end
    end)
    dress(g)
    groups[id] = g
    return g
end
local function panels()
    if not (ns.buffbar and ns.buffbar.Panels) then return {} end
    return ns.buffbar:Panels()
end
local function update(g, frame, isLocked)
    local now = shape(frame)
    if now ~= g.shape then
        g.shape = now
        place(g, frame)
    end
    show(g, (not isLocked) or cursorOver(g, frame))
end
local function fade(elapsed)
    local step = elapsed / FADE
    for _, g in pairs(groups) do
        local want = g.shown and 1 or 0
        if g.alpha ~= want then
            if g.alpha < want then
                g.alpha = math.min(want, g.alpha + step)
            else
                g.alpha = math.max(want, g.alpha - step)
            end
            g.tools:SetAlpha(g.alpha)
            if g.alpha <= 0 then g.tools:Hide() end
        end
    end
end
local function watch(self, elapsed)
    fade(elapsed)
    acc = acc + elapsed
    if acc < TICK then return end
    acc = 0
    local isLocked = locked()
    local flipped = isLocked ~= wasLocked
    wasLocked = isLocked
    local live = {}
    for _, p in ipairs(panels()) do
        local g = build(p.id)
        if flipped then dress(g) end
        update(g, p.frame, isLocked)
        live[p.id] = true
    end
    for id, g in pairs(groups) do
        if not live[id] then show(g, false) end
    end
end
function ns.Chrome.Apply()
    local isLocked = locked()
    wasLocked = isLocked
    local live = {}
    for _, p in ipairs(panels()) do
        local g = build(p.id)
        dress(g)
        place(g, p.frame)
        g.shape = shape(p.frame)
        show(g, (not isLocked) or cursorOver(g, p.frame))
        live[p.id] = true
    end
    for id, g in pairs(groups) do
        if not live[id] then show(g, false) end
    end
end
function ns.Chrome.Init()
    if watcher then
        ns.Chrome.Apply()
        return
    end
    watcher = CreateFrame("Frame")
    watcher:SetScript("OnUpdate", watch)
    ns.Chrome.Apply()
end
ns.chromeLoaded = true

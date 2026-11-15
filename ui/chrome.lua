local _, ns = ...
ns.Chrome = {}
local BTN = 18
local BTN_GAP = 3
local GAP = 7
local TOOLS_MIN, TOOLS_MAX = 0.8, 1.6
local PAD = 6
local TICK = 0.15
local FADE = 0.15
local UNDO_SECS = 10
local UNDO_GAP = 4
local GEAR = "Interface\\Icons\\INV_Misc_Gear_01"
local LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
local LOCK_COORD = { 0, 0.6875, 0, 0.84375 }
local DEL = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local INSET = 2
local MOVE_SZ = BTN - INSET * 2
local groups = {}
local spare = {}
local watcher
local acc = 0
local wasLocked
local undo
local undoBtn
local function locked()
    return ns.buffbar and ns.buffbar:IsLocked() and true or false
end
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
function ns.Chrome.MinimapShown()
    return db().minimap ~= false
end
function ns.Chrome.SetMinimapShown(on)
    if on then db().minimap = nil else db().minimap = false end
    ns.Chrome.Apply()
end
local MM_SIZE = 31
local MM_ANGLE = 225
local mm
local ROUND_QUARTERS = {
    ["ROUND"]                 = { true,  true,  true,  true  },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPRIGHT"]       = { true,  false, false, false },
    ["CORNER-TOPLEFT"]        = { false, true,  false, false },
    ["CORNER-BOTTOMLEFT"]     = { false, false, true,  false },
    ["CORNER-BOTTOMRIGHT"]    = { false, false, false, true  },
    ["SIDE-LEFT"]             = { false, true,  true,  false },
    ["SIDE-RIGHT"]            = { true,  false, false, true  },
    ["SIDE-TOP"]              = { true,  true,  false, false },
    ["SIDE-BOTTOM"]           = { false, false, true,  true  },
    ["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true  },
    ["TRICORNER-TOPLEFT"]     = { false, true,  true,  true  },
    ["TRICORNER-BOTTOMRIGHT"] = { true,  true,  false, true  },
    ["TRICORNER-BOTTOMLEFT"]  = { true,  true,  true,  false },
}
local function mmPlace()
    local angle = math.rad(db().minimapAngle or MM_ANGLE)
    local cos, sin = math.cos(angle), math.sin(angle)
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local q = (cos >= 0) and (sin >= 0 and 1 or 4) or (sin >= 0 and 2 or 3)
    local round = (ROUND_QUARTERS[shape] or ROUND_QUARTERS.ROUND)[q]
    local x, y
    if round then
        x, y = cos * 80, sin * 80
    else
        x = math.max(-82, math.min(110 * cos, 84))
        y = math.max(-86, math.min(110 * sin, 82))
    end
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
local function mmTip(self)
    if self.dragging then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(ns.T("chrome.mm_title"), 1, 1, 1)
    GameTooltip:AddLine(ns.T(locked() and "chrome.mm_unlock" or "chrome.mm_lock"), 1, 0.82, 0)
    GameTooltip:AddLine(ns.T("chrome.mm_settings"), 1, 0.82, 0)
    GameTooltip:AddLine(ns.T("chrome.mm_drag"), 0.6, 0.6, 0.6)
    GameTooltip:Show()
end
local function mmDrag()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    db().minimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
    mmPlace()
end
local function buildMinimap()
    if mm or not Minimap then return end
    mm = CreateFrame("Button", "LazyBuffBarMinimapButton", Minimap)
    ns.Layer(mm, "minimap")
    mm:SetWidth(MM_SIZE)
    mm:SetHeight(MM_SIZE)
    mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mm:RegisterForDrag("LeftButton")
    mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local ring = mm:CreateTexture(nil, "OVERLAY")
    ring:SetWidth(53)
    ring:SetHeight(53)
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetPoint("TOPLEFT", mm, "TOPLEFT", 0, 0)
    mm.icon = mm:CreateTexture(nil, "BACKGROUND")
    mm.icon:SetWidth(20)
    mm.icon:SetHeight(20)
    mm.icon:SetTexture(GEAR)
    mm.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    mm.icon:SetPoint("TOPLEFT", mm, "TOPLEFT", 7, -5)
    mm:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if ns.Options then ns.Options.Toggle() end
        elseif ns.buffbar then
            ns.buffbar:SetLocked(not locked())
            ns.Chrome.Apply()
            if ns.Options then ns.Options.Refresh() end
        end
        mmTip(self)
    end)
    mm:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:LockHighlight()
        GameTooltip:Hide()
        self:SetScript("OnUpdate", mmDrag)
    end)
    mm:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)
    mm:SetScript("OnEnter", mmTip)
    mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local function tip(b, titleKey, tipKey)
    b.tipTitle = ns.T(titleKey)
    b.tip = ns.T(tipKey)
end
local function paintButton(b)
    local e = ns.EDIT
    if b.hovered and not b.off then
        b:SetBackdropColor(1, 1, 1, 0.12)
        b:SetBackdropBorderColor(e.border[1], e.border[2], e.border[3], 1)
    else
        b:SetBackdropColor(0, 0, 0, 0.6)
        b:SetBackdropBorderColor(e.line[1], e.line[2], e.line[3], 1)
    end
    if b.tex then
        b.tex:SetDesaturated(b.off and true or false)
        b.tex:SetAlpha(b.off and 0.4 or 1)
    end
    local c = (b.hovered and not b.off) and e.gold or e.text
    for _, t in ipairs(b.marks or {}) do
        t:SetVertexColor(c[1], c[2], c[3], 1)
        t:SetAlpha(b.off and 0.4 or 1)
    end
end
local function drawMove(b)
    local marks = {}
    local function mark(x, y, w, h)
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        t:SetWidth(w)
        t:SetHeight(h)
        t:SetPoint("TOPLEFT", b, "TOPLEFT", INSET + x, -(INSET + y))
        marks[#marks + 1] = t
    end
    local mid = MOVE_SZ / 2
    mark(3, mid - 1, MOVE_SZ - 6, 2)
    mark(mid - 1, 3, 2, MOVE_SZ - 6)
    for i, w in ipairs({ 2, 4, 6 }) do
        local o = mid - w / 2
        mark(o, i - 1, w, 1)
        mark(o, MOVE_SZ - i, w, 1)
        mark(i - 1, o, 1, w)
        mark(MOVE_SZ - i, o, 1, w)
    end
    b.marks = marks
end
local function iconButton(parent, texture, coord)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(BTN)
    b:SetHeight(BTN)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
                    insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    if texture then
        b.tex = b:CreateTexture(nil, "ARTWORK")
        b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", INSET, -INSET)
        b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -INSET, INSET)
        b.tex:SetTexture(texture)
        if coord then
            b.tex:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
        else
            b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
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
    local ui = UIParent:GetEffectiveScale() or 1
    local ratio = (frame:GetEffectiveScale() or ui) / ui
    g.tools:SetScale(math.max(TOOLS_MIN, math.min(TOOLS_MAX, ratio)))
    g.tools:ClearAllPoints()
    if toLeft then
        g.tools:SetPoint("TOPRIGHT", frame, "TOPLEFT", -GAP, 0)
    else
        g.tools:SetPoint("TOPLEFT", frame, "TOPRIGHT", GAP, 0)
    end
    g.side = toLeft and -1 or 1
    local anchor = toLeft and "ANCHOR_LEFT" or "ANCHOR_RIGHT"
    for _, b in ipairs({ g.move, g.lock, g.gear, g.del }) do
        if b then b.tipAnchor = anchor end
    end
end
local function show(g, on)
    if g.shown == on then return end
    g.shown = on
    if on then g.tools:Show() end
end
local function lastPanel()
    return #(ns.Preset and ns.Preset.Blocks and ns.Preset.Blocks() or {}) < 2
end
local function dress(g)
    local on = locked()
    g.lock.tex:SetDesaturated(not on)
    tip(g.lock, on and "chrome.unlock" or "chrome.lock",
        on and "chrome.unlock_tip" or "chrome.lock_tip")
    g.lock:ClearAllPoints()
    g.gear:ClearAllPoints()
    if on then
        g.move:Hide()
        g.del:Hide()
        g.lock:SetPoint("TOPLEFT", g.tools, "TOPLEFT", 0, 0)
        g.gear:SetPoint("TOPLEFT", g.tools, "TOPLEFT", 0, -(BTN + BTN_GAP))
        g.tools:SetWidth(BTN)
        g.tools:SetHeight(BTN * 2 + BTN_GAP)
    else
        g.move:Show()
        g.del:Show()
        g.lock:SetPoint("TOPLEFT", g.tools, "TOPLEFT", BTN + BTN_GAP, 0)
        g.gear:SetPoint("TOPLEFT", g.tools, "TOPLEFT", 0, -(BTN + BTN_GAP))
        g.tools:SetWidth(BTN * 2 + BTN_GAP)
        g.tools:SetHeight(BTN * 2 + BTN_GAP)
        g.del.off = lastPanel()
        tip(g.del, "chrome.remove", g.del.off and "chrome.remove_last" or "chrome.remove_tip")
        paintButton(g.del)
    end
end
local function hideUndo()
    undo = nil
    if undoBtn then undoBtn:Hide() end
end
local function undoStale(u)
    if GetTime() - u.at > UNDO_SECS then return true end
    if ns.Preset.Edits() ~= u.edits or ns.Preset.Id() ~= u.id then return true end
    return locked()
end
local function undoTick(b)
    local u = undo
    if not u then b:Hide(); return end
    if undoStale(u) then hideUndo() end
end
local function undoNow()
    local u = undo
    if not u then return end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return
    end
    hideUndo()
    if ns.Preset.PutBlock(u.snap) then ns.Chrome.Apply() end
end
local function makeUndo()
    local b = ns.MakeButton(UIParent)
    ns.Layer(b, "undo")
    b:SetLabel(ns.T("reorder.undo"))
    b.tipTitle = ns.T("chrome.undo_tip")
    b.onClick = undoNow
    b:SetScript("OnUpdate", undoTick)
    b:Hide()
    return b
end
local function remove(g)
    local id, fr = g.id, g.frame
    if not id or locked() then return end
    if g.del.off then
        if ns.say then ns.say(ns.T("chrome.remove_last")) end
        return
    end
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return
    end
    local l, _, _, t = edges(fr)
    local snap = ns.Preset.TakeBlock(id)
    if not snap then return end
    if ns.PanelCard and ns.PanelCard.CurrentId and ns.PanelCard.CurrentId() == id then ns.PanelCard.Close() end
    undoBtn = undoBtn or makeUndo()
    undo = { snap = snap, at = GetTime(), x = l or 0, y = t or 0, edits = ns.Preset.Edits(), id = ns.Preset.Id() }
    undoBtn:ClearAllPoints()
    undoBtn:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", undo.x, undo.y)
    undoBtn:Show()
    ns.Chrome.Apply()
end
local function shape(frame)
    local l, r, b, t = edges(frame)
    if not l then return "?" end
    return string.format("%d:%d:%d:%d", l, r, b, t)
end
local function build(id)
    local g = groups[id]
    if g then return g end
    g = tremove(spare)
    if g then
        g.shape, g.frame, g.id = "", nil, id
        dress(g)
        groups[id] = g
        return g
    end
    g = { side = -1, shown = false, alpha = 0, shape = "", id = id }
    g.tools = CreateFrame("Frame", nil, UIParent)
    g.tools:SetHeight(BTN * 2 + BTN_GAP)
    g.tools:SetWidth(BTN * 2 + BTN_GAP)
    ns.Layer(g.tools, "chrome")
    g.tools:SetAlpha(0)
    g.tools:Hide()
    g.move = iconButton(g.tools, nil)
    drawMove(g.move)
    paintButton(g.move)
    g.move:SetPoint("TOPLEFT", g.tools, "TOPLEFT", 0, 0)
    g.move:RegisterForDrag("LeftButton")
    g.move:SetScript("OnDragStart", function()
        if g.frame then
            GameTooltip:Hide()
            ns.Blocks.GrabPanel(g.frame)
        end
    end)
    g.move:SetScript("OnDragStop", function()
        if g.frame then ns.Blocks.Drop(g.frame) end
    end)
    tip(g.move, "chrome.move", "chrome.move_tip")
    g.lock = iconButton(g.tools, LOCK, LOCK_COORD)
    g.lock:SetScript("OnClick", function()
        if not ns.buffbar then return end
        ns.buffbar:SetLocked(not locked())
        ns.Chrome.Apply()
        if ns.Options then ns.Options.Refresh() end
    end)
    g.gear = iconButton(g.tools, GEAR)
    g.gear:SetScript("OnClick", function()
        if ns.PanelCard and g.id then
            ns.PanelCard.Open(g.id, g.frame)
        elseif ns.Options then
            ns.Options.Toggle()
        end
    end)
    tip(g.gear, "chrome.settings", "chrome.settings_tip")
    g.del = iconButton(g.tools, DEL)
    g.del:SetPoint("TOPLEFT", g.tools, "TOPLEFT", BTN + BTN_GAP, -(BTN + BTN_GAP))
    g.del:SetScript("OnClick", function() remove(g) end)
    tip(g.del, "chrome.remove", "chrome.remove_tip")
    dress(g)
    groups[id] = g
    return g
end
local function sweep(live)
    for id, g in pairs(groups) do
        if not live[id] then
            if ns.buffbar and ns.buffbar.BarIndex and not ns.buffbar:BarIndex(id) then
                groups[id] = nil
                g.shown, g.alpha, g.frame = false, 0, nil
                g.tools:SetAlpha(0)
                g.tools:Hide()
                spare[#spare + 1] = g
            else
                show(g, false)
            end
        end
    end
end
function ns.Chrome.Group(id)
    return groups[id] and groups[id].tools
end
function ns.Chrome.Tools(id)
    local g = groups[id]
    return g and { move = g.move, lock = g.lock, gear = g.gear, del = g.del } or nil
end
function ns.Chrome.RemovePanel(id)
    local g = groups[id]
    if g then remove(g) end
end
function ns.Chrome.Undo()
    return undo, undoBtn
end
function ns.Chrome.UndoNow()
    if not undo then return false end
    undoNow()
    return undo == nil
end
local function panels()
    if not (ns.buffbar and ns.buffbar.Panels) then return {} end
    return ns.buffbar:Panels()
end
local function wanted(g, frame, isLocked)
    return (not isLocked) or cursorOver(g, frame)
end
local function update(g, frame, isLocked)
    local now = shape(frame)
    if now ~= g.shape or g.frame ~= frame then
        g.shape, g.frame = now, frame
        place(g, frame)
    end
    show(g, wanted(g, frame, isLocked))
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
    sweep(live)
end
function ns.Chrome.Apply()
    local isLocked = locked()
    wasLocked = isLocked
    if ns.EditBar then ns.EditBar.Apply() end
    local live = {}
    for _, p in ipairs(panels()) do
        local g = build(p.id)
        dress(g)
        place(g, p.frame)
        g.shape, g.frame, g.id = shape(p.frame), p.frame, p.id
        show(g, wanted(g, p.frame, isLocked))
        live[p.id] = true
    end
    sweep(live)
    if isLocked then hideUndo() end
    if ns.Chrome.MinimapShown() then
        buildMinimap()
        if mm then
            mmPlace()
            mm:Show()
        end
    elseif mm then
        mm:Hide()
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

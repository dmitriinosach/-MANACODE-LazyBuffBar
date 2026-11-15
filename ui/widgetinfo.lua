local _, ns = ...
ns.WidgetInfo = {}
local I = ns.WidgetInfo
local W = 400
local PAD = 14
local TOP = 40
local GAP = 10
local SEG_H = 22
local CELL = 32
local CELL_GAP = 2
local TICK = 1
local SCENES = { "solo", "party", "raid" }
local cur
local win
local function sceneOf(item, size)
    local _, class = UnitClass("player")
    return { size = size, fight = false, t = 0, opt = (item and item.opt) or {}, view = item and item.view, class = class or "WARRIOR" }
end
local function paint()
    if not (cur and win) then return end
    if cur.host then ns.Widget.DemoPaint(cur.host, cur.scene) end
    local fr = cur.host and ns.Widget.Frame(cur.host)
    local textH = ns.TextHeight and ns.TextHeight(win.text, W - 2 * PAD) or (win.text:GetHeight() or 0)
    local y = TOP + textH + GAP
    local h = y
    if fr then
        win.scenes:ClearAllPoints()
        win.scenes:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
        win.fight:ClearAllPoints()
        win.fight:SetPoint("LEFT", win.scenes, "RIGHT", 8, 0)
        y = y + SEG_H + GAP
        fr:ClearAllPoints()
        fr:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
        h = y + (fr:GetHeight() or CELL) + PAD
    end
    win:SetHeight(h)
end
local function build()
    win = CreateFrame("Frame", "LazyBuffBarWidgetInfo", UIParent)
    ns.Layer(win, "window")
    win:EnableMouse(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) self:StartMoving() end)
    win:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, "LazyBuffBarWidgetInfo")
    ns.PaintEdit(win)
    win:Hide()
    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.close = ns.MakeCloseX(win)
    win.close.onClick = function() win:Hide() end
    win:SetWidth(W)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    if ns.WindowScale then win:SetScale(ns.WindowScale()) end
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 22, -PAD)
    win.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
    win.icon = win:CreateTexture(nil, "ARTWORK")
    win.icon:SetWidth(18)
    win.icon:SetHeight(18)
    win.icon:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -PAD + 2)
    win.text = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    win.text:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -TOP)
    win.text:SetWidth(W - 2 * PAD)
    win.text:SetJustifyH("LEFT")
    win.text:SetJustifyV("TOP")
    local opts = {}
    for i, s in ipairs(SCENES) do opts[i] = { key = s, label = ns.T("widget.info_" .. s) } end
    win.scenes = ns.MakeSegments(win, opts)
    win.scenes:SetHeight(SEG_H)
    win.scenes:SetWidth(240)
    win.scenes.onPick = function(k)
        if not cur then return end
        cur.scene.size, cur.scene.t = k, 0
        paint()
    end
    win.fight = ns.MakeButton(win)
    win.fight:SetHeight(SEG_H)
    win.fight:SetLabel(ns.T("widget.info_fight"))
    win.fight.onClick = function()
        if not cur then return end
        local s = cur.scene
        s.fight, s.t, cur.acc = not s.fight, 0, 0
        win.fight:SetActive(s.fight)
        paint()
    end
    win:SetScript("OnUpdate", function(_, elapsed)
        if not (cur and cur.scene.fight) then return end
        cur.acc = cur.acc + (elapsed or 0)
        if cur.acc < TICK then return end
        cur.acc = 0
        cur.scene.t = cur.scene.t + 1
        paint()
    end)
    win:SetScript("OnHide", function()
        if cur and cur.host then ns.Widget.DemoDrop(cur.host) end
        cur = nil
    end)
end
function I.Open(name, item)
    local d = ns.Widget.Get(name)
    if not (d and d.info) then return false end
    if not win then build() end
    if cur and cur.host then ns.Widget.DemoDrop(cur.host) end
    local info = d.info
    local scenes = info.scenes or SCENES
    cur = { name = name, item = item or {}, scene = sceneOf(item, scenes[#scenes]), acc = 0 }
    win.title:SetText(ns.WidgetLabel(name))
    local icon = d.icon
    if type(icon) == "number" then icon = select(3, GetSpellInfo(icon)) end
    win.icon:SetTexture(icon or ns.QMARK)
    win.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    win.text:SetText(ns.T(info.text))
    cur.host = info.demo and ns.Widget.Demo(name, cur.scene, win, { cell = CELL, gap = CELL_GAP }) or nil
    if cur.host then
        win.scenes:SetValue(cur.scene.size)
        win.scenes:Show()
        if info.fight then win.fight:Show() else win.fight:Hide() end
        win.fight:SetActive(false)
    else
        win.scenes:Hide()
        win.fight:Hide()
    end
    win:Show()
    paint()
    return true
end
function I.IsShown()
    return win and win:IsShown() and true or false
end
function I.State()
    return cur
end
function I.Frame()
    return win
end
function I.SetFight(on)
    if not cur or cur.scene.fight == (on and true or false) then return end
    win.fight.onClick()
end
function I.SetScene(size)
    if win and win.scenes.onPick then win.scenes.onPick(size) end
end
function I.Close()
    if win then win:Hide() end
end
ns.widgetInfoLoaded = true

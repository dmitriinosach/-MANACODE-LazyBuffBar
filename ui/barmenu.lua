local _, ns = ...
ns.BarMenu = {}
local W = 300
local PAD = 14
local INSET = 12
local ROW = 26
local CAP_H = 26
local LABEL_W = 132
local STEP_W = 28
local VALUE_W = 48
local SIDE_GAP = 8
local MIN_SCALE, MAX_SCALE, SCALE_STEP = 0.5, 2.5, 0.1
local win, panel, hint, resetBtn
local barIndex = 1
local rows = {}
local function knobs()
    local out = {}
    for _, key in ipairs(ns.Look.BAR_ORDER) do
        local k = ns.Look.BAR[key]
        out[#out + 1] = {
            key = key, step = k.step, min = k.min, max = k.max,
            get = function(i) return ns.Look.Bar(i, key) end,
            set = function(i, v) ns.Look.SetBar(i, key, v) end,
            fmt = function(v) return ns.Look.Format(key, v) end,
        }
    end
    out[#out + 1] = {
        key = "perRow", step = 1, min = 0, max = 40,
        get = function(i)
            local b = ns.buffbar:Bars()[i]
            return b and b.perRow or 0
        end,
        set = function(i, v) ns.buffbar:SetPerRow(i, v) end,
        fmt = function(v) return v > 0 and tostring(v) or ns.T("bar.row_all") end,
    }
    out[#out + 1] = {
        key = "scale", step = SCALE_STEP, min = MIN_SCALE, max = MAX_SCALE,
        get = function(i) return ns.buffbar:GetScale(i) or 1 end,
        set = function(i, v) ns.buffbar:SetScale(v, i); ns.Chrome.Apply() end,
        fmt = function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end,
    }
    return out
end
local function nudge(r, dir)
    local k = r.knob
    local v = k.get(barIndex) + dir * k.step
    if v < k.min - 0.0001 or v > k.max + 0.0001 then return end
    k.set(barIndex, v)
    ns.BarMenu.Refresh()
    if ns.Settings and ns.Settings.Refresh then ns.Settings.Refresh() end
end
local function makeRow(y, knob)
    local f = CreateFrame("Frame", nil, panel)
    f:SetWidth(W - PAD * 2 - INSET * 2)
    f:SetHeight(ROW)
    f:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f.tipTitle = ns.T("look." .. knob.key)
    f.tip = ns.T("look." .. knob.key .. "_tip")
    f:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    f:SetScript("OnLeave", function() ns.TipHide() end)
    local r = { frame = f, knob = knob }
    r.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", f, "LEFT", 0, 0)
    r.name:SetWidth(LABEL_W)
    r.name:SetJustifyH("LEFT")
    r.name:SetText(ns.T("look." .. knob.key))
    r.less = ns.MakeButton(f)
    r.less:SetLabel("-")
    r.less:SetWidth(STEP_W)
    r.less:SetPoint("LEFT", f, "LEFT", LABEL_W, 0)
    r.less.onClick = function() nudge(r, -1) end
    r.value = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.value:SetPoint("LEFT", r.less, "RIGHT", 4, 0)
    r.value:SetWidth(VALUE_W)
    r.value:SetJustifyH("CENTER")
    r.more = ns.MakeButton(f)
    r.more:SetLabel("+")
    r.more:SetWidth(STEP_W)
    r.more:SetPoint("LEFT", r.value, "RIGHT", 4, 0)
    r.more.onClick = function() nudge(r, 1) end
    f:SetScript("OnMouseWheel", function(_, delta) nudge(r, delta > 0 and 1 or -1) end)
    return r
end
local function noteHeight(fs)
    local room = W - PAD * 2 - INSET * 2
    local lines = math.ceil((fs:GetStringWidth() or 0) / room)
    if lines < 1 then lines = 1 end
    local h = lines * (fs:GetStringHeight() or 12)
    local own = fs:GetHeight() or 0
    return (own > h) and own or h
end
local function build()
    if win then return end
    win = ns.MakeWindow("LazyBuffBarBarMenu", "")
    win:SetWidth(W)
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + 2, -PAD)
    win.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
    panel = ns.MakePanel(win, ns.T("look.panel"))
    panel:SetWidth(W - PAD * 2)
    panel:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(PAD + 26))
    local y = CAP_H
    for _, knob in ipairs(knobs()) do
        rows[#rows + 1] = makeRow(y, knob)
        y = y + ROW
    end
    y = y + 4
    resetBtn = ns.MakeButton(panel)
    resetBtn:SetLabel(ns.T("look.reset"))
    resetBtn.tip = ns.T("look.reset_tip")
    resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    resetBtn.onClick = function()
        ns.Look.ResetBar(barIndex)
        ns.BarMenu.Refresh()
    end
    y = y + ROW + 4
    hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET, -y)
    hint:SetWidth(W - PAD * 2 - INSET * 2)
    hint:SetJustifyH("LEFT")
    hint:SetText(ns.T("look.hint"))
    y = y + noteHeight(hint) + 8
    panel:SetHeight(y)
    win:SetHeight(PAD + 26 + y + PAD)
    ns.PaintWindow(win)
end
local function anchorTo(f)
    win:ClearAllPoints()
    if not (f and f:GetLeft()) then
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        return
    end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local mid = (f:GetLeft() + f:GetRight()) / 2 * k
    if mid < UIParent:GetWidth() / 2 then
        win:SetPoint("TOPLEFT", f, "TOPRIGHT", SIDE_GAP, 0)
    else
        win:SetPoint("TOPRIGHT", f, "TOPLEFT", -SIDE_GAP, 0)
    end
end
function ns.BarMenu.Open(i, f)
    if not i then return end
    build()
    barIndex = i
    anchorTo(f)
    win:Show()
    ns.BarMenu.Refresh()
end
function ns.BarMenu.Refresh()
    if not win or not win:IsShown() then return end
    if barIndex > #ns.buffbar:Bars() then
        win:Hide()
        return
    end
    win.title:SetText(ns.T("look.title", barIndex))
    for _, r in ipairs(rows) do
        local k = r.knob
        local v = k.get(barIndex)
        r.value:SetText(k.fmt(v))
        if v > k.min + 0.0001 then r.less:Enable() else r.less:Disable() end
        if v < k.max - 0.0001 then r.more:Enable() else r.more:Disable() end
    end
end
function ns.BarMenu.IsShown()
    return win and win:IsShown() and true or false
end
ns.barMenuLoaded = true

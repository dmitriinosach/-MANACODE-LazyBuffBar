local _, ns = ...
local floor = math.floor
local max = math.max
local format = string.format
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "GameFontHighlightSmall"
local CTL_H = 22
local GAP = 6
local LABEL_W = 110
local VALUE_W = 48
local EPS = 0.0001
local BAR_H = 16
local TRACK_H = 6
local THUMB_W, THUMB_H = 10, 16
local SEG_SLIDE = 0.12
local IND_H = 2
local SEC_GAP = 4
local SEC_HEAD = 16
local SLIDER_FALLBACK = {
    track = { 1, 1, 1, 0.16 }, fill = { 1, 0.82, 0.3, 0.72 },
    thumb = { 0.72, 0.78, 0.86, 1 }, thumbHot = { 0.96, 0.98, 1, 1 }, thumbOff = { 0.4, 0.4, 0.42, 1 },
    text = { 1, 1, 1 }, textOff = { 0.45, 0.45, 0.45 }, note = { 1, 0.6, 0.2 },
}
local SEGMENT_FALLBACK = {
    bg = { 0, 0, 0, 0.45 }, hover = { 1, 1, 1, 0.06 },
    text = { 1, 1, 1 }, textHover = { 1, 1, 1 }, textActive = { 1, 1, 1 }, textOff = { 0.45, 0.45, 0.45 },
    indicator = { 1, 0.82, 0.25, 1 }, border = { 1, 0.82, 0, 0.5 },
}
local EDIT_FALLBACK = {
    backdrop = {
        bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    },
    bg = { 0, 0, 0, 0.5 }, border = { 1, 0.82, 0, 0.5 }, borderFocus = { 1, 0.82, 0, 1 },
    text = { 1, 1, 1 }, textOff = { 0.45, 0.45, 0.45 }, ghost = { 0.6, 0.6, 0.6 },
}
local SWATCH_FALLBACK = {
    border = { 1, 0.82, 0, 0.65 }, borderHover = { 1, 0.82, 0, 1 }, borderOff = { 0.45, 0.45, 0.45, 0.6 },
}
local SEP_FALLBACK = { 1, 1, 1, 0.15 }
local function skin(name, fallback)
    local t = ns.CurrentTheme and ns.CurrentTheme()
    return (t and t[name]) or fallback
end
local function sepColor()
    local t = ns.CurrentTheme and ns.CurrentTheme()
    return (t and t.tabbar and t.tabbar.sep) or SEP_FALLBACK
end
local function paint(tex, c)
    tex:SetTexture(WHITE)
    tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
end
local function ink(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local made = {}
local function register(ctl)
    made[#made + 1] = ctl
end
if ns.OnTheme then
    ns.OnTheme(function()
        for i = 1, #made do made[i]:Restyle() end
    end)
end
local function snap(s, v)
    v = tonumber(v) or s.lo
    if v < s.lo then v = s.lo elseif v > s.hi then v = s.hi end
    local k = floor((v - s.lo) / s.step + 0.5)
    v = s.lo + k * s.step
    if v > s.hi then v = s.hi end
    return floor(v * 1000 + 0.5) / 1000
end
local function show(s, v)
    local f = s.fmt
    if type(f) == "function" then return f(v) end
    if type(f) == "string" then return format(f, v) end
    if math.abs(v - floor(v)) < EPS then return format("%d", v) end
    return format("%.1f", v)
end
local function sliderStyle(s)
    local sk = skin("slider", SLIDER_FALLBACK)
    paint(s.track, sk.track or SLIDER_FALLBACK.track)
    paint(s.fill, sk.fill or SLIDER_FALLBACK.fill)
    local th = sk.thumb or SLIDER_FALLBACK.thumb
    if s.off then
        th = sk.thumbOff or SLIDER_FALLBACK.thumbOff
    elseif s.hot or s.dragging then
        th = sk.thumbHot or SLIDER_FALLBACK.thumbHot
    end
    paint(s.thumb, th)
    local tc = s.off and (sk.textOff or SLIDER_FALLBACK.textOff) or (sk.text or SLIDER_FALLBACK.text)
    ink(s.label, tc)
    local nc = sk.note or SLIDER_FALLBACK.note
    ink(s.noteText, nc)
    if s.note and not s.off then
        ink(s.value, nc)
    else
        ink(s.value, tc)
    end
end
local function commit(s)
    if s.cur == s.committed then return end
    s.committed = s.cur
    if s.onCommit then s.onCommit(s.cur) end
end
local function onValue(bar, raw)
    local s = bar.owner
    local v = snap(s, raw)
    s.value:SetText(show(s, v))
    if s.quiet or v == s.cur then return end
    s.cur = v
    if s.onChange then s.onChange(v) end
    if not s.dragging then commit(s) end
end
local function onDown(bar)
    local s = bar.owner
    if s.off then return end
    s.dragging = true
    sliderStyle(s)
end
local function onUp(bar)
    local s = bar.owner
    s.dragging = nil
    sliderStyle(s)
    commit(s)
end
local function onWheel(bar, delta)
    local s = bar.owner
    if s.off then return end
    local v = snap(s, s.cur + (delta > 0 and s.step or -s.step))
    if v == s.cur then return end
    bar:SetValue(v)
end
local function sliderEnter(f)
    local s = f.owner or f
    if s.off then return end
    s.hot = true
    sliderStyle(s)
    if ns.TipShow then ns.TipShow(s) end
end
local function sliderLeave(f)
    local s = f.owner or f
    s.hot = nil
    sliderStyle(s)
    if ns.TipHide then ns.TipHide() end
end
local function sliderSetValue(self, v)
    v = snap(self, v)
    self.quiet = true
    self.bar:SetValue(v)
    self.quiet = nil
    self.cur, self.committed = v, v
    self.value:SetText(show(self, v))
end
local function sliderGetValue(self)
    return self.cur
end
local function sliderSetRange(self, lo, hi, step)
    self.lo, self.hi = lo, max(lo, hi)
    self.step = (step and step > 0) and step or 1
    self.quiet = true
    self.bar:SetMinMaxValues(self.lo, self.hi)
    self.bar:SetValueStep(self.step)
    self.quiet = nil
    sliderSetValue(self, self.cur or lo)
end
local function sliderEnable(self)
    self.off = nil
    self.bar:Enable()
    sliderStyle(self)
end
local function sliderDisable(self)
    self.off = true
    self.dragging = nil
    self.hot = nil
    self.bar:Disable()
    sliderStyle(self)
end
local function sliderSetLabel(self, text)
    self.label:SetText(text)
end
local function sliderSetNote(self, text)
    self.note = (text and text ~= "") and text or nil
    self.noteText:SetText(self.note or "")
    self.value:ClearAllPoints()
    self.value:SetPoint("RIGHT", self.noteText, "LEFT", self.note and -4 or 0, 0)
    sliderStyle(self)
end
local function sliderSetLabelWidth(self, w)
    self.labelW = w
    self.label:SetWidth(w)
    self.value:SetWidth(self.valueW)
    self.bar:ClearAllPoints()
    self.bar:SetPoint("LEFT", self, "LEFT", w + GAP, 0)
    self.bar:SetPoint("RIGHT", self.value, "LEFT", -GAP, 0)
end
function ns.MakeSlider(parent, spec)
    spec = spec or {}
    local s = CreateFrame("Frame", nil, parent)
    s:SetHeight(CTL_H)
    s:EnableMouse(true)
    s.valueW = spec.valueW or VALUE_W
    s.fmt = spec.fmt
    s.label = s:CreateFontString(nil, "ARTWORK", FONT)
    s.label:SetPoint("LEFT", s, "LEFT", 0, 0)
    s.label:SetJustifyH("LEFT")
    s.noteText = s:CreateFontString(nil, "ARTWORK", FONT)
    s.noteText:SetPoint("RIGHT", s, "RIGHT", 0, 0)
    s.noteText:SetJustifyH("RIGHT")
    s.noteText:SetText("")
    s.value = s:CreateFontString(nil, "ARTWORK", FONT)
    s.value:SetPoint("RIGHT", s.noteText, "LEFT", 0, 0)
    s.value:SetJustifyH("RIGHT")
    local bar = CreateFrame("Slider", nil, s)
    bar.owner = s
    bar:SetOrientation("HORIZONTAL")
    bar:SetHeight(BAR_H)
    bar:EnableMouseWheel(spec.wheel ~= false)
    s.bar = bar
    s.track = bar:CreateTexture(nil, "BACKGROUND")
    s.track:SetHeight(TRACK_H)
    s.track:SetPoint("LEFT", bar, "LEFT", 0, 0)
    s.track:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    s.thumb = bar:CreateTexture(nil, "OVERLAY")
    s.thumb:SetWidth(THUMB_W)
    s.thumb:SetHeight(THUMB_H)
    bar:SetThumbTexture(s.thumb)
    s.fill = bar:CreateTexture(nil, "ARTWORK")
    s.fill:SetHeight(TRACK_H)
    s.fill:SetPoint("LEFT", s.track, "LEFT", 0, 0)
    s.fill:SetPoint("RIGHT", s.thumb, "CENTER", 0, 0)
    bar:SetScript("OnValueChanged", onValue)
    bar:SetScript("OnMouseDown", onDown)
    bar:SetScript("OnMouseUp", onUp)
    bar:SetScript("OnMouseWheel", onWheel)
    bar:SetScript("OnEnter", sliderEnter)
    bar:SetScript("OnLeave", sliderLeave)
    s:SetScript("OnEnter", sliderEnter)
    s:SetScript("OnLeave", sliderLeave)
    s.cur = spec.min or 0
    s.SetValue = sliderSetValue
    s.GetValue = sliderGetValue
    s.SetRange = sliderSetRange
    s.SetLabel = sliderSetLabel
    s.SetNote = sliderSetNote
    s.SetLabelWidth = sliderSetLabelWidth
    s.Enable = sliderEnable
    s.Disable = sliderDisable
    s.Restyle = sliderStyle
    sliderSetLabelWidth(s, spec.labelW or LABEL_W)
    sliderSetRange(s, spec.min or 0, spec.max or 100, spec.step)
    register(s)
    sliderEnable(s)
    return s
end
local function segIndex(seg, key)
    for i, o in ipairs(seg.options) do
        if o.key == key then return i end
    end
    return nil
end
local function segWidth(seg)
    local n = #seg.options
    if n == 0 then return 0 end
    local w = seg.body:GetWidth() or 0
    if w <= 0 then
        local l, r = seg.body:GetLeft(), seg.body:GetRight()
        w = (l and r) and (r - l) or 0
    end
    return floor(w / n)
end
local function segStyle(seg)
    local sk = skin("segment", SEGMENT_FALLBACK)
    paint(seg.bg, sk.bg or SEGMENT_FALLBACK.bg)
    paint(seg.ind.tex, sk.indicator or SEGMENT_FALLBACK.indicator)
    local sep = sepColor()
    for _, t in ipairs(seg.seps) do paint(t, sep) end
    local lc = seg.off and (sk.textOff or SEGMENT_FALLBACK.textOff) or (sk.text or SEGMENT_FALLBACK.text)
    ink(seg.label, lc)
    for i, b in ipairs(seg.buttons) do
        local o = seg.options[i]
        local c
        if seg.off then
            c = sk.textOff or SEGMENT_FALLBACK.textOff
        elseif o and o.key == seg.cur then
            c = sk.textActive or SEGMENT_FALLBACK.textActive
        elseif b.hovered then
            c = sk.textHover or SEGMENT_FALLBACK.textHover
        else
            c = sk.text or SEGMENT_FALLBACK.text
        end
        ink(b.text, c)
        paint(b.hl, sk.hover or SEGMENT_FALLBACK.hover)
        if b.hovered and not seg.off then b.hl:Show() else b.hl:Hide() end
    end
end
local function indPlace(ind, x)
    ind.x = x
    ind:ClearAllPoints()
    ind:SetPoint("BOTTOMLEFT", ind:GetParent(), "BOTTOMLEFT", x, 0)
end
local function indUpdate(ind, dt)
    ind.t = ind.t + dt
    local k = ind.t / SEG_SLIDE
    if k >= 1 then
        indPlace(ind, ind.toX)
        ind:SetScript("OnUpdate", nil)
        return
    end
    k = 1 - (1 - k) * (1 - k)
    indPlace(ind, ind.fromX + (ind.toX - ind.fromX) * k)
end
local function segMoveIndicator(seg, animate)
    local i = segIndex(seg, seg.cur)
    local ind = seg.ind
    if not i then
        ind:SetScript("OnUpdate", nil)
        ind:Hide()
        return
    end
    local w = segWidth(seg)
    local toX = (i - 1) * w
    ind:SetWidth(max(w, 1))
    if animate and ind:IsShown() and ind.x and ind.x ~= toX then
        ind.fromX, ind.toX, ind.t = ind.x, toX, 0
        ind:SetScript("OnUpdate", indUpdate)
    else
        ind:SetScript("OnUpdate", nil)
        indPlace(ind, toX)
    end
    ind:Show()
end
local function segLayout(seg)
    local n = #seg.options
    local w = segWidth(seg)
    for i, b in ipairs(seg.buttons) do
        if i <= n then
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", seg.body, "TOPLEFT", (i - 1) * w, 0)
            b:SetWidth(max(w, 1))
            b:SetHeight(CTL_H)
            b.text:SetWidth(max(w - 4, 1))
            b:Show()
        else
            b:Hide()
        end
    end
    for i, t in ipairs(seg.seps) do
        if i < n then
            t:ClearAllPoints()
            t:SetPoint("TOP", seg.body, "TOPLEFT", i * w, -3)
            t:SetPoint("BOTTOM", seg.body, "BOTTOMLEFT", i * w, 3)
            t:Show()
        else
            t:Hide()
        end
    end
    segMoveIndicator(seg, false)
end
local function segButton(seg, i)
    local b = seg.buttons[i]
    if b then return b end
    b = CreateFrame("Button", nil, seg.body)
    b.owner = seg
    b.index = i
    b.hl = b:CreateTexture(nil, "BACKGROUND")
    b.hl:SetAllPoints(b)
    b.hl:Hide()
    b.text = b:CreateFontString(nil, "ARTWORK", FONT)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetJustifyH("CENTER")
    b.text:SetWordWrap(false)
    b:SetScript("OnClick", function(self)
        local sg = self.owner
        if sg.off then return end
        local o = sg.options[self.index]
        if not o then return end
        if o.key ~= sg.cur then
            sg.cur = o.key
            segMoveIndicator(sg, true)
            segStyle(sg)
        end
        if sg.onPick then sg.onPick(o.key) end
    end)
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        segStyle(self.owner)
        if ns.TipShow then ns.TipShow(self) end
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = nil
        segStyle(self.owner)
        if ns.TipHide then ns.TipHide() end
    end)
    seg.buttons[i] = b
    if i > 1 and not seg.seps[i - 1] then
        local t = seg.body:CreateTexture(nil, "ARTWORK")
        t:SetWidth(1)
        seg.seps[i - 1] = t
    end
    return b
end
local function segSetOptions(self, options)
    self.options = options or {}
    for i, o in ipairs(self.options) do
        local b = segButton(self, i)
        b.text:SetText(o.label or "")
        b.tipTitle = o.label
        b.tip = o.tip
    end
    if not segIndex(self, self.cur) then self.cur = nil end
    segLayout(self)
    segStyle(self)
end
local function segSetValue(self, key)
    self.cur = key
    segMoveIndicator(self, false)
    segStyle(self)
end
local function segGetValue(self)
    return self.cur
end
local function segSetLabel(self, text)
    self.label:SetText(text)
end
local function segEnable(self)
    self.off = nil
    segStyle(self)
end
local function segDisable(self)
    self.off = true
    segStyle(self)
end
function ns.MakeSegments(parent, options, spec)
    spec = spec or {}
    local seg = CreateFrame("Frame", nil, parent)
    seg:SetHeight(CTL_H)
    seg.buttons, seg.seps = {}, {}
    seg.label = seg:CreateFontString(nil, "ARTWORK", FONT)
    seg.label:SetPoint("LEFT", seg, "LEFT", 0, 0)
    seg.label:SetJustifyH("LEFT")
    seg.body = CreateFrame("Frame", nil, seg)
    seg.body:SetPoint("TOP", seg, "TOP", 0, 0)
    seg.body:SetPoint("BOTTOM", seg, "BOTTOM", 0, 0)
    seg.body:SetPoint("RIGHT", seg, "RIGHT", 0, 0)
    if spec.label then
        local w = spec.labelW or LABEL_W
        seg.label:SetText(spec.label)
        seg.label:SetWidth(w)
        seg.body:SetPoint("LEFT", seg, "LEFT", w + GAP, 0)
    else
        seg.label:Hide()
        seg.body:SetPoint("LEFT", seg, "LEFT", 0, 0)
    end
    seg.bg = seg.body:CreateTexture(nil, "BACKGROUND")
    seg.bg:SetAllPoints(seg.body)
    seg.ind = CreateFrame("Frame", nil, seg.body)
    seg.ind:SetHeight(IND_H)
    seg.ind.tex = seg.ind:CreateTexture(nil, "OVERLAY")
    seg.ind.tex:SetAllPoints(seg.ind)
    seg.ind:Hide()
    seg.body:SetScript("OnSizeChanged", function() segLayout(seg) end)
    seg.SetValue = segSetValue
    seg.GetValue = segGetValue
    seg.SetOptions = segSetOptions
    seg.SetLabel = segSetLabel
    seg.Layout = segLayout
    seg.Enable = segEnable
    seg.Disable = segDisable
    seg.Restyle = segStyle
    segSetOptions(seg, options)
    register(seg)
    return seg
end
local function fieldStyle(fld)
    local sk = skin("edit", EDIT_FALLBACK)
    local bg = sk.bg or EDIT_FALLBACK.bg
    fld:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    local br = (fld.focused and (sk.borderFocus or EDIT_FALLBACK.borderFocus)) or sk.border or EDIT_FALLBACK.border
    fld:SetBackdropBorderColor(br[1], br[2], br[3], br[4] or 1)
    local tc = fld.off and (sk.textOff or EDIT_FALLBACK.textOff) or (sk.text or EDIT_FALLBACK.text)
    fld.box:SetTextColor(tc[1], tc[2], tc[3])
    ink(fld.ghost, sk.ghost or EDIT_FALLBACK.ghost)
    local text = fld.box:GetText() or ""
    if text == "" and not fld.focused then fld.ghost:Show() else fld.ghost:Hide() end
end
local function fieldCommit(fld)
    local text = fld.box:GetText() or ""
    if text == fld.committed then return end
    fld.committed = text
    if fld.onCommit then fld.onCommit(text) end
end
local function fieldSetText(self, text)
    text = text or ""
    self.box:SetText(text)
    self.committed = self.box:GetText() or text
    fieldStyle(self)
end
local function fieldGetText(self)
    return self.box:GetText() or ""
end
local function fieldSetFocus(self)
    if self.off then return end
    self.box:SetFocus()
end
local function fieldEnable(self)
    self.off = nil
    self.box:EnableMouse(true)
    fieldStyle(self)
end
local function fieldDisable(self)
    self.off = true
    self.box:ClearFocus()
    self.box:EnableMouse(false)
    fieldStyle(self)
end
function ns.MakeField(parent, spec)
    spec = spec or {}
    local fld = CreateFrame("Frame", nil, parent)
    fld:SetHeight(CTL_H)
    fld:SetBackdrop(skin("edit", EDIT_FALLBACK).backdrop or EDIT_FALLBACK.backdrop)
    fld:EnableMouse(true)
    fld.committed = ""
    local box = CreateFrame("EditBox", nil, fld)
    box.owner = fld
    box:SetPoint("TOPLEFT", fld, "TOPLEFT", 4, -2)
    box:SetPoint("BOTTOMRIGHT", fld, "BOTTOMRIGHT", -4, 2)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetAutoFocus(false)
    box:SetMaxLetters(spec.maxLetters or 24)
    box:SetTextInsets(2, 2, 0, 0)
    box:SetText("")
    fld.box = box
    fld.ghost = fld:CreateFontString(nil, "ARTWORK", FONT)
    fld.ghost:SetPoint("LEFT", fld, "LEFT", 6, 0)
    fld.ghost:SetPoint("RIGHT", fld, "RIGHT", -6, 0)
    fld.ghost:SetJustifyH("LEFT")
    fld.ghost:SetText(spec.ghost or "")
    box:SetScript("OnEnterPressed", function(self)
        fieldCommit(self.owner)
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        local f = self.owner
        f.cancel = true
        self:SetText(f.committed)
        self:ClearFocus()
        f.cancel = nil
        fieldStyle(f)
    end)
    box:SetScript("OnEditFocusGained", function(self)
        local f = self.owner
        f.focused = true
        fieldStyle(f)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        local f = self.owner
        f.focused = nil
        if f.cancel then
            self:SetText(f.committed)
        else
            fieldCommit(f)
        end
        fieldStyle(f)
    end)
    box:SetScript("OnTextChanged", function(self)
        fieldStyle(self.owner)
    end)
    fld:SetScript("OnMouseDown", function(self)
        fieldSetFocus(self)
    end)
    fld.SetText = fieldSetText
    fld.GetText = fieldGetText
    fld.SetFocus = fieldSetFocus
    fld.Enable = fieldEnable
    fld.Disable = fieldDisable
    fld.Restyle = fieldStyle
    register(fld)
    fieldStyle(fld)
    return fld
end
local function swatchStyle(sw)
    local sk = skin("swatch", SWATCH_FALLBACK)
    local c
    if sw.off then
        c = sk.borderOff or SWATCH_FALLBACK.borderOff
    elseif sw.hovered then
        c = sk.borderHover or SWATCH_FALLBACK.borderHover
    else
        c = sk.border or SWATCH_FALLBACK.border
    end
    paint(sw.edge, c)
    sw.color:SetTexture(WHITE)
    sw.color:SetVertexColor(sw.r, sw.g, sw.b, sw.off and 0.5 or 1)
end
local function swatchSetColor(self, r, g, b)
    self.r, self.g, self.b = r or 0, g or 0, b or 0
    swatchStyle(self)
end
local function swatchGetColor(self)
    return self.r, self.g, self.b
end
local function swatchOpen(sw)
    local picker = ColorPickerFrame
    if not picker then return end
    if picker:IsShown() then HideUIPanel(picker) end
    local r, g, b = sw.r, sw.g, sw.b
    picker.hasOpacity = nil
    picker.opacityFunc = nil
    picker.opacity = nil
    picker.previousValues = { r = r, g = g, b = b }
    picker.func = function()
        local nr, ng, nb = picker:GetColorRGB()
        swatchSetColor(sw, nr, ng, nb)
        if sw.onChange then sw.onChange(nr, ng, nb) end
    end
    picker.cancelFunc = function(prev)
        local pr, pg, pb = r, g, b
        if type(prev) == "table" and prev.r then pr, pg, pb = prev.r, prev.g, prev.b end
        swatchSetColor(sw, pr, pg, pb)
        if sw.onChange then sw.onChange(pr, pg, pb) end
    end
    picker:SetColorRGB(r, g, b)
    ShowUIPanel(picker)
end
local function swatchEnable(self)
    self.off = nil
    swatchStyle(self)
end
local function swatchDisable(self)
    self.off = true
    swatchStyle(self)
end
function ns.MakeSwatch(parent)
    local sw = CreateFrame("Button", nil, parent)
    sw:SetWidth(CTL_H)
    sw:SetHeight(CTL_H)
    sw.r, sw.g, sw.b = 0, 0, 0
    sw.edge = sw:CreateTexture(nil, "BACKGROUND")
    sw.edge:SetAllPoints(sw)
    sw.color = sw:CreateTexture(nil, "ARTWORK")
    sw.color:SetPoint("TOPLEFT", sw, "TOPLEFT", 1, -1)
    sw.color:SetPoint("BOTTOMRIGHT", sw, "BOTTOMRIGHT", -1, 1)
    sw:SetScript("OnClick", function(self)
        if self.off then return end
        swatchOpen(self)
    end)
    sw:SetScript("OnEnter", function(self)
        self.hovered = true
        swatchStyle(self)
        if ns.TipShow then ns.TipShow(self) end
    end)
    sw:SetScript("OnLeave", function(self)
        self.hovered = nil
        swatchStyle(self)
        if ns.TipHide then ns.TipHide() end
    end)
    sw.SetColor = swatchSetColor
    sw.GetColor = swatchGetColor
    sw.Enable = swatchEnable
    sw.Disable = swatchDisable
    sw.Restyle = swatchStyle
    register(sw)
    swatchStyle(sw)
    return sw
end
local function sectionStyle(sec)
    if sec.caption then
        local r, g, b = 1, 0.82, 0
        if ns.Edge then r, g, b = ns.Edge() end
        sec.caption:SetTextColor(r, g, b)
    end
    if sec.line then paint(sec.line, sepColor()) end
end
local function sectionAdd(self, control, h)
    h = h or control:GetHeight() or CTL_H
    if h == 0 then h = CTL_H end
    control:ClearAllPoints()
    local top
    if self.last then
        top = -(self.used + SEC_GAP)
        self.used = self.used + SEC_GAP + h
    else
        top = self.caption and -(SEC_HEAD + SEC_GAP) or 0
        self.used = -top + h
    end
    control:SetPoint("TOPLEFT", self, "TOPLEFT", 0, top)
    control:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, top)
    control:SetHeight(h)
    self.items[#self.items + 1] = control
    self.last = control
    self:SetHeight(self.used)
    return control
end
local function sectionRelayout(self)
    local items = self.items
    self.items, self.last = {}, nil
    self.used = self.caption and SEC_HEAD or 0
    for _, c in ipairs(items) do
        if c.fold and not c:IsShown() then
            self.items[#self.items + 1] = c
        else
            sectionAdd(self, c, c:GetHeight())
        end
    end
    self:SetHeight(self.used)
end
function ns.MakeSection(parent, caption)
    local sec = CreateFrame("Frame", nil, parent)
    sec.items = {}
    sec.used = 0
    if caption then
        sec.caption = sec:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        sec.caption:SetPoint("TOPLEFT", sec, "TOPLEFT", 0, 0)
        sec.caption:SetHeight(SEC_HEAD - 2)
        sec.caption:SetJustifyH("LEFT")
        sec.caption:SetText(caption)
        sec.line = sec:CreateTexture(nil, "ARTWORK")
        sec.line:SetHeight(1)
        sec.line:SetPoint("TOPLEFT", sec, "TOPLEFT", 0, -SEC_HEAD)
        sec.line:SetPoint("TOPRIGHT", sec, "TOPRIGHT", 0, -SEC_HEAD)
        sec.used = SEC_HEAD
    end
    sec:SetHeight(sec.used)
    sec.Add = sectionAdd
    sec.Relayout = sectionRelayout
    sec.Restyle = sectionStyle
    register(sec)
    sectionStyle(sec)
    return sec
end
local MENU_ROW = 20
local MENU_PAD = 6
local MENU_MIN_W = 160
local MENU_LEVEL = 2
local ARROW_TEX = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local catcher
local lists = {}
local menuState = { rows = {}, subRows = {} }
local function paintMenu(list)
    ns.PaintEdit(list)
    if list.head then ns.Ink(list.head, ns.EDIT.gold) end
end
local function menuList(level)
    if lists[level] then return lists[level] end
    local list = CreateFrame("Frame", nil, catcher)
    list:SetFrameLevel(catcher:GetFrameLevel() + MENU_LEVEL + level)
    list:SetClampedToScreen(true)
    list.rows = {}
    list.head = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    list.head:SetPoint("TOPLEFT", list, "TOPLEFT", MENU_PAD + 6, -MENU_PAD - 4)
    list.head:SetJustifyH("LEFT")
    paintMenu(list)
    list:Hide()
    lists[level] = list
    return list
end
local function ensureCatcher()
    if catcher then return end
    catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    ns.Layer(catcher, "menu")
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", function() ns.MenuClose() end)
    catcher:Hide()
end
local function hideLevel(level)
    local list = lists[level]
    if not list then return end
    for _, b in ipairs(list.rows) do b:Hide() end
    list:Hide()
end
function ns.MenuClose()
    if catcher then catcher:Hide() end
    hideLevel(2)
    hideLevel(1)
    if menuState.anchor and menuState.anchor.SetActive then menuState.anchor:SetActive(false) end
    menuState = { rows = {}, subRows = {} }
end
local showLevel
local function menuRow(list, i)
    local b = list.rows[i]
    if b then return b end
    b = ns.MakeButton(list)
    b:SetHeight(MENU_ROW)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
    b.text:SetJustifyH("LEFT")
    b.note = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.note:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    b.note:SetJustifyH("RIGHT")
    b.arrow = b:CreateTexture(nil, "OVERLAY")
    b.arrow:SetWidth(12)
    b.arrow:SetHeight(12)
    b.arrow:SetTexture(ARROW_TEX)
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    b.swatch = b:CreateTexture(nil, "OVERLAY")
    b.swatch:SetWidth(10)
    b.swatch:SetHeight(10)
    b.swatch:SetTexture("Interface\\Buttons\\WHITE8X8")
    b.swatch:SetPoint("LEFT", b, "LEFT", 8, 0)
    b.swatch:Hide()
    b:HookScript("OnEnter", function(self)
        if self.item and self.item.submenu and self.level == 1 then showLevel(2, self.item.submenu, self, nil) end
    end)
    list.rows[i] = b
    return b
end
showLevel = function(level, items, anchor, side)
    hideLevel(level)
    if level == 1 then hideLevel(2) end
    local list = menuList(level)
    local y = MENU_PAD
    local w = MENU_MIN_W - MENU_PAD * 2
    local title
    if items[1] and items[1].isTitle then title = items[1].text end
    if title then
        list.head:SetText(title)
        list.head:Show()
        y = y + 18
        w = max(w, (list.head:GetStringWidth() or 0) + 14)
    else
        list.head:Hide()
    end
    local n = 0
    local rows = {}
    for i, it in ipairs(items) do
        if not (i == 1 and title) then
            n = n + 1
            local b = menuRow(list, n)
            b.item, b.level = it, level
            b:SetLabel(it.text)
            b.tip = it.tip
            b.tipTitle = false
            if it.note then b.note:SetText(it.note) b.note:Show() else b.note:SetText("") b.note:Hide() end
            if it.submenu then b.arrow:Show() else b.arrow:Hide() end
            b.text:ClearAllPoints()
            if it.swatch then
                b.swatch:SetVertexColor(it.swatch[1], it.swatch[2], it.swatch[3], 1)
                b.swatch:Show()
                b.text:SetPoint("LEFT", b, "LEFT", 22, 0)
            else
                b.swatch:Hide()
                b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
            end
            b:SetActive(it.checked and true or false)
            if it.disabled or (it.isTitle and i > 1) then b:Disable() else b:Enable() end
            b.onClick = function(self)
                if it.submenu then
                    showLevel(2, it.submenu, self, "right")
                    return
                end
                ns.MenuClose()
                if it.func then it.func() end
            end
            local need = (b.text:GetStringWidth() or 0) + 22
            if it.note then need = need + (b.note:GetStringWidth() or 0) + 10 end
            if it.submenu then need = need + 14 end
            if it.swatch then need = need + 14 end
            w = max(w, need)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", list, "TOPLEFT", MENU_PAD, -y)
            b:Show()
            y = y + MENU_ROW
            rows[#rows + 1] = b
        end
    end
    for i = n + 1, #list.rows do list.rows[i]:Hide() end
    for _, b in ipairs(rows) do b:SetWidth(w) end
    list:SetWidth(w + MENU_PAD * 2)
    list:SetHeight(y + MENU_PAD)
    list:ClearAllPoints()
    if not anchor then
        local scale = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        list:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale - 4, cy / scale + 4)
    elseif side == "right" then
        list:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, 0)
    else
        list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    end
    list:Show()
    if level == 1 then
        menuState.items, menuState.rows = items, rows
    else
        menuState.sub, menuState.subRows = items, rows
    end
end
function ns.MakeMenu(items, anchor)
    if anchor and menuState.anchor == anchor then
        ns.MenuClose()
        return
    end
    ns.MenuClose()
    ensureCatcher()
    catcher:Show()
    menuState.anchor = anchor
    if anchor and anchor.SetActive then anchor:SetActive(true) end
    showLevel(1, items, anchor, nil)
end
function ns.MenuState()
    return menuState
end
local ASK_W = 260
local ASK_H = 84
local ASK_CHOICE_H = 26
local ask
local function buildAsk()
    if ask then return end
    ask = CreateFrame("Frame", "LazyBuffBarAsk", UIParent)
    ns.Layer(ask, "menu")
    ask:SetWidth(ASK_W)
    ask:SetHeight(ASK_H)
    ask:EnableMouse(true)
    ask:SetClampedToScreen(true)
    ask.title = ask:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ask.title:SetPoint("TOPLEFT", ask, "TOPLEFT", 12, -10)
    ask.title:SetJustifyH("LEFT")
    ask.field = ns.MakeField(ask, { maxLetters = 32 })
    ask.field:SetPoint("TOPLEFT", ask, "TOPLEFT", 12, -28)
    ask.field:SetPoint("TOPRIGHT", ask, "TOPRIGHT", -12, -28)
    ask.ok = ns.MakeButton(ask)
    ask.ok:SetPoint("BOTTOMRIGHT", ask, "BOTTOMRIGHT", -12, 10)
    ask.cancel = ns.MakeButton(ask)
    ask.cancel:SetPoint("RIGHT", ask.ok, "LEFT", -6, 0)
    ask.cancel.onClick = function() ask:Hide() end
    ask.field.box:SetScript("OnEscapePressed", function() ask:Hide() end)
    ask:SetScript("OnHide", function() ask.field.box:ClearFocus() end)
    paintMenu(ask)
    ask:Hide()
end
function ns.AskName(anchor, spec)
    buildAsk()
    ns.MenuClose()
    ask.title:SetText(spec.title)
    ask.ok:SetLabel(spec.ok)
    ask.cancel:SetLabel(spec.cancel)
    ask.field.ghost:SetText(spec.ghost or "")
    ask.field:SetText(spec.text or "")
    local choice = spec.choice
    if choice then
        if not ask.seg then
            ask.seg = ns.MakeSegments(ask, choice.options)
            ask.seg:SetPoint("TOPLEFT", ask.field, "BOTTOMLEFT", 0, -4)
            ask.seg:SetPoint("TOPRIGHT", ask.field, "BOTTOMRIGHT", 0, -4)
            ask.seg:SetHeight(ASK_CHOICE_H - 4)
        else
            ask.seg:SetOptions(choice.options)
        end
        ask.seg:SetValue(choice.value)
        ask.seg:Layout()
        ask.seg:Show()
        ask:SetHeight(ASK_H + ASK_CHOICE_H)
    else
        if ask.seg then ask.seg:Hide() end
        ask:SetHeight(ASK_H)
    end
    local function accept(text)
        if not ask:IsShown() then return end
        text = tostring(text or ""):match("^%s*(.-)%s*$")
        if text == "" then return end
        ask:Hide()
        spec.onCommit(text, choice and ask.seg:GetValue() or nil)
    end
    ask.field.onCommit = accept
    ask.ok.onClick = function() accept(ask.field:GetText()) end
    ask:ClearAllPoints()
    if anchor then
        ask:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
        ask:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    end
    ask:Show()
    ask.field:SetFocus()
end
function ns.AskFrame()
    return ask
end
ns.OnTheme(function()
    for _, list in pairs(lists) do paintMenu(list) end
    if ask then paintMenu(ask) end
end)
ns.controlsLoaded = true

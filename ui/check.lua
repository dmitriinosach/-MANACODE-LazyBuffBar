local _, ns = ...
local MARK_FADE = 0.1
local CHK_FALLBACK = {
    box  = { tex = "Interface\\Buttons\\UI-CheckBox-Up" },
    mark = { tex = "Interface\\Buttons\\UI-CheckBox-Check" },
    boxColor      = { 1, 1, 1, 1 },
    boxColorHover = { 1, 1, 1, 1 },
    boxColorOff   = { 0.5, 0.5, 0.5, 1 },
    markColor     = { 1, 1, 1, 1 },
    label         = { 1, 1, 1 },
    labelHover    = { 1, 1, 1 },
    labelOff      = { 0.45, 0.45, 0.45 },
}
local function styleCheck(c)
    local theme = ns.CurrentTheme and ns.CurrentTheme()
    local ck = (theme and theme.check) or CHK_FALLBACK
    local hot = c.hovered and not c.off
    c.box:SetTexture(ck.box and ck.box.tex or CHK_FALLBACK.box.tex)
    if ck.box and ck.box.coord then
        c.box:SetTexCoord(ck.box.coord[1], ck.box.coord[2], ck.box.coord[3], ck.box.coord[4])
    end
    local bc
    if c.off then
        bc = ck.boxColorOff or CHK_FALLBACK.boxColorOff
    else
        bc = (hot and ck.boxColorHover or ck.boxColor) or CHK_FALLBACK.boxColor
    end
    c.box:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
    c.mark:SetTexture(ck.mark and ck.mark.tex or CHK_FALLBACK.mark.tex)
    local mc = ck.markColor or CHK_FALLBACK.markColor
    c.mark:SetVertexColor(mc[1], mc[2], mc[3], mc[4])
    local lc
    if c.off then
        lc = ck.labelOff or CHK_FALLBACK.labelOff
    else
        lc = (hot and ck.labelHover or ck.label) or CHK_FALLBACK.label
    end
    c.label:SetTextColor(lc[1], lc[2], lc[3])
end
ns.StyleCheck = styleCheck
local made = {}
if ns.OnTheme then
    ns.OnTheme(function()
        for i = 1, #made do styleCheck(made[i]) end
    end)
end
local function showMark(c, on, animate)
    local mf = c.markFrame
    local anim = animate and ns.Anim and ns.Anim.Fade
    if anim then
        if on then
            ns.Anim.Fade(mf, 0, 1, MARK_FADE)
        else
            ns.Anim.Fade(mf, nil, 0, MARK_FADE)
        end
        return
    end
    if ns.Anim and ns.Anim.Stop then ns.Anim.Stop(mf) end
    mf:SetAlpha(1)
    if on then mf:Show() else mf:Hide() end
end
function ns.MakeCheck(parent)
    local c = CreateFrame("Button", nil, parent)
    made[#made + 1] = c
    c:SetWidth(22)
    c:SetHeight(22)
    c.box = c:CreateTexture(nil, "ARTWORK")
    c.box:SetAllPoints(c)
    c.markFrame = CreateFrame("Frame", nil, c)
    c.markFrame:SetAllPoints(c)
    c.mark = c.markFrame:CreateTexture(nil, "OVERLAY")
    c.mark:SetAllPoints(c.markFrame)
    c.markFrame:Hide()
    c.label = c:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.label:SetJustifyH("LEFT")
    function c:SetChecked(on, animate)
        self.checked = on and true or false
        showMark(self, self.checked, animate)
    end
    function c:GetChecked() return self.checked and true or false end
    function c:SetLabel(text)
        self.label:SetText(text)
    end
    function c:Enable()
        self.off = nil
        styleCheck(self)
    end
    function c:Disable()
        self.off = true
        styleCheck(self)
    end
    c:SetScript("OnClick", function(self)
        if self.off then return end
        self:SetChecked(not self:GetChecked(), true)
        if self.onToggle then self.onToggle(self:GetChecked()) end
    end)
    c:SetScript("OnEnter", function(self)
        self.hovered = true
        styleCheck(self)
        if not self.tip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function(self)
        self.hovered = false
        styleCheck(self)
        GameTooltip:Hide()
    end)
    styleCheck(c)
    return c
end

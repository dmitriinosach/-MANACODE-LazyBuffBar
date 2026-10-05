local ADDON, ns = ...
local CHK_FALLBACK = {
    box  = { tex = "Interface\\Buttons\\UI-CheckBox-Up" },
    mark = { tex = "Interface\\Buttons\\UI-CheckBox-Check" },
    boxColor      = { 1, 1, 1, 1 },
    boxColorHover = { 1, 1, 1, 1 },
    markColor     = { 1, 1, 1, 1 },
    label         = { 1, 1, 1 },
    labelHover    = { 1, 1, 1 },
}
local function styleCheck(c)
    local theme = ns.CurrentTheme and ns.CurrentTheme()
    local ck = (theme and theme.check) or CHK_FALLBACK
    local hot = c.hovered
    c.box:SetTexture(ck.box and ck.box.tex or CHK_FALLBACK.box.tex)
    if ck.box and ck.box.coord then
        c.box:SetTexCoord(ck.box.coord[1], ck.box.coord[2], ck.box.coord[3], ck.box.coord[4])
    end
    local bc = (hot and ck.boxColorHover or ck.boxColor) or CHK_FALLBACK.boxColor
    c.box:SetVertexColor(bc[1], bc[2], bc[3], bc[4])
    c.mark:SetTexture(ck.mark and ck.mark.tex or CHK_FALLBACK.mark.tex)
    local mc = ck.markColor or CHK_FALLBACK.markColor
    c.mark:SetVertexColor(mc[1], mc[2], mc[3], mc[4])
    local lc = (hot and ck.labelHover or ck.label) or CHK_FALLBACK.label
    c.label:SetTextColor(lc[1], lc[2], lc[3])
end
ns.StyleCheck = styleCheck
local made = {}
if ns.OnTheme then
    ns.OnTheme(function()
        for i = 1, #made do styleCheck(made[i]) end
    end)
end
function ns.MakeCheck(parent)
    local c = CreateFrame("Button", nil, parent)
    made[#made + 1] = c
    c:SetWidth(22)
    c:SetHeight(22)
    c.box = c:CreateTexture(nil, "ARTWORK")
    c.box:SetAllPoints(c)
    c.mark = c:CreateTexture(nil, "OVERLAY")
    c.mark:SetAllPoints(c)
    c.mark:Hide()
    c.label = c:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c.label:SetJustifyH("LEFT")
    function c:SetChecked(on)
        self.checked = on and true or false
        if self.checked then self.mark:Show() else self.mark:Hide() end
    end
    function c:GetChecked() return self.checked and true or false end
    c:SetScript("OnClick", function(self)
        self:SetChecked(not self:GetChecked())
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

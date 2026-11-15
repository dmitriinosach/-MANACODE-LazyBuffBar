local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLOW_TEX = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SPAN = 1.9
local FONT_PART = 0.42
local SMALL_PART = 0.3
local T = {}
ns.WTile = T
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
function T.New(layer, x, y, s)
    local o = { glowing = false }
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = layer:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(o.edge)
    o.pulse = CreateFrame("Frame", nil, top)
    o.pulse:SetAllPoints(o.edge)
    local g = o.pulse:CreateTexture(nil, "OVERLAY")
    g:SetTexture(GLOW_TEX)
    g:SetBlendMode("ADD")
    g:SetWidth(s * GLOW_SPAN)
    g:SetHeight(s * GLOW_SPAN)
    g:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    local c = ns.STATE.full
    g:SetVertexColor(c[1], c[2], c[3])
    o.pulse:Hide()
    o.text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    o.text:SetPoint("CENTER", o.edge, "CENTER", 0, 0)
    fontSize(o.text, s * FONT_PART)
    o.mark = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.mark:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 2, -2)
    fontSize(o.mark, s * SMALL_PART)
    o.corner = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.corner:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -2, 2)
    fontSize(o.corner, s * SMALL_PART)
    return o
end
function T.Paint(o, k)
    local W = ns.Widget
    local S = ns.STATE
    W.Tex(o.icon, k.icon or ns.QMARK, k.grey)
    W.Color(o.icon, k.tint or S.text)
    W.Alpha(o.icon, k.alpha or 1)
    W.Color(o.edge, k.edge or S.off)
    W.Alpha(o.edge, k.edge and 1 or 0)
    W.Text(o.text, k.text or "")
    W.Color(o.text, k.textColor or S.text)
    W.Text(o.mark, k.mark or "")
    W.Color(o.mark, k.markColor or S.text)
    W.Text(o.corner, k.corner or "")
    W.Color(o.corner, k.cornerColor or S.text)
    local go = k.glow and true or false
    if go ~= o.glowing then
        o.glowing = go
        if go then o.pulse:Show() else o.pulse:Hide() end
        ns.Anim.Pulse(o.pulse, go)
    end
end
function T.Left(gcd, start, dur)
    if not (start and dur) or start <= 0 or dur <= gcd then return 0 end
    local l = start + dur - GetTime()
    return l > 0 and l or 0
end
local colors = {}
function T.ClassColor(class)
    local key = class or ""
    local c = colors[key]
    if c then return c end
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
    c = cc and { cc.r, cc.g, cc.b, 1 } or ns.STATE.text
    colors[key] = c
    return c
end
ns.wtileLoaded = true

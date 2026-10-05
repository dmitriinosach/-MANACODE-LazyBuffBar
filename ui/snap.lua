local _, ns = ...
ns.Snap = {}
local TOL = 10
local LINE = 1
local GUIDE_COLOR = { 1, 0.25, 0.65, 0.9 }
local SCREEN_COLOR = { 0.3, 0.8, 1, 0.75 }
local drag
local guides
local lines = {}
local function uiScale()
    return UIParent:GetEffectiveScale()
end
local function rect(f)
    local k = f:GetEffectiveScale() / uiScale()
    return f:GetLeft() * k, f:GetTop() * k, f:GetRight() * k, f:GetBottom() * k
end
local function best(mine, targets)
    local hit
    for _, m in ipairs(mine) do
        for _, t in ipairs(targets) do
            local d = t.v - m
            if math.abs(d) <= TOL and (not hit or math.abs(d) < math.abs(hit.d)) then
                hit = { d = d, t = t }
            end
        end
    end
    return hit
end
local function targets(f, others)
    local w, h = UIParent:GetWidth(), UIParent:GetHeight()
    local xs = { { v = 0 }, { v = w / 2 }, { v = w } }
    local ys = { { v = 0 }, { v = h / 2 }, { v = h } }
    for _, o in pairs(others) do
        if o ~= f and o:IsShown() and o:GetLeft() then
            local l, t, r, b = rect(o)
            for _, v in ipairs({ l, (l + r) / 2, r }) do xs[#xs + 1] = { v = v, lo = b, hi = t } end
            for _, v in ipairs({ b, (b + t) / 2, t }) do ys[#ys + 1] = { v = v, lo = l, hi = r } end
        end
    end
    return xs, ys
end
local function line(n)
    if not guides then
        guides = CreateFrame("Frame", nil, UIParent)
        guides:SetAllPoints(UIParent)
        guides:SetFrameStrata("TOOLTIP")
    end
    local tx = lines[n]
    if not tx then
        tx = guides:CreateTexture(nil, "OVERLAY")
        tx:SetTexture("Interface\\Buttons\\WHITE8X8")
        lines[n] = tx
    end
    return tx
end
local function hideGuides()
    for _, tx in ipairs(lines) do tx:Hide() end
end
local function showGuide(n, vertical, hit, lo, hi)
    local tx = line(n)
    local t = hit.t
    local c = t.lo and GUIDE_COLOR or SCREEN_COLOR
    tx:SetVertexColor(c[1], c[2], c[3], c[4])
    tx:ClearAllPoints()
    local size = vertical and UIParent:GetHeight() or UIParent:GetWidth()
    local a, z = 0, size
    if t.lo then
        a = math.min(lo, t.lo) - 6
        z = math.max(hi, t.hi) + 6
    end
    if vertical then
        tx:SetPoint("BOTTOMLEFT", guides, "BOTTOMLEFT", t.v - LINE / 2, a)
        tx:SetWidth(LINE)
        tx:SetHeight(z - a)
    else
        tx:SetPoint("BOTTOMLEFT", guides, "BOTTOMLEFT", a, t.v - LINE / 2)
        tx:SetWidth(z - a)
        tx:SetHeight(LINE)
    end
    tx:Show()
end
local driver = CreateFrame("Frame")
driver:Hide()
local function step()
    local f = drag.frame
    local cx, cy = GetCursorPosition()
    local u = uiScale()
    cx, cy = cx / u, cy / u
    local l, t = cx - drag.ox, cy - drag.oy
    local r, b = l + drag.w, t - drag.h
    hideGuides()
    if not IsAltKeyDown() then
        local hx = best({ l, (l + r) / 2, r }, drag.xs)
        local hy = best({ b, (b + t) / 2, t }, drag.ys)
        local pull = ns.Look.Get("snap")
        if hx and pull then l, r = l + hx.d, r + hx.d end
        if hy and pull then t, b = t + hy.d, b + hy.d end
        if hx then showGuide(1, true, hx, b, t) end
        if hy then showGuide(2, false, hy, l, r) end
    end
    local k = u / f:GetEffectiveScale()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * k, t * k)
end
driver:SetScript("OnUpdate", function()
    if not drag then driver:Hide(); return end
    if not IsMouseButtonDown("LeftButton") then
        ns.Snap.Finish(drag.frame)
        return
    end
    step()
end)
function ns.Snap.Begin(f, others, onDrop)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    if not f:GetLeft() then return false end
    local l, t, r, b = rect(f)
    local cx, cy = GetCursorPosition()
    local u = uiScale()
    local xs, ys = targets(f, others)
    drag = { frame = f, ox = cx / u - l, oy = cy / u - t, w = r - l, h = t - b,
             xs = xs, ys = ys, onDrop = onDrop }
    driver:Show()
    return true
end
function ns.Snap.Finish(f)
    if not drag or drag.frame ~= f then return false end
    step()
    local onDrop = drag.onDrop
    drag = nil
    driver:Hide()
    hideGuides()
    if onDrop then onDrop(f) end
    return true
end
function ns.Snap.Held()
    return drag and drag.frame or nil
end
ns.snapLoaded = true

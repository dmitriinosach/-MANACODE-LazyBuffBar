local _, ns = ...
ns.Gauge = {}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROUND = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local FLASH_TIME = 0.35
local CAP = 10
local RING = 12
local KINDS = { digits = true, pips = true, segments = true, ring = true, fill = true, bar = true }
local DIVIDED = { pips = true, segments = true, ring = true }
local RIM = 1
local RIM_C = { 0, 0, 0, 0.9 }
local Gauge = {}
Gauge.__index = Gauge
local active = {}
local running = {}
local driver = CreateFrame("Frame")
driver:Hide()
ns.Gauge.driver = driver
local function rgba(c, d)
    c = c or d
    return { c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 }
end
local function onColor(g)
    if g.full then return g.fullC end
    return g.color
end
local function paintPart(p, c)
    if p.c == c then return end
    p.c = c
    p.tex:SetVertexColor(c[1], c[2], c[3], c[4])
end
local function fraction(g)
    local m = g.maxv or 0
    if m <= 0 then return 0 end
    local f = (g.v or 0) / m
    if f < 0 then return 0 end
    if f > 1 then return 1 end
    return f
end
local function divisions(g)
    local m = math.floor((g.maxv or 0) + 0.5)
    if g.kind == "ring" then
        if g.spec.segs then return g.spec.segs end
        if m >= 3 and m <= RING then return m end
        return RING
    end
    if m < 1 then return 1 end
    if m > CAP then return CAP end
    return m
end
local function part(g, i)
    local p = g.parts[i]
    if p then return p end
    local tex = g.fr:CreateTexture(nil, "ARTWORK")
    local file = (g.kind == "pips" or g.kind == "ring") and ROUND or WHITE
    tex:SetTexture(file)
    p = { tex = tex }
    if g.spec.rim and DIVIDED[g.kind] then
        local rim = g.fr:CreateTexture(nil, "BORDER")
        rim:SetTexture(file)
        rim:SetVertexColor(RIM_C[1], RIM_C[2], RIM_C[3], RIM_C[4])
        rim:SetPoint("TOPLEFT", tex, "TOPLEFT", -RIM, RIM)
        rim:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", RIM, -RIM)
        p.rim = rim
    end
    g.parts[i] = p
    return p
end
local function placeTicks(g)
    local list = g.tickV or {}
    local w, h = g.spec.w, g.spec.h
    for i, v in ipairs(list) do
        local t = g.ticks[i]
        if not t then
            t = g.fr:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            t:SetVertexColor(0, 0, 0, 0.85)
            g.ticks[i] = t
        end
        local m = g.maxv or 0
        if m > 0 and v > 0 and v < m then
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", g.fr, "TOPLEFT", math.floor(w * v / m + 0.5), 0)
            t:SetWidth(1)
            t:SetHeight(h)
            t:Show()
        else
            t:Hide()
        end
    end
    for i = #list + 1, #g.ticks do g.ticks[i]:Hide() end
end
local function layout(g)
    local w, h, gap = g.spec.w, g.spec.h, g.spec.gap or 2
    g.fr:SetWidth(w)
    g.fr:SetHeight(h)
    local k = g.kind
    if g.fs then
        local file, _, flags = g.fs:GetFont()
        local px = g.spec.font or math.max(8, math.floor(h * (k == "bar" and 0.8 or 0.6) + 0.5))
        if file then g.fs:SetFont(file, px, flags ~= "" and flags or "OUTLINE") end
    end
    if k == "pips" or k == "segments" or k == "ring" then
        local n = divisions(g)
        g.n = n
        if k == "ring" then
            local d = math.min(w, h)
            local s = math.max(2, math.floor(d * 0.16 + 0.5))
            local r = d / 2 - s / 2
            for i = 1, n do
                local p = part(g, i)
                local a = math.pi / 2 - (i - 0.5) * 2 * math.pi / n
                p.tex:ClearAllPoints()
                p.tex:SetPoint("CENTER", g.fr, "CENTER", r * math.cos(a), r * math.sin(a))
                p.tex:SetWidth(s)
                p.tex:SetHeight(s)
                p.tex:Show()
                if p.rim then p.rim:Show() end
            end
        else
            local size = (w - (n - 1) * gap) / n
            local dh = h
            if k == "pips" then
                size = math.min(size, h)
                dh = size
            end
            local span = n * size + (n - 1) * gap
            local x0 = (w - span) / 2
            for i = 1, n do
                local p = part(g, i)
                p.tex:ClearAllPoints()
                p.tex:SetPoint("LEFT", g.fr, "LEFT", x0 + (i - 1) * (size + gap), 0)
                p.tex:SetWidth(size)
                p.tex:SetHeight(dh)
                p.tex:Show()
                if p.rim then p.rim:Show() end
            end
        end
        for i = n + 1, #g.parts do
            local p = g.parts[i]
            p.tex:Hide()
            if p.rim then p.rim:Hide() end
        end
    elseif k == "fill" or k == "bar" then
        local p = part(g, 1)
        p.tex:ClearAllPoints()
        if k == "fill" then
            p.tex:SetPoint("BOTTOMLEFT", g.fr, "BOTTOMLEFT", 0, 0)
            p.tex:SetPoint("BOTTOMRIGHT", g.fr, "BOTTOMRIGHT", 0, 0)
        else
            p.tex:SetPoint("TOPLEFT", g.fr, "TOPLEFT", 0, 0)
            p.tex:SetPoint("BOTTOMLEFT", g.fr, "BOTTOMLEFT", 0, 0)
            placeTicks(g)
        end
        g.n = 1
    end
    for _, p in ipairs(g.parts) do p.c = nil end
    g.fillPx = nil
end
local function paint(g)
    local k = g.kind
    if k == "digits" then
        local v = math.floor((g.v or 0) + 0.5)
        local s = (v ~= 0 or g.spec.zero) and tostring(v) or ""
        if s ~= g.shownText then
            g.shownText = s
            g.fs:SetText(s)
        end
        local c = onColor(g)
        if g.fsC ~= c then
            g.fsC = c
            g.fs:SetTextColor(c[1], c[2], c[3], c[4])
        end
        return
    end
    if k == "fill" or k == "bar" then
        local p = g.parts[1]
        local f = fraction(g)
        local size = (k == "fill") and g.spec.h or g.spec.w
        local px = math.floor(size * f * 2 + 0.5) / 2
        if px ~= g.fillPx then
            g.fillPx = px
            if px <= 0 then
                p.tex:Hide()
            else
                if k == "fill" then p.tex:SetHeight(px) else p.tex:SetWidth(px) end
                p.tex:Show()
            end
        end
        paintPart(p, onColor(g))
        if g.fs then
            local s = tostring(math.floor((g.v or 0) + 0.5))
            if s ~= g.shownText then
                g.shownText = s
                g.fs:SetText(s)
            end
        end
        return
    end
    local n = g.n
    local lit = math.floor(fraction(g) * n + 0.5)
    if g.kind ~= "ring" and (g.maxv or 0) <= n then lit = math.min(n, math.floor((g.v or 0) + 0.5)) end
    if lit < 0 then lit = 0 end
    g.lit = lit
    local on = onColor(g)
    for i = 1, n do paintPart(g.parts[i], i <= lit and on or g.offC) end
end
local function mix(a, b, t)
    return a + (b - a) * t
end
local function flashStep(g, t)
    local c = g.fullC
    local r, gg, b = mix(c[1], 1, t), mix(c[2], 1, t), mix(c[3], 1, t)
    if g.kind == "digits" then
        g.fs:SetTextColor(r, gg, b, c[4])
        g.fsC = nil
        return
    end
    local upto = (g.kind == "fill" or g.kind == "bar") and 1 or g.lit
    for i = 1, upto do
        local p = g.parts[i]
        p.tex:SetVertexColor(r, gg, b, c[4])
        p.c = nil
    end
end
driver:SetScript("OnUpdate", function(self, elapsed)
    for g in pairs(active) do
        g.flashT = (g.flashT or 0) + (elapsed or 0)
        local p = g.flashT / FLASH_TIME
        if p >= 1 or not g.full then
            g.flashT = nil
            active[g] = nil
            paint(g)
        else
            flashStep(g, 0.7 * (1 - p))
        end
    end
    if next(running) ~= nil then
        local now = GetTime()
        for g in pairs(running) do
            local r = g.run
            local f = r and (now - r.start) / r.dur or 1
            if f >= 1 then running[g] = nil end
            if r then g:Set(r.max * math.max(0, math.min(1, f)), r.max) end
        end
    end
    if next(active) == nil and next(running) == nil then self:Hide() end
end)
local function flash(g)
    if g.spec.flash == false then return end
    g.flashT = 0
    active[g] = true
    flashStep(g, 0.7)
    driver:Show()
end
function ns.Gauge.New(parent, kind, spec)
    if not KINDS[kind] then kind = "digits" end
    spec = spec or {}
    local s = {}
    for key, v in pairs(spec) do s[key] = v end
    s.w, s.h = s.w or 32, s.h or 32
    local fr = CreateFrame("Frame", nil, parent)
    local g = setmetatable({
        kind = kind, spec = s, fr = fr, parts = {}, ticks = {}, n = 0, lit = 0, full = false,
        maxv = s.max or 5, v = nil,
    }, Gauge)
    g.color = rgba(s.color, { 1, 0.82, 0, 1 })
    g.fullC = s.full and rgba(s.full, g.color) or g.color
    g.offC = rgba(s.off, { 0.22, 0.24, 0.32, 0.9 })
    if kind == "fill" or kind == "bar" then
        local bg = fr:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(WHITE)
        bg:SetAllPoints(fr)
        local c = rgba(s.bg, { 0, 0, 0, kind == "bar" and 0.6 or 0 })
        bg:SetVertexColor(c[1], c[2], c[3], c[4])
        g.bg = bg
    end
    if kind == "digits" or (kind == "bar" and s.text) then
        g.fs = fr:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        if kind == "bar" then
            g.fs:SetPoint("RIGHT", fr, "RIGHT", -2, 0)
            g.fs:SetJustifyH("RIGHT")
        else
            g.fs:SetPoint("CENTER", fr, "CENTER", 0, 0)
        end
    end
    g.tickV = s.ticks
    layout(g)
    g.v = 0
    paint(g)
    return g
end
function Gauge:Set(v, max)
    v = tonumber(v) or 0
    max = tonumber(max) or self.maxv or 0
    if v == self.v and max == self.maxv then return false end
    local wasFull = self.full
    if max ~= self.maxv then
        self.maxv = max
        if self.kind ~= "digits" then layout(self) end
    end
    self.v = v
    self.full = max > 0 and v >= max
    if self.full ~= wasFull then
        for _, p in ipairs(self.parts) do p.c = nil end
        self.fsC = nil
    end
    paint(self)
    if self.full and not wasFull and v > 0 then flash(self) end
    return true
end
function Gauge:SetColor(r, g, b, a, full)
    local cur = full and self.fullC or self.color
    if cur[1] == r and cur[2] == g and cur[3] == b and cur[4] == (a or 1) then return end
    local c = { r, g, b, a or 1 }
    if full then
        self.fullC = c
    else
        if self.fullC == self.color then self.fullC = c end
        self.color = c
    end
    paint(self)
end
function Gauge:SetSize(w, h)
    if w == self.spec.w and h == self.spec.h then return end
    self.spec.w, self.spec.h = w, h
    layout(self)
    paint(self)
end
function Gauge:SetTicks(list)
    if self.kind ~= "bar" then return end
    local old = self.tickV or {}
    list = list or {}
    local same = #old == #list
    for i = 1, #list do if old[i] ~= list[i] then same = false end end
    if same then return end
    self.tickV = list
    placeTicks(self)
end
function Gauge:Run(start, dur, max)
    if not start or not dur or dur <= 0 then
        if not self.run then return false end
        self.run = nil
        running[self] = nil
        return true
    end
    max = tonumber(max) or self.maxv or 0
    local r = self.run
    if r and r.start == start and r.dur == dur and r.max == max then return false end
    self.run = { start = start, dur = dur, max = max }
    local f = (GetTime() - start) / dur
    self:Set(max * math.max(0, math.min(1, f)), max)
    if f < 1 then
        running[self] = true
        driver:Show()
    else
        running[self] = nil
    end
    return true
end
function Gauge:Running() return running[self] == true end
function Gauge:Show() self.fr:Show() end
function Gauge:Hide() self.fr:Hide() end
function Gauge:Frame() return self.fr end
function Gauge:Flashing() return active[self] == true end
ns.gaugeLoaded = true

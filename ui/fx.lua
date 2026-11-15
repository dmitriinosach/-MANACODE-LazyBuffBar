local _, ns = ...
ns.FX = {}
local MAX_GHOSTS = 60
local CROP = { 0.07, 0.93, 0.07, 0.93 }
local FULL = { 0, 1, 0, 1 }
local FLASH_TEX = "Interface\\Cooldown\\star4"
local WAVE_TEX  = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local SPARK_TEX = "Interface\\Buttons\\WHITE8X8"
local QUAD = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }
local CORE = { 1.00, 0.97, 0.90 }
local HALO = { 0.45, 0.70, 1.00 }
local GONE = { 0.6, 0.6, 0.6 }
local SPARKS  = 8
local FLASH_T = 0.26
local WAVE_T  = 0.40
local SHARD_T = 0.55
local SPARK_T = 0.45
local PULSE_T = 0.3
local SHINE_T = 0.5
local BURST_T = 0.32
local SHRINK_T = 0.2
function ns.FX.Level()
    return ns.Look and ns.Look.Get("fx") or "full"
end
local pool
local function newGhost()
    local f = CreateFrame("Frame", nil, UIParent)
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetAllPoints(f)
    f.anim = f:CreateAnimationGroup()
    f.move = f.anim:CreateAnimation("Translation")
    f.grow = f.anim:CreateAnimation("Scale")
    f.fade = f.anim:CreateAnimation("Alpha")
    f.anim:SetScript("OnFinished", function() f:Hide() end)
    return f
end
function ns.FX.Ghost(parent, x, y, size, tex, crop)
    pool = pool or ns.NewPool(newGhost, nil, MAX_GHOSTS)
    local f = pool:Acquire()
    f:SetParent(parent)
    f:SetFrameLevel(parent:GetFrameLevel() + 40)
    f:SetWidth(size); f:SetHeight(size)
    f:ClearAllPoints()
    f:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
    f:SetAlpha(1)
    f:SetScale(1)
    f.tex:SetTexture(tex)
    f.tex:SetVertexColor(1, 1, 1)
    f.tex:SetBlendMode("BLEND")
    crop = crop or CROP
    f.tex:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
    f.tex:SetAlpha(1)
    f.move:SetStartDelay(0); f.grow:SetStartDelay(0); f.fade:SetStartDelay(0)
    f.move:SetSmoothing("NONE"); f.grow:SetSmoothing("NONE"); f.fade:SetSmoothing("NONE")
    f.move:SetOffset(0, 0); f.move:SetDuration(0)
    f.anim:Stop()
    return f
end
local function flying()
    if not pool then return 0 end
    local n = 0
    for i = 1, pool:Size() do
        if pool.items[i]:IsShown() then n = n + 1 end
    end
    return n
end
function ns.FX.Nova(parent, x, y, size, tex, scale)
    if not parent then return end
    scale = scale or 1
    local wave = ns.FX.Ghost(parent, x, y, size, WAVE_TEX, FULL)
    wave.tex:SetBlendMode("ADD")
    wave.tex:SetVertexColor(HALO[1], HALO[2], HALO[3])
    wave:SetAlpha(0.8)
    wave.move:SetDuration(WAVE_T)
    wave.grow:SetScale(3.2, 3.2)
    wave.grow:SetDuration(WAVE_T)
    wave.grow:SetSmoothing("OUT")
    ns.AlphaChange(wave.fade, -1)
    wave.fade:SetDuration(WAVE_T)
    wave.anim:Play()
    local flash = ns.FX.Ghost(parent, x, y, size * 1.1, FLASH_TEX, FULL)
    flash.tex:SetBlendMode("ADD")
    flash.tex:SetVertexColor(CORE[1], CORE[2], CORE[3])
    flash.move:SetDuration(FLASH_T)
    flash.grow:SetScale(2.4, 2.4)
    flash.grow:SetDuration(FLASH_T)
    flash.grow:SetSmoothing("OUT")
    ns.AlphaChange(flash.fade, -1)
    flash.fade:SetDuration(FLASH_T)
    flash.anim:Play()
    if tex and scale >= 0.75 then
        local w, h = CROP[2] - CROP[1], CROP[4] - CROP[3]
        local half = size / 2
        for q = 1, 4 do
            local qx, qy = QUAD[q][1], QUAD[q][2]
            local crop = {
                CROP[1] + w * qx / 2, CROP[1] + w * (qx + 1) / 2,
                CROP[3] + h * qy / 2, CROP[3] + h * (qy + 1) / 2,
            }
            local ox = x + (qx == 0 and -half / 2 or half / 2)
            local oy = y + (qy == 0 and half / 2 or -half / 2)
            local f = ns.FX.Ghost(parent, ox, oy, half, tex, crop)
            f.tex:SetVertexColor(0.8, 0.85, 1)
            local a = math.atan2(oy - y, ox - x) + (math.random() - 0.5) * 0.5
            local d = size * (0.9 + math.random() * 0.8)
            f.move:SetOffset(math.cos(a) * d, math.sin(a) * d)
            f.move:SetDuration(SHARD_T)
            f.move:SetSmoothing("OUT")
            f.grow:SetScale(0.35, 0.35)
            f.grow:SetDuration(SHARD_T)
            ns.AlphaChange(f.fade, -1)
            f.fade:SetDuration(SHARD_T * 0.5)
            f.fade:SetStartDelay(SHARD_T * 0.5)
            f.anim:Play()
        end
    end
    local sparks = math.max(3, math.floor(SPARKS * scale + 0.5))
    for i = 1, sparks do
        local a = (i - 1) / sparks * math.pi * 2 + math.random() * 0.7
        local d = size * (1.2 + math.random() * 1.3)
        local sz = 2 + math.random(2)
        local c = (i % 2 == 0) and CORE or HALO
        local f = ns.FX.Ghost(parent, x, y, sz, SPARK_TEX, FULL)
        f.tex:SetBlendMode("ADD")
        f.tex:SetVertexColor(c[1], c[2], c[3])
        f.move:SetOffset(math.cos(a) * d, math.sin(a) * d)
        f.move:SetDuration(SPARK_T)
        f.move:SetSmoothing("OUT")
        f.grow:SetScale(0.4, 0.4)
        f.grow:SetDuration(SPARK_T)
        ns.AlphaChange(f.fade, -1)
        f.fade:SetDuration(SPARK_T * 0.6)
        f.fade:SetStartDelay(SPARK_T * 0.4)
        f.anim:Play()
    end
end
function ns.FX.Pulse(parent, x, y, size, tex)
    local f = ns.FX.Ghost(parent, x, y, size, tex)
    f.tex:SetBlendMode("ADD")
    f:SetAlpha(0.7)
    f.grow:SetScale(1.8, 1.8)
    f.grow:SetDuration(PULSE_T)
    f.grow:SetSmoothing("OUT")
    ns.AlphaChange(f.fade, -0.7)
    f.fade:SetDuration(PULSE_T)
    f.anim:Play()
end
function ns.FX.Shine(parent, x, y, size)
    local f = ns.FX.Ghost(parent, x, y, size, FLASH_TEX, FULL)
    f.tex:SetBlendMode("ADD")
    f.tex:SetVertexColor(CORE[1], CORE[2], CORE[3])
    f.grow:SetScale(3, 3)
    f.grow:SetDuration(SHINE_T)
    f.grow:SetSmoothing("OUT")
    ns.AlphaChange(f.fade, -1)
    f.fade:SetDuration(SHINE_T)
    f.fade:SetSmoothing("IN")
    f.anim:Play()
end
function ns.FX.Burst(parent, x, y, size, tex)
    local f = ns.FX.Ghost(parent, x, y, size, tex)
    f.grow:SetScale(1.35, 1.35)
    f.grow:SetDuration(BURST_T)
    ns.AlphaChange(f.fade, -1)
    f.fade:SetDuration(BURST_T)
    f.anim:Play()
end
function ns.FX.Shrink(parent, x, y, size, tex)
    local f = ns.FX.Ghost(parent, x, y, size, tex)
    f.tex:SetVertexColor(GONE[1], GONE[2], GONE[3])
    f.grow:SetScale(0.1, 0.1)
    f.grow:SetDuration(SHRINK_T)
    f.grow:SetSmoothing("IN")
    ns.AlphaChange(f.fade, -1)
    f.fade:SetDuration(SHRINK_T)
    f.anim:Play()
end
local PLAY = {
    ready = { full = "Nova",   plain = "Pulse" },
    proc  = { full = "Burst",  plain = "Pulse" },
    gone  = { full = "Shrink", plain = "Shrink" },
}
local COST = { Nova = 14, Burst = 1, Pulse = 1, Shine = 1, Shrink = 1 }
function ns.FX.Icon(event, f)
    local level = ns.FX.Level()
    if level == "off" then return end
    local row = PLAY[event]
    if not row then return end
    local parent = f:GetParent()
    local cx, cy = f:GetCenter()
    local pl, pb = parent and parent:GetLeft(), parent and parent:GetBottom()
    if not (cx and cy and pl and pb) then return end
    local x, y = cx - pl, cy - pb
    local size = f:GetWidth()
    local tex = f.tex:GetTexture()
    local name = row[level] or row.plain
    if flying() + (COST[name] or 1) > MAX_GHOSTS then name = row.plain end
    if name == "Nova" then
        ns.FX.Nova(parent, x, y, size, tex, 1)
    elseif name == "Burst" then
        ns.FX.Burst(parent, x, y, size, tex)
        ns.FX.Shine(parent, x, y, size)
    elseif name == "Pulse" then
        ns.FX.Pulse(parent, x, y, size, tex)
    elseif name == "Shrink" then
        ns.FX.Shrink(parent, x, y, size, tex)
    end
end
ns.fxLoaded = true

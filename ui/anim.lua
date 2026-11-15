local _, ns = ...
ns.Anim = {}
local FADE_TIME = 0.25
local function isFrame(f)
    return type(f) == "table"
        and type(f.CreateAnimationGroup) == "function"
        and type(f.GetCenter) == "function"
end
local function seconds(v, d)
    if type(v) == "number" and v > 0 then return v end
    return d
end
local function unit(v, d)
    if type(v) ~= "number" then return d end
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end
local function fire(fn)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn)
    if not ok then geterrorhandler()(err) end
end
local function settle(a, natural)
    if not a.playing then return end
    a.playing = false
    local finish, onDone = a.finish, a.onDone
    a.finish, a.onDone = nil, nil
    if not natural then a.group:Stop() end
    if finish then finish(a.frame) end
    if natural then fire(onDone) end
end
local function slot(frame)
    local a = frame.lbbAnim
    if a then return a end
    local group = frame:CreateAnimationGroup()
    a = { frame = frame, group = group, fade = group:CreateAnimation("Alpha"), playing = false }
    a.fade:SetOrder(1)
    group:SetScript("OnFinished", function() settle(a, true) end)
    frame.lbbAnim = a
    return a
end
function ns.Anim.Fade(frame, from, to, dur, onDone)
    if not isFrame(frame) then return false end
    local keep = frame:GetAlpha()
    from = unit(from, keep)
    to = unit(to, 1)
    if to == 0 and not frame:IsShown() then
        fire(onDone)
        return true
    end
    local a = slot(frame)
    settle(a, false)
    dur = seconds(dur, FADE_TIME)
    ns.AlphaChange(a.fade, to - from)
    a.fade:SetDuration(dur)
    a.fade:SetStartDelay(0)
    a.fade:SetSmoothing("NONE")
    if to > 0 then
        a.finish = function(f) f:SetAlpha(to) end
    else
        a.finish = function(f) f:Hide(); f:SetAlpha(keep) end
    end
    a.onDone = type(onDone) == "function" and onDone or nil
    a.playing = true
    frame:SetAlpha(from)
    frame:Show()
    a.group:Play()
    return true
end
function ns.Anim.Stop(frame)
    if not isFrame(frame) then return end
    local a = frame.lbbAnim
    if a then settle(a, false) end
end
function ns.Anim.Busy(frame)
    if not isFrame(frame) then return false end
    local a = frame.lbbAnim
    return a ~= nil and a.playing == true
end
local PULSE_TIME = 1.2
local PULSE_LOW = 0.45
local pulsing = {}
local pulseT = 0
local pulser = CreateFrame("Frame")
pulser:Hide()
pulser:SetScript("OnUpdate", function(self, elapsed)
    pulseT = (pulseT + (elapsed or 0)) % PULSE_TIME
    local a = PULSE_LOW + (1 - PULSE_LOW) * (0.5 + 0.5 * math.sin(pulseT / PULSE_TIME * 2 * math.pi))
    local any = false
    for f in pairs(pulsing) do
        any = true
        f:SetAlpha(a)
    end
    if not any then self:Hide() end
end)
function ns.Anim.Pulse(frame, on)
    if on then
        if pulsing[frame] then return end
        pulsing[frame] = true
        pulser:Show()
    elseif pulsing[frame] then
        pulsing[frame] = nil
        frame:SetAlpha(1)
    end
end
function ns.Anim.Pulsing()
    local n = 0
    for _ in pairs(pulsing) do n = n + 1 end
    return n, pulser
end
ns.animLoaded = true

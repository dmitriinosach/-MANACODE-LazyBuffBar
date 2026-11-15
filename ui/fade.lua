local _, ns = ...
local TICK = 0.1
local FADE = 0.25
local UNLOCKED_MIN = 0.35
local OFF_ALPHA = 0.25
local HOVER_PAD = 6
local acc = 0
local function target(fr, i, combat)
    local a = ns.Look.Bar(i, "alpha")
    local b = ns.Preset.Blocks()[i]
    if not ns.buffbar:IsLocked() then
        if ns.buffbar:IsBarOff(i) then return OFF_ALPHA end
        if b and b.cond and not ns.Cond.AllowsAll(b.cond) then return OFF_ALPHA end
        return (a > UNLOCKED_MIN) and a or UNLOCKED_MIN
    end
    if b and b.cond and b.cond.rules and not ns.Cond.RulesPass(b.cond.rules) then return 0 end
    if fr:IsMouseOver(HOVER_PAD, -HOVER_PAD, -HOVER_PAD, HOVER_PAD) then return a end
    return a * ns.Look.Bar(i, combat and "fight" or "idle")
end
local fader = CreateFrame("Frame")
fader:SetScript("OnUpdate", function(self, elapsed)
    acc = acc + elapsed
    if acc < TICK then return end
    local dt = acc
    acc = 0
    if not (ns.buffbar and ns.buffbar.Panels and ns.Look) then return end
    ns.Cond.Flush()
    local combat = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
    local step = dt / FADE
    for _, p in ipairs(ns.buffbar:Panels()) do
        local want = target(p.frame, p.index, combat)
        local cur = p.frame:GetAlpha()
        if math.abs(cur - want) > 0.005 then
            if cur < want then
                cur = cur + step
                if cur > want then cur = want end
            else
                cur = cur - step
                if cur < want then cur = want end
            end
            p.frame:SetAlpha(cur)
        end
    end
end)
ns.fadeLoaded = true

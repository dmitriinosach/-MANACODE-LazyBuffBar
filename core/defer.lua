local _, ns = ...
local queue = {}
local slots = {}
function ns.Defer(fn)
    if not InCombatLockdown() then
        fn()
        return true
    end
    queue[#queue + 1] = fn
    return false
end
function ns.DeferKey(key, fn)
    if not InCombatLockdown() then
        fn()
        return true
    end
    local e = slots[key]
    if e then
        e.fn = fn
        return false
    end
    e = { fn = fn }
    slots[key] = e
    queue[#queue + 1] = function()
        if slots[key] ~= e then return end
        slots[key] = nil
        e.fn()
    end
    return false
end
function ns.DeferHas(key)
    return slots[key] ~= nil
end
function ns.DeferDrop(key)
    slots[key] = nil
end
function ns.DeferPending()
    return #queue > 0
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function()
    if #queue == 0 then return end
    local run = queue
    queue = {}
    for i = 1, #run do
        local ok, err = pcall(run[i])
        if not ok then geterrorhandler()(err) end
    end
end)
ns.deferLoaded = true

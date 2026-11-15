local _, ns = ...
local NAME = "shaman_enh_magma"
local FIRE = 1
local LOG = "COMBAT_LOG_EVENT_UNFILTERED"
local M = {}
ns.EnhMagma = M
local shaman = false
local listening = false
local listenAt = nil
local playerGUID = nil
local summon = nil
local totemStart = nil
local lastAny = nil
local seenGUID, seenAt = nil, nil
local hits = {}
local function data()
    return ns.widgetData.shaman_enh_magma
end
local function ours(name, icon)
    for _, id in ipairs(data().totems) do
        local sname, _, sicon = GetSpellInfo(id)
        if (sname and name:sub(1, #sname) == sname) or (icon and sicon and icon == sicon) then return true end
    end
    return false
end
local function fireStart()
    local _, name, start, dur, icon = GetTotemInfo(FIRE)
    if name and name ~= "" and start and dur and dur > 0 and start + dur > GetTime() and ours(name, icon) then return start end
    return nil
end
local function hosted()
    for _, h in ipairs(ns.Widget.Hosts()) do
        if h.name == NAME then return true end
    end
    return false
end
local watch = CreateFrame("Frame")
local function forget()
    hits = {}
    lastAny = nil
end
local function start()
    if listening then return end
    listening, listenAt = true, GetTime()
    watch:RegisterEvent(LOG)
end
local function stop()
    if not listening then return end
    listening, listenAt = false, nil
    watch:UnregisterEvent(LOG)
    forget()
end
local function sync(fight)
    local s = fireStart()
    if s ~= totemStart then
        totemStart = s
        forget()
    end
    if shaman and s and fight and hosted() then start() else stop() end
end
local function hit(dst, now)
    local before = hits[dst] or listenAt or now
    hits[dst], lastAny = now, now
    if now - before >= data().miss - 1 then ns.Widget.Poke(NAME) end
end
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("PLAYER_TOTEM_UPDATE")
watch:RegisterEvent("PLAYER_REGEN_DISABLED")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:SetScript("OnEvent", function(_, event, a1, sub, src, _, flags, dst, _, _, spellId)
    if event == LOG then
        if sub == "SPELL_DAMAGE" or sub == "SPELL_MISSED" then
            if not data().hits[spellId] then return end
            if src ~= summon and (flags or 0) % 2 ~= 1 then return end
            hit(dst, GetTime())
        elseif sub == "SPELL_SUMMON" and src == playerGUID and data().summons[spellId] then
            summon = dst
        end
        return
    end
    if event == "PLAYER_TOTEM_UPDATE" and a1 ~= FIRE then return end
    if event == "PLAYER_ENTERING_WORLD" then
        local _, class = UnitClass("player")
        shaman = class == "SHAMAN"
        playerGUID = UnitGUID("player")
    end
    if event == "PLAYER_REGEN_ENABLED" then
        stop()
        return
    end
    sync(event == "PLAYER_REGEN_DISABLED" or UnitAffectingCombat("player") and true or false)
end)
function M.Watch()
    if listening or not shaman then return end
    if fireStart() and UnitAffectingCombat("player") then start() end
end
M.Ours = ours
function M.Since(guid)
    if not listenAt or not guid then return listenAt end
    if guid ~= seenGUID then seenGUID, seenAt = guid, GetTime() end
    return math.max(listenAt, seenAt)
end
function M.Hit(guid)
    return guid and hits[guid] or nil
end
function M.Any()
    return lastAny
end
ns.shamanEnhMagmaCoreLoaded = true

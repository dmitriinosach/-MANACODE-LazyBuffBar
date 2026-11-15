local _, ns = ...
local function placeGroup(key)
    local bars = LazyBuffBarDB.bars
    if not bars then return end
    for _, bc in ipairs(bars) do
        for _, k in ipairs(bc.groups or {}) do
            if k == key then return end
        end
    end
    local first = bars[1]
    if first and first.groups then tinsert(first.groups, key) end
end
local OLD_TIPS = { "tipMode", "tipNotes", "helpTips" }
local function moveTips(look)
    if type(look) ~= "table" then return end
    local novice = look.tipMode == "full" or look.tipNotes == true or look.helpTips == true
    for _, k in ipairs(OLD_TIPS) do look[k] = nil end
    if novice then look.novice = true end
end
function ns.InitDB()
    if type(LazyBuffBarDB) ~= "table" then LazyBuffBarDB = {} end
    moveTips(LazyBuffBarDB.look)
    if type(LazyBuffBarDB.look) == "table" and not next(LazyBuffBarDB.look) then LazyBuffBarDB.look = nil end
    if LazyBuffBarDB.show == nil then LazyBuffBarDB.show = true end
    if LazyBuffBarDB.locked == nil then LazyBuffBarDB.locked = false end
    LazyBuffBarDB.hide = nil
    if not LazyBuffBarDB.wantPlaced then
        LazyBuffBarDB.wantPlaced = true
        placeGroup("want")
    end
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    ns.ApplyLocale()
    ns.InitDB()
    ns.buffbar:Init()
    ns.BuildOptions()
    ns.Chrome.Init()
end)
ns.initLoaded = true

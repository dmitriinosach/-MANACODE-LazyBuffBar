local ADDON, ns = ...
local PREFIX = "|cff33ff99lbb|r"
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " " .. tostring(msg))
end
function ns.PlayerClass()
    local _, class = UnitClass("player")
    return class or "?"
end
ns.window = {}
function ns.window:GetSkin()
    return (LazyBuffBarDB and LazyBuffBarDB.skin) or (ns.themeOrder and ns.themeOrder[1])
end
function ns.CurrentTheme()
    return ns.themes and ns.themes[ns.window:GetSkin()]
end
local AREA_INSTANCE = { IcecrownCitadel = "icc" }
function ns.CurrentInstance()
    if not IsInInstance() then return nil end
    if WorldMapFrame and WorldMapFrame:IsShown() then return nil end
    SetMapToCurrentZone()
    return AREA_INSTANCE[GetMapInfo() or ""]
end
ns.compatLoaded = true

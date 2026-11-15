local _, ns = ...
local PREFIX = "|cff33ff99lbb|r"
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. " " .. tostring(msg))
end
function ns.PlayerClass()
    local _, class = UnitClass("player")
    return class or "?"
end
function ns.SkinKey()
    return (LazyBuffBarDB and LazyBuffBarDB.skin) or (ns.themeOrder and ns.themeOrder[1])
end
function ns.CurrentTheme()
    return ns.themes and ns.themes[ns.SkinKey()]
end
function ns.AlphaChange(anim, delta)
    anim:SetChange(delta)
end
ns.compatLoaded = true

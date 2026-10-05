local ADDON, ns = ...
local SOURCE = "LazyBuffBar"
local function busReady()
    return type(HTP_Notify_API) == "table"
        and type(HTP_Notify_API.Notify) == "function"
end
function ns.Notify(payload)
    if type(payload) ~= "table" then return false end
    if type(payload.text) ~= "string" or payload.text == "" then return false end
    if busReady() then
        local ok, took = pcall(HTP_Notify_API.Notify, SOURCE, payload)
        if ok and took then return true end
        if ok then return false end
    end
    local head = payload.title and payload.title ~= "" and (payload.title .. ": ") or ""
    ns.say(head .. payload.text)
    return true
end
ns.notifyLoaded = true

local _, ns = ...
local SCREEN = { 1, 0.82, 0 }
function ns.Notify(payload)
    if type(payload) ~= "table" then return false end
    if type(payload.text) ~= "string" or payload.text == "" then return false end
    local head = payload.title and payload.title ~= "" and (payload.title .. ": ") or ""
    ns.say(head .. payload.text)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(payload.text, SCREEN[1], SCREEN[2], SCREEN[3])
    end
    return true
end
ns.notifyLoaded = true

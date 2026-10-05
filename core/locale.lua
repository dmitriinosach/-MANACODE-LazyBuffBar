local ADDON, ns = ...
ns.locales = ns.locales or {}
ns.L = ns.L or {}
local function flatten(src, prefix, out)
    for k, v in pairs(src) do
        local key = prefix and (prefix .. "." .. k) or k
        if type(v) == "table" then
            flatten(v, key, out)
        else
            out[key] = v
        end
    end
    return out
end
function ns.CurrentLocale()
    local code = GetLocale()
    return ns.locales[code] and code or "enUS"
end
function ns.ApplyLocale()
    wipe(ns.L)
    flatten(ns.locales.ruRU or {}, nil, ns.L)
    local code = ns.CurrentLocale()
    if code ~= "ruRU" and ns.locales[code] then
        for k, v in pairs(flatten(ns.locales[code], nil, {})) do ns.L[k] = v end
    end
end
function ns.T(key, ...)
    local s = ns.L[key]
    if s == nil then return "[" .. tostring(key) .. "]" end
    if select("#", ...) > 0 then return s:format(...) end
    return s
end
ns.coreLocaleLoaded = true

local _, ns = ...
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
    if next(ns.L) == nil and ns.locales.ruRU then ns.ApplyLocale() end
    local s = ns.L[key]
    if s == nil then return "[" .. tostring(key) .. "]" end
    if select("#", ...) > 0 then return s:format(...) end
    return s
end
local function asciiDown(c)
    return string.char(c:byte() + 32)
end
local function cyrA(b)
    return "\208" .. string.char(b:byte() + 32)
end
local function cyrR(b)
    return "\209" .. string.char(b:byte() - 32)
end
function ns.Lower(s)
    s = tostring(s or "")
    s = s:gsub("[A-Z]", asciiDown)
    s = s:gsub("\208([\144-\159])", cyrA)
    s = s:gsub("\208([\160-\175])", cyrR)
    s = s:gsub("\208\129", "\209\145")
    return s
end
function ns.Fold(s)
    s = ns.Lower(s):gsub("\209\145", "\208\181")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
ns.coreLocaleLoaded = true

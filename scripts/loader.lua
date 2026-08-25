--[[
  Vocalypse - KeyAuth Loader
  script_key = "YOUR_KEY"
  loadstring(game:HttpGet("https://raw.githubusercontent.com/vocalypse/Vocalypse/main/scripts/loader.lua"))()
]]

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Name = "Application de Vocalypsezombie"
local Ownerid = "Xl4z6yy1B1"
local APPVersion = "1.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/vocalypse/Vocalypse/main/scripts/full.lua"

local function enc(s)
    return tostring(s or ""):gsub("([^%w%-%.%_%~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20")
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 6
        })
    end)
    print("[Vocalypse] " .. tostring(title) .. " | " .. tostring(text))
end

local License = (type(script_key) == "string" and script_key)
    or (getgenv and getgenv().script_key)
    or ""
License = tostring(License):gsub("^%s+", ""):gsub("%s+$", "")

if License == "" then
    notify("Vocalypse", "Pas de cle")
    return
end

local function get(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" then return res end
    local reqFn = request or http_request or (syn and syn.request) or (http and http.request)
    if reqFn then
        local ok2, r = pcall(function()
            return reqFn({ Url = url, Method = "GET" })
        end)
        if ok2 and type(r) == "table" then
            return r.Body or r.body
        end
    end
    return nil
end

notify("Vocalypse", "Init KeyAuth...")

local initUrl = "https://keyauth.win/api/1.2/?type=init&name=" .. enc(Name)
    .. "&ownerid=" .. enc(Ownerid) .. "&ver=" .. enc(APPVersion)

local initBody = get(initUrl)
if not initBody or initBody == "" then
    initUrl = "https://keyauth.win/api/1.1/?name=" .. enc(Name)
        .. "&ownerid=" .. enc(Ownerid) .. "&type=init&ver=" .. enc(APPVersion)
    initBody = get(initUrl)
end

if not initBody then
    notify("Vocalypse", "Pas de reponse KeyAuth")
    return
end

print("[Vocalypse] init raw: " .. tostring(initBody):sub(1, 120))

if initBody == "KeyAuth_Invalid" then
    notify("Vocalypse", "App introuvable")
    return
end

if initBody:sub(1, 1) == "<" then
    notify("Vocalypse", "API bloquee (HTML)")
    return
end

local ok, initData = pcall(function() return HttpService:JSONDecode(initBody) end)
if not ok or type(initData) ~= "table" then
    notify("Vocalypse", "Init JSON invalide")
    return
end

if initData.success ~= true then
    notify("Vocalypse", "Init: " .. tostring(initData.message))
    return
end

local sessionid = initData.sessionid or ""

local licUrl = "https://keyauth.win/api/1.2/?type=license&name=" .. enc(Name)
    .. "&ownerid=" .. enc(Ownerid)
    .. "&key=" .. enc(License)
    .. "&ver=" .. enc(APPVersion)
    .. "&sessionid=" .. enc(sessionid)

local licBody = get(licUrl)
if not licBody then
    licUrl = "https://keyauth.win/api/1.1/?name=" .. enc(Name)
        .. "&ownerid=" .. enc(Ownerid)
        .. "&type=license&key=" .. enc(License)
        .. "&ver=" .. enc(APPVersion)
        .. "&sessionid=" .. enc(sessionid)
    licBody = get(licUrl)
end

if not licBody then
    notify("Vocalypse", "Pas de reponse license")
    return
end

print("[Vocalypse] license raw: " .. tostring(licBody):sub(1, 120))

local ok2, licData = pcall(function() return HttpService:JSONDecode(licBody) end)
if not ok2 or type(licData) ~= "table" or licData.success ~= true then
    notify("Vocalypse", "Cle refusee: " .. tostring(licData and licData.message or licBody:sub(1, 40)))
    return
end

notify("Vocalypse", "Cle OK - hub...")
local ok3, err = pcall(function()
    loadstring(game:HttpGet(SCRIPT_URL))()
end)
if not ok3 then
    notify("Vocalypse", "Hub: " .. tostring(err))
end

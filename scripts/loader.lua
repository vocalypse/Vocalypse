--[[
  Vocalypse - KeyAuth Loader
  script_key = "YOUR_KEY"
  loadstring(game:HttpGet("https://raw.githubusercontent.com/vocalypse/Vocalypse/main/scripts/loader.lua"))()
]]

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Name = "Application de Vocalypsezombie"
local Ownerid = "Xl4z6yy181"
local APPVersion = "1.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/vocalypse/Vocalypse/main/scripts/full.lua"

local function urlEncode(s)
    s = tostring(s or "")
    s = s:gsub("\n", "\r\n")
    s = s:gsub("([^%w%-%.%_%~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    s = s:gsub(" ", "%%20")
    return s
end

local License = (type(script_key) == "string" and script_key)
    or (getgenv and getgenv().script_key)
    or (getgenv and getgenv().Key)
    or ""

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

if License == "" then
    notify("Vocalypse", "Pas de cle. script_key = \"TA_CLE\"")
    return
end

notify("Vocalypse", "Verification de la cle...")

local initUrl = "https://keyauth.win/api/1.1/?name=" .. urlEncode(Name)
    .. "&ownerid=" .. urlEncode(Ownerid)
    .. "&type=init&ver=" .. urlEncode(APPVersion)

local okInit, initReq = pcall(function()
    return game:HttpGet(initUrl)
end)

if not okInit then
    notify("Vocalypse", "HttpGet init echoue: " .. tostring(initReq))
    return
end

if initReq == "KeyAuth_Invalid" then
    notify("Vocalypse", "App KeyAuth introuvable (nom/ownerid)")
    return
end

local okJ, initData = pcall(function()
    return HttpService:JSONDecode(initReq)
end)

if not okJ or type(initData) ~= "table" then
    notify("Vocalypse", "Reponse init invalide")
    print(tostring(initReq):sub(1, 200))
    return
end

if initData.success ~= true then
    notify("Vocalypse", "Init: " .. tostring(initData.message))
    return
end

local sessionid = initData.sessionid or ""

local licUrl = "https://keyauth.win/api/1.1/?name=" .. urlEncode(Name)
    .. "&ownerid=" .. urlEncode(Ownerid)
    .. "&type=license&key=" .. urlEncode(License)
    .. "&ver=" .. urlEncode(APPVersion)
    .. "&sessionid=" .. urlEncode(sessionid)

local okLic, licReq = pcall(function()
    return game:HttpGet(licUrl)
end)

if not okLic then
    notify("Vocalypse", "HttpGet license echoue")
    return
end

local okL, licData = pcall(function()
    return HttpService:JSONDecode(licReq)
end)

if not okL or type(licData) ~= "table" then
    notify("Vocalypse", "Reponse license invalide")
    print(tostring(licReq):sub(1, 200))
    return
end

if licData.success ~= true then
    notify("Vocalypse", "Cle refusee: " .. tostring(licData.message))
    return
end

notify("Vocalypse", "Cle OK - chargement hub...")

local okS, err = pcall(function()
    loadstring(game:HttpGet(SCRIPT_URL))()
end)

if not okS then
    notify("Vocalypse", "Erreur hub: " .. tostring(err))
end

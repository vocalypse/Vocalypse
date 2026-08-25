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

local License = (type(script_key) == "string" and script_key)
    or (getgenv and getgenv().script_key)
    or (getgenv and getgenv().Key)
    or ""

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
    print("[Vocalypse] " .. tostring(title) .. " - " .. tostring(text))
end

if License == "" then
    notify("Vocalypse", "No key. Use: script_key = \"YOUR_KEY\"")
    return
end

local initReq = game:HttpGet(
    "https://keyauth.win/api/1.1/?name=" .. Name
    .. "&ownerid=" .. Ownerid
    .. "&type=init&ver=" .. APPVersion
)

if initReq == "KeyAuth_Invalid" then
    notify("Vocalypse", "KeyAuth app not found")
    return
end

local ok, initData = pcall(function()
    return HttpService:JSONDecode(initReq)
end)

if not ok or not initData or initData.success ~= true then
    notify("Vocalypse", tostring(initData and initData.message or "Init failed"))
    return
end

local sessionid = initData.sessionid

local licReq = game:HttpGet(
    "https://keyauth.win/api/1.1/?name=" .. Name
    .. "&ownerid=" .. Ownerid
    .. "&type=license&key=" .. License
    .. "&ver=" .. APPVersion
    .. "&sessionid=" .. sessionid
)

local ok2, licData = pcall(function()
    return HttpService:JSONDecode(licReq)
end)

if not ok2 or not licData or licData.success ~= true then
    notify("Vocalypse", "Invalid key: " .. tostring(licData and licData.message or "?"))
    return
end

notify("Vocalypse", "Key valid - loading hub...")

local ok3, err = pcall(function()
    loadstring(game:HttpGet(SCRIPT_URL))()
end)

if not ok3 then
    notify("Vocalypse", "Script error: " .. tostring(err))
end

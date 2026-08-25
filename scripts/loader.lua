--[[
  Vocalypse - KeyAuth Loader
  1) Mets ta clé : script_key = "TA_CLE"
  2) Execute ce loader
  3) Si OK -> charge Volcano Gakuran Hub + updates auto
]]

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- ========== CONFIG KEYAUTH (à remplir) ==========
local Name = "Application de Vocalypsezombie"  -- nom exact de l'app KeyAuth
local Ownerid = "REMPLACE_OWNER_ID"            -- Owner ID dans le dashboard KeyAuth
local APPVersion = "1.0"
-- ================================================

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

if Ownerid == "REMPLACE_OWNER_ID" or Ownerid == "" then
    notify("Vocalypse", "Owner ID KeyAuth non configure dans loader.lua")
    return
end

if License == "" then
    notify("Vocalypse", "Aucune cle. Utilise: script_key = \"TA_CLE\"")
    return
end

-- Init KeyAuth
local initReq = game:HttpGet(
    "https://keyauth.win/api/1.1/?name=" .. Name
    .. "&ownerid=" .. Ownerid
    .. "&type=init&ver=" .. APPVersion
)

if initReq == "KeyAuth_Invalid" then
    notify("Vocalypse", "Application KeyAuth introuvable (nom / ownerid)")
    return
end

local ok, initData = pcall(function()
    return HttpService:JSONDecode(initReq)
end)

if not ok or not initData then
    notify("Vocalypse", "Erreur init KeyAuth")
    return
end

if initData.success ~= true then
    notify("Vocalypse", tostring(initData.message or "Init echouee"))
    return
end

local sessionid = initData.sessionid

-- License check
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

if not ok2 or not licData then
    notify("Vocalypse", "Erreur verification cle")
    return
end

if licData.success ~= true then
    notify("Vocalypse", "Cle invalide: " .. tostring(licData.message or "?"))
    return
end

notify("Vocalypse", "Cle valide - chargement du hub...")

local ok3, err = pcall(function()
    loadstring(game:HttpGet(SCRIPT_URL))()
end)

if not ok3 then
    notify("Vocalypse", "Erreur chargement script: " .. tostring(err))
end

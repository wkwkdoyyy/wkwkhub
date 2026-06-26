local placeId = game.PlaceId
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = game:GetService("Players").LocalPlayer

local function Notify(pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WKWKHUB Loader", 
            Text = pesan, 
            Duration = 5
        })
    end)
    print("[WKWKHUB] " .. pesan)
end

Notify("Mendeteksi game...")
task.wait(1)

local scriptToLoad = nil
local gameName = ""

if placeId == 137806249434874 then
    gameName = "Bus Explorer Indonesia"
    scriptToLoad = "https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/bxi.lua"

elseif placeId == 126509999114328 then 
    gameName = "99 Night in the forest"
    scriptToLoad = "https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/99night.lua"

elseif placeId == 79268393072444 then 
    gameName = "Sell Lemons"
    scriptToLoad = "https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/lemon.lua"
    
elseif placeId == 128784467030899 then 
    gameName = "Merge a Nuke"
    scriptToLoad = "https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/nuke.lua"
    
elseif placeId == 120564326011184 then 
    gameName = "Be a youtuber"
    scriptToLoad = "https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/youtube.lua"

else
    Notify("Game ini tidak disupport!...")
    warn("[WKWKHUB] Game ini tidak terdaftar: " .. tostring(placeId))
    
    task.wait(1)
    LocalPlayer:Kick("\n[WKWKHUB SECURITY]\nGame ini tidak disupport oleh WKWKHUB.\nHubungi admin untuk request game.")
    return
end

Notify("Game: " .. gameName .. "\nMemuat Key System...")

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "wkwkhub"
Junkie.identifier = "1134229"
Junkie.provider = "wkwkhub"

WindUI.Services.junkiedevelopment = {
    Name = "Junkie Development", 
    Icon = "shield-check",
    Args = { "ServiceId", "ApiKey", "Provider" },

    New = function()
        local function Verify(key)
            local result = Junkie.check_key(key)
            if result and result.valid then
                if result.message == "KEYLESS" then
                    getgenv().SCRIPT_KEY = "KEYLESS"
                    return true, "Keyless mode"
                elseif result.message == "KEY_VALID" then
                    getgenv().SCRIPT_KEY = key
                    return true, "Key valid"
                else
                    return false, "Invalid key"
                end
            end
        end

        local function Copy()
            local link = Junkie.get_key_link()
            if setclipboard then setclipboard(link) end
            return link
        end

        return { Verify = Verify, Copy = Copy }
    end
}

local Window = WindUI:CreateWindow({
    Title = "WKWKHUB",
    SubTitle = gameName,
    Icon = "terminal-square",
    Theme = "Midnight",
    Transparent = true,
    Resizable = true,
    Folder = "WKWKHUB",
    KeySystem = {
        Note = "Silakan masukkan key untuk melanjutkan",
        SaveKey = true,
        API = {
            {
                Title = "WKWKHUB Key Authentication",
                Desc  = "Klik ikon di samping untuk menyalin link key",
                Icon  = "key-round",
                Type  = "junkiedevelopment"
            }
        }
    }
})

while not getgenv().SCRIPT_KEY do
    task.wait(0.1)
end

WindUI:Notify({
    Title = "Verifikasi Berhasil!",
    Content = "Key Valid. Memuat script " .. gameName .. "...",
    Icon = "check-circle",
    Duration = 3
})

task.wait(0.3) 
pcall(function()
    if Window then
        Window:Destroy()
    end
end)

loadstring(game:HttpGet(scriptToLoad))()

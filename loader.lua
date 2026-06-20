local placeId = game.PlaceId
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = game:GetService("Players").LocalPlayer

local function Notify(pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WKWKHUB loader", 
            Text = pesan, 
            Duration = 5
        })
    end)
    print("[WKWKHUB] " .. pesan)
end

Notify("Mendeteksi game...")
task.wait(1)

if placeId == 116365546508507 then 
    Notify("Game: Bus Explorer Indonesia. Memuat script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/bladeball.lua"))()

elseif placeId == 13772394625 then 
    Notify("Game: Blade Ball. Memuat script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/bxi.lua"))()

elseif placeId == 79268393072444 then 
    Notify("Game: Sell Lemons. Memuat script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wkwkdoyyy/wkwkhub/refs/heads/main/lemon.lua"))()

else
    Notify("Game ini tidak disupport!...")
    warn("[WKWKHUB] game ini tidak terdaftar: " .. tostring(placeId))
    
    task.wait(1)
    LocalPlayer:Kick("\n[WKWKHUB SECURITY]\nGame ini tidak disupport oleh WKWKHUB.")
end

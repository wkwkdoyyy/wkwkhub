local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- VARIABEL AUTO PARRY (SOURCE ENGINE)
-- ==========================================
local AutoParryEnabled = false
local ReactionTime = 0.55 -- Default dari source lu
local Parried = false
local TargetConnection = nil
local BallsFolder = workspace:WaitForChild("Balls", 9e9)

-- ==========================================
-- UI WKKHUB
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "WKWKHUB",
    SubTitle = "Blade Ball (Source Engine)",
    TabWidth = 110, 
    Size = UDim2.fromOffset(500, 320), 
    Theme = "Darker",
})

local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or PlayerGui))
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(170, 85, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 22
ToggleButton.Draggable = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(170, 85, 255)
ToggleButton.MouseButton1Click:Connect(function() Window:Minimize() end)

local Tabs = { Combat = Window:AddTab({ Title = "Parry", Icon = "swords" }) }

Tabs.Combat:AddToggle("AutoParryTog", { 
    Title = "Enable Auto Parry", 
    Default = false, 
    Callback = function(Value) AutoParryEnabled = Value end 
})

Tabs.Combat:AddInput("ReactionInput", {
    Title = "Reaction Time (Detik)",
    Description = "Bawaan source adalah 0.55. Kalau nangkisnya kecepetan, turunin ke 0.40 atau 0.30.",
    Default = "0.55",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then ReactionTime = num end
    end
})

-- ==========================================
-- LOGIKA DARI SOURCE LU YANG UDAH DI-FIX
-- ==========================================
local function GetBall()
    for _, Ball in ipairs(BallsFolder:GetChildren()) do
        if Ball:GetAttribute("realBall") == true then
            return Ball
        end
    end
    return nil
end

local function ResetConnection()
    if TargetConnection then
        TargetConnection:Disconnect()
        TargetConnection = nil
    end
end

-- Deteksi bola baru dan pasang sensor perubahan target
BallsFolder.ChildAdded:Connect(function()
    local Ball = GetBall()
    if not Ball then return end
    
    ResetConnection()
    
    TargetConnection = Ball:GetAttributeChangedSignal("target"):Connect(function()
        -- Reset status parry setiap kali bola ganti target
        Parried = false
    end)
end)

-- Loop Super Cepat (PreSimulation)
RunService.PreSimulation:Connect(function()
    if not AutoParryEnabled then return end
    
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    local Ball = GetBall()
    
    if not Ball or not HRP then return end
    
    local zoomies = Ball:FindFirstChild("zoomies")
    if not zoomies then return end -- Amanin dari error kalau zoomies belum ke-load
    
    local Speed = zoomies.VectorVelocity.Magnitude
    local Distance = (HRP.Position - Ball.Position).Magnitude
    
    -- JIKA BOLA MENGINCAR KITA & BELUM DITANGKIS & KECEPATANNYA VALID
    if Ball:GetAttribute("target") == LocalPlayer.Name and not Parried and Speed > 0 then
        
        -- Rumus andalan dari source lu: Jarak / Kecepatan
        if (Distance / Speed) <= ReactionTime then
            
            local hotbar = LocalPlayer.PlayerGui:FindFirstChild("Hotbar")
            local blockButton = hotbar and hotbar:FindFirstChild("Block")
            
            if blockButton and getconnections then
                task.spawn(function()
                    for _, connection in pairs(getconnections(blockButton.Activated)) do connection:Fire() end
                    for _, connection in pairs(getconnections(blockButton.MouseButton1Click)) do connection:Fire() end
                    for _, connection in pairs(getconnections(blockButton.MouseButton1Down)) do connection:Fire() end
                end)
            end
            
            -- Kunci parry biar nggak nge-spam berlebihan
            Parried = true
            
            -- Backup reset kalau script nge-bug (menggantikan script cooldown lu yg error)
            task.delay(1, function()
                Parried = false
            end)
        end
    end
end)

Window:SelectTab(1)
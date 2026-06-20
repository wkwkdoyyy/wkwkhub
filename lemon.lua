if not game:IsLoaded() then game.Loaded:Wait() end

-- ==========================================
-- LOAD WIND UI LIBRARY
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[ERROR]: Failed to load LocalPlayer.")
    return
end

local SuccessIdle, ErrIdle = pcall(function()
    for _, idle in pairs(getconnections(LocalPlayer.Idled)) do
        idle:Disable()
    end
end)

if not SuccessIdle then
    warn("[ERROR]: Anti-Idle failed. | Error: " .. tostring(ErrIdle))
end

-- ==========================================
-- WKWKHUB UI SETUP (WIND UI)
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "WKWKHUB - Sell Lemons",
    Icon = "gem",
    Author = "Doyyy",
    Folder = "WKWKHUB",
    Size = UDim2.fromOffset(520, 400),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 160,
    HasOutline = false
})

-- FLOATING WKWKHUB BUTTON ("W")
local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")))
ScreenGui.Name = "WKWK_Toggle"
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(170, 85, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 22
ToggleButton.Draggable = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(170, 85, 255)

-- Buka/Tutup UI pakai WindUI Toggle API
ToggleButton.MouseButton1Click:Connect(function() 
    Window:Toggle() 
end)

local function DestroyUI(value)
    if value then task.wait(value) end
    if ScreenGui then ScreenGui:Destroy() end
    -- WindUI belum punya API Destroy resmi yang stabil di semua versi,
    -- jadi kita sembunyikan saja window-nya secara penuh jika DestroyUI dipanggil
    if Window then Window:Toggle() end 
end

local Tabs = {
    Main = Window:Tab({ Title = "Auto Farm", Icon = "play" }),
    Settings = Window:Tab({ Title = "Auto Settings", Icon = "sliders" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "settings" })
}

-- ==========================================
-- SCRIPT DATA & CORE LOGIC
-- ==========================================
local ScriptData = {
    PlayerTycoon = nil, 
    Values = nil, 
    Powers = nil, 
    Streams = nil, 

    AutoBuy = false, 
    AutoUpgrade = false,
    AutoRebirth = false,
    AutoEvolve = false,
    AutoAscend = false,
    AutoBuyPowers = false,
    AutoWakeIncomeSources = false,
    AutoPhoneOffers = false,
    AutoCollectFruits = false,

    MainSettings = {
        ButtonBuy = { BuyInterval = 0.05, UseForeverPurchase = false },
        Rebirth = { MaximumRebirths = 0, MinimumPotential = 1000, XFactor = 10, RebirthWhenUnableToBuy = false, TimeBeforeRebirthWhenUnableToBuy = 30, RebirthAfterCertainTime = false, TimeAmount = 60 },
        Evolve = { MaximumEvolution = 0 },
    },

    Modules = { Tycoon = nil, Balances = nil, Upgrades = nil, Rebirth = nil, Evolve = nil, Ascension = nil, PhoneOffers = nil, TycoonPowers = nil },
    Remotes = { Rebirth = nil, Evolve = nil, Ascend = nil, UpgradePowerLevel = nil, WakeIncomeStream = nil, PhoneOffer = nil },
}

local function FindValues(Value, AnotherChild, ReturnLast)
    if not ScriptData.PlayerTycoon then return end
    local Values = ScriptData.PlayerTycoon:FindFirstChild("Values")
    local ReturnValue = Values and Values:FindFirstChild(Value)
    if not AnotherChild then return ReturnValue else
        local Check = ReturnValue and ReturnValue:FindFirstChild(AnotherChild)
        if Check and not ReturnLast then return ReturnValue, Check
        elseif Check and ReturnLast then return Check end
    end
end

local function FindTycoon()
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") then
            if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then return v end
        end
    end
end

-- Tycoon Initialization
local StartTime = tick()
repeat
    ScriptData.PlayerTycoon = FindTycoon()
    if tick() - StartTime > 5 then
        WindUI:Notify({ Title = "Information", Content = "Taking longer than usual to find your tycoon. Please wait.", Duration = 5 })
    elseif tick() - StartTime > 30 then
        warn("[ERROR]: Tycoon unable to be found.")
        DestroyUI()
        return
    end
    task.wait(0.25)
until ScriptData.PlayerTycoon ~= nil

StartTime = tick()
repeat 
    ScriptData.Values = FindValues("Values")
    if tick() - StartTime > 5 then warn("[ERROR]: Values unable to be found."); DestroyUI(); return end
until ScriptData.Values ~= nil

StartTime = tick()
repeat 
    ScriptData.Powers = FindValues("Powers", "Permanent", true)
    if tick() - StartTime > 5 then warn("[ERROR]: Powers unable to be found."); DestroyUI(); return end
until ScriptData.Powers ~= nil

StartTime = tick()
repeat 
    ScriptData.Streams = FindValues("Income", "Streams", true)
    if tick() - StartTime > 5 then warn("[ERROR]: Streams unable to be found."); DestroyUI(); return end
until ScriptData.Streams ~= nil

local S1, R1 = pcall(function()
    ScriptData.Modules.Tycoon = require(ReplicatedStorage.Modules.Tycoon.Tycoon)
    ScriptData.Modules.Balances = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonBalances)
    ScriptData.Modules.Upgrades = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonUpgrades)
    ScriptData.Modules.Rebirth = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonRebirth)
    ScriptData.Modules.Evolve = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonEvolution)
    ScriptData.Modules.Ascension = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonAscension)
    ScriptData.Modules.PhoneOffers = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPhoneOffers)
    ScriptData.Modules.TycoonPowers = require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPowers)
end)

local S2, R2 = pcall(function()
    ScriptData.Remotes.Rebirth = ScriptData.PlayerTycoon.Remotes.Rebirth
    ScriptData.Remotes.Evolve = ScriptData.PlayerTycoon.Remotes.Evolve
    ScriptData.Remotes.Ascend = ScriptData.PlayerTycoon.Remotes.Ascend
    ScriptData.Remotes.UpgradePowerLevel = ScriptData.PlayerTycoon.Remotes.UpgradePowerLevel
    ScriptData.Remotes.WakeIncomeStream = ScriptData.PlayerTycoon.Remotes.WakeIncomeStream
    ScriptData.Remotes.PhoneOffer = ScriptData.PlayerTycoon.Remotes.PhoneOffer
end)

if not S1 or not S2 then
    if not S1 and not S2 then
        WindUI:Notify({ Title = "Critical Error!", Content = "Script is being aborted. Please wait and try again.", Duration = 3 })
        DestroyUI(5)
        return
    end
    if not S1 then WindUI:Notify({ Title = "Module Error!", Content = "Failed to load modules, some features may not work.", Duration = 3 }) end
    if not S2 then WindUI:Notify({ Title = "Remote Error!", Content = "Failed to load remotes, some features may not work.", Duration = 3 }) end
end

local function RequestComp(Class)
    if not (ScriptData.Modules.Tycoon and Class) then return nil end
    local Success, Return = pcall(function()
        local LiveTycoon = ScriptData.Modules.Tycoon.getLocal()
        return LiveTycoon and LiveTycoon:GetComponent(Class)
    end)
    return Success and Return or nil
end

local Resolving = false
local function WaitForResolve()
    Resolving = true
    task.wait(2)
    Resolving = false
end

-- ==========================================
-- AUTO FARM LOOPS
-- ==========================================

task.spawn(function() -- auto buy buttons
    local IsBusy = false
    local function BuyButtons()
        if IsBusy or Resolving then return end
        IsBusy = true
        local Buyable = {}
        for _, v in ipairs(ScriptData.PlayerTycoon.Purchases:GetDescendants()) do
            if v:IsA("Model") then
                local Shown = v:GetAttribute("Shown")
                local Purchased = v:GetAttribute("Purchased")
                if not Purchased and Shown then
                    local Purchase = v:FindFirstChild("Purchase")
                    if Purchase and Purchase:IsA("RemoteFunction") then table.insert(Buyable, Purchase) end
                end
            end
        end

        for _, Purchase in ipairs(Buyable) do
            if not ScriptData.AutoBuy or Resolving then IsBusy = false; return end
            if ScriptData.MainSettings.ButtonBuy.UseForeverPurchase then
                local Success = pcall(function() Purchase:InvokeServer(true) end)
                if not Success then pcall(function() Purchase:InvokeServer() end) end
            else
                pcall(function() Purchase:InvokeServer() end)
            end
            if type(ScriptData.MainSettings.ButtonBuy.BuyInterval) == "number" and ScriptData.MainSettings.ButtonBuy.BuyInterval > 0 then
                task.wait(ScriptData.MainSettings.ButtonBuy.BuyInterval)
            end
        end
        IsBusy = false
    end

    while true do task.wait(0.05)
        if ScriptData.AutoBuy then BuyButtons() end
    end
end)

task.spawn(function() -- auto upgrade
    local UpgradeRemotes = {}
    local LastUpgradeScan = 0
    local function RefreshUpgradeRemotes()
        UpgradeRemotes = {}
        local Purchases = ScriptData.PlayerTycoon:FindFirstChild("Purchases")
        if not Purchases then return end
        for _, v in ipairs(Purchases:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name == "Upgrade" then table.insert(UpgradeRemotes, v) end
        end
    end

    while true do task.wait(0.5)
        if not ScriptData.AutoUpgrade then continue end
        if tick() - LastUpgradeScan > 3 then
            RefreshUpgradeRemotes()
            LastUpgradeScan = tick()
        end
        for _, r in ipairs(UpgradeRemotes) do
            if r.Parent then
                task.spawn(function()
                    for i = 1, 10 do task.wait() pcall(function() r:InvokeServer(i) end) end
                end)
            end
        end
    end
end)

task.spawn(function() -- auto rebirth
    local RebirthBusy = false
    local LastConflictNotify = 0
    local LastUnableBuyTime = 0
    local LastRebirthTime = tick()
    local LastTimeState = false
    local LastSuccessfulRebirth = 0
    local LastAutoRebirthToggle = 0
    local RebirthCooldown = 2.5

    local function GetBalances() return RequestComp(ScriptData.Modules.Balances) end
    local function GetRebirth() return RequestComp(ScriptData.Modules.Rebirth) end
    local function GetCurrentInvestors()
        local Balances = GetBalances()
        if not Balances then return 0 end
        local Success, Value = pcall(function() return Balances:GetInvestors() end)
        return Success and Value or 0
    end
    local function GetPotentialInvestors()
        local RebirthComp = GetRebirth()
        if not RebirthComp then return 0 end
        local Success, Value = pcall(function() return RebirthComp:GetPotentialInvestors() end)
        return Success and Value or 0
    end
    local function IsMinimumMet(PotentialLog, Minimum)
        if Minimum == 0 then return true end
        return PotentialLog >= math.log10(Minimum)
    end
    local function GetInvestorMultiplierCondition(PotentialLog, CurrentLog, Multiplier)
        return PotentialLog >= CurrentLog + math.log10(Multiplier)
    end
    local function DoRebirth()
        pcall(function() 
            ScriptData.Remotes.Rebirth:InvokeServer()
            WaitForResolve()
        end)
    end
    local function HasAnythingToBuy()
        for _, v in ipairs(ScriptData.PlayerTycoon.Purchases:GetDescendants()) do
            if v:IsA("Model") then
                local Shown = v:GetAttribute("Shown")
                local Purchased = v:GetAttribute("Purchased")
                if Shown == true and Purchased ~= true then return true end
            end
        end
        return false
    end
    local function GetCurrentRebirths()
        if not ScriptData.Values then return 0 end
        return ScriptData.Values:GetAttribute("Rebirths") or 0
    end

    while true do task.wait(0.1)
        if not ScriptData.AutoRebirth or RebirthBusy then 
            if not ScriptData.AutoRebirth then LastAutoRebirthToggle = 0 end
            continue 
        end
        if LastAutoRebirthToggle == 0 then LastAutoRebirthToggle = tick(); continue end
        if tick() - LastAutoRebirthToggle < 3 then continue end
        if tick() - LastSuccessfulRebirth < RebirthCooldown then continue end
        
        local Remote = ScriptData.Remotes.Rebirth
        if not Remote then continue end

        local MaxRebirths = ScriptData.MainSettings.Rebirth.MaximumRebirths
        if MaxRebirths > 0 then
            if GetCurrentRebirths() >= MaxRebirths then continue end
        end

        local Settings = ScriptData.MainSettings.Rebirth
        local ShouldRebirth = false

        if Settings.RebirthWhenUnableToBuy and Settings.RebirthAfterCertainTime then
            if tick() - LastConflictNotify >= 5 then
                WindUI:Notify({ Title = "Rebirth Settings Conflict", Content = "Cannot use 'When Unable to Buy' and 'After Certain Time' together.", Duration = 5 })
                LastConflictNotify = tick()
            end
            continue
        end

        if Settings.RebirthAfterCertainTime then
            if LastTimeState ~= true then
                LastRebirthTime = tick(); LastTimeState = true
            end
            if tick() - LastRebirthTime >= Settings.TimeAmount then ShouldRebirth = true end
        else
            LastTimeState = false
            if Settings.RebirthWhenUnableToBuy then
                if not HasAnythingToBuy() then
                    if LastUnableBuyTime == 0 then LastUnableBuyTime = tick()
                    elseif tick() - LastUnableBuyTime >= Settings.TimeBeforeRebirthWhenUnableToBuy then ShouldRebirth = true end
                else LastUnableBuyTime = 0 end
            end
            
            if not ShouldRebirth then
                local Potential = GetPotentialInvestors()
                local Current = GetCurrentInvestors()
                if Potential > 0 then
                    local MinMet = IsMinimumMet(Potential, Settings.MinimumPotential)
                    if MinMet then
                        if Settings.XFactor > 0 then
                            if GetInvestorMultiplierCondition(Potential, Current, Settings.XFactor) then ShouldRebirth = true end
                        elseif Settings.MinimumPotential > 0 then ShouldRebirth = true
                        elseif Settings.XFactor == 0 and Settings.MinimumPotential == 0 then
                            if tick() - LastRebirthTime >= 8 then ShouldRebirth = true end
                        end
                    end
                end
            end
        end

        if ShouldRebirth and ScriptData.AutoRebirth then
            RebirthBusy = true
            DoRebirth()
            LastRebirthTime = tick()
            LastUnableBuyTime = 0
            LastSuccessfulRebirth = tick()
            LastAutoRebirthToggle = tick()
            task.wait(1.5)
            RebirthBusy = false
        end
    end
end)

task.spawn(function() -- auto evolve loop
    local function TryEvolve() pcall(function() ScriptData.Remotes.Evolve:InvokeServer(); WaitForResolve() end) end
    while true do task.wait(0.5)
        if not ScriptData.AutoEvolve then continue end
        local FreshModule = RequestComp(ScriptData.Modules.Evolve)
        if not FreshModule then continue end
        local Progress = FreshModule:GetEvolutionProgress()
        if Progress == 1 and ScriptData.MainSettings.Evolve.MaximumEvolution > 0 then
            local CurrentEvolve = ScriptData.Values:GetAttribute("Evolution")
            if CurrentEvolve and CurrentEvolve < ScriptData.MainSettings.Evolve.MaximumEvolution then TryEvolve() end
        elseif Progress == 1 and ScriptData.MainSettings.Evolve.MaximumEvolution == 0 then TryEvolve() end
    end
end)

task.spawn(function() -- auto ascend
    local function TryAscend() pcall(function() ScriptData.Remotes.Ascend:InvokeServer(); WaitForResolve() end) end
    while true do task.wait(0.5)
        if not ScriptData.AutoAscend then continue end
        local FreshModule = RequestComp(ScriptData.Modules.Ascension)
        if not FreshModule then continue end
        if FreshModule:GetAscensionProgress() == 1 then TryAscend() end
    end
end)

task.spawn(function() -- auto buy powers
    while true do task.wait(0.5)
        if not ScriptData.AutoBuyPowers then continue end
        local FreshModule = RequestComp(ScriptData.Modules.TycoonPowers)
        if not FreshModule then continue end
        local Success, Levels = pcall(function() return FreshModule:GetLevels() end)
        if Success and Levels then
            for PowerName, CurrentLevel in pairs(Levels) do
                local MaxLevel = FreshModule:GetMaxLevel(PowerName)
                if not MaxLevel or CurrentLevel < MaxLevel then
                    pcall(function() FreshModule:UpgradeAsync(PowerName) end)
                    task.wait(0.1)
                end
            end
        end
    end
end)

task.spawn(function() -- accept phone offers
    local Phone = ScriptData.Remotes.PhoneOffer
    local function AcceptOffer()
        if ScriptData.AutoPhoneOffers then pcall(function() Phone:FireServer("Accept") end) end
    end
    Phone.OnClientEvent:Connect(function(value)
        if type(value) == "number" then AcceptOffer() end
    end)
    while true do task.wait(1)
        if ScriptData.AutoPhoneOffers then
            local FreshModule = RequestComp(ScriptData.Modules.PhoneOffers)
            if FreshModule then
                local Success, Offer = pcall(function() return FreshModule:GetCurrentOffer() end)
                if Success and type(Offer) == "number" then AcceptOffer() end
            end
        end
    end
end)

task.spawn(function() -- auto wake income
    local IncomeStreams = {}
    local function TryWakeIncome()
        if #IncomeStreams == 0 then
            for _, v in pairs(ScriptData.Streams:GetChildren()) do table.insert(IncomeStreams, v) end
        end
        for _, v in ipairs(IncomeStreams) do
            if not v:GetAttribute("Automatic") then
                pcall(function() ScriptData.Remotes.WakeIncomeStream:InvokeServer(tostring(v)) end)
            end
        end
    end
    while true do task.wait()
        if ScriptData.AutoWakeIncomeSources then TryWakeIncome() end
    end
end)

task.spawn(function() -- auto collect fruits
    local Trees = {}
    local OriginalCFrame = nil
    local function UpdateTree(v, IsAdding)
        if v:IsA("Model") and v.Name == "LemonTree" then
            if IsAdding and not table.find(Trees, v) then table.insert(Trees, v)
            elseif not IsAdding then
                local Index = table.find(Trees, v)
                if Index then table.remove(Trees, Index) end
            end
        end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do UpdateTree(v, true) end
    Workspace.DescendantAdded:Connect(function(v) UpdateTree(v, true) end)
    Workspace.DescendantRemoving:Connect(function(v) UpdateTree(v, false) end)
    
    while true do task.wait(0.1)
        if ScriptData.AutoCollectFruits then
            for _, Tree in ipairs(Trees) do
                if Tree and Tree.Parent then
                    for _, v in ipairs(Tree:GetDescendants()) do
                        if v:IsA("BasePart") and v.Name == "Fruit" then
                            if not ScriptData.AutoCollectFruits then break end
                            local Detector = v:FindFirstChild("ClickPart") and v.ClickPart:FindFirstChildOfClass("ClickDetector")
                            if Detector then
                                local Character = LocalPlayer.Character
                                local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    pcall(function()
                                        if not OriginalCFrame then OriginalCFrame = HumanoidRootPart.CFrame end
                                        HumanoidRootPart.CFrame = Tree:GetPivot() + Vector3.new(0, Tree:GetExtentsSize().Y/2, 0)
                                        task.wait(0.05)
                                        fireclickdetector(Detector)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        elseif OriginalCFrame then
            local Character = LocalPlayer.Character
            local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                pcall(function() HumanoidRootPart.CFrame = OriginalCFrame; OriginalCFrame = nil end)
            end
        end
    end
end)

-- ==========================================
-- UI ELEMENTS (WIND UI)
-- ==========================================

-- TAB: MAIN (AUTO FARM)
Tabs.Main:Section({ Title = "Tycoon Progress" })
Tabs.Main:Toggle({ Title = "Auto Buy", Value = false, Callback = function(v) ScriptData.AutoBuy = v end })
Tabs.Main:Toggle({ Title = "Auto Upgrade", Value = false, Callback = function(v) ScriptData.AutoUpgrade = v end })
Tabs.Main:Toggle({ Title = "Auto Rebirth", Value = false, Callback = function(v) ScriptData.AutoRebirth = v end })
Tabs.Main:Toggle({ Title = "Auto Evolve", Value = false, Callback = function(v) ScriptData.AutoEvolve = v end })
Tabs.Main:Toggle({ Title = "Auto Ascend", Value = false, Callback = function(v) ScriptData.AutoAscend = v end })

Tabs.Main:Section({ Title = "Extras" })
Tabs.Main:Toggle({ Title = "Auto Buy Powers", Value = false, Callback = function(v) ScriptData.AutoBuyPowers = v end })
Tabs.Main:Toggle({ Title = "Auto Accept Phone Offers", Value = false, Callback = function(v) ScriptData.AutoPhoneOffers = v end })
Tabs.Main:Toggle({ Title = "Auto Wake Income Sources", Value = false, Callback = function(v) ScriptData.AutoWakeIncomeSources = v end })
Tabs.Main:Toggle({ Title = "Collect Fruits", Value = false, Callback = function(v) ScriptData.AutoCollectFruits = v end })

-- TAB: SETTINGS (AUTO SETTINGS)
Tabs.Settings:Section({ Title = "Auto Buy Settings" })
Tabs.Settings:Input({ Title = "Buy Interval (in seconds)", Value = "0.05", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.ButtonBuy.BuyInterval = n
    else WindUI:Notify({ Title = "Error", Content = "Invalid number entered.", Duration = 3 }) end
end})
Tabs.Settings:Toggle({ Title = "Use Forever Purchase", Value = false, Callback = function(v) ScriptData.MainSettings.ButtonBuy.UseForeverPurchase = v end })

Tabs.Settings:Section({ Title = "Rebirth Settings" })
Tabs.Settings:Input({ Title = "Max Rebirths (per evolve, 0 = off)", Value = "0", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Rebirth.MaximumRebirths = n end
end})
Tabs.Settings:Input({ Title = "Minimum Investors Needed", Value = "1000", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Rebirth.MinimumPotential = n end
end})
Tabs.Settings:Input({ Title = "X Factor (Current * XFactor = rebirth)", Value = "10", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Rebirth.XFactor = n end
end})

Tabs.Settings:Section({ Title = "Rebirth Conditions" })
Tabs.Settings:Input({ Title = "Rebirth When Unable Buy Interval (s)", Value = "30", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Rebirth.TimeBeforeRebirthWhenUnableToBuy = n end
end})
Tabs.Settings:Toggle({ Title = "Rebirth When Unable to Buy", Value = false, Callback = function(v) 
    WindUI:Notify({ Title = "Currently Unavailable", Content = v and "Will be added later." or "Sorry.", Duration = 3 })
end})

Tabs.Settings:Input({ Title = "Rebirth After Certain Time Interval (s)", Value = "60", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Rebirth.TimeAmount = n end
end})
Tabs.Settings:Toggle({ Title = "Rebirth After Certain Time", Value = false, Callback = function(v) ScriptData.MainSettings.Rebirth.RebirthAfterCertainTime = v end })

Tabs.Settings:Section({ Title = "Evolve Settings" })
Tabs.Settings:Input({ Title = "Max Evolve (0 = no max)", Value = "0", PlaceholderText = "Numbers only", Callback = function(v)
    local n = tonumber(v)
    if n and n >= 0 then ScriptData.MainSettings.Evolve.MaximumEvolution = n end
end})

-- TAB: MISC
Tabs.Misc:Section({ Title = "Extra" })
Tabs.Misc:Toggle({ Title = "Disable 3D Rendering (FPS Boost)", Value = false, Callback = function(v)
    RunService:Set3dRenderingEnabled(not v)
end})
Tabs.Misc:Button({ Title = "Destroy Script (Hides UI)", Callback = function() DestroyUI() end })

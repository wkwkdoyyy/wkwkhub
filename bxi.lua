local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- ==========================================
-- SETUP CORE VARIABLES
-- ==========================================
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StatsFolder = LP:WaitForChild("PlayerData")
local StartUang = StatsFolder.Uang.Value
local StartTime = os.time()
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local CarData = Remotes.GetClientCustomizationData:InvokeServer()
local OwnedCarsFolder = LP:WaitForChild("PlayerData"):WaitForChild("OwnedCars")

-- VARIABEL GLOBAL
_G.AutoFull = false
_G.AntiAFK = false
_G.AutoRejoin = false
_G.blackscreen = false
_G.SpoofName = false
_G.SelectedBus = "" 
_G.SelectedRoute = "" 
_G.WebhookURL = ""
_G.WebhookEnabled = false
_G.TotalEarning = 0
_G.CycleCount = 0
_G.StartTime = os.time()
_G.AutoKickEnabled = false
_G.StaffWatch = false
_G.StaffAction = "Warn Only"

local TargetUang = 0
local lastMoney = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData = {}
local pendingIncome = 0
local isRunning = false
local busOptions = {}
local RouteListData = {}
local SelectedAction = "Dealership"
local SelectedTP = "Dealership"
local MinDelay = 85
local MaxDelay = 130

local TP_Locations = {
    ["Dealership"] = CFrame.new(19830.625, 266.913116, -27910.4844),
    ["Modifikasi"] = CFrame.new(12035.499, -21.3362789, 12740.0605),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918)
}

if CarData and CarData.CarData_Cars then
    for carID, data in pairs(CarData.CarData_Cars) do table.insert(CarListData, carID) end
    table.sort(CarListData)
end

for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    if CarData.CarData_Cars[car.Name] then table.insert(busOptions, car.Name) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

-- ==========================================
-- FUNGSI DINAMIS (RUTE, TRIGGER, OBSTACLE)
-- ==========================================
local function ScanAvailableRoutes()
    local routes = {}
    local addedRoutes = {}
    pcall(function()
        for _, trigger in pairs(CollectionService:GetTagged("BusJobTrigger")) do
            local terminalId = trigger:GetAttribute("TerminalId")
            if terminalId then
                local rawData = Remotes.GetAvailableBusRoutes:InvokeServer(terminalId)
                if rawData then
                    for routeID in pairs(rawData) do
                        if not addedRoutes[routeID] then
                            addedRoutes[routeID] = true
                            table.insert(routes, routeID) 
                        end
                    end
                end
            end
        end
    end)
    if #routes == 0 then table.insert(routes, "Baranangsiang_ke_Cirebon2") end
    table.sort(routes)
    return routes
end

RouteListData = ScanAvailableRoutes()
_G.SelectedRoute = RouteListData[1]

local function GetEndTriggerPosition()
    local folder = workspace:FindFirstChild("BusJobEndTriggers")
    if folder then
        for _, trigger in pairs(folder:GetChildren()) do
            if string.find(trigger.Name, _G.SelectedRoute) or string.find(trigger.Name, "End") then
                return trigger.CFrame
            end
        end
    end
    -- Fallback aman jika rute tidak lazim
    return CFrame.new(-26471.1445, -212.441071, 33276.8203) 
end

local function ClearDynamicObstacles()
    pcall(function()
        local barrierFolders = {"Cikamurang", "GerbangTol", "Portal", "Rintangan"} 
        local targetParts = {"SInar", "Laser", "KillBrick", "Blocker"}
        for _, folderName in pairs(barrierFolders) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, desc in pairs(folder:GetDescendants()) do
                    if table.find(targetParts, desc.Name) then
                        desc:Destroy()
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- MINI HUD STATUS (GUI TERPISAH)
-- ==========================================
local CoreGui = game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
if CoreGui:FindFirstChild("WKWK_StatusHUD") then CoreGui.WKWK_StatusHUD:Destroy() end

local StatusGui = Instance.new("ScreenGui", CoreGui)
StatusGui.Name = "WKWK_StatusHUD"; StatusGui.DisplayOrder = 100 

local StatusFrame = Instance.new("Frame", StatusGui)
StatusFrame.Size = UDim2.new(0, 200, 0, 30); StatusFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); StatusFrame.Active = true; StatusFrame.Draggable = true
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)
local StatusStroke = Instance.new("UIStroke", StatusFrame)
StatusStroke.Color = Color3.fromRGB(170, 85, 255); StatusStroke.Thickness = 1.5

local MiniStatusLabel = Instance.new("TextLabel", StatusFrame)
MiniStatusLabel.Size = UDim2.new(1, 0, 1, 0); MiniStatusLabel.BackgroundTransparency = 1
MiniStatusLabel.Text = "Status: Idle"; MiniStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniStatusLabel.Font = Enum.Font.GothamBold; MiniStatusLabel.TextSize = 13

local FluentStatusText = nil
local function SetStatus(text) 
    MiniStatusLabel.Text = "Status: " .. text
    if FluentStatusText then FluentStatusText:SetDesc(text) end 
end

-- ==========================================
-- SETUP BLACKSCREEN SYSTEM
-- ==========================================
local BlackScreen = Instance.new("ScreenGui", CoreGui)
local BSFrame = Instance.new("Frame", BlackScreen)
BlackScreen.Name = "WKWK_Blackout"; BlackScreen.DisplayOrder = -1; BlackScreen.Enabled = false 
BSFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); BSFrame.Size = UDim2.new(1.5, 0, 1.5, 0)
BSFrame.Position = UDim2.new(-0.25, 0, -0.25, 0); BSFrame.BorderSizePixel = 0

task.spawn(function() while task.wait(0.5) do BlackScreen.Enabled = _G.blackscreen end end)

-- ==========================================
-- WKWKHUB UI SETUP
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "WKWKHUB V2.5", SubTitle = "Bus Explorer Indonesia", TabWidth = 140, Size = UDim2.fromOffset(500, 420), Theme = "Darker"
})

local ToggleScreen = Instance.new("ScreenGui", CoreGui); ToggleScreen.DisplayOrder = 100 
local ToggleButton = Instance.new("TextButton", ToggleScreen)
ToggleButton.Size = UDim2.new(0, 50, 0, 50); ToggleButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(170, 85, 255); ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 22; ToggleButton.Draggable = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 15)
local UIStroke = Instance.new("UIStroke", ToggleButton)
UIStroke.Color = Color3.fromRGB(170, 85, 255); UIStroke.Thickness = 2
ToggleButton.MouseButton1Click:Connect(function() Window:Minimize() end)

local Tabs = {
    Info = Window:AddTab({ Title = "Information", Icon = "info" }),
    Main = Window:AddTab({ Title = "Auto Job", Icon = "play" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Shop = Window:AddTab({ Title = "Bus Shop", Icon = "shopping-cart" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "send" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ==========================================
-- UTILITIES & WEBHOOK SYSTEM
-- ==========================================
local function formatRS(amount)
    local formatted = tostring(amount)
    while true do formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2'); if (k==0) then break end end
    return formatted
end

local function GetMyBus() return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus) end

local function SetFreeze(state)
    local bus = GetMyBus()
    if bus then
        for _, part in pairs(bus:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = state
                if not state then part.AssemblyLinearVelocity = Vector3.new(0,0,0); part.AssemblyAngularVelocity = Vector3.new(0,0,0) end
            end
        end
    end
end

local function InstantTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    SetFreeze(false); task.wait(0.1)
    for i = 1, 3 do bus:PivotTo(targetCF); task.wait(0.05) end
end

local function GetActiveStop()
    for _, part in pairs(workspace.Checkpoints:GetChildren()) do
        local bs = part:FindFirstChild("BusStop")
        if bs and bs:IsA("BillboardGui") and bs.Enabled == true then return part end
    end
    for _, part in pairs(workspace:WaitForChild("BusJobEndTriggers"):GetChildren()) do
         local bs = part:FindFirstChild("BusStop") or part:FindFirstChild("EndStop")
         if bs and bs:IsA("BillboardGui") and bs.Enabled == true then return part end
    end
    return nil
end

local function getAvatar() return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png" end
local function getRunningTime() local diff = os.time() - _G.StartTime; return string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60) end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local currentMoney = StatsFolder.Uang.Value
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local embed = {
        ["author"] = { ["name"] = "WKWKHUB Webhook", ["icon_url"] = getAvatar() },
        ["title"] = "🚌 Route Completed",
        ["color"] = 0xAA55FF,
        ["fields"] = {
            {["name"] = "Username", ["value"] = LP.Name, ["inline"] = false},
            {["name"] = "Route Done", ["value"] = _G.SelectedRoute, ["inline"] = false},
            {["name"] = "Cycle Income", ["value"] = "Rp " .. formatRS(income), ["inline"] = false},
            {["name"] = "Current Money", ["value"] = "Rp " .. formatRS(currentMoney), ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = "Rp " .. formatRS(_G.TotalEarning), ["inline"] = false},
            {["name"] = "Cycle Count", ["value"] = tostring(_G.CycleCount), ["inline"] = false},
            {["name"] = "Running Time", ["value"] = getRunningTime(), ["inline"] = false}
        },
        ["footer"] = { ["text"] = "Powered by WKWKHUB | " .. os.date("%m/%d/%Y %I:%M %p") }
    }
    local payload = HttpService:JSONEncode({ ["username"] = "WKWKHUB Reports", ["embeds"] = {embed} })
    if http_request then pcall(function() http_request({ Url = _G.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload }) end) end
end

StatsFolder.Uang:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = StatsFolder.Uang.Value
    if newMoney > lastMoney then
        pendingIncome = pendingIncome + (newMoney - lastMoney)
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(65) 
                    if pendingIncome > 0 and _G.WebhookURL ~= "" and _G.WebhookEnabled then
                        sendWebhook(pendingIncome)
                        pendingIncome = 0 
                    end
                    if not _G.AutoFull then isRunning = false end
                end
            end)
        end
    end
    lastMoney = newMoney
end)

-- ==========================================
-- STAFF WATCH LOGIC
-- ==========================================
local function getPlayerIdentity(player)
    local identity = { isThreat = false, role = "Player Biasa" }
    if player == LP then return identity end
    pcall(function()
        if game.CreatorType == Enum.CreatorType.User then
            if player.UserId == game.CreatorId then identity.isThreat = true; identity.role = "👑 GAME OWNER" end
        elseif game.CreatorType == Enum.CreatorType.Group then
            local roleString = player:GetRoleInGroup(game.CreatorId)
            if roleString then
                local r = string.lower(roleString)
                if string.find(r, "owner") or string.find(r, "founder") then
                    identity.isThreat = true; identity.role = "👑 GROUP OWNER"
                elseif string.find(r, "admin") or string.find(r, "mod") or string.find(r, "dev") or string.find(r, "staff") then
                    identity.isThreat = true; identity.role = "👮 STAFF / MODERATOR"
                end
            end
        end
    end)
    return identity
end

Players.PlayerAdded:Connect(function(player)
    if not _G.StaffWatch then return end
    local identity = getPlayerIdentity(player)
    if identity.isThreat then
        if _G.StaffAction == "Warn Only" then
            Fluent:Notify({ Title = "⚠️ STAFF TERDETEKSI ⚠️", Content = identity.role .. " ("..player.Name..") masuk server!", Duration = 10 })
        elseif _G.StaffAction == "Kick Me" then
            LP:Kick("\n[WKWKHUB STAFF WATCH]\nTerdeteksi " .. identity.role .. " masuk ke server!\nOtomatis dikeluarkan demi keamanan.")
        end
    end
end)

-- ==========================================
-- TAB: INFORMATION (LIVE STATS)
-- ==========================================
FluentStatusText = Tabs.Info:AddParagraph({ Title = "Current Status", Content = "Waiting..." })
local StatUang = Tabs.Info:AddParagraph({ Title = "Uang", Content = "Rp " .. formatRS(StartUang) })
local StatEarning = Tabs.Info:AddParagraph({ Title = "Earning", Content = "Rp 0" })
local StatTime = Tabs.Info:AddParagraph({ Title = "Running Time", Content = "00:00:00" })

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local currentUang = StatsFolder.Uang.Value
            StatUang:SetDesc("Rp " .. formatRS(currentUang))
            StatEarning:SetDesc("Rp " .. formatRS(currentUang - StartUang))
            StatTime:SetDesc(getRunningTime())
        end)
    end
end)

-- ==========================================
-- TAB: AUTO FARM
-- ==========================================
local lastTarget = nil
local noBillboardTime = 0
local jobStarted = false

local RouteDropdown = Tabs.Main:AddDropdown("RouteDrop", {
    Title = "📍 Pilih Rute Perjalanan",
    Values = RouteListData,
    Multi = false,
    Default = 1,
    Callback = function(Value)
        _G.SelectedRoute = Value
        SetStatus("Rute diubah: " .. Value)
    end
})

Tabs.Main:AddButton({
    Title = "Refresh Daftar Rute",
    Callback = function()
        RouteListData = ScanAvailableRoutes()
        RouteDropdown:SetValues(RouteListData)
        RouteDropdown:SetValue(RouteListData[1])
        Fluent:Notify({Title="Sukses", Content="Daftar rute diperbarui dari server!", Duration=3})
    end
})

Tabs.Main:AddInput("MinDelayInput", {
    Title = "Min Teleport Delay (Detik)",
    Description = "Batas minimal waktu nunggu (Rekomendasi: 77+)",
    Default = tostring(MinDelay),
    Numeric = true,
    Callback = function(Value) MinDelay = tonumber(Value) or 77 end
})

Tabs.Main:AddInput("MaxDelayInput", {
    Title = "Max Teleport Delay (Detik)",
    Description = "Batas maksimal waktu nunggu (Rekomendasi: 80+)",
    Default = tostring(MaxDelay),
    Numeric = true,
    Callback = function(Value) MaxDelay = tonumber(Value) or 80 end
})

Tabs.Main:AddToggle("AutoJobTog", {
    Title = "START Auto Job",
    Default = false,
    Callback = function(Value)
        _G.AutoFull = Value
        if not Value then 
            -- Reset semua variabel agar bot berhenti total
            lastTarget = nil
            jobStarted = false
            SetFreeze(false)
            SetStatus("Idle")
            return -- Keluar dari fungsi
        end
        
        -- Gunakan task.spawn agar tidak mengunci UI Thread
        task.spawn(function()
            while _G.AutoFull do

            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            local jobGui = LP.PlayerGui:FindFirstChild("BusJobGUI")
            local infoLabel = jobGui and jobGui.JobStatusFrame:FindFirstChild("InfoLabel")
            
            -- 1. KONDISI AUTO SPAWN & AMBIL KERJAAN BARU
            if not jobStarted then
                SetStatus("Spawning: " .. _G.SelectedBus)
                Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus); task.wait(4)
                local bus = GetMyBus()
                
                if bus and bus:FindFirstChild("DriveSeat") then
                    bus.DriveSeat:Sit(hum); task.wait(2)
                    SetStatus("Meminta Rute: " .. _G.SelectedRoute)
                    
                    Remotes:WaitForChild("StartBusJob"):InvokeServer(_G.SelectedRoute); task.wait(1)
                    
                    hum.Jump = true; task.wait(1.5)
                    SetStatus("Respawn vehicle...")
                    Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus); task.wait(4)
                    bus = GetMyBus() 
                    if bus and bus:FindFirstChild("DriveSeat") then
                        bus.DriveSeat:Sit(hum); jobStarted = true
                    end
                end
            end
            
            -- 2. MEMBACA TARGET CHECKPOINT / HALTE BERIKUTNYA
            local target = GetActiveStop()
            
            if target and jobStarted then
                if target ~= lastTarget then
                    SetStatus("Teleport ke Checkpoint..."); SetFreeze(true); task.wait(0.2)
                    InstantTP(target.CFrame); lastTarget = target
                    
                    -- DETEKSI PINTAR: Baca UI Game (Bukan nunggu kaku 30 detik)
                    local inZoneTimeout = 0
                    while _G.AutoFull and jobStarted do
                        infoLabel = jobGui and jobGui.JobStatusFrame:FindFirstChild("InfoLabel")
                        if infoLabel and (string.find(string.upper(infoLabel.Text), "STAY IN THE ZONE") or string.find(string.upper(infoLabel.Text), "WAITING")) then
                            SetStatus(infoLabel.Text)
                            inZoneTimeout = 0 -- Reset waktu selama masih disuruh nunggu
                        else
                            inZoneTimeout = inZoneTimeout + 1
                            if inZoneTimeout >= 15 then break end -- Kalau 15 detik udah gak disuruh nunggu, gas!
                        end
                        task.wait(1)
                    end
                    
                    SetFreeze(false)
                    
                    -- ANTI-BAN DELAY ACAK (Hanya jalan kalau UI job masih ada)
                    task.wait(0.5)
                    local checkGui = LP.PlayerGui:FindFirstChild("BusJobGUI")
                    if checkGui and checkGui.JobStatusFrame.Visible == true then
                        local randomDelay = math.random(MinDelay, MaxDelay)
                        for i = randomDelay, 1, -1 do
                            if not _G.AutoFull or not jobStarted then break end
                            SetStatus("Delay ("..randomDelay.."s total): " .. i .. "s")
                            task.wait(1)
                        end
                    end
                end
            else
                -- 3. JIKA RUTE SELESAI (UI Hilang atau Halte Habis)
                local checkGui = LP.PlayerGui:FindFirstChild("BusJobGUI")
                if jobStarted and (not checkGui or checkGui.JobStatusFrame.Visible == false or not GetActiveStop()) then
                    SetStatus("Rute Selesai Terdeteksi! Finishing...")
                    SetFreeze(true); task.wait(0.2)
                    
                    -- Teleport langsung ke trigger akhir rute (Dinamis)
                    local endCFrame = GetEndTriggerPosition()
                    InstantTP(endCFrame)
                    task.wait(2); SetFreeze(false)
                    
                    if hum then hum.Jump = true; task.wait(0.5) end
                    
                    -- Reset status bot biar instan ambil job baru
                    jobStarted = false
                    lastTarget = nil
                    
                    local bus = GetMyBus()
                    if bus then bus:Destroy() end 
                    
                    SetStatus("Sukses! Memulai Rute Baru Dalam 3 Detik...")
                    task.wait(3) 
                end
            end
            task.wait(1)
            end
        end)
    end
})

Tabs.Main:AddInput("TargetMoneyInput", {
    Title = "Set Target Money (Auto Kick)",
    Description = "Tanpa titik, isi 0 untuk mati", Default = "0", Numeric = true,
    Callback = function(Value)
        local cleanNumber = tostring(Value):gsub("%.", "")
        TargetUang = tonumber(cleanNumber) or 0
        Fluent:Notify({ Title = "Target Set", Content = "Target uang: Rp " .. formatRS(TargetUang), Duration = 3 })
    end
})

Tabs.Main:AddToggle("AutoKickTog", {
    Title = "Enable Auto-Kick", Default = false,
    Callback = function(Value)
        _G.AutoKickEnabled = Value
        if Value then
            task.spawn(function()
                while _G.AutoKickEnabled do
                    local currentMoney = StatsFolder.Uang.Value
                    if TargetUang > 0 and currentMoney >= TargetUang then
                        LP:Kick("\n[WKWKHUB]\nTarget money reached!\nTotal: Rp " .. formatRS(currentMoney))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

-- ==========================================
-- TAB: TELEPORT
-- ==========================================
Tabs.Teleport:AddDropdown("TPDrop", {
    Title = "Select TP Destination", Values = {"Dealership", "Modifikasi", "Teleport City"}, Multi = false, Default = 1,
    Callback = function(Value) SelectedTP = Value end
})

Tabs.Teleport:AddButton({
    Title = "Teleport Now",
    Callback = function()
        local targetCF = TP_Locations[SelectedTP]
        if targetCF and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then LP.Character:PivotTo(targetCF) end
    end
})

Tabs.Teleport:AddDropdown("ActionDrop", {
    Title = "Select Menu to Open (Proximity)", Values = {"Dealership", "Modifikasi", "Teleport City"}, Multi = false, Default = 1,
    Callback = function(Value) SelectedAction = Value end
})

Tabs.Teleport:AddButton({
    Title = "Open Selected Menu",
    Callback = function()
        pcall(function()
            if SelectedAction == "Dealership" then fireproximityprompt(workspace.BigBus_DealershipPart.ProximityPrompt)
            elseif SelectedAction == "Modifikasi" then fireproximityprompt(workspace.Modif.ModificationTriggerPart.ProximityPrompt)
            elseif SelectedAction == "Teleport City" then fireproximityprompt(workspace.Telportpart.ProximityPrompt) end
        end)
    end
})

-- ==========================================
-- TAB: BUS SHOP
-- ==========================================
local BusDropdown = Tabs.Shop:AddDropdown("BusDrop", {
    Title = "Select Bus to SPAWN", Values = busOptions, Multi = false, Default = 1,
    Callback = function(Value) _G.SelectedBus = Value; SetStatus("Selected: " .. _G.SelectedBus) end
})

Tabs.Shop:AddButton({
    Title = "Refresh Garage List",
    Callback = function()
        local newOptions = {}
        for _, car in pairs(OwnedCarsFolder:GetChildren()) do table.insert(newOptions, car.Name) end
        BusDropdown:SetValues(newOptions); BusDropdown:SetValue(newOptions[1])
    end
})

Tabs.Shop:AddDropdown("BuyDrop", {
    Title = "Select Bus to PURCHASE", Values = CarListData, Multi = false, Default = 1,
    Callback = function(Value) SelectedBusToBuy = Value end
})

Tabs.Shop:AddButton({
    Title = "Purchase Selected Bus",
    Callback = function()
        if SelectedBusToBuy ~= "" and SelectedBusToBuy ~= "None" then
            local success, err = pcall(function() Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy) end)
            Fluent:Notify({Title = success and "Success" or "Failed", Content = success and "Berhasil beli!" or "Gagal beli.", Duration = 3})
        end
    end
})

-- ==========================================
-- TAB: WEBHOOK
-- ==========================================
Tabs.Webhook:AddInput("WebhookInput", {
    Title = "Discord Webhook URL", Default = "", 
    Callback = function(Value) _G.WebhookURL = Value end
})

Tabs.Webhook:AddToggle("WebhookTog", {
    Title = "📡 Enable Webhook Report", Default = false,
    Callback = function(Value)
        _G.WebhookEnabled = Value 
        if Value then
            task.wait(0.1)
            if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then
                Fluent:Notify({ Title = "Webhook Error", Content = "Masukkan URL Webhook dulu!", Duration = 5 })
            else
                Fluent:Notify({ Title = "Webhook Aktif", Content = "Sistem laporan Discord menyala.", Duration = 3 })
            end
        end
    end
})

Tabs.Webhook:AddButton({
    Title = "🔔 Test Webhook",
    Callback = function()
        if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then
            Fluent:Notify({Title = "Error", Content = "URL Webhook kosong atau tidak valid!", Duration = 3})
            return
        end
        local testEmbed = {
            ["author"] = { ["name"] = "WKWKHUB System", ["icon_url"] = getAvatar() },
            ["title"] = "✅ Webhook Berhasil Terhubung!",
            ["description"] = "Test notifikasi WKWKHUB.",
            ["color"] = 0x00FF00,
            ["footer"] = { ["text"] = "WKWKHUB | " .. os.date("%I:%M %p") }
        }
        local payload = HttpService:JSONEncode({ ["username"] = "WKWKHUB Test", ["embeds"] = {testEmbed} })
        local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
        if http_request then
            pcall(function() http_request({ Url = _G.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload }) end)
            Fluent:Notify({Title = "Sukses", Content = "Pesan test terkirim! Silakan cek Discord lu.", Duration = 4})
        else
            Fluent:Notify({Title = "Gagal", Content = "Executor lu nggak support sistem Webhook.", Duration = 4})
        end
    end
})

-- ==========================================
-- TAB: SETTINGS & SECURITY
-- ==========================================
Tabs.Settings:AddSection("Staff Protection")
Tabs.Settings:AddDropdown("StaffDrop", {
    Title = "Action on Staff Join", Values = {"Warn Only", "Kick Me"}, Multi = false, Default = 1,
    Callback = function(Value) _G.StaffAction = Value end
})

Tabs.Settings:AddToggle("StaffWatchTog", {
    Title = "Enable Staff Watch", Default = false, 
    Callback = function(Value) 
        _G.StaffWatch = Value 
        if Value then for _, p in pairs(Players:GetPlayers()) do checkStaff(p) end end
    end
})

Tabs.Settings:AddSection("Performance & AFK")
Tabs.Settings:AddToggle("AntiAfkTog", {
    Title = "Anti AFK", Default = false, Callback = function(Value) _G.AntiAFK = Value end
})

Tabs.Settings:AddToggle("AutoRejoinTog", {
    Title = "Auto Rejoin", Default = false,
    Callback = function(Value)
        _G.AutoRejoin = Value
        if Value then
            game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if _G.AutoRejoin and child.Name == "ErrorPrompt" then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end
            end)
        end
    end
})

Tabs.Settings:AddToggle("BlackScreenTog", {
    Title = "Black Screen", Default = false, Callback = function(Value) _G.blackscreen = Value end
})

Tabs.Settings:AddButton({
    Title = "FPS Boost",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
        end
        Fluent:Notify({ Title = "WKWKHUB", Content = "FPS Boosted", Duration = 3 })
    end
})

Tabs.Settings:AddSection("Hide YourSelf")
Tabs.Settings:AddToggle("SpoofNameTog", {
    Title = "Hide",
    Description = "Ubah semua nama pemain & nama di Leaderboard.",
    Default = false,
    Callback = function(Value)
        _G.SpoofName = Value
        if Value then
            task.spawn(function()
                while _G.SpoofName do
                    pcall(function()
                        for _, player in pairs(Players:GetPlayers()) do
                            if player.Character and player.Character:FindFirstChild("Humanoid") then
                                player.Character.Humanoid.DisplayName = "WKWKHUB"
                            end
                        end
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("TextLabel") and v.Parent:IsA("BillboardGui") then v.Text = "WKWKHUB" end
                        end
                        for _, v in pairs(CoreGui:GetDescendants()) do
                            if v:IsA("TextLabel") and (v.Text == LP.Name or v.Text == LP.DisplayName) then v.Text = "WKWKHUB" end
                        end
                    end)
                    task.wait(1) 
                end
            end)
        end
    end
})

Tabs.Settings:AddToggle("HideCharTog", {
    Title = "Invisible", Default = false,
    Callback = function(Value)
        if LP.Character then
            for _, part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then part.Transparency = Value and 1 or 0 end
            end
        end
    end
})

LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

Window:SelectTab(1)

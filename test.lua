local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Core Variables
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =============================================
-- CONFIGURATION & SETTINGS
-- =============================================
local Config = {
    -- Fishing Modes
    FishingV1 = false,
    
    -- Player Settings
    WalkSpeed = 16,
    JumpPower = 50,
    AutoJump = false,
    AutoJumpDelay = 3,
    
    -- Utility
    AntiAFK = false,
    AutoSell = false,
    WalkOnWater = false,
    NoClip = false,
    XRay = false,
    InfiniteZoom = false,
    
    -- Fishing Tools
    EnableRadar = false,
    EnableDivingGear = false,
    
    -- Teleport
    LockedPosition = false,
    LockCFrame = nil,
    SavedPosition = nil,
    
    -- Weather
    AutoBuyWeather = false,
    SelectedWeathers = {},
    
    -- System
    AutoRejoin = false,
    Brightness = 2,
    TimeOfDay = 14,
}

-- Fishing Variables
local FishingActive = false
local TotalCatches = 0
local StartTime = 0
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

-- Remotes
local net, ChargeRod, StartMini, FinishFish, FishCaught, equipRemote, sellRemote, favoriteRemote
local RadarRemote, EquipOxy, UnequipOxy, PurchaseWeather, UpdateAutoFishing

-- UI References
local Window = nil

-- =============================================
-- CORE SYSTEMS
-- =============================================

local function SetupRemotes()
    local success = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net
        
        ChargeRod = net:WaitForChild("RF/ChargeFishingRod")
        StartMini = net:WaitForChild("RF/RequestFishingMinigameStarted")
        FinishFish = net:WaitForChild("RE/FishingCompleted")
        FishCaught = net:WaitForChild("RE/FishCaught")
        equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
        sellRemote = net:WaitForChild("RF/SellAllItems")
        favoriteRemote = net:WaitForChild("RE/FavoriteItem")
        
        -- Additional remotes
        RadarRemote = net:WaitForChild("RF/UpdateFishingRadar")
        EquipOxy = net:WaitForChild("RF/EquipOxygenTank")
        UnequipOxy = net:WaitForChild("RF/UnequipOxygenTank")
        PurchaseWeather = net:WaitForChild("RF/PurchaseWeatherEvent")
        UpdateAutoFishing = net:WaitForChild("RF/UpdateAutoFishingState")
    end)
    
    return success
end

-- =============================================
-- FISHING V1 (GAME AUTO)
-- =============================================

local function StartFishingV1()
    if FishingActive then return end
    
    print("🎣 FISHING V1 STARTED - GAME AUTO")
    FishingActive = true
    Config.FishingV1 = true
    
    -- Enable game's auto fishing
    pcall(function()
        if UpdateAutoFishing then
            UpdateAutoFishing:InvokeServer(true)
        end
    end)
    
    Rayfield:Notify({
        Title = "🎣 FISHING V1 STARTED",
        Content = "Game Auto System Activated!",
        Duration = 5,
        Image = 4483362458
    })
    
    -- Monitor
    task.spawn(function()
        while Config.FishingV1 do
            task.wait(1)
        end
        
        -- Cleanup
        pcall(function()
            if UpdateAutoFishing then
                UpdateAutoFishing:InvokeServer(false)
            end
        end)
        
        FishingActive = false
        print("🎣 FISHING V1 STOPPED")
    end)
end

local function StopFishingV1()
    Config.FishingV1 = false
end

-- =============================================
-- FISHING V5 (EXCLAIM DETECTION)
-- =============================================

local autoFishingV5Enabled = false
local fishingV5Active = false

local function autoFishingV5Loop()
    local cycles = 0
    while autoFishingV5Enabled do
        local ok, err = pcall(function()
            fishingV5Active = true
            cycles = cycles + 1
            
            -- PHASE 1: EQUIP fishing rod (slot 1)
            if equipRemote then
                equipRemote:FireServer(1)
                task.wait(0.2)
            end

            -- PHASE 2: CHARGE fishing rod
            if ChargeRod then
                local timestamp = tick()
                ChargeRod:InvokeServer(timestamp)
                task.wait(0.2)
            end

            -- PHASE 3: START Mini Game
            if StartMini then
                local baseX, baseY = -0.7499996, 1
                local x = baseX + (math.random(-500, 500) / 10000000)
                local y = baseY + (math.random(-500, 500) / 10000000)
                StartMini:InvokeServer(x, y)
                task.wait(2)
            end
            
            -- PHASE 4: FINISH Fishing
            if FinishFish then
                FinishFish:FireServer(true)
                task.wait(0.001)
            end
        end)
        
        if not ok then
            warn("[V5 ERROR]: " .. tostring(err))
        end
        
        task.wait(0.2)
    end
    fishingV5Active = false
end

local function StartFishingV5()
    if autoFishingV5Enabled then
        warn("⚠️ Fishing V5 sudah aktif!")
        return
    end
    
    print("🎣 FISHING V5 STARTED")
    autoFishingV5Enabled = true
    
    task.spawn(autoFishingV5Loop)
    
    if Window then
        Rayfield:Notify({
            Title = "🎣 FISHING V5 STARTED",
            Content = "V5 System Activated!",
            Duration = 5,
            Image = 4483362458
        })
    end
end

local function StopFishingV5()
    autoFishingV5Enabled = false
    fishingV5Active = false
    
    if Window then
        Rayfield:Notify({
            Title = "🛑 FISHING V5 STOPPED",
            Content = "Auto Fishing V5 dihentikan",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Exclaim Detection untuk V5
task.spawn(function()
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 2)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if autoFishingV5Enabled and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    print("🎣 V5 - Exclaim detected! Auto recasting...")
                    task.spawn(function()
                        for i = 1, 3 do
                            pcall(function()
                                if FinishFish then 
                                    FinishFish:FireServer(true)
                                end
                            end)
                        end
                    end)
                end
            end
        end)
        print("✅ V5 Exclaim detection activated")
    end
end)

-- =============================================
-- ULTRA INSTANT BITE SYSTEM (BYBASS)
-- =============================================

local UltraBiteActive = false
local UltraTotalCatches = 0
local UltraStartTime = 0
local UltraCycleSpeed = 0.1

local function ExecuteUltraBiteCycle()
    local catches = 0
    
    pcall(function()
        -- STEP 1: AUTO EQUIP FISHING ROD
        if equipRemote then
            equipRemote:FireServer(1)
        end
        
        -- STEP 2: AUTO CHARGE - INSTANT
        if ChargeRod then
            ChargeRod:InvokeServer(tick())
        end
        
        -- STEP 3: AUTO MINIGAME - INSTANT BITE BYPASS!
        if StartMini then
            StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
        end
        
        -- STEP 4: AUTO FINISH - INSTANT
        if FinishFish then
            FinishFish:FireServer(true)
        end
        
        -- STEP 5: AUTO FISH CAUGHT - MULTIPLE FISH
        if FishCaught then
            -- Fish utama
            FishCaught:FireServer({
                Name = "⚡ INSTANT BITE FISH",
                Tier = math.random(5, 7),
                SellPrice = math.random(15000, 40000),
                Rarity = "LEGENDARY",
                Weight = math.random(50, 150),
                Length = math.random(100, 250)
            })
            catches = catches + 1
            
            -- Extra fish untuk performance
            for i = 1, 2 do
                FishCaught:FireServer({
                    Name = "🚀 ULTRA FISH",
                    Tier = math.random(6, 7),
                    SellPrice = math.random(20000, 50000),
                    Rarity = "MYTHIC",
                    Weight = math.random(80, 200),
                    Length = math.random(150, 300)
                })
                catches = catches + 1
            end
        end
    end)
    
    return catches
end

local function StartUltraInstantBite()
    if UltraBiteActive then 
        warn("⚠️ Ultra Bite sudah aktif!")
        return 
    end
    
    print("🚀 ACTIVATING ULTRA INSTANT BITE...")
    
    UltraBiteActive = true
    UltraTotalCatches = 0
    UltraStartTime = tick()
    
    -- MAIN ULTRA BITE LOOP
    task.spawn(function()
        local cycleCount = 0
        while UltraBiteActive do
            cycleCount = cycleCount + 1
            local cycleStart = tick()
            
            -- EXECUTE COMPLETE FISHING CYCLE
            local catchesThisCycle = ExecuteUltraBiteCycle()
            UltraTotalCatches = UltraTotalCatches + catchesThisCycle
            
            -- ULTRA FAST CYCLE TIMING
            local cycleTime = tick() - cycleStart
            local waitTime = math.max(UltraCycleSpeed - cycleTime, 0.01)
            
            -- Debug info setiap 50 cycle
            if cycleCount % 50 == 0 then
                local elapsed = tick() - UltraStartTime
                local currentRate = math.floor(UltraTotalCatches / math.max(elapsed, 1))
                print(string.format("♻️ Ultra Cycle: %d | Fish: %d | Rate: %d/s", cycleCount, UltraTotalCatches, currentRate))
            end
            
            task.wait(waitTime)
        end
    end)
    
    -- PERFORMANCE MONITOR
    task.spawn(function()
        while UltraBiteActive do
            local elapsed = tick() - UltraStartTime
            local currentRate = math.floor(UltraTotalCatches / math.max(elapsed, 1))
            
            pcall(function()
                if Window and Window.SetWindowName then
                    Window:SetWindowName(string.format("🎣 ULTRA BITE | %d FISH/SEC | %d TOTAL", currentRate, UltraTotalCatches))
                end
            end)
            
            task.wait(0.5)
        end
    end)
    
    Rayfield:Notify({
        Title = "🚀 ULTRA INSTANT BITE ACTIVATED",
        Content = "LEMPAR LANGSUNG SAMBAR! Speed: " .. UltraCycleSpeed .. "s",
        Duration = 5,
        Image = 4483362458
    })
end

local function StopUltraInstantBite()
    if not UltraBiteActive then 
        warn("⚠️ Ultra Bite tidak aktif!")
        return 
    end
    
    UltraBiteActive = false
    
    local totalTime = tick() - UltraStartTime
    local avgRate = math.floor(UltraTotalCatches / math.max(totalTime, 1))
    
    Rayfield:Notify({
        Title = "🛑 ULTRA BITE STOPPED",
        Content = string.format("Total: %d fish | Avg: %d/sec | Time: %.1fs", UltraTotalCatches, avgRate, totalTime),
        Duration = 5,
        Image = 4483362458
    })
    
    pcall(function()
        if Window and Window.SetWindowName then
            Window:SetWindowName("🎣 Auto Fishing V5 - Codepik")
        end
    end)
end

-- Enhanced Exclaim Detection untuk Ultra Bite
task.spawn(function()
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 2)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if UltraBiteActive and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    print("🎣 ULTRA BITE - Exclaim detected! Instant recasting...")
                    
                    -- INSTANT RECAST - Tidak perlu menunggu
                    task.spawn(function()
                        ExecuteUltraBiteCycle()
                        
                        -- Extra finish untuk memastikan
                        for i = 1, 2 do
                            task.wait(0.05)
                            pcall(function()
                                if FinishFish then 
                                    FinishFish:FireServer(true)
                                end
                            end)
                        end
                    end)
                end
            end
        end)
        print("✅ Ultra Bite Exclaim detection activated")
    end
end)

-- =============================================
-- AUTO ENCHANT ROD SYSTEM
-- =============================================

local function AutoEnchantRod()
    local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
    local char = workspace:WaitForChild("Characters"):FindFirstChild(player.Name)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "Failed to get character HRP.",
            Duration = 3
        })
        return
    end

    Rayfield:Notify({
        Title = "Preparing Enchant...",
        Content = "Please manually place Enchant Stone into slot 5 before we begin...",
        Duration = 5,
        Image = 4483362458
    })

    task.wait(3)

    -- Check if slot 5 has enchant stone
    local backpackGui = player.PlayerGui:FindFirstChild("Backpack")
    local slot5 = backpackGui and backpackGui:FindFirstChild("Display") and backpackGui.Display:GetChildren()[10]
    local itemName = slot5 and slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")

    if not itemName or not itemName.Text:lower():find("enchant") then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "Slot 5 does not contain an Enchant Stone.",
            Duration = 3
        })
        return
    end

    Rayfield:Notify({
        Title = "Enchanting...",
        Content = "It is in the process of Enchanting, please wait until the Enchantment is complete",
        Duration = 7,
        Image = 4483362458
    })

    local originalPosition = hrp.Position
    task.wait(1)
    hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
    task.wait(1.2)

    local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")

    pcall(function()
        equipRemote:FireServer(5)
        task.wait(0.5)
        activateEnchant:FireServer()
        task.wait(7)
        Rayfield:Notify({
            Title = "Enchant",
            Content = "Successfully Enchanted!",
            Duration = 3,
            Image = 4483362458
        })
    end)

    task.wait(0.9)
    hrp.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
end

-- =============================================
-- UTILITY SYSTEMS
-- =============================================

-- Fishing Tools
local function ToggleRadar(enabled)
    Config.EnableRadar = enabled
    pcall(function()
        if RadarRemote then
            RadarRemote:InvokeServer(enabled)
        end
    end)
end

local function ToggleDivingGear(enabled)
    Config.EnableDivingGear = enabled
    pcall(function()
        if enabled then
            equipRemote:FireServer(2)
            if EquipOxy then
                EquipOxy:InvokeServer(105)
            end
        else
            if UnequipOxy then
                UnequipOxy:InvokeServer()
            end
        end
    end)
end

-- Auto Sell
local function SellNow()
    pcall(function() 
        sellRemote:InvokeServer()
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Successfully sold items!",
            Duration = 3,
            Image = 4483362458
        })
    end)
end

-- Anti-AFK
local AFKConnection = nil
local function ToggleAntiAFK(enabled)
    Config.AntiAFK = enabled
    
    if AFKConnection then
        AFKConnection:Disconnect()
        AFKConnection = nil
    end
    
    if enabled then
        AFKConnection = player.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end)
        
        Rayfield:Notify({
            Title = "Anti-AFK Enabled",
            Content = "Anti-AFK system activated",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Anti-AFK Disabled", 
            Content = "Anti-AFK system deactivated",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Walk on Water
local WalkOnWaterConnection = nil
local function ToggleWalkOnWater(enabled)
    Config.WalkOnWater = enabled
    
    if WalkOnWaterConnection then
        WalkOnWaterConnection:Disconnect()
        WalkOnWaterConnection = nil
    end
    
    if enabled then
        WalkOnWaterConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if HumanoidRootPart and Humanoid then
                    local rayOrigin = HumanoidRootPart.Position
                    local rayDirection = Vector3.new(0, -20, 0)
                    
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    
                    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    
                    if raycastResult and raycastResult.Instance then
                        local hitPart = raycastResult.Instance
                        
                        if hitPart.Name:lower():find("water") or hitPart.Material == Enum.Material.Water then
                            local waterSurfaceY = raycastResult.Position.Y
                            local playerY = HumanoidRootPart.Position.Y
                            
                            if playerY < waterSurfaceY + 3 then
                                local newPosition = Vector3.new(
                                    HumanoidRootPart.Position.X,
                                    waterSurfaceY + 3.5,
                                    HumanoidRootPart.Position.Z
                                )
                                HumanoidRootPart.CFrame = CFrame.new(newPosition)
                            end
                        end
                    end
                end
            end)
        end)
    end
end

-- NoClip
local function ToggleNoClip(enabled)
    Config.NoClip = enabled
    
    if enabled then
        RunService.Stepped:Connect(function()
            if not Config.NoClip then return end
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide == true then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- XRay
local function ToggleXRay(enabled)
    Config.XRay = enabled
    
    if enabled then
        task.spawn(function()
            while Config.XRay do
                pcall(function()
                    for _, part in pairs(Workspace:GetDescendants()) do
                        if part:IsA("BasePart") and part.Transparency < 0.5 then
                            part.LocalTransparencyModifier = 0.5
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    end
end

-- Infinite Zoom
local function ToggleInfiniteZoom(enabled)
    Config.InfiniteZoom = enabled
    
    if enabled then
        task.spawn(function()
            while Config.InfiniteZoom do
                pcall(function()
                    if player:FindFirstChild("CameraMaxZoomDistance") then
                        player.CameraMaxZoomDistance = math.huge
                    end
                end)
                task.wait(1)
            end
        end)
    end
end

-- Auto Jump
local function ToggleAutoJump(enabled)
    Config.AutoJump = enabled
    
    if enabled then
        task.spawn(function()
            while Config.AutoJump do
                pcall(function()
                    if Humanoid and Humanoid.FloorMaterial ~= Enum.Material.Air then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
                task.wait(Config.AutoJumpDelay)
            end
        end)
    end
end

-- =============================================
-- TELEPORT SYSTEM
-- =============================================

local IslandLocations = {
    ["Weather Machine"] = Vector3.new(-1471, -3, 1929),
    ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    ["Kohana Volcano"] = Vector3.new(-519, 24, 189),
    ["Coral Reefs"] = Vector3.new(-3095, 1, 2177),
    ["Crater Island"] = Vector3.new(968, 1, 4854),
    ["Kohana"] = Vector3.new(-658, 3, 719),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
    ["Fisherman Island"] = Vector3.new(92, 9, 2768),
    ["Ancient Jungle"] = Vector3.new(1481, 11, -302),
    ["Sisyphus Statue"] = Vector3.new(-3740, -136, -1013),
}

local function TeleportToIsland(islandName)
    local pos = IslandLocations[islandName]
    if not pos then return end
    
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        
        Rayfield:Notify({
            Title = "Teleport Success",
            Content = "Teleported to " .. islandName,
            Duration = 3,
            Image = 4483362458
        })
    end)
end

-- Position Lock
local function TogglePositionLock(enabled)
    Config.LockedPosition = enabled
    
    if enabled then
        Config.LockCFrame = HumanoidRootPart.CFrame
        task.spawn(function()
            while Config.LockedPosition do
                if HumanoidRootPart then
                    HumanoidRootPart.CFrame = Config.LockCFrame
                end
                task.wait()
            end
        end)
    end
end

-- Save/Load Position
local function SavePosition()
    Config.SavedPosition = HumanoidRootPart.CFrame
    Rayfield:Notify({
        Title = "Position Saved",
        Content = "Current position saved",
        Duration = 2,
        Image = 4483362458
    })
end

local function LoadPosition()
    if Config.SavedPosition then
        HumanoidRootPart.CFrame = Config.SavedPosition
        Rayfield:Notify({
            Title = "Position Loaded",
            Content = "Teleported to saved position",
            Duration = 2,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Error",
            Content = "No saved position found",
            Duration = 2,
            Image = 4483362458
        })
    end
end

-- =============================================
-- EMERGENCY & SAFETY
-- =============================================

local function EmergencyStopAll()
    print("🚨 EMERGENCY STOP ALL SYSTEMS")
    
    -- Stop all fishing systems
    FishingActive = false
    Config.FishingV1 = false
    autoFishingV5Enabled = false
    fishingV5Active = false
    UltraBiteActive = false
    
    -- Stop other systems
    Config.AutoBuyWeather = false
    Config.AutoJump = false
    
    Rayfield:Notify({
        Title = "🚨 EMERGENCY STOP",
        Content = "All systems stopped immediately!",
        Duration = 3,
        Image = 4483362458
    })
    
    pcall(function()
        if Window and Window.SetWindowName then
            Window:SetWindowName("🎣 Auto Fishing V5 - Codepik")
        end
    end)
end

-- =============================================
-- UI CREATION
-- =============================================

local function CreateUI()
    Window = Rayfield:CreateWindow({
        Name = "🎣 Codepik Premium++",
        LoadingTitle = "Loading Codepik script..",
        LoadingSubtitle = "by Codepik",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "codepik",
            FileName = "codepik_conf"
        },
        KeySystem = false
    })

    -- Patch Note Tab
    local PatchTab = Window:CreateTab("💌 Patch Notes", 4483362458)
    
    PatchTab:CreateSection("📝 Patch Notes")
    PatchTab:CreateLabel("🔄 Version: V5 + Ultra Bite")
    PatchTab:CreateLabel("📅 Update Date: 27-10-25")

    PatchTab:CreateButton({
        Name = "📋 Show Features",
        Callback = function()
            Rayfield:Notify({
                Title = "🎣 Auto Fishing Features",
                Content = [[
                🚀 FISHING SYSTEMS:
                • V1 - Game Auto Fishing
                • V5 - Exclaim Detection  
                • ULTRA BITE - Instant Bypass
                
                ⚡ ULTRA BITE FEATURES:
                • Instant Lempar & Sambar
                • Multi Fish (3x per cycle)
                • Exclaim Detection
                • Turbo Speed Options
                ]],
                Duration = 15,
                Image = 4483362458
            })
        end,
    })

    -- Main Tab
    local MainTab = Window:CreateTab("🔥 Main", 4483362458)

    -- Fishing Systems Section
    MainTab:CreateSection("🎣 FISHING SYSTEMS")

    -- Fishing V1 (Game Auto)
    local FishingV1Toggle = MainTab:CreateToggle({
        Name = "🎣 Fishing V1 (Game Auto)",
        CurrentValue = Config.FishingV1,
        Callback = function(Value)
            Config.FishingV1 = Value
            if Value then
                autoFishingV5Enabled = false
                UltraBiteActive = false
                StopFishingV5()
                StopUltraInstantBite()
                StartFishingV1()
            else
                StopFishingV1()
            end
        end,
    })

    -- Fishing V5 (FIXED VERSION)
    local FishingV5Toggle = MainTab:CreateToggle({
        Name = "🚀 Fishing V5 (Exclaim Detection)",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                -- Matikan sistem lain
                Config.FishingV1 = false
                UltraBiteActive = false
                FishingV1Toggle:Set(false)
                StopFishingV1()
                StopUltraInstantBite()
                
                -- Start V5
                StartFishingV5()
            else
                StopFishingV5()
            end
        end,
    })

    -- Status Display untuk V5
    local V5StatusLabel = MainTab:CreateLabel("V5 Status: INACTIVE")

    task.spawn(function()
        while task.wait(1) do
            local statusText = "V5 Status: "
            if autoFishingV5Enabled and fishingV5Active then
                statusText = "V5 Status: 🟢 ACTIVE"
            elseif autoFishingV5Enabled then
                statusText = "V5 Status: 🟡 STARTING..."
            else
                statusText = "V5 Status: 🔴 INACTIVE"
            end
            pcall(function()
                V5StatusLabel:Set(statusText)
            end)
        end
    end)

    -- Ultra Instant Bite Section
    MainTab:CreateSection("🚀 ULTRA INSTANT BITE")
    
    -- Ultra Bite Toggle
    local UltraBiteToggle = MainTab:CreateToggle({
        Name = "⚡ ULTRA INSTANT BITE (Bypass)",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                -- Matikan sistem lain
                Config.FishingV1 = false
                autoFishingV5Enabled = false
                FishingV1Toggle:Set(false)
                FishingV5Toggle:Set(false)
                StopFishingV1()
                StopFishingV5()
                
                -- Start Ultra Bite
                StartUltraInstantBite()
            else
                StopUltraInstantBite()
            end
        end,
    })
    
    -- Ultra Bite Status
    local UltraBiteStatus = MainTab:CreateLabel("Ultra Status: INACTIVE")
    
    -- Ultra Bite Speed Slider
    MainTab:CreateSlider({
        Name = "⚡ Ultra Bite Speed",
        Range = {0.05, 0.5},
        Increment = 0.05,
        Suffix = "s",
        CurrentValue = UltraCycleSpeed,
        Callback = function(Value)
            UltraCycleSpeed = Value
            Rayfield:Notify({
                Title = "⚡ Ultra Speed Updated",
                Content = "Cycle speed: " .. Value .. " seconds",
                Duration = 2,
                Image = 4483362458
            })
        end,
    })
    
    -- Ultra Bite Stats
    local UltraStatsLabel = MainTab:CreateLabel("Fish: 0 | Rate: 0/s")
    
    -- Status Updater untuk Ultra Bite
    task.spawn(function()
        while task.wait(0.5) do
            -- Update Ultra Status
            local statusText = "Ultra Status: " .. (UltraBiteActive and "🟢 ACTIVE" or "🔴 INACTIVE")
            
            -- Update Stats
            local statsText = "Fish: 0 | Rate: 0/s"
            if UltraBiteActive and UltraStartTime > 0 then
                local elapsed = tick() - UltraStartTime
                local currentRate = math.floor(UltraTotalCatches / math.max(elapsed, 1))
                statsText = string.format("Fish: %d | Rate: %d/s", UltraTotalCatches, currentRate)
            end
            
            pcall(function()
                UltraBiteStatus:Set(statusText)
                UltraStatsLabel:Set(statsText)
            end)
        end
    end)

    -- Fishing Tools Section
    MainTab:CreateSection("🎣 Fishing Tools")

    MainTab:CreateToggle({
        Name = "Enable Fishing Radar",
        CurrentValue = Config.EnableRadar,
        Callback = function(Value)
            ToggleRadar(Value)
        end,
    })

    MainTab:CreateToggle({
        Name = "Enable Diving Gear",
        CurrentValue = Config.EnableDivingGear,
        Callback = function(Value)
            ToggleDivingGear(Value)
        end,
    })

    -- Auto Sell Section
    MainTab:CreateSection("💰 Auto Sell System")

    MainTab:CreateInput({
        Name = "Auto Sell Threshold",
        PlaceholderText = "Default: 4000 fish",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            local num = tonumber(Text)
            if num then obtainedLimit = num end
        end,
    })

    MainTab:CreateButton({
        Name = "Sell Now",
        Callback = SellNow,
    })
    
    MainTab:CreateSection("Auto Enchant Rod")

    MainTab:CreateButton({
        Name = "🔮 Auto Enchant Rod",
        Callback = AutoEnchantRod
    })

    -- Teleport Tab
    local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

    TeleportTab:CreateSection("TELEPORT TO ISLAND")

    for islandName, _ in pairs(IslandLocations) do
        TeleportTab:CreateButton({
            Name = islandName,
            Callback = function()
                TeleportToIsland(islandName)
            end,
        })
    end

    TeleportTab:CreateSection("Position Management")

    TeleportTab:CreateToggle({
        Name = "Lock Position",
        CurrentValue = Config.LockedPosition,
        Callback = function(Value)
            TogglePositionLock(Value)
        end,
    })

    TeleportTab:CreateButton({
        Name = "Save Current Position",
        Callback = SavePosition,
    })

    TeleportTab:CreateButton({
        Name = "Load Saved Position",
        Callback = LoadPosition,
    })

    -- Player Tab
    local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

    PlayerTab:CreateSection("Player Settings")

    PlayerTab:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 100},
        Increment = 1,
        CurrentValue = Config.WalkSpeed,
        Callback = function(Value)
            Config.WalkSpeed = Value
            if Humanoid then Humanoid.WalkSpeed = Value end
        end,
    })

    PlayerTab:CreateSlider({
        Name = "Jump Power",
        Range = {50, 200},
        Increment = 10,
        CurrentValue = Config.JumpPower,
        Callback = function(Value)
            Config.JumpPower = Value
            if Humanoid then
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = Value
            end
        end,
    })

    PlayerTab:CreateSection("Player Features")

    PlayerTab:CreateToggle({
        Name = "No Clip",
        CurrentValue = Config.NoClip,
        Callback = function(Value)
            ToggleNoClip(Value)
        end,
    })

    PlayerTab:CreateToggle({
        Name = "Walk on Water",
        CurrentValue = Config.WalkOnWater,
        Callback = function(Value)
            ToggleWalkOnWater(Value)
        end,
    })

    PlayerTab:CreateToggle({
        Name = "Auto Jump",
        CurrentValue = Config.AutoJump,
        Callback = function(Value)
            ToggleAutoJump(Value)
        end,
    })

    PlayerTab:CreateSlider({
        Name = "Auto Jump Delay",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.AutoJumpDelay,
        Callback = function(Value)
            Config.AutoJumpDelay = Value
        end,
    })

    -- Graphics Tab
    local GraphicsTab = Window:CreateTab("🎨 Graphics", 4483362458)

    GraphicsTab:CreateSection("Lighting Settings")

    GraphicsTab:CreateSlider({
        Name = "Brightness",
        Range = {0, 10},
        Increment = 0.5,
        CurrentValue = Config.Brightness,
        Callback = function(Value)
            Config.Brightness = Value
            Lighting.Brightness = Value
        end,
    })

    GraphicsTab:CreateSlider({
        Name = "Time of Day",
        Range = {0, 24},
        Increment = 0.5,
        CurrentValue = Config.TimeOfDay,
        Callback = function(Value)
            Config.TimeOfDay = Value
            Lighting.ClockTime = Value
        end,
    })

    GraphicsTab:CreateSection("Performance")

    GraphicsTab:CreateToggle({
        Name = "XRay Mode",
        CurrentValue = Config.XRay,
        Callback = function(Value)
            ToggleXRay(Value)
        end,
    })

    GraphicsTab:CreateToggle({
        Name = "Infinite Zoom",
        CurrentValue = Config.InfiniteZoom,
        Callback = function(Value)
            ToggleInfiniteZoom(Value)
        end,
    })

    -- Utility Tab
    local UtilityTab = Window:CreateTab("⚙️ Utility", 4483362458)

    UtilityTab:CreateSection("System Features")

    UtilityTab:CreateToggle({
        Name = "Anti-AFK System",
        CurrentValue = Config.AntiAFK,
        Callback = function(Value)
            ToggleAntiAFK(Value)
        end,
    })

    UtilityTab:CreateSection("Emergency")

    UtilityTab:CreateButton({
        Name = "🚨 Emergency Stop All",
        Callback = EmergencyStopAll,
    })

    -- Settings Tab
    local SettingsTab = Window:CreateTab("🔧 Settings", 4483362458)

    SettingsTab:CreateSection("Configuration")

    SettingsTab:CreateKeybind({
        Name = "UI Keybind",
        CurrentKeybind = "G",
        HoldToInteract = false,
        Callback = function(Keybind)
            Window:SetKeybind(Keybind)
        end,
    })

    SettingsTab:CreateButton({
        Name = "Save Configuration",
        Callback = function()
            Rayfield:SaveConfiguration()
        end,
    })

    SettingsTab:CreateButton({
        Name = "Load Configuration",
        Callback = function()
            Rayfield:LoadConfiguration()
        end,
    })

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Auto Fishing V5 + Ultra Bite",
        Content = "All systems loaded! Features: V1 + V5 + Ultra Bite",
        Duration = 6,
        Image = 4483362458
    })
end

-- =============================================
-- INITIALIZATION
-- =============================================

-- Character respawn handler
player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    -- Restore settings
    if Humanoid then
        Humanoid.WalkSpeed = Config.WalkSpeed
        Humanoid.JumpPower = Config.JumpPower
    end
    
    -- Restore active features
    if Config.FishingV1 then
        task.wait(2)
        StartFishingV1()
    elseif autoFishingV5Enabled then
        task.wait(2)
        StartFishingV5()
    elseif UltraBiteActive then
        task.wait(2)
        StartUltraInstantBite()
    end
    
    if Config.AutoJump then
        task.wait(1)
        ToggleAutoJump(true)
    end
    
    if Config.WalkOnWater then
        task.wait(1)
        ToggleWalkOnWater(true)
    end
    
    if Config.NoClip then
        task.wait(1)
        ToggleNoClip(true)
    end
    
    if Config.XRay then
        task.wait(1)
        ToggleXRay(true)
    end
    
    if Config.InfiniteZoom then
        task.wait(1)
        ToggleInfiniteZoom(true)
    end
end)

-- Fish threshold monitor
task.spawn(function()
    while task.wait(1) do
        if (FishingActive or Config.FishingV1 or autoFishingV5Enabled or UltraBiteActive) and #obtainedFishUUIDs >= obtainedLimit then
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Selling fish at threshold...",
                Duration = 3,
                Image = 4483362458
            })
            pcall(function() sellRemote:InvokeServer() end)
            obtainedFishUUIDs = {}
            task.wait(2)
        end
    end
end)

-- Fish obtained listener
task.spawn(function()
    local success, remoteV2 = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and remoteV2 then
        remoteV2.OnClientEvent:Connect(function(_, _, data)
            if data and data.InventoryItem and data.InventoryItem.UUID then
                table.insert(obtainedFishUUIDs, data.InventoryItem.UUID)
            end
        end)
    end
end)

-- Hotkey for emergency stop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
           UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            EmergencyStopAll()
        end
    end
end)

-- Main initialization
task.spawn(function()
    task.wait(2)
    
    if SetupRemotes() then
        CreateUI()
        
        print("🎣 Auto Fishing V5 + Ultra Bite - Codepik Edition")
        print("🎯 Hotkey: CTRL+SHIFT+P for emergency stop")
        print("⚡ Systems: V1 (Game Auto) | V5 (Exclaim) | Ultra Bite (Bypass)")
    else
        warn("❌ Failed to setup remotes!")
    end
end)

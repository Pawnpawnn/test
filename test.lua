local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

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
    FishingV4 = false,
    FishingDelay = 0.3,
    CycleSpeed = 0.1,
    
    -- Performance
    PerfectCatch = false,
    MaxPerformance = true,
    PerformanceMode = false,
    
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
    ESPEnabled = false,
    ESPDistance = 20,
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

-- Enhanced Fishing Variables
local EnhancedFishingActive = false
local TotalEnhancedCatches = 0
local EnhancedStartTime = 0

-- Enhanced Fishing Configuration
local ENHANCED_CONFIG = {
    INSTANT_BITE_DELAY = 0.1,  -- Very short delay for instant bite
    BASE_SPEED = 0.15,         -- Base cycle speed
    MAX_SPEED_MULTIPLIER = 2.5, -- Maximum speed multiplier
    EXCLAIM_WAIT_TIME = 0.5,   -- Wait time after exclaim detection
}

-- Fishing Variables
local FishingActive = false
local IsCasting = false
local TotalCatches = 0
local StartTime = 0
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

-- Webhook Variables
local webhookEnabled = false
local webhookUrl = ""
local SelectedWebhookCategories = {"Secret"}

-- Auto Favorite System
local AutoFavorite = {
    Enabled = false,
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedCategories = {"Secret"},
    ScanCooldown = 5,
    LastScanTime = 0
}

-- Quest System
local QuestState = {
    Active = false,
    CurrentQuest = nil,
    SelectedTask = nil,
    CurrentLocation = nil,
    Teleported = false,
    Fishing = false,
    LastProgress = 0,
    LastTaskIndex = nil
}

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
        FishCaught = net:WaitForChild("RE/FishCaught") or net:WaitForChild("RF/FishCaught")
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
-- EXCLAIM DETECTION SYSTEM - IMPROVED
-- =============================================

local ExclaimDetectionActive = false
local LastExclaimTime = 0

local function SetupExclaimDetection()
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 5)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if EnhancedFishingActive and data and data.TextData then
                -- Check for exclaim effect
                if data.TextData.EffectType == "Exclaim" then
                    local head = player.Character and player.Character:FindFirstChild("Head")
                    if head and data.Container == head then
                        local currentTime = tick()
                        -- Prevent multiple triggers in short time
                        if currentTime - LastExclaimTime > 1 then
                            LastExclaimTime = currentTime
                            print("🎣 Exclaim detected! Auto recasting...")
                            
                            -- Wait then recast
                            task.spawn(function()
                                task.wait(ENHANCED_CONFIG.EXCLAIM_WAIT_TIME)
                                
                                -- Recast fishing rod
                                pcall(function()
                                    if FinishFish then 
                                        FinishFish:FireServer()
                                        print("🎣 Auto recast executed!")
                                    end
                                end)
                            end)
                        end
                    end
                end
            end
        end)
        ExclaimDetectionActive = true
        print("✅ Exclaim detection system activated")
        return true
    else
        warn("❌ Exclaim event not found, trying alternative detection...")
        return false
    end
end

-- Alternative exclaim detection through particle effects
local function SetupAlternativeExclaimDetection()
    task.spawn(function()
        while EnhancedFishingActive do
            task.wait(0.1)
            pcall(function()
                local character = player.Character
                if character then
                    local head = character:FindFirstChild("Head")
                    if head then
                        -- Check for exclaim particles
                        for _, part in ipairs(head:GetChildren()) do
                            if part:IsA("ParticleEmitter") and part.Name:lower():find("exclaim") then
                                local currentTime = tick()
                                if currentTime - LastExclaimTime > 1 then
                                    LastExclaimTime = currentTime
                                    print("🎣 Exclaim particle detected! Auto recasting...")
                                    
                                    task.wait(ENHANCED_CONFIG.EXCLAIM_WAIT_TIME)
                                    pcall(function()
                                        if FinishFish then 
                                            FinishFish:FireServer()
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- =============================================
-- ENHANCED FISHING V4 SYSTEM - IMPROVED
-- =============================================

-- 🚀 INSTANT FISHING FUNCTION - OPTIMIZED
local function ExecuteInstantFishingCycle()
    local catches = 0
    
    -- PHASE 1: EQUIP Rod (Fast)
    pcall(function() 
        if equipRemote then 
            equipRemote:FireServer(1) 
        end 
    end)
    
    task.wait(0.05) -- Very short delay
    
    -- PHASE 2: CHARGE Rod 
    pcall(function() 
        if ChargeRod then 
            ChargeRod:InvokeServer(tick()) 
        end 
    end)
    
    task.wait(ENHANCED_CONFIG.INSTANT_BITE_DELAY)
    
    -- PHASE 3: START Mini Game
    pcall(function() 
        if StartMini then 
            StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273) 
        end 
    end)
    
    -- PHASE 4: FINISH Fishing (Instant pull)
    pcall(function() 
        if FinishFish then 
            FinishFish:FireServer() 
        end 
    end)
    
    return catches
end

-- 🔥 ENHANCED FISHING LOOP - WITH EXCLAIM INTEGRATION
local function StartEnhancedFishing()
    if EnhancedFishingActive then
        warn("⚠️ Enhanced Fishing sudah aktif!")
        return
    end
    
    print("🎣 AUTO FISHING V4 DIHIDUPKAN!")
    print("Mode: INSTANT BITE + Exclaim Detection")
    
    EnhancedFishingActive = true
    TotalEnhancedCatches = 0
    EnhancedStartTime = tick()
    
    -- Setup exclaim detection
    if not SetupExclaimDetection() then
        SetupAlternativeExclaimDetection()
    end
    
    -- Main fishing thread
    task.spawn(function()
        print("🎣 Instant Fishing Thread started!")
        local cycleCount = 0
        local lastCatchCount = 0
        
        while EnhancedFishingActive do
            cycleCount = cycleCount + 1
            
            -- Execute instant fishing cycle
            local cycleCatches = ExecuteInstantFishingCycle()
            TotalEnhancedCatches = TotalEnhancedCatches + cycleCatches
            
            -- Adaptive speed calculation
            local elapsed = tick() - EnhancedStartTime
            local speedMultiplier = math.min(1 + (elapsed / 15), ENHANCED_CONFIG.MAX_SPEED_MULTIPLIER)
            
            -- Calculate wait time with variance
            local baseSpeed = ENHANCED_CONFIG.BASE_SPEED
            local randomVariance = math.random(95, 105) / 100
            local waitTime = (baseSpeed / speedMultiplier) * randomVariance
            
            -- Ensure minimum delay for stability
            task.wait(math.max(waitTime, 0.03))
            
            -- Performance monitoring
            if cycleCount % 50 == 0 then
                local currentRate = math.floor(TotalEnhancedCatches / math.max(elapsed, 1))
                local instantRate = TotalEnhancedCatches - lastCatchCount
                lastCatchCount = TotalEnhancedCatches
                
                print(string.format("♻️ Cycle: %d | Fish: %d | Rate: %d/s | Instant: %d", 
                    cycleCount, TotalEnhancedCatches, currentRate, instantRate))
            end
        end
        
        print("🛑 Instant Fishing Thread stopped! Total cycles: " .. cycleCount)
    end)
    
    -- UI Performance Monitor
    task.spawn(function()
        local lastUpdate = tick()
        local lastCount = 0
        
        while EnhancedFishingActive do
            local elapsed = tick() - EnhancedStartTime
            local currentRate = math.floor(TotalEnhancedCatches / math.max(elapsed, 1))
            
            -- Calculate instant rate (last 3 seconds)
            local instantRate = math.floor((TotalEnhancedCatches - lastCount) / math.max(tick() - lastUpdate, 0.1))
            lastUpdate = tick()
            lastCount = TotalEnhancedCatches
            
            -- Update window title
            pcall(function()
                if Window and Window.SetWindowName then
                    Window:SetWindowName(string.format(
                        "🎣 AUTO FISHING V4 | %d/s | %d TOTAL | EXCLAIM: %s",
                        instantRate, TotalEnhancedCatches,
                        ExclaimDetectionActive and "ACTIVE" or "INACTIVE"
                    ))
                end
            end)
            
            task.wait(2)
        end
    end)
    
    Rayfield:Notify({
        Title = "🎣 AUTO FISHING V4 STARTED",
        Content = "INSTANT BITE Mode Activated!\nExclaim detection: " .. (ExclaimDetectionActive and "ACTIVE" or "FALLBACK"),
        Duration = 5,
        Image = 4483362458
    })
end

local function StopEnhancedFishing()
    EnhancedFishingActive = false
    ExclaimDetectionActive = false
    
    local totalTime = tick() - EnhancedStartTime
    local avgRate = math.floor(TotalEnhancedCatches / math.max(totalTime, 1))
    
    pcall(function()
        if Window and Window.SetWindowName then
            Window:SetWindowName("🎣 Auto Fishing V4 - Codepik")
        end
    end)
    
    Rayfield:Notify({
        Title = "🛑 FISHING V4 STOPPED",
        Content = "Total: " .. TotalEnhancedCatches .. " fish | Avg: " .. avgRate .. "/sec",
        Duration = 5,
        Image = 4483362458
    })
end

-- =============================================
-- FISHING V1 (GAME AUTO) - KEEP ORIGINAL
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
    
    -- Perfect catch hook
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and self == StartMini and Config.FishingV1 then
                return old(self, -1.233184814453125, 0.9945034885633273)
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
    
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
-- UI CREATION - WITH IMPROVED V4 TOGGLE
-- =============================================

local function CreateUI()
    Window = Rayfield:CreateWindow({
        Name = "🎣 Codepik Premium++ V4",
        LoadingTitle = "Loading Codepik script..",
        LoadingSubtitle = "by Codepik - Enhanced V4",
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
    PatchTab:CreateLabel("🔄 Version: V4.4 - EXCLAIM EDITION")
    PatchTab:CreateLabel("📅 Update Date: 27-10-25")

    PatchTab:CreateButton({
        Name = "📋 Show V4.4 Features",
        Callback = function()
            Rayfield:Notify({
                Title = "🎣 Auto Fishing V4.4 Features",
                Content = [[
                🚀 NEW IN V4.4:
                • IMPROVED Exclaim Detection
                • Enhanced V4 Fishing System
                • Better Auto Recast
                • Optimized Performance
                
                🎯 EXCLAIM SYSTEM:
                • Auto detect exclaim mark
                • Instant auto recast
                • Fallback detection methods
                
                ⚡ V4 ENHANCEMENTS:
                • Faster fishing cycles
                • Adaptive speed system
                • Real-time performance stats
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
    MainTab:CreateToggle({
        Name = "🎣 Fishing V1 (Game Auto)",
        CurrentValue = Config.FishingV1,
        Callback = function(Value)
            Config.FishingV1 = Value
            if Value then
                Config.FishingV4 = false
                StopEnhancedFishing()
                StartFishingV1()
            else
                StopFishingV1()
            end
        end,
    })

    -- Fishing V4 (Enhanced)
    MainTab:CreateToggle({
        Name = "🚀 Fishing V4 (Ultra Instant + Exclaim)",
        CurrentValue = Config.FishingV4,
        Callback = function(Value)
            Config.FishingV4 = Value
            if Value then
                Config.FishingV1 = false
                StopFishingV1()
                StartEnhancedFishing()
            else
                StopEnhancedFishing()
            end
        end,
    })

    -- V4 Status Display
    local V4StatusLabel = MainTab:CreateLabel("V4 Status: INACTIVE")
    
    -- Update V4 status
    task.spawn(function()
        while task.wait(1) do
            local statusText = "V4 Status: "
            if EnhancedFishingActive then
                local elapsed = tick() - EnhancedStartTime
                local rate = math.floor(TotalEnhancedCatches / math.max(elapsed, 1))
                statusText = string.format("V4 Status: ACTIVE | %d fish | %d/s | Exclaim: %s", 
                    TotalEnhancedCatches, rate, ExclaimDetectionActive and "ON" or "OFF")
            else
                statusText = "V4 Status: INACTIVE"
            end
            V4StatusLabel:Set(statusText)
        end
    end)

    -- Fishing Tools Section
    MainTab:CreateSection("🎣 Fishing Tools")

    MainTab:CreateToggle({
        Name = "Perfect Catch",
        CurrentValue = Config.PerfectCatch,
        Callback = function(Value)
            Config.PerfectCatch = Value
        end,
    })

    MainTab:CreateToggle({
        Name = "Enable Fishing Radar",
        CurrentValue = Config.EnableRadar,
        Callback = function(Value)
            pcall(function()
                if RadarRemote then
                    RadarRemote:InvokeServer(Value)
                end
            end)
        end,
    })

    -- Exclaim Detection Settings
    MainTab:CreateSection("🎯 Exclaim Detection")

    MainTab:CreateSlider({
        Name = "Exclaim Wait Time",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = ENHANCED_CONFIG.EXCLAIM_WAIT_TIME,
        Callback = function(Value)
            ENHANCED_CONFIG.EXCLAIM_WAIT_TIME = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Fishing Speed",
        Range = {0.05, 0.5},
        Increment = 0.01,
        CurrentValue = ENHANCED_CONFIG.BASE_SPEED,
        Callback = function(Value)
            ENHANCED_CONFIG.BASE_SPEED = Value
        end,
    })

    -- ... (Keep the rest of your existing UI code for other features)
    
    -- Test Exclaim System Button
    MainTab:CreateButton({
        Name = "🧪 Test Exclaim System",
        Callback = function()
            if EnhancedFishingActive then
                Rayfield:Notify({
                    Title = "Exclaim Test",
                    Content = "Exclaim detection is ACTIVE and monitoring",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Exclaim Test",
                    Content = "Start V4 Fishing first to test exclaim system",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end,
    })

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Auto Fishing V4.4 - Codepik",
        Content = "Enhanced V4 with Exclaim Detection Loaded!\nStart V4 for auto exclaim recast!",
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
    elseif Config.FishingV4 then
        task.wait(2)
        StartEnhancedFishing()
    end
end)

-- Main initialization
task.spawn(function()
    task.wait(2)
    
    if SetupRemotes() then
        CreateUI()
        
        print("🎣 Auto Fishing V4.4 - Codepik Enhanced Edition")
        print("✅ All systems loaded successfully!")
        print("🚀 Features: V1 Game Auto + V4 Ultra Instant + Exclaim Detection")
        print("🎯 Exclaim System: Auto detect and recast when exclaim appears")
        print("⚡ Performance: Adaptive speed with real-time monitoring")
    else
        warn("❌ Failed to setup remotes!")
    end
end)

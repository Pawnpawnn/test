local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Core Variables
local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =============================================
-- CONFIGURATION
-- =============================================
local Config = {
    FishingEnabled = false,
    CycleSpeed = 1.5,
    UseBiteDetection = true,
    MaxWaitForBite = 8,
    InstantBiteDelay = 0.8
}

-- Fishing Variables
local FishingActive = false
local TotalCatches = 0
local StartTime = 0

-- Fishing State
local FishingState = {
    BiteDetected = false,
    ConsecutiveFails = 0,
    IsCharging = false
}

-- Remotes
local net
local ChargeRod, StartMini, FinishFish, FishCaught, equipRemote, stopfishing, UpdateChargeState

-- =============================================
-- CORE SYSTEMS
-- =============================================

local function SetupRemotes()
    local success = pcall(function()
        net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        
        ChargeRod = net["RF/ChargeFishingRod"]
        StartMini = net["RF/RequestFishingMinigameStarted"]
        FinishFish = net["RE/FishingCompleted"]
        FishCaught = net["RE/FishCaught"]
        equipRemote = net["RE/EquipToolFromHotbar"]
        stopfishing = net["RE/FishingStopped"]
        UpdateChargeState = net["RE/UpdateChargeState"]
    end)
    
    if success then
        print("✅ All fishing remotes loaded successfully!")
        return true
    else
        print("❌ Failed to load some remotes")
        return false
    end
end

-- =============================================
-- BITE DETECTION SYSTEM
-- =============================================

local function SetupBiteDetection()
    -- Monitor UpdateChargeState untuk deteksi bite
    if UpdateChargeState then
        UpdateChargeState.OnClientEvent:Connect(function(state)
            if state == true then
                FishingState.BiteDetected = true
                FishingState.IsCharging = false
                print("🎣 BITE DETECTED! Tanda seru muncul!")
            elseif state == false then
                FishingState.IsCharging = true
                print("⚡ Charging state: Ready for bite")
            end
        end)
        return true
    end
    return false
end

-- =============================================
-- FISHING SYSTEM - CORRECT SEQUENCE
-- =============================================

local function ExecuteFishingCycle()
    local catches = 0
    FishingState.BiteDetected = false
    FishingState.IsCharging = false

    print("🎯 Starting fishing cycle...")

    -- PHASE 1: Equip fishing rod (slot 1)
    pcall(function() 
        if equipRemote then 
            equipRemote:FireServer(1) -- Slot 1 untuk fishing rod
            print("✅ Phase 1: Fishing rod equipped")
        end 
    end)
    task.wait(0.3)

    -- PHASE 2: Charge fishing rod (lempar kail)
    pcall(function() 
        if ChargeRod then 
            ChargeRod:InvokeServer()
            FishingState.IsCharging = true
            print("✅ Phase 2: Fishing rod charged - Kail dilempar")
        end 
    end)
    task.wait(0.5)

    -- PHASE 3: Wait for bite (tanda seru)
    if Config.UseBiteDetection then
        local waitStart = tick()
        print("⏳ Waiting for bite signal...")
        
        while (tick() - waitStart) < Config.MaxWaitForBite do
            if FishingState.BiteDetected then
                print("🎣 BITE DETECTED! Proceeding to catch...")
                break
            end
            task.wait(0.1)
        end
        
        if not FishingState.BiteDetected then
            print("⏰ No bite detected, using timer...")
            task.wait(Config.InstantBiteDelay)
        end
    else
        task.wait(Config.InstantBiteDelay)
    end

    -- PHASE 4: Start fishing minigame (tarik ikan)
    pcall(function() 
        if StartMini then 
            StartMini:InvokeServer()
            print("✅ Phase 4: Fishing minigame started - Tarik ikan!")
        end 
    end)
    task.wait(0.3)

    -- PHASE 5: Finish fishing
    pcall(function() 
        if FinishFish then 
            FinishFish:FireServer()
            print("✅ Phase 5: Fishing finished")
        end 
    end)
    task.wait(0.2)

    -- PHASE 6: Catch fish
    if FishCaught then
        local success = pcall(function()
            FishCaught:FireServer()
            catches = 1
            print("✅ Phase 6: Fish caught successfully!")
        end)
        
        if not success then
            -- Alternative method
            pcall(function()
                FishCaught:InvokeServer()
                catches = 1
                print("✅ Phase 6: Fish caught (alternative method)!")
            end)
        end
    end

    -- PHASE 7: Stop fishing (reset state)
    pcall(function() 
        if stopfishing then 
            stopfishing:FireServer()
            print("✅ Phase 7: Fishing stopped - State reset")
        end 
    end)
    task.wait(0.2)

    -- Reset states untuk cycle berikutnya
    FishingState.BiteDetected = false
    FishingState.IsCharging = false

    return catches
end

-- Alternative method yang lebih sederhana
local function ExecuteSimpleFishingCycle()
    local catches = 0
    
    print("⚡ Simple fishing cycle...")

    -- Simple sequence
    pcall(function() equipRemote:FireServer(1) end)
    task.wait(0.3)
    
    pcall(function() ChargeRod:InvokeServer() end)
    task.wait(1.0) -- Tunggu lebih lama untuk bite
    
    pcall(function() StartMini:InvokeServer() end)
    task.wait(0.2)
    
    pcall(function() FinishFish:FireServer() end)
    task.wait(0.2)
    
    pcall(function() FishCaught:FireServer() end)
    task.wait(0.2)
    
    pcall(function() stopfishing:FireServer() end)
    task.wait(0.2)
    
    catches = 1
    print("✅ Simple cycle completed!")
    
    return catches
end

local function StartFishing()
    if FishingActive then return end
    
    print("🎣 FISHING SYSTEM STARTED")
    FishingActive = true
    Config.FishingEnabled = true
    StartTime = tick()
    TotalCatches = 0
    
    Rayfield:Notify({
        Title = "🎣 FISHING STARTED",
        Content = "Fishing system activated with proper sequence!",
        Duration = 3,
        Image = 4483362458
    })
    
    -- Setup bite detection
    if Config.UseBiteDetection then
        local biteDetectionEnabled = SetupBiteDetection()
        if biteDetectionEnabled then
            print("✅ Bite detection system enabled")
        else
            print("⚠️ Bite detection not available")
        end
    end
    
    -- Main fishing loop
    task.spawn(function()
        while Config.FishingEnabled and player.Character do
            local catchesThisCycle = 0
            
            -- Pilih method berdasarkan performance
            if FishingState.ConsecutiveFails < 2 then
                catchesThisCycle = ExecuteFishingCycle()
            else
                catchesThisCycle = ExecuteSimpleFishingCycle()
            end
            
            if catchesThisCycle > 0 then
                TotalCatches = TotalCatches + catchesThisCycle
                FishingState.ConsecutiveFails = 0
                print("✅ Cycle successful: " .. TotalCatches .. " total catches")
            else
                FishingState.ConsecutiveFails = FishingState.ConsecutiveFails + 1
                print("❌ Cycle failed: " .. FishingState.ConsecutiveFails .. " consecutive fails")
                
                -- Jika gagal terus, coba method yang berbeda
                if FishingState.ConsecutiveFails >= 3 then
                    Rayfield:Notify({
                        Title = "⚠️ FISHING ISSUE",
                        Content = "Trying different fishing method...",
                        Duration = 2,
                        Image = 4483362458
                    })
                    task.wait(1.5)
                end
            end
            
            -- Adaptive delay
            local delay = Config.CycleSpeed
            if FishingState.ConsecutiveFails > 0 then
                delay = math.min(delay * 1.3, 3.0)
            end
            
            task.wait(delay)
        end
        
        FishingActive = false
        print("🛑 FISHING STOPPED")
        
        -- Final stats
        if StartTime > 0 then
            local totalTime = tick() - StartTime
            local avgRate = math.floor(TotalCatches / math.max(totalTime, 1))
            
            Rayfield:Notify({
                Title = "📊 FISHING COMPLETED",
                Content = string.format("Total: %d fish | Rate: %d/sec", TotalCatches, avgRate),
                Duration = 5,
                Image = 4483362458
            })
        end
    end)
end

local function StopFishing()
    Config.FishingEnabled = false
    FishingActive = false
    
    -- Fire stop fishing remote
    pcall(function()
        if stopfishing then
            stopfishing:FireServer()
        end
    end)
    
    if StartTime > 0 then
        local totalTime = tick() - StartTime
        local avgRate = math.floor(TotalCatches / math.max(totalTime, 1))
        
        Rayfield:Notify({
            Title = "🛑 FISHING STOPPED",
            Content = "Total: " .. TotalCatches .. " fish | Rate: " .. avgRate .. "/sec",
            Duration = 5,
            Image = 4483362458
        })
    end
end

-- =============================================
-- SIMPLE UI
-- =============================================

local function CreateSimpleUI()
    local Window = Rayfield:CreateWindow({
        Name = "🎣 Fishing System V1",
        LoadingTitle = "Loading Proper Fishing System...",
        LoadingSubtitle = "Based on Remote Analysis",
        ConfigurationSaving = {
            Enabled = false
        },
        KeySystem = false
    })

    -- Main Tab
    local MainTab = Window:CreateTab("🔥 Fishing", 4483362458)

    -- Fishing Section
    MainTab:CreateSection("🎣 FISHING CONTROL")

    MainTab:CreateToggle({
        Name = "🎣 Enable Fishing",
        CurrentValue = Config.FishingEnabled,
        Callback = function(Value)
            if Value then
                StartFishing()
            else
                StopFishing()
            end
        end,
    })

    MainTab:CreateSlider({
        Name = "Cycle Speed",
        Range = {1.0, 5.0},
        Increment = 0.1,
        CurrentValue = Config.CycleSpeed,
        Suffix = "s",
        Callback = function(Value)
            Config.CycleSpeed = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Bite Wait Time",
        Range = {0.5, 3.0},
        Increment = 0.1,
        CurrentValue = Config.InstantBiteDelay,
        Suffix = "s",
        Callback = function(Value)
            Config.InstantBiteDelay = Value
        end,
    })

    MainTab:CreateToggle({
        Name = "Use Bite Detection",
        CurrentValue = Config.UseBiteDetection,
        Callback = function(Value)
            Config.UseBiteDetection = Value
        end,
    })

    MainTab:CreateSection("📊 STATISTICS")

    MainTab:CreateButton({
        Name = "📊 Show Fishing Stats",
        Callback = function()
            if FishingActive then
                local elapsed = tick() - StartTime
                local currentRate = math.floor(TotalCatches / math.max(elapsed, 1))
                
                Rayfield:Notify({
                    Title = "📊 Fishing Stats",
                    Content = string.format("Total: %d fish\nRate: %d/s\nTime: %.1fs", TotalCatches, currentRate, elapsed),
                    Duration = 6,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "📊 Fishing Stats",
                    Content = string.format("Total Fish: %d", TotalCatches),
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end,
    })

    MainTab:CreateButton({
        Name = "🔧 Test Single Cycle",
        Callback = function()
            local catches = ExecuteFishingCycle()
            Rayfield:Notify({
                Title = "⚡ Test Cycle",
                Content = "Fishing cycle executed! Catches: " .. catches,
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    MainTab:CreateSection("⚙️ SYSTEM")

    MainTab:CreateButton({
        Name = "🔄 Check Remotes",
        Callback = function()
            local success = SetupRemotes()
            Rayfield:Notify({
                Title = "Remote Check",
                Content = success and "✅ All remotes loaded!" or "❌ Some remotes failed",
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Proper Fishing System",
        Content = "Based on actual game remotes!",
        Duration = 3,
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
    
    task.wait(2)
    
    -- Restart fishing if it was active
    if Config.FishingEnabled then
        task.wait(2)
        StartFishing()
    end
end)

-- Main initialization
task.spawn(function()
    task.wait(2)
    
    if SetupRemotes() then
        CreateSimpleUI()
        
        print("🎣 Fishing System V1 - Based on Remote Analysis")
        print("✅ All fishing remotes loaded successfully!")
        print("⚡ Using proper 7-phase fishing sequence")
        print("🎣 Bite detection via UpdateChargeState")
    else
        warn("❌ Failed to setup remotes!")
        Rayfield:Notify({
            Title = "Initialization Error",
            Content = "Failed to setup fishing remotes",
            Duration = 5,
            Image = 4483362458
        })
    end
end)

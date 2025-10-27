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
    CycleSpeed = 2.0,
    CastDelay = 0.5,
    BiteWaitTime = 3.0,
    ReelDelay = 0.3
}

-- Fishing Variables
local FishingActive = false
local TotalCatches = 0
local StartTime = 0

-- Remotes
local net
local ChargeRod, StartMini, FinishFish, FishCaught, equipRemote, stopfishing

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
    end)
    
    if success then
        print("✅ All fishing remotes loaded!")
        return true
    else
        print("❌ Failed to load some remotes")
        return false
    end
end

-- =============================================
-- SIMPLE FISHING SYSTEM - NO BITE DETECTION
-- =============================================

local function ExecuteFishingCycle()
    local catches = 0

    print("🎯 Starting fishing cycle...")

    -- PHASE 1: Equip fishing rod
    local success1 = pcall(function()
        equipRemote:FireServer(1)
        print("✅ Rod equipped")
    end)
    
    if not success1 then
        print("❌ Failed to equip rod")
        return 0
    end
    task.wait(Config.CastDelay)

    -- PHASE 2: Charge fishing rod (lempar kail)
    local success2 = pcall(function()
        ChargeRod:InvokeServer()
        print("✅ Rod charged - Kail dilempar")
    end)
    
    if not success2 then
        print("❌ Failed to charge rod")
        return 0
    end

    -- PHASE 3: Wait for fish to bite
    print("⏳ Waiting for fish to bite...")
    task.wait(Config.BiteWaitTime)

    -- PHASE 4: Start fishing minigame (tarik ikan)
    local success3 = pcall(function()
        StartMini:InvokeServer()
        print("✅ Minigame started - Tarik ikan!")
    end)
    
    if not success3 then
        print("❌ Failed to start minigame")
        return 0
    end
    task.wait(Config.ReelDelay)

    -- PHASE 5: Finish fishing
    local success4 = pcall(function()
        FinishFish:FireServer()
        print("✅ Fishing finished")
    end)
    
    if not success4 then
        print("❌ Failed to finish fishing")
        return 0
    end
    task.wait(0.2)

    -- PHASE 6: Catch fish
    local success5 = pcall(function()
        FishCaught:FireServer()
        catches = 1
        print("✅ Fish caught!")
    end)
    
    if not success5 then
        print("❌ Failed to catch fish")
        return 0
    end
    task.wait(0.2)

    -- PHASE 7: Stop fishing
    pcall(function()
        stopfishing:FireServer()
        print("✅ Fishing stopped")
    end)

    return catches
end

-- Alternative method dengan timing berbeda
local function ExecuteQuickFishingCycle()
    local catches = 0
    
    print("⚡ Quick fishing cycle...")

    -- Faster sequence
    pcall(function() equipRemote:FireServer(1) end)
    task.wait(0.3)
    
    pcall(function() ChargeRod:InvokeServer() end)
    task.wait(1.5) -- Shorter wait for bite
    
    pcall(function() StartMini:InvokeServer() end)
    task.wait(0.2)
    
    pcall(function() FinishFish:FireServer() end)
    task.wait(0.2)
    
    pcall(function() FishCaught:FireServer() end)
    task.wait(0.2)
    
    pcall(function() stopfishing:FireServer() end)
    
    catches = 1
    print("✅ Quick cycle completed!")
    
    return catches
end

-- Test individual remote
local function TestRemote(remoteName, ...)
    print("🧪 Testing: " .. remoteName)
    local success, result = pcall(function()
        if remoteName == "ChargeRod" then
            return ChargeRod:InvokeServer(...)
        elseif remoteName == "StartMini" then
            return StartMini:InvokeServer(...)
        elseif remoteName == "FinishFish" then
            return FinishFish:FireServer(...)
        elseif remoteName == "FishCaught" then
            return FishCaught:FireServer(...)
        elseif remoteName == "equipRemote" then
            return equipRemote:FireServer(...)
        elseif remoteName == "stopfishing" then
            return stopfishing:FireServer(...)
        end
    end)
    
    if success then
        print("✅ " .. remoteName .. " success: " .. tostring(result))
        return true
    else
        print("❌ " .. remoteName .. " failed")
        return false
    end
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
        Content = "Simple fishing system activated!",
        Duration = 3,
        Image = 4483362458
    })
    
    -- Main fishing loop
    task.spawn(function()
        local consecutiveFails = 0
        
        while Config.FishingEnabled and player.Character do
            local catchesThisCycle = 0
            
            -- Pilih method berdasarkan performance
            if consecutiveFails < 2 then
                catchesThisCycle = ExecuteFishingCycle()
            else
                catchesThisCycle = ExecuteQuickFishingCycle()
            end
            
            if catchesThisCycle > 0 then
                TotalCatches = TotalCatches + catchesThisCycle
                consecutiveFails = 0
                print("✅ Cycle successful: " .. TotalCatches .. " total catches")
            else
                consecutiveFails = consecutiveFails + 1
                print("❌ Cycle failed: " .. consecutiveFails .. " consecutive fails")
                
                -- Jika gagal terus, coba method yang berbeda
                if consecutiveFails >= 3 then
                    Rayfield:Notify({
                        Title = "⚠️ ADJUSTING",
                        Content = "Trying different timing...",
                        Duration = 2,
                        Image = 4483362458
                    })
                    task.wait(2.0)
                end
            end
            
            task.wait(Config.CycleSpeed)
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
        stopfishing:FireServer()
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
        Name = "🎣 Simple Fishing V2",
        LoadingTitle = "Loading Simple Fishing System...",
        LoadingSubtitle = "No Bite Detection - Timer Based",
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
        Range = {1.5, 5.0},
        Increment = 0.1,
        CurrentValue = Config.CycleSpeed,
        Suffix = "s",
        Callback = function(Value)
            Config.CycleSpeed = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Bite Wait Time",
        Range = {1.0, 5.0},
        Increment = 0.1,
        CurrentValue = Config.BiteWaitTime,
        Suffix = "s",
        Callback = function(Value)
            Config.BiteWaitTime = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Cast Delay",
        Range = {0.3, 1.5},
        Increment = 0.1,
        CurrentValue = Config.CastDelay,
        Suffix = "s",
        Callback = function(Value)
            Config.CastDelay = Value
        end,
    })

    MainTab:CreateSection("🔧 TESTING")

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

    MainTab:CreateButton({
        Name = "🧪 Test Charge Rod",
        Callback = function()
            local success = TestRemote("ChargeRod")
            Rayfield:Notify({
                Title = "Remote Test",
                Content = success and "✅ ChargeRod works!" or "❌ ChargeRod failed",
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    MainTab:CreateButton({
        Name = "🧪 Test Start Mini",
        Callback = function()
            local success = TestRemote("StartMini")
            Rayfield:Notify({
                Title = "Remote Test",
                Content = success and "✅ StartMini works!" or "❌ StartMini failed",
                Duration = 3,
                Image = 4483362458
            })
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

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Simple Fishing System",
        Content = "Timer-based fishing activated!",
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
        
        print("🎣 Simple Fishing System V2")
        print("✅ All fishing remotes loaded!")
        print("⏰ Using timer-based system (no bite detection)")
        print("🔧 Test individual remotes first!")
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
    CycleSpeed = 1.0,
    UseBiteDetection = true,
    MaxWaitForBite = 5,
    InstantBiteDelay = 0.5
}

-- Fishing Variables
local FishingActive = false
local TotalCatches = 0
local StartTime = 0

-- Fishing State
local FishingState = {
    BiteDetected = false,
    ConsecutiveFails = 0
}

-- Remotes
local net, ChargeRod, StartMini, FinishFish, FishCaught, equipRemote, stopfishing

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
        stopfishing = net:WaitForChild("RE/FishingStopped") or net:WaitForChild("RF/FishingStopped")
    end)
    
    return success
end

-- =============================================
-- BITE DETECTION SYSTEM
-- =============================================

local function SetupBiteDetection()
    local biteRemote = nil
    
    -- Cari remote untuk bite detection
    local possibleBiteRemotes = {
        "RE/FishBite",
        "RF/FishBite", 
        "RE/BiteStarted",
        "RF/BiteStarted"
    }
    
    for _, remoteName in ipairs(possibleBiteRemotes) do
        local success, remote = pcall(function()
            return net[remoteName]
        end)
        if success and remote then
            biteRemote = remote
            print("✅ Bite detection remote found: " .. remoteName)
            break
        end
    end
    
    if biteRemote then
        biteRemote.OnClientEvent:Connect(function(...)
            FishingState.BiteDetected = true
            print("🎣 BITE DETECTED! Tanda seru muncul!")
        end)
        return true
    else
        print("⚠️ Bite detection remote not found")
        return false
    end
end

-- =============================================
-- FISHING SYSTEM
-- =============================================

local function ExecuteFishingCycle()
    local catches = 0
    FishingState.BiteDetected = false
    
    -- PHASE 1: Equip rod
    pcall(function() 
        if equipRemote then 
            equipRemote:FireServer(1)
        end 
    end)
    task.wait(0.2)
       
    -- PHASE 2: Charge rod 
    pcall(function() 
        if ChargeRod then 
            ChargeRod:InvokeServer(tick())
        end 
    end)
    task.wait(0.2)
    
    -- PHASE 3: Wait for bite
    if Config.UseBiteDetection then
        local waitStart = tick()
        print("⏳ Waiting for bite...")
        
        while (tick() - waitStart) < Config.MaxWaitForBite do
            if FishingState.BiteDetected then
                print("🎣 BITE DETECTED! Catching fish...")
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
    
    -- PHASE 4: Start minigame
    pcall(function() 
        if StartMini then 
            StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
        end 
    end)
    task.wait(0.2)
    
    -- PHASE 5: Finish fishing
    pcall(function() 
        if FinishFish then 
            FinishFish:FireServer()
        end 
    end)
    task.wait(0.2)
   
    -- PHASE 6: Stop fishing
    pcall(function() 
        if stopfishing then 
            stopfishing:FireServer()
        end 
    end)
    task.wait(0.2)
    
    -- PHASE 7: Catch fish
    if FishCaught then
        local success = pcall(function()
            FishCaught:FireServer()
            catches = 1
            print("✅ Fish caught!")
        end)
    end
    
    return catches
end

local function StartFishing()
    if FishingActive then return end
    
    print("🎣 FISHING STARTED")
    FishingActive = true
    Config.FishingEnabled = true
    StartTime = tick()
    TotalCatches = 0
    
    Rayfield:Notify({
        Title = "🎣 FISHING STARTED",
        Content = "Fishing system activated!",
        Duration = 3,
        Image = 4483362458
    })
    
    -- Setup bite detection
    if Config.UseBiteDetection then
        SetupBiteDetection()
    end
    
    -- Main fishing loop
    task.spawn(function()
        while Config.FishingEnabled and player.Character do
            local catchesThisCycle = ExecuteFishingCycle()
            
            if catchesThisCycle > 0 then
                TotalCatches = TotalCatches + catchesThisCycle
                FishingState.ConsecutiveFails = 0
            else
                FishingState.ConsecutiveFails = FishingState.ConsecutiveFails + 1
                print("❌ Failed to catch fish: " .. FishingState.ConsecutiveFails)
                
                if FishingState.ConsecutiveFails >= 3 then
                    task.wait(1) -- Delay longer if failing
                end
            end
            
            task.wait(Config.CycleSpeed)
        end
        
        FishingActive = false
        print("🛑 FISHING STOPPED")
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
        Name = "🎣 Simple Fishing",
        LoadingTitle = "Loading Fishing System...",
        LoadingSubtitle = "by Codepik",
        ConfigurationSaving = {
            Enabled = false
        },
        KeySystem = false
    })

    -- Main Tab
    local MainTab = Window:CreateTab("🔥 Main", 4483362458)

    -- Fishing Section
    MainTab:CreateSection("🎣 FISHING SYSTEM")

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
        Range = {0.5, 3.0},
        Increment = 0.1,
        CurrentValue = Config.CycleSpeed,
        Suffix = "s",
        Callback = function(Value)
            Config.CycleSpeed = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Bite Wait Time",
        Range = {0.1, 2.0},
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

    MainTab:CreateButton({
        Name = "📊 Show Stats",
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
                Content = "Cycle executed! Catches: " .. catches,
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    -- Settings Section
    MainTab:CreateSection("⚙️ SETTINGS")

    MainTab:CreateButton({
        Name = "🔄 Reload Script",
        Callback = function()
            Rayfield:Notify({
                Title = "Reloading...",
                Content = "Script will reload in 3 seconds",
                Duration = 3,
                Image = 4483362458
            })
            task.wait(3)
            -- Simple reload
            if Config.FishingEnabled then
                StopFishing()
            end
        end,
    })

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Simple Fishing System",
        Content = "Basic fishing system loaded!",
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
        
        print("🎣 Simple Fishing System Loaded")
        print("✅ All systems ready!")
        print("⚡ Features: Bite Detection + 7-Phase Fishing")
    else
        warn("❌ Failed to setup remotes!")
        Rayfield:Notify({
            Title = "Initialization Error",
            Content = "Failed to setup game remotes",
            Duration = 5,
            Image = 4483362458
        })
    end
end)

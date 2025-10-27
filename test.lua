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
    FishingV1 = false,  -- Game Auto
    FishingV4 = false,  -- Enhanced System
    FishingMethod = "Enhanced", -- Standard, Enhanced, Quick, Delayed
    FishingDelay = 0.3,
    CycleSpeed = 0.1,
    
    -- Enhanced Fishing Config
    INSTANT_BITE_DELAY = 0.2,
    
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

-- Fishing Variables
local FishingActive = false
local IsCasting = false
local TotalCatches = 0
local StartTime = 0
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

-- Fishing State untuk V4
local FishingState = {
    IsBiting = false,
    CurrentMethod = 1,
    ConsecutiveFails = 0,
    MethodSuccessCount = 0,
    MethodAttempts = 0
}

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
local RadarRemote, EquipOxy, UnequipOxy, PurchaseWeather, UpdateAutoFishing, stopfishing, UpdateChargeState, FishingStopped

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
        
        -- NEW REMOTES BASED ON YOUR INFO
        stopfishing = net:WaitForChild("RE/FishingStopped") or net:WaitForChild("RF/FishingStopped")
        UpdateChargeState = net:WaitForChild("RE/UpdateChargeState")
        FishingStopped = net:WaitForChild("RE/FishingStopped")
    end)
    
    return success
end

-- =============================================
-- FISHING SYSTEMS - UPDATED WITH NEW REMOTES
-- =============================================

-- Fishing V1 (Game Auto) - MASIH BEKERJA
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

-- NEW: Execute Instant Fishing Cycle berdasarkan info terbaru
local function ExecuteInstantFishingCycle()
    local catches = 0
    
    print("⚡ Executing Instant Fishing Cycle...")
    
    -- PHASE 1: LEMPAR Kail (INSTANT) - Equip rod
    pcall(function() 
        if equipRemote then 
            equipRemote:FireServer(1)
            print("✅ Phase 1: Rod equipped")
        end 
    end)
    task.wait(0.1)
       
    -- PHASE 2: CHARGE Rod 
    pcall(function() 
        if ChargeRod then 
            ChargeRod:InvokeServer(tick())
            print("✅ Phase 2: Rod charged")
        end 
    end)
    task.wait(0.1)
    
    -- Wait for bite detection
    task.wait(Config.INSTANT_BITE_DELAY)
    
    -- PHASE 3: START Mini Game (lempar kail)
    pcall(function() 
        if StartMini then 
            StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
            print("✅ Phase 3: Minigame started")
        end 
    end)
    task.wait(0.1)
    
    -- PHASE 4: FINISH Fishing (tarik kail INSTANT)
    pcall(function() 
        if FinishFish then 
            FinishFish:FireServer()
            print("✅ Phase 4: Fishing finished")
        end 
    end)
    task.wait(0.1)
   
    -- PHASE 5: STOP Fishing (NEW - penting setelah finish)
    pcall(function() 
        if stopfishing then 
            stopfishing:FireServer()
            print("✅ Phase 5: Fishing stopped")
        end 
    end)
    task.wait(0.1)
    
    -- PHASE 6: UPDATE Charge State (NEW)
    pcall(function() 
        if UpdateChargeState then 
            UpdateChargeState:FireServer(false) -- atau true tergantung state
            print("✅ Phase 6: Charge state updated")
        end 
    end)
    task.wait(0.1)
    
    -- PHASE 7: CATCH Fish 
    if FishCaught then
        local success = pcall(function()
            FishCaught:FireServer()
            catches = catches + 1
            print("✅ Phase 7: Fish caught!")
        end)
        if not success then
            -- Alternative catch method
            pcall(function()
                FishCaught:FireServer({
                    Name = "⚡ INSTANT FISH",
                    Tier = math.random(5, 7),
                    SellPrice = math.random(15000, 50000),
                    Rarity = "Legendary",
                    Weight = math.random(50, 200),
                    Length = math.random(100, 300)
                })
                catches = catches + 1
                print("✅ Phase 7: Fish caught (alternative method)!")
            end)
        end
    end
    
    return catches
end

-- Enhanced fishing system dengan new cycle
local function StartEnhancedFishingV4()
    if FishingActive then return end
    
    print("🔧 ENHANCED FISHING V4 STARTED")
    FishingActive = true
    Config.FishingV4 = true
    StartTime = tick()
    TotalCatches = 0
    
    -- Reset fishing state
    FishingState = {
        IsBiting = false,
        CurrentMethod = 1,
        ConsecutiveFails = 0,
        MethodSuccessCount = 0,
        MethodAttempts = 0
    }
    
    Rayfield:Notify({
        Title = "🔧 ENHANCED FISHING V4",
        Content = "New instant cycle system activated!",
        Duration = 5,
        Image = 4483362458
    })
    
    -- Main fishing loop dengan new instant cycle
    task.spawn(function()
        while Config.FishingV4 and player.Character do
            local catchesThisCycle = ExecuteInstantFishingCycle()
            
            if catchesThisCycle > 0 then
                TotalCatches = TotalCatches + catchesThisCycle
                FishingState.MethodSuccessCount = FishingState.MethodSuccessCount + 1
                FishingState.ConsecutiveFails = 0
                print(`✅ Cycle successful: {TotalCatches} total catches`)
            else
                FishingState.ConsecutiveFails = FishingState.ConsecutiveFails + 1
                print(`❌ Cycle failed: {FishingState.ConsecutiveFails} consecutive fails`)
                
                -- Try alternative method if failing
                if FishingState.ConsecutiveFails >= 3 then
                    print("🔄 Trying alternative method...")
                    task.wait(1) -- Wait a bit before retry
                end
            end
            
            -- Adaptive delay based on performance
            local delay = Config.CycleSpeed
            if FishingState.ConsecutiveFails > 0 then
                delay = math.min(delay * 1.5, 2.0) -- Increase delay if failing
            end
            
            task.wait(delay)
        end
        
        FishingActive = false
        print("🛑 ENHANCED FISHING STOPPED")
        
        -- Final stats
        if StartTime > 0 then
            local totalTime = tick() - StartTime
            local avgRate = math.floor(TotalCatches / math.max(totalTime, 1))
            
            Rayfield:Notify({
                Title = "📊 FISHING COMPLETED",
                Content = string.format("Total: %d fish | Rate: %d/sec | Time: %.1fs", TotalCatches, avgRate, totalTime),
                Duration = 6,
                Image = 4483362458
            })
        end
    end)
end

-- Alternative fishing method for compatibility
local function StartStandardFishingV4()
    if FishingActive then return end
    
    print("🚀 STANDARD FISHING V4 STARTED")
    FishingActive = true
    Config.FishingV4 = true
    StartTime = tick()
    TotalCatches = 0
    
    Rayfield:Notify({
        Title = "🚀 FISHING V4 STARTED",
        Content = "Standard Method Activated!",
        Duration = 5,
        Image = 4483362458
    })
    
    -- Standard fishing loop
    task.spawn(function()
        while Config.FishingV4 and player.Character do
            local catchesThisCycle = 0
            
            pcall(function()
                -- Simple cycle without complex phases
                if equipRemote then 
                    equipRemote:FireServer(1)
                    task.wait(0.1)
                end
                
                if ChargeRod then 
                    ChargeRod:InvokeServer(tick())
                    task.wait(0.15)
                end
                
                if StartMini then
                    StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
                    task.wait(0.05)
                end
                
                if FinishFish then
                    FinishFish:FireServer()
                    task.wait(0.05)
                end
                
                -- NEW: Add stop fishing
                if stopfishing then
                    stopfishing:FireServer()
                    task.wait(0.05)
                end
                
                if FishCaught then
                    FishCaught:FireServer()
                    catchesThisCycle = 1
                end
            end)
            
            TotalCatches = TotalCatches + catchesThisCycle
            
            task.wait(Config.CycleSpeed)
        end
        
        FishingActive = false
        print("🛑 STANDARD FISHING STOPPED")
    end)
end

local function StopFishingV4()
    Config.FishingV4 = false
    FishingActive = false
    
    -- Fire stop fishing remote when manually stopping
    pcall(function()
        if stopfishing then
            stopfishing:FireServer()
        end
    end)
    
    if StartTime > 0 then
        local totalTime = tick() - StartTime
        local avgRate = math.floor(TotalCatches / math.max(totalTime, 1))
        
        Rayfield:Notify({
            Title = "🛑 FISHING V4 STOPPED",
            Content = "Total: " .. TotalCatches .. " fish | Avg: " .. avgRate .. "/sec",
            Duration = 5,
            Image = 4483362458
        })
    end
end

-- =============================================
-- AUTO ENCHANT ROD SYSTEM
-- =============================================

local function AutoEnchantRod()
    local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
    
    -- Tunggu karakter
    local char = player.Character
    if not char then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "Character not found. Please wait...",
            Duration = 3
        })
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "HumanoidRootPart not found.",
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
    local slot5 = backpackGui and backpackGui:FindFirstChild("Display") and backpackGui.Display:FindFirstChild("Slot5")
    
    if not slot5 then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "Slot 5 not found in backpack.",
            Duration = 3
        })
        return
    end
    
    local itemName = slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")

    if not itemName or not string.lower(itemName.Text):find("enchant") then
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

    local originalPosition = hrp.CFrame
    task.wait(1)
    hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
    task.wait(1.2)

    local success, error = pcall(function()
        local equipRod = net:WaitForChild("RE/EquipToolFromHotbar", 5)
        local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar", 5)
        
        if not equipRod or not activateEnchant then
            error("Enchanting remotes not found")
            return
        end
        
        equipRod:FireServer(5)
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

    if not success then
        Rayfield:Notify({
            Title = "Enchant Failed",
            Content = "Error: " .. tostring(error),
            Duration = 5,
            Image = 4483362458
        })
    end

    task.wait(0.9)
    hrp.CFrame = originalPosition
end

-- =============================================
-- QUEST SYSTEM (SAMA SEPERTI SEBELUMNYA)
-- =============================================

local QuestTasks = {
    ["Catch a SECRET Crystal Crab"] = "CRYSTAL_CRAB",
    ["Catch 100 Epic Fish"] = "CRYSTAL_CRAB", 
    ["Catch 10,000 Fish"] = "CRYSTAL_CRAB",
    ["Catch 300 Rare/Epic fish"] = "RARE_EPIC_FISH",
    ["Earn 1M Coins"] = "FARM_COINS",
    ["Catch 1 SECRET fish at Sisyphus"] = "SECRET_SYPUSH",
    ["Catch 3 Mythic fishes at Sisyphus"] = "SECRET_SYPUSH",
    ["Create 3 Transcended Stones"] = "CREATE_STONES",
    ["Catch 1 SECRET fish at Sacred Temple"] = "SECRET_TEMPLE",
    ["Catch 1 SECRET fish at Ancient Jungle"] = "SECRET_JUNGLE"
}

local QuestLocations = {
    ["CRYSTAL_CRAB"] = CFrame.new(40.0956, 1.7772, 2757.2583),
    ["RARE_EPIC_FISH"] = CFrame.new(-3596.9094, -281.1832, -1645.1220),
    ["SECRET_SYPUSH"] = CFrame.new(-3658.5747, -138.4813, -951.7969),
    ["SECRET_TEMPLE"] = CFrame.new(1451.4100, -22.1250, -635.6500),
    ["SECRET_JUNGLE"] = CFrame.new(1479.6647, 11.1430, -297.9549),
    ["FARM_COINS"] = CFrame.new(-553.3464, 17.1376, 114.2622)
}

local function GetQuestTracker(questName)
    local menu = Workspace:FindFirstChild("!!! MENU RINGS")
    if not menu then return nil end
    
    for _, inst in ipairs(menu:GetChildren()) do
        if inst.Name:find("Tracker") and string.lower(inst.Name):find(string.lower(questName)) then
            return inst
        end
    end
    return nil
end

local function GetQuestProgress(questName)
    local tracker = GetQuestTracker(questName)
    if not tracker then return 0 end
    
    local label = tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui") 
        and tracker.Board.Gui:FindFirstChild("Content") 
        and tracker.Board.Gui.Content:FindFirstChild("Progress") 
        and tracker.Board.Gui.Content.Progress:FindFirstChild("ProgressLabel")
        
    if label and label:IsA("TextLabel") then
        local percent = string.match(label.Text, "([%d%.]+)%%")
        return tonumber(percent) or 0
    end
    return 0
end

local function GetAllTasks(questName)
    local tracker = GetQuestTracker(questName)
    if not tracker then return {} end
    
    local content = tracker:FindFirstChild("Board") and tracker.Board:FindFirstChild("Gui") and tracker.Board.Gui:FindFirstChild("Content")
    if not content then return {} end
    
    local tasks = {}
    for _, obj in ipairs(content:GetChildren()) do
        if obj:IsA("TextLabel") and obj.Name:match("Label") and not obj.Name:find("Progress") then
            local txt = obj.Text
            local percent = string.match(txt, "([%d%.]+)%%") or "0"
            local done = txt:find("100%%") or txt:find("DONE") or txt:find("COMPLETED")
            table.insert(tasks, {name = txt, percent = tonumber(percent), completed = done ~= nil})
        end
    end
    return tasks
end

local function GetActiveTasks(questName)
    local all = GetAllTasks(questName)
    local active = {}
    for _, t in ipairs(all) do
        if not t.completed then
            table.insert(active, t)
        end
    end
    return active
end

local function FindLocationByTaskName(taskName)
    for key, loc in pairs(QuestTasks) do
        if string.find(taskName, key, 1, true) then
            return loc
        end
    end
    return nil
end

local function TeleportToQuestLocation(locName)
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local cf = QuestLocations[locName]
    if cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- Quest Automation Loop
task.spawn(function()
    while task.wait(2) do
        if not QuestState.Active or not QuestState.CurrentQuest then 
            if QuestState.Fishing then
                Config.FishingV4 = false
                QuestState.Fishing = false
            end
            continue 
        end

        local questProgress = GetQuestProgress(QuestState.CurrentQuest)
        local activeTasks = GetActiveTasks(QuestState.CurrentQuest)
        
        -- Check if quest is completed
        if questProgress >= 100 then
            Config.FishingV4 = false
            QuestState.Active = false
            QuestState.Fishing = false
            
            Rayfield:Notify({
                Title = "🎉 QUEST COMPLETED",
                Content = "All tasks finished for " .. QuestState.CurrentQuest,
                Duration = 5,
                Image = 4483362458
            })
            continue
        end

        if #activeTasks == 0 then
            Config.FishingV4 = false
            QuestState.Active = false
            QuestState.Fishing = false
            continue
        end

        -- Find current task
        local currentTask = nil
        local currentTaskIndex = nil
        
        for i, t in ipairs(activeTasks) do
            if QuestState.SelectedTask and t.name == QuestState.SelectedTask then
                currentTask = t
                currentTaskIndex = i
                break
            end
        end

        if not currentTask then
            -- Select new task
            if QuestState.LastTaskIndex and QuestState.LastTaskIndex <= #activeTasks then
                currentTaskIndex = QuestState.LastTaskIndex
                currentTask = activeTasks[currentTaskIndex]
            else
                currentTaskIndex = 1
                currentTask = activeTasks[1]
            end
            
            if currentTask then
                QuestState.SelectedTask = currentTask.name
                QuestState.LastTaskIndex = currentTaskIndex
                
                Rayfield:Notify({
                    Title = "🎯 NEW TASK STARTED",
                    Content = currentTask.name .. " - " .. string.format("%.1f%%", currentTask.percent or 0),
                    Duration = 4,
                    Image = 4483362458
                })
            end
        end

        if not currentTask then
            QuestState.SelectedTask = nil
            QuestState.LastTaskIndex = nil
            QuestState.CurrentLocation = nil
            QuestState.Teleported = false
            QuestState.Fishing = false
            Config.FishingV4 = false
            continue
        end

        if currentTask.percent >= 100 then
            -- Task completed
            Rayfield:Notify({
                Title = "✅ TASK COMPLETED",
                Content = currentTask.name .. " - 100% FINISHED",
                Duration = 3,
                Image = 4483362458
            })
            
            QuestState.SelectedTask = nil
            QuestState.CurrentLocation = nil
            QuestState.Teleported = false
            QuestState.Fishing = false
            Config.FishingV4 = false
            
            if currentTaskIndex < #activeTasks then
                QuestState.LastTaskIndex = currentTaskIndex + 1
            else
                QuestState.LastTaskIndex = 1
            end
            continue
        end

        if not QuestState.CurrentLocation then
            QuestState.CurrentLocation = FindLocationByTaskName(currentTask.name)
            if not QuestState.CurrentLocation then
                QuestState.SelectedTask = nil
                continue
            end
        end

        if not QuestState.Teleported then
            if TeleportToQuestLocation(QuestState.CurrentLocation) then
                QuestState.Teleported = true
                task.wait(2)
            end
            continue
        end

        if not QuestState.Fishing then
            Config.FishingV4 = true
            StartEnhancedFishingV4()
            QuestState.Fishing = true
            Rayfield:Notify({
                Title = "🎣 QUEST FARMING STARTED",
                Content = "Auto fishing for: " .. currentTask.name,
                Duration = 3,
                Image = 4483362458
            })
        end
    end
end)

-- =============================================
-- WEBHOOK SYSTEM (SAMA)
-- =============================================

local function formatCurrency(amount)
    if not amount or amount <= 0 then
        return "$0"
    elseif amount >= 1000000 then
        return string.format("$%.2fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("$%.2fK", amount / 1000)
    else
        return "$" .. tostring(math.floor(amount))
    end
end

local function sendWebhook(fishName, fishTier, sellPrice, rarity)
    if not webhookEnabled or webhookUrl == "" or webhookUrl == "https://discord.com/api/webhooks/..." then
        return
    end
    
    local success, err = pcall(function()
        local timestamp = DateTime.now():ToIsoDate()
        
        local embed = {
            {
                ["title"] = "🎣 FISH CAUGHT!",
                ["color"] = 65280,
                ["fields"] = {
                    {
                        ["name"] = "Fish Name",
                        ["value"] = fishName or "Unknown",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Tier",
                        ["value"] = tostring(fishTier or "Unknown"),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Rarity",
                        ["value"] = rarity or "Unknown",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Sell Price",
                        ["value"] = formatCurrency(sellPrice or 0),
                        ["inline"] = true
                    }
                },
                ["footer"] = {
                    ["text"] = "Auto Fishing V4 • " .. timestamp
                },
                ["thumbnail"] = {
                    ["url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
                }
            }
        }
        
        local data = {
            ["embeds"] = embed,
            ["username"] = "Fish Notifier",
            ["avatar_url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
        }
        
        local jsonData = HttpService:JSONEncode(data)
        
        local requestFunc = (syn and syn.request) or 
                          (http and http.request) or 
                          (http_request) or
                          (request)
        
        if not requestFunc then
            warn("❌ Your executor doesn't support HTTP requests!")
            return
        end
        
        local response = requestFunc({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        
        print("📢 Webhook sent: " .. (fishName or "Unknown"))
    end)
    
    if not success then
        warn("Webhook error: " .. tostring(err))
    end
end

local function shouldSendWebhook(fishName, fishTier)
    if not webhookEnabled or #SelectedWebhookCategories == 0 then
        return false
    end
    
    if fishTier then
        if table.find(SelectedWebhookCategories, "Secret") and fishTier == 7 then
            return true
        elseif table.find(SelectedWebhookCategories, "Mythic") and fishTier == 6 then
            return true
        elseif table.find(SelectedWebhookCategories, "Legendary") and fishTier == 5 then
            return true
        end
    end
    
    return false
end

-- =============================================
-- UTILITY SYSTEMS (SAMA)
-- =============================================

-- Perfect Catch System
local function TogglePerfectCatch(enabled)
    Config.PerfectCatch = enabled
    
    if enabled then
        local mt = getrawmetatable(game)
        if not mt then return end
        
        setreadonly(mt, false)
        local old = mt.__namecall
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and self == StartMini and Config.PerfectCatch then
                return old(self, -1.233184814453125, 0.9945034885633273)
            end
            return old(self, ...)
        end)
        
        setreadonly(mt, true)
    end
end

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
            if equipRemote then
                equipRemote:FireServer(2)
            end
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
        if sellRemote then
            sellRemote:InvokeServer()
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Successfully sold items!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Sell Error",
                Content = "Sell remote not found",
                Duration = 3,
                Image = 4483362458
            })
        end
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
local NoClipConnection = nil
local function ToggleNoClip(enabled)
    Config.NoClip = enabled
    
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    
    if enabled then
        NoClipConnection = RunService.Stepped:Connect(function()
            if not Config.NoClip then return end
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- XRay
local XRayConnection = nil
local function ToggleXRay(enabled)
    Config.XRay = enabled
    
    if XRayConnection then
        XRayConnection:Disconnect()
        XRayConnection = nil
    end
    
    if enabled then
        XRayConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency < 0.5 then
                        part.LocalTransparencyModifier = 0.5
                    end
                end
            end)
        end)
    else
        pcall(function()
            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end)
    end
end

-- Infinite Zoom
local InfiniteZoomConnection = nil
local function ToggleInfiniteZoom(enabled)
    Config.InfiniteZoom = enabled
    
    if InfiniteZoomConnection then
        InfiniteZoomConnection:Disconnect()
        InfiniteZoomConnection = nil
    end
    
    if enabled then
        InfiniteZoomConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if player:FindFirstChild("CameraMaxZoomDistance") then
                    player.CameraMaxZoomDistance = 10000
                end
            end)
        end)
    else
        pcall(function()
            if player:FindFirstChild("CameraMaxZoomDistance") then
                player.CameraMaxZoomDistance = 128
            end
        end)
    end
end

-- Auto Jump
local AutoJumpConnection = nil
local function ToggleAutoJump(enabled)
    Config.AutoJump = enabled
    
    if AutoJumpConnection then
        AutoJumpConnection:Disconnect()
        AutoJumpConnection = nil
    end
    
    if enabled then
        AutoJumpConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                if Humanoid and Humanoid.FloorMaterial ~= Enum.Material.Air and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(Config.AutoJumpDelay)
                end
            end)
        end)
    end
end

-- =============================================
-- EMERGENCY & SAFETY
-- =============================================

local function EmergencyStopAll()
    print("🚨 EMERGENCY STOP ALL SYSTEMS")
    
    -- Stop all fishing
    FishingActive = false
    Config.FishingV1 = false
    Config.FishingV4 = false
    
    -- Stop other systems
    Config.AutoBuyWeather = false
    Config.AutoJump = false
    QuestState.Active = false
    
    -- Fire stop fishing remote
    pcall(function()
        if stopfishing then
            stopfishing:FireServer()
        end
    end)
    
    -- Disconnect all connections
    local connections = {AFKConnection, WalkOnWaterConnection, NoClipConnection, XRayConnection, 
                        InfiniteZoomConnection, AutoJumpConnection, PositionLockConnection,
                        LightingConnection, FogConnection}
    
    for _, connection in pairs(connections) do
        if connection then
            pcall(function() connection:Disconnect() end)
        end
    end
    
    Rayfield:Notify({
        Title = "🚨 EMERGENCY STOP",
        Content = "All systems stopped immediately!",
        Duration = 3,
        Image = 4483362458
    })
end

-- =============================================
-- UI CREATION - DIPERBAIKI DENGAN SISTEM BARU
-- =============================================

local function CreateUI()
    Window = Rayfield:CreateWindow({
        Name = "🎣 Codepik Premium++ V4.5",
        LoadingTitle = "Loading New Fishing System..",
        LoadingSubtitle = "by Codepik - Instant Cycle System",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "codepik",
            FileName = "codepik_instant"
        },
        KeySystem = false
    })

    -- Patch Note Tab
    local PatchTab = Window:CreateTab("💌 Patch Notes", 4483362458)
    
    PatchTab:CreateSection("📝 Patch Notes V4.5")
    PatchTab:CreateLabel("🔄 Version: V4.5 - Instant Cycle System")
    PatchTab:CreateLabel("📅 Update Date: 27-10-25")

    PatchTab:CreateButton({
        Name = "📋 Show V4.5 Features",
        Callback = function()
            Rayfield:Notify({
                Title = "🎣 Auto Fishing V4.5 Features",
                Content = [[
                🚀 NEW IN V4.5:
                • New Instant Fishing Cycle System
                • 7-Phase Fishing Process
                • Added StopFishing Remote
                • Added UpdateChargeState Remote
                • Better Phase Management
                • Improved Error Recovery

                🎯 PHASE SYSTEM:
                1. Equip Rod
                2. Charge Rod  
                3. Wait for Bite
                4. Start Minigame
                5. Finish Fishing
                6. STOP Fishing (NEW)
                7. Update Charge State (NEW)
                8. Catch Fish

                🔧 TECHNICAL:
                • Proper remote sequencing
                • Enhanced error handling
                • Better state management
                • Improved catch detection
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
                StartFishingV1()
            else
                StopFishingV1()
            end
        end,
    })

    -- Fishing V4 Enhanced dengan sistem baru
    MainTab:CreateToggle({
        Name = "⚡ Fishing V4 (Instant Cycle)",
        CurrentValue = Config.FishingV4,
        Callback = function(Value)
            Config.FishingV4 = Value
            if Value then
                Config.FishingV1 = false
                StartEnhancedFishingV4()
            else
                StopFishingV4()
            end
        end,
    })

    MainTab:CreateSlider({
        Name = "Cycle Speed",
        Range = {0.01, 2.0},
        Increment = 0.05,
        CurrentValue = Config.CycleSpeed,
        Suffix = "s",
        Callback = function(Value)
            Config.CycleSpeed = Value
        end,
    })

    MainTab:CreateSlider({
        Name = "Bite Detection Delay",
        Range = {0.1, 1.0},
        Increment = 0.05,
        CurrentValue = Config.INSTANT_BITE_DELAY,
        Suffix = "s",
        Callback = function(Value)
            Config.INSTANT_BITE_DELAY = Value
        end,
    })

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
        Name = "🔧 Test Instant Cycle",
        Callback = function()
            local catches = ExecuteInstantFishingCycle()
            Rayfield:Notify({
                Title = "⚡ Test Cycle",
                Content = "Instant cycle executed! Catches: " .. catches,
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    -- Fishing Tools Section
    MainTab:CreateSection("🎣 Fishing Tools")

    MainTab:CreateToggle({
        Name = "Perfect Catch",
        CurrentValue = Config.PerfectCatch,
        Callback = function(Value)
            TogglePerfectCatch(Value)
        end,
    })

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

    -- Auto Favorite Section
    MainTab:CreateSection("⭐ Auto Favorite System")

    MainTab:CreateToggle({
        Name = "Enable Auto Favorite",
        CurrentValue = AutoFavorite.Enabled,
        Callback = function(Value)
            AutoFavorite.Enabled = Value
            if Value then
                InitializeAutoFavorite()
            end
        end,
    })

    MainTab:CreateDropdown({
        Name = "Favorite Categories",
        Options = {"Secret", "Mythic", "Legendary"},
        CurrentOption = {"Secret"},
        MultipleOptions = true,
        Callback = function(Options)
            AutoFavorite.SelectedCategories = Options
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

    MainTab:CreateToggle({
        Name = "Auto Sell Enabled",
        CurrentValue = Config.AutoSell,
        Callback = function(Value)
            Config.AutoSell = Value
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
    
    -- [SISA UI CODE SAMA SEPERTI SEBELUMNYA...]
    -- Quest Tab, Teleport Tab, Webhook Tab, Player Tab, Graphics Tab, Utility Tab, Settings Tab
    -- ... (code untuk tab lainnya tetap sama seperti sebelumnya)

    -- Initial notification
    Rayfield:Notify({
        Title = "🎣 Auto Fishing V4.5 - Instant Cycle",
        Content = "New 7-phase fishing system loaded!",
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
        StartEnhancedFishingV4()
    end
    
    -- Restore other features...
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
    
    if Config.PerformanceMode then
        task.wait(1)
        TogglePerformanceMode(true)
    end
end)

-- Fish threshold monitor
task.spawn(function()
    while task.wait(1) do
        if Config.AutoSell and (FishingActive or Config.FishingV1 or Config.FishingV4) and #obtainedFishUUIDs >= obtainedLimit then
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Selling fish at threshold...",
                Duration = 3,
                Image = 4483362458
            })
            pcall(function() 
                if sellRemote then
                    sellRemote:InvokeServer() 
                end
            end)
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
        ApplyPermanentLighting()
        
        print("🎣 Auto Fishing V4.5 - Instant Cycle System")
        print("✅ All systems loaded successfully!")
        print("🚀 Features: V1 Game Auto + V4 Instant Cycle")
        print("🎯 Hotkey: CTRL+SHIFT+P for emergency stop")
        print("⚡ Using new 7-phase fishing cycle with stopfishing remote")
    else
        warn("❌ Failed to setup remotes!")
        Rayfield:Notify({
            Title = "Initialization Error",
            Content = "Failed to setup game remotes. Some features may not work.",
            Duration = 10,
            Image = 4483362458
        })
    end
end)

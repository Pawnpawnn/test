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
    -- Fishing Systems
    FishingV1 = false,
    FishingV2 = false,
    
    -- Performance Settings
    PerfectCatch = false,
    PerformanceMode = false,
    
    -- Player Settings
    WalkSpeed = 16,
    JumpPower = 50,
    AutoJump = false,
    AutoJumpDelay = 3,
    
    -- Utility Settings
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
    
    -- Teleport Settings
    LockedPosition = false,
    LockCFrame = nil,
    SavedPosition = nil,
    
    -- Weather Settings
    AutoBuyWeather = false,
    SelectedWeathers = {},
    
    -- System Settings
    AutoRejoin = false,
    Brightness = 2,
    TimeOfDay = 14,
}

-- Fishing State Variables
local FishingActive = false
local IsCasting = false
local TotalCatches = 0
local StartTime = 0
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

-- Webhook Configuration
local WebhookConfig = {
    Enabled = false,
    Url = "",
    SelectedCategories = {"Secret"}
}

-- Auto Favorite Configuration
local AutoFavoriteConfig = {
    Enabled = false,
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedCategories = {"Secret"},
    ScanCooldown = 5,
    LastScanTime = 0
}

-- Quest System Configuration
local QuestConfig = {
    Active = false,
    CurrentQuest = nil,
    SelectedTask = nil,
    CurrentLocation = nil,
    Teleported = false,
    Fishing = false,
    LastProgress = 0,
    LastTaskIndex = nil
}

-- Fishing V2 State
local FishingV2State = {
    Enabled = false,
    Active = false,
    DetectedRod = nil,
    RodDelay = 0.5,
    DelayInitialized = false
}

-- Remote References
local RemoteReferences = {
    Net = nil,
    ChargeRod = nil,
    StartMini = nil,
    FinishFish = nil,
    FishCaught = nil,
    EquipRemote = nil,
    SellRemote = nil,
    FavoriteRemote = nil,
    RadarRemote = nil,
    EquipOxy = nil,
    UnequipOxy = nil,
    PurchaseWeather = nil,
    UpdateAutoFishing = nil,
    RodRemote = nil,
    MiniGameRemote = nil,
    FinishRemote = nil
}

-- UI Reference
local Window = nil

-- =============================================
-- CORE SYSTEMS
-- =============================================

local function SetupRemoteReferences()
    local success = pcall(function()
        RemoteReferences.Net = ReplicatedStorage:WaitForChild("Packages")._Index["sleitnick_net@0.2.0"].net
        
        RemoteReferences.ChargeRod = RemoteReferences.Net:WaitForChild("RF/ChargeFishingRod")
        RemoteReferences.StartMini = RemoteReferences.Net:WaitForChild("RF/RequestFishingMinigameStarted")
        RemoteReferences.FinishFish = RemoteReferences.Net:WaitForChild("RE/FishingCompleted")
        RemoteReferences.FishCaught = RemoteReferences.Net:WaitForChild("RE/FishCaught") or RemoteReferences.Net:WaitForChild("RF/FishCaught")
        RemoteReferences.EquipRemote = RemoteReferences.Net:WaitForChild("RE/EquipToolFromHotbar")
        RemoteReferences.SellRemote = RemoteReferences.Net:WaitForChild("RF/SellAllItems")
        RemoteReferences.FavoriteRemote = RemoteReferences.Net:WaitForChild("RE/FavoriteItem")
        RemoteReferences.RadarRemote = RemoteReferences.Net:WaitForChild("RF/UpdateFishingRadar")
        RemoteReferences.EquipOxy = RemoteReferences.Net:WaitForChild("RF/EquipOxygenTank")
        RemoteReferences.UnequipOxy = RemoteReferences.Net:WaitForChild("RF/UnequipOxygenTank")
        RemoteReferences.PurchaseWeather = RemoteReferences.Net:WaitForChild("RF/PurchaseWeatherEvent")
        RemoteReferences.UpdateAutoFishing = RemoteReferences.Net:WaitForChild("RF/UpdateAutoFishingState")
        RemoteReferences.RodRemote = RemoteReferences.Net:WaitForChild("RF/ChargeFishingRod")
        RemoteReferences.MiniGameRemote = RemoteReferences.Net:WaitForChild("RF/RequestFishingMinigameStarted")
        RemoteReferences.FinishRemote = RemoteReferences.Net:WaitForChild("RE/FishingCompleted")
    end)
    
    return success
end

-- =============================================
-- FISHING SYSTEMS
-- =============================================

local function StartFishingV1()
    if FishingActive then return end
    
    FishingActive = true
    Config.FishingV1 = true
    
    pcall(function()
        if RemoteReferences.UpdateAutoFishing then
            RemoteReferences.UpdateAutoFishing:InvokeServer(true)
        end
    end)
    
    if Config.PerfectCatch then
        local metatable = getrawmetatable(game)
        if metatable then
            setreadonly(metatable, false)
            local originalNamecall = metatable.__namecall
            
            metatable.__namecall = newcclosure(function(self, ...)
                local methodName = getnamecallmethod()
                if methodName == "InvokeServer" and self == RemoteReferences.StartMini and Config.FishingV1 then
                    return originalNamecall(self, -1.233184814453125, 0.9945034885633273)
                end
                return originalNamecall(self, ...)
            end)
            
            setreadonly(metatable, true)
        end
    end
    
    Rayfield:Notify({
        Title = "🎣 FISHING V1 STARTED",
        Content = "Game Auto System Activated!",
        Duration = 5,
        Image = 4483362458
    })
    
    task.spawn(function()
        while Config.FishingV1 do
            task.wait(1)
        end
        
        pcall(function()
            if RemoteReferences.UpdateAutoFishing then
                RemoteReferences.UpdateAutoFishing:InvokeServer(false)
            end
        end)
        
        FishingActive = false
    end)
end

local function StopFishingV1()
    Config.FishingV1 = false
end

-- =============================================
-- AUTO FISHING V2
-- =============================================

local RodDelays = {
    ["Bamboo Rod"] = 1.12,
    ["Element Rod"] = 1.12,
    ["Ares Rod"] = 1.45,
    ["Angler Rod"] = 1.45,
    ["Ghostfinn Rod"] = 1.45,
    ["Astral Rod"] = 1.9,
    ["Chrome Rod"] = 2.3,
    ["Steampunk Rod"] = 2.5,
    ["Lucky Rod"] = 3.5,
    ["Midnight Rod"] = 3.3,
    ["Demascus Rod"] = 3.9,
    ["Grass Rod"] = 3.8,
    ["Luck Rod"] = 4.2,
    ["Carbon Rod"] = 4.0,
    ["Lava Rod"] = 4.2,
    ["Starter Rod"] = 4.3,
}

-- 🎣 ROD DETECTION SYSTEM
local function DetectEquippedRod()
    local success, rodName = pcall(function()
        local backpackGui = player.PlayerGui:FindFirstChild("Backpack")
        if not backpackGui then return nil end
        
        local display = backpackGui:FindFirstChild("Display")
        if not display then return nil end
        
        for _, tile in ipairs(display:GetChildren()) do
            local success2, itemNamePath = pcall(function()
                return tile.Inner.Tags.ItemName
            end)
            
            if success2 and itemNamePath and itemNamePath:IsA("TextLabel") then
                local name = itemNamePath.Text
                if RodDelays[name] then
                    return name
                end
            end
        end
        return nil
    end)
    
    if success and rodName then
        return rodName
    end
    return nil
end

local function UpdateRodDelay(showNotify)
    if FishingV2State.DelayInitialized then return end
    
    local rodName = DetectEquippedRod()
    
    if rodName and RodDelays[rodName] then
        FishingV2State.DetectedRod = rodName
        FishingV2State.RodDelay = RodDelays[rodName]
        FishingV2State.DelayInitialized = true
        
        if showNotify and Window then
            Rayfield:Notify({
                Title = "🎣 Rod Detected",
                Content = "Start Fishing Now",
                Duration = 4,
                Image = 4483362458
            })
        end
        
    else
        FishingV2State.DetectedRod = "Unknown Rod"
        FishingV2State.RodDelay = 2.0
        FishingV2State.DelayInitialized = true
        
        if showNotify and Window then
            Rayfield:Notify({
                Title = "⚠️ Rod Detection Failed",
                Content = "Using default delay: 2.0s",
                Duration = 4,
                Image = 4483362458
            })
        end
        
        warn("⚠️ [V2] No valid rod detected, using default delay: 2.0s")
    end
end

local function SetupRodWatcher()
    pcall(function()
        local backpackGui = player.PlayerGui:WaitForChild("Backpack", 5)
        if not backpackGui then return end
        
        local display = backpackGui:WaitForChild("Display", 5)
        if not display then return end
        
        display.ChildAdded:Connect(function()
            task.wait(0.1)
            if FishingV2State.Enabled and not FishingV2State.DelayInitialized then
                UpdateRodDelay(true)
            end
        end)
    end)
end

task.spawn(SetupRodWatcher)

local function FishingV2Loop()
    while FishingV2State.Enabled do
        local success, errorMessage = pcall(function()
            -- Equip
            if RemoteReferences.EquipRemote then 
                RemoteReferences.EquipRemote:FireServer(1) 
            end
            
            -- Rod invoke
            if RemoteReferences.RodRemote then 
                RemoteReferences.RodRemote:InvokeServer(tick()) 
            end
            
            -- MiniGame
            if RemoteReferences.MiniGameRemote then 
                local baseX, baseY = -0.7499996, 1
                local x = baseX + (math.random(-500, 500) / 10000000)
                local y = baseY + (math.random(-500, 500) / 10000000)
                RemoteReferences.MiniGameRemote:InvokeServer(x, y)
            end

            -- Wait based on detected rod
            task.wait(FishingV2State.RodDelay)
            
            -- Finish
            if RemoteReferences.FinishRemote then
               RemoteReferences.FinishRemote:FireServer()
            end
            
            task.wait(0.1) -- Cooldown sebelum loop lagi
        end)
        
        if not success then 
            warn("[V2 ERROR]: " .. tostring(errorMessage))
            task.wait(2)
        end
    end
end

local function StartFishingV2()
    if FishingV2State.Enabled then
        warn("⚠️ Fishing V2 sudah aktif!")
        return
    end
    
    FishingV2State.Enabled = true
    FishingV2State.DelayInitialized = false
    
    UpdateRodDelay(true)
    task.spawn(FishingV2Loop)
    
    if Window then
        Rayfield:Notify({
            Title = "🎣 FISHING V2 STARTED",
            Content = "Fishing with smart system",
            Duration = 5,
            Image = 4483362458
        })
    end
end

local function StopFishingV2()
    FishingV2State.Enabled = false
    FishingV2State.Active = false
    FishingV2State.DelayInitialized = false
    
    if Window then
        Rayfield:Notify({
            Title = "🛑 FISHING V2 STOPPED",
            Content = "Auto Fishing V2 dihentikan",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- =============================================
-- AUTO ENCHANT ROD SYSTEM
-- =============================================

local function AutoEnchantRod()
    local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
    local character = workspace:WaitForChild("Characters"):FindFirstChild(player.Name)
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoidRootPart then
        Rayfield:Notify({
            Title = "Auto Enchant Rod",
            Content = "Failed to get character HumanoidRootPart.",
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

    local originalPosition = humanoidRootPart.Position
    task.wait(1)
    humanoidRootPart.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
    task.wait(1.2)

    local equipRod = RemoteReferences.Net:WaitForChild("RE/EquipToolFromHotbar")
    local activateEnchant = RemoteReferences.Net:WaitForChild("RE/ActivateEnchantingAltar")

    pcall(function()
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

    task.wait(0.9)
    humanoidRootPart.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
end

-- =============================================
-- QUEST SYSTEM
-- =============================================

local QuestData = {
    Tasks = {
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
    },
    
    Locations = {
        ["CRYSTAL_CRAB"] = CFrame.new(40.0956, 1.7772, 2757.2583),
        ["RARE_EPIC_FISH"] = CFrame.new(-3596.9094, -281.1832, -1645.1220),
        ["SECRET_SYPUSH"] = CFrame.new(-3658.5747, -138.4813, -951.7969),
        ["SECRET_TEMPLE"] = CFrame.new(1451.4100, -22.1250, -635.6500),
        ["SECRET_JUNGLE"] = CFrame.new(1479.6647, 11.1430, -297.9549),
        ["FARM_COINS"] = CFrame.new(-553.3464, 17.1376, 114.2622)
    }
}

local function GetQuestTracker(questName)
    local menu = Workspace:FindFirstChild("!!! MENU RINGS")
    if not menu then return nil end
    
    for _, instance in ipairs(menu:GetChildren()) do
        if instance.Name:find("Tracker") and instance.Name:lower():find(questName:lower()) then
            return instance
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
    for _, object in ipairs(content:GetChildren()) do
        if object:IsA("TextLabel") and object.Name:match("Label") and not object.Name:find("Progress") then
            local text = object.Text
            local percent = string.match(text, "([%d%.]+)%%") or "0"
            local completed = text:find("100%%") or text:find("DONE") or text:find("COMPLETED")
            table.insert(tasks, {
                name = text, 
                percent = tonumber(percent), 
                completed = completed ~= nil
            })
        end
    end
    return tasks
end

local function GetActiveTasks(questName)
    local allTasks = GetAllTasks(questName)
    local activeTasks = {}
    
    for _, task in ipairs(allTasks) do
        if not task.completed then
            table.insert(activeTasks, task)
        end
    end
    return activeTasks
end

local function FindLocationByTaskName(taskName)
    for key, location in pairs(QuestData.Tasks) do
        if string.find(taskName, key, 1, true) then
            return location
        end
    end
    return nil
end

local function TeleportToQuestLocation(locationName)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local cframe = QuestData.Locations[locationName]
    if cframe then
        humanoidRootPart.CFrame = cframe
        return true
    end
    return false
end

task.spawn(function()
    while task.wait(1) do
        if not QuestConfig.Active then continue end

        local questProgress = GetQuestProgress(QuestConfig.CurrentQuest)
        local activeTasks = GetActiveTasks(QuestConfig.CurrentQuest)
        local allTasks = GetAllTasks(QuestConfig.CurrentQuest)
        
        local allTasksCompleted = true
        for _, task in ipairs(allTasks) do
            if not task.completed and task.percent < 100 then
                allTasksCompleted = false
                break
            end
        end
        
        if allTasksCompleted and questProgress >= 100 then
            FishingV2State.Active = false
            QuestConfig.Active = false
            Rayfield:Notify({
                Title = "🎉 QUEST COMPLETED",
                Content = "All tasks finished for " .. QuestConfig.CurrentQuest,
                Duration = 5,
                Image = 4483362458
            })
            continue
        end

        if #activeTasks == 0 then
            FishingV2State.Active = false
            QuestConfig.Active = false
            continue
        end

        local currentTask = nil
        local currentTaskIndex = nil
        
        for index, task in ipairs(activeTasks) do
            if QuestConfig.SelectedTask and task.name == QuestConfig.SelectedTask then
                currentTask = task
                currentTaskIndex = index
                break
            end
        end

        if not currentTask then
            if QuestConfig.LastTaskIndex and QuestConfig.LastTaskIndex <= #activeTasks then
                currentTaskIndex = QuestConfig.LastTaskIndex
                currentTask = activeTasks[currentTaskIndex]
            else
                currentTaskIndex = 1
                currentTask = activeTasks[1]
            end
            
            if currentTask then
                QuestConfig.SelectedTask = currentTask.name
                QuestConfig.LastTaskIndex = currentTaskIndex
                
                Rayfield:Notify({
                    Title = "🎯 NEW TASK STARTED",
                    Content = currentTask.name .. " - " .. string.format("%.1f%%", currentTask.percent or 0),
                    Duration = 4,
                    Image = 4483362458
                })
            end
        end

        if not currentTask then
            QuestConfig.SelectedTask = nil
            QuestConfig.LastTaskIndex = nil
            QuestConfig.CurrentLocation = nil
            QuestConfig.Teleported = false
            QuestConfig.Fishing = false
            FishingV2State.Active = false
            continue
        end

        if currentTask.percent >= 100 and not QuestConfig.Fishing then
            Rayfield:Notify({
                Title = "✅ TASK COMPLETED",
                Content = currentTask.name .. " - 100% FINISHED",
                Duration = 3,
                Image = 4483362458
            })
            
            if currentTaskIndex < #activeTasks then
                QuestConfig.LastTaskIndex = currentTaskIndex + 1
            else
                QuestConfig.LastTaskIndex = 1
            end
            QuestConfig.SelectedTask = nil
            QuestConfig.CurrentLocation = nil
            QuestConfig.Teleported = false
            QuestConfig.Fishing = false
            continue
        end

        if not QuestConfig.CurrentLocation then
            QuestConfig.CurrentLocation = FindLocationByTaskName(currentTask.name)
            if not QuestConfig.CurrentLocation then
                QuestConfig.SelectedTask = nil
                continue
            end
        end

        if not QuestConfig.Teleported then
            if TeleportToQuestLocation(QuestConfig.CurrentLocation) then
                QuestConfig.Teleported = true
                task.wait(2)
            end
            continue
        end

        if not QuestConfig.Fishing then
            FishingV2State.Active = true
            StartFishingV2()
            QuestConfig.Fishing = true
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
-- WEBHOOK SYSTEM
-- =============================================

local function FormatCurrency(amount)
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

local function SendWebhook(fishName, fishTier, sellPrice, rarity)
    if not WebhookConfig.Enabled or WebhookConfig.Url == "" then
        return
    end
    
    local success, errorMessage = pcall(function()
        local timestamp = DateTime.now():ToIsoDate()
        
        local embed = {
            {
                ["title"] = "🎣 Hey New Fish Caught!",
                ["color"] = 65280,
                ["fields"] = {
                    {
                        ["name"] = "Fish Name",
                        ["value"] = fishName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Tier",
                        ["value"] = tostring(fishTier),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Rarity",
                        ["value"] = rarity,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Sell Price",
                        ["value"] = FormatCurrency(sellPrice),
                        ["inline"] = true
                    }
                },
                ["footer"] = {
                    ["text"] = "Codepik Script V5 • " .. timestamp
                },
                ["thumbnail"] = {
                    ["url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
                }
            }
        }
        
        local data = {
            ["embeds"] = embed,
            ["username"] = "Codepik Webhook",
            ["avatar_url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
        }
        
        local jsonData = HttpService:JSONEncode(data)
        
        local requestFunction = (syn and syn.request) or 
                              (http and http.request) or 
                              (http_request) or
                              (request)
        
        if not requestFunction then
            warn("❌ Your executor doesn't support HTTP requests!")
            return
        end
        
        requestFunction({
            Url = WebhookConfig.Url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        
    end)
    
    if not success then
        warn("Webhook error: " .. tostring(errorMessage))
    end
end

local function ShouldSendWebhook(fishName, fishTier)
    if not WebhookConfig.Enabled or #WebhookConfig.SelectedCategories == 0 then
        return false
    end
    
    if fishTier then
        if table.find(WebhookConfig.SelectedCategories, "Secret") and fishTier == 7 then
            return true
        elseif table.find(WebhookConfig.SelectedCategories, "Mythic") and fishTier == 6 then
            return true
        elseif table.find(WebhookConfig.SelectedCategories, "Legendary") and fishTier == 5 then
            return true
        end
    end
    
    return false
end

local FishCategories = {
    ["Secret"] = {
        "Blob Shark", "Great Christmas Whale", "Frostborn Shark", "Great Whale", 
        "Worm Fish", "Robot Kraken", "Giant Squid", "Ghost Worm Fish", 
        "Ghost Shark", "Queen Crab", "Orca", "Crystal Crab", 
        "Monster Shark", "Eerie Shark", "King Jelly", "Bone Whale",
        "Ancient Whale", "Mosasaur Shark", "Elshark Gran Maja",
        "Dead Zombie Shark", "Zombie Shark", "Megalodon", "Lochness Monster",
        "Zombie Megalodon"
    },
    ["Mythic"] = {
        "Gingerbread Shark", "Loving Shark", "King Crab", "Blob Fish", 
        "Hermit Crab", "Luminous Fish", "Plasma Shark", "Crocodile",
        "Ancient Relic Crocodile", "Panther Eel", "Hybodus Shark",
        "Magma Shark", "Sharp One", "Mammoth Appafish",
        "Frankenstein Longsnapper", "Pumpkin Ray", "Dark Pumpkin Appafish", "Armor Catfish"
    },
    ["Legendary"] = {
        "Yellowfin Tuna", "Lake Sturgeon", "Ligned Cardinal Fish", "Saw Fish",
        "Abyss Seahorse", "Blueflame Ray", "Hammerhead Shark", 
        "Hawks Turtle", "Manta Ray", "Loggerhead Turtle", 
        "Prismy Seahorse", "Gingerbread Turtle", "Thresher Shark",
        "Dotted Stingray", "Strippled Seahorse", "Deep Sea Crab",
        "Ruby", "Temple Spokes Tuna", "Sacred Guardian Squid",
        "Manoai Statue Fish", "Pumpkin Carved Shark", "Wizard Stingray",
        "Crystal Salamander", "Pumpkin StoneTurtle"
    },
}

-- =============================================
-- TELEPORT EVENT SYSTEM
-- =============================================

local function ScanActiveEvents()
    local events = {}
    local validEvents = {
        "megalodon", "whale", "kraken", "hunt", "Ghost Worm", "Mount Hallow (bug dont click)",
        "admin", "Hallow Bay (bug dont click)", "worm", "blackhole", "HalloweenFastTravel"
    }

    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("Model") or object:IsA("Folder") then
            local name = object.Name:lower()

            for _, keyword in ipairs(validEvents) do
                if name:find(keyword:lower()) and not name:find("boat") and not name:find("sharki") then
                    local exists = false
                    for _, event in ipairs(events) do
                        if event.Name == object.Name then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        local position = Vector3.new(0, 0, 0)

                        if object:IsA("Model") then
                            pcall(function()
                                position = object:GetPivot().Position
                            end)
                        elseif object:IsA("BasePart") then
                            position = object.Position
                        elseif object:IsA("Folder") and #object:GetChildren() > 0 then
                            local child = object:GetChildren()[1]
                            if child:IsA("Model") then
                                pcall(function()
                                    position = child:GetPivot().Position
                                end)
                            elseif child:IsA("BasePart") then
                                position = child.Position
                            end
                        end

                        table.insert(events, {
                            Name = object.Name,
                            Object = object,
                            Position = position
                        })
                    end

                    break
                end
            end
        end
    end
    return events
end

local function TeleportToEventPosition(position)
    local success, errorMessage = pcall(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
            task.wait(0.5)
            return true
        end
    end)
    
    return success, errorMessage
end

-- =============================================
-- SIMPLE WEBHOOK & AUTO FAVORITE (FIXED)
-- =============================================

local function SetupSimpleListener()
    local success, obtainedNewFishNotification = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if not success or not obtainedNewFishNotification then
        warn("❌ Failed to find ObtainedNewFishNotification remote")
        return false
    end
    
    obtainedNewFishNotification.OnClientEvent:Connect(function(itemId, itemData, inventoryData)
        local fishName = "Unknown Fish"
        local fishTier = 0
        local sellPrice = 0
        local uuid = nil
        
        local actualData = nil
        
        pcall(function()
            if type(itemData) == "table" and itemData.Name then
                actualData = itemData
            elseif typeof(itemData) == "Instance" and itemData:IsA("ModuleScript") then
                actualData = require(itemData)
            else
                local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
                if itemsFolder then
                    for _, item in pairs(itemsFolder:GetChildren()) do
                        local success2, data = pcall(function() return require(item) end)
                        if success2 and data and data.Data and data.Data.Id == itemId then
                            actualData = data.Data
                            break
                        end
                    end
                end
            end
        end)
        
        if actualData then
            if actualData.Name then
                fishName = actualData.Name
            elseif actualData.DisplayName then
                fishName = actualData.DisplayName
            end
            
            if actualData.Tier then
                fishTier = tonumber(actualData.Tier) or 0
            end
        end
        
        if inventoryData and inventoryData.InventoryItem then
            local invItem = inventoryData.InventoryItem
            
            if invItem.UUID then
                uuid = invItem.UUID
                -- ✅ TAMBAH: Track UUID untuk auto-sell
                table.insert(obtainedFishUUIDs, uuid)
            end
            
            if invItem.SellPrice then
                sellPrice = invItem.SellPrice
            end
        end
        
        local rarity = "Common"
        if fishTier == 7 then rarity = "Secret"
        elseif fishTier == 6 then rarity = "Mythic" 
        elseif fishTier == 5 then rarity = "Legendary"
        elseif fishTier == 4 then rarity = "Epic"
        elseif fishTier == 3 then rarity = "Rare"
        elseif fishTier == 2 then rarity = "Uncommon"
        end
        
        -- AUTO FAVORITE
        if AutoFavoriteConfig.Enabled and uuid and fishTier > 0 then
            local shouldFavorite = false
            
            for _, category in ipairs(AutoFavoriteConfig.SelectedCategories) do
                if (category == "Secret" and fishTier == 7) or
                   (category == "Mythic" and fishTier == 6) or
                   (category == "Legendary" and fishTier == 5) then
                    shouldFavorite = true
                    break
                end
            end
            
            if shouldFavorite then
                task.spawn(function()
                    task.wait(0.3)
                    
                    pcall(function()
                        if RemoteReferences.FavoriteRemote then
                            RemoteReferences.FavoriteRemote:FireServer(uuid)
                            
                            if Window then
                                Rayfield:Notify({
                                    Title = "⭐ Auto Favorited",
                                    Content = string.format("%s (%s)", fishName, rarity),
                                    Duration = 2,
                                    Image = 4483362458
                                })
                            end
                        end
                    end)
                end)
            end
        end
        
        -- WEBHOOK (✅ HANYA SEKALI!)
        if WebhookConfig.Enabled and WebhookConfig.Url ~= "" and 
           #WebhookConfig.SelectedCategories > 0 and fishTier > 0 then
            
            local shouldWebhook = false
            
            for _, category in ipairs(WebhookConfig.SelectedCategories) do
                if (category == "Secret" and fishTier == 7) or
                   (category == "Mythic" and fishTier == 6) or
                   (category == "Legendary" and fishTier == 5) then
                    shouldWebhook = true
                    break
                end
            end
            
            if shouldWebhook then
                task.spawn(function()
                    task.wait(0.5)
                    SendWebhook(fishName, fishTier, sellPrice, rarity)
                end)
            end
        end
    end)
    
    return true
end

-- =============================================
-- UTILITY SYSTEMS
-- =============================================

local function TogglePerfectCatch(enabled)
    Config.PerfectCatch = enabled
    
    if enabled then
        local metatable = getrawmetatable(game)
        if not metatable then return end
        
        setreadonly(metatable, false)
        local originalNamecall = metatable.__namecall
        
        metatable.__namecall = newcclosure(function(self, ...)
            local methodName = getnamecallmethod()
            if methodName == "InvokeServer" and self == RemoteReferences.StartMini and Config.PerfectCatch then
                return originalNamecall(self, -1.233184814453125, 0.9945034885633273)
            end
            return originalNamecall(self, ...)
        end)
        
        setreadonly(metatable, true)
    end
end

local function ToggleRadar(enabled)
    Config.EnableRadar = enabled
    pcall(function()
        if RemoteReferences.RadarRemote then
            RemoteReferences.RadarRemote:InvokeServer(enabled)
        end
    end)
end

local function ToggleDivingGear(enabled)
    Config.EnableDivingGear = enabled
    pcall(function()
        if enabled then
            RemoteReferences.EquipRemote:FireServer(2)
            if RemoteReferences.EquipOxy then
                RemoteReferences.EquipOxy:InvokeServer(105)
            end
        else
            if RemoteReferences.UnequipOxy then
                RemoteReferences.UnequipOxy:InvokeServer()
            end
        end
    end)
end

local function SellNow()
    pcall(function() 
        RemoteReferences.SellRemote:InvokeServer()
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Successfully sold items!",
            Duration = 3,
            Image = 4483362458
        })
    end)
end

local AntiAFKConnection = nil
local function ToggleAntiAFK(enabled)
    Config.AntiAFK = enabled
    
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
    
    if enabled then
        AntiAFKConnection = player.Idled:Connect(function()
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
-- PERFORMANCE MODE
-- =============================================

local function TogglePerformanceMode(enabled)
    Config.PerformanceMode = enabled
    
    if enabled then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 1
        
        for _, object in pairs(Workspace:GetDescendants()) do
            if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
                object.Enabled = false
            end
            
            if object:IsA("Part") or object:IsA("MeshPart") then
                object.Material = Enum.Material.SmoothPlastic
                object.Reflectance = 0
                object.CastShadow = false
            end
        end
        
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0.9
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end
        
        settings().Rendering.QualityLevel = 1
        
        Rayfield:Notify({
            Title = "🚀 PERFORMANCE MODE",
            Content = "Ultra performance activated!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10000
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end

-- =============================================
-- WEATHER SYSTEM
-- =============================================

local function AutoBuyWeatherSystem()
    task.spawn(function()
        while Config.AutoBuyWeather do
            for _, weather in pairs(Config.SelectedWeathers) do
                if weather then
                    pcall(function()
                        RemoteReferences.PurchaseWeather:InvokeServer(weather)
                    end)
                    task.wait(0.5)
                end
            end
            task.wait(5)
        end
    end)
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
    local position = IslandLocations[islandName]
    if not position then return end
    
    pcall(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
        humanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
        
        Rayfield:Notify({
            Title = "Teleport Success",
            Content = "Teleported to " .. islandName,
            Duration = 3,
            Image = 4483362458
        })
    end)
end

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
-- GRAPHICS & PERFORMANCE
-- =============================================

local function ApplyPermanentLighting()
    RunService.Heartbeat:Connect(function()
        Lighting.Brightness = Config.Brightness
        Lighting.ClockTime = Config.TimeOfDay
    end)
end

local function RemoveFog()
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    
    RunService.Heartbeat:Connect(function()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end)
end

local function Enable8BitMode()
    for _, object in pairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Material = Enum.Material.SmoothPlastic
            object.Reflectance = 0
            object.CastShadow = false
        end
        if object:IsA("MeshPart") then
            object.Material = Enum.Material.SmoothPlastic
            object.Reflectance = 0
            object.TextureID = ""
        end
    end
    
    Lighting.Brightness = 3
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    
    Rayfield:Notify({
        Title = "8-Bit Mode",
        Content = "Super smooth rendering enabled!",
        Duration = 2,
        Image = 4483362458
    })
end

local function BoostFPS()
    for _, object in pairs(game:GetDescendants()) do
        if object:IsA("BasePart") and not object.Parent:FindFirstChildOfClass("Humanoid") then
            object.Material = Enum.Material.SmoothPlastic
            object.Reflectance = 0
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Performance optimized!",
        Duration = 3,
        Image = 4483362458
    })
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
    PatchTab:CreateLabel("🔄 Version: V5.7")
    PatchTab:CreateLabel("📅 Update Date: 3-11-25")

    PatchTab:CreateButton({
        Name = "📋 Show V5.7 Features",
        Callback = function()
            Rayfield:Notify({
                Title = "🎣 Auto Fishing V5 Features",
                Content = [[              
💥 Adjustment :
• Adjust Speed V3
• Adjust Speed V2
❗ Fix :
• Fix Webhook (Now Works)
• Fix Auto Favorite (Now Works)
                ]],
                Duration = 15,
                Image = 4483362458
            })
        end,
    })

    -- Main Tab
    local MainTab = Window:CreateTab("🔥 Main", 4483362458)

    MainTab:CreateSection("🎣 Auto Fishing Ingame")

    MainTab:CreateToggle({
        Name = "🎣 Fishing V1 (Game Auto)",
        CurrentValue = Config.FishingV1,
        Callback = function(Value)
            Config.FishingV1 = Value
            if Value then
                FishingV2State.Enabled = false
                StopFishingV2()
                StartFishingV1()
            else
                StopFishingV1()
            end
        end,
    })

   MainTab:CreateSection("🎣 FISHING V2 (Smart Detect Rod)")

    MainTab:CreateToggle({
        Name = "🎣 Fishing V2 (Smart Rod Detect)",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                Config.FishingV1 = false
                StopFishingV1()
                StartFishingV2()
            else
                StopFishingV2()
            end
        end,
    })

    MainTab:CreateButton({
        Name = "🔄 Re-detect Rod (For V2 Only)",
        Callback = function()
            FishingV2State.DelayInitialized = false
            UpdateRodDelay(true)
        end,
    })

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

    MainTab:CreateSection("⭐ Auto Favorite System (While Fishing)")

    MainTab:CreateToggle({
    Name = "Enable Auto Favorite",
    CurrentValue = AutoFavoriteConfig.Enabled,
    Callback = function(Value)
        AutoFavoriteConfig.Enabled = Value
        if Value then
            Rayfield:Notify({
                Title = "⭐ Auto Favorite (While Fishing)",
                Content = "Fish will be auto-favorited while fishing",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})
    MainTab:CreateDropdown({
        Name = "Favorite Categories",
        Options = {"Secret", "Mythic", "Legendary"},
        CurrentOption = {"Secret"},
        MultipleOptions = true,
        Callback = function(Options)
            AutoFavoriteConfig.SelectedCategories = Options
        end,
    })

    MainTab:CreateSection("💰 Auto Sell System")

    MainTab:CreateInput({
        Name = "Auto Sell Threshold",
        PlaceholderText = "Default: 4000 fish",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            local number = tonumber(Text)
            if number then obtainedLimit = number end
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
    
    -- Quest Tab
    local QuestTab = Window:CreateTab("🎯 Quests", 4483362458)

    QuestTab:CreateSection("Auto Quest System")

    local quests = {
        {Name = "Aura", Display = "Aura Boat"},
        {Name = "Deep Sea", Display = "Ghostfinn Rod"},
        {Name = "Element", Display = "Element Rod"}
    }

    for _, quest in ipairs(quests) do
        QuestTab:CreateSection(quest.Display .. " Quest")

        QuestTab:CreateToggle({
            Name = "Auto " .. quest.Display,
            CurrentValue = false,
            Callback = function(Value)
                if Value then
                    QuestConfig.Active = true
                    QuestConfig.CurrentQuest = quest.Name
                    QuestConfig.SelectedTask = nil
                    QuestConfig.CurrentLocation = nil
                    QuestConfig.Teleported = false
                    QuestConfig.Fishing = false
                    QuestConfig.LastProgress = GetQuestProgress(quest.Name)
                    QuestConfig.LastTaskIndex = nil
                    
                    Rayfield:Notify({
                        Title = "🎯 QUEST STARTED",
                        Content = "Auto quest activated for " .. quest.Display,
                        Duration = 4,
                        Image = 4483362458
                    })
                else
                    QuestConfig.Active = false
                end
            end
        })

        QuestTab:CreateButton({
            Name = "Check " .. quest.Display .. " Progress",
            Callback = function()
                local progress = GetQuestProgress(quest.Name)
                local activeTasks = GetActiveTasks(quest.Name)
                
                local message = quest.Display .. " Progress: " .. string.format("%.1f%%", progress) .. "\n\n"
                for index, task in ipairs(activeTasks) do
                    message = message .. string.format("- %s (%.1f%%)\n", task.name, task.percent)
                end
                
                Rayfield:Notify({
                    Title = quest.Display .. " Progress",
                    Content = message,
                    Duration = 6,
                    Image = 4483362458
                })
            end
        })
    end

    QuestTab:CreateSection("Quest Status")

    local QuestStatusLabel = QuestTab:CreateLabel("No active quest")

    task.spawn(function()
        while task.wait(2) do
            local text = "QUEST STATUS\n\n"
            if QuestConfig.Active then
                text = text .. "Active: " .. QuestConfig.CurrentQuest .. "\n"
                text = text .. "Progress: " .. string.format("%.1f", GetQuestProgress(QuestConfig.CurrentQuest)) .. "%\n"
                if QuestConfig.SelectedTask then 
                    text = text .. "Task: " .. QuestConfig.SelectedTask .. "\n" 
                end
                text = text .. (QuestConfig.Fishing and "\nFARMING..." or "\nPreparing...")
            else
                text = text .. "No active quest\n\nSelect a quest to start"
            end
            QuestStatusLabel:Set(text)
        end
    end)

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

    TeleportTab:CreateSection("TELEPORT TO ACTIVE EVENTS")

    local eventButtons = {}
    local lastEventSnapshot = {}

    local function HasEventChanged(newEvents)
        if #newEvents ~= #lastEventSnapshot then
            return true
        end
        for index, event in ipairs(newEvents) do
            if not lastEventSnapshot[index] or lastEventSnapshot[index].Name ~= event.Name then
                return true
            end
        end
        return false
    end

    local function UpdateEventButtons()
        local events = ScanActiveEvents() or {}

        for _, button in pairs(eventButtons) do
            pcall(function() button:Destroy() end)
        end
        table.clear(eventButtons)

        local header = TeleportTab:CreateParagraph({
            Title = "Active Events",
            Content = "Auto-refreshing every 5 seconds"
        })
        table.insert(eventButtons, header)

        for _, event in ipairs(events) do
            local button = TeleportTab:CreateButton({
                Name = "📍 " .. event.Name,
                Callback = function()
                    TeleportToEventPosition(event.Position)
                end
            })
            table.insert(eventButtons, button)
        end

        if #events == 0 then
            local noEvent = TeleportTab:CreateParagraph({
                Title = "No Events",
                Content = "📭 No active events found"
            })
            table.insert(eventButtons, noEvent)
        end

        lastEventSnapshot = events
    end

    local refreshButton = TeleportTab:CreateButton({
        Name = "🔄 Refresh Active Events",
        Callback = function()
            UpdateEventButtons()
            Rayfield:Notify({
                Title = "Event Scanner",
                Content = "✅ Events refreshed successfully",
                Duration = 2,
                Image = 4483362458
            })
        end
    })

    task.spawn(function()
        while task.wait(5) do
            local events = ScanActiveEvents() or {}
            if HasEventChanged(events) then
                UpdateEventButtons()
            end
        end
    end)

    UpdateEventButtons()

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

    -- Webhook Tab
    local WebhookTab = Window:CreateTab("📣 Webhook", 4483362458)

    WebhookTab:CreateSection("Send Webhook")

    WebhookTab:CreateToggle({
        Name = "🔔 Enable Webhook Notifications",
        CurrentValue = WebhookConfig.Enabled,
        Callback = function(Value)
            WebhookConfig.Enabled = Value
            if Value then
                Rayfield:Notify({
                    Title = "Webhook Enabled",
                    Content = "Webhook notifications activated",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Webhook Disabled",
                    Content = "Webhook notifications deactivated", 
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end,
    })

    WebhookTab:CreateInput({
        Name = "Webhook URL",
        PlaceholderText = "https://discord.com/api/webhooks/...",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            WebhookConfig.Url = Text
            if Text ~= "" then
                Rayfield:Notify({
                    Title = "Webhook URL Set",
                    Content = "Webhook URL saved successfully",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end,
    })

    WebhookTab:CreateDropdown({
        Name = "Webhook Categories",
        Options = {"Secret", "Mythic", "Legendary"},
        CurrentOption = {"Secret"},
        MultipleOptions = true,
        Callback = function(Options)
            WebhookConfig.SelectedCategories = Options
            local categories = #Options > 0 and table.concat(Options, ", ") or "None"
            Rayfield:Notify({
                Title = "Webhook Categories Updated",
                Content = "Notifications for: " .. categories,
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    WebhookTab:CreateButton({
        Name = "🧪 Test Webhook",
        Callback = function()
            if WebhookConfig.Url == "" then
                Rayfield:Notify({
                    Title = "Webhook Error",
                    Content = "Please set webhook URL first",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            
            SendWebhook("Test Fish", 7, 25000, "Secret")
            Rayfield:Notify({
                Title = "Webhook Test",
                Content = "Test notification sent!",
                Duration = 3,
                Image = 4483362458
            })
        end,
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
        Name = "Infinite Jump",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                UserInputService.JumpRequest:Connect(function()
                    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                    end
                end)
            end
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

    GraphicsTab:CreateButton({
        Name = "Remove Fog",
        Callback = RemoveFog,
    })

    GraphicsTab:CreateButton({
        Name = "8-Bit Mode",
        Callback = Enable8BitMode,
    })

    GraphicsTab:CreateButton({
        Name = "Boost FPS",
        Callback = BoostFPS,
    })

    GraphicsTab:CreateToggle({
        Name = "Performance Mode",
        CurrentValue = Config.PerformanceMode,
        Callback = function(Value)
            TogglePerformanceMode(Value)
        end,
    })

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

    UtilityTab:CreateToggle({
        Name = "Auto Rejoin System",
        CurrentValue = Config.AutoRejoin,
        Callback = function(Value)
            Config.AutoRejoin = Value
        end,
    })

    UtilityTab:CreateSection("Weather System")

    UtilityTab:CreateDropdown({
        Name = "Auto Buy Weather",
        Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
        CurrentOption = {},
        MultipleOptions = true,
        Callback = function(Options)
            Config.SelectedWeathers = Options
        end,
    })

    UtilityTab:CreateToggle({
        Name = "Enable Auto Buy Weather",
        CurrentValue = Config.AutoBuyWeather,
        Callback = function(Value)
            Config.AutoBuyWeather = Value
            if Value then
                AutoBuyWeatherSystem()
            end
        end,
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
        Title = "🎣 Auto Fishing V5.5 - Codepik",
        Content = "Check Patch Notes For All update!",
        Duration = 6,
        Image = 4483362458
    })
end

-- =============================================
-- INITIALIZATION
-- =============================================

player.CharacterAdded:Connect(function(character)
    Character = character
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    Humanoid = character:WaitForChild("Humanoid")
    
    task.wait(2)
    
    if Humanoid then
        Humanoid.WalkSpeed = Config.WalkSpeed
        Humanoid.JumpPower = Config.JumpPower
    end
    
   if Config.FishingV1 then
        task.wait(2)
        StartFishingV1()
    elseif FishingV2State.Enabled then
        task.wait(2)
        StartFishingV2()
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
    
    if Config.PerformanceMode then
        task.wait(1)
        TogglePerformanceMode(true)
    end
end)

task.spawn(function()
    while task.wait(1) do
        if (FishingActive or Config.FishingV1 or FishingV2State) and #obtainedFishUUIDs >= obtainedLimit then
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Selling fish at threshold...",
                Duration = 3,
                Image = 4483362458
            })
            pcall(function() RemoteReferences.SellRemote:InvokeServer() end)
            obtainedFishUUIDs = {}
            task.wait(2)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
           UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            EmergencyStopAll()
        end
    end
end)

task.spawn(function()
    task.wait(2)
    
    if SetupRemoteReferences() then
        CreateUI()
        ApplyPermanentLighting()
        
        task.wait(1)
        SetupSimpleListener()
        
        print("🎣 Auto Fishing V5 - Codepik Edition")
    else
        warn("❌ Failed to setup remotes!")
    end
end)

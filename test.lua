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
    -- Fishing Modes (Sederhana - V1 & V4 saja)
    FishingV1 = false,  -- Game Auto
    
    
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
-- FISHING SYSTEMS - SIMPLIFIED (V1 & V4 ONLY)
-- =============================================

-- Fishing V1 (Game Auto)
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

-- ===================================
-- ========== FISHING V5 SYSTEM ======
-- ========== FIXED VERSION ===========
-- ===================================

-- State Variables untuk V5
local autoFishingV5Enabled = false
local fishingV5Active = false

-- Deklarasi remotes yang diperlukan V5
local rodRemote, miniGameRemote, finishRemote

-- Setup V5 Remotes
local function SetupV5Remotes()
    local success = pcall(function()
        rodRemote = net:WaitForChild("RF/ChargeFishingRod")
        miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
        finishRemote = net:WaitForChild("RE/FishingCompleted")
    end)
    return success
end

-- Fungsi Auto Fishing V5 - FIXED
local function autoFishingV5Loop()
    while autoFishingV5Enabled do
        local ok, err = pcall(function()
            fishingV5Active = true
            
            -- PHASE 1: EQUIP fishing rod (slot 1)
            if equipRemote then
                equipRemote:FireServer(1)
            end

            -- PHASE 2: CHARGE fishing rod
            if rodRemote then
                local timestamp = tick()
                rodRemote:InvokeServer(timestamp)
            end

            -- PHASE 3: START Mini Game dengan nilai yang sama
            if miniGameRemote then
               miniGameRemote:InvokeServer(-1.233184814453125, 0.9945034885633273)
               task.wait(2) -- default 2
            end
            
            -- PHASE 4: FINISH Fishing
            if finishRemote then
                finishRemote:FireServer(true)
            end
        end)
        
        if not ok then
            warn("[V5 ERROR]: " .. tostring(err))
        end
        
        task.wait(0.08)
    end
    fishingV5Active = false
end

-- Start Fishing V5
local function StartFishingV5()
    if autoFishingV5Enabled then
        warn("⚠️ Fishing V5 sudah aktif!")
        return
    end
    
    -- Setup remotes dulu
    if not SetupV5Remotes() then
        Rayfield:Notify({
            Title = "❌ V5 Error",
            Content = "Failed to setup V5 remotes",
            Duration = 3,
            Image = 4483362458
        })
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

-- Stop Fishing V5
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

    local equipRod = net:WaitForChild("RE/EquipToolFromHotbar")
    local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")

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
    hrp.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
end

-- =============================================
-- AUTO QUEST SYSTEM
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
        if inst.Name:find("Tracker") and inst.Name:lower():find(questName:lower()) then
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
    while task.wait(1) do
        if not QuestState.Active then continue end

        local questProgress = GetQuestProgress(QuestState.CurrentQuest)
        local activeTasks = GetActiveTasks(QuestState.CurrentQuest)
        local allTasks = GetAllTasks(QuestState.CurrentQuest)
        
        -- Check if all tasks completed
        local allTasksCompleted = true
        for _, task in ipairs(allTasks) do
            if not task.completed and task.percent < 100 then
                allTasksCompleted = false
                break
            end
        end
        
        if allTasksCompleted and questProgress >= 100 then
            -- Quest completed
            fishingV5Active = false
            QuestState.Active = false
            Rayfield:Notify({
                Title = "🎉 QUEST COMPLETED",
                Content = "All tasks finished for " .. QuestState.CurrentQuest,
                Duration = 5,
                Image = 4483362458
            })
            continue
        end

        if #activeTasks == 0 then
            -- No active tasks
            fishingV5Active = false
            QuestState.Active = false
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
            fishingV5Active = false
            continue
        end

        if currentTask.percent >= 100 and not QuestState.Fishing then
            -- Task completed
            Rayfield:Notify({
                Title = "✅ TASK COMPLETED",
                Content = currentTask.name .. " - 100% FINISHED",
                Duration = 3,
                Image = 4483362458
            })
            
            if currentTaskIndex < #activeTasks then
                QuestState.LastTaskIndex = currentTaskIndex + 1
            else
                QuestState.LastTaskIndex = 1
            end
            QuestState.SelectedTask = nil
            QuestState.CurrentLocation = nil
            QuestState.Teleported = false
            QuestState.Fishing = false
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
            fishingV5Active = true
            StartFishingV5()
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
-- WEBHOOK SYSTEM (NEW ADDITION)
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
    if not webhookEnabled or webhookUrl == "" then
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
                        ["value"] = formatCurrency(sellPrice),
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
        
        -- UNIVERSAL HTTP REQUEST - Works on multiple executors
        local requestFunc = (syn and syn.request) or 
                          (http and http.request) or 
                          (http_request) or
                          (request)
        
        if not requestFunc then
            warn("❌ Your executor doesn't support HTTP requests!")
            return
        end
        
        requestFunc({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        
        print("📢 Webhook sent: " .. fishName)
    end)
    
    if not success then
        warn("Webhook error: " .. tostring(err))
    end
end

local function shouldSendWebhook(fishName, fishTier)
    if not webhookEnabled or #SelectedWebhookCategories == 0 then
        return false
    end
    
    -- Filter berdasarkan tier
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

-- Fish Categories untuk Webhook
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
-- TELEPORT EVENT SYSTEM (NEW ADDITION)
-- =============================================

local function ScanActiveEvents()
    local events = {}
    local validEvents = {
        "megalodon", "whale", "kraken", "hunt", "Ghost Worm", "Mount Hallow (bug dont click)",
        "admin", "Hallow Bay (bug dont click)", "worm", "blackhole", "HalloweenFastTravel"
    }

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local name = obj.Name:lower()

            for _, keyword in ipairs(validEvents) do
                if name:find(keyword:lower()) and not name:find("boat") and not name:find("sharki") then
                    local exists = false
                    for _, e in ipairs(events) do
                        if e.Name == obj.Name then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        local pos = Vector3.new(0, 0, 0)

                        if obj:IsA("Model") then
                            pcall(function()
                                pos = obj:GetPivot().Position
                            end)
                        elseif obj:IsA("BasePart") then
                            pos = obj.Position
                        elseif obj:IsA("Folder") and #obj:GetChildren() > 0 then
                            local child = obj:GetChildren()[1]
                            if child:IsA("Model") then
                                pcall(function()
                                    pos = child:GetPivot().Position
                                end)
                            elseif child:IsA("BasePart") then
                                pos = child.Position
                            end
                        end

                        table.insert(events, {
                            Name = obj.Name,
                            Object = obj,
                            Position = pos
                        })
                    end

                    break
                end
            end
        end
    end
    return events
end

local function teleportToEventPosition(position)
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
            task.wait(0.5)
            return true
        end
    end)
    
    return success, err
end

-- =============================================
-- AUTO FAVORITE SYSTEM
-- =============================================

local function BuildFishDatabase()
    AutoFavorite.FishIdToName = {}
    AutoFavorite.FishNameToId = {}
    AutoFavorite.FishNames = {}
    
    local success = pcall(function()
        local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
        if not ItemsFolder then return false end
        
        for _, item in pairs(ItemsFolder:GetChildren()) do
            local ok, data = pcall(function() return require(item) end)
            if ok and data and data.Data and data.Data.Type == "Fishes" then
                local id = tostring(data.Data.Id)
                local name = tostring(data.Data.Name)
                local tier = tonumber(data.Data.Tier) or 1
                
                AutoFavorite.FishIdToName[id] = {
                    name = name,
                    tier = tier,
                    displayName = data.Data.DisplayName or name
                }
                
                AutoFavorite.FishNameToId[name] = id
                AutoFavorite.FishNameToId[string.lower(name)] = id
                table.insert(AutoFavorite.FishNames, name)
                
                if data.Data.DisplayName and data.Data.DisplayName ~= name then
                    AutoFavorite.FishNameToId[data.Data.DisplayName] = id
                    AutoFavorite.FishNameToId[string.lower(data.Data.DisplayName)] = id
                end
            end
        end
        return true
    end)
    
    if success then
        print(string.format("✅ Fish Database: %d fish loaded", #AutoFavorite.FishNames))
    else
        warn("❌ Failed to build fish database")
    end
    
    return success
end

local function ShouldFavoriteFish(fishName, fishTier)
    if not fishName or #AutoFavorite.SelectedCategories == 0 then
        return false
    end
    
    -- Tier-based filtering
    if fishTier then
        if table.find(AutoFavorite.SelectedCategories, "Secret") and fishTier == 7 then
            return true
        elseif table.find(AutoFavorite.SelectedCategories, "Mythic") and fishTier == 6 then
            return true
        elseif table.find(AutoFavorite.SelectedCategories, "Legendary") and fishTier == 5 then
            return true
        end
    end
    
    return false
end

local function FavoriteFishByUUID(uuid, fishName)
    if not uuid or not favoriteRemote then return false end
    
    local success = pcall(function()
        favoriteRemote:FireServer(uuid)
        return true
    end)
    
    if success then
        print(string.format("⭐ Favorited: %s", fishName))
        return true
    end
    
    return false
end

local function SetupAutoFavoriteListener()
    local success, REObtainedNewFishNotification = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
            if not AutoFavorite.Enabled then return end

            local uuid = data.InventoryItem and data.InventoryItem.UUID
            if not uuid then return end

            local fishInfo = AutoFavorite.FishIdToName[tostring(itemId)]
            if not fishInfo then return end
            
            if ShouldFavoriteFish(fishInfo.name, fishInfo.tier) then
                task.wait(0.2)
                if FavoriteFishByUUID(uuid, fishInfo.name) then
                    Rayfield:Notify({
                        Title = "⭐ Auto Favorite",
                        Content = string.format("%s (Tier %d)", fishInfo.name, fishInfo.tier),
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end
            
            -- Webhook notification
            if webhookEnabled then
                local rarity = "Common"
                if fishInfo.tier == 7 then
                    rarity = "Secret"
                elseif fishInfo.tier == 6 then
                    rarity = "Mythic" 
                elseif fishInfo.tier == 5 then
                    rarity = "Legendary"
                end

                if shouldSendWebhook(fishInfo.name, fishInfo.tier) then
                    task.wait(1)
                    sendWebhook(fishInfo.name, fishInfo.tier, data.InventoryItem and data.InventoryItem.SellPrice or 0, rarity)
                end
            end
        end)
        return true
    end
    
    return false
end

local function InitializeAutoFavorite()
    if not BuildFishDatabase() then
        Rayfield:Notify({
            Title = "Auto Favorite Error",
            Content = "Failed to load fish database",
            Duration = 5,
            Image = 4483362458
        })
        return false
    end
    
    if not SetupAutoFavoriteListener() then
        Rayfield:Notify({
            Title = "Auto Favorite Warning",
            Content = "Live favorite might not work",
            Duration = 5,
            Image = 4483362458
        })
    end
    
    return true
end

-- =============================================
-- UTILITY SYSTEMS (KEEP ALL ORIGINAL)
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
-- PERFORMANCE MODE (KEEP ORIGINAL)
-- =============================================

local function TogglePerformanceMode(enabled)
    Config.PerformanceMode = enabled
    
    if enabled then
        -- Optimize lighting
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 1
        
        -- Remove particles and effects
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
            
            if obj:IsA("Part") or obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end
        end
        
        -- Optimize terrain
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
        -- Restore settings
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10000
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end

-- =============================================
-- WEATHER SYSTEM (KEEP ORIGINAL)
-- =============================================

local function AutoBuyWeatherSystem()
    task.spawn(function()
        while Config.AutoBuyWeather do
            for _, weather in pairs(Config.SelectedWeathers) do
                if weather then
                    pcall(function()
                        PurchaseWeather:InvokeServer(weather)
                        print("[WEATHER] Purchased: " .. weather)
                    end)
                    task.wait(0.5)
                end
            end
            task.wait(5)
        end
    end)
end

-- =============================================
-- TELEPORT SYSTEM (KEEP ORIGINAL + ADD EVENT)
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
-- GRAPHICS & PERFORMANCE (KEEP ORIGINAL)
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
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        if obj:IsA("MeshPart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.TextureID = ""
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
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
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
-- EMERGENCY & SAFETY
-- =============================================

local function EmergencyStopAll()
    print("🚨 EMERGENCY STOP ALL SYSTEMS")
    
    -- Stop all fishing
    FishingActive = false
    Config.FishingV1 = false
    autoFishingV5Enabled = false  -- GANTI dari Config.FishingV4
    fishingV5Active = false
    
    -- Stop other systems
    Config.AutoBuyWeather = false
    Config.AutoJump = false
    QuestState.Active = false
    
    Rayfield:Notify({
        Title = "🚨 EMERGENCY STOP",
        Content = "All systems stopped immediately!",
        Duration = 3,
        Image = 4483362458
    })
    
    pcall(function()
        if Window and Window.SetWindowName then
            Window:SetWindowName("🎣 Auto Fishing V4 - Codepik")
        end
    end)
end

-- =============================================
-- UI CREATION - MODIFIED WITH NEW FEATURES
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
    PatchTab:CreateLabel("🔄 Version: V5")
    PatchTab:CreateLabel("📅 Update Date: 27-10-25")

    PatchTab:CreateButton({
    Name = "📋 Show V5 Features",
    Callback = function()
        Rayfield:Notify({
            Title = "🎣 Auto Fishing V5 Features",
            Content = [[
            🚀 NEW IN V4.3:
            • Redesign UI
            • New feature check in game
            • New Fishing V1 (Auto fishing in game)
            • New Fishing V5 Skip animation
            • New Quest System
                
            ❗ FIX BUG:
            • Fixing Auto fishing V4. Deleting Feature
            ]],
            Duration = 15,
            Image = 4483362458
        })
    end,
    })
    
    

    -- Main Tab
    local MainTab = Window:CreateTab("🔥 Main", 4483362458)

    -- Fishing Systems Section (Simplified)
    -- Fishing Systems Section (Simplified)
MainTab:CreateSection("🎣 FISHING SYSTEMS")

-- Fishing V1 (Game Auto)
MainTab:CreateToggle({
    Name = "🎣 Fishing V1 (Game Auto)",
    CurrentValue = Config.FishingV1,
    Callback = function(Value)
        Config.FishingV1 = Value
        if Value then
            autoFishingV5Enabled = false -- Matikan V5
            StopFishingV5()
            StartFishingV1()
        else
            StopFishingV1()
        end
    end,
})

-- Fishing V5 (FIXED VERSION)
MainTab:CreateToggle({
    Name = "🚀 Fishing V5 (Fix Cannot get fish)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            -- Matikan sistem lain
            Config.FishingV1 = false
            StopFishingV1()
            
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

    MainTab:CreateButton({
        Name = "Sell Now",
        Callback = SellNow,
    })
    
    MainTab:CreateSection("Auto Enchant Rod")

    MainTab:CreateButton({
        Name = "🔮 Auto Enchant Rod",
        Callback = AutoEnchantRod
    })
    
    -- Buat Quest Tab baru
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
                QuestState.Active = true
                QuestState.CurrentQuest = quest.Name
                QuestState.SelectedTask = nil
                QuestState.CurrentLocation = nil
                QuestState.Teleported = false
                QuestState.Fishing = false
                QuestState.LastProgress = GetQuestProgress(quest.Name)
                QuestState.LastTaskIndex = nil
                
                Rayfield:Notify({
                    Title = "🎯 QUEST STARTED",
                    Content = "Auto quest activated for " .. quest.Display,
                    Duration = 4,
                    Image = 4483362458
                })
            else
                QuestState.Active = false
                Config.FishingV4 = false
            end
        end
    })

    QuestTab:CreateButton({
        Name = "Check " .. quest.Display .. " Progress",
        Callback = function()
            local progress = GetQuestProgress(quest.Name)
            local activeTasks = GetActiveTasks(quest.Name)
            
            local message = quest.Display .. " Progress: " .. string.format("%.1f%%", progress) .. "\n\n"
            for i, task in ipairs(activeTasks) do
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
            if QuestState.Active then
            text = text .. "Active: " .. QuestState.CurrentQuest .. "\n"
            text = text .. "Progress: " .. string.format("%.1f", GetQuestProgress(QuestState.CurrentQuest)) .. "%\n"
            if QuestState.SelectedTask then 
                text = text .. "Task: " .. QuestState.SelectedTask .. "\n" 
            end
            text = text .. (QuestState.Fishing and "\nFARMING..." or "\nPreparing...")
        else
            text = text .. "No active quest\n\nSelect a quest to start"
        end
        QuestStatusLabel:Set(text)
       end
      end)

    -- Teleport Tab (WITH EVENT TELEPORT ADDED)
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

    -- NEW: TELEPORT TO ACTIVE EVENTS SECTION
    TeleportTab:CreateSection("TELEPORT TO ACTIVE EVENTS")

    -- Event UI Handler
    local eventButtons = {}
    local lastEventSnapshot = {}

    local function hasEventChanged(newEvents)
        if #newEvents ~= #lastEventSnapshot then
            return true
        end
        for i, v in ipairs(newEvents) do
            if not lastEventSnapshot[i] or lastEventSnapshot[i].Name ~= v.Name then
                return true
            end
        end
        return false
    end

    local function updateEventButtons()
        local events = ScanActiveEvents() or {}

        for _, b in pairs(eventButtons) do
            pcall(function() b:Destroy() end)
        end
        table.clear(eventButtons)

        local header = TeleportTab:CreateParagraph({
            Title = "Active Events",
            Content = "Auto-refreshing every 5 seconds"
        })
        table.insert(eventButtons, header)

        for _, event in ipairs(events) do
            local btn = TeleportTab:CreateButton({
                Name = "📍 " .. event.Name,
                Callback = function()
                    teleportToEventPosition(event.Position)
                end
            })
            table.insert(eventButtons, btn)
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

    local refreshBtn = TeleportTab:CreateButton({
        Name = "🔄 Refresh Active Events",
        Callback = function()
            updateEventButtons()
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
            if hasEventChanged(events) then
                updateEventButtons()
            end
        end
    end)

    updateEventButtons()

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

    -- NEW: WEBHOOK TAB
    local WebhookTab = Window:CreateTab("📣 Webhook", 4483362458)

    WebhookTab:CreateSection("Send Webhook")

    WebhookTab:CreateToggle({
        Name = "🔔 Enable Webhook Notifications",
        CurrentValue = webhookEnabled,
        Callback = function(Value)
            webhookEnabled = Value
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
            webhookUrl = Text
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
            SelectedWebhookCategories = Options
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
            if webhookUrl == "" then
                Rayfield:Notify({
                    Title = "Webhook Error",
                    Content = "Please set webhook URL first",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            
            sendWebhook("Test Fish", 7, 25000, "Secret")
            Rayfield:Notify({
                Title = "Webhook Test",
                Content = "Test notification sent!",
                Duration = 3,
                Image = 4483362458
            })
        end,
    })

    -- Player Tab (KEEP ALL ORIGINAL FEATURES)
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

    -- Graphics Tab (KEEP ALL ORIGINAL FEATURES)
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

    -- Utility Tab (KEEP ALL ORIGINAL FEATURES)
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
        Title = "🎣 Auto Fishing V5 - Codepik",
        Content = "All systems loaded! Features: V1 Game Auto + V5 Fix Bug + Webhook + Event Teleport",
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
    -- Restore active features
    if Config.FishingV1 then
     task.wait(2)
     StartFishingV1()
    elseif autoFishingV5Enabled then  -- GANTI dari Config.FishingV4
     task.wait(2)
     StartFishingV5()
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

-- Fish threshold monitor
task.spawn(function()
    while task.wait(1) do
        if (FishingActive or Config.FishingV1 or Config.FishingV4) and #obtainedFishUUIDs >= obtainedLimit then
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
        ApplyPermanentLighting()
        
        print("🎣 Auto Fishing V5 - Codepik Edition")
        print("🎯 Hotkey: CTRL+SHIFT+P for emergency stop")
    else
        warn("❌ Failed to setup remotes!")
    end
end)

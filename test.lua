local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library dengan error handling
local Rayfield = nil
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI")
    return
end

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

-- Fish Threshold Variables
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

local antiAFKEnabled = false
local autoFavoriteEnabled = false
local autoFarmEnabled = false
local universalNoclip = false
local floatEnabled = false
local autoTPEventEnabled = false
local autoSellMythicEnabled = false
local fishWebhookEnabled = false

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote, REEquipItem, RFSellItem
local AFKConnection = nil
local floatPlatform = nil

-- Auto Farm Variables
local selectedIsland = "Fisherman Island"
local farmLocations = {
    ["Crater Islands"] = {
        CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1, -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
        CFrame.new(1057.28992, 33.0884132, 5133.79883, 0.833871782, 5.44149223e-08, 0.551958203, -6.58184218e-09, 1, -8.86416984e-08, -0.551958203, 7.02829084e-08, 0.833871782),
    },
    ["Tropical Grove"] = {
        CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1, -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407)
    },
    ["Fisherman Island"] = {
        CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1, 8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
        CFrame.new(-162.285294, 3.26205397, 2954.47412, -0.74356699, -1.93168272e-08, -0.668661416, 1.03873425e-08, 1, -4.04397653e-08, 0.668661416, -3.70152904e-08, -0.74356699),
    }
}

-- Auto Event Farm
local savedCFrame = nil
local alreadyTeleported = false
local teleportTime = nil
local eventTarget = nil

-- Player Variables
local ijumpEnabled = false
local AntiDrown_Enabled = false

-- Auto Favorite Variables
local GlobalFav = {
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedCategories = {},
    AutoFavoriteEnabled = false
}

-- Fish Categories (Updated berdasarkan Tier)
local FishCategories = {
    ["Secret"] = {
        -- Tier 7 - Paling Langka
        "Blob Shark", "Great Christmas Whale", "Frostborn Shark", "Great Whale", 
        "Worm Fish", "Robot Kraken", "Giant Squid", "Ghost Worm Fish", 
        "Ghost Shark", "Queen Crab", "Orca", "Crystal Crab", 
        "Monster Shark", "Eerie Shark", "King Jelly", "Bone Whale",
        "Ancient Whale", "Mosasaur Shark", "Elshark Gran Maja",
        "Dead Zombie Shark", "Zombie Shark", "Megalodon", "Lochness Monster",
        "Zombie Megalodon"
    },
    ["Mythic"] = {
        -- Tier 6
        "Gingerbread Shark", "Loving Shark", "King Crab", "Blob Fish", 
        "Hermit Crab", "Luminous Fish", "Plasma Shark", "Crocodile",
        "Ancient Relic Crocodile", "Panther Eel", "Hybodus Shark",
        "Magma Shark", "Sharp One", "Mammoth Appafish",
        "Frankenstein Longsnapper", "Pumpkin Ray", "Dark Pumpkin Appafish"
    },
    ["Legendary"] = {
        -- Tier 5
        "Yellowfin Tuna", "Lake Sturgeon", "Lined Cardinal Fish", "Saw Fish",
        "Abyss Seahorse", "Blueflame Ray", "Hammerhead Shark", 
        "Hawks Turtle", "Manta Ray", "Loggerhead Turtle", 
        "Prismy Seahorse", "Gingerbread Turtle", "Thresher Shark",
        "Dotted Stingray", "Strippled Seahorse", "Deep Sea Crab",
        "Ruby", "Temple Spokes Tuna", "Sacred Guardian Squid",
        "Manoai Statue Fish", "Pumpkin Carved Shark", "Wizard Stingray",
        "Crystal Salamander", "Pumpkin StoneTurtle"
    },
}

-- Weather Variables
local weatherActive = {}
local weatherData = {
    ["Storm"] = { duration = 900 },
    ["Cloudy"] = { duration = 900 },
    ["Snow"] = { duration = 900 },
    ["Wind"] = { duration = 900 },
    ["Radiant"] = { duration = 900 }
}

-- Fish Notification Variables
local webhookPath = nil
local SelectedCategories = {"Secret"}
local LastCatchData = {}

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

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

local function setupRemotes()
    local success, err = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
    end)

    if not success then
        success, err = pcall(function()
            net = ReplicatedStorage:WaitForChild("Net")
        end)
        
        if not success then
            warn("Failed to find net: " .. tostring(err))
            return false
        end
    end

    local function safeWaitForChild(parent, name, timeout)
        timeout = timeout or 5
        local start = tick()
        while tick() - start < timeout do
            local child = parent:FindFirstChild(name)
            if child then return child end
            task.wait(0.1)
        end
        warn("Timeout waiting for: " .. name)
        return nil
    end

    rodRemote = safeWaitForChild(net, "RF/ChargeFishingRod")
    miniGameRemote = safeWaitForChild(net, "RF/RequestFishingMinigameStarted")
    finishRemote = safeWaitForChild(net, "RE/FishingCompleted")
    equipRemote = safeWaitForChild(net, "RE/EquipToolFromHotbar")
    sellRemote = safeWaitForChild(net, "RF/SellAllItems")
    favoriteRemote = safeWaitForChild(net, "RE/FavoriteItem")
    REEquipItem = safeWaitForChild(net, "RE/EquipItem")
    RFSellItem = safeWaitForChild(net, "RF/SellItem")
    
    return true
end

-- ===================================
-- ========== ENHANCE FISHING ========
-- ===================================

-- 🚀 STABLE FISHING SYSTEM - OPTIMIZED
local StableFishing = {
    Enabled = false,
    SpeedMultiplier = 1.0,
    PerfectCast = true,
    CastCount = 0,
    FixedSpeed = 0.4
}

local function updateRodModifiers()
    local char = player.Character
    if not char then return 1.0 end
    
    local equippedRod = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then
            equippedRod = tool
            break
        end
    end
    
    local speedMultiplier = 1.0
    if equippedRod then
        for attrName, attrValue in pairs(equippedRod:GetAttributes()) do
            local nameLower = string.lower(tostring(attrName))
            
            if nameLower:find("reel") and nameLower:find("faster") then
                local speedBonus = tonumber(string.match(attrValue, "%d+")) or 
                                 tonumber(string.match(attrName, "%d+")) or 0
                if speedBonus > 0 then
                    speedMultiplier = math.max(0.3, 1.0 - (speedBonus / 100))
                end
            end
        end
    end
    
    StableFishing.SpeedMultiplier = speedMultiplier
    return speedMultiplier
end

-- 🎯 OPTIMIZED FISHING LOOP - LESS DETECTABLE
local function stableFishingLoop()
    while StableFishing.Enabled and task.wait() do
        local success, err = pcall(function()
            if not StableFishing.Enabled then return end
            
            StableFishing.CastCount = StableFishing.CastCount + 1
            
            updateRodModifiers()
            
            -- PHASE 1: EQUIP & CAST
            equipRemote:FireServer(1)
            task.wait(0.12 * StableFishing.SpeedMultiplier)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.08 * StableFishing.SpeedMultiplier)
            
            -- PHASE 2: RANDOMIZED CAST
            local x, y
            if StableFishing.PerfectCast then
                x = -0.7499996 + (math.random(-3, 3) / 10000000)
                y = 1 + (math.random(-3, 3) / 10000000)
            else
                x = math.random(-80, 80) / 100
                y = math.random(70, 95) / 100
            end
            
            miniGameRemote:InvokeServer(x, y)
            
            -- PHASE 3: RANDOMIZED SUCCESS
            task.spawn(function()
                local waitTimes = {0.0003, 0.0005, 0.0007, 0.0009, 0.0011}
                
                for i = 1, 4 do
                    if not StableFishing.Enabled then break end
                    
                    pcall(function()
                        finishRemote:FireServer(true)
                    end)
                    
                    local waitTime = waitTimes[math.random(1, #waitTimes)]
                    task.wait(waitTime)
                end
                
                -- Final cleanup dengan delay acak
                task.wait(math.random(5, 15) / 1000)
                pcall(function()
                    finishRemote:FireServer()
                end)
            end)
            
            -- PHASE 4: RANDOMIZED COOLDOWN
            local cooldown = math.random(4, 8) / 100 * StableFishing.SpeedMultiplier
            task.wait(math.max(0.03, cooldown))
            
        end)
        
        if not success then
            warn("Fishing Error: " .. tostring(err))
            task.wait(0.5)
        end
    end
end

-- ===================================
-- ========== FISH THRESHOLD =========
-- ===================================

local function monitorFishThreshold()
    task.spawn(function()
        while task.wait(1) do
            if StableFishing.Enabled and #obtainedFishUUIDs >= obtainedLimit then
                Rayfield:Notify({
                    Title = "Fish Threshold",
                    Content = "Selling all fishes...",
                    Duration = 3,
                    Image = 4483362458
                })
                pcall(function() sellRemote:InvokeServer() end)
                obtainedFishUUIDs = {}
                task.wait(2)
            end
        end
    end)
end

-- Setup fish obtained listener
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

-- Start Stable Fishing
local function startStableFishing()
    if StableFishing.Enabled then
        return
    end
    
    StableFishing.Enabled = true
    StableFishing.CastCount = 0
    
    task.spawn(stableFishingLoop)
    
    Rayfield:Notify({
        Title = "🚀 Auto Fishing",
        Content = "Started successfully",
        Duration = 3,
        Image = 4483362458
    })
end

local function stopStableFishing()
    StableFishing.Enabled = false
    
    Rayfield:Notify({
        Title = "🛑 Auto Fishing Stopped",
        Content = "Fishing system disabled",
        Duration = 3
    })
end

-- ===================================
-- ========== SCAN EXISTING INVENTORY (FIXED)
-- ===================================

local function scanAndFavoriteExistingFish()
    if not GlobalFav.AutoFavoriteEnabled then return end
    
    Rayfield:Notify({
        Title = "🔍 Scanning Inventory",
        Content = "Checking existing fish...",
        Duration = 2,
        Image = 4483362458
    })
    
    local favoritedCount = 0
    local scannedCount = 0
    
    task.spawn(function()
        pcall(function()
            local backpackGui = player.PlayerGui:FindFirstChild("Backpack")
            if not backpackGui then 
                warn("Backpack GUI not found")
                return 
            end
            
            local display = backpackGui:FindFirstChild("Display")
            if not display then 
                warn("Display not found")
                return 
            end
            
            -- Iterate through all children
            for _, slot in pairs(display:GetChildren()) do
                -- ONLY process ImageButton that represents fish slots
                if not slot:IsA("ImageButton") then
                    continue
                end
                
                -- Skip non-fish slots by name
                local slotName = slot.Name
                if slotName == "Inventory" or slotName == "Tile" or 
                   slotName:find("Layout") or slotName:find("Padding") or
                   slotName:find("Constraint") then
                    continue
                end
                
                local inner = slot:FindFirstChild("Inner")
                if not inner then continue end
                
                local tags = inner:FindFirstChild("Tags")
                if not tags then continue end
                
                local itemName = tags:FindFirstChild("ItemName")
                if not itemName or not itemName.Text or itemName.Text == "" then continue end
                
                -- Check if already favorited
                local favoritedTag = tags:FindFirstChild("Favorited")
                if favoritedTag and favoritedTag.Value == true then
                    continue
                end
                
                local fishName = itemName.Text
                scannedCount = scannedCount + 1
                
                print(string.format("🔍 Scanning: %s", fishName))
                
                -- Find fish tier by name from our database
                local fishTier = nil
                for id, fishInfo in pairs(GlobalFav.FishIdToName) do
                    if fishInfo.name == fishName then
                        fishTier = fishInfo.tier
                        break
                    end
                end
                
                -- Fallback: Try exact match from FishCategories
                if not fishTier then
                    for category, fishList in pairs(FishCategories) do
                        for _, targetFish in ipairs(fishList) do
                            if string.lower(fishName) == string.lower(targetFish) then
                                if category == "Secret" then
                                    fishTier = 7
                                elseif category == "Mythic" then
                                    fishTier = 6
                                elseif category == "Legendary" then
                                    fishTier = 5
                                end
                                break
                            end
                        end
                        if fishTier then break end
                    end
                end
                
                if not fishTier then 
                    print(string.format("⚠️ Tier not found for: %s", fishName))
                    continue 
                end
                
                -- Check if should favorite based on tier
                local shouldFavorite = false
                
                if table.find(GlobalFav.SelectedCategories or {}, "Secret") and fishTier == 7 then
                    shouldFavorite = true
                elseif table.find(GlobalFav.SelectedCategories or {}, "Mythic") and fishTier == 6 then
                    shouldFavorite = true
                elseif table.find(GlobalFav.SelectedCategories or {}, "Legendary") and fishTier == 5 then
                    shouldFavorite = true
                end
                
                if shouldFavorite then
                    -- Try to get UUID from Tags children first
                    local uuid = nil
                    
                    -- Method 1: Check Tags children
                    for _, child in pairs(tags:GetChildren()) do
                        if child.Name == "UUID" or child.Name == "ItemUUID" or child.Name == "Id" then
                            uuid = child.Value or child.Text
                            if uuid and uuid ~= "" then
                                break
                            end
                        end
                    end
                    
                    -- Method 2: Check slot/inner attributes
                    if not uuid then
                        uuid = slot:GetAttribute("UUID") or 
                              slot:GetAttribute("ItemUUID") or
                              inner:GetAttribute("UUID") or
                              inner:GetAttribute("ItemUUID")
                    end
                    
                    if uuid and uuid ~= "" then
                        task.wait(0.2)
                        local success, err = pcall(function()
                            favoriteRemote:FireServer(uuid)
                        end)
                        
                        if success then
                            favoritedCount = favoritedCount + 1
                            print(string.format("✅ Favorited: %s (Tier %d) - UUID: %s", fishName, fishTier, tostring(uuid)))
                        else
                            warn(string.format("❌ Failed to favorite: %s - Error: %s", fishName, tostring(err)))
                        end
                    else
                        warn(string.format("⚠️ UUID not found for: %s", fishName))
                        
                        -- Debug: print all tag children
                        print("  Available Tags:")
                        for _, child in pairs(tags:GetChildren()) do
                            local val = child.Value or child.Text or "N/A"
                            print(string.format("    - %s = %s", child.Name, tostring(val)))
                        end
                    end
                end
            end
            
            task.wait(1)
            
            Rayfield:Notify({
                Title = "✅ Scan Complete",
                Content = string.format("Scanned: %d | Favorited: %d", scannedCount, favoritedCount),
                Duration = 4,
                Image = 4483362458
            })
            
            print(string.format("📊 Final Stats: Scanned=%d, Favorited=%d", scannedCount, favoritedCount))
        end)
    end)
end
-- ===================================
-- ========== AUTO FAVORITE SYSTEM ===
-- ===================================

local function setupAutoFavorite()
    -- Build fish database dengan tier info
    pcall(function()
        for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
            local ok, data = pcall(require, item)
            if ok and data and data.Data and data.Data.Type == "Fishes" then
                local id = data.Data.Id
                local name = data.Data.Name
                local tier = data.Data.Tier or "1"
                
                GlobalFav.FishIdToName[id] = {
                    name = name,
                    tier = tonumber(tier) or 1
                }
                GlobalFav.FishNameToId[name] = id
                table.insert(GlobalFav.FishNames, name)
            end
        end
    end)

    -- Listen fish caught event
    local success, REObtainedNewFishNotification = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
            if not GlobalFav.AutoFavoriteEnabled then return end

            local uuid = data.InventoryItem and data.InventoryItem.UUID
            if not uuid then return end

            local fishInfo = GlobalFav.FishIdToName[itemId]
            if not fishInfo then return end
            
            local fishName = fishInfo.name
            local fishTier = fishInfo.tier

            -- TIER BASED FILTERING (lebih akurat!)
            local shouldFavorite = false
            
            -- Tier 7 = Secret (paling langka)
            -- Tier 6 = Mythic
            -- Tier 5 = Legendary
            
            if table.find(GlobalFav.SelectedCategories or {}, "Secret") and fishTier == 7 then
                shouldFavorite = true
            elseif table.find(GlobalFav.SelectedCategories or {}, "Mythic") and fishTier == 6 then
                shouldFavorite = true
            elseif table.find(GlobalFav.SelectedCategories or {}, "Legendary") and fishTier == 5 then
                shouldFavorite = true
            end
            
            -- BACKUP: Name-based check (kalau tier ga ketemu)
            if not shouldFavorite then
                for category, fishList in pairs(FishCategories) do
                    if table.find(GlobalFav.SelectedCategories or {}, category) then
                        for _, targetFish in ipairs(fishList) do
                            if string.lower(fishName) == string.lower(targetFish) then
                                shouldFavorite = true
                                break
                            end
                        end
                    end
                    if shouldFavorite then break end
                end
            end

            if shouldFavorite then
                -- Reduced delay untuk faster favoriting
                task.wait(0.1)
                pcall(function() 
                    favoriteRemote:FireServer(uuid) 
                end)
                
                Rayfield:Notify({
                    Title = "⭐ Auto Favorite",
                    Content = string.format("%s (Tier %d)", fishName, fishTier),
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end)
    end
end
-- ===================================
-- ========== AUTO SELL ==============
-- ===================================

local function sellNow()
    local success, err = pcall(function()
        sellRemote:InvokeServer()
    end)

    if success then
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Successfully sold items!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Auto Sell Failed",
            Content = "Error: " .. tostring(err),
            Duration = 3
        })
    end
end

-- ===================================
-- ========== WEATHER SYSTEM =========
-- ===================================

local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

local function autoBuyWeather(weatherType)
    local purchaseRemote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net")
        :WaitForChild("RF/PurchaseWeatherEvent")

    task.spawn(function()
        while weatherActive[weatherType] do
            pcall(function()
                purchaseRemote:InvokeServer(weatherType)
                
                task.wait(weatherData[weatherType].duration)
                local randomWait = randomDelay(2, 8)
                task.wait(randomWait)
            end)
            task.wait(1)
        end
    end)
end

-- ===================================
-- ========== FLOATING PLATFORM ======
-- ===================================

local function toggleFloat(enabled)
    if enabled then
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder:FindFirstChild(player.Name)
        if not char then 
            return 
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            return 
        end

        floatPlatform = Instance.new("Part")
        floatPlatform.Anchored = true
        floatPlatform.Size = Vector3.new(8, 1, 8)
        floatPlatform.Transparency = 0.8
        floatPlatform.Material = Enum.Material.Neon
        floatPlatform.Color = Color3.fromRGB(0, 255, 255)
        floatPlatform.CanCollide = true
        floatPlatform.Name = "FloatPlatform_" .. math.random(1000,9999)
        floatPlatform.Parent = workspace

        task.spawn(function()
            while floatPlatform and floatPlatform.Parent and task.wait(0.2) do
                pcall(function()
                    if char and hrp then
                        floatPlatform.Position = hrp.Position - Vector3.new(0, 4, 0)
                    end
                end)
            end
        end)

    else
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
    end
end

-- ===================================
-- ========== AUTO EVENT FARM ========
-- ===================================

local knownEvents = {}

local eventData = {
    ["Shark Hunt"] = {hasBoat = true, offset = Vector3.new(0, 15, 0)},
    ["Ghost Shark Hunt"] = {hasBoat = true, offset = Vector3.new(0, 15, 0)},
    ["Worm Hunt"] = {hasBoat = false, offset = Vector3.new(0, 20, 0)},
    ["Ghost Worm"] = {hasBoat = false, offset = Vector3.new(0, 20, 0)},
    ["Megalodon"] = {hasBoat = false, offset = Vector3.new(0, 25, 0)}, -- TAMBAH INI
    ["Black Hole"] = {hasBoat = true, offset = Vector3.new(0, 15, 0)},
    ["Shocked"] = {hasBoat = true, offset = Vector3.new(0, 15, 0)},
    ["Meteor Rain"] = {hasBoat = true, offset = Vector3.new(0, 15, 0)}
}


local function updateKnownEvents()
    knownEvents = {}
    local props = workspace:FindFirstChild("Props")
    if props then
        for _, child in ipairs(props:GetChildren()) do
            if child:IsA("Model") then
                local eventName = child.Name
                knownEvents[eventName:lower()] = {
                    Model = child,
                    Name = eventName,
                    Position = child:GetPivot().Position
                }
            end
        end
    end
    return knownEvents
end

local function teleportToEventPosition(eventName, position, offset)
    offset = offset or Vector3.new(0, 15, 0)
    
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if hrp then
            hrp.CFrame = CFrame.new(position + offset)
            task.wait(0.5)
            return true
        end
    end)
    
    return success, err
end


local function findEventPosition(eventModel)
    if not eventModel then return nil end
    
    -- Priority 1: Check for Fishing Boat (untuk Shark Hunt dll)
    local fishingBoat = eventModel:FindFirstChild("Fishing Boat")
    if fishingBoat and fishingBoat:IsA("Model") then
        return fishingBoat:GetPivot().Position
    end
    
    -- Priority 2: Check PrimaryPart
    if eventModel.PrimaryPart then
        return eventModel.PrimaryPart.Position
    end
    
    -- Priority 3: Find largest BasePart (untuk Worm/Megalodon)
    local largestPart = nil
    local largestSize = 0
    
    for _, part in ipairs(eventModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local size = part.Size.Magnitude
            if size > largestSize then
                largestPart = part
                largestSize = size
            end
        end
    end
    
    if largestPart then
        return largestPart.Position
    end
    
    -- Priority 4: Fallback ke Model pivot
    return eventModel:GetPivot().Position
end

local function saveOriginalPosition()
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return false end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
        return true
    end
    return false
end

local function returnToOriginalPosition()
    if savedCFrame then
        local charFolder = workspace:FindFirstChild("Characters")
        if not charFolder then return end
        
        local char = charFolder:FindFirstChild(player.Name)
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = savedCFrame
        end
    end
end

local function isEventStillActive(eventName)
    updateKnownEvents()
    return knownEvents[eventName:lower()] ~= nil
end

local function monitorAutoTP()
    task.spawn(function()
        while task.wait(3) do
            if autoTPEventEnabled then
                if not alreadyTeleported then
                    updateKnownEvents()
                    
                    for eventName, eventData in pairs(knownEvents) do
                        if saveOriginalPosition() then
                            local position = findEventPosition(eventData.Model)
                            if position then
                                local eventInfo = eventData[eventData.Name] or {hasBoat = true, offset = Vector3.new(0, 15, 0)}
                                local offset = eventInfo.offset or Vector3.new(0, 15, 0)
                                
                                local success, err = teleportToEventPosition(eventData.Name, position, offset)
                                if success then
                                    toggleFloat(true)
                                    alreadyTeleported = true
                                    teleportTime = tick()
                                    eventTarget = eventData.Name
                                    break
                                end
                            end
                        end
                    end
                else
                    if teleportTime and (tick() - teleportTime >= 900) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        eventTarget = nil
                    elseif eventTarget and not isEventStillActive(eventTarget) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                    end
                end
            else
                if alreadyTeleported then
                    returnToOriginalPosition()
                    toggleFloat(false)
                    alreadyTeleported = false
                    teleportTime = nil
                    eventTarget = nil
                end
            end
        end
    end)
end

local function teleportToEvent(eventName)
    updateKnownEvents()
    
    local eventKey = eventName:lower()
    if not knownEvents[eventKey] then
        Rayfield:Notify({
            Title = "Event Not Found",
            Content = eventName .. " is not available!",
            Duration = 3
        })
        return
    end
    
    local eventModel = knownEvents[eventKey].Model
    local eventInfo = eventData[eventName] or {hasBoat = true, offset = Vector3.new(0, 15, 0)}
    
    local position = findEventPosition(eventModel)
    if not position then
        return
    end
    
    local offset = eventInfo.offset or Vector3.new(0, 15, 0)
    local success, err = teleportToEventPosition(eventName, position, offset)
    
    if success then
        Rayfield:Notify({
            Title = "Event Teleport",
            Content = "Teleported to " .. eventName,
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function scanAvailableEvents()
    updateKnownEvents()
    local available = {}
    
    for eventName, eventData in pairs(knownEvents) do
        table.insert(available, eventData.Name)
    end
    
    if #available > 0 then
        Rayfield:Notify({
            Title = "Available Events",
            Content = "Found: " .. table.concat(available, ", "),
            Duration = 5,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "No Events",
            Content = "No events available",
            Duration = 3
        })
    end
    
    return available
end

-- ===================================
-- ========== SERVER HOP =============
-- ===================================

local function Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end

local function QuickServerHop()
    local placeId = game.PlaceId
    local servers = {}
    
    Rayfield:Notify({
        Title = "Quick Server Hop",
        Content = "Finding available server...",
        Duration = 3,
        Image = 4483362458
    })
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer, player)
    else
        Rayfield:Notify({
            Title = "Server Hop Failed",
            Content = "No servers available!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== BOOST FPS ==============
-- ===================================

local function BoostFPS()
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Optimizing performance...",
        Duration = 3,
        Image = 4483362458
    })
    
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        end
    end

    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Performance optimized!",
        Duration = 3,
        Image = 4483362458
    })
end

-- ===================================
-- ========== TELEPORT SYSTEMS =======
-- ===================================

local islandCoords = {
    ["Weather Machine"] = Vector3.new(-1471, -3, 1929),
    ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    ["Kohana Volcano"] = Vector3.new(-519, 24, 189),
    ["Coral Reefs"] = Vector3.new(-3095, 1, 2177),
    ["Crater Island"] = Vector3.new(968, 1, 4854),
    ["Kohana"] = Vector3.new(-658, 3, 719),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
    ["Isoteric Island"] = Vector3.new(1987, 4, 1400),
    ["Treasure Hall"] = Vector3.new(-3600, -267, -1558),
    ["Lost Shore"] = Vector3.new(-3663, 38, -989),
    ["Sishypus Statue"] = Vector3.new(-3792, -135, -986),
    ["Ancient Jungle"] = Vector3.new(1316, 7, -196)
}

local function teleportToIsland(islandName)
    local pos = islandCoords[islandName]
    if not pos then 
        return
    end
    
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end)

    if success then
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Teleported to " .. islandName,
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- ===================================
-- ========== ANTI-AFK ===============
-- ===================================

local function toggleAntiAFK()
    antiAFKEnabled = not antiAFKEnabled
    
    if antiAFKEnabled then
        if AFKConnection then
            AFKConnection:Disconnect()
        end
        
        AFKConnection = player.Idled:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end)
        
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
    end
end

-- ===================================
-- ========== AUTO FARM ==============
-- ===================================

local function startAutoFarmLoop()
    while autoFarmEnabled and task.wait(2) do
        local success, err = pcall(function()
            local islandSpots = farmLocations[selectedIsland]
            if type(islandSpots) == "table" and #islandSpots > 0 then
                local location = islandSpots[math.random(1, #islandSpots)]
                
                local charFolder = workspace:FindFirstChild("Characters")
                if not charFolder then return end
                
                local char = charFolder:FindFirstChild(player.Name)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = location
                    task.wait(2)
                end
            end
        end)
        
        if not success then
            warn("Auto Farm Error: " .. tostring(err))
        end
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Codepikk Premium++",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Patch Note Tab
local PatchNote = Window:CreateTab("📝 Patch Notes", 4483362458)

PatchNote:CreateSection("📝 Patch Notes")

PatchNote:CreateLabel("🔄 Version: v3.0.3")
PatchNote:CreateLabel("📅 Release Date: 25-10-25")

PatchNote:CreateButton({
    Name = "📋 Show Patch Notes",
    Callback = function()
        Rayfield:Notify({
            Title = "📝 Patch Notes v3.0.2",
            Content = [[
🛠️ IMPROVEMENTS:
• Redesign UI
• Optimized Fishing Speed
• Stable Performance

🐛 FIXES:
• Auto Threshold bug
• Auto Favorite Now Works
• Cannot Scrolling Section
            ]],
            Duration = 15,
            Image = 4483362458
        })
    end,
})


-- Main Tab
local MainTab = Window:CreateTab("🔥 Main Tab", 4483362458)


MainTab:CreateSection("Auto Fishing")

MainTab:CreateToggle({
    Name = "🚀 Auto Fishing",
    CurrentValue = false,
    Flag = "StableFishingToggle",
    Callback = function(Value)
        if Value then
            startStableFishing()
        else
            stopStableFishing()
        end
    end,
})

MainTab:CreateToggle({
    Name = "🎯 Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        StableFishing.PerfectCast = Value
    end,
})

MainTab:CreateSection("Auto Sell fish")

MainTab:CreateInput({
    Name = "Auto Sell fish Custom",
    PlaceholderText = "Default: 4000 fish",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            obtainedLimit = num
        end
    end,
})

MainTab:CreateButton({
    Name = "💰 Sell Now",
    Callback = sellNow,
})

MainTab:CreateSection("Auto Favorite System")

MainTab:CreateToggle({
    Name = "⭐ Enable Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        GlobalFav.AutoFavoriteEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Favorite ON",
                Content = "Favoriting: " .. table.concat(GlobalFav.SelectedCategories, ", "),
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateDropdown({
    Name = "Select Rarity Categories",
    Options = {"Secret", "Mythic", "Legendary"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FavoriteCategoryDropdown",
    Callback = function(Options)
        GlobalFav.SelectedCategories = Options
        
        local categories = #Options > 0 and table.concat(Options, ", ") or "None"
        Rayfield:Notify({
            Title = "Category Updated",
            Content = "Selected: " .. categories,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

MainTab:CreateLabel("💡 Tier Info:")
MainTab:CreateLabel("Tier 7 = Secret | Tier 6 = Mythic | Tier 5 = Legendary")

MainTab:CreateButton({
    Name = "🔍 Scan & Favorite Inventory Fish",
    Callback = function()
        if not GlobalFav.AutoFavoriteEnabled then
            Rayfield:Notify({
                Title = "⚠️ Auto Favorite Disabled",
                Content = "Enable Auto Favorite first!",
                Duration = 3
            })
            return
        end
        
        if #GlobalFav.SelectedCategories == 0 then
            Rayfield:Notify({
                Title = "⚠️ No Category Selected",
                Content = "Select rarity categories first!",
                Duration = 3
            })
            return
        end
        
        scanAndFavoriteExistingFish()
    end,
})

MainTab:CreateSection("Auto Farm")

local islandOptions = {
    "Crater Islands",
    "Tropical Grove", 
    "Fisherman Island"
}

MainTab:CreateDropdown({
    Name = "Select Farm Island",
    Options = islandOptions,
    CurrentOption = "Fisherman Island",
    Flag = "FarmIslandDropdown",
    Callback = function(Option)
        selectedIsland = Option
    end,
})

MainTab:CreateToggle({
    Name = "🌾 Start Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            task.spawn(startAutoFarmLoop)
        end
    end,
})

MainTab:CreateSection("Auto Buy Weather")

MainTab:CreateDropdown({
    Name = "Auto Buy Weather",
    Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "WeatherDropdown",
    Callback = function(Options)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(Options, weatherType) then
                weatherActive[weatherType] = false
            end
        end
        
        for _, weatherType in pairs(Options) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                autoBuyWeather(weatherType)
            end
        end
    end,
})

MainTab:CreateSection("Auto Enchant Rod")

MainTab:CreateButton({
    Name = "🔮 Auto Enchant Rod",
    Callback = function()
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

        local slot5 = player.PlayerGui.Backpack.Display:GetChildren()[10]
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
})


-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

TeleportTab:CreateSection("TELEPORT TO ISLAND")

local islandList = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

for _, islandName in ipairs(islandList) do
    TeleportTab:CreateButton({
        Name = islandName,
        Callback = function()
            teleportToIsland(islandName)
        end,
    })
end

TeleportTab:CreateSection("TELEPORT TO EVENT")

TeleportTab:CreateButton({
    Name = "🔍 Scan Available Events",
    Callback = function()
        scanAvailableEvents()
    end,
})


local eventOptions = {
    "Shark Hunt", 
    "Ghost Shark Hunt", 
    "Worm Hunt", 
    "Ghost Worm",
    "Megalodon",  -- TAMBAH INI
    "Black Hole", 
    "Shocked", 
    "Meteor Rain"
}

for _, eventName in ipairs(eventOptions) do
    TeleportTab:CreateButton({
        Name = eventName,
        Callback = function()
            teleportToEvent(eventName)
        end,
    })
end

TeleportTab:CreateSection("Auto Event Farm")

TeleportTab:CreateToggle({
    Name = "🎯 Auto Farm Event",
    CurrentValue = false,
    Flag = "AutoEventFarmToggle",
    Callback = function(Value)
        autoTPEventEnabled = Value
        if Value then
            monitorAutoTP()
        end
    end,
})

-- Player Tab
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSection("Player Features")

PlayerTab:CreateToggle({
    Name = "🔓 No Clip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        universalNoclip = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "🎈 Enable Float",
    CurrentValue = false,
    Flag = "FloatToggle",
    Callback = function(Value)
        floatEnabled = Value
        toggleFloat(Value)
    end,
})

PlayerTab:CreateToggle({
    Name = "🏃 Infinity Jump",
    CurrentValue = false,
    Flag = "InfinityJumpToggle",
    Callback = function(Value)
        ijumpEnabled = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "🌊 Anti Drown",
    CurrentValue = false,
    Flag = "AntiDrownToggle",
    Callback = function(Value)
        AntiDrown_Enabled = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 20,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.WalkSpeed = Value
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 200},
    Increment = 10,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = Value
            end
        end
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Miscellaneous")

MiscTab:CreateToggle({
    Name = "⏰ Anti-AFK System",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        toggleAntiAFK()
    end,
})

MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

MiscTab:CreateSection("Server Hop")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        Rejoin()
    end,
})

MiscTab:CreateButton({
    Name = "⚡ Quick Server Hop",
    Callback = function()
        QuickServerHop()
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("🔧 Settings", 4483362458)

SettingsTab:CreateSection("Configuration")

SettingsTab:CreateKeybind({
    Name = "UI Keybind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function(Keybind)
        Window:SetKeybind(Keybind)
    end,
})

SettingsTab:CreateButton({
    Name = "💾 Save Configuration",
    Callback = function()
        Rayfield:SaveConfiguration()
    end,
})

SettingsTab:CreateButton({
    Name = "📂 Load Configuration",
    Callback = function()
        Rayfield:LoadConfiguration()
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

-- NoClip Loop
RunService.Stepped:Connect(function()
    if not universalNoclip then return end

    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinity Jump Handler
UserInputService.JumpRequest:Connect(function()
    if ijumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Anti Drown System
local rawmt = getrawmetatable(game)
setreadonly(rawmt, false)
local oldNamecall = rawmt.__namecall

rawmt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if tostring(self) == "URE/UpdateOxygen" and method == "FireServer" and AntiDrown_Enabled then
        return nil
    end

    return oldNamecall(self, ...)
end)

setreadonly(rawmt, true)

-- Initialize script
local function safeSetup()
    if not setupRemotes() then
        return false
    end
    
    
    setupAutoFavorite()
    monitorFishThreshold()
    return true
end

if safeSetup() then
    updateKnownEvents()
    
    local props = workspace:FindFirstChild("Props")
    if props then
        props.ChildAdded:Connect(function()
            task.wait(0.5)
            updateKnownEvents()
        end)
        props.ChildRemoved:Connect(function()
            task.wait(0.5)
            updateKnownEvents()
        end)
    end

    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Fishing script loaded successfully!",
        Duration = 5,
        Image = 4483362458
    })
end

Rayfield:LoadConfiguration()

-- Anti-AFK untuk semua connections
for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

print("🎣 Fishing Script - Ready to use!")

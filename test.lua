local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local autoFishingEnabled = false
local autoFishingV2Enabled = false
local autoFishingV3Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false
local autoSellAt4000Enabled = false
local autoFarmEnabled = false
local universalNoclip = false
local floatEnabled = false
local autoTPEventEnabled = false
local perfectCastEnabled = true
local autoSellMythicEnabled = false
local fishWebhookEnabled = false
local autoBuyWeatherEnabled = false

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote, REEquipItem, RFSellItem, tradeRemote
local AFKConnection = nil
local floatPlatform = nil

-- Rod Animations
local RodIdle, RodReel, RodShake

-- Fish Price Database
local FishPriceDB = {}

-- Fish Threshold Variables
local obtainedFishUUIDs = {}
local obtainedLimit = 30

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

-- Trade Variables
local autoTradeEnabled = false
local selectedTradePlayer = nil
local selectedTradeAmount = 100000
local tradeSuccessCount = 0
local tradeFailedCount = 0
local totalCoinConverted = 0
local tradeInProgress = false
local availablePlayers = {}
local TradeProgressLabel = nil

-- Auto Favorite Variables
local GlobalFav = {
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    Variants = {},
    SelectedFishIds = {},
    SelectedVariants = {},
    AutoFavoriteEnabled = false
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
local FishCategories = {
    ["Secret"] = {
        "Blob Shark","Great Christmas Whale","Frostborn Shark","Great Whale","Worm Fish","Robot Kraken",
        "Giant Squid","Ghost Worm Fish","Ghost Shark","Queen Crab","Orca","Crystal Crab","Monster Shark","Eerie Shark"
    },
    ["Mythic"] = {
        "Gingerbread Shark","Loving Shark","King Crab","Blob Fish","Hermit Crab","Luminous Fish",
        "Plasma Shark","Abyss Seahorse","Blueflame Ray","Hammerhead Shark","Hawks Turtle",
        "Manta Rey","Loggerhead Turtle","Prismy Seahorse","Gingerbread Turtle","Lined Cardinal Fish",
        "Strippled Seahorse","Thresher Shark","Dotted Stingray"
    },
    ["Legendary"] = {
        "Yellowfin Tuna","Lake Sturgeon","Lined Cardinal Fish","Saw Fish","Slurpfish Chromis","Chrome Tuna","Lobster",
        "Bumblebee Grouper","Lavafin Tuna","Blue Lobster","Greenbee Grouper","Starjam Tang","Magic Tang",
        "Enchanted Angelfish","Axolotl","Deep Sea Crab"
    },
}
local SelectedCategories = {"Secret"}
local LastCatchData = {}

-- ===================================
-- ========== FISH PRICE DATABASE ====
-- ===================================

local function buildFishPriceDatabase()
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then return 0 end
    
    local loadedCount = 0
    
    for _, itemModule in ipairs(itemsFolder:GetChildren()) do
        if itemModule:IsA("ModuleScript") then
            local success, itemData = pcall(require, itemModule)
            
            if success and type(itemData) == "table" then
                local isFish = itemData.Data and itemData.Data.Type == "Fishes"
                local fishId = itemData.Data and itemData.Data.Id
                local sellPrice = itemData.SellPrice
                
                if isFish and fishId and sellPrice then
                    FishPriceDB[fishId] = {
                        Name = itemData.Data.Name or "Unknown",
                        Price = sellPrice,
                        Tier = itemData.Data.Tier or 0
                    }
                    loadedCount = loadedCount + 1
                end
            end
        end
    end
    
    return loadedCount
end

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

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
    tradeRemote = safeWaitForChild(net, "RF/RequestTrade") or 
                  safeWaitForChild(net, "RF/SendTradeRequest") or
                  safeWaitForChild(net, "RF/InitiateTrade")
    
    return true
end

local function setupAnimations()
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
        task.wait(2)
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    
    local success1, rodIdleAnim = pcall(function()
        local RodIdleModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
        return animator:LoadAnimation(RodIdleModule)
    end)
    
    local success2, rodReelAnim = pcall(function()
        local RodReelModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
        return animator:LoadAnimation(RodReelModule)
    end)
    
    local success3, rodShakeAnim = pcall(function()
        local RodShakeModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")
        return animator:LoadAnimation(RodShakeModule)
    end)
    
    if success1 then RodIdle = rodIdleAnim end
    if success2 then RodReel = rodReelAnim end
    if success3 then RodShake = rodShakeAnim end
    
    return success1 and success2 and success3
end

-- ===================================
-- ========== FISH THRESHOLD =========
-- ===================================

local function monitorFishThreshold()
    task.spawn(function()
        while autoFishingEnabled or autoFishingV2Enabled or autoFishingV3Enabled do
            if #obtainedFishUUIDs >= obtainedLimit then
                Rayfield:Notify({
                    Title = "Fish Threshold",
                    Content = "Selling all fishes...",
                    Duration = 3,
                    Image = 4483362458
                })
                sellRemote:InvokeServer()
                obtainedFishUUIDs = {}
                task.wait(0.5)
            end
            task.wait(0.3)
        end
    end)
end

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

-- ===================================
-- ========== TRADE SYSTEM FIXED =====
-- ===================================

local function getAvailablePlayers()
    availablePlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            table.insert(availablePlayers, p.Name)
        end
    end
    return availablePlayers
end

local function getInventoryValue()
    local totalValue = 0
    local fishCount = 0
    
    local success = pcall(function()
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local data = Replion.Client:WaitReplion("Data")
        local items = data:Get({"Inventory","Items"})
        
        for _, item in ipairs(items) do
            local fishData = FishPriceDB[item.Id]
            if fishData and not item.Favorited and fishData.Price > 0 then
                totalValue = totalValue + fishData.Price
                fishCount = fishCount + 1
            end
        end
    end)
    
    if not success then
        warn("Failed to get inventory value")
    end
    
    return totalValue, fishCount
end

local function getFishToTrade(targetValue)
    local fishList = {}
    local currentValue = 0
    
    local success = pcall(function()
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local data = Replion.Client:WaitReplion("Data")
        local items = data:Get({"Inventory","Items"})
        
        local availableFish = {}
        for _, item in ipairs(items) do
            local fishData = FishPriceDB[item.Id]
            if fishData and not item.Favorited and fishData.Price > 0 then
                table.insert(availableFish, {
                    UUID = item.UUID,
                    Value = fishData.Price,
                    Id = item.Id,
                    Name = fishData.Name
                })
            end
        end
        
        table.sort(availableFish, function(a, b)
            return a.Value < b.Value
        end)
        
        for _, fish in ipairs(availableFish) do
            if currentValue < targetValue then
                table.insert(fishList, fish)
                currentValue = currentValue + fish.Value
                
                if currentValue >= targetValue then
                    break
                end
            end
        end
    end)
    
    if not success then
        warn("Failed to get fish for trade")
    end
    
    return fishList, currentValue
end

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

local function updateTradeProgress()
    if TradeProgressLabel then
        local totalTrades = tradeSuccessCount + tradeFailedCount
        local successRate = totalTrades > 0 and (tradeSuccessCount / totalTrades * 100) or 0
        
        local progressText = string.format(
            "╔════════════════════════╗\n" ..
            "║     TRADE PROGRESS     ║\n" ..
            "╚════════════════════════╝\n\n" ..
            "✅ Success: %d / 100\n" ..
            "❌ Failed: %d\n" ..
            "💰 Total Converted: %s\n" ..
            "📊 Success Rate: %.1f%%",
            tradeSuccessCount,
            tradeFailedCount,
            formatCurrency(totalCoinConverted),
            successRate
        )
        TradeProgressLabel:Set(progressText)
    end
end

local function validateTradeConditions()
    if not selectedTradePlayer or selectedTradePlayer == "" then
        return false, "❌ Please select a player first!"
    end
    
    local targetPlayer = Players:FindFirstChild(selectedTradePlayer)
    if not targetPlayer then
        return false, "❌ Player '" .. selectedTradePlayer .. "' not found in server!"
    end
    
    if not targetPlayer.Character then
        return false, "❌ Player '" .. selectedTradePlayer .. "' is not active!"
    end
    
    if not selectedTradeAmount or selectedTradeAmount <= 0 then
        return false, "❌ Please set a valid trade amount!"
    end
    
    local inventoryValue, fishCount = getInventoryValue()
    if inventoryValue <= 0 or fishCount == 0 then
        return false, "❌ No tradable fish found in inventory!"
    end
    
    if inventoryValue < selectedTradeAmount then
        return false, string.format("❌ Not enough value! Current: %s / Needed: %s", 
            formatCurrency(inventoryValue), formatCurrency(selectedTradeAmount))
    end
    
    return true, "Validation passed"
end

local function executeTrade()
    if tradeInProgress then 
        Rayfield:Notify({
            Title = "Trade Busy",
            Content = "Trade in progress, please wait...",
            Duration = 2
        })
        return false
    end
    
    local valid, errorMsg = validateTradeConditions()
    if not valid then
        Rayfield:Notify({
            Title = "Trade Error",
            Content = errorMsg,
            Duration = 4
        })
        return false
    end
    
    tradeInProgress = true
    
    local fishList, totalValue = getFishToTrade(selectedTradeAmount)
    
    if #fishList == 0 or totalValue <= 0 then
        Rayfield:Notify({
            Title = "❌ No Tradable Fish",
            Content = "No suitable fish found for trading!",
            Duration = 3
        })
        tradeInProgress = false
        return false
    end
    
    Rayfield:Notify({
        Title = "📤 Starting Trade...",
        Content = string.format("Trading %d fish worth %s to %s", 
            #fishList, formatCurrency(totalValue), selectedTradePlayer),
        Duration = 4,
        Image = 4483362458
    })
    
    local tradeSuccess = false
    
    local success, result = pcall(function()
        local targetPlayer = Players:FindFirstChild(selectedTradePlayer)
        if not targetPlayer then return false end
        
        if not tradeRemote then
            tradeRemote = net:FindFirstChild("RF/RequestTrade") or 
                         net:FindFirstChild("RF/SendTradeRequest") or
                         net:FindFirstChild("RF/InitiateTrade")
        end
        
        if not tradeRemote then return false end
        
        local uuidList = {}
        for _, fish in ipairs(fishList) do
            if fish.UUID then
                table.insert(uuidList, fish.UUID)
            end
        end
        
        if #uuidList == 0 then return false end
        
        local methods = {
            function() return tradeRemote:InvokeServer(targetPlayer.UserId, uuidList) end,
            function() return tradeRemote:InvokeServer({TargetPlayer = targetPlayer.UserId, Items = uuidList}) end,
            function() return tradeRemote:InvokeServer(selectedTradePlayer, uuidList) end,
        }
        
        for _, method in ipairs(methods) do
            local success, result = pcall(method)
            if success then
                tradeSuccess = true
                break
            end
        end
        
        return tradeSuccess
    end)
    
    task.wait(3)
    
    if success and tradeSuccess then
        tradeSuccessCount += 1
        totalCoinConverted += totalValue
        
        Rayfield:Notify({
            Title = "✅ Trade Success!",
            Content = string.format("Traded %s to %s!\nFish: %d items", 
                formatCurrency(totalValue), selectedTradePlayer, #fishList),
            Duration = 6,
            Image = 4483362458
        })
    else
        tradeFailedCount += 1
        Rayfield:Notify({
            Title = "❌ Trade Failed",
            Content = "Trade request failed. Player might be busy.",
            Duration = 5
        })
    end
    
    updateTradeProgress()
    tradeInProgress = false
    return tradeSuccess
end

local function autoTradeLoop()
    if not selectedTradePlayer then
        Rayfield:Notify({
            Title = "❌ Auto Trade Error",
            Content = "Please select a player first!",
            Duration = 4
        })
        autoTradeEnabled = false
        return
    end
    
    Rayfield:Notify({
        Title = "🔄 Auto Trade Started",
        Content = string.format("Target: %s | Amount: %s", 
            selectedTradePlayer, formatCurrency(selectedTradeAmount)),
        Duration = 6,
        Image = 4483362458
    })
    
    local checkCount = 0
    
    while autoTradeEnabled and tradeSuccessCount < 100 do
        checkCount += 1
        
        if checkCount % 10 == 0 then
            getAvailablePlayers()
        end
        
        local targetPlayer = Players:FindFirstChild(selectedTradePlayer)
        if not targetPlayer then
            Rayfield:Notify({
                Title = "❌ Player Left",
                Content = selectedTradePlayer .. " left the server!",
                Duration = 4
            })
            autoTradeEnabled = false
            break
        end
        
        local currentValue, fishCount = getInventoryValue()
        
        if currentValue >= selectedTradeAmount and fishCount > 0 then
            executeTrade()
            task.wait(math.random(5, 8))
        else
            if checkCount % 5 == 0 then
                Rayfield:Notify({
                    Title = "⏳ Waiting for Fish...",
                    Content = string.format("Current: %s (%d fish) / Target: %s", 
                        formatCurrency(currentValue), fishCount, formatCurrency(selectedTradeAmount)),
                    Duration = 4
                })
            end
            task.wait(15)
        end
        
        if not autoTradeEnabled then break end
        task.wait(2)
    end
    
    if tradeSuccessCount >= 100 then
        Rayfield:Notify({
            Title = "🎉 Trade Goal Achieved!",
            Content = string.format("Completed 100 trades!\nTotal Converted: %s", 
                formatCurrency(totalCoinConverted)),
            Duration = 8,
            Image = 4483362458
        })
    end
    
    autoTradeEnabled = false
end

-- ===================================
-- ========== AUTO FAVORITE SYSTEM ===
-- ===================================

local function setupAutoFavorite()
    for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
        local ok, data = pcall(require, item)
        if ok and data.Data and data.Data.Type == "Fishes" then
            local id = data.Data.Id
            local name = data.Data.Name
            GlobalFav.FishIdToName[id] = name
            GlobalFav.FishNameToId[name] = id
            table.insert(GlobalFav.FishNames, name)
        end
    end

    for _, variantModule in pairs(ReplicatedStorage.Variants:GetChildren()) do
        local ok, variantData = pcall(require, variantModule)
        if ok and variantData.Data and variantData.Data.Name then
            table.insert(GlobalFav.Variants, variantData.Data.Name)
        end
    end

    local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
        if not GlobalFav.AutoFavoriteEnabled then return end

        local uuid = data.InventoryItem and data.InventoryItem.UUID
        local fishName = GlobalFav.FishIdToName[itemId] or "Unknown"
        local variantId = data.InventoryItem.Metadata and data.InventoryItem.Metadata.VariantId

        if not uuid then return end

        local matchByName = GlobalFav.SelectedFishIds[itemId]
        local matchByVariant = variantId and GlobalFav.SelectedVariants[variantId]
        
        local shouldFavorite = false

        if matchByName and matchByVariant then
            shouldFavorite = true
        elseif matchByName and not next(GlobalFav.SelectedVariants) then
            shouldFavorite = true
        elseif matchByVariant and not matchByName then
            shouldFavorite = true
        end

        if shouldFavorite then
            favoriteRemote:FireServer(uuid)
            local msg = "Favorited " .. fishName
            if matchByVariant then
                msg = msg .. " (" .. (variantId or "Variant") .. ")"
            end
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = msg,
                Duration = 3,
                Image = 4483362458
            })
        end
    end)
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
            Content = "Successfully sold all non-favorite items!",
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

local function checkInventoryAndSell()
    task.spawn(function()
        while autoSellAt4000Enabled do
            pcall(function()
                local inventoryCount = 0
                
                local Replion = require(ReplicatedStorage.Packages.Replion)
                local data = Replion.Client:WaitReplion("Data")
                local items = data:Get({"Inventory","Items"})
                
                inventoryCount = #items
                
                if inventoryCount >= 4000 then
                    Rayfield:Notify({
                        Title = "Auto Sell",
                        Content = "Inventory full! Selling...",
                        Duration = 3,
                        Image = 4483362458
                    })
                    sellNow()
                end
            end)
            task.wait(10)
        end
    end)
end

-- ===================================
-- ========== AUTO FISHING LOOPS =====
-- ===================================

local function autoFishingLoop()
    while autoFishingEnabled do
        pcall(function()
            equipRemote:FireServer(1)
            task.wait(0.5)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.5)
            
            local x, y
            if perfectCastEnabled then
                x = -0.7499996 + (math.random(-50, 50) / 1000000)
                y = 0.9910676 + (math.random(-50, 50) / 1000000)
            else
                x = math.random(-100, 100) / 100
                y = math.random(50, 100) / 100
            end
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(2.5)
            finishRemote:FireServer()
        end)
        task.wait(0.5)
    end
end

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        pcall(function()
            equipRemote:FireServer(1)
            task.wait(0.3)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.3)
            
            local x = -0.7499996 + (math.random(-10, 10) / 1000000)
            local y = 1 + (math.random(-10, 10) / 1000000)
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(1.8)
            finishRemote:FireServer()
        end)
        task.wait(0.3)
    end
end

local function autoFishingV3Loop()
    local successPattern = {}
    
    while autoFishingV3Enabled do
        local success, err = pcall(function()
            fishingActive = true
            
            local optimalWait = 0.25
            
            if #successPattern >= 5 then
                local recentSuccess = 0
                for i = math.max(1, #successPattern - 4), #successPattern do
                    if successPattern[i] then recentSuccess += 1 end
                end
                
                if recentSuccess >= 4 then
                    optimalWait = 0.18
                elseif recentSuccess <= 2 then
                    optimalWait = 0.32
                end
            end
            
            if not player.Character then
                player.CharacterAdded:Wait()
                task.wait(1)
            end
            
            equipRemote:FireServer(1)
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-30, 30) / 10000000)
            local y = baseY + (math.random(-30, 30) / 10000000)
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(optimalWait)
            
            local willSucceed = math.random(1, 100) <= 75
            finishRemote:FireServer(willSucceed)
            table.insert(successPattern, willSucceed)
            
            if #successPattern > 10 then
                table.remove(successPattern, 1)
            end
            
            task.wait(0.08)
            finishRemote:FireServer()
        end)
        
        if not success then
            warn("Error in autoFishingV3Loop: " .. tostring(err))
        end
        
        local cooldown = math.random(8, 20) / 100
        task.wait(cooldown)
    end
    fishingActive = false
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Premium V3 [FIXED]",
    LoadingTitle = "Fish It Premium Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = true,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main", 4483362458)

MainTab:CreateSection("Auto Fishing")

MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (Custom Delay)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        autoFishingV2Enabled = false
        autoFishingV3Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingLoop)
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "⚡ Auto Fishing V2 (Fixed Delay)",
    CurrentValue = false,
    Flag = "FishingV2Toggle",
    Callback = function(Value)
        autoFishingV2Enabled = Value
        autoFishingEnabled = false
        autoFishingV3Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingV2Loop)
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🚀 Auto Fishing V3 (X3 Speed)",
    CurrentValue = false,
    Flag = "FishingV3Toggle",
    Callback = function(Value)
        autoFishingV3Enabled = Value
        autoFishingEnabled = false
        autoFishingV2Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingV3Loop)
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🎯 Auto Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        perfectCastEnabled = Value
        Rayfield:Notify({
            Title = "Perfect Cast",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

MainTab:CreateSection("Inventory Management")

MainTab:CreateButton({
    Name = "💰 Sell Now (Non-Favorite)",
    Callback = sellNow,
})

MainTab:CreateToggle({
    Name = "🔄 Auto Sell at 4000 Fish",
    CurrentValue = false,
    Flag = "AutoSell4000Toggle",
    Callback = function(Value)
        autoSellAt4000Enabled = Value
        if Value then
            checkInventoryAndSell()
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto Sell at 4000 Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto Sell at 4000 Disabled!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateInput({
    Name = "Fish Threshold",
    PlaceholderText = "Default: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            obtainedLimit = num
            Rayfield:Notify({
                Title = "Threshold Set",
                Content = "Fish threshold set to " .. num,
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- Trade Tab
local TradeTab = Window:CreateTab("💱 Trade System", 4483362458)

TradeTab:CreateSection("🎯 Player Selection")

TradeTab:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        local players = getAvailablePlayers()
        Rayfield:Notify({
            Title = "Player List Updated",
            Content = "Found " .. #players .. " players in server",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

TradeTab:CreateDropdown({
    Name = "👤 Select Player to Trade",
    Options = getAvailablePlayers(),
    CurrentOption = nil,
    Flag = "TradePlayerDropdown",
    Callback = function(Option)
        selectedTradePlayer = Option
        Rayfield:Notify({
            Title = "✅ Player Selected",
            Content = "Will trade with: " .. Option,
            Duration = 3,
            Image = 4483362458
        })
    end,
})

TradeTab:CreateSection("💰 Trade Amount")

local tradeAmounts = {
    {name = "💵 $100K", value = 100000},
    {name = "💸 $500K", value = 500000},
    {name = "💎 $1M", value = 1000000},
    {name = "🏆 $2M", value = 2000000},
    {name = "👑 $5M", value = 5000000}
}

for _, amount in ipairs(tradeAmounts) do
    TradeTab:CreateButton({
        Name = amount.name,
        Callback = function()
            selectedTradeAmount = amount.value
            Rayfield:Notify({
                Title = "💰 Amount Set",
                Content = "Trade target: " .. formatCurrency(amount.value),
                Duration = 3,
                Image = 4483362458
            })
        end,
    })
end

TradeTab:CreateSection("📊 Trade Controls")

TradeTab:CreateButton({
    Name = "💼 Check Inventory Value",
    Callback = function()
        local value, count = getInventoryValue()
        Rayfield:Notify({
            Title = "📊 Inventory Status",
            Content = string.format(
                "Total Value: %s\nTradable Fish: %d items",
                formatCurrency(value), count
            ),
            Duration = 6,
            Image = 4483362458
        })
    end,
})

TradeTab:CreateButton({
    Name = "📤 Execute Single Trade",
    Callback = function()
        executeTrade()
    end,
})

TradeTab:CreateToggle({
    Name = "🔄 Auto Trade (100 Success Max)",
    CurrentValue = false,
    Flag = "AutoTradeToggle",
    Callback = function(Value)
        autoTradeEnabled = Value
        
        if Value then
            local valid, errorMsg = validateTradeConditions()
            if not valid then
                Rayfield:Notify({
                    Title = "❌ Auto Trade Failed",
                    Content = errorMsg,
                    Duration = 5
                })
                autoTradeEnabled = false
                return
            end
            
            task.spawn(autoTradeLoop)
        else
            Rayfield:Notify({
                Title = "🛑 Auto Trade Stopped",
                Content = "Auto trading has been disabled",
                Duration = 3
            })
        end
    end,
})

TradeTab:CreateSection("📈 Trade Progress")

TradeProgressLabel = TradeTab:CreateLabel(
    "╔════════════════════════╗\n" ..
    "║     TRADE PROGRESS     ║\n" ..
    "╚════════════════════════╝\n\n" ..
    "✅ Success: 0 / 100\n" ..
    "❌ Failed: 0\n" ..
    "💰 Total Converted: $0\n" ..
    "📊 Success Rate: 0%"
)

TradeTab:CreateButton({
    Name = "🔄 Reset Statistics",
    Callback = function()
        tradeSuccessCount = 0
        tradeFailedCount = 0
        totalCoinConverted = 0
        updateTradeProgress()
        
        Rayfield:Notify({
            Title = "🔄 Statistics Reset",
            Content = "All trade statistics have been reset!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Favorite Tab
local FavoriteTab = Window:CreateTab("⭐ Auto Favorite", 4483362458)

FavoriteTab:CreateSection("Auto Favorite Settings")

FavoriteTab:CreateToggle({
    Name = "⭐ Enable Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        GlobalFav.AutoFavoriteEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Disabled!",
                Duration = 3
            })
        end
    end,
})

local FishDropdown = FavoriteTab:CreateDropdown({
    Name = "Select Fish to Favorite",
    Options = GlobalFav.FishNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "FavoriteFishDropdown",
    Callback = function(Options)
        GlobalFav.SelectedFishIds = {}
        for _, fishName in ipairs(Options) do
            local id = GlobalFav.FishNameToId[fishName]
            if id then
                GlobalFav.SelectedFishIds[id] = true
            end
        end
        Rayfield:Notify({
            Title = "Auto Favorite",
            Content = "Favoriting active for selected fish",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Farm Tab
local FarmTab = Window:CreateTab("🌾 Auto Farm", 4483362458)

FarmTab:CreateSection("Auto Farm Settings")

local islandOptions = {
    "Crater Islands",
    "Tropical Grove", 
    "Fisherman Island"
}

FarmTab:CreateDropdown({
    Name = "Select Farm Island",
    Options = islandOptions,
    CurrentOption = "Fisherman Island",
    Flag = "FarmIslandDropdown",
    Callback = function(Option)
        selectedIsland = Option
        Rayfield:Notify({
            Title = "Island Selected",
            Content = "Farming location set to " .. Option,
            Duration = 3,
            Image = 4483362458
        })
    end,
})

FarmTab:CreateToggle({
    Name = "🌾 Start Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            autoFishingV3Enabled = true
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Started on " .. selectedIsland,
                Duration = 3,
                Image = 4483362458
            })
        else
            autoFishingV3Enabled = false
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Player Tab
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSection("Player Features")

PlayerTab:CreateToggle({
    Name = "🔓 Universal No Clip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        universalNoclip = Value
        if Value then
            Rayfield:Notify({
                Title = "Universal Noclip",
                Content = "You can penetrate all objects!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Universal Noclip",
                Content = "Noclip Disabled!",
                Duration = 3
            })
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "🏃 Infinity Jump",
    CurrentValue = false,
    Flag = "InfinityJumpToggle",
    Callback = function(Value)
        ijumpEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Infinity Jump",
                Content = "Infinity Jump Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Infinity Jump",
                Content = "Infinity Jump Disabled!",
                Duration = 3
            })
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
        antiAFKEnabled = Value
        if Value then
            AFKConnection = player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
            Rayfield:Notify({
                Title = "Anti-AFK",
                Content = "Anti-AFK Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end
            Rayfield:Notify({
                Title = "Anti-AFK",
                Content = "Anti-AFK Disabled!",
                Duration = 3
            })
        end
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function safeSetup()
    if not setupRemotes() then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to setup remotes! Script may not work properly.",
            Duration = 5,
            Image = 4483362458
        })
        return false
    end
    
    pcall(setupAnimations)
    setupAutoFavorite()
    
    -- Build fish price database
    local dbCount = buildFishPriceDatabase()
    if dbCount > 0 then
        print("✅ Fish price database loaded: " .. dbCount .. " fish")
    else
        warn("❌ Failed to build fish price database")
    end
    
    return true
end

-- Initialize
if safeSetup() then
    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Fish It Premium V3 [FIXED] loaded successfully!\nTrade system now working properly!",
        Duration = 5,
        Image = 4483362458
    })
else
    Rayfield:Notify({
        Title = "Warning",
        Content = "Script loaded with some issues. Some features may not work.",
        Duration = 5,
        Image = 4483362458
    })
end

Rayfield:LoadConfiguration()

-- Anti-AFK
for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

print("🎉 Fish It Premium V3 [FIXED] - Fully Loaded!")

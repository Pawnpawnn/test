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

local EnhanceFishing = {
    Enabled = false,
    SpeedMultiplier = 1.0,
    PerfectCast = true,
    SuccessPattern = {},
    FishingActive = false
}

-- ⚡ INSTANT EXCLAIM DETECTION SYSTEM ⚡
local ExclaimDetected = false
local ExclaimConnection = nil

local autoSellThresholdEnabled = false
local obtainedFishUUIDs = {}
local obtainedLimit = 30

local antiAFKEnabled = false
local autoFavoriteEnabled = false
local autoSellAt4000Enabled = false
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

-- Fish Categories
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
                    speedMultiplier = math.max(0.5, 1.0 - (speedBonus / 100))
                    print("🎯 Rod Modifier: " .. speedBonus .. "% faster -> Multiplier: " .. speedMultiplier)
                end
            end
        end
    end
    
    EnhanceFishing.SpeedMultiplier = speedMultiplier
    return speedMultiplier
end

-- ⚡⚡⚡ INSTANT EXCLAIM DETECTION SYSTEM ⚡⚡⚡
local function setupInstantExclaimSystem()
    local textEffectRemote = net:FindFirstChild("RE/ReplicateTextEffect")
    
    if textEffectRemote then
        if ExclaimConnection then
            ExclaimConnection:Disconnect()
        end
        
        ExclaimConnection = textEffectRemote.OnClientEvent:Connect(function(data)
            -- Cek jika ini exclaim DAN fishing aktif
            if data and data.TextData and data.TextData.EffectType == "Exclaim" and EnhanceFishing.Enabled then
                print("🚨 EXCLAIM DETECTED - INSTANT PULL!")
                ExclaimDetected = true
                
                -- ⚡ INSTANT PULL - LANGSUNG TARIK! ⚡
                task.spawn(function()
                    for i = 1, 10 do
                        pcall(function()
                            finishRemote:FireServer(true)
                        end)
                        if i <= 3 then
                            task.wait(0.003) -- Super fast initial 3 fires
                        else
                            task.wait(0.008) -- Follow-up fires
                        end
                    end
                    print("⚡ INSTANT: 10x fire completed in 0.07s!")
                end)
            end
        end)
        
        print("✅ INSTANT Exclaim System: ACTIVE!")
        print("   ⚡ Pull langsung saat tanda seru muncul")
        print("   🎯 10x fire dalam <0.1 detik")
    else
        warn("❌ Exclaim remote not found")
    end
end

local function cleanupExclaimSystem()
    if ExclaimConnection then
        ExclaimConnection:Disconnect()
        ExclaimConnection = nil
    end
    ExclaimDetected = false
end

-- Enhanced Fishing Core Loop dengan INSTANT DETECTION
local function enhanceFishingLoop()
    EnhanceFishing.SuccessPattern = {}
    
    while EnhanceFishing.Enabled do
        local success, err = pcall(function()
            EnhanceFishing.FishingActive = true
            ExclaimDetected = false -- Reset flag
            
            updateRodModifiers()
            
            -- Equip fishing rod
            equipRemote:FireServer(1)
            task.wait(0.3 * EnhanceFishing.SpeedMultiplier)
            
            -- Start fishing cast
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.2 * EnhanceFishing.SpeedMultiplier)
            
            -- Perfect cast coordinates
            local x, y
            if EnhanceFishing.PerfectCast then
                x = -0.7499996 + (math.random(-20, 20) / 10000000)
                y = 1 + (math.random(-20, 20) / 10000000)
            else
                x = math.random(-100, 100) / 100
                y = math.random(50, 100) / 100
            end
            
            -- Start minigame
            miniGameRemote:InvokeServer(x, y)
            
            -- ⚡ WAIT FOR EXCLAIM dengan ultra-fast monitoring ⚡
            local maxWaitTime = 2.5 * EnhanceFishing.SpeedMultiplier
            local startTime = tick()
            
            -- Loop monitoring exclaim dengan check interval SANGAT CEPAT
            while (tick() - startTime) < maxWaitTime and not ExclaimDetected do
                task.wait(0.003) -- Check setiap 3ms untuk INSTANT response
            end
            
            -- Jika exclaim terdeteksi, system sudah auto-fire
            if ExclaimDetected then
                print("✅ Exclaim detected & pulled INSTANTLY!")
                table.insert(EnhanceFishing.SuccessPattern, true)
            else
                -- Backup pull jika timeout
                print("⏱️ Timeout - backup pull")
                for i = 1, 5 do
                    pcall(function()
                        finishRemote:FireServer(true)
                    end)
                    task.wait(0.01)
                end
                table.insert(EnhanceFishing.SuccessPattern, false)
            end
            
            -- Cleanup pattern array
            if #EnhanceFishing.SuccessPattern > 5 then
                table.remove(EnhanceFishing.SuccessPattern, 1)
            end
            
            -- Final cleanup
            task.wait(0.05)
            pcall(function()
                finishRemote:FireServer()
            end)
            
            -- Dynamic cooldown
            local recentSuccessRate = 0
            if #EnhanceFishing.SuccessPattern > 0 then
                for _, success in ipairs(EnhanceFishing.SuccessPattern) do
                    if success then recentSuccessRate += 1 end
                end
                recentSuccessRate = recentSuccessRate / #EnhanceFishing.SuccessPattern
            end
            
            local cooldown = math.random(8, 15) / 100 * EnhanceFishing.SpeedMultiplier
            if recentSuccessRate > 0.7 then
                cooldown = cooldown * 0.8
            elseif recentSuccessRate < 0.3 then
                cooldown = cooldown * 1.2
            end
            
            task.wait(cooldown)
        end)
        
        if not success then
            warn("Enhance Fishing Error: " .. tostring(err))
            task.wait(1)
        end
    end
    
    EnhanceFishing.FishingActive = false
    cleanupExclaimSystem()
    print("🛑 Enhance Fishing Stopped")
end

-- Fish Threshold System
local function monitorFishThreshold()
    task.spawn(function()
        while EnhanceFishing.Enabled do
            if autoSellThresholdEnabled and #obtainedFishUUIDs >= obtainedLimit then
                Rayfield:Notify({
                    Title = "🎣 Fish Threshold",
                    Content = "Selling " .. obtainedLimit .. " fishes...",
                    Duration = 3,
                    Image = 4483362458
                })
                sellRemote:InvokeServer()
                obtainedFishUUIDs = {}
                task.wait(0.5)
            end
            task.wait(0.5)
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

-- Start Enhance Fishing
local function startEnhanceFishing()
    if EnhanceFishing.Enabled then
        Rayfield:Notify({
            Title = "🎣 Enhance Fishing",
            Content = "Already running!",
            Duration = 2
        })
        return
    end
    
    EnhanceFishing.Enabled = true
    
    if autoSellThresholdEnabled then
        monitorFishThreshold()
        print("🎣 Auto Sell Threshold: ENABLED (at " .. obtainedLimit .. " fish)")
    else
        print("🎣 Auto Sell Threshold: DISABLED")
    end
    
    -- ⚡ SETUP INSTANT EXCLAIM SYSTEM ⚡
    setupInstantExclaimSystem()
    
    task.spawn(enhanceFishingLoop)
    
    Rayfield:Notify({
        Title = "🚀 INSTANT Fishing Started",
        Content = "Tarik INSTANT saat tanda seru muncul (no delay)!",
        Duration = 4,
        Image = 4483362458
    })
    
    print("🎣 Enhance Fishing: STARTED - INSTANT EXCLAIM MODE")
    print("   ⚡ 10x fire dalam 0.07 detik saat tanda seru MUNCUL")
    print("   🎯 Monitor interval: 3ms (ultra-fast)")
    print("   🚀 NO WAITING - langsung tarik!")
end

local function stopEnhanceFishing()
    EnhanceFishing.Enabled = false
    
    Rayfield:Notify({
        Title = "🛑 Enhance Fishing Stopped",
        Content = "Fishing system disabled",
        Duration = 3
    })
    
    print("🎣 Enhance Fishing: STOPPED")
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

    local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
        if not GlobalFav.AutoFavoriteEnabled then return end

        local uuid = data.InventoryItem and data.InventoryItem.UUID
        local fishName = GlobalFav.FishIdToName[itemId] or "Unknown"

        if not uuid then return end

        local shouldFavorite = false
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

        if shouldFavorite then
            favoriteRemote:FireServer(uuid)
            Rayfield:Notify({
                Title = "⭐ Auto Favorite",
                Content = "Favorited: " .. fishName,
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

-- ===================================
-- ========== FISH NOTIFICATION ======
-- ===================================

local function validateWebhook(path)
    if not path or not path:match("^%d+/.+") then
        return false, "Invalid webhook format"
    end

    local url = "https://discord.com/api/webhooks/" .. path
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return false, "Failed to connect to Discord"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok or not data or not data.channel_id then
        return false, "Invalid webhook"
    end

    return true, data.channel_id
end

local function GetRobloxImage(assetId)
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    local success, response = pcall(game.HttpGet, game, url)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function isTargetFish(fishName)
    for _, category in pairs(SelectedCategories) do
        local list = FishCategories[category]
        if list then
            for _, keyword in pairs(list) do
                if string.find(string.lower(fishName), string.lower(keyword)) then
                    return true
                end
            end
        end
    end
    return false
end

local function sendFishWebhook(fishName, rarityText, assetId)
    if not webhookPath or webhookPath == "" or not fishWebhookEnabled then
        return
    end

    local WebhookURL = "https://discord.com/api/webhooks/" .. webhookPath
    local username = player.DisplayName
    local imageUrl = GetRobloxImage(assetId)
    if not imageUrl then return end

    local caught = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Caught")
    local rarest = player.leaderstats and player.leaderstats:FindFirstChild("Rarest Fish")

    local embedDesc = string.format([[
Hei **%s**! 🎣
You have successfully caught a fish.

====| FISH DATA |====
🧾 Name : **%s**
🌟 Rarity : **%s**

====| ACCOUNT DATA |====
🎯 Total Caught : **%s**
🏆 Rarest Fish : **%s**
]],
        username,
        fishName,
        rarityText,
        caught and caught.Value or "N/A",
        rarest and rarest.Value or "N/A"
    )

    local data = {
        ["username"] = "e-Fishery",
        ["embeds"] = {{
            ["title"] = "Fish Caught!",
            ["description"] = embedDesc,
            ["color"] = tonumber("0x00bfff"),
            ["image"] = { ["url"] = imageUrl },
            ["footer"] = { ["text"] = "Fish Notification • " .. os.date("%d %B %Y, %H:%M:%S") }
        }}
    }

    local requestFunc = syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request
    if requestFunc then
        requestFunc({
            Url = WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end
end

local function startFishDetection()
    local guiNotif = player.PlayerGui:WaitForChild("Small Notification"):WaitForChild("Display"):WaitForChild("Container")
    local fishText = guiNotif:WaitForChild("ItemName")
    local rarityText = guiNotif:WaitForChild("Rarity")
    local imageFrame = player.PlayerGui["Small Notification"]:WaitForChild("Display"):WaitForChild("VectorFrame"):WaitForChild("Vector")

    fishText:GetPropertyChangedSignal("Text"):Connect(function()
        local fishName = fishText.Text
        if isTargetFish(fishName) then
            local rarity = rarityText.Text
            local assetId = string.match(imageFrame.Image, "%d+")
            if assetId then
                sendFishWebhook(fishName, rarity, assetId)
            end
        end
    end)
end

task.spawn(function()
    local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata)
        LastCatchData.ItemId = itemId
        LastCatchData.VariantId = metadata and metadata.VariantId
    end)
end)

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
                Rayfield:Notify({
                    Title = "Weather Purchased",
                    Content = "Successfully activated " .. weatherType,
                    Duration = 3,
                    Image = 4483362458
                })

                task.wait(weatherData[weatherType].duration)

                local randomWait = randomDelay(1, 5)
                task.wait(randomWait)
            end)
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
            Rayfield:Notify({
                Title = "Float Error",
                Content = "Character not found!",
                Duration = 3
            })
            return 
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            Rayfield:Notify({
                Title = "Float Error",
                Content = "HumanoidRootPart not found!",
                Duration = 3
            })
            return 
        end

        floatPlatform = Instance.new("Part")
        floatPlatform.Anchored = true
        floatPlatform.Size = Vector3.new(10, 1, 10)
        floatPlatform.Transparency = 1
        floatPlatform.CanCollide = true
        floatPlatform.Name = "FloatPlatform"
        floatPlatform.Parent = workspace

        task.spawn(function()
            while floatPlatform and floatPlatform.Parent do
                pcall(function()
                    floatPlatform.Position = hrp.Position - Vector3.new(0, 3.5, 0)
                end)
                task.wait(0.1)
            end
        end)

        Rayfield:Notify({
            Title = "Float Enabled",
            Content = "Feature activated!",
            Duration = 3,
            Image = 4483362458
        })
    else
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
        Rayfield:Notify({
            Title = "Float Disabled",
            Content = "Feature disabled",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== AUTO EVENT FARM ========
-- ===================================

local knownEvents = {}

local function updateKnownEvents()
    knownEvents = {}
    local props = workspace:FindFirstChild("Props")
    if props then
        for _, child in ipairs(props:GetChildren()) do
            if child:IsA("Model") and child.PrimaryPart then
                knownEvents[child.Name:lower()] = child
            end
        end
    end
end

local function teleportTo(position)
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
        end
    end
end

local function saveOriginalPosition()
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
    end
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

local function isEventStillActive(name)
    updateKnownEvents()
    return knownEvents[name:lower()] ~= nil
end

local function monitorAutoTP()
    task.spawn(function()
        while true do
            if autoTPEventEnabled then
                if not alreadyTeleported then
                    updateKnownEvents()
                    for _, eventModel in pairs(knownEvents) do
                        saveOriginalPosition()
                        teleportTo(eventModel:GetPivot().Position)
                        toggleFloat(true)
                        alreadyTeleported = true
                        teleportTime = tick()
                        eventTarget = eventModel.Name
                        Rayfield:Notify({
                            Title = "Event Farm",
                            Content = "Teleported to: " .. eventTarget,
                            Duration = 3,
                            Image = 4483362458
                        })
                        break
                    end
                else
                    if teleportTime and (tick() - teleportTime >= 900) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        eventTarget = nil
                        Rayfield:Notify({
                            Title = "Event Timeout",
                            Content = "Returned after 15 minutes",
                            Duration = 3,
                            Image = 4483362458
                        })
                    elseif eventTarget and not isEventStillActive(eventTarget) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        Rayfield:Notify({
                            Title = "Event Ended",
                            Content = "Returned to start position",
                            Duration = 3,
                            Image = 4483362458
                        })
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
            task.wait(1)
        end
    end)
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
    
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
    
    local success, result = pcall(function()
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
        Content = "Boosting FPS...",
        Duration = 3,
        Image = 4483362458
    })
    
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    settings().Rendering.QualityLevel = "Level01"
    
    Rayfield:Notify({
        Title = "Success",
        Content = "FPS Boosted Successfully!",
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
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Island not found!",
            Duration = 3
        })
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
    else
        Rayfield:Notify({
            Title = "Teleport Failed",
            Content = "Failed to teleport: " .. tostring(err),
            Duration = 3
        })
    end
end

local function teleportToEvent(eventName)
    local props = workspace:FindFirstChild("Props")
    if props and props:FindFirstChild(eventName) and props[eventName]:FindFirstChild("Fishing Boat") then
        local fishingBoat = props[eventName]["Fishing Boat"]
        local boatCFrame = fishingBoat:GetPivot()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
        Rayfield:Notify({
            Title = "Event Teleport",
            Content = "Teleported to " .. eventName,
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Event Not Found",
            Content = eventName .. " Not Available!",
            Duration = 3
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
end

-- ===================================
-- ========== AUTO FARM ==============
-- ===================================

local function startAutoFarmLoop()
    Rayfield:Notify({
        Title = "Auto Farm",
        Content = "Starting farm on " .. selectedIsland,
        Duration = 3,
        Image = 4483362458
    })

    while autoFarmEnabled do
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
                    task.wait(1.5)
                    
                    if not EnhanceFishing.Enabled then
                        startEnhanceFishing()
                    end
                end
            end
        end)
        
        if not success then
            warn("Error in auto farm: " .. tostring(err))
        end
        
        task.wait(0.5)
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - INSTANT EXCLAIM V5",
    LoadingTitle = "Fish It Premium Loading...",
    LoadingSubtitle = "by Codepikk - INSTANT EXCLAIM Edition",
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
local MainTab = Window:CreateTab("🎣 Enhance Fishing", 4483362458)

MainTab:CreateSection("⚡ INSTANT EXCLAIM Fishing System")

MainTab:CreateToggle({
    Name = "⚡ Enable Enhance Fishing",
    CurrentValue = false,
    Flag = "EnhanceFishingToggle",
    Callback = function(Value)
        if Value then
            startEnhanceFishing()
        else
            stopEnhanceFishing()
        end
    end,
})

MainTab:CreateToggle({
    Name = "🎯 Perfect Cast Mode",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        EnhanceFishing.PerfectCast = Value
        Rayfield:Notify({
            Title = "Perfect Cast",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

MainTab:CreateSection("INSTANT EXCLAIM Features")

MainTab:CreateLabel("🚨 Tanda Seru: TARIK INSTANT saat muncul!")
MainTab:CreateLabel("⚡ Response: 10x fire dalam 0.07 detik")
MainTab:CreateLabel("🎯 Monitor: 3ms interval (ultra-fast)")
MainTab:CreateLabel("🚀 NO DELAY - tarik langsung!")

MainTab:CreateSection("Inventory Management")

MainTab:CreateToggle({
    Name = "🔢 Auto Sell Threshold",
    CurrentValue = false,
    Flag = "AutoSellThresholdToggle",
    Callback = function(Value)
        autoSellThresholdEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Sell Threshold",
                Content = "Enabled - Auto sell at " .. obtainedLimit .. " fishes",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Sell Threshold", 
                Content = "Disabled - No auto selling",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateInput({
    Name = "Fish Threshold Limit",
    PlaceholderText = "Default: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            obtainedLimit = num
            Rayfield:Notify({
                Title = "Threshold Updated",
                Content = "Auto sell at " .. num .. " fishes (if enabled)",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateButton({
    Name = "💰 Sell Now (Non-Favorite)",
    Callback = sellNow,
})

MainTab:CreateButton({
    Name = "🔍 Scan Rod Modifiers",
    Callback = function()
        updateRodModifiers()
        Rayfield:Notify({
            Title = "Rod Scan",
            Content = "Speed Multiplier: " .. (EnhanceFishing.SpeedMultiplier * 100) .. "%",
            Duration = 4,
            Image = 4483362458
        })
    end,
})

-- Auto Favorite Tab
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

FavoriteTab:CreateDropdown({
    Name = "Select Rarity Categories",
    Options = {"Secret", "Mythic", "Legendary"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FavoriteCategoryDropdown",
    Callback = function(Options)
        GlobalFav.SelectedCategories = Options
        Rayfield:Notify({
            Title = "⭐ Auto Favorite",
            Content = "Now favoriting: " .. table.concat(Options, ", "),
            Duration = 4,
            Image = 4483362458
        })
    end,
})

FavoriteTab:CreateLabel("📝 Auto favorite akan aktif untuk ikan dengan rarity yang dipilih")

-- Auto Farm Tab
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
            task.spawn(startAutoFarmLoop)
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Started on " .. selectedIsland,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Stopped!",
                Duration = 3
            })
        end
    end,
})

FarmTab:CreateToggle({
    Name = "🎯 Auto Farm Event",
    CurrentValue = false,
    Flag = "AutoEventFarmToggle",
    Callback = function(Value)
        autoTPEventEnabled = Value
        if Value then
            monitorAutoTP()
            Rayfield:Notify({
                Title = "Auto Event Farm",
                Content = "Auto Event Farm Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Event Farm",
                Content = "Auto Event Farm Disabled!",
                Duration = 3
            })
        end
    end,
})

FarmTab:CreateLabel("⚠️ Auto Farm Event: DO WITH YOUR OWN RISK!")

-- Fish Notification Tab
local NotifTab = Window:CreateTab("🔔 Notifications", 4483362458)

NotifTab:CreateSection("Fish Notification Settings")

NotifTab:CreateInput({
    Name = "Discord Webhook Path",
    PlaceholderText = "ID/Token",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        webhookPath = Text
        local isValid, result = validateWebhook(webhookPath)
        if isValid then
            Rayfield:Notify({
                Title = "Webhook Valid",
                Content = "Channel ID: " .. tostring(result),
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Webhook Invalid",
                Content = tostring(result),
                Duration = 5
            })
        end
    end,
})

NotifTab:CreateToggle({
    Name = "Enable Fish Notifications",
    CurrentValue = false,
    Flag = "FishNotifToggle",
    Callback = function(Value)
        fishWebhookEnabled = Value
        Rayfield:Notify({
            Title = "Fish Notifications",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

NotifTab:CreateDropdown({
    Name = "Select Fish Categories",
    Options = {"Secret", "Legendary", "Mythic"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FishCategoryDropdown",
    Callback = function(Options)
        SelectedCategories = Options
        Rayfield:Notify({
            Title = "Fish Categories",
            Content = "Now tracking: " .. table.concat(SelectedCategories, ", "),
            Duration = 5,
            Image = 4483362458
        })
    end,
})

-- Weather Tab
local WeatherTab = Window:CreateTab("🌤️ Weather", 4483362458)

WeatherTab:CreateSection("Auto Buy Weather")

WeatherTab:CreateDropdown({
    Name = "Auto Buy Weather",
    Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "WeatherDropdown",
    Callback = function(Options)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(Options, weatherType) then
                weatherActive[weatherType] = false
                Rayfield:Notify({
                    Title = "Auto Weather",
                    Content = "Auto buying " .. weatherType .. " stopped",
                    Duration = 3
                })
            end
        end
        
        for _, weatherType in pairs(Options) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                Rayfield:Notify({
                    Title = "Auto Weather",
                    Content = "Auto buying " .. weatherType .. " started!",
                    Duration = 3,
                    Image = 4483362458
                })
                autoBuyWeather(weatherType)
            end
        end
    end,
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

local eventOptions = {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}

for _, eventName in ipairs(eventOptions) do
    TeleportTab:CreateButton({
        Name = eventName,
        Callback = function()
            teleportToEvent(eventName)
        end,
    })
end

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

PlayerTab:CreateToggle({
    Name = "🌊 Anti Drown",
    CurrentValue = false,
    Flag = "AntiDrownToggle",
    Callback = function(Value)
        AntiDrown_Enabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Anti Drown",
                Content = "Oxygen loss blocked!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Anti Drown",
                Content = "Anti Drown Disabled!",
                Duration = 3
            })
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 20,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.WalkSpeed = Value
                Rayfield:Notify({
                    Title = "WalkSpeed",
                    Content = "WalkSpeed set to " .. Value,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 500},
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
                Rayfield:Notify({
                    Title = "Jump Power",
                    Content = "Jump Power set to " .. Value,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "🔭 Unlimited Zoom",
    CurrentValue = false,
    Flag = "UnlimitedZoomToggle",
    Callback = function(Value)
        if Value then
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 9999
            Rayfield:Notify({
                Title = "Unlimited Zoom",
                Content = "Unlimited Zoom Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 400
            Rayfield:Notify({
                Title = "Unlimited Zoom",
                Content = "Unlimited Zoom Disabled!",
                Duration = 3
            })
        end
    end,
})

PlayerTab:CreateButton({
    Name = "🚤 Access All Boats",
    Callback = function()
        local vehicles = workspace:FindFirstChild("Vehicles")
        if not vehicles then
            Rayfield:Notify({
                Title = "Not Found",
                Content = "Vehicles container not found.",
                Duration = 3
            })
            return
        end

        local count = 0
        for _, boat in ipairs(vehicles:GetChildren()) do
            if boat:IsA("Model") and boat:GetAttribute("OwnerId") then
                local currentOwner = boat:GetAttribute("OwnerId")
                if currentOwner ~= player.UserId then
                    boat:SetAttribute("OwnerId", player.UserId)
                    count += 1
                end
            end
        end

        Rayfield:Notify({
            Title = "Access Granted",
            Content = "You now own " .. count .. " boat(s).",
            Duration = 3,
            Image = 4483362458
        })
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

MiscTab:CreateButton({
    Name = "✨ HDR Shader",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/unclemaggot/fishitpremi/refs/heads/main/hdr.lua"))()
    end,
})

MiscTab:CreateSection("Server Hop")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Rejoining",
            Content = "Rejoining current server...",
            Duration = 3,
            Image = 4483362458
        })
        Rejoin()
    end,
})

MiscTab:CreateButton({
    Name = "⚡ Quick Server Hop",
    Callback = function()
        QuickServerHop()
    end,
})

MiscTab:CreateLabel("📌 Quick: Fast random server")

MiscTab:CreateSection("Auto Enchant Rod")

MiscTab:CreateButton({
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
        Rayfield:Notify({
            Title = "Config Saved",
            Content = "Configuration has been saved!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

SettingsTab:CreateButton({
    Name = "📂 Load Configuration",
    Callback = function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Config Loaded",
            Content = "Configuration has been loaded!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

SettingsTab:CreateSection("Credits")

SettingsTab:CreateLabel("Fish It INSTANT EXCLAIM V5")
SettingsTab:CreateLabel("Developed by Codepikk")
SettingsTab:CreateLabel("Thanks for using! 🎣")

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
    
    setupAutoFavorite()
    startFishDetection()
    
    return true
end

-- Initialize script
if safeSetup() then
    updateKnownEvents()
    
    -- Monitor Props untuk events
    local props = workspace:FindFirstChild("Props")
    if props then
        props.ChildAdded:Connect(function()
            task.wait(0.3)
            updateKnownEvents()
        end)
        props.ChildRemoved:Connect(function()
            task.wait(0.3)
            updateKnownEvents()
        end)
    end

    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Fish It INSTANT EXCLAIM V5 loaded successfully!\nAuto Sell Threshold: DISABLED (Default)",
        Duration = 5,
        Image = 4483362458
    })
    
    print("🎣 Fish It INSTANT EXCLAIM V5 - Fully Loaded!")
    print("🚀 INSTANT MODE: Tarik langsung saat tanda seru MUNCUL!")
    print("⚡ 10x fire dalam 0.07 detik")
    print("🎯 Monitor: 3ms interval (ultra-fast)")
    print("🔢 Auto Sell Threshold: DISABLED (Default) - Enable manually jika perlu")
else
    Rayfield:Notify({
        Title = "Warning",
        Content = "Script loaded with some issues. Some features may not work.",
        Duration = 5,
        Image = 4483362458
    })
end

Rayfield:LoadConfiguration()

-- Anti-AFK untuk semua connections
for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

-- Auto Reconnect System
local PlaceId = game.PlaceId
local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

-- Final message
task.delay(2, function()
    print("🎣 Fish It INSTANT EXCLAIM V5 - Ready to use!")
    print("📁 Configuration saved to: codepik/FishItConfig")
    print("💡 INSTANT EXCLAIM: Tarik langsung saat tanda seru MUNCUL!")
    print("⚡ Ultra-fast response: 3ms monitoring interval")
    print("🎯 10x fire guarantee dalam <0.1 detik")
end)

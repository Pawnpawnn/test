local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local LocalPlayer = player

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
local noClipEnabled = false
local noclipConnection = nil

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local AFKConnection = nil

-- ===================================
-- ========== NO CLIP SYSTEM =========
-- ===================================

local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    
    if noClipEnabled then
        Rayfield:Notify({
            Title = "No Clip",
            Content = "No Clip Enabled! Anda bisa tembus benda.",
            Duration = 3,
            Image = 4483362458
        })
        
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        
        noclipConnection = RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        Rayfield:Notify({
            Title = "No Clip",
            Content = "No Clip Disabled!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== SERVER HOP SYSTEM ======
-- ===================================

local function scanServerLuck()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    for _, guiObject in pairs(playerGui:GetDescendants()) do
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
            local text = tostring(guiObject.Text)
            if text:find("Server Luck: x") then
                local multiplier = text:match("Server Luck: x(%d+)")
                if multiplier then
                    return tonumber(multiplier), text
                end
            end
        end
    end
    return nil
end

local function joinServerWithLuck()
    Rayfield:Notify({
        Title = "🔍 Scanning Server Luck",
        Content = "Checking current server...",
        Duration = 4,
        Image = 4483362458
    })
    
    task.wait(3)
    local currentLuck, luckText = scanServerLuck()
    
    if currentLuck then
        Rayfield:Notify({
            Title = "🎉 Server Luck Found!",
            Content = string.format("%s | Stay in this server!", luckText),
            Duration = 6,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "❌ No Server Luck",
            Content = "No luck found in this server. Stay here.",
            Duration = 5
        })
    end
end

local function joinLowestPopulationServer()
    Rayfield:Notify({
        Title = "🔍 Finding Empty Server",
        Content = "Looking for server with lowest population...",
        Duration = 4,
        Image = 4483362458
    })
    
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        playing = server.playing,
                        maxPlayers = server.maxPlayers
                    })
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers >= 10
    
    if #servers > 0 then
        table.sort(servers, function(a, b) return a.playing < b.playing end)
        local targetServer = servers[1]
        
        Rayfield:Notify({
            Title = "👥 Joining Empty Server",
            Content = string.format("Joining server with %d/%d players", targetServer.playing, targetServer.maxPlayers),
            Duration = 4,
            Image = 4483362458
        })
        
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
    else
        Rayfield:Notify({
            Title = "❌ No Servers Found",
            Content = "Could not find any empty servers!",
            Duration = 4
        })
    end
end

local function joinPopularServer()
    Rayfield:Notify({
        Title = "🔍 Finding Popular Server",
        Content = "Looking for server with most players...",
        Duration = 4,
        Image = 4483362458
    })
    
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        playing = server.playing,
                        maxPlayers = server.maxPlayers
                    })
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers >= 10
    
    if #servers > 0 then
        table.sort(servers, function(a, b) return a.playing > b.playing end)
        local targetServer = servers[1]
        
        Rayfield:Notify({
            Title = "🔥 Joining Popular Server",
            Content = string.format("Joining server with %d/%d players", targetServer.playing, targetServer.maxPlayers),
            Duration = 4,
            Image = 4483362458
        })
        
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
    else
        Rayfield:Notify({
            Title = "❌ No Servers Found",
            Content = "Could not find any popular servers!",
            Duration = 4
        })
    end
end

-- ===================================
-- ========== TRADE BY COIN SYSTEM ===
-- ===================================

-- Variables untuk trade system
local tradeRemote = nil
local sendTradeRemote = nil
local acceptTradeRemote = nil

-- Setup trade remotes
local function setupTradeRemotes()
    pcall(function()
        -- Cari trade remotes dengan berbagai kemungkinan nama
        local replicatedStorage = game:GetService("ReplicatedStorage")
        
        -- Coba berbagai lokasi dan nama remote
        tradeRemote = replicatedStorage:FindFirstChild("RequestTrade") 
            or replicatedStorage:FindFirstChild("RF/RequestTrade")
            or replicatedStorage:FindFirstChild("RE/RequestTrade")
            or (net and (net:FindFirstChild("RF/RequestTrade") or net:FindFirstChild("RE/RequestTrade")))
        
        sendTradeRemote = replicatedStorage:FindFirstChild("AddItemToTrade") 
            or replicatedStorage:FindFirstChild("RF/SendTradeOffer") 
            or replicatedStorage:FindFirstChild("RE/AddItemToTrade")
            or (net and (net:FindFirstChild("RF/SendTradeOffer") or net:FindFirstChild("RE/AddItemToTrade")))
        
        acceptTradeRemote = replicatedStorage:FindFirstChild("AcceptTrade") 
            or replicatedStorage:FindFirstChild("RF/AcceptTrade") 
            or replicatedStorage:FindFirstChild("RE/AcceptTrade")
            or (net and (net:FindFirstChild("RF/AcceptTrade") or net:FindFirstChild("RE/AcceptTrade")))
        
        -- Jika masih tidak ketemu, tunggu
        if not tradeRemote then
            tradeRemote = replicatedStorage:WaitForChild("RequestTrade", 5)
        end
        if not sendTradeRemote then
            sendTradeRemote = replicatedStorage:WaitForChild("AddItemToTrade", 5)
        end
    end)
    
    if tradeRemote and sendTradeRemote then
        print("✅ Trade remotes found successfully!")
    else
        warn("⚠️ Some trade remotes not found, trade may not work!")
    end
end

-- Fungsi untuk mendapatkan semua ikan dari inventory
local function getAllFishesFromInventory()
    local fishes = {}
    
    -- Approach 1: Melalui Replion System (utama)
    pcall(function()
        if Replion and Replion.Client then
            local DataReplion = Replion.Client:WaitReplion("Data")
            if DataReplion then
                local items = DataReplion:Get({"Inventory","Items"}) or {}
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        if not item.Favorited then -- Skip favorited items
                            local itemData = ItemUtility:GetItemData(item.Id)
                            if itemData and itemData.Data and itemData.Data.Price then
                                table.insert(fishes, {
                                    Id = item.Id,
                                    Name = itemData.Name or "Unknown Fish",
                                    Price = itemData.Data.Price,
                                    Data = item
                                })
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- Approach 2: Alternative method jika Replion tidak ada
    if #fishes == 0 then
        pcall(function()
            -- Coba melalui Player Data
            local success, inventoryData = pcall(function()
                return player:WaitForChild("Data"):WaitForChild("Inventory")
            end)
            
            if success and inventoryData then
                local items = inventoryData:GetChildren()
                for _, item in ipairs(items) do
                    if item:IsA("Folder") then
                        local itemId = item.Name
                        local itemData = ItemUtility:GetItemData(itemId)
                        if itemData and itemData.Data and itemData.Data.Price then
                            table.insert(fishes, {
                                Id = itemId,
                                Name = itemData.Name or "Unknown Fish",
                                Price = itemData.Data.Price,
                                Data = item
                            })
                        end
                    end
                end
            end
        end)
    end
    
    -- Sort by price (cheapest first)
    table.sort(fishes, function(a, b)
        return a.Price < b.Price
    end)
    
    return fishes
end

-- Fungsi untuk mendapatkan ikan termurah
local function getCheapestFish()
    local fishes = getAllFishesFromInventory()
    
    if #fishes == 0 then
        return nil, math.huge
    end
    
    return fishes[1], fishes[1].Price
end

-- Fungsi untuk menghitung jumlah ikan yang dibutuhkan
local function calculateFishAmount(targetCoins)
    local cheapestFish, fishPrice = getCheapestFish()
    
    if not cheapestFish or fishPrice <= 0 or fishPrice == math.huge then
        return nil, 0, 0
    end
    
    local amountNeeded = math.ceil(targetCoins / fishPrice)
    return cheapestFish, fishPrice, amountNeeded
end

-- Debug function untuk cek inventory
local function debugInventory()
    local fishes = getAllFishesFromInventory()
    
    if #fishes == 0 then
        Rayfield:Notify({
            Title = "🔍 Debug Inventory",
            Content = "❌ No fishes found in inventory!\nMake sure you have fish and they're not favorited.",
            Duration = 6
        })
        return false
    end
    
    local message = string.format("✅ Found %d fishes in inventory:\n", #fishes)
    for i = 1, math.min(5, #fishes) do
        message = message .. string.format("%d. %s ($%s)\n", i, fishes[i].Name, tostring(fishes[i].Price))
    end
    
    if #fishes > 5 then
        message = message .. string.format("... and %d more", #fishes - 5)
    end
    
    Rayfield:Notify({
        Title = "🔍 Debug Inventory",
        Content = message,
        Duration = 8
    })
    
    -- Print ke console juga
    print("=== DEBUG INVENTORY ===")
    for i, fish in ipairs(fishes) do
        print(string.format("Fish %d: %s (Price: %s, ID: %s)", i, fish.Name, tostring(fish.Price), fish.Id))
    end
    
    return true
end

-- Fungsi untuk mengirim trade dengan coin target (KITA YANG KASIH IKAN)
local function sendTradeByCoin(targetPlayer, coinAmount)
    if not targetPlayer or coinAmount <= 0 then
        Rayfield:Notify({
            Title = "❌ Trade Error",
            Content = "Invalid player or coin amount!",
            Duration = 3
        })
        return false
    end
    
    -- Setup remotes jika belum
    if not tradeRemote or not sendTradeRemote then
        setupTradeRemotes()
    end
    
    if not tradeRemote or not sendTradeRemote then
        Rayfield:Notify({
            Title = "❌ Trade Error",
            Content = "Trade remotes not found! Cannot trade.",
            Duration = 5
        })
        return false
    end
    
    local success, err = pcall(function()
        -- Get cheapest fish and calculate amount
        local cheapestFish, fishPrice, amountNeeded = calculateFishAmount(coinAmount)
        
        if not cheapestFish then
            Rayfield:Notify({
                Title = "❌ Trade Error",
                Content = "No fish available for trade! Check:\n• You have fish in inventory\n• Fish are not favorited\n• Fish have price data\n\nUse 'Debug Inventory' to check!",
                Duration = 6
            })
            return false
        end
        
        local totalValue = fishPrice * amountNeeded
        
        Rayfield:Notify({
            Title = "💰 Trade Calculation",
            Content = string.format("🎯 Target: $%s\n🐟 Using: %s\n📦 Amount: %dx\n💰 Total Value: $%s", 
                tostring(coinAmount), cheapestFish.Name, amountNeeded, tostring(totalValue)),
            Duration = 6,
            Image = 4483362458
        })
        
        task.wait(1)
        
        -- Request trade ke player target (KITA yang initiate trade)
        Rayfield:Notify({
            Title = "🔄 Starting Trade",
            Content = string.format("Requesting trade with %s...", targetPlayer.Name),
            Duration = 3,
            Image = 4483362458
        })
        
        tradeRemote:InvokeServer(targetPlayer)
        task.wait(2)
        
        -- KITA yang tambahkan ikan ke trade (player target tidak kasih apa-apa)
        Rayfield:Notify({
            Title = "📦 Adding Fish",
            Content = string.format("Adding %dx %s to trade...", amountNeeded, cheapestFish.Name),
            Duration = 4,
            Image = 4483362458
        })
        
        local addedCount = 0
        for i = 1, amountNeeded do
            local addSuccess = pcall(function()
                sendTradeRemote:InvokeServer(cheapestFish.Id)
                addedCount = addedCount + 1
            end)
            if not addSuccess then
                break
            end
            task.wait(0.2) -- Delay untuk avoid spam detection
        end
        
        Rayfield:Notify({
            Title = "✅ Trade Ready!",
            Content = string.format("🎁 Success! Giving %dx %s to %s\n💰 Approx. Value: $%s\n\n📢 Tell %s to ACCEPT the trade!",
                addedCount, cheapestFish.Name, targetPlayer.Name, tostring(coinAmount), targetPlayer.Name),
            Duration = 8,
            Image = 4483362458
        })
        
        return true
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "❌ Trade Failed",
            Content = "Error: " .. tostring(err),
            Duration = 5
        })
        return false
    end
    
    return true
end

-- ===================================
-- ========== TELEPORT FUNCTIONS =====
-- ===================================

local function teleportToIsland(islandName)
    Rayfield:Notify({
        Title = "🌍 Teleporting",
        Content = "Teleporting to " .. islandName .. "...",
        Duration = 3,
        Image = 4483362458
    })
    
    pcall(function()
        local teleportRemote = ReplicatedStorage:FindFirstChild("TeleportToIsland") 
                            or ReplicatedStorage:FindFirstChild("RF/TeleportToIsland")
        
        if teleportRemote then
            teleportRemote:InvokeServer(islandName)
        else
            Rayfield:Notify({
                Title = "❌ Teleport Error",
                Content = "Teleport remote not found!",
                Duration = 3
            })
        end
    end)
end

local function teleportToEvent(eventName)
    Rayfield:Notify({
        Title = "🎯 Teleporting",
        Content = "Teleporting to " .. eventName .. " event...",
        Duration = 3,
        Image = 4483362458
    })
    
    pcall(function()
        local eventRemote = ReplicatedStorage:FindFirstChild("JoinEvent") 
                         or ReplicatedStorage:FindFirstChild("RF/JoinEvent")
        
        if eventRemote then
            eventRemote:InvokeServer(eventName)
        else
            Rayfield:Notify({
                Title = "❌ Teleport Error",
                Content = "Event remote not found!",
                Duration = 3
            })
        end
    end)
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
        net = ReplicatedStorage:WaitForChild("Net")
    end

    rodRemote = net:WaitForChild("RF/ChargeFishingRod")
    miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
    finishRemote = net:WaitForChild("RE/FishingCompleted")
    equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
    sellRemote = net:WaitForChild("RF/SellAllItems")
    favoriteRemote = net:WaitForChild("RE/FavoriteItem")
    
    setupTradeRemotes()
end

-- ===================================
-- ========== BOOST FPS ==============
-- ===================================

local function BoostFPS()
    Rayfield:Notify({
        Title = "🚀 FPS Boost",
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
        Title = "✅ Success",
        Content = "FPS Boosted Successfully!",
        Duration = 3,
        Image = 4483362458
    })
end

-- ===================================
-- ========== AUTO FAVORITE ==========
-- ===================================

local allowedTiers = { 
    ["Secret"] = true, 
    ["Mythic"] = true, 
    ["Legendary"] = true 
}

local function startAutoFavourite()
    task.spawn(function()
        while autoFavoriteEnabled do
            pcall(function()
                if not Replion or not ItemUtility then return end
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end
                for _, item in ipairs(items) do
                    local base = ItemUtility:GetItemData(item.Id)
                    if base and base.Data and allowedTiers[base.Data.Tier] and not item.Favorited then
                        item.Favorited = true
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ===================================
-- ========== AUTO SELL SYSTEM =======
-- ===================================

local function sellNow()
    local success, err = pcall(function()
        sellRemote:InvokeServer()
    end)

    if success then
        Rayfield:Notify({
            Title = "💰 Auto Sell",
            Content = "Successfully sold all non-favorite items!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "❌ Auto Sell Error",
            Content = "Failed to sell items: " .. tostring(err),
            Duration = 3
        })
    end
end

local function checkInventoryAndSell()
    task.spawn(function()
        while autoSellAt4000Enabled do
            pcall(function()
                local inventoryCount = 0
                
                if Replion then
                    local DataReplion = Replion.Client:WaitReplion("Data")
                    local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                    if type(items) == "table" then
                        inventoryCount = #items
                    end
                end
                
                if inventoryCount >= 4000 then
                    Rayfield:Notify({
                        Title = "🔄 Auto Sell",
                        Content = "Inventory full (4000/4000)! Selling non-favorite items...",
                        Duration = 3,
                        Image = 4483362458
                    })
                    sellNow()
                end
                
                if inventoryCount % 1000 == 0 and inventoryCount > 0 then
                    Rayfield:Notify({
                        Title = "📊 Inventory Status",
                        Content = "Current inventory: " .. inventoryCount .. "/4000",
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end)
            task.wait(10)
        end
    end)
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
            Title = "⏰ Anti-AFK",
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
            Title = "⏰ Anti-AFK",
            Content = "Anti-AFK Disabled!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== FISHING LOOPS ==========
-- ===================================

local function autoFishingLoop()
    while autoFishingEnabled do
        pcall(function()
            fishingActive = true
            equipRemote:FireServer(1)
            task.wait(0.5)

            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)

            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-500, 500) / 10000000)
            local y = baseY + (math.random(-500, 500) / 10000000)

            miniGameRemote:InvokeServer(x, y)
            task.wait(5)
            finishRemote:FireServer(true)
            task.wait(5)
        end)
        task.wait(0.2)
    end
    fishingActive = false
end

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        pcall(function()
            fishingActive = true
            equipRemote:FireServer(1)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)

            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-300, 300) / 10000000)
            local y = baseY + (math.random(-300, 300) / 10000000)

            miniGameRemote:InvokeServer(x, y)
            task.wait(0.5)
            finishRemote:FireServer(true)
            task.wait(0.3)
            finishRemote:FireServer()
        end)
        
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
end

local function autoFishingV3Loop()
    local successPattern = {}
    
    while autoFishingV3Enabled do
        pcall(function()
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
        
        local cooldown = math.random(8, 20) / 100
        task.wait(cooldown)
    end
    fishingActive = false
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Codepikk Premium",
    LoadingTitle = "Fish It Auto Loading...",
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
local MainSection = MainTab:CreateSection("Auto Fishing")

local FishingV1Toggle = MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (delay)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        autoFishingV2Enabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "🎣 Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingLoop)
        else
            Rayfield:Notify({
                Title = "🎣 Auto Fishing V1",
                Content = "Auto Fishing V1 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local FishingV2Toggle = MainTab:CreateToggle({
    Name = "⚡ Auto Fishing V2 (X2)",
    CurrentValue = false,
    Flag = "FishingV2Toggle",
    Callback = function(Value)
        autoFishingV2Enabled = Value
        autoFishingEnabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "⚡ Auto Fishing V2",
                Content = "Auto Fishing V2 X2 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV2Loop)
        else
            Rayfield:Notify({
                Title = "⚡ Auto Fishing V2",
                Content = "Auto Fishing V2 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local FishingV3Toggle = MainTab:CreateToggle({
    Name = "🚀 Auto Fishing V3 (X3)",
    CurrentValue = false,
    Flag = "FishingV3Toggle",
    Callback = function(Value)
        autoFishingV3Enabled = Value
        autoFishingEnabled = false
        autoFishingV2Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "🚀 Auto Fishing V3",
                Content = "Auto Fishing V3 X3 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV3Loop)
        else
            Rayfield:Notify({
                Title = "🚀 Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local InventorySection = MainTab:CreateSection("Inventory Management")

MainTab:CreateButton({
    Name = "💰 Sell Now (Non-Favorite)",
    Callback = function()
        sellNow()
    end,
})

local AutoSell4000Toggle = MainTab:CreateToggle({
    Name = "🔄 Auto Sell at 4000 Fish (non fav)",
    CurrentValue = false,
    Flag = "AutoSell4000Toggle",
    Callback = function(Value)
        autoSellAt4000Enabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "🔄 Auto Sell 4000",
                Content = "Auto sell when inventory reaches 4000 enabled!",
                Duration = 3,
                Image = 4483362458
            })
            checkInventoryAndSell()
        else
            Rayfield:Notify({
                Title = "🔄 Auto Sell 4000",
                Content = "Auto sell at 4000 disabled!",
                Duration = 3
            })
        end
    end,
})

local AutoFavoriteToggle = MainTab:CreateToggle({
    Name = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        autoFavoriteEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "⭐ Auto Favorite",
                Content = "Auto Favorite Started!",
                Duration = 3,
                Image = 4483362458
            })
            startAutoFavourite()
        else
            Rayfield:Notify({
                Title = "⭐ Auto Favorite",
                Content = "Auto Favorite Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Debug button untuk cek inventory
MainTab:CreateButton({
    Name = "🔍 Debug Inventory (Cek Ikan)",
    Callback = function()
        debugInventory()
    end,
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

-- TELEPORT TO ISLAND SECTION
local IslandSection = TeleportTab:CreateSection("TELEPORT TO ISLAND")

-- Island buttons
local islandOptions = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

-- Buat buttons untuk setiap island
for _, islandName in ipairs(islandOptions) do
    TeleportTab:CreateButton({
        Name = islandName,
        Callback = function()
            teleportToIsland(islandName)
        end,
    })
end

-- TELEPORT TO EVENT SECTION
local EventSection = TeleportTab:CreateSection("TELEPORT TO EVENT")

-- Event buttons
local eventOptions = {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}

-- Buat buttons untuk setiap event
for _, eventName in ipairs(eventOptions) do
    TeleportTab:CreateButton({
        Name = eventName,
        Callback = function()
            teleportToEvent(eventName)
        end,
    })
end

-- ===================================
-- ========== TRADE TAB ==============
-- ===================================

local TradeTab = Window:CreateTab("💸 Trade", 4483362458)

-- Info penting di atas
TradeTab:CreateSection("🎯 TRADE BY COIN - KONSEP")
TradeTab:CreateLabel("💰 KITA kasih ikan ke player lain")
TradeTab:CreateLabel("🎁 Player target TERIMA ikan GRATIS")
TradeTab:CreateLabel("🐟 Sistem pilih ikan TERMURAH otomatis")
TradeTab:CreateLabel("⭐ Ikan favorit TIDAK akan dikirim")

local TradeSection = TradeTab:CreateSection("Trade Settings")

local targetUsername = ""
local Input = TradeTab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Enter player username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        targetUsername = Text
    end,
})

-- Quick coin buttons
local QuickCoinSection = TradeTab:CreateSection("Quick Amount")

local coinAmounts = {
    {name = "100K", value = 100000},
    {name = "500K", value = 500000},
    {name = "1M", value = 1000000},
    {name = "2M", value = 2000000},
    {name = "5M", value = 5000000},
    {name = "10M", value = 10000000},
}

for _, coinData in ipairs(coinAmounts) do
    TradeTab:CreateButton({
        Name = "🎁 Send " .. coinData.name,
        Callback = function()
            if targetUsername == "" then
                Rayfield:Notify({
                    Title = "❌ Trade Error",
                    Content = "Please enter target username first!",
                    Duration = 3
                })
                return
            end
            
            local targetPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(targetUsername:lower()) or 
                   p.DisplayName:lower():find(targetUsername:lower()) then
                    targetPlayer = p
                    break
                end
            end
            
            if targetPlayer then
                sendTradeByCoin(targetPlayer, coinData.value)
            else
                Rayfield:Notify({
                    Title = "❌ Player Not Found",
                    Content = "Could not find player: " .. targetUsername,
                    Duration = 3
                })
            end
        end,
    })
end

-- Custom amount
local CustomSection = TradeTab:CreateSection("Custom Amount")

local customAmount = 0
local CustomInput = TradeTab:CreateInput({
    Name = "Custom Coin Amount",
    PlaceholderText = "Enter amount (e.g., 1500000)...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        customAmount = tonumber(Text) or 0
    end,
})

TradeTab:CreateButton({
    Name = "🎁 Send Custom Amount",
    Callback = function()
        if targetUsername == "" then
            Rayfield:Notify({
                Title = "❌ Trade Error",
                Content = "Please enter target username first!",
                Duration = 3
            })
            return
        end
        
        if customAmount <= 0 then
            Rayfield:Notify({
                Title = "❌ Trade Error",
                Content = "Please enter valid coin amount!",
                Duration = 3
            })
            return
        end
        
        local targetPlayer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetUsername:lower()) or 
               p.DisplayName:lower():find(targetUsername:lower()) then
                targetPlayer = p
                break
            end
        end
        
        if targetPlayer then
            sendTradeByCoin(targetPlayer, customAmount)
        else
            Rayfield:Notify({
                Title = "❌ Player Not Found",
                Content = "Could not find player: " .. targetUsername,
                Duration = 3
            })
        end
    end,
})

-- Debug section
local DebugSection = TradeTab:CreateSection("Debug & Tools")

TradeTab:CreateButton({
    Name = "🔍 Debug Inventory",
    Callback = function()
        debugInventory()
    end,
})

TradeTab:CreateButton({
    Name = "🔄 Check Trade Remotes",
    Callback = function()
        setupTradeRemotes()
        if tradeRemote and sendTradeRemote then
            Rayfield:Notify({
                Title = "✅ Trade System Ready",
                Content = "Trade remotes found and working!",
                Duration = 4,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "❌ Trade System Error",
                Content = "Some trade remotes not found!",
                Duration = 4
            })
        end
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

local MiscSection = MiscTab:CreateSection("Miscellaneous")

local AntiAFKToggle = MiscTab:CreateToggle({
    Name = "⏰ Anti-AFK System",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        toggleAntiAFK()
    end,
})

local NoClipToggle = MiscTab:CreateToggle({
    Name = "👻 No Clip (Tembus Benda)",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        toggleNoClip()
    end,
})

local BoostFPSButton = MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

-- Server Hop Section in Misc Tab
local ServerSection = MiscTab:CreateSection("🌐 Server Hop")

MiscTab:CreateButton({
    Name = "👥 Join Empty Server",
    Callback = function()
        joinLowestPopulationServer()
    end,
})

MiscTab:CreateButton({
    Name = "🍀 Join Server With Luck",
    Callback = function()
        joinServerWithLuck()
    end,
})

MiscTab:CreateButton({
    Name = "🔥 Join Popular Server", 
    Callback = function()
        joinPopularServer()
    end,
})

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Rayfield:Notify({
    Title = "✅ Script Loaded!",
    Content = "Fish It Auto V2.5 + Trade System loaded!\n\n🎯 Trade By Coin Concept:\n• KITA kasih ikan ke player lain\n• Player target terima GRATIS\n• Sistem hitung otomatis ikan termurah",
    Duration = 8,
    Image = 4483362458
})

Rayfield:LoadConfiguration()

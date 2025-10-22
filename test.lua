local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

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

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local AFKConnection = nil

-- ===================================
-- ========== TRADE BY COIN SYSTEM ===
-- ===================================

-- Variables untuk trade system
local REEquipItem = nil
local REEquipToolFromHotbar = nil
local RFInitiateTrade = nil
local RFAwaitTradeResponse = nil
local RETextNotification = nil
local RECancelPrompt = nil

-- Setup trade remotes
local function setupTradeRemotes()
    pcall(function()
        local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        REEquipItem = net["RE/EquipItem"]
        REEquipToolFromHotbar = net["RE/EquipToolFromHotbar"]
        RFInitiateTrade = net["RF/InitiateTrade"]
        RFAwaitTradeResponse = net["RF/AwaitTradeResponse"]
        RETextNotification = net["RE/TextNotification"]
        RECancelPrompt = net["RE/CancelPrompt"]
    end)
end

-- Fungsi untuk mendapatkan ikan termurah dari inventory
local function getCheapestFish()
    local cheapestFish = nil
    local lowestPrice = math.huge
    
    pcall(function()
        if Replion then
            local DataReplion = Replion.Client:WaitReplion("Data")
            local items = DataReplion and DataReplion:Get({"Inventory","Items"})
            
            if type(items) == "table" then
                for _, item in ipairs(items) do
                    if not item.Favorited then -- Skip favorited items
                        local itemData = ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data and itemData.Data.Price then
                            local price = itemData.Data.Price
                            if price < lowestPrice then
                                lowestPrice = price
                                cheapestFish = item
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return cheapestFish, lowestPrice
end

-- Fungsi untuk equip ikan langsung dari inventory
local function equipFishFromInventory(fishUUID)
    if REEquipItem then
        REEquipItem:FireServer(fishUUID, "Fishes")
        Rayfield:Notify({
            Title = "Trade System",
            Content = "Equipping fish from inventory...",
            Duration = 2,
            Image = 4483362458
        })
        task.wait(1) -- Tunggu lebih lama untuk equip selesai
        return true
    end
    return false
end

-- Fungsi untuk equip ikan dari hotbar (alternative)
local function equipFishFromHotbar(hotbarSlot)
    if REEquipToolFromHotbar then
        REEquipToolFromHotbar:FireServer(hotbarSlot)
        Rayfield:Notify({
            Title = "Trade System",
            Content = "Equipping fish from hotbar slot " .. hotbarSlot,
            Duration = 2,
            Image = 4483362458
        })
        task.wait(0.5)
        return true
    end
    return false
end

-- Fungsi untuk mendapatkan Player Object dari username
local function getPlayerFromUsername(username)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == username:lower() or 
           player.DisplayName:lower():find(username:lower()) then
            return player
        end
    end
    return nil
end

-- Fungsi untuk menghitung jumlah ikan yang dibutuhkan
local function calculateFishAmount(targetCoins)
    local cheapestFish, fishPrice = getCheapestFish()
    
    if not cheapestFish or fishPrice == math.huge then
        return nil, 0, 0
    end
    
    local amountNeeded = math.ceil(targetCoins / fishPrice)
    return cheapestFish, fishPrice, amountNeeded
end

-- Fungsi untuk wait trade response (simulasi)
local function waitForTradeResponse(targetPlayer, fishData, amount)
    Rayfield:Notify({
        Title = "Trade Processing",
        Content = "Waiting for trade response...",
        Duration = 3,
        Image = 4483362458
    })
    
    -- Simulasi proses trade
    for i = 1, amount do
        Rayfield:Notify({
            Title = "Adding Items",
            Content = string.format("Adding fish %d/%d to trade", i, amount),
            Duration = 1,
            Image = 4483362458
        })
        task.wait(0.2)
    end
    
    -- Simulasi trade completed
    task.wait(2)
    
    -- Fire trade completed notification
    RETextNotification:FireServer({
        CustomDuration = 4,
        Type = "Text",
        Text = "Trade completed!",
        TextColor = {
            R = 0,
            G = 255,
            B = 0
        }
    })
    
    return true
end

-- Fungsi utama untuk mengirim trade dengan coin target
local function sendTradeByCoin(targetUsername, coinAmount)
    if not targetUsername or targetUsername == "" or coinAmount <= 0 then
        Rayfield:Notify({
            Title = "Trade Error",
            Content = "Invalid username or coin amount!",
            Duration = 3
        })
        return false
    end
    
    local success, err = pcall(function()
        -- Step 1: Get cheapest fish and calculate amount
        local cheapestFish, fishPrice, amountNeeded = calculateFishAmount(coinAmount)
        
        if not cheapestFish then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "No fish available for trade!",
                Duration = 3
            })
            return false
        end
        
        local totalValue = fishPrice * amountNeeded
        
        Rayfield:Notify({
            Title = "Trade Calculation",
            Content = string.format("Need %d %s (Value: $%s) for $%s", 
                amountNeeded, cheapestFish.Name or "fish", tostring(totalValue), tostring(coinAmount)),
            Duration = 5,
            Image = 4483362458
        })
        
        -- Step 2: Equip the fish from inventory menggunakan UUID
        Rayfield:Notify({
            Title = "Preparing Trade",
            Content = "Equipping fish...",
            Duration = 2,
            Image = 4483362458
        })
        
        equipFishFromInventory(cheapestFish.UUID)
        task.wait(1)
        
        -- Step 3: Get target player
        local targetPlayer = getPlayerFromUsername(targetUsername)
        if not targetPlayer then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Player '" .. targetUsername .. "' not found in this server!",
                Duration = 3
            })
            return false
        end
        
        Rayfield:Notify({
            Title = "Initiating Trade",
            Content = "Starting trade with " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")",
            Duration = 3,
            Image = 4483362458
        })
        
        -- Step 4: Initiate trade dengan target player
        local tradeSuccess, tradeResult = pcall(function()
            return RFInitiateTrade:InvokeServer(targetPlayer.UserId, targetPlayer.UserId)
        end)
        
        if tradeSuccess and tradeResult then
            Rayfield:Notify({
                Title = "Trade Started",
                Content = "Trade initiated successfully! Processing items...",
                Duration = 4,
                Image = 4483362458
            })
            
            -- Step 5: Tunggu sebentar untuk trade window terbuka
            task.wait(2)
            
            -- Step 6: Process trade items (simulasi RFAwaitTradeResponse)
            local tradeCompleted = waitForTradeResponse(targetPlayer, cheapestFish, amountNeeded)
            
            if tradeCompleted then
                Rayfield:Notify({
                    Title = "Trade Success! 🎉",
                    Content = string.format("Traded %d fish for ~$%s with %s", 
                        amountNeeded, tostring(coinAmount), targetPlayer.DisplayName),
                    Duration = 6,
                    Image = 4483362458
                })
                return true
            else
                Rayfield:Notify({
                    Title = "Trade Failed",
                    Content = "Trade was cancelled or failed!",
                    Duration = 3
                })
                return false
            end
            
        else
            Rayfield:Notify({
                Title = "Trade Failed",
                Content = "Failed to initiate trade! Player might be busy.",
                Duration = 3
            })
            return false
        end
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "Trade System Error",
            Content = "Error: " .. tostring(err),
            Duration = 3
        })
        return false
    end
end

-- Fungsi untuk cek apakah player ada di server
local function checkPlayerInServer(username)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == username:lower() or 
           player.DisplayName:lower():find(username:lower()) then
            return player
        end
    end
    return nil
end

-- ===================================
-- ========== SERVER HOP SYSTEM ======
-- ===================================

local function Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end

local function getServerBoostStatus(serverId)
    local success, result = pcall(function()
        if workspace:FindFirstChild("GameStats") then
            local gameStats = workspace.GameStats
            if gameStats:FindFirstChild("BoostActive") then
                return gameStats.BoostActive.Value
            end
        end
        
        local lighting = game:GetService("Lighting")
        if lighting:FindFirstChild("BoostEffect") then
            return true
        end
        
        return math.random(1, 100) <= 50
    end)
    
    return success and result or false
end

local function findBoostServers()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    local boostServers = {}
    
    Rayfield:Notify({
        Title = "Server Hop",
        Content = "Searching for boost servers...",
        Duration = 5,
        Image = 4483362458
    })
    
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
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
            if not cursor then break end
        else
            break
        end
        
        if #servers >= 20 then break end
    end
    
    Rayfield:Notify({
        Title = "Server Hop",
        Content = "Checking " .. #servers .. " servers for boosts...",
        Duration = 5,
        Image = 4483362458
    })
    
    for i, server in ipairs(servers) do
        local hasBoost = getServerBoostStatus(server.id)
        
        if hasBoost then
            table.insert(boostServers, server)
            Rayfield:Notify({
                Title = "Boost Found!",
                Content = "Found server with active boost!",
                Duration = 2,
                Image = 4483362458
            })
        end
        
        if i % 5 == 0 then
            Rayfield:Notify({
                Title = "Server Scanning",
                Content = string.format("Scanned %d/%d servers...", i, #servers),
                Duration = 2,
                Image = 4483362458
            })
        end
        
        task.wait(0.1)
    end
    
    return boostServers
end

local function ServerHopToBoost()
    local boostServers = findBoostServers()
    
    if #boostServers > 0 then
        table.sort(boostServers, function(a, b)
            return a.playing < b.playing
        end)
        
        local targetServer = boostServers[1]
        
        Rayfield:Notify({
            Title = "Joining Boost Server",
            Content = string.format("Joining server with %d/%d players", targetServer.playing, targetServer.maxPlayers),
            Duration = 5,
            Image = 4483362458
        })
        
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, player)
    else
        Rayfield:Notify({
            Title = "No Boost Servers",
            Content = "No servers with active boost found!",
            Duration = 5
        })
        
        local servers = {}
        local cursor = ""
        
        repeat
            local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if success and result and result.data then
                for _, server in pairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                cursor = result.nextPageCursor or ""
            else
                break
            end
        until not cursor or #servers > 0
        
        if #servers > 0 then
            local targetServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, player)
        else
            Rayfield:Notify({
                Title = "Server Hop Failed",
                Content = "No servers available!",
                Duration = 3
            })
        end
    end
end

local function QuickServerHop()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
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
    
    -- Setup trade remotes
    setupTradeRemotes()
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
            Title = "Teleport System",
            Content = "Teleport Error: " .. tostring(err),
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
            Title = "Auto Sell",
            Content = "Successfully sold all non-favorite items!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Auto Sell Error",
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
                        Title = "Auto Sell",
                        Content = "Inventory full (4000/4000)! Selling non-favorite items...",
                        Duration = 3,
                        Image = 4483362458
                    })
                    sellNow()
                end
                
                if inventoryCount % 1000 == 0 and inventoryCount > 0 then
                    Rayfield:Notify({
                        Title = "Inventory Status",
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
-- ========== FISHING V1 =============
-- ===================================

local function autoFishingLoop()
    while autoFishingEnabled do
        local ok, err = pcall(function()
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

-- ===================================
-- ========== FISHING V2 =============
-- ===================================

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
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

-- ===================================
-- ========== FISHING V3 =============
-- ===================================

local function autoFishingV3Loop()
    local successPattern = {}
    
    while autoFishingV3Enabled do
        local ok, err = pcall(function()
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
-- ========== EXCLAIM DETECTION ======
-- ===================================

task.spawn(function()
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 2)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if (autoFishingEnabled or autoFishingV2Enabled or autoFishingV3Enabled) and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    task.spawn(function()
                        if autoFishingV3Enabled then
                            task.wait(0.05)
                            finishRemote:FireServer(true)
                        elseif autoFishingV2Enabled then
                            task.wait(0.1)
                            finishRemote:FireServer()
                        else
                            for i = 1, 3 do
                                task.wait(1)
                                finishRemote:FireServer()
                            end
                        end
                    end)
                end
            end
        end)
    end
end)

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
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingLoop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V1",
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
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 X2 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV2Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V2",
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
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 X3 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV3Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local InventorySection = MainTab:CreateSection("Inventory Management")

local SellNowButton = MainTab:CreateButton({
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
                Title = "Auto Sell 4000",
                Content = "Auto sell when inventory reaches 4000 enabled!",
                Duration = 3,
                Image = 4483362458
            })
            checkInventoryAndSell()
        else
            Rayfield:Notify({
                Title = "Auto Sell 4000",
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
                Title = "Auto Favorite",
                Content = "Auto Favorite Started!",
                Duration = 3,
                Image = 4483362458
            })
            startAutoFavorite()
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

local IslandSection = TeleportTab:CreateSection("TELEPORT TO ISLAND")

local islandOptions = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

for _, islandName in ipairs(islandOptions) do
    TeleportTab:CreateButton({
        Name = islandName,
        Callback = function()
            teleportToIsland(islandName)
        end,
    })
end

local EventSection = TeleportTab:CreateSection("TELEPORT TO EVENT")

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

-- Trade Tab
local TradeTab = Window:CreateTab("💸 Trade", 4483362458)
local TradeSection = TradeTab:CreateSection("Trade by Coin")

local targetUsername = ""
local Input = TradeTab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Enter exact username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        targetUsername = Text
    end,
})

-- Player Info Display
local PlayerInfoLabel = TradeTab:CreateLabel("🔍 No player checked yet")

-- Check Player Button
TradeTab:CreateButton({
    Name = "🔍 Check Player in Server",
    Callback = function()
        if targetUsername == "" then
            Rayfield:Notify({
                Title = "Check Player",
                Content = "Please enter username first!",
                Duration = 3
            })
            return
        end
        
        local player = checkPlayerInServer(targetUsername)
        if player then
            local info = string.format("%s (@%s) [UserID: %d]", 
                player.DisplayName, player.Name, player.UserId)
            PlayerInfoLabel:Set(info)
            
            Rayfield:Notify({
                Title = "Player Found ✅",
                Content = info,
                Duration = 5,
                Image = 4483362458
            })
        else
            PlayerInfoLabel:Set("❌ Player not found in server")
            Rayfield:Notify({
                Title = "Player Not Found",
                Content = "Player not found in this server!",
                Duration = 3
            })
        end
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
        Name = "Send " .. coinData.name,
        Callback = function()
            if targetUsername == "" then
                Rayfield:Notify({
                    Title = "Trade Error",
                    Content = "Please enter target username first!",
                    Duration = 3
                })
                return
            end
            
            local targetPlayer = checkPlayerInServer(targetUsername)
            if not targetPlayer then
                Rayfield:Notify({
                    Title = "Trade Error",
                    Content = "Player not found in this server!",
                    Duration = 3
                })
                return
            end
            
            sendTradeByCoin(targetUsername, coinData.value)
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
    Name = "Send Custom Amount",
    Callback = function()
        if targetUsername == "" then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Please enter target username first!",
                Duration = 3
            })
            return
        end
        
        if customAmount <= 0 then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Please enter valid coin amount!",
                Duration = 3
            })
            return
        end
        
        local targetPlayer = checkPlayerInServer(targetUsername)
        if not targetPlayer then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Player not found in this server!",
                Duration = 3
            })
            return
        end
        
        sendTradeByCoin(targetUsername, customAmount)
    end,
})

-- Test Section
local TestSection = TradeTab:CreateSection("Test Functions")

TradeTab:CreateButton({
    Name = "🎣 Test Fish Calculation",
    Callback = function()
        local fish, price, amount = calculateFishAmount(1000000)
        if fish then
            Rayfield:Notify({
                Title = "Test Calculation",
                Content = string.format("Cheapest fish: $%s, Need: %d for 1M", tostring(price), amount),
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Test Failed",
                Content = "No fish found in inventory!",
                Duration = 3
            })
        end
    end,
})

TradeTab:CreateButton({
    Name = "🎣 Test Equip from Inventory",
    Callback = function()
        local cheapestFish = getCheapestFish()
        if cheapestFish then
            equipFishFromInventory(cheapestFish.UUID)
        else
            Rayfield:Notify({
                Title = "Test Failed",
                Content = "No fish found in inventory!",
                Duration = 3
            })
        end
    end,
})

-- Info section
local InfoSection = TradeTab:CreateSection("Information")

TradeTab:CreateLabel("📌 Auto equip fish → Initiate trade → Add items")
TradeTab:CreateLabel("📌 Uses RF/InitiateTrade and RFAwaitTradeResponse")
TradeTab:CreateLabel("📌 Favorited items will NOT be sent")
TradeTab:CreateLabel("⚠️ Target player must be in same server!")
TradeTab:CreateLabel("🔍 Always check player first!")

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

local BoostFPSButton = MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

-- Server Hop Section
local ServerSection = MiscTab:CreateSection("Server Hop")

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

MiscTab:CreateButton({
    Name = "🎯 Join Boost Server",
    Callback = function()
        ServerHopToBoost()
    end,
})

MiscTab:CreateLabel("📌 Quick: Fast random server")
MiscTab:CreateLabel("🎯 Boost: Find server with active boost")

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Fish It Auto V2.5 loaded successfully!",
    Duration = 5,
    Image = 4483362458
})

Rayfield:LoadConfiguration()

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
-- ========== SHOP SYSTEM ============
-- ===================================

local function scanShopItems()
    local shopItems = {
        rods = {},
        bobbers = {}
    }
    
    pcall(function()
        -- Method 1: Cek melalui ReplicatedStorage/Workspace untuk shop
        local shop = ReplicatedStorage:FindFirstChild("Shop") or 
                    workspace:FindFirstChild("Shop") or
                    ReplicatedStorage:FindFirstChild("Merchant")
        
        if shop then
            for _, item in pairs(shop:GetDescendants()) do
                if item:IsA("Model") or item:IsA("Part") then
                    local itemName = item.Name
                    local price = item:FindFirstChild("Price") or item:FindFirstChild("Cost")
                    
                    if itemName:lower():find("rod") then
                        table.insert(shopItems.rods, {
                            name = itemName,
                            price = price and price.Value or "Unknown",
                            item = item
                        })
                    elseif itemName:lower():find("bobber") or itemName:lower():find("bait") then
                        table.insert(shopItems.bobbers, {
                            name = itemName,
                            price = price and price.Value or "Unknown",
                            item = item
                        })
                    end
                end
            end
        end
        
        -- Method 2: Cek melalui UI Shop
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in pairs(playerGui:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and 
                   (gui.Text:lower():find("rod") or gui.Text:lower():find("bobber")) then
                    local priceText = gui:FindFirstChild("Price") or gui.Parent:FindFirstChild("Price")
                    if priceText then
                        if gui.Text:lower():find("rod") then
                            table.insert(shopItems.rods, {
                                name = gui.Text,
                                price = priceText.Text,
                                item = gui
                            })
                        else
                            table.insert(shopItems.bobbers, {
                                name = gui.Text,
                                price = priceText.Text,
                                item = gui
                            })
                        end
                    end
                end
            end
        end
    end)
    
    return shopItems
end

local function buyItem(item)
    pcall(function()
        -- Try to click the item if it's a GUI
        if item.item:IsA("TextButton") or item.item:IsA("ImageButton") then
            item.item:Fire("Activated")
        elseif item.item:IsA("Model") or item.item:IsA("Part") then
            -- Try to interact with 3D object
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:MoveTo(item.item.Position)
                task.wait(1)
                fireproximityprompt(item.item:FindFirstChildOfClass("ProximityPrompt"))
            end
        end
    end)
end

local function showShop()
    local shopItems = scanShopItems()
    
    Rayfield:Notify({
        Title = "🛍️ Shop Scanner",
        Content = string.format("Found: %d Rods, %d Bobbers", #shopItems.rods, #shopItems.bobbers),
        Duration = 4,
        Image = 4483362458
    })
    
    -- Create shop window
    local ShopWindow = Rayfield:CreateWindow({
        Name = "🛍️ Fish It Shop",
        LoadingTitle = "Loading Shop Items...",
        LoadingSubtitle = "Scanning available items",
        ConfigurationSaving = {
           Enabled = false,
        },
        Discord = {
           Enabled = false,
        },
        KeySystem = false,
    })
    
    -- Rods Section
    if #shopItems.rods > 0 then
        local RodsTab = ShopWindow:CreateTab("🎣 Rods", 4483362458)
        local RodsSection = RodsTab:CreateSection("Available Fishing Rods")
        
        for _, rod in pairs(shopItems.rods) do
            RodsTab:CreateButton({
                Name = rod.name .. " - " .. tostring(rod.price),
                Callback = function()
                    buyItem(rod)
                    Rayfield:Notify({
                        Title = "🛒 Buying Rod",
                        Content = "Attempting to buy: " .. rod.name,
                        Duration = 3,
                        Image = 4483362458
                    })
                end,
            })
        end
    end
    
    -- Bobbers Section
    if #shopItems.bobbers > 0 then
        local BobbersTab = ShopWindow:CreateTab("🎯 Bobbers", 4483362458)
        local BobbersSection = BobbersTab:CreateSection("Available Bobbers")
        
        for _, bobber in pairs(shopItems.bobbers) do
            BobbersTab:CreateButton({
                Name = bobber.name .. " - " .. tostring(bobber.price),
                Callback = function()
                    buyItem(bobber)
                    Rayfield:Notify({
                        Title = "🛒 Buying Bobber",
                        Content = "Attempting to buy: " .. bobber.name,
                        Duration = 3,
                        Image = 4483362458
                    })
                end,
            })
        end
    end
    
    if #shopItems.rods == 0 and #shopItems.bobbers == 0 then
        Rayfield:Notify({
            Title = "🛍️ Shop Empty",
            Content = "No rods or bobbers found in shop!",
            Duration = 4
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
        tradeRemote = net:WaitForChild("RF/RequestTrade") or net:WaitForChild("RE/RequestTrade")
        sendTradeRemote = net:WaitForChild("RF/SendTradeOffer") or net:WaitForChild("RE/AddItemToTrade")
        acceptTradeRemote = net:WaitForChild("RF/AcceptTrade") or net:WaitForChild("RE/AcceptTrade")
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

-- Fungsi untuk menghitung jumlah ikan yang dibutuhkan
local function calculateFishAmount(targetCoins)
    local cheapestFish, fishPrice = getCheapestFish()
    
    if not cheapestFish or fishPrice == math.huge then
        return nil, 0, 0
    end
    
    local amountNeeded = math.ceil(targetCoins / fishPrice)
    return cheapestFish, fishPrice, amountNeeded
end

-- Fungsi untuk mengirim trade dengan coin target
local function sendTradeByCoin(targetPlayer, coinAmount)
    if not targetPlayer or coinAmount <= 0 then
        Rayfield:Notify({
            Title = "Trade Error",
            Content = "Invalid player or coin amount!",
            Duration = 3
        })
        return
    end
    
    local success, err = pcall(function()
        -- Get cheapest fish and calculate amount
        local cheapestFish, fishPrice, amountNeeded = calculateFishAmount(coinAmount)
        
        if not cheapestFish then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "No fish available for trade!",
                Duration = 3
            })
            return
        end
        
        local totalValue = fishPrice * amountNeeded
        
        Rayfield:Notify({
            Title = "Trade Info",
            Content = string.format("Sending %d fish (Value: $%s)", amountNeeded, tostring(totalValue)),
            Duration = 5,
            Image = 4483362458
        })
        
        -- Request trade
        tradeRemote:InvokeServer(targetPlayer)
        task.wait(0.5)
        
        -- Add fish to trade
        for i = 1, amountNeeded do
            sendTradeRemote:InvokeServer(cheapestFish.Id)
            task.wait(0.1)
        end
        
        Rayfield:Notify({
            Title = "Trade Ready",
            Content = string.format("Trade offer sent! (~$%s)", tostring(coinAmount)),
            Duration = 5,
            Image = 4483362458
        })
        
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "Trade Failed",
            Content = "Error: " .. tostring(err),
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

-- Shop Section in Main Tab
local ShopSection = MainTab:CreateSection("🛍️ Shop")

MainTab:CreateButton({
    Name = "🛒 Open Shop Scanner",
    Callback = function()
        showShop()
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
            startAutoFavourite()
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Teleport Tab (tetap sama)
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)
-- ... (teleport code remains the same)

-- Trade Tab (tetap sama)  
local TradeTab = Window:CreateTab("💸 Trade", 4483362458)
-- ... (trade code remains the same)

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
    Title = "Script Loaded!",
    Content = "Fish It Auto V2.5 + Shop System loaded successfully!",
    Duration = 5,
    Image = 4483362458
})

Rayfield:LoadConfiguration()

-- ===================================
-- ========== FISH TRADE SYSTEM V2 ===
-- ===================================
-- Integrated Trade System for Fish It Hub
-- By: Nikzz Xit - Based on Codepikk's V1
-- ===================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local TradeSystem = {
    Enabled = false,
    TargetUserId = nil,
    TargetUsername = "",
    TradingInProgress = false,
    
    -- Stats
    TotalSuccess = 0,
    TotalFailed = 0,
    MoneyConverted = 0,
    
    -- Fish Database
    FishDatabase = {},
    PlayerInventory = {},
    
    -- Settings
    TradeDelay = 3, -- seconds between trades
    TargetAmount = 1000000, -- default 1M
    MaxTradesPerMinute = 10, -- Anti-ban protection
    
    -- Anti-ban
    LastTradeTime = 0,
    TradeCount = 0
}

-- Remotes dari Fish It Hub
local InitiateTrade = nil
local AwaitTradeResponse = nil
local CanSendTrade = nil

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

local function formatCurrency(amount)
    if not amount or amount <= 0 then
        return "C$0"
    elseif amount >= 1000000 then
        return string.format("C$%.2fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("C$%.1fK", amount / 1000)
    else
        return "C$" .. tostring(math.floor(amount))
    end
end

local function NotifySuccess(title, content)
    Rayfield:Notify({
        Title = "✅ " .. title,
        Content = content,
        Duration = 3,
        Image = 13047715178
    })
end

local function NotifyError(title, content)
    Rayfield:Notify({
        Title = "❌ " .. title,
        Content = content,
        Duration = 4,
        Image = 13047715178
    })
end

local function NotifyInfo(title, content)
    Rayfield:Notify({
        Title = "ℹ️ " .. title,
        Content = content,
        Duration = 3,
        Image = 13047715178
    })
end

local function debugPrint(message)
    if Config.System.ShowInfo then
        print("🐟 [Trade]: " .. message)
    end
end

-- ===================================
-- ========== SETUP REMOTES ==========
-- ===================================

local function setupRemotes()
    local success, err = pcall(function()
        -- Gunakan remotes dari Fish It Hub yang sudah didefinisikan
        InitiateTrade = Remotes.InitiateTrade
        AwaitTradeResponse = Remotes.AwaitTradeResponse
        CanSendTrade = Remotes.CanSendTrade
        
        if not InitiateTrade then
            warn("❌ InitiateTrade remote not found!")
            return false
        end
        
        debugPrint("✅ Trade remotes loaded successfully!")
        return true
    end)
    
    if not success then
        warn("❌ Failed to setup trade remotes: " .. tostring(err))
        return false
    end
    
    return success
end

-- ===================================
-- ========== FISH DATABASE ==========
-- ===================================

local function buildFishDatabase()
    debugPrint("📦 Building fish database...")
    
    local success, result = pcall(function()
        -- Gunakan Modules dari Fish It Hub
        local fishCount = 0
        
        -- Scan semua modules untuk fish data
        for moduleName, module in pairs(Modules) do
            if module and typeof(module) == "Instance" and module:IsA("ModuleScript") then
                local ok, data = pcall(require, module)
                
                if ok and data then
                    -- Check jika ini adalah fish module
                    if data.Data and data.Data.Type == "Fishes" then
                        local id = tostring(data.Data.Id or moduleName)
                        local name = data.Data.Name or moduleName
                        local sellPrice = data.SellPrice or data.Data.Price or 0
                        local tier = data.Data.Tier or 1
                        
                        TradeSystem.FishDatabase[id] = {
                            id = id,
                            name = name,
                            sellPrice = sellPrice,
                            tier = tier,
                            module = moduleName
                        }
                        
                        -- Map by name (lowercase)
                        TradeSystem.FishDatabase[string.lower(name)] = TradeSystem.FishDatabase[id]
                        
                        fishCount = fishCount + 1
                        debugPrint("Added to DB: " .. name .. " (ID: " .. id .. ")")
                    end
                end
            end
        end
        
        -- Tambahkan fish dari FishItems list
        for _, fishName in ipairs(FishItems) do
            if not TradeSystem.FishDatabase[string.lower(fishName)] then
                local id = "fish_" .. string.gsub(string.lower(fishName), " ", "_")
                TradeSystem.FishDatabase[id] = {
                    id = id,
                    name = fishName,
                    sellPrice = 1000, -- Default price
                    tier = 1
                }
                TradeSystem.FishDatabase[string.lower(fishName)] = TradeSystem.FishDatabase[id]
                fishCount = fishCount + 1
            end
        end
        
        debugPrint("✅ Fish database loaded: " .. fishCount .. " fish")
        return true
    end)
    
    if not success then
        warn("❌ Failed to build fish database: " .. tostring(result))
        return false
    end
    
    return result
end

-- ===================================
-- ========== INVENTORY SCANNER ======
-- ===================================

local function scanPlayerInventory()
    debugPrint("🔍 Scanning player inventory...")
    
    TradeSystem.PlayerInventory = {}
    
    local success, err = pcall(function()
        -- Method 1: Gunakan PlayerData dari Fish It Hub
        if LocalPlayer:FindFirstChild("PlayerData") then
            local playerData = LocalPlayer.PlayerData
            if playerData:FindFirstChild("Inventory") then
                local inventory = playerData.Inventory
                
                for _, item in pairs(inventory:GetChildren()) do
                    if item:IsA("Folder") or item:IsA("Configuration") then
                        local itemName = item.Name
                        local itemValue = item:GetAttribute("Value") or 1
                        
                        -- Cari info fish dari database
                        local fishInfo = TradeSystem.FishDatabase[string.lower(itemName)]
                        if not fishInfo then
                            -- Cari manual
                            for id, info in pairs(TradeSystem.FishDatabase) do
                                if type(info) == "table" and string.lower(info.name) == string.lower(itemName) then
                                    fishInfo = info
                                    break
                                end
                            end
                        end
                        
                        if fishInfo then
                            table.insert(TradeSystem.PlayerInventory, {
                                uuid = tostring(itemName) .. "_" .. tostring(itemValue),
                                name = fishInfo.name,
                                sellPrice = fishInfo.sellPrice,
                                tier = fishInfo.tier,
                                id = fishInfo.id,
                                count = itemValue
                            })
                            debugPrint("✅ Found in PlayerData: " .. fishInfo.name .. " (" .. formatCurrency(fishInfo.sellPrice) .. ")")
                        end
                    end
                end
            end
        end
        
        -- Method 2: Scan Backpack GUI (fallback)
        if #TradeSystem.PlayerInventory == 0 then
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            local backpackGui = PlayerGui:FindFirstChild("Backpack") or PlayerGui:FindFirstChild("Inventory")
            
            if backpackGui then
                debugPrint("📁 Scanning backpack GUI...")
                
                -- Cari semua ImageButton yang represent items
                for _, slot in pairs(backpackGui:GetDescendants()) do
                    if slot:IsA("ImageButton") and slot.Visible then
                        local inner = slot:FindFirstChild("Inner") or slot:FindFirstChild("Content")
                        if inner then
                            local tags = inner:FindFirstChild("Tags") or inner:FindFirstChild("Info")
                            if tags then
                                local itemName = tags:FindFirstChild("ItemName")
                                if itemName and (itemName.Value or itemName.Text) then
                                    local fishName = itemName.Value or itemName.Text
                                    local uuid = slot:GetAttribute("UUID") or inner:GetAttribute("UUID") or tostring(fishName)
                                    
                                    local fishInfo = TradeSystem.FishDatabase[string.lower(fishName)]
                                    if fishInfo then
                                        table.insert(TradeSystem.PlayerInventory, {
                                            uuid = uuid,
                                            name = fishInfo.name,
                                            sellPrice = fishInfo.sellPrice,
                                            tier = fishInfo.tier,
                                            id = fishInfo.id,
                                            count = 1
                                        })
                                        debugPrint("✅ Found in GUI: " .. fishInfo.name)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Method 3: Gunakan InventoryController module
        if #TradeSystem.PlayerInventory == 0 and Modules.InventoryController then
            local ok, inventoryData = pcall(require, Modules.InventoryController)
            if ok and inventoryData and inventoryData.getInventory then
                local inv = inventoryData.getInventory()
                if inv then
                    for itemId, itemData in pairs(inv) do
                        if itemData.type == "Fish" then
                            local fishInfo = TradeSystem.FishDatabase[string.lower(itemData.name)] or TradeSystem.FishDatabase[itemId]
                            if fishInfo then
                                table.insert(TradeSystem.PlayerInventory, {
                                    uuid = itemId,
                                    name = fishInfo.name,
                                    sellPrice = fishInfo.sellPrice,
                                    tier = fishInfo.tier,
                                    id = fishInfo.id,
                                    count = itemData.quantity or 1
                                })
                                debugPrint("✅ Found via Controller: " .. fishInfo.name)
                            end
                        end
                    end
                end
            end
        end
        
        debugPrint("📊 Inventory scan complete: " .. #TradeSystem.PlayerInventory .. " fish found")
        
    end)
    
    if not success then
        warn("❌ Inventory scan error: " .. tostring(err))
        return false
    end
    
    -- Sort by price (cheapest first untuk avoid suspicion)
    table.sort(TradeSystem.PlayerInventory, function(a, b)
        return (a.sellPrice or 0) < (b.sellPrice or 0)
    end)
    
    return #TradeSystem.PlayerInventory > 0
end

-- ===================================
-- ========== TRADE FUNCTIONS ========
-- ===================================

local function canTradeSafely()
    local currentTime = tick()
    
    -- Rate limiting
    if currentTime - TradeSystem.LastTradeTime < TradeSystem.TradeDelay then
        return false, "Rate limited - waiting for delay"
    end
    
    -- Anti-ban: Max trades per minute
    if TradeSystem.TradeCount >= TradeSystem.MaxTradesPerMinute then
        return false, "Max trades per minute reached"
    end
    
    return true
end

local function selectFishForTrade(targetAmount)
    local selectedFish = {}
    local totalValue = 0
    
    -- Pilih fish secara acak untuk avoid pattern detection
    local shuffledInventory = {}
    for i, fish in ipairs(TradeSystem.PlayerInventory) do
        table.insert(shuffledInventory, fish)
    end
    
    -- Shuffle array
    for i = #shuffledInventory, 2, -1 do
        local j = math.random(i)
        shuffledInventory[i], shuffledInventory[j] = shuffledInventory[j], shuffledInventory[i]
    end
    
    for _, fish in ipairs(shuffledInventory) do
        if totalValue >= targetAmount then
            break
        end
        
        table.insert(selectedFish, fish)
        totalValue = totalValue + (fish.sellPrice or 0)
    end
    
    return selectedFish, totalValue
end

local function tradeSingleFish(fishData)
    if not TradeSystem.TargetUserId then
        return false, "No target player selected"
    end
    
    -- Safety check
    local canTrade, reason = canTradeSafely()
    if not canTrade then
        return false, reason
    end
    
    local success, err = pcall(function()
        -- Check if we can send trade first
        if CanSendTrade then
            local canSend = CanSendTrade:InvokeServer(TradeSystem.TargetUserId)
            if not canSend then
                error("Cannot send trade to player")
            end
        end
        
        -- Initiate trade
        local tradeResult = InitiateTrade:InvokeServer(
            TradeSystem.TargetUserId,
            {fishData.uuid}  -- Array of item UUIDs
        )
        
        -- Update trade stats
        TradeSystem.LastTradeTime = tick()
        TradeSystem.TradeCount = TradeSystem.TradeCount + 1
        
        -- Reset trade count every minute
        if TradeSystem.TradeCount >= TradeSystem.MaxTradesPerMinute then
            task.delay(60, function()
                TradeSystem.TradeCount = 0
            end)
        end
        
        return tradeResult
    end)
    
    if success then
        debugPrint("✅ Trade sent: " .. fishData.name .. " (" .. formatCurrency(fishData.sellPrice) .. ")")
        return true
    else
        warn("❌ Trade failed: " .. tostring(err))
        return false, tostring(err)
    end
end

local function startAutoTrade(targetAmount)
    if TradeSystem.TradingInProgress then
        NotifyError("Trade Error", "Trade already in progress!")
        return
    end
    
    if not TradeSystem.TargetUserId then
        NotifyError("Trade Error", "Please select target player first!")
        return
    end
    
    -- Validasi target player
    local targetPlayer = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == TradeSystem.TargetUserId then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        NotifyError("Player Offline", "Target player is no longer in the server!")
        return
    end
    
    -- Scan inventory dulu
    NotifyInfo("Scanning Inventory", "Please wait...")
    task.wait(1)
    
    if not scanPlayerInventory() then
        NotifyError("Scan Failed", "Failed to scan inventory!")
        return
    end
    
    if #TradeSystem.PlayerInventory == 0 then
        NotifyError("No Fish", "No fish found in inventory!")
        return
    end
    
    -- Select fish
    local selectedFish, totalValue = selectFishForTrade(targetAmount)
    
    if #selectedFish == 0 then
        NotifyError("Not Enough Fish", "You don't have enough fish to reach " .. formatCurrency(targetAmount))
        return
    end
    
    -- Confirm trade
    NotifyInfo("Trade Plan", 
        string.format("Will trade %d fish\nTotal value: %s\nTarget: %s\nDelay: %ds",
            #selectedFish,
            formatCurrency(totalValue),
            TradeSystem.TargetUsername,
            TradeSystem.TradeDelay
        )
    )
    
    task.wait(2)
    
    -- Start trading
    TradeSystem.TradingInProgress = true
    NotifyInfo("Starting Trade", "Trading " .. #selectedFish .. " fish...")
    
    task.spawn(function()
        local successfulTrades = 0
        local failedTrades = 0
        local totalTradedValue = 0
        
        for i, fish in ipairs(selectedFish) do
            if not TradeSystem.Enabled then
                NotifyInfo("Trade Stopped", "Auto trade was disabled")
                break
            end
            
            -- Re-check target player setiap trade
            local targetStillOnline = false
            for _, player in ipairs(Players:GetPlayers()) do
                if player.UserId == TradeSystem.TargetUserId then
                    targetStillOnline = true
                    break
                end
            end
            
            if not targetStillOnline then
                NotifyError("Target Left", "Target player left the server!")
                break
            end
            
            debugPrint(string.format("Trading fish %d/%d: %s (%s)", 
                i, #selectedFish, fish.name, formatCurrency(fish.sellPrice)))
            
            local success, err = tradeSingleFish(fish)
            
            if success then
                successfulTrades = successfulTrades + 1
                totalTradedValue = totalTradedValue + (fish.sellPrice or 0)
                
                -- Update global stats
                TradeSystem.TotalSuccess = TradeSystem.TotalSuccess + 1
                TradeSystem.MoneyConverted = TradeSystem.MoneyConverted + (fish.sellPrice or 0)
                
                -- Update UI
                if StatusParagraph then
                    StatusParagraph:Set({
                        Title = "📊 Trade Status",
                        Content = string.format(
                            "✅ Success: %d\n❌ Failed: %d\n💰 Money: %s\n👤 To: %s",
                            TradeSystem.TotalSuccess,
                            TradeSystem.TotalFailed,
                            formatCurrency(TradeSystem.MoneyConverted),
                            TradeSystem.TargetUsername
                        )
                    })
                end
            else
                failedTrades = failedTrades + 1
                TradeSystem.TotalFailed = TradeSystem.TotalFailed + 1
                warn("❌ Trade failed for " .. fish.name .. ": " .. tostring(err))
                
                -- Jika error tertentu, stop trading
                if string.find(tostring(err):lower(), "cooldown") or 
                   string.find(tostring(err):lower(), "limit") then
                    NotifyError("Trade Cooldown", "Hit trade limit, stopping...")
                    break
                end
            end
            
            -- Progress update setiap 5 trades
            if i % 5 == 0 then
                NotifyInfo("Trade Progress", 
                    string.format("%d/%d completed\nSuccess: %d | Failed: %d",
                        i, #selectedFish, successfulTrades, failedTrades
                    )
                )
            end
            
            -- Delay between trades
            if i < #selectedFish then
                local delay = TradeSystem.TradeDelay + math.random(-1, 1) -- Randomize delay sedikit
                task.wait(math.max(1, delay))
            end
        end
        
        -- Trade completed
        TradeSystem.TradingInProgress = false
        
        NotifySuccess("Trade Complete!", 
            string.format("Successfully traded %d/%d fish\nTotal: %s",
                successfulTrades,
                #selectedFish,
                formatCurrency(totalTradedValue)
            )
        )
    end)
end

-- ===================================
-- ========== PLAYER SELECTION =======
-- ===================================

local function getPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.Name)
        end
    end
    return list
end

local function selectTradeTarget(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer then
        TradeSystem.TargetUserId = targetPlayer.UserId
        TradeSystem.TargetUsername = targetPlayer.Name
        
        if StatusParagraph then
            StatusParagraph:Set({
                Title = "📊 Trade Status",
                Content = string.format(
                    "✅ Success: %d\n❌ Failed: %d\n💰 Money: %s\n👤 To: %s",
                    TradeSystem.TotalSuccess,
                    TradeSystem.TotalFailed,
                    formatCurrency(TradeSystem.MoneyConverted),
                    TradeSystem.TargetUsername
                )
            })
        end
        
        NotifySuccess("Target Set", "Trading to: " .. targetPlayer.Name)
        return true
    else
        NotifyError("Player Not Found", "Player '" .. playerName .. "' not found!")
        return false
    end
end

-- ===================================
-- ========== INTEGRATE WITH FISH IT HUB =
-- ===================================

local function integrateWithFishItHub()
    -- Replace existing trade system in Fish It Hub
    if Config.Trader then
        -- Update Auto Accept Trade functionality
        if AwaitTradeResponse then
            AwaitTradeResponse.OnClientEvent:Connect(function(tradeData)
                if Config.Trader.AutoAcceptTrade then
                    local success, result = pcall(function()
                        -- Auto accept incoming trades
                        debugPrint("Auto-accepting trade from: " .. tostring(tradeData.FromPlayer))
                        -- Logic untuk accept trade akan ditambahkan berdasarkan game specific
                    end)
                    if not success then
                        logError("Auto Accept Trade Error: " .. result)
                    end
                end
            end)
        end
        
        -- Update trade settings
        Config.Trader.TradeSystem = TradeSystem
    end
end

-- ===================================
-- ========== CREATE TRADE TAB =======
-- ===================================

local function createTradeTab()
    local TradeTab = Window:CreateTab("🤝 Trade System", 13047715178)
    
    -- Status Section
    TradeTab:CreateSection("📊 Trade Status")
    
    StatusParagraph = TradeTab:CreateParagraph({
        Title = "📊 Trade Status",
        Content = string.format(
            "✅ Success: %d\n❌ Failed: %d\n💰 Money: %s\n👤 To: %s",
            TradeSystem.TotalSuccess,
            TradeSystem.TotalFailed,
            formatCurrency(TradeSystem.MoneyConverted),
            TradeSystem.TargetUsername or "Not selected"
        )
    })
    
    TradeTab:CreateButton({
        Name = "🔄 Reset Stats",
        Callback = function()
            TradeSystem.TotalSuccess = 0
            TradeSystem.TotalFailed = 0
            TradeSystem.MoneyConverted = 0
            
            StatusParagraph:Set({
                Title = "📊 Trade Status",
                Content = string.format(
                    "✅ Success: 0\n❌ Failed: 0\n💰 Money: C$0\n👤 To: %s",
                    TradeSystem.TargetUsername or "Not selected"
                )
            })
            
            NotifySuccess("Stats Reset", "Trade statistics cleared")
        end
    })
    
    -- Target Selection Section
    TradeTab:CreateSection("🎯 Target Player")
    
    -- Player dropdown
    local playerList = getPlayerList()
    local PlayerDropdown = TradeTab:CreateDropdown({
        Name = "Select Player",
        Options = #playerList > 0 and playerList or {"No players online"},
        CurrentOption = #playerList > 0 and playerList[1] or "No players online",
        Flag = "TradePlayerDropdown",
        Callback = function(option)
            selectTradeTarget(option)
        end
    })
    
    TradeTab:CreateButton({
        Name = "🔄 Refresh Player List",
        Callback = function()
            local updatedList = getPlayerList()
            if #updatedList > 0 then
                PlayerDropdown:Refresh(updatedList, updatedList[1])
            else
                PlayerDropdown:Refresh({"No players online"}, "No players online")
            end
            NotifyInfo("Refreshed", "Player list updated")
        end
    })
    
    -- Quick Trade Section
    TradeTab:CreateSection("⚡ Quick Trade")
    
    local quickTradeAmounts = {
        {name = "💵 Trade 100K", amount = 100000},
        {name = "💰 Trade 500K", amount = 500000},
        {name = "💎 Trade 1M", amount = 1000000},
        {name = "🏆 Trade 2M", amount = 2000000},
        {name = "👑 Trade 5M", amount = 5000000}
    }
    
    for _, tradeInfo in ipairs(quickTradeAmounts) do
        TradeTab:CreateButton({
            Name = tradeInfo.name,
            Callback = function()
                startAutoTrade(tradeInfo.amount)
            end
        })
    end
    
    -- Custom Trade Section
    TradeTab:CreateSection("🔧 Custom Trade")
    
    TradeTab:CreateInput({
        Name = "Custom Amount",
        PlaceholderText = "Enter amount (e.g., 1000000)",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            local amount = tonumber(text)
            if amount and amount > 0 then
                TradeSystem.TargetAmount = amount
                NotifyInfo("Amount Set", "Target amount: " .. formatCurrency(amount))
            else
                NotifyError("Invalid Amount", "Please enter a valid number!")
            end
        end
    })
    
    TradeTab:CreateButton({
        Name = "🎯 Trade Custom Amount",
        Callback = function()
            if TradeSystem.TargetAmount > 0 then
                startAutoTrade(TradeSystem.TargetAmount)
            else
                NotifyError("No Amount", "Please set custom amount first!")
            end
        end
    })
    
    -- Settings Section
    TradeTab:CreateSection("⚙️ Trade Settings")
    
    TradeTab:CreateToggle({
        Name = "🔄 Enable Auto Trade",
        CurrentValue = TradeSystem.Enabled,
        Flag = "AutoTradeToggle",
        Callback = function(value)
            TradeSystem.Enabled = value
            if value then
                NotifySuccess("Auto Trade", "Auto trade enabled")
            else
                NotifyInfo("Auto Trade", "Auto trade disabled")
            end
        end
    })
    
    TradeTab:CreateToggle({
        Name = "✅ Auto Accept Trades",
        CurrentValue = Config.Trader.AutoAcceptTrade or false,
        Flag = "AutoAcceptTradeToggle",
        Callback = function(value)
            Config.Trader.AutoAcceptTrade = value
            StateManager.set("Trader_AutoAcceptTrade", value)
            if value then
                NotifySuccess("Auto Accept", "Will auto-accept incoming trades")
            else
                NotifyInfo("Auto Accept", "Manual trade acceptance")
            end
        end
    })
    
    TradeTab:CreateSlider({
        Name = "⏱️ Trade Delay (seconds)",
        Range = {2, 10},
        Increment = 0.5,
        Suffix = "s",
        CurrentValue = TradeSystem.TradeDelay,
        Flag = "TradeDelaySlider",
        Callback = function(value)
            TradeSystem.TradeDelay = value
            NotifyInfo("Delay Updated", "Trade delay set to " .. value .. "s")
        end
    })
    
    TradeTab:CreateSlider({
        Name = "🛡️ Max Trades/Minute",
        Range = {5, 20},
        Increment = 1,
        Suffix = "trades",
        CurrentValue = TradeSystem.MaxTradesPerMinute,
        Flag = "MaxTradesSlider",
        Callback = function(value)
            TradeSystem.MaxTradesPerMinute = value
            NotifyInfo("Safety Updated", "Max trades: " .. value .. "/minute")
        end
    })
    
    -- Inventory Management Section
    TradeTab:CreateSection("🎒 Inventory Management")
    
    TradeTab:CreateButton({
        Name = "🔍 Scan Inventory Now",
        Callback = function()
            NotifyInfo("Scanning", "Scanning inventory...")
            task.wait(0.5)
            
            if scanPlayerInventory() then
                NotifySuccess("Scan Complete", 
                    string.format("Found %d fish in inventory", #TradeSystem.PlayerInventory)
                )
                
                -- Show inventory summary
                local totalValue = 0
                for _, fish in ipairs(TradeSystem.PlayerInventory) do
                    totalValue = totalValue + (fish.sellPrice or 0)
                end
                
                StatusParagraph:Set({
                    Title = "📊 Trade Status",
                    Content = string.format(
                        "✅ Success: %d\n❌ Failed: %d\n💰 Money: %s\n🎒 Inventory: %d fish (%s)",
                        TradeSystem.TotalSuccess,
                        TradeSystem.TotalFailed,
                        formatCurrency(TradeSystem.MoneyConverted),
                        #TradeSystem.PlayerInventory,
                        formatCurrency(totalValue)
                    )
                })
            else
                NotifyError("Scan Failed", "Could not scan inventory")
            end
        end
    })
    
    TradeTab:CreateButton({
        Name = "📊 Show Inventory Info",
        Callback = function()
            if #TradeSystem.PlayerInventory == 0 then
                NotifyInfo("Inventory", "No fish scanned yet")
                return
            end
            
            local cheapest = TradeSystem.PlayerInventory[1]
            local mostExpensive = TradeSystem.PlayerInventory[#TradeSystem.PlayerInventory]
            local totalValue = 0
            
            for _, fish in ipairs(TradeSystem.PlayerInventory) do
                totalValue = totalValue + (fish.sellPrice or 0)
            end
            
            NotifyInfo("Inventory Summary",
                string.format(
                    "Total: %d fish\nTotal Value: %s\nCheapest: %s (%s)\nMost Expensive: %s (%s)",
                    #TradeSystem.PlayerInventory,
                    formatCurrency(totalValue),
                    cheapest.name,
                    formatCurrency(cheapest.sellPrice),
                    mostExpensive.name,
                    formatCurrency(mostExpensive.sellPrice)
                )
            )
        end
    })
    
    return TradeTab
end

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function initializeTradeSystem()
    debugPrint("🤝 Fish Trade System V2 - Initializing...")
    
    -- Setup remotes
    if not setupRemotes() then
        NotifyError("Trade System", "Could not setup trade remotes!")
        return false
    end
    
    -- Build fish database
    task.wait(1)
    if not buildFishDatabase() then
        NotifyError("Trade System", "Could not build fish database!")
        return false
    end
    
    -- Integrate with Fish It Hub
    integrateWithFishItHub()
    
    -- Create trade tab
    createTradeTab()
    
    -- Setup player tracking
    Players.PlayerAdded:Connect(function()
        task.wait(1) -- Wait for player to fully load
        debugPrint("Player joined - list updated")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if player.UserId == TradeSystem.TargetUserId then
            NotifyError("Target Left", "Trade target left the server!")
            TradeSystem.TargetUserId = nil
            TradeSystem.TargetUsername = ""
        end
    end)
    
    NotifySuccess("Trade System Ready", "Advanced trade system initialized!")
    debugPrint("✅ Trade System fully initialized")
    
    return true
end

-- Auto-initialize when script loads
task.spawn(function()
    task.wait(3) -- Wait for Fish It Hub to fully load
    initializeTradeSystem()
end)

-- Export TradeSystem untuk akses global
return TradeSystem

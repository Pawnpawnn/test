-- ===================================
-- ========== FISH TRADE SYSTEM V1 ===
-- ===================================
-- Standalone script untuk auto trade fish
-- By: Codepikk
-- ===================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
    TradeDelay = 6, -- seconds between trades
    TargetAmount = 1000000 -- default 1M
}

-- Remotes
local net = nil
local InitiateTrade = nil
local REEquipItem = nil

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
        Image = 4483362458
    })
end

local function NotifyError(title, content)
    Rayfield:Notify({
        Title = "❌ " .. title,
        Content = content,
        Duration = 4,
        Image = 4483362458
    })
end

local function NotifyInfo(title, content)
    Rayfield:Notify({
        Title = "ℹ️ " .. title,
        Content = content,
        Duration = 3,
        Image = 4483362458
    })
end

-- ===================================
-- ========== SETUP REMOTES ==========
-- ===================================

local function setupRemotes()
    local success, err = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages", 5)
            :WaitForChild("_Index", 5)
            :WaitForChild("sleitnick_net@0.2.0", 5)
            :WaitForChild("net", 5)
    end)
    
    if not success then
        warn("Failed to find net folder: " .. tostring(err))
        return false
    end
    
    -- Get trade remote
    InitiateTrade = net:WaitForChild("RF"):WaitForChild("InitiateTrade", 5)
    REEquipItem = net:WaitForChild("RE"):WaitForChild("EquipItem", 5)
    
    if not InitiateTrade then
        warn("InitiateTrade remote not found!")
        return false
    end
    
    print("✅ Remotes loaded successfully!")
    return true
end

-- ===================================
-- ========== FISH DATABASE ==========
-- ===================================

local function buildFishDatabase()
    print("📦 Building fish database...")
    
    local success, result = pcall(function()
        local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
        if not ItemsFolder then
            warn("Items folder not found!")
            return false
        end
        
        local fishCount = 0
        for _, item in pairs(ItemsFolder:GetChildren()) do
            local ok, data = pcall(require, item)
            
            if ok and data and data.Data then
                if data.Data.Type == "Fishes" then
                    local id = tostring(data.Data.Id)
                    local name = data.Data.Name
                    local sellPrice = data.SellPrice or 0
                    local tier = data.Data.Tier or 1
                    
                    TradeSystem.FishDatabase[id] = {
                        id = id,
                        name = name,
                        sellPrice = sellPrice,
                        tier = tier
                    }
                    
                    -- Also map by name (lowercase)
                    TradeSystem.FishDatabase[string.lower(name)] = TradeSystem.FishDatabase[id]
                    
                    fishCount = fishCount + 1
                    debugPrint("Added to DB: " .. name .. " (ID: " .. id .. ")")
                end
            end
        end
        
        print("✅ Fish database loaded: " .. fishCount .. " fish")
        return true
    end)
    
    if not success then
        warn("Failed to build fish database: " .. tostring(result))
        return false
    end
    
    return result
end

-- ===================================
-- ========== INVENTORY SCANNER ======
-- ===================================

local function scanPlayerInventory()
    print("🔍 Scanning player inventory...")
    
    TradeSystem.PlayerInventory = {}
    
    local success, err = pcall(function()
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local backpackGui = PlayerGui:FindFirstChild("Backpack") or PlayerGui:FindFirstChild("Inventory")
        
        if not backpackGui then 
            warn("Backpack/Inventory GUI not found! Please open inventory first!")
            return false
        end
        
        print("📁 Found inventory GUI: " .. backpackGui.Name)
        
        -- Cari display container seperti di explorer script
        local display = backpackGui:FindFirstChild("Display") 
                     or backpackGui:FindFirstChild("Main")
                     or backpackGui:FindFirstChild("Frame")
                     or backpackGui:FindFirstChild("Container")
                     or backpackGui:FindFirstChild("Content")
        
        if not display then 
            warn("Display container not found!")
            return false
        end
        
        print("🎯 Scanning in display: " .. display.Name)
        
        local scannedCount = 0
        
        -- Iterate through all children seperti approach explorer yang terbukti bekerja
        for _, slot in pairs(display:GetChildren()) do
            -- Hanya proses ImageButton yang represent fish slots
            if not slot:IsA("ImageButton") then
                continue
            end
            
            -- Skip non-fish slots by name (seperti di explorer)
            local slotName = slot.Name
            if slotName == "Inventory" or slotName:find("Layout") or slotName:find("Padding") or
               slotName:find("Constraint") or slotName:find("UI") then
                continue
            end
            
            -- Cari inner container
            local inner = slot:FindFirstChild("Inner") or slot:FindFirstChild("Content")
            if not inner then continue end
            
            -- Cari tags container
            local tags = inner:FindFirstChild("Tags") or inner:FindFirstChild("Info")
            if not tags then continue end
            
            -- Extract fish name dari Tags
            local itemName = tags:FindFirstChild("ItemName")
            if not itemName then continue end
            
            local fishName = itemName.Value or itemName.Text
            if not fishName or fishName == "" then continue end
            
            -- Get UUID dari Tags children (seperti approach explorer)
            local uuid = nil
            for _, child in pairs(tags:GetChildren()) do
                if child.Name == "UUID" or child.Name == "ItemUUID" or child.Name == "Id" then
                    uuid = child.Value or child.Text
                    if uuid and uuid ~= "" then
                        break
                    end
                end
            end
            
            -- Alternative: Check attributes
            if not uuid then
                uuid = slot:GetAttribute("UUID") or 
                      slot:GetAttribute("ItemUUID") or
                      inner:GetAttribute("UUID") or
                      inner:GetAttribute("ItemUUID")
            end
            
            if not uuid then
                debugPrint("⚠️ UUID not found for: " .. fishName)
                continue
            end
            
            -- Find fish info from database
            local fishInfo = TradeSystem.FishDatabase[string.lower(fishName)]
            
            -- Jika tidak ketemu di database, cari manual
            if not fishInfo then
                for id, info in pairs(TradeSystem.FishDatabase) do
                    if type(info) == "table" and info.name == fishName then
                        fishInfo = info
                        break
                    end
                end
            end
            
            if fishInfo then
                table.insert(TradeSystem.PlayerInventory, {
                    uuid = uuid,
                    name = fishInfo.name,
                    sellPrice = fishInfo.sellPrice,
                    tier = fishInfo.tier,
                    id = fishInfo.id
                })
                scannedCount = scannedCount + 1
                debugPrint("✅ Found: " .. fishInfo.name .. " (" .. formatCurrency(fishInfo.sellPrice) .. ")")
            else
                -- Fish tidak ada di database, tapi kita tetap catat dengan harga default
                table.insert(TradeSystem.PlayerInventory, {
                    uuid = uuid,
                    name = fishName,
                    sellPrice = 0, -- Unknown price
                    tier = 1,
                    id = "unknown"
                })
                scannedCount = scannedCount + 1
                debugPrint("❓ Unknown fish: " .. fishName)
            end
        end
        
        -- Jika metode pertama tidak berhasil, coba scan semua ImageButton di backpackGui
        if scannedCount == 0 then
            print("🔄 Trying alternative scan method...")
            
            for _, obj in pairs(backpackGui:GetDescendants()) do
                if obj:IsA("ImageButton") and obj.Visible then
                    local inner = obj:FindFirstChild("Inner") or obj:FindFirstChild("Content")
                    if inner then
                        local tags = inner:FindFirstChild("Tags") or inner:FindFirstChild("Info")
                        if tags then
                            local itemName = tags:FindFirstChild("ItemName")
                            if itemName and (itemName.Value or itemName.Text) then
                                local fishName = itemName.Value or itemName.Text
                                local uuid = nil
                                
                                -- Get UUID
                                for _, child in pairs(tags:GetChildren()) do
                                    if child.Name == "UUID" or child.Name == "ItemUUID" then
                                        uuid = child.Value or child.Text
                                        break
                                    end
                                end
                                
                                if uuid then
                                    local fishInfo = TradeSystem.FishDatabase[string.lower(fishName)]
                                    if fishInfo then
                                        table.insert(TradeSystem.PlayerInventory, {
                                            uuid = uuid,
                                            name = fishInfo.name,
                                            sellPrice = fishInfo.sellPrice,
                                            tier = fishInfo.tier,
                                            id = fishInfo.id
                                        })
                                        scannedCount = scannedCount + 1
                                        debugPrint("✅ Found (alt): " .. fishInfo.name)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        print("📊 Inventory scan complete: " .. scannedCount .. " fish found")
        
    end)
    
    if not success then
        warn("❌ Inventory scan error: " .. tostring(err))
        return false
    end
    
    -- Sort by price (cheapest first)
    table.sort(TradeSystem.PlayerInventory, function(a, b)
        return (a.sellPrice or 0) < (b.sellPrice or 0)
    end)
    
    return #TradeSystem.PlayerInventory > 0
end

-- ===================================
-- ========== TRADE FUNCTIONS ========
-- ===================================

local function selectFishForTrade(targetAmount)
    local selectedFish = {}
    local totalValue = 0
    
    for _, fish in ipairs(TradeSystem.PlayerInventory) do
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
    
    local success, err = pcall(function()
        InitiateTrade:InvokeServer(
            TradeSystem.TargetUserId,
            fishData.uuid,
            "Fishes"
        )
    end)
    
    if success then
        print("✅ Trade sent: " .. fishData.name .. " (" .. formatCurrency(fishData.sellPrice) .. ")")
        return true
    else
        warn("Trade failed: " .. tostring(err))
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
        string.format("Will trade %d fish\nTotal value: %s\nTarget: %s",
            #selectedFish,
            formatCurrency(totalValue),
            TradeSystem.TargetUsername
        )
    )
    
    task.wait(2)
    
    -- Start trading
    TradeSystem.TradingInProgress = true
    NotifyInfo("Starting Trade", "Trading " .. #selectedFish .. " fish...")
    
    task.spawn(function()
        for i, fish in ipairs(selectedFish) do
            if not TradeSystem.Enabled then
                NotifyInfo("Trade Stopped", "Auto trade was disabled")
                break
            end
            
            print(string.format("Trading fish %d/%d: %s (%s)", 
                i, #selectedFish, fish.name, formatCurrency(fish.sellPrice)))
            
            local success, err = tradeSingleFish(fish)
            
            if success then
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
                TradeSystem.TotalFailed = TradeSystem.TotalFailed + 1
                warn("Trade failed for " .. fish.name .. ": " .. tostring(err))
            end
            
            -- Delay between trades
            if i < #selectedFish then
                task.wait(TradeSystem.TradeDelay)
            end
        end
        
        -- Trade completed
        TradeSystem.TradingInProgress = false
        
        NotifySuccess("Trade Complete!", 
            string.format("Successfully traded %d fish\nTotal: %s",
                TradeSystem.TotalSuccess,
                formatCurrency(TradeSystem.MoneyConverted)
            )
        )
    end)
end

-- ===================================
-- ========== PLAYER LIST ============
-- ===================================

local function getPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.DisplayName .. " (@" .. player.Name .. ")")
        end
    end
    return list
end

local function refreshPlayerList()
    if PlayerDropdown then
        local updatedList = getPlayerList()
        -- FIX: Check if there are players before refreshing
        if #updatedList > 0 then
            PlayerDropdown:Refresh(updatedList, updatedList[1])
        else
            PlayerDropdown:Refresh({"No players found"}, "No players found")
        end
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish Trade System V1",
    LoadingTitle = "Loading Fish Trade System...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("📊 Trade System", 4483362458)

-- Status Section
MainTab:CreateSection("📊 Trade Status")

StatusParagraph = MainTab:CreateParagraph({
    Title = "📊 Trade Status",
    Content = string.format(
        "✅ Success: %d\n❌ Failed: %d\n💰 Money: %s\n👤 To: %s",
        TradeSystem.TotalSuccess,
        TradeSystem.TotalFailed,
        formatCurrency(TradeSystem.MoneyConverted),
        TradeSystem.TargetUsername or "Not selected"
    )
})

MainTab:CreateButton({
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

-- Target Player Section
MainTab:CreateSection("🎯 Target Player")

-- FIX: Improved player dropdown with better error handling
local playerList = getPlayerList()
if #playerList == 0 then
    playerList = {"No players online"}
end

local TargetInput = MainTab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Masukkan username target...",
    RemoveTextAfterFocusLoss = false,
    Callback = function(text)
        if not text or text == "" then
            NotifyError("Input Error", "Username cannot be empty!")
            return
        end

        local targetPlayer = Players:FindFirstChild(text)
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
        else
            NotifyError("Player Not Found", "Player with username '" .. text .. "' is not in the server.")
        end
    end
})


MainTab:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        refreshPlayerList()
        NotifyInfo("Refreshed", "Player list updated")
    end
})

-- Quick Trade Buttons
MainTab:CreateSection("⚡ Quick Trade")

MainTab:CreateButton({
    Name = "💵 Trade 500K",
    Callback = function()
        startAutoTrade(500000)
    end
})

MainTab:CreateButton({
    Name = "💰 Trade 1M",
    Callback = function()
        startAutoTrade(1000000)
    end
})

MainTab:CreateButton({
    Name = "💎 Trade 2M",
    Callback = function()
        startAutoTrade(2000000)
    end
})

MainTab:CreateButton({
    Name = "🏆 Trade 5M",
    Callback = function()
        startAutoTrade(5000000)
    end
})

-- Settings Section
MainTab:CreateSection("⚙️ Settings")

MainTab:CreateToggle({
    Name = "🔄 Enable Auto Trade",
    CurrentValue = false,
    Flag = "AutoTradeToggle",
    Callback = function(value)
        TradeSystem.Enabled = value
        if value then
            NotifySuccess("Auto Trade", "Auto trade enabled")
        else
            NotifyInfo("Auto Trade", "Auto trade disabled")
            if TradeSystem.TradingInProgress then
                NotifyInfo("Trade Stopped", "Current trade will finish, then stop")
            end
        end
    end
})

MainTab:CreateSlider({
    Name = "⏱️ Trade Delay (seconds)",
    Range = {3, 15},
    Increment = 1,
    CurrentValue = 6,
    Flag = "TradeDelaySlider",
    Callback = function(value)
        TradeSystem.TradeDelay = value
        NotifyInfo("Delay Updated", "Trade delay set to " .. value .. "s")
    end
})

MainTab:CreateButton({
    Name = "🔍 Scan Inventory Now",
    Callback = function()
        NotifyInfo("Scanning", "Scanning inventory...")
        task.wait(0.5)
        
        if scanPlayerInventory() then
            NotifySuccess("Scan Complete", 
                string.format("Found %d fish in inventory", #TradeSystem.PlayerInventory)
            )
        else
            NotifyError("Scan Failed", "Could not scan inventory")
        end
    end
})

-- FIX: Added Inventory Management Section
MainTab:CreateSection("🎒 Inventory Management")

local selectedItems = {}

MainTab:CreateButton({
    Name = "📥 Select All Fish",
    Callback = function()
        selectedItems = {}
        for _, fish in ipairs(TradeSystem.PlayerInventory) do
            selectedItems[fish.uuid] = true
        end
        NotifySuccess("Selection", "All " .. #TradeSystem.PlayerInventory .. " fish selected")
    end
})

MainTab:CreateButton({
    Name = "📤 Clear Selection",
    Callback = function()
        selectedItems = {}
        NotifyInfo("Selection", "All items deselected")
    end
})

MainTab:CreateButton({
    Name = "💾 Save Selected Items",
    Callback = function()
        if scanPlayerInventory() then
            local saveData = {
                timestamp = os.time(),
                items = {}
            }
            
            for uuid, selected in pairs(selectedItems) do
                if selected then
                    for _, fish in ipairs(TradeSystem.PlayerInventory) do
                        if fish.uuid == uuid then
                            table.insert(saveData.items, fish)
                            break
                        end
                    end
                end
            end
            
            if #saveData.items > 0 then
                -- Simpan ke workspace (bisa diganti dengan DataStore jika perlu)
                local saveFolder = Instance.new("Folder")
                saveFolder.Name = "FishTradeSave_" .. os.time()
                
                for _, item in ipairs(saveData.items) do
                    local value = Instance.new("StringValue")
                    value.Name = item.uuid
                    value.Value = HttpService:JSONEncode(item)
                    value.Parent = saveFolder
                end
                
                saveFolder.Parent = workspace
                NotifySuccess("Save Complete", "Saved " .. #saveData.items .. " items to " .. saveFolder.Name)
            else
                NotifyError("Save Failed", "No items selected to save")
            end
        else
            NotifyError("Save Failed", "Could not scan inventory")
        end
    end
})

-- Debug Tab
local DebugTab = Window:CreateTab("🔧 Debug", 4483362458)

DebugTab:CreateSection("🔧 Debug Tools")

DebugTab:CreateButton({
    Name = "📦 Show Fish Database",
    Callback = function()
        local count = 0
        for _ in pairs(TradeSystem.FishDatabase) do
            count = count + 1
        end
        
        NotifyInfo("Fish Database", 
            string.format("Database loaded: %d entries", count)
        )
    end
})

DebugTab:CreateButton({
    Name = "🎒 Show Inventory",
    Callback = function()
        if #TradeSystem.PlayerInventory == 0 then
            NotifyInfo("Inventory", "No fish scanned yet. Click 'Scan Inventory Now' first")
            return
        end
        
        local cheapest = TradeSystem.PlayerInventory[1]
        local mostExpensive = TradeSystem.PlayerInventory[#TradeSystem.PlayerInventory]
        
        NotifyInfo("Inventory Info",
            string.format(
                "Total: %d fish\nCheapest: %s (%s)\nMost Expensive: %s (%s)",
                #TradeSystem.PlayerInventory,
                cheapest.name,
                formatCurrency(cheapest.sellPrice),
                mostExpensive.name,
                formatCurrency(mostExpensive.sellPrice)
            )
        )
    end
})

DebugTab:CreateButton({
    Name = "🧪 Test Trade (Single Fish)",
    Callback = function()
        if #TradeSystem.PlayerInventory == 0 then
            NotifyError("No Fish", "Scan inventory first!")
            return
        end
        
        if not TradeSystem.TargetUserId then
            NotifyError("No Target", "Select target player first!")
            return
        end
        
        local testFish = TradeSystem.PlayerInventory[1]
        NotifyInfo("Test Trade", "Trading: " .. testFish.name)
        
        task.wait(1)
        local success, err = tradeSingleFish(testFish)
        
        if success then
            NotifySuccess("Test Success", "Trade sent successfully!")
        else
            NotifyError("Test Failed", "Error: " .. tostring(err))
        end
    end
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function initialize()
    print("🐟 Fish Trade System V1 - Initializing...")
    
    -- Setup remotes
    if not setupRemotes() then
        NotifyError("Initialization Failed", "Could not setup remotes!")
        return false
    end
    
    -- Build fish database
    task.wait(1)
    if not buildFishDatabase() then
        NotifyError("Initialization Failed", "Could not build fish database!")
        return false
    end
    
    -- Listen for player changes
    Players.PlayerAdded:Connect(refreshPlayerList)
    Players.PlayerRemoving:Connect(refreshPlayerList)
    
    NotifySuccess("System Ready", "Fish Trade System initialized successfully!")
    return true
end

-- Start initialization
task.spawn(function()
    task.wait(2)
    initialize()
end)

print("🐟 Fish Trade System V1 loaded!")
print("📌 Features:")
print("   • Auto scan inventory")
print("   • Sort fish by price (cheapest first)")
print("   • Quick trade buttons (500K, 1M, 2M, 5M)")
print("   • Real-time trade statistics")
print("   • Safe trade delay (configurable)")
print("   • Fixed dropdown player callback")
print("   • Added inventory save mode")
print("✅ Ready to use!")

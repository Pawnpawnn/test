-- ===================================
-- ========== FISH TRADE SYSTEM V3 ===
-- ===================================
-- Standalone script untuk auto trade fish
-- Menggunakan approach yang terbukti bekerja dari Fish It Explorer
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
    TargetAmount = 1000000, -- default 1M
    
    -- Debug
    DebugMode = false
}

-- Remotes
local net = nil
local InitiateTrade = nil

-- UI References
local StatusParagraph = nil
local PlayerDropdown = nil

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

local function debugPrint(message)
    if TradeSystem.DebugMode then
        print("🐛 [DEBUG] " .. message)
    end
end

-- ===================================
-- ========== SETUP REMOTES ==========
-- ===================================

local function setupRemotes()
    local success, err = pcall(function()
        -- Cari net framework seperti di explorer script
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
        if #updatedList > 0 then
            PlayerDropdown:Refresh(updatedList, updatedList[1])
        else
            PlayerDropdown:Refresh({"No players found"}, "No players found")
        end
    end
end

-- ===================================
-- ========== GUI ANALYSIS ===========
-- ===================================

local function analyzeGUIStructure()
    print("=== GUI STRUCTURE ANALYSIS ===")
    
    local function printStructure(obj, depth, maxDepth)
        if depth > (maxDepth or 3) then return end
        
        local prefix = string.rep("  ", depth)
        local info = prefix .. obj.Name .. " (" .. obj.ClassName .. ")"
        
        -- Check for interesting attributes
        local attributes = {}
        local uuid = obj:GetAttribute("UUID")
        if uuid then table.insert(attributes, "UUID=" .. tostring(uuid)) end
        
        local itemId = obj:GetAttribute("ItemId")
        if itemId then table.insert(attributes, "ItemId=" .. tostring(itemId)) end
        
        if #attributes > 0 then
            info = info .. " [" .. table.concat(attributes, ", ") .. "]"
        end
        
        print(info)
        
        for _, child in ipairs(obj:GetChildren()) do
            printStructure(child, depth + 1, maxDepth)
        end
    end
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (string.find(gui.Name:lower(), "inventory") or string.find(gui.Name:lower(), "backpack") or gui.Enabled) then
            print("=== " .. gui.Name .. " ===")
            printStructure(gui, 0, 2)
        end
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish Trade System V3",
    LoadingTitle = "Loading Fish Trade System...",
    LoadingSubtitle = "by Codepikk - Enhanced Scanner",
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

PlayerDropdown = MainTab:CreateDropdown({
    Name = "Select Target Player",
    Options = getPlayerList(),
    CurrentOption = getPlayerList()[1] or "No players",
    Flag = "TargetPlayerDropdown",
    Callback = function(selected)
        -- Extract username dari format "DisplayName (@Username)"
        local username = selected:match("@(.-)%)")
        if not username then
            username = selected:match("%((.-)%)")
        end
        
        if username then
            local targetPlayer = Players:FindFirstChild(username)
            if targetPlayer then
                TradeSystem.TargetUserId = targetPlayer.UserId
                TradeSystem.TargetUsername = targetPlayer.Name
                
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
                
                NotifySuccess("Target Set", "Trading to: " .. targetPlayer.Name)
            else
                NotifyError("Player Not Found", "Could not find player: " .. username)
            end
        else
            NotifyError("Invalid Selection", "Please select a valid player")
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
    Name = "💵 Trade 100K",
    Callback = function()
        startAutoTrade(100000)
    end
})

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

MainTab:CreateButton({
    Name = "🎯 Custom Amount",
    Callback = function()
        Rayfield:Prompt({
            Title = "Custom Trade Amount",
            SubTitle = "Enter amount in cash:",
            TextInput = {
                Text = "1000000",
                PlaceholderText = "Enter amount"
            }
        }).then(function(result)
            if result and tonumber(result) then
                local amount = tonumber(result)
                if amount > 0 then
                    startAutoTrade(amount)
                else
                    NotifyError("Invalid Amount", "Please enter a positive number")
                end
            end
        end)
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

-- Debug Tab
local DebugTab = Window:CreateTab("🔧 Debug", 4483362458)

DebugTab:CreateSection("🔧 Debug Tools")

DebugTab:CreateToggle({
    Name = "🐛 Debug Mode",
    CurrentValue = false,
    Flag = "DebugModeToggle",
    Callback = function(value)
        TradeSystem.DebugMode = value
        if value then
            NotifyInfo("Debug Mode", "Debug mode enabled - check console")
        else
            NotifyInfo("Debug Mode", "Debug mode disabled")
        end
    end
})

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
        
        -- Show some sample fish
        local sampleCount = 0
        for id, fish in pairs(TradeSystem.FishDatabase) do
            if type(fish) == "table" and fish.name then
                print(string.format("  %s: %s (%s)", fish.id, fish.name, formatCurrency(fish.sellPrice)))
                sampleCount = sampleCount + 1
                if sampleCount >= 10 then break end
            end
        end
    end
})

DebugTab:CreateButton({
    Name = "🎒 Show Inventory Details",
    Callback = function()
        if #TradeSystem.PlayerInventory == 0 then
            NotifyInfo("Inventory", "No fish scanned yet. Click 'Scan Inventory Now' first")
            return
        end
        
        local cheapest = TradeSystem.PlayerInventory[1]
        local mostExpensive = TradeSystem.PlayerInventory[#TradeSystem.PlayerInventory]
        local totalValue = 0
        
        for _, fish in ipairs(TradeSystem.PlayerInventory) do
            totalValue = totalValue + (fish.sellPrice or 0)
        end
        
        NotifyInfo("Inventory Info",
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
        
        -- Print first 5 fish for debugging
        print("=== First 5 Fish ===")
        for i = 1, math.min(5, #TradeSystem.PlayerInventory) do
            local fish = TradeSystem.PlayerInventory[i]
            print(string.format("%d. %s - %s (Tier %d)", i, fish.name, formatCurrency(fish.sellPrice), fish.tier))
        end
    end
})

DebugTab:CreateButton({
    Name = "🔍 Debug GUI Structure",
    Callback = function()
        NotifyInfo("Debug", "Analyzing GUI structure... Check console!")
        task.spawn(analyzeGUIStructure)
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
        NotifyInfo("Test Trade", "Trading: " .. testFish.name .. " (" .. formatCurrency(testFish.sellPrice) .. ")")
        
        task.wait(1)
        local success, err = tradeSingleFish(testFish)
        
        if success then
            NotifySuccess("Test Success", "Trade sent successfully!")
        else
            NotifyError("Test Failed", "Error: " .. tostring(err))
        end
    end
})

DebugTab:CreateButton({
    Name = "🔄 Reinitialize System",
    Callback = function()
        NotifyInfo("Reinitializing", "Restarting system...")
        task.wait(1)
        
        TradeSystem.FishDatabase = {}
        TradeSystem.PlayerInventory = {}
        
        if buildFishDatabase() then
            NotifySuccess("Reinitialized", "System restarted successfully!")
        else
            NotifyError("Reinit Failed", "Could not rebuild database")
        end
    end
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function initialize()
    print("🐟 Fish Trade System V3 - Initializing...")
    
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
    
    -- Auto-refresh player list
    refreshPlayerList()
    
    -- Listen for player changes
    Players.PlayerAdded:Connect(refreshPlayerList)
    Players.PlayerRemoving:Connect(refreshPlayerList)
    
    NotifySuccess("System Ready", "Fish Trade System V3 initialized successfully!")
    
    -- Auto instructions
    task.wait(3)
    NotifyInfo("How to Use", 
        "1. Open Backpack/Inventory first\n" ..
        "2. Select target player\n" ..
        "3. Scan inventory\n" ..
        "4. Start trading!"
    )
    
    return true
end

-- Start initialization
task.spawn(function()
    task.wait(2)
    local success = initialize()
    if not success then
        NotifyError("Initialization Failed", "Please re-execute the script")
    end
end)

print("🐟 Fish Trade System V3 loaded!")
print("📌 Features:")
print("   • Enhanced inventory scanner (Backpack-based)")
print("   • Proven approach from Fish It Explorer")
print("   • Better error handling")
print("   • Debug tools for troubleshooting")
print("   • Custom trade amounts")
print("   • Real-time statistics")
print("✅ Ready to use!")

-- Auto-scan reminder
task.spawn(function()
    task.wait(10)
    if #TradeSystem.PlayerInventory == 0 then
        NotifyInfo("Reminder", "Don't forget to open your Backpack/Inventory and click 'Scan Inventory Now'!")
    end
end)

-- ===================================
-- ========== FISH TRADE SYSTEM V2 ===
-- ===================================
-- Manual Mode - Click to Save & Trade
-- By: Codepikk
-- ===================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local TradeSystem = {
    SaveMode = false,
    TradingInProgress = false,
    TargetUserId = nil,
    TargetUsername = "Not selected",
    
    -- Saved fish list
    SavedFishList = {},
    
    -- Stats
    TotalSuccess = 0,
    TotalFailed = 0,
    TotalTraded = 0,
    
    -- Settings
    TradeDelay = 6, -- seconds
}

-- Remotes
local net = nil
local InitiateTrade = nil
local REEquipItem = nil
local RFAwaitTradeResponse = nil

-- UI Elements
local StatusParagraph = nil
local PlayerDropdown = nil
local SavedFishLabel = nil

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

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

local function NotifyWarning(title, content)
    Rayfield:Notify({
        Title = "⚠️ " .. title,
        Content = content,
        Duration = 3,
        Image = 4483362458
    })
end

local function UpdateStatusUI()
    if StatusParagraph then
        StatusParagraph:Set({
            Title = "📊 Trade Status",
            Content = string.format(
                "✅ Success: %d\n❌ Failed: %d\n📦 Total Traded: %d\n👤 Target: %s",
                TradeSystem.TotalSuccess,
                TradeSystem.TotalFailed,
                TradeSystem.TotalTraded,
                TradeSystem.TargetUsername
            )
        })
    end
end

local function UpdateSavedFishLabel()
    if SavedFishLabel then
        SavedFishLabel:Set("📦 Saved Fish: " .. #TradeSystem.SavedFishList)
    end
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
        NotifyError("Setup Failed", "Could not find net folder")
        return false
    end
    
    -- Get remotes
    local RF = net:WaitForChild("RF", 5)
    local RE = net:WaitForChild("RE", 5)
    
    if not RF or not RE then
        NotifyError("Setup Failed", "RF or RE folder not found")
        return false
    end
    
    InitiateTrade = RF:WaitForChild("InitiateTrade", 5)
    REEquipItem = RE:WaitForChild("EquipItem", 5)
    RFAwaitTradeResponse = RF:WaitForChild("AwaitTradeResponse", 5)
    
    if not InitiateTrade or not REEquipItem then
        NotifyError("Setup Failed", "Trade remotes not found")
        return false
    end
    
    print("✅ Remotes loaded successfully!")
    return true
end

-- ===================================
-- ========== HOOK SYSTEM ============
-- ===================================

local function setupHook()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        -- SAVE MODE: Capture fish UUID when clicked
        if TradeSystem.SaveMode and tostring(self) == "RE/EquipItem" and method == "FireServer" then
            local uuid = args[1]
            local category = args[2]
            
            if uuid and category == "Fishes" then
                -- Check if already saved
                local alreadySaved = false
                for _, fish in ipairs(TradeSystem.SavedFishList) do
                    if fish.UUID == uuid then
                        alreadySaved = true
                        break
                    end
                end
                
                if not alreadySaved then
                    table.insert(TradeSystem.SavedFishList, {
                        UUID = uuid,
                        Category = category
                    })
                    
                    NotifySuccess("Fish Saved", 
                        string.format("Fish added! Total: %d", #TradeSystem.SavedFishList)
                    )
                    
                    UpdateSavedFishLabel()
                else
                    NotifyWarning("Already Saved", "This fish is already in the list")
                end
            end
            
            return nil -- Don't equip the item
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    setreadonly(mt, true)
    
    print("✅ Hook installed!")
end

-- ===================================
-- ========== TRADE FUNCTIONS ========
-- ===================================

local function checkTradeCompletion(timeout)
    local tradeCompleted = false
    local elapsed = 0
    local lastTrigger = 0
    local cooldown = 0.5
    
    local success, notifGui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Text Notifications")
    end)
    
    if not success then
        warn("Could not find notification GUI")
        return false
    end
    
    local connection
    connection = notifGui.Frame.ChildAdded:Connect(function(child)
        if child.Name == "TextTile" then
            task.wait(0.5)
            local header = child:FindFirstChild("Header")
            if header and header:IsA("TextLabel") and header.Text == "Trade completed!" then
                local now = tick()
                if now - lastTrigger > cooldown then
                    lastTrigger = now
                    tradeCompleted = true
                end
            end
        end
    end)
    
    -- Wait for completion or timeout
    repeat
        task.wait(0.2)
        elapsed = elapsed + 0.2
    until tradeCompleted or elapsed >= timeout
    
    if connection then
        connection:Disconnect()
    end
    
    return tradeCompleted
end

local function tradeSingleFish(fishData, index, total)
    if not TradeSystem.TargetUserId then
        return false, "No target selected"
    end
    
    NotifyInfo("Trading", 
        string.format("Trading fish %d/%d...", index, total)
    )
    
    local success, err = pcall(function()
        InitiateTrade:InvokeServer(
            TradeSystem.TargetUserId,
            fishData.UUID,
            fishData.Category
        )
    end)
    
    if not success then
        return false, tostring(err)
    end
    
    -- Wait for trade completion
    local completed = checkTradeCompletion(10)
    
    if completed then
        return true
    else
        return false, "Trade timeout"
    end
end

local function startMassTrade()
    if TradeSystem.TradingInProgress then
        NotifyWarning("Trade in Progress", "Please wait for current trade to finish")
        return
    end
    
    if not TradeSystem.TargetUserId then
        NotifyError("No Target", "Please select a target player first!")
        return
    end
    
    if #TradeSystem.SavedFishList == 0 then
        NotifyError("No Fish", "No fish saved! Enable 'Save Mode' and click fish items")
        return
    end
    
    TradeSystem.TradingInProgress = true
    
    NotifyInfo("Starting Trade", 
        string.format("Trading %d fish to %s...", 
            #TradeSystem.SavedFishList, 
            TradeSystem.TargetUsername
        )
    )
    
    task.spawn(function()
        local successCount = 0
        local failCount = 0
        
        for i, fish in ipairs(TradeSystem.SavedFishList) do
            local success, err = tradeSingleFish(fish, i, #TradeSystem.SavedFishList)
            
            if success then
                successCount = successCount + 1
                TradeSystem.TotalSuccess = TradeSystem.TotalSuccess + 1
                NotifySuccess("Trade Success", 
                    string.format("Fish %d/%d traded successfully", i, #TradeSystem.SavedFishList)
                )
            else
                failCount = failCount + 1
                TradeSystem.TotalFailed = TradeSystem.TotalFailed + 1
                NotifyError("Trade Failed", 
                    string.format("Fish %d/%d failed: %s", i, #TradeSystem.SavedFishList, tostring(err))
                )
            end
            
            TradeSystem.TotalTraded = TradeSystem.TotalTraded + 1
            UpdateStatusUI()
            
            -- Delay between trades (except last one)
            if i < #TradeSystem.SavedFishList then
                task.wait(TradeSystem.TradeDelay)
            end
        end
        
        -- Trade completed
        TradeSystem.TradingInProgress = false
        
        NotifySuccess("Trade Complete!", 
            string.format(
                "Finished! ✅ %d success | ❌ %d failed",
                successCount,
                failCount
            )
        )
        
        -- Clear saved list after successful trade
        TradeSystem.SavedFishList = {}
        UpdateSavedFishLabel()
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
        end
    end
end

-- ===================================
-- ========== AUTO ACCEPT ============
-- ===================================

local function setupAutoAccept()
    if RFAwaitTradeResponse then
        RFAwaitTradeResponse.OnClientInvoke = function(fromPlayer, timeNow)
            -- Always return nil (manual accept)
            -- Can be changed to return true for auto-accept
            return nil
        end
        print("✅ Auto-accept handler setup")
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish Trade System V2",
    LoadingTitle = "Loading Fish Trade System...",
    LoadingSubtitle = "Manual Mode - Click to Save & Trade",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("📊 Trade System", 4483362458)

-- ===================================
-- Status Section
-- ===================================

MainTab:CreateSection("📊 Current Status")

StatusParagraph = MainTab:CreateParagraph({
    Title = "📊 Trade Status",
    Content = string.format(
        "✅ Success: %d\n❌ Failed: %d\n📦 Total Traded: %d\n👤 Target: %s",
        TradeSystem.TotalSuccess,
        TradeSystem.TotalFailed,
        TradeSystem.TotalTraded,
        TradeSystem.TargetUsername
    )
})

SavedFishLabel = MainTab:CreateLabel("📦 Saved Fish: 0")

MainTab:CreateButton({
    Name = "🔄 Reset Stats",
    Callback = function()
        TradeSystem.TotalSuccess = 0
        TradeSystem.TotalFailed = 0
        TradeSystem.TotalTraded = 0
        UpdateStatusUI()
        NotifySuccess("Reset", "Statistics cleared")
    end
})

-- ===================================
-- Target Player Section
-- ===================================

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

-- ===================================
-- Save Mode Section
-- ===================================

MainTab:CreateSection("💾 Save Fish (Step 1)")

MainTab:CreateParagraph({
    Title = "📖 How to Use",
    Content = "1. Enable 'Save Mode'\n2. Click fish items in your hotbar/inventory\n3. Each click will save that fish\n4. When done, disable 'Save Mode'\n5. Click 'Start Mass Trade'"
})

MainTab:CreateToggle({
    Name = "💾 Enable Save Mode",
    CurrentValue = false,
    Flag = "SaveModeToggle",
    Callback = function(value)
        TradeSystem.SaveMode = value
        if value then
            NotifySuccess("Save Mode ON", "Click fish items to save them for trade")
        else
            NotifyInfo("Save Mode OFF", 
                string.format("Saved %d fish. Ready to trade!", #TradeSystem.SavedFishList)
            )
        end
    end
})

MainTab:CreateButton({
    Name = "🗑️ Clear Saved Fish",
    Callback = function()
        local count = #TradeSystem.SavedFishList
        TradeSystem.SavedFishList = {}
        UpdateSavedFishLabel()
        NotifyInfo("Cleared", string.format("Removed %d saved fish", count))
    end
})

-- ===================================
-- Trade Section
-- ===================================

MainTab:CreateSection("🚀 Start Trading (Step 2)")

MainTab:CreateButton({
    Name = "🚀 Start Mass Trade",
    Callback = function()
        startMassTrade()
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
        NotifyInfo("Delay Updated", "Trade delay: " .. value .. "s")
    end
})

-- ===================================
-- Settings Tab
-- ===================================

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateSection("⚙️ Configuration")

SettingsTab:CreateParagraph({
    Title = "ℹ️ About",
    Content = "Fish Trade System V2\n\nManual Mode:\n• Click to save fish\n• Trade saved fish to target player\n• Safe with configurable delays"
})

SettingsTab:CreateButton({
    Name = "🔧 Reload Remotes",
    Callback = function()
        if setupRemotes() then
            NotifySuccess("Reload", "Remotes reloaded successfully")
        else
            NotifyError("Reload Failed", "Could not reload remotes")
        end
    end
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function initialize()
    print("🐟 Fish Trade System V2 - Initializing...")
    
    -- Setup remotes
    if not setupRemotes() then
        NotifyError("Init Failed", "Could not setup remotes")
        return false
    end
    
    -- Setup hook
    setupHook()
    
    -- Setup auto-accept handler
    setupAutoAccept()
    
    -- Listen for player changes
    Players.PlayerAdded:Connect(refreshPlayerList)
    Players.PlayerRemoving:Connect(refreshPlayerList)
    
    NotifySuccess("System Ready", "Fish Trade System V2 initialized!")
    
    -- Show tutorial
    task.wait(2)
    Rayfield:Notify({
        Title = "📖 Quick Tutorial",
        Content = "1. Select target player\n2. Enable 'Save Mode'\n3. Click fish items\n4. Disable 'Save Mode'\n5. Click 'Start Mass Trade'",
        Duration = 8,
        Image = 4483362458
    })
    
    return true
end

-- Start initialization
task.spawn(function()
    task.wait(2)
    initialize()
end)

print("🐟 Fish Trade System V2 loaded!")
print("📌 Mode: Manual (Click to Save)")
print("✅ Ready to use!")

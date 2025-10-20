local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

-- State Variables
local autoFishingEnabled = false
local autoFishingV2Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false

-- Remote Variables
local net
local rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote

-- Connection Variables
local AFKConnection = nil

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

-- Fungsi untuk membuat instance dengan properties
local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

-- ===================================
-- ========== WIND UI IMPLEMENTATION =
-- ===================================

-- Load Wind UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "🐟 Fish It Premium v2.5",
    SubTitle = "by Codepikk",
    Size = UDim2.fromOffset(500, 550),
    Theme = "Dark"
})

-- ===================================
-- ========== AUTO BOOST FPS =========
-- ===================================

local function BoostFPS()
    updateStatus("🚀 Boosting FPS...", Color3.fromRGB(255, 200, 100))
    
    -- Optimize parts and materials
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    -- Optimize lighting
    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10

    -- Set graphics quality to lowest
    settings().Rendering.QualityLevel = "Level01"
    
    updateStatus("✅ FPS Boosted Successfully", Color3.fromRGB(100, 255, 100))
end

-- ===================================
-- ========== AUTO FAVORITE ==========
-- ===================================

local allowedTiers = { 
    ["Secret"] = true, 
    ["Mythic"] = true, 
    ["Legendary"] = true 
}

local function startAutoFavorite()
    task.spawn(function()
        while autoFavoriteEnabled do
            pcall(function()
                updateStatus("⭐ Scanning items...", Color3.fromRGB(255, 215, 0))
                
                local totalFavorited = 0
                local totalChecked = 0
                
                -- METHOD 1: Coba Replion System
                local success1, replionData = pcall(function()
                    return Replion and Replion.Client:WaitReplion("Data")
                end)
                
                if success1 and replionData then
                    local items = replionData:Get({"Inventory", "Items"})
                    if type(items) == "table" then
                        for _, item in ipairs(items) do
                            if not autoFavoriteEnabled then break end
                            
                            totalChecked = totalChecked + 1
                            local itemData = ItemUtility and ItemUtility:GetItemData(item.Id)
                            
                            if itemData and itemData.Data and allowedTiers[itemData.Data.Tier] and not item.Favorited then
                                item.Favorited = true
                                totalFavorited = totalFavorited + 1
                                updateStatus("⭐ Fav: " .. itemData.Data.Tier .. " item", Color3.fromRGB(100, 255, 100))
                                task.wait(0.2)
                            end
                        end
                    end
                    
                -- METHOD 2: Coba Remote Events
                else
                    local favoriteRemote = ReplicatedStorage:FindFirstChild("FavoriteItem") or
                                         ReplicatedStorage:FindFirstChild("ToggleFavorite")
                    
                    if favoriteRemote then
                        updateStatus("⭐ Using remote system...", Color3.fromRGB(100, 255, 100))
                        
                        -- Coba favorite items 1-50
                        for itemId = 1, 50 do
                            if not autoFavoriteEnabled then break end
                            
                            totalChecked = totalChecked + 1
                            favoriteRemote:FireServer(itemId)
                            totalFavorited = totalFavorited + 1
                            
                            if itemId % 10 == 0 then
                                updateStatus("⭐ Progress: " .. itemId .. "/50", Color3.fromRGB(255, 215, 0))
                            end
                            
                            task.wait(0.1)
                        end
                    end
                end
                
                -- SHOW FINAL RESULT
                if totalFavorited > 0 then
                    updateStatus("✅ Done! Fav: " .. totalFavorited .. " items", Color3.fromRGB(100, 255, 100))
                else
                    updateStatus("ℹ️ No items to favorite", Color3.fromRGB(255, 255, 100))
                end
                
            end)
            
            -- Wait before next scan
            for i = 1, 20 do
                if not autoFavoriteEnabled then break end
                task.wait(0.5)
            end
        end
        updateStatus("🔴 Auto Favorite: Stopped")
    end)
end

-- ===================================
-- ========== REMOTE SETUP ===========
-- ===================================

-- Setup remote events/functions untuk komunikasi dengan server
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
end

-- ===================================
-- ========== TAB CREATION ===========
-- ===================================

-- Create Tabs
local MainTab = Window:CreateTab("🎯 Main Features", "http://www.roblox.com/asset/?id=17336637104")
local TeleportTab = Window:CreateTab("🚀 Teleports", "http://www.roblox.com/asset/?id=17336637104")
local UtilitiesTab = Window:CreateTab("⚙️ Utilities", "http://www.roblox.com/asset/?id=17336637104")

-- Status variable untuk update
local statusText = "🔴 Status: Idle"
local statusColor = Color3.fromRGB(255, 100, 100)

-- Fungsi untuk update status
local function updateStatus(newStatus, color)
    statusText = newStatus
    statusColor = color or Color3.fromRGB(255, 100, 100)
    
    -- Update status label jika ada
    if statusLabel then
        statusLabel:SetText(statusText)
    end
end

-- ===================================
-- ========== MAIN TAB ===============
-- ===================================

-- Status Section
local StatusSection = MainTab:CreateSection("System Status")

local statusLabel = StatusSection:AddLabel("🔴 Status: Idle")

-- Auto Fishing Section
local FishingSection = MainTab:CreateSection("Auto Fishing Systems")

local v1Toggle = FishingSection:AddToggle("Auto Fishing V1", {
    Text = "🎣 Auto Instant Fishing V1 (Perfect + Delay)",
    Default = false,
    Callback = function(value)
        autoFishingEnabled = value
        autoFishingV2Enabled = false
        
        if value then
            v2Toggle:SetValue(false)
            updateStatus("🎣 Status: Fishing V1", Color3.fromRGB(100, 255, 100))
            task.spawn(autoFishingLoop)
        else
            updateStatus("🔴 Status: Idle")
            fishingActive = false
            finishRemote:FireServer()
        end
    end
})

local v2Toggle = FishingSection:AddToggle("Auto Fishing V2", {
    Text = "⚡ Auto Fishing V2 (ULTRA FAST)",
    Default = false,
    Callback = function(value)
        autoFishingV2Enabled = value
        autoFishingEnabled = false
        
        if value then
            v1Toggle:SetValue(false)
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            task.spawn(autoFishingV2Loop)
        else
            updateStatus("🔴 Status: Idle")
            fishingActive = false
            finishRemote:FireServer()
        end
    end
})

-- Auto Systems Section
local AutoSystemsSection = MainTab:CreateSection("Auto Systems")

local sellToggle = AutoSystemsSection:AddToggle("Auto Sell", {
    Text = "💰 Auto Sell All (non favorite fish)",
    Default = false,
    Callback = function(value)
        autoSellEnabled = value
        
        if value then
            updateStatus("🟢 Status: Auto Sell Started", Color3.fromRGB(100, 255, 100))
            task.spawn(autoSellLoop)
        else
            updateStatus("🔴 Status: Auto Sell Stopped")
        end
    end
})

local favoriteToggle = AutoSystemsSection:AddToggle("Auto Favorite", {
    Text = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    Default = false,
    Callback = function(value)
        autoFavoriteEnabled = value
        
        if value then
            updateStatus("⭐ Auto Favorite: Started", Color3.fromRGB(255, 215, 0))
            startAutoFavorite()
        else
            updateStatus("🔴 Auto Favorite: Disabled")
        end
    end
})

-- ===================================
-- ========== TELEPORT TAB ===========
-- ===================================

-- NPC Teleport Section
local NPCSection = TeleportTab:CreateSection("NPC Teleport")

NPCSection:AddButton("🧍 Open NPC Teleport", {
    Callback = function()
        createNPCTeleportGUI()
    end
})

-- Islands Teleport Section
local IslandsSection = TeleportTab:CreateSection("Islands Teleport")

IslandsSection:AddButton("🏝️ Open Islands Teleport", {
    Callback = function()
        createTeleportGUI()
    end
})

-- Events Teleport Section
local EventsSection = TeleportTab:CreateSection("Events Teleport")

EventsSection:AddButton("🎯 Open Events Teleport", {
    Callback = function()
        createEventTeleportGUI()
    end
})

-- ===================================
-- ========== UTILITIES TAB ==========
-- ===================================

-- System Utilities Section
local SystemSection = UtilitiesTab:CreateSection("System Utilities")

local antiAFKToggle = SystemSection:AddToggle("Anti-AFK", {
    Text = "⏰ Anti-AFK System",
    Default = false,
    Callback = function(value)
        antiAFKEnabled = value
        
        if value then
            -- Enable Anti-AFK
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
            
            updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100, 255, 100))
        else
            -- Disable Anti-AFK
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end
            
            updateStatus("🔴 Status: Idle")
        end
    end
})

SystemSection:AddButton("🚀 Boost FPS", {
    Callback = function()
        BoostFPS()
    end
})

-- Info Section
local InfoSection = UtilitiesTab:CreateSection("Information")

InfoSection:AddLabel("🐟 Fish It Premium v2.5")
InfoSection:AddLabel("Made by: Codepikk")
InfoSection:AddLabel("Discord: codepikk")

-- ===================================
-- ========== FISHING SYSTEMS ========
-- ===================================

-- Fungsi utama Auto Fishing V1
local function autoFishingLoop()
    while autoFishingEnabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("🎣 Status: Fishing V1", Color3.fromRGB(100, 255, 100))
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
        if not ok then
            -- Handle error silently
        end
        task.wait(0.2)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- Fungsi utama Auto Fishing V2 (ULTRA FAST)
local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            
            -- Equip rod super cepat
            equipRemote:FireServer(1)
            
            -- Cast langsung tanpa delay
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)

            -- Random coordinates yang lebih natural tapi tetap cepat
            local baseX, baseY = -0.7499996, 1
            -- Random kecil tapi cukup untuk avoid detection
            local x = baseX + (math.random(-300, 300) / 10000000)
            local y = baseY + (math.random(-300, 300) / 10000000)

            -- Mini game instant
            miniGameRemote:InvokeServer(x, y)
            
            -- Finish dalam 0.5 detik (super cepat tapi masih natural)
            task.wait(0.5)
            finishRemote:FireServer(true)
            
            -- Auto recast cepat
            task.wait(0.3)
            finishRemote:FireServer()
        end)
        
        if not ok then
            -- Error handling silent
        end
        
        -- Delay antara fishing cycle yang random (antara 0.1-0.3 detik)
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- ===================================
-- ========== AUTO SELL SYSTEM =======
-- ===================================

-- Fungsi untuk auto sell loop
local function autoSellLoop()
    while autoSellEnabled do
        task.wait(1)
        
        local success, err = pcall(function()
            updateStatus("💰 Status: Selling", Color3.fromRGB(255, 215, 0))
            
            local sellSuccess = pcall(function()
                sellRemote:InvokeServer()
            end)

            if sellSuccess then
                updateStatus("✅ Status: Sold!. Please Stop Selling Button", Color3.fromRGB(100, 255, 100))
            else
                updateStatus("❌ Status: Sell Failed")
            end
        end)
        
        if not success then
            updateStatus("❌ Status: Sell Error!")
        end
    end
    updateStatus("🔴 Status: Idle")
end

-- ===================================
-- ========== TELEPORT SYSTEMS =======
-- ===================================

-- Koordinat island untuk teleport
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

-- Fungsi untuk membuat GUI teleport islands
local function createTeleportGUI()
    local teleportGui = WindUI:CreateWindow({
        Title = "🏝️ Island Teleport",
        SubTitle = "Select an island to teleport",
        Size = UDim2.fromOffset(300, 400),
        Theme = "Dark"
    })
    
    local IslandsTab = teleportGui:CreateTab("Islands", "http://www.roblox.com/asset/?id=17336637104")
    local IslandsSection = IslandsTab:CreateSection("Available Islands")
    
    for islandName, position in pairs(islandCoords) do
        IslandsSection:AddButton("📍 " .. islandName, {
            Callback = function()
                local charFolder = workspace:WaitForChild("Characters", 5)
                local char = charFolder:FindFirstChild(player.Name)
                if not char then 
                    updateStatus("❌ Character not found")
                    return 
                end
                
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then 
                    updateStatus("❌ HRP not found")
                    return 
                end

                local success, err = pcall(function()
                    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
                end)

                if success then
                    updateStatus("✅ Success Teleport to " .. islandName, Color3.fromRGB(100, 255, 100))
                    teleportGui:Close()
                else
                    updateStatus("❌ Teleport failed")
                end
            end
        })
    end
end

-- Fungsi untuk membuat GUI teleport NPC
local function createNPCTeleportGUI()
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    if not npcFolder then
        updateStatus("❌ NPC folder not found")
        return
    end

    local npcList = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end

    if #npcList == 0 then
        updateStatus("❌ No NPCs found")
        return
    end

    local npcTeleportGui = WindUI:CreateWindow({
        Title = "🧍 NPC Teleport",
        SubTitle = "Select an NPC to teleport",
        Size = UDim2.fromOffset(300, 400),
        Theme = "Dark"
    })
    
    local NPCTab = npcTeleportGui:CreateTab("NPCs", "http://www.roblox.com/asset/?id=17336637104")
    local NPCSection = NPCTab:CreateSection("Available NPCs")
    
    for _, npcName in ipairs(npcList) do
        NPCSection:AddButton("🧍 " .. npcName, {
            Callback = function()
                local npc = npcFolder:FindFirstChild(npcName)
                if npc and npc:IsA("Model") then
                    local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                    if hrp then
                        local charFolder = workspace:FindFirstChild("Characters")
                        local char = charFolder and charFolder:FindFirstChild(player.Name)
                        if not char then 
                            updateStatus("❌ Character not found")
                            return 
                        end
                        
                        local myHRP = char:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            local success, err = pcall(function()
                                myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                            end)

                            if success then
                                updateStatus("✅ Teleported to: " .. npcName, Color3.fromRGB(100, 255, 100))
                                npcTeleportGui:Close()
                            else
                                updateStatus("❌ Teleport failed: " .. tostring(err))
                            end
                        else
                            updateStatus("❌ HRP not found")
                        end
                    else
                        updateStatus("❌ NPC HRP not found")
                    end
                else
                    updateStatus("❌ NPC not found")
                end
            end
        })
    end
end

-- Fungsi untuk membuat GUI teleport events
local function createEventTeleportGUI()
    local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

    local eventTeleportGui = WindUI:CreateWindow({
        Title = "🎯 Event Teleport",
        SubTitle = "Teleport to active events",
        Size = UDim2.fromOffset(300, 400),
        Theme = "Dark"
    })
    
    local EventsTab = eventTeleportGui:CreateTab("Events", "http://www.roblox.com/asset/?id=17336637104")
    local InfoSection = EventsTab:CreateSection("Information")
    
    InfoSection:AddLabel("⚡ Only works when events are ACTIVE")
    
    local EventsSection = EventsTab:CreateSection("Available Events")
    
    for _, eventName in ipairs(eventsList) do
        EventsSection:AddButton("⚡ " .. eventName, {
            Callback = function()
                updateStatus("🔍 Mencari: " .. eventName, Color3.fromRGB(255, 200, 100))
                
                task.wait(0.3)
                
                local function findEventLocation(eventName)
                    local searchLocations = {
                        workspace,
                        workspace:FindFirstChild("Events"),
                        workspace:FindFirstChild("Props"), 
                        workspace:FindFirstChild("Map"),
                        workspace:FindFirstChild("World"),
                        workspace:FindFirstChild("Game"),
                    }
                    
                    for _, location in pairs(searchLocations) do
                        if location then
                            local eventObj = location:FindFirstChild(eventName)
                            if eventObj then
                                return eventObj
                            end
                            
                            for _, child in pairs(location:GetChildren()) do
                                if string.find(string.lower(child.Name), string.lower(eventName)) then
                                    return child
                                end
                            end
                        end
                    end
                    
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if string.lower(obj.Name) == string.lower(eventName) then
                            return obj
                        end
                    end
                    
                    return nil
                end

                local eventObject = findEventLocation(eventName)
                
                if eventObject then
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local success, err = pcall(function()
                            local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                            if fishingBoat then
                                hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                                updateStatus("✅ Teleport ke Fishing Boat " .. eventName, Color3.fromRGB(100, 255, 100))
                            else
                                hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                                updateStatus("✅ Teleport ke " .. eventName, Color3.fromRGB(100, 255, 100))
                            end
                            eventTeleportGui:Close()
                        end)

                        if not success then
                            updateStatus("❌ Gagal teleport: " .. tostring(err))
                        end
                    else
                        updateStatus("❌ HRP tidak ditemukan")
                    end
                else
                    updateStatus("❌ " .. eventName .. " tidak ditemukan\nPastikan event sedang ACTIVE", Color3.fromRGB(255, 100, 100))
                end
            end
        })
    end
end

-- ===================================
-- ========== EXCLAIM DETECTION ======
-- ===================================

-- Listener untuk detect exclaim (tanda seru) dan auto recast
task.spawn(function()
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 2)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if (autoFishingEnabled or autoFishingV2Enabled) and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    task.spawn(function()
                        if autoFishingV2Enabled then
                            task.wait(0.1)
                            finishRemote:FireServer()
                        else
                            -- V1: Original behavior
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
-- ========== SCRIPT INITIALIZATION ==
-- ===================================

-- Setup remotes terlebih dahulu
setupRemotes()

-- Inisialisasi status
updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(100, 255, 100))

print("🎯 Fish It Premium v2.5 - Wind UI Loaded Successfully!")

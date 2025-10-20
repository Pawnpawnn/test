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
-- ========== WINDUI SETUP ===========
-- ===================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create main window
local Window = WindUI:CreateWindow({
    Title = "🐟 Fish It - Codepikk Premium",
    Center = true,
    Size = UDim2.new(0, 500, 0, 450),
    Theme = "Dark"
})

-- ===================================
-- ========== TAB CREATION ===========
-- ===================================

-- Main Tab
local MainTab = Window:CreateTab("Main")

-- Status Section
local StatusSection = MainTab:CreateSection("Status")
local StatusLabel = StatusSection:AddLabel("🔴 Status: Idle\nScript: V.2.5\nNote: Donate me if you happy using this script  :)")

-- Fungsi untuk update status dengan format yang dipertahankan
local function updateStatus(newStatus, color)
    local baseText = "Script: V.2.5\nNote: Donate me if you happy using this script :)"
    StatusLabel:SetText(newStatus .. "\n" .. baseText)
end

-- Fishing Section
local FishingSection = MainTab:CreateSection("Fishing Features")

local AutoFishToggle = FishingSection:AddToggle({
    Text = "🎣 Auto Instant Fishing V1 (perfect + delay)",
    Callback = function(state)
        autoFishingEnabled = state
        autoFishingV2Enabled = false
        
        if state then
            AutoFishV2Toggle:Set(false)
            updateStatus("🟢 Status: Auto Fishing V1 Started", Color3.fromRGB(100, 255, 100))
            task.spawn(autoFishingLoop)
        else
            updateStatus("🔴 Status: Auto Fishing Stopped")
            fishingActive = false
            finishRemote:FireServer()
        end
    end
})

local AutoFishV2Toggle = FishingSection:AddToggle({
    Text = "⚡ Auto Fishing V2 (FAST)",
    Callback = function(state)
        autoFishingV2Enabled = state
        autoFishingEnabled = false
        
        if state then
            AutoFishToggle:Set(false)
            updateStatus("⚡ Status: Auto Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            task.spawn(autoFishingV2Loop)
        else
            updateStatus("🔴 Status: Auto Fishing Stopped")
            fishingActive = false
            finishRemote:FireServer()
        end
    end
})

-- Auto Features Section
local AutoFeaturesSection = MainTab:CreateSection("Auto Features")

local AutoSellToggle = AutoFeaturesSection:AddToggle({
    Text = "💰 Auto Sell All (non favorite fish)",
    Callback = function(state)
        autoSellEnabled = state
        
        if state then
            updateStatus("🟢 Status: Auto Sell Started", Color3.fromRGB(100, 255, 100))
            task.spawn(autoSellLoop)
        else
            updateStatus("🔴 Status: Auto Sell Stopped")
        end
    end
})

local AutoFavoriteToggle = AutoFeaturesSection:AddToggle({
    Text = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    Callback = function(state)
        autoFavoriteEnabled = state
        
        if state then
            startAutoFavorite()
        else
            updateStatus("🔴 Auto Favorite: Disabled")
        end
    end
})

-- ===================================
-- ========== TELEPORTS TAB ==========
-- ===================================

local TeleportsTab = Window:CreateTab("Teleports")

-- NPC Teleport Section
local NPCTeleportSection = TeleportsTab:CreateSection("NPC Teleports")

NPCTeleportSection:AddButton({
    Text = "🧍 Teleport to NPC",
    Callback = function()
        createNPCTeleportGUI()
    end
})

-- Island Teleport Section
local IslandTeleportSection = TeleportsTab:CreateSection("Island Teleports")

IslandTeleportSection:AddButton({
    Text = "🏝️ Teleport to Islands",
    Callback = function()
        createTeleportGUI()
    end
})

-- Event Teleport Section
local EventTeleportSection = TeleportsTab:CreateSection("Event Teleports")

EventTeleportSection:AddButton({
    Text = "🎯 Teleport to Events",
    Callback = function()
        createEventTeleportGUI()
    end
})

-- ===================================
-- ========== MISC TAB ===============
-- ===================================

local MiscTab = Window:CreateTab("Misc")

-- Utility Section
local UtilitySection = MiscTab:CreateSection("Utilities")

local AntiAFKToggle = UtilitySection:AddToggle({
    Text = "⏰ Anti-AFK System",
    Callback = function(state)
        antiAFKEnabled = state
        
        if state then
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

UtilitySection:AddButton({
    Text = "🚀 Auto Boost FPS",
    Callback = function()
        BoostFPS()
    end
})

-- Info Section
local InfoSection = MiscTab:CreateSection("Information")
InfoSection:AddLabel("🐟 Fish It Premium V2.5")
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
    local teleportGui = create("ScreenGui", {
        Name = "TeleportGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local teleportFrame = create("Frame", {
        Name = "TeleportFrame",
        Parent = teleportGui,
        Size = UDim2.new(0, 280, 0, 300),
        Position = UDim2.new(0.5, -140, 0.5, -150),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = teleportFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = teleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local teleportTitle = create("TextLabel", {
        Parent = teleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🏝️ Island Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextYAlignment = Enum.TextYAlignment.Center
    })

    create("UICorner", {Parent = teleportTitle, CornerRadius = UDim.new(0, 10)})

    local closeTeleportBtn = create("TextButton", {
        Parent = teleportTitle,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeTeleportBtn, CornerRadius = UDim.new(0, 6)})

    local scrollFrame = create("ScrollingFrame", {
        Parent = teleportFrame,
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
        CanvasSize = UDim2.new(0, 0, 0, #game:GetService("HttpService"):JSONEncode(islandCoords) * 35)
    })

    local yPosition = 0
    for islandName, position in pairs(islandCoords) do
        local islandBtn = create("TextButton", {
            Parent = scrollFrame,
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 0, yPosition),
            BackgroundColor3 = Color3.fromRGB(35, 45, 65),
            Text = "📍 " .. islandName,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            TextYAlignment = Enum.TextYAlignment.Center
        })

        create("UICorner", {Parent = islandBtn, CornerRadius = UDim.new(0, 6)})
        create("UIStroke", {Parent = islandBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

        islandBtn.MouseButton1Click:Connect(function()
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
                teleportGui:Destroy()
            else
                updateStatus("❌ Teleport failed")
            end
        end)

        yPosition = yPosition + 35
    end

    closeTeleportBtn.MouseButton1Click:Connect(function()
        teleportGui:Destroy()
    end)
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

    local npcTeleportGui = create("ScreenGui", {
        Name = "NPCTeleportGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local npcTeleportFrame = create("Frame", {
        Name = "NPCTeleportFrame",
        Parent = npcTeleportGui,
        Size = UDim2.new(0, 280, 0, 350),
        Position = UDim2.new(0.5, -140, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = npcTeleportFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = npcTeleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local npcTeleportTitle = create("TextLabel", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🧍 NPC Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextYAlignment = Enum.TextYAlignment.Center
    })

    create("UICorner", {Parent = npcTeleportTitle, CornerRadius = UDim.new(0, 10)})

    local closeNPCTeleportBtn = create("TextButton", {
        Parent = npcTeleportTitle,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeNPCTeleportBtn, CornerRadius = UDim.new(0, 6)})

    local searchBox = create("TextBox", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
        PlaceholderText = "🔍 Search NPC...",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    create("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0, 6)})
    create("UIStroke", {Parent = searchBox, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    create("UIPadding", {
        Parent = searchBox,
        PaddingLeft = UDim.new(0, 8)
    })

    local scrollFrame = create("ScrollingFrame", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, -20, 1, -95),
        Position = UDim2.new(0, 10, 0, 85),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
        CanvasSize = UDim2.new(0, 0, 0, #npcList * 35)
    })

    local function createNPCButtons(filterText)
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local yPosition = 0
        local filteredCount = 0

        for _, npcName in ipairs(npcList) do
            if string.lower(npcName):find(string.lower(filterText or "")) then
                local npcBtn = create("TextButton", {
                    Parent = scrollFrame,
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0, 0, 0, yPosition),
                    BackgroundColor3 = Color3.fromRGB(35, 45, 65),
                    Text = "🧍 " .. npcName,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    TextYAlignment = Enum.TextYAlignment.Center
                })

                create("UICorner", {Parent = npcBtn, CornerRadius = UDim.new(0, 6)})
                create("UIStroke", {Parent = npcBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

                npcBtn.MouseButton1Click:Connect(function()
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
                                    npcTeleportGui:Destroy()
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
                end)

                yPosition = yPosition + 35
                filteredCount = filteredCount + 1
            end
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, filteredCount * 35)
    end

    createNPCButtons("")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        createNPCButtons(searchBox.Text)
    end)

    closeNPCTeleportBtn.MouseButton1Click:Connect(function()
        npcTeleportGui:Destroy()
    end)
end

-- Fungsi untuk membuat GUI teleport events
local function createEventTeleportGUI()
    local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

    local eventTeleportGui = create("ScreenGui", {
        Name = "EventTeleportGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local eventTeleportFrame = create("Frame", {
        Name = "EventTeleportFrame",
        Parent = eventTeleportGui,
        Size = UDim2.new(0, 300, 0, 350),
        Position = UDim2.new(0.5, -150, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = eventTeleportFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = eventTeleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local eventTeleportTitle = create("TextLabel", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🎯 Event Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextYAlignment = Enum.TextYAlignment.Center
    })

    create("UICorner", {Parent = eventTeleportTitle, CornerRadius = UDim.new(0, 10)})

    local closeEventTeleportBtn = create("TextButton", {
        Parent = eventTeleportTitle,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeEventTeleportBtn, CornerRadius = UDim.new(0, 6)})

    local infoLabel = create("TextLabel", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        Text = "Teleport to active events\n⚡ Hanya work ketika event ACTIVE",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(100, 255, 200),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local scrollFrame = create("ScrollingFrame", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, -20, 1, -110),
        Position = UDim2.new(0, 10, 0, 105),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
        CanvasSize = UDim2.new(0, 0, 0, #eventsList * 40)
    })

    local yPosition = 0
    for _, eventName in ipairs(eventsList) do
        local eventBtn = create("TextButton", {
            Parent = scrollFrame,
            Size = UDim2.new(1, 0, 0, 35),
            Position = UDim2.new(0, 0, 0, yPosition),
            BackgroundColor3 = Color3.fromRGB(35, 45, 65),
            Text = "⚡ " .. eventName,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            TextYAlignment = Enum.TextYAlignment.Center
        })

        create("UICorner", {Parent = eventBtn, CornerRadius = UDim.new(0, 6)})
        create("UIStroke", {Parent = eventBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

        eventBtn.MouseButton1Click:Connect(function()
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
                        eventTeleportGui:Destroy()
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
        end)

        yPosition = yPosition + 40
    end

    closeEventTeleportBtn.MouseButton1Click:Connect(function()
        eventTeleportGui:Destroy()
    end)
end

-- ===================================
-- ========== SCRIPT LOADED ==========
-- ===================================

-- Setup remotes terlebih dahulu
setupRemotes()

-- Script selesai di-load
updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(100, 255, 100))

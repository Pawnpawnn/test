local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Load Wind UI Library
local Wind = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
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

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local AFKConnection = nil

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
end

-- ===================================
-- ========== BOOST FPS ==============
-- ===================================

local function BoostFPS()
    Wind:Notify("FPS Boost", "Boosting FPS...", 3)
    
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
    
    Wind:Notify("Success", "FPS Boosted Successfully!", 3)
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
        
        Wind:Notify("Anti-AFK", "Anti-AFK Enabled!", 3)
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        Wind:Notify("Anti-AFK", "Anti-AFK Disabled!", 3)
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
-- ========== AUTO SELL ==============
-- ===================================

local function autoSellLoop()
    while autoSellEnabled do
        task.wait(1)
        
        local success, err = pcall(function()
            local sellSuccess = pcall(function()
                sellRemote:InvokeServer()
            end)

            if sellSuccess then
                Wind:Notify("Auto Sell", "Successfully sold all items!", 2)
            end
        end)
    end
end

-- ===================================
-- ========== WIND UI ================
-- ===================================

local Window = Wind:CreateWindow("🐟 Fish It - Codepikk Premium")

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main")
MainTab:CreateSection("Auto Fishing")

local FishingV1Toggle = MainTab:CreateToggle("🎣 Auto Fishing V1 (Perfect + Delay)", false, function(Value)
    autoFishingEnabled = Value
    autoFishingV2Enabled = false
    autoFishingV3Enabled = false
    
    if Value then
        Wind:Notify("Auto Fishing V1", "Auto Fishing V1 Started!", 3)
        task.spawn(autoFishingLoop)
    else
        Wind:Notify("Auto Fishing V1", "Auto Fishing V1 Stopped!", 3)
        fishingActive = false
        finishRemote:FireServer()
    end
end)

local FishingV2Toggle = MainTab:CreateToggle("⚡ Auto Fishing V2 (FAST)", false, function(Value)
    autoFishingV2Enabled = Value
    autoFishingEnabled = false
    autoFishingV3Enabled = false
    
    if Value then
        Wind:Notify("Auto Fishing V2", "Auto Fishing V2 ULTRA FAST Started!", 3)
        task.spawn(autoFishingV2Loop)
    else
        Wind:Notify("Auto Fishing V2", "Auto Fishing V2 Stopped!", 3)
        fishingActive = false
        finishRemote:FireServer()
    end
end)

local FishingV3Toggle = MainTab:CreateToggle("🚀 Auto Fishing V3 (TIMING EXPLOIT)", false, function(Value)
    autoFishingV3Enabled = Value
    autoFishingEnabled = false
    autoFishingV2Enabled = false
    
    if Value then
        Wind:Notify("Auto Fishing V3", "Auto Fishing V3 TIMING EXPLOIT Started!", 3)
        task.spawn(autoFishingV3Loop)
    else
        Wind:Notify("Auto Fishing V3", "Auto Fishing V3 Stopped!", 3)
        fishingActive = false
        finishRemote:FireServer()
    end
end)

MainTab:CreateSection("Inventory Management")

local AutoSellToggle = MainTab:CreateToggle("💰 Auto Sell All (Non-Favorite)", false, function(Value)
    autoSellEnabled = Value
    
    if Value then
        Wind:Notify("Auto Sell", "Auto Sell Started!", 3)
        task.spawn(autoSellLoop)
    else
        Wind:Notify("Auto Sell", "Auto Sell Stopped!", 3)
    end
end)

local AutoFavoriteToggle = MainTab:CreateToggle("⭐ Auto Favorite (Secret/Mythic/Legendary)", false, function(Value)
    autoFavoriteEnabled = Value
    
    if Value then
        Wind:Notify("Auto Favorite", "Auto Favorite Started!", 3)
        startAutoFavorite()
    else
        Wind:Notify("Auto Favorite", "Auto Favorite Stopped!", 3)
    end
end)

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports")

TeleportTab:CreateSection("Island Teleports")

local islandOptions = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

local IslandDropdown = TeleportTab:CreateDropdown("🏝️ Select Island", islandOptions, function(Option)
    local pos = islandCoords[Option]
    if not pos then 
        Wind:Notify("Teleport System", "Island not found!", 3)
        return
    end
    
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end)

    if success then
        Wind:Notify("Teleport System", "Teleported to " .. Option, 3)
    else
        Wind:Notify("Teleport System", "Teleport Error", 3)
    end
end)

-- NPC Teleport
TeleportTab:CreateSection("NPC Teleports")

local npcFolder = workspace:FindFirstChild("NPC") or ReplicatedStorage:FindFirstChild("NPC")
if npcFolder then
    local npcList = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            table.insert(npcList, npc.Name)
        end
    end
    
    if #npcList > 0 then
        local NPCDropdown = TeleportTab:CreateDropdown("🧍 Select NPC", npcList, function(Option)
            local npc = npcFolder:FindFirstChild(Option)
            if npc and npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                if hrp then
                    local char = player.Character or player.CharacterAdded:Wait()
                    local myHRP = char:WaitForChild("HumanoidRootPart", 3)
                    myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                    Wind:Notify("Teleport System", "Teleported to NPC: " .. Option, 3)
                end
            end
        end)
    end
end

-- Event Teleport
TeleportTab:CreateSection("Event Teleports")

local eventOptions = {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}

local EventDropdown = TeleportTab:CreateDropdown("🎯 Select Event (Must be Active)", eventOptions, function(option)
    local props = workspace:FindFirstChild("Props")
    if props and props:FindFirstChild(option) and props[option]:FindFirstChild("Fishing Boat") then
        local fishingBoat = props[option]["Fishing Boat"]
        local boatCFrame = fishingBoat:GetPivot()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
        Wind:Notify("Event Teleport", "Teleported to " .. option, 3)
    else
        Wind:Notify("Event Not Found", option .. " Not Available!", 3)
    end
end)

-- Misc Tab
local MiscTab = Window:CreateTab("⚙️ Misc")

MiscTab:CreateSection("Miscellaneous")

local AntiAFKToggle = MiscTab:CreateToggle("⏰ Anti-AFK System", false, function(Value)
    toggleAntiAFK()
end)

MiscTab:CreateButton("🚀 Boost FPS", function()
    BoostFPS()
end)

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Wind:Notify("Script Loaded!", "Fish It Auto V2.5 loaded successfully!", 5)

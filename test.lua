local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- Load Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

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

local allowedTiers = {
    ["Secret"] = true,
    ["Mythic"] = true,
    ["Legendary"] = true
}

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
end

-- ===================================
-- ========== AUTO FAVORITE ==========
-- ===================================

local function startAutoFavorite()
    task.spawn(function()
        while autoFavoriteEnabled do
            local success = pcall(function()
                local Replion = require(ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.3"].knit.Util.Remote.Replion)
                local ItemUtility = require(ReplicatedStorage.Modules.Shared.ItemUtility)
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    local totalFavorited = 0
                    
                    for _, item in ipairs(items) do
                        if not autoFavoriteEnabled then break end
                        
                        local base = ItemUtility:GetItemData(item.Id)
                        
                        if base and base.Data and allowedTiers[base.Data.Tier] and not item.Favorited then
                            favoriteRemote:FireServer(item.UUID, true)
                            totalFavorited = totalFavorited + 1
                            task.wait(0.3)
                        end
                    end
                end
            end)
            
            if autoFavoriteEnabled then
                for i = 1, 30 do
                    if not autoFavoriteEnabled then break end
                    task.wait(1)
                end
            end
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
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
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
            sellRemote:InvokeServer()
        end)
    end
end

-- ===================================
-- ========== TELEPORT FUNCTIONS =====
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
    local position = islandCoords[islandName]
    if position then
        local charFolder = workspace:FindFirstChild("Characters")
        local char = charFolder and charFolder:FindFirstChild(player.Name)
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
            end
        end
    end
end

local function teleportToNPC(npcName)
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    if npcFolder then
        local npc = npcFolder:FindFirstChild(npcName)
        if npc and npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                local charFolder = workspace:FindFirstChild("Characters")
                local char = charFolder and charFolder:FindFirstChild(player.Name)
                if char then
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
    end
end

local function teleportToEvent(eventName)
    local function findEventLocation(eventName)
        local searchLocations = {
            workspace,
            workspace:FindFirstChild("Events"),
            workspace:FindFirstChild("Props"), 
            workspace:FindFirstChild("Map"),
        }
        
        for _, location in pairs(searchLocations) do
            if location then
                local eventObj = location:FindFirstChild(eventName)
                if eventObj then return eventObj end
                
                for _, child in pairs(location:GetChildren()) do
                    if string.find(string.lower(child.Name), string.lower(eventName)) then
                        return child
                    end
                end
            end
        end
        
        return nil
    end

    local eventObject = findEventLocation(eventName)
    
    if eventObject then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
            if fishingBoat then
                hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
            else
                hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
            end
        end
    end
end

-- ===================================
-- ========== KAVO UI ================
-- ===================================

local Window = Library.CreateLib("🐟 Fish It - Codepikk V2.5", "DarkTheme")

-- Main Tab
local MainTab = Window:NewTab("🎣 Main")
local FishingSection = MainTab:NewSection("Auto Fishing")

FishingSection:NewToggle("Auto Fishing V1 (Perfect)", "Perfect catch with delay", function(state)
    autoFishingEnabled = state
    autoFishingV2Enabled = false
    autoFishingV3Enabled = false
    
    if state then
        task.spawn(autoFishingLoop)
    else
        fishingActive = false
        finishRemote:FireServer()
    end
end)

FishingSection:NewToggle("Auto Fishing V2 (FAST)", "Ultra fast fishing", function(state)
    autoFishingV2Enabled = state
    autoFishingEnabled = false
    autoFishingV3Enabled = false
    
    if state then
        task.spawn(autoFishingV2Loop)
    else
        fishingActive = false
        finishRemote:FireServer()
    end
end)

FishingSection:NewToggle("Auto Fishing V3 (EXPLOIT)", "Timing exploit mode", function(state)
    autoFishingV3Enabled = state
    autoFishingEnabled = false
    autoFishingV2Enabled = false
    
    if state then
        task.spawn(autoFishingV3Loop)
    else
        fishingActive = false
        finishRemote:FireServer()
    end
end)

local InventorySection = MainTab:NewSection("Inventory")

InventorySection:NewToggle("Auto Sell All", "Sell all non-favorite fish", function(state)
    autoSellEnabled = state
    
    if state then
        task.spawn(autoSellLoop)
    end
end)

InventorySection:NewToggle("Auto Favorite Rare", "Auto favorite Secret/Mythic/Legendary", function(state)
    autoFavoriteEnabled = state
    
    if state then
        startAutoFavorite()
    end
end)

-- Teleport Tab
local TeleportTab = Window:NewTab("🌍 Teleports")
local IslandSection = TeleportTab:NewSection("Islands")

IslandSection:NewDropdown("Select Island", "Teleport to islands", {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}, function(currentOption)
    teleportToIsland(currentOption)
end)

local NPCSection = TeleportTab:NewSection("NPCs")

local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
if npcFolder then
    local npcList = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            table.insert(npcList, npc.Name)
        end
    end
    
    if #npcList > 0 then
        NPCSection:NewDropdown("Select NPC", "Teleport to NPCs", npcList, function(currentOption)
            teleportToNPC(currentOption)
        end)
    end
end

local EventSection = TeleportTab:NewSection("Events (Must be Active)")

EventSection:NewDropdown("Select Event", "Teleport to active events", {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}, function(currentOption)
    teleportToEvent(currentOption)
end)

-- Misc Tab
local MiscTab = Window:NewTab("⚙️ Misc")
local UtilitySection = MiscTab:NewSection("Utilities")

UtilitySection:NewToggle("Anti-AFK", "Prevent AFK kick", function(state)
    toggleAntiAFK()
end)

UtilitySection:NewButton("Boost FPS", "Optimize game performance", function()
    BoostFPS()
end)

local InfoSection = MiscTab:NewSection("Information")

InfoSection:NewLabel("Fish It Premium V2.5")
InfoSection:NewLabel("Made by: Codepikk")
InfoSection:NewLabel("Discord: codepikk")
InfoSection:NewLabel("Donate if happy! :)")

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

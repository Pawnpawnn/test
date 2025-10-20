local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ===================================
-- ========== LOAD KAVO UI ===========
-- ===================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/addons/SaveManager.lua"))()

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local autoFishingEnabled = false
local autoFishingV2Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false

local net
local rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote
local AFKConnection = nil

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
                local totalFavorited = 0
                local totalChecked = 0
                
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
                                task.wait(0.2)
                            end
                        end
                    end
                else
                    local favoriteRemote = ReplicatedStorage:FindFirstChild("FavoriteItem") or
                                         ReplicatedStorage:FindFirstChild("ToggleFavorite")
                    
                    if favoriteRemote then
                        for itemId = 1, 50 do
                            if not autoFavoriteEnabled then break end
                            totalChecked = totalChecked + 1
                            favoriteRemote:FireServer(itemId)
                            totalFavorited = totalFavorited + 1
                            task.wait(0.1)
                        end
                    end
                end
            end)
            
            for i = 1, 20 do
                if not autoFavoriteEnabled then break end
                task.wait(0.5)
            end
        end
    end)
end

-- ===================================
-- ========== AUTO BOOST FPS =========
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
    
    Library:ShowNotification("FPS Boost", "FPS optimization completed!", 3)
end

-- ===================================
-- ========== REMOTE SETUP ===========
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
end

-- ===================================
-- ========== ANTI-AFK SYSTEM ========
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
        
        Library:ShowNotification("Anti-AFK", "Anti-AFK system activated!", 3)
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        Library:ShowNotification("Anti-AFK", "Anti-AFK system disabled!", 3)
    end
end

-- ===================================
-- ========== FISHING V1 SYSTEM ======
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
-- ========== FISHING V2 SYSTEM ======
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
-- ========== EXCLAIM DETECTION ======
-- ===================================

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
-- ========== AUTO SELL SYSTEM =======
-- ===================================

local function autoSellLoop()
    while autoSellEnabled do
        task.wait(1)
        pcall(function()
            sellRemote:InvokeServer()
        end)
    end
end

-- ===================================
-- ========== TELEPORT DATA ==========
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

local function teleportToPosition(position, name)
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(player.Name)
    if not char then 
        Library:ShowNotification("Teleport Failed", "Character not found!", 3)
        return false 
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        Library:ShowNotification("Teleport Failed", "HumanoidRootPart not found!", 3)
        return false 
    end

    local success = pcall(function()
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end)

    if success then
        Library:ShowNotification("Teleport Success", "Teleported to " .. name, 3)
    end

    return success
end

-- ===================================
-- ========== CREATE KAVO UI =========
-- ===================================

setupRemotes()

local Window = Library.CreateLib("🐟 Fish It Premium - Codepikk", "DarkTheme")

-- ===================================
-- ========== MAIN TAB ===============
-- ===================================

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("🎣 Auto Fishing")
MainSection:NewToggle("Auto Fishing V1", "Perfect timing with delay (Recommended)", function(Value)
    autoFishingEnabled = Value
    
    if Value then
        if autoFishingV2Enabled then
            autoFishingV2Enabled = false
        end
        
        Library:ShowNotification("Auto Fishing V1", "Auto Fishing V1 started!", 3)
        task.spawn(autoFishingLoop)
    else
        fishingActive = false
        pcall(function() finishRemote:FireServer() end)
        Library:ShowNotification("Auto Fishing V1", "Auto Fishing V1 stopped!", 3)
    end
end)

MainSection:NewToggle("Auto Fishing V2 FAST ⚡", "Ultra fast fishing mode (May be detected)", function(Value)
    autoFishingV2Enabled = Value
    
    if Value then
        if autoFishingEnabled then
            autoFishingEnabled = false
        end
        
        Library:ShowNotification("Auto Fishing V2", "Ultra Fast Fishing activated!", 3)
        task.spawn(autoFishingV2Loop)
    else
        fishingActive = false
        pcall(function() finishRemote:FireServer() end)
        Library:ShowNotification("Auto Fishing V2", "Ultra Fast Fishing stopped!", 3)
    end
end)

local UtilitySection = MainTab:NewSection("💰 Auto Sell & Utilities")
UtilitySection:NewToggle("Auto Sell All", "Automatically sell non-favorite fish", function(Value)
    autoSellEnabled = Value
    
    if Value then
        Library:ShowNotification("Auto Sell", "Auto Sell started!", 3)
        task.spawn(autoSellLoop)
    else
        Library:ShowNotification("Auto Sell", "Auto Sell stopped!", 3)
    end
end)

UtilitySection:NewToggle("Auto Favorite ⭐", "Auto favorite Secret/Mythic/Legendary items", function(Value)
    autoFavoriteEnabled = Value
    
    if Value then
        Library:ShowNotification("Auto Favorite", "Auto Favorite started!", 3)
        startAutoFavorite()
    else
        Library:ShowNotification("Auto Favorite", "Auto Favorite stopped!", 3)
    end
end)

-- ===================================
-- ========== TELEPORT TAB ===========
-- ===================================

local TeleportTab = Window:NewTab("Teleport")
local IslandSection = TeleportTab:NewSection("🏝️ Island Teleports")

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

IslandSection:NewDropdown("Select Island", "Teleport to various islands", islandNames, function(Value)
    local pos = islandCoords[Value]
    if pos then
        teleportToPosition(pos, Value)
    end
end)

local NPCSection = TeleportTab:NewSection("🧍 NPC Teleports")

local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
if npcFolder then
    local npcList = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end
    table.sort(npcList)
    
    NPCSection:NewDropdown("Select NPC", "Teleport to NPCs", npcList, function(Value)
        local npc = npcFolder:FindFirstChild(Value)
        if npc and npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                local charFolder = workspace:FindFirstChild("Characters")
                local char = charFolder and charFolder:FindFirstChild(player.Name)
                if char then
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        local success = pcall(function()
                            myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                        end)
                        
                        if success then
                            Library:ShowNotification("NPC Teleport", "Teleported to " .. Value, 3)
                        end
                    end
                end
            end
        end
    end)
end

local EventSection = TeleportTab:NewSection("🎯 Event Teleports")

local eventsList = {"Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"}

EventSection:NewDropdown("Select Event", "Teleport to active events", eventsList, function(Value)
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
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if string.lower(obj.Name) == string.lower(eventName) then
                return obj
            end
        end
        
        return nil
    end

    local eventObject = findEventLocation(Value)
    
    if eventObject then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local success = pcall(function()
                local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                if fishingBoat then
                    hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                else
                    hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                end
            end)
            
            if success then
                Library:ShowNotification("Event Teleport", "Teleported to " .. Value, 3)
            end
        end
    else
        Library:ShowNotification("Event Not Found", Value .. " is not active right now!", 3)
    end
end)

-- ===================================
-- ========== MISC TAB ===============
-- ===================================

local MiscTab = Window:NewTab("Misc")
local SystemSection = MiscTab:NewSection("⚙️ System Settings")

SystemSection:NewToggle("Anti-AFK System", "Prevents you from being kicked for inactivity", function(Value)
    toggleAntiAFK()
end)

SystemSection:NewButton("Boost FPS 🚀", "Optimize graphics for better performance", function()
    BoostFPS()
end)

local InfoSection = MiscTab:NewSection("ℹ️ Script Information")
InfoSection:NewLabel("Fish It Premium V2.5 Kavo Edition")
InfoSection:NewLabel("Made by: Codepikk")
InfoSection:NewLabel("Discord: codepikk")
InfoSection:NewLabel("Donate me if you're happy using this script! :)")

-- ===================================
-- ========== NOTIFICATION ===========
-- ===================================

Library:ShowNotification("Fish It Premium", "Script loaded successfully! V2.5 Kavo Edition", 5)

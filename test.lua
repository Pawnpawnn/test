local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ===================================
-- ========== LOAD WINDUI ============
-- ===================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
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
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local success = pcall(function()
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end)

    return success
end

-- ===================================
-- ========== CREATE WINDUI ==========
-- ===================================

setupRemotes()

local Window = WindUI:CreateWindow({
    Title = "🐟 Fish It - Codepikk Premium",
    Icon = "rbxassetid://10723415766",
    Author = "Codepikk",
    Folder = "FishItConfig",
    Size = UDim2.fromOffset(500, 450),
    KeySystem = {
        Key = "fishit123",
        Note = "Donate me if you happy using this script :)",
        URL = "https://discord.gg/codepikk",
        SaveKey = true
    },
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
})

-- ===================================
-- ========== MAIN TAB ===============
-- ===================================

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

local FishingSection = MainTab:Section({
    Title = "Auto Fishing",
    Side = "Left"
})

local fishV1Toggle = FishingSection:Toggle({
    Title = "Auto Fishing V1",
    Description = "Perfect timing + delay",
    Default = false,
    Callback = function(v)
        autoFishingEnabled = v
        autoFishingV2Enabled = false
        
        if v then
            if fishV2Toggle then fishV2Toggle:Set(false) end
            task.spawn(autoFishingLoop)
        else
            fishingActive = false
            pcall(function() finishRemote:FireServer() end)
        end
    end
})

local fishV2Toggle = FishingSection:Toggle({
    Title = "Auto Fishing V2 FAST",
    Description = "Ultra fast fishing mode",
    Default = false,
    Callback = function(v)
        autoFishingV2Enabled = v
        autoFishingEnabled = false
        
        if v then
            if fishV1Toggle then fishV1Toggle:Set(false) end
            task.spawn(autoFishingV2Loop)
        else
            fishingActive = false
            pcall(function() finishRemote:FireServer() end)
        end
    end
})

local UtilitySection = MainTab:Section({
    Title = "Utilities",
    Side = "Left"
})

UtilitySection:Toggle({
    Title = "Auto Sell All",
    Description = "Sell non-favorite fish",
    Default = false,
    Callback = function(v)
        autoSellEnabled = v
        if v then
            task.spawn(autoSellLoop)
        end
    end
})

UtilitySection:Toggle({
    Title = "Auto Favorite",
    Description = "Secret/Mythic/Legendary",
    Default = false,
    Callback = function(v)
        autoFavoriteEnabled = v
        if v then
            startAutoFavorite()
        end
    end
})

-- ===================================
-- ========== TELEPORT TAB ===========
-- ===================================

local TeleportTab = Window:Tab({
    Title = "Teleports",
    Icon = "map-pin"
})

-- Fix untuk dropdown islands
local IslandSection = TeleportTab:Section({
    Title = "Islands",
    Side = "Left"
})

-- Buat list islands dengan pengecekan
local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

-- Pastikan ada item dalam list
if #islandNames > 0 then
    IslandSection:Dropdown({
        Title = "Select Island",
        List = islandNames,
        Default = islandNames[1],
        Callback = function(v)
            local pos = islandCoords[v]
            if pos then
                teleportToPosition(pos, v)
            end
        end
    })
else
    IslandSection:Label({
        Title = "No Islands Available",
        Description = "Check island coordinates"
    })
end

-- Fix untuk dropdown NPCs
local NPCSection = TeleportTab:Section({
    Title = "NPCs",
    Side = "Right"
})

local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
local npcList = {}

if npcFolder then
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end
    table.sort(npcList)
end

-- Pastikan NPC list tidak kosong
if #npcList > 0 then
    NPCSection:Dropdown({
        Title = "Select NPC",
        List = npcList,
        Default = npcList[1],
        Callback = function(v)
            local npc = npcFolder:FindFirstChild(v)
            if npc and npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                if hrp then
                    local charFolder = workspace:FindFirstChild("Characters")
                    local char = charFolder and charFolder:FindFirstChild(player.Name)
                    if char then
                        local myHRP = char:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            pcall(function()
                                myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                            end)
                        end
                    end
                end
            end
        end
    })
else
    NPCSection:Label({
        Title = "No NPCs Found",
        Description = "NPC folder not available"
    })
end

-- Fix untuk dropdown Events
local EventSection = TeleportTab:Section({
    Title = "Events",
    Side = "Right"
})

local eventsList = {"Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"}

EventSection:Dropdown({
    Title = "Select Event",
    List = eventsList,
    Default = eventsList[1],
    Callback = function(v)
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

        local eventObject = findEventLocation(v)
        
        if eventObject then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                    if fishingBoat then
                        hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                    else
                        hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                    end
                end)
            end
        end
    end
})

-- ===================================
-- ========== MISC TAB ===============
-- ===================================

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "settings"
})

local SystemSection = MiscTab:Section({
    Title = "System",
    Side = "Left"
})

SystemSection:Toggle({
    Title = "Anti-AFK",
    Description = "Prevent AFK kick",
    Default = false,
    Callback = function(v)
        toggleAntiAFK()
    end
})

SystemSection:Button({
    Title = "Boost FPS",
    Description = "Optimize graphics",
    Callback = function()
        BoostFPS()
    end
})

local InfoSection = MiscTab:Section({
    Title = "Information",
    Side = "Right"
})

InfoSection:Label({
    Title = "Script Version",
    Description = "V2.5 WindUI Edition"
})

InfoSection:Label({
    Title = "Made by",
    Description = "Codepikk"
})

InfoSection:Label({
    Title = "Discord",
    Description = "codepikk"
})

-- ===================================
-- ========== FIX FISHING V2 =========
-- ===================================

-- Tambahan fix untuk fishing v2
task.spawn(function()
    while true do
        if autoFishingV2Enabled and not fishingActive then
            pcall(function()
                fishingActive = true
                equipRemote:FireServer(1)
                task.wait(0.1)
                
                local timestamp = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(timestamp)
                task.wait(0.1)
                
                local baseX, baseY = -0.7499996, 1
                local x = baseX + (math.random(-300, 300) / 10000000)
                local y = baseY + (math.random(-300, 300) / 10000000)

                miniGameRemote:InvokeServer(x, y)
                task.wait(0.2)
                finishRemote:FireServer(true)
                task.wait(0.1)
                finishRemote:FireServer()
                task.wait(math.random(5, 15) / 100)
            end)
        end
        task.wait(0.1)
    end
end)

print("🐟 Fish It Script Loaded Successfully!")

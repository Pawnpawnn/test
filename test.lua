local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ===================================
-- ========== LOAD FLUENT UI =========
-- ===================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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
    
    Fluent:Notify({
        Title = "FPS Boost",
        Content = "FPS optimization completed!",
        Duration = 3
    })
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
        
        Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK system activated!",
            Duration = 3
        })
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK system disabled!",
            Duration = 3
        })
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
        Fluent:Notify({
            Title = "Teleport Failed",
            Content = "Character not found!",
            Duration = 3
        })
        return false 
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        Fluent:Notify({
            Title = "Teleport Failed",
            Content = "HumanoidRootPart not found!",
            Duration = 3
        })
        return false 
    end

    local success = pcall(function()
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end)

    if success then
        Fluent:Notify({
            Title = "Teleport Success",
            Content = "Teleported to " .. name,
            Duration = 3
        })
    end

    return success
end

-- ===================================
-- ========== CREATE FLUENT UI =======
-- ===================================

setupRemotes()

local Window = Fluent:CreateWindow({
    Title = "🐟 Fish It Premium - Codepikk",
    SubTitle = "by Codepikk",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "sliders-horizontal" })
}

local Options = Fluent.Options

-- ===================================
-- ========== MAIN TAB ===============
-- ===================================

Tabs.Main:AddParagraph({
    Title = "🎣 Auto Fishing",
    Content = "Choose between V1 (stable) or V2 (fast) fishing mode"
})

local FishV1Toggle = Tabs.Main:AddToggle("FishV1", {
    Title = "Auto Fishing V1",
    Description = "Perfect timing with delay (Recommended)",
    Default = false,
    Callback = function(Value)
        autoFishingEnabled = Value
        
        if Value then
            if autoFishingV2Enabled then
                autoFishingV2Enabled = false
                Options.FishV2:SetValue(false)
            end
            
            Fluent:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 started!",
                Duration = 3
            })
            
            task.spawn(autoFishingLoop)
        else
            fishingActive = false
            pcall(function() finishRemote:FireServer() end)
            
            Fluent:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 stopped!",
                Duration = 3
            })
        end
    end
})

local FishV2Toggle = Tabs.Main:AddToggle("FishV2", {
    Title = "Auto Fishing V2 FAST ⚡",
    Description = "Ultra fast fishing mode (May be detected)",
    Default = false,
    Callback = function(Value)
        autoFishingV2Enabled = Value
        
        if Value then
            if autoFishingEnabled then
                autoFishingEnabled = false
                Options.FishV1:SetValue(false)
            end
            
            Fluent:Notify({
                Title = "Auto Fishing V2",
                Content = "Ultra Fast Fishing activated!",
                Duration = 3
            })
            
            task.spawn(autoFishingV2Loop)
        else
            fishingActive = false
            pcall(function() finishRemote:FireServer() end)
            
            Fluent:Notify({
                Title = "Auto Fishing V2",
                Content = "Ultra Fast Fishing stopped!",
                Duration = 3
            })
        end
    end
})

Tabs.Main:AddParagraph({
    Title = "💰 Auto Sell & Utilities",
    Content = "Automatic selling and item management"
})

Tabs.Main:AddToggle("AutoSell", {
    Title = "Auto Sell All",
    Description = "Automatically sell non-favorite fish",
    Default = false,
    Callback = function(Value)
        autoSellEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "Auto Sell",
                Content = "Auto Sell started!",
                Duration = 3
            })
            task.spawn(autoSellLoop)
        else
            Fluent:Notify({
                Title = "Auto Sell",
                Content = "Auto Sell stopped!",
                Duration = 3
            })
        end
    end
})

Tabs.Main:AddToggle("AutoFav", {
    Title = "Auto Favorite ⭐",
    Description = "Auto favorite Secret/Mythic/Legendary items",
    Default = false,
    Callback = function(Value)
        autoFavoriteEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite started!",
                Duration = 3
            })
            startAutoFavorite()
        else
            Fluent:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite stopped!",
                Duration = 3
            })
        end
    end
})

-- ===================================
-- ========== TELEPORT TAB ===========
-- ===================================

Tabs.Teleport:AddParagraph({
    Title = "🏝️ Island Teleports",
    Content = "Teleport to various islands"
})

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

local IslandDropdown = Tabs.Teleport:AddDropdown("Islands", {
    Title = "Select Island",
    Values = islandNames,
    Multi = false,
    Default = 1,
})

IslandDropdown:OnChanged(function(Value)
    local pos = islandCoords[Value]
    if pos then
        teleportToPosition(pos, Value)
    end
end)

Tabs.Teleport:AddParagraph({
    Title = "🧍 NPC Teleports",
    Content = "Teleport to NPCs"
})

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
    
    local NPCDropdown = Tabs.Teleport:AddDropdown("NPCs", {
        Title = "Select NPC",
        Values = npcList,
        Multi = false,
        Default = 1,
    })
    
    NPCDropdown:OnChanged(function(Value)
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
                            Fluent:Notify({
                                Title = "NPC Teleport",
                                Content = "Teleported to " .. Value,
                                Duration = 3
                            })
                        end
                    end
                end
            end
        end
    end)
end

Tabs.Teleport:AddParagraph({
    Title = "🎯 Event Teleports",
    Content = "Teleport to active events (Only works when event is active)"
})

local eventsList = {"Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"}

local EventDropdown = Tabs.Teleport:AddDropdown("Events", {
    Title = "Select Event",
    Values = eventsList,
    Multi = false,
    Default = 1,
})

EventDropdown:OnChanged(function(Value)
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
                Fluent:Notify({
                    Title = "Event Teleport",
                    Content = "Teleported to " .. Value,
                    Duration = 3
                })
            end
        end
    else
        Fluent:Notify({
            Title = "Event Not Found",
            Content = Value .. " is not active right now!",
            Duration = 3
        })
    end
end)

-- ===================================
-- ========== MISC TAB ===============
-- ===================================

Tabs.Misc:AddParagraph({
    Title = "⚙️ System Settings",
    Content = "Various system utilities"
})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "Anti-AFK System",
    Description = "Prevents you from being kicked for inactivity",
    Default = false,
    Callback = function(Value)
        toggleAntiAFK()
    end
})

Tabs.Misc:AddButton({
    Title = "Boost FPS 🚀",
    Description = "Optimize graphics for better performance",
    Callback = function()
        BoostFPS()
    end
})

Tabs.Misc:AddParagraph({
    Title = "ℹ️ Script Information",
    Content = "Fish It Premium V2.5 Fluent Edition\n\nMade by: Codepikk\nDiscord: codepikk\n\nDonate me if you're happy using this script! :)"
})

-- ===================================
-- ========== SETTINGS TAB ===========
-- ===================================

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("FishItPremium")
SaveManager:SetFolder("FishItPremium/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()

-- ===================================
-- ========== NOTIFICATION ===========
-- ===================================

Fluent:Notify({
    Title = "Fish It Premium",
    Content = "Script loaded successfully! V2.5 Fluent Edition",
    Duration = 5
})

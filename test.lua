-- Full script with Teleport fixes
-- (Paste this replacing your old script file)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
-- ========== UTILS (CHAR & POPUP) ===
-- ===================================

-- getMyCharacter: prefer workspace.Characters[player.Name], fallback player.Character
local function getMyCharacter()
    local charFolder = workspace:FindFirstChild("Characters")
    if charFolder then
        local c = charFolder:FindFirstChild(player.Name)
        if c then return c end
    end
    -- fallback to regular player.Character (in case of different game builds)
    return player.Character or player.CharacterAdded:Wait()
end

-- small popup (auto-destroy) — mimic old UI brief popup when teleport
local function showTeleportPopup(title, content, dur)
    dur = dur or 2
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = dur,
        Image = 4483362458
    })
end

-- safe teleport helper
local function safeTeleportToPos(pos, yOffset)
    yOffset = yOffset or 5
    local char = getMyCharacter()
    if not char then
        showTeleportPopup("Teleport Error", "Character not found", 3)
        return false, "char nil"
    end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart") -- explicit
    if not hrp then
        showTeleportPopup("Teleport Error", "HumanoidRootPart not found", 3)
        return false, "hrp nil"
    end
    local ok, err = pcall(function()
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, yOffset, 0))
    end)
    if ok then
        return true
    else
        return false, err
    end
end

-- ===================================
-- ========== BOOST FPS ==============
-- ===================================

local function BoostFPS()
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Boosting FPS...",
        Duration = 3,
        Image = 4483362458
    })
    
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
    
    Rayfield:Notify({
        Title = "Success",
        Content = "FPS Boosted Successfully!",
        Duration = 3,
        Image = 4483362458
    })
end

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
        while state and state.AutoFavourite do
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
        
        Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK Enabled!",
            Duration = 3,
            Image = 4483362458
        })
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK Disabled!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== FISHING LOOPS ==========
-- (kept same as original)
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

                local head = getMyCharacter() and getMyCharacter():FindFirstChild("Head")
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
                Rayfield:Notify({
                    Title = "Auto Sell",
                    Content = "Successfully sold all items!",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end)
    end
end

-- ===================================
-- ========== TELEPORT SYSTEMS =======
-- ===================================

-- Koordinat island untuk teleport (public default list you provided)
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
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Codepikk Premium",
    LoadingTitle = "Fish It Auto Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = true,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main", 4483362458)
local MainSection = MainTab:CreateSection("Auto Fishing")

local FishingV1Toggle = MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (Perfect + Delay)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        autoFishingV2Enabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingLoop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Stopped!",
                Duration = 3
            })
            fishingActive = false
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end
    end,
})

local FishingV2Toggle = MainTab:CreateToggle({
    Name = "⚡ Auto Fishing V2 (FAST)",
    CurrentValue = false,
    Flag = "FishingV2Toggle",
    Callback = function(Value)
        autoFishingV2Enabled = Value
        autoFishingEnabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 ULTRA FAST Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV2Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Stopped!",
                Duration = 3
            })
            fishingActive = false
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end
    end,
})

local FishingV3Toggle = MainTab:CreateToggle({
    Name = "🚀 Auto Fishing V3 (TIMING EXPLOIT)",
    CurrentValue = false,
    Flag = "FishingV3Toggle",
    Callback = function(Value)
        autoFishingV3Enabled = Value
        autoFishingEnabled = false
        autoFishingV2Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 TIMING EXPLOIT Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV3Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
            fishingActive = false
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end
    end,
})

local InventorySection = MainTab:CreateSection("Inventory Management")

local AutoSellToggle = MainTab:CreateToggle({
    Name = "💰 Auto Sell All (Non-Favorite)",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(Value)
        autoSellEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Auto Sell Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoSellLoop)
        else
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Auto Sell Stopped!",
                Duration = 3
            })
        end
    end,
})

local AutoFavoriteToggle = MainTab:CreateToggle({
    Name = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        autoFavoriteEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Started!",
                Duration = 3,
                Image = 4483362458
            })
            startAutoFavourite()
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

local IslandSection = TeleportTab:CreateSection("Island Teleports")

local islandOptions = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "🏝️ Select Island",
    Options = islandOptions,
    CurrentOption = "Kohana",
    Flag = "IslandDropdown",
    Callback = function(Option)
        -- Auto popup + teleport (A behavior)
        local pos = islandCoords[Option]
        if not pos then
            Rayfield:Notify({
                Title = "Teleport System",
                Content = "Island not found!",
                Duration = 3
            })
            return
        end

        -- show small popup then teleport
        showTeleportPopup("Teleporting...", "To " .. Option, 1.2)
        task.delay(0.15, function()
            local ok, err = safeTeleportToPos(pos, 5)
            if ok then
                showTeleportPopup("Teleport System", "Teleported to " .. Option, 2)
            else
                showTeleportPopup("Teleport Error", tostring(err or "unknown"), 3)
            end
        end)
    end
})

-- NPC Teleport
local NPCSection = TeleportTab:CreateSection("NPC Teleports")

-- wait for NPC folder (avoid nil callbacks)
local npcFolder = nil
pcall(function()
    npcFolder = ReplicatedStorage:WaitForChild("NPC", 2)
    if not npcFolder then
        npcFolder = workspace:FindFirstChild("NPC") or workspace:FindFirstChild("NPCs")
    end
end)

local function getNPCList()
    local list = {}
    if not npcFolder then return list end
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(list, npc.Name)
            end
        end
    end
    return list
end

local npcList = getNPCList()
if #npcList > 0 then
    local NPCDropdown = TeleportTab:CreateDropdown({
        Name = "🧍 Select NPC",
        Options = npcList,
        CurrentOption = npcList[1],
        Flag = "NPCDropdown",
        Callback = function(Option)
            if not npcFolder then
                Rayfield:Notify({Title="NPC Teleport", Content="NPC folder not available", Duration=3})
                return
            end
            local npc = npcFolder:FindFirstChild(Option)
            if npc and npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                if hrp then
                    local char = getMyCharacter()
                    if not char then
                        Rayfield:Notify({Title="NPC Teleport", Content="Character not found", Duration=3})
                        return
                    end
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        local ok, err = pcall(function()
                            myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                        end)
                        if ok then
                            Rayfield:Notify({Title="NPC Teleport", Content="Teleported to NPC: "..Option, Duration=3, Image=4483362458})
                        else
                            Rayfield:Notify({Title="NPC Teleport", Content="Teleport failed: "..tostring(err), Duration=3})
                        end
                    else
                        Rayfield:Notify({Title="NPC Teleport", Content="HRP not found", Duration=3})
                    end
                else
                    Rayfield:Notify({Title="NPC Teleport", Content="NPC HRP not found", Duration=3})
                end
            else
                Rayfield:Notify({Title="NPC Teleport", Content="NPC not found", Duration=3})
            end
        end
    })
else
    -- no NPCs found: notify but allow refresh later (user can reopen UI)
    TeleportTab:CreateLabel("No NPCs found (will refresh on reload).")
end

-- Event Teleport
local EventSection = TeleportTab:CreateSection("Event Teleports")

local EventDropdown = TeleportTab:CreateDropdown({
    Name = "🎯 Select Event (Must be Active)",
    Options = {
        "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
        "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
    },
    CurrentOption = "Shark Hunt",
    Flag = "EventDropdown",
    Callback = function(option)
        Rayfield:Notify({Title="Event Teleport", Content="Searching for "..option.." ...", Duration=1.2})
        task.delay(0.2, function()
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

            local eventObject = findEventLocation(option)
            if eventObject then
                local char = getMyCharacter()
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local ok, err = pcall(function()
                        local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                        if fishingBoat and fishingBoat:GetPivot then
                            hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                        else
                            -- try GetPivot if available otherwise use PrimaryPart or Position
                            if eventObject.GetPivot then
                                hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                            elseif eventObject.PrimaryPart then
                                hrp.CFrame = eventObject.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
                            else
                                local pos = eventObject:FindFirstChildWhichIsA("BasePart") or eventObject
                                if pos and pos.Position then
                                    hrp.CFrame = CFrame.new(pos.Position + Vector3.new(0,10,0))
                                else
                                    error("No valid pivot found")
                                end
                            end
                        end
                    end)
                    if ok then
                        Rayfield:Notify({Title="Event Teleport", Content="Teleported to "..option, Duration=2})
                    else
                        Rayfield:Notify({Title="Event Teleport", Content="Teleport failed: "..tostring(err), Duration=3})
                    end
                else
                    Rayfield:Notify({Title="Event Teleport", Content="Character HRP not found", Duration=3})
                end
            else
                Rayfield:Notify({Title="Event Teleport", Content=option.." not found (make sure event is ACTIVE)", Duration=3})
            end
        end)
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

local MiscSection = MiscTab:CreateSection("Miscellaneous")

local AntiAFKToggle = MiscTab:CreateToggle({
    Name = "⏰ Anti-AFK System",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        toggleAntiAFK()
    end,
})

local BoostFPSButton = MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Fish It Auto V2.5 loaded successfully!",
    Duration = 5,
    Image = 4483362458
})

Rayfield:LoadConfiguration()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

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
-- ========== TELEPORT FUNCTIONS =====
-- ===================================

-- PERBAIKAN: Struktur data yang benar untuk islandCoords
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

-- Fungsi teleport yang lebih robust
local function teleportToPosition(position)
    local char = player.Character
    if not char then
        return false, "Character not found"
    end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid not found"
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false, "HumanoidRootPart not found"
    end
    
    -- Validasi position
    if not position or typeof(position) ~= "Vector3" then
        return false, "Invalid position"
    end
    
    local success, err = pcall(function()
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end)
    
    return success, err
end

-- Fungsi untuk mendapatkan NPC yang valid
local function getValidNPCs()
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    if not npcFolder then
        return {}
    end
    
    local validNPCs = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(validNPCs, {
                    Name = npc.Name,
                    Model = npc,
                    Position = hrp.Position
                })
            end
        end
    end
    
    return validNPCs
end

-- Fungsi untuk mendapatkan event yang aktif
local function getActiveEvents()
    local props = workspace:FindFirstChild("Props")
    if not props then
        return {}
    end
    
    local activeEvents = {}
    local eventNames = {
        "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
        "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
    }
    
    for _, eventName in ipairs(eventNames) do
        local eventFolder = props:FindFirstChild(eventName)
        if eventFolder and eventFolder:FindFirstChild("Fishing Boat") then
            local fishingBoat = eventFolder["Fishing Boat"]
            if fishingBoat then
                table.insert(activeEvents, {
                    Name = eventName,
                    Boat = fishingBoat
                })
            end
        end
    end
    
    return activeEvents
end

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
            finishRemote:FireServer()
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
            finishRemote:FireServer()
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
            finishRemote:FireServer()
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

-- Island Teleports
local IslandSection = TeleportTab:CreateSection("Island Teleports")

-- PERBAIKAN: Dropdown dengan callback yang benar
local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "🏝️ Select Island",
    Options = {
        "Weather Machine", "Esoteric Depths", "Tropical Grove", 
        "Stingray Shores", "Kohana Volcano", "Coral Reefs",
        "Crater Island", "Kohana", "Winter Fest",
        "Isoteric Island", "Treasure Hall", "Lost Shore",
        "Sishypus Statue", "Ancient Jungle"
    },
    CurrentOption = "Kohana",
    Flag = "IslandDropdown",
    Callback = function(SelectedOption)
        -- Hanya menyimpan pilihan, tidak langsung teleport
        -- Teleport dilakukan via tombol terpisah
    end,
})

-- PERBAIKAN: Tombol teleport terpisah dengan logika yang benar
local IslandTeleportButton = TeleportTab:CreateButton({
    Name = "🚀 Teleport to Selected Island",
    Callback = function()
        local selectedIsland = Rayfield.Flags["IslandDropdown"]
        local position = islandCoords[selectedIsland]
        
        if not position then
            Rayfield:Notify({
                Title = "Teleport Error",
                Content = "Invalid island selection!",
                Duration = 3
            })
            return
        end
        
        local success, err = teleportToPosition(position)
        
        if success then
            Rayfield:Notify({
                Title = "Teleport Success",
                Content = "Teleported to " .. selectedIsland,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Teleport Failed",
                Content = "Error: " .. tostring(err),
                Duration = 3
            })
        end
    end,
})

-- NPC Teleports
local NPCSection = TeleportTab:CreateSection("NPC Teleports")

-- PERBAIKAN: Validasi NPC sebelum membuat dropdown
local validNPCs = getValidNPCs()
local npcOptions = {}

if #validNPCs > 0 then
    for _, npcData in ipairs(validNPCs) do
        table.insert(npcOptions, npcData.Name)
    end
    
    local NPCDropdown = TeleportTab:CreateDropdown({
        Name = "🧍 Select NPC",
        Options = npcOptions,
        CurrentOption = npcOptions[1] or "",
        Flag = "NPCDropdown",
        Callback = function(SelectedOption)
            -- Hanya menyimpan pilihan
        end,
    })

    local NPCTeleportButton = TeleportTab:CreateButton({
        Name = "🚀 Teleport to Selected NPC",
        Callback = function()
            local selectedNPCName = Rayfield.Flags["NPCDropdown"]
            local targetNPC = nil
            
            -- Cari NPC yang sesuai
            for _, npcData in ipairs(validNPCs) do
                if npcData.Name == selectedNPCName then
                    targetNPC = npcData
                    break
                end
            end
            
            if not targetNPC then
                Rayfield:Notify({
                    Title = "Teleport Error",
                    Content = "NPC not found: " .. selectedNPCName,
                    Duration = 3
                })
                return
            end
            
            local hrp = targetNPC.Model:FindFirstChild("HumanoidRootPart") or targetNPC.Model.PrimaryPart
            if not hrp then
                Rayfield:Notify({
                    Title = "Teleport Error",
                    Content = "NPC has no valid root part",
                    Duration = 3
                })
                return
            end
            
            local success, err = teleportToPosition(hrp.Position)
            
            if success then
                Rayfield:Notify({
                    Title = "Teleport Success",
                    Content = "Teleported to " .. selectedNPCName,
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Teleport Failed",
                    Content = "Error: " .. tostring(err),
                    Duration = 3
                })
            end
        end,
    })
else
    TeleportTab:CreateLabel("❌ No NPCs found in ReplicatedStorage")
end

-- Event Teleports
local EventSection = TeleportTab:CreateSection("Event Teleports")

-- PERBAIKAN: Validasi event sebelum membuat dropdown
local activeEvents = getActiveEvents()
local eventOptions = {}

if #activeEvents > 0 then
    for _, eventData in ipairs(activeEvents) do
        table.insert(eventOptions, eventData.Name)
    end
    
    local EventDropdown = TeleportTab:CreateDropdown({
        Name = "🎯 Select Event",
        Options = eventOptions,
        CurrentOption = eventOptions[1] or "",
        Flag = "EventDropdown",
        Callback = function(SelectedOption)
            -- Hanya menyimpan pilihan
        end,
    })

    local EventTeleportButton = TeleportTab:CreateButton({
        Name = "🚀 Teleport to Selected Event",
        Callback = function()
            local selectedEventName = Rayfield.Flags["EventDropdown"]
            local targetEvent = nil
            
            -- Cari event yang sesuai
            for _, eventData in ipairs(activeEvents) do
                if eventData.Name == selectedEventName then
                    targetEvent = eventData
                    break
                end
            end
            
            if not targetEvent then
                Rayfield:Notify({
                    Title = "Teleport Error",
                    Content = "Event not found: " .. selectedEventName,
                    Duration = 3
                })
                return
            end
            
            local boatCFrame = targetEvent.Boat:GetPivot()
            local char = player.Character
            if not char then
                Rayfield:Notify({
                    Title = "Teleport Error",
                    Content = "Character not found",
                    Duration = 3
                })
                return
            end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                Rayfield:Notify({
                    Title = "Teleport Error",
                    Content = "HumanoidRootPart not found",
                    Duration = 3
                })
                return
            end
            
            local success, err = pcall(function()
                hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
            end)
            
            if success then
                Rayfield:Notify({
                    Title = "Teleport Success",
                    Content = "Teleported to " .. selectedEventName,
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Teleport Failed",
                    Content = "Error: " .. tostring(err),
                    Duration = 3
                })
            end
        end,
    })
else
    TeleportTab:CreateLabel("❌ No active events found")
end

-- Refresh button untuk events
local RefreshEventsButton = TeleportTab:CreateButton({
    Name = "🔄 Refresh Active Events",
    Callback = function()
        activeEvents = getActiveEvents()
        Rayfield:Notify({
            Title = "Events Refreshed",
            Content = "Found " .. #activeEvents .. " active events",
            Duration = 3,
            Image = 4483362458
        })
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

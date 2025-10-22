-------------------------------------------
----- =======[ Load Rayfield ] =======
-------------------------------------------

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-------------------------------------------
----- =======[ GLOBAL FUNCTION ] =======
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- Wait for network module with error handling
local net
pcall(function()
    net = ReplicatedStorage:WaitForChild("Packages", 10)
        :WaitForChild("_Index", 5)
        :WaitForChild("sleitnick_net@0.2.0", 5)
        :WaitForChild("net", 5)
end)

if not net then
    warn("Failed to load network module")
    return
end

local state = { 
    AutoFavourite = false, 
    AutoSell = false 
}

local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")

local Player = Players.LocalPlayer
local XPBar = Player:WaitForChild("PlayerGui"):WaitForChild("XP")

-- Anti-AFK Setup
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

for i,v in next, getconnections(LocalPlayer.Idled) do
    v:Disable()
end

task.spawn(function()
    if XPBar then
        XPBar.Enabled = true
    end
end)

-- Auto Reconnect Setup
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId

local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

-- Animation Setup
local RodIdle, RodReel, RodShake
local RodShakeAnim, RodIdleAnim, RodReelAnim

pcall(function()
    RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
    RodReel = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
    RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")

    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

    RodShakeAnim = animator:LoadAnimation(RodShake)
    RodIdleAnim = animator:LoadAnimation(RodIdle)
    RodReelAnim = animator:LoadAnimation(RodReel)
end)

local HttpService = game:GetService("HttpService")

-------------------------------------------
----- =======[ AUTO BOOST FPS ] =======
-------------------------------------------
local function BoostFPS()
    pcall(function()
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
    end)
end

task.spawn(BoostFPS)

-------------------------------------------
----- =======[ LOAD WINDOW ] =======
-------------------------------------------

local Window = Rayfield:CreateWindow({
    Name = "ZiaanHub - Fish It",
    LoadingTitle = "ZiaanHub Loading...",
    LoadingSubtitle = "by @ziaandev",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZiaanHub",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

Rayfield:Notify({
    Title = "ZiaanHub - Fish It",
    Content = "All Features Loaded Successfully!",
    Duration = 5,
    Image = 4483362458
})

-------------------------------------------
----- =======[ MAIN TABS ] =======
-------------------------------------------

local AutoFishTab = Window:CreateTab("🎣 Auto Fishing", 4483362458)
local UtilityTab = Window:CreateTab("⚙️ Utility", 4483362458)
local SettingsTab = Window:CreateTab("🔧 Settings", 4483362458)

-------------------------------------------
----- =======[ AUTO FISHING TAB ] =======
-------------------------------------------

local AutoFishSection = AutoFishTab:CreateSection("Fishing Automation")

local FuncAutoFishV2 = {
    REReplicateTextEffectV2 = nil,
    autofishV2 = false,
    perfectCastV2 = true,
    fishingActiveV2 = false,
    delayInitializedV2 = false
}

pcall(function()
    FuncAutoFishV2.REReplicateTextEffectV2 = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]
end)

local RodDelaysV2 = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8},
    ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1},
    ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local customDelayV2 = 1
local BypassDelayV2 = 0.5

local function getValidRodNameV2()
    local success, result = pcall(function()
        local player = Players.LocalPlayer
        local display = player.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        for _, tile in ipairs(display:GetChildren()) do
            local itemNamePath = tile:FindFirstChild("Inner") and 
                                tile.Inner:FindFirstChild("Tags") and 
                                tile.Inner.Tags:FindFirstChild("ItemName")
            if itemNamePath and itemNamePath:IsA("TextLabel") then
                local name = itemNamePath.Text
                if RodDelaysV2[name] then
                    return name
                end
            end
        end
    end)
    return success and result or nil
end

local function updateDelayBasedOnRodV2(showNotify)
    if FuncAutoFishV2.delayInitializedV2 then return end
    local rodName = getValidRodNameV2()
    if rodName and RodDelaysV2[rodName] then
        customDelayV2 = RodDelaysV2[rodName].custom
        BypassDelayV2 = RodDelaysV2[rodName].bypass
        FuncAutoFishV2.delayInitializedV2 = true
        if showNotify and FuncAutoFishV2.autofishV2 then
            Rayfield:Notify({
                Title = "Rod Detected",
                Content = string.format("Rod: %s | Delay: %.2fs", rodName, customDelayV2),
                Duration = 3,
                Image = 4483362458
            })
        end
    else
        customDelayV2 = 10
        BypassDelayV2 = 1
        FuncAutoFishV2.delayInitializedV2 = true
    end
end

local function setupRodWatcher()
    pcall(function()
        local player = Players.LocalPlayer
        local display = player.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        display.ChildAdded:Connect(function()
            task.wait(0.05)
            if not FuncAutoFishV2.delayInitializedV2 then
                updateDelayBasedOnRodV2(true)
            end
        end)
    end)
end
setupRodWatcher()

-- Auto Sell System
local lastSellTime = 0
local AUTO_SELL_THRESHOLD = 60
local AUTO_SELL_DELAY = 60

local function startAutoSell()
    task.spawn(function()
        while state.AutoSell do
            pcall(function()
                if not _G.Replion then return end
                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end

                local unfavoritedCount = 0
                for _, item in ipairs(items) do
                    if not item.Favorited then
                        unfavoritedCount = unfavoritedCount + (item.Count or 1)
                    end
                end

                if unfavoritedCount >= AUTO_SELL_THRESHOLD and os.time() - lastSellTime >= AUTO_SELL_DELAY then
                    local netFolder = net
                    if netFolder then
                        local sellFunc = netFolder:FindFirstChild("RF/SellAllItems")
                        if sellFunc then
                            task.spawn(sellFunc.InvokeServer, sellFunc)
                            Rayfield:Notify({
                                Title = "Auto Sell",
                                Content = "Selling non-favorited items...",
                                Duration = 3,
                                Image = 4483362458
                            })
                            lastSellTime = os.time()
                        end
                    end
                end
            end)
            task.wait(10)
        end
    end)
end

-- Text Effect Connection
if FuncAutoFishV2.REReplicateTextEffectV2 then
    FuncAutoFishV2.REReplicateTextEffectV2.OnClientEvent:Connect(function(data)
        if FuncAutoFishV2.autofishV2 and FuncAutoFishV2.fishingActiveV2
        and data and data.TextData and data.TextData.EffectType == "Exclaim" then
            local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
            if myHead and data.Container == myHead then
                task.spawn(function()
                    for i = 1, 3 do
                        task.wait(BypassDelayV2)
                        finishRemote:FireServer()
                    end
                end)
            end
        end
    end)
end

function StartAutoFishV2()
    if FuncAutoFishV2.autofishV2 then return end
    
    FuncAutoFishV2.autofishV2 = true
    updateDelayBasedOnRodV2(true)
    task.spawn(function()
        while FuncAutoFishV2.autofishV2 do
            pcall(function()
                FuncAutoFishV2.fishingActiveV2 = true

                local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
                equipRemote:FireServer(1)
                task.wait(0.1)

                local chargeRemote = ReplicatedStorage
                    .Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                local timestamp = workspace:GetServerTimeNow()
                if RodShakeAnim then RodShakeAnim:Play() end
                rodRemote:InvokeServer(timestamp)

                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if FuncAutoFishV2.perfectCastV2 then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end

                if RodIdleAnim then RodIdleAnim:Play() end
                miniGameRemote:InvokeServer(x, y)

                task.wait(customDelayV2)
                FuncAutoFishV2.fishingActiveV2 = false
            end)
        end
    end)
end

function StopAutoFishV2()
    FuncAutoFishV2.autofishV2 = false
    FuncAutoFishV2.fishingActiveV2 = false
    FuncAutoFishV2.delayInitializedV2 = false
    if RodIdleAnim then RodIdleAnim:Stop() end
    if RodShakeAnim then RodShakeAnim:Stop() end
    if RodReelAnim then RodReelAnim:Stop() end
end

local BypassDelayInput = AutoFishTab:CreateInput({
    Name = "Bypass Delay",
    PlaceholderText = "Example: 1.45",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        local number = tonumber(value)
        if number then
            BypassDelayV2 = number
            Rayfield:Notify({
                Title = "Bypass Delay",
                Content = "Set to " .. number,
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

local AutoSellToggle = AutoFishTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(value)
        state.AutoSell = value
        if value then
            startAutoSell()
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Enabled",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

local AutoFishToggle = AutoFishTab:CreateToggle({
    Name = "Auto Fish V2 (Optimized)",
    CurrentValue = false,
    Flag = "AutoFishV2Toggle",
    Callback = function(value)
        if value then
            StartAutoFishV2()
            Rayfield:Notify({
                Title = "Auto Fish",
                Content = "Started",
                Duration = 2,
                Image = 4483362458
            })
        else
            StopAutoFishV2()
            Rayfield:Notify({
                Title = "Auto Fish",
                Content = "Stopped",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

local PerfectCastToggle = AutoFishTab:CreateToggle({
    Name = "Auto Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(value)
        FuncAutoFishV2.perfectCastV2 = value
    end,
})

-- Auto Favorite Section
AutoFishTab:CreateSection("Auto Favorite System")

local allowedTiers = { 
    ["Secret"] = true, 
    ["Mythic"] = true, 
    ["Legendary"] = true 
}

local function startAutoFavourite()
    task.spawn(function()
        while state.AutoFavourite do
            pcall(function()
                if not _G.Replion or not _G.ItemUtility then return end
                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end
                for _, item in ipairs(items) do
                    local base = _G.ItemUtility:GetItemData(item.Id)
                    if base and base.Data and allowedTiers[base.Data.Tier] and not item.Favorited then
                        item.Favorited = true
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

local AutoFavoriteToggle = AutoFishTab:CreateToggle({
    Name = "Enable Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(value)
        state.AutoFavourite = value
        if value then
            startAutoFavourite()
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Enabled",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

-- Manual Actions Section
AutoFishTab:CreateSection("Manual Actions")

function sellAllFishes()
    local success = pcall(function()
        local charFolder = workspace:FindFirstChild("Characters")
        local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found",
                Duration = 3,
                Image = 4483362458
            })
            return
        end

        local sellRemote = net:WaitForChild("RF/SellAllItems")
        Rayfield:Notify({
            Title = "Selling",
            Content = "Selling all fish...",
            Duration = 2,
            Image = 4483362458
        })
        
        task.wait(1)
        sellRemote:InvokeServer()
        Rayfield:Notify({
            Title = "Success",
            Content = "All fish sold!",
            Duration = 2,
            Image = 4483362458
        })
    end)
end

local SellButton = AutoFishTab:CreateButton({
    Name = "Sell All Fishes",
    Callback = function()
        sellAllFishes()
    end,
})

local EnchantButton = AutoFishTab:CreateButton({
    Name = "Auto Enchant Rod",
    Callback = function()
        pcall(function()
            local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
            local char = workspace:WaitForChild("Characters"):FindFirstChild(LocalPlayer.Name)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not hrp then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Character not found",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end

            Rayfield:Notify({
                Title = "Preparing",
                Content = "Place Enchant Stone in slot 5...",
                Duration = 3,
                Image = 4483362458
            })
            task.wait(3)

            local slot5 = LocalPlayer.PlayerGui.Backpack.Display:GetChildren()[10]
            local itemName = slot5 and slot5:FindFirstChild("Inner") and 
                            slot5.Inner:FindFirstChild("Tags") and 
                            slot5.Inner.Tags:FindFirstChild("ItemName")

            if not itemName or not itemName.Text:lower():find("enchant") then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No Enchant Stone in slot 5",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end

            local originalPosition = hrp.Position
            hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
            task.wait(1.2)

            local equipRod = net:WaitForChild("RE/EquipToolFromHotbar")
            local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")

            equipRod:FireServer(5)
            task.wait(0.5)
            activateEnchant:FireServer()
            task.wait(7)
            
            Rayfield:Notify({
                Title = "Success",
                Content = "Rod enchanted!",
                Duration = 3,
                Image = 4483362458
            })

            hrp.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
        end)
    end,
})

-------------------------------------------
----- =======[ UTILITY TAB ] =======
-------------------------------------------

local TeleportSection = UtilityTab:CreateSection("Teleport Utility")

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
    ["Sishypus Statue"] = Vector3.new(-3792, -135, -986)
}

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end

local IslandDropdown = UtilityTab:CreateDropdown({
    Name = "Island Teleport",
    Options = islandNames,
    CurrentOption = islandNames[1],
    Flag = "IslandDropdown",
    Callback = function(option)
        local position = islandCoords[option]
        if position then
            pcall(function()
                local charFolder = workspace:WaitForChild("Characters", 5)
                local char = charFolder:FindFirstChild(LocalPlayer.Name)
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
                        Rayfield:Notify({
                            Title = "Teleported",
                            Content = "To " .. option,
                            Duration = 2,
                            Image = 4483362458
                        })
                    end
                end
            end)
        end
    end,
})

local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

local EventDropdown = UtilityTab:CreateDropdown({
    Name = "Event Teleport",
    Options = eventsList,
    CurrentOption = eventsList[1],
    Flag = "EventDropdown",
    Callback = function(option)
        pcall(function()
            local props = workspace:FindFirstChild("Props")
            if props and props:FindFirstChild(option) and props[option]:FindFirstChild("Fishing Boat") then
                local fishingBoat = props[option]["Fishing Boat"]
                local boatCFrame = fishingBoat:GetPivot()
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
                    Rayfield:Notify({
                        Title = "Teleported",
                        Content = "To " .. option,
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Not Found",
                    Content = option .. " event not active",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end)
    end,
})

-- NPC Teleport
local npcList = {}
pcall(function()
    local npcFolder = ReplicatedStorage:WaitForChild("NPC")
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end
end)

if #npcList > 0 then
    local NPCDropdown = UtilityTab:CreateDropdown({
        Name = "NPC Teleport",
        Options = npcList,
        CurrentOption = npcList[1],
        Flag = "NPCDropdown",
        Callback = function(selectedName)
            pcall(function()
                local npcFolder = ReplicatedStorage:WaitForChild("NPC")
                local npc = npcFolder:FindFirstChild(selectedName)
                if npc and npc:IsA("Model") then
                    local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                    if hrp then
                        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
                        if char then
                            local myHRP = char:FindFirstChild("HumanoidRootPart")
                            if myHRP then
                                myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                                Rayfield:Notify({
                                    Title = "Teleported",
                                    Content = "To " .. selectedName,
                                    Duration = 2,
                                    Image = 4483362458
                                })
                            end
                        end
                    end
                end
            end)
        end,
    })
end

-- Server Utility Section
UtilityTab:CreateSection("Server Utility")

local function Rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

local function ServerHop()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""

    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers > 0

    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
    else
        Rayfield:Notify({
            Title = "Error",
            Content = "No servers available",
            Duration = 3,
            Image = 4483362458
        })
    end
end

local RejoinButton = UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Rejoin()
    end,
})

local ServerHopButton = UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        ServerHop()
    end,
})

-- Visual Utility Section
UtilityTab:CreateSection("Visual Utility")

local HDRButton = UtilityTab:CreateButton({
    Name = "HDR Shader",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/avvr1gTW"))()
        end)
    end,
})

-------------------------------------------
----- =======[ SETTINGS TAB ] =======
-------------------------------------------

SettingsTab:CreateSection("Anti-AFK System")

local AntiAFKEnabled = true
local AFKConnection = nil

local AntiAFKToggle = SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFKToggle",
    Callback = function(value)
        AntiAFKEnabled = value
        if AntiAFKEnabled then
            if AFKConnection then
                AFKConnection:Disconnect()
            end
            
            AFKConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)

            Rayfield:Notify({
                Title = "Anti-AFK",
                Content = "Activated",
                Duration = 2,
                Image = 4483362458
            })
        else
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end

            Rayfield:Notify({
                Title = "Anti-AFK",
                Content = "Deactivated",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

-- Information Section
SettingsTab:CreateSection("Script Information")

SettingsTab:CreateLabel("ZiaanHub - Fish It")
SettingsTab:CreateLabel("Version: 1.7.0 (Rayfield)")
SettingsTab:CreateLabel("Developer: @ziaandev")
SettingsTab:CreateLabel("Status: Operational")

-- Destroy UI Button
SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- Final notification
task.wait(0.5)
Rayfield:Notify({
    Title = "ZiaanHub - Fish It",
    Content = "Script loaded successfully!",
    Duration = 5,
    Image = 4483362458
})

print("==============================================")
print("ZiaanHub Fish It v1.7.0 - Loaded Successfully!")
print("UI Library: Rayfield")
print("All features initialized")
print("==============================================")
print("")
print("Features:")
print("✓ Auto Fish V2 with Rod Detection")
print("✓ Auto Sell System")
print("✓ Auto Favorite (Secret/Mythic/Legendary)")
print("✓ Island & Event Teleport")
print("✓ Auto Enchant Rod")
print("✓ Server Hop & Rejoin")
print("✓ Anti-AFK System")
print("==============================================")
print("")
print("Press Right Shift to toggle UI")

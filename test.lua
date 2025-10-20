-- WindUI-converted FishIt (Purple Premium)
-- Paste ini menggantikan UI lama. Logic (remotes, loops, teleports) tidak diubah.

-- =========================
-- ========== SETUP ========
-- =========================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

-- state & remotes (kept from original)
local autoFishingEnabled = false
local autoFishingV2Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false

local net
local rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote

local AFKConnection = nil

-- helper create (dipakai untuk fallback UI)
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

local function addHover(btn, normal, hover)
    btn.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play()
        end)
    end)
    btn.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
        end)
    end)
end

-- update status function (UI will hook into this)
local statusLabel
local function updateStatus(newStatus, color)
    -- update UI label if available
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = newStatus .. "\n" .. "Script: V.2.5\nNote: Donate me if you happy using this script :)"
        if color then
            statusLabel.TextColor3 = color
        end
    end
    -- also print to console (useful)
    pcall(function() print("[FishIt Status] " .. tostring(newStatus)) end)
end

-- ===================================
-- ========== LOGIC (UNCHANGED) ======
-- ===================================

-- (I copy/paste the original logic functions and loops, *untouched*.)
-- Setup remotes
local function setupRemotes()
    local success, err = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
    end)

    if not success then
        net = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:WaitForChild("Net")
    end

    -- Use pcall in case structure differs in some games
    pcall(function()
        if net then
            rodRemote = net:WaitForChild("RF/ChargeFishingRod")
            miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
            finishRemote = net:WaitForChild("RE/FishingCompleted")
            equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
            sellRemote = net:WaitForChild("RF/SellAllItems")
        else
            rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote = nil, nil, nil, nil, nil
        end
    end)
end

-- Boost FPS (kept)
local function BoostFPS()
    updateStatus("🚀 Boosting FPS...", Color3.fromRGB(255, 200, 100))

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
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    updateStatus("✅ FPS Boosted Successfully", Color3.fromRGB(100, 255, 100))
end

-- Auto Favorite (kept)
local allowedTiers = { ["Secret"] = true, ["Mythic"] = true, ["Legendary"] = true }

local function startAutoFavorite()
    task.spawn(function()
        while autoFavoriteEnabled do
            pcall(function()
                updateStatus("⭐ Scanning items...", Color3.fromRGB(255, 215, 0))
                local totalFavorited, totalChecked = 0, 0

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
                else
                    local favoriteRemote = ReplicatedStorage:FindFirstChild("FavoriteItem") or ReplicatedStorage:FindFirstChild("ToggleFavorite")
                    if favoriteRemote then
                        updateStatus("⭐ Using remote system...", Color3.fromRGB(100, 255, 100))
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

                if totalFavorited > 0 then
                    updateStatus("✅ Done! Fav: " .. totalFavorited .. " items", Color3.fromRGB(100, 255, 100))
                else
                    updateStatus("ℹ️ No items to favorite", Color3.fromRGB(255, 255, 100))
                end
            end)

            for i = 1, 20 do
                if not autoFavoriteEnabled then break end
                task.wait(0.5)
            end
        end
        updateStatus("🔴 Auto Favorite: Stopped")
    end)
end

-- Auto fishing loops (kept)
local function autoFishingLoop()
    while autoFishingEnabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("🎣 Status: Fishing V1", Color3.fromRGB(100, 255, 100))
            if equipRemote then pcall(function() equipRemote:FireServer(1) end) end
            task.wait(0.5)

            local timestamp = workspace:GetServerTimeNow()
            if rodRemote then pcall(function() rodRemote:InvokeServer(timestamp) end) end

            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-500, 500) / 10000000)
            local y = baseY + (math.random(-500, 500) / 10000000)

            if miniGameRemote then pcall(function() miniGameRemote:InvokeServer(x, y) end) end
            task.wait(5)
            if finishRemote then pcall(function() finishRemote:FireServer(true) end) end
            task.wait(5)
        end)
        task.wait(0.2)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            if equipRemote then pcall(function() equipRemote:FireServer(1) end) end

            local timestamp = workspace:GetServerTimeNow()
            if rodRemote then pcall(function() rodRemote:InvokeServer(timestamp) end) end

            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-300, 300) / 10000000)
            local y = baseY + (math.random(-300, 300) / 10000000)

            if miniGameRemote then pcall(function() miniGameRemote:InvokeServer(x, y) end) end
            task.wait(0.5)
            if finishRemote then pcall(function() finishRemote:FireServer(true) end) end
            task.wait(0.3)
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end)
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- Exclaim detection (kept)
task.spawn(function()
    local success, exclaimEvent = pcall(function()
        return net and net:WaitForChild("RE/ReplicateTextEffect", 2)
    end)

    if success and exclaimEvent then
        exclaimEvent.OnClientEvent:Connect(function(data)
            if (autoFishingEnabled or autoFishingV2Enabled) and data and data.TextData and data.TextData.EffectType == "Exclaim" then
                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    task.spawn(function()
                        if autoFishingV2Enabled then
                            task.wait(0.1)
                            if finishRemote then pcall(function() finishRemote:FireServer() end) end
                        else
                            for i = 1, 3 do
                                task.wait(1)
                                if finishRemote then pcall(function() finishRemote:FireServer() end) end
                            end
                        end
                    end)
                end
            end
        end)
    end
end)

-- Auto sell (kept)
local function autoSellLoop()
    while autoSellEnabled do
        task.wait(1)
        local success, err = pcall(function()
            updateStatus("💰 Status: Selling", Color3.fromRGB(255, 215, 0))
            local sellSuccess = pcall(function()
                if sellRemote then sellRemote:InvokeServer() end
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

-- Island coords (kept)
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

-- Teleport helper functions (kept)
local function createTeleportGUI()
    -- This function will be called by the WindUI teleport buttons.
    -- We keep original behavior but we will not create a separate window here since
    -- the WindUI collapsible will handle the list. For compatibility, implement a direct teleport action.
    -- (This function kept as fallback in case needed.)
    updateStatus("ℹ️ Teleport GUI requested - use sidebar teleport list.", Color3.fromRGB(255, 200, 100))
end

local function createNPCTeleportAction(npcName)
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    if not npcFolder then
        updateStatus("❌ NPC folder not found")
        return
    end

    local npc = npcFolder:FindFirstChild(npcName)
    if not npc or not npc:IsA("Model") then
        updateStatus("❌ NPC not found: " .. tostring(npcName))
        return
    end

    local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
    if not hrp then
        updateStatus("❌ NPC HRP not found")
        return
    end

    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(player.Name)
    if not char then
        updateStatus("❌ Character not found")
        return
    end

    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        updateStatus("❌ HRP not found")
        return
    end

    local ok, err = pcall(function()
        myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
    end)
    if ok then
        updateStatus("✅ Teleported to: " .. npcName, Color3.fromRGB(100, 255, 100))
    else
        updateStatus("❌ Teleport failed: " .. tostring(err))
    end
end

local function createEventTeleportAction(eventName)
    updateStatus("🔍 Searching event: " .. eventName, Color3.fromRGB(255, 200, 100))

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

    local eventObject = findEventLocation(eventName)
    if not eventObject then
        updateStatus("❌ " .. eventName .. " not found (make sure event is active)", Color3.fromRGB(255, 100, 100))
        return
    end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        updateStatus("❌ HRP not found")
        return
    end

    local ok, err = pcall(function()
        local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
        if fishingBoat then
            hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
            updateStatus("✅ Teleported to Fishing Boat " .. eventName, Color3.fromRGB(100, 255, 100))
        else
            hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
            updateStatus("✅ Teleported to " .. eventName, Color3.fromRGB(100, 255, 100))
        end
    end)
    if not ok then
        updateStatus("❌ Teleport failed: " .. tostring(err))
    end
end

-- ===================================
-- ========== WIND UI CREATION ========
-- ===================================

-- Destroy old GUI if exists
if playerGui:FindFirstChild("FishItAutoGUI") then
    pcall(function() playerGui:FindFirstChild("FishItAutoGUI"):Destroy() end)
end

-- Try load WindUI
local okWind, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

-- We'll create handles for UI elements so logic can bind
local uiHandles = {
    toggleFishingV1 = nil,
    toggleFishingV2 = nil,
    toggleAutoSell = nil,
    toggleAutoFav = nil,
    toggleAntiAFK = nil,
    boostFPSBtn = nil,
    statusLabelRef = nil,
    closeFunction = nil,
    minimizeFunction = nil,
    teleportContainer = nil
}

-- Helper to safely set button text + color
local function setToggleVisual(btn, enabled)
    pcall(function()
        if btn and btn:IsA("TextButton") then
            if enabled then
                btn.Text = "STOP"
                btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            else
                btn.Text = "START"
                btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            end
        end
    end)
end

-- Fallback function to render UI using basic Instances if WindUI missing
local function createFallbackUI()
    -- Simple frame similar to previous UI but with purple theme
    local screenGui = create("ScreenGui", {
        Name = "FishItAutoGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    local mainFrame = create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = UDim2.new(0, 360, 0, 420),
        Position = UDim2.new(0.5, -180, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(18, 12, 30), -- dark purple
        BorderSizePixel = 0
    })
    create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0, 12)})
    create("UIStroke", {Parent = mainFrame, Color = Color3.fromRGB(120, 60, 170), Thickness = 1.2})

    -- Title
    local title = create("TextLabel", {
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(30, 20, 48),
        Text = "🐟 Fish It - Premium (Purple)",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 160, 255)
    })
    create("UICorner", {Parent = title, CornerRadius = UDim.new(0, 10)})

    -- Status box
    local statusBox = create("Frame", {
        Parent = mainFrame,
        Size = UDim2.new(1, -20, 0, 60),
        Position = UDim2.new(0, 10, 0, 46),
        BackgroundColor3 = Color3.fromRGB(25, 15, 40),
    })
    create("UICorner", {Parent = statusBox, CornerRadius = UDim.new(0, 8)})
    create("UIStroke", {Parent = statusBox, Color = Color3.fromRGB(100, 40, 150), Thickness = 1})

    statusLabel = create("TextLabel", {
        Parent = statusBox,
        Size = UDim2.new(1, -12, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundTransparency = 1,
        Text = "🔴 Status: Idle\nScript: V.2.5\nNote: Donate me if you happy using this script :)",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 130, 255),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Main buttons (simple layout; enough as fallback)
    local y = 120
    local function addSection(titleText, btnText)
        local frame = create("Frame", {
            Parent = mainFrame,
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, y),
            BackgroundColor3 = Color3.fromRGB(22, 14, 36)
        })
        create("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 8)})
        create("UIStroke", {Parent = frame, Color = Color3.fromRGB(90, 40, 140), Thickness = 1})
        local label = create("TextLabel", {
            Parent = frame,
            Size = UDim2.new(0.6, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = titleText,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(220, 220, 255),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local btn = create("TextButton", {
            Parent = frame,
            Size = UDim2.new(0, 80, 0, 28),
            Position = UDim2.new(1, -90, 0, 6),
            BackgroundColor3 = Color3.fromRGB(50, 150, 90),
            Text = btnText,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(255,255,255)
        })
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
        addHover(btn, btn.BackgroundColor3, Color3.fromRGB(120, 70, 180))
        y = y + 50
        return btn
    end

    local btnFishV1 = addSection("🎣 Auto Fishing V1", "START")
    local btnFishV2 = addSection("⚡ Auto Fishing V2", "START")
    local btnSell = addSection("💰 Auto Sell All", "START")
    local btnFav = addSection("⭐ Auto Favorite", "START")
    local btnAnti = addSection("⏰ Anti-AFK", "START")
    local btnBoost = addSection("🚀 Boost FPS", "BOOST")

    -- Hook fallback actions
    btnAnti.MouseButton1Click:Connect(function()
        antiAFKEnabled = not antiAFKEnabled
        if antiAFKEnabled then
            -- enable
            if AFKConnection then AFKConnection:Disconnect() end
            AFKConnection = player.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)
            btnAnti.Text = "STOP"
            btnAnti.BackgroundColor3 = Color3.fromRGB(200,50,50)
            updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100,255,100))
        else
            if AFKConnection then AFKConnection:Disconnect(); AFKConnection = nil end
            btnAnti.Text = "START"
            btnAnti.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("🔴 Status: Idle")
        end
    end)

    btnFishV1.MouseButton1Click:Connect(function()
        autoFishingEnabled = not autoFishingEnabled
        autoFishingV2Enabled = false
        if autoFishingEnabled then
            btnFishV1.Text = "STOP"
            btnFishV1.BackgroundColor3 = Color3.fromRGB(200,50,50)
            btnFishV2.Text = "START"
            btnFishV2.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("🟢 Status: Auto Fishing V1 Started", Color3.fromRGB(100,255,100))
            task.spawn(autoFishingLoop)
        else
            btnFishV1.Text = "START"
            btnFishV1.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("🔴 Status: Auto Fishing Stopped")
            fishingActive = false
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end
    end)

    btnFishV2.MouseButton1Click:Connect(function()
        autoFishingV2Enabled = not autoFishingV2Enabled
        autoFishingEnabled = false
        if autoFishingV2Enabled then
            btnFishV2.Text = "STOP"
            btnFishV2.BackgroundColor3 = Color3.fromRGB(200,50,50)
            btnFishV1.Text = "START"
            btnFishV1.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("⚡ Status: Auto Fishing V2 ULTRA FAST", Color3.fromRGB(255,255,100))
            task.spawn(autoFishingV2Loop)
        else
            btnFishV2.Text = "START"
            btnFishV2.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("🔴 Status: Auto Fishing Stopped")
            fishingActive = false
            if finishRemote then pcall(function() finishRemote:FireServer() end) end
        end
    end)

    btnSell.MouseButton1Click:Connect(function()
        autoSellEnabled = not autoSellEnabled
        if autoSellEnabled then
            btnSell.Text = "STOP"
            btnSell.BackgroundColor3 = Color3.fromRGB(200,50,50)
            updateStatus("🟢 Status: Auto Sell Started", Color3.fromRGB(100,255,100))
            task.spawn(autoSellLoop)
        else
            btnSell.Text = "START"
            btnSell.BackgroundColor3 = Color3.fromRGB(50,150,90)
            updateStatus("🔴 Status: Auto Sell Stopped")
        end
    end)

    btnFav.MouseButton1Click:Connect(function()
        autoFavoriteEnabled = not autoFavoriteEnabled
        if autoFavoriteEnabled then
            btnFav.Text = "STOP"
            btnFav.BackgroundColor3 = Color3.fromRGB(200,50,50)
            startAutoFavorite()
        else
            btnFav.Text = "START"
            btnFav.BackgroundColor3 = Color3.fromRGB(130,80,150)
            updateStatus("🔴 Auto Favorite: Disabled")
        end
    end)

    btnBoost.MouseButton1Click:Connect(function()
        BoostFPS()
    end)

    -- save statusLabel ref
    statusLabel = statusLabel or statusLabel -- already set above

    updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(100,255,100))
end

-- If WindUI loaded, create Wind UI styled interface
if okWind and WindUI then
    -- Many WindUI libs return a table with CreateWindow / new / etc.
    -- We'll attempt a few common APIs gracefully.

    local SuccessCreate = false

    -- Try API pattern 1: WindUI:CreateWindow(opts)
    pcall(function()
        if WindUI.CreateWindow then
            local win = WindUI:CreateWindow({
                Title = "🐟 Fish It - Premium",
                Size = UDim2.new(0, 360, 0, 420),
                Theme = "Purple"
            })

            -- Sidebar pages (Main, Teleports, Misc)
            local mainPage = win:CreateTab("Main")
            local teleportPage = win:CreateTab("Teleports")
            local miscPage = win:CreateTab("Misc")

            -- Status (top of main)
            mainPage:CreateLabel("Status:"):SetText("🔴 Status: Idle\nScript: V.2.5\nNote: Donate if you're happy :)")
            -- store reference if library supports label update
            statusLabel = nil -- not accessible; so also print updates

            -- Buttons (Main)
            mainPage:CreateSection("Fishing")
            local btnFishV1 = mainPage:CreateToggle("Auto Fishing V1", false, function(val)
                autoFishingEnabled = val
                if val then
                    autoFishingV2Enabled = false
                    task.spawn(autoFishingLoop)
                end
            end)

            local btnFishV2 = mainPage:CreateToggle("Auto Fishing V2 (ULTRA)", false, function(val)
                autoFishingV2Enabled = val
                if val then
                    autoFishingEnabled = false
                    task.spawn(autoFishingV2Loop)
                end
            end)

            mainPage:CreateSection("Automation")
            local btnSell = mainPage:CreateToggle("Auto Sell All", false, function(val)
                autoSellEnabled = val
                if val then task.spawn(autoSellLoop) end
            end)
            local btnFav = mainPage:CreateToggle("Auto Favorite (Secret/Mythic/Legendary)", false, function(val)
                autoFavoriteEnabled = val
                if val then startAutoFavorite() end
            end)

            mainPage:CreateSection("Utility")
            local btnAntiAFK = mainPage:CreateToggle("Anti-AFK", false, function(val)
                antiAFKEnabled = val
                if val then
                    if AFKConnection then AFKConnection:Disconnect() end
                    AFKConnection = player.Idled:Connect(function()
                        pcall(function()
                            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                            task.wait(1)
                            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        end)
                    end)
                    updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100,255,100))
                else
                    if AFKConnection then AFKConnection:Disconnect(); AFKConnection = nil end
                    updateStatus("🔴 Status: Idle")
                end
            end)

            mainPage:CreateButton("Boost FPS", function()
                BoostFPS()
            end)

            -- Teleports (collapsible / accordion)
            teleportPage:CreateSection("Teleports (Collapsible)")
            -- Islands collapsible
            local islandsFold = teleportPage:CreateFolder("Islands")
            for islandName,_ in pairs(islandCoords) do
                islandsFold:CreateButton(islandName, function()
                    -- teleport to island
                    local charFolder = workspace:FindFirstChild("Characters")
                    local char = charFolder and charFolder:FindFirstChild(player.Name)
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            char.HumanoidRootPart.CFrame = islandCoords[islandName] + Vector3.new(0,5,0)
                        end)
                        updateStatus("✅ Success Teleport to " .. islandName, Color3.fromRGB(100,255,100))
                    else
                        updateStatus("❌ Character / HRP not found", Color3.fromRGB(255,100,100))
                    end
                end)
            end

            -- NPC collapsible: gather NPC list
            local npcFold = teleportPage:CreateFolder("NPCs")
            local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
            if npcFolder then
                for _, npc in ipairs(npcFolder:GetChildren()) do
                    if npc:IsA("Model") then
                        local nName = npc.Name
                        npcFold:CreateButton(nName, function()
                            createNPCTeleportAction(nName)
                        end)
                    end
                end
            else
                npcFold:CreateLabel("No NPC folder found")
            end

            -- Events collapsible
            local eventsFold = teleportPage:CreateFolder("Events")
            local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }
            for _, eName in ipairs(eventsList) do
                eventsFold:CreateButton(eName, function()
                    createEventTeleportAction(eName)
                end)
            end

            -- Misc page
            miscPage:CreateSection("Info")
            miscPage:CreateLabel("🐟 Fish It Premium V2.5\nMade by: Codepikk\nDiscord: codepikk")

            -- Close handling (if library provides close)
            if win.Close then
                win.Close:Connect(function()
                    autoFishingEnabled = false
                    autoFishingV2Enabled = false
                    autoSellEnabled = false
                    fishingActive = false
                    autoFavoriteEnabled = false
                    if AFKConnection then AFKConnection:Disconnect(); AFKConnection = nil end
                end)
            end

            SuccessCreate = true
        end
    end)

    -- Try API pattern 2: global functions style (some WindUI variants)
    if not SuccessCreate then
        pcall(function()
            if WindUI:Create then
                local win = WindUI:Create("Fish It - Premium", {Accent = "Purple"})
                local main = win:NewPage("Main")
                local tele = win:NewPage("Teleports")
                local misc = win:NewPage("Misc")

                main:NewSection("Status")
                main:NewLabel("🔴 Status: Idle\nScript: V.2.5")

                -- toggles
                main:NewToggle("Auto Fishing V1", false, function(v)
                    autoFishingEnabled = v
                    if v then task.spawn(autoFishingLoop) end
                end)
                main:NewToggle("Auto Fishing V2", false, function(v)
                    autoFishingV2Enabled = v
                    if v then task.spawn(autoFishingV2Loop) end
                end)
                main:NewToggle("Auto Sell", false, function(v)
                    autoSellEnabled = v
                    if v then task.spawn(autoSellLoop) end
                end)
                main:NewToggle("Auto Favorite", false, function(v)
                    autoFavoriteEnabled = v
                    if v then startAutoFavorite() end
                end)
                main:NewToggle("Anti-AFK", false, function(v)
                    antiAFKEnabled = v
                    if v then
                        if AFKConnection then AFKConnection:Disconnect() end
                        AFKConnection = player.Idled:Connect(function()
                            pcall(function()
                                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                                task.wait(1)
                                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                            end)
                        end)
                    else
                        if AFKConnection then AFKConnection:Disconnect(); AFKConnection = nil end
                    end
                end)
                main:NewButton("Boost FPS", function() BoostFPS() end)

                tele:NewSection("Islands")
                for islandName,_ in pairs(islandCoords) do
                    tele:NewButton(islandName, function()
                        local charFolder = workspace:FindFirstChild("Characters")
                        local char = charFolder and charFolder:FindFirstChild(player.Name)
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                char.HumanoidRootPart.CFrame = islandCoords[islandName] + Vector3.new(0,5,0)
                            end)
                            updateStatus("✅ Success Teleport to " .. islandName, Color3.fromRGB(100,255,100))
                        else
                            updateStatus("❌ Character / HRP not found", Color3.fromRGB(255,100,100))
                        end
                    end)
                end

                tele:NewSection("NPCs")
                local npcFolder2 = ReplicatedStorage:FindFirstChild("NPC")
                if npcFolder2 then
                    for _, npc in ipairs(npcFolder2:GetChildren()) do
                        if npc:IsA("Model") then
                            local nName = npc.Name
                            tele:NewButton(nName, function() createNPCTeleportAction(nName) end)
                        end
                    end
                else
                    tele:NewLabel("No NPC folder found")
                end

                tele:NewSection("Events")
                local eventsList2 = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }
                for _, eName in ipairs(eventsList2) do
                    tele:NewButton(eName, function() createEventTeleportAction(eName) end)
                end

                misc:NewSection("Info")
                misc:NewLabel("🐟 Fish It Premium V2.5\nMade by: Codepikk\nDiscord: codepikk")

                SuccessCreate = true
            end
        end)
    end

    -- If both attempts to use WindUI API failed, fallback to basic UI
    if not SuccessCreate then
        createFallbackUI()
    else
        -- If success with WindUI, still set a basic status updater to print updates,
        -- because not all WindUI instances expose an easy label handle.
        updateStatus("✅ Script Loaded Successfully (WindUI Purple Premium)", Color3.fromRGB(180,120,255))
    end
else
    -- WindUI failed to load: create fallback UI
    createFallbackUI()
end

-- ===================================
-- ========== BUTTON HOOKUPS =========
-- ===================================

-- Because the WindUI creation above might have directly created toggles that already control variables,
-- we only need to ensure that core button behaviors are consistent. The toggles in WindUI call the
-- same state variables and the loops watch those variables, so nothing else is required.

-- BUT: ensure remotes are setup
pcall(function() setupRemotes() end)

-- For safety - print that UI is ready
print("[FishIt] WindUI conversion loaded. Theme: Purple Premium")

-- Final status
updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(180,120,255))

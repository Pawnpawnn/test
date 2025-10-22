local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

-- Fungsi untuk membuat popup GUI
local function createPopupGUI(title, options, callback)
    -- Hapus GUI lama jika ada
    local existingGui = player.PlayerGui:FindFirstChild("TeleportPopupGUI")
    if existingGui then
        existingGui:Destroy()
    end

    -- Buat GUI baru
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "TeleportPopupGUI"
    popupGui.Parent = player.PlayerGui
    popupGui.ResetOnSpawn = false
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Parent = popupGui
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = popupGui
    mainFrame.Size = UDim2.new(0, 350, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 120, 255)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    -- Title
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Parent = mainFrame
    titleFrame.Size = UDim2.new(1, 0, 0, 50)
    titleFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
    titleFrame.BorderSizePixel = 0

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = titleFrame
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleFrame
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BorderSizePixel = 0

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Parent = mainFrame
    searchBox.Size = UDim2.new(1, -20, 0, 40)
    searchBox.Position = UDim2.new(0, 10, 0, 60)
    searchBox.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
    searchBox.PlaceholderText = "🔍 Search..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
    searchBox.Text = ""
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 14
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchBox

    local searchPadding = Instance.new("UIPadding")
    searchPadding.Parent = searchBox
    searchPadding.PaddingLeft = UDim.new(0, 12)

    -- Scroll frame untuk items
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Parent = mainFrame
    scrollFrame.Size = UDim2.new(1, -20, 1, -130)
    scrollFrame.Position = UDim2.new(0, 10, 0, 110)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.Parent = scrollFrame
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.Name

    local function updateButtons(filterText)
        -- Clear existing buttons
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        -- Filter options
        local filteredOptions = {}
        if filterText and filterText ~= "" then
            local lowerFilter = string.lower(filterText)
            for _, option in ipairs(options) do
                if string.lower(option):find(lowerFilter) then
                    table.insert(filteredOptions, option)
                end
            end
        else
            filteredOptions = options
        end

        -- Sort options
        table.sort(filteredOptions)

        -- Create buttons
        for _, option in ipairs(filteredOptions) do
            local button = Instance.new("TextButton")
            button.Name = option
            button.Parent = scrollFrame
            button.Size = UDim2.new(1, 0, 0, 45)
            button.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
            button.Text = ""
            button.BorderSizePixel = 0
            button.AutoButtonColor = false

            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 8)
            buttonCorner.Parent = button

            local buttonStroke = Instance.new("UIStroke")
            buttonStroke.Color = Color3.fromRGB(70, 90, 150)
            buttonStroke.Thickness = 1
            buttonStroke.Parent = button

            local buttonLabel = Instance.new("TextLabel")
            buttonLabel.Name = "Label"
            buttonLabel.Parent = button
            buttonLabel.Size = UDim2.new(1, -10, 1, 0)
            buttonLabel.Position = UDim2.new(0, 10, 0, 0)
            buttonLabel.BackgroundTransparency = 1
            buttonLabel.Text = option
            buttonLabel.Font = Enum.Font.Gotham
            buttonLabel.TextSize = 14
            buttonLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            buttonLabel.TextXAlignment = Enum.TextXAlignment.Left

            -- Hover effect
            button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(65, 70, 100)}):Play()
                TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 140, 255)}):Play()
            end)

            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 80)}):Play()
                TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(70, 90, 150)}):Play()
            end)

            -- Click event
            button.MouseButton1Click:Connect(function()
                -- Animation on click
                TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 120, 255)}):Play()
                task.wait(0.1)
                callback(option)
                popupGui:Destroy()
            end)
        end
    end

    -- Initial buttons
    updateButtons("")

    -- Search functionality
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        updateButtons(searchBox.Text)
    end)

    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        popupGui:Destroy()
    end)

    overlay.MouseButton1Click:Connect(function()
        popupGui:Destroy()
    end)

    -- Animation when opening
    mainFrame.Position = UDim2.new(0.5, -175, 0.3, -225)
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -175, 0.5, -225)
    }):Play()
end

-- Fungsi teleport ke island
local function teleportToIsland(islandName)
    local pos = islandCoords[islandName]
    if not pos then 
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Island not found!",
            Duration = 3
        })
        return
    end
    
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end)

    if success then
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Teleported to " .. islandName,
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Teleport Error: " .. tostring(err),
            Duration = 3
        })
    end
end

-- Fungsi teleport ke NPC
local function teleportToNPC(npcName)
    local npcFolder = workspace:FindFirstChild("NPC") or ReplicatedStorage:FindFirstChild("NPC")
    if not npcFolder then
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "NPC folder not found!",
            Duration = 3
        })
        return
    end

    local npc = npcFolder:FindFirstChild(npcName)
    if npc and npc:IsA("Model") then
        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
        if hrp then
            local char = player.Character or player.CharacterAdded:Wait()
            local myHRP = char:WaitForChild("HumanoidRootPart", 3)
            myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            Rayfield:Notify({
                Title = "Teleport System",
                Content = "Teleported to NPC: " .. npcName,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Teleport System",
                Content = "NPC HRP not found!",
                Duration = 3
            })
        end
    else
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "NPC not found!",
            Duration = 3
        })
    end
end

-- Fungsi teleport ke event
local function teleportToEvent(eventName)
    local props = workspace:FindFirstChild("Props")
    if props and props:FindFirstChild(eventName) and props[eventName]:FindFirstChild("Fishing Boat") then
        local fishingBoat = props[eventName]["Fishing Boat"]
        local boatCFrame = fishingBoat:GetPivot()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
        Rayfield:Notify({
            Title = "Event Teleport",
            Content = "Teleported to " .. eventName,
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Event Not Found",
            Content = eventName .. " Not Available!",
            Duration = 3
        })
    end
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
            startAutoFavorite()
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

-- Button untuk membuka popup island teleport
local IslandButton = TeleportTab:CreateButton({
    Name = "🏝️ Teleport to Island",
    Callback = function()
        local islandOptions = {
            "Weather Machine", "Esoteric Depths", "Tropical Grove", 
            "Stingray Shores", "Kohana Volcano", "Coral Reefs",
            "Crater Island", "Kohana", "Winter Fest",
            "Isoteric Island", "Treasure Hall", "Lost Shore",
            "Sishypus Statue", "Ancient Jungle"
        }
        
        createPopupGUI("🏝️ Select Island", islandOptions, teleportToIsland)
    end,
})

local NPCSection = TeleportTab:CreateSection("NPC Teleports")

-- Button untuk membuka popup NPC teleport
local NPCButton = TeleportTab:CreateButton({
    Name = "🧍 Teleport to NPC",
    Callback = function()
        local npcFolder = workspace:FindFirstChild("NPC") or ReplicatedStorage:FindFirstChild("NPC")
        if not npcFolder then
            Rayfield:Notify({
                Title = "Teleport System",
                Content = "NPC folder not found!",
                Duration = 3
            })
            return
        end
        
        local npcList = {}
        for _, npc in pairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                table.insert(npcList, npc.Name)
            end
        end
        
        if #npcList == 0 then
            Rayfield:Notify({
                Title = "Teleport System",
                Content = "No NPCs found!",
                Duration = 3
            })
            return
        end
        
        table.sort(npcList)
        createPopupGUI("🧍 Select NPC", npcList, teleportToNPC)
    end,
})

local EventSection = TeleportTab:CreateSection("Event Teleports")

-- Button untuk membuka popup event teleport
local EventButton = TeleportTab:CreateButton({
    Name = "🎯 Teleport to Event",
    Callback = function()
        local eventOptions = {
            "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
            "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
        }
        
        createPopupGUI("🎯 Select Event", eventOptions, teleportToEvent)
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

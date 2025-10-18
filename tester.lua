-- FREE.LUA - Simple Trial System
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Key dan waktu trial
local FREE_KEY = "FREE_CODEPIK"
local trialDuration = 5 * 60 -- 5 menit

-- Cek status trial
local function checkTrial()
    local savedTime = player:GetAttribute("FishItTrialStart")
    if savedTime then
        local elapsed = os.time() - savedTime
        if elapsed >= trialDuration then
            return false, "Trial expired! Please relog."
        end
        return true, "Trial active"
    end
    return false, "Need activation"
end

-- Tampilkan input key
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeyInputGUI"
keyGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 250)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
mainFrame.Parent = keyGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
title.Text = "🔑 FREE TRIAL ACTIVATION"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(100, 180, 255)
title.TextSize = 16
title.Parent = mainFrame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 40)
keyBox.Position = UDim2.new(0.1, 0, 0.3, 0)
keyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
keyBox.PlaceholderText = "Enter FREE key..."
keyBox.Text = ""
keyBox.Font = Enum.Font.Gotham
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 14
keyBox.Parent = mainFrame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.6, 0, 0, 40)
submitBtn.Position = UDim2.new(0.2, 0, 0.55, 0)
submitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
submitBtn.Text = "ACTIVATE TRIAL"
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 14
submitBtn.Parent = mainFrame

local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
getKeyBtn.Position = UDim2.new(0.2, 0, 0.75, 0)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
getKeyBtn.Text = "📱 GET KEY FROM DISCORD"
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
getKeyBtn.TextSize = 12
getKeyBtn.Parent = mainFrame

local statusMsg = Instance.new("TextLabel")
statusMsg.Size = UDim2.new(0.8, 0, 0, 30)
statusMsg.Position = UDim2.new(0.1, 0, 0.15, 0)
statusMsg.BackgroundTransparency = 1
statusMsg.Text = "Enter FREE key to start 5-minute trial"
statusMsg.Font = Enum.Font.Gotham
statusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
statusMsg.TextSize = 12
statusMsg.Parent = mainFrame

-- Fungsi untuk load script utama
local function loadMainScript()
    -- Cek trial
    local isValid = checkTrial()
    if not isValid then
        statusMsg.Text = "❌ Trial expired! Please relog."
        statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    -- Hapus GUI key
    keyGui:Destroy()

    -- ========== SCRIPT UTAMA ==========
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- State Variables
    local autoFishingEnabled = false
    local autoSellEnabled = false
    local antiAFKEnabled = false
    local fishingActive = false

    -- Remote Variables
    local net
    local rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote

    -- Connection Variables
    local AFKConnection = nil

    -- Helper function
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

    -- Setup remotes
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

    -- Hapus GUI lama jika ada
    if playerGui:FindFirstChild("FishItFreeGUI") then
        playerGui:FindFirstChild("FishItFreeGUI"):Destroy()
    end

    -- Main ScreenGui
    local screenGui = create("ScreenGui", {
        Name = "FishItFreeGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Main Frame
    local mainFrame = create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = UDim2.new(0, 300, 0, 420),
        Position = UDim2.new(0.5, -150, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = mainFrame, Color = Color3.fromRGB(100, 150, 255), Thickness = 1.5})

    -- Title Bar
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 33),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = titleBar, CornerRadius = UDim.new(0, 10)})

    local titleText = create("TextLabel", {
        Parent = titleBar,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "🐟 Fish It - FREE",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Timer Label
    local timerLabel = create("TextLabel", {
        Parent = titleBar,
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Text = "05:00",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 255, 100),
        TextXAlignment = Enum.TextXAlignment.Right
    })

    local closeBtn = create("TextButton", {
        Parent = titleBar,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -35, 0, 4),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})

    -- Content Frame
    local contentFrame = create("ScrollingFrame", {
        Name = "Content",
        Parent = mainFrame,
        Size = UDim2.new(1, -18, 1, -51),
        Position = UDim2.new(0, 9, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255),
        CanvasSize = UDim2.new(0, 0, 0, 400)
    })

    -- Status Section
    local statusBox = create("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
    })

    create("UICorner", {Parent = statusBox, CornerRadius = UDim.new(0, 7)})
    create("UIStroke", {Parent = statusBox, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    local statusLabel = create("TextLabel", {
        Parent = statusBox,
        Size = UDim2.new(1, -12, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundTransparency = 1,
        Text = "🔴 Status: Idle\n⏰ FREE TRIAL - 5 minutes",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local function updateStatus(newStatus, color)
        local baseText = "⏰ FREE TRIAL - 5 minutes"
        statusLabel.Text = newStatus .. "\n" .. baseText
        statusLabel.TextColor3 = color or Color3.fromRGB(255, 100, 100)
    end

    -- Anti-AFK Section
    local antiAFKSection = create("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 58),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
    })

    create("UICorner", {Parent = antiAFKSection, CornerRadius = UDim.new(0, 7)})
    create("UIStroke", {Parent = antiAFKSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    local antiAFKTitle = create("TextLabel", {
        Parent = antiAFKSection,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = "⏰ Anti-AFK System",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local antiAFKBtn = create("TextButton", {
        Parent = antiAFKSection,
        Size = UDim2.new(0, 72, 0, 27),
        Position = UDim2.new(1, -78, 0, 6),
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        Text = "START",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = antiAFKBtn, CornerRadius = UDim.new(0, 6)})

    -- Fishing Section
    local fishSection = create("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 106),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
    })

    create("UICorner", {Parent = fishSection, CornerRadius = UDim.new(0, 7)})
    create("UIStroke", {Parent = fishSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    local fishTitle = create("TextLabel", {
        Parent = fishSection,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = "🎣 Auto Fishing V1",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local fishBtn = create("TextButton", {
        Parent = fishSection,
        Size = UDim2.new(0, 72, 0, 27),
        Position = UDim2.new(1, -78, 0, 6),
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        Text = "START",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = fishBtn, CornerRadius = UDim.new(0, 6)})

    -- Auto Sell Section
    local sellSection = create("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 154),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
    })

    create("UICorner", {Parent = sellSection, CornerRadius = UDim.new(0, 7)})
    create("UIStroke", {Parent = sellSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    local sellTitle = create("TextLabel", {
        Parent = sellSection,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = "💰 Auto Sell All",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local sellBtn = create("TextButton", {
        Parent = sellSection,
        Size = UDim2.new(0, 72, 0, 27),
        Position = UDim2.new(1, -78, 0, 6),
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        Text = "START",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = sellBtn, CornerRadius = UDim.new(0, 6)})

    -- Teleport Section
    local teleportSection = create("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 202),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
    })

    create("UICorner", {Parent = teleportSection, CornerRadius = UDim.new(0, 7)})
    create("UIStroke", {Parent = teleportSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    local teleportTitle = create("TextLabel", {
        Parent = teleportSection,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = "📍 Teleport to Islands",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local teleportBtn = create("TextButton", {
        Parent = teleportSection,
        Size = UDim2.new(0, 72, 0, 27),
        Position = UDim2.new(1, -78, 0, 6),
        BackgroundColor3 = Color3.fromRGB(150, 100, 50),
        Text = "OPEN",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = teleportBtn, CornerRadius = UDim.new(0, 6)})

    -- Drag functionality
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Anti-AFK System
    local function toggleAntiAFK()
        antiAFKEnabled = not antiAFKEnabled
        
        if antiAFKEnabled then
            if AFKConnection then
                AFKConnection:Disconnect()
            end
            
            AFKConnection = player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
            
            antiAFKBtn.Text = "STOP"
            antiAFKBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100, 255, 100))
        else
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end
            
            antiAFKBtn.Text = "START"
            antiAFKBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            updateStatus("🔴 Status: Idle")
        end
    end

    -- Auto Fishing System
    local function autoFishingLoop()
        while autoFishingEnabled do
            pcall(function()
                fishingActive = true
                updateStatus("🎣 Status: Fishing", Color3.fromRGB(100, 255, 100))
                equipRemote:FireServer(1)
                wait(0.1)

                local timestamp = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(timestamp)

                local baseX, baseY = -0.7499996, 1
                local x = baseX + (math.random(-500, 500) / 10000000)
                local y = baseY + (math.random(-500, 500) / 10000000)

                miniGameRemote:InvokeServer(x, y)
                wait(2)
                finishRemote:FireServer(true)
                wait(2)
            end)
            wait(0.2)
        end
        fishingActive = false
        updateStatus("🔴 Status: Idle")
    end

    -- Auto Sell System
    local function autoSellLoop()
        while autoSellEnabled do
            wait(1)
            pcall(function()
                updateStatus("💰 Status: Selling", Color3.fromRGB(255, 215, 0))
                sellRemote:InvokeServer()
                updateStatus("✅ Status: Sold!", Color3.fromRGB(100, 255, 100))
            end)
        end
        updateStatus("🔴 Status: Idle")
    end

    -- Teleport System
    local islandCoords = {
        ["Weather Machine"] = Vector3.new(-1471, -3, 1929),
        ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
        ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
        ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    }

    local function createTeleportGUI()
        local teleportGui = create("ScreenGui", {
            Name = "TeleportGUI",
            Parent = playerGui,
        })

        local teleportFrame = create("Frame", {
            Name = "TeleportFrame",
            Parent = teleportGui,
            Size = UDim2.new(0, 280, 0, 200),
            Position = UDim2.new(0.5, -140, 0.5, -100),
            BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        })

        create("UICorner", {Parent = teleportFrame, CornerRadius = UDim.new(0, 10)})

        local teleportTitle = create("TextLabel", {
            Parent = teleportFrame,
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(25, 35, 55),
            Text = "📍 Island Teleport - FREE",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(100, 180, 255),
        })

        local closeBtn = create("TextButton", {
            Parent = teleportTitle,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -26, 0, 6),
            BackgroundColor3 = Color3.fromRGB(220, 50, 50),
            Text = "X",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })

        local scrollFrame = create("ScrollingFrame", {
            Parent = teleportFrame,
            Size = UDim2.new(1, -20, 1, -50),
            Position = UDim2.new(0, 10, 0, 45),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0, 0, 0, 200)
        })

        local yPosition = 0
        for islandName, position in pairs(islandCoords) do
            local islandBtn = create("TextButton", {
                Parent = scrollFrame,
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0, 0, 0, yPosition),
                BackgroundColor3 = Color3.fromRGB(35, 45, 65),
                Text = "📍 " .. islandName,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(220, 220, 220),
            })

            islandBtn.MouseButton1Click:Connect(function()
                local char = workspace.Characters:FindFirstChild(player.Name)
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        pcall(function()
                            hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
                            updateStatus("✅ Teleport to " .. islandName, Color3.fromRGB(100, 255, 100))
                            teleportGui:Destroy()
                        end)
                    end
                end
            end)

            yPosition = yPosition + 35
        end

        closeBtn.MouseButton1Click:Connect(function()
            teleportGui:Destroy()
        end)
    end

    -- Button Connections
    antiAFKBtn.MouseButton1Click:Connect(toggleAntiAFK)

    fishBtn.MouseButton1Click:Connect(function()
        autoFishingEnabled = not autoFishingEnabled
        if autoFishingEnabled then
            fishBtn.Text = "STOP"
            fishBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            spawn(autoFishingLoop)
        else
            fishBtn.Text = "START"
            fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            fishingActive = false
            finishRemote:FireServer()
        end
    end)

    sellBtn.MouseButton1Click:Connect(function()
        autoSellEnabled = not autoSellEnabled
        if autoSellEnabled then
            sellBtn.Text = "STOP"
            sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            spawn(autoSellLoop)
        else
            sellBtn.Text = "START"
            sellBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
    end)

    teleportBtn.MouseButton1Click:Connect(createTeleportGUI)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Timer Countdown
    local startTime = player:GetAttribute("FishItTrialStart")
    spawn(function()
        while true do
            local currentTime = os.time()
            local elapsed = currentTime - startTime
            local remaining = trialDuration - elapsed
            
            if remaining <= 0 then
                timerLabel.Text = "00:00"
                updateStatus("⏰ TRIAL EXPIRED", Color3.fromRGB(255, 50, 50))
                wait(3)
                game:Shutdown()
                break
            end
            
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
            wait(1)
        end
    end)

    -- Setup dan mulai
    setupRemotes()
    updateStatus("✅ FREE TRIAL Started", Color3.fromRGB(100, 255, 100))
    warn("🎣 Fish It FREE Loaded! Trial: 5 minutes")
end

-- Button events
submitBtn.MouseButton1Click:Connect(function()
    if keyBox.Text == FREE_KEY then
        player:SetAttribute("FishItTrialStart", os.time())
        statusMsg.Text = "✅ Key accepted! Loading..."
        statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(1)
        loadMainScript()
    else
        statusMsg.Text = "❌ Invalid key!"
        statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

getKeyBtn.MouseButton1Click:Connect(function()
    statusMsg.Text = "📱 Join Discord: your-discord-link"
    statusMsg.TextColor3 = Color3.fromRGB(100, 200, 255)
end)

-- Auto load jika trial masih aktif
local isValid = checkTrial()
if isValid then
    keyGui:Destroy()
    loadMainScript()
end

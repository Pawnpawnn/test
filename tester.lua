-- FREE.LUA - Trial System
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================================
-- ========== KEY SYSTEM ==============
-- ===================================
local FREE_KEY = "FISHIT_FREE_2024"
local trialDuration = 5 * 60 -- 5 menit

-- Cek trial status
local function checkTrial()
    local savedTime = player:GetAttribute("FishItTrialStart")
    
    if savedTime then
        local elapsed = os.time() - savedTime
        if elapsed >= trialDuration then
            return false, "Trial expired! Please relog to use again."
        end
        return true, "Trial time left: " .. math.floor((trialDuration - elapsed) / 60) .. " minutes"
    else
        player:SetAttribute("FishItTrialStart", os.time())
        return true, "Trial started! 5 minutes remaining"
    end
end

-- ===================================
-- ========== KEY INPUT GUI ===========
-- ===================================
local function createKeyInputGUI()
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
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 150, 255)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    title.Text = "🔑 FREE TRIAL ACTIVATION"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(100, 180, 255)
    title.TextSize = 16
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title
    
    -- Key Input
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8, 0, 0, 40)
    keyBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
    keyBox.PlaceholderText = "Enter FREE key..."
    keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    keyBox.Text = ""
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.TextSize = 14
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = mainFrame
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 8)
    keyCorner.Parent = keyBox
    
    -- Submit Button
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.6, 0, 0, 40)
    submitBtn.Position = UDim2.new(0.2, 0, 0.55, 0)
    submitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    submitBtn.Text = "ACTIVATE TRIAL"
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 14
    submitBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = submitBtn
    
    -- Get Key Button
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    getKeyBtn.Position = UDim2.new(0.2, 0, 0.75, 0)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
    getKeyBtn.Text = "📱 GET KEY FROM DISCORD"
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyBtn.TextSize = 12
    getKeyBtn.Parent = mainFrame
    
    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 8)
    getKeyCorner.Parent = getKeyBtn
    
    -- Status Message
    local statusMsg = Instance.new("TextLabel")
    statusMsg.Size = UDim2.new(0.8, 0, 0, 30)
    statusMsg.Position = UDim2.new(0.1, 0, 0.15, 0)
    statusMsg.BackgroundTransparency = 1
    statusMsg.Text = "Enter FREE key to start 5-minute trial"
    statusMsg.Font = Enum.Font.Gotham
    statusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusMsg.TextSize = 12
    statusMsg.Parent = mainFrame
    
    -- Button Functions
    submitBtn.MouseButton1Click:Connect(function()
        if keyBox.Text == FREE_KEY then
            statusMsg.Text = "✅ Key accepted! Starting trial..."
            statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            wait(1)
            keyGui:Destroy()
            startMainScript()
        else
            statusMsg.Text = "❌ Invalid key! Please check again"
            statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        statusMsg.Text = "📱 Join Discord: YourDiscordLinkHere"
        statusMsg.TextColor3 = Color3.fromRGB(100, 200, 255)
    end)
end

-- ===================================
-- ========== MAIN SCRIPT ============
-- ===================================
local function startMainScript()
    -- Cek trial status
    local isValid, message = checkTrial()
    
    if not isValid then
        local notification = Instance.new("ScreenGui")
        notification.Parent = playerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 200)
        frame.Position = UDim2.new(0.5, -200, 0.5, -100)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.Parent = notification
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 50)
        title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        title.Text = "⏰ TRIAL EXPIRED"
        title.Font = Enum.Font.GothamBold
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 20
        title.Parent = frame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, -40, 0, 80)
        messageLabel.Position = UDim2.new(0, 20, 0, 60)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message .. "\n\nPlease rejoin the game."
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        messageLabel.TextSize = 16
        messageLabel.TextWrapped = true
        messageLabel.Parent = frame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 120, 0, 40)
        closeBtn.Position = UDim2.new(0.5, -60, 1, -50)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeBtn.Text = "CLOSE GAME"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 14
        closeBtn.Parent = frame
        
        closeBtn.MouseButton1Click:Connect(function()
            game:Shutdown()
        end)
        
        return
    end

    -- ===================================
    -- ========== VARIABLES ==============
    -- ===================================

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

    -- ===================================
    -- ========== HELPER FUNCTIONS =======
    -- ===================================

    -- Fungsi untuk membuat instance dengan properties
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

    -- Fungsi untuk menambahkan efek hover pada button
    local function addHover(btn, normal, hover)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normal}):Play()
        end)
    end

    -- ===================================
    -- ========== REMOTE SETUP ===========
    -- ===================================

    -- Setup remote events/functions untuk komunikasi dengan server
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
    -- ========== GUI CREATION ===========
    -- ===================================

    -- Hapus GUI lama jika ada
    if playerGui:FindFirstChild("FishItAutoGUI") then
        playerGui:FindFirstChild("FishItAutoGUI"):Destroy()
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

    -- Title Bar dengan close dan minimize button
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
        Size = UDim2.new(1, -66, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "🐟 Fish It - FREE TRIAL",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Timer Label
    local timerLabel = create("TextLabel", {
        Parent = titleBar,
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(1, -55, 0, 0),
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
        Position = UDim2.new(1, -29, 0, 4),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})

    local minimizeBtn = create("TextButton", {
        Parent = titleBar,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -58, 0, 4),
        BackgroundColor3 = Color3.fromRGB(70, 80, 100),
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = minimizeBtn, CornerRadius = UDim.new(0, 6)})

    -- Content Frame untuk menampung semua section
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

    -- ===================================
    -- ========== STATUS SECTION =========
    -- ===================================

    -- Status box untuk menampilkan informasi status script
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
        Text = "🔴 Status: Idle\n⏰ FREE TRIAL - 5 minutes\n⚡ Limited to basic features",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Fungsi untuk update status dengan format yang dipertahankan
    local function updateStatus(newStatus, color)
        local baseText = "⏰ FREE TRIAL - 5 minutes\n⚡ Limited to basic features"
        statusLabel.Text = newStatus .. "\n" .. baseText
        statusLabel.TextColor3 = color or Color3.fromRGB(255, 100, 100)
    end

    -- Inisialisasi status awal
    updateStatus("🔴 Status: Idle")

    -- ===================================
    -- ========== ANTI-AFK SECTION =======
    -- ===================================

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

    -- ===================================
    -- ========== FISHING V1 SECTION =====
    -- ===================================

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
        Text = "🎣 Auto Instant Fishing V1",
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

    -- ===================================
    -- ========== AUTO SELL SECTION ======
    -- ===================================

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

    -- ===================================
    -- ========== TELEPORT SECTION =======
    -- ===================================

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

    -- ===================================
    -- ========== DRAG FUNCTIONALITY =====
    -- ===================================

    -- Fungsi untuk drag window
    local dragging, dragInput, dragStart, startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        TweenService:Create(mainFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updateDrag(input)
        end
    end)

    -- ===================================
    -- ========== HOVER EFFECTS ==========
    -- ===================================

    -- Tambahkan efek hover pada semua button
    addHover(closeBtn, Color3.fromRGB(220, 50, 50), Color3.fromRGB(240, 80, 80)) 
    addHover(minimizeBtn, Color3.fromRGB(70, 80, 100), Color3.fromRGB(90, 100, 120))
    addHover(antiAFKBtn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
    addHover(fishBtn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
    addHover(sellBtn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
    addHover(teleportBtn, Color3.fromRGB(150, 100, 50), Color3.fromRGB(170, 120, 70))

    -- ===================================
    -- ========== ANTI-AFK SYSTEM ========
    -- ===================================

    -- Fungsi untuk toggle Anti-AFK system
    local function toggleAntiAFK()
        antiAFKEnabled = not antiAFKEnabled
        
        if antiAFKEnabled then
            -- Enable Anti-AFK
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
            
            antiAFKBtn.Text = "STOP"
            antiAFKBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100, 255, 100))
            
        else
            -- Disable Anti-AFK
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end
            
            antiAFKBtn.Text = "START"
            antiAFKBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            updateStatus("🔴 Status: Idle")
        end
    end

    -- ===================================
    -- ========== FISHING V1 SYSTEM ======
    -- ===================================

    -- Fungsi utama Auto Fishing V1
    local function autoFishingLoop()
        while autoFishingEnabled do
            local ok, err = pcall(function()
                fishingActive = true
                updateStatus("🎣 Status: Fishing", Color3.fromRGB(100, 255, 100))
                equipRemote:FireServer(1)
                task.wait(0.1)

                local timestamp = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(timestamp)

                local baseX, baseY = -0.7499996, 1
                local x = baseX + (math.random(-500, 500) / 10000000)
                local y = baseY + (math.random(-500, 500) / 10000000)

                miniGameRemote:InvokeServer(x, y)
                task.wait(2)
                finishRemote:FireServer(true)
                task.wait(2)
            end)
            if not ok then
                -- Handle error silently
            end
            task.wait(0.2)
        end
        fishingActive = false
        updateStatus("🔴 Status: Idle")
    end

    -- ===================================
    -- ========== AUTO SELL SYSTEM =======
    -- ===================================

    -- Fungsi untuk auto sell loop
    local function autoSellLoop()
        while autoSellEnabled do
            task.wait(1)
            
            local success, err = pcall(function()
                updateStatus("💰 Status: Selling", Color3.fromRGB(255, 215, 0))
                
                local sellSuccess = pcall(function()
                    sellRemote:InvokeServer()
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

    -- Fungsi untuk membuat GUI teleport islands
    local function createTeleportGUI()
        local teleportGui = create("ScreenGui", {
            Name = "TeleportGUI",
            Parent = playerGui,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })

        local teleportFrame = create("Frame", {
            Name = "TeleportFrame",
            Parent = teleportGui,
            Size = UDim2.new(0, 280, 0, 300),
            Position = UDim2.new(0.5, -140, 0.5, -150),
            BackgroundColor3 = Color3.fromRGB(15, 20, 30),
            BorderSizePixel = 0
        })

        create("UICorner", {Parent = teleportFrame, CornerRadius = UDim.new(0, 10)})
        create("UIStroke", {Parent = teleportFrame, Color = Color3.fromRGB(100, 150, 255), Thickness = 1.5})

        local teleportTitle = create("TextLabel", {
            Parent = teleportFrame,
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(25, 35, 55),
            Text = "📍 Island Teleport - FREE",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(100, 180, 255),
            TextYAlignment = Enum.TextYAlignment.Center
        })

        create("UICorner", {Parent = teleportTitle, CornerRadius = UDim.new(0, 10)})

        local closeTeleportBtn = create("TextButton", {
            Parent = teleportTitle,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -26, 0, 6),
            BackgroundColor3 = Color3.fromRGB(220, 50, 50),
            Text = "X",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })

        create("UICorner", {Parent = closeTeleportBtn, CornerRadius = UDim.new(0, 6)})

        local scrollFrame = create("ScrollingFrame", {
            Parent = teleportFrame,
            Size = UDim2.new(1, -20, 1, -50),
            Position = UDim2.new(0, 10, 0, 45),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255),
            CanvasSize = UDim2.new(0, 0, 0, #game:GetService("HttpService"):JSONEncode(islandCoords) * 35)
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
                TextYAlignment = Enum.TextYAlignment.Center
            })

            create("UICorner", {Parent = islandBtn, CornerRadius = UDim.new(0, 6)})
            create("UIStroke", {Parent = islandBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

            addHover(islandBtn, Color3.fromRGB(35, 45, 65), Color3.fromRGB(45, 55, 75))

            islandBtn.MouseButton1Click:Connect(function()
                local charFolder = workspace:WaitForChild("Characters", 5)
                local char = charFolder:FindFirstChild(player.Name)
                if not char then 
                    updateStatus("❌ Character not found")
                    return 
                end
                
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then 
                    updateStatus("❌ HRP not found")
                    return 
                end

                local success, err = pcall(function()
                    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
                end)

                if success then
                    updateStatus("✅ Success Teleport to " .. islandName, Color3.fromRGB(100, 255, 100))
                    teleportGui:Destroy()
                else
                    updateStatus("❌ Teleport failed")
                end
            end)

            yPosition = yPosition + 35
        end

        closeTeleportBtn.MouseButton1Click:Connect(function()
            teleportGui:Destroy()
        end)
    end

    -- ===================================
    -- ========== EXCLAIM DETECTION ======
    -- ===================================

    -- Listener untuk detect exclaim (tanda seru) dan auto recast
    task.spawn(function()
        local success, exclaimEvent = pcall(function()
            return net:WaitForChild("RE/ReplicateTextEffect", 2)
        end)

        if success and exclaimEvent then
            exclaimEvent.OnClientEvent:Connect(function(data)
                if autoFishingEnabled and data and data.TextData
                    and data.TextData.EffectType == "Exclaim" then

                    local head = player.Character and player.Character:FindFirstChild("Head")
                    if head and data.Container == head then
                        task.spawn(function()
                            for i = 1, 3 do
                                task.wait(1)
                                finishRemote:FireServer()
                            end
                        end)
                    end
                end
            end)
        end
    end)

    -- ===================================
    -- ========== BUTTON CONNECTIONS =====
    -- ===================================

    -- Setup remotes terlebih dahulu
    setupRemotes()

    -- Anti-AFK Button
    antiAFKBtn.MouseButton1Click:Connect(toggleAntiAFK)

    -- Fishing V1 Button
    fishBtn.MouseButton1Click:Connect(function()
        autoFishingEnabled = not autoFishingEnabled
        
        if autoFishingEnabled then
            fishBtn.Text = "STOP"
            fishBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            updateStatus("🟢 Status: Auto Fishing Started", Color3.fromRGB(100, 255, 100))
            task.spawn(autoFishingLoop)
        else
            fishBtn.Text = "START"
            fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            updateStatus("🔴 Status: Auto Fishing Stopped")
            fishingActive = false
            finishRemote:FireServer()
        end
    end)

    -- Auto Sell Button
    sellBtn.MouseButton1Click:Connect(function()
        autoSellEnabled = not autoSellEnabled
        
        if autoSellEnabled then
            sellBtn.Text = "STOP"
            sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            updateStatus("🟢 Status: Auto Sell Started", Color3.fromRGB(100, 255, 100))
            task.spawn(autoSellLoop)
        else
            sellBtn.Text = "START"
            sellBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            updateStatus("🔴 Status: Auto Sell Stopped")
        end
    end)

    -- Teleport Button
    teleportBtn.MouseButton1Click:Connect(createTeleportGUI)

    -- Close dan Minimize Buttons
    closeBtn.MouseButton1Click:Connect(function()
        autoFishingEnabled = false
        autoSellEnabled = false
        fishingActive = false
        if antiAFKEnabled then
            toggleAntiAFK()
        end
        screenGui:Destroy()
    end)

    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = minimized and UDim2.new(0, 300, 0, 33) or UDim2.new(0, 300, 0, 420)
        }):Play()
        minimizeBtn.Text = minimized and "+" or "—"
    end)

    -- ===================================
    -- ========== TIMER COUNTDOWN ========
    -- ===================================
    local startTime = player:GetAttribute("FishItTrialStart")
    spawn(function()
        while true do
            local currentTime = os.time()
            local elapsed = currentTime - startTime
            local remaining = trialDuration - elapsed
            
            if remaining <= 0 then
                timerLabel.Text = "00:00"
                updateStatus("⏰ TRIAL EXPIRED - Please rejoin", Color3.fromRGB(255, 50, 50))
                
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

    -- ===================================
    -- ========== SCRIPT LOADED ==========
    -- ===================================

    updateStatus("✅ FREE TRIAL Started", Color3.fromRGB(100, 255, 100))
    warn("🎣 Fish It FREE Loaded! Trial time: 5 minutes")
end

-- ===================================
-- ========== START SCRIPT ===========
-- ===================================
createKeyInputGUI()

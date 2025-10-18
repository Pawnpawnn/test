-- ===================================
-- ========== KEY SYSTEM ==============
-- ===================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local API_URL = "https://keygen-fsh.vercel.app/api" -- Hilangkan trailing slash
local trialDuration = 6 * 60 * 60

-- Validate key dengan API (dengan error handling yang lebih baik)
local function validateKeyWithAPI(key)
    local success, result = pcall(function()
        local headers = {
            ["Content-Type"] = "application/json"
        }
        
        local body = HttpService:JSONEncode({
            key = key
        })
        
        local response = HttpService:RequestAsync({
            Url = API_URL .. "/validate-key",
            Method = "POST",
            Headers = headers,
            Body = body
        })
        
        if response.Success and response.StatusCode == 200 then
            return HttpService:JSONDecode(response.Body)
        else
            return {
                valid = false,
                message = "Server error: " .. tostring(response.StatusCode)
            }
        end
    end)
    
    if success then
        if result.valid then
            return true, result.message or "Key validated successfully"
        else
            return false, result.message or "Invalid key"
        end
    else
        -- Detailed error logging
        warn("API Error:", result)
        return false, "Network error - check console"
    end
end

-- Cek status trial
local function checkTrial()
    local savedTime = player:GetAttribute("FishItTrialStart")
    if savedTime then
        local elapsed = os.time() - savedTime
        if elapsed >= trialDuration then
            return false, "Trial expired"
        end
        return true, "Trial active"
    end
    return false, "Need activation"
end

-- Tampilkan input key
local function createKeyGUI()
    -- Hapus GUI lama jika ada
    if playerGui:FindFirstChild("KeyInputGUI") then
        playerGui:FindFirstChild("KeyInputGUI"):Destroy()
    end

    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "KeyInputGUI"
    keyGui.Parent = playerGui
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Tambahkan ini

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

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8, 0, 0, 40)
    keyBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
    keyBox.PlaceholderText = "Enter key from website..."
    keyBox.Text = ""
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.TextSize = 14
    keyBox.Parent = mainFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = keyBox

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.6, 0, 0, 40)
    submitBtn.Position = UDim2.new(0.2, 0, 0.55, 0)
    submitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    submitBtn.Text = "ACTIVATE TRIAL"
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 14
    submitBtn.Parent = mainFrame

    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 8)
    submitCorner.Parent = submitBtn

    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.6, 0, 0, 35)
    getKeyBtn.Position = UDim2.new(0.2, 0, 0.75, 0)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
    getKeyBtn.Text = "🌐 GET KEY FROM WEBSITE"
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyBtn.TextSize = 12
    getKeyBtn.Parent = mainFrame

    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 8)
    getKeyCorner.Parent = getKeyBtn

    local statusMsg = Instance.new("TextLabel")
    statusMsg.Size = UDim2.new(0.8, 0, 0, 30)
    statusMsg.Position = UDim2.new(0.1, 0, 0.15, 0)
    statusMsg.BackgroundTransparency = 1
    statusMsg.Text = "Get key from website and paste here"
    statusMsg.Font = Enum.Font.Gotham
    statusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusMsg.TextSize = 12
    statusMsg.TextWrapped = true
    statusMsg.Parent = mainFrame

    -- Button events dengan debounce
    local isProcessing = false

    submitBtn.MouseButton1Click:Connect(function()
        if isProcessing then return end
        isProcessing = true
        
        local key = keyBox.Text:gsub("%s+", "") -- Hapus whitespace
        
        if string.len(key) < 10 then
            statusMsg.Text = "❌ Invalid key format (min 10 chars)"
            statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
            isProcessing = false
            return
        end
        
        submitBtn.Text = "VALIDATING..."
        submitBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusMsg.Text = "⏳ Validating key with server..."
        statusMsg.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        task.wait(0.5) -- Small delay untuk UX
        
        local isValid, message = validateKeyWithAPI(key)
        
        if isValid then
            player:SetAttribute("FishItTrialStart", os.time())
            statusMsg.Text = "✅ " .. message
            statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
            submitBtn.Text = "SUCCESS!"
            task.wait(1)
            loadMainScript()
        else
            statusMsg.Text = "❌ " .. message
            statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
            submitBtn.Text = "ACTIVATE TRIAL"
            submitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            isProcessing = false
        end
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        statusMsg.Text = "🌐 Open: keygen-fsh.vercel.app"
        statusMsg.TextColor3 = Color3.fromRGB(100, 200, 255)
        
        -- Copy URL to clipboard (optional)
        pcall(function()
            setclipboard("https://keygen-fsh.vercel.app/")
        end)
    end)

    return keyGui
end

-- Fungsi untuk load script utama
local function loadMainScript()
    -- Hancurkan GUI key input
    if playerGui:FindFirstChild("KeyInputGUI") then
        playerGui:FindFirstChild("KeyInputGUI"):Destroy()
    end

    -- [[ TEMPATKAN SCRIPT UTAMA ANDA DI SINI ]]
    -- Copy seluruh script utama Anda mulai dari baris ini:
    
    warn("✅ Key validated! Loading main script...")
    
    -- ===================================
    -- ========== SCRIPT UTAMA ===========
    -- ===================================
    
    -- Tempatkan seluruh kode script utama Anda di sini...
    -- Mulai dari: local Players = game:GetService("Players")
    -- Hingga akhir script
    local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

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
    Name = "FishItAutoGUI",
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
create("UIStroke", {Parent = mainFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

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
    Text = "🐟 Fish It - Codepikk (free)",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(100, 180, 255),
    TextXAlignment = Enum.TextXAlignment.Left
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
    ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
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
    Text = "🔴 Status: Idle\nScript: V.2.2\nUpdate: +Buff Speed Fishing, +Add Anti AFK\nNote: found bug on script? Pm me on discord!",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Fungsi untuk update status dengan format yang dipertahankan
local function updateStatus(newStatus, color)
    local baseText = "Script: V.2.2\nUpdate: +Buff Speed Fishing, +Add Anti AFK\nNote: found bug on script? Pm me on discord!"
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
    Text = "🎣 Auto Instant Fishing V1 (perfect)",
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
    Text = "💰 Auto Sell All (non favorite fish)",
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
-- ========== TELEPORT SECTIONS ======
-- ===================================

-- Teleport to Islands Section
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
    Text = "🚀 Teleport to Islands",
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

-- Teleport to NPC Section
local teleportNPCSection = create("Frame", {
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 250),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = teleportNPCSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = teleportNPCSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local teleportNPCTitle = create("TextLabel", {
    Parent = teleportNPCSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🧍 Teleport to NPC",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local teleportNPCBtn = create("TextButton", {
    Parent = teleportNPCSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(100, 80, 180),
    Text = "OPEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = teleportNPCBtn, CornerRadius = UDim.new(0, 6)})

-- Teleport to Event Section
local teleportEventSection = create("Frame", {
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 298),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = teleportEventSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = teleportEventSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local teleportEventTitle = create("TextLabel", {
    Parent = teleportEventSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🎯 Teleport to Events",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local teleportEventBtn = create("TextButton", {
    Parent = teleportEventSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 80, 120),
    Text = "OPEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = teleportEventBtn, CornerRadius = UDim.new(0, 6)})

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
addHover(teleportNPCBtn, Color3.fromRGB(100, 80, 180), Color3.fromRGB(120, 100, 200))
addHover(teleportEventBtn, Color3.fromRGB(180, 80, 120), Color3.fromRGB(200, 100, 140))

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
-- ========== FISHING V2 SYSTEM ======
-- ========== TAMBAH FITUR BARU DIBAWAH INI ==========
-- ===================================

-- [[ TAMBAHKAN FISHING V2 LOGIC DI SINI ]]
-- Buat fungsi autoFishingV2Loop() dan variabel autoFishingV2Enabled

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
    create("UIStroke", {Parent = teleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local teleportTitle = create("TextLabel", {
        Parent = teleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🚀 Island Teleport",
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
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
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

-- Fungsi untuk membuat GUI teleport NPC
local function createNPCTeleportGUI()
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    if not npcFolder then
        updateStatus("❌ NPC folder not found")
        return
    end

    local npcList = {}
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end

    if #npcList == 0 then
        updateStatus("❌ No NPCs found")
        return
    end

    local npcTeleportGui = create("ScreenGui", {
        Name = "NPCTeleportGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local npcTeleportFrame = create("Frame", {
        Name = "NPCTeleportFrame",
        Parent = npcTeleportGui,
        Size = UDim2.new(0, 280, 0, 350),
        Position = UDim2.new(0.5, -140, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = npcTeleportFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = npcTeleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local npcTeleportTitle = create("TextLabel", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🧍 NPC Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextYAlignment = Enum.TextYAlignment.Center
    })

    create("UICorner", {Parent = npcTeleportTitle, CornerRadius = UDim.new(0, 10)})

    local closeNPCTeleportBtn = create("TextButton", {
        Parent = npcTeleportTitle,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeNPCTeleportBtn, CornerRadius = UDim.new(0, 6)})

    local searchBox = create("TextBox", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = Color3.fromRGB(25, 35, 50),
        PlaceholderText = "🔍 Search NPC...",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    create("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0, 6)})
    create("UIStroke", {Parent = searchBox, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

    create("UIPadding", {
        Parent = searchBox,
        PaddingLeft = UDim.new(0, 8)
    })

    local scrollFrame = create("ScrollingFrame", {
        Parent = npcTeleportFrame,
        Size = UDim2.new(1, -20, 1, -95),
        Position = UDim2.new(0, 10, 0, 85),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
        CanvasSize = UDim2.new(0, 0, 0, #npcList * 35)
    })

    local function createNPCButtons(filterText)
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local yPosition = 0
        local filteredCount = 0

        for _, npcName in ipairs(npcList) do
            if string.lower(npcName):find(string.lower(filterText or "")) then
                local npcBtn = create("TextButton", {
                    Parent = scrollFrame,
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0, 0, 0, yPosition),
                    BackgroundColor3 = Color3.fromRGB(35, 45, 65),
                    Text = "🧍 " .. npcName,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Color3.fromRGB(220, 220, 220),
                    TextYAlignment = Enum.TextYAlignment.Center
                })

                create("UICorner", {Parent = npcBtn, CornerRadius = UDim.new(0, 6)})
                create("UIStroke", {Parent = npcBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

                addHover(npcBtn, Color3.fromRGB(35, 45, 65), Color3.fromRGB(45, 55, 75))

                npcBtn.MouseButton1Click:Connect(function()
                    local npc = npcFolder:FindFirstChild(npcName)
                    if npc and npc:IsA("Model") then
                        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                        if hrp then
                            local charFolder = workspace:FindFirstChild("Characters")
                            local char = charFolder and charFolder:FindFirstChild(player.Name)
                            if not char then 
                                updateStatus("❌ Character not found")
                                return 
                            end
                            
                            local myHRP = char:FindFirstChild("HumanoidRootPart")
                            if myHRP then
                                local success, err = pcall(function()
                                    myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                                end)

                                if success then
                                    updateStatus("✅ Teleported to: " .. npcName, Color3.fromRGB(100, 255, 100))
                                    npcTeleportGui:Destroy()
                                else
                                    updateStatus("❌ Teleport failed: " .. tostring(err))
                                end
                            else
                                updateStatus("❌ HRP not found")
                            end
                        else
                            updateStatus("❌ NPC HRP not found")
                        end
                    else
                        updateStatus("❌ NPC not found")
                    end
                end)

                yPosition = yPosition + 35
                filteredCount = filteredCount + 1
            end
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, filteredCount * 35)
    end

    createNPCButtons("")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        createNPCButtons(searchBox.Text)
    end)

    closeNPCTeleportBtn.MouseButton1Click:Connect(function()
        npcTeleportGui:Destroy()
    end)
end

-- Fungsi untuk membuat GUI teleport events
local function createEventTeleportGUI()
    local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

    local eventTeleportGui = create("ScreenGui", {
        Name = "EventTeleportGUI",
        Parent = playerGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local eventTeleportFrame = create("Frame", {
        Name = "EventTeleportFrame",
        Parent = eventTeleportGui,
        Size = UDim2.new(0, 300, 0, 350),
        Position = UDim2.new(0.5, -150, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(15, 20, 30),
        BorderSizePixel = 0
    })

    create("UICorner", {Parent = eventTeleportFrame, CornerRadius = UDim.new(0, 10)})
    create("UIStroke", {Parent = eventTeleportFrame, Color = Color3.fromRGB(40, 80, 150), Thickness = 1.5})

    local eventTeleportTitle = create("TextLabel", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(25, 35, 55),
        Text = "🎯 Event Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(100, 180, 255),
        TextYAlignment = Enum.TextYAlignment.Center
    })

    create("UICorner", {Parent = eventTeleportTitle, CornerRadius = UDim.new(0, 10)})

    local closeEventTeleportBtn = create("TextButton", {
        Parent = eventTeleportTitle,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220, 50, 50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    create("UICorner", {Parent = closeEventTeleportBtn, CornerRadius = UDim.new(0, 6)})

    local infoLabel = create("TextLabel", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        Text = "Teleport to active events\n⚡ Hanya work ketika event ACTIVE",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(100, 255, 200),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })

    local scrollFrame = create("ScrollingFrame", {
        Parent = eventTeleportFrame,
        Size = UDim2.new(1, -20, 1, -110),
        Position = UDim2.new(0, 10, 0, 105),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
        CanvasSize = UDim2.new(0, 0, 0, #eventsList * 40)
    })

    local yPosition = 0
    for _, eventName in ipairs(eventsList) do
        local eventBtn = create("TextButton", {
            Parent = scrollFrame,
            Size = UDim2.new(1, 0, 0, 35),
            Position = UDim2.new(0, 0, 0, yPosition),
            BackgroundColor3 = Color3.fromRGB(35, 45, 65),
            Text = "⚡ " .. eventName,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            TextYAlignment = Enum.TextYAlignment.Center
        })

        create("UICorner", {Parent = eventBtn, CornerRadius = UDim.new(0, 6)})
        create("UIStroke", {Parent = eventBtn, Color = Color3.fromRGB(60, 100, 160), Thickness = 1})

        addHover(eventBtn, Color3.fromRGB(35, 45, 65), Color3.fromRGB(45, 55, 75))

        eventBtn.MouseButton1Click:Connect(function()
            updateStatus("🔍 Mencari: " .. eventName, Color3.fromRGB(255, 200, 100))
            
            task.wait(0.3)
            
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

            local eventObject = findEventLocation(eventName)
            
            if eventObject then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local success, err = pcall(function()
                        local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                        if fishingBoat then
                            hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                            updateStatus("✅ Teleport ke Fishing Boat " .. eventName, Color3.fromRGB(100, 255, 100))
                        else
                            hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                            updateStatus("✅ Teleport ke " .. eventName, Color3.fromRGB(100, 255, 100))
                        end
                        eventTeleportGui:Destroy()
                    end)

                    if not success then
                        updateStatus("❌ Gagal teleport: " .. tostring(err))
                    end
                else
                    updateStatus("❌ HRP tidak ditemukan")
                end
            else
                updateStatus("❌ " .. eventName .. " tidak ditemukan\nPastikan event sedang ACTIVE", Color3.fromRGB(255, 100, 100))
            end
        end)

        yPosition = yPosition + 40
    end

    closeEventTeleportBtn.MouseButton1Click:Connect(function()
        eventTeleportGui:Destroy()
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

-- Teleport Buttons
teleportBtn.MouseButton1Click:Connect(createTeleportGUI)
teleportNPCBtn.MouseButton1Click:Connect(createNPCTeleportGUI)
teleportEventBtn.MouseButton1Click:Connect(createEventTeleportGUI)

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
-- ========== SCRIPT LOADED ==========
-- ===================================

-- Script selesai di-load
    
end

-- Main execution
task.spawn(function()
    -- Tunggu hingga player siap
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    task.wait(2) -- Tunggu sedikit lebih lama
    
    -- Cek HttpService
    if not checkHttpService() then
        warn("❌ HttpService not enabled! Please enable in game settings.")
        return
    end
    
    -- Check trial status
    local hasActiveTrial, message = checkTrial()
    if hasActiveTrial then
        warn("⏰ " .. message)
        loadMainScript()
    else
        warn("🔑 Key System Loaded - Creating GUI...")
        createKeyGUI()
    end
end)

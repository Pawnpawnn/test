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
local autoFishingV2Enabled = false
local autoFishingV3Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false

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
-- ========== AUTO BOOST FPS =========
-- ===================================

local function BoostFPS()
    updateStatus("🚀 Boosting FPS...", Color3.fromRGB(255, 200, 100))
    
    -- Optimize parts and materials
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    -- Optimize lighting
    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10

    -- Set graphics quality to lowest
    settings().Rendering.QualityLevel = "Level01"
    
    updateStatus("✅ FPS Boosted Successfully", Color3.fromRGB(100, 255, 100))
end

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
                updateStatus("⭐ Scanning items...", Color3.fromRGB(255, 215, 0))
                
                local totalFavorited = 0
                local totalChecked = 0
                
                -- METHOD 1: Coba Replion System
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
                    
                -- METHOD 2: Coba Remote Events
                else
                    local favoriteRemote = ReplicatedStorage:FindFirstChild("FavoriteItem") or
                                         ReplicatedStorage:FindFirstChild("ToggleFavorite")
                    
                    if favoriteRemote then
                        updateStatus("⭐ Using remote system...", Color3.fromRGB(100, 255, 100))
                        
                        -- Coba favorite items 1-50
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
                
                -- SHOW FINAL RESULT
                if totalFavorited > 0 then
                    updateStatus("✅ Done! Fav: " .. totalFavorited .. " items", Color3.fromRGB(100, 255, 100))
                else
                    updateStatus("ℹ️ No items to favorite", Color3.fromRGB(255, 255, 100))
                end
                
            end)
            
            -- Wait before next scan
            for i = 1, 20 do
                if not autoFavoriteEnabled then break end
                task.wait(0.5)
            end
        end
        updateStatus("🔴 Auto Favorite: Stopped")
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
    Size = UDim2.new(0, 320, 0, 420), -- Diperbesar untuk V3
    Position = UDim2.new(0.5, -160, 0.5, -210),
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
    Text = "🐟 Fish It - Codepikk Premium V3",
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

-- Tab Container
local tabContainer = create("Frame", {
    Name = "TabContainer",
    Parent = mainFrame,
    Size = UDim2.new(1, -20, 0, 35),
    Position = UDim2.new(0, 10, 0, 38),
    BackgroundTransparency = 1,
    BorderSizePixel = 0
})

-- Tab Buttons
local tabs = {"Main", "Teleports", "Misc"}
local tabButtons = {}
local activeTab = "Main"

for i, tabName in ipairs(tabs) do
    local tabBtn = create("TextButton", {
        Name = tabName .. "Tab",
        Parent = tabContainer,
        Size = UDim2.new(1/#tabs, -4, 1, 0),
        Position = UDim2.new((i-1)/#tabs, 2, 0, 0),
        BackgroundColor3 = tabName == "Main" and Color3.fromRGB(40, 60, 100) or Color3.fromRGB(30, 40, 60),
        Text = tabName,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(220, 220, 220)
    })
    
    create("UICorner", {Parent = tabBtn, CornerRadius = UDim.new(0, 6)})
    tabButtons[tabName] = tabBtn
    
    addHover(tabBtn, 
        tabName == "Main" and Color3.fromRGB(40, 60, 100) or Color3.fromRGB(30, 40, 60),
        Color3.fromRGB(50, 70, 110)
    )
end

-- Content Frame untuk menampung semua section
local contentFrame = create("Frame", {
    Name = "Content",
    Parent = mainFrame,
    Size = UDim2.new(1, -18, 1, -85),
    Position = UDim2.new(0, 9, 0, 80),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

-- ===================================
-- ========== TAB CONTENT ============
-- ===================================

-- Content untuk setiap tab
local tabContents = {}

-- Main Tab Content
local mainTab = create("ScrollingFrame", {
    Name = "MainTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
    CanvasSize = UDim2.new(0, 0, 0, 300), -- Diperbesar untuk V3
    Visible = true
})

-- Status box untuk menampilkan informasi status script
local statusBox = create("Frame", {
    Parent = mainTab,
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
    Text = "🔴 Status: Idle\nScript: V.3.0\nNote: Donate me if you happy using this script  :)",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Fungsi untuk update status dengan format yang dipertahankan
local function updateStatus(newStatus, color)
    local baseText = "Script: V.3.0\nNote: Donate me if you happy using this script :)"
    statusLabel.Text = newStatus .. "\n" .. baseText
    statusLabel.TextColor3 = color or Color3.fromRGB(255, 100, 100)
end

-- Inisialisasi status awal
updateStatus("🔴 Status: Idle")

-- FISHING V1 SECTION
local fishSection = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = fishSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = fishSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local fishTitle = create("TextLabel", {
    Parent = fishSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🎣 Auto Instant Fishing V1 (perfect + delay)",
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

-- FISHING V2 SECTION
local fishV2Section = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 106),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = fishV2Section, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = fishV2Section, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local fishV2Title = create("TextLabel", {
    Parent = fishV2Section,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚡ Auto Fishing V2 (FAST)",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(100, 255, 100),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local fishV2Btn = create("TextButton", {
    Parent = fishV2Section,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
    Text = "START",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = fishV2Btn, CornerRadius = UDim.new(0, 6)})

-- FISHING V3 SECTION (BARU)
local fishV3Section = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 154),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = fishV3Section, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = fishV3Section, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local fishV3Title = create("TextLabel", {
    Parent = fishV3Section,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🚀 Auto Fishing V3 (TIMING EXPLOIT)",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local fishV3Btn = create("TextButton", {
    Parent = fishV3Section,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 60, 60),
    Text = "START",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = fishV3Btn, CornerRadius = UDim.new(0, 6)})

-- AUTO SELL SECTION
local sellSection = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 202),
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

-- AUTO FAVORITE SECTION
local favoriteSection = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 250),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = favoriteSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = favoriteSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local favoriteTitle = create("TextLabel", {
    Parent = favoriteSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local favoriteBtn = create("TextButton", {
    Parent = favoriteSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 80, 180),
    Text = "START",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = favoriteBtn, CornerRadius = UDim.new(0, 6)})

-- Teleports Tab Content dengan Dropdown (disingkat untuk hemat space)
local teleportsTab = create("ScrollingFrame", {
    Name = "TeleportsTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
    CanvasSize = UDim2.new(0, 0, 0, 200),
    Visible = false
})

-- ... (Teleport sections tetap sama seperti sebelumnya) ...

-- Misc Tab Content (disingkat untuk hemat space)
local miscTab = create("ScrollingFrame", {
    Name = "MiscTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = Color3.fromRGB(50, 100, 180),
    CanvasSize = UDim2.new(0, 0, 0, 200),
    Visible = false
})

-- ... (Misc sections tetap sama seperti sebelumnya) ...

-- ===================================
-- ========== TAB FUNCTIONALITY ======
-- ===================================

local function switchTab(tabName)
    activeTab = tabName
    
    -- Sembunyikan semua tab
    mainTab.Visible = false
    teleportsTab.Visible = false
    miscTab.Visible = false
    
    -- Tampilkan tab aktif
    if tabName == "Main" then
        mainTab.Visible = true
    elseif tabName == "Teleports" then
        teleportsTab.Visible = true
    elseif tabName == "Misc" then
        miscTab.Visible = true
    end
    
    -- Update tampilan tab buttons
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
        end
    end
end

-- Connect tab buttons
for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
end

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
addHover(fishV2Btn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
addHover(fishV3Btn, Color3.fromRGB(180, 60, 60), Color3.fromRGB(200, 80, 80)) -- V3 special color
addHover(sellBtn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
addHover(favoriteBtn, Color3.fromRGB(180, 80, 180), Color3.fromRGB(200, 100, 200))

-- ===================================
-- ========== FISHING V1 SYSTEM ======
-- ===================================

-- Fungsi utama Auto Fishing V1
local function autoFishingLoop()
    while autoFishingEnabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("🎣 Status: Fishing V1", Color3.fromRGB(100, 255, 100))
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
-- ===================================

-- Fungsi utama Auto Fishing V2 (ULTRA FAST)
local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            
            -- Equip rod super cepat
            equipRemote:FireServer(1)
            
            -- Cast langsung tanpa delay
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)

            -- Random coordinates yang lebih natural tapi tetap cepat
            local baseX, baseY = -0.7499996, 1
            -- Random kecil tapi cukup untuk avoid detection
            local x = baseX + (math.random(-300, 300) / 10000000)
            local y = baseY + (math.random(-300, 300) / 10000000)

            -- Mini game instant
            miniGameRemote:InvokeServer(x, y)
            
            -- Finish dalam 0.5 detik (super cepat tapi masih natural)
            task.wait(0.5)
            finishRemote:FireServer(true)
            
            -- Auto recast cepat
            task.wait(0.3)
            finishRemote:FireServer()
        end)
        
        if not ok then
            -- Error handling silent
        end
        
        -- Delay antara fishing cycle yang random (antara 0.1-0.3 detik)
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- ===================================
-- ========== FISHING V3 SYSTEM ======
-- ===================================

-- Fungsi utama Auto Fishing V3 (TIMING EXPLOIT)
local function autoFishingV3Loop()
    local cycleCount = 0
    local successPattern = {}
    
    while autoFishingV3Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            cycleCount += 1
            
            -- Adaptive timing berdasarkan success rate
            local optimalWait = 0.25  -- Default
            
            if #successPattern >= 5 then
                local recentSuccess = 0
                for i = math.max(1, #successPattern - 4), #successPattern do
                    if successPattern[i] then recentSuccess += 1 end
                end
                
                if recentSuccess >= 4 then  -- Jika 4/5 berhasil, percepat
                    optimalWait = 0.18
                    updateStatus("🚀 V3: SPEED BOOST!", Color3.fromRGB(100, 255, 100))
                elseif recentSuccess <= 2 then  -- Jika <= 2/5 berhasil, perlambat
                    optimalWait = 0.32
                    updateStatus("🚀 V3: Adjusting Timing...", Color3.fromRGB(255, 200, 100))
                end
            end
            
            updateStatus("🚀 Status: Fishing V3 TIMING EXPLOIT", Color3.fromRGB(255, 100, 100))
            
            -- PHASE 1: PREPARE - SUPER CEPAT
            equipRemote:FireServer(1)  -- Equip rod
            local timestamp = workspace:GetServerTimeNow()
            
            -- PHASE 2: CAST + MINIGAME SECARA BERSAMAAN
            rodRemote:InvokeServer(timestamp)
            
            -- Koordinat micro-random untuk avoid detection
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-30, 30) / 10000000)
            local y = baseY + (math.random(-30, 30) / 10000000)
            
            -- LANGSUNG mulai mini game (bypass wait time)
            miniGameRemote:InvokeServer(x, y)
            
            -- PHASE 3: OPTIMAL TIMING WINDOW
            task.wait(optimalWait)
            
            -- PHASE 4: FINISH DENGAN STRATEGI BERBEDA
            local willSucceed = math.random(1, 100) <= 75  -- 75% base success rate
            
            if willSucceed then
                finishRemote:FireServer(true)
                table.insert(successPattern, true)
                updateStatus("🎯 V3 Hit! (" .. string.format("%.3f", optimalWait) .. "s)", Color3.fromRGB(100, 255, 100))
            else
                finishRemote:FireServer(false)
                table.insert(successPattern, false)
                updateStatus("🎯 V3 Miss (" .. string.format("%.3f", optimalWait) .. "s)", Color3.fromRGB(255, 200, 100))
            end
            
            -- Maintain pattern history
            if #successPattern > 10 then
                table.remove(successPattern, 1)
            end
            
            -- PHASE 5: AUTO RECAST CEPAT
            task.wait(0.08)
            finishRemote:FireServer()
            
        end)
        
        if not ok then
            -- Silent error handling
        end
        
        -- Dynamic cooldown berdasarkan performance
        local cooldown = math.random(8, 20) / 100
        task.wait(cooldown)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
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
            if (autoFishingEnabled or autoFishingV2Enabled or autoFishingV3Enabled) and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    task.spawn(function()
                        if autoFishingV3Enabled then
                            -- V3: Immediate finish dengan timing exploit
                            task.wait(0.05)
                            finishRemote:FireServer(true)
                            updateStatus("⚡ V3 Exclaim Backup!", Color3.fromRGB(255, 255, 100))
                        elseif autoFishingV2Enabled then
                            task.wait(0.1)
                            finishRemote:FireServer()
                        else
                            -- V1: Original behavior
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
-- ========== BUTTON CONNECTIONS =====
-- ===================================

-- Setup remotes terlebih dahulu
setupRemotes()

-- Fishing V1 Button
fishBtn.MouseButton1Click:Connect(function()
    autoFishingEnabled = not autoFishingEnabled
    autoFishingV2Enabled = false -- Matikan V2 jika V1 aktif
    autoFishingV3Enabled = false -- Matikan V3 jika V1 aktif
    
    if autoFishingEnabled then
        fishBtn.Text = "STOP"
        fishBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fishV2Btn.Text = "START"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        fishV3Btn.Text = "START"
        fishV3Btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        updateStatus("🟢 Status: Auto Fishing V1 Started", Color3.fromRGB(100, 255, 100))
        task.spawn(autoFishingLoop)
    else
        fishBtn.Text = "START"
        fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🔴 Status: Auto Fishing Stopped")
        fishingActive = false
        finishRemote:FireServer()
    end
end)

-- Fishing V2 Button
fishV2Btn.MouseButton1Click:Connect(function()
    autoFishingV2Enabled = not autoFishingV2Enabled
    autoFishingEnabled = false -- Matikan V1 jika V2 aktif
    autoFishingV3Enabled = false -- Matikan V3 jika V2 aktif
    
    if autoFishingV2Enabled then
        fishV2Btn.Text = "STOP"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fishBtn.Text = "START"
        fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        fishV3Btn.Text = "START"
        fishV3Btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        updateStatus("⚡ Status: Auto Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
        task.spawn(autoFishingV2Loop)
    else
        fishV2Btn.Text = "START"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🔴 Status: Auto Fishing Stopped")
        fishingActive = false
        finishRemote:FireServer()
    end
end)

-- Fishing V3 Button (BARU)
fishV3Btn.MouseButton1Click:Connect(function()
    autoFishingV3Enabled = not autoFishingV3Enabled
    autoFishingEnabled = false -- Matikan V1 jika V3 aktif
    autoFishingV2Enabled = false -- Matikan V2 jika V3 aktif
    
    if autoFishingV3Enabled then
        fishV3Btn.Text = "STOP"
        fishV3Btn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        fishBtn.Text = "START"
        fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        fishV2Btn.Text = "START"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🚀 Status: Fishing V3 TIMING EXPLOIT", Color3.fromRGB(255, 100, 100))
        task.spawn(autoFishingV3Loop)
    else
        fishV3Btn.Text = "START"
        fishV3Btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
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

-- Auto Favorite Button
favoriteBtn.MouseButton1Click:Connect(function()
    autoFavoriteEnabled = not autoFavoriteEnabled
    
    if autoFavoriteEnabled then
        favoriteBtn.Text = "STOP"
        favoriteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        updateStatus("⭐ Auto Favorite: Started", Color3.fromRGB(255, 215, 0))
        startAutoFavorite()
    else
        favoriteBtn.Text = "START"
        favoriteBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 180)
        updateStatus("🔴 Auto Favorite: Disabled")
    end
end)

-- Boost FPS Button
boostFPSBtn.MouseButton1Click:Connect(function()
    BoostFPS()
end)

-- Teleport Dropdown Buttons
npcDropdownBtn.MouseButton1Click:Connect(createNPCTeleportGUI)
islandsDropdownBtn.MouseButton1Click:Connect(createTeleportGUI)
eventsDropdownBtn.MouseButton1Click:Connect(createEventTeleportGUI)

-- Close dan Minimize Buttons
closeBtn.MouseButton1Click:Connect(function()
    autoFishingEnabled = false
    autoFishingV2Enabled = false
    autoFishingV3Enabled = false
    autoSellEnabled = false
    fishingActive = false
    autoFavoriteEnabled = false

    if antiAFKEnabled then
        toggleAntiAFK()
    end
    screenGui:Destroy()
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- Minimize SEMUA: kecilkan jadi sangat kecil
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 80, 0, 25),
            Position = UDim2.new(1, -90, 1, -35)  -- Posisi di pojok kanan bawah
        }):Play()
        
        -- Sembunyikan semua elemen kecuali minimize button
        titleText.Visible = false
        closeBtn.Visible = false
        tabContainer.Visible = false
        contentFrame.Visible = false
        
        -- Pindahkan minimize button ke posisi yang sesuai
        minimizeBtn.Size = UDim2.new(0, 70, 0, 20)
        minimizeBtn.Position = UDim2.new(0, 5, 0, 2)
        minimizeBtn.Text = "+"
        
    else
        -- Maximize: kembalikan ke ukuran normal
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 320, 0, 420),
            Position = UDim2.new(0.5, -160, 0.5, -210)
        }):Play()
        
        -- Tampilkan kembali semua elemen
        titleText.Visible = true
        closeBtn.Visible = true
        tabContainer.Visible = true
        contentFrame.Visible = true
        
        -- Kembalikan minimize button ke posisi semula
        minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
        minimizeBtn.Position = UDim2.new(1, -58, 0, 4)
        minimizeBtn.Text = "—"
    end
end)

-- ... (Button connections lainnya tetap sama) ...

-- ===================================
-- ========== SCRIPT LOADED ==========
-- ===================================

-- Script selesai di-load
updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(100, 255, 100))

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
-- ========== MODERN UI CREATION =====
-- ===================================

-- Hapus GUI lama jika ada
if playerGui:FindFirstChild("FishItAutoGUI") then
    playerGui:FindFirstChild("FishItAutoGUI"):Destroy()
end

-- Color Scheme Modern
local Colors = {
    Background = Color3.fromRGB(13, 17, 23),
    Surface = Color3.fromRGB(22, 27, 34),
    Primary = Color3.fromRGB(47, 129, 247),
    Secondary = Color3.fromRGB(35, 134, 54),
    Danger = Color3.fromRGB(218, 54, 51),
    Warning = Color3.fromRGB(219, 171, 9),
    Text = Color3.fromRGB(248, 250, 252),
    TextSecondary = Color3.fromRGB(139, 148, 158)
}

-- Modern Gradients
local Gradients = {
    Primary = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(47, 129, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(97, 175, 239))
    }),
    Success = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 160, 67)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(87, 187, 106))
    })
}

-- Main ScreenGui dengan efek modern
local screenGui = create("ScreenGui", {
    Name = "FishItAutoGUI",
    Parent = playerGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Background Blur Effect
local blurEffect = create("BlurEffect", {
    Parent = screenGui,
    Size = 0,
    Name = "BackgroundBlur"
})

-- Main Container dengan glass morphism effect
local mainContainer = create("Frame", {
    Name = "MainContainer",
    Parent = screenGui,
    Size = UDim2.new(0, 400, 0, 550),
    Position = UDim2.new(0.5, -200, 0.5, -275),
    BackgroundColor3 = Colors.Surface,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0
})

-- Glass morphism effect
create("UICorner", {Parent = mainContainer, CornerRadius = UDim.new(0, 16)})
create("UIStroke", {
    Parent = mainContainer,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.9,
    Thickness = 1
})

-- Background Gradient
local backgroundGradient = create("UIGradient", {
    Parent = mainContainer,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.Surface),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 33, 40))
    }),
    Rotation = 120
})

-- Header dengan gradient modern
local header = create("Frame", {
    Name = "Header",
    Parent = mainContainer,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = Colors.Primary,
    BorderSizePixel = 0
})

create("UICorner", {Parent = header, CornerRadius = UDim.new(0, 16)})

local headerGradient = create("UIGradient", {
    Parent = header,
    Color = Gradients.Primary,
    Rotation = 45
})

-- Header Content
local headerContent = create("Frame", {
    Parent = header,
    Size = UDim2.new(1, -32, 1, -16),
    Position = UDim2.new(0, 16, 0, 8),
    BackgroundTransparency = 1
})

local titleLabel = create("TextLabel", {
    Parent = headerContent,
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundTransparency = 1,
    Text = "🎯 FISH IT PREMIUM",
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextColor3 = Colors.Text,
    TextXAlignment = Enum.TextXAlignment.Left
})

local subtitleLabel = create("TextLabel", {
    Parent = headerContent,
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0, 32),
    BackgroundTransparency = 1,
    Text = "Advanced Automation Suite • v2.5",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(200, 200, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTransparency = 0.2
})

-- Control Buttons (Close/Minimize)
local controlButtons = create("Frame", {
    Parent = headerContent,
    Size = UDim2.new(0, 60, 0, 24),
    Position = UDim2.new(1, -60, 0, 0),
    BackgroundTransparency = 1
})

local minimizeBtn = create("TextButton", {
    Parent = controlButtons,
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9,
    Text = "─",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Colors.Text
})

create("UICorner", {Parent = minimizeBtn, CornerRadius = UDim.new(1, 0)})
create("UIStroke", {Parent = minimizeBtn, Color = Colors.Text, Transparency = 0.8})

local closeBtn = create("TextButton", {
    Parent = controlButtons,
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(0, 32, 0, 0),
    BackgroundColor3 = Colors.Danger,
    BackgroundTransparency = 0.1,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Colors.Text
})

create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(1, 0)})

-- Status Card
local statusCard = create("Frame", {
    Parent = mainContainer,
    Size = UDim2.new(1, -32, 0, 80),
    Position = UDim2.new(0, 16, 0, 96),
    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0.2
})

create("UICorner", {Parent = statusCard, CornerRadius = UDim.new(0, 12)})
create("UIStroke", {
    Parent = statusCard,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.9,
    Thickness = 1
})

local statusIcon = create("TextLabel", {
    Parent = statusCard,
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0, 16, 0, 20),
    BackgroundTransparency = 1,
    Text = "⚡",
    Font = Enum.Font.Gotham,
    TextSize = 24,
    TextColor3 = Colors.Primary
})

local statusLabel = create("TextLabel", {
    Parent = statusCard,
    Size = UDim2.new(1, -72, 0, 20),
    Position = UDim2.new(0, 64, 0, 20),
    BackgroundTransparency = 1,
    Text = "System Ready",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Colors.Text,
    TextXAlignment = Enum.TextXAlignment.Left
})

local statusSubLabel = create("TextLabel", {
    Parent = statusCard,
    Size = UDim2.new(1, -72, 0, 16),
    Position = UDim2.new(0, 64, 0, 42),
    BackgroundTransparency = 1,
    Text = "Fish It Premium v2.5 • Made with ❤️",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Colors.TextSecondary,
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Navigation Tabs
local tabContainer = create("Frame", {
    Name = "TabContainer",
    Parent = mainContainer,
    Size = UDim2.new(1, -32, 0, 40),
    Position = UDim2.new(0, 16, 0, 192),
    BackgroundTransparency = 1
})

local tabs = {"Fishing", "Teleport", "Utilities"}
local tabButtons = {}
local activeTab = "Fishing"

for i, tabName in ipairs(tabs) do
    local tabBtn = create("TextButton", {
        Name = tabName .. "Tab",
        Parent = tabContainer,
        Size = UDim2.new(1/#tabs, -8, 1, 0),
        Position = UDim2.new((i-1)/#tabs, 0, 0, 0),
        BackgroundColor3 = tabName == "Fishing" and Colors.Primary or Color3.fromRGB(45, 51, 59),
        BackgroundTransparency = tabName == "Fishing" and 0.1 or 0.6,
        Text = tabName,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.Text,
        AutoButtonColor = false
    })
    
    create("UICorner", {Parent = tabBtn, CornerRadius = UDim.new(0, 8)})
    tabButtons[tabName] = tabBtn
    
    addHover(tabBtn, 
        tabName == "Fishing" and Colors.Primary or Color3.fromRGB(45, 51, 59),
        Colors.Primary
    )
end

-- Content Area
local contentFrame = create("ScrollingFrame", {
    Name = "Content",
    Parent = mainContainer,
    Size = UDim2.new(1, -32, 0, 310),
    Position = UDim2.new(0, 16, 0, 248),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Colors.Primary,
    CanvasSize = UDim2.new(0, 0, 0, 600)
})

-- Fungsi untuk membuat feature card yang modern
local function createFeatureCard(parent, title, description, buttonText, buttonColor, icon)
    local card = create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.1
    })
    
    create("UICorner", {Parent = card, CornerRadius = UDim.new(0, 12)})
    create("UIStroke", {
        Parent = card,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.9,
        Thickness = 1
    })
    
    local iconLabel = create("TextLabel", {
        Parent = card,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 16, 0, 20),
        BackgroundTransparency = 1,
        Text = icon,
        Font = Enum.Font.Gotham,
        TextSize = 20,
        TextColor3 = Colors.Primary
    })
    
    local titleLabel = create("TextLabel", {
        Parent = card,
        Size = UDim2.new(0.6, -60, 0, 20),
        Position = UDim2.new(0, 64, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local descLabel = create("TextLabel", {
        Parent = card,
        Size = UDim2.new(0.6, -60, 0, 32),
        Position = UDim2.new(0, 64, 0, 38),
        BackgroundTransparency = 1,
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Colors.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    local actionBtn = create("TextButton", {
        Parent = card,
        Size = UDim2.new(0, 80, 0, 32),
        Position = UDim2.new(1, -96, 0, 24),
        BackgroundColor3 = buttonColor,
        BackgroundTransparency = 0.1,
        Text = buttonText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.Text,
        AutoButtonColor = false
    })
    
    create("UICorner", {Parent = actionBtn, CornerRadius = UDim.new(0, 8)})
    
    -- Add hover effect
    addHover(actionBtn, buttonColor, Color3.fromRGB(
        math.min(buttonColor.R * 255 + 20, 255),
        math.min(buttonColor.G * 255 + 20, 255),
        math.min(buttonColor.B * 255 + 20, 255)
    ))
    
    return card, actionBtn
end

-- ===================================
-- ========== TAB CONTENT CREATION ===
-- ===================================

-- Fishing Tab Content
local fishingTab = create("Frame", {
    Name = "FishingTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 400),
    BackgroundTransparency = 1,
    Visible = true
})

-- Auto Fishing V1 Card
local v1Card, v1Btn = createFeatureCard(fishingTab, 
    "Auto Instant Fishing V1", 
    "Perfect catch with optimized delays • Stable & Safe", 
    "START", 
    Colors.Secondary,
    "🎣"
)

-- Auto Fishing V2 Card
local v2Card, v2Btn = createFeatureCard(fishingTab, 
    "Auto Fishing V2 (ULTRA FAST)", 
    "Maximum speed fishing • Advanced algorithm", 
    "START", 
    Color3.fromRGB(219, 171, 9),
    "⚡"
)
v2Card.Position = UDim2.new(0, 0, 0, 96)

-- Auto Sell Card
local sellCard, sellBtn = createFeatureCard(fishingTab, 
    "Auto Sell System", 
    "Automatically sell non-favorite items • Smart detection", 
    "START", 
    Color3.fromRGB(46, 160, 67),
    "💰"
)
sellCard.Position = UDim2.new(0, 0, 0, 192)

-- Auto Favorite Card
local favoriteCard, favoriteBtn = createFeatureCard(fishingTab, 
    "Auto Favorite", 
    "Auto-favorite Secret/Mythic/Legendary items", 
    "START", 
    Color3.fromRGB(158, 89, 181),
    "⭐"
)
favoriteCard.Position = UDim2.new(0, 0, 0, 288)

-- Teleport Tab Content
local teleportTab = create("Frame", {
    Name = "TeleportTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 400),
    BackgroundTransparency = 1,
    Visible = false
})

-- NPC Teleport Card
local npcCard, npcBtn = createFeatureCard(teleportTab, 
    "NPC Teleport", 
    "Teleport to any NPC instantly • Full list available", 
    "OPEN", 
    Color3.fromRGB(101, 84, 192),
    "🧍"
)

-- Islands Teleport Card
local islandsCard, islandsBtn = createFeatureCard(teleportTab, 
    "Island Teleport", 
    "Quick travel to all islands • Complete map coverage", 
    "OPEN", 
    Color3.fromRGB(219, 154, 4),
    "🏝️"
)
islandsCard.Position = UDim2.new(0, 0, 0, 96)

-- Events Teleport Card
local eventsCard, eventsBtn = createFeatureCard(teleportTab, 
    "Event Teleport", 
    "Join active events automatically • Real-time detection", 
    "OPEN", 
    Color3.fromRGB(229, 83, 116),
    "🎯"
)
eventsCard.Position = UDim2.new(0, 0, 0, 192)

-- Utilities Tab Content
local utilitiesTab = create("Frame", {
    Name = "UtilitiesTab",
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 400),
    BackgroundTransparency = 1,
    Visible = false
})

-- Anti-AFK Card
local afkCard, afkBtn = createFeatureCard(utilitiesTab, 
    "Anti-AFK System", 
    "Prevent getting kicked for inactivity • Smart movement", 
    "ENABLE", 
    Color3.fromRGB(44, 142, 209),
    "⏰"
)

-- Boost FPS Card
local fpsCard, fpsBtn = createFeatureCard(utilitiesTab, 
    "Performance Boost", 
    "Optimize game performance • Increase FPS significantly", 
    "BOOST", 
    Color3.fromRGB(230, 126, 34),
    "🚀"
)
fpsCard.Position = UDim2.new(0, 0, 0, 96)

-- Info Card
local infoCard = create("Frame", {
    Parent = utilitiesTab,
    Size = UDim2.new(1, 0, 0, 100),
    Position = UDim2.new(0, 0, 0, 192),
    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0.1
})

create("UICorner", {Parent = infoCard, CornerRadius = UDim.new(0, 12)})
create("UIStroke", {
    Parent = infoCard,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.9,
    Thickness = 1
})

local infoLabel = create("TextLabel", {
    Parent = infoCard,
    Size = UDim2.new(1, -32, 1, -16),
    Position = UDim2.new(0, 16, 0, 8),
    BackgroundTransparency = 1,
    Text = "🐟 Fish It Premium v2.5\n\nMade with ❤️ by Codepikk\nDiscord: codepikk",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Colors.TextSecondary,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center
})

-- ===================================
-- ========== UI FUNCTIONALITY =======
-- ===================================

-- Fungsi untuk update status dengan animasi
local function updateStatus(newStatus, color)
    statusLabel.Text = newStatus
    statusLabel.TextColor3 = color or Colors.Text
    
    -- Animasi status change
    TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        TextTransparency = 0.5
    }):Play()
    
    wait(0.1)
    
    TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        TextTransparency = 0
    }):Play()
end

-- Tab switching functionality
local function switchTab(tabName)
    activeTab = tabName
    
    -- Hide all tabs
    fishingTab.Visible = false
    teleportTab.Visible = false
    utilitiesTab.Visible = false
    
    -- Show active tab
    if tabName == "Fishing" then
        fishingTab.Visible = true
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    elseif tabName == "Teleport" then
        teleportTab.Visible = true
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    elseif tabName == "Utilities" then
        utilitiesTab.Visible = true
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    end
    
    -- Update tab buttons appearance
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            TweenService:Create(btn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.1,
                BackgroundColor3 = Colors.Primary
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.6,
                BackgroundColor3 = Color3.fromRGB(45, 51, 59)
            }):Play()
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

local dragging, dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainContainer.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X, 
        startPos.Y.Scale, 
        startPos.Y.Offset + delta.Y
    )
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainContainer.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        updateDrag(input)
    end
end)

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
        
        afkBtn.Text = "DISABLE"
        afkBtn.BackgroundColor3 = Colors.Danger
        updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100, 255, 100))
        
    else
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        afkBtn.Text = "ENABLE"
        afkBtn.BackgroundColor3 = Color3.fromRGB(44, 142, 209)
        updateStatus("🔴 Status: Idle")
    end
end

-- ===================================
-- ========== FISHING SYSTEMS ========
-- ===================================

-- [FISHING V1 SYSTEM - Tetap sama seperti sebelumnya]
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

-- [FISHING V2 SYSTEM - Tetap sama seperti sebelumnya]
local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            
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
        
        if not ok then
            -- Error handling silent
        end
        
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- [AUTO SELL SYSTEM - Tetap sama seperti sebelumnya]
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
-- ========== BUTTON CONNECTIONS =====
-- ===================================

-- Setup remotes terlebih dahulu
setupRemotes()

-- Fishing V1 Button
v1Btn.MouseButton1Click:Connect(function()
    autoFishingEnabled = not autoFishingEnabled
    autoFishingV2Enabled = false
    
    if autoFishingEnabled then
        v1Btn.Text = "STOP"
        v1Btn.BackgroundColor3 = Colors.Danger
        v2Btn.Text = "START"
        v2Btn.BackgroundColor3 = Color3.fromRGB(219, 171, 9)
        updateStatus("🟢 Status: Auto Fishing V1 Started", Color3.fromRGB(100, 255, 100))
        task.spawn(autoFishingLoop)
    else
        v1Btn.Text = "START"
        v1Btn.BackgroundColor3 = Colors.Secondary
        updateStatus("🔴 Status: Auto Fishing Stopped")
        fishingActive = false
        finishRemote:FireServer()
    end
end)

-- Fishing V2 Button
v2Btn.MouseButton1Click:Connect(function()
    autoFishingV2Enabled = not autoFishingV2Enabled
    autoFishingEnabled = false
    
    if autoFishingV2Enabled then
        v2Btn.Text = "STOP"
        v2Btn.BackgroundColor3 = Colors.Danger
        v1Btn.Text = "START"
        v1Btn.BackgroundColor3 = Colors.Secondary
        updateStatus("⚡ Status: Auto Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
        task.spawn(autoFishingV2Loop)
    else
        v2Btn.Text = "START"
        v2Btn.BackgroundColor3 = Color3.fromRGB(219, 171, 9)
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
        sellBtn.BackgroundColor3 = Colors.Danger
        updateStatus("🟢 Status: Auto Sell Started", Color3.fromRGB(100, 255, 100))
        task.spawn(autoSellLoop)
    else
        sellBtn.Text = "START"
        sellBtn.BackgroundColor3 = Color3.fromRGB(46, 160, 67)
        updateStatus("🔴 Status: Auto Sell Stopped")
    end
end)

-- Auto Favorite Button
favoriteBtn.MouseButton1Click:Connect(function()
    autoFavoriteEnabled = not autoFavoriteEnabled
    
    if autoFavoriteEnabled then
        favoriteBtn.Text = "STOP"
        favoriteBtn.BackgroundColor3 = Colors.Danger
        startAutoFavorite()
    else
        favoriteBtn.Text = "START"
        favoriteBtn.BackgroundColor3 = Color3.fromRGB(158, 89, 181)
        updateStatus("🔴 Auto Favorite: Disabled")
    end
end)

-- Anti-AFK Button
afkBtn.MouseButton1Click:Connect(toggleAntiAFK)

-- Boost FPS Button
fpsBtn.MouseButton1Click:Connect(function()
    BoostFPS()
end)

-- Teleport Buttons (gunakan fungsi yang sama seperti sebelumnya)
npcBtn.MouseButton1Click:Connect(createNPCTeleportGUI)
islandsBtn.MouseButton1Click:Connect(createTeleportGUI)
eventsBtn.MouseButton1Click:Connect(createEventTeleportGUI)

-- Close Button
closeBtn.MouseButton1Click:Connect(function()
    autoFishingEnabled = false
    autoFishingV2Enabled = false
    autoSellEnabled = false
    fishingActive = false
    autoFavoriteEnabled = false

    if antiAFKEnabled then
        toggleAntiAFK()
    end
    
    -- Animasi close
    TweenService:Create(mainContainer, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    wait(0.3)
    screenGui:Destroy()
end)

-- Minimize Button
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(mainContainer, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(1, -100, 1, -100)
        }):Play()
        
        TweenService:Create(header, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 1, 0)
        }):Play()
        
        titleLabel.Visible = false
        subtitleLabel.Visible = false
        controlButtons.Visible = false
        minimizeBtn.Text = "+"
        minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
        minimizeBtn.Position = UDim2.new(0.5, -20, 0.5, -20)
        
    else
        TweenService:Create(mainContainer, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 400, 0, 550),
            Position = UDim2.new(0.5, -200, 0.5, -275)
        }):Play()
        
        TweenService:Create(header, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 0, 80)
        }):Play()
        
        titleLabel.Visible = true
        subtitleLabel.Visible = true
        controlButtons.Visible = true
        minimizeBtn.Text = "─"
        minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
        minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
    end
end)

-- ===================================
-- ========== SCRIPT INITIALIZATION ==
-- ===================================

-- Inisialisasi status
updateStatus("✅ System Ready", Color3.fromRGB(100, 255, 100))

-- Exclaim Detection (tetap sama seperti sebelumnya)
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

-- Script loaded successfully
print("🎯 Fish It Premium v2.5 - Modern UI Loaded Successfully!")

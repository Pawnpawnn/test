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
            local success, err = pcall(function()
                -- Cari Replion service
                local Replion
                local success1, err1 = pcall(function()
                    Replion = ReplicatedStorage:WaitForChild("Packages")
                        :WaitForChild("_Index")
                        :WaitForChild("sleitnick_knit@1.5.4")
                        :WaitForChild("knit")
                        :WaitForChild("Services")
                        :WaitForChild("ReplionService")
                        :WaitForChild("RF")
                        :WaitForChild("GetReplion")
                end)
                
                if not success1 then
                    Replion = ReplicatedStorage:WaitForChild("Replion")
                end
                
                if not Replion then return end
                
                -- Get inventory data
                local inventoryData = Replion:InvokeServer("Data")
                if inventoryData and inventoryData.Inventory and inventoryData.Inventory.Items then
                    local items = inventoryData.Inventory.Items
                    
                    for _, item in ipairs(items) do
                        if item and item.Id and allowedTiers[item.Tier] and not item.Favorited then
                            -- Mark as favorite
                            local favoriteSuccess = pcall(function()
                                Replion:InvokeServer("FavoriteItem", item.Id, true)
                            end)
                            
                            if favoriteSuccess then
                                updateStatus("⭐ Favorite: " .. item.Tier .. " fish", Color3.fromRGB(255, 215, 0))
                            end
                        end
                    end
                end
            end)
            
            if not success then
                -- Silent error handling
            end
            
            task.wait(5) -- Check setiap 5 detik
        end
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
    Size = UDim2.new(0, 320, 0, 380),
    Position = UDim2.new(0.5, -160, 0.5, -190),
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
    Text = "🐟 Fish It - Codepikk Premium",
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
    CanvasSize = UDim2.new(0, 0, 0, 250),
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
    Text = "🔴 Status: Idle\nScript: V.2.4\nNote: if auto fishing stuck respawn",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Fungsi untuk update status dengan format yang dipertahankan
local function updateStatus(newStatus, color)
    local baseText = "Script: V.2.4\nNote: If auto fishing stuck respawn"
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

-- AUTO SELL SECTION
local sellSection = create("Frame", {
    Parent = mainTab,
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

-- AUTO FAVORITE SECTION
local favoriteSection = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 202),
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

-- Teleports Tab Content dengan Dropdown
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

-- Dropdown untuk Teleport to NPC
local npcDropdownSection = create("Frame", {
    Parent = teleportsTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 10),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = npcDropdownSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = npcDropdownSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local npcDropdownTitle = create("TextLabel", {
    Parent = npcDropdownSection,
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

local npcDropdownBtn = create("TextButton", {
    Parent = npcDropdownSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(100, 80, 180),
    Text = "OPEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = npcDropdownBtn, CornerRadius = UDim.new(0, 6)})

-- Dropdown untuk Teleport to Islands
local islandsDropdownSection = create("Frame", {
    Parent = teleportsTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = islandsDropdownSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = islandsDropdownSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local islandsDropdownTitle = create("TextLabel", {
    Parent = islandsDropdownSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🏝️ Teleport to Islands",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local islandsDropdownBtn = create("TextButton", {
    Parent = islandsDropdownSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(150, 100, 50),
    Text = "OPEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = islandsDropdownBtn, CornerRadius = UDim.new(0, 6)})

-- Dropdown untuk Teleport to Events
local eventsDropdownSection = create("Frame", {
    Parent = teleportsTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 106),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = eventsDropdownSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = eventsDropdownSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local eventsDropdownTitle = create("TextLabel", {
    Parent = eventsDropdownSection,
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

local eventsDropdownBtn = create("TextButton", {
    Parent = eventsDropdownSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 80, 120),
    Text = "OPEN",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = eventsDropdownBtn, CornerRadius = UDim.new(0, 6)})

-- Misc Tab Content
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

-- ANTI-AFK SECTION
local antiAFKSection = create("Frame", {
    Parent = miscTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 10),
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

-- BOOST FPS SECTION
local boostFPSSection = create("Frame", {
    Parent = miscTab,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 58),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = boostFPSSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = boostFPSSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local boostFPSTitle = create("TextLabel", {
    Parent = boostFPSSection,
    Size = UDim2.new(0.55, 0, 1, 0),
    Position = UDim2.new(0, 9, 0, 0),
    BackgroundTransparency = 1,
    Text = "🚀 Auto Boost FPS",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
})

local boostFPSBtn = create("TextButton", {
    Parent = boostFPSSection,
    Size = UDim2.new(0, 72, 0, 27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 100, 50),
    Text = "BOOST",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

create("UICorner", {Parent = boostFPSBtn, CornerRadius = UDim.new(0, 6)})

-- INFO SECTION
local infoSection = create("Frame", {
    Parent = miscTab,
    Size = UDim2.new(1, 0, 0, 80),
    Position = UDim2.new(0, 0, 0, 106),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = infoSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = infoSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local infoLabel = create("TextLabel", {
    Parent = infoSection,
    Size = UDim2.new(1, -12, 1, -8),
    Position = UDim2.new(0, 6, 0, 4),
    BackgroundTransparency = 1,
    Text = "🐟 Fish It Premium V2.4\n\nMade by: Codepikk\nDiscord: codepikk",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(100, 200, 255),
    TextXAlignment = Enum.TextXAlignment.Center
})

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
addHover(sellBtn, Color3.fromRGB(50, 150, 50), Color3.fromRGB(70, 170, 70))
addHover(favoriteBtn, Color3.fromRGB(180, 80, 180), Color3.fromRGB(200, 100, 200))
addHover(npcDropdownBtn, Color3.fromRGB(100, 80, 180), Color3.fromRGB(120, 100, 200))
addHover(islandsDropdownBtn, Color3.fromRGB(150, 100, 50), Color3.fromRGB(170, 120, 70))
addHover(eventsDropdownBtn, Color3.fromRGB(180, 80, 120), Color3.fromRGB(200, 100, 140))
addHover(boostFPSBtn, Color3.fromRGB(180, 100, 50), Color3.fromRGB(200, 120, 70))

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
-- ========== FISHING V2 (FIXED TIMING) =====
-- ===================================
local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            updateStatus("⚡ Status: Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
            
            equipRemote:FireServer(1)
            task.wait(0.1)
            
            -- Fire cast multiple times buat mastiin ke-trigger
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.05)
            rodRemote:InvokeServer(timestamp) -- ✅ Double cast
            
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-300, 300) / 10000000)
            local y = baseY + (math.random(-300, 300) / 10000000)
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(0.5)
            finishRemote:FireServer(true)
            task.wait(0.2)
            finishRemote:FireServer()
        end)
        
        if not ok then
            warn("Fishing error:", err)
        end
        
        task.wait(0.2)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

-- ===================================
-- ========== EXCLAIM DETECTION V1 ===
-- ===================================

-- Listener untuk detect exclaim (tanda seru) dan auto recast
-- VERSI ALTERNATIF (Kalau masih stuck)
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
                            -- Force finish multiple kali biar pasti kelar
                            task.wait(0.2)
                            finishRemote:FireServer(true)
                            task.wait(0.1)
                            finishRemote:FireServer(true) -- Double finish
                            task.wait(0.2)
                            finishRemote:FireServer() -- Reset state
                        else
                            -- V1: Original behavior
                            for i = 1, 3 do
                                task.wait(4)
                                finishRemote:FireServer(true)
                            end
                        end
                    end)
                end
            end
        end)
    end
end)

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
        Text = "🏝️ Island Teleport",
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
-- ========== BUTTON CONNECTIONS =====
-- ===================================

-- Setup remotes terlebih dahulu
setupRemotes()

-- Anti-AFK Button
antiAFKBtn.MouseButton1Click:Connect(toggleAntiAFK)

-- Fishing V1 Button
fishBtn.MouseButton1Click:Connect(function()
    autoFishingEnabled = not autoFishingEnabled
    autoFishingV2Enabled = false -- Matikan V2 jika V1 aktif
    
    if autoFishingEnabled then
        fishBtn.Text = "STOP"
        fishBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fishV2Btn.Text = "START"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🟢 Status: Auto Fishing V1 Started", Color3.fromRGB(100, 255, 100))
        task.spawn(autoFishingLoop)
    else
        fishBtn.Text = "START"
        fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🔴 Status: Auto Fishing Stopped")
        fishingActive = false
        finishRemote:FireServer()
        rconsoleclear()
    end
end)

-- Fishing V2 Button
fishV2Btn.MouseButton1Click:Connect(function()
    autoFishingV2Enabled = not autoFishingV2Enabled
    autoFishingEnabled = false -- Matikan V1 jika V2 aktif
    
    if autoFishingV2Enabled then
        fishV2Btn.Text = "STOP"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fishBtn.Text = "START"
        fishBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("⚡ Status: Auto Fishing V2 ULTRA FAST", Color3.fromRGB(255, 255, 100))
        task.spawn(autoFishingV2Loop)
    else
        fishV2Btn.Text = "START"
        fishV2Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        updateStatus("🔴 Status: Auto Fishing Stopped")
        fishingActive = false
        finishRemote:FireServer()
        rconsoleclear()
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
        updateStatus("⭐ Auto Favorite: Enabled", Color3.fromRGB(255, 215, 0))
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
            Size = UDim2.new(0, 320, 0, 380),
            Position = UDim2.new(0.5, -160, 0.5, -190)
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

-- ===================================
-- ========== SCRIPT LOADED ==========
-- ===================================

-- Script selesai di-load
updateStatus("✅ Script Loaded Successfully", Color3.fromRGB(100, 255, 100))

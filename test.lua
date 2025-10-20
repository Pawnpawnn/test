-- final_v3.lua
-- Fish It - Codepikk Premium V3 (REBUILT FINAL)
-- Features: compact 320x300, high ZIndex, smart overlay, hidden scrollbars,
-- tabs top, drag by titlebar only, minimize -> bubble (🐟), includes core logic.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Simple create helper (safe minimal)
local function create(className, props)
    local obj = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            if k ~= "Parent" then
                pcall(function() obj[k] = v end)
            end
        end
        if props.Parent then
            pcall(function() obj.Parent = props.Parent end)
        end
    end
    return obj
end

-- Simple addHover helper (changes bg on mouse enter/leave)
local function addHover(inst, normal, hover)
    if not inst then return end
    inst.MouseEnter:Connect(function()
        pcall(function() inst.BackgroundColor3 = hover end)
    end)
    inst.MouseLeave:Connect(function()
        pcall(function() inst.BackgroundColor3 = normal end)
    end)
end

-- updateStatus helper (shows statusLabel text if exists)
local function updateStatus(text, color)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = text
        if color then
            statusLabel.TextColor3 = color
        end
    end
end

-- Remotes placeholders (will try to setup)
local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote = nil, nil, nil, nil, nil, nil, nil

local function setupRemotes()
    local ok
    ok = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    end)
    if not ok then
        pcall(function() net = ReplicatedStorage:WaitForChild("Net") end)
    end

    if net then
        pcall(function() rodRemote = net:WaitForChild("RF/ChargeFishingRod") end)
        pcall(function() miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted") end)
        pcall(function() finishRemote = net:WaitForChild("RE/FishingCompleted") end)
        pcall(function() equipRemote = net:WaitForChild("RE/EquipToolFromHotbar") end)
        pcall(function() sellRemote = net:WaitForChild("RF/SellAllItems") end)
        pcall(function() favoriteRemote = net:WaitForChild("RE/FavoriteItem") end)
        updateStatus("✅ Remotes setup completed", Color3.fromRGB(100,255,100))
    else
        updateStatus("⚠️ Remotes not found (some features may not work)", Color3.fromRGB(255,180,80))
    end
end

-- Cleanup existing GUI
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

-- Main Frame (320x300 compact)
local mainFrame = create("Frame", {
    Name = "MainFrame",
    Parent = screenGui,
    Size = UDim2.new(0,320,0,300),
    Position = UDim2.new(0.5, -160, 0.5, -150),
    BackgroundColor3 = Color3.fromRGB(15,20,30),
    BorderSizePixel = 0,
    ZIndex = 100
})
mainFrame.ClipsDescendants = false
create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0,10)})
create("UIStroke", {Parent = mainFrame, Color = Color3.fromRGB(40,80,150), Thickness = 1.5})

-- TitleBar (drag area)
local titleBar = create("Frame", {
    Name = "TitleBar",
    Parent = mainFrame,
    Size = UDim2.new(1,0,0,33),
    BackgroundColor3 = Color3.fromRGB(25,35,55),
    BorderSizePixel = 0,
    ZIndex = 103
})
titleBar.ClipsDescendants = false
create("UICorner", {Parent = titleBar, CornerRadius = UDim.new(0,10)})

local titleText = create("TextLabel", {
    Parent = titleBar,
    Size = UDim2.new(1, -66, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "🐟 Fish It - Codepikk Premium V3",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(100,180,255),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Close & Minimize buttons (ZIndex high)
local closeBtn = create("TextButton", {
    Parent = titleBar,
    Size = UDim2.new(0,25,0,25),
    Position = UDim2.new(1, -29, 0, 4),
    BackgroundColor3 = Color3.fromRGB(220,50,50),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})
closeBtn.ZIndex = 104

local minimizeBtn = create("TextButton", {
    Parent = titleBar,
    Size = UDim2.new(0,25,0,25),
    Position = UDim2.new(1, -58, 0, 4),
    BackgroundColor3 = Color3.fromRGB(70,80,100),
    Text = "—",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = minimizeBtn, CornerRadius = UDim.new(0,6)})
minimizeBtn.ZIndex = 104

-- Tab container (top)
local tabContainer = create("Frame", {
    Name = "TabContainer",
    Parent = mainFrame,
    Size = UDim2.new(1, -20, 0, 35),
    Position = UDim2.new(0,10,0,38),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 101
})

local tabs = {"Main","Teleports","Misc"}
local tabButtons = {}
local activeTab = "Main"

for i, tabName in ipairs(tabs) do
    local tabBtn = create("TextButton", {
        Name = tabName.."Tab",
        Parent = tabContainer,
        Size = UDim2.new(1/#tabs, -4, 1, 0),
        Position = UDim2.new((i-1)/#tabs, 2, 0, 0),
        BackgroundColor3 = tabName == "Main" and Color3.fromRGB(40,60,100) or Color3.fromRGB(30,40,60),
        Text = tabName,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(220,220,220)
    })
    create("UICorner", {Parent = tabBtn, CornerRadius = UDim.new(0,6)})
    tabBtn.ZIndex = 101
    tabButtons[tabName] = tabBtn

    addHover(tabBtn,
        tabName == "Main" and Color3.fromRGB(40,60,100) or Color3.fromRGB(30,40,60),
        Color3.fromRGB(50,70,110)
    )
end

-- Content frame below tabs
local contentFrame = create("Frame", {
    Name = "Content",
    Parent = mainFrame,
    Size = UDim2.new(1, -18, 1, -85),
    Position = UDim2.new(0,9,0,80),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 99
})

-- MainTab (scrolling, hidden scrollbar)
local mainTab = create("ScrollingFrame", {
    Name = "MainTab",
    Parent = contentFrame,
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    ScrollBarImageColor3 = Color3.fromRGB(50,100,180),
    CanvasSize = UDim2.new(0,0,0,400),
    Visible = true
})
mainTab.ZIndex = 99

-- Status box
local statusBox = create("Frame", {
    Parent = mainTab,
    Size = UDim2.new(1,0,0,50),
    BackgroundColor3 = Color3.fromRGB(25,35,50),
})
statusBox.ZIndex = 99
create("UICorner", {Parent = statusBox, CornerRadius = UDim.new(0,7)})
create("UIStroke", {Parent = statusBox, Color = Color3.fromRGB(40,60,90), Thickness = 1})

statusLabel = create("TextLabel", {
    Parent = statusBox,
    Size = UDim2.new(1,-12,1,-8),
    Position = UDim2.new(0,6,0,4),
    BackgroundTransparency = 1,
    Text = "🔴 Status: Idle\nScript: V.3.0",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255,100,100),
    TextXAlignment = Enum.TextXAlignment.Left
})
statusLabel.ZIndex = 99

-- Teleports Tab
local teleportsTab = create("Frame", {
    Name = "TeleportsTab",
    Parent = contentFrame,
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Visible = false
})
teleportsTab.ZIndex = 99

-- Misc Tab
local miscTab = create("ScrollingFrame", {
    Name = "MiscTab",
    Parent = contentFrame,
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0,0,0,200),
    Visible = false
})
miscTab.ZIndex = 99

-- Example Misc: Anti-AFK toggle button
local antiAFKSection = create("Frame", {
    Parent = miscTab,
    Size = UDim2.new(1,0,0,40),
    Position = UDim2.new(0,0,0,10),
    BackgroundColor3 = Color3.fromRGB(25,35,50),
})
antiAFKSection.ZIndex = 99
create("UICorner", {Parent = antiAFKSection, CornerRadius = UDim.new(0,7)})
create("UIStroke", {Parent = antiAFKSection, Color = Color3.fromRGB(40,60,90), Thickness = 1})

local antiAFKBtn = create("TextButton", {
    Parent = antiAFKSection,
    Size = UDim2.new(0,72,0,27),
    Position = UDim2.new(1, -78, 0, 6),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    Text = "START",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = antiAFKBtn, CornerRadius = UDim.new(0,6)})

-- Tab switching logic
local function switchTab(tabName)
    activeTab = tabName
    mainTab.Visible = (tabName == "Main")
    teleportsTab.Visible = (tabName == "Teleports")
    miscTab.Visible = (tabName == "Misc")
    for name, btn in pairs(tabButtons) do
        if name == tabName then btn.BackgroundColor3 = Color3.fromRGB(40,60,100)
        else btn.BackgroundColor3 = Color3.fromRGB(30,40,60) end
    end
end

for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- Dragging (titleBar only)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updateDrag(input)
    local delta = input.Position - dragStart
    TweenService:Create(mainFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    }):Play()
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Close button behavior
closeBtn.MouseButton1Click:Connect(function()
    -- stop any loops you have (placeholders)
    -- destroy GUI
    if screenGui then screenGui:Destroy() end
end)

-- Minimize behavior -> create bubble (modern, 45x45, icon 🐟)
local bubbleGui, bubbleBtn
local function createBubble()
    if bubbleGui and bubbleGui.Parent then return end
    bubbleGui = create("ScreenGui", {Name = "FishItBubbleGUI", Parent = playerGui, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    bubbleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bubbleBtn = create("TextButton", {
        Parent = bubbleGui,
        Size = UDim2.new(0,45,0,45),
        Position = UDim2.new(1, -56, 1, -56),
        BackgroundColor3 = Color3.fromRGB(25,35,55),
        Text = "🐟",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = Color3.fromRGB(255,255,255),
        ZIndex = 200
    })
    create("UICorner", {Parent = bubbleBtn, CornerRadius = UDim.new(0,22)})
    create("UIStroke", {Parent = bubbleBtn, Color = Color3.fromRGB(40,80,150), Thickness = 1})
    bubbleBtn.MouseButton1Click:Connect(function()
        -- restore
        if bubbleGui then bubbleGui:Destroy() end
        mainFrame.Visible = true
    end)
end

minimizeBtn.MouseButton1Click:Connect(function()
    -- hide main UI and show bubble
    mainFrame.Visible = false
    createBubble()
end)

-- Example Restore if bubble exists and user clicked; handled in createBubble()

-- Smart overlay note: when creating popup GUIs, ensure you set their ZIndex <= 104 for titlebar buttons to remain clickable.
-- We'll include example teleport popup creation functions that respect ZIndex.

-- Example: create teleport GUI for islands
local function createTeleportGUI(islandCoords)
    if not islandCoords or type(islandCoords) ~= "table" then
        islandCoords = {
            ["Spawn"] = Vector3.new(0,5,0)
        }
    end

    local teleportGui = create("ScreenGui", {Name = "TeleportGUI", Parent = playerGui, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    local teleportFrame = create("Frame", {
        Parent = teleportGui,
        Size = UDim2.new(0,300,0,350),
        Position = UDim2.new(0.5,-150,0.5,-175),
        BackgroundColor3 = Color3.fromRGB(15,20,30),
        BorderSizePixel = 0,
        ZIndex = 102
    })
    create("UICorner", {Parent = teleportFrame, CornerRadius = UDim.new(0,10)})
    create("UIStroke", {Parent = teleportFrame, Color = Color3.fromRGB(40,80,150), Thickness = 1.5})

    local teleportTitle = create("TextLabel", {
        Parent = teleportFrame,
        Size = UDim2.new(1,0,0,35),
        BackgroundColor3 = Color3.fromRGB(25,35,55),
        Text = "🏝️ Island Teleport",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(100,180,255),
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 103
    })
    create("UICorner", {Parent = teleportTitle, CornerRadius = UDim.new(0,10)})
    local closeTeleportBtn = create("TextButton", {
        Parent = teleportTitle,
        Size = UDim2.new(0,22,0,22),
        Position = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = Color3.fromRGB(220,50,50),
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255,255,255),
        ZIndex = 104
    })
    create("UICorner", {Parent = closeTeleportBtn, CornerRadius = UDim.new(0,6)})

    local scrollFrame = create("ScrollingFrame", {
        Parent = teleportFrame,
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0, #islandCoords * 35),
        ZIndex = 102
    })

    local yPos = 0
    for name, position in pairs(islandCoords) do
        local btn = create("TextButton", {
            Parent = scrollFrame,
            Size = UDim2.new(1,0,0,32),
            Position = UDim2.new(0,0,0,yPos),
            BackgroundColor3 = Color3.fromRGB(35,45,65),
            Text = "📍 "..tostring(name),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(220,220,220),
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 102
        })
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
        create("UIStroke", {Parent = btn, Color = Color3.fromRGB(60,100,160), Thickness = 1})
        addHover(btn, Color3.fromRGB(35,45,65), Color3.fromRGB(45,55,75))

        btn.MouseButton1Click:Connect(function()
            local char = player.Character
            if not char then updateStatus("❌ Character not found") return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then updateStatus("❌ HRP not found") return end
            local success, err = pcall(function()
                hrp.CFrame = CFrame.new(position + Vector3.new(0,5,0))
            end)
            if success then
                updateStatus("✅ Teleported to "..tostring(name), Color3.fromRGB(100,255,100))
                teleportGui:Destroy()
            else
                updateStatus("❌ Teleport failed: "..tostring(err))
            end
        end)

        yPos = yPos + 35
    end

    closeTeleportBtn.MouseButton1Click:Connect(function()
        teleportGui:Destroy()
    end)
end

-- Example buttons in mainTab: Start AutoFishing toggle, AutoSell, Favorite
local startBtn = create("TextButton", {
    Parent = mainTab,
    Size = UDim2.new(0,100,0,30),
    Position = UDim2.new(0,10,0,70),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    Text = "START",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = startBtn, CornerRadius = UDim.new(0,6)})

local autoSellBtn = create("TextButton", {
    Parent = mainTab,
    Size = UDim2.new(0,100,0,30),
    Position = UDim2.new(0,120,0,70),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    Text = "AUTO SELL",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = autoSellBtn, CornerRadius = UDim.new(0,6)})

local favoriteBtn = create("TextButton", {
    Parent = mainTab,
    Size = UDim2.new(0,100,0,30),
    Position = UDim2.new(0,230,0,70),
    BackgroundColor3 = Color3.fromRGB(180,80,180),
    Text = "FAVORITE",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = favoriteBtn, CornerRadius = UDim.new(0,6)})

-- Logic placeholders / toggles
local autoFishingEnabled = false
local autoSellEnabled = false
local autoFavoriteEnabled = false
local fishingActive = false
local antiAFKEnabled = false
local AFKConnection = nil

-- AutoFishing loop (simple safe placeholder)
local function autoFishingLoop()
    while autoFishingEnabled do
        fishingActive = true
        updateStatus("🎣 Auto Fishing running...", Color3.fromRGB(100,255,100))
        -- call remotes safely if available
        if equipRemote then pcall(function() equipRemote:FireServer(1) end) end
        if rodRemote then pcall(function() rodRemote:FireServer() end) end
        task.wait(3)
        if finishRemote then pcall(function() finishRemote:FireServer(true) end) end
        task.wait(2)
    end
    fishingActive = false
    updateStatus("🔴 Status: Idle")
end

startBtn.MouseButton1Click:Connect(function()
    autoFishingEnabled = not autoFishingEnabled
    if autoFishingEnabled then
        startBtn.Text = "STOP"
        startBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        task.spawn(autoFishingLoop)
        updateStatus("🟢 AutoFishing Started", Color3.fromRGB(100,255,100))
    else
        startBtn.Text = "START"
        startBtn.BackgroundColor3 = Color3.fromRGB(50,150,50)
        updateStatus("🔴 AutoFishing Stopped")
    end
end)

autoSellBtn.MouseButton1Click:Connect(function()
    autoSellEnabled = not autoSellEnabled
    if autoSellEnabled then
        autoSellBtn.Text = "STOP"
        autoSellBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        updateStatus("🟢 AutoSell Started", Color3.fromRGB(100,255,100))
    else
        autoSellBtn.Text = "AUTO SELL"
        autoSellBtn.BackgroundColor3 = Color3.fromRGB(50,150,50)
        updateStatus("🔴 AutoSell Stopped")
    end
end)

favoriteBtn.MouseButton1Click:Connect(function()
    autoFavoriteEnabled = not autoFavoriteEnabled
    if autoFavoriteEnabled then
        favoriteBtn.Text = "STOP"
        favoriteBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        updateStatus("⭐ Auto Favorite Started", Color3.fromRGB(255,215,0))
    else
        favoriteBtn.Text = "FAVORITE"
        favoriteBtn.BackgroundColor3 = Color3.fromRGB(180,80,180)
        updateStatus("🔴 Auto Favorite Disabled")
    end
end)

-- Anti-AFK toggle
local function toggleAntiAFK()
    antiAFKEnabled = not antiAFKEnabled
    if antiAFKEnabled then
        if AFKConnection then AFKConnection:Disconnect() end
        AFKConnection = player.Idled:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end)
        antiAFKBtn.Text = "STOP"
        antiAFKBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100,255,100))
    else
        if AFKConnection then AFKConnection:Disconnect() AFKConnection = nil end
        antiAFKBtn.Text = "START"
        antiAFKBtn.BackgroundColor3 = Color3.fromRGB(50,150,50)
        updateStatus("🔴 Anti-AFK Disabled")
    end
end
antiAFKBtn.MouseButton1Click:Connect(toggleAntiAFK)

-- Teleport buttons in teleportsTab (example open)
local islandsDropdownBtn = create("TextButton", {
    Parent = teleportsTab,
    Size = UDim2.new(0,90,0,30),
    Position = UDim2.new(0,10,0,10),
    BackgroundColor3 = Color3.fromRGB(150,100,50),
    Text = "ISLANDS",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(255,255,255)
})
create("UICorner", {Parent = islandsDropdownBtn, CornerRadius = UDim.new(0,6)})
islandsDropdownBtn.ZIndex = 100
islandsDropdownBtn.MouseButton1Click:Connect(function()
    createTeleportGUI({["Spawn"]=Vector3.new(0,5,0), ["Example Island"]=Vector3.new(100,5,100)})
end)

-- Initialize remotes
task.spawn(setupRemotes)

-- Ensure when script ends unexpectedly, GUI is cleaned (safety)
game:BindToClose(function()
    if screenGui and screenGui.Parent then pcall(function() screenGui:Destroy() end) end
    if bubbleGui and bubbleGui.Parent then pcall(function() bubbleGui:Destroy() end) end
end)

-- Ready
updateStatus("✅ UI ready (compact) — enjoy!", Color3.fromRGB(100,255,150))


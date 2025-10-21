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
local autoFishingV3Enabled = false
local antiAFKEnabled = false
local fishingActive = false

-- Remote Variables
local net
local rodRemote, miniGameRemote, finishRemote, equipRemote

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
    Size = UDim2.new(0, 380, 0, 280),
    Position = UDim2.new(0.5, -160, 0.5, -140),
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
    Text = "🐟 Fish It - Fishing V3 + Anti-AFK",
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

-- Content Frame
local contentFrame = create("Frame", {
    Name = "Content",
    Parent = mainFrame,
    Size = UDim2.new(1, -18, 1, -85),
    Position = UDim2.new(0, 9, 0, 80),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

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
    Text = "🔴 Status: Idle\nScript: V.2.5\nNote: Donate me if you happy using this script  :)",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Fungsi untuk update status dengan format yang dipertahankan
local function updateStatus(newStatus, color)
    local baseText = "Script: V.2.5\nNote: Donate me if you happy using this script :)"
    statusLabel.Text = newStatus .. "\n" .. baseText
    statusLabel.TextColor3 = color or Color3.fromRGB(255, 100, 100)
end

-- Inisialisasi status awal
updateStatus("🔴 Status: Idle")

-- FISHING V3 SECTION
local fishV3Section = create("Frame", {
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 58),
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

-- ANTI-AFK SECTION
local antiAFKSection = create("Frame", {
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 106),
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

-- INFO SECTION
local infoSection = create("Frame", {
    Parent = contentFrame,
    Size = UDim2.new(1, 0, 0, 80),
    Position = UDim2.new(0, 0, 0, 154),
    BackgroundColor3 = Color3.fromRGB(25, 35, 50),
})

create("UICorner", {Parent = infoSection, CornerRadius = UDim.new(0, 7)})
create("UIStroke", {Parent = infoSection, Color = Color3.fromRGB(40, 60, 90), Thickness = 1})

local infoLabel = create("TextLabel", {
    Parent = infoSection,
    Size = UDim2.new(1, -12, 1, -8),
    Position = UDim2.new(0, 6, 0, 4),
    BackgroundTransparency = 1,
    Text = "🐟 Fish It Premium V2.5\n\nMade by: Codepikk\nDiscord: codepikk",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(100, 200, 255),
    TextXAlignment = Enum.TextXAlignment.Center
})

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
addHover(fishV3Btn, Color3.fromRGB(180, 60, 60), Color3.fromRGB(200, 80, 80))

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
            if autoFishingV3Enabled and data and data.TextData
                and data.TextData.EffectType == "Exclaim" then

                local head = player.Character and player.Character:FindFirstChild("Head")
                if head and data.Container == head then
                    task.spawn(function()
                        -- V3: Immediate finish dengan timing exploit
                        task.wait(0.05)
                        finishRemote:FireServer(true)
                        updateStatus("⚡ V3 Exclaim Backup!", Color3.fromRGB(255, 255, 100))
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

-- Fishing V3 Button
fishV3Btn.MouseButton1Click:Connect(function()
    autoFishingV3Enabled = not autoFishingV3Enabled
    
    if autoFishingV3Enabled then
        fishV3Btn.Text = "STOP"
        fishV3Btn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
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

-- Close dan Minimize Buttons
closeBtn.MouseButton1Click:Connect(function()
    autoFishingV3Enabled = false
    fishingActive = false

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
        contentFrame.Visible = false
        
        -- Pindahkan minimize button ke posisi yang sesuai
        minimizeBtn.Size = UDim2.new(0, 70, 0, 20)
        minimizeBtn.Position = UDim2.new(0, 5, 0, 2)
        minimizeBtn.Text = "+"
        
    else
        -- Maximize: kembalikan ke ukuran normal
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 380, 0, 280),
            Position = UDim2.new(0.5, -160, 0.5, -140)
        }):Play()
        
        -- Tampilkan kembali semua elemen
        titleText.Visible = true
        closeBtn.Visible = true
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

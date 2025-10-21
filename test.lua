local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library dengan error handling
local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    warn("Failed to load Rayfield UI Library: " .. tostring(err))
    return
end

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local autoFishingEnabled = false
local antiAFKEnabled = false
local fishingActive = false

local net, rodRemote, miniGameRemote, finishRemote, equipRemote
local AFKConnection = nil

-- Fishing Animations with error handling
local RodIdle, RodReel, RodShake
local animator
local RodShakeAnim, RodIdleAnim, RodReelAnim

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

local function setupRemotes()
    local success, err = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages", 5)
            :WaitForChild("_Index", 5)
            :WaitForChild("sleitnick_net@0.2.0", 5)
            :WaitForChild("net", 5)
    end)

    if not success then
        local netSuccess = pcall(function()
            net = ReplicatedStorage:WaitForChild("Net", 5)
        end)
        
        if not netSuccess then
            warn("Failed to find Net folder")
            return false
        end
    end

    local remoteSuccess = pcall(function()
        rodRemote = net:WaitForChild("RF/ChargeFishingRod", 5)
        miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 5)
        finishRemote = net:WaitForChild("RE/FishingCompleted", 5)
        equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 5)
    end)
    
    return remoteSuccess
end

local function setupAnimations()
    pcall(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid", 5)
        animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        
        RodIdle = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("FishingRodReelIdle", 5)
        RodReel = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("EasyFishReelStart", 5)
        RodShake = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5):WaitForChild("CastFromFullChargePosition1Hand", 5)

        RodShakeAnim = animator:LoadAnimation(RodShake)
        RodIdleAnim = animator:LoadAnimation(RodIdle)
        RodReelAnim = animator:LoadAnimation(RodReel)
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
            
            -- Equip fishing rod
            if equipRemote then
                equipRemote:FireServer(1)
                task.wait(0.5)
            end

            -- Start fishing with animation
            if rodRemote then
                local timestamp = workspace:GetServerTimeNow()
                if RodShakeAnim then RodShakeAnim:Play() end
                rodRemote:InvokeServer(timestamp)
            end

            -- Perfect cast
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-500, 500) / 10000000)
            local y = baseY + (math.random(-500, 500) / 10000000)

            -- Play idle animation and start minigame
            if RodIdleAnim then RodIdleAnim:Play() end
            if miniGameRemote then
                miniGameRemote:InvokeServer(x, y)
            end
            
            -- Wait for catch
            task.wait(5)
            
            -- Finish fishing with reel animation
            if RodReelAnim then RodReelAnim:Play() end
            if finishRemote then
                finishRemote:FireServer(true)
            end
            task.wait(5)
        end)
        
        if not ok then
            Rayfield:Notify({
                Title = "Fishing Error",
                Content = "Error: " .. tostring(err),
                Duration = 3
            })
        end
        
        task.wait(0.2)
    end
    fishingActive = false
    if RodIdleAnim then RodIdleAnim:Stop() end
    if RodShakeAnim then RodShakeAnim:Stop() end
    if RodReelAnim then RodReelAnim:Stop() end
end

-- ===================================
-- ========== EXCLAIM DETECTION ======
-- ===================================

task.spawn(function()
    task.wait(2) -- Wait for net to be initialized
    
    local success, exclaimEvent = pcall(function()
        return net:WaitForChild("RE/ReplicateTextEffect", 5)
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
                            if finishRemote then
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
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Auto Fishing V1",
    LoadingTitle = "Fish It Auto Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItAuto",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main", 4483362458)
local MainSection = MainTab:CreateSection("Auto Fishing")

local FishingV1Toggle = MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (Perfect + Animasi)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 dengan Animasi Started!",
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
            if finishRemote then finishRemote:FireServer() end
            if RodIdleAnim then RodIdleAnim:Stop() end
            if RodShakeAnim then RodShakeAnim:Stop() end
            if RodReelAnim then RodReelAnim:Stop() end
        end
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

local InfoSection = MiscTab:CreateSection("Information")

local InfoLabel = MiscTab:CreateLabel("🐟 Fish It Auto Fishing V1")
local InfoLabel2 = MiscTab:CreateLabel("Dengan Animasi + Anti AFK")
local InfoLabel3 = MiscTab:CreateLabel("Request dari Client")

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

-- Initialize with delay
task.spawn(function()
    local remotesReady = setupRemotes()
    
    if remotesReady then
        Rayfield:Notify({
            Title = "Remotes Ready!",
            Content = "All remotes loaded successfully!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Warning",
            Content = "Some remotes may not be available",
            Duration = 5,
            Image = 4483362458
        })
    end
    
    setupAnimations()
    
    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Auto Fishing V1 loaded successfully!",
        Duration = 5,
        Image = 4483362458
    })
end)

-- Load configuration after a small delay
task.wait(1)
Rayfield:LoadConfiguration()

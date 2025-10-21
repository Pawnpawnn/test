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

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, playVFXRemote
local AFKConnection = nil

-- Variabel animasi
local RodIdleAnim, RodReelAnim, RodShakeAnim
local animator
local animationsLoaded = false

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
    local function loadAnimations(character)
        if not character then return end
        
        local success, result = pcall(function()
            local humanoid = character:WaitForChild("Humanoid", 10)
            if not humanoid then return false end
            
            animator = humanoid:FindFirstChildOfClass("Animator") 
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end
            
            -- Cari folder animations dengan berbagai kemungkinan path
            local animationsFolder
            local possiblePaths = {
                ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Animations", 5),
                ReplicatedStorage:WaitForChild("Animations", 5),
                ReplicatedStorage:WaitForChild("Modules", 5),
                game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts", 5):WaitForChild("Modules", 5):WaitForChild("Animations", 5)
            }
            
            for _, path in ipairs(possiblePaths) do
                if path then
                    animationsFolder = path
                    break
                end
            end
            
            if not animationsFolder then
                warn("Animations folder not found")
                return false
            end
            
            -- Load animation objects
            local RodIdle = animationsFolder:FindFirstChild("FishingRodReelIdle") or animationsFolder:FindFirstChild("RodIdle")
            local RodReel = animationsFolder:FindFirstChild("EasyFishReelStart") or animationsFolder:FindFirstChild("RodReel")
            local RodShake = animationsFolder:FindFirstChild("CastFromFullChargePosition1Hand") or animationsFolder:FindFirstChild("RodShake")
            
            if RodIdle and RodReel and RodShake then
                RodIdleAnim = animator:LoadAnimation(RodIdle)
                RodReelAnim = animator:LoadAnimation(RodReel)
                RodShakeAnim = animator:LoadAnimation(RodShake)
                
                -- Configure animation properties
                RodIdleAnim.Looped = true
                RodReelAnim.Looped = false
                RodShakeAnim.Looped = false
                
                animationsLoaded = true
                return true
            else
                warn("Some animation objects not found")
                return false
            end
        end)
        
        if not success then
            warn("Error loading animations: " .. tostring(result))
            return false
        end
        
        return result
    end

    -- Try to load animations for current character
    if player.Character then
        loadAnimations(player.Character)
    end
    
    -- Listen for new characters
    player.CharacterAdded:Connect(function(character)
        task.wait(2) -- Wait for character to fully load
        loadAnimations(character)
    end)
end

local function playAnimation(animation, stopOthers)
    if not animation then return false end
    
    if stopOthers then
        if RodIdleAnim then RodIdleAnim:Stop() end
        if RodReelAnim then RodReelAnim:Stop() end
        if RodShakeAnim then RodShakeAnim:Stop() end
    end
    
    local success = pcall(function()
        animation:Play()
    end)
    
    return success
end

local function stopAllAnimations()
    pcall(function()
        if RodIdleAnim then RodIdleAnim:Stop() end
        if RodReelAnim then RodReelAnim:Stop() end
        if RodShakeAnim then RodShakeAnim:Stop() end
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
                
                -- Play cast animation
                if animationsLoaded then
                    playAnimation(RodShakeAnim, true)
                end
                
                rodRemote:InvokeServer(timestamp)
                task.wait(0.5)
            end

            -- Perfect cast coordinates
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-500, 500) / 10000000)
            local y = baseY + (math.random(-500, 500) / 10000000)

            -- Play idle animation and start minigame
            if animationsLoaded then
                playAnimation(RodIdleAnim, true)
            end
            
            if miniGameRemote then
                miniGameRemote:InvokeServer(x, y)
            end
            
            -- Wait for catch
            local waitTime = 5
            local startTime = tick()
            while tick() - startTime < waitTime and autoFishingEnabled do
                task.wait(0.1)
            end
            
            -- Finish fishing with reel animation
            if animationsLoaded then
                playAnimation(RodReelAnim, true)
            end
            
            if finishRemote then
                finishRemote:FireServer(true)
            end
            
            -- Wait before next cycle
            task.wait(2)
        end)
        
        if not ok then
            warn("Fishing error: " .. tostring(err))
            Rayfield:Notify({
                Title = "Fishing Error",
                Content = "Error: " .. tostring(err),
                Duration = 3
            })
        end
        
        -- Small delay between cycles
        task.wait(0.5)
    end
    
    fishingActive = false
    stopAllAnimations()
end

-- ===================================
-- ========== EXCLAIM DETECTION ======
-- ===================================

task.spawn(function()
    task.wait(3) -- Wait for net to be initialized
    
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
                            if finishRemote and autoFishingEnabled then
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
            -- Pastikan animasi sudah di-load
            if not animationsLoaded then
                setupAnimations()
                task.wait(1)
            end
            
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = animationsLoaded and "Auto Fishing dengan Animasi Started!" or "Auto Fishing Started (Animasi tidak tersedia)",
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
            stopAllAnimations()
            if finishRemote then finishRemote:FireServer() end
        end
    end,
})

-- Animations Tab
local AnimTab = Window:CreateTab("🎭 Animations", 4483362458)

local AnimSection = AnimTab:CreateSection("Animation Controls")

local ReloadAnimBtn = AnimTab:CreateButton({
    Name = "🔄 Reload Animations",
    Callback = function()
        setupAnimations()
        Rayfield:Notify({
            Title = "Animations",
            Content = animationsLoaded and "Animations reloaded successfully!" or "Failed to load animations",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

local TestAnimSection = AnimTab:CreateSection("Test Animations")

local TestCastBtn = AnimTab:CreateButton({
    Name = "🎣 Test Cast Animation",
    Callback = function()
        if animationsLoaded then
            playAnimation(RodShakeAnim, true)
        else
            Rayfield:Notify({
                Title = "Animation Error",
                Content = "Animations not loaded!",
                Duration = 3
            })
        end
    end,
})

local TestIdleBtn = AnimTab:CreateButton({
    Name = "⏸️ Test Idle Animation",
    Callback = function()
        if animationsLoaded then
            playAnimation(RodIdleAnim, true)
        else
            Rayfield:Notify({
                Title = "Animation Error",
                Content = "Animations not loaded!",
                Duration = 3
            })
        end
    end,
})

local TestReelBtn = AnimTab:CreateButton({
    Name = "🎣 Test Reel Animation",
    Callback = function()
        if animationsLoaded then
            playAnimation(RodReelAnim, true)
        else
            Rayfield:Notify({
                Title = "Animation Error",
                Content = "Animations not loaded!",
                Duration = 3
            })
        end
    end,
})

local StopAnimBtn = AnimTab:CreateButton({
    Name = "⏹️ Stop All Animations",
    Callback = function()
        stopAllAnimations()
        Rayfield:Notify({
            Title = "Animations",
            Content = "All animations stopped!",
            Duration = 2
        })
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

local StatusSection = MiscTab:CreateSection("Status Information")

local AnimStatusLabel = MiscTab:CreateLabel("Animation Status: " .. (animationsLoaded and "✅ Loaded" or "❌ Not Loaded"))
local FishingStatusLabel = MiscTab:CreateLabel("Fishing Status: Stopped")

-- Update status labels
coroutine.wrap(function()
    while true do
        task.wait(1)
        if AnimStatusLabel then
            AnimStatusLabel:SetText("Animation Status: " .. (animationsLoaded and "✅ Loaded" or "❌ Not Loaded"))
        end
        if FishingStatusLabel then
            FishingStatusLabel:SetText("Fishing Status: " .. (fishingActive and "🎣 Active" : "⏹️ Stopped"))
        end
    end
end)()

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
    
    -- Load animations dengan delay
    task.wait(2)
    setupAnimations()
    
    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = animationsLoaded and "Auto Fishing V1 dengan Animasi loaded!" or "Auto Fishing V1 loaded (no animations)",
        Duration = 5,
        Image = 4483362458
    })
end)

-- Load configuration after a small delay
task.wait(1)
Rayfield:LoadConfiguration()

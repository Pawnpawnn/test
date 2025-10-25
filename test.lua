local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library dengan error handling
local Rayfield = nil
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI")
    return
end

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

-- Fish Threshold Variables
local obtainedFishUUIDs = {}
local obtainedLimit = 4000

local antiAFKEnabled = false
local AFKConnection = nil

local autoFavoriteEnabled = false

local autoFarmEnabled = false

local universalNoclip = false

local floatEnabled = false

local autoSellMythicEnabled = false



-- Auto Event Farm Variables
local autoTPEventEnabled = false
local savedCFrame = nil
local alreadyTeleported = false
local teleportTime = nil
local eventTarget = nil

-- Webhook Variables
local webhookEnabled = false
local webhookUrl = ""
local SelectedWebhookCategories = {"Secret"}
local LastCatchData = {}

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote, REEquipItem, RFSellItem

local floatPlatform = nil

-- Auto Farm Variables
local selectedIsland = "Fisherman Island"
local farmLocations = {
    ["Crater Islands"] = {
        CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1, -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
        CFrame.new(1057.28992, 33.0884132, 5133.79883, 0.833871782, 5.44149223e-08, 0.551958203, -6.58184218e-09, 1, -8.86416984e-08, -0.551958203, 7.02829084e-08, 0.833871782),
    },
    ["Tropical Grove"] = {
        CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1, -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407)
    },
    ["Fisherman Island"] = {
        CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1, 8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
        CFrame.new(-162.285294, 3.26205397, 2954.47412, -0.74356699, -1.93168272e-08, -0.668661416, 1.03873425e-08, 1, -4.04397653e-08, 0.668661416, -3.70152904e-08, -0.74356699),
    }
}

-- Player Variables
local ijumpEnabled = false
local AntiDrown_Enabled = false

-- Auto Favorite Variables
local GlobalFav = {
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedCategories = {},
    AutoFavoriteEnabled = false
}

-- Ultra Instant Bite Variables
local UltraBiteActive = false
local TotalCatches = 0
local StartTime = 0
local ChargeRod, StartMini, FinishFish, FishCaught

-- Fish Categories (Updated berdasarkan Tier)
local FishCategories = {
    ["Secret"] = {
        -- Tier 7 - Paling Langka
        "Blob Shark", "Great Christmas Whale", "Frostborn Shark", "Great Whale", 
        "Worm Fish", "Robot Kraken", "Giant Squid", "Ghost Worm Fish", 
        "Ghost Shark", "Queen Crab", "Orca", "Crystal Crab", 
        "Monster Shark", "Eerie Shark", "King Jelly", "Bone Whale",
        "Ancient Whale", "Mosasaur Shark", "Elshark Gran Maja",
        "Dead Zombie Shark", "Zombie Shark", "Megalodon", "Lochness Monster",
        "Zombie Megalodon"
    },
    ["Mythic"] = {
        -- Tier 6
        "Gingerbread Shark", "Loving Shark", "King Crab", "Blob Fish", 
        "Hermit Crab", "Luminous Fish", "Plasma Shark", "Crocodile",
        "Ancient Relic Crocodile", "Panther Eel", "Hybodus Shark",
        "Magma Shark", "Sharp One", "Mammoth Appafish",
        "Frankenstein Longsnapper", "Pumpkin Ray", "Dark Pumpkin Appafish"
    },
    ["Legendary"] = {
        -- Tier 5
        "Yellowfin Tuna", "Lake Sturgeon", "Ligned Cardinal Fish", "Saw Fish",
        "Abyss Seahorse", "Blueflame Ray", "Hammerhead Shark", 
        "Hawks Turtle", "Manta Ray", "Loggerhead Turtle", 
        "Prismy Seahorse", "Gingerbread Turtle", "Thresher Shark",
        "Dotted Stingray", "Strippled Seahorse", "Deep Sea Crab",
        "Ruby", "Temple Spokes Tuna", "Sacred Guardian Squid",
        "Manoai Statue Fish", "Pumpkin Carved Shark", "Wizard Stingray",
        "Crystal Salamander", "Pumpkin StoneTurtle"
    },
}

-- Weather Variables
local weatherActive = {}
local weatherData = {
    ["Storm"] = { duration = 900 },
    ["Cloudy"] = { duration = 900 },
    ["Snow"] = { duration = 900 },
    ["Wind"] = { duration = 900 },
    ["Radiant"] = { duration = 900 }
}

-- Ultra Bite Configuration - FIXED CYCLE SPEED
local Config = {
    CycleSpeed = 0.1, -- TETAP 0.1
    MaxPerformance = true
}

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

local function formatCurrency(amount)
    if not amount or amount <= 0 then
        return "$0"
    elseif amount >= 1000000 then
        return string.format("$%.2fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("$%.2fK", amount / 1000)
    else
        return "$" .. tostring(math.floor(amount))
    end
end

local function ScanActiveEvents()
    local events = {}
    local validEvents = {
        "megalodon", "whale", "kraken", "hunt", "Ghost Worm", "Mount Hallow",
        "admin", "Hallow Bay", "worm", "blackhole", "HalloweenFastTravel"
    }

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local name = obj.Name:lower()

            for _, keyword in ipairs(validEvents) do
                if name:find(keyword:lower()) and not name:find("boat") and not name:find("sharki") then
                    local exists = false
                    for _, e in ipairs(events) do
                        if e.Name == obj.Name then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        local pos = Vector3.new(0, 0, 0)

                        if obj:IsA("Model") then
                            pcall(function()
                                pos = obj:GetPivot().Position
                            end)
                        elseif obj:IsA("BasePart") then
                            pos = obj.Position
                        elseif obj:IsA("Folder") and #obj:GetChildren() > 0 then
                            local child = obj:GetChildren()[1]
                            if child:IsA("Model") then
                                pcall(function()
                                    pos = child:GetPivot().Position
                                end)
                            elseif child:IsA("BasePart") then
                                pos = child.Position
                            end
                        end

                        table.insert(events, {
                            Name = obj.Name,
                            Object = obj,
                            Position = pos
                        })
                    end

                    break
                end
            end
        end
    end
    return events
end

local function saveOriginalPosition()
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return false end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
        return true
    end
    return false
end

local function returnToOriginalPosition()
    if savedCFrame then
        local charFolder = workspace:FindFirstChild("Characters")
        if not charFolder then return end
        
        local char = charFolder:FindFirstChild(player.Name)
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = savedCFrame
        end
    end
end

local function teleportToEventPosition(position)
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
            task.wait(0.5)
            return true
        end
    end)
    
    return success, err
end

local function monitorAutoTP()
    task.spawn(function()
        while task.wait(5) do  -- Check every 5 seconds
            if autoTPEventEnabled then
                if not alreadyTeleported then
                    local events = ScanActiveEvents()
                    
                    if #events > 0 then
                        local event = events[1]  -- Take first available event
                        if saveOriginalPosition() then
                            local success, err = teleportToEventPosition(event.Position)
                            if success then
                                toggleFloat(true)
                                alreadyTeleported = true
                                teleportTime = tick()
                                eventTarget = event.Name
                                
                                Rayfield:Notify({
                                    Title = "🚀 Auto Event Farm",
                                    Content = "Teleported to: " .. event.Name,
                                    Duration = 5,
                                    Image = 4483362458
                                })
                            end
                        end
                    end
                else
                    -- Check if event is still active or 15 minutes passed
                    if teleportTime and (tick() - teleportTime >= 900) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        eventTarget = nil
                        
                        Rayfield:Notify({
                            Title = "🔄 Auto Event Farm",
                            Content = "Returned to original position (15min elapsed)",
                            Duration = 3,
                            Image = 4483362458
                        })
                    end
                end
            else
                if alreadyTeleported then
                    returnToOriginalPosition()
                    toggleFloat(false)
                    alreadyTeleported = false
                    teleportTime = nil
                    eventTarget = nil
                end
            end
        end
    end)
end

local function sendWebhook(fishName, fishTier, sellPrice, rarity)
    if not webhookEnabled or webhookUrl == "" then
        return
    end
    
    local success, err = pcall(function()
        local timestamp = DateTime.now():ToIsoDate()
        
        local embed = {
            {
                ["title"] = "🎣 FISH CAUGHT!",
                ["color"] = 65280,
                ["fields"] = {
                    {
                        ["name"] = "Fish Name",
                        ["value"] = fishName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Tier",
                        ["value"] = tostring(fishTier),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Rarity",
                        ["value"] = rarity,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Sell Price",
                        ["value"] = formatCurrency(sellPrice),
                        ["inline"] = true
                    }
                },
                ["footer"] = {
                    ["text"] = "Codepikk Premium • " .. timestamp
                },
                ["thumbnail"] = {
                    ["url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
                }
            }
        }
        
        local data = {
            ["embeds"] = embed,
            ["username"] = "Fish Notifier",
            ["avatar_url"] = "https://cdn.discordapp.com/attachments/1128833020023439502/1142635557613989948/Untitled_design.png"
        }
        
        local jsonData = HttpService:JSONEncode(data)
        
        local headers = {
            ["Content-Type"] = "application/json"
        }
        
        syn.request({
            Url = webhookUrl,
            Method = "POST",
            Headers = headers,
            Body = jsonData
        })
        
        print("📢 Webhook sent: " .. fishName)
    end)
    
    if not success then
        warn("Webhook error: " .. tostring(err))
    end
end

local function shouldSendWebhook(fishName, fishTier)
    if not webhookEnabled or #SelectedWebhookCategories == 0 then  -- GANTI DI SINI
        return false
    end
    
    -- Filter berdasarkan tier
    if fishTier then
        if table.find(SelectedWebhookCategories, "Secret") and fishTier == 7 then  -- GANTI DI SINI
            return true
        elseif table.find(SelectedWebhookCategories, "Mythic") and fishTier == 6 then  -- GANTI DI SINI
            return true
        elseif table.find(SelectedWebhookCategories, "Legendary") and fishTier == 5 then  -- GANTI DI SINI
            return true
        end
    end
    
    -- Filter berdasarkan nama
    local fishNameLower = string.lower(fishName)
    for category, fishList in pairs(FishCategories) do
        if table.find(SelectedWebhookCategories, category) then  -- GANTI DI SINI
            for _, targetFish in ipairs(fishList) do
                if fishNameLower == string.lower(targetFish) then
                    return true
                end
            end
        end
    end
    
    return false
end

local function setupRemotes()
    local success, err = pcall(function()
        net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
    end)

    if not success then
        success, err = pcall(function()
            net = ReplicatedStorage:WaitForChild("Net")
        end)
        
        if not success then
            warn("Failed to find net: " .. tostring(err))
            return false
        end
    end

    local function safeWaitForChild(parent, name, timeout)
        timeout = timeout or 5
        local start = tick()
        while tick() - start < timeout do
            local child = parent:FindFirstChild(name)
            if child then return child end
            task.wait(0.1)
        end
        warn("Timeout waiting for: " .. name)
        return nil
    end

    rodRemote = safeWaitForChild(net, "RF/ChargeFishingRod")
    miniGameRemote = safeWaitForChild(net, "RF/RequestFishingMinigameStarted")
    finishRemote = safeWaitForChild(net, "RE/FishingCompleted")
    equipRemote = safeWaitForChild(net, "RE/EquipToolFromHotbar")
    sellRemote = safeWaitForChild(net, "RF/SellAllItems")
    favoriteRemote = safeWaitForChild(net, "RE/FavoriteItem")
    REEquipItem = safeWaitForChild(net, "RE/EquipItem")
    RFSellItem = safeWaitForChild(net, "RF/SellItem")
    
    -- Setup Ultra Bite Remotes
    ChargeRod = rodRemote
    StartMini = miniGameRemote
    FinishFish = finishRemote
    FishCaught = safeWaitForChild(net, "RE/FishCaught") or safeWaitForChild(net, "RF/FishCaught")
    
    return true
end

-- ===================================
-- ========== ULTRA INSTANT BITE =====
-- ===================================

local function ExecuteUltraBiteCycle()
    local catches = 0
    
    -- AUTO FISHING COMPLETE PROCESS - INSTANT BITE
    pcall(function()
        -- STEP 1: AUTO EQUIP
        if equipRemote then
            equipRemote:FireServer(1) -- Equip fishing rod
        end
        
        -- STEP 2: AUTO CHARGE/LEMPAR
        if ChargeRod then
            ChargeRod:InvokeServer(tick()) -- Instant charge
        end
        
        -- STEP 3: AUTO MINIGAME - INSTANT BITE BYPASS!
        if StartMini then
            -- BYPASS MENUNGGU IKAN MAKAN UMPAN
            -- Langsung mulai minigame dengan perfect score
            StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
        end
        
        -- STEP 4: AUTO FINISH COMPLETE
        if FinishFish then
            FinishFish:FireServer() -- Complete fishing
        end
        
        -- STEP 5: AUTO FISH CAUGHT
        if FishCaught then
            -- Dapat ikan rare
            FishCaught:FireServer({
                Name = "⚡ INSTANT BITE FISH",
                Tier = math.random(5, 7),
                SellPrice = math.random(15000, 40000),
                Rarity = "LEGENDARY"
            })
            catches = 1
        end
        
        -- EXTRA: MASS CATCH FOR MAX PERFORMANCE
        if Config.MaxPerformance and FishCaught then
            for i = 1, 2 do -- Extra 2 fish
                FishCaught:FireServer({
                    Name = "🚀 ULTRA FISH",
                    Tier = math.random(6, 7),
                    SellPrice = math.random(20000, 50000),
                    Rarity = "MYTHIC"
                })
                catches = catches + 1
            end
        end
    end)
    
    return catches
end

local function StartUltraInstantBite()
    if UltraBiteActive then return end
    
    print("🚀 ACTIVATING ULTRA INSTANT BITE...")
    
    UltraBiteActive = true
    TotalCatches = 0
    StartTime = tick()
    
    -- MAIN ULTRA BITE LOOP
    task.spawn(function()
        while UltraBiteActive do
            local cycleStart = tick()
            
            -- EXECUTE COMPLETE FISHING CYCLE
            local catchesThisCycle = ExecuteUltraBiteCycle()
            TotalCatches = TotalCatches + catchesThisCycle
            
            -- ULTRA FAST CYCLE TIMING - FIXED 0.1s
            local cycleTime = tick() - cycleStart
            local waitTime = math.max(0.1 - cycleTime, 0.01) -- TETAP 0.1
            
            task.wait(waitTime)
        end
    end)
    
    -- PERFORMANCE MONITOR
    task.spawn(function()
        while UltraBiteActive do
            local elapsed = tick() - StartTime
            local currentRate = math.floor(TotalCatches / math.max(elapsed, 1))
            
            pcall(function()
                Window:SetWindowName("WAKWIK ULTRA | " .. currentRate .. " FISH/SEC")
            end)
            
            task.wait(0.5)
        end
    end)
    
    Rayfield:Notify({
        Title = "🚀 ULTRA INSTANT BITE ACTIVATED",
        Content = "LEMPAR LANGSUNG SAMBAR! Speed: 0.1s", -- TAMPILKAN SPEED TETAP
        Duration = 5
    })
end

local function StopUltraInstantBite()
    if not UltraBiteActive then return end
    
    UltraBiteActive = false
    
    local totalTime = tick() - StartTime
    local avgRate = math.floor(TotalCatches / math.max(totalTime, 1))
    
    Rayfield:Notify({
        Title = "🛑 ULTRA BITE STOPPED",
        Content = "Total: " .. TotalCatches .. " fish | Avg: " .. avgRate .. "/sec",
        Duration = 5
    })
    
    pcall(function()
        Window:SetWindowName("WAKWIK ULTRA INSTANT BITE")
    end)
end

-- ===================================
-- ========== ENHANCE FISHING ========
-- ===================================

-- 🚀 STABLE FISHING SYSTEM - OPTIMIZED
local StableFishing = {
    Enabled = false,
    SpeedMultiplier = 1.0,
    PerfectCast = true,
    CastCount = 0,
    FixedSpeed = 0.4
}

local function updateRodModifiers()
    local char = player.Character
    if not char then return 1.0 end
    
    local equippedRod = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then
            equippedRod = tool
            break
        end
    end
    
    local speedMultiplier = 1.0
    if equippedRod then
        for attrName, attrValue in pairs(equippedRod:GetAttributes()) do
            local nameLower = string.lower(tostring(attrName))
            
            if nameLower:find("reel") and nameLower:find("faster") then
                local speedBonus = tonumber(string.match(attrValue, "%d+")) or 
                                 tonumber(string.match(attrName, "%d+")) or 0
                if speedBonus > 0 then
                    speedMultiplier = math.max(0.3, 1.0 - (speedBonus / 100))
                end
            end
        end
    end
    
    StableFishing.SpeedMultiplier = speedMultiplier
    return speedMultiplier
end

-- 🎯 OPTIMIZED FISHING LOOP - LESS DETECTABLE
local function stableFishingLoop()
    while StableFishing.Enabled and task.wait() do
        local success, err = pcall(function()
            if not StableFishing.Enabled then return end
            
            StableFishing.CastCount = StableFishing.CastCount + 1
            
            updateRodModifiers()
            
            -- PHASE 1: EQUIP & CAST
            equipRemote:FireServer(1)
            task.wait(0.12 * StableFishing.SpeedMultiplier)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.08 * StableFishing.SpeedMultiplier)
            
            -- PHASE 2: RANDOMIZED CAST
            local x, y
            if StableFishing.PerfectCast then
                x = -0.7499996 + (math.random(-3, 3) / 10000000)
                y = 1 + (math.random(-3, 3) / 10000000)
            else
                x = math.random(-80, 80) / 100
                y = math.random(70, 95) / 100
            end
            
            miniGameRemote:InvokeServer(x, y)
            
            -- PHASE 3: RANDOMIZED SUCCESS
            task.spawn(function()
                local waitTimes = {0.0003, 0.0005, 0.0007, 0.0009, 0.0011}
                
                for i = 1, 4 do
                    if not StableFishing.Enabled then break end
                    
                    pcall(function()
                        finishRemote:FireServer(true)
                    end)
                    
                    local waitTime = waitTimes[math.random(1, #waitTimes)]
                    task.wait(waitTime)
                end
                
                -- Final cleanup dengan delay acak
                task.wait(math.random(5, 15) / 1000)
                pcall(function()
                    finishRemote:FireServer()
                end)
            end)
            
            -- PHASE 4: RANDOMIZED COOLDOWN
            local cooldown = math.random(4, 8) / 100 * StableFishing.SpeedMultiplier
            task.wait(math.max(0.03, cooldown))
            
        end)
        
        if not success then
            warn("Fishing Error: " .. tostring(err))
            task.wait(0.5)
        end
    end
end

-- ===================================
-- ========== FISH THRESHOLD =========
-- ===================================

local function monitorFishThreshold()
    task.spawn(function()
        while task.wait(1) do
            if (StableFishing.Enabled or UltraBiteActive) and #obtainedFishUUIDs >= obtainedLimit then
                Rayfield:Notify({
                    Title = "Fish Threshold",
                    Content = "Selling all fishes...",
                    Duration = 3,
                    Image = 4483362458
                })
                pcall(function() sellRemote:InvokeServer() end)
                obtainedFishUUIDs = {}
                task.wait(2)
            end
        end
    end)
end

-- Setup fish obtained listener
task.spawn(function()
    local success, remoteV2 = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and remoteV2 then
        remoteV2.OnClientEvent:Connect(function(_, _, data)
            if data and data.InventoryItem and data.InventoryItem.UUID then
                table.insert(obtainedFishUUIDs, data.InventoryItem.UUID)
            end
        end)
    end
end)

-- Start Stable Fishing
local function startStableFishing()
    if StableFishing.Enabled then
        return
    end
    
    StableFishing.Enabled = true
    StableFishing.CastCount = 0
    
    task.spawn(stableFishingLoop)
    
    Rayfield:Notify({
        Title = "🚀 Auto Fishing",
        Content = "Started successfully",
        Duration = 3,
        Image = 4483362458
    })
end

local function stopStableFishing()
    StableFishing.Enabled = false
    
    Rayfield:Notify({
        Title = "🛑 Auto Fishing Stopped",
        Content = "Fishing system disabled",
        Duration = 3
    })
end

-- ===================================
-- ========== SISTEM AUTO FAVORITE ===
-- ===================================

local AutoFavorite = {
    Enabled = false,
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedCategories = {"Secret"},
    ScanCooldown = 5, -- detik antara scan
    LastScanTime = 0
}

-- Build database ikan yang lengkap
local function buildFishDatabase()
    AutoFavorite.FishIdToName = {}
    AutoFavorite.FishNameToId = {}
    AutoFavorite.FishNames = {}
    
    local success, result = pcall(function()
        local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
        if not ItemsFolder then
            warn("Folder Items tidak ditemukan di ReplicatedStorage")
            return false
        end
        
        for _, item in pairs(ItemsFolder:GetChildren()) do
            local ok, data = pcall(function()
                return require(item)
            end)
            
            if ok and data and data.Data then
                if data.Data.Type == "Fishes" then
                    local id = tostring(data.Data.Id)
                    local name = tostring(data.Data.Name)
                    local tier = tonumber(data.Data.Tier) or 1
                    
                    AutoFavorite.FishIdToName[id] = {
                        name = name,
                        tier = tier,
                        displayName = data.Data.DisplayName or name
                    }
                    AutoFavorite.FishNameToId[name] = id
                    AutoFavorite.FishNameToId[string.lower(name)] = id
                    table.insert(AutoFavorite.FishNames, name)
                    
                    -- Tambahkan display name jika berbeda
                    if data.Data.DisplayName and data.Data.DisplayName ~= name then
                        AutoFavorite.FishNameToId[data.Data.DisplayName] = id
                        AutoFavorite.FishNameToId[string.lower(data.Data.DisplayName)] = id
                    end
                end
            end
        end
        return true
    end)
    
    if not success then
        warn("Gagal membangun database ikan: " .. tostring(result))
        return false
    end
    
    print(string.format("✅ Database ikan berhasil: %d ikan dimuat", #AutoFavorite.FishNames))
    return true
end

-- Ekstrak data ikan dari slot inventory berdasarkan struktur yang ada
local function extractFishDataFromSlot(slot)
    local fishData = {
        uuid = nil,
        name = nil,
        tier = nil,
        isFavorited = false
    }
    
    -- Cek atribut di slot langsung
    fishData.uuid = slot:GetAttribute("UUID") or 
                   slot:GetAttribute("ItemUUID")
    
    -- Cek Inner frame
    local inner = slot:FindFirstChild("Inner")
    if inner then
        -- Dapatkan UUID dari atribut Inner
        if not fishData.uuid then
            fishData.uuid = inner:GetAttribute("UUID") or 
                           inner:GetAttribute("ItemUUID")
        end
        
        -- Cek Tags untuk nama dan status favorite
        local tags = inner:FindFirstChild("Tags")
        if tags then
            -- Dapatkan nama ikan dari ItemName
            local itemName = tags:FindFirstChild("ItemName")
            if itemName and itemName:IsA("StringValue") then
                fishData.name = itemName.Value
            end
            
            -- Cek apakah sudah di favorite
            local favorited = tags:FindFirstChild("Favorited")
            if favorited and favorited:IsA("BoolValue") then
                fishData.isFavorited = favorited.Value == true
            end
            
            -- Dapatkan ID ikan dari ItemId
            local itemId = tags:FindFirstChild("ItemId")
            if itemId and itemId:IsA("StringValue") and itemId.Value ~= "" then
                local fishInfo = AutoFavorite.FishIdToName[itemId.Value]
                if fishInfo then
                    fishData.name = fishData.name or fishInfo.name
                    fishData.tier = fishInfo.tier
                end
            end
        end
    end
    
    -- Jika punya nama tapi tidak ada tier, cari di database
    if fishData.name and not fishData.tier then
        local fishId = AutoFavorite.FishNameToId[fishData.name] or AutoFavorite.FishNameToId[string.lower(fishData.name)]
        if fishId then
            local fishInfo = AutoFavorite.FishIdToName[fishId]
            if fishInfo then
                fishData.tier = fishInfo.tier
            end
        end
    end
    
    return (fishData.uuid and fishData.name) and fishData or nil
end

-- Tentukan apakah ikan harus di favorite berdasarkan kategori dan tier
local function shouldFavoriteFish(fishName, fishTier)
    if not fishName or not AutoFavorite.SelectedCategories or #AutoFavorite.SelectedCategories == 0 then
        return false
    end
    
    -- Filter berdasarkan tier (paling akurat)
    if fishTier then
        if table.find(AutoFavorite.SelectedCategories, "Secret") and fishTier == 7 then
            return true
        elseif table.find(AutoFavorite.SelectedCategories, "Mythic") and fishTier == 6 then
            return true
        elseif table.find(AutoFavorite.SelectedCategories, "Legendary") and fishTier == 5 then
            return true
        end
    end
    
    -- Fallback berdasarkan nama
    local fishNameLower = string.lower(fishName)
    for category, fishList in pairs(FishCategories) do
        if table.find(AutoFavorite.SelectedCategories, category) then
            for _, targetFish in ipairs(fishList) do
                if fishNameLower == string.lower(targetFish) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Favorite ikan berdasarkan UUID
local function favoriteFishByUUID(uuid, fishName)
    if not uuid or not favoriteRemote then
        return false
    end
    
    local success, err = pcall(function()
        favoriteRemote:FireServer(uuid)
        return true
    end)
    
    if success then
        print(string.format("⭐ Difavorite: %s (UUID: %s)", fishName, uuid))
        return true
    else
        warn(string.format("Gagal memfavorite %s: %s", fishName, tostring(err)))
        return false
    end
end

-- Scan dan favorite ikan yang ada di inventory
local function scanAndFavoriteExistingFish()
    if not AutoFavorite.Enabled then 
        Rayfield:Notify({
            Title = "Auto Favorite",
            Content = "Silakan aktifkan Auto Favorite terlebih dahulu!",
            Duration = 3,
            Image = 4483362458
        })
        return 
    end
    
    -- Cek cooldown
    if tick() - AutoFavorite.LastScanTime < AutoFavorite.ScanCooldown then
        Rayfield:Notify({
            Title = "Auto Favorite",
            Content = "Tunggu sebentar sebelum scan lagi",
            Duration = 2,
            Image = 4483362458
        })
        return
    end
    
    AutoFavorite.LastScanTime = tick()
    
    Rayfield:Notify({
        Title = "🔍 Memindai Inventory (Not Working now)",
        Content = "Mengecek ikan yang ada...",
        Duration = 2,
        Image = 4483362458
    })
    
    local favoritedCount = 0
    local scannedCount = 0
    local skippedCount = 0
    
    task.spawn(function()
        local success, err = pcall(function()
            -- Cek Backpack GUI
            local backpackGui = player.PlayerGui:FindFirstChild("Backpack")
            if not backpackGui then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Backpack GUI tidak ditemukan!",
                    Duration = 3
                })
                return
            end
            
            local display = backpackGui:FindFirstChild("Display")
            if not display then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Display tidak ditemukan di Backpack!",
                    Duration = 3
                })
                return
            end
            
            -- Scan semua slot di Display
            for _, slot in pairs(display:GetChildren()) do
                if slot:IsA("Frame") or slot:IsA("ImageButton") then
                    scannedCount = scannedCount + 1
                    
                    local fishData = extractFishDataFromSlot(slot)
                    if fishData then
                        if fishData.isFavorited then
                            skippedCount = skippedCount + 1
                        elseif shouldFavoriteFish(fishData.name, fishData.tier) then
                            if favoriteFishByUUID(fishData.uuid, fishData.name) then
                                favoritedCount = favoritedCount + 1
                                task.wait(0.15) -- Mencegah rate limiting
                            end
                        end
                    end
                end
            end
            
        end)
        
        if not success then
            warn("Error saat scan inventory: " .. tostring(err))
            Rayfield:Notify({
                Title = "Error Scan",
                Content = "Terjadi error saat memindai inventory",
                Duration = 3
            })
        end
        
        -- Laporkan hasil
        task.wait(1)
        local message = string.format("Slot dipindai: %d\nDifavorite: %d\nDilewati: %d", 
                                    scannedCount, favoritedCount, skippedCount)
        
        if favoritedCount > 0 then
            Rayfield:Notify({
                Title = "✅ Scan Selesai",
                Content = message,
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "ℹ️ Scan Selesai",
                Content = message,
                Duration = 4,
                Image = 4483362458
            })
        end
        
        -- Debug info
        print(string.format("📊 HASIL SCAN: %d slot, %d difavorite, %d dilewati", 
                          scannedCount, favoritedCount, skippedCount))
    end)
end

-- Setup listener untuk ikan yang baru ditangkap
local function setupAutoFavoriteListener()
    local success, REObtainedNewFishNotification = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
            if not AutoFavorite.Enabled then return end

            local uuid = data.InventoryItem and data.InventoryItem.UUID
            if not uuid then return end

            local fishInfo = AutoFavorite.FishIdToName[tostring(itemId)]
            if not fishInfo then return end
            
            local fishName = fishInfo.name
            local fishTier = fishInfo.tier

            if shouldFavoriteFish(fishName, fishTier) then
                task.wait(0.2) -- Delay kecil untuk memastikan server memproses tangkapan
                if favoriteFishByUUID(uuid, fishName) then
                    Rayfield:Notify({
                        Title = "⭐ Auto Favorite",
                        Content = string.format("%s (Tier %d)", fishName, fishTier),
                        Duration = 2,
                        Image = 4483362458
                    })
                end
            end
        end)
        
        print("✅ Listener Auto Favorite berhasil di setup")
        return true
    else
        warn("❌ Gagal setup listener Auto Favorite")
        return false
    end
end

-- Inisialisasi sistem auto favorite
local function initializeAutoFavorite()
    -- Build database ikan dulu
    if not buildFishDatabase() then
        Rayfield:Notify({
            Title = "Error Auto Favorite",
            Content = "Gagal memuat database ikan",
            Duration = 5,
            Image = 4483362458
        })
        return false
    end
    
    -- Setup listener untuk tangkapan baru
    if not setupAutoFavoriteListener() then
        Rayfield:Notify({
            Title = "Peringatan Auto Favorite",
            Content = "Auto favorite live mungkin tidak bekerja",
            Duration = 5,
            Image = 4483362458
        })
    end
    
    return true
end



-- ===================================
-- ========== AUTO SELL ==============
-- ===================================

local function sellNow()
    local success, err = pcall(function()
        sellRemote:InvokeServer()
    end)

    if success then
        Rayfield:Notify({
            Title = "Auto Sell",
            Content = "Successfully sold items!",
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Auto Sell Failed",
            Content = "Error: " .. tostring(err),
            Duration = 3
        })
    end
end

-- ===================================
-- ========== WEATHER SYSTEM =========
-- ===================================

local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

local function autoBuyWeather(weatherType)
    local purchaseRemote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net")
        :WaitForChild("RF/PurchaseWeatherEvent")

    task.spawn(function()
        while weatherActive[weatherType] do
            pcall(function()
                purchaseRemote:InvokeServer(weatherType)
                
                task.wait(weatherData[weatherType].duration)
                local randomWait = randomDelay(2, 8)
                task.wait(randomWait)
            end)
            task.wait(1)
        end
    end)
end

-- ===================================
-- ========== FLOATING PLATFORM ======
-- ===================================

local function toggleFloat(enabled)
    if enabled then
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder:FindFirstChild(player.Name)
        if not char then 
            return 
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            return 
        end

        floatPlatform = Instance.new("Part")
        floatPlatform.Anchored = true
        floatPlatform.Size = Vector3.new(8, 1, 8)
        floatPlatform.Transparency = 0.8
        floatPlatform.Material = Enum.Material.Neon
        floatPlatform.Color = Color3.fromRGB(0, 255, 255)
        floatPlatform.CanCollide = true
        floatPlatform.Name = "FloatPlatform_" .. math.random(1000,9999)
        floatPlatform.Parent = workspace

        task.spawn(function()
            while floatPlatform and floatPlatform.Parent and task.wait(0.2) do
                pcall(function()
                    if char and hrp then
                        floatPlatform.Position = hrp.Position - Vector3.new(0, 4, 0)
                    end
                end)
            end
        end)

    else
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
    end
end

-- ===================================
-- ========== SERVER HOP =============
-- ===================================

local function Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end

local function QuickServerHop()
    local placeId = game.PlaceId
    local servers = {}
    
    Rayfield:Notify({
        Title = "Quick Server Hop",
        Content = "Finding available server...",
        Duration = 3,
        Image = 4483362458
    })
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer, player)
    else
        Rayfield:Notify({
            Title = "Server Hop Failed",
            Content = "No servers available!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== BOOST FPS ==============
-- ===================================

local function BoostFPS()
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Optimizing performance...",
        Duration = 3,
        Image = 4483362458
    })
    
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        end
    end

    local Lighting = game:GetService("Lighting")
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    
    Rayfield:Notify({
        Title = "Success",
        Content = "Performance optimized!",
        Duration = 3,
        Image = 4483362458
    })
end

-- ===================================
-- ========== TELEPORT SYSTEMS =======
-- ===================================

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

local function teleportToIsland(islandName)
    local pos = islandCoords[islandName]
    if not pos then 
        return
    end
    
    local success, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end)

    if success then
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Teleported to " .. islandName,
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- ===================================
-- ========== ANTI-AFK ===============
-- ===================================

local function toggleAntiAFK()
    antiAFKEnabled = not antiAFKEnabled
    
    if antiAFKEnabled then
        -- Hentikan connection lama jika ada
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        -- Buat connection baru
        AFKConnection = player.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end)
        
        Rayfield:Notify({
            Title = "Anti-AFK Enabled",
            Content = "Anti-AFK system activated",
            Duration = 3,
            Image = 4483362458
        })
    else
        -- Matikan Anti-AFK
        if AFKConnection then
            AFKConnection:Disconnect()
            AFKConnection = nil
        end
        
        Rayfield:Notify({
            Title = "Anti-AFK Disabled", 
            Content = "Anti-AFK system deactivated",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- ===================================
-- ========== AUTO FARM ==============
-- ===================================

local function startAutoFarmLoop()
    while autoFarmEnabled and task.wait(2) do
        local success, err = pcall(function()
            local islandSpots = farmLocations[selectedIsland]
            if type(islandSpots) == "table" and #islandSpots > 0 then
                local location = islandSpots[math.random(1, #islandSpots)]
                
                local charFolder = workspace:FindFirstChild("Characters")
                if not charFolder then return end
                
                local char = charFolder:FindFirstChild(player.Name)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = location
                    task.wait(2)
                end
            end
        end)
        
        if not success then
            warn("Auto Farm Error: " .. tostring(err))
        end
    end
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Codepikk Premium++",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Patch Note Tab
local PatchNote = Window:CreateTab("📝 Patch Notes", 4483362458)

PatchNote:CreateSection("📝 Patch Notes")

PatchNote:CreateLabel("🔄 Version: v3.1.5")
PatchNote:CreateLabel("📅 Release Date: 25-10-25")

PatchNote:CreateButton({
    Name = "📋 Show Patch Notes",
    Callback = function()
        Rayfield:Notify({
            Title = "📝 Patch Notes v3.1.5",
            Content = [[

🐛 FIXES:
• Auto Teleport Event now works

🚀 NEW FEATURES:
• Webhook Discord

🗑️ REMOVED:
• - Nothing in here rn.
            ]],
            Duration = 15,
            Image = 4483362458
        })
    end,
})

-- Main Tab
local MainTab = Window:CreateTab("🔥 Main Tab", 4483362458)

MainTab:CreateSection("🚀 Auto Fishing x2")

MainTab:CreateToggle({
    Name = "⚡ Auto Fishing x2",
    CurrentValue = false,
    Flag = "UltraBiteToggle",
    Callback = function(Value)
        if Value then
            StartUltraInstantBite()
        else
            StopUltraInstantBite()
        end
    end,
})

MainTab:CreateToggle({
    Name = "🚀 Max Performance",
    CurrentValue = true,
    Flag = "MaxPerformanceToggle",
    Callback = function(Value)
        Config.MaxPerformance = Value
    end,
})

MainTab:CreateSection("Auto Fishing")

MainTab:CreateToggle({
    Name = "🚀 Auto Fishing",
    CurrentValue = false,
    Flag = "StableFishingToggle",
    Callback = function(Value)
        if Value then
            startStableFishing()
        else
            stopStableFishing()
        end
    end,
})

MainTab:CreateToggle({
    Name = "🎯 Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        StableFishing.PerfectCast = Value
    end,
})

MainTab:CreateSection("Auto Sell fish")

MainTab:CreateInput({
    Name = "Auto Sell fish Custom",
    PlaceholderText = "Default: 4000 fish",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            obtainedLimit = num
        end
    end,
})

MainTab:CreateButton({
    Name = "💰 Sell Now",
    Callback = sellNow,
})

MainTab:CreateSection("Sistem Auto Favorite")

MainTab:CreateToggle({
    Name = "⭐ Auto Fav While Fishing",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        AutoFavorite.Enabled = Value
        
        if Value then
            -- Inisialisasi jika belum dilakukan
            if #AutoFavorite.FishNames == 0 then
                initializeAutoFavorite()
            end
            
            local categories = #AutoFavorite.SelectedCategories > 0 and table.concat(AutoFavorite.SelectedCategories, ", ") or "Tidak ada"
            Rayfield:Notify({
                Title = "Auto Favorite AKTIF",
                Content = "Memfavorite: " .. categories,
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Favorite NONAKTIF",
                Content = "Auto favorite dimatikan",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

MainTab:CreateDropdown({
    Name = "Select Category Rarity",
    Options = {"Secret", "Mythic", "Legendary"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FavoriteCategoryDropdown",
    Callback = function(Options)
        AutoFavorite.SelectedCategories = Options
        
        local categories = #Options > 0 and table.concat(Options, ", ") or "Tidak ada"
        Rayfield:Notify({
            Title = "Kategori Diupdate",
            Content = "Dipilih: " .. categories,
            Duration = 2,
            Image = 4483362458
        })
    end,
})


MainTab:CreateSection("Auto Farm")

local islandOptions = {
    "Crater Islands",
    "Tropical Grove", 
    "Fisherman Island"
}

MainTab:CreateDropdown({
    Name = "Select Farm Island",
    Options = islandOptions,
    CurrentOption = "Fisherman Island",
    Flag = "FarmIslandDropdown",
    Callback = function(Option)
        selectedIsland = Option
    end,
})

MainTab:CreateToggle({
    Name = "🌾 Start Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            task.spawn(startAutoFarmLoop)
        end
    end,
})

MainTab:CreateSection("Auto Buy Weather")

MainTab:CreateDropdown({
    Name = "Auto Buy Weather",
    Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "WeatherDropdown",
    Callback = function(Options)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(Options, weatherType) then
                weatherActive[weatherType] = false
            end
        end
        
        for _, weatherType in pairs(Options) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                autoBuyWeather(weatherType)
            end
        end
    end,
})

MainTab:CreateSection("Auto Enchant Rod")

MainTab:CreateButton({
    Name = "🔮 Auto Enchant Rod",
    Callback = function()
        local ENCHANT_POSITION = Vector3.new(3231, -1303, 1402)
        local char = workspace:WaitForChild("Characters"):FindFirstChild(player.Name)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Rayfield:Notify({
                Title = "Auto Enchant Rod",
                Content = "Failed to get character HRP.",
                Duration = 3
            })
            return
        end

        Rayfield:Notify({
            Title = "Preparing Enchant...",
            Content = "Please manually place Enchant Stone into slot 5 before we begin...",
            Duration = 5,
            Image = 4483362458
        })

        task.wait(3)

        local slot5 = player.PlayerGui.Backpack.Display:GetChildren()[10]
        local itemName = slot5 and slot5:FindFirstChild("Inner") and slot5.Inner:FindFirstChild("Tags") and slot5.Inner.Tags:FindFirstChild("ItemName")

        if not itemName or not itemName.Text:lower():find("enchant") then
            Rayfield:Notify({
                Title = "Auto Enchant Rod",
                Content = "Slot 5 does not contain an Enchant Stone.",
                Duration = 3
            })
            return
        end

        Rayfield:Notify({
            Title = "Enchanting...",
            Content = "It is in the process of Enchanting, please wait until the Enchantment is complete",
            Duration = 7,
            Image = 4483362458
        })

        local originalPosition = hrp.Position
        task.wait(1)
        hrp.CFrame = CFrame.new(ENCHANT_POSITION + Vector3.new(0, 5, 0))
        task.wait(1.2)

        local equipRod = net:WaitForChild("RE/EquipToolFromHotbar")
        local activateEnchant = net:WaitForChild("RE/ActivateEnchantingAltar")

        pcall(function()
            equipRod:FireServer(5)
            task.wait(0.5)
            activateEnchant:FireServer()
            task.wait(7)
            Rayfield:Notify({
                Title = "Enchant",
                Content = "Successfully Enchanted!",
                Duration = 3,
                Image = 4483362458
            })
        end)

        task.wait(0.9)
        hrp.CFrame = CFrame.new(originalPosition + Vector3.new(0, 3, 0))
    end
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

TeleportTab:CreateSection("TELEPORT TO ISLAND")

local islandList = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

for _, islandName in ipairs(islandList) do
    TeleportTab:CreateButton({
        Name = islandName,
        Callback = function()
            teleportToIsland(islandName)
        end,
    })
end


TeleportTab:CreateSection("TELEPORT TO ACTIVE EVENTS (Only Active Event)")

-- =============================
-- EVENT UI HANDLER (AUTO + REFRESH)
-- =============================

local eventButtons = {}
local lastEventSnapshot = {}

-- Utility untuk cek perubahan (soft update)
local function hasEventChanged(newEvents)
    if #newEvents ~= #lastEventSnapshot then
        return true
    end
    for i, v in ipairs(newEvents) do
        if not lastEventSnapshot[i] or lastEventSnapshot[i].Name ~= v.Name then
            return true
        end
    end
    return false
end

-- Render ulang UI event
local function updateEventButtons()
    local events = ScanActiveEvents() or {}

    -- Hapus button lama
    for _, b in pairs(eventButtons) do
        pcall(function() b:Destroy() end) -- Tambah pcall untuk keamanan
    end
    table.clear(eventButtons)

    -- HEADER (gunakan Paragraph atau skip)
    local header = TeleportTab:CreateParagraph({
        Title = "Active Events",
        Content = "Auto-refreshing every 5 seconds"
    })
    table.insert(eventButtons, header)

    -- Jika ada event
    for _, event in ipairs(events) do
        local btn = TeleportTab:CreateButton({
            Name = "📍 " .. event.Name,
            Callback = function()
                teleportToEventPosition(event.Position)
            end
        })
        table.insert(eventButtons, btn)
    end

    -- Jika tidak ada event
    if #events == 0 then
        local noEvent = TeleportTab:CreateParagraph({
            Title = "No Events",
            Content = "📭 No active events found"
        })
        table.insert(eventButtons, noEvent)
    end

    -- Update snapshot
    lastEventSnapshot = events
end

-- Manual refresh button (di atas)
local refreshBtn = TeleportTab:CreateButton({
    Name = "🔄 Refresh Active Events",
    Callback = function()
        updateEventButtons()
        Rayfield:Notify({
            Title = "Event Scanner",
            Content = "✅ Events refreshed successfully",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- Auto scan setiap 5 detik (soft update)
task.spawn(function()
    while task.wait(5) do
        local events = ScanActiveEvents() or {}
        if hasEventChanged(events) then
            updateEventButtons()
        end
    end
end)

-- render pertama kali
updateEventButtons()




-- Manual refresh button (di atas)
local refreshBtn = TeleportTab:CreateButton({
    Name = "🔄 Refresh Active Events",
    Callback = function()
        updateEventButtons()
        Rayfield:Notify({
            Title = "Event Scanner",
            Content = "✅ Events refreshed successfully",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- Auto scan setiap 5 detik (soft update)
task.spawn(function()
    while task.wait(5) do
        local events = ScanActiveEvents() or {}
        if hasEventChanged(events) then
            updateEventButtons()
        end
    end
end)

updateEventButtons()


-- Webhook Tab
local WebhookTab = Window:CreateTab("📣 Webhook", 4483362458)

WebhookTab:CreateSection("Send Webhook")

WebhookTab:CreateToggle({
    Name = "🔔 Enable Webhook Notifications",
    CurrentValue = false,
    Flag = "WebhookToggle",
    Callback = function(Value)
        webhookEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Webhook Enabled",
                Content = "Webhook notifications activated",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Webhook Disabled",
                Content = "Webhook notifications deactivated", 
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

WebhookTab:CreateInput({
    Name = "Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        webhookUrl = Text
        if Text ~= "" then
            Rayfield:Notify({
                Title = "Webhook URL Set",
                Content = "Webhook URL saved successfully",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

WebhookTab:CreateDropdown({
    Name = "Webhook Categories",
    Options = {"Secret", "Mythic", "Legendary"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "WebhookCategoryDropdown",
    Callback = function(Options)
        SelectedWebhookCategories = Options
        local categories = #Options > 0 and table.concat(Options, ", ") or "None"
        Rayfield:Notify({
            Title = "Webhook Categories Updated",
            Content = "Notifications for: " .. categories,
            Duration = 3,
            Image = 4483362458
        })
    end,
})

WebhookTab:CreateButton({
    Name = "🧪 Test Webhook",
    Callback = function()
        if webhookUrl == "" then
            Rayfield:Notify({
                Title = "Webhook Error",
                Content = "Please set webhook URL first",
                Duration = 3,
                Image = 4483362458
            })
            return
        end
        
        sendWebhook("Test Fish", 7, 25000, "Secret")
        Rayfield:Notify({
            Title = "Webhook Test",
            Content = "Test notification sent!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Player Tab
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSection("Player Features")

PlayerTab:CreateToggle({
    Name = "🔓 No Clip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        universalNoclip = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "🎈 Enable Float",
    CurrentValue = false,
    Flag = "FloatToggle",
    Callback = function(Value)
        floatEnabled = Value
        toggleFloat(Value)
    end,
})

PlayerTab:CreateToggle({
    Name = "🏃 Infinity Jump",
    CurrentValue = false,
    Flag = "InfinityJumpToggle",
    Callback = function(Value)
        ijumpEnabled = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "🌊 Anti Drown",
    CurrentValue = false,
    Flag = "AntiDrownToggle",
    Callback = function(Value)
        AntiDrown_Enabled = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 20,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.WalkSpeed = Value
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 200},
    Increment = 10,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = Value
            end
        end
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Miscellaneous")

MiscTab:CreateToggle({
    Name = "⏰ Anti-AFK System",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        toggleAntiAFK()
    end,
})

MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

MiscTab:CreateSection("Server Hop")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        Rejoin()
    end,
})

MiscTab:CreateButton({
    Name = "⚡ Quick Server Hop",
    Callback = function()
        QuickServerHop()
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("🔧 Settings", 4483362458)

SettingsTab:CreateSection("Configuration")

SettingsTab:CreateKeybind({
    Name = "UI Keybind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function(Keybind)
        Window:SetKeybind(Keybind)
    end,
})

SettingsTab:CreateButton({
    Name = "💾 Save Configuration",
    Callback = function()
        Rayfield:SaveConfiguration()
    end,
})

SettingsTab:CreateButton({
    Name = "📂 Load Configuration",
    Callback = function()
        Rayfield:LoadConfiguration()
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================


-- NoClip Loop
RunService.Stepped:Connect(function()
    if not universalNoclip then return end

    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinity Jump Handler
UserInputService.JumpRequest:Connect(function()
    if ijumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Anti Drown System
local rawmt = getrawmetatable(game)
setreadonly(rawmt, false)
local oldNamecall = rawmt.__namecall

rawmt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if tostring(self) == "URE/UpdateOxygen" and method == "FireServer" and AntiDrown_Enabled then
        return nil
    end

    return oldNamecall(self, ...)
end)

setreadonly(rawmt, true)

-- Setup listener untuk ikan yang baru ditangkap
local function setupWebhookListener()
    local success, REObtainedNewFishNotification = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if success and REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
            if not webhookEnabled then return end

            local fishInfo = AutoFavorite.FishIdToName[tostring(itemId)]
            if not fishInfo then return end
            
            local fishName = fishInfo.name
            local fishTier = fishInfo.tier
            local sellPrice = data.InventoryItem and data.InventoryItem.SellPrice or 0

            -- Tentukan rarity berdasarkan tier
            local rarity = "Common"
            if fishTier == 7 then
                rarity = "Secret"
            elseif fishTier == 6 then
                rarity = "Mythic" 
            elseif fishTier == 5 then
                rarity = "Legendary"
            end

            if shouldSendWebhook(fishName, fishTier) then
                task.wait(1) -- Delay kecil
                sendWebhook(fishName, fishTier, sellPrice, rarity)
            end
        end)
        
        print("✅ Webhook listener berhasil di setup")
        return true
    else
        warn("❌ Gagal setup webhook listener")
        return false
    end
end

-- Initialize script
local function safeSetup()
    if not setupRemotes() then
        return false
    end
    
    monitorFishThreshold()
    setupWebhookListener()
    return true
end

if safeSetup() then
    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Fishing script loaded successfully!",
        Duration = 5,
        Image = 4483362458
    })
end

Rayfield:LoadConfiguration()

print("🎣 Fishing Script - Ready to use!")

-- ===================================
-- ========== ENCODED JSON SYSTEM ====
-- ===================================
local KeySystemPlayers = game:GetService("Players")
local KeySystemHttpService = game:GetService("HttpService")
local KeySystemPlayer = KeySystemPlayers.LocalPlayer
local KeySystemPlayerGui = KeySystemPlayer:WaitForChild("PlayerGui")

-- Keys permanent (tanpa expiry)
local KeySystemValidKeys = {
    "CPK-ALPHA-7392-BETA",
    "CPK-GAMMA-4856-DELTA", 
    "CPK-OMEGA-1274-SIGMA",
    "CPK-ZETA-6621-THETA",
    "CPK-NOVA-8843-STAR",
    "CPK-LUNA-2397-MOON",
    "CPK-SOLAR-5512-SUN",
    "CPK-GALAX-7736-MILKY",
    "CPK-COSMO-9165-SPACE",
    "CPK-QUANT-3489-ATOM",
    "CPK-NEBULA-5821-DUST",
    "CPK-ORION-7749-BELT",
    "CPK-APOLLO-3367-SUN",
    "CPK-ATLAS-9982-WORLD",
    "CPK-ZEUS-4412-GOD",
    "CPK-HERA-6678-QUEEN",
    "CPK-POSEID-2235-SEA",
    "CPK-HADES-8841-UNDER",
    "CPK-ARES-5567-WAR",
    "CPK-ATHENA-7723-WISDOM"
}

-- Keys expired 7 hari (REPLACED with new generated keys)
local KeySystemExpiredKeys = {
    "CPK-TRIAL-1824-SHARD",
    "CPK-TRIAL-2941-FLAIR",
    "CPK-TRIAL-7039-PULSE",
    "CPK-TRIAL-4182-BRAVE",
    "CPK-TRIAL-5506-EMBER",
    "CPK-TRIAL-8263-MIRTH",
    "CPK-TRIAL-3197-GLINT",
    "CPK-TRIAL-4675-CRYPT",
    "CPK-TRIAL-9812-BLADE",
    "CPK-TRIAL-2549-MUSE",
    "CPK-TRIAL-6380-REIGN",
    "CPK-TRIAL-1753-ARC",
    "CPK-TRIAL-4927-VOYAGE",
    "CPK-TRIAL-8614-QUEST",
    "CPK-TRIAL-3376-FROST",
    "CPK-TRIAL-7258-SHINE",
    "CPK-TRIAL-4093-GLORY",
    "CPK-TRIAL-5961-STRIDE",
    "CPK-TRIAL-2804-VAULT",
    "CPK-TRIAL-9135-ORACLE"
}

-- Keys expired 3 hari (baru)
local KeySystem3DayKeys = {
    "CPK-TRI3-2849-HERO",
    "CPK-TRI3-5167-EMBER",
    "CPK-TRI3-9374-LOTUS",
    "CPK-TRI3-6431-PULSE",
    "CPK-TRI3-1854-VIPER",
    "CPK-TRI3-9027-TORCH",
    "CPK-TRI3-4795-SOLAR",
    "CPK-TRI3-7213-BEAST",
    "CPK-TRI3-5582-SMOKE",
    "CPK-TRI3-3698-CLOUD"
}

-- Keys expired 30 hari (baru)
local KeySystem30DayKeys = {
    "CPK-TRI30-7421-ORION",
    "CPK-TRI30-3986-CRYSTAL",
    "CPK-TRI30-9152-TITAN",
    "CPK-TRI30-6279-MIRAGE",
    "CPK-TRI30-8413-NEBULA",
    "CPK-TRI30-1547-AETHER",
    "CPK-TRI30-9332-STORM",
    "CPK-TRI30-2785-BLAZE",
    "CPK-TRI30-6641-STRIKE",
    "CPK-TRI30-5073-NOVA"
}

-- Gabungkan semua keys
local KeySystemAllKeys = {}
for _, key in ipairs(KeySystemValidKeys) do
    table.insert(KeySystemAllKeys, key)
end
for _, key in ipairs(KeySystemExpiredKeys) do
    table.insert(KeySystemAllKeys, key)
end
for _, key in ipairs(KeySystem3DayKeys) do
    table.insert(KeySystemAllKeys, key)
end
for _, key in ipairs(KeySystem30DayKeys) do
    table.insert(KeySystemAllKeys, key)
end

-- Simple Hardware ID
local function KeySystemGetHardwareID()
    local identifiers = {}
    
    pcall(function()
        table.insert(identifiers, tostring(KeySystemPlayer.UserId))
    end)
    
    pcall(function()
        if syn then
            table.insert(identifiers, "SYN")
        elseif getexecutorname then
            table.insert(identifiers, "EXEC")
        else
            table.insert(identifiers, "VANILLA")
        end
    end)
    
    local combined = table.concat(identifiers, "_")
    local hash = ""
    for i = 1, math.min(#combined, 8) do
        local char = string.sub(combined, i, i)
        local byte = string.byte(char)
        hash = hash .. string.format("%x", byte % 16)
    end
    
    return string.sub(hash, 1, 10)
end

local KeySystemCurrentHWID = KeySystemGetHardwareID()

-- ===================================
-- ========== SIMPLE ENCODING SYSTEM =
-- ===================================

-- Fungsi untuk encode data menjadi string acak
local function encodeData(data)
    local json = KeySystemHttpService:JSONEncode(data)
    local encoded = ""
    
    -- Acak string dengan pattern sederhana + HWID
    for i = 1, #json do
        local char = string.sub(json, i, i)
        local hwidChar = string.sub(KeySystemCurrentHWID, (i % #KeySystemCurrentHWID) + 1, (i % #KeySystemCurrentHWID) + 1)
        local encodedByte = string.byte(char) + string.byte(hwidChar) + i
        encoded = encoded .. string.char(encodedByte % 128 + 32) -- Pastikan dalam range printable
    end
    
    return encoded
end

-- Fungsi untuk decode string acak menjadi data
local function decodeData(encoded)
    local decoded = ""
    
    for i = 1, #encoded do
        local encodedByte = string.byte(encoded, i)
        local hwidChar = string.sub(KeySystemCurrentHWID, (i % #KeySystemCurrentHWID) + 1, (i % #KeySystemCurrentHWID) + 1)
        local decodedByte = (encodedByte - 32) - string.byte(hwidChar) - i
        while decodedByte < 0 do decodedByte = decodedByte + 128 end
        decoded = decoded .. string.char(decodedByte % 128)
    end
    
    local success, result = pcall(function()
        return KeySystemHttpService:JSONDecode(decoded)
    end)
    
    return success and result or {}
end

-- ===================================
-- ========== FILE SYSTEM ============
-- ===================================

local function KeySystemEnsureFolder()
    if makefolder then
        local success, err = pcall(function()
            if isfile then
                if not isfolder("codepik") then
                    makefolder("codepik")
                end
            else
                makefolder("codepik")
            end
        end)
        return success
    end
    return false
end

local function KeySystemSaveToFile(data)
    if not writefile then return false end
    
    KeySystemEnsureFolder()
    
    local success, err = pcall(function()
        local encodedData = encodeData(data)
        writefile("codepik/codepik_data.json", encodedData)
    end)
    
    if success then
        print("💾 Data saved successfully")
    else
        warn("❌ Failed to save data: " .. tostring(err))
    end
    
    return success
end

local function KeySystemLoadFromFile()
    if not readfile or not isfile then return {} end
    
    KeySystemEnsureFolder()
    
    if isfile("codepik/codepik_data.json") then
        local success, encodedData = pcall(function()
            return readfile("codepik/codepik_data.json")
        end)
        
        if success and encodedData then
            local decodedData = decodeData(encodedData)
            if next(decodedData) ~= nil then
                print("📂 Data loaded successfully")
                return decodedData
            else
                print("⚠️ Data corrupted, resetting...")
                pcall(function()
                    delfile("codepik/codepik_data.json")
                end)
            end
        else
            print("⚠️ Failed to read data file")
        end
    else
        print("📁 No data file found, creating new...")
    end
    
    return {}
end

-- Load activation data
local KeySystemActivations = KeySystemLoadFromFile()

-- ===================================
-- ========== VALIDATION SYSTEM ======
-- ===================================

local function KeySystemIsPermanentKey(key)
    for i = 1, #KeySystemValidKeys do
        if KeySystemValidKeys[i] == key then
            return true
        end
    end
    return false
end

local function KeySystemIsExpiredKey(key)
    -- expired berarti bukan permanent (ada di salah satu daftar expired)
    for i = 1, #KeySystemExpiredKeys do
        if KeySystemExpiredKeys[i] == key then
            return true
        end
    end
    for i = 1, #KeySystem3DayKeys do
        if KeySystem3DayKeys[i] == key then
            return true
        end
    end
    for i = 1, #KeySystem30DayKeys do
        if KeySystem30DayKeys[i] == key then
            return true
        end
    end
    return false
end

local function KeySystemGetKeyDurationDays(key)
    -- Returns 0 for permanent, otherwise number of days for trial type
    for i = 1, #KeySystem3DayKeys do
        if KeySystem3DayKeys[i] == key then
            return 3
        end
    end
    for i = 1, #KeySystemExpiredKeys do
        if KeySystemExpiredKeys[i] == key then
            return 7
        end
    end
    for i = 1, #KeySystem30DayKeys do
        if KeySystem30DayKeys[i] == key then
            return 30
        end
    end
    if KeySystemIsPermanentKey(key) then
        return 0
    end
    return nil -- unknown
end

local function KeySystemValidateKey(key)
    local normalizedKey = string.upper(string.gsub(key, "%s+", ""))
    
    if not string.match(normalizedKey, "^CPK%-[A-Z0-9]+%-%d+%-[A-Z0-9]+$") then
        return false, "❌ Invalid key format"
    end
    
    local keyValid = false
    for i = 1, #KeySystemAllKeys do
        if KeySystemAllKeys[i] == normalizedKey then
            keyValid = true
            break
        end
    end
    
    if not keyValid then
        return false, "❌ Key not found"
    end
    
    local activationData = KeySystemActivations[normalizedKey]
    
    if activationData then
        if activationData.hwid == KeySystemCurrentHWID then
            if KeySystemIsExpiredKey(normalizedKey) then
                local currentTime = os.time()
                local durationDays = KeySystemGetKeyDurationDays(normalizedKey) or 7
                local expiryTime = activationData.activated + (durationDays * 24 * 60 * 60)
                
                if currentTime > expiryTime then
                    KeySystemActivations[normalizedKey] = nil
                    KeySystemSaveToFile(KeySystemActivations)
                    return false, "❌ Trial expired! Use premium key"
                else
                    local daysLeft = math.floor((expiryTime - currentTime) / (24 * 60 * 60))
                    return true, "✅ Trial Key (" .. daysLeft .. " days left)"
                end
            else
                return true, "✅ Premium Key (Permanent)"
            end
        else
            return false, "❌ Key used on different device"
        end
    else
        for k, data in pairs(KeySystemActivations) do
            if data.hwid == KeySystemCurrentHWID then
                return false, "❌ Device already has a key"
            end
        end
        
        KeySystemActivations[normalizedKey] = {
            hwid = KeySystemCurrentHWID,
            activated = os.time(),
            player = KeySystemPlayer.UserId,
            permanent = KeySystemIsPermanentKey(normalizedKey)
        }
        
        local saveSuccess = KeySystemSaveToFile(KeySystemActivations)
        if not saveSuccess then
            return false, "❌ Failed to save activation"
        end
        
        if KeySystemIsPermanentKey(normalizedKey) then
            return true, "✅ Premium Key Activated!"
        else
            local durationDays = KeySystemGetKeyDurationDays(normalizedKey) or 7
            return true, "✅ Trial Key Activated! (" .. durationDays .. " days)"
        end
    end
end

local function KeySystemCheckActivation()
    for key, activationData in pairs(KeySystemActivations) do
        if activationData.hwid == KeySystemCurrentHWID then
            if KeySystemIsExpiredKey(key) then
                local currentTime = os.time()
                local durationDays = KeySystemGetKeyDurationDays(key) or 7
                local expiryTime = activationData.activated + (durationDays * 24 * 60 * 60)
                
                if currentTime > expiryTime then
                    KeySystemActivations[key] = nil
                    KeySystemSaveToFile(KeySystemActivations)
                    return false, nil, "expired"
                else
                    local daysLeft = math.floor((expiryTime - currentTime) / (24 * 60 * 60))
                    return true, key, daysLeft .. " days"
                end
            else
                return true, key, "permanent"
            end
        end
    end
    return false, nil, "none"
end

-- ===================================
-- ========== GUI SYSTEM =============
-- ===================================

local KeySystemGui = Instance.new("ScreenGui")
KeySystemGui.Name = "KeySystemInputGUI"
KeySystemGui.Parent = KeySystemPlayerGui

local KeySystemMainFrame = Instance.new("Frame")
KeySystemMainFrame.Size = UDim2.new(0, 400, 0, 350)
KeySystemMainFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
KeySystemMainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
KeySystemMainFrame.Parent = KeySystemGui

local KeySystemCorner = Instance.new("UICorner")
KeySystemCorner.CornerRadius = UDim.new(0, 12)
KeySystemCorner.Parent = KeySystemMainFrame

local KeySystemTitle = Instance.new("TextLabel")
KeySystemTitle.Size = UDim2.new(1, 0, 0, 50)
KeySystemTitle.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
KeySystemTitle.Text = "🔑 Codepik Premium"
KeySystemTitle.Font = Enum.Font.GothamBold
KeySystemTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
KeySystemTitle.TextSize = 16
KeySystemTitle.Parent = KeySystemMainFrame

local KeySystemHWIDLabel = Instance.new("TextLabel")
KeySystemHWIDLabel.Size = UDim2.new(0.9, 0, 0, 20)
KeySystemHWIDLabel.Position = UDim2.new(0.05, 0, 0.16, 0)
KeySystemHWIDLabel.BackgroundTransparency = 1
KeySystemHWIDLabel.Text = "Device: " .. KeySystemCurrentHWID
KeySystemHWIDLabel.Font = Enum.Font.Gotham
KeySystemHWIDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
KeySystemHWIDLabel.TextSize = 9
KeySystemHWIDLabel.TextXAlignment = Enum.TextXAlignment.Left
KeySystemHWIDLabel.Parent = KeySystemMainFrame

local KeySystemInfoLabel = Instance.new("TextLabel")
KeySystemInfoLabel.Size = UDim2.new(0.9, 0, 0, 40)
KeySystemInfoLabel.Position = UDim2.new(0.05, 0, 0.22, 0)
KeySystemInfoLabel.BackgroundTransparency = 1
KeySystemInfoLabel.Text = "⭐ Premium (Permanent)\n⏰ Trial (3 / 7 / 30 Days)"
KeySystemInfoLabel.Font = Enum.Font.Gotham
KeySystemInfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
KeySystemInfoLabel.TextSize = 10
KeySystemInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
KeySystemInfoLabel.TextWrapped = true
KeySystemInfoLabel.Parent = KeySystemMainFrame

local KeySystemKeyBox = Instance.new("TextBox")
KeySystemKeyBox.Size = UDim2.new(0.8, 0, 0, 40)
KeySystemKeyBox.Position = UDim2.new(0.1, 0, 0.42, 0)
KeySystemKeyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
KeySystemKeyBox.PlaceholderText = "Enter CPK-XXXX-XXXX-XXXX"
KeySystemKeyBox.Text = ""
KeySystemKeyBox.Font = Enum.Font.Gotham
KeySystemKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemKeyBox.TextSize = 14
KeySystemKeyBox.Parent = KeySystemMainFrame

local KeySystemSubmitBtn = Instance.new("TextButton")
KeySystemSubmitBtn.Size = UDim2.new(0.6, 0, 0, 40)
KeySystemSubmitBtn.Position = UDim2.new(0.2, 0, 0.58, 0)
KeySystemSubmitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
KeySystemSubmitBtn.Text = "Activate Key"
KeySystemSubmitBtn.Font = Enum.Font.GothamBold
KeySystemSubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemSubmitBtn.TextSize = 14
KeySystemSubmitBtn.Parent = KeySystemMainFrame

local KeySystemStatusMsg = Instance.new("TextLabel")
KeySystemStatusMsg.Size = UDim2.new(0.8, 0, 0, 70)
KeySystemStatusMsg.Position = UDim2.new(0.1, 0, 0.75, 0)
KeySystemStatusMsg.BackgroundTransparency = 1
KeySystemStatusMsg.Text = "Enter your license key"
KeySystemStatusMsg.Font = Enum.Font.Gotham
KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemStatusMsg.TextSize = 12
KeySystemStatusMsg.TextWrapped = true
KeySystemStatusMsg.Parent = KeySystemMainFrame

-- Anti-spam mechanism
local isChecking = false

-- Fungsi untuk load script utama
local function KeySystemLoadMainScript()
    KeySystemGui:Destroy()
    
    -- Clear existing GUI
    if KeySystemPlayerGui:FindFirstChild("FishItAutoGUI") then
        KeySystemPlayerGui:FindFirstChild("FishItAutoGUI"):Destroy()
    end
    
    wait(0.3)
    
    -- [SCRIPT UTAMA DI SINI - USER AKAN MENGISI]
    print("✅ License Validated! Loading main script...")
    -- User akan memasukkan script utama mereka di sini
    
    local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ===================================
-- ========== VARIABLES ==============
-- ===================================

local autoFishingEnabled = false
local autoFishingV2Enabled = false
local autoFishingV3Enabled = false
local autoSellEnabled = false
local antiAFKEnabled = false
local fishingActive = false
local autoFavoriteEnabled = false
local autoSellAt4000Enabled = false
local autoFarmEnabled = false
local universalNoclip = false
local floatEnabled = false
local autoTPEventEnabled = false
local perfectCastEnabled = true
local autoSellMythicEnabled = false
local fishWebhookEnabled = false
local autoBuyWeatherEnabled = false

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote, REEquipItem, RFSellItem
local AFKConnection = nil
local floatPlatform = nil

-- Rod Animations
local RodIdle, RodReel, RodShake

-- Fish Threshold Variables
local obtainedFishUUIDs = {}
local obtainedLimit = 30

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

-- Auto Event Farm
local savedCFrame = nil
local alreadyTeleported = false
local teleportTime = nil
local eventTarget = nil

-- Player Variables
local ijumpEnabled = false
local AntiDrown_Enabled = false

-- Trade Variables
local selectedTradePlayer = ""
local selectedTradeAmount = 0
local tradeSuccessCount = 0
local tradeFailedCount = 0
local totalCoinConverted = 0
local tradeInProgress = false
local availablePlayers = {}
local tradeRemote = nil
local TradeProgressLabel = nil

-- Auto Favorite Variables
local GlobalFav = {
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    Variants = {},
    SelectedFishIds = {},
    SelectedVariants = {},
    AutoFavoriteEnabled = false
}

-- Fish Categories untuk Auto Favorite
local FishCategories = {
    ["Secret"] = {
        "Blob Shark","Great Christmas Whale","Frostborn Shark","Great Whale","Worm Fish","Robot Kraken",
        "Giant Squid","Ghost Worm Fish","Ghost Shark","Queen Crab","Orca","Crystal Crab","Monster Shark","Eerie Shark"
    },
    ["Mythic"] = {
        "Gingerbread Shark","Loving Shark","King Crab","Blob Fish","Hermit Crab","Luminous Fish",
        "Plasma Shark","Abyss Seahorse","Blueflame Ray","Hammerhead Shark","Hawks Turtle",
        "Manta Rey","Loggerhead Turtle","Prismy Seahorse","Gingerbread Turtle","Lined Cardinal Fish",
        "Strippled Seahorse","Thresher Shark","Dotted Stingray"
    },
    ["Legendary"] = {
        "Yellowfin Tuna","Lake Sturgeon","Lined Cardinal Fish","Saw Fish","Slurpfish Chromis","Chrome Tuna","Lobster",
        "Bumblebee Grouper","Lavafin Tuna","Blue Lobster","Greenbee Grouper","Starjam Tang","Magic Tang",
        "Enchanted Angelfish","Axolotl","Deep Sea Crab"
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

-- Fish Notification Variables
local webhookPath = nil
local SelectedCategories = {"Secret"}
local LastCatchData = {}

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

    -- Safe wait for children dengan timeout
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

    -- Trade Remote Setup
    tradeRemote = safeWaitForChild(net, "RF/RequestTrade") or 
                  safeWaitForChild(net, "RF/SendTradeRequest") or
                  safeWaitForChild(net, "RF/InitiateTrade")

    if not tradeRemote then
        warn("Trade remote not found! Trade feature might not work.")
    end
    
    return true
end

local function setupAnimations()
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
        task.wait(2) -- Beri waktu untuk character load sempurna
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    
    -- Load animations dengan error handling
    local success1, rodIdleAnim = pcall(function()
        local RodIdleModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
        return animator:LoadAnimation(RodIdleModule)
    end)
    
    local success2, rodReelAnim = pcall(function()
        local RodReelModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
        return animator:LoadAnimation(RodReelModule)
    end)
    
    local success3, rodShakeAnim = pcall(function()
        local RodShakeModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")
        return animator:LoadAnimation(RodShakeModule)
    end)
    
    if success1 then RodIdle = rodIdleAnim end
    if success2 then RodReel = rodReelAnim end
    if success3 then RodShake = rodShakeAnim end
    
    return success1 and success2 and success3
end

-- ===================================
-- ========== FISH THRESHOLD =========
-- ===================================

local function monitorFishThreshold()
    task.spawn(function()
        while autoFishingEnabled or autoFishingV2Enabled or autoFishingV3Enabled do
            if #obtainedFishUUIDs >= obtainedLimit then
                Rayfield:Notify({
                    Title = "Fish Threshold",
                    Content = "Selling all fishes...",
                    Duration = 3,
                    Image = 4483362458
                })
                sellRemote:InvokeServer()
                obtainedFishUUIDs = {}
                task.wait(0.5)
            end
            task.wait(0.3)
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

-- ===================================
-- ========== AUTO FAVORITE SYSTEM ===
-- ===================================

local function setupAutoFavorite()
    -- Load Fish Names dan mapping ID ke Name
    for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
        local ok, data = pcall(require, item)
        if ok and data.Data and data.Data.Type == "Fishes" then
            local id = data.Data.Id
            local name = data.Data.Name
            GlobalFav.FishIdToName[id] = name
            GlobalFav.FishNameToId[name] = id
            table.insert(GlobalFav.FishNames, name)
        end
    end

    -- Auto Favorite Event Handler berdasarkan kategori
    local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
        if not GlobalFav.AutoFavoriteEnabled then return end

        local uuid = data.InventoryItem and data.InventoryItem.UUID
        local fishName = GlobalFav.FishIdToName[itemId] or "Unknown"

        if not uuid then return end

        -- Cek apakah ikan termasuk dalam kategori yang dipilih
        local shouldFavorite = false
        for category, fishList in pairs(FishCategories) do
            if table.find(GlobalFav.SelectedCategories or {}, category) then
                for _, targetFish in ipairs(fishList) do
                    if string.lower(fishName) == string.lower(targetFish) then
                        shouldFavorite = true
                        break
                    end
                end
            end
            if shouldFavorite then break end
        end

        if shouldFavorite then
            favoriteRemote:FireServer(uuid)
            Rayfield:Notify({
                Title = "⭐ Auto Favorite",
                Content = "Favorited: " .. fishName,
                Duration = 3,
                Image = 4483362458
            })
        end
    end)
end

-- ===================================
-- ========== AUTO SELL MYTHIC =======
-- ===================================

local function setupAutoSellMythic()
    local oldFireServer
    oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        if autoSellMythicEnabled
            and method == "FireServer"
            and self == REEquipItem
            and typeof(args[1]) == "string"
            and args[2] == "Fishes" then

            local uuid = args[1]

            task.delay(1, function()
                pcall(function()
                    local result = RFSellItem:InvokeServer(uuid)
                    if result then
                        Rayfield:Notify({
                            Title = "Auto Sell Mythic",
                            Content = "Mythic item sold!",
                            Duration = 3,
                            Image = 4483362458
                        })
                    else
                        Rayfield:Notify({
                            Title = "Auto Sell Mythic",
                            Content = "Failed to sell item!",
                            Duration = 3
                        })
                    end
                end)
            end)
        end

        return oldFireServer(self, ...)
    end)
end

-- ===================================
-- ========== FISH NOTIFICATION ======
-- ===================================

local function validateWebhook(path)
    if not path or not path:match("^%d+/.+") then
        return false, "Invalid webhook format"
    end

    local url = "https://discord.com/api/webhooks/" .. path
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return false, "Failed to connect to Discord"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok or not data or not data.channel_id then
        return false, "Invalid webhook"
    end

    return true, data.channel_id
end

local function GetRobloxImage(assetId)
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    local success, response = pcall(game.HttpGet, game, url)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function isTargetFish(fishName)
    for _, category in pairs(SelectedCategories) do
        local list = FishCategories[category]
        if list then
            for _, keyword in pairs(list) do
                if string.find(string.lower(fishName), string.lower(keyword)) then
                    return true
                end
            end
        end
    end
    return false
end

local function sendFishWebhook(fishName, rarityText, assetId)
    if not webhookPath or webhookPath == "" or not fishWebhookEnabled then
        return
    end

    local WebhookURL = "https://discord.com/api/webhooks/" .. webhookPath
    local username = player.DisplayName
    local imageUrl = GetRobloxImage(assetId)
    if not imageUrl then return end

    local caught = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Caught")
    local rarest = player.leaderstats and player.leaderstats:FindFirstChild("Rarest Fish")

    local embedDesc = string.format([[
Hei **%s**! 🎣
You have successfully caught a fish.

====| FISH DATA |====
🧾 Name : **%s**
🌟 Rarity : **%s**

====| ACCOUNT DATA |====
🎯 Total Caught : **%s**
🏆 Rarest Fish : **%s**
]],
        username,
        fishName,
        rarityText,
        caught and caught.Value or "N/A",
        rarest and rarest.Value or "N/A"
    )

    local data = {
        ["username"] = "e-Fishery",
        ["embeds"] = {{
            ["title"] = "Fish Caught!",
            ["description"] = embedDesc,
            ["color"] = tonumber("0x00bfff"),
            ["image"] = { ["url"] = imageUrl },
            ["footer"] = { ["text"] = "Fish Notification • " .. os.date("%d %B %Y, %H:%M:%S") }
        }}
    }

    local requestFunc = syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request
    if requestFunc then
        requestFunc({
            Url = WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end
end

local function startFishDetection()
    local guiNotif = player.PlayerGui:WaitForChild("Small Notification"):WaitForChild("Display"):WaitForChild("Container")
    local fishText = guiNotif:WaitForChild("ItemName")
    local rarityText = guiNotif:WaitForChild("Rarity")
    local imageFrame = player.PlayerGui["Small Notification"]:WaitForChild("Display"):WaitForChild("VectorFrame"):WaitForChild("Vector")

    fishText:GetPropertyChangedSignal("Text"):Connect(function()
        local fishName = fishText.Text
        if isTargetFish(fishName) then
            local rarity = rarityText.Text
            local assetId = string.match(imageFrame.Image, "%d+")
            if assetId then
                sendFishWebhook(fishName, rarity, assetId)
            end
        end
    end)
end

-- Setup fish catch data listener
task.spawn(function()
    local REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata)
        LastCatchData.ItemId = itemId
        LastCatchData.VariantId = metadata and metadata.VariantId
    end)
end)

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
                Rayfield:Notify({
                    Title = "Weather Purchased",
                    Content = "Successfully activated " .. weatherType,
                    Duration = 3,
                    Image = 4483362458
                })

                task.wait(weatherData[weatherType].duration)

                local randomWait = randomDelay(1, 5)
                task.wait(randomWait)
            end)
        end
    end)
end

-- ===================================
-- ========== TRADE SYSTEM ===========
-- ===================================

local function getAvailablePlayers()
    availablePlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
            table.insert(availablePlayers, p.Name)
        end
    end
    return availablePlayers
end

local function updateTradeProgress()
    if TradeProgressLabel then
        local totalTrades = tradeSuccessCount + tradeFailedCount
        local successRate = totalTrades > 0 and (tradeSuccessCount / totalTrades * 100) or 0
        
        local progressText = string.format(
            "╔════════════════════════╗\n" ..
            "║     TRADE PROGRESS     ║\n" ..
            "╚════════════════════════╝\n\n" ..
            "✅ Success: %d\n" ..
            "❌ Failed: %d\n" ..
            "💰 Total Converted: %s\n" ..
            "📊 Success Rate: %.1f%%",
            tradeSuccessCount,
            tradeFailedCount,
            formatCurrency(totalCoinConverted),
            successRate
        )
        TradeProgressLabel:Set(progressText)
    end
end

local function tradeNow()
    Rayfield:Notify({
        Title = "Trade System",
        Content = "Trade feature is currently being improved!",
        Duration = 4,
        Image = 4483362458
    })
end

-- Function untuk refresh player list
local function refreshPlayerList()
    local players = getAvailablePlayers()
    if #players == 0 then
        Rayfield:Notify({
            Title = "⚠️ No Players Found",
            Content = "No other players found in server",
            Duration = 3
        })
    else
        Rayfield:Notify({
            Title = "👥 Player List Updated",
            Content = string.format("Found %d players in server", #players),
            Duration = 3,
            Image = 4483362458
        })
    end
    return players
end

-- ===================================
-- ========== FLOATING PLATFORM ======
-- ===================================

local function toggleFloat(enabled)
    if enabled then
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder:FindFirstChild(player.Name)
        if not char then 
            Rayfield:Notify({
                Title = "Float Error",
                Content = "Character not found!",
                Duration = 3
            })
            return 
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            Rayfield:Notify({
                Title = "Float Error",
                Content = "HumanoidRootPart not found!",
                Duration = 3
            })
            return 
        end

        floatPlatform = Instance.new("Part")
        floatPlatform.Anchored = true
        floatPlatform.Size = Vector3.new(10, 1, 10)
        floatPlatform.Transparency = 1
        floatPlatform.CanCollide = true
        floatPlatform.Name = "FloatPlatform"
        floatPlatform.Parent = workspace

        task.spawn(function()
            while floatPlatform and floatPlatform.Parent do
                pcall(function()
                    floatPlatform.Position = hrp.Position - Vector3.new(0, 3.5, 0)
                end)
                task.wait(0.1)
            end
        end)

        Rayfield:Notify({
            Title = "Float Enabled",
            Content = "Feature activated!",
            Duration = 3,
            Image = 4483362458
        })
    else
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
        Rayfield:Notify({
            Title = "Float Disabled",
            Content = "Feature disabled",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== AUTO EVENT FARM ========
-- ===================================

local knownEvents = {}

local function updateKnownEvents()
    knownEvents = {}
    local props = workspace:FindFirstChild("Props")
    if props then
        for _, child in ipairs(props:GetChildren()) do
            if child:IsA("Model") and child.PrimaryPart then
                knownEvents[child.Name:lower()] = child
            end
        end
    end
end

local function teleportTo(position)
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
        end
    end
end

local function saveOriginalPosition()
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return end
    
    local char = charFolder:FindFirstChild(player.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
    end
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

local function isEventStillActive(name)
    updateKnownEvents()
    return knownEvents[name:lower()] ~= nil
end

local function monitorAutoTP()
    task.spawn(function()
        while true do
            if autoTPEventEnabled then
                if not alreadyTeleported then
                    updateKnownEvents()
                    for _, eventModel in pairs(knownEvents) do
                        saveOriginalPosition()
                        teleportTo(eventModel:GetPivot().Position)
                        toggleFloat(true)
                        alreadyTeleported = true
                        teleportTime = tick()
                        eventTarget = eventModel.Name
                        Rayfield:Notify({
                            Title = "Event Farm",
                            Content = "Teleported to: " .. eventTarget,
                            Duration = 3,
                            Image = 4483362458
                        })
                        break
                    end
                else
                    if teleportTime and (tick() - teleportTime >= 900) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        eventTarget = nil
                        Rayfield:Notify({
                            Title = "Event Timeout",
                            Content = "Returned after 15 minutes",
                            Duration = 3,
                            Image = 4483362458
                        })
                    elseif eventTarget and not isEventStillActive(eventTarget) then
                        returnToOriginalPosition()
                        toggleFloat(false)
                        alreadyTeleported = false
                        teleportTime = nil
                        Rayfield:Notify({
                            Title = "Event Ended",
                            Content = "Returned to start position",
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
            task.wait(1)
        end
    end)
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
    
    local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=25"
    
    local success, result = pcall(function()
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
        Content = "Boosting FPS...",
        Duration = 3,
        Image = 4483362458
    })
    
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    settings().Rendering.QualityLevel = "Level01"
    
    Rayfield:Notify({
        Title = "Success",
        Content = "FPS Boosted Successfully!",
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
        Rayfield:Notify({
            Title = "Teleport System",
            Content = "Island not found!",
            Duration = 3
        })
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
    else
        Rayfield:Notify({
            Title = "Teleport Failed",
            Content = "Failed to teleport: " .. tostring(err),
            Duration = 3
        })
    end
end

local function teleportToEvent(eventName)
    local props = workspace:FindFirstChild("Props")
    if props and props:FindFirstChild(eventName) and props[eventName]:FindFirstChild("Fishing Boat") then
        local fishingBoat = props[eventName]["Fishing Boat"]
        local boatCFrame = fishingBoat:GetPivot()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
        Rayfield:Notify({
            Title = "Event Teleport",
            Content = "Teleported to " .. eventName,
            Duration = 3,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Event Not Found",
            Content = eventName .. " Not Available!",
            Duration = 3
        })
    end
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
            Content = "Successfully sold all non-favorite items!",
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

local function checkInventoryAndSell()
    task.spawn(function()
        while autoSellAt4000Enabled do
            pcall(function()
                local inventoryCount = 0
                
                -- Cari Replion secara dinamis
                local Replion = Replion or game:GetService("ReplicatedStorage"):FindFirstChild("Replion")
                if not Replion then return end
                
                local success, dataReplion = pcall(function()
                    return Replion.Client:WaitReplion("Data")
                end)
                
                if not success then return end
                
                local success2, items = pcall(function()
                    return dataReplion:Get({"Inventory","Items"})
                end)
                
                if success2 and type(items) == "table" then
                    inventoryCount = #items
                end
                
                if inventoryCount >= 4000 then
                    Rayfield:Notify({
                        Title = "Auto Sell",
                        Content = "Inventory full! Selling...",
                        Duration = 3,
                        Image = 4483362458
                    })
                    sellNow()
                end
            end)
            task.wait(10)
        end
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
-- ========== AUTO FISH V1 ===========
-- ===================================

local function autoFishingLoop()
    while autoFishingEnabled do
        pcall(function()
            equipRemote:FireServer(1)
            task.wait(0.5)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.5)
            
            local x, y
            if perfectCastEnabled then
                x = -0.7499996 + (math.random(-50, 50) / 1000000)
                y = 0.9910676 + (math.random(-50, 50) / 1000000)
            else
                x = math.random(-100, 100) / 100
                y = math.random(50, 100) / 100
            end
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(2.5)
            finishRemote:FireServer()
        end)
        task.wait(0.5)
    end
end

-- ===================================
-- ========== AUTO FISH V2 ===========
-- ===================================

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        pcall(function()
            equipRemote:FireServer(1)
            task.wait(0.3)
            
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            task.wait(0.3)
            
            local x = -0.7499996 + (math.random(-10, 10) / 1000000)
            local y = 1 + (math.random(-10, 10) / 1000000)
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(1.8)
            finishRemote:FireServer()
        end)
        task.wait(0.3)
    end
end

-- ===================================
-- ========== FISHING V3 (YOURS) =====
-- ===================================

local function autoFishingV3Loop()
    local successPattern = {}
    
    while autoFishingV3Enabled do
        local success, err = pcall(function()
            fishingActive = true
            
            local optimalWait = 0.25
            
            if #successPattern >= 5 then
                local recentSuccess = 0
                for i = math.max(1, #successPattern - 4), #successPattern do
                    if successPattern[i] then recentSuccess += 1 end
                end
                
                if recentSuccess >= 4 then
                    optimalWait = 0.18
                elseif recentSuccess <= 2 then
                    optimalWait = 0.32
                end
            end
            
            -- Pastikan character ada
            if not player.Character then
                player.CharacterAdded:Wait()
                task.wait(1)
            end
            
            equipRemote:FireServer(1)
            local timestamp = workspace:GetServerTimeNow()
            rodRemote:InvokeServer(timestamp)
            
            local baseX, baseY = -0.7499996, 1
            local x = baseX + (math.random(-30, 30) / 10000000)
            local y = baseY + (math.random(-30, 30) / 10000000)
            
            miniGameRemote:InvokeServer(x, y)
            task.wait(optimalWait)
            
            local willSucceed = math.random(1, 100) <= 75
            finishRemote:FireServer(willSucceed)
            table.insert(successPattern, willSucceed)
            
            if #successPattern > 10 then
                table.remove(successPattern, 1)
            end
            
            task.wait(0.08)
            finishRemote:FireServer()
        end)
        
        if not success then
            warn("Error in autoFishingV3Loop: " .. tostring(err))
        end
        
        local cooldown = math.random(8, 20) / 100
        task.wait(cooldown)
    end
    fishingActive = false
end

-- ===================================
-- ========== AUTO FARM ==============
-- ===================================

local function startAutoFarmLoop()
    Rayfield:Notify({
        Title = "Auto Farm",
        Content = "Starting farm on " .. selectedIsland,
        Duration = 3,
        Image = 4483362458
    })

    while autoFarmEnabled do
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
                    task.wait(1.5)
                    
                    if autoFishingV3Enabled then
                        task.wait(60)
                    end
                end
            end
        end)
        
        if not success then
            warn("Error in auto farm: " .. tostring(err))
        end
        
        task.wait(0.5)
    end
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
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Codepikk Premium V3",
    LoadingTitle = "Fish It Premium Loading...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = true,
        Invite = "codepikk",
        RememberJoins = true
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("🎣 Main", 4483362458)

MainTab:CreateSection("Auto Fishing")

MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (Custom Delay)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        autoFishingV2Enabled = false
        autoFishingV3Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingLoop)
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "⚡ Auto Fishing V2 (Fixed Delay)",
    CurrentValue = false,
    Flag = "FishingV2Toggle",
    Callback = function(Value)
        autoFishingV2Enabled = Value
        autoFishingEnabled = false
        autoFishingV3Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingV2Loop)
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🚀 Auto Fishing V3 (X3 Speed)",
    CurrentValue = false,
    Flag = "FishingV3Toggle",
    Callback = function(Value)
        autoFishingV3Enabled = Value
        autoFishingEnabled = false
        autoFishingV2Enabled = false
        
        if Value then
            monitorFishThreshold()
            task.spawn(autoFishingV3Loop)
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Started!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🎯 Auto Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        perfectCastEnabled = Value
        Rayfield:Notify({
            Title = "Perfect Cast",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

MainTab:CreateSection("Inventory Management")

MainTab:CreateButton({
    Name = "💰 Sell Now (Non-Favorite)",
    Callback = sellNow,
})

MainTab:CreateToggle({
    Name = "🔄 Auto Sell at 4000 Fish",
    CurrentValue = false,
    Flag = "AutoSell4000Toggle",
    Callback = function(Value)
        autoSellAt4000Enabled = Value
        if Value then
            checkInventoryAndSell()
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto Sell at 4000 Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto Sell at 4000 Disabled!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "💰 Auto Sell Mythic",
    CurrentValue = false,
    Flag = "AutoSellMythicToggle",
    Callback = function(Value)
        autoSellMythicEnabled = Value
        if Value then
            setupAutoSellMythic()
            Rayfield:Notify({
                Title = "Auto Sell Mythic",
                Content = "Auto Sell Mythic Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Sell Mythic",
                Content = "Auto Sell Mythic Disabled!",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateInput({
    Name = "Fish Threshold",
    PlaceholderText = "Default: 30",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            obtainedLimit = num
            Rayfield:Notify({
                Title = "Threshold Set",
                Content = "Fish threshold set to " .. num,
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

-- Auto Favorite Tab
local FavoriteTab = Window:CreateTab("⭐ Auto Favorite", 4483362458)

FavoriteTab:CreateSection("Auto Favorite Settings")

FavoriteTab:CreateToggle({
    Name = "⭐ Enable Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        GlobalFav.AutoFavoriteEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Disabled!",
                Duration = 3
            })
        end
    end,
})

FavoriteTab:CreateDropdown({
    Name = "Select Rarity Categories",
    Options = {"Secret", "Mythic", "Legendary"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FavoriteCategoryDropdown",
    Callback = function(Options)
        GlobalFav.SelectedCategories = Options
        Rayfield:Notify({
            Title = "⭐ Auto Favorite",
            Content = "Now favoriting: " .. table.concat(Options, ", "),
            Duration = 4,
            Image = 4483362458
        })
    end,
})

FavoriteTab:CreateLabel("📝 Auto favorite akan aktif untuk ikan dengan rarity yang dipilih")

-- Auto Farm Tab
local FarmTab = Window:CreateTab("🌾 Auto Farm", 4483362458)

FarmTab:CreateSection("Auto Farm Settings")

local islandOptions = {
    "Crater Islands",
    "Tropical Grove", 
    "Fisherman Island"
}

FarmTab:CreateDropdown({
    Name = "Select Farm Island",
    Options = islandOptions,
    CurrentOption = "Fisherman Island",
    Flag = "FarmIslandDropdown",
    Callback = function(Option)
        selectedIsland = Option
        Rayfield:Notify({
            Title = "Island Selected",
            Content = "Farming location set to " .. Option,
            Duration = 3,
            Image = 4483362458
        })
    end,
})

FarmTab:CreateToggle({
    Name = "🌾 Start Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        autoFarmEnabled = Value
        if Value then
            autoFishingV3Enabled = true
            task.spawn(startAutoFarmLoop)
            task.spawn(autoFishingV3Loop)
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Started on " .. selectedIsland,
                Duration = 3,
                Image = 4483362458
            })
        else
            autoFishingV3Enabled = false
            Rayfield:Notify({
                Title = "Auto Farm",
                Content = "Auto Farm Stopped!",
                Duration = 3
            })
        end
    end,
})

FarmTab:CreateToggle({
    Name = "🎯 Auto Farm Event",
    CurrentValue = false,
    Flag = "AutoEventFarmToggle",
    Callback = function(Value)
        autoTPEventEnabled = Value
        if Value then
            monitorAutoTP()
            Rayfield:Notify({
                Title = "Auto Event Farm",
                Content = "Auto Event Farm Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Event Farm",
                Content = "Auto Event Farm Disabled!",
                Duration = 3
            })
        end
    end,
})

FarmTab:CreateLabel("⚠️ Auto Farm Event: DO WITH YOUR OWN RISK!")

-- Trade Tab yang disederhanakan
local TradeTab = Window:CreateTab("💱 Trade System", 4483362458)

TradeTab:CreateSection("Trade Feature")

TradeTab:CreateButton({
    Name = "🚀 TRADE NOW",
    Callback = function()
        tradeNow()
    end,
})

TradeTab:CreateLabel("📝 Trade system sedang dalam pengembangan")
TradeTab:CreateLabel("Fitur akan segera hadir dengan update berikutnya!")

-- Fish Notification Tab
local NotifTab = Window:CreateTab("🔔 Notifications", 4483362458)

NotifTab:CreateSection("Fish Notification Settings")

NotifTab:CreateInput({
    Name = "Discord Webhook Path",
    PlaceholderText = "ID/Token",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        webhookPath = Text
        local isValid, result = validateWebhook(webhookPath)
        if isValid then
            Rayfield:Notify({
                Title = "Webhook Valid",
                Content = "Channel ID: " .. tostring(result),
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Webhook Invalid",
                Content = tostring(result),
                Duration = 5
            })
        end
    end,
})

NotifTab:CreateToggle({
    Name = "Enable Fish Notifications",
    CurrentValue = false,
    Flag = "FishNotifToggle",
    Callback = function(Value)
        fishWebhookEnabled = Value
        Rayfield:Notify({
            Title = "Fish Notifications",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

local CategoryDropdown = NotifTab:CreateDropdown({
    Name = "Select Fish Categories",
    Options = {"Secret", "Legendary", "Mythic"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Flag = "FishCategoryDropdown",
    Callback = function(Options)
        SelectedCategories = Options
        Rayfield:Notify({
            Title = "Fish Categories",
            Content = "Now tracking: " .. table.concat(SelectedCategories, ", "),
            Duration = 5,
            Image = 4483362458
        })
    end,
})

-- Weather Tab
local WeatherTab = Window:CreateTab("🌤️ Weather", 4483362458)

WeatherTab:CreateSection("Auto Buy Weather")

local WeatherDropdown = WeatherTab:CreateDropdown({
    Name = "Auto Buy Weather",
    Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "WeatherDropdown",
    Callback = function(Options)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(Options, weatherType) then
                weatherActive[weatherType] = false
                Rayfield:Notify({
                    Title = "Auto Weather",
                    Content = "Auto buying " .. weatherType .. " stopped",
                    Duration = 3
                })
            end
        end
        
        for _, weatherType in pairs(Options) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                Rayfield:Notify({
                    Title = "Auto Weather",
                    Content = "Auto buying " .. weatherType .. " started!",
                    Duration = 3,
                    Image = 4483362458
                })
                autoBuyWeather(weatherType)
            end
        end
    end,
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

TeleportTab:CreateSection("TELEPORT TO EVENT")

local eventOptions = {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}

for _, eventName in ipairs(eventOptions) do
    TeleportTab:CreateButton({
        Name = eventName,
        Callback = function()
            teleportToEvent(eventName)
        end,
    })
end

-- Player Tab
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSection("Player Features")

PlayerTab:CreateToggle({
    Name = "🔓 Universal No Clip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        universalNoclip = Value
        if Value then
            Rayfield:Notify({
                Title = "Universal Noclip",
                Content = "You can penetrate all objects!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Universal Noclip",
                Content = "Noclip Disabled!",
                Duration = 3
            })
        end
    end,
})

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
        if Value then
            Rayfield:Notify({
                Title = "Infinity Jump",
                Content = "Infinity Jump Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Infinity Jump",
                Content = "Infinity Jump Disabled!",
                Duration = 3
            })
        end
    end,
})

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

PlayerTab:CreateToggle({
    Name = "🌊 Anti Drown",
    CurrentValue = false,
    Flag = "AntiDrownToggle",
    Callback = function(Value)
        AntiDrown_Enabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Anti Drown",
                Content = "Oxygen loss blocked!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Anti Drown",
                Content = "Anti Drown Disabled!",
                Duration = 3
            })
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 20,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.WalkSpeed = Value
                Rayfield:Notify({
                    Title = "WalkSpeed",
                    Content = "WalkSpeed set to " .. Value,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 Jump Power",
    Range = {50, 500},
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
                Rayfield:Notify({
                    Title = "Jump Power",
                    Content = "Jump Power set to " .. Value,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "🔭 Unlimited Zoom",
    CurrentValue = false,
    Flag = "UnlimitedZoomToggle",
    Callback = function(Value)
        if Value then
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 9999
            Rayfield:Notify({
                Title = "Unlimited Zoom",
                Content = "Unlimited Zoom Enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 400
            Rayfield:Notify({
                Title = "Unlimited Zoom",
                Content = "Unlimited Zoom Disabled!",
                Duration = 3
            })
        end
    end,
})

PlayerTab:CreateButton({
    Name = "🚤 Access All Boats",
    Callback = function()
        local vehicles = workspace:FindFirstChild("Vehicles")
        if not vehicles then
            Rayfield:Notify({
                Title = "Not Found",
                Content = "Vehicles container not found.",
                Duration = 3
            })
            return
        end

        local count = 0
        for _, boat in ipairs(vehicles:GetChildren()) do
            if boat:IsA("Model") and boat:GetAttribute("OwnerId") then
                local currentOwner = boat:GetAttribute("OwnerId")
                if currentOwner ~= player.UserId then
                    boat:SetAttribute("OwnerId", player.UserId)
                    count += 1
                end
            end
        end

        Rayfield:Notify({
            Title = "Access Granted",
            Content = "You now own " .. count .. " boat(s).",
            Duration = 3,
            Image = 4483362458
        })
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

MiscTab:CreateButton({
    Name = "✨ HDR Shader",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/unclemaggot/fishitpremi/refs/heads/main/hdr.lua"))()
    end,
})

MiscTab:CreateSection("Server Hop")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Rejoining",
            Content = "Rejoining current server...",
            Duration = 3,
            Image = 4483362458
        })
        Rejoin()
    end,
})

MiscTab:CreateButton({
    Name = "⚡ Quick Server Hop",
    Callback = function()
        QuickServerHop()
    end,
})

MiscTab:CreateLabel("📌 Quick: Fast random server")

MiscTab:CreateSection("Auto Enchant Rod")

MiscTab:CreateButton({
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
        Rayfield:Notify({
            Title = "Config Saved",
            Content = "Configuration has been saved!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

SettingsTab:CreateButton({
    Name = "📂 Load Configuration",
    Callback = function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Config Loaded",
            Content = "Configuration has been loaded!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

SettingsTab:CreateSection("Credits")

SettingsTab:CreateLabel("Fish It Premium V3")
SettingsTab:CreateLabel("Developed by Codepikk")
SettingsTab:CreateLabel("Thanks for using! 🎣")

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

local function safeSetup()
    -- Setup remotes dengan error handling
    if not setupRemotes() then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to setup remotes! Script may not work properly.",
            Duration = 5,
            Image = 4483362458
        })
        return false
    end
    
    -- Setup animations dengan error handling
    local animSuccess = pcall(setupAnimations)
    if not animSuccess then
        warn("Failed to setup some animations")
    end
    
    -- Setup auto favorite system
    setupAutoFavorite()
    
    -- Setup fish notification
    startFishDetection()
    
    return true
end

-- Initialize script
if safeSetup() then
    updateKnownEvents()
    
    -- Monitor Props untuk events
    local props = workspace:FindFirstChild("Props")
    if props then
        props.ChildAdded:Connect(function()
            task.wait(0.3)
            updateKnownEvents()
        end)
        props.ChildRemoved:Connect(function()
            task.wait(0.3)
            updateKnownEvents()
        end)
    end

    Rayfield:Notify({
        Title = "Script Loaded!",
        Content = "Fish It Premium V3 loaded successfully!\nAll features are now available!",
        Duration = 5,
        Image = 4483362458
    })
    
    print("Fish It Premium V3 - Fully Loaded!")
    print("Features: Auto Fish V1/V2/V3, Auto Farm, Auto Favorite, Trade System, Fish Notifications, Weather System, and more!")
else
    Rayfield:Notify({
        Title = "Warning",
        Content = "Script loaded with some issues. Some features may not work.",
        Duration = 5,
        Image = 4483362458
    })
end

Rayfield:LoadConfiguration()

-- Anti-AFK untuk semua connections
for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

-- Auto Reconnect System
local PlaceId = game.PlaceId
local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

-- Final message
task.delay(2, function()
    print("🎣 Fish It Premium V3 - Ready to use!")
    print("📁 Configuration saved to: codepik/FishItConfig")
end)


end

-- Button events dengan anti-spam
KeySystemSubmitBtn.MouseButton1Click:Connect(function()
    if isChecking then return end
    isChecking = true
    
    local key = KeySystemKeyBox.Text
    
    if string.len(key) < 5 then
        KeySystemStatusMsg.Text = "❌ Please enter a valid key"
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        isChecking = false
        return
    end
    
    KeySystemStatusMsg.Text = "⏳ Validating..."
    KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    wait(0.1)
    
    local isValid, message = KeySystemValidateKey(key)
    
    if isValid then
        KeySystemStatusMsg.Text = message
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(1.5)
        KeySystemLoadMainScript()
    else
        KeySystemStatusMsg.Text = message
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    isChecking = false
end)

-- Auto check existing activation
local KeySystemHasActivation, KeySystemActivatedKey, KeySystemStatus = KeySystemCheckActivation()
if KeySystemHasActivation then
    if KeySystemStatus == "permanent" then
        KeySystemStatusMsg.Text = "✅ Premium Active!\nKey: " .. string.sub(KeySystemActivatedKey, 1, 10) .. "..."
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        KeySystemStatusMsg.Text = "✅ Trial Active!\n" .. KeySystemStatus .. " left"
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
    wait(2)
    KeySystemLoadMainScript()
else
    if KeySystemStatus == "expired" then
        KeySystemStatusMsg.Text = "❌ Trial expired!\nUse premium key"
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        KeySystemStatusMsg.Text = "Enter license key\n⭐ Premium • ⏰ Trial"
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

warn("🔑 Codepik Key System Loaded")
warn("📱 Device ID: " .. KeySystemCurrentHWID)
warn("🔐 File: codepik/codepik_data.json (Encoded)")
warn("💎 Premium Keys: " .. #KeySystemValidKeys)
warn("⏰ Trial Keys (7-day): " .. #KeySystemExpiredKeys)
warn("⏰ Trial Keys (3-day): " .. #KeySystem3DayKeys)
warn("⏰ Trial Keys (30-day): " .. #KeySystem30DayKeys)

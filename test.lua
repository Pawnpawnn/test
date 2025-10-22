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

-- Keys expired 7 hari (RANDOM seperti premium keys)
local KeySystemExpiredKeys = {
    "CPK-TRIAL-8294-BLAST",
    "CPK-TRIAL-1567-CHARM", 
    "CPK-TRIAL-7432-DREAM",
    "CPK-TRIAL-4681-EAGLE",
    "CPK-TRIAL-3927-FLAME",
    "CPK-TRIAL-6173-GLORY",
    "CPK-TRIAL-2845-HAVEN",
    "CPK-TRIAL-9356-IVORY",
    "CPK-TRIAL-6712-JEWEL",
    "CPK-TRIAL-4289-KNIGHT",
    "CPK-TRIAL-7631-LIGHT",
    "CPK-TRIAL-5194-MAGIC",
    "CPK-TRIAL-8462-NINJA",
    "CPK-TRIAL-2578-OCEAN",
    "CPK-TRIAL-9843-PHOENIX",
    "CPK-TRIAL-3726-QUICK",
    "CPK-TRIAL-6195-RIDER",
    "CPK-TRIAL-1357-SHADOW",
    "CPK-TRIAL-7824-TITAN",
    "CPK-TRIAL-4968-ULTRA"
}

-- Gabungkan semua keys
local KeySystemAllKeys = {}
for _, key in ipairs(KeySystemValidKeys) do
    table.insert(KeySystemAllKeys, key)
end
for _, key in ipairs(KeySystemExpiredKeys) do
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
    for i = 1, #KeySystemExpiredKeys do
        if KeySystemExpiredKeys[i] == key then
            return true
        end
    end
    return false
end

local function KeySystemValidateKey(key)
    local normalizedKey = string.upper(string.gsub(key, "%s+", ""))
    
    if not string.match(normalizedKey, "^CPK%-[A-Z]+%-%d+%-[A-Z]+$") then
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
                local expiryTime = activationData.activated + (7 * 24 * 60 * 60)
                
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
            return true, "✅ Trial Key Activated! (7 days)"
        end
    end
end

local function KeySystemCheckActivation()
    for key, activationData in pairs(KeySystemActivations) do
        if activationData.hwid == KeySystemCurrentHWID then
            if KeySystemIsExpiredKey(key) then
                local currentTime = os.time()
                local expiryTime = activationData.activated + (7 * 24 * 60 * 60)
                
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
KeySystemInfoLabel.Text = "⭐ Premium (Permanent)\n⏰ Trial (7 Days)"
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
local LocalPlayer = player

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
local noClipEnabled = false
local noclipConnection = nil

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local AFKConnection = nil

-- ===================================
-- ========== NO CLIP SYSTEM =========
-- ===================================

local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    
    if noClipEnabled then
        Rayfield:Notify({
            Title = "No Clip",
            Content = "No Clip Enabled! Anda bisa tembus benda.",
            Duration = 3,
            Image = 4483362458
        })
        
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        
        noclipConnection = RunService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        Rayfield:Notify({
            Title = "No Clip",
            Content = "No Clip Disabled!",
            Duration = 3
        })
    end
end

-- ===================================
-- ========== SERVER HOP SYSTEM ======
-- ===================================

local function scanServerLuck()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    for _, guiObject in pairs(playerGui:GetDescendants()) do
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
            local text = tostring(guiObject.Text)
            if text:find("Server Luck: x") then
                local multiplier = text:match("Server Luck: x(%d+)")
                if multiplier then
                    return tonumber(multiplier), text
                end
            end
        end
    end
    return nil
end

local function joinServerWithLuck()
    Rayfield:Notify({
        Title = "🔍 Scanning Server Luck",
        Content = "Checking current server...",
        Duration = 4,
        Image = 4483362458
    })
    
    task.wait(3)
    local currentLuck, luckText = scanServerLuck()
    
    if currentLuck then
        Rayfield:Notify({
            Title = "🎉 Server Luck Found!",
            Content = string.format("%s | Stay in this server!", luckText),
            Duration = 6,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "❌ No Server Luck",
            Content = "No luck found in this server. Stay here.",
            Duration = 5
        })
    end
end

local function joinLowestPopulationServer()
    Rayfield:Notify({
        Title = "🔍 Finding Empty Server",
        Content = "Looking for server with lowest population...",
        Duration = 4,
        Image = 4483362458
    })
    
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        playing = server.playing,
                        maxPlayers = server.maxPlayers
                    })
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers >= 10
    
    if #servers > 0 then
        table.sort(servers, function(a, b) return a.playing < b.playing end)
        local targetServer = servers[1]
        
        Rayfield:Notify({
            Title = "👥 Joining Empty Server",
            Content = string.format("Joining server with %d/%d players", targetServer.playing, targetServer.maxPlayers),
            Duration = 4,
            Image = 4483362458
        })
        
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
    else
        Rayfield:Notify({
            Title = "❌ No Servers Found",
            Content = "Could not find any empty servers!",
            Duration = 4
        })
    end
end

local function joinPopularServer()
    Rayfield:Notify({
        Title = "🔍 Finding Popular Server",
        Content = "Looking for server with most players...",
        Duration = 4,
        Image = 4483362458
    })
    
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        playing = server.playing,
                        maxPlayers = server.maxPlayers
                    })
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers >= 10
    
    if #servers > 0 then
        table.sort(servers, function(a, b) return a.playing > b.playing end)
        local targetServer = servers[1]
        
        Rayfield:Notify({
            Title = "🔥 Joining Popular Server",
            Content = string.format("Joining server with %d/%d players", targetServer.playing, targetServer.maxPlayers),
            Duration = 4,
            Image = 4483362458
        })
        
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, LocalPlayer)
    else
        Rayfield:Notify({
            Title = "❌ No Servers Found",
            Content = "Could not find any popular servers!",
            Duration = 4
        })
    end
end

-- ===================================
-- ========== TRADE BY COIN SYSTEM ===
-- ===================================

-- Variables untuk trade system
local tradeRemote = nil
local sendTradeRemote = nil
local acceptTradeRemote = nil

-- Setup trade remotes
local function setupTradeRemotes()
    pcall(function()
        tradeRemote = net:WaitForChild("RF/RequestTrade") or net:WaitForChild("RE/RequestTrade")
        sendTradeRemote = net:WaitForChild("RF/SendTradeOffer") or net:WaitForChild("RE/AddItemToTrade")
        acceptTradeRemote = net:WaitForChild("RF/AcceptTrade") or net:WaitForChild("RE/AcceptTrade")
    end)
end

-- Fungsi untuk mendapatkan ikan termurah dari inventory
local function getCheapestFish()
    local cheapestFish = nil
    local lowestPrice = math.huge
    
    pcall(function()
        if Replion then
            local DataReplion = Replion.Client:WaitReplion("Data")
            local items = DataReplion and DataReplion:Get({"Inventory","Items"})
            
            if type(items) == "table" then
                for _, item in ipairs(items) do
                    if not item.Favorited then -- Skip favorited items
                        local itemData = ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data and itemData.Data.Price then
                            local price = itemData.Data.Price
                            if price < lowestPrice then
                                lowestPrice = price
                                cheapestFish = item
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return cheapestFish, lowestPrice
end

-- Fungsi untuk menghitung jumlah ikan yang dibutuhkan
local function calculateFishAmount(targetCoins)
    local cheapestFish, fishPrice = getCheapestFish()
    
    if not cheapestFish or fishPrice == math.huge then
        return nil, 0, 0
    end
    
    local amountNeeded = math.ceil(targetCoins / fishPrice)
    return cheapestFish, fishPrice, amountNeeded
end

-- Fungsi untuk mengirim trade dengan coin target
local function sendTradeByCoin(targetPlayer, coinAmount)
    if not targetPlayer or coinAmount <= 0 then
        Rayfield:Notify({
            Title = "Trade Error",
            Content = "Invalid player or coin amount!",
            Duration = 3
        })
        return
    end
    
    local success, err = pcall(function()
        -- Get cheapest fish and calculate amount
        local cheapestFish, fishPrice, amountNeeded = calculateFishAmount(coinAmount)
        
        if not cheapestFish then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "No fish available for trade!",
                Duration = 3
            })
            return
        end
        
        local totalValue = fishPrice * amountNeeded
        
        Rayfield:Notify({
            Title = "Trade Info",
            Content = string.format("Sending %d fish (Value: $%s)", amountNeeded, tostring(totalValue)),
            Duration = 5,
            Image = 4483362458
        })
        
        -- Request trade
        tradeRemote:InvokeServer(targetPlayer)
        task.wait(0.5)
        
        -- Add fish to trade
        for i = 1, amountNeeded do
            sendTradeRemote:InvokeServer(cheapestFish.Id)
            task.wait(0.1)
        end
        
        Rayfield:Notify({
            Title = "Trade Ready",
            Content = string.format("Trade offer sent! (~$%s)", tostring(coinAmount)),
            Duration = 5,
            Image = 4483362458
        })
        
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "Trade Failed",
            Content = "Error: " .. tostring(err),
            Duration = 3
        })
    end
end

-- ===================================
-- ========== HELPER FUNCTIONS =======
-- ===================================

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
    favoriteRemote = net:WaitForChild("RE/FavoriteItem")
    
    setupTradeRemotes()
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
-- ========== AUTO FAVORITE ==========
-- ===================================

local allowedTiers = { 
    ["Secret"] = true, 
    ["Mythic"] = true, 
    ["Legendary"] = true 
}

local function startAutoFavourite()
    task.spawn(function()
        while autoFavoriteEnabled do
            pcall(function()
                if not Replion or not ItemUtility then return end
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                if type(items) ~= "table" then return end
                for _, item in ipairs(items) do
                    local base = ItemUtility:GetItemData(item.Id)
                    if base and base.Data and allowedTiers[base.Data.Tier] and not item.Favorited then
                        item.Favorited = true
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ===================================
-- ========== AUTO SELL SYSTEM =======
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
            Title = "Auto Sell Error",
            Content = "Failed to sell items: " .. tostring(err),
            Duration = 3
        })
    end
end

local function checkInventoryAndSell()
    task.spawn(function()
        while autoSellAt4000Enabled do
            pcall(function()
                local inventoryCount = 0
                
                if Replion then
                    local DataReplion = Replion.Client:WaitReplion("Data")
                    local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                    if type(items) == "table" then
                        inventoryCount = #items
                    end
                end
                
                if inventoryCount >= 4000 then
                    Rayfield:Notify({
                        Title = "Auto Sell",
                        Content = "Inventory full (4000/4000)! Selling non-favorite items...",
                        Duration = 3,
                        Image = 4483362458
                    })
                    sellNow()
                end
                
                if inventoryCount % 1000 == 0 and inventoryCount > 0 then
                    Rayfield:Notify({
                        Title = "Inventory Status",
                        Content = "Current inventory: " .. inventoryCount .. "/4000",
                        Duration = 2,
                        Image = 4483362458
                    })
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
-- ========== FISHING LOOPS ==========
-- ===================================

local function autoFishingLoop()
    while autoFishingEnabled do
        pcall(function()
            fishingActive = true
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
        task.wait(0.2)
    end
    fishingActive = false
end

local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        pcall(function()
            fishingActive = true
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
        
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
end

local function autoFishingV3Loop()
    local successPattern = {}
    
    while autoFishingV3Enabled do
        pcall(function()
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
        
        local cooldown = math.random(8, 20) / 100
        task.wait(cooldown)
    end
    fishingActive = false
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Codepikk Premium",
    LoadingTitle = "Fish It Auto Loading...",
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
local MainSection = MainTab:CreateSection("Auto Fishing")

local FishingV1Toggle = MainTab:CreateToggle({
    Name = "🎣 Auto Fishing V1 (delay)",
    CurrentValue = false,
    Flag = "FishingV1Toggle",
    Callback = function(Value)
        autoFishingEnabled = Value
        autoFishingV2Enabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V1",
                Content = "Auto Fishing V1 Started!",
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
            finishRemote:FireServer()
        end
    end,
})

local FishingV2Toggle = MainTab:CreateToggle({
    Name = "⚡ Auto Fishing V2 (X2)",
    CurrentValue = false,
    Flag = "FishingV2Toggle",
    Callback = function(Value)
        autoFishingV2Enabled = Value
        autoFishingEnabled = false
        autoFishingV3Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 X2 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV2Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V2",
                Content = "Auto Fishing V2 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local FishingV3Toggle = MainTab:CreateToggle({
    Name = "🚀 Auto Fishing V3 (X3)",
    CurrentValue = false,
    Flag = "FishingV3Toggle",
    Callback = function(Value)
        autoFishingV3Enabled = Value
        autoFishingEnabled = false
        autoFishingV2Enabled = false
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 X3 Started!",
                Duration = 3,
                Image = 4483362458
            })
            task.spawn(autoFishingV3Loop)
        else
            Rayfield:Notify({
                Title = "Auto Fishing V3",
                Content = "Auto Fishing V3 Stopped!",
                Duration = 3
            })
            fishingActive = false
            finishRemote:FireServer()
        end
    end,
})

local InventorySection = MainTab:CreateSection("Inventory Management")

MainTab:CreateButton({
    Name = "💰 Sell Now (Non-Favorite)",
    Callback = function()
        sellNow()
    end,
})

local AutoSell4000Toggle = MainTab:CreateToggle({
    Name = "🔄 Auto Sell at 4000 Fish (non fav)",
    CurrentValue = false,
    Flag = "AutoSell4000Toggle",
    Callback = function(Value)
        autoSellAt4000Enabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto sell when inventory reaches 4000 enabled!",
                Duration = 3,
                Image = 4483362458
            })
            checkInventoryAndSell()
        else
            Rayfield:Notify({
                Title = "Auto Sell 4000",
                Content = "Auto sell at 4000 disabled!",
                Duration = 3
            })
        end
    end,
})

local AutoFavoriteToggle = MainTab:CreateToggle({
    Name = "⭐ Auto Favorite (Secret/Mythic/Legendary)",
    CurrentValue = false,
    Flag = "AutoFavoriteToggle",
    Callback = function(Value)
        autoFavoriteEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Started!",
                Duration = 3,
                Image = 4483362458
            })
            startAutoFavourite()
        else
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Auto Favorite Stopped!",
                Duration = 3
            })
        end
    end,
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

-- TELEPORT TO ISLAND SECTION
local IslandSection = TeleportTab:CreateSection("TELEPORT TO ISLAND")

-- Island buttons
local islandOptions = {
    "Weather Machine", "Esoteric Depths", "Tropical Grove", 
    "Stingray Shores", "Kohana Volcano", "Coral Reefs",
    "Crater Island", "Kohana", "Winter Fest",
    "Isoteric Island", "Treasure Hall", "Lost Shore",
    "Sishypus Statue", "Ancient Jungle"
}

-- Buat buttons untuk setiap island
for _, islandName in ipairs(islandOptions) do
    TeleportTab:CreateButton({
        Name = islandName,
        Callback = function()
            teleportToIsland(islandName)
        end,
    })
end

-- TELEPORT TO EVENT SECTION
local EventSection = TeleportTab:CreateSection("TELEPORT TO EVENT")

-- Event buttons
local eventOptions = {
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
    "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
}

-- Buat buttons untuk setiap event
for _, eventName in ipairs(eventOptions) do
    TeleportTab:CreateButton({
        Name = eventName,
        Callback = function()
            teleportToEvent(eventName)
        end,
    })
end

-- ===================================
-- ========== TRADE TAB ==============
-- ===================================

local TradeTab = Window:CreateTab("💸 Trade", 4483362458)
local TradeSection = TradeTab:CreateSection("Trade by Coin")

local targetUsername = ""
local Input = TradeTab:CreateInput({
    Name = "Target Username",
    PlaceholderText = "Enter player username...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        targetUsername = Text
    end,
})

-- Quick coin buttons
local QuickCoinSection = TradeTab:CreateSection("Quick Amount")

local coinAmounts = {
    {name = "100K", value = 100000},
    {name = "500K", value = 500000},
    {name = "1M", value = 1000000},
    {name = "2M", value = 2000000},
    {name = "5M", value = 5000000},
    {name = "10M", value = 10000000},
}

for _, coinData in ipairs(coinAmounts) do
    TradeTab:CreateButton({
        Name = "Send " .. coinData.name,
        Callback = function()
            if targetUsername == "" then
                Rayfield:Notify({
                    Title = "Trade Error",
                    Content = "Please enter target username first!",
                    Duration = 3
                })
                return
            end
            
            local targetPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(targetUsername:lower()) or 
                   p.DisplayName:lower():find(targetUsername:lower()) then
                    targetPlayer = p
                    break
                end
            end
            
            if targetPlayer then
                sendTradeByCoin(targetPlayer, coinData.value)
            else
                Rayfield:Notify({
                    Title = "Player Not Found",
                    Content = "Could not find player: " .. targetUsername,
                    Duration = 3
                })
            end
        end,
    })
end

-- Custom amount
local CustomSection = TradeTab:CreateSection("Custom Amount")

local customAmount = 0
local CustomInput = TradeTab:CreateInput({
    Name = "Custom Coin Amount",
    PlaceholderText = "Enter amount (e.g., 1500000)...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        customAmount = tonumber(Text) or 0
    end,
})

TradeTab:CreateButton({
    Name = "Send Custom Amount",
    Callback = function()
        if targetUsername == "" then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Please enter target username first!",
                Duration = 3
            })
            return
        end
        
        if customAmount <= 0 then
            Rayfield:Notify({
                Title = "Trade Error",
                Content = "Please enter valid coin amount!",
                Duration = 3
            })
            return
        end
        
        local targetPlayer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetUsername:lower()) or 
               p.DisplayName:lower():find(targetUsername:lower()) then
                targetPlayer = p
                break
            end
        end
        
        if targetPlayer then
            sendTradeByCoin(targetPlayer, customAmount)
        else
            Rayfield:Notify({
                Title = "Player Not Found",
                Content = "Could not find player: " .. targetUsername,
                Duration = 3
            })
        end
    end,
})

-- Info section
local InfoSection = TradeTab:CreateSection("Information")

TradeTab:CreateLabel("📌 This feature automatically sends the cheapest fish")
TradeTab:CreateLabel("📌 to reach your target coin amount")
TradeTab:CreateLabel("📌 Favorited items will NOT be sent")
TradeTab:CreateLabel("⚠️ Make sure you have enough fish in inventory!")

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

local NoClipToggle = MiscTab:CreateToggle({
    Name = "👻 No Clip (Tembus Benda)",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        toggleNoClip()
    end,
})

local BoostFPSButton = MiscTab:CreateButton({
    Name = "🚀 Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

-- Server Hop Section in Misc Tab
local ServerSection = MiscTab:CreateSection("🌐 Server Hop")

MiscTab:CreateButton({
    Name = "👥 Join Empty Server",
    Callback = function()
        joinLowestPopulationServer()
    end,
})

MiscTab:CreateButton({
    Name = "🍀 Join Server With Luck",
    Callback = function()
        joinServerWithLuck()
    end,
})

MiscTab:CreateButton({
    Name = "🔥 Join Popular Server", 
    Callback = function()
        joinPopularServer()
    end,
})

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Fish It Auto V2.5 + No Clip loaded successfully!",
    Duration = 5,
    Image = 4483362458
})

Rayfield:LoadConfiguration()
    

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
warn("⏰ Trial Keys: " .. #KeySystemExpiredKeys)

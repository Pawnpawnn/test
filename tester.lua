-- ===================================
-- ========== LOCAL KEY SYSTEM ==============
-- ===================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


-- 50 Local Keys (masing-masing untuk 1 device)
local validKeys = {
    ["CPK-ALPHA-7392-BETA"] = {used = false, hwid = nil},
    ["CPK-GAMMA-4856-DELTA"] = {used = false, hwid = nil},
    ["CPK-OMEGA-1274-SIGMA"] = {used = false, hwid = nil},
    ["CPK-ZETA-6621-THETA"] = {used = false, hwid = nil},
    ["CPK-NOVA-8843-STAR"] = {used = false, hwid = nil},
    ["CPK-LUNA-2397-MOON"] = {used = false, hwid = nil},
    ["CPK-SOLAR-5512-SUN"] = {used = false, hwid = nil},
    ["CPK-GALAX-7736-MILKY"] = {used = false, hwid = nil},
    ["CPK-COSMO-9165-SPACE"] = {used = false, hwid = nil},
    ["CPK-QUANT-3489-ATOM"] = {used = false, hwid = nil},
    ["CPK-NEBULA-5821-DUST"] = {used = false, hwid = nil},
    ["CPK-ORION-7749-BELT"] = {used = false, hwid = nil},
    ["CPK-APOLLO-3367-SUN"] = {used = false, hwid = nil},
    ["CPK-ATLAS-9982-WORLD"] = {used = false, hwid = nil},
    ["CPK-ZEUS-4412-GOD"] = {used = false, hwid = nil},
    ["CPK-HERA-6678-QUEEN"] = {used = false, hwid = nil},
    ["CPK-POSEID-2235-SEA"] = {used = false, hwid = nil},
    ["CPK-HADES-8841-UNDER"] = {used = false, hwid = nil},
    ["CPK-ARES-5567-WAR"] = {used = false, hwid = nil},
    ["CPK-ATHENA-7723-WISDOM"] = {used = false, hwid = nil},
    ["CPK-APOLLO-1198-MUSIC"] = {used = false, hwid = nil},
    ["CPK-ARTEMIS-6634-MOON"] = {used = false, hwid = nil},
    ["CPK-HERMES-2255-SPEED"] = {used = false, hwid = nil},
    ["CPK-DIONYS-9947-WINE"] = {used = false, hwid = nil},
    ["CPK-PERSEUS-3376-HERO"] = {used = false, hwid = nil},
    ["CPK-HERCULES-5582-STR"] = {used = false, hwid = nil},
    ["CPK-THOR-7721-HAMMER"] = {used = false, hwid = nil},
    ["CPK-LOKI-4469-TRICK"] = {used = false, hwid = nil},
    ["CPK-ODIN-8832-ALLFATHER"] = {used = false, hwid = nil},
    ["CPK-FREYA-1145-LOVE"] = {used = false, hwid = nil},
    ["CPK-VALKYRIE-6673-WAR"] = {used = false, hwid = nil},
    ["CPK-DRAGON-9921-FIRE"] = {used = false, hwid = nil},
    ["CPK-PHOENIX-3388-RISE"] = {used = false, hwid = nil},
    ["CPK-GRIFFIN-5546-GUARD"] = {used = false, hwid = nil},
    ["CPK-UNICORN-7788-MAGIC"] = {used = false, hwid = nil},
    ["CPK-CYBER-1123-TECH"] = {used = false, hwid = nil},
    ["CPK-NINJA-4456-SHADOW"] = {used = false, hwid = nil},
    ["CPK-SAMURAI-8897-HONOR"] = {used = false, hwid = nil},
    ["CPK-VIKING-2234-RAID"] = {used = false, hwid = nil},
    ["CPK-WIZARD-6675-SPELL"] = {used = false, hwid = nil},
    ["CPK-ROGUE-9912-STEALTH"] = {used = false, hwid = nil},
    ["CPK-PALADIN-3347-LIGHT"] = {used = false, hwid = nil},
    ["CPK-BERSERK-5588-RAGE"] = {used = false, hwid = nil},
    ["CPK-ARCHER-7722-AIM"] = {used = false, hwid = nil},
    ["CPK-MAGE-1167-POWER"] = {used = false, hwid = nil},
    ["CPK-KNIGHT-4433-SHIELD"] = {used = false, hwid = nil},
    ["CPK-PIRATE-8867-SEA"] = {used = false, hwid = nil},
    ["CPK-ROYAL-2298-CROWN"] = {used = false, hwid = nil},
    ["CPK-LEGEND-5544-MYTH"] = {used = false, hwid = nil},
    ["CPK-EPIC-8876-STORY"] = {used = false, hwid = nil}
}

-- Fungsi untuk mendapatkan Hardware ID sederhana
local function getHardwareID()
    local hwid = ""
    
    -- Gabungkan beberapa identifier system
    pcall(function()
        -- Dari game (jika available)
        if game:GetService("RbxAnalyticsService"):GetClientId() then
            hwid = hwid .. game:GetService("RbxAnalyticsService"):GetClientId()
        end
    end)
    
    pcall(function()
        -- Dari player (userid + account age)
        hwid = hwid .. tostring(player.UserId) .. tostring(player.AccountAge)
    end)
    
    pcall(function()
        -- Dari system (jika executor support)
        if syn and syn.crypt.hash then
            hwid = hwid .. syn.crypt.hash(hwid)
        end
    end)
    
    -- Hash final untuk konsistensi
    if #hwid > 0 then
        return string.sub(tostring(string.gsub(hwid, "%W", "")), 1, 16)
    end
    
    return "DEFAULT_HWID_" .. tostring(player.UserId)
end

local currentHWID = getHardwareID()

-- Validate key lokal
local function validateLocalKey(key)
    if not validKeys[key] then
        return false, "❌ Invalid key"
    end
    
    local keyData = validKeys[key]
    
    -- Jika key sudah digunakan
    if keyData.used then
        -- Cek apakah digunakan di device yang sama
        if keyData.hwid == currentHWID then
            return true, "✅ Key validated (same device)"
        else
            return false, "❌ Key already used on another device"
        end
    end
    
    -- Jika key belum digunakan, assign ke device ini
    keyData.used = true
    keyData.hwid = currentHWID
    
    return true, "✅ Key activated successfully!"
end

-- Cek apakah user sudah pernah activate key di device ini
local function checkExistingActivation()
    for key, keyData in pairs(validKeys) do
        if keyData.used and keyData.hwid == currentHWID then
            return true, key
        end
    end
    return false, nil
end

-- Tampilkan input key
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeyInputGUI"
keyGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
mainFrame.Parent = keyGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
title.Text = "🔑 Codepik Premium"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(100, 180, 255)
title.TextSize = 18
title.Parent = mainFrame

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(0.9, 0, 0, 30)
hwidLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Text = "Device ID: " .. string.sub(currentHWID, 1, 8) .. "..."
hwidLabel.Font = Enum.Font.Gotham
hwidLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hwidLabel.TextSize = 11
hwidLabel.Parent = mainFrame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 40)
keyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
keyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
keyBox.PlaceholderText = "Enter your premium key..."
keyBox.Text = ""
keyBox.Font = Enum.Font.Gotham
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 14
keyBox.Parent = mainFrame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.6, 0, 0, 40)
submitBtn.Position = UDim2.new(0.2, 0, 0.55, 0)
submitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
submitBtn.Text = "Activate Key"
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 14
submitBtn.Parent = mainFrame

local statusMsg = Instance.new("TextLabel")
statusMsg.Size = UDim2.new(0.8, 0, 0, 40)
statusMsg.Position = UDim2.new(0.1, 0, 0.75, 0)
statusMsg.BackgroundTransparency = 1
statusMsg.Text = "Enter your premium key to continue"
statusMsg.Font = Enum.Font.Gotham
statusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
statusMsg.TextSize = 12
statusMsg.TextWrapped = true
statusMsg.Parent = mainFrame

-- Fungsi untuk load script utama
local function loadMainScript()
    keyGui:Destroy()
    
    -- Clear semua GUI existing dulu
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "Chat" and gui.Name ~= "PlayerList" then
            gui:Destroy()
        end
    end
    
    wait(0.5) -- Biar clear sempurna
    
    -- Load dari Gist kamu
    local gistUrl = "https://gist.githubusercontent.com/Pawnpawnn/322b40a87a52f2feba1edb2cc1177b17/raw"
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(gistUrl))()
    end)
    
    if not success then
        player:Kick("Failed to load script: " .. tostring(err))
    end
end

-- Button events
submitBtn.MouseButton1Click:Connect(function()
    local key = string.upper(string.gsub(keyBox.Text, "%s+", ""))
    
    if string.len(key) < 5 then
        statusMsg.Text = "❌ Please enter a valid key"
        statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    statusMsg.Text = "⏳ Validating key..."
    statusMsg.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    local isValid, message = validateLocalKey(key)
    
    if isValid then
        statusMsg.Text = message
        statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(1)
        loadMainScript()
    else
        statusMsg.Text = message
        statusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Auto check jika sudah ada aktivasi
local hasActivation, activatedKey = checkExistingActivation()
if hasActivation then
    statusMsg.Text = "✅ Already activated with key: " .. string.sub(activatedKey, 1, 8) .. "..."
    statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
    wait(2)
    loadMainScript()
else
    statusMsg.Text = "🔑 Enter your premium key\n10 keys available • 1 key per device"
    statusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
end

warn("🔑 Local Key System Loaded - HWID: " .. currentHWID)
warn("📝 Available Keys: " .. #validKeys .. " keys • 1 device per key")

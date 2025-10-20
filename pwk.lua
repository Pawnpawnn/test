-- ===================================
-- ========== KEY SYSTEM ==============
-- ===================================
local KeySystemPlayers = game:GetService("Players")
local KeySystemHttpService = game:GetService("HttpService")
local KeySystemPlayer = KeySystemPlayers.LocalPlayer
local KeySystemPlayerGui = KeySystemPlayer:WaitForChild("PlayerGui")

-- 50 Local Keys (masing-masing untuk 1 device)
local KeySystemValidKeys = {
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
local function KeySystemGetHardwareID()
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
        hwid = hwid .. tostring(KeySystemPlayer.UserId) .. tostring(KeySystemPlayer.AccountAge)
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
    
    return "DEFAULT_HWID_" .. tostring(KeySystemPlayer.UserId)
end

local KeySystemCurrentHWID = KeySystemGetHardwareID()

-- Validate key lokal
local function KeySystemValidateLocalKey(key)
    if not KeySystemValidKeys[key] then
        return false, "❌ Invalid key"
    end
    
    local keyData = KeySystemValidKeys[key]
    
    -- Jika key sudah digunakan
    if keyData.used then
        -- Cek apakah digunakan di device yang sama
        if keyData.hwid == KeySystemCurrentHWID then
            return true, "✅ Key validated (same device)"
        else
            return false, "❌ Key already used on another device"
        end
    end
    
    -- Jika key belum digunakan, assign ke device ini
    keyData.used = true
    keyData.hwid = KeySystemCurrentHWID
    
    return true, "✅ Key activated successfully!"
end

-- Cek apakah user sudah pernah activate key di device ini
local function KeySystemCheckExistingActivation()
    for key, keyData in pairs(KeySystemValidKeys) do
        if keyData.used and keyData.hwid == KeySystemCurrentHWID then
            return true, key
        end
    end
    return false, nil
end

-- Tampilkan input key
local KeySystemGui = Instance.new("ScreenGui")
KeySystemGui.Name = "KeySystemInputGUI"
KeySystemGui.Parent = KeySystemPlayerGui

local KeySystemMainFrame = Instance.new("Frame")
KeySystemMainFrame.Size = UDim2.new(0, 400, 0, 300)
KeySystemMainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
KeySystemMainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
KeySystemMainFrame.Parent = KeySystemGui

local KeySystemCorner = Instance.new("UICorner")
KeySystemCorner.CornerRadius = UDim.new(0, 12)
KeySystemCorner.Parent = KeySystemMainFrame

local KeySystemTitle = Instance.new("TextLabel")
KeySystemTitle.Size = UDim2.new(1, 0, 0, 60)
KeySystemTitle.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
KeySystemTitle.Text = "🔑 Codepik Premium"
KeySystemTitle.Font = Enum.Font.GothamBold
KeySystemTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
KeySystemTitle.TextSize = 18
KeySystemTitle.Parent = KeySystemMainFrame

local KeySystemHWIDLabel = Instance.new("TextLabel")
KeySystemHWIDLabel.Size = UDim2.new(0.9, 0, 0, 30)
KeySystemHWIDLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
KeySystemHWIDLabel.BackgroundTransparency = 1
KeySystemHWIDLabel.Text = "Device ID: " .. string.sub(KeySystemCurrentHWID, 1, 8) .. "..."
KeySystemHWIDLabel.Font = Enum.Font.Gotham
KeySystemHWIDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
KeySystemHWIDLabel.TextSize = 11
KeySystemHWIDLabel.Parent = KeySystemMainFrame

local KeySystemKeyBox = Instance.new("TextBox")
KeySystemKeyBox.Size = UDim2.new(0.8, 0, 0, 40)
KeySystemKeyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
KeySystemKeyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
KeySystemKeyBox.PlaceholderText = "Enter your premium key..."
KeySystemKeyBox.Text = ""
KeySystemKeyBox.Font = Enum.Font.Gotham
KeySystemKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemKeyBox.TextSize = 14
KeySystemKeyBox.Parent = KeySystemMainFrame

local KeySystemSubmitBtn = Instance.new("TextButton")
KeySystemSubmitBtn.Size = UDim2.new(0.6, 0, 0, 40)
KeySystemSubmitBtn.Position = UDim2.new(0.2, 0, 0.55, 0)
KeySystemSubmitBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
KeySystemSubmitBtn.Text = "Activate Key"
KeySystemSubmitBtn.Font = Enum.Font.GothamBold
KeySystemSubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemSubmitBtn.TextSize = 14
KeySystemSubmitBtn.Parent = KeySystemMainFrame

local KeySystemStatusMsg = Instance.new("TextLabel")
KeySystemStatusMsg.Size = UDim2.new(0.8, 0, 0, 40)
KeySystemStatusMsg.Position = UDim2.new(0.1, 0, 0.75, 0)
KeySystemStatusMsg.BackgroundTransparency = 1
KeySystemStatusMsg.Text = "Enter your premium key to continue"
KeySystemStatusMsg.Font = Enum.Font.Gotham
KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
KeySystemStatusMsg.TextSize = 12
KeySystemStatusMsg.TextWrapped = true
KeySystemStatusMsg.Parent = KeySystemMainFrame

-- Fungsi untuk load script utama
local function KeySystemLoadMainScript()
    KeySystemGui:Destroy()
    
    -- Clear existing GUI
    if KeySystemPlayerGui:FindFirstChild("FishItAutoGUI") then
        KeySystemPlayerGui:FindFirstChild("FishItAutoGUI"):Destroy()
    end
    
    wait(0.3)
    
    -- Load main script dari Gist
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/Pawnpawnn/322b40a87a52f2feba1edb2cc1177b17/raw"))()
    end)
    
    if not success then
        KeySystemPlayer:Kick("Failed to load main script: " .. tostring(err))
    end
end

-- Button events
KeySystemSubmitBtn.MouseButton1Click:Connect(function()
    local key = string.upper(string.gsub(KeySystemKeyBox.Text, "%s+", ""))
    
    if string.len(key) < 5 then
        KeySystemStatusMsg.Text = "❌ Please enter a valid key"
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    KeySystemStatusMsg.Text = "⏳ Validating key..."
    KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    local isValid, message = KeySystemValidateLocalKey(key)
    
    if isValid then
        KeySystemStatusMsg.Text = message
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
        wait(1)
        KeySystemLoadMainScript()
    else
        KeySystemStatusMsg.Text = message
        KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Auto check jika sudah ada aktivasi
local KeySystemHasActivation, KeySystemActivatedKey = KeySystemCheckExistingActivation()
if KeySystemHasActivation then
    KeySystemStatusMsg.Text = "✅ Already activated with key: " .. string.sub(KeySystemActivatedKey, 1, 8) .. "..."
    KeySystemStatusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
    wait(2)
    KeySystemLoadMainScript()
else
    KeySystemStatusMsg.Text = "🔑 Enter your premium key\n50 keys available • 1 key per device"
    KeySystemStatusMsg.TextColor3 = Color3.fromRGB(255, 255, 255)
end

warn("🔑 Local Key System Loaded - HWID: " .. KeySystemCurrentHWID)
warn("📝 Available Keys: " .. #KeySystemValidKeys .. " keys • 1 device per key")
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

-------------------------------------------
----- =======[ Load WindUI ] =======
-------------------------------------------

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-------------------------------------------
----- =======[ GLOBAL FUNCTION ] =======
-------------------------------------------

local Notifs = {
	WBN = true,
	FavBlockNotif = true,
	FishBlockNotif = true,
	DelayBlockNotif = true,
	AFKBN = true,
	APIBN = true
}

-- State table for new features
local state = { 
    AutoFavourite = false, 
    AutoSell = false 
}

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

setupRemotes()

local Player = Players.LocalPlayer
local XPBar = Player:WaitForChild("PlayerGui"):WaitForChild("XP")

Player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

task.spawn(function()
    if XPBar then
        XPBar.Enabled = true
    end
end)

local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId

local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

local RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
local RodReel = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
local RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodShakeAnim = animator:LoadAnimation(RodShake)
local RodIdleAnim = animator:LoadAnimation(RodIdle)
local RodReelAnim = animator:LoadAnimation(RodReel)

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-------------------------------------------
----- =======[ AUTO BOOST FPS ] =======
-------------------------------------------
local function BoostFPS()
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
end

BoostFPS() -- Activate FPS Boost on script execution

-------------------------------------------
----- =======[ NOTIFY FUNCTION ] =======
-------------------------------------------

local function NotifySuccess(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "circle-check"
    })
end

local function NotifyError(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "ban"
    })
end

local function NotifyInfo(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "info"
    })
end

local function NotifyWarning(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "triangle-alert"
    })
end

-------------------------------------------
----- =======[ LOAD WINDOW ] =======
-------------------------------------------

local Window = WindUI:CreateWindow({
    Title = "Fish It Premium v2.5",
    Icon = "fish",
    Author = "by Codepikk",
    Folder = "FishItPremium",
    Size = UDim2.fromOffset(600, 500),
    Theme = "Dark",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

WindUI:SetNotificationLower(true)

WindUI:Notify({
	Title = "Fish It Premium v2.5",
	Content = "All Features Loaded Successfully!",
	Duration = 5,
	Icon = "circle-check"
})

-------------------------------------------
----- =======[ MAIN TABS ] =======
-------------------------------------------

local AutoFishTab = Window:Tab({
	Title = "Auto Fishing",
	Icon = "fish"
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin"
})

local UtilityTab = Window:Tab({
	Title = "Utility", 
	Icon = "settings" 
})

-------------------------------------------
----- =======[ AUTO FISHING TAB ] =======
-------------------------------------------

local AutoFishSection = AutoFishTab:Section({
	Title = "Fishing Automation",
	Icon = "fish"
})

-- State variables untuk fishing
local FuncAutoFishV2 = {
	REReplicateTextEffectV2 = net:WaitForChild("RE/ReplicateTextEffect"),
	autofishV2 = false,
	perfectCastV2 = true,
	fishingActiveV2 = false,
	delayInitializedV2 = false
}

local RodDelaysV2 = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8},
    ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1},
    ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local customDelayV2 = 1
local BypassDelayV2 = 0.5

local function getValidRodNameV2()
    local player = Players.LocalPlayer
    local display = player.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        local success, itemNamePath = pcall(function()
            return tile.Inner.Tags.ItemName
        end)
        if success and itemNamePath and itemNamePath:IsA("TextLabel") then
            local name = itemNamePath.Text
            if RodDelaysV2[name] then
                return name
            end
        end
    end
    return nil
end

local function updateDelayBasedOnRodV2(showNotify)
    if FuncAutoFishV2.delayInitializedV2 then return end
    local rodName = getValidRodNameV2()
    if rodName and RodDelaysV2[rodName] then
        customDelayV2 = RodDelaysV2[rodName].custom
        BypassDelayV2 = RodDelaysV2[rodName].bypass
        FuncAutoFishV2.delayInitializedV2 = true
        if showNotify and FuncAutoFishV2.autofishV2 then
            NotifySuccess("Rod Detected", string.format("Detected Rod: %s | Delay: %.2fs | Bypass: %.2fs", rodName, customDelayV2, BypassDelayV2))
        end
    else
        customDelayV2 = 10
        BypassDelayV2 = 1
        FuncAutoFishV2.delayInitializedV2 = true
        if showNotify and FuncAutoFishV2.autofishV2 then
            NotifyWarning("Rod Detection Failed", "No valid rod found. Default delay applied.")
        end
    end
end

local function setupRodWatcher()
    local player = Players.LocalPlayer
    local display = player.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    display.ChildAdded:Connect(function()
        task.wait(0.05)
        if not FuncAutoFishV2.delayInitializedV2 then
            updateDelayBasedOnRodV2(true)
        end
    end)
end
setupRodWatcher()

-- Auto Fishing V1 System
local function autoFishingLoop()
    while autoFishingEnabled do
        local ok, err = pcall(function()
            fishingActive = true
            NotifyInfo("Fishing Status", "🎣 Auto Fishing V1 Active")
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
    NotifyWarning("Fishing Status", "🔴 Auto Fishing Stopped")
end

-- Auto Fishing V2 System
local function autoFishingV2Loop()
    while autoFishingV2Enabled do
        local ok, err = pcall(function()
            fishingActive = true
            
            equipRemote:FireServer(1)
            task.wait(0.1)

            local timestamp = workspace:GetServerTimeNow()
            RodShakeAnim:Play()
            rodRemote:InvokeServer(timestamp)

            local baseX, baseY = -0.7499996, 1
            local x, y
            if FuncAutoFishV2.perfectCastV2 then
                x = baseX + (math.random(-500, 500) / 10000000)
                y = baseY + (math.random(-500, 500) / 10000000)
            else
                x = math.random(-1000, 1000) / 1000
                y = math.random(0, 1000) / 1000
            end

            RodIdleAnim:Play()
            miniGameRemote:InvokeServer(x, y)

            task.wait(customDelayV2)
            finishRemote:FireServer(true)
            task.wait(0.3)
            finishRemote:FireServer()
        end)
        
        if not ok then
            -- Error handling silent
        end
        
        task.wait(math.random(10, 30) / 100)
    end
    fishingActive = false
    RodIdleAnim:Stop()
    RodShakeAnim:Stop()
    RodReelAnim:Stop()
    NotifyWarning("Fishing Status", "🔴 Auto Fishing V2 Stopped")
end

-- Exclaim Detection untuk V2
FuncAutoFishV2.REReplicateTextEffectV2.OnClientEvent:Connect(function(data)
    if (autoFishingEnabled or autoFishingV2Enabled) and data and data.TextData
    and data.TextData.EffectType == "Exclaim" then

        local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
        if myHead and data.Container == myHead then
            task.spawn(function()
                if autoFishingV2Enabled then
                    task.wait(0.1)
                    finishRemote:FireServer()
                else
                    for i = 1, 3 do
                        task.wait(1)
                        finishRemote:FireServer()
                    end
                end
            end)
        end
    end
end)

-- Auto Sell System
local lastSellTime = 0
local AUTO_SELL_THRESHOLD = 60
local AUTO_SELL_DELAY = 60

local function startAutoSell()
    task.spawn(function()
        while autoSellEnabled do
            pcall(function()
                local sellSuccess = pcall(function()
                    sellRemote:InvokeServer()
                end)

                if sellSuccess and os.time() - lastSellTime >= AUTO_SELL_DELAY then
                    NotifyInfo("Auto Sell", "Sold non-favorited items successfully")
                    lastSellTime = os.time()
                end
            end)
            task.wait(10)
        end
    end)
end

-- Auto Favorite System
local allowedTiers = { 
    ["Secret"] = true, 
    ["Mythic"] = true, 
    ["Legendary"] = true 
}

local function startAutoFavorite()
    task.spawn(function()
        while autoFavoriteEnabled do
            pcall(function()
                NotifyInfo("Auto Favorite", "⭐ Scanning items...")
                
                local totalFavorited = 0
                
                -- METHOD 1: Coba Replion System
                local success1, replionData = pcall(function()
                    return Replion and Replion.Client:WaitReplion("Data")
                end)
                
                if success1 and replionData then
                    local items = replionData:Get({"Inventory", "Items"})
                    if type(items) == "table" then
                        for _, item in ipairs(items) do
                            if not autoFavoriteEnabled then break end
                            
                            local itemData = ItemUtility and ItemUtility:GetItemData(item.Id)
                            
                            if itemData and itemData.Data and allowedTiers[itemData.Data.Tier] and not item.Favorited then
                                item.Favorited = true
                                totalFavorited = totalFavorited + 1
                                task.wait(0.2)
                            end
                        end
                    end
                    
                -- METHOD 2: Coba Remote Events
                else
                    local favoriteRemote = ReplicatedStorage:FindFirstChild("FavoriteItem") or
                                         ReplicatedStorage:FindFirstChild("ToggleFavorite")
                    
                    if favoriteRemote then
                        for itemId = 1, 50 do
                            if not autoFavoriteEnabled then break end
                            favoriteRemote:FireServer(itemId)
                            totalFavorited = totalFavorited + 1
                            task.wait(0.1)
                        end
                    end
                end
                
                if totalFavorited > 0 then
                    NotifySuccess("Auto Favorite", "✅ Fav: " .. totalFavorited .. " items")
                else
                    NotifyInfo("Auto Favorite", "ℹ️ No items to favorite")
                end
            end)
            
            for i = 1, 20 do
                if not autoFavoriteEnabled then break end
                task.wait(0.5)
            end
        end
        NotifyWarning("Auto Favorite", "🔴 Auto Favorite Stopped")
    end)
end

-- Fishing Controls
AutoFishSection:Toggle({
	Title = "Auto Fish V1 (Stable)",
	Content = "Classic fishing with perfect catch + delay",
	Callback = function(value)
		autoFishingEnabled = value
        autoFishingV2Enabled = false
        
        if value then
            NotifySuccess("Auto Fishing", "🎣 Auto Fishing V1 Started")
            task.spawn(autoFishingLoop)
        else
            fishingActive = false
            finishRemote:FireServer()
        end
	end
})

AutoFishSection:Toggle({
	Title = "Auto Fish V2 (Fast)",
	Content = "Ultra fast fishing with rod detection",
	Callback = function(value)
		autoFishingV2Enabled = value
        autoFishingEnabled = false
        
        if value then
            updateDelayBasedOnRodV2(true)
            NotifySuccess("Auto Fishing", "⚡ Auto Fishing V2 Started")
            task.spawn(autoFishingV2Loop)
        else
            fishingActive = false
            finishRemote:FireServer()
        end
	end
})

AutoFishSection:Toggle({
    Title = "Auto Perfect Cast",
    Content = "Automatically achieve perfect casting",
    Value = true,
    Callback = function(value)
        FuncAutoFishV2.perfectCastV2 = value
    end
})

AutoFishSection:Input({
	Title = "Bypass Delay",
	Content = "Adjust delay between catches (for V2 system)",
	Placeholder = "Example: 1.45",
	Callback = function(value)
		local number = tonumber(value)
		if number then
		  BypassDelayV2 = number
			NotifySuccess("Bypass Delay", "Bypass Delay set to " .. number)
		else
		  NotifyError("Invalid Input", "Failed to convert input to number.")
		end
	end,
})

-- Auto Systems Section
local AutoSystemsSection = AutoFishTab:Section({
	Title = "Auto Systems",
	Icon = "settings"
})

AutoSystemsSection:Toggle({
    Title = "Auto Sell",
    Content = "Automatically sells non-favorited fish",
    Callback = function(value)
        autoSellEnabled = value
        if value then
            NotifySuccess("Auto Sell", "💰 Auto Sell Enabled")
            startAutoSell()
        else
            NotifyWarning("Auto Sell", "🔴 Auto Sell Disabled")
        end
    end
})

AutoSystemsSection:Toggle({
    Title = "Auto Favorite",
    Content = "Auto-favorite Secret/Mythic/Legendary items",
    Callback = function(value)
        autoFavoriteEnabled = value
        if value then
            NotifySuccess("Auto Favorite", "⭐ Auto Favorite Enabled")
            startAutoFavorite()
        else
            NotifyWarning("Auto Favorite", "🔴 Auto Favorite Disabled")
        end
    end
})

-- Manual Actions Section
local ManualSection = AutoFishTab:Section({
	Title = "Manual Actions",
	Icon = "hand"
})

ManualSection:Button({
    Title = "Sell All Fishes",
    Content = "Manually sell all non-favorited fish",
    Callback = function()
        local success, err = pcall(function()
            sellRemote:InvokeServer()
        end)

        if success then
            NotifySuccess("Manual Sell", "✅ All fish sold successfully!")
        else
            NotifyError("Sell Failed", "❌ Failed to sell fish")
        end
    end
})

ManualSection:Button({
    Title = "Boost FPS",
    Content = "Optimize game performance",
    Callback = function()
        BoostFPS()
        NotifySuccess("FPS Boost", "🚀 FPS Boosted Successfully")
    end
})

-------------------------------------------
----- =======[ TELEPORT TAB ] =======
-------------------------------------------

local IslandsSection = TeleportTab:Section({
	Title = "Island Teleport",
	Icon = "map-pin"
})

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

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

IslandsSection:Dropdown({
    Title = "Island Teleport",
    Content = "Quick teleport to different islands",
    Values = islandNames,
    Callback = function(selectedName)
        local position = islandCoords[selectedName]
        if position then
            local success, err = pcall(function()
                local charFolder = workspace:WaitForChild("Characters", 5)
                local char = charFolder:FindFirstChild(player.Name)
                if not char then error("Character not found") end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then error("HumanoidRootPart not found") end
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
            end)

            if success then
                NotifySuccess("Teleported!", "You are now at " .. selectedName)
            else
                NotifyError("Teleport Failed", tostring(err))
            end
        end
    end
})

-- NPC Teleport Section
local NPCSection = TeleportTab:Section({
	Title = "NPC Teleport",
	Icon = "users"
})

local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
local npcList = {}

if npcFolder then
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                table.insert(npcList, npc.Name)
            end
        end
    end
    table.sort(npcList)
end

NPCSection:Dropdown({
	Title = "NPC Teleport",
	Content = "Teleport to specific NPCs",
	Values = npcList,
	Callback = function(selectedName)
		local npc = npcFolder:FindFirstChild(selectedName)
		if npc and npc:IsA("Model") then
			local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			if hrp then
				local charFolder = workspace:FindFirstChild("Characters")
				local char = charFolder and charFolder:FindFirstChild(player.Name)
				if not char then return end
				local myHRP = char:FindFirstChild("HumanoidRootPart")
				if myHRP then
					myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
					NotifySuccess("Teleported!", "You are now near: " .. selectedName)
				end
			end
		end
	end
})

-- Events Teleport Section
local EventsSection = TeleportTab:Section({
	Title = "Event Teleport",
	Icon = "calendar"
})

local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

EventsSection:Dropdown({
    Title = "Event Teleport",
    Content = "Teleport to active events",
    Values = eventsList,
    Callback = function(option)
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

        local eventObject = findEventLocation(option)
        
        if eventObject then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local success, err = pcall(function()
                    local fishingBoat = eventObject:FindFirstChild("Fishing Boat")
                    if fishingBoat then
                        hrp.CFrame = fishingBoat:GetPivot() + Vector3.new(0, 15, 0)
                        NotifySuccess("Event Teleport", "✅ Teleport ke Fishing Boat " .. option)
                    else
                        hrp.CFrame = eventObject:GetPivot() + Vector3.new(0, 10, 0)
                        NotifySuccess("Event Teleport", "✅ Teleport ke " .. option)
                    end
                end)

                if not success then
                    NotifyError("Teleport Failed", "❌ Gagal teleport: " .. tostring(err))
                end
            else
                NotifyError("Teleport Failed", "❌ HRP tidak ditemukan")
            end
        else
            NotifyError("Event Not Found", "❌ " .. option .. " tidak ditemukan\nPastikan event sedang ACTIVE")
        end
    end
})

-------------------------------------------
----- =======[ UTILITY TAB ] =======
-------------------------------------------

-- Anti-AFK Section
local AFKSection = UtilityTab:Section({
	Title = "Anti-AFK System",
	Icon = "user-x"
})

AFKSection:Toggle({
	Title = "Anti-AFK",
	Content = "Prevent automatic disconnection",
	Value = false,
	Callback = function(Value)
		antiAFKEnabled = Value
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

			NotifySuccess("Anti-AFK", "⏰ Anti-AFK Activated")

		else
			if AFKConnection then
				AFKConnection:Disconnect()
				AFKConnection = nil
			end

			NotifyWarning("Anti-AFK", "🔴 Anti-AFK Deactivated")
		end
	end,
})

-- Server Utility Section
local ServerSection = UtilityTab:Section({
	Title = "Server Utility",
	Icon = "server"
})

ServerSection:Button({
	Title = "Rejoin Server",
	Content = "Rejoin current server",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, player)
	end,
})

ServerSection:Button({
	Title = "Server Hop",
	Content = "Join a new server",
	Callback = function()
		local placeId = game.PlaceId
		local servers = {}
		local cursor = ""

		repeat
			local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
			if cursor ~= "" then
				url = url .. "&cursor=" .. cursor
			end

			local success, result = pcall(function()
				return HttpService:JSONDecode(game:HttpGet(url))
			end)

			if success and result and result.data then
				for _, server in pairs(result.data) do
					if server.playing < server.maxPlayers and server.id ~= game.JobId then
						table.insert(servers, server.id)
					end
				end
				cursor = result.nextPageCursor or ""
			else
				break
			end
		until not cursor or #servers > 0

		if #servers > 0 then
			local targetServer = servers[math.random(1, #servers)]
			TeleportService:TeleportToPlaceInstance(placeId, targetServer, player)
		else
			NotifyError("Server Hop", "No servers available or all are full!")
		end
	end,
})

-- Information Section
local InfoSection = UtilityTab:Section({
	Title = "Script Information",
	Icon = "info"
})

InfoSection:Label({
	Title = "Version",
	Content = "Fish It Premium v2.5"
})

InfoSection:Label({
	Title = "Developer",
	Content = "Codepikk"
})

InfoSection:Label({
	Title = "Discord",
	Content = "codepikk"
})

InfoSection:Paragraph({
	Title = "About",
	Content = "Advanced fishing automation script with comprehensive features for maximum efficiency and convenience."
})

-- Final Notification
WindUI:Notify({
	Title = "Fish It Premium v2.5",
	Content = "Script loaded successfully! Press RightControl to toggle UI.",
	Duration = 6,
	Icon = "circle-check"
})

print("🎯 Fish It Premium v2.5 - Wind UI Loaded Successfully!")

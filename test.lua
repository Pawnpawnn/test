-- Codepik Premium - Rayfield UI Version (Single File Complete)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- GLOBAL VARIABLES & SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local net = ReplicatedStorage:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")

-- NOTIFICATION FUNCTIONS
local function NotifySuccess(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Image = 4483362458
    })
end

local function NotifyError(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Image = 4483362458
    })
end

local function NotifyInfo(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Image = 4483362458
    })
end

local function NotifyWarning(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Image = 4483362458
    })
end

-- CREATE WINDOW
local Window = Rayfield:CreateWindow({
	Name = "Codepik - Premium",
	LoadingTitle = "Codepik Premium",
	LoadingSubtitle = "by Codepik",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CodepikConfig",
		FileName = "QuietXConfig"
	},
	Discord = {
		Enabled = false,
		Invite = "your_invite_code",
		RememberJoins = true
	},
	KeySystem = false,
})

-- ANTI-AFK SETUP
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

-- AUTO RECONNECT
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
end
task.spawn(AutoReconnect)

-- HOME TAB
local HomeTab = Window:CreateTab("Home", 4483362458)
local HomeSection = HomeTab:CreateSection("Developer Info")

HomeSection:CreateLabel("Codepik Premium v1.6.45")
HomeSection:CreateLabel("All Features Loaded!")
HomeSection:CreateParagraph("Welcome", "Thank you for using Codepik Premium! All features are now available.")

-- AUTO FISH SYSTEM
local AutoFishTab = Window:CreateTab("Auto Fish", 4483362458)

-- Fishing Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")

-- Animation Setup
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodShakeAnim = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")
local RodIdleAnim = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")

local RodShake = animator:LoadAnimation(RodShakeAnim)
local RodIdle = animator:LoadAnimation(RodIdleAnim)

-- Auto Fish Variables
local FuncAutoFishV2 = {
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
local obtainedLimitV2 = 30
local obtainedFishUUIDsV2 = {}

-- Rod Detection
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
            NotifySuccess("Rod Detected (V2)", string.format("Detected Rod: %s | Delay: %.2fs | Bypass: %.2fs", rodName, customDelayV2, BypassDelayV2))
        end
    else
        customDelayV2 = 10
        BypassDelayV2 = 1
        FuncAutoFishV2.delayInitializedV2 = true
        if showNotify and FuncAutoFishV2.autofishV2 then
            NotifyWarning("Rod Detection Failed (V2)", "No valid rod found. Default delay applied.")
        end
    end
end

-- Fish Threshold System
local RemoteV2 = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
RemoteV2.OnClientEvent:Connect(function(_, _, data)
    if data and data.InventoryItem and data.InventoryItem.UUID then
        table.insert(obtainedFishUUIDsV2, data.InventoryItem.UUID)
    end
end)

local function sellItemsV2()
    if #obtainedFishUUIDsV2 > 0 then
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/SellAllItems"):InvokeServer()
    end
    obtainedFishUUIDsV2 = {}
end

local function monitorFishThresholdV2()
    task.spawn(function()
        while FuncAutoFishV2.autofishV2 do
            if #obtainedFishUUIDsV2 >= obtainedLimitV2 then
                NotifyInfo("Fish Threshold Reached (V2)", "Selling all fishes...")
                sellItemsV2()
                obtainedFishUUIDsV2 = {}
                task.wait(0.5)
            end
            task.wait(0.3)
        end
    end)
end

-- Text Effect Detection
local REReplicateTextEffectV2 = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]
REReplicateTextEffectV2.OnClientEvent:Connect(function(data)
    if FuncAutoFishV2.autofishV2 and FuncAutoFishV2.fishingActiveV2
    and data and data.TextData and data.TextData.EffectType == "Exclaim" then

        local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
        if myHead and data.Container == myHead then
            task.spawn(function()
                for i = 1, 3 do
                    task.wait(BypassDelayV2)
                    finishRemote:FireServer()
                end
            end)
        end
    end
end)

-- Auto Fish Functions
function StartAutoFishV2()
    FuncAutoFishV2.autofishV2 = true
    updateDelayBasedOnRodV2(true)
    monitorFishThresholdV2()
    
    task.spawn(function()
        while FuncAutoFishV2.autofishV2 do
            pcall(function()
                FuncAutoFishV2.fishingActiveV2 = true

                local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
                equipRemote:FireServer(1)
                task.wait(0.1)

                local chargeRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.5)

                local timestamp = workspace:GetServerTimeNow()
                RodShake:Play()
                rodRemote:InvokeServer(timestamp)

                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                if FuncAutoFishV2.perfectCastV2 then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end

                RodIdle:Play()
                miniGameRemote:InvokeServer(x, y)
                task.wait(customDelayV2)
                FuncAutoFishV2.fishingActiveV2 = false
            end)
        end
    end)
end

function StopAutoFishV2()
    FuncAutoFishV2.autofishV2 = false
    FuncAutoFishV2.fishingActiveV2 = false
    FuncAutoFishV2.delayInitializedV2 = false
    RodIdle:Stop()
    RodShake:Stop()
end

-- AUTO FISH UI
local AutoFishSection = AutoFishTab:CreateSection("Auto Fish Settings")

local BypassDelayInput = AutoFishSection:CreateInput({
    Name = "Bypass Delay",
    PlaceholderText = "Example: 1",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            BypassDelayV2 = number
            NotifySuccess("Bypass Delay", "Bypass Delay set to " .. number)
        else
            NotifyError("Invalid Input", "Failed to convert input to number.")
        end
    end,
})

local FishThresholdInput = AutoFishSection:CreateInput({
    Name = "Fish Threshold",
    PlaceholderText = "Example: 1500",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            obtainedLimitV2 = number
            NotifySuccess("Threshold Set", "Fish threshold set to " .. number)
        else
            NotifyError("Invalid Input", "Failed to convert input to number.")
        end
    end,
})

local AutoFishV2Toggle = AutoFishSection:CreateToggle({
    Name = "Auto Fish V2",
    CurrentValue = false,
    Flag = "AutoFishV2",
    Callback = function(Value)
        if Value then
            StartAutoFishV2()
        else
            StopAutoFishV2()
        end
    end,
})

local PerfectCastToggle = AutoFishSection:CreateToggle({
    Name = "Auto Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCast",
    Callback = function(Value)
        FuncAutoFishV2.perfectCastV2 = Value
    end,
})

AutoFishSection:CreateButton({
    Name = "Sell All Fishes",
    Callback = function()
        local sellRemote = net:WaitForChild("RF/SellAllItems")
        local success, err = pcall(function()
            sellRemote:InvokeServer()
        end)

        if success then
            NotifySuccess("Sold!", "All fish were sold successfully!")
        else
            NotifyError("Sell Failed", tostring(err))
        end
    end,
})

-- AUTO FAVORITE SYSTEM
local AutoFavTab = Window:CreateTab("Auto Favorite", 4483362458)

local GlobalFav = {
    REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"],
    REFavoriteItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FavoriteItem"],
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    Variants = {},
    SelectedFishIds = {},
    SelectedVariants = {},
    AutoFavoriteEnabled = false
}

-- Load Fish Data
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

-- Load Variants
for _, variantModule in pairs(ReplicatedStorage.Variants:GetChildren()) do
    local ok, variantData = pcall(require, variantModule)
    if ok and variantData.Data and variantData.Data.Name then
        table.insert(GlobalFav.Variants, variantData.Data.Name)
    end
end

-- Auto Favorite Event Handler
GlobalFav.REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
    if not GlobalFav.AutoFavoriteEnabled then return end

    local uuid = data.InventoryItem and data.InventoryItem.UUID
    local fishName = GlobalFav.FishIdToName[itemId] or "Unknown"
    local variantId = data.InventoryItem.Metadata and data.InventoryItem.Metadata.VariantId

    if not uuid then return end

    local matchByName = GlobalFav.SelectedFishIds[itemId]
    local matchByVariant = variantId and GlobalFav.SelectedVariants[variantId]
    
    local shouldFavorite = false

    if matchByName and matchByVariant then
        shouldFavorite = true
    elseif matchByName and not next(GlobalFav.SelectedVariants) then
        shouldFavorite = true
    elseif matchByVariant and not matchByName then
        shouldFavorite = true
    end

    if shouldFavorite then
        GlobalFav.REFavoriteItem:FireServer(uuid)
        local msg = "Favorited " .. fishName
        if matchByVariant then
            msg = msg .. " (" .. (variantId or "Variant") .. ")"
        end
        NotifySuccess("Auto Favorite", msg .. "!")
    end
end)

-- AUTO FAVORITE UI
local AutoFavSection = AutoFavTab:CreateSection("Auto Favorite Settings")

local AutoFavoriteToggle = AutoFavSection:CreateToggle({
    Name = "Enable Auto Favorite",
    CurrentValue = false,
    Flag = "AutoFavorite",
    Callback = function(Value)
        GlobalFav.AutoFavoriteEnabled = Value
        if Value then
            NotifySuccess("Auto Favorite", "Auto Favorite feature enabled")
        else
            NotifyWarning("Auto Favorite", "Auto Favorite feature disabled")
        end
    end,
})

local FishDropdown = AutoFavSection:CreateDropdown({
    Name = "Auto Favorite Fishes",
    Options = GlobalFav.FishNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "FavoriteFishes",
    Callback = function(Options)
        GlobalFav.SelectedFishIds = {}
        for _, fishName in ipairs(Options) do
            local id = GlobalFav.FishNameToId[fishName]
            if id then
                GlobalFav.SelectedFishIds[id] = true
            end
        end
        NotifyInfo("Auto Favorite", "Favoriting active for selected fish")
    end,
})

local VariantDropdown = AutoFavSection:CreateDropdown({
    Name = "Auto Favorite Variants",
    Options = GlobalFav.Variants,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "FavoriteVariants",
    Callback = function(Options)
        GlobalFav.SelectedVariants = {}
        for _, variantName in ipairs(Options) do
            GlobalFav.SelectedVariants[variantName] = true
        end
        NotifyInfo("Auto Favorite", "Favoriting active for selected variants")
    end,
})

-- AUTO FARM SYSTEM
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)

local isAutoFarmRunning = false
local selectedIsland = "Fisherman Island"

local islandCodes = {
    ["01"] = "Crater Islands",
    ["02"] = "Tropical Grove", 
    ["03"] = "Vulcano",
    ["04"] = "Coral Reefs",
    ["05"] = "Winter",
    ["06"] = "Machine",
    ["07"] = "Treasure Room",
    ["08"] = "Sisyphus Statue",
    ["09"] = "Fisherman Island"
}

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

local function startAutoFarmLoop()
    NotifySuccess("Auto Farm Enabled", "Fishing started on island: " .. selectedIsland)

    while isAutoFarmRunning do  
        local islandSpots = farmLocations[selectedIsland]  
        if not islandSpots or #islandSpots == 0 then
            NotifyError("Auto Farm", "No spots found for " .. selectedIsland)
            break
        end

        local location = islandSpots[math.random(1, #islandSpots)]  
        
        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)  
        local hrp = char and char:FindFirstChild("HumanoidRootPart")  
        if not hrp then  
            NotifyError("Teleport Failed", "HumanoidRootPart not found.")  
            return  
        end  

        hrp.CFrame = location  
        task.wait(1.5)  

        StartAutoFishV2()
        
        local fishTime = 0
        local maxFishTime = 300
        
        while isAutoFarmRunning and fishTime < maxFishTime do
            task.wait(1)
            fishTime = fishTime + 1
            
            if not isAutoFarmRunning then
                StopAutoFishV2()
                break
            end
        end
        
        StopAutoFishV2()
        task.wait(1)
    end
    
    NotifyWarning("Auto Farm Stopped", "Auto Farm has been disabled")
end

-- AUTO FARM UI
local AutoFarmSection = AutoFarmTab:CreateSection("Auto Farm Settings")

local nameList = {}
for code, name in pairs(islandCodes) do
    table.insert(nameList, name)
end
table.sort(nameList)

local IslandDropdown = AutoFarmSection:CreateDropdown({
    Name = "Farm Island",
    Options = nameList,
    CurrentOption = "Fisherman Island",
    Flag = "FarmIsland",
    Callback = function(Option)
        selectedIsland = Option
        NotifySuccess("Island Selected", "Farming location set to " .. Option)
    end,
})

local AutoFarmToggle = AutoFarmSection:CreateToggle({
    Name = "Start Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        isAutoFarmRunning = Value
        if Value then
            task.spawn(startAutoFarmLoop)
        else
            StopAutoFishV2()
        end
    end,
})

-- TRADE SYSTEM
local TradeTab = Window:CreateTab("Trade", 4483362458)

local TradeFunction = {
	TempTradeList = {},
	saveTempMode = false,
	onTrade = false,
	targetUserId = nil,
	tradingInProgress = false,
	autoAcceptTrade = false,
	AutoTrade = false
}

local RETextNotification = net["RE/TextNotification"]
local RFAwaitTradeResponse = net["RF/AwaitTradeResponse"]
local InitiateTrade = net["RF/InitiateTrade"]

local function getPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.DisplayName .. " (" .. player.Name .. ")")
        end
    end
    return list
end

local function refreshTradeDropdown()
    local updatedList = getPlayerList()
    TradeTargetDropdown:Refresh(updatedList)
end

-- Trade Metatable Hook
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if TradeFunction.saveTempMode and tostring(self) == "RE/EquipItem" and method == "FireServer" then
        local uuid, categoryName = args[1], args[2]
        if uuid and categoryName then
            table.insert(TradeFunction.TempTradeList, {UUID = uuid, Category = categoryName})
            NotifySuccess("Save Mode", "Added item: " .. uuid .. " ("..categoryName..")")
        end
        return nil
        
    elseif TradeFunction.onTrade and tostring(self) == "RE/EquipItem" and method == "FireServer" then
        local uuid = args[1]
        if uuid and TradeFunction.targetUserId then
            InitiateTrade:InvokeServer(TradeFunction.targetUserId, uuid)
            NotifySuccess("Trade Sent", "Trade sent to " .. TradeFunction.targetUserId)
        else
            NotifyError("Trade Error", "Invalid target or item.")
        end
        return nil
    end

    return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)

-- Mass Trade Function
local function TradeAll()        
    if TradeFunction.tradingInProgress then        
        NotifyWarning("Mass Trade", "Trade already in progress!")        
        return        
    end        
    if not TradeFunction.targetUserId then        
        NotifyError("Mass Trade", "Set trade target first!")        
        return        
    end        
    if #TradeFunction.TempTradeList == 0 then        
        NotifyWarning("Mass Trade", "No items saved!")        
        return        
    end        
        
    TradeFunction.tradingInProgress = true        
    NotifyInfo("Mass Trade", "Starting trade of "..#TradeFunction.TempTradeList.." items...")        
        
    task.spawn(function()        
        for i, item in ipairs(TradeFunction.TempTradeList) do        
            if not TradeFunction.AutoTrade then        
                NotifyWarning("Mass Trade", "Auto Trade stopped!")        
                break        
            end        
        
            local uuid = item.UUID        
            local category = item.Category        

            NotifyInfo("Mass Trade", "Trade item "..i.." of "..#TradeFunction.TempTradeList)        
            InitiateTrade:InvokeServer(TradeFunction.targetUserId, uuid, category)        

            local tradeCompleted = false        
            local timeout = 10        
            local elapsed = 0        
            local lastTrigger = 0
            local cooldown = 0.5        

            local notifGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Text Notifications")
            local connection
            connection = notifGui.Frame.ChildAdded:Connect(function(child)
                if child.Name == "TextTile" then
                    task.wait(0.5)
                    local header = child:FindFirstChild("Header")
                    if header and header:IsA("TextLabel") and header.Text == "Trade completed!" then
                        local now = tick()
                        if now - lastTrigger > cooldown then
                            lastTrigger = now
                            tradeCompleted = true
                            NotifySuccess("Mass Trade", "Success "..i.." of "..#TradeFunction.TempTradeList)
                        end
                    end
                end
            end)        

            repeat        
                task.wait(0.2)        
                elapsed += 0.2        
            until tradeCompleted or elapsed >= timeout        

            if connection then        
                connection:Disconnect()        
            end        

            if not tradeCompleted then        
                NotifyWarning("Mass Trade", "Trade timeout for item "..i)        
            else        
                task.wait(5.5)        
            end        
        end        

        NotifySuccess("Mass Trade", "Finished trading!")        
        TradeFunction.tradingInProgress = false        
        TradeFunction.TempTradeList = {}        
    end)        
end

-- TRADE UI
local TradeSection = TradeTab:CreateSection("Trade Settings")

local TradeTargetDropdown = TradeSection:CreateDropdown({
    Name = "Select Trade Target",
    Options = getPlayerList(),
    CurrentOption = getPlayerList()[1] or nil,
    Flag = "TradeTarget",
    Callback = function(Option)
        local username = Option:match("%((.-)%)")
        local player = Players:FindFirstChild(username)
        if player then
            TradeFunction.targetUserId = player.UserId
            NotifySuccess("Trade Target", "Target found: " .. player.Name)
        else
            NotifyError("Trade Target", "Player not found!")
        end
    end,
})

local SaveModeToggle = TradeSection:CreateToggle({
    Name = "Mode Save Items",
    CurrentValue = false,
    Flag = "SaveMode",
    Callback = function(Value)
        TradeFunction.saveTempMode = Value
        if Value then
            TradeFunction.TempTradeList = {}
            NotifySuccess("Save Mode", "Enabled - Click items to save")
        else
            NotifyInfo("Save Mode", "Disabled - "..#TradeFunction.TempTradeList.." items saved")
        end
    end,
})

local AutoTradeToggle = TradeSection:CreateToggle({
    Name = "Auto Trade",
    CurrentValue = false,
    Flag = "AutoTrade",
    Callback = function(Value)
        TradeFunction.AutoTrade = Value
        if TradeFunction.AutoTrade then
            if #TradeFunction.TempTradeList == 0 then
                NotifyError("Mass Trade", "No items saved to trade!")
                TradeFunction.AutoTrade = false
                return
            end
            TradeAll()
            NotifySuccess("Mass Trade", "Auto Trade Enabled")
        else
            NotifyWarning("Mass Trade", "Auto Trade Disabled")
        end
    end,
})

local OriginalTradeToggle = TradeSection:CreateToggle({
    Name = "Trade (Original Mode)",
    CurrentValue = false,
    Flag = "OriginalTrade",
    Callback = function(Value)
        TradeFunction.onTrade = Value
        if Value then
            NotifySuccess("Trade", "Trade Mode Enabled. Click an item to send trade.")
        else
            NotifyWarning("Trade", "Trade Mode Disabled.")
        end
    end,
})

local AutoAcceptToggle = TradeSection:CreateToggle({
    Name = "Auto Accept Trade",
    CurrentValue = false,
    Flag = "AutoAcceptTrade",
    Callback = function(Value)
        TradeFunction.autoAcceptTrade = Value
        if Value then
            NotifySuccess("Auto Accept Trade", "Enabled")
        else
            NotifyWarning("Auto Accept Trade", "Disabled")
        end
    end,
})

-- Auto Accept Trade Handler
RFAwaitTradeResponse.OnClientInvoke = function(fromPlayer, timeNow)
    if TradeFunction.autoAcceptTrade then
        return true
    else
        return nil
    end
end

-- Player list monitoring
Players.PlayerAdded:Connect(refreshTradeDropdown)
Players.PlayerRemoving:Connect(refreshTradeDropdown)

-- PLAYER TAB
local PlayerTab = Window:CreateTab("Player", 4483362458)
local PlayerSection = PlayerTab:CreateSection("Player Settings")

local function getPlayerTeleportList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName)
        end
    end
    return list
end

local function teleportToPlayerExact(targetName)
    local characters = workspace:FindFirstChild("Characters")
    if not characters then return false end

    for _, player in pairs(Players:GetPlayers()) do
        if player.DisplayName == targetName then
            local targetChar = characters:FindFirstChild(player.Name)
            local myChar = characters:FindFirstChild(LocalPlayer.Name)

            if targetChar and myChar then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if targetHRP and myHRP then
                    myHRP.CFrame = targetHRP.CFrame + Vector3.new(2, 0, 0)
                    return true
                end
            end
        end
    end
    return false
end

local TeleportDropdown = PlayerSection:CreateDropdown({
    Name = "Teleport to Player",
    Options = getPlayerTeleportList(),
    CurrentOption = nil,
    Flag = "TeleportPlayer",
    Callback = function(Option)
        if teleportToPlayerExact(Option) then
            NotifySuccess("Teleport Successfully", "Successfully Teleported to " .. Option .. "!", 3)
        else
            NotifyError("Teleport Failed", "Could not teleport to " .. Option)
        end
    end,
})

local defaultMinZoom = LocalPlayer.CameraMinZoomDistance
local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance

local UnlimitedZoomToggle = PlayerSection:CreateToggle({
    Name = "Unlimited Zoom",
    CurrentValue = false,
    Flag = "UnlimitedZoom",
    Callback = function(Value)
        if Value then
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 9999
        else
            LocalPlayer.CameraMinZoomDistance = defaultMinZoom
            LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
        end
    end,
})

local InfinityJumpToggle = PlayerSection:CreateToggle({
    Name = "Infinity Jump",
    CurrentValue = false,
    Flag = "InfinityJump",
    Callback = function(Value)
        getgenv().ijump = Value
    end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if getgenv().ijump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

local SpeedSlider = PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 20,
    Flag = "WalkSpeed",
    Callback = function(Value)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Value end
    end,
})

local JumpPowerSlider = PlayerSection:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 35,
    Flag = "JumpPower",
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = Value
            end
        end
    end,
})

PlayerSection:CreateButton({
    Name = "Access All Boats",
    Callback = function()
        local vehicles = workspace:FindFirstChild("Vehicles")
        if not vehicles then
            NotifyError("Not Found", "Vehicles container not found.")
            return
        end

        local count = 0
        for _, boat in ipairs(vehicles:GetChildren()) do
            if boat:IsA("Model") and boat:GetAttribute("OwnerId") then
                local currentOwner = boat:GetAttribute("OwnerId")
                if currentOwner ~= LocalPlayer.UserId then
                    boat:SetAttribute("OwnerId", LocalPlayer.UserId)
                    count += 1
                end
            end
        end

        NotifySuccess("Access Granted", "You now own " .. count .. " boat(s).")
    end,
})

-- UTILITY TAB
local UtilityTab = Window:CreateTab("Utility", 4483362458)
local UtilitySection = UtilityTab:CreateSection("Utility Features")

local weatherActive = {}
local weatherData = {
    ["Storm"] = { duration = 900 },
    ["Cloudy"] = { duration = 900 },
    ["Snow"] = { duration = 900 },
    ["Wind"] = { duration = 900 },
    ["Radiant"] = { duration = 900 }
}

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
                NotifySuccess("Weather Purchased", "Successfully activated " .. weatherType)

                task.wait(weatherData[weatherType].duration)

                local randomWait = randomDelay(1, 5)
                NotifyInfo("Waiting...", "Delay before next purchase: " .. tostring(randomWait) .. "s")
                task.wait(randomWait)
            end)
        end
    end)
end

local WeatherDropdown = UtilitySection:CreateDropdown({
    Name = "Auto Buy Weather",
    Options = {"Storm", "Cloudy", "Snow", "Wind", "Radiant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoWeather",
    Callback = function(Options)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(Options, weatherType) then
                weatherActive[weatherType] = false
                NotifyWarning("Auto Weather", "Auto buying " .. weatherType .. " has been stopped.")
            end
        end
        
        for _, weatherType in pairs(Options) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                NotifyInfo("Auto Weather", "Auto buying " .. weatherType .. " has started!")
                autoBuyWeather(weatherType)
            end
        end
    end,
})

-- FISH NOTIFICATION TAB
local FishNotifTab = Window:CreateTab("Fish Notification", 4483362458)
local FishNotifSection = FishNotifTab:CreateSection("Fish Notification Settings")

local webhookPath = nil
local FishWebhookEnabled = true

FishNotifSection:CreateLabel("Fish Notification")
FishNotifSection:CreateParagraph("Description", "This feature sends fish catch notifications to Discord webhook.")

local ApiKeyInput = FishNotifSection:CreateInput({
    Name = "Webhook Path",
    PlaceholderText = "Enter webhook path...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        webhookPath = Value
        if Value and Value:match("^%d+/.+") then
            NotifySuccess("Webhook Set", "Webhook path saved successfully!")
        else
            NotifyWarning("Invalid Format", "Webhook path should be in format: ID/Token")
        end
    end,
})

local FishNotifToggle = FishNotifSection:CreateToggle({
    Name = "Enable Fish Notifications",
    CurrentValue = true,
    Flag = "FishNotification",
    Callback = function(Value)
        FishWebhookEnabled = Value
    end,
})

-- SETTINGS TAB
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Settings")

local AntiAFKEnabled = true
local AFKConnection = nil

local AntiAFKToggle = SettingsSection:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        AntiAFKEnabled = Value
        if AntiAFKEnabled then
            if AFKConnection then
                AFKConnection:Disconnect()
            end

            local VirtualUser = game:GetService("VirtualUser")
            AFKConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)

            NotifySuccess("Anti-AFK Activated", "You will now avoid being kicked.")
        else
            if AFKConnection then
                AFKConnection:Disconnect()
                AFKConnection = nil
            end
            NotifySuccess("Anti-AFK Deactivated", "You can now go idle again.")
        end
    end,
})

local KeybindPicker = SettingsSection:CreateKeybind({
    Name = "UI Keybind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "UIKeybind",
    Callback = function(Keybind)
        Window:SetKeybind(Keybind)
    end,
})

SettingsSection:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Rayfield:SaveConfiguration()
        NotifySuccess("Config Saved", "Config has been saved!")
    end,
})

SettingsSection:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        Rayfield:LoadConfiguration()
        NotifySuccess("Config Loaded", "Config has been loaded!")
    end,
})

SettingsSection:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

SettingsSection:CreateButton({
    Name = "Server Hop",
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
            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
        else
            NotifyError("Server Hop Failed", "No servers available or all are full!")
        end
    end,
})

-- FINAL INITIALIZATION
NotifySuccess("Codepik Premium", "All features loaded successfully!", 5)
Rayfield:LoadConfiguration()

print("Codepik Premium Rayfield UI - Fully Loaded!")

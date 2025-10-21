-- MainScript.lua (LocalScript)
-- Uses UI from GitHub and contains full logic (Fishing, Sell, Favorite, Teleport, AntiAFK)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI from GitHub
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pawnpawnn/nk/main/mainui.lua"))()
-- parent UI screenGui is set in module itself
local mainFrame = UI.MainFrame
local titleLabel = UI.TitleLabel
local closeBtn = UI.CloseButton
local minimizeBtn = UI.MinimizeButton
local tabs = UI.TabButtons
local content = UI.ContentFrame

-- Set title text
titleLabel.Text = "🐟 FishIt Premium"

-- Create status label / notif system
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Parent = mainFrame
statusLabel.Size = UDim2.new(1,-20,0,30)
statusLabel.Position = UDim2.new(0,10,0,40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local function updateStatus(txt, clr)
	statusLabel.Text = txt
	if clr then statusLabel.TextColor3 = clr end
end

-- Tab switching logic
local Tabs = {Main = {}, Teleports = {}, Misc = {}}
local currentTab = "Main"
local function clearContent()
	for _,v in pairs(content:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
end

local function switchTab(tab)
	currentTab = tab
	clearContent()
	for _,func in ipairs(Tabs[tab]) do
		func()
	end
	for name,btn in pairs(tabs) do
		if name == tab then
			btn.BackgroundColor3 = Color3.fromRGB(44,44,56)
		else
			btn.BackgroundColor3 = Color3.fromRGB(28,28,34)
		end
	end
end

for name,btn in pairs(tabs) do
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Parent:Destroy()
end)

-- Section + Button factories
local function createSection(title)
	local sec = Instance.new("Frame")
	sec.Parent = content
	sec.Size = UDim2.new(1,0,0,40)
	sec.BackgroundColor3 = Color3.fromRGB(25,25,30)
	sec.BorderSizePixel = 0
	local uic = Instance.new("UICorner", sec)
	uic.CornerRadius = UDim.new(0,6)
	local lbl = Instance.new("TextLabel", sec)
	lbl.Size = UDim2.new(1,-90,1,0)
	lbl.Position = UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(220,220,230)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = title
	return sec
end

local function createButton(section, text, callback)
	local btn = Instance.new("TextButton")
	btn.Parent = section
	btn.Size = UDim2.new(0,70,0,26)
	btn.Position = UDim2.new(1,-80,0,7)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = Color3.fromRGB(50,150,50)
	local uic = Instance.new("UICorner", btn)
	uic.CornerRadius = UDim.new(0,6)
	btn.MouseButton1Click:Connect(function()
		callback(btn)
	end)
	return btn
end

-- Toggle system
local state = {
	autoFishing = false,
	autoFishingV2 = false,
	autoFishingV3 = false,
	autoSell = false,
	autoFav = false,
	antiAFK = false
}

local function setBtnState(btn, on)
	if on then
		btn.Text = "STOP"
		btn.BackgroundColor3 = Color3.fromRGB(180,50,50)
	else
		btn.Text = "START"
		btn.BackgroundColor3 = Color3.fromRGB(50,150,50)
	end
end

-- Setup remotes and data (extracted from your v3.lua)
local netRemote
local rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local function setupRemotes()
	local ok = pcall(function()
		netRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
	end)
	if not ok then
		netRemote = ReplicatedStorage:WaitForChild("Net")
	end

	rodRemote = netRemote:WaitForChild("RF/ChargeFishingRod")
	miniGameRemote = netRemote:WaitForChild("RF/RequestFishingMinigameStarted")
	finishRemote = netRemote:WaitForChild("RE/FishingCompleted")
	equipRemote = netRemote:WaitForChild("RE/EquipToolFromHotbar")
	sellRemote = netRemote:WaitForChild("RF/SellAllItems")
	favoriteRemote = netRemote:WaitForChild("RE/FavoriteItem")
end

-- Extracted island coordinates
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

-- Core logic loops (Fishing V1/V2/V3, Sell, Fav, AntiAFK)
-- Auto Fishing V1
local function autoFishingLoop()
	while state.autoFishing do
		pcall(function()
			updateStatus("🎣 Fishing V1 …", Color3.fromRGB(100,255,100))
			equipRemote:FireServer(1)
			task.wait(0.5)
			local ts = workspace:GetServerTimeNow()
			rodRemote:InvokeServer(ts)
			local baseX, baseY = -0.7499996, 1
			local x = baseX + (math.random(-500,500)/1e7)
			local y = baseY + (math.random(-500,500)/1e7)
			miniGameRemote:InvokeServer(x, y)
			task.wait(5)
			finishRemote:FireServer(true)
			task.wait(5)
		end)
		task.wait(0.2)
	end
	updateStatus("🔴 Idle", Color3.fromRGB(255,120,120))
end

-- Auto Fishing V2 (FAST)
local function autoFishingV2Loop()
	while state.autoFishingV2 do
		pcall(function()
			updateStatus("⚡ Fishing V2 …", Color3.fromRGB(255,255,100))
			equipRemote:FireServer(1)
			local ts = workspace:GetServerTimeNow()
			rodRemote:InvokeServer(ts)
			local baseX, baseY = -0.7499996, 1
			local x = baseX + (math.random(-300,300)/1e7)
			local y = baseY + (math.random(-300,300)/1e7)
			miniGameRemote:InvokeServer(x, y)
			task.wait(0.5)
			finishRemote:FireServer(true)
			task.wait(0.3)
			finishRemote:FireServer()
		end)
		task.wait(math.random(10,30)/100)
	end
	updateStatus("🔴 Idle", Color3.fromRGB(255,120,120))
end

-- Auto Fishing V3 (TIMING EXPLOIT)
local function autoFishingV3Loop()
	local successPattern = {}
	while state.autoFishingV3 do
		pcall(function()
			updateStatus("🚀 Fishing V3 …", Color3.fromRGB(255,100,100))
			equipRemote:FireServer(1)
			local ts = workspace:GetServerTimeNow()
			rodRemote:InvokeServer(ts)
			local baseX, baseY = -0.7499996, 1
			local x = baseX + (math.random(-30,30)/1e7)
			local y = baseY + (math.random(-30,30)/1e7)
			miniGameRemote:InvokeServer(x, y)
			task.wait(0.25)
			local willSucceed = (math.random(1,100) <= 75)
			if willSucceed then
				finishRemote:FireServer(true)
				table.insert(successPattern, true)
				updateStatus("🎯 V3 Hit!", Color3.fromRGB(100,255,100))
			else
				finishRemote:FireServer(false)
				table.insert(successPattern, false)
				updateStatus("🎯 V3 Miss", Color3.fromRGB(255,200,100))
			end
			if #successPattern > 10 then table.remove(successPattern,1) end
			task.wait(0.08)
			finishRemote:FireServer()
		end)
		task.wait(math.random(8,20)/100)
	end
	updateStatus("🔴 Idle", Color3.fromRGB(255,120,120))
end

-- Auto Sell loop
local function autoSellLoop()
	while state.autoSell do
		pcall(function()
			updateStatus("💰 Selling …", Color3.fromRGB(255,215,0))
			sellRemote:InvokeServer()
			updateStatus("✅ Sold!", Color3.fromRGB(100,255,100))
		end)
		task.wait(1)
	end
	updateStatus("🔴 Idle", Color3.fromRGB(255,120,120))
end

-- Auto Favorite
local function startAutoFavorite()
	task.spawn(function()
		while state.autoFav do
			pcall(function()
				updateStatus("⭐ Scanning Inventory …", Color3.fromRGB(255,215,0))
				local Replion = require(ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.3"].knit.Util.Remote.Replion)
				local ItemUtility = require(ReplicatedStorage.Modules.Shared.ItemUtility)
				local data = Replion.Client:WaitReplion("Data")
				local items = data:Get({"Inventory","Items"})
				if items and type(items) == "table" then
					local count = 0
					for _,it in ipairs(items) do
						if not state.autoFav then break end
						local base = ItemUtility:GetItemData(it.Id)
						if base and base.Data and (base.Data.Tier == "Mythic" or base.Data.Tier == "Legendary" or base.Data.Tier == "Secret") and not it.Favorited then
							favoriteRemote:FireServer(it.UUID, true)
							count = count + 1
							updateStatus("⭐ Favorited "..(base.Name or "?").." ["..base.Data.Tier.."]", Color3.fromRGB(255,215,0))
							task.wait(0.3)
						end
					end
					if count > 0 then
						updateStatus("✅ Favorited "..count.." items!", Color3.fromRGB(100,255,100))
					else
						updateStatus("ℹ️ No rare items found", Color3.fromRGB(255,255,100))
					end
				end
			end)
			for i=1,30 do if not state.autoFav then break end; task.wait(1) end
		end
		if not state.autoFav then updateStatus("⭐ Auto Favorite: Stopped", Color3.fromRGB(255,120,120)) end
	end)
end

-- Anti AFK
local AFKConn = nil
local function toggleAntiAFK(on)
	if on then
		if AFKConn then AFKConn:Disconnect() end
		AFKConn = player.Idled:Connect(function()
			pcall(function()
				VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
				task.wait(1)
				VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			end)
		end)
		updateStatus("⏰ Anti-AFK: Active", Color3.fromRGB(100,255,100))
	else
		if AFKConn then AFKConn:Disconnect(); AFKConn = nil end
		updateStatus("🔴 Idle", Color3.fromRGB(255,120,120))
	end
end

-- Teleport Islands GUI
local function openTeleportIslandsGUI()
	local gui = Instance.new("ScreenGui", playerGui)
	gui.Name = "TeleportGUI"
	gui.ResetOnSpawn = false

	local frame = create("Frame", {
		Parent = gui,
		Size = UDim2.new(0,280,0,300),
		Position = UDim2.new(0.5,-140,0.5,-150),
		BackgroundColor3 = Color3.fromRGB(15,20,30),
	})
	create("UICorner", {Parent=frame, CornerRadius=UDim.new(0,10)})
	create("UIStroke", {Parent=frame, Color = Color3.fromRGB(40,80,150), Thickness = 1.5})

	local title = create("TextLabel", {
		Parent = frame,
		Size = UDim2.new(1,0,0,35),
		BackgroundColor3 = Color3.fromRGB(25,35,55),
		Text = "🏝️ Teleport Islands",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(100,180,255),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	create("UICorner", {Parent = title, CornerRadius = UDim.new(0,8)})

	local closeBtn2 = create("TextButton", {
		Parent = title,
		Size = UDim2.new(0,22,0,22),
		Position = UDim2.new(1,-28,0,6),
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255,255,255),
		BackgroundColor3 = Color3.fromRGB(220,50,50)
	})
	create("UICorner", {Parent = closeBtn2, CornerRadius = UDim.new(0,6)})

	local scroll = create("ScrollingFrame", {
		Parent = frame,
		Size = UDim2.new(1,-20,1,-50),
		Position = UDim2.new(0,10,0,45),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
	})
	local y = 0
	for name, pos in pairs(islandCoords) do
		local b = create("TextButton", {
			Parent = scroll,
			Size = UDim2.new(1,0,0,32),
			Position = UDim2.new(0,0,0,y),
			Text = "📍 "..name,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(220,220,230),
			BackgroundColor3 = Color3.fromRGB(35,45,65)
		})
		create("UICorner", {Parent = b, CornerRadius = UDim.new(0,6)})
		b.MouseButton1Click:Connect(function()
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				pcall(function()
					hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
					updateStatus("✅ Teleported to "..name, Color3.fromRGB(100,255,100))
				end)
			end
			gui:Destroy()
		end)
		y = y + 36
	end
	scroll.CanvasSize = UDim2.new(0,0,0,y)
	closeBtn2.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)
end

-- Register functions & UI
setupRemotes()

-- Register buttons
-- note: exclusive logic for fishing modes
local function registerToggle(title, key, callbackStart, callbackStop)
	local sec = createSection(title)
	pushCanvas(48)
	local btn = createButton(sec, "START", function()
		state[key] = not state[key]
		setBtnState(btn, state[key])

		-- Exclusivity for fishing modes
		if key == "autoFishing" and state[key] then
			state.autoFishingV2 = false
			state.autoFishingV3 = false
		elseif key == "autoFishingV2" and state[key] then
			state.autoFishing = false
			state.autoFishingV3 = false
		elseif key == "autoFishingV3" and state[key] then
			state.autoFishing = false
			state.autoFishingV2 = false
		end

		if state[key] then
			if callbackStart then task.spawn(callbackStart) end
		else
			if callbackStop then pcall(callbackStop) end
		end
	end)
	return btn
end

-- Teleport button
local function registerButton(title, callback)
	local sec = createSection(title)
	pushCanvas(48)
	local btn = createButton(sec, "OPEN", callback)
	return btn
end

-- MAIN tab
registerToggle("🎣 Auto Fishing V1", "autoFishing", autoFishingLoop, function() finishRemote:FireServer() end)
registerToggle("⚡ Auto Fishing V2", "autoFishingV2", autoFishingV2Loop, function() finishRemote:FireServer() end)
registerToggle("🚀 Auto Fishing V3", "autoFishingV3", autoFishingV3Loop, function() finishRemote:FireServer() end)
registerToggle("💰 Auto Sell All", "autoSell", autoSellLoop, nil)
registerToggle("⭐ Auto Favorite", "autoFav", startAutoFavorite, nil)

-- TELEPORT tab
registerButton("🏝️ Teleport Islands", openTeleportIslandsGUI)

-- MISC tab
registerToggle("⏰ Anti-AFK", "antiAFK", function() toggleAntiAFK(true) end, function() toggleAntiAFK(false) end)

-- Switch to default tab
switchTab("Main")

-- initial status
updateStatus("✅ Script Loaded", Color3.fromRGB(100,255,100))

-- pushCanvas function (must define earlier)
function pushCanvas(height)
	local cs = content.CanvasSize
	local newY = (cs.Y.Offset or 0) + height
	content.CanvasSize = UDim2.new(0,0,0,newY)
end

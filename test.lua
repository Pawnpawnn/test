local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

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

local net, rodRemote, miniGameRemote, finishRemote, equipRemote, sellRemote, favoriteRemote
local AFKConnection = nil

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
end

-- ===================================
-- ========== SIMPLE TELEPORT ========
-- ===================================

-- Fungsi teleport yang sangat sederhana
local function simpleTeleport(cframe)
    pcall(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = cframe
            return true
        end
    end)
    return false
end

-- Island locations dengan CFrame langsung
local islandLocations = {
    ["Weather Machine"] = CFrame.new(-1471, 10, 1929),
    ["Esoteric Depths"] = CFrame.new(3157, -1298, 1439),
    ["Tropical Grove"] = CFrame.new(-2038, 10, 3650),
    ["Stingray Shores"] = CFrame.new(-32, 10, 2773),
    ["Kohana Volcano"] = CFrame.new(-519, 30, 189),
    ["Coral Reefs"] = CFrame.new(-3095, 10, 2177),
    ["Crater Island"] = CFrame.new(968, 10, 4854),
    ["Kohana"] = CFrame.new(-658, 10, 719),
    ["Winter Fest"] = CFrame.new(1611, 10, 3280),
    ["Isoteric Island"] = CFrame.new(1987, 10, 1400),
    ["Treasure Hall"] = CFrame.new(-3600, -262, -1558),
    ["Lost Shore"] = CFrame.new(-3663, 45, -989),
    ["Sishypus Statue"] = CFrame.new(-3792, -130, -986),
    ["Ancient Jungle"] = CFrame.new(1316, 15, -196)
}

-- Get available NPCs
local function getAvailableNPCs()
    local npcs = {}
    local npcFolder = ReplicatedStorage:FindFirstChild("NPC")
    
    if npcFolder then
        for _, npc in pairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                if hrp then
                    npcs[npc.Name] = hrp.CFrame * CFrame.new(0, 3, 0)
                end
            end
        end
    end
    
    return npcs
end

-- Get available Events
local function getAvailableEvents()
    local events = {}
    local props = workspace:FindFirstChild("Props")
    
    if props then
        local eventNames = {
            "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", 
            "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain"
        }
        
        for _, eventName in pairs(eventNames) do
            local eventFolder = props:FindFirstChild(eventName)
            if eventFolder and eventFolder:FindFirstChild("Fishing Boat") then
                local boat = eventFolder["Fishing Boat"]
                if boat then
                    events[eventName] = boat:GetPivot() * CFrame.new(0, 15, 0)
                end
            end
        end
    end
    
    return events
end

-- ===================================
-- ========== RAYFIELD UI ============
-- ===================================

local Window = Rayfield:CreateWindow({
    Name = "🐟 Fish It - Teleport System",
    LoadingTitle = "Loading Teleport System...",
    LoadingSubtitle = "by Codepikk",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "codepik",
        FileName = "FishItConfig"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("🌍 Teleports", 4483362458)

-- Island Teleports Section
local IslandSection = TeleportTab:CreateSection("Island Teleports")

-- Island Dropdown dengan teleport langsung
local islandOptions = {}
for islandName, _ in pairs(islandLocations) do
    table.insert(islandOptions, islandName)
end
table.sort(islandOptions)

local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "🏝️ Click Island to Teleport",
    Options = islandOptions,
    CurrentOption = "Kohana",
    Flag = "IslandDropdown",
    Callback = function(SelectedIsland)
        local location = islandLocations[SelectedIsland]
        if location then
            Rayfield:Notify({
                Title = "Teleporting...",
                Content = "Going to " .. SelectedIsland,
                Duration = 2,
                Image = 4483362458
            })
            
            local success = simpleTeleport(location)
            
            if success then
                Rayfield:Notify({
                    Title = "Success!",
                    Content = "Arrived at " .. SelectedIsland,
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Failed",
                    Content = "Could not teleport to " .. SelectedIsland,
                    Duration = 3
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Location not found: " .. SelectedIsland,
                Duration = 3
            })
        end
    end,
})

-- NPC Teleports Section
local NPCSection = TeleportTab:CreateSection("NPC Teleports")

-- Get NPC data
local npcData = getAvailableNPCs()
local npcOptions = {}
for npcName, _ in pairs(npcData) do
    table.insert(npcOptions, npcName)
end
table.sort(npcOptions)

if #npcOptions > 0 then
    local NPCDropdown = TeleportTab:CreateDropdown({
        Name = "🧍 Click NPC to Teleport",
        Options = npcOptions,
        CurrentOption = npcOptions[1],
        Flag = "NPCDropdown",
        Callback = function(SelectedNPC)
            local location = npcData[SelectedNPC]
            if location then
                Rayfield:Notify({
                    Title = "Teleporting...",
                    Content = "Going to " .. SelectedNPC,
                    Duration = 2,
                    Image = 4483362458
                })
                
                local success = simpleTeleport(location)
                
                if success then
                    Rayfield:Notify({
                        Title = "Success!",
                        Content = "Arrived at " .. SelectedNPC,
                        Duration = 3,
                        Image = 4483362458
                    })
                else
                    Rayfield:Notify({
                        Title = "Failed",
                        Content = "Could not teleport to " .. SelectedNPC,
                        Duration = 3
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "NPC not found: " .. SelectedNPC,
                    Duration = 3
                })
            end
        end,
    })
else
    TeleportTab:CreateLabel("No NPCs found")
end

-- Event Teleports Section
local EventSection = TeleportTab:CreateSection("Event Teleports")

-- Get Event data
local eventData = getAvailableEvents()
local eventOptions = {}
for eventName, _ in pairs(eventData) do
    table.insert(eventOptions, eventName)
end
table.sort(eventOptions)

if #eventOptions > 0 then
    local EventDropdown = TeleportTab:CreateDropdown({
        Name = "🎯 Click Event to Teleport",
        Options = eventOptions,
        CurrentOption = eventOptions[1],
        Flag = "EventDropdown",
        Callback = function(SelectedEvent)
            local location = eventData[SelectedEvent]
            if location then
                Rayfield:Notify({
                    Title = "Teleporting...",
                    Content = "Going to " .. SelectedEvent,
                    Duration = 2,
                    Image = 4483362458
                })
                
                local success = simpleTeleport(location)
                
                if success then
                    Rayfield:Notify({
                        Title = "Success!",
                        Content = "Arrived at " .. SelectedEvent,
                        Duration = 3,
                        Image = 4483362458
                    })
                else
                    Rayfield:Notify({
                        Title = "Failed",
                        Content = "Could not teleport to " .. SelectedEvent,
                        Duration = 3
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Event not found: " .. SelectedEvent,
                    Duration = 3
                })
            end
        end,
    })
else
    TeleportTab:CreateLabel("No active events found")
end

-- Refresh Section
local RefreshSection = TeleportTab:CreateSection("Refresh")

local RefreshButton = TeleportTab:CreateButton({
    Name = "🔄 Refresh NPC & Event Lists",
    Callback = function()
        -- Refresh NPC data
        npcData = getAvailableNPCs()
        local newNPCOptions = {}
        for npcName, _ in pairs(npcData) do
            table.insert(newNPCOptions, npcName)
        end
        table.sort(newNPCOptions)
        
        -- Refresh Event data
        eventData = getAvailableEvents()
        local newEventOptions = {}
        for eventName, _ in pairs(eventData) do
            table.insert(newEventOptions, eventName)
        end
        table.sort(newEventOptions)
        
        Rayfield:Notify({
            Title = "Refreshed!",
            Content = "NPCs: " .. #newNPCOptions .. " | Events: " .. #newEventOptions,
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- ===================================
-- ========== INITIALIZATION =========
-- ===================================

setupRemotes()

Rayfield:Notify({
    Title = "Ready!",
    Content = "Teleport system loaded\nClick dropdown options to teleport instantly!",
    Duration = 5,
    Image = 4483362458
})

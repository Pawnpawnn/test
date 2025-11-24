-- 🧭 Tampilkan Koordinat Player di Layar
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Buat GUI
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoordinateDisplay"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

-- Label teks posisi
local coordLabel = Instance.new("TextLabel")
coordLabel.Size = UDim2.new(0, 250, 0, 80)
coordLabel.Position = UDim2.new(0, 15, 0, 15)
coordLabel.BackgroundTransparency = 0.3
coordLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
coordLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
coordLabel.Font = Enum.Font.Code
coordLabel.TextSize = 16
coordLabel.TextXAlignment = Enum.TextXAlignment.Left
coordLabel.TextYAlignment = Enum.TextYAlignment.Top
coordLabel.Parent = screenGui
coordLabel.Text = "Koordinat: Loading..."

-- Perbarui posisi setiap 0.2 detik
task.spawn(function()
	while task.wait(0.2) do
		if humanoidRootPart and humanoidRootPart:IsDescendantOf(workspace) then
			local pos = humanoidRootPart.Position
			coordLabel.Text =
				string.format("📍 Posisi Saat Ini:\nX: %.2f\nY: %.2f\nZ: %.2f\nVector3.new(%d, %d, %d)",
					pos.X, pos.Y, pos.Z,
					math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
				)
		else
			coordLabel.Text = "❌ Tidak dapat menemukan HumanoidRootPart"
		end
	end
end)

local World = {}
local positions = { top = Vector3.new(-25, 3, 0), bottom = Vector3.new(25, 3, 0), shoes = Vector3.new(-25, 3, 30), accessory = Vector3.new(25, 3, 30) }
World.StorePositions = positions
World.Stage = CFrame.new(0, 5, -40)
World.Lobby = CFrame.new(0, 5, 18)

local function part(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end

function World.create(onStore)
	-- Only our own generated folder is managed here. Existing maps are preserved.
	local old = workspace:FindFirstChild("ShoppingQueenPrototype")
	if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "ShoppingQueenPrototype"; folder.Parent = workspace
	part(folder, "Floor", Vector3.new(90, 1, 115), CFrame.new(0, -0.5, -5), Color3.fromRGB(242, 231, 239))
	part(folder, "Runway", Vector3.new(14, 2, 30), CFrame.new(0, 1, -35), Color3.fromRGB(183, 100, 147))
	local names = { top = "BUTIK • góra", bottom = "BUTIK • dół", shoes = "BUTY", accessory = "DODATKI" }
	for category, position in pairs(positions) do
		local counter = part(folder, category, Vector3.new(12, 4, 6), CFrame.new(position), Color3.fromRGB(84, 56, 100))
		local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(230, 60); gui.StudsOffset = Vector3.new(0, 5, 0); gui.AlwaysOnTop = true; gui.Parent = counter
		local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1, 1); text.BackgroundTransparency = 1; text.Text = names[category]; text.TextColor3 = Color3.new(1, 1, 1); text.TextScaled = true; text.Parent = gui
		local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Przeglądaj"; prompt.ObjectText = names[category]; prompt.MaxActivationDistance = 20; prompt.HoldDuration = 0; prompt.Parent = counter
		prompt.Triggered:Connect(function(player) onStore(player, category) end)
	end
end
return World

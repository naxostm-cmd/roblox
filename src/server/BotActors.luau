-- NPC contestants: R15 bodies that walk the mall. Purchases are not decided here.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local BotActors = {}

local skins = { { 255, 220, 196 }, { 234, 184, 146 }, { 198, 140, 104 }, { 141, 94, 66 }, { 247, 208, 178 } }
local hairColors = { { 60, 40, 30 }, { 214, 170, 100 }, { 25, 22, 26 }, { 150, 70, 40 }, { 230, 150, 190 } }
-- Default Roblox R15 animations; NPCs need them played from the server.
local animations = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826", sit = "rbxassetid://2506281703" }
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local function weld(head, name, size, offset, color, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color
	p.Material = Enum.Material.SmoothPlastic; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	if shape then p.Shape = shape end
	p.CFrame = head.CFrame * offset; p.Parent = head.Parent
	local w = Instance.new("WeldConstraint"); w.Part0 = head; w.Part1 = p; w.Parent = p
end

local function hair(model, rng)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local color = Color3.fromRGB(table.unpack(hairColors[rng:NextInteger(1, #hairColors)]))
	local s = head.Size
	weld(head, "BotHair", Vector3.new(s.X + 0.25, s.Y * 0.75, s.Z + 0.3), CFrame.new(0, s.Y * 0.28, 0.08), color, Enum.PartType.Ball)
	if rng:NextInteger(1, 2) == 1 then
		weld(head, "BotPonytail", Vector3.new(0.55, 1.5, 0.55), CFrame.new(0, -0.1, s.Z * 0.7) * CFrame.Angles(0.35, 0, 0), color, Enum.PartType.Ball)
	else
		for _, side in ipairs({ -1, 1 }) do
			weld(head, "BotLongHair", Vector3.new(0.4, 1.6, 0.8), CFrame.new(side * s.X * 0.5, -0.45, 0.2), color)
		end
	end
end

local function animate(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local tracks = {}
	for key, id in pairs(animations) do
		local animation = Instance.new("Animation"); animation.AnimationId = id
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if ok then tracks[key] = track end
	end
	if tracks.idle then tracks.idle.Looped = true; tracks.idle:Play() end
	humanoid.Seated:Connect(function(active)
		if not tracks.sit then return end
		if active then tracks.sit.Looped = true; tracks.sit:Play(0.1) else tracks.sit:Stop(0.1) end
	end)
	humanoid.Running:Connect(function(speed)
		if not tracks.walk then return end
		if speed > 0.5 and not tracks.walk.IsPlaying then tracks.walk.Looped = true; tracks.walk:Play(0.15)
		elseif speed <= 0.5 and tracks.walk.IsPlaying then tracks.walk:Stop(0.2) end
	end)
end

local layered = { LeftShoe = 1, RightShoe = 1, Pants = 2, Shorts = 2, DressSkirt = 3, TShirt = 4, Shirt = 5, Sweater = 6, Jacket = 7 }

local function body(skin, outfit, shoes)
	local description = Instance.new("HumanoidDescription")
	local color = Color3.fromRGB(table.unpack(skin))
	description.HeadColor = color; description.TorsoColor = color
	description.LeftArmColor = color; description.RightArmColor = color
	description.LeftLegColor = color; description.RightLegColor = color
	local list = {}
	for _, entry in ipairs(outfit or {}) do
		local order = layered[entry[2]]
		table.insert(list, { AssetId = entry[1], AccessoryType = Enum.AccessoryType[entry[2]], IsLayered = order ~= nil, Order = order, Puffiness = if order then 1 else nil })
	end
	if shoes then
		table.insert(list, { AssetId = shoes[1], AccessoryType = Enum.AccessoryType.LeftShoe, IsLayered = true, Order = 1, Puffiness = 1 })
		table.insert(list, { AssetId = shoes[2], AccessoryType = Enum.AccessoryType.RightShoe, IsLayered = true, Order = 1, Puffiness = 1 })
	end
	pcall(function() description:SetAccessories(list, true) end)
	return description
end

local function build(description)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and model then return model end
	warn("NPC body could not be created: " .. tostring(model))
	return nil
end

function BotActors.spawn(folder, name, cf, rng)
	-- Real catalog hair; fall back to a part hairstyle if it fails to load.
	local skin = skins[rng:NextInteger(1, #skins)]
	local description = body(skin, { { Config.BotHair[rng:NextInteger(1, #Config.BotHair)], "Hair" } })
	local model = build(description)
	local partHair = false
	if not model then
		description = body(skin, {})
		model = build(description); partHair = true
	end
	if not model then return nil end
	model.Name = "[BOT] " .. name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "[BOT] " .. name
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance = 80
	-- The bundled Animate LocalScript never runs on an NPC.
	local animateScript = model:FindFirstChild("Animate"); if animateScript then animateScript:Destroy() end
	if partHair then hair(model, rng) end
	model.Parent = folder
	model:PivotTo(cf)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then pcall(function() root:SetNetworkOwner(nil) end) end
	animate(humanoid)
	return model, description
end

-- Host and jury: anchored presenters wearing real catalog outfits.
function BotActors.npc(folder, definition, cf)
	local description = body(definition.skin, definition.outfit, definition.shoes)
	local model = build(description) or build(body(definition.skin, {}))
	if not model then return nil end
	model.Name = definition.title .. " " .. definition.name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = definition.name .. " • " .. definition.title
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance = 60
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local animateScript = model:FindFirstChild("Animate"); if animateScript then animateScript:Destroy() end
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(cf * CFrame.new(0, humanoid.HipHeight + (if root then root.Size.Y / 2 else 1), 0))
	if root then pcall(function() root:SetNetworkOwner(nil) end) end
	animate(humanoid)
	return model
end

function BotActors.sit(model, seat)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not seat then return end
	root.Anchored = false
	model:PivotTo(seat.CFrame * CFrame.new(0, 2.5, 0))
	seat:Sit(humanoid)
end

-- Speech bubble above the head, visible to everyone.
function BotActors.say(model, text, seconds)
	local head = model and model:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("SpeechBubble"); if old then old:Destroy() end
	local gui = Instance.new("BillboardGui"); gui.Name = "SpeechBubble"; gui.Size = UDim2.fromOffset(280, 86)
	gui.StudsOffset = Vector3.new(0, 3.2, 0); gui.AlwaysOnTop = true; gui.MaxDistance = 120; gui.Parent = head
	local frame = Instance.new("Frame"); frame.Size = UDim2.fromScale(1, 1); frame.BackgroundColor3 = Color3.fromRGB(255, 248, 252)
	frame.BorderSizePixel = 0; frame.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = frame
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 92, 160); stroke.Thickness = 2; stroke.Parent = frame
	local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -16, 1, -10); label.Position = UDim2.fromOffset(8, 5)
	label.BackgroundTransparency = 1; label.TextWrapped = true; label.TextScaled = true; label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(40, 24, 46); label.Text = text; label.Parent = frame
	task.delay(seconds or 4, function() if gui.Parent then gui:Destroy() end end)
end

-- One-shot emote (runway pose); default Roblox R15 emotes.
function BotActors.pose(model, animationId)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local animation = Instance.new("Animation"); animation.AnimationId = animationId
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	if ok and track then track:Play(0.2) end
end

-- Walks with pathfinding; teleports to the target when blocked or stuck, so a
-- navigation failure never freezes a bot's shopping.
function BotActors.walkTo(model, target, running)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return false end
	root.Anchored = false
	local path = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = true, WaypointSpacing = 6 })
	local ok = pcall(function() path:ComputeAsync(root.Position, target) end)
	if ok and path.Status == Enum.PathStatus.Success then
		for _, waypoint in ipairs(path:GetWaypoints()) do
			if not running() then return false end
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
			humanoid:MoveTo(waypoint.Position)
			local started = os.clock()
			while true do
				local offset = root.Position - waypoint.Position
				if Vector3.new(offset.X, 0, offset.Z).Magnitude < 2.5 and math.abs(offset.Y) < 6 then break end
				if os.clock() - started > 4 then
					model:PivotTo(CFrame.new(target)); return true
				end
				if not running() or not model.Parent then return false end
				task.wait(0.1)
			end
		end
	else
		model:PivotTo(CFrame.new(target))
	end
	return true
end

function BotActors.place(model, cf, anchored)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local seat = humanoid.SeatPart
		humanoid.Sit = false
		local weld = seat and seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end
		humanoid:MoveTo(root.Position)
	end
	root.Anchored = false; root.AssemblyLinearVelocity = Vector3.zero
	model:PivotTo(cf); root.Anchored = anchored == true
end

return BotActors

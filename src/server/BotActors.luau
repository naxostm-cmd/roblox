-- NPC contestants: R15 bodies that walk the mall. Purchases are not decided here.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local BotActors = {}

local skins = { { 255, 220, 196 }, { 234, 184, 146 }, { 198, 140, 104 }, { 141, 94, 66 }, { 247, 208, 178 } }
local hairColors = { { 60, 40, 30 }, { 214, 170, 100 }, { 25, 22, 26 }, { 150, 70, 40 }, { 230, 150, 190 } }
-- Default Roblox R15 animations; NPCs need them played from the server.
local animations = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826" }

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
	humanoid.Running:Connect(function(speed)
		if not tracks.walk then return end
		if speed > 0.5 and not tracks.walk.IsPlaying then tracks.walk.Looped = true; tracks.walk:Play(0.15)
		elseif speed <= 0.5 and tracks.walk.IsPlaying then tracks.walk:Stop(0.2) end
	end)
end

function BotActors.spawn(folder, name, cf, rng)
	local description = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(table.unpack(skins[rng:NextInteger(1, #skins)]))
	description.HeadColor = skin; description.TorsoColor = skin
	description.LeftArmColor = skin; description.RightArmColor = skin
	description.LeftLegColor = skin; description.RightLegColor = skin
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("Bot body could not be created: " .. tostring(model))
		return nil
	end
	model.Name = "[BOT] " .. name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "[BOT] " .. name
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance = 80
	-- The bundled Animate LocalScript never runs on an NPC.
	local animateScript = model:FindFirstChild("Animate"); if animateScript then animateScript:Destroy() end
	hair(model, rng)
	model.Parent = folder
	model:PivotTo(cf)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then pcall(function() root:SetNetworkOwner(nil) end) end
	animate(humanoid)
	return model, description
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
	if humanoid then humanoid:MoveTo(root.Position) end
	root.Anchored = false; root.AssemblyLinearVelocity = Vector3.zero
	model:PivotTo(cf); root.Anchored = anchored == true
end

return BotActors

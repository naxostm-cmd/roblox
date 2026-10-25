-- Visual-only rewards: rank tag, VIP badge, aura, crown, runway effects.
local Cosmetics = {}
local poses = { "rbxassetid://507770677", "rbxassetid://507770239", "rbxassetid://507771019" } -- cheer, wave, dance

local function emitter(parent, name, colors, rate)
	local e = Instance.new("ParticleEmitter"); e.Name = name
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(colors[1], colors[2]); e.Rate = rate
	e.Lifetime = NumberRange.new(0.8, 1.6); e.Speed = NumberRange.new(0.5, 2)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.SpreadAngle = Vector2.new(180, 180); e.LightEmission = 0.6; e.Parent = parent
	return e
end

function Cosmetics.apply(character, summary)
	if not character or not summary then return end
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	for _, object in ipairs(character:GetDescendants()) do
		if object:GetAttribute("SQCosmetic") then object:Destroy() end
	end
	local equipped = summary.equipped or {}
	if head then
		local tag = Instance.new("BillboardGui"); tag.Name = "RankTag"; tag:SetAttribute("SQCosmetic", true)
		tag.Size = UDim2.fromOffset(220, 46); tag.StudsOffset = Vector3.new(0, 2.6, 0); tag.MaxDistance = 70; tag.Parent = head
		local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold; label.TextScaled = true; label.TextStrokeTransparency = 0.4
		label.Text = (if equipped.vip_style then "VIP ✦ " else "") .. "★ " .. summary.title
		label.TextColor3 = if equipped.vip_style then Color3.fromRGB(255, 214, 120) else Color3.fromRGB(255, 190, 220)
		label.Parent = tag
		if equipped.diamond_name then
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 230, 255)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 170, 255)) })
			gradient.Parent = label
			label.TextColor3 = Color3.new(1, 1, 1)
			task.spawn(function()
				while gradient.Parent do gradient.Rotation = (gradient.Rotation + 4) % 360; task.wait(0.05) end
			end)
		end
		if equipped.star_crown then
			local crown = Instance.new("Part"); crown.Name = "StarCrown"; crown:SetAttribute("SQCosmetic", true)
			crown.Size = Vector3.new(1.4, 0.5, 1.4); crown.Shape = Enum.PartType.Cylinder; crown.Material = Enum.Material.Neon
			crown.Color = Color3.fromRGB(255, 205, 90); crown.CanCollide = false; crown.CanQuery = false; crown.CanTouch = false; crown.Massless = true
			crown.CFrame = head.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2); crown.Parent = character
			local weld = Instance.new("WeldConstraint"); weld.Part0 = head; weld.Part1 = crown; weld.Parent = crown
			emitter(crown, "CrownSparkle", { Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 255, 255) }, 4)
		end
	end
	if root and equipped.rose_trail then
		local aura = emitter(root, "RoseAura", { Color3.fromRGB(255, 120, 190), Color3.fromRGB(255, 200, 230) }, 10)
		aura:SetAttribute("SQCosmetic", true)
	end
end

-- On the runway: golden entrance sparkles, then a pose at the front.
function Cosmetics.entrance(character, summary)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not summary or not summary.equipped.gold_entrance then return end
	local burst = emitter(root, "GoldenEntrance", { Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 250, 200) }, 40)
	task.delay(5, function() burst.Enabled = false; task.wait(2); burst:Destroy() end)
end

function Cosmetics.poseId(summary, rng)
	if not summary or not summary.equipped.runway_poses then return nil end
	return poses[rng:NextInteger(1, #poses)]
end

return Cosmetics

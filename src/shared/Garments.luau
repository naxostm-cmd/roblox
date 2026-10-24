-- Original, stylised clothing built from fitted parts. Works without asset uploads.
local Garments = {}
function Garments.build(character, item, color, folder)
	local clothingTypes = { Shirt = true, Pants = true, Jacket = true, Sweater = true, Shorts = true, DressSkirt = true }
	for _, object in ipairs(character:GetChildren()) do
		if object:IsA("Accessory") and clothingTypes[object.AccessoryType.Name] then
			for _, p in ipairs(object:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 1 end end
		end
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local hip = character:FindFirstChild("LowerTorso") or torso
	if not torso or not hip then return end
	local function piece(limb, name, size, offset, tint, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = tint or color
		p.Material = Enum.Material.Fabric; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.CFrame = limb.CFrame * offset; p.Parent = folder
		local weld = Instance.new("WeldConstraint"); weld.Part0 = limb; weld.Part1 = p; weld.Parent = p
		return p
	end
	local w, h, d = torso.Size.X, torso.Size.Y, torso.Size.Z
	local trim = Color3.fromRGB(232, 199, 134)
	if item.style == "pleated" or item.style == "mini" then
		local length = if item.style == "pleated" then 1.65 else 1.0
		local waistY = if hip == torso then -h * 0.36 else 0
		local radius = math.max(hip.Size.X * 0.6, 0.8)
		for i = 1, 16 do
			local angle = (i - 1) * math.pi * 2 / 16
			local cf = CFrame.new(0, waistY, 0) * CFrame.Angles(0, angle, 0)
				* CFrame.new(0, -length * 0.45, -radius) * CFrame.Angles(-0.28, 0, 0)
			piece(hip, "SkirtPleat", Vector3.new(radius * 0.52, length, 0.16), cf, if i % 2 == 0 then color else color:Lerp(Color3.new(0, 0, 0), 0.08))
		end
		piece(hip, "Waistband", Vector3.new(hip.Size.X + 0.2, 0.22, hip.Size.Z + 0.24), CFrame.new(0, waistY, 0), trim)
		return
	end
	if not item.style then return end
	piece(torso, "FittedBodice", Vector3.new(w + 0.12, h * 0.82, d + 0.14), CFrame.new(0, -h * 0.08, 0))
	if item.style == "jacket" then
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "IvoryLapel", Vector3.new(w * 0.2, h * 0.7, 0.12), CFrame.new(side * w * 0.18, h * 0.04, -d / 2 - 0.14) * CFrame.Angles(0, 0, side * -0.24), Color3.fromRGB(245, 233, 216))
			piece(torso, "Pocket", Vector3.new(w * 0.26, h * 0.12, 0.13), CFrame.new(side * w * 0.29, -h * 0.28, -d / 2 - 0.17))
		end
		for i = 1, 3 do piece(torso, "GoldButton", Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, h * (0.15 - i * 0.17), -d / 2 - 0.2), trim, Enum.PartType.Ball) end
	elseif item.style == "corset" then
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "CorsetSeam", Vector3.new(0.06, h * 0.65, 0.06), CFrame.new(side * w * 0.22, -h * 0.08, -d / 2 - 0.12), trim)
		end
		for i = 1, 4 do
			piece(torso, "Lacing", Vector3.new(w * 0.27, 0.035, 0.05), CFrame.new(0, h * (0.23 - i * 0.13), -d / 2 - 0.14) * CFrame.Angles(0, 0, if i % 2 == 0 then 0.3 else -0.3), trim)
		end
	else
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "Bow", Vector3.new(w * 0.3, h * 0.18, 0.22), CFrame.new(side * w * 0.12, h * 0.24, -d / 2 - 0.2) * CFrame.Angles(0, 0, side * 0.25), color:Lerp(Color3.new(1, 1, 1), 0.25))
		end
	end
	if item.style ~= "corset" then
		for _, side in ipairs({ "Left", "Right" }) do
			local arm = character:FindFirstChild(side .. "UpperArm") or character:FindFirstChild(side .. " Arm")
			if arm then
				piece(arm, "Sleeve", Vector3.new(arm.Size.X + 0.16, arm.Size.Y * 0.75, arm.Size.Z + 0.16), CFrame.new(0, arm.Size.Y * 0.1, 0), color, if item.style == "blouse" then Enum.PartType.Ball else nil)
			end
		end
	end
end
return Garments

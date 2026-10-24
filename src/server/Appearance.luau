local Appearance = {}
local originals = setmetatable({}, { __mode = "k" })

local function remember(character)
	if originals[character] then return originals[character] end
	local snapshot = { colors = {}, clothes = {}, accessories = {} }
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") and object.Parent == character then snapshot.colors[object] = object.Color end
		if object:IsA("Shirt") then snapshot.clothes[object] = object.ShirtTemplate end
		if object:IsA("Pants") then snapshot.clothes[object] = object.PantsTemplate end
		if object:IsA("BasePart") and object:FindFirstAncestorOfClass("Accessory") then snapshot.accessories[object] = object.Transparency end
	end
	originals[character] = snapshot
	return snapshot
end

local function restore(character)
	local snapshot = remember(character)
	local generated = character:FindFirstChild("SQOutfit")
	if generated then generated:Destroy() end
	for p, color in pairs(snapshot.colors) do if p.Parent then p.Color = color end end
	for p, value in pairs(snapshot.clothes) do
		if p.Parent then
			if p:IsA("Shirt") then p.ShirtTemplate = value else p.PantsTemplate = value end
		end
	end
	for p, value in pairs(snapshot.accessories) do if p.Parent then p.Transparency = value end end
	return snapshot
end

local function attach(folder, limb, name, size, offset, color)
	if not limb then return end
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color
	p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true
	p.CFrame = limb.CFrame * offset; p.Parent = folder
	local weld = Instance.new("WeldConstraint"); weld.Part0 = limb; weld.Part1 = p; weld.Parent = p
end

function Appearance.apply(character, look, catalog)
	if not character then return end
	local snapshot = restore(character)
	if not look or next(look) == nil then return end
	for p in pairs(snapshot.clothes) do
		if p.Parent then
			if p:IsA("Shirt") then p.ShirtTemplate = "" else p.PantsTemplate = "" end
		end
	end
	local folder = Instance.new("Folder"); folder.Name = "SQOutfit"; folder.Parent = character
	for _, item in ipairs(catalog) do
		if look[item.category] ~= item.id then continue end
		local color = Color3.fromRGB(table.unpack(item.color))
		if item.category == "top" or item.category == "bottom" then
			for p in pairs(snapshot.colors) do
				local name = p.Name
				local upper = name:find("Torso") or name:find("Arm") or name:find("Hand")
				local lower = name:find("Leg") or name:find("Foot")
				if p.Parent and ((item.category == "top" and upper) or (item.category == "bottom" and lower)) then p.Color = color end
			end
		elseif item.category == "shoes" then
			for _, side in ipairs({ "Left", "Right" }) do
				local foot = character:FindFirstChild(side .. "Foot") or character:FindFirstChild(side .. " Leg")
				if foot then attach(folder, foot, "Shoe", Vector3.new(foot.Size.X + 0.15, 0.45, foot.Size.Z + 0.25), CFrame.new(0, -foot.Size.Y / 2 + 0.2, -0.08), color) end
			end
		else
			for p in pairs(snapshot.accessories) do if p.Parent then p.Transparency = 1 end end
			local head = character:FindFirstChild("Head")
			attach(folder, head, "HatBrim", Vector3.new(3, 0.15, 2), CFrame.new(0, 0.65, 0), color)
			attach(folder, head, "HatCrown", Vector3.new(1.6, 0.65, 1.5), CFrame.new(0, 1, 0), color)
		end
	end
end
return Appearance

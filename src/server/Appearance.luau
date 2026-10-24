local Appearance = {}
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local shared = game:GetService("ReplicatedStorage").Shared
local Garments = require(shared.Garments)
local Rules = require(shared.Rules)
local Config = require(shared.Config)
local Mall = require(shared.Mall)
local originals = setmetatable({}, { __mode = "k" })
local bases = setmetatable({}, { __mode = "k" })
local applied = setmetatable({}, { __mode = "k" })
local queued = setmetatable({}, { __mode = "k" })
local userDescriptions = {}
local versions = setmetatable({}, { __mode = "k" })

-- Layered clothing needs an order: shoes, then bottoms, then tops from inner to outer.
local layerOrder = { LeftShoe = 1, RightShoe = 1, Pants = 2, Shorts = 2, DressSkirt = 3, TShirt = 4, Shirt = 5, Sweater = 6, Jacket = 7 }
-- A bought piece replaces what the avatar already wears in the same place.
local replaces = {
	top = { Shirt = true, TShirt = true, Sweater = true, Jacket = true },
	bottom = { Pants = true, Shorts = true, DressSkirt = true },
	shoes = { LeftShoe = true, RightShoe = true },
	accessory = { Hat = true },
	glasses = { Face = true },
	jewelry = { Neck = true },
	bag = {},
}

local function remember(character)
	if originals[character] then return originals[character] end
	local snapshot = { colors = {}, clothes = {}, accessories = {} }
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") and object.Parent == character then snapshot.colors[object] = object.Color end
		if object:IsA("Shirt") then snapshot.clothes[object] = object.ShirtTemplate end
		if object:IsA("Pants") then snapshot.clothes[object] = object.PantsTemplate end
		if object:IsA("ShirtGraphic") then snapshot.clothes[object] = object.Graphic end
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
			if p:IsA("Shirt") then p.ShirtTemplate = value elseif p:IsA("Pants") then p.PantsTemplate = value else p.Graphic = value end
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

-- Bots pass the description they were built from.
function Appearance.setBase(character, description)
	bases[character] = description
end

local function baseFor(character, humanoid)
	if bases[character] then return bases[character] end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return nil end
	local description = userDescriptions[player.UserId]
	if not description then
		local ok, result = pcall(function() return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1)) end)
		if ok and result then description = result; userDescriptions[player.UserId] = result end
	end
	if not description then
		local ok, result = pcall(function() return humanoid:GetAppliedDescription() end)
		if ok then description = result end
	end
	bases[character] = description
	return description
end

local function describe(base, items)
	local description = base:Clone()
	local drop = {}
	for _, item in ipairs(items) do
		for kind in pairs(replaces[item.category] or {}) do drop[kind] = true end
		if item.category == "top" then description.Shirt = 0; description.GraphicTShirt = 0 end
		if item.category == "bottom" then description.Pants = 0 end
	end
	local list, signature = {}, {}
	for _, accessory in ipairs(description:GetAccessories(true)) do
		if not drop[accessory.AccessoryType.Name] then table.insert(list, accessory) end
	end
	for _, item in ipairs(items) do
		for _, asset in ipairs(item.assets) do
			local order = layerOrder[asset.type]
			table.insert(list, { AssetId = asset.id, AccessoryType = Enum.AccessoryType[asset.type], IsLayered = order ~= nil, Order = order, Puffiness = if order then 1 else nil })
			table.insert(signature, asset.id)
		end
	end
	description:SetAccessories(list, true)
	table.sort(signature)
	return description, table.concat(signature, ",")
end

-- ApplyDescription yields; keep only the latest request per character.
local function applyDescription(character, humanoid, description, signature)
	-- An untouched avatar already wears its base description.
	if applied[character] == signature or (signature == "" and applied[character] == nil) then return true end
	if queued[character] then queued[character] = { description, signature }; return true end
	queued[character] = { description, signature }
	local ok = true
	while queued[character] do
		local job = queued[character]
		ok = pcall(function() humanoid:ApplyDescription(job[1]) end)
		if ok then applied[character] = job[2] else applied[character] = nil end
		if queued[character] == job then queued[character] = nil end
	end
	return ok
end

local function buildParts(character, snapshot, items, look)
	if #items == 0 then return end
	local hidesTop, hidesBottom = false, false
	for _, item in ipairs(items) do
		if item.category == "top" then hidesTop = true elseif item.category == "bottom" then hidesBottom = true end
	end
	for p in pairs(snapshot.clothes) do
		if p.Parent then
			if p:IsA("Shirt") and hidesTop then p.ShirtTemplate = "" elseif p:IsA("Pants") and hidesBottom then p.PantsTemplate = "" elseif p:IsA("ShirtGraphic") and hidesTop then p.Graphic = "" end
		end
	end
	local folder = Instance.new("Folder"); folder.Name = "SQOutfit"; folder.Parent = character
	for _, item in ipairs(items) do
		local choice = look.colors and Rules.color(Config.Palette, look.colors[item.category])
		local color = Color3.fromRGB(table.unpack(if choice then choice.rgb else item.color))
		if item.style then
			Garments.build(character, item, color, folder)
		elseif item.category == "shoes" then
			for _, side in ipairs({ "Left", "Right" }) do
				local foot = character:FindFirstChild(side .. "Foot") or character:FindFirstChild(side .. " Leg")
				if foot then attach(folder, foot, "Shoe", Vector3.new(foot.Size.X + 0.15, 0.45, foot.Size.Z + 0.25), CFrame.new(0, -foot.Size.Y / 2 + 0.2, -0.08), color) end
			end
		end
	end
end

-- R15 avatars wear the real catalog items; R6 avatars, and items whose asset is
-- unavailable, get the built-in part models instead.
function Appearance.apply(character, look, catalog)
	if not character then return end
	versions[character] = (versions[character] or 0) + 1
	local version = versions[character]
	local snapshot = restore(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local base = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and baseFor(character, humanoid)
	local catalogItems, partItems = {}, {}
	for _, item in ipairs(catalog) do
		if look and look[item.category] == item.id then
			if base and Mall.usesCatalog(item) then table.insert(catalogItems, item) else table.insert(partItems, item) end
		end
	end
	if base then
		local description, signature = describe(base, catalogItems)
		if not applyDescription(character, humanoid, description, signature) then
			-- One broken asset must not leave the player without clothes.
			for _, item in ipairs(catalogItems) do table.insert(partItems, item) end
		end
	end
	-- A newer request may have arrived while the description was loading.
	if character.Parent and versions[character] == version then buildParts(character, snapshot, partItems, look or {}) end
end

-- Server start: items whose assets were deleted fall back to part models.
function Appearance.validate(pools)
	for _, pool in pairs(pools) do
		for _, template in ipairs(pool) do
			for _, asset in ipairs(template[5] or {}) do
				local ok, info = pcall(function() return MarketplaceService:GetProductInfo(asset.id, Enum.InfoType.Asset) end)
				if not ok or type(info) ~= "table" or info.AssetId == nil or string.find(info.Name or "", "Content Deleted", 1, true) then
					Mall.Unavailable[asset.id] = true
					warn("Catalog item unavailable, using part model: " .. asset.id)
				end
				task.wait(0.1)
			end
		end
	end
end

-- Store mannequins dressed in the real item.
function Appearance.mannequin(item, cf, parent)
	if not Mall.usesCatalog(item) then return nil end
	local description = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(240, 232, 226)
	description.HeadColor = skin; description.TorsoColor = skin
	description.LeftArmColor = skin; description.RightArmColor = skin
	description.LeftLegColor = skin; description.RightLegColor = skin
	local model
	local ok = pcall(function()
		description = describe(description, { item })
		model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model or not parent.Parent then
		if model then model:Destroy() end
		return nil
	end
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") then object:Destroy()
		elseif object:IsA("BasePart") then object.Anchored = true; object.CanCollide = false end
	end
	local face = model:FindFirstChild("Head") and model.Head:FindFirstChildOfClass("Decal")
	if face then face:Destroy() end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local root = model:FindFirstChild("HumanoidRootPart")
	model.Name = "CatalogMannequin"
	model:SetAttribute("ItemId", item.id)
	model:PivotTo(cf * CFrame.new(0, 0.5 + humanoid.HipHeight + (if root then root.Size.Y / 2 else 1), 0))
	model.Parent = parent
	return model
end

return Appearance

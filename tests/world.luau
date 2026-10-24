-- Geometry checks with a small engine stand-in, not a Roblox rendering test.
return function(source, configSource, garmentsSource, mallSource)
	local all = {}
	local V = {}
	V.__index = function(self, key)
		if key == "Magnitude" then return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z) end
		if key == "Unit" then local m = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z); return setmetatable({ X = self.X / m, Y = self.Y / m, Z = self.Z / m }, V) end
		return V[key]
	end
	local function vec(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V) end
	V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
	V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
	V.__unm = function(a) return vec(-a.X, -a.Y, -a.Z) end
	V.__mul = function(a, b)
		if type(a) == "number" then return vec(a * b.X, a * b.Y, a * b.Z) end
		if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
		return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end
	V.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
	function V.Lerp(a, b, t) return a + (b - a) * t end
	function V.Cross(a, b) return vec(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
	function V.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end

	-- Rotation matrix as three columns (right, up, back).
	local C = {}
	local function cframe(p, r) return setmetatable({ p = p, r = r or { vec(1, 0, 0), vec(0, 1, 0), vec(0, 0, 1) } }, C) end
	local function rotate(r, v) return r[1] * v.X + r[2] * v.Y + r[3] * v.Z end
	C.__index = function(self, key)
		if key == "Position" then return self.p end
		if key == "LookVector" then return -self.r[3] end
		if key == "UpVector" then return self.r[2] end
		if key == "RightVector" then return self.r[1] end
		return C[key]
	end
	C.__mul = function(a, b)
		if getmetatable(b) == V then return a.p + rotate(a.r, b) end
		return cframe(a.p + rotate(a.r, b.p), { rotate(a.r, b.r[1]), rotate(a.r, b.r[2]), rotate(a.r, b.r[3]) })
	end
	function C.PointToObjectSpace(self, v)
		local d = v - self.p
		return vec(d:Dot(self.r[1]), d:Dot(self.r[2]), d:Dot(self.r[3]))
	end
	local function axis(angle, which)
		local c, s = math.cos(angle), math.sin(angle)
		if which == "x" then return { vec(1, 0, 0), vec(0, c, s), vec(0, -s, c) } end
		if which == "y" then return { vec(c, 0, -s), vec(0, 1, 0), vec(s, 0, c) } end
		return { vec(c, s, 0), vec(-s, c, 0), vec(0, 0, 1) }
	end
	local CFrameLib = {
		new = function(x, y, z)
			if x == nil then return cframe(vec()) end
			if type(x) == "table" then return cframe(x) end
			return cframe(vec(x, y, z))
		end,
		Angles = function(rx, ry, rz)
			return cframe(vec(), axis(rx, "x")) * cframe(vec(), axis(ry, "y")) * cframe(vec(), axis(rz, "z"))
		end,
		lookAt = function(at, target)
			local forward = (target - at).Unit
			local right = forward:Cross(vec(0, 1, 0))
			if right.Magnitude < 1e-6 then right = vec(1, 0, 0) else right = right.Unit end
			local up = right:Cross(forward)
			return cframe(at, { right, up, -forward })
		end,
	}

	local methods = {}
	function methods:FindFirstChild(name)
		for _, child in ipairs(all) do if child.Parent == self and child.Name == name and not child.destroyed then return child end end
	end
	function methods:FindFirstChildOfClass(class)
		for _, child in ipairs(all) do if child.Parent == self and child.ClassName == class and not child.destroyed then return child end end
	end
	function methods:GetChildren()
		local children = {}; for _, obj in ipairs(all) do if obj.Parent == self and not obj.destroyed then table.insert(children, obj) end end; return children
	end
	function methods:GetDescendants()
		local descendants = {}
		for _, obj in ipairs(all) do
			local ancestor = obj.Parent
			while ancestor do if ancestor == self and not obj.destroyed then table.insert(descendants, obj); break end; ancestor = ancestor.Parent end
		end
		return descendants
	end
	function methods:IsA(class) return self.ClassName == class or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "Seat")) end
	function methods:Destroy()
		self.destroyed = true
		for _, child in ipairs(all) do if child.Parent == self and not child.destroyed then child:Destroy() end end
	end
	local function instance(class)
		local obj = setmetatable({ ClassName = class, CanCollide = true }, { __index = methods })
		obj.Triggered = { Connect = function(_, fn) obj.callback = fn end }
		table.insert(all, obj)
		return obj
	end
	local workspace = instance("Workspace")
	local original = instance("Part"); original.Name = "OriginalBaseplate"; original.Parent = workspace
	local enum = setmetatable({}, { __index = function(_, key)
		return setmetatable({}, { __index = function(_, value) return key .. "." .. value end })
	end })
	local env = setmetatable({
		workspace = workspace, Instance = { new = instance }, Enum = enum,
		Vector3 = { new = vec, zero = vec() }, Color3 = { fromRGB = vec, new = vec },
		CFrame = CFrameLib, UDim2 = { fromScale = function(...) return { ... } end },
	}, { __index = getfenv() })
	local loader = assert(loadstring(source))
	setfenv(loader, env)
	local World = loader()
	local config = assert(loadstring(configSource))()
	local garmentLoader = assert(loadstring(garmentsSource)); setfenv(garmentLoader, env)
	local garments = garmentLoader()
	local Mall = assert(loadstring(mallSource))()
	local rng = { NextInteger = function(_, low) return low end }
	local catalog = Mall.generate(rng, nil, config.Palette)
	World.configure(Mall.Stores, Mall.Decor)
	local opened, products, joined, food = {}, {}, nil, {}
	local mall = World.create(function(player, category, id) opened[category] = player; if id then products[id] = true end end, catalog, garments,
		function(player) joined = player end, function(_, index) food[index] = true end)

	local parts, prompts, models = {}, {}, {}
	for _, obj in ipairs(all) do
		if obj.ClassName == "Part" or obj.ClassName == "SpawnLocation" or obj.ClassName == "Seat" then
			if obj ~= original then table.insert(parts, obj); assert(obj.Anchored or obj:FindFirstChildOfClass("WeldConstraint"), obj.Name .. " is not anchored") end
		elseif obj.ClassName == "ProximityPrompt" then table.insert(prompts, obj)
		elseif obj.ClassName == "Model" then models[obj.Name] = (models[obj.Name] or 0) + 1 end
	end
	assert(#prompts == 87, "20 counters + 60 products + lounge entry + 6 food stalls, got " .. #prompts)
	for _, prompt in ipairs(prompts) do
		assert(prompt.callback and prompt.MaxActivationDistance >= 9)
		prompt.callback("test-player")
	end
	assert(joined == "test-player", "lounge door must register for the round")
	for i = 1, 6 do assert(food[i], "food stall " .. i) end
	for _, item in ipairs(catalog) do assert(products[item.id], "missing garment interaction") end
	assert(models.Escalator == 2 and models.Staircase == 2, "two escalators and two staircases")
	for _, unit in ipairs(Mall.Decor) do assert(models["Unit_" .. unit.id], "decor unit " .. unit.id) end

	-- World-space bounding boxes, exact for the axis-aligned bulk of the map.
	local function bounds(p)
		local cf = p.CFrame or CFrameLib.new(p.Position)
		local h = p.Size * 0.5
		local e = vec(
			math.abs(cf.r[1].X) * h.X + math.abs(cf.r[2].X) * h.Y + math.abs(cf.r[3].X) * h.Z,
			math.abs(cf.r[1].Y) * h.X + math.abs(cf.r[2].Y) * h.Y + math.abs(cf.r[3].Y) * h.Z,
			math.abs(cf.r[1].Z) * h.X + math.abs(cf.r[2].Z) * h.Y + math.abs(cf.r[3].Z) * h.Z)
		return cf.p, e
	end
	local boxes = {}
	for _, p in ipairs(parts) do
		if p.CanCollide ~= false and not p.destroyed then
			local c, e = bounds(p); table.insert(boxes, { part = p, c = c, e = e })
		end
	end
	local function blockedAt(x, y, z, margin, ignore)
		for _, b in ipairs(boxes) do
			if ignore and ignore(b.part) then continue end
			if math.abs(x - b.c.X) < b.e.X + margin and math.abs(y - b.c.Y) < b.e.Y and math.abs(z - b.c.Z) < b.e.Z + margin then return b.part end
		end
		return nil
	end
	local function supported(x, y, z)
		for _, b in ipairs(boxes) do
			local top = b.c.Y + b.e.Y
			if math.abs(x - b.c.X) <= b.e.X and math.abs(z - b.c.Z) <= b.e.Z and top >= y - 0.6 and top <= y + 0.35 then return true end
		end
		return false
	end
	local function clear(label, from, to, ignore)
		local steps = math.ceil((to - from).Magnitude / 1.5)
		for i = 0, steps do
			local p = from:Lerp(to, i / steps)
			for _, h in ipairs({ 1.2, 3, 5 }) do
				local hit = blockedAt(p.X, p.Y + h, p.Z, 0.8, ignore)
				assert(not hit, label .. " blocked at " .. math.floor(p.X) .. "," .. math.floor(p.Z) .. " by " .. (hit and hit.Name or ""))
			end
		end
	end
	local F, L2 = World.FLOOR, World.L2
	-- Walkable floors on both levels, and an open void above the runway.
	for _, point in ipairs({
		vec(30, F, 0), vec(0, F, 50), vec(0, F, 90), vec(40, F, 60), vec(0, F, -50), vec(60, F, 8), vec(-120, F, -8),
		vec(0, L2, -33), vec(33, L2, 0), vec(0, L2, 33), vec(60, L2, 8), vec(-100, L2, -8), vec(68, L2, 0), vec(-68, L2, 0),
		vec(0, L2, -60), vec(20, L2, -95), vec(-19, L2, -26), vec(19, F, 18),
	}) do
		assert(supported(point.X, point.Y, point.Z), "missing floor at " .. point.X .. "," .. point.Y .. "," .. point.Z)
	end
	assert(not supported(0, L2, 0) and not supported(55, L2, 0), "atrium and wing voids stay open")
	-- Routes: plaza -> automatic doors -> hall -> atrium -> wings and food court.
	local doors = function(p) return p.Name == "AutoDoor" end
	clear("plaza to doors", vec(0, F, 88), vec(0, F, 40), doors)
	assert(blockedAt(2, F + 3, 65.4, 0, nil) and blockedAt(-2, F + 3, 65.4, 0, nil), "closed doors fill the opening")
	World.updateDoors({ World.EntranceDoor + vec(0, 0, 8) })
	for _, b in ipairs(boxes) do if b.part.Name == "AutoDoor" then b.c, b.e = bounds(b.part) end end
	clear("doors open on approach", vec(0, F, 88), vec(0, F, 40))
	World.updateDoors({})
	for _, b in ipairs(boxes) do if b.part.Name == "AutoDoor" then b.c, b.e = bounds(b.part) end end
	assert(blockedAt(2, F + 3, 65.4, 0, nil) and blockedAt(-2, F + 3, 65.4, 0, nil), "doors close again")
	clear("hall to atrium", vec(8, F, 40), vec(8, F, 26))
	for _, sx in ipairs({ -1, 1 }) do
		clear("ground corridor", vec(sx * 26, F, 8), vec(sx * 124, F, 8))
		clear("first floor walkway", vec(sx * 33, L2, 7), vec(sx * 122, L2, 7))
	end
	clear("food court entry", vec(0, L2, -30), vec(0, L2, -50))
	-- Every store: an unobstructed way from its corridor into the shop.
	for _, store in ipairs(Mall.Stores) do
		assert(opened[store.id] == "test-player", "missing shop callback: " .. store.id)
		assert(models["Shop_" .. store.id], "missing shop building")
		local target = World.StoreTargets[store.id]
		local y = F + (store.level - 1) * 20
		assert(supported(target.X, y + 0.25, target.Z), "shop floor under target " .. store.id)
		clear("entrance " .. store.id, vec(store.x, y, (if store.z > 0 then 1 else -1) * 8), vec(target.X, y, target.Z))
		assert(World.nearStore(store.id, target), "near own counter")
		assert(not World.nearStore(store.id, target + vec(0, 20, 0)) and not World.nearStore(store.id, target - vec(0, 20, 0)), "other floor is not near")
		for _, other in ipairs(Mall.Stores) do
			if other ~= store then assert(not World.nearStore(store.id, World.StoreTargets[other.id]), "neighbour counts as near") end
		end
	end
	-- Lounge: enclosed glass room with a gap-free envelope.
	local LZ = World.LoungeCenter.Z
	assert(World.isInsideLobby(World.Lobby.Position), "spawn inside lounge")
	assert(not World.isInsideLobby(World.ShoppingStart.Position), "shopping destination outside lounge")
	for _, position in ipairs({ vec(0, 12, LZ - 13), vec(0, 12, LZ + 13), vec(18, 12, LZ), vec(-18, 12, LZ), vec(0, 30, LZ), vec(0, 0, LZ) }) do
		assert(not World.isInsideLobby(position), "escape or fall detected")
	end
	local function solid(x, y, z) return blockedAt(x, y, z, 0, nil) ~= nil end
	for _, y in ipairs({ 10, 18, 23 }) do
		for x = -16, 16, 2 do
			assert(solid(x, y, LZ - 12), "front window or closed door has gap")
			assert(solid(x, y, LZ + 12), "back wall has gap")
		end
		for z = LZ - 11, LZ + 11, 2 do assert(solid(-17, y, z) and solid(17, y, z), "side wall has gap") end
	end
	for x = -16, 16, 4 do
		for z = LZ - 11, LZ + 11, 4 do assert(solid(x, 24.1, z), "ceiling must prevent climbing out") end
	end
	local seats, transparentWalls = 0, 0
	for _, p in ipairs(parts) do
		if p.Name == "LoungeSeat" then seats += 1 end
		if p.Name == "LoungeSideGlass" or p.Name == "LoungeFrontGlass" or p.Name == "LockedLobbyDoor" then
			assert(p.CanCollide and p.Transparency >= 0.6, "lounge windows must be see-through and solid")
			transparentWalls += 1
		end
	end
	assert(seats == 6 and transparentWalls == 5, "furnished lounge with clear view of the mall")
	local spawn = World.Lobby.Position
	for _, x in ipairs({ -1, 0, 1 }) do
		for _, y in ipairs({ -2, 0, 2 }) do
			for _, z in ipairs({ -1, 0, 1 }) do assert(not solid(spawn.X + x, spawn.Y + y, spawn.Z + z), "spawn overlaps furniture") end
		end
	end
	assert(supported(World.ShoppingStart.Position.X, F + 0.2, World.ShoppingStart.Position.Z), "start point stands on the plaza")
	assert(World.Stage.Position.Y > F + 2, "stage above floor")
	assert(#parts < 7000, "part budget")
	-- Exercise every generated design on both supported rig layouts.
	local designs = {}
	local seed = 42
	local allRng = { NextInteger = function(_, low, high) seed = (seed * 16807) % 2147483647; return low + seed % (high - low + 1) end }
	for _ = 1, 100 do for _, item in ipairs(Mall.generate(allRng, nil, config.Palette)) do designs[item.style] = item end end
	for _, rigType in ipairs({ "R6", "R15" }) do
		local rig = instance("Model"); rig.Parent = workspace
		local names = if rigType == "R6" then { "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } else { "UpperTorso", "LowerTorso", "Head", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot" }
		for _, name in ipairs(names) do
			local limb = instance("Part"); limb.Name = name; limb.Size = vec(2, 2, 1); limb.CFrame = CFrameLib.new(0, 0, 0); limb.Parent = rig
		end
		local count = 0
		for _, item in pairs(designs) do
			local outfit = instance("Folder"); outfit.Parent = rig
			garments.build(rig, item, vec(1, 0.5, 0.5), outfit)
			assert(#outfit:GetChildren() > 0, item.style .. " missing geometry on " .. rigType)
			for _, obj in ipairs(outfit:GetChildren()) do
				assert(not obj.CanCollide and obj.Massless and obj:FindFirstChildOfClass("WeldConstraint"), "wearable must be attached without blocking movement")
			end
			count += 1; outfit:Destroy()
		end
		assert(count == 42); rig:Destroy()
	end
	print("PASS: all 42 garment designs construct on R6 and R15 stand-ins")
	local shopModels = {}
	for _, obj in ipairs(all) do if obj.ClassName == "Model" and not obj.destroyed then shopModels[obj.Name] = obj end end
	local previousStock = {}
	for _, store in ipairs(Mall.Stores) do previousStock[store.id] = shopModels["Shop_" .. store.id]:FindFirstChild("Stock") end
	local nextCatalog = Mall.generate(rng, catalog, config.Palette)
	World.refreshStock(nextCatalog, garments, function() end)
	for _, store in ipairs(Mall.Stores) do
		assert(previousStock[store.id].destroyed, "old stock must be removed")
		assert(not shopModels["Shop_" .. store.id].destroyed, "refresh must preserve store building")
		local stock = shopModels["Shop_" .. store.id]:FindFirstChild("Stock")
		local livePrompts = 0
		for _, obj in ipairs(stock:GetDescendants()) do if obj.ClassName == "ProximityPrompt" then livePrompts += 1 end end
		assert(livePrompts == 3, "refresh must not accumulate products")
	end
	World.create(function() end)
	assert(mall.destroyed and not original.destroyed, "rebuild must replace only generated gallery")
	print("PASS: two-storey mall, 20 shops + 4 extra units, food court, escalators, stairs, auto doors, routes, enclosed lounge (" .. #parts .. " parts)")
end

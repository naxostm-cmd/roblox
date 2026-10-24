-- Self-contained two-storey shopping centre. Never edits the user's existing map.
-- Plan (top view): south plaza + lounge -> glass entrance hall -> central atrium
-- with runway and escalators -> east/west fashion wings, north food court.
local World = {}
local FLOOR = 8 -- Above the original baseplate, avoiding coplanar floor flicker.
local STOREY = 20
local L2 = FLOOR + STOREY
local ROOF = FLOOR + 2 * STOREY
local SHOP_W, SHOP_D = 28, 30
local LZ = 126 -- Lounge centre on the plaza.
World.FLOOR, World.L2, World.ROOF = FLOOR, L2, ROOF

local cream = Color3.fromRGB(244, 235, 224)
local marble = Color3.fromRGB(236, 230, 224)
local marbleDark = Color3.fromRGB(206, 196, 190)
local pink = Color3.fromRGB(194, 87, 131)
local dark = Color3.fromRGB(48, 43, 55)
local plum = Color3.fromRGB(62, 38, 72)
local gold = Color3.fromRGB(207, 171, 105)
local glass = Color3.fromRGB(190, 220, 225)
local steel = Color3.fromRGB(70, 72, 82)
local wood = Color3.fromRGB(176, 132, 96)
local green = Color3.fromRGB(61, 110, 82)
local paving = Color3.fromRGB(204, 192, 182)

local shops, storeModels, displays = {}, {}, {}
World.StorePositions, World.StoreTargets = {}, {}
World.Doors = {}

local function unitFrame(definition, level)
	local y = FLOOR + (level - 1) * STOREY
	-- Shop fronts are local -Z; turn north-side units to face the corridor.
	local cf = CFrame.new(definition.x, y, definition.z)
	if definition.facing == 1 then cf = cf * CFrame.Angles(0, math.pi, 0) end
	return cf
end

function World.configure(definitions, decor)
	shops = {}; World.StorePositions = {}; World.StoreTargets = {}
	World.DecorUnits = decor or {}
	for _, definition in ipairs(definitions) do
		local shop = table.clone(definition)
		shop.color = Color3.fromRGB(table.unpack(definition.color)); shop.subtitle = definition.specialty
		shop.cf = unitFrame(definition, definition.level or 1)
		table.insert(shops, shop)
		World.StorePositions[shop.id] = (shop.cf * CFrame.new(0, 3, 0)).Position
		World.StoreTargets[shop.id] = (shop.cf * CFrame.new(-5, 3, 1)).Position
	end
end

-- Inside the unit or just outside its front door, on the same floor.
function World.nearStore(id, position)
	for _, shop in ipairs(shops) do
		if shop.id == id then
			local rel = shop.cf:PointToObjectSpace(position)
			return math.abs(rel.X) <= SHOP_W / 2 + 3 and rel.Z >= -SHOP_D / 2 - 9 and rel.Z <= SHOP_D / 2
				and rel.Y > -2 and rel.Y < 12
		end
	end
	return false
end

World.Stage = CFrame.new(0, FLOOR + 5, 11) * CFrame.Angles(0, math.pi, 0)
World.Lobby = CFrame.new(0, FLOOR + 4, LZ + 4)
World.LoungeCenter = Vector3.new(0, FLOOR, LZ)
-- In front of the automatic doors: participants walk into the mall themselves.
World.ShoppingStart = CFrame.new(0, FLOOR + 4, 90)
World.EntranceDoor = Vector3.new(0, FLOOR + 3, 66)

function World.isInsideLobby(position)
	return math.abs(position.X) <= 16.5 and position.Z >= LZ - 11.5 and position.Z <= LZ + 11.5
		and position.Y >= FLOOR + 0.5 and position.Y <= FLOOR + 15.5
end

local function box(parent, name, size, cf, color, material, className)
	local p = Instance.new(className or "Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color; p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function part(parent, name, size, position, color, material, className)
	return box(parent, name, size, CFrame.new(position), color, material, className)
end

local function pane(parent, name, size, cf, transparency)
	local p = box(parent, name, size, cf, glass, Enum.Material.Glass)
	p.Transparency = transparency or 0.7; p.CastShadow = false
	return p
end

local function deco(p)
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	return p
end

local function lamp(p, range, brightness, color)
	local light = Instance.new("PointLight"); light.Range = range or 24; light.Brightness = brightness or 0.8
	light.Color = color or cream; light.Shadows = false; light.Parent = p
	return light
end

local function sign(parent, name, text, size, cf, color, textColor, face, font)
	local board = box(parent, name, size, cf, color)
	local gui = Instance.new("SurfaceGui"); gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 35; gui.Parent = board
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(0.94, 0.86); label.Position = UDim2.fromScale(0.03, 0.07)
	label.BackgroundTransparency = 1; label.Text = text; label.Font = font or Enum.Font.GothamBold
	label.TextColor3 = textColor or cream; label.TextScaled = true; label.TextWrapped = true; label.Parent = gui
	return board
end

local function plant(parent, x, y, z, scale)
	local s = scale or 1
	part(parent, "Planter", Vector3.new(3, 2, 3) * s, Vector3.new(x, y + s, z), cream, Enum.Material.Marble)
	deco(part(parent, "Stem", Vector3.new(0.5, 3, 0.5) * s, Vector3.new(x, y + 3 * s, z), wood))
	local leaves = deco(part(parent, "Leaves", Vector3.new(4, 4, 4) * s, Vector3.new(x, y + 5 * s, z), green, Enum.Material.Grass))
	leaves.Shape = Enum.PartType.Ball
end

local function tree(parent, x, z)
	part(parent, "TreeTrunk", Vector3.new(1.4, 9, 1.4), Vector3.new(x, FLOOR + 4.5, z), wood, Enum.Material.Wood)
	for i, offset in ipairs({ Vector3.new(0, 10, 0), Vector3.new(1.8, 8.5, 0.8), Vector3.new(-1.6, 8.8, -1) }) do
		local crown = deco(part(parent, "TreeCrown", Vector3.new(7, 7, 7) - Vector3.new(i, i, i), Vector3.new(x, FLOOR, z) + offset, green, Enum.Material.Grass))
		crown.Shape = Enum.PartType.Ball
	end
end

local function bench(parent, cf)
	box(parent, "Bench", Vector3.new(6, 0.6, 2), cf * CFrame.new(0, 1.6, 0), wood, Enum.Material.Wood)
	for _, side in ipairs({ -1, 1 }) do
		box(parent, "BenchLeg", Vector3.new(0.3, 1.3, 1.8), cf * CFrame.new(side * 2.5, 0.65, 0), steel, Enum.Material.Metal)
	end
end

local function mannequin(parent, cf, color)
	local model = Instance.new("Model"); model.Name = "AtelierMannequin"; model.Parent = parent
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	box(model, "DisplayPlinth", Vector3.new(4, 0.5, 4), at(0, 0.25, 0), cream, Enum.Material.Marble)
	box(model, "Torso", Vector3.new(2, 2.4, 1), at(0, 4, 0), color)
	local head = box(model, "Head", Vector3.new(1.2, 1.2, 1.2), at(0, 5.8, 0), cream)
	head.Shape = Enum.PartType.Ball
	for _, side in ipairs({ -1, 1 }) do
		box(model, if side == -1 then "Left Leg" else "Right Leg", Vector3.new(0.7, 2.5, 0.8), at(side * 0.55, 1.8, 0), dark)
		box(model, if side == -1 then "Left Arm" else "Right Arm", Vector3.new(0.6, 2.3, 0.7), at(side * 1.4, 3.9, 0), color)
	end
	return model
end

-- Smooth collider along a slope, top face from `from` to `to`.
local function ramp(parent, name, from, to, width, color, material)
	local mid = (from + to) / 2
	local length = (to - from).Magnitude
	local frame = CFrame.lookAt(mid, to)
	local p = box(parent, name, Vector3.new(width, 1, length), frame * CFrame.new(0, -0.5, 0), color, material)
	return p, frame
end

local function escalator(parent, from, to, speed)
	local model = Instance.new("Model"); model.Name = "Escalator"; model.Parent = parent
	local belt, frame = ramp(model, "EscalatorBelt", from, to, 6, steel, Enum.Material.DiamondPlate)
	-- An anchored part with velocity carries characters like a moving step band.
	belt.AssemblyLinearVelocity = frame.LookVector * speed
	local length = (to - from).Magnitude
	for _, side in ipairs({ -1, 1 }) do
		pane(model, "EscalatorGlass", Vector3.new(0.3, 3, length), frame * CFrame.new(side * 3.2, 1.5, 0), 0.5)
		deco(box(model, "Handrail", Vector3.new(0.4, 0.3, length + 1), frame * CFrame.new(side * 3.2, 3.1, 0), Color3.fromRGB(25, 25, 30), Enum.Material.Rubber))
		deco(box(model, "EscalatorSkirt", Vector3.new(0.6, 2, length), frame * CFrame.new(side * 3.2, -1, 0), gold, Enum.Material.Metal))
	end
	deco(box(model, "EscalatorNeon", Vector3.new(0.2, 0.15, length), frame * CFrame.new(-2.9, 0.1, 0), pink, Enum.Material.Neon))
	deco(box(model, "EscalatorNeon", Vector3.new(0.2, 0.15, length), frame * CFrame.new(2.9, 0.1, 0), pink, Enum.Material.Neon))
	for _, point in ipairs({ from, to }) do
		deco(part(model, "LandingPlate", Vector3.new(6.4, 0.1, 3), point + Vector3.new(0, 0.05, 0), gold, Enum.Material.Metal))
	end
	return model
end

local function staircase(parent, from, to, width)
	local model = Instance.new("Model"); model.Name = "Staircase"; model.Parent = parent
	local collider, frame = ramp(model, "StairRamp", from, to, width, marble, Enum.Material.Marble)
	collider.Transparency = 1
	local run = to - from
	local steps = math.floor(run.Y)
	local horizontal = Vector3.new(run.X, 0, run.Z)
	local direction = horizontal.Unit
	local tread = horizontal.Magnitude / steps
	local facing = CFrame.lookAt(Vector3.zero, direction)
	for i = 1, steps do
		local centre = from + direction * (tread * (i - 0.5)) + Vector3.new(0, i - 0.5, 0)
		deco(box(model, "StairStep", Vector3.new(width, 1, tread + 0.05), CFrame.new(centre - Vector3.new(0, 0.5, 0)) * facing, if i % 2 == 0 then marble else marbleDark, Enum.Material.Marble))
	end
	local length = run.Magnitude
	for _, side in ipairs({ -1, 1 }) do
		pane(model, "StairGlass", Vector3.new(0.3, 3.2, length), frame * CFrame.new(side * (width / 2 + 0.2), 1.6, 0), 0.55)
		deco(box(model, "StairRail", Vector3.new(0.3, 0.3, length), frame * CFrame.new(side * (width / 2 + 0.2), 3.3, 0), gold, Enum.Material.Metal))
	end
	return model
end

-- Glass balustrade between two floor points at the same level.
local function rail(parent, a, b)
	local length = (b - a).Magnitude
	if length < 0.5 then return end
	local frame = CFrame.lookAt((a + b) / 2, b)
	pane(parent, "Balustrade", Vector3.new(0.3, 3.4, length), frame * CFrame.new(0, 1.7, 0), 0.55)
	deco(box(parent, "Handrail", Vector3.new(0.45, 0.3, length + 0.3), frame * CFrame.new(0, 3.5, 0), gold, Enum.Material.Metal))
end

local function railZ(parent, y, x1, x2, z) rail(parent, Vector3.new(x1, y, z), Vector3.new(x2, y, z)) end
local function railX(parent, y, z1, z2, x) rail(parent, Vector3.new(x, y, z1), Vector3.new(x, y, z2)) end

-- Rectangle frame [outer] minus [inner], as four slabs.
local function ring(parent, name, y, thickness, outer, inner, color, material)
	local ox, oz, ix, iz = outer, outer, inner, inner
	part(parent, name, Vector3.new(ox * 2, thickness, oz - iz), Vector3.new(0, y, -(oz + iz) / 2), color, material)
	part(parent, name, Vector3.new(ox * 2, thickness, oz - iz), Vector3.new(0, y, (oz + iz) / 2), color, material)
	part(parent, name, Vector3.new(ox - ix, thickness, iz * 2), Vector3.new(-(ox + ix) / 2, y, 0), color, material)
	part(parent, name, Vector3.new(ox - ix, thickness, iz * 2), Vector3.new((ox + ix) / 2, y, 0), color, material)
end

local function wall(parent, name, x1, z1, x2, z2, y1, y2, color, material)
	local sx, sz = math.max(math.abs(x2 - x1), 1), math.max(math.abs(z2 - z1), 1)
	return part(parent, name, Vector3.new(sx, y2 - y1, sz), Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2), color or cream, material)
end

local function buildUnit(parent, info, onStore, trading)
	local model = Instance.new("Model"); model.Name = (if trading then "Shop_" else "Unit_") .. info.id; model.Parent = parent
	local cf = info.cf
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	local color = info.color
	local h = STOREY - 1
	local front = -SHOP_D / 2
	box(model, "ShopFloor", Vector3.new(SHOP_W, 1, SHOP_D), at(0, -0.25, 0), if trading and (info.category == "top" or info.category == "bottom") then wood else marble, if trading and (info.category == "top" or info.category == "bottom") then Enum.Material.WoodPlanks else Enum.Material.Marble)
	box(model, "BackWall", Vector3.new(SHOP_W, h, 0.6), at(0, h / 2, SHOP_D / 2 - 0.3), cream)
	box(model, "FeatureWall", Vector3.new(SHOP_W - 3, 11, 0.2), at(0, 7, SHOP_D / 2 - 0.7), color:Lerp(cream, 0.35), Enum.Material.Fabric)
	for _, side in ipairs({ -1, 1 }) do
		box(model, "SideWall", Vector3.new(0.6, h, SHOP_D), at(side * (SHOP_W / 2 - 0.5), h / 2, 0), cream)
		-- Floor-to-ceiling display windows either side of a ten-stud doorway.
		pane(model, "ShopWindow", Vector3.new(SHOP_W / 2 - 5, 12, 0.3), at(side * (5 + (SHOP_W / 2 - 5) / 2), 6, front + 0.4), 0.72)
		box(model, "WindowFrame", Vector3.new(0.5, 12, 0.5), at(side * 5, 6, front + 0.4), gold, Enum.Material.Metal)
		box(model, "WindowFrame", Vector3.new(0.5, 12, 0.5), at(side * (SHOP_W / 2 - 0.3), 6, front + 0.4), gold, Enum.Material.Metal)
	end
	box(model, "Fascia", Vector3.new(SHOP_W, h - 12, 0.8), at(0, 12 + (h - 12) / 2, front + 0.4), dark)
	sign(model, "StoreSign", if trading then string.format("%02d  %s", info.number, info.name) else info.name, Vector3.new(SHOP_W - 6, 3.2, 0.3), at(0, 15.6, front - 0.05), color, cream, nil, Enum.Font.Bodoni)
	sign(model, "StoreSubtitle", string.upper(info.subtitle or info.specialty), Vector3.new(14, 1.2, 0.2), at(0, 13.1, front - 0.05), dark, gold)
	deco(box(model, "FasciaNeon", Vector3.new(SHOP_W - 1, 0.15, 0.2), at(0, 12.1, front - 0.1), color, Enum.Material.Neon))
	box(model, "Ceiling", Vector3.new(SHOP_W, 0.4, SHOP_D), at(0, h - 0.2, 0), cream)
	lamp(deco(box(model, "CeilingLight", Vector3.new(14, 0.2, 2.5), at(0, h - 0.5, 1), cream, Enum.Material.Neon)), 30, 0.9)
	for _, side in ipairs({ -1, 1 }) do
		mannequin(model, at(side * 9.5, 0.25, front + 3), color)
	end
	if not trading then
		-- Closed-for-the-game units still look stocked.
		for _, side in ipairs({ -1, 1 }) do
			for row = 1, 3 do
				box(model, "Shelf", Vector3.new(1.4, 0.3, 18), at(side * 12.4, row * 3, 2), wood, Enum.Material.Wood)
				for k = -1, 1 do
					box(model, "Goods", Vector3.new(0.9, 1.2, 1.6), at(side * 12.4, row * 3 + 0.75, 2 + k * 5), color:Lerp(Color3.new(1, 1, 1), 0.2 * (k + 1)))
				end
			end
		end
		box(model, "Counter", Vector3.new(6, 3, 3), at(0, 1.5, 9), color)
		box(model, "CounterTop", Vector3.new(6.3, 0.25, 3.3), at(0, 3.1, 9), cream, Enum.Material.Marble)
		storeModels[info.id] = model
		return model
	end
	displays[info.id] = { at(-8, 0.25, -5), at(8, 0.25, -5), at(0, 0.25, 2) }
	local counter = box(model, "Checkout", Vector3.new(6, 3, 3), at(0, 1.5, 10), color)
	box(model, "CounterTop", Vector3.new(6.3, 0.25, 3.3), at(0, 3.1, 10), cream, Enum.Material.Marble)
	local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Przymierz i kup"; prompt.ObjectText = info.name
	prompt.MaxActivationDistance = 12; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0; prompt.Parent = counter
	prompt.Triggered:Connect(function(player) onStore(player, info.id) end)
	if info.category == "top" or info.category == "bottom" then
		-- Rails of hanging garments on the side walls and a fitting room.
		for _, side in ipairs({ -1, 1 }) do
			local railX = side * 11.8
			deco(box(model, "RackRail", Vector3.new(0.2, 0.2, 14), at(railX, 6.5, -4), gold, Enum.Material.Metal))
			for k = -3, 3 do
				deco(box(model, "HangingGarment", Vector3.new(0.4, 2.6, 1.6), at(railX, 5, -4 + k * 2), if k % 2 == 0 then color else color:Lerp(cream, 0.5), Enum.Material.Fabric))
			end
		end
		box(model, "FittingWall", Vector3.new(0.3, 9, 7), at(-6.8, 4.5, 11), cream)
		box(model, "VelvetCurtain", Vector3.new(6.2, 9, 0.25), at(-10, 4.5, 7.6), color:Lerp(dark, 0.3), Enum.Material.Fabric)
		box(model, "MirrorFrame", Vector3.new(0.3, 9, 5), at(13.3, 5, 9), gold, Enum.Material.Metal)
		local mirror = box(model, "DecorativeMirror", Vector3.new(0.15, 8.4, 4.4), at(13.1, 5, 9), glass, Enum.Material.Glass)
		mirror.Reflectance = 0.35
	else
		for _, side in ipairs({ -1, 1 }) do
			for row = 1, 3 do
				box(model, "DisplayShelf", Vector3.new(1.4, 0.3, 16), at(side * 12.4, 2 + row * 2.6, -2), gold, Enum.Material.Metal)
				for k = -1, 1 do
					local goods = box(model, "ShelfItem", Vector3.new(0.8, 0.8, 1.2), at(side * 12.4, 2.6 + row * 2.6, -2 + k * 5), if (row + k) % 2 == 0 then color else cream)
					goods.Shape = if info.category == "jewelry" or info.category == "glasses" then Enum.PartType.Ball else Enum.PartType.Block
				end
			end
		end
		pane(model, "GlassCase", Vector3.new(6, 2.5, 3), at(0, 4.6, 6.5), 0.55)
		box(model, "CaseBase", Vector3.new(6.2, 3.4, 3.2), at(0, 1.7, 6.5), dark)
	end
	storeModels[info.id] = model
	return model
end

function World.refreshStock(catalog, garments, onStore)
	for _, shop in ipairs(shops) do
		local model = storeModels[shop.id]
		local old = model:FindFirstChild("Stock"); if old then old:Destroy() end
		local stock = Instance.new("Folder"); stock.Name = "Stock"; stock.Parent = model
		local index = 0
		for _, item in ipairs(catalog) do
			if item.store ~= shop.id then continue end
			index += 1
			local display = mannequin(stock, displays[shop.id][index], cream)
			local outfit = Instance.new("Folder"); outfit.Name = "SQOutfit"; outfit.Parent = display
			garments.build(display, item, Color3.fromRGB(table.unpack(item.color)), outfit)
			local torso = display:FindFirstChild("Torso")
			local prompt = Instance.new("ProximityPrompt"); prompt.ObjectText = item.name .. " • " .. item.price .. " zł"
			prompt.ActionText = "Zobacz i przymierz"; prompt.MaxActivationDistance = 9; prompt.RequiresLineOfSight = false; prompt.Parent = torso
			prompt.Triggered:Connect(function(player) onStore(player, shop.id, item.id) end)
			-- Swap in a mannequin wearing the real catalog item once it has loaded;
			-- the part figure stays (invisible) as the prompt anchor and fallback.
			if World.CatalogMannequin and item.assets then
				local cf = displays[shop.id][index]
				task.spawn(function()
					local real = World.CatalogMannequin(item, cf, display)
					if not real or stock.Parent == nil then return end
					for _, object in ipairs(display:GetDescendants()) do
						if object:IsA("BasePart") and object.Name ~= "DisplayPlinth" and not object:IsDescendantOf(real) then object.Transparency = 1 end
					end
				end)
			end
		end
	end
end

local function slidingDoor(parent, centre, width, height)
	local panels = {}
	for _, side in ipairs({ -1, 1 }) do
		local closed = CFrame.new(centre + Vector3.new(side * width / 4, height / 2, -0.6))
		local p = pane(parent, "AutoDoor", Vector3.new(width / 2, height, 0.4), closed, 0.55)
		local handle = deco(box(parent, "DoorEdge", Vector3.new(0.3, height, 0.5), closed * CFrame.new(-side * (width / 4 - 0.15), 0, 0), gold, Enum.Material.Metal))
		table.insert(panels, { part = p, edge = handle, closed = closed, open = closed * CFrame.new(side * (width / 2 - 0.5), 0, 0), side = side })
	end
	local door = { panels = panels, centre = centre, range = 13, open = false }
	table.insert(World.Doors, door)
	return door
end

local tween
pcall(function()
	local TweenService = game:GetService("TweenService")
	tween = function(object, goal) TweenService:Create(object, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play() end
end)

-- Called by the server with live character positions. Doors open on approach.
function World.updateDoors(positions)
	for _, door in ipairs(World.Doors) do
		local near = false
		for _, position in ipairs(positions) do
			local offset = position - door.centre
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= door.range and math.abs(offset.Y) < 10 then near = true; break end
		end
		if near == door.open then continue end
		door.open = near
		for _, panel in ipairs(door.panels) do
			local goal = if near then panel.open else panel.closed
			local edgeGoal = goal * CFrame.new(-panel.side * (panel.part.Size.X / 2 - 0.15), 0, 0)
			if tween then
				tween(panel.part, { CFrame = goal }); tween(panel.edge, { CFrame = edgeGoal })
			else
				panel.part.CFrame = goal; panel.edge.CFrame = edgeGoal
			end
		end
	end
end

local function buildLounge(parent, onJoin)
	local room = Instance.new("Model"); room.Name = "WaitingLounge"; room.Parent = parent
	local function z(value) return LZ + value end
	part(room, "LoungeFloor", Vector3.new(34, 0.18, 24), Vector3.new(0, FLOOR + 0.31, z(0)), cream, Enum.Material.Marble)
	part(room, "LoungeRug", Vector3.new(21, 0.08, 16), Vector3.new(0, FLOOR + 0.45, z(0)), Color3.fromRGB(218, 166, 182), Enum.Material.Fabric)
	part(room, "LoungeBackWall", Vector3.new(34, 16, 0.5), Vector3.new(0, FLOOR + 8, z(12)), cream)
	local roof = part(room, "LoungeCeiling", Vector3.new(34.5, 0.5, 24.5), Vector3.new(0, FLOOR + 16.1, z(0)), cream)
	roof.CastShadow = false
	part(room, "LoungeRoofTrim", Vector3.new(36, 1, 26), Vector3.new(0, FLOOR + 16.85, z(0)), plum)
	for _, side in ipairs({ -1, 1 }) do
		local sideGlass = pane(room, "LoungeSideGlass", Vector3.new(0.5, 16, 24), CFrame.new(side * 17, FLOOR + 8, z(0)), 0.75)
		sideGlass.CastShadow = false
		pane(room, "LoungeFrontGlass", Vector3.new(13, 16, 0.5), CFrame.new(side * 10.5, FLOOR + 8, z(-12)), 0.8)
		for _, offset in ipairs({ -12, 0, 12 }) do
			part(room, "LoungeWindowMullion", Vector3.new(0.6, 16, 0.6), Vector3.new(side * 17, FLOOR + 8, z(offset)), gold, Enum.Material.Metal)
		end
		part(room, "DoorFrame", Vector3.new(0.35, 16, 0.7), Vector3.new(side * 4, FLOOR + 8, z(-12)), gold, Enum.Material.Metal)
		part(room, "SofaBase", Vector3.new(4.5, 1, 11), Vector3.new(side * 12.5, FLOOR + 1.1, z(-1)), pink, Enum.Material.Fabric)
		part(room, "SofaBack", Vector3.new(0.8, 3.5, 11), Vector3.new(side * 14.5, FLOOR + 2.8, z(-1)), pink, Enum.Material.Fabric)
		for _, offset in ipairs({ -6.5, 4.5 }) do
			part(room, "SofaArm", Vector3.new(4.5, 1.3, 0.8), Vector3.new(side * 12.5, FLOOR + 2.3, z(offset)), pink, Enum.Material.Fabric)
		end
		for offset = -4.5, 2.5, 3.5 do
			local seat = part(room, "LoungeSeat", Vector3.new(3, 0.5, 3), Vector3.new(side * 12, FLOOR + 1.9, z(offset)), Color3.fromRGB(226, 161, 183), Enum.Material.Fabric, "Seat")
			seat.CFrame *= CFrame.Angles(0, side * math.pi / 2, 0)
		end
		plant(room, side * 13.5, FLOOR, z(8.5))
		deco(part(room, "LoungeCeilingStrip", Vector3.new(0.2, 0.15, 22), Vector3.new(side * 15.5, FLOOR + 15.8, z(0)), gold, Enum.Material.Neon))
	end
	-- The glass door stays shut: joining is a server decision, and opening it
	-- would let spectators leave the lounge.
	local door = pane(room, "LockedLobbyDoor", Vector3.new(8, 16, 0.5), CFrame.new(0, FLOOR + 8, z(-12)), 0.65)
	for _, side in ipairs({ -1, 1 }) do
		part(room, "DoorHandle", Vector3.new(0.18, 2, 0.2), Vector3.new(side * 0.65, FLOOR + 4.5, z(-11.6)), gold, Enum.Material.Metal)
	end
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "JoinRound"; prompt.ActionText = "Wejdź do gry"
	prompt.ObjectText = "Runda: 1500 zł • 8 minut"; prompt.MaxActivationDistance = 10; prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0; prompt.Parent = door
	prompt.Triggered:Connect(function(player) onJoin(player) end)
	deco(part(room, "JoinMat", Vector3.new(8, 0.06, 4), Vector3.new(0, FLOOR + 0.44, z(-9.5)), gold, Enum.Material.Neon))
	sign(room, "DoorNotice", "WEJŚCIE DO GRY\nPodejdź do drzwi i naciśnij E", Vector3.new(15, 2.5, 0.2), CFrame.new(0, FLOOR + 12.5, z(-11.4)), dark, gold, Enum.NormalId.Back)
	sign(room, "DoorNoticeOutside", "STYLE LOUNGE", Vector3.new(15, 2.5, 0.2), CFrame.new(0, FLOOR + 12.5, z(-12.4)), dark, gold, nil, Enum.Font.Bodoni)
	sign(room, "LoungeTitle", "STYLE LOUNGE\nPOCZEKALNIA KRÓLOWEJ STYLU", Vector3.new(23, 4.5, 0.3), CFrame.new(0, FLOOR + 11, z(11.6)), dark, gold)
	sign(room, "RoundInstructions", "2 TEMATY • 1500 ZŁ • 8 MINUT\nWejdź sama — resztę miejsc zajmą boty", Vector3.new(18, 2.5, 0.25), CFrame.new(0, FLOOR + 6.7, z(11.5)), cream, dark)
	part(room, "CoffeeTable", Vector3.new(7, 0.35, 4), Vector3.new(0, FLOOR + 2.3, z(-3)), cream, Enum.Material.Marble)
	for _, side in ipairs({ -1, 1 }) do
		part(room, "TableLeg", Vector3.new(0.4, 1.8, 3), Vector3.new(side * 2.7, FLOOR + 1.3, z(-3)), gold, Enum.Material.Metal)
	end
	for i = 1, 3 do
		part(room, "FashionMagazine", Vector3.new(1.1, 0.08, 1.5), Vector3.new(-2 + i, FLOOR + 2.55 + i * 0.08, z(-3)), if i == 2 then pink else gold)
	end
	lamp(part(room, "LoungeChandelier", Vector3.new(6, 0.35, 3), Vector3.new(0, FLOOR + 14, z(0)), cream, Enum.Material.Neon), 23, 1)
	part(room, "ChandelierStem", Vector3.new(0.25, 2, 0.25), Vector3.new(0, FLOOR + 15, z(0)), gold, Enum.Material.Metal)
end

local function buildPlaza(mall)
	local plaza = Instance.new("Model"); plaza.Name = "Plaza"; plaza.Parent = mall
	part(plaza, "PlazaPaving", Vector3.new(140, 0.2, 84), Vector3.new(0, FLOOR + 0.1, 108), paving, Enum.Material.Pavement)
	for _, side in ipairs({ -1, 1 }) do
		part(plaza, "PlazaPaving", Vector3.new(46, 0.2, 24), Vector3.new(side * 47, FLOOR + 0.1, 54), paving, Enum.Material.Pavement)
	end
	for x = -60, 60, 20 do
		deco(part(plaza, "PavingStripe", Vector3.new(1.2, 0.05, 84), Vector3.new(x, FLOOR + 0.225, 108), marbleDark, Enum.Material.Pavement))
	end
	part(plaza, "EntranceCarpet", Vector3.new(12, 0.06, 26), Vector3.new(0, FLOOR + 0.23, 79), pink, Enum.Material.Fabric)
	-- Hedges are visual; invisible walls keep everyone on the plaza.
	for _, side in ipairs({ -1, 1 }) do
		part(plaza, "Hedge", Vector3.new(3, 3.5, 106), Vector3.new(side * 68.5, FLOOR + 1.75, 97), green, Enum.Material.Grass)
		local barrier = part(plaza, "PlazaBoundary", Vector3.new(2, 40, 110), Vector3.new(side * 71, FLOOR + 20, 96), glass)
		barrier.Transparency = 1; barrier.CastShadow = false
		for _, zPos in ipairs({ 58, 84, 100, 146 }) do tree(plaza, side * 52, zPos) end
		for _, zPos in ipairs({ 76, 104, 132 }) do
			part(plaza, "LampPost", Vector3.new(0.6, 14, 0.6), Vector3.new(side * 30, FLOOR + 7, zPos), steel, Enum.Material.Metal)
			lamp(deco(part(plaza, "LampHead", Vector3.new(2.2, 0.6, 2.2), Vector3.new(side * 30, FLOOR + 14.2, zPos), cream, Enum.Material.Neon)), 26, 0.7)
			bench(plaza, CFrame.new(side * 36, FLOOR, zPos) * CFrame.Angles(0, math.pi / 2, 0))
		end
		plant(plaza, side * 12, FLOOR, 70, 1.3)
	end
	part(plaza, "Hedge", Vector3.new(140, 3.5, 3), Vector3.new(0, FLOOR + 1.75, 148.5), green, Enum.Material.Grass)
	local back = part(plaza, "PlazaBoundary", Vector3.new(144, 40, 2), Vector3.new(0, FLOOR + 20, 151), glass)
	back.Transparency = 1; back.CastShadow = false
	-- Totem sign beside the walkway.
	sign(plaza, "Totem", "KRÓLOWA\nSTYLU\n★\nGALERIA\nMODY", Vector3.new(4, 14, 1.2), CFrame.new(-20, FLOOR + 7, 96) * CFrame.Angles(0, math.pi, 0), plum, gold)
	-- Round fountain on the east side of the plaza.
	local basin = part(plaza, "FountainBasin", Vector3.new(2, 14, 14), Vector3.new(36, FLOOR + 1, 118), marble, Enum.Material.Marble)
	basin.CFrame *= CFrame.Angles(0, 0, math.pi / 2); basin.Shape = Enum.PartType.Cylinder
	local water = deco(part(plaza, "FountainWater", Vector3.new(0.4, 12.5, 12.5), Vector3.new(36, FLOOR + 1.9, 118), Color3.fromRGB(110, 175, 210), Enum.Material.Glass))
	water.CFrame *= CFrame.Angles(0, 0, math.pi / 2); water.Shape = Enum.PartType.Cylinder; water.Transparency = 0.3
	deco(part(plaza, "FountainJet", Vector3.new(0.8, 7, 0.8), Vector3.new(36, FLOOR + 4.5, 118), Color3.fromRGB(200, 235, 255), Enum.Material.Neon)).Transparency = 0.4
end

local function buildEntrance(mall)
	local hall = Instance.new("Model"); hall.Name = "EntranceHall"; hall.Parent = mall
	part(hall, "HallFloor", Vector3.new(48, 0.2, 24), Vector3.new(0, FLOOR + 0.1, 54), marble, Enum.Material.Marble)
	deco(part(hall, "HallInlay", Vector3.new(10, 0.05, 10), Vector3.new(0, FLOOR + 0.225, 54), gold, Enum.Material.Metal)).CFrame *= CFrame.Angles(0, math.pi / 4, 0)
	for _, side in ipairs({ -1, 1 }) do
		wall(hall, "HallSideWall", side * 24, 42, side * 24.8, 66, FLOOR, ROOF, cream)
		pane(hall, "FacadeGlass", Vector3.new(17, 12, 0.4), CFrame.new(side * 15.5, FLOOR + 6, 66), 0.6)
		pane(hall, "DoorPocketGlass", Vector3.new(7, 12, 0.3), CFrame.new(side * 10.5, FLOOR + 6, 64.8), 0.7)
		part(hall, "CanopyPost", Vector3.new(0.8, 14, 0.8), Vector3.new(side * 14, FLOOR + 7, 75), gold, Enum.Material.Metal)
		plant(hall, side * 20, FLOOR, 46)
	end
	for x = -24, 24, 8 do
		-- Mullions above the doorway only, so the opening stays clear.
		local bottom = if math.abs(x) < 8 then FLOOR + 13 else FLOOR
		part(hall, "FacadeMullion", Vector3.new(0.5, ROOF - bottom, 0.6), Vector3.new(x, (bottom + ROOF) / 2, 66), gold, Enum.Material.Metal)
	end
	part(hall, "DoorHeader", Vector3.new(48, 1, 0.8), Vector3.new(0, FLOOR + 12.5, 66), gold, Enum.Material.Metal)
	pane(hall, "FacadeUpperGlass", Vector3.new(48, ROOF - FLOOR - 13, 0.4), CFrame.new(0, (FLOOR + 13 + ROOF) / 2, 66), 0.6)
	part(hall, "Canopy", Vector3.new(32, 0.8, 12), Vector3.new(0, FLOOR + 14.4, 71), plum)
	deco(part(hall, "CanopyNeon", Vector3.new(32, 0.2, 0.2), Vector3.new(0, FLOOR + 14, 77), pink, Enum.Material.Neon))
	sign(hall, "MallName", "GALERIA  KRÓLOWA STYLU", Vector3.new(40, 5, 0.6), CFrame.new(0, FLOOR + 30, 66.8) * CFrame.Angles(0, math.pi, 0), plum, gold, nil, Enum.Font.Bodoni)
	pane(hall, "HallRoof", Vector3.new(48, 0.4, 24), CFrame.new(0, ROOF + 0.2, 54), 0.5)
	for x = -18, 18, 12 do
		deco(part(hall, "RoofBeam", Vector3.new(0.5, 0.6, 24), Vector3.new(x, ROOF, 54), gold, Enum.Material.Metal))
	end
	slidingDoor(hall, Vector3.new(0, FLOOR, 66), 14, 12)
	-- Info desk with the floor directory.
	part(hall, "InfoDesk", Vector3.new(8, 3, 3), Vector3.new(-12, FLOOR + 1.5, 50), plum)
	part(hall, "InfoDeskTop", Vector3.new(8.3, 0.25, 3.3), Vector3.new(-12, FLOOR + 3.1, 50), marble, Enum.Material.Marble)
	sign(hall, "InfoSign", "i  INFORMACJA", Vector3.new(7, 1.4, 0.3), CFrame.new(-12, FLOOR + 6, 51.5) * CFrame.Angles(0, math.pi, 0), dark, gold)
end

local function directoryText(level)
	local lines = { if level == 1 then "PARTER" else "PIĘTRO 1" }
	for _, shop in ipairs(shops) do
		if shop.level == level then table.insert(lines, string.format("%02d %s  (%s)", shop.number, shop.name, if shop.wing == "east" then "wsch." else "zach.")) end
	end
	if level == 2 then table.insert(lines, "FOOD COURT  (północ)") end
	return table.concat(lines, "\n")
end

local function buildAtrium(mall)
	local atrium = Instance.new("Model"); atrium.Name = "Atrium"; atrium.Parent = mall
	part(atrium, "AtriumFloor", Vector3.new(84, 0.2, 84), Vector3.new(0, FLOOR + 0.1, 0), marble, Enum.Material.Marble)
	for _, r in ipairs({ 26, 23 }) do
		for _, side in ipairs({ -1, 1 }) do
			deco(part(atrium, "FloorInlay", Vector3.new(r * 2, 0.05, 0.6), Vector3.new(0, FLOOR + 0.225, side * r), gold, Enum.Material.Metal))
			deco(part(atrium, "FloorInlay", Vector3.new(0.6, 0.05, r * 2), Vector3.new(side * r, FLOOR + 0.225, 0), gold, Enum.Material.Metal))
		end
	end
	-- First-floor gallery ring around the void, with glass balustrades.
	ring(atrium, "GalleryFloor", L2 - 0.5, 1, 42, 24, marble, Enum.Material.Marble)
	railZ(atrium, L2, -15, 15, -24)
	railZ(atrium, L2, -24, 24, 24)
	railX(atrium, L2, -24, 24, -24)
	railX(atrium, L2, -24, 24, 24)
	railZ(atrium, L2, -24, 24, 42)
	for _, x in ipairs({ -24, 24 }) do
		for _, zPos in ipairs({ -24, 24 }) do
			part(atrium, "AtriumColumn", Vector3.new(2.5, ROOF - FLOOR, 2.5), Vector3.new(x, (FLOOR + ROOF) / 2, zPos), cream, Enum.Material.Marble)
			deco(part(atrium, "ColumnRing", Vector3.new(3, 0.6, 3), Vector3.new(x, L2 + 4, zPos), gold, Enum.Material.Metal))
		end
	end
	deco(part(atrium, "GalleryEdgeNeon", Vector3.new(48, 0.2, 0.2), Vector3.new(0, L2 - 1.1, 24.2), pink, Enum.Material.Neon))
	deco(part(atrium, "GalleryEdgeNeon", Vector3.new(48, 0.2, 0.2), Vector3.new(0, L2 - 1.1, -24.2), pink, Enum.Material.Neon))
	escalator(atrium, Vector3.new(-19, FLOOR, 16), Vector3.new(-19, L2, -24), 5)
	escalator(atrium, Vector3.new(19, L2, -24), Vector3.new(19, FLOOR, 16), 5)
	sign(atrium, "EscalatorSign", "▲ PIĘTRO 1 • FOOD COURT", Vector3.new(8, 1.2, 0.2), CFrame.new(-19, FLOOR + 7, 18.5) * CFrame.Angles(0, math.pi, 0), dark, gold)
	sign(atrium, "EscalatorSign", "▼ PARTER", Vector3.new(6, 1.2, 0.2), CFrame.new(19, L2 + 7, -26.5), dark, gold)
	for _, offset in ipairs({ Vector3.new(33, 0, 0), Vector3.new(-33, 0, 0), Vector3.new(0, 0, 33), Vector3.new(0, 0, -33) }) do
		lamp(deco(part(atrium, "GalleryDownlight", Vector3.new(3, 0.2, 3), offset + Vector3.new(0, L2 - 1.1, 0), cream, Enum.Material.Neon)), 30, 0.8)
	end
	-- Glass lantern roof over the void, solid roof over the gallery ring.
	ring(atrium, "Roof", ROOF + 0.5, 1, 43.5, 24, cream)
	pane(atrium, "LanternGlass", Vector3.new(50, 0.4, 50), CFrame.new(0, ROOF + 8, 0), 0.55)
	for _, side in ipairs({ -1, 1 }) do
		pane(atrium, "LanternSide", Vector3.new(48, 8, 0.4), CFrame.new(0, ROOF + 4, side * 24), 0.6)
		pane(atrium, "LanternSide", Vector3.new(0.4, 8, 48), CFrame.new(side * 24, ROOF + 4, 0), 0.6)
	end
	for offset = -20, 20, 10 do
		deco(part(atrium, "LanternBeam", Vector3.new(0.5, 0.5, 50), Vector3.new(offset, ROOF + 7.8, 0), gold, Enum.Material.Metal))
		deco(part(atrium, "LanternBeam", Vector3.new(50, 0.5, 0.5), Vector3.new(0, ROOF + 7.8, offset), gold, Enum.Material.Metal))
	end
	-- Atrium walls with openings to the wings, food court and entrance hall.
	for _, side in ipairs({ -1, 1 }) do
		wall(atrium, "AtriumWall", side * 30, -42.5, side * 42, -43.5, FLOOR, ROOF)
		wall(atrium, "AtriumWall", side * 24, 42.5, side * 42, 43.5, FLOOR, ROOF)
		wall(atrium, "AtriumWall", side * 41.5, -42, side * 42.5, -12, FLOOR, ROOF)
		wall(atrium, "AtriumWall", side * 41.5, 12, side * 42.5, 42, FLOOR, ROOF)
		for _, zPos in ipairs({ -12, 12 }) do
			part(atrium, "WingArch", Vector3.new(1.5, ROOF - FLOOR, 1.5), Vector3.new(side * 42.5, (FLOOR + ROOF) / 2, zPos), gold, Enum.Material.Metal)
		end
		bench(atrium, CFrame.new(side * 33, FLOOR, 30))
		bench(atrium, CFrame.new(side * 33, L2, 33))
		plant(atrium, side * 36, FLOOR, -36)
		plant(atrium, side * 36, L2, -36)
		plant(atrium, side * 36, L2, 36)
	end
	-- Hanging banners in the void.
	for _, entry in ipairs({ { -12, "NOWA\nKOLEKCJA" }, { 12, "SEZON\nMODY" } }) do
		sign(atrium, "HangingBanner", entry[2], Vector3.new(6, 12, 0.3), CFrame.new(entry[1], L2 + 8, -22) * CFrame.Angles(0, math.pi, 0), pink, cream)
	end
	for _, side in ipairs({ -1, 1 }) do
		lamp(deco(part(atrium, "Chandelier", Vector3.new(6, 0.6, 6), Vector3.new(side * 12, ROOF - 3, side * 12), cream, Enum.Material.Neon)), 40, 1.2)
	end
	-- The runway sits in the void so both floors can watch the show.
	part(atrium, "Runway", Vector3.new(12, 2, 34), Vector3.new(0, FLOOR + 1, -2), dark, Enum.Material.Marble)
	part(atrium, "RunwayCarpet", Vector3.new(8, 0.12, 34), Vector3.new(0, FLOOR + 2.06, -2), pink, Enum.Material.Fabric)
	for i = 1, 4 do
		part(atrium, "StageStep", Vector3.new(12, i * 0.5, 1.5), Vector3.new(0, FLOOR + i * 0.25, 21.5 - i * 1.5), cream, Enum.Material.Marble)
	end
	for _, side in ipairs({ -1, 1 }) do
		deco(part(atrium, "StageTrim", Vector3.new(0.2, 0.15, 34), Vector3.new(side * 5.9, FLOOR + 2.1, -2), gold, Enum.Material.Neon))
		for zPos = -4, 12, 8 do
			bench(atrium, CFrame.new(side * 10.5, FLOOR, zPos) * CFrame.Angles(0, math.pi / 2, 0))
		end
		local spotAt = Vector3.new(side * 23, L2 + 6, 10)
		local spot = deco(part(atrium, "StageSpot", Vector3.new(1.5, 1.5, 1.5), spotAt, steel, Enum.Material.Metal))
		local light = Instance.new("SpotLight"); light.Face = Enum.NormalId.Front; light.Angle = 40; light.Range = 45; light.Brightness = 3
		light.Color = Color3.fromRGB(255, 220, 235); light.Parent = spot
		spot.CFrame = CFrame.lookAt(spotAt, Vector3.new(0, FLOOR + 3, 10))
	end
	sign(atrium, "ShowBackdrop", "KRÓLOWA STYLU\nTHE RUNWAY", Vector3.new(24, 12, 0.8), CFrame.new(0, FLOOR + 8, -20) * CFrame.Angles(0, math.pi, 0), plum, gold, nil, Enum.Font.Bodoni)
	-- Two-sided directory near the entrance.
	part(atrium, "DirectoryBase", Vector3.new(6, 1, 1.4), Vector3.new(0, FLOOR + 0.5, 36), dark)
	sign(atrium, "DirectoryBoard", directoryText(1), Vector3.new(6, 10, 0.6), CFrame.new(0, FLOOR + 6, 36) * CFrame.Angles(0, math.pi, 0), plum, cream)
	sign(atrium, "DirectoryBoardBack", directoryText(2), Vector3.new(6, 10, 0.2), CFrame.new(0, FLOOR + 6, 35.6), plum, cream)
end

local function buildWing(mall, sx)
	local wing = Instance.new("Model"); wing.Name = if sx > 0 then "EastWing" else "WestWing"; wing.Parent = mall
	local cx = sx * 84
	part(wing, "CorridorFloor", Vector3.new(84, 0.2, 24), Vector3.new(cx, FLOOR + 0.1, 0), marble, Enum.Material.Marble)
	for _, zPos in ipairs({ -9, 9 }) do
		deco(part(wing, "CorridorInlay", Vector3.new(82, 0.05, 0.5), Vector3.new(cx, FLOOR + 0.225, zPos), gold, Enum.Material.Metal))
	end
	-- First-floor walkways along both shop rows, a bridge at the stair top.
	for _, zPos in ipairs({ -8, 8 }) do
		part(wing, "WalkwayFloor", Vector3.new(84, 1, 8), Vector3.new(cx, L2 - 0.5, zPos), marble, Enum.Material.Marble)
		deco(part(wing, "WalkwayNeon", Vector3.new(80, 0.2, 0.3), Vector3.new(cx, L2 - 1.1, zPos / 2 + zPos / math.abs(zPos) * 0.2), pink, Enum.Material.Neon))
	end
	part(wing, "Bridge", Vector3.new(8, 1, 8), Vector3.new(sx * 68, L2 - 0.5, 0), marble, Enum.Material.Marble)
	part(wing, "WalkwayCap", Vector3.new(2, 1, 8), Vector3.new(sx * 43, L2 - 0.5, 0), marble, Enum.Material.Marble)
	part(wing, "WalkwayCap", Vector3.new(2, 1, 8), Vector3.new(sx * 125, L2 - 0.5, 0), marble, Enum.Material.Marble)
	for _, zPos in ipairs({ -4, 4 }) do
		railZ(wing, L2, sx * 44, sx * 64, zPos)
		railZ(wing, L2, sx * 72, sx * 124, zPos)
	end
	railX(wing, L2, -4, 4, sx * 44)
	railX(wing, L2, -4, 4, sx * 64)
	railX(wing, L2, -4, 4, sx * 124)
	staircase(wing, Vector3.new(sx * 112, FLOOR, 0), Vector3.new(sx * 72, L2, 0), 7)
	sign(wing, "StairSign", "▲ PIĘTRO 1", Vector3.new(6, 1.2, 0.2), CFrame.new(sx * 114, FLOOR + 5, 0) * CFrame.Angles(0, sx * math.pi / 2, 0), dark, gold)
	-- Facades and the glazed wing end.
	for _, side in ipairs({ -1, 1 }) do
		wall(wing, "Facade", sx * 42, side * 42.5, sx * 126, side * 43.5, FLOOR, ROOF)
		part(wing, "FacadeBand", Vector3.new(84, 1.2, 0.4), Vector3.new(cx, L2, side * 43.8), gold, Enum.Material.Metal)
		wall(wing, "WingEndWall", sx * 126, side * 12, sx * 127, side * 43.5, FLOOR, ROOF)
		part(wing, "RoofDeck", Vector3.new(83, 1, 31.5), Vector3.new(sx * 85, ROOF + 0.5, side * 27.75), cream)
	end
	pane(wing, "WingEndGlass", Vector3.new(0.4, ROOF - FLOOR, 24), CFrame.new(sx * 126.5, (FLOOR + ROOF) / 2, 0), 0.6)
	part(wing, "WingEndMullion", Vector3.new(0.6, ROOF - FLOOR, 0.6), Vector3.new(sx * 126.3, (FLOOR + ROOF) / 2, 0), gold, Enum.Material.Metal)
	part(wing, "WingEndTransom", Vector3.new(0.6, 0.6, 24), Vector3.new(sx * 126.3, L2, 0), gold, Enum.Material.Metal)
	pane(wing, "Skylight", Vector3.new(84, 0.4, 24), CFrame.new(cx, ROOF + 0.2, 0), 0.5)
	for x = 48, 120, 12 do
		deco(part(wing, "SkylightBeam", Vector3.new(0.5, 0.6, 24), Vector3.new(sx * x, ROOF, 0), gold, Enum.Material.Metal))
	end
	for _, x in ipairs({ 56, 84, 112 }) do
		lamp(deco(part(wing, "PendantLamp", Vector3.new(2, 1, 2), Vector3.new(sx * x, ROOF - 4, 8), cream, Enum.Material.Neon)), 34, 0.9)
		deco(part(wing, "PendantCord", Vector3.new(0.1, 3.5, 0.1), Vector3.new(sx * x, ROOF - 1.75, 8), steel))
	end
	plant(wing, sx * 52, FLOOR, 0)
	plant(wing, sx * 120, FLOOR, 0)
	bench(wing, CFrame.new(sx * 70, L2, -10.5))
	bench(wing, CFrame.new(sx * 98, L2, 10.5))
end

local stalls = {
	{ "Pizza Bella", "Pizza • makaron", { 196, 62, 52 }, "🍕" },
	{ "Sushi Zen", "Sushi • ramen", { 52, 66, 108 }, "🍣" },
	{ "Burger Lab", "Burgery • frytki", { 222, 128, 44 }, "🍔" },
	{ "Kebab Sultan", "Kebab • falafel", { 150, 92, 52 }, "🥙" },
	{ "Lody & Gofry", "Desery", { 228, 120, 168 }, "🍦" },
	{ "Kawa & Croissant", "Kawiarnia", { 112, 78, 60 }, "☕" },
}
World.FoodStalls = stalls

local function buildNorthWing(mall, onFood)
	local north = Instance.new("Model"); north.Name = "FoodCourt"; north.Parent = mall
	part(north, "NorthFloor", Vector3.new(60, 0.2, 60), Vector3.new(0, FLOOR + 0.1, -72), marble, Enum.Material.Marble)
	part(north, "FoodCourtFloor", Vector3.new(60, 1, 60), Vector3.new(0, L2 - 0.5, -72), Color3.fromRGB(222, 205, 186), Enum.Material.WoodPlanks)
	for _, side in ipairs({ -1, 1 }) do
		wall(north, "NorthWall", side * 30, -42, side * 31, -102, FLOOR, ROOF)
	end
	wall(north, "NorthBackWall", -31, -102, 31, -103, FLOOR, L2 + 3)
	pane(north, "PanoramaWindow", Vector3.new(62, 13, 0.4), CFrame.new(0, L2 + 9.5, -102.5), 0.55)
	wall(north, "NorthBackWall", -31, -102, 31, -103, L2 + 16, ROOF)
	part(north, "NorthRoof", Vector3.new(62, 1, 61), Vector3.new(0, ROOF + 0.5, -72.5), cream)
	-- Ground floor: fountain and café tables.
	local basin = part(north, "FountainBasin", Vector3.new(2, 16, 16), Vector3.new(0, FLOOR + 1, -72), marble, Enum.Material.Marble)
	basin.CFrame *= CFrame.Angles(0, 0, math.pi / 2); basin.Shape = Enum.PartType.Cylinder
	local water = deco(part(north, "FountainWater", Vector3.new(0.4, 14.5, 14.5), Vector3.new(0, FLOOR + 1.9, -72), Color3.fromRGB(110, 175, 210), Enum.Material.Glass))
	water.CFrame *= CFrame.Angles(0, 0, math.pi / 2); water.Shape = Enum.PartType.Cylinder; water.Transparency = 0.3
	part(north, "FountainSculpture", Vector3.new(1.5, 6, 1.5), Vector3.new(0, FLOOR + 3, -72), gold, Enum.Material.Metal)
	lamp(deco(part(north, "FountainGlow", Vector3.new(2.5, 2.5, 2.5), Vector3.new(0, FLOOR + 6.5, -72), Color3.fromRGB(200, 235, 255), Enum.Material.Neon)), 22, 1)
	part(north, "CafeCounter", Vector3.new(4, 3, 16), Vector3.new(-26, FLOOR + 1.5, -72), Color3.fromRGB(112, 78, 60), Enum.Material.Wood)
	sign(north, "CafeSign", "CAFÉ ROYALE", Vector3.new(14, 2.4, 0.4), CFrame.new(-29, FLOOR + 10, -72) * CFrame.Angles(0, -math.pi / 2, 0), plum, gold, nil, Enum.Font.Bodoni)
	for _, zPos in ipairs({ -54, -90 }) do
		for _, x in ipairs({ -14, 14 }) do bench(north, CFrame.new(x, FLOOR, zPos)) end
	end
	lamp(deco(part(north, "NorthLight", Vector3.new(20, 0.2, 2), Vector3.new(0, L2 - 1.2, -56), cream, Enum.Material.Neon)), 30, 0.9)
	-- First floor: food court with six stalls and shared seating.
	for index, stall in ipairs(stalls) do
		local side = if index <= 3 then -1 else 1
		local zPos = -54 - ((index - 1) % 3) * 18
		local color = Color3.fromRGB(table.unpack(stall[3]))
		local facing = CFrame.new(side * 26, L2, zPos) * CFrame.Angles(0, side * math.pi / 2, 0)
		local function at(x, y, z) return facing * CFrame.new(x, y, z) end
		box(north, "StallBack", Vector3.new(16, 12, 0.6), at(0, 6, 3.6), color:Lerp(cream, 0.2))
		local counter = box(north, "StallCounter", Vector3.new(14, 3.2, 2.5), at(0, 1.6, -1), color)
		box(north, "StallCounterTop", Vector3.new(14.4, 0.3, 2.9), at(0, 3.35, -1), marble, Enum.Material.Marble)
		sign(north, "StallSign", stall[4] .. "  " .. stall[1], Vector3.new(14, 2.6, 0.4), at(0, 12.5, 3), color, cream)
		sign(north, "StallMenu", string.upper(stall[2]), Vector3.new(10, 1.4, 0.2), at(0, 8, 3.2), dark, gold)
		deco(box(north, "StallNeon", Vector3.new(14, 0.2, 0.2), at(0, 11, 3.1), color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Neon))
		local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Zamów"; prompt.ObjectText = stall[1]
		prompt.MaxActivationDistance = 10; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0.3; prompt.Parent = counter
		prompt.Triggered:Connect(function(player) if onFood then onFood(player, index) end end)
	end
	for _, x in ipairs({ -10, 0, 10 }) do
		for _, zPos in ipairs({ -56, -72, -88 }) do
			local top = part(north, "TableTop", Vector3.new(0.3, 4.5, 4.5), Vector3.new(x, L2 + 3, zPos), cream, Enum.Material.Marble)
			top.CFrame *= CFrame.Angles(0, 0, math.pi / 2); top.Shape = Enum.PartType.Cylinder
			part(north, "TableLeg", Vector3.new(0.5, 3, 0.5), Vector3.new(x, L2 + 1.5, zPos), gold, Enum.Material.Metal)
			for _, dz in ipairs({ -3.2, 3.2 }) do
				local seat = part(north, "FoodSeat", Vector3.new(2.2, 0.5, 2.2), Vector3.new(x, L2 + 1.6, zPos + dz), pink, Enum.Material.Fabric, "Seat")
				seat.CFrame *= CFrame.Angles(0, if dz > 0 then 0 else math.pi, 0)
			end
		end
		lamp(deco(part(north, "PendantLamp", Vector3.new(2, 1, 2), Vector3.new(x, ROOF - 5, -72), Color3.fromRGB(255, 222, 180), Enum.Material.Neon)), 30, 0.8)
	end
	sign(north, "FoodCourtSign", "FOOD COURT", Vector3.new(24, 3, 0.4), CFrame.new(0, L2 + 15, -42.6) * CFrame.Angles(0, math.pi, 0), plum, gold, nil, Enum.Font.Bodoni)
end

function World.create(onStore, catalog, garments, onJoin, onFood)
	local old = workspace:FindFirstChild("ShoppingQueenPrototype")
	if old then old:Destroy() end
	storeModels, displays, World.Doors = {}, {}, {}
	local mall = Instance.new("Folder"); mall.Name = "ShoppingQueenPrototype"; mall.Parent = workspace
	part(mall, "Foundation", Vector3.new(262, 2, 260), Vector3.new(0, FLOOR - 1, 22), dark, Enum.Material.Concrete)
	buildPlaza(mall)
	buildEntrance(mall)
	buildAtrium(mall)
	buildWing(mall, 1)
	buildWing(mall, -1)
	buildNorthWing(mall, onFood)
	local units = Instance.new("Folder"); units.Name = "Shops"; units.Parent = mall
	for _, shop in ipairs(shops) do buildUnit(units, shop, onStore, true) end
	for _, unit in ipairs(World.DecorUnits or {}) do
		local info = table.clone(unit)
		info.color = Color3.fromRGB(table.unpack(unit.color)); info.subtitle = unit.specialty
		info.cf = unitFrame(unit.place, unit.place.level)
		buildUnit(units, info, onStore, false)
	end
	if catalog and garments then World.refreshStock(catalog, garments, onStore) end
	local spawn = Instance.new("SpawnLocation"); spawn.Name = "GallerySpawn"; spawn.Size = Vector3.new(8, 0.2, 8)
	spawn.Position = Vector3.new(0, FLOOR + 0.52, LZ + 4); spawn.Anchored = true; spawn.Neutral = true; spawn.Duration = 0
	spawn.Transparency = 1; spawn.CanCollide = false
	spawn.Material = Enum.Material.Marble; spawn.Color = pink; spawn.Parent = mall
	local decal = spawn:FindFirstChildOfClass("Decal"); if decal then decal:Destroy() end
	buildLounge(mall, onJoin or function() end)
	local bots = Instance.new("Folder"); bots.Name = "Bots"; bots.Parent = mall
	World.BotFolder = bots
	return mall
end
return World

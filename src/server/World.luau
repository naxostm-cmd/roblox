-- Self-contained low-poly shopping gallery. Never edits the user's existing map.
local World = {}
local FLOOR = 8 -- Above the original baseplate, avoiding coplanar floor flicker.
local cream = Color3.fromRGB(244, 235, 224)
local pink = Color3.fromRGB(194, 87, 131)
local dark = Color3.fromRGB(48, 43, 55)
local gold = Color3.fromRGB(207, 171, 105)
local glass = Color3.fromRGB(190, 220, 225)
local shops = {
 { category = "top", name = "ROSE ATELIER", subtitle = "GÓRA • TOPS & JACKETS", x = -42, z = 0, color = Color3.fromRGB(202, 114, 148) },
 { category = "bottom", name = "STUDIO DENIM", subtitle = "DÓŁ • TROUSERS & SKIRTS", x = 42, z = 0, color = Color3.fromRGB(96, 137, 167) },
 { category = "shoes", name = "SOLE SOCIETY", subtitle = "BUTY • SHOE BOUTIQUE", x = -42, z = 42, color = Color3.fromRGB(169, 123, 94) },
 { category = "accessory", name = "GOLDEN DETAILS", subtitle = "DODATKI • FINISH YOUR LOOK", x = 42, z = 42, color = gold },
}
World.StorePositions = {}
for _, shop in ipairs(shops) do
 World.StorePositions[shop.category] = Vector3.new(shop.x, FLOOR + 3, shop.z)
end
World.Stage = CFrame.new(0, FLOOR + 5, -48) * CFrame.Angles(0, math.pi, 0)
World.Lobby = CFrame.new(0, FLOOR + 4, 78)
World.ShoppingStart = CFrame.new(0, FLOOR + 4, 48)

function World.isInsideLobby(position)
 return math.abs(position.X) <= 16.5 and position.Z >= 62.5 and position.Z <= 85.5
  and position.Y >= FLOOR + 0.5 and position.Y <= FLOOR + 15.5
end

local function part(parent, name, size, position, color, material, className)
 local p = Instance.new(className or "Part")
 p.Name = name; p.Size = size; p.CFrame = CFrame.new(position); p.Color = color; p.Anchored = true
 p.Material = material or Enum.Material.SmoothPlastic
 p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
 p.Parent = parent
 return p
end

local function sign(parent, name, text, size, cf, color, textColor, face)
 local board = part(parent, name, size, cf.Position, color)
 board.CFrame = cf
 local gui = Instance.new("SurfaceGui"); gui.Face = face or Enum.NormalId.Front
 gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 35; gui.Parent = board
 local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(0.94, 0.86); label.Position = UDim2.fromScale(0.03, 0.07)
 label.BackgroundTransparency = 1; label.Text = text; label.Font = Enum.Font.GothamBold
 label.TextColor3 = textColor or cream; label.TextScaled = true; label.TextWrapped = true; label.Parent = gui
 return board
end

local function plant(parent, x, z)
 part(parent, "Planter", Vector3.new(3, 2, 3), Vector3.new(x, FLOOR + 1, z), cream, Enum.Material.Marble)
 part(parent, "Stem", Vector3.new(0.5, 3, 0.5), Vector3.new(x, FLOOR + 3, z), gold)
 local leaves = part(parent, "Leaves", Vector3.new(4, 4, 4), Vector3.new(x, FLOOR + 5, z), Color3.fromRGB(61, 110, 82), Enum.Material.Grass)
 leaves.Shape = Enum.PartType.Ball; leaves.CanCollide = false
end

local function mannequin(parent, x, z, color)
 part(parent, "DisplayPlinth", Vector3.new(4, 0.5, 4), Vector3.new(x, FLOOR + 0.25, z), cream, Enum.Material.Marble)
 part(parent, "DisplayTorso", Vector3.new(2, 2.4, 1), Vector3.new(x, FLOOR + 4, z), color)
 local head = part(parent, "DisplayHead", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, FLOOR + 5.8, z), cream)
 head.Shape = Enum.PartType.Ball
 for _, side in ipairs({ -1, 1 }) do
  part(parent, "DisplayLeg", Vector3.new(0.7, 2.5, 0.8), Vector3.new(x + side * 0.55, FLOOR + 1.8, z), dark)
  part(parent, "DisplayArm", Vector3.new(0.6, 2.3, 0.7), Vector3.new(x + side * 1.4, FLOOR + 3.9, z), color)
 end
end

local function buildShop(parent, shop, onStore)
 local model = Instance.new("Model"); model.Name = "Shop_" .. shop.category; model.Parent = parent
 local x, z = shop.x, shop.z
 local inward = if x < 0 then 1 else -1
 local frontX, backX = x + inward * 15, x - inward * 15
 part(model, "ShopFloor", Vector3.new(30, 0.12, 32), Vector3.new(x, FLOOR + 0.22, z), cream, Enum.Material.Marble)
 part(model, "BackWall", Vector3.new(0.6, 17, 32), Vector3.new(backX, FLOOR + 8.5, z), cream)
 for _, side in ipairs({ -1, 1 }) do
  part(model, "SideWall", Vector3.new(30, 17, 0.6), Vector3.new(x, FLOOR + 8.5, z + side * 16), cream)
  -- Leave a ten-stud doorway between the glass display windows.
  local window = part(model, "ShopWindow", Vector3.new(0.3, 11, 10), Vector3.new(frontX, FLOOR + 5.5, z + side * 10.5), glass, Enum.Material.Glass)
  window.Transparency = 0.65
  part(model, "WindowFrame", Vector3.new(0.5, 11, 0.35), Vector3.new(frontX, FLOOR + 5.5, z + side * 5.5), gold, Enum.Material.Metal)
  mannequin(model, frontX - inward * 4.5, z + side * 10.5, shop.color)
 end
 part(model, "Ceiling", Vector3.new(31, 0.5, 33), Vector3.new(x, FLOOR + 17, z), cream)
 local facing = CFrame.new(frontX + inward * 0.3, FLOOR + 13.5, z) * CFrame.Angles(0, if inward == 1 then -math.pi / 2 else math.pi / 2, 0)
 sign(model, "StoreSign", shop.name .. "\n" .. shop.subtitle, Vector3.new(30, 4.5, 0.5), facing, shop.color)
 part(model, "LightStrip", Vector3.new(0.4, 0.2, 31), Vector3.new(frontX + inward * 0.4, FLOOR + 16.3, z), cream, Enum.Material.Neon)
 local ceilingLight = part(model, "CeilingLight", Vector3.new(20, 0.15, 1), Vector3.new(x, FLOOR + 16.5, z), cream, Enum.Material.Neon)
 local light = Instance.new("PointLight"); light.Color = cream; light.Brightness = 0.7; light.Range = 27; light.Parent = ceilingLight
 -- A rack with small garment silhouettes along the back wall.
 for _, side in ipairs({ -1, 1 }) do
  part(model, "RackPost", Vector3.new(0.2, 6, 0.2), Vector3.new(backX + inward * 3, FLOOR + 3, z + side * 7), gold, Enum.Material.Metal)
 end
 part(model, "RackRail", Vector3.new(0.2, 0.2, 14), Vector3.new(backX + inward * 3, FLOOR + 6, z), gold, Enum.Material.Metal)
 for i = -2, 2 do
  local color = if i % 2 == 0 then shop.color else dark
  part(model, "HangingGarment", Vector3.new(1.7, 2.3, 0.35), Vector3.new(backX + inward * 3, FLOOR + 4.5, z + i * 2.5), color)
 end
 local counter = part(model, "Checkout", Vector3.new(5, 3, 5), Vector3.new(x, FLOOR + 1.5, z), shop.color)
 part(model, "CounterTop", Vector3.new(5.3, 0.25, 5.3), Vector3.new(x, FLOOR + 3.1, z), cream, Enum.Material.Marble)
 local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Przymierz i kup"; prompt.ObjectText = shop.name
 prompt.MaxActivationDistance = 12; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0; prompt.Parent = counter
 prompt.Triggered:Connect(function(player) onStore(player, shop.category) end)
end

local function buildLounge(parent)
 local room = Instance.new("Model"); room.Name = "WaitingLounge"; room.Parent = parent
 part(room, "LoungeFloor", Vector3.new(34, 0.18, 24), Vector3.new(0, FLOOR + 0.31, 74), cream, Enum.Material.Marble)
 part(room, "LoungeRug", Vector3.new(21, 0.08, 16), Vector3.new(0, FLOOR + 0.45, 74), Color3.fromRGB(218, 166, 182), Enum.Material.Fabric)
 part(room, "LoungeBackWall", Vector3.new(34, 16, 0.5), Vector3.new(0, FLOOR + 8, 86), cream)
 local roof = part(room, "LoungeCeiling", Vector3.new(34.5, 0.5, 24.5), Vector3.new(0, FLOOR + 16.1, 74), cream)
 roof.CastShadow = false
 for _, side in ipairs({ -1, 1 }) do
  local wall = part(room, "LoungeSideGlass", Vector3.new(0.5, 16, 24), Vector3.new(side * 17, FLOOR + 8, 74), glass, Enum.Material.Glass)
  wall.Transparency = 0.75; wall.CastShadow = false
  local front = part(room, "LoungeFrontGlass", Vector3.new(13, 16, 0.5), Vector3.new(side * 10.5, FLOOR + 8, 62), glass, Enum.Material.Glass)
  front.Transparency = 0.8; front.CastShadow = false
  for _, z in ipairs({ 62, 74, 86 }) do
   part(room, "LoungeWindowMullion", Vector3.new(0.6, 16, 0.6), Vector3.new(side * 17, FLOOR + 8, z), gold, Enum.Material.Metal)
  end
  part(room, "DoorFrame", Vector3.new(0.35, 16, 0.7), Vector3.new(side * 4, FLOOR + 8, 62), gold, Enum.Material.Metal)
  -- Two three-seat sofas, turned towards the coffee table.
  part(room, "SofaBase", Vector3.new(4.5, 1, 11), Vector3.new(side * 12.5, FLOOR + 1.1, 73), pink, Enum.Material.Fabric)
  part(room, "SofaBack", Vector3.new(0.8, 3.5, 11), Vector3.new(side * 14.5, FLOOR + 2.8, 73), pink, Enum.Material.Fabric)
  for _, z in ipairs({ 67.5, 78.5 }) do
   part(room, "SofaArm", Vector3.new(4.5, 1.3, 0.8), Vector3.new(side * 12.5, FLOOR + 2.3, z), pink, Enum.Material.Fabric)
  end
  for z = 69.5, 76.5, 3.5 do
   local seat = part(room, "LoungeSeat", Vector3.new(3, 0.5, 3), Vector3.new(side * 12, FLOOR + 1.9, z), Color3.fromRGB(226, 161, 183), Enum.Material.Fabric, "Seat")
   seat.CFrame *= CFrame.Angles(0, side * math.pi / 2, 0)
  end
  plant(room, side * 13.5, 82.5)
  part(room, "LoungeCeilingStrip", Vector3.new(0.2, 0.15, 22), Vector3.new(side * 15.5, FLOOR + 15.8, 74), gold, Enum.Material.Neon)
 end
 -- Permanently closed: participants are moved into the mall by the server.
 -- Opening a shared door would also let waiting spectators escape.
 local door = part(room, "LockedLobbyDoor", Vector3.new(8, 16, 0.5), Vector3.new(0, FLOOR + 8, 62), glass, Enum.Material.Glass)
 door.Transparency = 0.65; door.CastShadow = false
 for _, side in ipairs({ -1, 1 }) do
  part(room, "DoorHandle", Vector3.new(0.18, 2, 0.2), Vector3.new(side * 0.65, FLOOR + 4.5, 62.4), gold, Enum.Material.Metal)
 end
 sign(room, "DoorNotice", "WEJŚCIE DO GALERII\nPrzeniesiemy Cię po rozpoczęciu rundy", Vector3.new(15, 2.5, 0.2), CFrame.new(0, FLOOR + 12, 62.5) * CFrame.Angles(0, math.pi, 0), dark, gold)
 sign(room, "LoungeTitle", "STYLE LOUNGE\nPOCZEKALNIA KRÓLOWEJ STYLU", Vector3.new(23, 4.5, 0.3), CFrame.new(0, FLOOR + 11, 85.6), dark, gold)
 sign(room, "RoundInstructions", "2 TEMATY • 1500 ZŁ • 8 MINUT\nRozsiądź się i poczekaj na pozostałych!", Vector3.new(18, 2.5, 0.25), CFrame.new(0, FLOOR + 6.7, 85.5), cream, dark)
 part(room, "CoffeeTable", Vector3.new(7, 0.35, 4), Vector3.new(0, FLOOR + 2.3, 71), cream, Enum.Material.Marble)
 for _, side in ipairs({ -1, 1 }) do
  part(room, "TableLeg", Vector3.new(0.4, 1.8, 3), Vector3.new(side * 2.7, FLOOR + 1.3, 71), gold, Enum.Material.Metal)
 end
 for i = 1, 3 do
  part(room, "FashionMagazine", Vector3.new(1.1, 0.08, 1.5), Vector3.new(-2 + i, FLOOR + 2.55 + i * 0.08, 71), if i == 2 then pink else gold)
 end
 local lamp = part(room, "LoungeChandelier", Vector3.new(6, 0.35, 3), Vector3.new(0, FLOOR + 14, 74), cream, Enum.Material.Neon)
 local light = Instance.new("PointLight"); light.Color = cream; light.Range = 23; light.Brightness = 1; light.Parent = lamp
 part(room, "ChandelierStem", Vector3.new(0.25, 2, 0.25), Vector3.new(0, FLOOR + 15, 74), gold, Enum.Material.Metal)
end

function World.create(onStore)
 local old = workspace:FindFirstChild("ShoppingQueenPrototype")
 if old then old:Destroy() end
 local mall = Instance.new("Folder"); mall.Name = "ShoppingQueenPrototype"; mall.Parent = workspace
 part(mall, "Foundation", Vector3.new(126, 2, 160), Vector3.new(0, FLOOR - 1, 8), dark, Enum.Material.Concrete)
 -- Narrow grout channels are gaps between tiles, not overlapping surfaces.
 for x = -60, 60, 10 do
  for z = -67, 83, 10 do
   part(mall, "FloorTile", Vector3.new(9.96, 0.12, 9.96), Vector3.new(x, FLOOR + 0.08, z), if (x + z) % 20 == 3 then cream else Color3.fromRGB(231, 221, 213), Enum.Material.Marble)
  end
 end
 for _, side in ipairs({ -1, 1 }) do
  part(mall, "GalleryWall", Vector3.new(1, 25, 160), Vector3.new(side * 63, FLOOR + 12.5, 8), cream)
  for z = -68, 72, 20 do
   part(mall, "GalleryColumn", Vector3.new(2, 23, 2), Vector3.new(side * 23, FLOOR + 11.5, z), cream, Enum.Material.Marble)
  end
  part(mall, "GalleryBeam", Vector3.new(2.5, 1, 157), Vector3.new(side * 23, FLOOR + 23, 8), gold, Enum.Material.Metal)
  part(mall, "WalkwayLight", Vector3.new(0.2, 0.12, 112), Vector3.new(side * 20, FLOOR + 0.2, 6), gold, Enum.Material.Neon)
 end
 part(mall, "BackWall", Vector3.new(126, 25, 1), Vector3.new(0, FLOOR + 12.5, -72), cream)
 part(mall, "EntranceWall", Vector3.new(126, 25, 1), Vector3.new(0, FLOOR + 12.5, 88), cream)
 local roof = part(mall, "Skylight", Vector3.new(45, 0.25, 156), Vector3.new(0, FLOOR + 25, 8), glass, Enum.Material.Glass)
 roof.Transparency = 0.75; roof.CastShadow = false
 for z = -60, 80, 20 do
  part(mall, "RoofBeam", Vector3.new(48, 0.4, 0.4), Vector3.new(0, FLOOR + 25.2, z), gold, Enum.Material.Metal)
 end
 for _, shop in ipairs(shops) do buildShop(mall, shop, onStore) end
 -- Stage and steps, oriented towards the audience and entrance.
 part(mall, "Runway", Vector3.new(14, 2, 29), Vector3.new(0, FLOOR + 1, -40), dark, Enum.Material.Marble)
 part(mall, "RunwayCarpet", Vector3.new(10, 0.12, 29), Vector3.new(0, FLOOR + 2.08, -40), pink, Enum.Material.Fabric)
 for i = 1, 4 do
  part(mall, "StageStep", Vector3.new(14, i * 0.5, 1.5), Vector3.new(0, FLOOR + i * 0.25, -19.5 - i * 1.5), cream, Enum.Material.Marble)
 end
 sign(mall, "ShowBackdrop", "KRÓLOWA STYLU\nTHE RUNWAY", Vector3.new(32, 13, 0.8), CFrame.new(0, FLOOR + 8.5, -62) * CFrame.Angles(0, math.pi, 0), dark, gold)
 for _, side in ipairs({ -1, 1 }) do
  part(mall, "StageTrim", Vector3.new(0.2, 0.15, 29), Vector3.new(side * 6.8, FLOOR + 2.2, -40), gold, Enum.Material.Neon)
  for z = -16, -4, 6 do
   part(mall, "AudienceBench", Vector3.new(8, 1, 3), Vector3.new(side * 12, FLOOR + 1.5, z), pink, Enum.Material.Fabric)
   for _, leg in ipairs({ -1, 1 }) do part(mall, "BenchLeg", Vector3.new(0.3, 1, 2), Vector3.new(side * 12 + leg * 3, FLOOR + 0.5, z), gold, Enum.Material.Metal) end
  end
  for _, z in ipairs({ 20, 65, -57 }) do plant(mall, side * 19, z) end
 end
 -- The visible starting point belongs to this gallery, not the old baseplate.
 local spawn = Instance.new("SpawnLocation"); spawn.Name = "GallerySpawn"; spawn.Size = Vector3.new(8, 0.2, 8)
 spawn.Position = Vector3.new(0, FLOOR + 0.52, 78); spawn.Anchored = true; spawn.Neutral = true; spawn.Duration = 0
 spawn.Transparency = 1; spawn.CanCollide = false
 spawn.Material = Enum.Material.Marble; spawn.Color = pink; spawn.Parent = mall
 local decal = spawn:FindFirstChildOfClass("Decal"); if decal then decal:Destroy() end
 buildLounge(mall)
 -- Return constants too, so all clients use the same stage coordinates.
 return mall
end
return World

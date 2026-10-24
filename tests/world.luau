-- Geometry checks with a small engine stand-in, not a Roblox rendering test.
return function(source)
 local all = {}
 local vector = {}
 vector.__index = vector
 vector.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, vector) end
 local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, vector) end
 local cf = {}
 cf.__mul = function(a, b) return setmetatable({ Position = a.Position + b.Position }, cf) end
 local function frame(x, y, z)
  return setmetatable({ Position = if type(x) == "table" then x else vec(x, y, z) }, cf)
 end
 local methods = {}
 function methods:FindFirstChild(name)
  for _, child in ipairs(all) do if child.Parent == self and child.Name == name and not child.destroyed then return child end end
 end
 function methods:FindFirstChildOfClass(class)
  for _, child in ipairs(all) do if child.Parent == self and child.ClassName == class and not child.destroyed then return child end end
 end
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
  Vector3 = { new = vec }, Color3 = { fromRGB = vec },
  CFrame = { new = frame, Angles = function() return frame(0, 0, 0) end },
  UDim2 = { fromScale = function(...) return { ... } end },
 }, { __index = getfenv() })
 local loader = assert(loadstring(source))
 setfenv(loader, env)
 local World = loader()
 local opened = {}
 local mall = World.create(function(player, category) opened[category] = player end)
 local parts, prompts, shops = {}, {}, {}
 for _, obj in ipairs(all) do
  if obj.ClassName == "Part" or obj.ClassName == "SpawnLocation" or obj.ClassName == "Seat" then
   if obj ~= original then table.insert(parts, obj); assert(obj.Anchored, obj.Name .. " is not anchored") end
  elseif obj.ClassName == "ProximityPrompt" then table.insert(prompts, obj)
  elseif obj.ClassName == "Model" then shops[obj.Name] = obj end
 end
 assert(#prompts == 4 and #parts > 350, "full gallery and four interactive stores required")
 for _, prompt in ipairs(prompts) do
  assert(prompt.callback and prompt.MaxActivationDistance >= 10)
  prompt.callback("test-player")
 end
 for _, category in ipairs({ "top", "bottom", "shoes", "accessory" }) do
  assert(opened[category] == "test-player", "missing shop callback: " .. category)
  assert(shops["Shop_" .. category], "missing shop building")
  local target = World.StorePositions[category]
  -- Check a player-sized corridor from the central passage through each entrance,
  -- stopping before the checkout. Walls and columns must not block this route.
  local side = if target.X < 0 then -1 else 1
  for distance = 0, 36, 2 do
   local x, z = distance * side, target.Z
   for _, p in ipairs(parts) do
    if p.CanCollide == false then continue end
    local pos = if p.CFrame then p.CFrame.Position else p.Position
    local size = p.Size
    if pos.Y + size.Y / 2 <= 8.4 or pos.Y - size.Y / 2 >= 14 then continue end
    assert(not (math.abs(x - pos.X) < size.X / 2 + 0.8 and math.abs(z - pos.Z) < size.Z / 2 + 0.8), "blocked entrance: " .. category .. " at " .. distance .. " by " .. p.Name)
   end
  end
 end
 local tiles, shopFloors = {}, {}
 for _, p in ipairs(parts) do
  if p.Name == "FloorTile" then table.insert(tiles, p) end
  if p.Name == "ShopFloor" then table.insert(shopFloors, p) end
 end
 for _, floor in ipairs(shopFloors) do
  for _, tile in ipairs(tiles) do
   assert(floor.CFrame.Position.Y - floor.Size.Y / 2 > tile.CFrame.Position.Y + tile.Size.Y / 2, "overlapping floor surfaces")
  end
 end
 assert(World.Lobby.Position.Y > 8 and World.Stage.Position.Y > 10, "spawn and stage above floor")
 assert(World.isInsideLobby(World.Lobby.Position), "spawn inside lounge")
 assert(not World.isInsideLobby(World.ShoppingStart.Position), "shopping destination outside lounge")
 for _, position in ipairs({ vec(0, 12, 61), vec(0, 12, 87), vec(18, 12, 74), vec(-18, 12, 74), vec(0, 30, 74), vec(0, 0, 74) }) do
  assert(not World.isInsideLobby(position), "escape or fall detected")
 end
 local function blocked(x, y, z)
  for _, p in ipairs(parts) do
   if not p.CanCollide then continue end
   local pos = if p.CFrame then p.CFrame.Position else p.Position
   if math.abs(x-pos.X) <= p.Size.X/2 and math.abs(y-pos.Y) <= p.Size.Y/2 and math.abs(z-pos.Z) <= p.Size.Z/2 then return true end
  end
  return false
 end
 for _, y in ipairs({ 10, 18, 23 }) do
  for x = -16, 16, 2 do
   assert(blocked(x,y,62), "front window or closed door has gap")
   assert(blocked(x,y,86), "back wall has gap")
  end
  for z = 63, 85, 2 do
   assert(blocked(-17,y,z) and blocked(17,y,z), "side wall has gap")
  end
 end
 for x = -16, 16, 4 do
  for z = 63, 85, 4 do assert(blocked(x,24.1,z), "ceiling must prevent climbing out") end
 end
 local seats, transparentWalls = 0, 0
 for _, p in ipairs(parts) do
  if p.ClassName == "Seat" then seats += 1 end
  if p.Name == "LoungeSideGlass" or p.Name == "LoungeFrontGlass" or p.Name == "LockedLobbyDoor" then
   assert(p.CanCollide and p.Transparency >= 0.6, "lounge windows must be see-through and solid")
   transparentWalls += 1
  end
 end
 assert(seats == 6 and transparentWalls == 5, "furnished lounge with clear view of mall")
 local spawn = World.Lobby.Position
 for _, x in ipairs({ -1, 0, 1 }) do
  for _, y in ipairs({ -2, 0, 2 }) do
   for _, z in ipairs({ -1, 0, 1 }) do assert(not blocked(spawn.X+x,spawn.Y+y,spawn.Z+z), "spawn overlaps furniture") end
  end
 end
 World.create(function() end)
 assert(mall.destroyed and not original.destroyed, "rebuild must replace only generated gallery")
 print("PASS: gallery entrances/floors, enclosed glass lounge, six seats, safe spawn, destinations and rebuild (" .. #parts .. " parts)")
end

-- Runs the real server script on a stand-in engine with a virtual clock and plays
-- one full episode: join -> intro -> shopping (bots) -> runway show -> results.
-- Catches logic errors in the round flow; it does not emulate Roblox physics.
return function(sources)
	local clock = 0
	local queue = {}
	local function schedule(at, co, ...) table.insert(queue, { at = at, co = co, args = table.pack(...) }) end
	local function resume(co, ...)
		local ok, err = coroutine.resume(co, ...)
		if not ok then error(debug.traceback(co, tostring(err)), 0) end
	end
	local task = {
		wait = function(t) schedule(clock + math.max(t or 0.03, 0.03), coroutine.running()); coroutine.yield(); return t end,
		spawn = function(fn, ...) local co = coroutine.create(fn); resume(co, ...); return co end,
		defer = function(fn, ...) schedule(clock, coroutine.create(fn), ...) end,
		delay = function(t, fn, ...) schedule(clock + (t or 0), coroutine.create(fn), ...) end,
	}

	-- Geometry stand-ins (same maths as tests/world.luau, trimmed).
	local V = {}
	V.__index = function(self, key)
		if key == "Magnitude" then return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z) end
		if key == "Unit" then local m = math.max(1e-9, math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)); return setmetatable({ X = self.X / m, Y = self.Y / m, Z = self.Z / m }, V) end
		if key == "R" then return self.X / 255 elseif key == "G" then return self.Y / 255 elseif key == "B" then return self.Z / 255 end
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
	V.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
	function V.Lerp(a, b, t) return a + (b - a) * t end
	function V.Cross(a, b) return vec(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
	function V.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	local C = {}
	local function cframe(p, r) return setmetatable({ p = p, r = r or { vec(1, 0, 0), vec(0, 1, 0), vec(0, 0, 1) } }, C) end
	local function rotate(r, v) return r[1] * v.X + r[2] * v.Y + r[3] * v.Z end
	C.__index = function(self, key)
		if key == "Position" then return self.p end
		if key == "LookVector" then return -self.r[3] end
		if key == "UpVector" then return self.r[2] end
		return C[key]
	end
	C.__mul = function(a, b)
		if getmetatable(b) == V then return a.p + rotate(a.r, b) end
		return cframe(a.p + rotate(a.r, b.p), { rotate(a.r, b.r[1]), rotate(a.r, b.r[2]), rotate(a.r, b.r[3]) })
	end
	C.__add = function(a, b) return cframe(a.p + b, a.r) end
	function C.PointToObjectSpace(self, v) local d = v - self.p; return vec(d:Dot(self.r[1]), d:Dot(self.r[2]), d:Dot(self.r[3])) end
	function C.Lerp(a) return a end
	local function axis(angle, which)
		local c, s = math.cos(angle), math.sin(angle)
		if which == "x" then return { vec(1, 0, 0), vec(0, c, s), vec(0, -s, c) } end
		if which == "y" then return { vec(c, 0, -s), vec(0, 1, 0), vec(s, 0, c) } end
		return { vec(c, s, 0), vec(-s, c, 0), vec(0, 0, 1) }
	end
	local CFrameLib = {
		new = function(x, y, z) if x == nil then return cframe(vec()) end; if type(x) == "table" then return cframe(x) end; return cframe(vec(x, y, z)) end,
		Angles = function(rx, ry, rz) return cframe(vec(), axis(rx, "x")) * cframe(vec(), axis(ry, "y")) * cframe(vec(), axis(rz, "z")) end,
		lookAt = function(at, target)
			local forward = (target - at).Unit
			local right = forward:Cross(vec(0, 1, 0))
			right = if right.Magnitude < 1e-6 then vec(1, 0, 0) else right.Unit
			return cframe(at, { right, right:Cross(forward), -forward })
		end,
	}

	-- Interned enum items, so equality and .Value behave like Roblox enums.
	local enumItems = {}
	local enum = setmetatable({}, { __index = function(_, key)
		enumItems[key] = enumItems[key] or {}
		return setmetatable({ GetEnumItems = function() return {} end }, { __index = function(_, value)
			enumItems[key][value] = enumItems[key][value] or setmetatable({ Name = value, Value = 1000, EnumType = key }, { __tostring = function() return "Enum." .. key .. "." .. value end })
			return enumItems[key][value]
		end })
	end })
	-- Instances: any property, children by name, lazily created events.
	local all = {}
	local events = { Triggered = true, Running = true, Seated = true, Ended = true, OnServerEvent = true, PlayerAdded = true,
		PlayerRemoving = true, CharacterAdded = true, CharacterAppearanceLoaded = true, MoveToFinished = true, OnClientEvent = true,
		MouseEnter = true, MouseLeave = true, MouseButton1Down = true, MouseButton1Up = true, Activated = true, InputBegan = true, RenderStepped = true }
	local function event()
		local e = { handlers = {} }
		function e:Connect(fn) table.insert(self.handlers, fn); return { Disconnect = function() end } end
		function e:Fire(...) for _, fn in ipairs(self.handlers) do task.spawn(fn, ...) end end
		return e
	end
	local methods = {}
	local Instance
	local meta = {}
	local internal = { destroyed = true, Parent = true, Name = true }
	meta.__index = function(self, key)
		if methods[key] then return methods[key] end
		if internal[key] then return nil end
		if events[key] then local e = event(); rawset(self, key, e); return e end
		if key == "Position" then local cf = rawget(self, "CFrame"); return cf and cf.Position end
		for _, child in ipairs(all) do
			if rawget(child, "Parent") == self and rawget(child, "Name") == key and not rawget(child, "destroyed") then return child end
		end
		return nil
	end
	function methods:FindFirstChild(name) for _, c in ipairs(all) do if c.Parent == self and c.Name == name and not c.destroyed then return c end end end
	methods.WaitForChild = methods.FindFirstChild
	function methods:FindFirstChildOfClass(class) for _, c in ipairs(all) do if c.Parent == self and c.ClassName == class and not c.destroyed then return c end end end
	function methods:GetChildren() local r = {}; for _, c in ipairs(all) do if c.Parent == self and not c.destroyed then table.insert(r, c) end end; return r end
	function methods:GetDescendants()
		local r = {}
		for _, c in ipairs(all) do
			local a = c.Parent
			while a do if a == self and not c.destroyed then table.insert(r, c); break end; a = a.Parent end
		end
		return r
	end
	function methods:IsDescendantOf(other) local a = self.Parent; while a do if a == other then return true end; a = a.Parent end; return false end
	function methods:FindFirstAncestorOfClass(class) local a = self.Parent; while a do if a.ClassName == class then return a end; a = a.Parent end end
	local baseParts = { Part = true, Seat = true, SpawnLocation = true }
	function methods:IsA(class) return self.ClassName == class or (class == "BasePart" and baseParts[self.ClassName] == true) end
	function methods:Destroy() self.destroyed = true; self.Parent = nil; for _, c in ipairs(all) do if c.Parent == self then c:Destroy() end end end
	function methods:SetAttribute(k, v) rawset(self, "attr_" .. k, v) end
	function methods:GetAttribute(k) return rawget(self, "attr_" .. k) end
	function methods:PivotTo(cf) local root = self:FindFirstChild("HumanoidRootPart"); if root then root.CFrame = cf else self.CFrame = cf end end
	function methods:MoveTo(target) self.moveTarget = target end
	function methods:Sit(humanoid) humanoid.SeatPart = self; humanoid.Sit = true end
	function methods:LoadAnimation() return { Play = function() end, Stop = function() end, IsPlaying = false } end
	function methods:SetNetworkOwner() end
	function methods:ApplyDescription(d) self.applied = d end
	function methods:GetAppliedDescription() return Instance.new("HumanoidDescription") end
	function methods:Clone() local c = Instance.new(self.ClassName); for k, v in pairs(self) do if type(k) == "string" and k ~= "Parent" then rawset(c, k, v) end end; return c end
	function methods:GetAccessories() return {} end
	function methods:SetAccessories(list) self.accessories = list end
	-- Roblox rejects tables that mix array and dictionary keys, or use non-string keys.
	local function serializable(value, path)
		if type(value) ~= "table" or getmetatable(value) ~= nil then return end
		local n, count, strings, numbers = #value, 0, 0, 0
		for k, v in pairs(value) do
			count += 1
			if type(k) == "string" then strings += 1 elseif type(k) == "number" then numbers += 1 else error("bad key type at " .. path) end
			serializable(v, path .. "." .. tostring(k))
		end
		assert(strings == 0 or numbers == 0, "mixed table keys at " .. path)
		assert(numbers == 0 or numbers == n, "sparse or non-sequential array at " .. path)
	end
	local function copy(value)
		if type(value) ~= "table" or getmetatable(value) ~= nil then return value end
		local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
	end
	function methods:FireClient(player, packet)
		serializable(packet, "packet")
		player.lastPacket = packet; player.packets = (player.packets or 0) + 1
		if self.OnClientEvent and #self.OnClientEvent.handlers > 0 then
			local delivered = copy(packet)
			task.defer(function() for _, fn in ipairs(self.OnClientEvent.handlers) do fn(delivered) end end)
		end
	end
	function methods:FireServer(action, payload)
		for _, fn in ipairs(self.OnServerEvent.handlers) do task.defer(fn, rawget(self, "fromPlayer"), action, payload) end
	end
	function methods:GetPropertyChangedSignal() return event() end
	function methods:Play() end
	function methods:Stop() end
	function methods:HasAppearanceLoaded() return true end
	function methods:GetServerTimeNow() return clock end
	Instance = { new = function(class, parent)
		local obj = setmetatable({ ClassName = class, Name = class, CanCollide = true, Size = vec(2, 2, 1), CFrame = cframe(vec()) }, meta)
		if class == "Humanoid" then obj.HipHeight = 2; obj.RigType = enum.HumanoidRigType.R15; obj.WalkSpeed = 16 end
		table.insert(all, obj)
		if parent then obj.Parent = parent end
		return obj
	end }

	local workspace = Instance.new("Workspace")
	local function rig(name)
		local model = Instance.new("Model"); model.Name = name
		for _, part in ipairs({ "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }) do
			local p = Instance.new("Part"); p.Name = part; p.Parent = model
		end
		local humanoid = Instance.new("Humanoid"); humanoid.Parent = model
		local animator = Instance.new("Animator"); animator.Parent = humanoid
		return model
	end
	local Players = Instance.new("Players")
	local playerList = {}
	function Players:GetPlayers() local r = {}; for _, p in ipairs(playerList) do if p.Parent == Players then table.insert(r, p) end end; return r end
	function Players:CreateHumanoidModelFromDescription() return rig("NPC") end
	function Players:GetHumanoidDescriptionFromUserId() return Instance.new("HumanoidDescription") end
	function Players:GetPlayerFromCharacter(char) for _, p in ipairs(playerList) do if p.Character == char then return p end end end
	function Players:GetPlayerByUserId(id) for _, p in ipairs(playerList) do if p.UserId == id then return p end end end
	function Players:GetNameFromUserIdAsync(id) return "user" .. id end
	local memory, ordered = {}, {}
	local frozen, warnings, frozeDuringShow = nil, {}, false
	local DataStoreService = { GetDataStore = function() return {
		GetAsync = function(_, k) return memory[k] end, SetAsync = function(_, k, v) memory[k] = v end } end,
		GetOrderedDataStore = function() return {
			SetAsync = function(_, k, v) ordered[k] = v end,
			GetSortedAsync = function() return { GetCurrentPage = function()
				local rows = {}; for k, v in pairs(ordered) do table.insert(rows, { key = k, value = v }) end
				table.sort(rows, function(a, b) return a.value > b.value end); return rows end } end } end }
	local services = {
		Players = Players, DataStoreService = DataStoreService,
		ReplicatedStorage = Instance.new("ReplicatedStorage"),
		MarketplaceService = { GetProductInfo = function(_, id) return { AssetId = id, Name = "Item" } end },
		PathfindingService = { CreatePath = function() local target; return {
			ComputeAsync = function(_, _, t) target = t end, Status = enum.PathStatus.Success,
			GetWaypoints = function() return { { Position = target, Action = enum.PathWaypointAction.Walk } } end } end },
		Lighting = { Ambient = vec(0, 0, 0) },
		TweenService = { Create = function() return { Play = function() end } end },
		ContextActionService = { BindActionAtPriority = function(_, name) frozen = name end, UnbindAction = function() frozen = nil end },
		RunService = Instance.new("RunService"), UserInputService = Instance.new("UserInputService"), SoundService = Instance.new("SoundService"),
	}
	local game = { GetService = function(_, name) return services[name] end, BindToClose = function() end }
	local shared = Instance.new("Folder"); shared.Name = "Shared"; shared.Parent = services.ReplicatedStorage
	local serverScript = Instance.new("Script"); serverScript.Name = "Server"
	for name in pairs(sources.shared) do local m = Instance.new("ModuleScript"); m.Name = name; m.Parent = shared; m.module = { "shared", name } end
	for name in pairs(sources.server) do local m = Instance.new("ModuleScript"); m.Name = name; m.Parent = serverScript; m.module = { "server", name } end
	local loaded = {}
	local random = { new = function(seed)
		local s = seed or 12345
		local function step() s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 end
		return { NextInteger = function(_, a, b) return a + math.floor(step() * (b - a + 1)) end, NextNumber = function(_, a, b) return (a or 0) + step() * ((b or 1) - (a or 0)) end }
	end }
	local env
	local function load(source, scriptObject)
		local fn = assert(loadstring(source))
		setfenv(fn, setmetatable({ script = scriptObject }, { __index = env }))
		return fn
	end
	local function require(module)
		if type(module) == "string" then error("unexpected path require " .. module) end
		local key = module.module[1] .. "/" .. module.module[2]
		if loaded[key] == nil then loaded[key] = load(sources[module.module[1]][module.module[2]], serverScript)() end
		return loaded[key]
	end
	local packed = function(...) return { ... } end
	local function ud(xs, xo, ys, yo) return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } } end
	local udim2 = { new = ud, fromScale = function(x, y) return ud(x, 0, y, 0) end, fromOffset = function(x, y) return ud(0, x, 0, y) end }
	env = setmetatable({
		game = game, workspace = workspace, task = task, Instance = Instance, Enum = enum, require = require, Random = random,
		Vector3 = { new = vec, zero = vec() }, Color3 = { fromRGB = vec, new = vec }, CFrame = CFrameLib,
		UDim2 = { fromScale = packed, fromOffset = packed, new = packed }, UDim = { new = packed }, Vector2 = { new = packed },
		NumberRange = { new = packed }, NumberSequence = { new = packed }, NumberSequenceKeypoint = { new = packed },
		ColorSequence = { new = packed }, ColorSequenceKeypoint = { new = packed }, warn = function(message) table.insert(warnings, tostring(message)) end,
		os = setmetatable({ clock = function() return clock end }, { __index = os }),
	}, { __index = getfenv() })

	-- Client: the real GUI script, fed with the packets the server sends.
	local function startClient(localPlayer, remotes)
		local clientScript = Instance.new("LocalScript"); clientScript.Name = "Client"
		for name in pairs(sources.client) do local m = Instance.new("ModuleScript"); m.Name = name; m.Parent = clientScript; m.module = { "client", name } end
		local playerGui = Instance.new("PlayerGui"); playerGui.Name = "PlayerGui"; playerGui.Parent = localPlayer
		local scripts = Instance.new("PlayerScripts"); scripts.Name = "PlayerScripts"; scripts.Parent = localPlayer
		workspace.CurrentCamera = Instance.new("Camera")
		local clientPlayers = setmetatable({ LocalPlayer = localPlayer }, { __index = Players })
		local clientServices = setmetatable({ Players = clientPlayers }, { __index = services })
		local clientGame = { GetService = function(_, name) return clientServices[name] end }
		local clientEnv = setmetatable({ game = clientGame, Font = { new = function() return {} end, fromEnum = function() return {} end },
			TweenInfo = { new = packed }, UDim2 = udim2, Vector2 = { new = packed, zero = {} }, math = setmetatable({ random = function(a, b) return a or 0 end }, { __index = math }) }, { __index = env })
		-- Every GUI object reports a laptop-sized area.
		local oldNew = Instance.new
		Instance.new = function(class, parent)
			local obj = oldNew(class, parent)
			obj.AbsoluteSize = vec(1280, 720); obj.CanvasPosition = vec()
			return obj
		end
		local fn = assert(loadstring(sources.client.init))
		setfenv(fn, setmetatable({ script = clientScript }, { __index = clientEnv }))
		local oldLoad = load
		load = function(source, scriptObject)
			local f = assert(loadstring(source)); setfenv(f, setmetatable({ script = scriptObject }, { __index = clientEnv })); return f
		end
		task.spawn(fn)
		load = oldLoad
		task.spawn(function()
			while true do services.RunService.RenderStepped:Fire(1 / 30); task.wait(0.5) end
		end)
		return clientScript
	end

	-- One real player who joins from the lounge.
	local player = Instance.new("Player"); player.UserId = 101; player.DisplayName = "Mati"; player.Name = "Mati"; player.Parent = Players
	table.insert(playerList, player)
	player.Character = rig("Mati"); player.Character.Parent = workspace
	local main = coroutine.create(load(sources.main, serverScript))
	resume(main)
	Players.PlayerAdded:Fire(player)
	local remoteFolder = services.ReplicatedStorage:FindFirstChild("ShoppingQueen")
	remoteFolder.Request.fromPlayer = player
	startClient(player, remoteFolder)
	local remote = services.ReplicatedStorage:FindFirstChild("ShoppingQueen"):FindFirstChild("Request")
	local function act(action, payload) for _, fn in ipairs(remote.OnServerEvent.handlers) do fn(player, action, payload) end end
	local seen, votedShows, bought = {}, {}, false
	local lastShow, resultsPacket, lobbyAt = 0, nil, nil
	while #queue > 0 and clock < 1500 do
		table.sort(queue, function(a, b) return a.at < b.at end)
		local job = table.remove(queue, 1)
		clock = math.max(clock, job.at)
		if coroutine.status(job.co) == "suspended" then resume(job.co, table.unpack(job.args, 1, job.args.n)) end
		local packet = player.lastPacket
		if packet then
			seen[packet.phase] = true
			if clock > 2 and packet.phase == "Lobby" and not packet.queued and not packet.participating and not seen.Results then act("Join") end
			if packet.phase == "Shopping" and not bought then
				bought = true
				-- Shop like a player: walk into a top and a bottom store, buy, equip, save both looks.
				local wanted = { top = true, bottom = true }
				for _, item in ipairs(packet.catalog) do
					if wanted[item.category] then
						wanted[item.category] = nil
						for _, store in ipairs(loaded["shared/Mall"].Stores) do
							if store.id == item.store then player.Character.HumanoidRootPart.CFrame = CFrameLib.new(loaded["server/World"].StoreTargets[store.id]) end
						end
						clock += 1; act("Buy", { slot = 1, id = item.id })
						clock += 1; act("Equip", { slot = 1, id = item.id })
						clock += 1; act("Equip", { slot = 2, id = item.id })
					end
				end
				clock += 1; act("Save", { slot = 1 }); clock += 1; act("Save", { slot = 2 })
			end
			if packet.phase == "Showcase" and packet.step == "vote" and packet.presenter ~= player.UserId and not votedShows[packet.showId] then
				votedShows[packet.showId] = true; clock += 0.2; act("Vote", { score = 4, showId = packet.showId })
			end
			if packet.phase == "Showcase" then lastShow = math.max(lastShow, packet.showId); if frozen then frozeDuringShow = true end end
			if packet.phase == "Results" and #packet.results > 0 then resultsPacket = packet end
			if seen.Results and packet.phase == "Lobby" then
				lobbyAt = lobbyAt or clock
				if clock > lobbyAt + 2 then break end
			end
		end
	end
	local packet = player.lastPacket
	-- The GUI must have processed packets: the HUD shows the current phase.
	local hudTexts = {}
	for _, obj in ipairs(all) do if obj.ClassName == "TextLabel" and not obj.destroyed and type(rawget(obj, "Text")) == "string" then hudTexts[obj.Text] = true end end
	for _, message in ipairs(warnings) do assert(not string.find(message, "Królowa Stylu", 1, true), message) end
	assert(frozeDuringShow, "movement is locked during the runway show")
	assert(frozen == nil, "movement unlocked after the episode")
	assert(not hudTexts["Łączymy z galerią…"], "client never rendered a server packet")
	assert(hudTexts["Poczekalnia"] or hudTexts["Podliczenie gwiazdek"] or hudTexts["Za chwilę start"], "HUD shows the phase")
	assert(remoteFolder.Update.OnClientEvent and #remoteFolder.Update.OnClientEvent.handlers == 1, "client listens for updates")
	assert(seen.Intermission and seen.Intro and seen.Shopping and seen.Showcase and seen.Results, "episode must pass every phase")
	assert(lastShow >= 8, "4 contestants x 2 looks presented, got " .. lastShow)
	local profile = packet.profile
	local mine
	assert(resultsPacket, "results were broadcast")
	for _, entry in ipairs(resultsPacket.results) do if entry.userId == player.UserId then mine = entry end end
	assert(mine and mine.score >= 2.5, "saved looks are scored by the jury, got " .. tostring(mine and mine.score))
	assert(#resultsPacket.results == 4, "player plus three bots ranked")
	for _, entry in ipairs(resultsPacket.results) do assert(entry.score >= 1 and entry.score <= 5 and entry.reward, "valid result row") end
	assert(profile and profile.rounds == 1 and profile.coins > 0 and profile.stars > 0, "rewards stored in the profile")
	assert(memory["u101"] and memory["u101"].coins == profile.coins, "profile saved to the data store")
	assert(#packet.leaderboard >= 0)
	-- Spend coins in the boutique and toggle the cosmetic.
	local coins = profile.coins
	act("BuyCosmetic", { id = "vip_style" })
	local after = player.lastPacket.profile
	if coins >= 300 then assert(after.owned.vip_style and after.coins == coins - 300, "cosmetic bought") else assert(not after.owned.vip_style, "cannot buy without coins") end
	print(string.format("PASS: full episode simulated in %.0f virtual seconds (%d shows, +%d★, +%d coins, rank %s)", clock, lastShow, profile.stars, profile.coins, profile.title))
end

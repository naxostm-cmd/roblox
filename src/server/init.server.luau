local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)
local Access = require(ReplicatedStorage.Shared.Access)
local BotLogic = require(ReplicatedStorage.Shared.BotLogic)
local World = require(script.World)
local Mall = require(ReplicatedStorage.Shared.Mall)
local Garments = require(ReplicatedStorage.Shared.Garments)
World.configure(Mall.Stores, Mall.Decor)
local Appearance = require(script.Appearance)
local BotActors = require(script.BotActors)
-- Store mannequins and avatars wear real catalog items (see Mall pools).
World.CatalogMannequin = Appearance.mannequin
task.spawn(Appearance.validate, Mall.Pools)

local remotes = Instance.new("Folder"); remotes.Name = "ShoppingQueen"; remotes.Parent = ReplicatedStorage
local request = Instance.new("RemoteEvent"); request.Name = "Request"; request.Parent = remotes
local update = Instance.new("RemoteEvent"); update.Name = "Update"; update.Parent = remotes
local state = { phase = "Lobby", endsAt = 0, themes = {}, round = 0, presenter = 0, slot = 0, showId = 0, results = {} }
-- Entrants are real players or bots; bots use negative ids in data/votes.
local entrants, data, votes, lastRequest = {}, {}, {}, {}
local queue = {}
local rng = Random.new()
local activeCatalog = Mall.generate(rng, nil, Config.Palette)

local function present(entrant)
	return entrant.bot or (entrant.player and entrant.player.Parent == Players)
end

local function eligible()
	local ids = {}
	for _, entrant in ipairs(entrants) do
		if present(entrant) then ids[entrant.id] = true end
	end
	return ids
end

local function humansPresent()
	for _, entrant in ipairs(entrants) do
		if not entrant.bot and present(entrant) then return true end
	end
	return false
end

local function entrantOf(player)
	for _, entrant in ipairs(entrants) do if entrant.player == player then return entrant end end
	return nil
end

local function characterOf(entrant)
	return if entrant.bot then entrant.model else entrant.player.Character
end

local function queued(player)
	return table.find(queue, player) ~= nil
end

local function pruneQueue()
	for i = #queue, 1, -1 do
		if queue[i].Parent ~= Players then table.remove(queue, i) end
	end
end

local function send(player, message, store, fittingItem)
	local own = data[player.UserId]
	local roster = {}
	for _, entrant in ipairs(entrants) do
		if present(entrant) then table.insert(roster, { userId = entrant.id, name = entrant.name, bot = entrant.bot == true }) end
	end
	local waiting = {}
	for _, waitingPlayer in ipairs(queue) do table.insert(waiting, waitingPlayer.DisplayName) end
	update:FireClient(player, {
		catalog = activeCatalog, fittingItem = fittingItem, playerCount = #Players:GetPlayers(), stagePosition = World.Stage.Position,
		phase = state.phase, endsAt = state.endsAt, round = state.round, themes = state.themes,
		presenter = state.presenter, slot = state.slot, showId = state.showId, results = state.results,
		roster = roster, queue = waiting, queued = queued(player), roundSize = Config.RoundSize,
		participating = own ~= nil, budget = if own then own.budget else 0,
		owned = if own then own.owned else {}, looks = if own then own.looks else { {}, {} },
		saved = if own then own.saved else { false, false },
		voted = votes[player.UserId] ~= nil, message = message, store = store,
	})
end

local function broadcast()
	for _, player in ipairs(Players:GetPlayers()) do send(player) end
end

local function moveCharacter(char, cf, anchored)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local seat = humanoid.SeatPart
		humanoid.Sit = false
		local weld = seat and seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end
	end
	root.Anchored = false; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(cf); root.Anchored = anchored == true
end

local function move(player, cf, anchored) moveCharacter(player.Character, cf, anchored) end

-- Bots wait beside the runway while others present.
local function backstage(index)
	local side = if index % 2 == 0 then 1 else -1
	return CFrame.lookAt(Vector3.new(side * 14, World.FLOOR + 3, -12 + math.floor((index - 1) / 2) * 6), Vector3.new(0, World.FLOOR + 3, -2))
end

local function spawnPoint(player)
	return if Access.canBrowse(state.phase, data[player.UserId] ~= nil) then World.ShoppingStart else World.Lobby
end

local function displayEntrant(entrant)
	local own = data[entrant.id]
	local char = characterOf(entrant)
	if state.phase == "Showcase" and state.presenter == entrant.id and own then
		Appearance.apply(char, if own.saved[state.slot] then own.looks[state.slot] else {}, activeCatalog)
		moveCharacter(char, World.Stage, true)
	elseif state.phase == "Shopping" and own then
		Appearance.apply(char, own.looks[own.activeSlot], activeCatalog)
	else
		Appearance.apply(char, nil, activeCatalog)
	end
end

local function displayFor(player)
	local entrant = entrantOf(player)
	if entrant then displayEntrant(entrant) else Appearance.apply(player.Character, nil, activeCatalog) end
end

local function setupPlayer(player)
	player.CharacterAppearanceLoaded:Connect(function() displayFor(player) end)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and player.Parent then
			move(player, spawnPoint(player), false)
			-- AppearanceLoaded will reapply after Roblox finishes loading the avatar.
			if player:HasAppearanceLoaded() then displayFor(player) end
		end
	end)
	if player.Character then move(player, spawnPoint(player), false) end
	task.defer(broadcast)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	local index = table.find(queue, player); if index then table.remove(queue, index) end
	-- Keep the snapshot until round cleanup; departed players cannot buy/vote or win.
	task.defer(broadcast)
end)

local function join(player)
	if data[player.UserId] then send(player, "Już bierzesz udział w tej rundzie."); return end
	if queued(player) then send(player, "Jesteś już zapisana/y — zaraz start!"); return end
	pruneQueue()
	if #queue >= Config.MaxPlayers then send(player, "Komplet zapisów. Spróbuj w następnej rundzie."); return end
	table.insert(queue, player)
	local waiting = state.phase == "Lobby" or state.phase == "Intermission"
	send(player, if waiting then "Zapisano! Za chwilę przeniesiemy Cię do galerii." else "Zapisano na następną rundę — poczekaj w salonie.")
	broadcast()
end

local function openStore(player, category, fittingItem)
	if Access.canBrowse(state.phase, data[player.UserId] ~= nil) then send(player, nil, category, fittingItem)
	else send(player, "Poczekaj w salonie — wejdziesz do sklepów jako uczestnik rundy.") end
end

local function orderFood(player, index)
	local stall = World.FoodStalls[index]
	if stall then send(player, stall[4] .. " " .. stall[1] .. ": smacznego! (posiłek nie zmienia budżetu)") end
end
World.create(openStore, activeCatalog, Garments, join, orderFood)
-- The mall is roofed; lift only a near-black ambient so interiors stay readable.
local Lighting = game:GetService("Lighting")
if Lighting.Ambient.R + Lighting.Ambient.G + Lighting.Ambient.B < 0.6 then Lighting.Ambient = Color3.fromRGB(115, 105, 118) end

-- Walls contain normal movement. This also covers resets, falls and attempts to
-- move a waiting character outside the room; the decision belongs to the server.
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and Access.mustWait(state.phase, data[player.UserId] ~= nil, state.presenter == player.UserId)
				and not World.isInsideLobby(root.Position) then
				move(player, World.Lobby, false)
			end
		end
		task.wait(0.5)
	end
end)

-- Automatic entrance doors react to players and bots.
task.spawn(function()
	while true do
		local positions = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then table.insert(positions, root.Position) end
		end
		for _, entrant in ipairs(entrants) do
			local root = entrant.bot and entrant.model and entrant.model:FindFirstChild("HumanoidRootPart")
			if root then table.insert(positions, root.Position) end
		end
		World.updateDoors(positions)
		task.wait(0.15)
	end
end)

request.OnServerEvent:Connect(function(player, action, payload)
	if type(action) ~= "string" then return end
	local now = os.clock()
	if now - (lastRequest[player] or -1) < 0.12 then return end
	lastRequest[player] = now
	if action == "Sync" then send(player); return end
	if action == "Join" then join(player); return end
	if type(payload) ~= "table" then return end
	local own = data[player.UserId]
	if not own then send(player, "Najpierw wejdź do gry przy drzwiach salonu."); return end
	if action == "Vote" then
		if state.phase ~= "Showcase" or workspace:GetServerTimeNow() >= state.endsAt or payload.showId ~= state.showId then
			send(player, "To głosowanie już się zakończyło."); return
		end
		local _, message = Rules.vote(votes, player.UserId, state.presenter, payload.score, eligible())
		send(player, message); return
	end
	if state.phase ~= "Shopping" or workspace:GetServerTimeNow() >= state.endsAt then send(player, "Zakupy są zamknięte."); return end
	local slot = payload.slot
	if slot ~= 1 and slot ~= 2 then return end
	if action == "Slot" then
		own.activeSlot = slot; displayFor(player); send(player); return
	end
	if action == "Save" then
		local _, message = Rules.save(own, slot)
		own.activeSlot = slot; displayFor(player); send(player, message); return
	end
	if type(payload.id) ~= "string" or #payload.id > 64 then return end
	local item = Rules.item(activeCatalog, payload.id)
	if not item then send(player, "Ten produkt nie jest dostępny w bieżącej kolekcji."); return end
	if action == "Buy" or action == "Try" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not World.nearStore(item.store, root.Position) then
			local store = Mall.store(item.store)
			send(player, "Podejdź do sklepu " .. store.name .. " (" .. Mall.where(store) .. ")."); return
		end
		if action == "Try" then
			local preview, errorMessage = Rules.preview(own, activeCatalog, slot, item.id, payload.color, Config.Palette)
			if not preview then send(player, errorMessage); return end
			Appearance.apply(player.Character, preview, activeCatalog)
			send(player, "Przymiarka — aby zachować produkt, kup go i wybierz do stylizacji."); return
		end
		local _, message = Rules.buy(own, item)
		send(player, message); return
	end
	if action == "Equip" then
		local _, message = Rules.equip(own, activeCatalog, slot, item.id, payload.color, Config.Palette)
		own.activeSlot = slot; displayFor(player); send(player, message)
	end
end)

local function countdown(seconds, shouldContinue)
	state.endsAt = workspace:GetServerTimeNow() + seconds
	broadcast()
	while workspace:GetServerTimeNow() < state.endsAt do
		if shouldContinue and not shouldContinue() then return false end
		task.wait(0.25)
	end
	return true
end

-- NPC shopping uses the same Rules and deadline as players.
local function runBot(entrant, round)
	local own = data[entrant.id]
	local plan = BotLogic.plan(activeCatalog, own.budget, Config.Palette, rng)
	local function running()
		return state.round == round and state.phase == "Shopping" and workspace:GetServerTimeNow() < state.endsAt
			and entrant.model ~= nil and entrant.model.Parent ~= nil
	end
	task.wait(rng:NextNumber(0.5, 3))
	for _, stop in ipairs(plan.route) do
		if not running() then return end
		BotActors.walkTo(entrant.model, World.StoreTargets[stop.store], running)
		if not running() then return end
		task.wait(rng:NextNumber(2.5, 6)) -- browsing the rails
		if not running() then return end
		for _, id in ipairs(stop.items) do Rules.buy(own, Rules.item(activeCatalog, id)) end
		for slot = 1, 2 do
			for category, choice in pairs(plan.looks[slot]) do
				if own.owned[choice.id] and own.looks[slot][category] ~= choice.id then
					Rules.equip(own, activeCatalog, slot, choice.id, choice.color, Config.Palette)
				end
			end
			if own.looks[slot].top and own.looks[slot].bottom and not own.saved[slot] then Rules.save(own, slot) end
		end
		Appearance.apply(entrant.model, own.looks[1], activeCatalog)
	end
	-- Done early: relax in the food court until the show.
	if running() then
		BotActors.walkTo(entrant.model, Vector3.new(rng:NextInteger(-12, 12), World.L2 + 3, rng:NextInteger(-92, -52)), running)
	end
end

local function reset()
	state.presenter = 0; state.slot = 0; votes = {}
	for _, entrant in ipairs(entrants) do
		if entrant.bot and entrant.model then entrant.model:Destroy() end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(Appearance.apply, player.Character, nil, activeCatalog)
		move(player, World.Lobby, false)
	end
	entrants = {}; data = {}
end

local function newData()
	return { budget = Config.Budget, owned = {}, looks = { {}, {} }, saved = { false, false }, activeSlot = 1, scores = {} }
end

while true do
	reset()
	state.phase = "Lobby"; state.themes = {}; state.results = {}; state.endsAt = 0
	broadcast()
	repeat task.wait(0.25); pruneQueue() until #queue >= Config.MinPlayers
	state.phase = "Intermission"
	if not countdown(Config.IntermissionSeconds, function() pruneQueue(); return #queue >= Config.MinPlayers end) then continue end
	pruneQueue()
	for i = 1, math.min(#queue, Config.MaxPlayers) do
		local player = queue[i]
		table.insert(entrants, { id = player.UserId, name = player.DisplayName, player = player })
		data[player.UserId] = newData()
	end
	queue = {}
	local names = table.clone(Config.BotNames)
	for i = #names, 2, -1 do local j = rng:NextInteger(1, i); names[i], names[j] = names[j], names[i] end
	local botCount = math.max(0, Config.RoundSize - #entrants)
	for i = 1, botCount do
		local id = -i
		-- Bots start inside the entrance hall, so closed doors never block their path.
		local start = CFrame.new(((i - 1) % 4 - 1.5) * 4, World.FLOOR + 4, 52 - math.floor((i - 1) / 4) * 4)
		local model, description = BotActors.spawn(World.BotFolder, names[i], start, rng)
		if model then Appearance.setBase(model, description) end
		table.insert(entrants, { id = id, name = "[BOT] " .. names[i], bot = true, model = model })
		data[id] = newData()
	end
	local first = rng:NextInteger(1, #Config.Themes)
	local second = rng:NextInteger(1, #Config.Themes - 1)
	if second >= first then second += 1 end
	state.themes = { Config.Themes[first], Config.Themes[second] }; state.round += 1
	activeCatalog = Mall.generate(rng, activeCatalog, Config.Palette)
	World.refreshStock(activeCatalog, Garments, openStore)
	state.phase = "Shopping"
	local index = 0
	for _, entrant in ipairs(entrants) do
		if entrant.bot then continue end
		index += 1
		move(entrant.player, World.ShoppingStart * CFrame.new(((index - 1) % 4 - 1.5) * 3, 0, math.floor((index - 1) / 4) * 4), false)
	end
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(displayFor, player) end
	local round = state.round
	for _, entrant in ipairs(entrants) do
		if entrant.bot and entrant.model then task.defer(runBot, entrant, round) end
	end
	if not countdown(Config.ShoppingSeconds, humansPresent) then continue end
	local aborted = false
	for slot = 1, 2 do
		for _, entrant in ipairs(entrants) do
			if not humansPresent() then aborted = true; break end
			if not present(entrant) then continue end
			state.phase = "Showcase"; state.presenter = entrant.id; state.slot = slot; state.showId += 1; votes = {}
			-- Outfit changes load assets; run them in parallel, the queue keeps the latest.
			for _, viewer in ipairs(Players:GetPlayers()) do
				task.spawn(Appearance.apply, viewer.Character, nil, activeCatalog)
				move(viewer, World.Lobby, false)
			end
			local waitingIndex = 0
			for _, other in ipairs(entrants) do
				if other.bot and other ~= entrant then
					waitingIndex += 1
					task.spawn(Appearance.apply, other.model, nil, activeCatalog)
					BotActors.place(other.model, backstage(waitingIndex), false)
				end
			end
			displayEntrant(entrant)
			-- Bot jurors vote once, at a random moment, never for themselves.
			local showKey = state.showId
			for _, juror in ipairs(entrants) do
				if juror.bot and juror ~= entrant then
					task.delay(rng:NextNumber(2, Config.VotingSeconds - 3), function()
						if state.phase ~= "Showcase" or state.showId ~= showKey or workspace:GetServerTimeNow() >= state.endsAt then return end
						local own = data[entrant.id]
						Rules.vote(votes, juror.id, entrant.id, BotLogic.score(own.saved[slot], own.looks[slot], rng), eligible())
					end)
				end
			end
			local completed = countdown(Config.VotingSeconds, function() return humansPresent() and present(entrant) end)
			data[entrant.id].scores[slot] = table.clone(votes)
			if entrant.bot then BotActors.place(entrant.model, backstage(1), false) else move(entrant.player, World.Lobby, false) end
			if not completed and not humansPresent() then aborted = true; break end
		end
		if aborted then break end
	end
	if aborted then continue end
	local entries, ids = {}, eligible()
	for _, entrant in ipairs(entrants) do
		if not ids[entrant.id] then continue end
		local own = data[entrant.id]
		local a, ac = Rules.average(own.scores[1] or {}, ids)
		local b, bc = Rules.average(own.scores[2] or {}, ids)
		table.insert(entries, { userId = entrant.id, name = entrant.name, bot = entrant.bot == true, score = (a + b) / 2, first = a, second = b, votes = ac + bc })
	end
	state.results = Rules.rank(entries)
	state.phase = "Results"; state.presenter = 0; state.slot = 0; votes = {}
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(Appearance.apply, player.Character, nil, activeCatalog); move(player, World.Lobby, false) end
	countdown(Config.ResultsSeconds)
end

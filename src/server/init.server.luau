local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)
local Access = require(ReplicatedStorage.Shared.Access)
local BotLogic = require(ReplicatedStorage.Shared.BotLogic)
local Scoring = require(ReplicatedStorage.Shared.Scoring)
local World = require(script.World)
local Mall = require(ReplicatedStorage.Shared.Mall)
local Garments = require(ReplicatedStorage.Shared.Garments)
World.configure(Mall.Stores, Mall.Decor)
local Appearance = require(script.Appearance)
local BotActors = require(script.BotActors)
local Progress = require(script.Progress)
local Cosmetics = require(script.Cosmetics)
-- Store mannequins and avatars wear real catalog items (see Mall pools).
World.CatalogMannequin = Appearance.mannequin
task.spawn(Appearance.validate, Mall.Pools)

local remotes = Instance.new("Folder"); remotes.Name = "ShoppingQueen"; remotes.Parent = ReplicatedStorage
local request = Instance.new("RemoteEvent"); request.Name = "Request"; request.Parent = remotes
local update = Instance.new("RemoteEvent"); update.Name = "Update"; update.Parent = remotes
-- Phases: Lobby -> Intermission -> Intro (host cutscene) -> Shopping -> Showcase
-- (walk / vote / reveal per look) -> Results (podium) -> Lobby.
local state = { phase = "Lobby", step = nil, endsAt = 0, themes = {}, round = 0, presenter = 0, slot = 0, showId = 0, results = {},
	cam = nil, follow = nil, line = nil, reveal = nil }
-- Entrants are real players or bots; bots use negative ids in data/votes.
local entrants, data, votes, juryVotes, lastRequest = {}, {}, {}, {}, {}
local queue, skips = {}, {}
local rng = Random.new()
local activeCatalog = Mall.generate(rng, nil, Config.Palette)
local cast = { host = nil, jury = {} }

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
		catalog = activeCatalog, fittingItem = fittingItem, playerCount = #Players:GetPlayers(), followCam = World.StudioCams.runway.pos,
		phase = state.phase, step = state.step, endsAt = state.endsAt, round = state.round, themes = state.themes,
		presenter = state.presenter, slot = state.slot, showId = state.showId, results = state.results,
		cam = state.cam, follow = state.follow, line = state.line, reveal = state.reveal, skipped = skips[player.UserId] == true,
		roster = roster, queue = waiting, queued = queued(player), roundSize = Config.RoundSize,
		participating = own ~= nil, budget = if own then own.budget else 0,
		owned = if own then own.owned else {}, looks = if own then own.looks else { {}, {} },
		saved = if own then own.saved else { false, false },
		voted = votes[player.UserId] ~= nil, message = message, store = store,
		profile = Progress.summary(player), leaderboard = Progress.leaderboard,
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

local function inStudio(phase)
	return phase == "Intro" or phase == "Showcase" or phase == "Results"
end

-- Contestants sit on the studio sofas; spectators watch from the audience area.
local function seatEntrant(entrant)
	local seat = World.ContestantSeats[entrant.seat]
	local char = characterOf(entrant)
	if not seat or not char then return end
	if entrant.bot then BotActors.sit(char, seat); return end
	moveCharacter(char, seat.CFrame * CFrame.new(0, 3, 0), false)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then task.defer(function() if seat.Parent and humanoid.Parent then seat:Sit(humanoid) end end) end
end

local function homeFor(player)
	local participating = data[player.UserId] ~= nil
	if Access.canBrowse(state.phase, participating) then return World.ShoppingStart end
	if inStudio(state.phase) then return World.StudioAudience end
	return World.Lobby
end

local function displayEntrant(entrant)
	local own = data[entrant.id]
	local char = characterOf(entrant)
	if state.phase == "Showcase" and state.presenter == entrant.id and own then
		Appearance.apply(char, if own.saved[state.slot] then own.looks[state.slot] else {}, activeCatalog)
	elseif state.phase == "Shopping" and own then
		Appearance.apply(char, own.looks[own.activeSlot], activeCatalog)
	else
		Appearance.apply(char, nil, activeCatalog)
	end
end

local function displayFor(player)
	local entrant = entrantOf(player)
	if entrant then displayEntrant(entrant) else Appearance.apply(player.Character, nil, activeCatalog) end
	Cosmetics.apply(player.Character, Progress.summary(player))
end

local function placePlayer(player)
	local entrant = entrantOf(player)
	if entrant and inStudio(state.phase) and state.presenter ~= entrant.id then seatEntrant(entrant)
	else move(player, homeFor(player), false) end
end

local function setupPlayer(player)
	task.spawn(function()
		Progress.load(player)
		if player.Character then Cosmetics.apply(player.Character, Progress.summary(player)) end
		send(player, if Progress.saving then nil else "Postęp nie zapisuje się (w Studio włącz: Game Settings → Security → API Services).")
	end)
	player.CharacterAppearanceLoaded:Connect(function() displayFor(player) end)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and player.Parent then
			placePlayer(player)
			-- AppearanceLoaded will reapply after Roblox finishes loading the avatar.
			if player:HasAppearanceLoaded() then displayFor(player) end
		end
	end)
	if player.Character then placePlayer(player) end
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
	send(player, if waiting then "Zapisano! Za chwilę zaczyna się odcinek." else "Zapisano na następny odcinek — poczekaj w salonie.")
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

-- Host and jury live in the studio for the whole session.
local castFolder = Instance.new("Folder"); castFolder.Name = "ShowCast"; castFolder.Parent = workspace:FindFirstChild("ShoppingQueenPrototype")
task.spawn(function()
	cast.host = BotActors.npc(castFolder, Config.Host, World.HostSpot)
	local root = cast.host and cast.host:FindFirstChild("HumanoidRootPart")
	if root then root.Anchored = true end
	for index, definition in ipairs(Config.Jury) do
		local seat = World.JurySeats[index]
		local model = BotActors.npc(castFolder, definition, seat.CFrame)
		if model then BotActors.sit(model, seat) end
		cast.jury[index] = model
	end
end)

-- Keep everyone where the phase needs them: lounge, mall or studio.
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local participating = data[player.UserId] ~= nil
				if inStudio(state.phase) then
					local entrant = entrantOf(player)
					local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
					local seatedPhase = state.phase == "Intro" or (state.phase == "Showcase" and state.presenter ~= player.UserId)
					if not World.isInsideStudio(root.Position) then placePlayer(player)
					elseif entrant and seatedPhase and humanoid and humanoid.SeatPart == nil and not root.Anchored then
						-- Got up from the sofa (e.g. the jump button on a phone): sit back down.
						seatEntrant(entrant)
					end
				elseif not Access.canBrowse(state.phase, participating) and not World.isInsideLobby(root.Position) then
					move(player, World.Lobby, false)
				end
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

-- Lounge leaderboard board.
task.spawn(function()
	while true do
		local rows = Progress.refresh()
		local lines = { "🏆 RANKING • TOP 10" }
		for i, row in ipairs(rows) do table.insert(lines, string.format("%d. %s — ★ %d (%s)", i, row.name, row.stars, row.title)) end
		if #rows == 0 then table.insert(lines, "Zagraj odcinek, by trafić na tablicę!") end
		if World.LeaderboardLabel then World.LeaderboardLabel.Text = table.concat(lines, "\n") end
		task.wait(60)
	end
end)

request.OnServerEvent:Connect(function(player, action, payload)
	if type(action) ~= "string" then return end
	local now = os.clock()
	if now - (lastRequest[player] or -1) < 0.12 then return end
	lastRequest[player] = now
	if action == "Sync" then send(player); return end
	if action == "Join" then join(player); return end
	if action == "Skip" then
		if state.phase == "Intro" and data[player.UserId] then skips[player.UserId] = true; send(player, "Pominiesz intro, gdy wszystkie uczestniczki się zgodzą.") end
		return
	end
	if type(payload) ~= "table" then return end
	if action == "BuyCosmetic" or action == "EquipCosmetic" then
		if type(payload.id) ~= "string" then return end
		local _, message
		if action == "BuyCosmetic" then _, message = Progress.buy(player, payload.id) else _, message = Progress.toggle(player, payload.id) end
		Cosmetics.apply(player.Character, Progress.summary(player))
		send(player, message); return
	end
	local own = data[player.UserId]
	if not own then send(player, "Najpierw wejdź do gry przy drzwiach salonu."); return end
	if action == "Vote" then
		if state.phase ~= "Showcase" or state.step ~= "vote" or workspace:GetServerTimeNow() >= state.endsAt or payload.showId ~= state.showId then
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
		task.wait(0.2)
	end
	return true
end

-- One spoken line: subtitle for everyone, bubble above the speaker, camera shot.
local function speak(model, speaker, text, shot)
	state.line = { speaker = speaker, text = text }
	if shot then state.cam = World.StudioCams[shot]; state.follow = nil end
	BotActors.say(model, text, Config.IntroLineSeconds + 1)
	broadcast()
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
	state.presenter = 0; state.slot = 0; state.step = nil; state.cam = nil; state.follow = nil; state.line = nil; state.reveal = nil
	votes = {}; juryVotes = {}; skips = {}
	World.setConfetti(false)
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
	return { budget = Config.Budget, owned = {}, looks = { {}, {} }, saved = { false, false }, activeSlot = 1, shows = {} }
end

local function seatEveryone()
	for _, entrant in ipairs(entrants) do
		if present(entrant) then task.spawn(Appearance.apply, characterOf(entrant), nil, activeCatalog); seatEntrant(entrant) end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if not data[player.UserId] then move(player, World.StudioAudience * CFrame.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-8, 8)), false) end
	end
end

local function allSkipped()
	local any = false
	for _, entrant in ipairs(entrants) do
		if not entrant.bot and present(entrant) then
			any = true
			if not skips[entrant.id] then return false end
		end
	end
	return any
end

local function lookItemName(own, slot)
	local names = {}
	for category, id in pairs(own.looks[slot] or {}) do
		if category ~= "colors" then
			local item = Rules.item(activeCatalog, id)
			if item then table.insert(names, item.name) end
		end
	end
	return if #names > 0 then names[rng:NextInteger(1, #names)] else nil
end

-- Presenter walks the runway at catwalk pace; teleports if a client blocks it.
local function walkRunway(entrant, showKey)
	local char = characterOf(entrant)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	moveCharacter(char, World.RunwayStart, false)
	humanoid.WalkSpeed = 7
	humanoid:MoveTo(World.RunwayEnd)
	local summary = if entrant.player then Progress.summary(entrant.player) else nil
	Cosmetics.entrance(char, summary)
	task.delay(6.5, function()
		if state.showId ~= showKey or not char.Parent then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - World.RunwayEnd).Magnitude > 4 then moveCharacter(char, CFrame.lookAt(World.RunwayEnd, World.RunwayEnd - Vector3.new(0, 0, 1)), false) end
		local pose = Cosmetics.poseId(summary, rng) or (if entrant.bot and rng:NextInteger(1, 2) == 1 then "rbxassetid://507770239" else nil)
		if pose then BotActors.pose(char, pose) end
	end)
end

local function intro()
	state.phase = "Intro"; state.step = nil
	seatEveryone()
	local names = {}
	for _, entrant in ipairs(entrants) do table.insert(names, entrant.name) end
	local host = Config.Host.name
	local lines = {
		{ "Witajcie w programie Królowa Stylu! Nazywam się " .. host .. " i to ja poprowadzę dzisiejszy odcinek!", "host" },
		{ "Przywitajmy nasze uczestniczki: " .. table.concat(names, ", ") .. "!", "wide" },
		{ "Dzisiejsze tematy to „" .. state.themes[1] .. "” oraz „" .. state.themes[2] .. "”.", "host" },
		{ "Macie " .. Config.Budget .. " zł i tylko " .. math.floor(Config.ShoppingSeconds / 60) .. " minut na zakupy w naszej galerii. Przygotujcie dwie stylizacje — po jednej na każdy temat!", "wide" },
		{ "Potem wrócicie tutaj, na czerwony dywan. Każda z was przejdzie po wybiegu, a jury — " .. Config.Jury[1].name .. ", " .. Config.Jury[2].name .. " i " .. Config.Jury[3].name .. " — oraz wy same przyznacie od 1 do 5 gwiazdek.", "jury" },
		{ "Zwyciężczyni zgarnie najwięcej monet i gwiazdek do rankingu. Gotowe? Czas start!", "host" },
	}
	for _, line in ipairs(lines) do
		if allSkipped() then break end
		speak(cast.host, host, line[1], line[2])
		if not countdown(Config.IntroLineSeconds, function() return humansPresent() and not allSkipped() end) and not humansPresent() then return false end
	end
	return humansPresent()
end

local function showcase()
	state.phase = "Showcase"; state.step = "intro"
	seatEveryone()
	speak(cast.host, Config.Host.name, "Czas minął! Zapraszam na czerwony dywan — zaczynamy pokaz!", "wide")
	if not countdown(Config.IntroLineSeconds, humansPresent) then return false end
	for slot = 1, 2 do
		for _, entrant in ipairs(entrants) do
			if not humansPresent() then return false end
			if not present(entrant) then continue end
			local own = data[entrant.id]
			state.presenter = entrant.id; state.slot = slot; state.showId += 1; votes = {}; juryVotes = {}; state.reveal = nil
			local showKey = state.showId
			local theme = state.themes[slot]
			-- 1) Runway walk, camera follows the presenter.
			state.step = "walk"; state.cam = nil; state.follow = entrant.id
			displayEntrant(entrant)
			walkRunway(entrant, showKey)
			state.line = { speaker = Config.Host.name, text = "Na wybiegu: " .. entrant.name .. "! Temat: „" .. theme .. "”." }
			BotActors.say(cast.host, state.line.text, 5)
			if not countdown(Config.PresentSeconds, function() return humansPresent() and present(entrant) end) then
				if not humansPresent() then return false end
			end
			-- 2) Scores: jury comments on camera, contestants vote 1–5 stars.
			state.step = "vote"; state.follow = nil; state.cam = World.StudioCams.jury
			for _, other in ipairs(entrants) do
				if other.bot and other ~= entrant then
					task.delay(rng:NextNumber(1.5, Config.VoteSeconds - 1.5), function()
						if state.showId ~= showKey or state.step ~= "vote" then return end
						Rules.vote(votes, other.id, entrant.id, BotLogic.score(own.saved[slot], own.looks[slot], rng), eligible())
					end)
				end
			end
			for index, judge in ipairs(Config.Jury) do
				task.delay(0.4 + (index - 1) * (Config.VoteSeconds - 1) / 3, function()
					if state.showId ~= showKey or state.step ~= "vote" then return end
					local score = BotLogic.juryScore(own.saved[slot], own.looks[slot], rng)
					juryVotes[index] = score
					local text = BotLogic.comment(score, lookItemName(own, slot), theme, rng) .. "  " .. Scoring.starText(score)
					state.line = { speaker = judge.name, text = text, stars = score }
					BotActors.say(cast.jury[index], text, 4)
					broadcast()
				end)
			end
			countdown(Config.VoteSeconds, humansPresent)
			-- 3) Reveal the show score.
			for index in ipairs(Config.Jury) do
				if not juryVotes[index] then juryVotes[index] = BotLogic.juryScore(own.saved[slot], own.looks[slot], rng) end
			end
			local score, jury, crowd, count = Scoring.show(juryVotes, votes, eligible())
			own.shows[slot] = { score = score, jury = jury, crowd = crowd }
			state.step = "reveal"; state.follow = entrant.id; state.cam = nil
			state.reveal = { name = entrant.name, score = score, jury = jury, crowd = crowd, votes = count, theme = theme }
			state.line = { speaker = Config.Host.name, text = string.format("%s zdobywa %.1f / 5 gwiazdek!", entrant.name, score) }
			countdown(Config.RevealSeconds, humansPresent)
			local char = characterOf(entrant)
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.WalkSpeed = 16 end
			state.presenter = 0
			task.spawn(Appearance.apply, char, nil, activeCatalog)
			seatEntrant(entrant)
		end
	end
	return humansPresent()
end

local function results()
	local entries, ids = {}, eligible()
	for _, entrant in ipairs(entrants) do
		if not ids[entrant.id] then continue end
		local own = data[entrant.id]
		table.insert(entries, { userId = entrant.id, name = entrant.name, bot = entrant.bot == true,
			score = Scoring.final(own.shows), first = own.shows[1] and own.shows[1].score or 0, second = own.shows[2] and own.shows[2].score or 0 })
	end
	Rules.rank(entries)
	for _, entry in ipairs(entries) do
		entry.reward = Scoring.reward(entry.rank, entry.score)
		for _, entrant in ipairs(entrants) do
			if entrant.id == entry.userId and entrant.player and entrant.player.Parent then
				Progress.award(entrant.player, entry.reward, entry.rank == 1)
			end
		end
	end
	state.results = entries
	state.phase = "Results"; state.step = nil; state.presenter = 0; state.slot = 0; state.reveal = nil; votes = {}
	-- Top three on the podium wearing their best look.
	for index, entry in ipairs(entries) do
		for _, entrant in ipairs(entrants) do
			if entrant.id ~= entry.userId then continue end
			local char = characterOf(entrant)
			if index <= 3 then
				local own = data[entrant.id]
				local best = if (own.shows[2] and own.shows[2].score or 0) > (own.shows[1] and own.shows[1].score or 0) then 2 else 1
				task.spawn(Appearance.apply, char, if own.saved[best] then own.looks[best] else nil, activeCatalog)
				moveCharacter(char, World.PodiumSpots[index], true)
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do Cosmetics.apply(player.Character, Progress.summary(player)) end
	local host = Config.Host.name
	local function nameAt(place)
		local entry = entries[place]
		return if entry then string.format("%s (%.1f★)", entry.name, entry.score) else nil
	end
	local lines = { { "Czas na podliczenie gwiazdek!", "podium" } }
	if nameAt(3) then table.insert(lines, { "Trzecie miejsce zajmuje… " .. nameAt(3) .. "!", "podium" }) end
	if nameAt(2) then table.insert(lines, { "Na drugim miejscu… " .. nameAt(2) .. "!", "podium" }) end
	table.insert(lines, { "A Królową Stylu tego odcinka zostaje… " .. (nameAt(1) or "") .. "! Gratulacje!", "podium", true })
	table.insert(lines, { "Dziękuję za wspaniały pokaz! Monety i gwiazdki trafiły już do waszych profili. Do zobaczenia!", "wide" })
	local perLine = Config.ResultsSeconds / #lines
	for _, line in ipairs(lines) do
		if line[3] then World.setConfetti(true) end
		speak(cast.host, host, line[1], line[2])
		countdown(perLine)
	end
	for _, entrant in ipairs(entrants) do
		local root = characterOf(entrant) and characterOf(entrant):FindFirstChild("HumanoidRootPart")
		if root then root.Anchored = false end
	end
end

local function episode()
	reset()
	state.phase = "Lobby"; state.themes = {}; state.results = {}; state.endsAt = 0
	broadcast()
	repeat task.wait(0.25); pruneQueue() until #queue >= Config.MinPlayers
	state.phase = "Intermission"
	if not countdown(Config.IntermissionSeconds, function() pruneQueue(); return #queue >= Config.MinPlayers end) then return end
	pruneQueue()
	for i = 1, math.min(#queue, Config.MaxPlayers) do
		local player = queue[i]
		table.insert(entrants, { id = player.UserId, name = player.DisplayName, player = player, seat = i })
		data[player.UserId] = newData()
	end
	queue = {}
	local names = table.clone(Config.BotNames)
	for i = #names, 2, -1 do local j = rng:NextInteger(1, i); names[i], names[j] = names[j], names[i] end
	local botCount = math.max(0, Config.RoundSize - #entrants)
	for i = 1, botCount do
		local id = -i
		local seat = #entrants + 1
		local model, description = BotActors.spawn(World.BotFolder, names[i], World.ContestantSeats[seat].CFrame * CFrame.new(0, 3, 0), rng)
		if model then Appearance.setBase(model, description); model:SetAttribute("EntrantId", id) end
		table.insert(entrants, { id = id, name = "[BOT] " .. names[i], bot = true, model = model, seat = seat })
		data[id] = newData()
	end
	local first = rng:NextInteger(1, #Config.Themes)
	local second = rng:NextInteger(1, #Config.Themes - 1)
	if second >= first then second += 1 end
	state.themes = { Config.Themes[first], Config.Themes[second] }; state.round += 1
	activeCatalog = Mall.generate(rng, activeCatalog, Config.Palette)
	World.refreshStock(activeCatalog, Garments, openStore)
	if not intro() then return end
	-- Shopping: players appear in front of the mall, bots inside the hall.
	state.phase = "Shopping"; state.step = nil; state.cam = nil; state.follow = nil; state.line = nil
	local index = 0
	for i, entrant in ipairs(entrants) do
		if entrant.bot then
			BotActors.place(entrant.model, CFrame.new(((i - 1) % 4 - 1.5) * 4, World.FLOOR + 4, 52 - math.floor((i - 1) / 4) * 4), false)
			continue
		end
		index += 1
		move(entrant.player, World.ShoppingStart * CFrame.new(((index - 1) % 4 - 1.5) * 3, 0, math.floor((index - 1) / 4) * 4), false)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if not data[player.UserId] then move(player, World.Lobby, false) end
		task.spawn(displayFor, player)
	end
	local round = state.round
	for _, entrant in ipairs(entrants) do
		if entrant.bot and entrant.model then task.defer(runBot, entrant, round) end
	end
	if not countdown(Config.ShoppingSeconds, humansPresent) then return end
	if not showcase() then return end
	results()
end

-- A bug in one episode returns everyone to the lounge instead of freezing the game.
while true do
	local ok, err = xpcall(episode, debug.traceback)
	if not ok then
		warn("[Królowa Stylu] Błąd rundy: " .. tostring(err))
		task.wait(1)
	end
end

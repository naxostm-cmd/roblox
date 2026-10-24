local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)
local World = require(script.World)
local Appearance = require(script.Appearance)

local remotes = Instance.new("Folder"); remotes.Name = "ShoppingQueen"; remotes.Parent = ReplicatedStorage
local request = Instance.new("RemoteEvent"); request.Name = "Request"; request.Parent = remotes
local update = Instance.new("RemoteEvent"); update.Name = "Update"; update.Parent = remotes
local state = { phase = "Lobby", endsAt = 0, themes = {}, round = 0, presenter = 0, slot = 0, showId = 0, results = {} }
local participants, data, votes, lastRequest = {}, {}, {}, {}
local rng = Random.new()

local function eligible()
	local ids = {}
	for _, player in ipairs(participants) do
		if player.Parent == Players then ids[player.UserId] = true end
	end
	return ids
end

local function activeCount()
	local count = 0
	for _ in pairs(eligible()) do count += 1 end
	return count
end

local function send(player, message, store)
	local own = data[player.UserId]
	local roster = {}
	for _, participant in ipairs(participants) do
		if participant.Parent == Players then table.insert(roster, { userId = participant.UserId, name = participant.DisplayName }) end
	end
	update:FireClient(player, {
		phase = state.phase, endsAt = state.endsAt, round = state.round, themes = state.themes,
		presenter = state.presenter, slot = state.slot, showId = state.showId, results = state.results,
		roster = roster, participating = own ~= nil, budget = if own then own.budget else 0,
		owned = if own then own.owned else {}, looks = if own then own.looks else { {}, {} },
		saved = if own then own.saved else { false, false },
		voted = votes[player.UserId] ~= nil, message = message, store = store,
	})
end

local function broadcast()
	for _, player in ipairs(Players:GetPlayers()) do send(player) end
end

local function move(player, cf, anchored)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then root.Anchored = false; char:PivotTo(cf); root.Anchored = anchored == true end
end

local function displayFor(player)
	local own = data[player.UserId]
	if state.phase == "Showcase" and state.presenter == player.UserId and own then
		Appearance.apply(player.Character, if own.saved[state.slot] then own.looks[state.slot] else {}, Config.Catalog)
		move(player, World.Stage, true)
	elseif state.phase == "Shopping" and own then
		Appearance.apply(player.Character, own.looks[own.activeSlot], Config.Catalog)
	else
		Appearance.apply(player.Character, nil, Config.Catalog)
	end
end

local function setupPlayer(player)
	player.CharacterAppearanceLoaded:Connect(function() displayFor(player) end)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and player.Parent then
			move(player, World.Lobby, false)
			-- AppearanceLoaded will reapply after Roblox finishes loading the avatar.
			if player:HasAppearanceLoaded() then displayFor(player) end
		end
	end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	-- Keep the snapshot until round cleanup; departed players cannot buy/vote or win.
	task.defer(broadcast)
end)

World.create(function(player, category)
	if state.phase == "Shopping" and data[player.UserId] then send(player, nil, category) end
end)

request.OnServerEvent:Connect(function(player, action, payload)
	if type(action) ~= "string" then return end
	local now = os.clock()
	if now - (lastRequest[player] or -1) < 0.12 then return end
	lastRequest[player] = now
	if action == "Sync" then send(player); return end
	if type(payload) ~= "table" then return end
	local own = data[player.UserId]
	if not own then send(player, "Dołączysz do następnej rundy."); return end
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
	local item = Rules.item(Config.Catalog, payload.id)
	if not item then return end
	if action == "Buy" or action == "Try" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - World.StorePositions[item.category]).Magnitude > Config.StoreDistance then
			send(player, "Podejdź do odpowiedniego sklepu."); return
		end
		if action == "Try" then
			local preview = table.clone(own.looks[slot]); preview[item.category] = item.id
			Appearance.apply(player.Character, preview, Config.Catalog)
			send(player, "Przymiarka — aby zachować produkt, kup go i wybierz do stylizacji."); return
		end
		local _, message = Rules.buy(own, item)
		send(player, message); return
	end
	if action == "Equip" then
		local _, message = Rules.equip(own, Config.Catalog, slot, item.id)
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

local function enough() return activeCount() >= Config.MinPlayers end

local function reset()
	state.presenter = 0; state.slot = 0; votes = {}
	for _, player in ipairs(Players:GetPlayers()) do
		Appearance.apply(player.Character, nil, Config.Catalog)
		move(player, World.Lobby, false)
	end
	participants = {}; data = {}
end

while true do
	reset()
	state.phase = "Lobby"; state.themes = {}; state.results = {}; state.endsAt = 0
	broadcast()
	repeat task.wait(1) until #Players:GetPlayers() >= Config.MinPlayers
	state.phase = "Intermission"
	if not countdown(Config.IntermissionSeconds, function() return #Players:GetPlayers() >= Config.MinPlayers end) then continue end
	local available = Players:GetPlayers()
	-- Random selection if more than eight players join; others spectate this round.
	for i = #available, 2, -1 do local j = rng:NextInteger(1, i); available[i], available[j] = available[j], available[i] end
	for i = 1, math.min(#available, Config.MaxPlayers) do
		local player = available[i]
		table.insert(participants, player)
		data[player.UserId] = { budget = Config.Budget, owned = {}, looks = { {}, {} }, saved = { false, false }, activeSlot = 1, scores = {} }
	end
	local first = rng:NextInteger(1, #Config.Themes)
	local second = rng:NextInteger(1, #Config.Themes - 1)
	if second >= first then second += 1 end
	state.themes = { Config.Themes[first], Config.Themes[second] }; state.round += 1
	state.phase = "Shopping"
	if not countdown(Config.ShoppingSeconds, enough) then continue end
	local aborted = false
	for slot = 1, 2 do
		for _, player in ipairs(participants) do
			if not enough() then aborted = true; break end
			if player.Parent ~= Players then continue end
			state.phase = "Showcase"; state.presenter = player.UserId; state.slot = slot; state.showId += 1; votes = {}
			for _, viewer in ipairs(Players:GetPlayers()) do
				Appearance.apply(viewer.Character, nil, Config.Catalog)
				move(viewer, World.Lobby, false)
			end
			displayFor(player)
			local completed = countdown(Config.VotingSeconds, function() return enough() and player.Parent == Players end)
			data[player.UserId].scores[slot] = table.clone(votes)
			move(player, World.Lobby, false)
			if not completed and not enough() then aborted = true; break end
		end
		if aborted then break end
	end
	if aborted then continue end
	local entries, ids = {}, eligible()
	for _, player in ipairs(participants) do
		if not ids[player.UserId] then continue end
		local own = data[player.UserId]
		local a, ac = Rules.average(own.scores[1] or {}, ids)
		local b, bc = Rules.average(own.scores[2] or {}, ids)
		table.insert(entries, { userId = player.UserId, name = player.DisplayName, score = (a + b) / 2, first = a, second = b, votes = ac + bc })
	end
	state.results = Rules.rank(entries)
	state.phase = "Results"; state.presenter = 0; state.slot = 0; votes = {}
	for _, player in ipairs(Players:GetPlayers()) do Appearance.apply(player.Character, nil, Config.Catalog); move(player, World.Lobby, false) end
	countdown(Config.ResultsSeconds)
end

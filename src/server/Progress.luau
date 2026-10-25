-- Persistent player progress: coins, lifetime stars, wins, cosmetics, ranking.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Scoring = require(game:GetService("ReplicatedStorage").Shared.Scoring)
local Premium = require(game:GetService("ReplicatedStorage").Shared.PremiumCatalog)
local Progress = { saving = true, leaderboard = {} }
local profiles, names = {}, {}
local store, ordered
local ok = pcall(function()
	store = DataStoreService:GetDataStore("ShoppingQueenProfile_v1")
	ordered = DataStoreService:GetOrderedDataStore("ShoppingQueenStars_v1")
end)
if not ok then Progress.saving = false end

local function blank()
	return { coins = 0, stars = 0, wins = 0, rounds = 0, owned = {}, equipped = {} }
end

local function stats(player, profile)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder"); folder.Name = "leaderstats"; folder.Parent = player
		local stars = Instance.new("IntValue"); stars.Name = "★ Gwiazdki"; stars.Parent = folder
		local coins = Instance.new("IntValue"); coins.Name = "Monety"; coins.Parent = folder
	end
	folder["★ Gwiazdki"].Value = profile.stars
	folder.Monety.Value = profile.coins
end

function Progress.load(player)
	local profile = blank()
	if store then
		local success, saved = pcall(function() return store:GetAsync("u" .. player.UserId) end)
		if success and type(saved) == "table" then
			for key, value in pairs(saved) do profile[key] = value end
		elseif not success then
			-- Studio without API access, or a DataStore outage: play on, unsaved.
			Progress.saving = false
		end
	end
	profiles[player] = profile
	names[player.UserId] = player.DisplayName
	stats(player, profile)
	return profile
end

function Progress.get(player)
	return profiles[player]
end

function Progress.save(player)
	local profile = profiles[player]
	if not profile or not store or not Progress.saving then return end
	pcall(function() store:SetAsync("u" .. player.UserId, profile) end)
	pcall(function() ordered:SetAsync(tostring(player.UserId), profile.stars) end)
end

function Progress.summary(player)
	local profile = profiles[player]
	if not profile then return nil end
	local index, title, nextAt = Scoring.rank(profile.stars)
	return { coins = profile.coins, stars = profile.stars, wins = profile.wins, rounds = profile.rounds,
		owned = profile.owned, equipped = profile.equipped, rank = index, title = title, nextAt = nextAt, saving = Progress.saving }
end

function Progress.award(player, reward, won)
	local profile = profiles[player]
	if not profile then return end
	profile.stars += reward.stars; profile.coins += reward.coins
	profile.rounds += 1; if won then profile.wins += 1 end
	stats(player, profile)
	task.spawn(Progress.save, player)
end

function Progress.buy(player, id)
	local profile = profiles[player]
	if not profile then return false, "Profil jeszcze się ładuje." end
	for _, item in ipairs(Premium) do
		if item.id == id then
			if profile.owned[id] then return false, "Już to masz." end
			if profile.coins < item.price then return false, "Brakuje monet: potrzebujesz " .. item.price .. "." end
			profile.coins -= item.price; profile.owned[id] = true; profile.equipped[id] = true
			stats(player, profile)
			task.spawn(Progress.save, player)
			return true, "Kupiono: " .. item.name .. " ✨"
		end
	end
	return false, "Nieznany produkt."
end

function Progress.toggle(player, id)
	local profile = profiles[player]
	if not profile or not profile.owned[id] then return false, "Najpierw kup ten dodatek." end
	profile.equipped[id] = not profile.equipped[id] or nil
	return true, if profile.equipped[id] then "Założono." else "Zdjęto."
end

local function nameOf(userId)
	if names[userId] then return names[userId] end
	local success, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	names[userId] = if success then name else ("Gracz " .. userId)
	return names[userId]
end

-- Top 10 by lifetime stars; online players fill in when the store is unavailable.
function Progress.refresh()
	local rows = {}
	if ordered and Progress.saving then
		local success, page = pcall(function() return ordered:GetSortedAsync(false, 10):GetCurrentPage() end)
		if success then
			for _, entry in ipairs(page) do
				local userId = tonumber(entry.key)
				if userId then table.insert(rows, { name = nameOf(userId), stars = entry.value }) end
			end
		end
	end
	if #rows == 0 then
		for player, profile in pairs(profiles) do
			if player.Parent then table.insert(rows, { name = player.DisplayName, stars = profile.stars }) end
		end
		table.sort(rows, function(a, b) return a.stars > b.stars end)
		while #rows > 10 do table.remove(rows) end
	end
	for _, row in ipairs(rows) do row.title = select(2, Scoring.rank(row.stars)) end
	Progress.leaderboard = rows
	return rows
end

Players.PlayerRemoving:Connect(function(player)
	Progress.save(player)
	profiles[player] = nil
end)
game:BindToClose(function()
	for player in pairs(profiles) do Progress.save(player) end
end)
task.spawn(function()
	while true do
		task.wait(120)
		for player in pairs(profiles) do Progress.save(player) end
	end
end)

return Progress

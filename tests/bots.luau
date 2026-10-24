local Mall = require("../src/shared/Mall")
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local BotLogic = require("../src/shared/BotLogic")
local Access = require("../src/shared/Access")

local seed = 777
local rng = { NextInteger = function(_, low, high) seed = (seed * 16807) % 2147483647; return low + seed % (high - low + 1) end }
local previous
local extrasSeen = 0
for round = 1, 300 do
	local catalog = Mall.generate(rng, previous, Config.Palette)
	previous = catalog
	local plan = BotLogic.plan(catalog, Config.Budget, Config.Palette, rng)
	assert(plan.spent <= Config.Budget, "bot overspent")
	-- Replay the plan through the real rules, as the server does.
	local data = { budget = Config.Budget, owned = {}, looks = { {}, {} }, saved = { false, false } }
	local visited = {}
	for _, stop in ipairs(plan.route) do
		assert(not visited[stop.store], "each store is visited once"); visited[stop.store] = true
		assert(Mall.store(stop.store), "route uses real stores")
		for _, id in ipairs(stop.items) do
			local item = Rules.item(catalog, id)
			assert(item and item.store == stop.store, "item belongs to its stop")
			assert(Rules.buy(data, item), "planned purchase must succeed")
		end
	end
	assert(Config.Budget - data.budget == plan.spent, "replayed spend matches plan")
	for slot = 1, 2 do
		local look = plan.looks[slot]
		assert(look.top and look.bottom, "both looks need top and bottom")
		for category, choice in pairs(look) do
			assert(Rules.equip(data, catalog, slot, choice.id, choice.color, Config.Palette), "equip " .. category)
			if category ~= "top" and category ~= "bottom" then extrasSeen += 1 end
		end
		assert(Rules.save(data, slot), "bot look saves")
	end
	local score = BotLogic.score(true, data.looks[1], rng)
	assert(score >= 6 and score <= 10 and score % 1 == 0)
	local weak = BotLogic.score(false, {}, rng)
	assert(weak >= 1 and weak <= 4)
	-- Bots vote through the same validator: never for themselves.
	local votes, eligible = {}, { [-1] = true, [-2] = true, [42] = true }
	assert(not Rules.vote(votes, -1, -1, score, eligible))
	assert(Rules.vote(votes, -1, 42, score, eligible))
end
assert(extrasSeen > 300, "bots also wear accessories")
assert(Config.MinPlayers == 1 and Config.RoundSize == 4 and Config.Budget == 1500 and Config.ShoppingSeconds == 480)
assert(Access.canBrowse("Shopping", true) and not Access.canBrowse("Lobby", true))
print("PASS: 300 bot shopping plans replayed through Rules, two saved looks each, valid jury scores")

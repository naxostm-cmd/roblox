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
	assert(score >= 3 and score <= 5 and score % 1 == 0)
	local weak = BotLogic.score(false, {}, rng)
	assert(weak >= 1 and weak <= 2)
	local jury = BotLogic.juryScore(true, data.looks[1], rng)
	assert(jury >= 2 and jury <= 5 and BotLogic.juryScore(false, {}, rng) == 1)
	local comment = BotLogic.comment(jury, "Trencz biały", "Randka w Paryżu", rng)
	assert(type(comment) == "string" and #comment > 10 and not string.find(comment, "%%s", 1, true), "jury comment")
	-- Bots vote through the same validator: never for themselves.
	local votes, eligible = {}, { [-1] = true, [-2] = true, [42] = true }
	assert(not Rules.vote(votes, -1, -1, score, eligible))
	assert(Rules.vote(votes, -1, 42, score, eligible))
end
assert(extrasSeen > 300, "bots also wear accessories")
assert(Config.MinPlayers == 1 and Config.RoundSize == 4 and Config.Budget == 1500 and Config.ShoppingSeconds == 480)
assert(Access.canBrowse("Shopping", true) and not Access.canBrowse("Lobby", true))
local Scoring = require("../src/shared/Scoring")
-- Show score: the jury carries half the weight, so 1-star tactics cannot sink a look.
local s1 = Scoring.show({ 5, 5, 5 }, { [1] = 1, [2] = 1 }, { [1] = true, [2] = true })
assert(s1 == 3, "jury half weight")
assert(Scoring.show({ 4, 4, 4 }, {}, {}) == 4, "jury only without crowd votes")
assert(Scoring.show({ 3 }, { [9] = 5 }, {}) == 3, "departed voters ignored")
assert(math.abs(Scoring.final({ { score = 4 }, { score = 3 } }) - 3.5) < 1e-9)
local r1, r2 = Scoring.reward(1, 4.5), Scoring.reward(4, 2)
assert(r1.stars == 14 and r1.coins == 20 + 14 * 5 + 100 and r2.stars == 4 and r2.coins == 40, "rewards")
local index, title, nextAt = Scoring.rank(0)
assert(index == 1 and title == "Debiutantka" and nextAt == 15)
assert(select(2, Scoring.rank(1500)) == "Królowa Stylu" and select(3, Scoring.rank(99999)) == nil)
for i = 2, #Scoring.Ranks do assert(Scoring.Ranks[i][1] > Scoring.Ranks[i - 1][1], "ascending ranks") end
assert(Scoring.starText(4.4) == "★★★★☆")
print("PASS: 300 bot shopping plans replayed through Rules, 1–5 star jury/crowd scores, comments, rewards and ranks")

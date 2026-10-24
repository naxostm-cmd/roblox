local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")
local count = 0
local function check(condition, message)
 count += 1
 assert(condition, message)
end
local function newPlayer()
 return { budget = Config.Budget, owned = {}, looks = { {}, {} }, saved = { false, false } }
end
local data = newPlayer()
check(Rules.buy(data, nil) == false and data.budget == 1500, "unknown item")
local top = Rules.item(Config.Catalog, "rose_top")
check(Rules.buy(data, top) == true, "first purchase")
check(data.budget == 1280 and data.owned.rose_top, "server price deducted")
check(Rules.buy(data, top) == false and data.budget == 1280, "duplicate purchase must not charge")
local poor = newPlayer(); poor.budget = 1
check(Rules.buy(poor, top) == false and poor.budget == 1 and not poor.owned.rose_top, "insufficient funds")
check(Rules.equip(data, Config.Catalog, 1, "black_top") == false, "unowned item")
check(Rules.equip(data, Config.Catalog, 3, "rose_top") == false, "invalid slot")
check(Rules.save(data, 0) == false, "invalid save slot")
check(Rules.save(data, 1) == false, "empty outfit")
check(Rules.equip(data, Config.Catalog, 1, "rose_top") == true, "equip owned top")
check(Rules.save(data, 1) == false, "bottom required")
check(Rules.buy(data, Rules.item(Config.Catalog, "blue_bottom")) == true, "buy bottom")
check(Rules.equip(data, Config.Catalog, 1, "blue_bottom") == true, "equip bottom")
check(Rules.save(data, 1) == true and data.saved[1], "complete look saved")
check(not data.saved[2] and next(data.looks[2]) == nil, "slots independent")
check(Rules.equip(data, Config.Catalog, 2, "rose_top") == true, "owned top reusable in second look")
check(Rules.equip(data, Config.Catalog, 2, "blue_bottom") == true, "owned bottom reusable")
check(Rules.save(data, 2) == true, "second look saved")
check(Rules.equip(data, Config.Catalog, 1, "rose_top") == true and not data.saved[1] and data.saved[2], "edit invalidates only affected save")
local ids, votes = { [11] = true, [22] = true, [33] = true }, {}
check(Rules.vote(votes, 11, 11, 10, ids) == false, "self voting blocked")
check(Rules.vote(votes, 99, 11, 10, ids) == false, "spectator voting blocked")
check(Rules.vote(votes, 22, 99, 10, ids) == false, "departed presenter blocked")
for _, invalid in ipairs({ 0, 11, 4.5, "10", math.huge, 0 / 0 }) do
 check(Rules.vote(votes, 22, 11, invalid, ids) == false, "invalid score blocked")
end
check(Rules.vote(votes, 22, 11, 8, ids) == true, "valid vote")
check(Rules.vote(votes, 22, 11, 1, ids) == false and votes[22] == 8, "one immutable vote per show")
check(Rules.vote(votes, 33, 11, 10, ids) == true, "second voter")
local mean, total = Rules.average(votes, ids)
check(mean == 9 and total == 2, "mean of valid votes")
ids[33] = nil
mean, total = Rules.average(votes, ids)
check(mean == 8 and total == 1, "departed voter excluded")
mean, total = Rules.average({}, ids)
check(mean == 0 and total == 0, "no votes yields zero")
local ranked = Rules.rank({ { userId = 33, score = 7 }, { userId = 22, score = 9 }, { userId = 11, score = 9 }, { userId = 44, score = 0 } })
check(ranked[1].userId == 11 and ranked[2].userId == 22, "stable tie order")
check(ranked[1].rank == 1 and ranked[2].rank == 1 and ranked[3].rank == 3, "joint winners")
check(ranked[4].rank == 4, "lowest result last")
local seen = {}
for _, item in ipairs(Config.Catalog) do
 check(not seen[item.id] and item.price > 0 and item.price % 1 == 0, "unique catalog items with positive integer prices")
 seen[item.id] = true
end
check(#Config.Themes >= 2 and Config.MinPlayers >= 2 and Config.MaxPlayers >= Config.MinPlayers, "valid round settings")
print("PASS: " .. count .. " gameplay rule assertions")

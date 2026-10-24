local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")
local Catalog = require("./fixtures/Catalog")
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
local top = Rules.item(Catalog, "rose_top")
check(Rules.buy(data, top) == true, "first purchase")
check(data.budget == 1280 and data.owned.rose_top, "server price deducted")
check(Rules.buy(data, top) == false and data.budget == 1280, "duplicate purchase must not charge")
local poor = newPlayer(); poor.budget = 1
check(Rules.buy(poor, top) == false and poor.budget == 1 and not poor.owned.rose_top, "insufficient funds")
check(Rules.equip(data, Catalog, 1, "black_top") == false, "unowned item")
check(Rules.equip(data, Catalog, 3, "rose_top") == false, "invalid slot")
check(Rules.save(data, 0) == false, "invalid save slot")
check(Rules.save(data, 1) == false, "empty outfit")
check(Rules.equip(data, Catalog, 1, "rose_top") == true, "equip owned top")
check(Rules.save(data, 1) == false, "bottom required")
check(Rules.buy(data, Rules.item(Catalog, "blue_bottom")) == true, "buy bottom")
check(Rules.equip(data, Catalog, 1, "blue_bottom") == true, "equip bottom")
check(Rules.save(data, 1) == true and data.saved[1], "complete look saved")
check(not data.saved[2] and next(data.looks[2]) == nil, "slots independent")
check(Rules.equip(data, Catalog, 2, "rose_top") == true, "owned top reusable in second look")
check(Rules.equip(data, Catalog, 2, "blue_bottom") == true, "owned bottom reusable")
check(Rules.save(data, 2) == true, "second look saved")
check(Rules.equip(data, Catalog, 1, "rose_top") == true and not data.saved[1] and data.saved[2], "edit invalidates only affected save")
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
for _, item in ipairs(Catalog) do
 check(not seen[item.id] and item.price > 0 and item.price % 1 == 0, "unique catalog items with positive integer prices")
 seen[item.id] = true
end
check(#Config.Themes >= 2 and Config.MinPlayers >= 1 and Config.RoundSize >= 2 and Config.MaxPlayers >= Config.RoundSize, "valid round settings: solo player plus bots")
local Access = require("../src/shared/Access")
check(not Access.canBrowse("Lobby", false) and not Access.canBrowse("Intermission", true), "lounge closed before shopping")
check(not Access.canTry("Lobby", false), "no remote preview from lounge")
check(Access.canBrowse("Shopping", true) and Access.canTry("Shopping", true), "participants may shop")
check(not Access.canBrowse("Shopping", false), "late arrivals stay in lounge")
for _, phase in ipairs({ "Lobby", "Intermission", "Results" }) do
 for _, participating in ipairs({ true, false }) do
  check(Access.mustWait(phase, participating, false), "everyone waits during " .. phase)
 end
end
check(not Access.mustWait("Shopping", true, false), "release participant for shopping")
check(Access.mustWait("Shopping", false, false), "spectator remains in lounge during shopping")
check(not Access.mustWait("Showcase", true, true), "presenter allowed on runway")
check(Access.mustWait("Showcase", true, false), "other participants wait between shows")
check(Access.mustWait("Showcase", false, true), "spectator cannot claim presenter access")
check(Access.mustWait("Results", true, true), "presenter returns to lounge after shows")
local outfit = newPlayer()
Rules.buy(outfit, top)
local before = outfit.budget
local preview = Rules.preview(outfit, Catalog, 1, "rose_top", "sage", Config.Palette)
check(preview.top == "rose_top" and preview.colors.top == "sage", "preview selected shape and colour")
check(next(outfit.looks[1]) == nil and outfit.budget == before, "preview must not mutate look or budget")
check(Rules.equip(outfit, Catalog, 1, "rose_top", "sage", Config.Palette), "equip validated colour")
check(Rules.equip(outfit, Catalog, 2, "rose_top", "black", Config.Palette), "different colour in second look")
check(outfit.looks[1].colors.top == "sage" and outfit.looks[2].colors.top == "black", "colours isolated across looks")
local preview2 = Rules.preview(outfit, Catalog, 1, "black_top", "cream", Config.Palette)
check(preview2.top == "black_top" and outfit.looks[1].top == "rose_top" and outfit.looks[1].colors.top == "sage", "unowned preview preserves saved look")
outfit.saved[1] = true
check(not Rules.equip(outfit, Catalog, 1, "rose_top", "invalid", Config.Palette) and outfit.saved[1], "invalid colour leaves saved look untouched")
check(not Rules.equip(outfit, Catalog, 1, "black_top", "cream", Config.Palette), "preview does not grant ownership")
check(not Rules.preview(outfit, Catalog, 1, "rose_top", {}, Config.Palette), "reject injected colour tables")
check(not Rules.preview(outfit, Catalog, 3, "rose_top", "rose", Config.Palette), "invalid preview slot")
check(Rules.equip(outfit, Catalog, 1, "rose_top", "blue", Config.Palette) and not outfit.saved[1], "colour change requires new save")
check(outfit.budget == before, "colour changes do not charge again")
print("PASS: " .. count .. " gameplay rule assertions")

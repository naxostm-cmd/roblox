-- Pure scoring, rewards and rank titles; shared by server, client and tests.
local Scoring = {}

-- Lifetime stars unlock titles, like rank ladders in fashion games.
Scoring.Ranks = {
	{ 0, "Debiutantka" }, { 15, "Stylowa Nowicjuszka" }, { 40, "Modowa Entuzjastka" },
	{ 80, "Fashionistka" }, { 150, "Trendsetterka" }, { 250, "Stylistka" },
	{ 400, "Ikona Stylu" }, { 650, "Projektantka" }, { 1000, "Supermodelka" }, { 1500, "Królowa Stylu" },
}

function Scoring.rank(stars)
	local index = 1
	for i, entry in ipairs(Scoring.Ranks) do
		if stars >= entry[1] then index = i end
	end
	local nextEntry = Scoring.Ranks[index + 1]
	return index, Scoring.Ranks[index][2], if nextEntry then nextEntry[1] else nil
end

local function mean(votes, eligible)
	local sum, count = 0, 0
	for voter, score in pairs(votes) do
		if eligible == nil or eligible[voter] then sum += score; count += 1 end
	end
	return if count > 0 then sum / count else 0, count
end

-- The jury counts half, so contestants cannot sink a rival with 1-star votes.
function Scoring.show(juryVotes, crowdVotes, eligible)
	local jury, juryCount = mean(juryVotes, nil)
	local crowd, crowdCount = mean(crowdVotes, eligible)
	local score
	if juryCount == 0 then score = crowd
	elseif crowdCount == 0 then score = jury
	else score = (jury + crowd) / 2 end
	return score, jury, crowd, crowdCount
end

function Scoring.final(shows)
	local sum, count = 0, 0
	for _, show in pairs(shows) do sum += show.score; count += 1 end
	return if count > 0 then sum / count else 0
end

local placeStars = { 5, 3, 1 }
local placeCoins = { 100, 60, 30 }
-- Stars feed the ranking ladder; coins buy cosmetics in the boutique.
function Scoring.reward(place, average)
	local stars = math.floor(average * 2 + 0.5) + (placeStars[place] or 0)
	local coins = 20 + stars * 5 + (placeCoins[place] or 0)
	return { stars = stars, coins = coins }
end

function Scoring.starText(score)
	local full = math.floor(score + 0.5)
	return string.rep("★", full) .. string.rep("☆", 5 - full)
end

return Scoring

-- Pure planning for NPC contestants. Purchases still go through Rules on the server.
local BotLogic = {}
local required = { "top", "bottom" }
local extras = { "shoes", "bag", "jewelry", "glasses", "accessory" }

local function shuffle(list, rng)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function byCategory(catalog)
	local groups = {}
	for _, item in ipairs(catalog) do
		groups[item.category] = groups[item.category] or {}
		table.insert(groups[item.category], item)
	end
	return groups
end

-- Returns a store route and the items to wear in each look. Required pieces are
-- planned first with a reserve, so both looks always get a top and a bottom.
function BotLogic.plan(catalog, budget, palette, rng)
	local groups = byCategory(catalog)
	local cheapest = {}
	for category, items in pairs(groups) do
		local low = math.huge
		for _, item in ipairs(items) do low = math.min(low, item.price) end
		cheapest[category] = low
	end
	local left, owned, bought = budget, {}, {}
	local looks = { {}, {} }
	local needs = {}
	for slot = 1, 2 do
		for _, category in ipairs(required) do table.insert(needs, { slot = slot, category = category }) end
	end
	local function reserve(fromIndex)
		local total = 0
		for i = fromIndex, #needs do total += cheapest[needs[i].category] or 0 end
		return total
	end
	local function pick(slot, category, limit)
		local options = {}
		for _, item in ipairs(groups[category] or {}) do
			if not owned[item.id] and item.price <= limit then table.insert(options, item) end
		end
		if #options > 0 then
			local item = options[rng:NextInteger(1, #options)]
			owned[item.id] = true; left -= item.price; table.insert(bought, item)
			looks[slot][category] = { id = item.id, color = palette[rng:NextInteger(1, #palette)].id }
			return true
		end
		-- Re-wearing an owned piece is free and allowed by the rules.
		for _, item in ipairs(bought) do
			if item.category == category then
				looks[slot][category] = { id = item.id, color = palette[rng:NextInteger(1, #palette)].id }
				return true
			end
		end
		return false
	end
	for index, need in ipairs(needs) do
		pick(need.slot, need.category, left - reserve(index + 1))
	end
	for slot = 1, 2 do
		for _, category in ipairs(shuffle(table.clone(extras), rng)) do
			if rng:NextInteger(1, 4) > 1 then pick(slot, category, left) end
		end
	end
	-- Group purchases by store so the NPC visits each unit once.
	local route, stops = {}, {}
	for _, item in ipairs(bought) do
		if not stops[item.store] then
			stops[item.store] = { store = item.store, items = {} }
			table.insert(route, stops[item.store])
		end
		table.insert(stops[item.store].items, item.id)
	end
	-- Stores selling tops/bottoms come first, so the looks are complete early.
	shuffle(route, rng)
	local function essential(stop)
		for _, id in ipairs(stop.items) do
			for _, item in ipairs(bought) do
				if item.id == id and (item.category == "top" or item.category == "bottom") then return true end
			end
		end
		return false
	end
	local ordered = {}
	for _, stop in ipairs(route) do if essential(stop) then table.insert(ordered, stop) end end
	for _, stop in ipairs(route) do if not essential(stop) then table.insert(ordered, stop) end end
	return { route = ordered, looks = looks, spent = budget - left }
end

local function pieces(look)
	local count = 0
	for category in pairs(look or {}) do
		if category ~= "colors" then count += 1 end
	end
	return count
end

-- Simulated, clearly labelled contestant votes (1–5 stars).
function BotLogic.score(saved, look, rng)
	if not saved then return rng:NextInteger(1, 2) end
	return math.min(5, rng:NextInteger(3, 4) + (if pieces(look) >= 5 then 1 else 0))
end

-- Jury NPCs: complete looks with more accessories score higher, plus taste.
function BotLogic.juryScore(saved, look, rng)
	if not saved then return 1 end
	local score = 3 + (if pieces(look) >= 4 then 1 else 0) + (if pieces(look) >= 6 then 1 else 0) + rng:NextInteger(-1, 1)
	return math.clamp(score, 2, 5)
end

local phrases = {
	[5] = { "Absolutnie zachwycające! %s to strzał w dziesiątkę przy temacie „%s”.", "Brak mi słów — %s i cała stylizacja to czysta klasa!", "Tak wygląda królowa stylu. %s skradł(a) mi serce!" },
	[4] = { "Bardzo dobrze! %s wygląda świetnie, brakuje mi tylko jednego dodatku.", "Mocna stylizacja. %s pasuje do tematu „%s”.", "Podoba mi się! %s robi robotę." },
	[3] = { "Poprawnie, ale %s nie do końca pasuje do „%s”.", "Jest nieźle, choć %s mnie nie przekonuje.", "Bezpiecznie. Przy %s można było zaryzykować więcej." },
	[2] = { "Hmm… liczyłam/em na więcej. %s gryzie się z resztą.", "Temat „%s” to chyba coś innego niż %s.", "Za mało odwagi, a %s nie ratuje sytuacji." },
	[1] = { "Niestety, ta stylizacja nie została dokończona.", "Bez zapisanego zestawu trudno cokolwiek ocenić.", "Tym razem nie wyszło — następnym razem będzie lepiej!" },
}

-- A short spoken comment mentioning a real item from the look.
function BotLogic.comment(score, itemName, theme, rng)
	local bank = phrases[math.clamp(score, 1, 5)]
	local line = bank[rng:NextInteger(1, #bank)]
	local first, second = itemName or "ta stylizacja", theme or "dnia"
	if string.find(line, "Temat „%%s”") then first, second = second, first end
	local ok, text = pcall(string.format, line, first, second)
	return if ok then text else line
end

return BotLogic

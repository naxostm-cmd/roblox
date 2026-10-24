-- Pure rules shared with the CLI tests; never trust client prices or inventories.
local Rules = {}
local categories = { top = true, bottom = true, shoes = true, accessory = true }

function Rules.item(catalog, id)
	for _, item in ipairs(catalog) do
		if item.id == id then return item end
	end
	return nil
end

function Rules.buy(data, item)
	if not item then return false, "Nieznany produkt." end
	if data.owned[item.id] then return false, "Ten produkt już masz." end
	if data.budget < item.price then return false, "Za mały budżet." end
	data.budget -= item.price
	data.owned[item.id] = true
	return true, "Kupiono: " .. item.name
end

function Rules.color(palette, key)
	for _, color in ipairs(palette or {}) do if color.id == key then return color end end
	return nil
end

function Rules.preview(data, catalog, slot, id, colorKey, palette)
	if slot ~= 1 and slot ~= 2 then return nil, "Nieprawidłowa stylizacja." end
	local item = Rules.item(catalog, id)
	if not item then return nil, "Nieznany produkt." end
	if colorKey ~= nil and not Rules.color(palette, colorKey) then return nil, "Nieprawidłowy kolor." end
	local look = table.clone(data.looks[slot])
	look.colors = table.clone(look.colors or {})
	look[item.category] = id
	look.colors[item.category] = colorKey or item.colorKey
	return look
end

function Rules.equip(data, catalog, slot, id, colorKey, palette)
	if slot ~= 1 and slot ~= 2 then return false, "Nieprawidłowa stylizacja." end
	local item = Rules.item(catalog, id)
	if not item or not categories[item.category] or not data.owned[id] then
		return false, "Najpierw kup ten produkt."
	end
	local look, message = Rules.preview(data, catalog, slot, id, colorKey, palette)
	if not look then return false, message end
	data.looks[slot] = look
	data.saved[slot] = false
	return true, "Dodano do stylizacji " .. slot
end

function Rules.save(data, slot)
	if slot ~= 1 and slot ~= 2 then return false, "Nieprawidłowa stylizacja." end
	local look = data.looks[slot]
	if not look.top or not look.bottom then return false, "Wybierz przynajmniej górę i dół." end
	data.saved[slot] = true
	return true, "Zapisano stylizację " .. slot
end

function Rules.vote(votes, voterId, targetId, score, eligible)
	if not eligible[voterId] or not eligible[targetId] or voterId == targetId then
		return false, "Nie możesz oceniać tej osoby."
	end
	if type(score) ~= "number" or score ~= score or score % 1 ~= 0 or score < 1 or score > 10 then
		return false, "Ocena musi być liczbą całkowitą 1–10."
	end
	if votes[voterId] then return false, "Głos został już oddany." end
	votes[voterId] = score
	return true, "Głos zapisany."
end

function Rules.average(votes, eligible)
	local sum, count = 0, 0
	for voter, score in pairs(votes) do
		if eligible[voter] then sum += score; count += 1 end
	end
	return if count > 0 then sum / count else 0, count
end

function Rules.rank(entries)
	table.sort(entries, function(a, b)
		if a.score == b.score then return a.userId < b.userId end
		return a.score > b.score
	end)
	local rank, previous = 0, nil
	for index, entry in ipairs(entries) do
		if previous == nil or math.abs(entry.score - previous) > 0.000001 then rank = index end
		entry.rank = rank
		previous = entry.score
	end
	return entries
end
return Rules

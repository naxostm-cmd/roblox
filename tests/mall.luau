local Mall = require("../src/shared/Mall")
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
assert(#Mall.Stores == 20)
local ids, positions, counts = {}, {}, {}
for _, store in ipairs(Mall.Stores) do
 assert(not ids[store.id]); ids[store.id] = store
 local position = tostring(store.x)..":"..tostring(store.z)
 assert(not positions[position]); positions[position] = true
 counts[store.category] = (counts[store.category] or 0) + 1
end
for _, category in ipairs({"top","bottom","shoes","bag","jewelry","glasses","accessory"}) do assert(counts[category], category) end
local seed = 1234
local rng = {NextInteger = function(_, low, high) seed = (seed*16807)%2147483647; return low + seed%(high-low+1) end}
local previous, previousSets = nil, {}
local offeredStyles = {}
for round=1,100 do
 local catalog = Mall.generate(rng,previous,Config.Palette)
 assert(#catalog == 60)
 local seen, sets, minTop, minBottom = {}, {}, math.huge, math.huge
 for _, item in ipairs(catalog) do
  assert(not seen[item.id]); seen[item.id] = true
  assert(ids[item.store].category == item.category, "store specialization")
  assert(item.price > 0 and item.price%1 == 0)
  assert(Rules.color(Config.Palette,item.colorKey))
  sets[item.store] = sets[item.store] or {}; table.insert(sets[item.store],item.id)
  offeredStyles[item.style] = true
  if item.category == "top" then minTop=math.min(minTop,item.price) end
  if item.category == "bottom" then minBottom=math.min(minBottom,item.price) end
 end
 assert(2*(minTop+minBottom) <= Config.Budget, "two basic looks affordable")
 for store, set in pairs(sets) do
  assert(#set == 3); table.sort(set); local signature=table.concat(set,",")
  assert(signature ~= previousSets[store], "store must change stock every round")
  previousSets[store]=signature
 end
 previous=catalog
end
local styles=0; for _ in pairs(offeredStyles) do styles+=1 end
assert(styles == 42, "all 42 designs can appear")
-- Worst case: RNG repeats exactly; selection must still change in every shop.
local fixed = {NextInteger=function(_,low) return low end}
local first = Mall.generate(fixed,nil,Config.Palette)
local second = Mall.generate(fixed,first,Config.Palette)
for _, store in ipairs(Mall.Stores) do
 local different=false
 for _, item in ipairs(second) do if item.store==store.id and not Rules.item(first,item.id) then different=true end end
 assert(different,store.id)
end
local data={budget=10000,owned={},looks={{},{}},saved={false,false}}
local equipped={}
for _, item in ipairs(first) do
 if not equipped[item.category] then
  assert(Rules.buy(data,item))
  assert(Rules.equip(data,first,1,item.id,"blue",Config.Palette))
  equipped[item.category]=true
 end
end
assert(data.looks[1].bag and data.looks[1].jewelry and data.looks[1].glasses and data.looks[1].accessory, "accessory types coexist")
assert(Rules.save(data,1))
local removed
for _, item in ipairs(first) do if not Rules.item(second,item.id) then removed=item; break end end
assert(removed and not Rules.preview(data,second,1,removed.id,"blue",Config.Palette), "old withdrawn offer cannot be previewed from new catalogue")
print("PASS: 100 rounds, 20 stores, 60 offers, 42 designs, fair budget, guaranteed stock changes")

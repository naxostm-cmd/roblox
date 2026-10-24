-- Pure catalogue/assortment rules. One server roll is shared by all players.
local Mall = {}
local definitions = {
 { "rose", "Rose Atelier", "top", "Bluzki i gorsety" }, { "denim", "Studio Denim", "bottom", "Spodnie i spódnice" },
 { "urban", "Urban Muse", "top", "Moda miejska" }, { "sole", "Sole Society", "shoes", "Obuwie" },
 { "silk", "Silk Avenue", "top", "Eleganckie góry" }, { "pleat", "Maison Plissé", "bottom", "Spódnice" },
 { "bags", "Bag Stories", "bag", "Torebki" }, { "gold", "Golden Details", "jewelry", "Biżuteria" },
 { "bloom", "Bloom Studio", "top", "Moda damska" }, { "steps", "City Steps", "shoes", "Obuwie miejskie" },
 { "noir", "Atelier Noir", "top", "Moda wieczorowa" }, { "tailor", "The Tailor", "bottom", "Spodnie i spódnice" },
 { "hats", "Hat Gallery", "accessory", "Nakrycia głowy" }, { "optics", "Vue Optique", "glasses", "Okulary" },
 { "casual", "Everyday Edit", "top", "Moda codzienna" }, { "leather", "Petite Maro", "bag", "Torebki i kopertówki" },
 { "walk", "Velvet Walk", "shoes", "Buty na wyjście" }, { "pearl", "Pearl Room", "jewelry", "Biżuteria" },
 { "hem", "Hemline", "bottom", "Kolekcja dołów" }, { "crown", "Crown & Co", "accessory", "Kapelusze i berety" },
}
-- Two-storey layout: east/west wings, three units per corridor side.
-- Unit centres are shared with World; facing = 1 when the shop front faces +Z.
Mall.Levels = { "Parter", "Piętro 1" }
Mall.Wings = { east = "Skrzydło Różane (wschód)", west = "Skrzydło Złote (zachód)" }
local function unit(wing, level, side, index)
 return { x = (if wing == "east" then 1 else -1) * (28 + index * 28), z = side * 27, level = level, wing = wing, facing = -side }
end
local placement = {
 rose = unit("east", 1, -1, 1), denim = unit("east", 1, 1, 1), silk = unit("east", 1, -1, 2), pleat = unit("east", 1, 1, 2), sole = unit("east", 1, -1, 3), bags = unit("east", 1, 1, 3),
 urban = unit("west", 1, -1, 1), tailor = unit("west", 1, 1, 1), bloom = unit("west", 1, -1, 2), hem = unit("west", 1, 1, 2), steps = unit("west", 1, -1, 3), gold = unit("west", 1, 1, 3),
 noir = unit("east", 2, -1, 1), walk = unit("east", 2, 1, 1), leather = unit("east", 2, -1, 2), hats = unit("east", 2, 1, 2), optics = unit("east", 2, -1, 3),
 casual = unit("west", 2, -1, 1), pearl = unit("west", 2, 1, 1), crown = unit("west", 2, -1, 2),
}
-- Non-trading units make the wings feel like a real mall.
Mall.Decor = {
 { id = "perfume", name = "Lumière", specialty = "Perfumeria", place = unit("east", 2, 1, 3), color = {150,120,190} },
 { id = "beauty", name = "Beauty Bar", specialty = "Kosmetyki", place = unit("west", 2, 1, 2), color = {226,140,150} },
 { id = "books", name = "Słowo", specialty = "Księgarnia", place = unit("west", 2, -1, 3), color = {120,150,120} },
 { id = "tech", name = "Pixel", specialty = "Elektronika", place = unit("west", 2, 1, 3), color = {90,120,170} },
}
Mall.Stores = {}
for i, def in ipairs(definitions) do
 local place = placement[def[1]]
 table.insert(Mall.Stores, { id = def[1], name = def[2], category = def[3], specialty = def[4], number = i,
  x = place.x, z = place.z, level = place.level, wing = place.wing, facing = place.facing,
  color = ({ {202,114,148}, {96,137,167}, {169,123,94}, {207,171,105} })[(i-1)%4+1] })
end
function Mall.where(store)
 return Mall.Levels[store.level] .. " • " .. Mall.Wings[store.wing]
end
-- Real Roblox catalog items: {key, name, price, fallback style, assets[, bundle]}.
-- Most pieces are made by Roblox itself; bags, jewellery and some hats are popular
-- UGC items. The fallback style is the built-in part model (R6 or missing asset).
local function A(id, kind) return { id = id, type = kind } end
local function shoes(left, right) return { A(left, "LeftShoe"), A(right, "RightShoe") } end
local pools = {
 top = {
  { "tie_white", "Bluzka wiązana biała", 220, "blouse", { A(9240752338, "Shirt") } },
  { "tie_blue", "Bluzka wiązana błękitna", 220, "blouse", { A(9174384558, "Shirt") } },
  { "dots", "Bluzka w kropki", 230, "blouse", { A(9620958893, "Shirt") } },
  { "floral", "Koszula w kwiaty", 240, "tunic", { A(9728267998, "Shirt") } },
  { "knit_pink", "Sweter różowy", 210, "hoodie", { A(6984771334, "Sweater") } },
  { "knit_beige", "Sweter beżowy", 200, "hoodie", { A(6984769289, "Sweater") } },
  { "trench", "Trencz biały", 290, "jacket", { A(8648380153, "Jacket") } },
  { "leather", "Ramoneska czarna", 280, "jacket", { A(7192549218, "Jacket") } },
  { "denim", "Kurtka jeansowa", 250, "jacket", { A(8516609675, "Jacket") } },
  { "coat", "Płaszcz łososiowy", 300, "jacket", { A(8516655378, "Jacket") } },
  { "zip", "Bluza zapinana", 190, "hoodie", { A(7192553841, "Jacket") } },
  { "stripes", "T-shirt w paski", 150, "vest", { A(9112483644, "TShirt") } },
 },
 bottom = {
  { "ruffle_white", "Spódnica z falbaną biała", 230, "pleated", { A(9240776381, "DressSkirt") } },
  { "ruffle_red", "Spódnica z falbaną czerwona", 230, "pleated", { A(7192696851, "DressSkirt") } },
  { "chiffon_pink", "Szyfonowa spódnica różowa", 220, "mini", { A(9240772455, "DressSkirt") } },
  { "chiffon_black", "Szyfonowa spódnica czarna", 220, "mini", { A(7192691582, "DressSkirt") } },
  { "tennis", "Spódniczka tenisowa", 180, "pencil", { A(7192690731, "DressSkirt") } },
  { "leather_pants", "Skórzane spodnie białe", 260, "trousers", { A(7192681239, "Pants") } },
  { "cargo", "Bojówki", 200, "widepants", { A(6984740059, "Pants") } },
  { "sweats", "Spodnie dresowe", 160, "trousers", { A(7192664790, "Pants") } },
  { "jean_shorts", "Szorty jeansowe", 150, "shorts", { A(7192687500, "Shorts") } },
  { "bermuda", "Bermudy miętowe", 150, "shorts", { A(9240767370, "Shorts") } },
 },
 shoes = {
  { "flats_black", "Baleriny czarne", 120, "flats", shoes(7193104827, 7193106211), 902 },
  { "flats_beige", "Baleriny beżowe", 120, "flats", shoes(9538147267, 9538149777), 910 },
  { "flats_cheetah", "Baleriny w panterkę", 140, "flats", shoes(7193110577, 7193111520), 897 },
  { "hightop_pink", "Sneakersy różowe metaliczne", 180, "sneakers", shoes(9483490552, 9483495483), 900 },
  { "hightop_gold", "Złote sneakersy", 190, "platforms", shoes(9611957025, 9611959460), 922 },
  { "sneakers_white", "Białe sneakersy", 140, "sneakers", shoes(9482987287, 9482991343), 896 },
  { "canvas_pink", "Trampki różowe", 130, "sneakers", shoes(7192850635, 7192852086), 877 },
  { "boots_beige", "Botki beżowe", 190, "boots", shoes(9542483996, 9542491319), 917 },
  { "dress_black", "Czarne półbuty", 170, "heels", shoes(8044843668, 8044852814), 907 },
  { "running_pink", "Różowe buty sportowe", 150, "sneakers", shoes(8722150843, 8722146746), 915 },
 },
 accessory = {
  { "beret_red", "Czerwony beret", 120, "beret", { A(4623271709, "Hat") } },
  { "beret_black", "Czarny beret", 120, "beret", { A(4420280348, "Hat") } },
  { "beret_classic", "Beret klasyczny", 110, "beret", { A(9471278, "Hat") } },
  { "beret_cat", "Beret z falbanką", 140, "beret", { A(7037682087, "Hat") } },
  { "butterfly_hat", "Kapelusz z motylami", 170, "widehat", { A(4849184439, "Hat") } },
  { "trendy_white", "Biały kapelusz", 150, "bucket", { A(4904907858, "Hat") } },
  { "cowboy_white", "Biały kapelusz kowbojski", 160, "widehat", { A(118590124126030, "Hat") } },
  { "tiara_pink", "Tiara z perłami", 230, "crown", { A(6255878442, "Hat") } },
  { "tiara_white", "Diamentowa tiara", 240, "crown", { A(16236764821, "Hat") } },
 },
 bag = {
  { "shoulder_white", "Biała torebka na ramię", 160, "satchel", { A(5508770029, "Front") } },
  { "shoulder_black", "Czarna torebka na ramię", 160, "satchel", { A(5508780383, "Front") } },
  { "mini_white", "Biała mini torebka", 110, "mini_bag", { A(5548562349, "Front") } },
  { "heart", "Torebka serduszko", 170, "round_bag", { A(8715048013, "Front") } },
  { "handbag", "Elegancka biała torebka", 180, "box_bag", { A(4739789528, "Front") } },
  { "classy_red", "Czerwona torebka klasyczna", 170, "box_bag", { A(6346748082, "Front") } },
  { "tote", "Torba shopper", 140, "tote", { A(6871237205, "Front") } },
  { "clutch", "Biała kopertówka", 130, "clutch", { A(8970143162, "Front") } },
  { "crochet", "Szydełkowa torebka", 150, "tote", { A(18514611032, "Shoulder") } },
 },
 jewelry = {
  { "shell", "Naszyjnik z muszelką", 130, "pendant", { A(376527115, "Neck") } },
  { "butterfly", "Naszyjnik z motylkiem", 140, "pendant", { A(6682341755, "Neck") } },
  { "silver", "Srebrny wisiorek", 130, "pendant", { A(4846578500, "Neck") } },
  { "infinity", "Naszyjnik nieskończoność", 150, "chain", { A(4960940411, "Neck") } },
  { "beads", "Naszyjnik z białych koralików", 140, "pearls", { A(7331163641, "Neck") } },
  { "lace", "Koronkowy choker", 110, "choker", { A(14264800663, "Neck") } },
  { "studs", "Diamentowe kolczyki", 180, "earrings", { A(4508445398, "Hat") } },
  { "hoops", "Kolczyki koła", 120, "earrings", { A(4300266038, "Hat") } },
 },
 glasses = {
  { "aviators", "Aviatory", 160, "aviator", { A(376526673, "Face") } },
  { "orange", "Pomarańczowe okulary", 120, "round", { A(376527500, "Face") } },
  { "nerd", "Okulary kujonki", 100, "square", { A(11884330, "Face") } },
  { "horn", "Oprawki rogowe", 110, "square", { A(22151904, "Face") } },
  { "hipster", "Hipsterskie okulary", 120, "oversized", { A(125369932, "Face") } },
  { "midnight", "Czarne okulary słoneczne", 150, "cat_eye", { A(30331986, "Face") } },
  { "rainbow", "Tęczowe okulary", 140, "oversized", { A(63995305, "Face") } },
  { "moon", "Złote okulary księżyce", 150, "round", { A(6214120785, "Face") } },
 },
}
Mall.Pools = pools
-- Asset ids that failed validation on the server; those items use the part model.
Mall.Unavailable = {}
function Mall.usesCatalog(item)
 if not item.assets then return false end
 for _, asset in ipairs(item.assets) do if Mall.Unavailable[asset.id] then return false end end
 return true
end
function Mall.store(id)
 for _, store in ipairs(Mall.Stores) do if store.id == id then return store end end
 return nil
end
function Mall.generate(rng, previous, palette)
 local catalog = {}
 local old = {}
 for _, item in ipairs(previous or {}) do old[item.id] = true end
 for _, store in ipairs(Mall.Stores) do
  local pool = table.clone(pools[store.category])
  for i = #pool, 2, -1 do local j = rng:NextInteger(1, i); pool[i], pool[j] = pool[j], pool[i] end
  -- Ensure each store changes its selection, even when the random roll repeats.
  local same = true
  for i = 1, 3 do if not old[store.id .. "_" .. pool[i][1]] then same = false end end
  if same then
   for i = 4, #pool do
    if not old[store.id .. "_" .. pool[i][1]] then pool[3], pool[i] = pool[i], pool[3]; break end
   end
  end
  for i = 1, 3 do
   local template = pool[i]; local color = palette[rng:NextInteger(1, #palette)]
   local assets = template[5]
   local thumb = if template[6] then "rbxthumb://type=BundleThumbnail&id=" .. template[6] .. "&w=150&h=150"
    elseif assets then "rbxthumb://type=Asset&id=" .. assets[1].id .. "&w=150&h=150" else nil
   table.insert(catalog, { id = store.id .. "_" .. template[1], key = template[1], name = template[2], style = template[4], category = store.category,
    store = store.id, price = template[3], colorKey = color.id, color = table.clone(color.rgb), assets = assets, thumb = thumb })
  end
 end
 return catalog
end
return Mall

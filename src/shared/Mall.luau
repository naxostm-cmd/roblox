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
Mall.Stores = {}
local rows = { 42, 0, -84, -126, -168, -210, -252, -294, -336, -378 }
for i, def in ipairs(definitions) do
 table.insert(Mall.Stores, { id = def[1], name = def[2], category = def[3], specialty = def[4], number = i,
  x = if i % 2 == 1 then -42 else 42, z = rows[math.ceil(i / 2)], color = ({ {202,114,148}, {96,137,167}, {169,123,94}, {207,171,105} })[(i-1)%4+1] })
end
local pools = {
 top = { {"blouse","Bluzka z kokardą",220}, {"jacket","Żakiet z klapami",280}, {"corset","Gorset wiązany",260}, {"hoodie","Bluza z kapturem",190}, {"vest","Kamizelka",170}, {"tunic","Tunika z paskiem",240} },
 bottom = { {"pleated","Spódnica plisowana",210}, {"mini","Spódnica mini",230}, {"pencil","Spódnica ołówkowa",220}, {"trousers","Spodnie klasyczne",200}, {"widepants","Spodnie palazzo",240}, {"shorts","Szorty",150} },
 shoes = { {"sneakers","Sneakersy",140}, {"boots","Botki",190}, {"heels","Czółenka",200}, {"flats","Baleriny",120}, {"platforms","Platformy",180}, {"tallboots","Kozaki",240} },
 accessory = { {"widehat","Kapelusz z rondem",160}, {"beret","Beret",120}, {"cap","Czapka z daszkiem",100}, {"tophat","Cylinder",180}, {"bucket","Bucket hat",130}, {"crown","Korona",230} },
 bag = { {"tote","Shopperka",140}, {"clutch","Kopertówka",130}, {"satchel","Listonoszka",170}, {"mini_bag","Mini torebka",110}, {"box_bag","Kuferek",180}, {"round_bag","Okrągła torebka",160} },
 jewelry = { {"pearls","Perły",150}, {"pendant","Naszyjnik",130}, {"choker","Choker",110}, {"earrings","Kolczyki",120}, {"brooch","Broszka",100}, {"chain","Łańcuch",180} },
 glasses = { {"square","Kwadratowe oprawki",110}, {"round","Okrągłe okulary",120}, {"cat_eye","Kocie oczy",150}, {"oversized","Duże oprawki",140}, {"slim","Wąskie oprawki",100}, {"aviator","Aviatory",160} },
}
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
   table.insert(catalog, { id = store.id .. "_" .. template[1], name = template[2], style = template[1], category = store.category,
    store = store.id, price = template[3], colorKey = color.id, color = table.clone(color.rgb) })
  end
 end
 return catalog
end
return Mall

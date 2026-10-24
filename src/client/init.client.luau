local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("Config"))
local Mall = require(shared:WaitForChild("Mall"))
local Access = require(shared:WaitForChild("Access"))
local Premium = require(shared:WaitForChild("PremiumCatalog"))
local UiState = require(shared:WaitForChild("UiState"))
local UI = require(script.UI)
local FittingPreview = require(script.FittingPreview)
local Music = require(script.Music)
local C = UI.Colors
local remotes = ReplicatedStorage:WaitForChild("ShoppingQueen")
local request, update = remotes:WaitForChild("Request"), remotes:WaitForChild("Update")
local gui = Instance.new("ScreenGui"); gui.Name = "ShoppingQueenUI"; gui.ResetOnSpawn = false
-- Respect Roblox's safe area, top bar and device cut-outs.
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 10; gui.Parent = player:WaitForChild("PlayerGui")
local root = UI.frame(gui, "SafeArea", UDim2.fromScale(1, 1), nil, C.Panel, 0); root.BackgroundTransparency = 1
local state, slot, category = nil, 1, "store"
local currentStore = "rose"
local fittingItem = nil
local chosenColors = { {}, {} }
local view, opened, detail = "home", false, nil
local modalWidth, short = 800, false
local render, adapt
local categories = { {"store","Ten sklep"}, {"top","👚 Góry"}, {"bottom","👖 Doły"}, {"shoes","👠 Buty"}, {"accessory","👒 Czapki"}, {"bag","👜 Torebki"}, {"jewelry","💍 Biżuteria"}, {"glasses","🕶️ Okulary"}, {"owned","⭐ Moje"} }
local icons = { top = "👚", bottom = "👖", shoes = "👠", accessory = "👒", bag = "👜", jewelry = "💍", glasses = "🕶️" }
local phases = { Lobby = "Poczekalnia", Intermission = "Za chwilę start", Shopping = "Czas na zakupy", Showcase = "Światła, wybieg!", Results = "Wyniki odcinka" }

-- Top HUD: brand, phase, budget, timer, two themes.
local hud = UI.glass(root, "RoundHUD", UDim2.fromOffset(760, 118), UDim2.new(0.5, 0, 0, 10), 20)
hud.AnchorPoint = Vector2.new(0.5, 0)
local brand = UI.frame(hud, "Brand", UDim2.fromOffset(46, 46), UDim2.fromOffset(12, 12), C.White, 14)
UI.gradient(brand, C.Rose, C.Violet, 45)
local crown = UI.motif(brand, "crown", C.White); local crownScale = Instance.new("UIScale"); crownScale.Scale = 0.42; crownScale.Parent = crown
local title = UI.text(hud, "KRÓLOWA STYLU", UDim2.new(1, -300, 0, 26), UDim2.fromOffset(68, 10), 20, C.Text, "title")
local phaseLabel = UI.text(hud, "Łączymy z galerią…", UDim2.new(1, -300, 0, 20), UDim2.fromOffset(68, 36), 14, C.Sub, "strong")
local walletChip = UI.frame(hud, "Wallet", UDim2.fromOffset(118, 46), UDim2.new(1, -224, 0, 12), C.Card, 12); UI.stroke(walletChip, C.Gold, 0.6)
local walletCaption = UI.text(walletChip, "BUDŻET", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 5), 11, C.Gold, "bold"); walletCaption.TextXAlignment = Enum.TextXAlignment.Center
local wallet = UI.text(walletChip, "—", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 19), 19, C.Text, "title"); wallet.TextXAlignment = Enum.TextXAlignment.Center
local timeBox = UI.frame(hud, "Clock", UDim2.fromOffset(94, 46), UDim2.new(1, -104, 0, 12), C.White, 12)
UI.gradient(timeBox, C.Rose, C.Violet, 30)
local timer = UI.text(timeBox, "—:—", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 3), 22, C.White, "title"); timer.TextXAlignment = Enum.TextXAlignment.Center
local clockCaption = UI.text(timeBox, "CZEKAMY", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 29), 10, C.White, "bold"); clockCaption.TextXAlignment = Enum.TextXAlignment.Center
local themeChips = {}
for i = 1, 2 do
	local chip = UI.frame(hud, "Theme" .. i, UDim2.new(0.5, -18, 0, 36), UDim2.new((i - 1) * 0.5, 12, 0, 70), C.Card, 10); UI.stroke(chip)
	local number = UI.badge(chip, tostring(i), UDim2.fromOffset(24, 24), UDim2.fromOffset(6, 6), C.Rose)
	UI.gradient(number, C.White, Color3.fromRGB(230, 200, 255), 0)
	themeChips[i] = { frame = chip, badge = number, text = UI.text(chip, "Temat poznamy za chwilę", UDim2.new(1, -42, 1, 0), UDim2.fromOffset(37, 0), 14, C.Text, "strong") }
end
local progressTrack = UI.frame(hud, "TimeTrack", UDim2.new(1, -28, 0, 4), UDim2.new(0, 14, 1, -7), C.CardHi, 2)
local progress = UI.frame(progressTrack, "TimeLeft", UDim2.fromScale(0, 1), nil, C.White, 2)
UI.gradient(progress, C.Rose, C.Gold, 0)

-- Contestant list: players and bots.
local rosterPanel = UI.glass(root, "Roster", UDim2.fromOffset(230, 60), UDim2.fromOffset(16, 150), 16)
local rosterTitle = UI.text(rosterPanel, "UCZESTNICZKI", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 8), 12, C.Gold, "bold")
local rosterList = UI.text(rosterPanel, "", UDim2.new(1, -24, 1, -34), UDim2.fromOffset(12, 28), 14, C.Text, "strong")
rosterList.TextYAlignment = Enum.TextYAlignment.Top

local shade = Instance.new("TextButton"); shade.Name = "ModalBackdrop"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C.Ink
shade.BackgroundTransparency = 0.45; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 10; shade.Parent = root
local modal = UI.glass(root, "Menu", UDim2.fromOffset(800, 500), nil, 22); modal.Visible = false; modal.Active = true; modal.ZIndex = 20
local accent = UI.frame(modal, "Accent", UDim2.new(1, -40, 0, 3), UDim2.fromOffset(20, 0), C.White, 2); UI.gradient(accent, C.Rose, C.Gold, 0)
local heading = UI.text(modal, "Style Lounge", UDim2.new(1, -90, 0, 34), UDim2.fromOffset(22, 14), 26, C.Text, "title")
local subtitle = UI.text(modal, "TWOJA HISTORIA ZACZYNA SIĘ TUTAJ", UDim2.new(1, -44, 0, 18), UDim2.fromOffset(22, 48), 12, C.Gold, "bold")
local content = Instance.new("ScrollingFrame"); content.Name = "PageContent"; content.BackgroundTransparency = 1; content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(16, 80); content.Size = UDim2.new(1, -32, 1, -94)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.CanvasSize = UDim2.new(); content.ScrollBarThickness = 5; content.ScrollBarImageColor3 = C.Rose; content.Active = true; content.Parent = modal
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 12); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
local dock = UI.glass(root, "Navigation", UDim2.fromOffset(600, 64), UDim2.new(0.5, 0, 1, -10), 20)
dock.AnchorPoint = Vector2.new(0.5, 1); dock.ZIndex = 30
local navEntries = {}

-- Big call to action in the lounge.
local joinCard = UI.frame(root, "JoinRound", UDim2.fromOffset(360, 78), UDim2.new(0.5, 0, 1, -86), C.White, 20)
joinCard.AnchorPoint = Vector2.new(0.5, 1); UI.gradient(joinCard, C.Rose, C.Violet, 15); UI.stroke(joinCard, C.Gold, 0.3, 2)
local joinButton = Instance.new("TextButton"); joinButton.Name = "JoinButton"; joinButton.Size = UDim2.fromScale(1, 1); joinButton.BackgroundTransparency = 1
joinButton.Text = ""; joinButton.ZIndex = 5; joinButton.Parent = joinCard
local joinTitle = UI.text(joinCard, "✨  WEJDŹ DO GRY", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), 22, C.White, "title")
joinTitle.TextXAlignment = Enum.TextXAlignment.Center
local joinSub = UI.text(joinCard, Config.Budget .. " zł • " .. math.floor(Config.ShoppingSeconds / 60) .. " minut • brakujące miejsca zajmą boty", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 44), 14, C.White, "strong")
joinSub.TextXAlignment = Enum.TextXAlignment.Center
local joinScale = Instance.new("UIScale"); joinScale.Parent = joinCard
joinButton.Activated:Connect(function() if state and not state.queued and not state.participating then request:FireServer("Join") end end)

local toast = UI.frame(root, "Notification", UDim2.fromOffset(520, 56), UDim2.new(0.5, 0, 1, -84), C.Panel, 16)
toast.AnchorPoint = Vector2.new(0.5, 1); toast.Visible = false; toast.ZIndex = 40; UI.stroke(toast, C.Rose, 0.3, 1.5)
local toastText = UI.text(toast, "", UDim2.new(1, -28, 1, -12), UDim2.fromOffset(14, 6), 15, C.Text, "strong")
toastText.TextXAlignment = Enum.TextXAlignment.Center
local toastVersion = 0
local function message(text)
	toastVersion += 1; local version = toastVersion
	toastText.Text = text; toast.Visible = true
	task.delay(5, function() if toastVersion == version then toast.Visible = false end end)
end
local function openPage(page)
	if opened and view == page then opened = false else view, opened = page, true end
	detail = nil; render()
end
shade.Activated:Connect(function() opened = false; render() end)
UI.button(modal, "✕", UDim2.fromOffset(38, 38), UDim2.new(1, -54, 0, 16), function() opened = false; render() end, "light")
local navItems = { { "home", "🏠", "SALON" }, { "wardrobe", "🛍️", "SKLEPY" }, { "premium", "✨", "BUTIK +" }, { "help", "📖", "ZASADY" }, { "music", "🔊", "MUZYKA" } }
for i, entry in ipairs(navItems) do
	local page = entry[1]
	local width = 1 / #navItems
	local b = UI.button(dock, "", UDim2.new(width, -8, 0, 50), UDim2.new((i - 1) * width, 4, 0, 7), function()
		if page == "music" then
			local muted = Music.toggle()
			navEntries.music.icon.Text = if muted then "🔇" else "🔊"
			message(if muted then "Muzyka wyciszona" else "Muzyka włączona 🎶")
		elseif page == "wardrobe" and state and (state.phase == "Showcase" or state.phase == "Results") then openPage("round")
		elseif page == "wardrobe" then openPage("directory")
		else openPage(page) end
	end, "light")
	local icon = UI.text(b, entry[2], UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 3), 20, C.Text); icon.TextXAlignment = Enum.TextXAlignment.Center
	local label = UI.text(b, entry[3], UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 28), 11, C.Sub, "bold"); label.TextXAlignment = Enum.TextXAlignment.Center
	local indicator = UI.frame(dock, "Selected", UDim2.new(width, -36, 0, 3), UDim2.new((i - 1) * width, 18, 1, -5), C.White, 2)
	UI.gradient(indicator, C.Rose, C.Gold, 0)
	navEntries[page] = { button = b, indicator = indicator, icon = icon, label = label }
end
local function colorKey(item)
	return chosenColors[slot][item.id] or (state and state.looks[slot][item.category] == item.id and state.looks[slot].colors and state.looks[slot].colors[item.category]) or item.colorKey or "rose"
end
local function paletteColor(key)
	for _, entry in ipairs(Config.Palette) do if entry.id == key then return Color3.fromRGB(table.unpack(entry.rgb)) end end
	return C.Rose
end
-- Real catalog items render on R15 avatars; R6 shows the simplified part model.
local function realItem(item)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return item.assets ~= nil and humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15
end
local function thumbnail(parent, item, size, position)
	local image = Instance.new("ImageLabel"); image.Name = "CatalogThumbnail"; image.BackgroundTransparency = 1
	image.Size = size; image.Position = position or UDim2.new(); image.Image = item.thumb; image.ScaleType = Enum.ScaleType.Fit
	image.Parent = parent
	return image
end
local function act(action, id)
	local color
	for _, item in ipairs((state and state.catalog or {})) do if item.id == id then color = colorKey(item) end end
	request:FireServer(action, { slot = slot, id = id, color = color })
end
local order = 0
local function block(height, color)
	order += 1
	local frame = UI.frame(content, "Section", UDim2.new(1, -8, 0, height), nil, color or C.Card, 16)
	frame.LayoutOrder = order; return frame
end
local function info(titleText, body, height, icon)
	local frame = block(height or 92); UI.stroke(frame)
	local offset = if icon then 58 else 16
	if icon then
		local mark = UI.frame(frame, "Icon", UDim2.fromOffset(34, 34), UDim2.fromOffset(14, 14), C.White, 10)
		UI.gradient(mark, C.Rose, C.Violet, 45)
		local glyph = UI.text(mark, icon, UDim2.fromScale(1, 1), nil, 17, C.White, "title"); glyph.TextXAlignment = Enum.TextXAlignment.Center
	end
	UI.text(frame, titleText, UDim2.new(1, -offset - 14, 0, 24), UDim2.fromOffset(offset, 12), 17, C.Text, "bold")
	UI.text(frame, body, UDim2.new(1, -offset - 14, 1, -44), UDim2.fromOffset(offset, 38), 15, C.Sub)
	return frame
end
local function row(height)
	local frame = block(height); frame.BackgroundTransparency = 1
	return frame
end
local function loungePage()
	heading.Text = "Style Lounge"; subtitle.Text = "TWÓJ MOMENT • TWÓJ STYL • TWOJA SCENA"
	local hero = block(170, C.White); UI.gradient(hero, C.Rose, C.Violet, 20)
	local wide = modalWidth > 560
	UI.badge(hero, "WITAJ W GALERII", UDim2.fromOffset(150, 24), UDim2.fromOffset(18, 16), C.Ink, C.Gold)
	UI.text(hero, "Od pomysłu\ndo wielkiego wejścia.", UDim2.new(if wide then 0.66 else 1, -32, 0, 66), UDim2.fromOffset(18, 46), 26, C.White, "title")
	if state and not state.participating then
		local label = if state.queued then "✓ Zapisano — czekaj na start" else "✨ Wejdź do gry"
		UI.button(hero, label, UDim2.fromOffset(240, 40), UDim2.fromOffset(18, 118), function() request:FireServer("Join") end, "gold")
	else
		UI.text(hero, "Dwa tematy. Jedna królowa stylu.", UDim2.new(1, -32, 0, 24), UDim2.fromOffset(18, 122), 15, C.White, "strong")
	end
	if wide then
		local art = UI.frame(hero, "HeroArt", UDim2.new(0.28, 0, 1, -24), UDim2.new(0.72, -12, 0, 12), C.Ink, 14)
		art.BackgroundTransparency = 0.6
		UI.motif(art, "crown", C.Gold)
	end
	info("Jak zacząć?", "Podejdź do szklanych drzwi salonu i naciśnij E albo kliknij „Wejdź do gry”. Po " .. Config.IntermissionSeconds .. " s trafisz przed galerię — drzwi otworzą się same.", 100, "1")
	info("Grasz sama? Spoko!", "Brakujące miejsca do " .. Config.RoundSize .. " uczestniczek zajmą boty [BOT]. Mają ten sam budżet, robią zakupy i oceniają pokazy.", 100, "2")
	local card = block(90, C.CardHi); UI.stroke(card, C.Gold, 0.6)
	UI.text(card, "Mały dodatek. Wielkie wejście.", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(16, 8), 18, C.Text, "bold")
	UI.button(card, "Odkryj Butik +  →", UDim2.new(1, -32, 0, 38), UDim2.fromOffset(16, 42), function() view, detail = "premium", nil; render() end)
end
local function helpPage()
	heading.Text = "Jak grać?"; subtitle.Text = "MAŁY PRZEWODNIK PO WIELKIM POKAZIE"
	info("Wejście do rundy", "Wystarczy jedna osoba. Wolne miejsca do " .. Config.RoundSize .. " uczestniczek zajmą boty. Przygotuj dwie stylizacje do wylosowanych tematów.", 100, "1")
	info("Zakupy z pomysłem", "Masz " .. Config.Budget .. " zł na obie stylizacje i " .. math.floor(Config.ShoppingSeconds / 60) .. " minut. Galeria ma dwa piętra: ruchome schody są w atrium, schody na końcach skrzydeł.", 100, "2")
	info("Zapisz oba zestawy", "Kup produkt, dodaj go do zestawu 1 lub 2 i zapisz. Każdy zestaw wymaga góry i dołu. Po zmianie zapisz ponownie.", 100, "3")
	info("Twój moment na wybiegu", "Oceń pozostałych w skali 1–10. Nie możesz oceniać siebie. Wygrywa najwyższa średnia z obu pokazów.", 92, "4")
	info("Skróty", "M — Salon • B — Butik + • Esc — zamknij okno", 80, "⌨")
end
local function premiumPage()
	heading.Text = "Butik premium"; subtitle.Text = "KOLEKCJA DODATKÓW • JUŻ WKRÓTCE"
	if detail then
		local product
		for _, candidate in ipairs(Premium) do if candidate.id == detail then product = candidate end end
		if not product then detail = nil; return end
		local back = row(38)
		UI.button(back, "← Cała kolekcja", UDim2.fromOffset(170, 36), nil, function() detail = nil; render() end, "light")
		local color = Color3.fromRGB(table.unpack(product.color))
		local art = block(160, C.White)
		UI.gradient(art, color, color:Lerp(C.Violet, 0.5)); UI.motif(art, product.motif, C.White)
		info(product.name, product.description, 100)
		local notice = info("Wkrótce za Robuxy", "To zapowiedź produktu. Cena nie została ustalona, a płatności nie są jeszcze dostępne. Obejrzenie oferty nic nie kosztuje.", 110)
		UI.stroke(notice, C.Gold, 0.5)
		return
	end
	info("Coś wyjątkowego dla Twojej postaci", "Planowane dodatki kosmetyczne za Robuxy. Poniżej zapowiedzi — produkty nie są jeszcze dostępne do kupienia.", 96, "✦")
	local columns = UiState.columns(modalWidth - 32)
	for index = 1, #Premium, columns do
		local line = row(240)
		for column = 1, columns do
			local product = Premium[index + column - 1]; if not product then break end
			local card = UI.frame(line, "Product_" .. product.id, UDim2.new(1 / columns, -8, 1, 0), UDim2.new((column - 1) / columns, 0, 0, 0), C.Card, 16); UI.stroke(card)
			local color = Color3.fromRGB(table.unpack(product.color))
			local art = UI.frame(card, "Preview", UDim2.new(1, -16, 0, 100), UDim2.fromOffset(8, 8), C.White, 12)
			UI.gradient(art, color, color:Lerp(C.Violet, 0.5)); UI.motif(art, product.motif, C.White)
			UI.badge(art, product.tag, UDim2.fromOffset(56, 22), UDim2.fromOffset(8, 8), C.Ink, C.Gold)
			UI.text(card, product.name, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 114), 20, C.Text, "title")
			UI.text(card, "Wkrótce · Robux", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 144), 14, C.Gold, "strong")
			UI.button(card, "Zobacz zapowiedź  →", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 186), function() detail = product.id; render() end, "light")
		end
	end
end
local function directoryPage()
	heading.Text = "Mapa galerii • 20 butików"; subtitle.Text = "NOWA KOLEKCJA W KAŻDEJ RUNDZIE • WSPÓLNA OFERTA DLA WSZYSTKICH"
	info("Znajdź swój butik", "Parter i piętro łączą ruchome schody w atrium oraz schody w obu skrzydłach. Food court jest na piętrze, od strony północnej.", 100, "🗺")
	local columns = UiState.columns(modalWidth - 32)
	for level = 1, 2 do
		local header = row(28)
		UI.text(header, string.upper(Mall.Levels[level]), UDim2.fromScale(1, 1), nil, 15, C.Gold, "title")
		local list = {}
		for _, store in ipairs(Mall.Stores) do if store.level == level then table.insert(list, store) end end
		for index = 1, #list, columns do
			local line = row(104)
			for column = 1, columns do
				local store = list[index + column - 1]; if not store then break end
				local card = UI.frame(line, "Store_" .. store.id, UDim2.new(1 / columns, -8, 1, 0), UDim2.new((column - 1) / columns, 0, 0, 0), C.Card, 16); UI.stroke(card)
				local color = Color3.fromRGB(table.unpack(store.color))
				local number = UI.frame(card, "Number", UDim2.fromOffset(46, 46), UDim2.fromOffset(12, 12), C.White, 12)
				UI.gradient(number, color, color:Lerp(C.Violet, 0.4), 45)
				local digits = UI.text(number, string.format("%02d", store.number), UDim2.fromScale(1, 1), nil, 17, C.White, "title"); digits.TextXAlignment = Enum.TextXAlignment.Center
				UI.text(card, store.name, UDim2.new(1, -150, 0, 24), UDim2.fromOffset(70, 12), 17, C.Text, "bold")
				UI.text(card, (icons[store.category] or "") .. " " .. store.specialty, UDim2.new(1, -150, 0, 20), UDim2.fromOffset(70, 36), 14, C.Sub)
				UI.text(card, Mall.Wings[store.wing], UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 74), 13, C.Faint)
				UI.button(card, "Oferta →", UDim2.fromOffset(84, 36), UDim2.new(1, -96, 0, 16), function()
					currentStore = store.id; category = "store"; view = "wardrobe"
					for _, item in ipairs(state and state.catalog or {}) do if item.store == store.id then fittingItem = item.id; break end end
					render()
				end, "light")
			end
		end
	end
end
local function wardrobePage()
	if not state or not Access.canBrowse(state.phase, state.participating) then loungePage(); return end
	local store = Mall.store(currentStore)
	heading.Text = if category == "store" then store.name else "Twoja garderoba"
	subtitle.Text = (if category == "store" then string.upper(Mall.where(store)) .. " • " else "") .. "BUDŻET: " .. state.budget .. " ZŁ"
	local slots = row(56)
	for index = 1, 2 do
		local chosen = index
		local b = UI.button(slots, "", UDim2.new(0.5, -5, 0, 54), UDim2.fromScale((index - 1) * 0.5, 0), function() slot = chosen; act("Slot"); render() end, if slot == index then nil else "light")
		local t = UI.text(b, "Zestaw " .. index .. (if state.saved[index] then "  ✓ zapisany" else "  • do zapisu"), UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 6), 15, C.White, "bold")
		t.TextXAlignment = Enum.TextXAlignment.Center
		local themeLabel = UI.text(b, state.themes[index] or "", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 29), 13, if slot == index then C.White else C.Sub)
		themeLabel.TextXAlignment = Enum.TextXAlignment.Center
	end
	local summary = block(58, C.CardHi); UI.stroke(summary, C.Gold, 0.6)
	UI.text(summary, "🎯 " .. (state.themes[slot] or "Twój temat"), UDim2.new(0.6, -22, 1, -8), UDim2.fromOffset(14, 4), 16, C.Text, "bold")
	UI.button(summary, "💾 Zapisz zestaw " .. slot, UDim2.new(0.4, -12, 0, 40), UDim2.new(0.6, 0, 0, 9), function() act("Save") end, "gold")
	local tabColumns = if modalWidth >= 620 then 5 else 3
	local tabs = row(math.ceil(#categories / tabColumns) * 42)
	for index, pair in ipairs(categories) do
		local chosenCategory = pair[1]
		UI.button(tabs, pair[2], UDim2.new(1 / tabColumns, -6, 0, 36), UDim2.new(((index - 1) % tabColumns) / tabColumns, 0, 0, math.floor((index - 1) / tabColumns) * 42), function() category = chosenCategory; render() end, if category == pair[1] then nil else "light")
	end
	local previewItem
	for _, item in ipairs((state and state.catalog or {})) do if item.id == fittingItem then previewItem = item end end
	if previewItem and previewItem.style then
		local fitting = block(290, C.CardHi); UI.stroke(fitting, C.Rose, 0.6)
		local pane = UI.frame(fitting, "AvatarPreview", UDim2.new(0.5, -16, 1, -16), UDim2.fromOffset(8, 8), C.Ink, 14)
		UI.gradient(pane, Color3.fromRGB(70, 44, 84), C.Ink, 90)
		local real = realItem(previewItem)
		local rotate
		if real then
			pane.BackgroundColor3 = C.White; UI.gradient(pane, Color3.fromRGB(255, 244, 250), Color3.fromRGB(226, 210, 240), 90)
			thumbnail(pane, previewItem, UDim2.new(1, -24, 1, -40), UDim2.fromOffset(12, 8))
			UI.badge(pane, "KATALOG ROBLOX", UDim2.fromOffset(130, 24), UDim2.new(0.5, -65, 1, -32), C.Ink, C.Gold)
		else
			rotate = FittingPreview.mount(pane, player.Character, previewItem, paletteColor(colorKey(previewItem)))
			if not rotate then UI.text(pane, "Poczekaj na załadowanie postaci", UDim2.fromScale(1, 1), nil, 14, C.Sub) end
		end
		UI.text(fitting, (icons[previewItem.category] or "") .. " " .. previewItem.name, UDim2.new(0.5, -12, 0, 30), UDim2.new(0.5, 0, 0, 10), 19, C.Text, "title")
		local colorName = "domyślny"
		for _, c in ipairs(Config.Palette) do if c.id == colorKey(previewItem) then colorName = c.name end end
		UI.text(fitting, previewItem.price .. " zł" .. (if real then " • oryginalny kolor" else " • kolor: " .. colorName), UDim2.new(0.5, -12, 0, 22), UDim2.new(0.5, 0, 0, 42), 14, C.Gold, "strong")
		UI.text(fitting, if real then "Prawdziwy przedmiot z katalogu Roblox. Przymierz go — zobaczysz go na swojej postaci." else "Wybierz kolor — zmiana jest bezpłatna", UDim2.new(0.5, -12, 0, if real then 60 else 20), UDim2.new(0.5, 0, 0, 66), 13, C.Sub)
		for i, entry in ipairs(if real then {} else Config.Palette) do
			local selectedColor = entry.id
			local b = Instance.new("TextButton"); b.Name = entry.name
			b.Text = if colorKey(previewItem) == entry.id then "✓" else ""
			b.Size = UDim2.new(1 / 6, -8, 0, 34); b.Position = UDim2.new(0.5 + ((i - 1) % 3) / 6, 0, 0, 92 + math.floor((i - 1) / 3) * 40)
			b.BackgroundColor3 = Color3.fromRGB(table.unpack(entry.rgb)); b.TextColor3 = if entry.id == "black" then C.White else C.Ink
			b.BorderSizePixel = 0; b.TextSize = 20; b.FontFace = UI.Fonts.Title; b.Parent = fitting; UI.corner(b, 10)
			UI.stroke(b, C.White, if colorKey(previewItem) == entry.id then 0 else 0.7, 2)
			b.Activated:Connect(function() chosenColors[slot][previewItem.id] = selectedColor; render() end)
		end
		UI.button(fitting, "👗 Przymierz na postaci", UDim2.new(0.5, -12, 0, 38), UDim2.new(0.5, 0, 0, 180), function() act("Try", previewItem.id) end)
		UI.button(fitting, "Zakończ przymiarkę", UDim2.new(0.5, -12, 0, 34), UDim2.new(0.5, 0, 0, 226), function() act("Slot") end, "light")
		if rotate then
			UI.button(fitting, "↶", UDim2.new(0.25, -12, 0, 32), UDim2.new(0, 12, 1, -44), function() rotate(-1) end, "light")
			UI.button(fitting, "↷", UDim2.new(0.25, -12, 0, 32), UDim2.new(0.25, -4, 1, -44), function() rotate(1) end, "light")
		end
	end
	local items = {}
	for _, item in ipairs((state and state.catalog or {})) do
		if category == item.category or (category == "owned" and state.owned[item.id]) or (category == "store" and item.store == currentStore) then
			table.insert(items, item)
		end
	end
	local columns = UiState.columns(modalWidth - 32)
	for index = 1, #items, columns do
		local line = row(212)
		for column = 1, columns do
			local item = items[index + column - 1]; if not item then break end
			local id = item.id
			local selected, owned = state.looks[slot][item.category] == id, state.owned[id]
			local card = UI.frame(line, "Item_" .. id, UDim2.new(1 / columns, -8, 1, 0), UDim2.new((column - 1) / columns, 0, 0, 0), C.Card, 16)
			UI.stroke(card, if selected then C.Gold elseif owned then C.Green else C.Line, if selected or owned then 0.3 else 0.86, if selected then 2 else 1)
			local tint = paletteColor(colorKey(item))
			local swatch = UI.frame(card, "Swatch", UDim2.fromOffset(64, 64), UDim2.fromOffset(12, 12), C.White, 14)
			if item.thumb then
				UI.gradient(swatch, Color3.fromRGB(255, 244, 250), Color3.fromRGB(226, 210, 240), 90)
				thumbnail(swatch, item, UDim2.new(1, -6, 1, -6), UDim2.fromOffset(3, 3))
			else
				UI.gradient(swatch, tint, tint:Lerp(C.Ink, 0.35), 45)
				local glyph = UI.text(swatch, icons[item.category] or "✦", UDim2.fromScale(1, 1), nil, 30, C.White); glyph.TextXAlignment = Enum.TextXAlignment.Center
			end
			UI.text(card, item.name, UDim2.new(1, -96, 0, 24), UDim2.fromOffset(86, 12), 17, C.Text, "bold")
			local priceChip = UI.frame(card, "Price", UDim2.fromOffset(84, 24), UDim2.fromOffset(86, 40), C.Ink, 8)
			local priceText = UI.text(priceChip, item.price .. " zł", UDim2.fromScale(1, 1), nil, 14, C.Gold, "title"); priceText.TextXAlignment = Enum.TextXAlignment.Center
			local status = if selected then "✓ W ZESTAWIE " .. slot elseif owned then "✓ W GARDEROBIE" else Mall.store(item.store).name
			UI.text(card, status, UDim2.new(1, -96, 0, 18), UDim2.fromOffset(86, 68), 13, if owned then C.Green else C.Sub, "strong")
			UI.button(card, if realItem(item) then "🔍 Podgląd" else "🎨 Fason i kolory", UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 108), function() fittingItem = item.id; content.CanvasPosition = Vector2.zero; render() end, "light")
			if owned then
				UI.button(card, if selected then "Wybrano • dodaj ponownie" else "➕ Dodaj do zestawu " .. slot, UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 156), function() act("Equip", id) end, "gold")
			else
				UI.button(card, "Przymierz", UDim2.new(0.5, -18, 0, 40), UDim2.fromOffset(12, 156), function() act("Try", id) end, "light")
				UI.button(card, "🛒 Kup", UDim2.new(0.5, -18, 0, 40), UDim2.new(0.5, 6, 0, 156), function() act("Buy", id) end)
			end
		end
	end
	if #items == 0 then info("Twoja kolekcja czeka", "Podejdź do butiku i kup pierwsze produkty. Potem znajdziesz je w tej zakładce.", 92, "🛍") end
end
local function roundPage()
	if not state then loungePage(); return end
	if state.phase == "Results" then
		heading.Text = "Gwiazdy tego odcinka"; subtitle.Text = "DWA POKAZY • JEDEN WIELKI FINAŁ"
		for _, entry in ipairs(state.results) do
			local winner = entry.rank == 1
			local card = block(92, if winner then C.White else C.Card)
			if winner then UI.gradient(card, C.Gold, Color3.fromRGB(226, 150, 86), 20) else UI.stroke(card) end
			local medal = if entry.rank == 1 then "👑" elseif entry.rank == 2 then "🥈" elseif entry.rank == 3 then "🥉" else "#" .. entry.rank
			local badge = UI.text(card, medal, UDim2.fromOffset(56, 56), UDim2.fromOffset(12, 18), 30, if winner then C.Ink else C.Text, "title")
			badge.TextXAlignment = Enum.TextXAlignment.Center
			UI.text(card, entry.name .. (if entry.userId == player.UserId then "  (Ty)" else ""), UDim2.new(1, -90, 0, 28), UDim2.fromOffset(76, 12), 20, if winner then C.Ink else C.Text, "title")
			UI.text(card, string.format("%.2f / 10   •   pokazy: %.2f i %.2f   •   głosy: %d", entry.score, entry.first, entry.second, entry.votes), UDim2.new(1, -90, 0, 36), UDim2.fromOffset(76, 44), 14, if winner then C.Ink else C.Sub, "strong")
		end
		info("Oceny botów są symulowane", "Boty oceniają kompletne, zapisane zestawy wyżej. To tryb testowy — prawdziwi gracze oceniają sami.", 92, "🤖")
	elseif state.phase == "Showcase" then
		local name = "Uczestniczka"
		for _, person in ipairs(state.roster) do if person.userId == state.presenter then name = person.name end end
		heading.Text = "Oceń stylizację"; subtitle.Text = string.upper(name) .. " • " .. string.upper(state.themes[state.slot] or "")
		if state.presenter == player.UserId then info("To Twój moment!", "Zaprezentuj stylizację. Pozostali właśnie wystawiają oceny.", 95, "✨")
		elseif not state.participating then info("Miejsce w pierwszym rzędzie", "Oglądasz pokaz. Zagłosujesz, gdy weźmiesz udział w kolejnej rundzie.", 95, "👀")
		elseif state.voted then info("Dziękujemy za ocenę", "Twój głos jest zapisany. Za chwilę kolejna stylizacja.", 95, "✓")
		else
			local legend = row(24)
			UI.text(legend, "1 = słabo   •   10 = zachwycająco", UDim2.fromScale(1, 1), nil, 14, C.Sub, "strong")
			for rowIndex = 0, 1 do
				local line = row(48)
				for column = 1, 5 do
					local score, showId = rowIndex * 5 + column, state.showId
					local b = UI.button(line, tostring(score), UDim2.new(0.2, -6, 0, 46), UDim2.fromScale((column - 1) * 0.2, 0), function() request:FireServer("Vote", { score = score, showId = showId }) end, if score >= 8 then "gold" elseif score >= 5 then nil else "light")
					b.TextSize = 20; b.FontFace = UI.Fonts.Title
				end
			end
		end
	else loungePage() end
end

local renderedView, renderedDetail, renderedPhase, renderedShow, revision = nil, nil, nil, nil, 0
local function rosterText()
	if not state then return "", 0 end
	local lines = {}
	if state.phase == "Lobby" or state.phase == "Intermission" then
		for _, name in ipairs(state.queue or {}) do table.insert(lines, "• " .. name) end
		local missing = math.max(0, (state.roundSize or Config.RoundSize) - #lines)
		if #lines > 0 and missing > 0 then table.insert(lines, "🤖 + " .. missing .. " bot" .. (if missing == 1 then "" else "y")) end
	else
		for _, person in ipairs(state.roster or {}) do
			local marker = if person.userId == state.presenter then "🎤 " elseif person.bot then "🤖 " else "• "
			table.insert(lines, marker .. person.name)
		end
	end
	return table.concat(lines, "\n"), #lines
end
render = function()
	if not adapt then return end
	adapt()
	modal.Visible = opened; shade.Visible = opened and not (view == "round" and state and state.phase == "Showcase")
	for page, entry in pairs(navEntries) do
		local active = opened and (view == page or (page == "wardrobe" and (view == "round" or view == "directory")))
		entry.indicator.Visible = active
		entry.label.TextColor3 = if active then C.Text else C.Sub
	end
	local showing = state and (state.phase == "Showcase" or state.phase == "Results")
	navEntries.wardrobe.icon.Text = if showing then "🎤" else "🛍️"
	navEntries.wardrobe.label.Text = if showing then "OCENY" else "SKLEPY"
	local canJoin = state ~= nil and not state.participating and not opened
	joinCard.Visible = canJoin and not short
	toast.Position = UDim2.new(0.5, 0, 1, if joinCard.Visible then -172 else -84)
	if state then
		joinTitle.Text = if state.queued then "✓  ZAPISANO" else "✨  WEJDŹ DO GRY"
		joinSub.Text = if state.queued then (if state.phase == "Intermission" then "Start za chwilę — przeniesiemy Cię przed galerię" else "Poczekaj na koniec bieżącej rundy")
			else Config.Budget .. " zł • " .. math.floor(Config.ShoppingSeconds / 60) .. " minut • brakujące miejsca zajmą boty"
		local phase = phases[state.phase] or state.phase
		phaseLabel.Text = phase .. (if state.phase == "Shopping" and not state.participating then " • oglądasz z salonu" else "")
		wallet.Text = if state.participating then state.budget .. " zł" else "—"
		walletCaption.Text = if state.participating then "BUDŻET" else "GRACZE: " .. (state.playerCount or 1)
		for i, chip in ipairs(themeChips) do
			chip.text.Text = state.themes[i] or (if i == 1 then "Zapisz się przy drzwiach salonu" else "Temat poznasz po starcie")
			chip.text.TextColor3 = if state.themes[i] then C.Text else C.Sub
		end
		local text, count = rosterText()
		rosterList.Text = text
		rosterTitle.Text = if state.phase == "Lobby" or state.phase == "Intermission" then "ZAPISANI DO RUNDY" else "UCZESTNICZKI"
		rosterPanel.Size = UDim2.fromOffset(230, 40 + count * 19)
		rosterPanel.Visible = count > 0 and not short and not opened
	end
	local resetScroll = renderedView ~= view or renderedDetail ~= detail
		or (view == "round" and state and (renderedPhase ~= state.phase or renderedShow ~= state.showId))
	local oldPosition = content.CanvasPosition
	revision += 1; local currentRevision = revision
	UI.clear(content); order = 0
	if view == "premium" then premiumPage()
	elseif view == "wardrobe" then wardrobePage()
	elseif view == "directory" then directoryPage()
	elseif view == "help" then helpPage()
	elseif view == "round" then roundPage()
	else loungePage() end
	renderedView, renderedDetail = view, detail
	if state then renderedPhase, renderedShow = state.phase, state.showId end
	task.defer(function()
		if revision == currentRevision then content.CanvasPosition = if resetScroll then Vector2.zero else oldPosition end
	end)
end
adapt = function()
	local size = root.AbsoluteSize
	if size.X < 1 or size.Y < 1 then return end
	short = size.Y < 520
	local narrow = size.X < 600
	local hudHeight = if short then 86 else 118
	hud.Size = UDim2.fromOffset(math.min(760, size.X - 24), hudHeight)
	title.TextSize = if narrow then 16 else 20
	title.Size = UDim2.new(1, if narrow then -250 else -300, 0, 26)
	phaseLabel.Size = title.Size; phaseLabel.TextSize = if narrow then 12 else 14
	walletChip.Size = UDim2.fromOffset(if narrow then 92 else 118, if short then 36 else 46)
	walletChip.Position = UDim2.new(1, if narrow then -196 else -224, 0, if short then 8 else 12)
	walletCaption.Visible = not short
	wallet.Position = UDim2.fromOffset(0, if short then 7 else 19); wallet.TextSize = if narrow then 16 else 19
	for _, chip in ipairs(themeChips) do
		chip.frame.Position = UDim2.new(chip.frame.Position.X.Scale, 12, 0, if short then 50 else 70)
		chip.frame.Size = UDim2.new(0.5, -18, 0, if short then 28 else 36)
		chip.badge.Visible = not short
		chip.text.Position = UDim2.fromOffset(if short then 8 else 37, 0); chip.text.Size = UDim2.new(1, if short then -14 else -42, 1, 0)
		chip.text.TextSize = if short or narrow then 12 else 14
	end
	timeBox.Size = UDim2.fromOffset(if narrow then 80 else 94, if short then 36 else 46)
	timeBox.Position = UDim2.new(1, if narrow then -92 else -104, 0, if short then 8 else 12)
	timer.TextSize = if short then 19 else 22; timer.Size = UDim2.new(1, 0, 0, if short then 30 else 26)
	clockCaption.Visible = not short
	rosterPanel.Position = UDim2.fromOffset(16, hudHeight + 22)
	dock.Size = UDim2.fromOffset(math.min(600, size.X - 24), 64)
	toast.Size = UDim2.fromOffset(math.min(520, size.X - 24), 56)
	joinCard.Size = UDim2.fromOffset(math.min(380, size.X - 24), 78)
	local voting = view == "round" and state and state.phase == "Showcase"
	modalWidth = if voting then math.min(380, size.X - 24) else math.min(900, size.X - 24)
	local height = math.min(if voting then 290 else 590, math.max(120, size.Y - hudHeight - 104))
	local top = hudHeight + 22
	if voting and size.X >= 650 then
		modal.Position = UDim2.fromOffset(size.X - modalWidth - 16, top)
	elseif voting then
		modal.Position = UDim2.fromOffset((size.X - modalWidth) / 2, size.Y - 86 - height)
	else modal.Position = UDim2.fromOffset((size.X - modalWidth) / 2, top + math.max(0, (size.Y - top - 86 - height) / 2)) end
	modal.Size = UDim2.fromOffset(modalWidth, height)
	heading.TextSize = if modalWidth < 480 then 21 else 26
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() render() end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then openPage("premium")
	elseif input.KeyCode == Enum.KeyCode.M then openPage("home")
	elseif input.KeyCode == Enum.KeyCode.Escape and opened then opened = false; render() end
end)
local function mood(packet)
	if packet.phase == "Shopping" and packet.participating then return "Shopping" end
	if packet.phase == "Showcase" then return "Showcase" end
	if packet.phase == "Results" then return "Results" end
	return "Lobby"
end
update.OnClientEvent:Connect(function(packet)
	local previous = state
	view, opened = UiState.receive(previous, packet, view, opened)
	state = packet
	Music.setMood(mood(packet))
	if packet.fittingItem then fittingItem = packet.fittingItem end
	if packet.store then
		currentStore = packet.store; category = "store"
		if not packet.fittingItem then for _, item in ipairs(packet.catalog) do if item.store == currentStore then fittingItem = item.id; break end end end
	end
	if not previous or previous.round ~= packet.round then
		slot = 1; chosenColors = { {}, {} }
		if not packet.fittingItem then
			fittingItem = packet.catalog[1] and packet.catalog[1].id
			for _, item in ipairs(packet.catalog) do if item.store == currentStore then fittingItem = item.id; break end end
		end
	end
	if packet.message then message(packet.message) end
	if packet.phase == "Shopping" and (not previous or previous.phase ~= "Shopping") and packet.participating then
		message("Start! Wejdź przez automatyczne drzwi, kup produkty i zapisz dwa zestawy 🛍️")
	end
	if packet.phase == "Showcase" and (not previous or previous.phase ~= "Showcase") then
		-- The runway may be outside the streamed area around the lounge.
		task.spawn(function() pcall(function() player:RequestStreamAroundAsync(packet.stagePosition) end) end)
	end
	local camera = workspace.CurrentCamera
	if camera and previous and previous.phase == "Showcase" and packet.phase ~= "Showcase" then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then camera.CameraSubject = humanoid end
	end
	render()
end)
RunService.RenderStepped:Connect(function()
	if not state then return end
	local left = math.max(0, state.endsAt - workspace:GetServerTimeNow())
	local seconds = math.ceil(left)
	timer.Text = if state.endsAt == 0 then "—:—" else string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
	clockCaption.Text = if state.endsAt == 0 then "CZEKAMY" else "DO KOŃCA"
	timer.TextColor3 = if state.endsAt > 0 and left <= 10 then Color3.fromRGB(255, 230, 120) else C.White
	local duration = ({ Intermission = Config.IntermissionSeconds, Shopping = Config.ShoppingSeconds, Showcase = Config.VotingSeconds, Results = Config.ResultsSeconds })[state.phase]
	progress.Size = UDim2.fromScale(if duration then math.clamp(left / duration, 0, 1) else 0, 1)
	-- Gentle pulse on the join button so it is easy to spot.
	if joinCard.Visible and not state.queued then joinScale.Scale = 1 + 0.025 * math.sin(os.clock() * 4) else joinScale.Scale = 1 end
	-- Reapply after character resets too; the default camera script may reset itself.
	if state.phase == "Showcase" and workspace.CurrentCamera then
		local camera = workspace.CurrentCamera; local stage = state.stagePosition
		camera.CameraType = Enum.CameraType.Scriptable; camera.CFrame = CFrame.lookAt(stage + Vector3.new(0, 3, 17), stage + Vector3.new(0, -1, 0))
	end
end)
render()
request:FireServer("Sync")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("Config"))
local Access = require(shared:WaitForChild("Access"))
local Premium = require(shared:WaitForChild("PremiumCatalog"))
local UiState = require(shared:WaitForChild("UiState"))
local UI = require(script.UI)
local C = UI.Colors
local remotes = ReplicatedStorage:WaitForChild("ShoppingQueen")
local request, update = remotes:WaitForChild("Request"), remotes:WaitForChild("Update")
local gui = Instance.new("ScreenGui"); gui.Name = "ShoppingQueenUI"; gui.ResetOnSpawn = false
-- Respect Roblox's safe area, top bar and device cut-outs.
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 10; gui.Parent = player:WaitForChild("PlayerGui")
local root = UI.frame(gui, "SafeArea", UDim2.fromScale(1, 1), nil, C.Paper, 0); root.BackgroundTransparency = 1
local state, slot, category = nil, 1, "top"
local view, opened, detail = "home", false, nil
local modalWidth, short = 800, false
local render, adapt
local categories = { { "top", "Góra" }, { "bottom", "Dół" }, { "shoes", "Buty" }, { "accessory", "Dodatki" }, { "owned", "Moje" } }
local phases = { Lobby = "Poczekalnia", Intermission = "Za chwilę start", Shopping = "Czas na zakupy", Showcase = "Światła, wybieg!", Results = "Wyniki odcinka" }

local hud = UI.frame(root, "RoundHUD", UDim2.fromOffset(760, 124), UDim2.new(0.5, 0, 0, 10), C.Paper, 18)
hud.AnchorPoint = Vector2.new(0.5, 0); UI.stroke(hud)
local brand = UI.frame(hud, "Brand", UDim2.fromOffset(42, 42), UDim2.fromOffset(12, 12), C.Blush, 12)
local crown = UI.motif(brand, "crown", C.Rose); local crownScale = Instance.new("UIScale"); crownScale.Scale = 0.42; crownScale.Parent = crown
local title = UI.text(hud, "KRÓLOWA STYLU", UDim2.new(1, -176, 0, 24), UDim2.fromOffset(64, 8), 18, C.Ink, true)
local phaseLabel = UI.text(hud, "Łączymy z galerią…", UDim2.new(1, -176, 0, 18), UDim2.fromOffset(64, 32), 12, C.Muted)
local wallet = UI.text(hud, "STYLE LOUNGE", UDim2.new(1, -176, 0, 18), UDim2.fromOffset(64, 50), 12, C.Rose, true)
local timeBox = UI.frame(hud, "Clock", UDim2.fromOffset(88, 51), UDim2.new(1, -100, 0, 11), C.Blush, 12)
local timer = UI.text(timeBox, "—:—", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 3), 23, C.Rose, true); timer.TextXAlignment = Enum.TextXAlignment.Center
local clockCaption = UI.text(timeBox, "CZEKAMY", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 32), 9, C.Rose, true); clockCaption.TextXAlignment = Enum.TextXAlignment.Center
local themeChips = {}
for i = 1, 2 do
 local chip = UI.frame(hud, "Theme" .. i, UDim2.new(0.5, -18, 0, 34), UDim2.new((i - 1) * 0.5, 12, 0, 78), C.White, 9); UI.stroke(chip)
 UI.badge(chip, tostring(i), UDim2.fromOffset(22, 22), UDim2.fromOffset(6, 6))
 themeChips[i] = { frame = chip, text = UI.text(chip, "Temat poznamy za chwilę", UDim2.new(1, -40, 1, 0), UDim2.fromOffset(35, 0), 12, C.Muted) }
end
local progressTrack = UI.frame(hud, "TimeTrack", UDim2.new(1, -26, 0, 3), UDim2.new(0, 13, 1, -5), C.Line, 2)
local progress = UI.frame(progressTrack, "TimeLeft", UDim2.fromScale(0, 1), nil, C.Rose, 2)

local shade = Instance.new("TextButton"); shade.Name = "ModalBackdrop"; shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = C.Ink
shade.BackgroundTransparency = 0.62; shade.Text = ""; shade.AutoButtonColor = false; shade.Visible = false; shade.ZIndex = 10; shade.Parent = root
local modal = UI.frame(root, "Menu", UDim2.fromOffset(800, 500), nil, C.Paper, 20); modal.Visible = false; modal.Active = true; modal.ZIndex = 20; UI.stroke(modal)
local heading = UI.text(modal, "Style Lounge", UDim2.new(1, -80, 0, 30), UDim2.fromOffset(20, 12), 24, C.Ink, true)
local subtitle = UI.text(modal, "TWOJA HISTORIA ZACZYNA SIĘ TUTAJ", UDim2.new(1, -40, 0, 20), UDim2.fromOffset(20, 44), 10, C.Muted, true)
local content = Instance.new("ScrollingFrame"); content.Name = "PageContent"; content.BackgroundTransparency = 1; content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(16, 78); content.Size = UDim2.new(1, -32, 1, -92)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.CanvasSize = UDim2.new(); content.ScrollBarThickness = 4; content.ScrollBarImageColor3 = C.Rose; content.Active = true; content.Parent = modal
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 12); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
local dock = UI.frame(root, "Navigation", UDim2.fromOffset(540, 56), UDim2.new(0.5, 0, 1, -10), C.Paper, 16)
dock.AnchorPoint = Vector2.new(0.5, 1); dock.ZIndex = 30; UI.stroke(dock)
local navEntries = {}
local welcome = UI.frame(root, "LoungeHint", UDim2.fromOffset(270, 96), UDim2.new(0, 16, 1, -82), C.Paper, 16); UI.stroke(welcome)
UI.text(welcome, "Cześć, " .. player.DisplayName .. "!", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 8), 15, C.Ink, true)
UI.text(welcome, "Rozsiądź się. Twój styl zaraz\nznajdzie się w centrum uwagi.", UDim2.new(1, -24, 0, 49), UDim2.fromOffset(12, 34), 12, C.Muted)
local toast = UI.frame(root, "Notification", UDim2.fromOffset(500, 54), UDim2.new(0.5, 0, 1, -80), C.Ink, 14)
toast.AnchorPoint = Vector2.new(0.5, 1); toast.Visible = false; toast.ZIndex = 40
local toastText = UI.text(toast, "", UDim2.new(1, -28, 1, -12), UDim2.fromOffset(14, 6), 13, C.White)
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
UI.button(modal, "×", UDim2.fromOffset(34, 34), UDim2.new(1, -48, 0, 14), function() opened = false; render() end, "light")
for i, entry in ipairs({ { "home", "SALON" }, { "wardrobe", "STYLIZACJE" }, { "premium", "BUTIK +" }, { "help", "ZASADY" } }) do
 local page = entry[1]
 local b = UI.button(dock, entry[2], UDim2.new(0.25, -10, 0, 38), UDim2.new((i - 1) * 0.25, 5, 0, 7), function()
  if page == "wardrobe" and state and (state.phase == "Showcase" or state.phase == "Results") then openPage("round") else openPage(page) end
 end, if page == "premium" then nil else "light")
 local indicator = UI.frame(dock, "Selected", UDim2.new(0.25, -30, 0, 2), UDim2.new((i - 1) * 0.25, 15, 1, -5), C.Rose, 2)
 navEntries[page] = { button = b, indicator = indicator }
end
local function act(action, id) request:FireServer(action, { slot = slot, id = id }) end
local order = 0
local function block(height, color)
 order += 1
 local frame = UI.frame(content, "Section", UDim2.new(1, -6, 0, height), nil, color or C.White, 14)
 frame.LayoutOrder = order; return frame
end
local function info(titleText, body, height)
 local frame = block(height or 90); UI.stroke(frame)
 UI.text(frame, titleText, UDim2.new(1, -28, 0, 25), UDim2.fromOffset(14, 9), 15, C.Ink, true)
 UI.text(frame, body, UDim2.new(1, -28, 1, -39), UDim2.fromOffset(14, 34), 13, C.Muted)
 return frame
end
local function loungePage()
 heading.Text = "Style Lounge"; subtitle.Text = "TWÓJ MOMENT. TWÓJ STYL. TWOJA SCENA."
 local hero = block(152, C.Blush); UI.gradient(hero, C.Blush, Color3.fromRGB(250, 237, 214))
 local wide = modalWidth > 550
 UI.badge(hero, "WITAJ W GALERII", UDim2.fromOffset(142, 24), UDim2.fromOffset(18, 14), C.Rose)
 UI.text(hero, "Od pomysłu\ndo wielkiego wejścia.", UDim2.new(if wide then 0.72 else 1, -32, 0, 62), UDim2.fromOffset(18, 44), 25, C.Ink, true)
 UI.text(hero, "Dwa tematy. Jedna królowa stylu.", UDim2.new(1, -32, 0, 24), UDim2.fromOffset(18, 116), 13, C.Muted)
 if wide then
  local art = UI.frame(hero, "HeroArt", UDim2.new(0.25, 0, 1, -20), UDim2.new(0.75, -10, 0, 10), C.Paper, 14)
  UI.motif(art, "crown", C.Gold)
 end
 local waiting = state and (state.phase == "Lobby" or state.phase == "Intermission")
 info(if waiting then "Zostań chwilę w salonie" else "Galeria żyje modą", if waiting then "Przez szyby widać pasaż. Zajmij miejsce na kanapie — na start rundy przeniesiemy uczestników prosto do sklepów." else "Uczestnicy robią zakupy, a osoby oczekujące odpoczywają w przeszklonym salonie.", 100)
 local card = block(86, C.Ink)
 UI.text(card, "Mały dodatek. Wielkie wejście.", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 7), 17, C.White, true)
 UI.button(card, "Odkryj Butik +  →", UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 42), function() view, detail = "premium", nil; render() end)
end
local function helpPage()
 heading.Text = "Jak grać?"; subtitle.Text = "MAŁY PRZEWODNIK PO WIELKIM POKAZIE"
 info("01 / Dwa tematy", "Runda zaczyna się od " .. Config.MinPlayers .. " osób. Przygotuj dwie stylizacje pasujące do wylosowanych tematów.")
 info("02 / Zakupy z pomysłem", "Masz " .. Config.Budget .. " zł na obie stylizacje i " .. math.floor(Config.ShoppingSeconds / 60) .. " minut. Podejdź do lady i użyj E lub przycisku na ekranie.")
 info("03 / Zapisz oba zestawy", "Kup produkt, wybierz go do zestawu 1 lub 2 i zapisz. Każdy zestaw wymaga góry i dołu. Po zmianie zapisz ponownie.", 100)
 info("04 / Twój moment na wybiegu", "Oceń pozostałych w skali 1–10. Nie możesz oceniać siebie. Wygrywa najwyższa średnia z obu pokazów.")
end
local function premiumPage()
 heading.Text = "Butik premium"; subtitle.Text = "KOLEKCJA DODATKÓW • JUŻ WKRÓTCE"
 if detail then
  local product
  for _, candidate in ipairs(Premium) do if candidate.id == detail then product = candidate end end
  if not product then detail = nil; return end
  local back = block(36); back.BackgroundTransparency = 1
  UI.button(back, "← Cała kolekcja", UDim2.fromOffset(160, 34), nil, function() detail = nil; render() end, "light")
  local art = block(150, Color3.fromRGB(table.unpack(product.color)))
  UI.gradient(art, art.BackgroundColor3, art.BackgroundColor3:Lerp(C.White, 0.5)); UI.motif(art, product.motif, C.White)
  info(product.name, product.description, 100)
  local notice = info("Wkrótce za Robuxy", "To zapowiedź produktu. Cena nie została ustalona, a płatności nie są jeszcze dostępne. Obejrzenie oferty nic nie kosztuje.", 110)
  notice.BackgroundColor3 = C.Blush
  return
 end
 info("Coś wyjątkowego dla Twojej postaci", "Planowane dodatki kosmetyczne za Robuxy. Poniżej zapowiedzi — produkty nie są jeszcze dostępne do kupienia.", 96)
 local columns = UiState.columns(modalWidth - 32)
 for index = 1, #Premium, columns do
  local row = block(232); row.BackgroundTransparency = 1
  for column = 1, columns do
   local product = Premium[index + column - 1]; if not product then break end
   local card = UI.frame(row, "Product_" .. product.id, UDim2.new(1 / columns, -6, 1, 0), UDim2.new((column - 1) / columns, 0, 0, 0), C.White, 14); UI.stroke(card)
   local color = Color3.fromRGB(table.unpack(product.color))
   local art = UI.frame(card, "Preview", UDim2.new(1, -16, 0, 96), UDim2.fromOffset(8, 8), color, 10)
   UI.gradient(art, color, color:Lerp(C.White, 0.45)); UI.motif(art, product.motif, C.White)
   UI.badge(art, product.tag, UDim2.fromOffset(54, 20), UDim2.fromOffset(8, 8), C.Ink)
   UI.text(card, product.name, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 110), 20, C.Ink, true)
   UI.text(card, "Wkrótce · Robux", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 139), 12, C.Muted)
   UI.button(card, "Zobacz zapowiedź  →", UDim2.new(1, -24, 0, 38), UDim2.fromOffset(12, 180), function() detail = product.id; render() end, "light")
  end
 end
end
local function wardrobePage()
 if not state or not Access.canBrowse(state.phase, state.participating) then loungePage(); return end
 heading.Text = "Twoja garderoba"; subtitle.Text = "BUDŻET RUNDY: " .. state.budget .. " ZŁ • ZAPISZ OBIE STYLIZACJE"
 local slots = block(46); slots.BackgroundTransparency = 1
 for index = 1, 2 do
  local chosen = index
  UI.button(slots, (if slot == index then "• " else "") .. "Zestaw " .. index .. (if state.saved[index] then " / zapisany" else " / do zapisu"), UDim2.new(0.5, -4, 0, 42), UDim2.fromScale((index - 1) * 0.5, 0), function() slot = chosen; act("Slot"); render() end, if slot == index then nil else "light")
 end
 local chosenTheme = state.themes[slot] or "Twój temat"
 local summary = block(60, C.Blush)
 UI.text(summary, chosenTheme, UDim2.new(0.62, -22, 1, -8), UDim2.fromOffset(12, 4), 15, C.Rose, true)
 UI.button(summary, "Zapisz zestaw " .. slot, UDim2.new(0.38, -10, 0, 40), UDim2.new(0.62, 0, 0, 10), function() act("Save") end)
 local tabs = block(36); tabs.BackgroundTransparency = 1
 for index, pair in ipairs(categories) do
  local chosenCategory = pair[1]
  UI.button(tabs, pair[2], UDim2.new(0.2, -4, 0, 34), UDim2.fromScale((index - 1) * 0.2, 0), function() category = chosenCategory; render() end, if category == pair[1] then nil else "light")
 end
 local count = 0
 for _, item in ipairs(Config.Catalog) do
  if category ~= item.category and not (category == "owned" and state.owned[item.id]) then continue end
  count += 1
  local id = item.id
  local selected, owned = state.looks[slot][item.category] == id, state.owned[id]
  local card = block(126); UI.stroke(card)
  local swatch = UI.frame(card, "Swatch", UDim2.fromOffset(40, 40), UDim2.fromOffset(12, 12), Color3.fromRGB(table.unpack(item.color)), 10)
  UI.gradient(swatch, swatch.BackgroundColor3, swatch.BackgroundColor3:Lerp(C.White, 0.3))
  UI.text(card, item.name, UDim2.new(1, -76, 0, 24), UDim2.fromOffset(64, 10), 16, C.Ink, true)
  UI.text(card, if selected then "W TWOIM ZESTAWIE" elseif owned then "W TWOJEJ GARDEROBIE" else item.price .. " zł / budżet rundy", UDim2.new(1, -76, 0, 22), UDim2.fromOffset(64, 34), 11, if owned then C.Green else C.Muted)
  if owned then
   UI.button(card, if selected then "Wybrano / wybierz ponownie" else "Dodaj do zestawu " .. slot, UDim2.new(1, -24, 0, 38), UDim2.fromOffset(12, 74), function() act("Equip", id) end, "light")
  else
   UI.button(card, "Przymierz", UDim2.new(0.5, -18, 0, 38), UDim2.fromOffset(12, 74), function() act("Try", id) end, "light")
   UI.button(card, "Kup / " .. item.price .. " zł", UDim2.new(0.5, -18, 0, 38), UDim2.new(0.5, 6, 0, 74), function() act("Buy", id) end)
  end
 end
 if count == 0 then info("Twoja kolekcja czeka", "Podejdź do butiku i kup pierwsze produkty. Potem znajdziesz je w tej zakładce.") end
end
local function roundPage()
 if not state then loungePage(); return end
 if state.phase == "Results" then
  heading.Text = "Gwiazdy tego odcinka"; subtitle.Text = "DWA POKAZY • JEDEN WIELKI FINAŁ"
  for _, entry in ipairs(state.results) do
   local card = block(90, if entry.rank == 1 then C.Blush else C.White); UI.stroke(card)
   UI.badge(card, string.format("#%d", entry.rank), UDim2.fromOffset(44, 44), UDim2.fromOffset(12, 20), if entry.rank == 1 then C.Gold else C.Rose)
   UI.text(card, entry.name, UDim2.new(1, -84, 0, 27), UDim2.fromOffset(68, 10), 18, C.Ink, true)
   UI.text(card, string.format("%.2f / 10   •   Pokazy: %.2f i %.2f   •   Głosy: %d", entry.score, entry.first, entry.second, entry.votes), UDim2.new(1, -84, 0, 42), UDim2.fromOffset(68, 38), 12, C.Muted)
  end
 elseif state.phase == "Showcase" then
  local name = "Uczestniczka"
  for _, person in ipairs(state.roster) do if person.userId == state.presenter then name = person.name end end
  heading.Text = "Oceń stylizację"; subtitle.Text = name .. " • " .. (state.themes[state.slot] or "")
  if state.presenter == player.UserId then info("To Twój moment!", "Zaprezentuj stylizację. Pozostali właśnie wystawiają oceny.", 95)
  elseif not state.participating then info("Miejsce w pierwszym rzędzie", "Oglądasz pokaz. Zagłosujesz, gdy weźmiesz udział w kolejnej rundzie.", 95)
  elseif state.voted then info("Dziękujemy za ocenę", "Twój głos jest zapisany. Za chwilę kolejna stylizacja.", 95)
  else
   local legend = block(34); legend.BackgroundTransparency = 1
   UI.text(legend, "1 = słabo   •   10 = zachwycająco", UDim2.fromScale(1, 1), nil, 12, C.Muted)
   for rowIndex = 0, 1 do
    local row = block(45); row.BackgroundTransparency = 1
    for column = 1, 5 do
     local score, showId = rowIndex * 5 + column, state.showId
     UI.button(row, tostring(score), UDim2.new(0.2, -6, 0, 42), UDim2.fromScale((column - 1) * 0.2, 0), function() request:FireServer("Vote", { score = score, showId = showId }) end, if score >= 8 then nil else "light")
    end
   end
  end
 else loungePage() end
end

local renderedView, renderedDetail, renderedPhase, renderedShow, revision = nil, nil, nil, nil, 0
render = function()
 if not adapt then return end
 adapt()
 modal.Visible = opened; shade.Visible = opened and not (view == "round" and state and state.phase == "Showcase")
 welcome.Visible = not opened and state ~= nil and (state.phase == "Lobby" or state.phase == "Intermission") and not short
 for page, entry in pairs(navEntries) do entry.indicator.Visible = opened and (view == page or (page == "wardrobe" and view == "round")) end
 navEntries.wardrobe.button.Text = if state and (state.phase == "Showcase" or state.phase == "Results") then "POKAZ / OCENY" else "STYLIZACJE"
 if state then
  local phase = phases[state.phase] or state.phase
  phaseLabel.Text = phase .. (if short and state.participating then " / " .. state.budget .. " zł" else "")
  wallet.Text = if state.participating then "BUDŻET RUNDY  /  " .. state.budget .. " zł" else "STYLE LOUNGE  /  " .. (state.playerCount or 1) .. " graczy"
  for i, chip in ipairs(themeChips) do
   chip.text.Text = state.themes[i] or (if i == 1 then "Czekamy na " .. Config.MinPlayers .. " osoby" else "Wejście po starcie rundy")
  end
 end
 local resetScroll = renderedView ~= view or renderedDetail ~= detail
  or (view == "round" and state and (renderedPhase ~= state.phase or renderedShow ~= state.showId))
 local oldPosition = content.CanvasPosition
 revision += 1; local currentRevision = revision
 UI.clear(content); order = 0
 if view == "premium" then premiumPage()
 elseif view == "wardrobe" then wardrobePage()
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
 local hudHeight = if short then 84 else 124
 hud.Size = UDim2.fromOffset(math.min(760, size.X - 24), hudHeight)
 title.TextSize = if size.X < 500 then 15 else 18
 wallet.Visible = not short
 for _, chip in ipairs(themeChips) do
  chip.frame.Position = UDim2.new(chip.frame.Position.X.Scale, 12, 0, if short then 51 else 78)
  chip.frame.Size = UDim2.new(0.5, -18, 0, if short then 26 else 34)
  local badge = chip.frame:FindFirstChild("Badge"); badge.Visible = not short
  chip.text.Position = UDim2.fromOffset(if short then 6 else 35, 0); chip.text.Size = UDim2.new(1, if short then -12 else -40, 1, 0)
  chip.text.TextSize = if short then 10 else 12
 end
 timeBox.Size = UDim2.fromOffset(88, if short then 35 else 51)
 timer.TextSize = if short then 19 else 23; timer.Size = UDim2.new(1, 0, 0, if short then 27 else 30)
 clockCaption.Visible = not short
 dock.Size = UDim2.fromOffset(math.min(540, size.X - 24), 56)
 toast.Size = UDim2.fromOffset(math.min(500, size.X - 24), 54)
 local voting = view == "round" and state and state.phase == "Showcase"
 modalWidth = if voting then math.min(360, size.X - 24) else math.min(900, size.X - 24)
 local height = math.min(if voting then 270 else 570, math.max(110, size.Y - hudHeight - 98))
 local top = hudHeight + 22
 if voting and size.X >= 650 then
  modal.Position = UDim2.fromOffset(size.X - modalWidth - 16, top)
 elseif voting then
  modal.Position = UDim2.fromOffset((size.X - modalWidth) / 2, size.Y - 80 - height)
 else modal.Position = UDim2.fromOffset((size.X - modalWidth) / 2, top + math.max(0, (size.Y - top - 80 - height) / 2)) end
 modal.Size = UDim2.fromOffset(modalWidth, height)
 heading.TextSize = if modalWidth < 480 then 20 else 24
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() render() end)
UserInputService.InputBegan:Connect(function(input, processed)
 if processed then return end
 if input.KeyCode == Enum.KeyCode.B then openPage("premium")
 elseif input.KeyCode == Enum.KeyCode.M then openPage("home")
 elseif input.KeyCode == Enum.KeyCode.Escape and opened then opened = false; render() end
end)
update.OnClientEvent:Connect(function(packet)
 local previous = state
 view, opened = UiState.receive(previous, packet, view, opened)
 state = packet
 if packet.store then category = packet.store end
 if not previous or previous.round ~= packet.round then slot = 1 end
 if packet.message then message(packet.message) end
 if packet.phase == "Shopping" and (not previous or previous.phase ~= "Shopping") and packet.participating then
  message("Twój moment! Wejdź do butików, kup produkty i zapisz dwa zestawy.")
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
 timer.TextColor3 = if state.endsAt > 0 and left <= 10 then Color3.fromRGB(181, 48, 71) else C.Rose
 local duration = ({ Intermission = Config.IntermissionSeconds, Shopping = Config.ShoppingSeconds, Showcase = Config.VotingSeconds, Results = Config.ResultsSeconds })[state.phase]
 progress.Size = UDim2.fromScale(if duration then math.clamp(left / duration, 0, 1) else 0, 1)
 -- Reapply after character resets too; the default camera script may reset itself.
 if state.phase == "Showcase" and workspace.CurrentCamera then
  local camera = workspace.CurrentCamera; local stage = state.stagePosition
  camera.CameraType = Enum.CameraType.Scriptable; camera.CFrame = CFrame.lookAt(stage + Vector3.new(0, 3, 17), stage + Vector3.new(0, -1, 0))
 end
end)
render()
request:FireServer("Sync")

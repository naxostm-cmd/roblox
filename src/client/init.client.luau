local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("ShoppingQueen")
local request, update = remotes:WaitForChild("Request"), remotes:WaitForChild("Update")
local gui = Instance.new("ScreenGui"); gui.Name = "ShoppingQueenUI"; gui.ResetOnSpawn = false; gui.Parent = player:WaitForChild("PlayerGui")
local bg, ink, accent = Color3.fromRGB(34, 25, 46), Color3.fromRGB(252, 240, 249), Color3.fromRGB(164, 62, 112)
local state, slot, category, opened = nil, 1, "top", false
local categories = { { "top", "Góra" }, { "bottom", "Dół" }, { "shoes", "Buty" }, { "accessory", "Dodatki" }, { "owned", "Garderoba" } }

local function label(parent, text, size, position)
	local l = Instance.new("TextLabel"); l.Size = size; l.Position = position or UDim2.new()
	l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = ink; l.TextSize = 16; l.Font = Enum.Font.Gotham
	l.TextWrapped = true; l.Parent = parent; return l
end

local function button(parent, text, size, position, callback)
	local b = Instance.new("TextButton"); b.Size = size; b.Position = position or UDim2.new()
	b.Text = text; b.BackgroundColor3 = accent; b.TextColor3 = ink; b.TextSize = 15; b.Font = Enum.Font.GothamBold; b.TextWrapped = true
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = b
	b.Parent = parent; b.Activated:Connect(callback); return b
end

local hud = Instance.new("Frame"); hud.Size = UDim2.new(1, -16, 0, 126); hud.Position = UDim2.fromOffset(8, 8); hud.BackgroundColor3 = bg; hud.Parent = gui
local title = label(hud, "KRÓLOWA STYLU", UDim2.new(0.72, 0, 0, 30))
title.Font = Enum.Font.GothamBold
local timer = label(hud, "", UDim2.new(0.28, 0, 0, 30), UDim2.fromScale(0.72, 0))
local themes = label(hud, "Czekamy na graczy…", UDim2.new(1, -16, 0, 48), UDim2.fromOffset(8, 30))
local wallet = label(hud, "", UDim2.new(0.55, 0, 0, 40), UDim2.fromOffset(0, 80))
local panel = Instance.new("Frame"); panel.Name = "Wardrobe"; panel.Size = UDim2.new(0.94, 0, 0.68, 0); panel.Position = UDim2.fromScale(0.5, 0.62); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.BackgroundColor3 = bg; panel.Visible = false; panel.Parent = gui
local constraint = Instance.new("UISizeConstraint"); constraint.MaxSize = Vector2.new(900, 650); constraint.Parent = panel
local heading = label(panel, "Zakupy i garderoba", UDim2.new(1, -65, 0, 34))
local content = Instance.new("ScrollingFrame"); content.Size = UDim2.new(1, -16, 1, -135); content.Position = UDim2.fromOffset(8, 130); content.BackgroundTransparency = 1; content.BorderSizePixel = 0; content.ScrollBarThickness = 6; content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.CanvasSize = UDim2.new(); content.Parent = panel
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 8); layout.Parent = content
local controls = Instance.new("Frame"); controls.Size = UDim2.new(1, -16, 0, 88); controls.Position = UDim2.fromOffset(8, 36); controls.BackgroundTransparency = 1; controls.Parent = panel
local toast = label(gui, "", UDim2.new(0.94, 0, 0, 54), UDim2.fromScale(0.03, 0.92)); toast.BackgroundColor3 = bg; toast.Visible = false; toast.ZIndex = 5
local toastVersion = 0
local function message(text)
	toastVersion += 1; local version = toastVersion
	toast.Text = text; toast.Visible = true
	task.delay(5, function() if toastVersion == version then toast.Visible = false end end)
end

local render
button(hud, "Sklepy / garderoba", UDim2.new(0.43, 0, 0, 34), UDim2.new(0.56, 0, 0, 84), function()
	opened = not opened; render()
end)
button(panel, "×", UDim2.fromOffset(44, 30), UDim2.new(1, -48, 0, 2), function() opened = false; render() end)

local function act(action, id)
	request:FireServer(action, { slot = slot, id = id })
end

local function clear(parent)
	for _, child in ipairs(parent:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end

local function row(text, height)
	local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, -8, 0, height or 88); frame.BackgroundColor3 = Color3.fromRGB(53, 39, 67); frame.Parent = content
	label(frame, text, UDim2.new(1, -12, 0, 40), UDim2.fromOffset(6, 0))
	return frame
end

render = function()
	if not state then return end
	panel.Visible = opened
	clear(controls); clear(content)
	local phases = { Lobby = "Poczekalnia", Intermission = "Za chwilę start", Shopping = "Zakupy", Showcase = "Pokaz i oceny", Results = "Wyniki" }
	title.Text = "KRÓLOWA STYLU • " .. (phases[state.phase] or state.phase)
	themes.Text = if #state.themes == 2 then "1. " .. state.themes[1] .. "   |   2. " .. state.themes[2] else "Potrzeba co najmniej " .. Config.MinPlayers .. " osób."
	wallet.Text = if state.participating then "Budżet: " .. state.budget .. " zł" else "Obserwujesz • czekaj na rundę"
	if state.phase == "Shopping" and state.participating then
		heading.Text = "Wybierz zestaw • kupione produkty można użyć w obu stylizacjach"
		for index = 1, 2 do
			local selected = index
			local text = (if index == slot then "▶ " else "") .. "Zestaw " .. index .. (if state.saved[index] then " ✓" else " • niezapisany")
			button(controls, text, UDim2.new(0.32, -4, 0, 38), UDim2.fromScale((index - 1) * 0.33, 0), function() slot = selected; act("Slot"); render() end)
		end
		button(controls, "Zapisz zestaw " .. slot, UDim2.new(0.34, -4, 0, 38), UDim2.fromScale(0.66, 0), function() act("Save") end)
		for index, pair in ipairs(categories) do
			local selectedCategory = pair[1]
			button(controls, (if category == pair[1] then "• " else "") .. pair[2], UDim2.new(0.2, -4, 0, 36), UDim2.new((index - 1) * 0.2, 0, 0, 46), function() category = selectedCategory; render() end)
		end
		row("Podejdź do stoiska, aby kupować i przymierzać. Garderoba działa wszędzie. Po zmianie zestawu zapisz go ponownie.", 52)
		for _, item in ipairs(Config.Catalog) do
			if category ~= item.category and not (category == "owned" and state.owned[item.id]) then continue end
			local selected = state.looks[slot][item.category] == item.id
			local card = row(item.name .. " • " .. item.price .. " zł" .. (if selected then " • WYBRANO" elseif state.owned[item.id] then " • kupione" else ""))
			local id = item.id
			if not state.owned[id] then
				button(card, "Przymierz", UDim2.new(0.48, -8, 0, 36), UDim2.new(0, 6, 0, 44), function() act("Try", id) end)
				button(card, "Kup", UDim2.new(0.48, -8, 0, 36), UDim2.new(0.5, 0, 0, 44), function() act("Buy", id) end)
			else
				button(card, "Wybierz do zestawu " .. slot, UDim2.new(1, -12, 0, 36), UDim2.fromOffset(6, 44), function() act("Equip", id) end)
			end
		end
	elseif state.phase == "Showcase" then
		local name = "Uczestniczka"
		for _, person in ipairs(state.roster) do if person.userId == state.presenter then name = person.name end end
		heading.Text = name .. " • " .. (state.themes[state.slot] or "")
		if state.presenter == player.UserId then row("Twój pokaz! Pozostali oceniają Twoją stylizację.", 60)
		elseif not state.participating then row("Obserwujesz pokaz. Zagłosujesz, gdy weźmiesz udział w następnej rundzie.", 60)
		elseif state.voted then row("Dziękujemy! Twój głos został zapisany.", 60)
		else
			row("Oceń dopasowanie do tematu i pomysłowość. 1 = najniższa, 10 = najwyższa ocena.", 60)
			for score = 1, 10 do
				local value, showId = score, state.showId
				local card = row("", 42)
				button(card, tostring(score) .. " / 10", UDim2.new(1, -12, 1, -4), UDim2.fromOffset(6, 2), function()
					request:FireServer("Vote", { score = value, showId = showId })
				end)
			end
		end
	elseif state.phase == "Results" then
		heading.Text = "Wyniki • wspólne miejsce przy remisie"
		row("Wynik to średnia ocen z obu pokazów. Brak głosów w pokazie = 0 punktów.", 55)
		for _, entry in ipairs(state.results) do
			row(string.format("%d. %s • %.2f / 10\nTemat 1: %.2f | Temat 2: %.2f | Głosy: %d", entry.rank, entry.name, entry.score, entry.first, entry.second, entry.votes), 68)
		end
	else
		heading.Text = "Witaj w Królowej Stylu"
		row("Dwa tematy. " .. Config.Budget .. " zł na całą rundę. " .. math.floor(Config.ShoppingSeconds / 60) .. " minut zakupów. Zapisz dwa zestawy, a potem oceń pozostałych!", 90)
		row("Ubrania w prototypie to kolory ciała i proste dodatki. Zakupy używają wyłącznie waluty rundy, bez Robuxów.", 80)
	end
end

update.OnClientEvent:Connect(function(packet)
	local previous = state
	state = packet
	if packet.message then message(packet.message) end
	if packet.store then category = packet.store; opened = true end
	if not previous or previous.phase ~= packet.phase then
		opened = packet.phase == "Showcase" or packet.phase == "Results"
		if packet.phase == "Shopping" then slot = 1; message("Podejdź do sklepu i naciśnij E. Zapisz oba zestawy przed końcem czasu!") end
	end
	if packet.phase == "Showcase" and (not previous or previous.showId ~= packet.showId) then opened = true end
	local camera = workspace.CurrentCamera
	if camera then
		if packet.phase == "Showcase" then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(Vector3.new(0, 8, -57), Vector3.new(0, 4, -40))
		elseif previous and previous.phase == "Showcase" then
			camera.CameraType = Enum.CameraType.Custom
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then camera.CameraSubject = humanoid end
		end
	end
	render()
end)
RunService.RenderStepped:Connect(function()
	if not state then return end
	local left = math.max(0, math.ceil(state.endsAt - workspace:GetServerTimeNow()))
	timer.Text = if state.endsAt == 0 then "Czekamy…" else string.format("%02d:%02d", math.floor(left / 60), left % 60)
end)
request:FireServer("Sync")

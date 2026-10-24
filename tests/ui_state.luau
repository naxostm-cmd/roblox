local UiState = require("../src/shared/UiState")
local checks = 0
local function route(previous, packet, view, opened, expectedView, expectedOpened)
	local nextView, nextOpened = UiState.receive(previous, packet, view, opened)
	checks += 1
	assert(nextView == expectedView and nextOpened == expectedOpened, "unexpected UI route in " .. packet.phase)
end
local lobby = { phase = "Lobby" }
local shopping = { phase = "Shopping", participating = true }
local show = { phase = "Showcase", showId = 1 }
local results = { phase = "Results" }
route(nil, lobby, "home", false, "home", false)
route(nil, lobby, "premium", true, "premium", true)
route(lobby, shopping, "premium", true, "premium", true)
route(shopping, shopping, "premium", true, "premium", true)
route(shopping, shopping, "wardrobe", true, "wardrobe", true)
route(shopping, { phase = "Shopping", participating = true, store = "top" }, "premium", true, "wardrobe", true)
route(shopping, { phase = "Shopping", participating = false, store = "top" }, "premium", true, "premium", true)
route(lobby, { phase = "Lobby", store = "top" }, "home", false, "home", false)
route(shopping, show, "premium", true, "round", true)
route(show, show, "premium", true, "premium", true)
route(show, show, "round", false, "round", false)
route(show, { phase = "Showcase", showId = 2 }, "premium", true, "round", true)
route(show, results, "premium", false, "round", true)
route(results, lobby, "round", true, "home", false)
route(shopping, lobby, "wardrobe", true, "wardrobe", false)
route(shopping, lobby, "help", true, "help", true)
print("PASS: " .. checks .. " UI navigation scenarios")

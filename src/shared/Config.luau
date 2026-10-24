local Config = {
	MinPlayers = 2,
	MaxPlayers = 8,
	Budget = 1500,
	IntermissionSeconds = 15,
	ShoppingSeconds = 480,
	VotingSeconds = 15,
	ResultsSeconds = 20,
	StoreDistance = 24,
	Themes = { "Randka w Paryżu", "Elegancki biznes", "Impreza na plaży", "Wesele glamour", "Jesienna stylizacja", "Czerwony dywan" },
	-- Prototype visuals: body colours and generated accessories, without paid/catalog purchases.
	Catalog = {
		{ id = "rose_top", name = "Różowy top", category = "top", price = 220, color = { 244, 119, 170 } },
		{ id = "black_top", name = "Czarna elegancja", category = "top", price = 280, color = { 30, 29, 43 } },
		{ id = "gold_top", name = "Złota góra", category = "top", price = 260, color = { 235, 185, 70 } },
		{ id = "blue_bottom", name = "Błękitny dół", category = "bottom", price = 200, color = { 92, 166, 220 } },
		{ id = "black_bottom", name = "Czarny dół", category = "bottom", price = 230, color = { 32, 32, 43 } },
		{ id = "cream_bottom", name = "Kremowy dół", category = "bottom", price = 210, color = { 239, 222, 190 } },
		{ id = "pink_shoes", name = "Różowe buty", category = "shoes", price = 140, color = { 244, 119, 170 } },
		{ id = "black_shoes", name = "Czarne buty", category = "shoes", price = 150, color = { 24, 24, 32 } },
		{ id = "gold_hat", name = "Złoty kapelusz", category = "accessory", price = 180, color = { 235, 185, 70 } },
		{ id = "rose_hat", name = "Różowy kapelusz", category = "accessory", price = 160, color = { 244, 119, 170 } },
	},
}
return Config

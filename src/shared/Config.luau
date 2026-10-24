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
	Palette = {
        { id = "rose", name = "Pudrowy róż", rgb = { 244, 119, 170 } },
        { id = "black", name = "Czerń", rgb = { 30, 29, 43 } },
        { id = "cream", name = "Ecru", rgb = { 239, 222, 190 } },
        { id = "blue", name = "Błękit", rgb = { 92, 166, 220 } },
        { id = "gold", name = "Złoto", rgb = { 235, 185, 70 } },
        { id = "sage", name = "Szałwia", rgb = { 135, 170, 145 } },
    },

}
return Config

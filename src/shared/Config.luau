local Config = {
	-- One real player is enough; bots fill the round up to RoundSize.
	MinPlayers = 1,
	MaxPlayers = 8,
	RoundSize = 4,
	Budget = 1500,
	IntermissionSeconds = 5,
	ShoppingSeconds = 480,
	VotingSeconds = 15,
	ResultsSeconds = 20,
	StoreDistance = 24,
	BotNames = { "Zosia", "Lena", "Maja", "Iga", "Hania", "Nela", "Ola", "Pola" },
	-- Roblox-licensed APM Music tracks (APMOfficial), safe in any experience.
	Music = {
		Lobby = { 9044539308, 1839002474, 1841296740 },
		Shopping = { 1844487326, 1837913244, 1837702577, 1839763308 },
		Showcase = { 1835983198, 1836568532 },
		Results = { 1837407430 },
	},
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

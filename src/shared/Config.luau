local Config = {
	-- One real player is enough; bots fill the round up to RoundSize.
	MinPlayers = 1,
	MaxPlayers = 8,
	RoundSize = 4,
	Budget = 1500,
	IntermissionSeconds = 5,
	ShoppingSeconds = 480,
	-- Show: each look is presented on the runway, then the jury and contestants
	-- award 1–5 stars, then the score is revealed.
	IntroLineSeconds = 4.5,
	PresentSeconds = 15,
	VoteSeconds = 10,
	RevealSeconds = 4,
	ResultsSeconds = 24,
	MaxStars = 5,
	Host = { name = "Gabriela", title = "Prowadząca",
		outfit = { { 451220849, "Hair" }, { 8648380153, "Jacket" }, { 9240772455, "DressSkirt" }, { 16236764821, "Hat" }, { 376527115, "Neck" } }, shoes = { 8044843668, 8044852814 }, skin = { 234, 190, 160 } },
	Jury = {
		{ name = "Marco", title = "Juror • stylista", outfit = { { 62743701, "Hair" }, { 8516638468, "Jacket" }, { 8721985925, "Pants" }, { 376526673, "Face" } }, shoes = { 8044823721, 8044826993 }, skin = { 198, 140, 104 } },
		{ name = "Lili", title = "Jurorka • influencerka", outfit = { { 5890690147, "Hair" }, { 6984771334, "Sweater" }, { 7192691582, "DressSkirt" }, { 6255878442, "Hat" }, { 6682341755, "Neck" } }, shoes = { 9483490552, 9483495483 }, skin = { 255, 220, 196 } },
		{ name = "Victor", title = "Juror • projektant", outfit = { { 6026462825, "Hair" }, { 7192549218, "Jacket" }, { 7192681239, "Pants" }, { 30331986, "Face" } }, shoes = { 8044843668, 8044852814 }, skin = { 141, 94, 66 } },
	},
	-- Real catalog hair for bot contestants.
	BotHair = { 63690008, 451220849, 376548738, 62724852, 5890690147 },
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

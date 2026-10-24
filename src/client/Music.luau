-- Background music per game phase, with fades. Plays locally for each player.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local VOLUME = 0.35
local Music = { muted = false }
local sound = Instance.new("Sound"); sound.Name = "ShoppingQueenMusic"; sound.Volume = 0; sound.Parent = SoundService
local mood, index = nil, 0

local function fade(volume, seconds)
	TweenService:Create(sound, TweenInfo.new(seconds), { Volume = volume }):Play()
end

local function playNext()
	local list = Config.Music[mood]
	if not list or #list == 0 then sound:Stop(); return end
	index = index % #list + 1
	sound.SoundId = "rbxassetid://" .. list[index]
	sound.TimePosition = 0
	sound:Play()
	fade(if Music.muted then 0 else VOLUME, 1.5)
end
sound.Ended:Connect(playNext)

function Music.setMood(key)
	if key == mood then return end
	mood = key
	local list = Config.Music[key] or {}
	index = if #list > 0 then math.random(0, #list - 1) else 0
	fade(0, 0.6)
	task.delay(0.65, function() if mood == key then playNext() end end)
end

function Music.toggle()
	Music.muted = not Music.muted
	fade(if Music.muted then 0 else VOLUME, 0.4)
	return Music.muted
end

return Music

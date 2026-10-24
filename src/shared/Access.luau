-- Browsing must not depend on a multiplayer round already being active.
local Access = {}
function Access.canBrowse(phase)
	return phase == "Lobby" or phase == "Intermission" or phase == "Shopping"
end
function Access.canTry(phase, participating)
	return phase == "Lobby" or phase == "Intermission" or (phase == "Shopping" and participating)
end
return Access

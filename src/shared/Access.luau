-- Waiting players stay in the lounge; only round participants enter the mall.
local Access = {}
function Access.canBrowse(phase, participating)
	return phase == "Shopping" and participating == true
end
function Access.canTry(phase, participating)
	return Access.canBrowse(phase, participating)
end
function Access.mustWait(phase, participating, presenting)
	return not (Access.canBrowse(phase, participating) or (phase == "Showcase" and participating == true and presenting == true))
end
return Access

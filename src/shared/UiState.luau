local UiState = {}

-- Incoming budget/vote updates must not close an open shop or change its tab.
-- A new presentation takes priority so the player gets a chance to vote.
function UiState.receive(previous, packet, view, opened)
	local changedPhase = not previous or previous.phase ~= packet.phase
	if changedPhase then
		if packet.phase == "Showcase" or packet.phase == "Results" then
			view, opened = "round", true
		elseif view == "round" then
			view, opened = "home", false
		elseif view == "wardrobe" then
			opened = false
		end
	end
	if packet.phase == "Showcase" and (not previous or previous.showId ~= packet.showId) then
		view, opened = "round", true
	end
	if packet.store and packet.phase == "Shopping" and packet.participating then
		view, opened = "wardrobe", true
	end
	return view, opened
end

function UiState.columns(width)
	return if width >= 620 then 2 else 1
end
return UiState

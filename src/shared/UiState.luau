local UiState = {}

-- Incoming budget/vote updates must not close an open shop or change its tab.
-- Cutscenes (intro and runway show) close menus; results open the summary.
function UiState.receive(previous, packet, view, opened)
	local changedPhase = not previous or previous.phase ~= packet.phase
	if changedPhase then
		if packet.phase == "Results" then
			view, opened = "round", true
		elseif packet.phase == "Intro" or packet.phase == "Showcase" then
			if view == "round" or view == "wardrobe" then view = "home" end
			opened = false
		elseif view == "round" then
			view, opened = "home", false
		elseif view == "wardrobe" then
			opened = false
		end
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

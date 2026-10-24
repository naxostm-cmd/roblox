local TweenService = game:GetService("TweenService")
local UI = {}
UI.Colors = {
	Paper = Color3.fromRGB(255, 250, 244), Ink = Color3.fromRGB(52, 37, 47),
	Muted = Color3.fromRGB(133, 111, 123), Rose = Color3.fromRGB(177, 66, 111),
	Blush = Color3.fromRGB(245, 225, 231), Gold = Color3.fromRGB(182, 139, 71),
	Line = Color3.fromRGB(232, 216, 219), White = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(62, 120, 103),
}
local C = UI.Colors

function UI.corner(object, radius)
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 14); corner.Parent = object
end

function UI.stroke(object, color, transparency)
	local stroke = Instance.new("UIStroke"); stroke.Color = color or C.Line; stroke.Transparency = transparency or 0
	stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = object
end

function UI.frame(parent, name, size, position, color, radius)
	local frame = Instance.new("Frame"); frame.Name = name; frame.Size = size
	frame.Position = position or UDim2.new(); frame.BackgroundColor3 = color or C.Paper; frame.BorderSizePixel = 0
	if radius ~= 0 then UI.corner(frame, radius) end
	frame.Parent = parent; return frame
end

function UI.text(parent, text, size, position, fontSize, color, bold)
	local label = Instance.new("TextLabel"); label.Size = size; label.Position = position or UDim2.new()
	label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = color or C.Ink
	label.TextSize = fontSize or 15; label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.TextWrapped = true; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent; return label
end

function UI.button(parent, text, size, position, callback, style)
	local b = Instance.new("TextButton"); b.Size = size; b.Position = position or UDim2.new()
	local light = style == "light"
	local base = if light then C.Blush else C.Rose
	b.BackgroundColor3 = base; b.TextColor3 = if light then C.Rose else C.White
	b.Text = text; b.TextSize = 14; b.Font = Enum.Font.GothamBold; b.TextWrapped = true
	b.AutoButtonColor = false; b.BorderSizePixel = 0; UI.corner(b, 10)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base:Lerp(C.White, 0.12) }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play() end)
	b.Activated:Connect(callback); b.Parent = parent; return b
end

function UI.badge(parent, text, size, position, color)
	local frame = UI.frame(parent, "Badge", size, position, color or C.Blush, 8)
	local label = UI.text(frame, text, UDim2.fromScale(1, 1), nil, 11, if color then C.White else C.Rose, true)
	label.TextXAlignment = Enum.TextXAlignment.Center
	return frame
end

function UI.gradient(object, first, second, rotation)
	local gradient = Instance.new("UIGradient"); gradient.Color = ColorSequence.new(first, second)
	gradient.Rotation = rotation or 35; gradient.Parent = object
end

-- Native vector-like marks keep placeholders crisp without unapproved assets.
function UI.motif(parent, kind, color)
	local mark = UI.frame(parent, "Illustration", UDim2.fromOffset(100, 74), UDim2.fromScale(0.5, 0.5), color, 0)
	mark.AnchorPoint = Vector2.new(0.5, 0.5); mark.BackgroundTransparency = 1
	if kind == "crown" then
		UI.frame(mark, "CrownBase", UDim2.fromOffset(62, 12), UDim2.fromOffset(19, 49), color, 3)
		for i = 1, 3 do
			local bar = UI.frame(mark, "CrownPoint", UDim2.fromOffset(17, if i == 2 then 36 else 28), UDim2.fromOffset(20 + (i - 1) * 21, if i == 2 then 15 else 23), color, 4)
			bar.Rotation = (i - 2) * 14
			UI.frame(mark, "Pearl", UDim2.fromOffset(8, 8), UDim2.fromOffset(24 + (i - 1) * 21, if i == 2 then 3 else 12), color, 8)
		end
	else
		local function sparkle(x, y, scale)
			local diamond = UI.frame(mark, "Sparkle", UDim2.fromOffset(24 * scale, 24 * scale), UDim2.fromOffset(x, y), color, 4)
			diamond.Rotation = 45
		end
		sparkle(36, 22, 1.35); sparkle(12, 11, 0.55); sparkle(74, 50, 0.45)
	end
	return mark
end

function UI.clear(parent)
	for _, child in ipairs(parent:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
return UI

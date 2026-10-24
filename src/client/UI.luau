-- "Midnight boutique" theme: dark glass panels, pink-violet accents, gold details.
local TweenService = game:GetService("TweenService")
local UI = {}
UI.Colors = {
	Panel = Color3.fromRGB(24, 15, 31), Card = Color3.fromRGB(41, 27, 50), CardHi = Color3.fromRGB(60, 40, 72),
	Text = Color3.fromRGB(255, 248, 251), Sub = Color3.fromRGB(216, 196, 218), Faint = Color3.fromRGB(160, 136, 166),
	Rose = Color3.fromRGB(255, 92, 160), Violet = Color3.fromRGB(176, 84, 230), Gold = Color3.fromRGB(244, 200, 112),
	Green = Color3.fromRGB(104, 222, 166), Red = Color3.fromRGB(255, 108, 124), Ink = Color3.fromRGB(28, 17, 34),
	White = Color3.fromRGB(255, 255, 255), Line = Color3.fromRGB(255, 255, 255),
}
local C = UI.Colors

local function family(name, weight)
	local ok, font = pcall(Font.new, "rbxasset://fonts/families/" .. name .. ".json", weight)
	return if ok then font else Font.fromEnum(Enum.Font.GothamBold)
end
UI.Fonts = {
	Title = family("Montserrat", Enum.FontWeight.ExtraBold),
	Bold = family("Montserrat", Enum.FontWeight.Bold),
	Body = family("BuilderSans", Enum.FontWeight.Medium),
	Strong = family("BuilderSans", Enum.FontWeight.Bold),
}

function UI.corner(object, radius)
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 14); corner.Parent = object
	return corner
end

function UI.stroke(object, color, transparency, thickness)
	local stroke = Instance.new("UIStroke"); stroke.Color = color or C.Line; stroke.Transparency = transparency or 0.86
	stroke.Thickness = thickness or 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = object
	return stroke
end

function UI.gradient(object, first, second, rotation)
	local gradient = Instance.new("UIGradient"); gradient.Color = ColorSequence.new(first, second)
	gradient.Rotation = rotation or 35; gradient.Parent = object
	return gradient
end

function UI.frame(parent, name, size, position, color, radius)
	local frame = Instance.new("Frame"); frame.Name = name; frame.Size = size
	frame.Position = position or UDim2.new(); frame.BackgroundColor3 = color or C.Panel; frame.BorderSizePixel = 0
	if radius ~= 0 then UI.corner(frame, radius) end
	frame.Parent = parent; return frame
end

-- Translucent panel that stays readable over the bright 3D world.
function UI.glass(parent, name, size, position, radius)
	local frame = UI.frame(parent, name, size, position, C.Panel, radius or 18)
	frame.BackgroundTransparency = 0.06
	UI.gradient(frame, C.Panel, Color3.fromRGB(38, 22, 48), 90)
	UI.stroke(frame, C.Rose, 0.72, 1.5)
	return frame
end

function UI.text(parent, text, size, position, fontSize, color, weight)
	local label = Instance.new("TextLabel"); label.Size = size; label.Position = position or UDim2.new()
	label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = color or C.Text
	label.TextSize = fontSize or 16
	label.FontFace = if weight == "title" then UI.Fonts.Title elseif weight == "bold" or weight == true then UI.Fonts.Bold
		elseif weight == "strong" then UI.Fonts.Strong else UI.Fonts.Body
	label.TextWrapped = true; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent; return label
end

local styles = {
	primary = { C.Rose, C.Violet, C.White },
	gold = { C.Gold, Color3.fromRGB(226, 150, 86), C.Ink },
	light = { C.CardHi, C.Card, C.Text },
	danger = { C.Red, Color3.fromRGB(200, 70, 110), C.White },
}

function UI.button(parent, text, size, position, callback, style)
	local look = styles[style or "primary"] or styles.primary
	local b = Instance.new("TextButton"); b.Size = size; b.Position = position or UDim2.new()
	b.BackgroundColor3 = C.White; b.TextColor3 = look[3]; b.Text = text; b.TextSize = 15
	b.FontFace = UI.Fonts.Bold; b.TextWrapped = true; b.AutoButtonColor = false; b.BorderSizePixel = 0
	UI.corner(b, 12)
	UI.gradient(b, look[1], look[2], 20)
	if style == "light" then UI.stroke(b, C.Line, 0.8) end
	local scale = Instance.new("UIScale"); scale.Parent = b
	local function to(value) TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = value }):Play() end
	b.MouseEnter:Connect(function() to(1.03) end)
	b.MouseLeave:Connect(function() to(1) end)
	b.MouseButton1Down:Connect(function() to(0.96) end)
	b.MouseButton1Up:Connect(function() to(1.03) end)
	b.Activated:Connect(callback); b.Parent = parent; return b
end

function UI.badge(parent, text, size, position, color, textColor)
	local frame = UI.frame(parent, "Badge", size, position, color or C.CardHi, 8)
	local label = UI.text(frame, text, UDim2.fromScale(1, 1), nil, 12, textColor or (if color then C.White else C.Rose), "bold")
	label.TextXAlignment = Enum.TextXAlignment.Center
	return frame
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

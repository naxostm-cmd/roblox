local Garments = require(game:GetService("ReplicatedStorage").Shared.Garments)
local Preview = {}
function Preview.mount(parent, character, item, color)
	if not character then return nil end
	local previous = character.Archivable; character.Archivable = true
	local ok, clone = pcall(function() return character:Clone() end)
	character.Archivable = previous
	if not ok or not clone then return nil end
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") then object:Destroy()
		elseif object:IsA("BasePart") then object.Anchored = true
		elseif (item.category == "top" and (object:IsA("Shirt") or object:IsA("ShirtGraphic"))) or (item.category == "bottom" and object:IsA("Pants")) then object:Destroy() end
	end
	local old = clone:FindFirstChild("SQOutfit"); if old then old:Destroy() end
	local viewport = Instance.new("ViewportFrame"); viewport.Name = "FittingPreview"
	viewport.Size = UDim2.fromScale(1, 1); viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(210, 205, 205); viewport.LightColor = Color3.new(1, 1, 1); viewport.LightDirection = Vector3.new(-1, -1, -2)
	viewport.Parent = parent
	local world = Instance.new("WorldModel"); world.Parent = viewport; clone.Parent = world; clone:PivotTo(CFrame.new())
	local folder = Instance.new("Folder"); folder.Name = "SQOutfit"; folder.Parent = clone
	Garments.build(clone, item, color, folder)
	for _, object in ipairs(folder:GetDescendants()) do if object:IsA("BasePart") then object.Anchored = true end end
	local camera = Instance.new("Camera"); camera.FieldOfView = 38; camera.Parent = viewport; viewport.CurrentCamera = camera
	local box, size = clone:GetBoundingBox()
	camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(0, size.Y * 0.05, -math.max(size.Y * 1.65, size.X * 1.8, 7)), box.Position)
	local yaw = 0
	return function(direction)
		yaw += direction * math.rad(30); clone:PivotTo(CFrame.Angles(0, yaw, 0))
	end
end
return Preview

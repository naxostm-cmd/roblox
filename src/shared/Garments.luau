-- Original, stylised clothing built from fitted parts. Works without asset uploads.
local Garments = {}
function Garments.build(character, item, color, folder)
	local clothingTypes = if item.category == "top" then { Shirt = true, Jacket = true, Sweater = true }
        elseif item.category == "bottom" then { Pants = true, Shorts = true, DressSkirt = true }
        elseif item.category == "accessory" then { Hat = true } else {}
	for _, object in ipairs(character:GetChildren()) do
		if object:IsA("Accessory") and clothingTypes[object.AccessoryType.Name] then
			for _, p in ipairs(object:GetDescendants()) do if p:IsA("BasePart") then p.Transparency = 1 end end
		end
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local hip = character:FindFirstChild("LowerTorso") or torso
	if not torso or not hip then return end
	local function piece(limb, name, size, offset, tint, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = tint or color
		p.Material = Enum.Material.Fabric; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.CFrame = limb.CFrame * offset; p.Parent = folder
		local weld = Instance.new("WeldConstraint"); weld.Part0 = limb; weld.Part1 = p; weld.Parent = p
		return p
	end
	local w, h, d = torso.Size.X, torso.Size.Y, torso.Size.Z
	local trim = Color3.fromRGB(232, 199, 134)
 local head = character:FindFirstChild("Head")
 local style = item.style
 if item.category == "bag" then
  local sizes = { tote = {1.2,1.5,0.5}, clutch = {1.3,0.6,0.35}, satchel = {1.3,1,0.6}, mini_bag = {0.7,0.65,0.4}, box_bag = {1,1,0.8}, round_bag = {1.2,1.2,0.45} }
  local size = sizes[style] or sizes.tote
  piece(torso, "BagBody", Vector3.new(table.unpack(size)), CFrame.new(w*0.65,-h*0.5,-0.1), color, if style == "round_bag" then Enum.PartType.Ball else nil)
  piece(torso, "BagStrap", Vector3.new(0.09,h*1.4,0.08), CFrame.new(w*0.22,0,-d/2-0.22)*CFrame.Angles(0,0,-0.65), trim)
  piece(torso, "BagClasp", Vector3.new(0.2,0.16,0.08), CFrame.new(w*0.65,-h*0.4,-size[3]/2-0.15),trim)
  return
 elseif item.category == "glasses" and head then
  local size = if style == "oversized" then 0.65 elseif style == "slim" then 0.32 else 0.48
  for _, side in ipairs({-1,1}) do
   local angle = if style == "cat_eye" then side*0.2 else 0
   piece(head,"GlassesFrame",Vector3.new(size,size*0.7,0.13),CFrame.new(side*0.3,0.12,-head.Size.Z/2-0.14)*CFrame.Angles(0,0,angle),color,if style == "round" or style == "aviator" then Enum.PartType.Ball else nil)
   local lens = piece(head,"GlassesLens",Vector3.new(size*0.77,size*0.5,0.06),CFrame.new(side*0.3,0.12,-head.Size.Z/2-0.22)*CFrame.Angles(0,0,angle),Color3.fromRGB(60,65,85))
   lens.Transparency = 0.3; lens.Material = Enum.Material.Glass
  end
  if style == "aviator" then piece(head,"AviatorBrow",Vector3.new(0.65,0.06,0.1),CFrame.new(0,0.38,-head.Size.Z/2-0.16),color) end
  piece(head,"GlassesBridge",Vector3.new(0.22,0.08,0.12),CFrame.new(0,0.12,-head.Size.Z/2-0.16))
  return
 elseif item.category == "jewelry" then
  if style == "earrings" and head then
   for _, side in ipairs({-1,1}) do piece(head,"Earring",Vector3.new(0.18,0.5,0.18),CFrame.new(side*(head.Size.X/2+0.08),-0.2,0),color,Enum.PartType.Ball) end
  elseif style == "brooch" then
   piece(torso,"Brooch",Vector3.new(0.35,0.35,0.14),CFrame.new(w*0.3,h*0.25,-d/2-0.18),color,Enum.PartType.Ball)
  else
   for i=1,9 do
    local t=(i-5)/4
    piece(torso,"NecklaceBead",Vector3.new(0.13,0.13,0.13),CFrame.new(t*w*0.33,h*(if style == "choker" then 0.42 else 0.16+math.abs(t)*0.25),-d/2-0.18),color,Enum.PartType.Ball)
   end
   if style == "pendant" then piece(torso,"Pendant",Vector3.new(0.25,0.4,0.15),CFrame.new(0,h*0.03,-d/2-0.2),trim,Enum.PartType.Ball) end
   if style == "chain" then piece(torso,"ChainMedallion",Vector3.new(0.4,0.4,0.18),CFrame.new(0,h*0.02,-d/2-0.22),color,Enum.PartType.Ball) end
  end
  return
 elseif item.category == "accessory" and head then
  if style == "crown" then
   piece(head,"CrownBand",Vector3.new(1.6,0.2,1.3),CFrame.new(0,0.65,0),color)
   for i=-1,1 do piece(head,"CrownPoint",Vector3.new(0.2,0.5,0.2),CFrame.new(i*0.6,0.95,-0.55),color) end
  else
   local tall = if style == "tophat" then 1.2 elseif style == "beret" then 0.25 else 0.6
   piece(head,"HatCrown",Vector3.new(1.7,tall,1.5),CFrame.new(0,0.6+tall/2,0),color,if style == "beret" or style == "cap" then Enum.PartType.Ball else nil)
   if style ~= "beret" then piece(head,"HatBrim",Vector3.new(if style == "widehat" then 3 else 2,0.12,if style == "cap" then 1.5 else 2),CFrame.new(0,0.6,if style == "cap" then -0.65 else 0),color) end
  end
  return
 elseif item.category == "shoes" then
  for _, side in ipairs({"Left","Right"}) do
   local foot = character:FindFirstChild(side.."Foot") or character:FindFirstChild(side.." Leg")
   if foot then
    local height = if style == "tallboots" then 1.5 elseif style == "boots" then 0.9 elseif style == "platforms" then 0.65 else 0.4
    piece(foot,"ShoeBody",Vector3.new(foot.Size.X+0.12,height,foot.Size.Z+0.25),CFrame.new(0,-foot.Size.Y/2+height/2,-0.06))
    if style == "heels" then piece(foot,"Heel",Vector3.new(0.2,0.5,0.25),CFrame.new(0,-foot.Size.Y/2-0.15,foot.Size.Z*0.3),trim) end
    if style == "sneakers" then piece(foot,"SneakerSole",Vector3.new(foot.Size.X+0.17,0.12,foot.Size.Z+0.3),CFrame.new(0,-foot.Size.Y/2,-0.06),Color3.new(1,1,1)) end
   end
  end
  return
 elseif item.category == "bottom" and (style == "trousers" or style == "widepants" or style == "shorts") then
  for _, side in ipairs({"Left","Right"}) do
   for _, suffix in ipairs({"UpperLeg","LowerLeg"," Leg"}) do
    local leg = character:FindFirstChild(side..suffix)
    if leg and (style ~= "shorts" or suffix ~= "LowerLeg") then
     local length = leg.Size.Y * (if style == "shorts" then 0.65 else 1)
     local width = if style == "widepants" then 0.35 else 0.12
     piece(leg,"TrouserLeg",Vector3.new(leg.Size.X+width,length,leg.Size.Z+width),CFrame.new(0,(leg.Size.Y-length)/2,0))
    end
   end
  end
  return
 end
 if item.style == "pleated" or item.style == "mini" or item.style == "pencil" then
		local length = if item.style == "mini" then 1.0 else 1.65
		local waistY = if hip == torso then -h * 0.36 else 0
		local radius = math.max(hip.Size.X * 0.6, 0.8)
		for i = 1, 16 do
			local angle = (i - 1) * math.pi * 2 / 16
			local cf = CFrame.new(0, waistY, 0) * CFrame.Angles(0, angle, 0)
				* CFrame.new(0, -length * 0.45, -radius) * CFrame.Angles(if style == "pencil" then 0 else -0.28, 0, 0)
			piece(hip, "SkirtPleat", Vector3.new(radius * 0.52, length, 0.16), cf, if i % 2 == 0 then color else color:Lerp(Color3.new(0, 0, 0), 0.08))
		end
		piece(hip, "Waistband", Vector3.new(hip.Size.X + 0.2, 0.22, hip.Size.Z + 0.24), CFrame.new(0, waistY, 0), trim)
		return
	end
	if not item.style then return end
	piece(torso, "FittedBodice", Vector3.new(w + 0.12, h * 0.82, d + 0.14), CFrame.new(0, -h * 0.08, 0))
	if item.style == "jacket" or item.style == "vest" then
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "IvoryLapel", Vector3.new(w * 0.2, h * 0.7, 0.12), CFrame.new(side * w * 0.18, h * 0.04, -d / 2 - 0.14) * CFrame.Angles(0, 0, side * -0.24), Color3.fromRGB(245, 233, 216))
			piece(torso, "Pocket", Vector3.new(w * 0.26, h * 0.12, 0.13), CFrame.new(side * w * 0.29, -h * 0.28, -d / 2 - 0.17))
		end
		for i = 1, 3 do piece(torso, "GoldButton", Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, h * (0.15 - i * 0.17), -d / 2 - 0.2), trim, Enum.PartType.Ball) end
 elseif style == "hoodie" then
  piece(torso,"Hood",Vector3.new(w*0.8,h*0.55,d*0.6),CFrame.new(0,h*0.5,d*0.5),color,Enum.PartType.Ball)
  piece(torso,"KangarooPocket",Vector3.new(w*0.65,h*0.25,0.15),CFrame.new(0,-h*0.23,-d/2-0.15))
 elseif style == "tunic" then
  piece(torso,"TunicHem",Vector3.new(w+0.3,h*0.35,d+0.2),CFrame.new(0,-h*0.48,0))
  piece(torso,"TunicBelt",Vector3.new(w+0.22,0.13,d+0.2),CFrame.new(0,-h*0.2,0),trim)
	elseif item.style == "corset" then
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "CorsetSeam", Vector3.new(0.06, h * 0.65, 0.06), CFrame.new(side * w * 0.22, -h * 0.08, -d / 2 - 0.12), trim)
		end
		for i = 1, 4 do
			piece(torso, "Lacing", Vector3.new(w * 0.27, 0.035, 0.05), CFrame.new(0, h * (0.23 - i * 0.13), -d / 2 - 0.14) * CFrame.Angles(0, 0, if i % 2 == 0 then 0.3 else -0.3), trim)
		end
	else
		for _, side in ipairs({ -1, 1 }) do
			piece(torso, "Bow", Vector3.new(w * 0.3, h * 0.18, 0.22), CFrame.new(side * w * 0.12, h * 0.24, -d / 2 - 0.2) * CFrame.Angles(0, 0, side * 0.25), color:Lerp(Color3.new(1, 1, 1), 0.25))
		end
	end
	if item.style ~= "corset" and item.style ~= "vest" then
		for _, side in ipairs({ "Left", "Right" }) do
			local arm = character:FindFirstChild(side .. "UpperArm") or character:FindFirstChild(side .. " Arm")
			if arm then
				piece(arm, "Sleeve", Vector3.new(arm.Size.X + 0.16, arm.Size.Y * 0.75, arm.Size.Z + 0.16), CFrame.new(0, arm.Size.Y * 0.1, 0), color, if item.style == "blouse" then Enum.PartType.Ball else nil)
			end
		end
	end
end
return Garments

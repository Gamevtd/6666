local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
	Title = "di   ck   hub",
	Footer = "suck my a  ss",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "crosshair"),
	Visuals = Window:AddTab("Visuals", "eye"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local SpeedGroup = Tabs.Main:AddLeftGroupbox("Speed", "zap")
local MainLeftGroup = Tabs.Main:AddLeftGroupbox("Combat Functions", "swords")
local MainRightGroup = Tabs.Main:AddRightGroupbox("Silent Aim", "target")
local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("Chams & World", "palette")
local VisualsRightGroup = Tabs.Visuals:AddRightGroupbox("ESP & Camera", "camera")

local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local coregui = game:GetService("CoreGui")
local userinputservice = game:GetService("UserInputService")
local replicatedstorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local soundservice = game:GetService("SoundService")
local tweenservice = game:GetService("TweenService")

local lp = players.LocalPlayer
local cam = workspace.CurrentCamera
local shootevent = replicatedstorage:WaitForChild("Remotes"):WaitForChild("ShootEvent")

local armcache = {}
local wpncache = {}
local lightcache = {}
local maplightcache = {}
local skycache = {}
local espcache = {}

local ui = {
	screen = nil,
	main = nil,
	highlight = nil,
	billboard = nil,
	healthtext = nil
}

local st = {
	enabled = false,
	tpenabled = false,
	armffenabled = false,
	weaponffenabled = false,
	purpleenabled = false,
	soundenabled = true,
	beamenabled = true,
	wallcheck = true,
	silentwallcheck = true,
	silentenabled = false,
	fovvisible = false,
	fovradius = 100,
	target = nil,
	interval = 0.05,
	lastshot = 0,
	origcframe = nil,
	esp = false,
	hitchance = 100,
	hitpart = "Head",
	tpwalking = false,
	tpwalkSpeed = 22
}

local lastcheck = 0
local lastwpn = nil
local lastcharwpn = nil

local cachedSilentTarget = nil
local lastSilentUpdate = 0
local silentUpdateDelay = 0.1

local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Visible = false
FOV_Circle.Radius = st.fovradius
FOV_Circle.Color = Color3.fromRGB(255, 255, 255)
FOV_Circle.Thickness = 1
FOV_Circle.Transparency = 1
FOV_Circle.Filled = false
FOV_Circle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	FOV_Circle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end)

local function isvisible(part)
	if not part then return false end
	local mychar = lp.Character
	if not mychar then return false end
	local origin = cam.CFrame.Position
	local direction = part.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local filterList = {mychar, cam}
	local vm = cam:FindFirstChild("Viewmodel")
	if vm then table.insert(filterList, vm) end
	
	params.FilterDescendantsInstances = filterList
	params.IgnoreWater = true
	
	local result = workspace:Raycast(origin, direction, params)
	if result then
		return result.Instance:IsDescendantOf(part.Parent)
	end
	return true
end

local function getmodel(obj)
	if not obj then return nil end
	if obj:IsA("Player") then
		return obj.Character
	elseif obj:IsA("Model") then
		return obj
	end
	return nil
end

local function cleanup()
	if ui.highlight then
		ui.highlight:Destroy()
		ui.highlight = nil
	end
	if ui.billboard then
		ui.billboard:Destroy()
		ui.billboard = nil
	end
	ui.healthtext = nil
end

local function clearAllESP()
	for model, hl in pairs(espcache) do
		if hl and hl.Parent then
			hl:Destroy()
		end
	end
	espcache = {}
end

local function isTeammate(model)
	local head = model:FindFirstChild("Head")
	if head and head:FindFirstChild("TeammateNametag") then
		return true
	end
	return false
end

local function updateESP()
	if not st.esp then
		clearAllESP()
		return
	end

	local function processModel(model)
		if not model or model == lp.Character then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
		if not hum or hum.Health <= 0 or not hrp then
			if espcache[model] then
				espcache[model]:Destroy()
				espcache[model] = nil
			end
			return
		end

		local team = isTeammate(model)
		local targetColor = team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

		local hl = espcache[model]
		if not hl or hl.Parent ~= model then
			if hl then hl:Destroy() end
			hl = Instance.new("Highlight")
			hl.Name = "KanlHubESP"
			hl.Adornee = model
			hl.FillTransparency = 1
			hl.OutlineTransparency = 0
			hl.OutlineColor = targetColor
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = model
			espcache[model] = hl
		else
			if hl.OutlineColor ~= targetColor then
				hl.OutlineColor = targetColor
			end
		end
	end

	local plist = players:GetPlayers()
	for i = 1, #plist do
		if plist[i].Character then
			processModel(plist[i].Character)
		end
	end

	local npcsfolder = workspace:FindFirstChild("NPCS")
	if npcsfolder then
		local npclist = npcsfolder:GetChildren()
		for i = 1, #npclist do
			processModel(npclist[i])
		end
	end
end

local function restorelight()
	for prop, val in pairs(lightcache) do
		pcall(function()
			lighting[prop] = val
		end)
	end
	lightcache = {}

	for obj, data in pairs(skycache) do
		if obj and obj.Parent then
			pcall(function()
				obj.SkyboxBk = data.bk
				obj.SkyboxDn = data.dn
				obj.SkyboxFt = data.ft
				obj.SkyboxLf = data.lf
				obj.SkyboxRt = data.rt
				obj.SkyboxUp = data.up
			end)
		end
	end
	skycache = {}

	for obj, origcol in pairs(maplightcache) do
		if obj and obj.Parent then
			pcall(function()
				obj.Color = origcol
			end)
		end
	end
	maplightcache = {}
end

local function applypurple()
	if next(lightcache) == nil then
		lightcache.Ambient = lighting.Ambient
		lightcache.OutdoorAmbient = lighting.OutdoorAmbient
		lightcache.ColorShift_Top = lighting.ColorShift_Top
		lightcache.ColorShift_Bottom = lighting.ColorShift_Bottom
	end
	
	local chosenColor = Options.PurpleColor and Options.PurpleColor.Value or Color3.fromRGB(160, 110, 200)
	
	lighting.Ambient = chosenColor
	lighting.OutdoorAmbient = chosenColor
	lighting.ColorShift_Top = chosenColor
	lighting.ColorShift_Bottom = chosenColor

	local sky = lighting:FindFirstChildOfClass("Sky")
	if sky and not skycache[sky] then
		skycache[sky] = {
			bk = sky.SkyboxBk,
			dn = sky.SkyboxDn,
			ft = sky.SkyboxFt,
			lf = sky.SkyboxLf,
			rt = sky.SkyboxRt,
			up = sky.SkyboxUp
		}
	end

	local desc = workspace:GetDescendants()
	for i = 1, #desc do
		local obj = desc[i]
		if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
			if not maplightcache[obj] then
				maplightcache[obj] = obj.Color
			end
			obj.Color = chosenColor
		end
	end
end

local function isvalid(obj)
	if not obj then return false end
	
	local model = getmodel(obj)
	if not model then return false end
	if model == lp.Character then return false end
	
	if isTeammate(model) then
		return false
	end
	
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local targetpart = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or humanoid.Health <= 0 or not targetpart then return false end
	if model:FindFirstChildOfClass("ForceField") then return false end
	
	return true
end

local function isvalidSilent(obj)
	if not obj then return false end
	
	local model = getmodel(obj)
	if not model then return false end
	if model == lp.Character then return false end
	
	if isTeammate(model) then
		return false
	end
	
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local targetpart = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or humanoid.Health <= 0 or not targetpart then return false end
	if model:FindFirstChildOfClass("ForceField") then return false end
	
	if st.silentwallcheck and not isvisible(targetpart) then
		return false
	end

	return true
end

local function restorearm()
	for part, data in pairs(armcache) do
		if part and part.Parent then
			part.Material = data.mat
			part.Color = data.col
			if part:IsA("MeshPart") then
				part.TextureID = data.tex
			end
		end
	end
	armcache = {}
end

local function restorewpn()
	for part, data in pairs(wpncache) do
		if part and part.Parent then
			part.Material = data.mat
			part.Color = data.col
			if part:IsA("MeshPart") then
				part.TextureID = data.tex
			end
		end
	end
	wpncache = {}
end

local function getclosest()
	local closest = nil
	local shortdist = math.huge
	
	local mychar = lp.Character
	if not mychar then return nil end
	local mypart = mychar:FindFirstChild("Head") or mychar:FindFirstChild("HumanoidRootPart")
	if not mypart then return nil end
	
	local mypos = mypart.Position

	local plist = players:GetPlayers()
	for i = 1, #plist do
		local p = plist[i]
		if isvalid(p) then
			local model = p.Character
			local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
			if part then
				local dist = (part.Position - mypos).Magnitude
				if dist < shortdist then
					shortdist = dist
					closest = p
				end
			end
		end
	end
	
	local npcsfolder = workspace:FindFirstChild("NPCS")
	if npcsfolder then
		local npclist = npcsfolder:GetChildren()
		for i = 1, #npclist do
			local npc = npclist[i]
			if isvalid(npc) then
				local part = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
				if part then
					local dist = (part.Position - mypos).Magnitude
					if dist < shortdist then
						shortdist = dist
						closest = npc
					end
				end
			end
		end
	end
	
	return closest
end

local function getTargetPart(model)
	if not model then return nil end
	local choice = st.hitpart

	if choice == "Random" then
		local parts = {"Head", "Torso", "UpperTorso", "LowerTorso", "LeftArm", "LeftUpperArm", "RightArm", "RightUpperArm", "LeftLeg", "LeftUpperLeg", "RightLeg", "RightUpperLeg"}
		local validParts = {}
		for i = 1, #parts do
			local p = model:FindFirstChild(parts[i])
			if p then table.insert(validParts, p) end
		end
		if #validParts > 0 then
			return validParts[math.random(1, #validParts)]
		end
	elseif choice == "Head" then
		return model:FindFirstChild("Head")
	elseif choice == "Torso" then
		return model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso")
	elseif choice == "Left Arm" then
		return model:FindFirstChild("LeftArm") or model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("LeftHand")
	elseif choice == "Right Arm" then
		return model:FindFirstChild("RightArm") or model:FindFirstChild("RightUpperArm") or model:FindFirstChild("RightHand")
	elseif choice == "Left Leg" then
		return model:FindFirstChild("LeftLeg") or model:FindFirstChild("LeftUpperLeg") or model:FindFirstChild("LeftFoot")
	elseif choice == "Right Leg" then
		return model:FindFirstChild("RightLeg") or model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("RightFoot")
	end

	return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

local function updateSilentTarget()
	if not st.silentenabled then
		cachedSilentTarget = nil
		return
	end

	local closest, shortdist = nil, math.huge
	local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

	local function checkCandidate(obj)
		if isvalidSilent(obj) then
			local model = getmodel(obj)
			local part = getTargetPart(model)
			if part then
				local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
				if onScreen then
					local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if distFromCenter <= st.fovradius and distFromCenter < shortdist then
						shortdist = distFromCenter
						closest = part
					end
				end
			end
		end
	end

	local plist = players:GetPlayers()
	for i = 1, #plist do
		checkCandidate(plist[i])
	end

	local npcsfolder = workspace:FindFirstChild("NPCS")
	if npcsfolder then
		local npclist = npcsfolder:GetChildren()
		for i = 1, #npclist do
			checkCandidate(npclist[i])
		end
	end

	cachedSilentTarget = closest
end

local function updatevis(target)
	local char = getmodel(target)
	if not char then
		cleanup()
		return
	end
	
	local vhead = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	
	if not vhead or not humanoid then
		cleanup()
		return
	end

	if not ui.highlight or ui.highlight.Parent ~= char then
		if ui.highlight then ui.highlight:Destroy() end
		local hl = Instance.new("Highlight")
		hl.Adornee = char
		hl.FillColor = Color3.fromRGB(255, 0, 0)
		hl.FillTransparency = 0.5
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char
		ui.highlight = hl
	end

	if not ui.billboard or ui.billboard.Parent ~= vhead then
		if ui.billboard then ui.billboard:Destroy() end
		local bb = Instance.new("BillboardGui")
		bb.Adornee = vhead
		bb.Size = UDim2.new(0, 100, 0, 30)
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop = true
		
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = Color3.fromRGB(255, 255, 255)
		txt.TextStrokeTransparency = 0
		txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		txt.TextSize = 14
		txt.Font = Enum.Font.SourceSansBold
		txt.Parent = bb
		
		bb.Parent = vhead
		ui.billboard = bb
		ui.healthtext = txt
	end

	if ui.healthtext and humanoid then
		ui.healthtext.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
	end
end

local function applyffpart(obj, cache, color)
	if obj:IsA("BasePart") then
		if not cache[obj] then
			local texid = ""
			if obj:IsA("MeshPart") then
				texid = obj.TextureID
			end
			cache[obj] = {
				mat = obj.Material,
				col = obj.Color,
				tex = texid
			}
		end
		if obj:IsA("MeshPart") then
			obj.TextureID = ""
		end
		obj.Material = Enum.Material.ForceField
		obj.Color = color or Color3.fromRGB(255, 255, 255)
	end
end

local function doarm(parent, color)
	local desc = parent:GetDescendants()
	for i = 1, #desc do
		applyffpart(desc[i], armcache, color)
	end
end

local function getequippedwpn()
	local vm = cam:FindFirstChild("Viewmodel")
	if vm then
		local children = vm:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("Model") then
				return children[i].Name
			end
		end
	end

	local charfolder = workspace:FindFirstChild(lp.Name)
	if charfolder then
		local children = charfolder:GetChildren()
		for i = 1, #children do
			local child = children[i]
			if child:IsA("Model") and child.Name ~= "HumanoidRootPart" and not child:FindFirstChildOfClass("Humanoid") then
				return child.Name
			end
		end
	end

	local mychar = lp.Character
	if mychar then
		local tool = mychar:FindFirstChildOfClass("Tool")
		if tool then
			return tool.Name
		end
	end

	return "M4A4"
end

local function getwpnmodel()
	local vm = cam:FindFirstChild("Viewmodel")
	if vm then
		local children = vm:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("Model") then
				return children[i]
			end
		end
	end

	local charfolder = workspace:FindFirstChild(lp.Name)
	if charfolder then
		local children = charfolder:GetChildren()
		for i = 1, #children do
			local child = children[i]
			if child:IsA("Model") and child.Name ~= "HumanoidRootPart" and not child:FindFirstChildOfClass("Humanoid") then
				return child
			end
		end
	end
	return nil
end

local function dowpn(wpnmodel, color)
	local desc = wpnmodel:GetDescendants()
	for i = 1, #desc do
		local obj = desc[i]
		local isarm = false
		local p = obj
		while p and p ~= wpnmodel do
			if p.Name == "Arms" then
				isarm = true
				break
			end
			p = p.Parent
		end
		if not isarm then
			applyffpart(obj, wpncache, color)
		end
	end
end

local function playsound()
	if not st.soundenabled then return end
	task.spawn(function()
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://17148249625"
		s.Volume = 0.65
		s.Parent = soundservice
		s.Ended:Connect(function()
			s:Destroy()
		end)
		s:Play()
		task.delay(3, function()
			if s and s.Parent then
				s:Destroy()
			end
		end)
	end)
end

local function createbeam(targetchar)
	if not st.beamenabled then return end
	task.spawn(function()
		local wmodel = getwpnmodel()
		local originpos = cam.CFrame.Position
		if wmodel then
			local part = wmodel:FindFirstChild("Handle") or wmodel:FindFirstChildWhichIsA("BasePart", true)
			if part then
				originpos = part.Position + (part.CFrame.LookVector * 2)
			end
		end

		local targetpart = targetchar and (targetchar:FindFirstChild("HumanoidRootPart") or targetchar:FindFirstChild("Head") or targetchar:FindFirstChildWhichIsA("BasePart"))
		if not targetpart then return end
		local targetpos = targetpart.Position

		local p1 = Instance.new("Part")
		p1.Size = Vector3.new(0.1, 0.1, 0.1)
		p1.Position = originpos
		p1.Anchored = true
		p1.CanCollide = false
		p1.Transparency = 1
		p1.Parent = workspace.Terrain

		local p2 = Instance.new("Part")
		p2.Size = Vector3.new(0.1, 0.1, 0.1)
		p2.Position = targetpos
		p2.Anchored = true
		p2.CanCollide = false
		p2.Transparency = 1
		p2.Parent = workspace.Terrain

		local att1 = Instance.new("Attachment")
		att1.Parent = p1

		local att2 = Instance.new("Attachment")
		att2.Parent = p2

		local beamColor = Options.BeamColor and Options.BeamColor.Value or Color3.fromRGB(255, 0, 0)

		local beam = Instance.new("Beam")
		beam.Attachment0 = att1
		beam.Attachment1 = att2
		beam.Color = ColorSequence.new(beamColor)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Width0 = 2
		beam.Width1 = 2
		beam.FaceCamera = true
		beam.Segments = 10
		beam.Texture = "rbxassetid://446111271"
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureSpeed = 5
		beam.TextureLength = 1.3

		local initialtransparency = 0.01
		beam.Transparency = NumberSequence.new(initialtransparency)
		beam.Parent = workspace.Terrain

		local objects = {p1, p2, att1, att2, beam}

		local function cleanobjects()
			for i = 1, #objects do
				local obj = objects[i]
				if obj and obj.Parent then
					pcall(function() obj:Destroy() end)
				end
			end
		end

		local success, err = pcall(function()
			task.wait(2)

			local fadeduration = 0.8
			local starttime = tick()
			local endtime = starttime + fadeduration
			while tick() < endtime do
				local elapsed = tick() - starttime
				local progress = math.clamp(elapsed / fadeduration, 0, 1)
				local currenttransparency = initialtransparency + (1 - initialtransparency) * progress
				beam.Transparency = NumberSequence.new(currenttransparency)
				task.wait()
			end
			beam.Transparency = NumberSequence.new(1)
			task.wait(0.05)

			cleanobjects()
		end)

		if not success then
			cleanobjects()
		end
	end)
end

local function bang(target)
	local mychar = lp.Character
	if not mychar then return end
	local myhead = mychar:FindFirstChild("Head")
	
	local targetchar = getmodel(target)
	local targethead = targetchar and (targetchar:FindFirstChild("Head") or targetchar:FindFirstChild("HumanoidRootPart"))
	
	if not myhead or not targethead then return end

	local origin = myhead.Position
	local targetpos = targethead.Position
	local direction = (targetpos - origin).Unit
	local wpnname = getequippedwpn()

	local payload = {
		a = false,
		r = 5000,
		e = targetpos,
		d = direction,
		w = wpnname,
		h = {
			partName = targethead.Name,
			modelName = targetchar.Name
		},
		t = "BULLET",
		cs = false,
		o = origin
	}

	shootevent:FireServer(payload)
	playsound()
	createbeam(targetchar)
end

local function updateff()
	local vm = cam:FindFirstChild("Viewmodel")
	local curvmwpn = nil
	if vm then
		local children = vm:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("Model") then
				curvmwpn = children[i]
				break
			end
		end
	end

	local charfolder = workspace:FindFirstChild(lp.Name)
	local curcharwpn = nil
	if charfolder then
		local children = charfolder:GetChildren()
		for i = 1, #children do
			local child = children[i]
			if child:IsA("Model") and child.Name ~= "HumanoidRootPart" and not child:FindFirstChildOfClass("Humanoid") then
				curcharwpn = child
				break
			end
		end
	end

	if lastwpn ~= curvmwpn or lastcharwpn ~= curcharwpn then
		restorearm()
		restorewpn()
		lastwpn = curvmwpn
		lastcharwpn = curcharwpn
	end

	if not curvmwpn and not curcharwpn then
		restorearm()
		restorewpn()
		return
	end

	local armColor = Options.ArmFFColor and Options.ArmFFColor.Value or Color3.fromRGB(255, 255, 255)
	local weaponColor = Options.WeaponFFColor and Options.WeaponFFColor.Value or Color3.fromRGB(255, 255, 255)

	if st.armffenabled then
		if curvmwpn then
			local arms = curvmwpn:FindFirstChild("Arms")
			if arms then
				doarm(arms, armColor)
			else
				restorearm()
			end
		else
			restorearm()
		end
	else
		restorearm()
	end

	if st.weaponffenabled then
		if curvmwpn then
			dowpn(curvmwpn, weaponColor)
		end
		if curcharwpn then
			dowpn(curcharwpn, weaponColor)
		end
	else
		restorewpn()
	end
end

SpeedGroup:AddToggle("SpeedToggle", {
	Text = "速度",
	Default = false,
	Tooltip = "Toggles speed boost",
	Callback = function(Value)
		st.tpwalking = Value
		if Value then
			task.spawn(function()
				while st.tpwalking do
					local chr = lp.Character or lp.CharacterAdded:Wait()
					local hrp = chr:FindFirstChild("HumanoidRootPart")
					local hum = chr:FindFirstChildWhichIsA("Humanoid")
					local delta = runservice.Heartbeat:Wait()
					if hrp and hum and hum.MoveDirection.Magnitude > 0 then
						hrp.CFrame = hrp.CFrame + (hum.MoveDirection * st.tpwalkSpeed * delta)
					end
				end
			end)
		end
	end,
})

SpeedGroup:AddSlider("SpeedSlider", {
	Text = "速度调节",
	Default = 22,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = false,
	Tooltip = "Adjust speed boost value",
	Callback = function(Value)
		st.tpwalkSpeed = Value
	end,
})

MainLeftGroup:AddToggle("AttackToggle", {
	Text = "ragebot",
	Default = false,
	Tooltip = "Toggles automatic target attack",
	Callback = function(Value)
		st.enabled = Value
		if not st.enabled then
			st.target = nil
			cleanup()
		end
	end,
})

MainLeftGroup:AddSlider("AttackSpeedSlider", {
	Text = "Attack Speed",
	Default = 0.05,
	Min = 0.01,
	Max = 1,
	Rounding = 2,
	Compact = false,
	Tooltip = "Adjust attack execution interval",
	Callback = function(Value)
		st.interval = Value
	end,
})

MainLeftGroup:AddToggle("TPToggle", {
	Text = "ragebot tpkill",
	Default = false,
	Tooltip = "Toggles teleporting to target",
	Callback = function(Value)
		st.tpenabled = Value
		if st.tpenabled then
			local mychar = lp.Character
			local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
			if hrp then
				st.origcframe = hrp.CFrame
			end
		else
			local mychar = lp.Character
			local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
			if hrp and st.origcframe then
				hrp.CFrame = st.origcframe
			end
			st.origcframe = nil
		end
	end,
})

MainLeftGroup:AddToggle("WallCheckToggle", {
	Text = "ragebot wallcheck",
	Default = true,
	Tooltip = "Checks if target is behind walls for Ragebot",
	Callback = function(Value)
		st.wallcheck = Value
	end,
})

MainLeftGroup:AddToggle("SoundToggle", {
	Text = "hit sound",
	Default = true,
	Tooltip = "Plays audio on firing",
	Callback = function(Value)
		st.soundenabled = Value
	end,
})

MainLeftGroup:AddToggle("BeamToggle", {
	Text = "visualized ragebot",
	Default = true,
	Tooltip = "Renders visual beams when attacking",
	Callback = function(Value)
		st.beamenabled = Value
	end,
}):AddColorPicker("BeamColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Beam Color",
})

MainRightGroup:AddToggle("SilentAimToggle", {
	Text = "Silent Aim",
	Default = false,
	Tooltip = "Redirects shots to target within FOV",
	Callback = function(Value)
		st.silentenabled = Value
		if not st.silentenabled then
			cachedSilentTarget = nil
		end
	end,
})

MainRightGroup:AddToggle("SilentWallCheckToggle", {
	Text = "silent aim wallcheck",
	Default = true,
	Tooltip = "Checks if target is behind walls for Silent Aim",
	Callback = function(Value)
		st.silentwallcheck = Value
	end,
})

MainRightGroup:AddToggle("FOVCircleToggle", {
	Text = "Draw FOV",
	Default = false,
	Tooltip = "Shows FOV circle on screen",
	Callback = function(Value)
		st.fovvisible = Value
		FOV_Circle.Visible = Value
	end,
}):AddColorPicker("FOVColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "FOV Color",
	Callback = function(Value)
		FOV_Circle.Color = Value
	end
})

MainRightGroup:AddSlider("FOVRadiusSlider", {
	Text = "FOV Radius",
	Default = 100,
	Min = 10,
	Max = 500,
	Rounding = 0,
	Compact = false,
	Tooltip = "Adjust FOV circle size",
	Callback = function(Value)
		st.fovradius = Value
		FOV_Circle.Radius = Value
	end,
})

MainRightGroup:AddSlider("HitChanceSlider", {
	Text = "Hit Chance",
	Default = 100,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Compact = false,
	Tooltip = "Adjust probability of silent aim redirecting shots",
	Callback = function(Value)
		st.hitchance = Value
	end,
})

MainRightGroup:AddDropdown("HitPartDropdown", {
	Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Random" },
	Default = "Head",
	Text = "Hit Part",
	Tooltip = "Select target body part",
	Callback = function(Value)
		st.hitpart = Value
	end,
})

VisualsRightGroup:AddToggle("ESPToggle", {
	Text = "ESP Box / Highlight",
	Default = false,
	Tooltip = "Draws highlights for teammates and enemies",
	Callback = function(Value)
		st.esp = Value
		if not st.esp then
			clearAllESP()
		end
	end,
})

VisualsLeftGroup:AddToggle("ArmFFToggle", {
	Text = "Arm ForceField",
	Default = false,
	Tooltip = "Applies forcefield material to arms",
	Callback = function(Value)
		st.armffenabled = Value
		if not st.armffenabled then
			restorearm()
		end
	end,
}):AddColorPicker("ArmFFColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Arm FF Color",
	Callback = function()
		if st.armffenabled then
			updateff()
		end
	end
})

VisualsLeftGroup:AddToggle("WeaponFFToggle", {
	Text = "Weapon ForceField",
	Default = false,
	Tooltip = "Applies forcefield material to weapons",
	Callback = function(Value)
		st.weaponffenabled = Value
		if not st.weaponffenabled then
			restorewpn()
		end
	end,
}):AddColorPicker("WeaponFFColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Weapon FF Color",
	Callback = function()
		if st.weaponffenabled then
			updateff()
		end
	end
})

VisualsLeftGroup:AddToggle("PurpleToggle", {
	Text = "Purple Lighting",
	Default = false,
	Tooltip = "Toggles purple ambient lighting",
	Callback = function(Value)
		st.purpleenabled = Value
		if st.purpleenabled then
			applypurple()
		else
			restorelight()
		end
	end,
}):AddColorPicker("PurpleColor", {
	Default = Color3.fromRGB(160, 110, 200),
	Title = "Ambient Color",
	Callback = function()
		if st.purpleenabled then
			applypurple()
		end
	end
})

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu Settings", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	st.enabled = false
	st.tpwalking = false
	if st.tpenabled then
		st.tpenabled = false
		local mychar = lp.Character
		local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
		if hrp and st.origcframe then
			hrp.CFrame = st.origcframe
		end
	end
	st.armffenabled = false
	st.weaponffenabled = false
	st.purpleenabled = false
	st.soundenabled = false
	st.beamenabled = false
	st.silentenabled = false
	st.esp = false
	clearAllESP()
	FOV_Circle.Visible = false
	FOV_Circle:Destroy()
	restorearm()
	restorewpn()
	restorelight()
	cleanup()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("KanlHub")
SaveManager:SetFolder("KanlHub/game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

Library:OnUnload(function()
	st.enabled = false
	st.tpwalking = false
	if st.tpenabled then
		st.tpenabled = false
		local mychar = lp.Character
		local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
		if hrp and st.origcframe then
			hrp.CFrame = st.origcframe
		end
	end
	st.armffenabled = false
	st.weaponffenabled = false
	st.purpleenabled = false
	st.soundenabled = false
	st.beamenabled = false
	st.silentenabled = false
	st.esp = false
	clearAllESP()
	FOV_Circle.Visible = false
	FOV_Circle:Destroy()
	restorearm()
	restorewpn()
	restorelight()
	cleanup()
end)

local old
old = hookmetamethod(game, "__namecall", function(self, ...)
	local method = getnamecallmethod()
	if st.silentenabled and cachedSilentTarget and not checkcaller() and self == workspace and (method == "Raycast" or method == "FindPartOnRay") then
		local chanceRoll = math.random(1, 100)
		if chanceRoll <= st.hitchance then
			local args = {...}
			local origin, direction
			if method == "Raycast" then
				origin, direction = args[1], args[2]
			else
				local ray = args[1]
				if typeof(ray) == "Ray" then
					origin, direction = ray.Origin, ray.Direction
				end
			end
			if origin and direction then
				return {
					Instance = cachedSilentTarget,
					Position = cachedSilentTarget.Position,
					Normal = (cachedSilentTarget.Position - origin).Unit,
					Material = Enum.Material.Plastic
				}
			end
		end
	end
	return old(self, ...)
end)

workspace.DescendantAdded:Connect(function(child)
	if st.purpleenabled then
		if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
			if not maplightcache[child] then
				maplightcache[child] = child.Color
			end
			local chosenColor = Options.PurpleColor and Options.PurpleColor.Value or Color3.fromRGB(160, 110, 200)
			child.Color = chosenColor
		end
	end
end)

runservice.Heartbeat:Connect(function()
	local targetforloop = getclosest()

	if st.tpenabled then
		if targetforloop then
			local mychar = lp.Character
			local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
			local targetchar = getmodel(targetforloop)
			local targethrp = targetchar and (targetchar:FindFirstChild("HumanoidRootPart") or targetchar:FindFirstChild("Head"))
			
			if hrp and targethrp then
				if not st.origcframe then
					st.origcframe = hrp.CFrame
				end
				hrp.CFrame = targethrp.CFrame * CFrame.new(0, 0, 7)
			end
		else
			if st.origcframe then
				local mychar = lp.Character
				local hrp = mychar and mychar:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = st.origcframe
				end
			end
		end
	end

	if not st.enabled then return end
	
	if targetforloop ~= st.target then
		cleanup()
		st.target = targetforloop
	end
	
	if st.target then
		updatevis(st.target)

		local canShoot = true
		if st.wallcheck then
			local targetchar = getmodel(st.target)
			local targetpart = targetchar and (targetchar:FindFirstChild("Head") or targetchar:FindFirstChild("HumanoidRootPart"))
			if targetpart then
				canShoot = isvisible(targetpart)
			end
		end
		
		local now = os.clock()
		if canShoot and now - st.lastshot >= st.interval then
			st.lastshot = now
			bang(st.target)
		end
	else
		cleanup()
	end
end)

runservice.RenderStepped:Connect(function()
	updateESP()

	if st.silentenabled and tick() - lastSilentUpdate > silentUpdateDelay then
		lastSilentUpdate = tick()
		updateSilentTarget()
	end

	local now = os.clock()
	if now - lastcheck >= 0.1 then
		lastcheck = now
		if st.armffenabled or st.weaponffenabled then
			updateff()
		end
	end
end)

SaveManager:LoadAutoloadConfig()
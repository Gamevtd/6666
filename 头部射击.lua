local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -22)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
OpenBtn.BackgroundTransparency = 0.4
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Text = "展开"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 13
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true

local OpenCorner = Instance.new("UICorner", OpenBtn)
OpenCorner.CornerRadius = UDim.new(0, 8)
local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Color = Color3.fromRGB(200, 200, 200)
OpenStroke.Transparency = 0.7

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 180, 0, 270)
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.4
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(200, 200, 200)
UIStroke.Transparency = 0.7
UIStroke.Thickness = 1

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -30, 0, 30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "杀戮光环面板"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Text = "一"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14

MinimizeBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	OpenBtn.Visible = false
end)

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, 0, 1, -30)
Container.Position = UDim2.new(0, 0, 0, 30)
Container.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0, 8)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	MainFrame.Size = UDim2.new(0, 180, 0, UIListLayout.AbsoluteContentSize.Y + 45)
end)

local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.85, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.85
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.AutoButtonColor = true
	
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 6)
	
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = Color3.fromRGB(255, 255, 255)
	btnStroke.Transparency = 0.8
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	btn.Parent = Container
	return btn
end

local function createSlider(text, min, max, default)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.85, 0, 0, 45)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 6)
	
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = text .. ": " .. default
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	
	local sliderBg = Instance.new("Frame", frame)
	sliderBg.Size = UDim2.new(0.9, 0, 0, 6)
	sliderBg.Position = UDim2.new(0.05, 0, 0, 28)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
	
	local sliderFill = Instance.new("Frame", sliderBg)
	sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
	
	local sliderBtn = Instance.new("TextButton", sliderBg)
	sliderBtn.Size = UDim2.new(1, 0, 1, 16)
	sliderBtn.Position = UDim2.new(0, 0, 0.5, -8)
	sliderBtn.BackgroundTransparency = 1
	sliderBtn.Text = ""
	
	local val = default
	local dragging = false
	
	local function update(input)
		local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		val = math.floor(min + ((max - min) * pos))
		label.Text = text .. ": " .. val
	end
	
	sliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	frame.Parent = Container
	return frame, function() return val end
end

local AuraBtn = createButton("杀戮光环: 关")
local TeamCheckBtn = createButton("队伍检测: 开")
local RadiusSliderFrame, getRadius = createSlider("攻击范围", 10, 1000, 200)
local SpeedSliderFrame, getSpeed = createSlider("间隔(0.1秒)", 0, 20, 1)

TeamCheckBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
TeamCheckBtn.BackgroundTransparency = 0.6

local isAuraActive = false
local useTeamCheck = true
local auraConnection = nil
local lastAttackTime = 0

TeamCheckBtn.MouseButton1Click:Connect(function()
	useTeamCheck = not useTeamCheck
	if useTeamCheck then
		TeamCheckBtn.Text = "队伍检测: 开"
		TeamCheckBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		TeamCheckBtn.BackgroundTransparency = 0.6
	else
		TeamCheckBtn.Text = "队伍检测: 关"
		TeamCheckBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TeamCheckBtn.BackgroundTransparency = 0.85
	end
end)

local function getClosestValidTarget(radius)
	local closestTarget = nil
	local shortestDistance = radius
	
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
	local myPos = char.HumanoidRootPart.Position

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then
			if useTeamCheck and p.Team == player.Team then continue end
			local pChar = p.Character
			if pChar and pChar:FindFirstChild("HumanoidRootPart") then
				local hum = pChar:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local dist = (pChar.HumanoidRootPart.Position - myPos).Magnitude
					if dist <= shortestDistance then
						shortestDistance = dist
						closestTarget = pChar
					end
				end
			end
		end
	end

	local charsFolder = workspace:FindFirstChild("Characters")
	if charsFolder then
		for _, obj in pairs(charsFolder:GetChildren()) do
			if obj:IsA("Model") and obj ~= char and not Players:GetPlayerFromCharacter(obj) then
				local hum = obj:FindFirstChildOfClass("Humanoid")
				local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head")
				if hum and hum.Health > 0 and root then
					local dist = (root.Position - myPos).Magnitude
					if dist <= shortestDistance then
						shortestDistance = dist
						closestTarget = obj
					end
				end
			end
		end
	end

	return closestTarget
end

local function performAura()
	local GunRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("GunRemote")
	if not GunRemote then return end

	local char = player.Character
	if not char then return end
	
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	local radius = getRadius()
	local targetChar = getClosestValidTarget(radius)

	if targetChar then
		local interval = getSpeed() * 0.1
		local currentTime = tick()
		
		if currentTime - lastAttackTime >= interval then
			lastAttackTime = currentTime
			
			local targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
			
			if targetPart then
				pcall(function()
					GunRemote:FireServer(
						1,
						tool,
						targetPart.Position, 
						Vector3.new(0, 1, 0),
						targetPart 
					)
				end)
			end
		end
	end
end

AuraBtn.MouseButton1Click:Connect(function()
	isAuraActive = not isAuraActive
	if isAuraActive then
		AuraBtn.Text = "杀戮光环: 开"
		AuraBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		AuraBtn.BackgroundTransparency = 0.6
		
		auraConnection = RunService.Heartbeat:Connect(performAura)
	else
		AuraBtn.Text = "杀戮光环: 关"
		AuraBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		AuraBtn.BackgroundTransparency = 0.85
		
		if auraConnection then
			auraConnection:Disconnect()
			auraConnection = nil
		end
	end
end)
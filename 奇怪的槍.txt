local unloaded = false
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "NXP hub V2",
    Footer = "汉化版 汉化者: BH-CHANGED工作室",
    Icon = "rbxassetid://130931198530758",
    NotifySide = "Right",
    ShowCustomCursor = true,
    Size = UDim2.fromOffset(736, 361)
})

local Tabs = {
    Guns = Window:AddTab("改枪", "sword"),
    SilentAim = Window:AddTab("追踪", "zap"),
    ESP = Window:AddTab("绘制", "eye"),
    Player = Window:AddTab("玩家", "navigation"),
    ["UI Settings"] = Window:AddTab("UI", "settings"),
}

local services = setmetatable({}, {
    __index = function(_, name)
        return cloneref(game:GetService(name))
    end
})

local replicatedStorage = services.ReplicatedStorage
local players = services.Players
local localPlayer = players.LocalPlayer
local uis = services.UserInputService

local function getGun()
    local char = localPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            return tool
        end
    end
end

local function getTargets()
    local targets = {}
    for i, v in pairs(workspace.ServerBots.GetChildren(workspace.ServerBots)) do
        table.insert(targets, v.HumanoidRootPart)
    end
    for i, v in pairs(players.GetPlayers(players)) do
        if v ~= localPlayer and v.Character and v.Character.FindFirstChild(v.Character, "HumanoidRootPart") and v.Character.FindFirstChild(v.Character, "Humanoid") then
            table.insert(targets, v.Character.HumanoidRootPart)
        end
    end
    return targets
end
local function getTargets2()
    local targets = {}
    for i, v in pairs(workspace.ServerBots.GetChildren(workspace.ServerBots)) do
        table.insert(targets, {Character = v})
    end
    for i, v in pairs(players.GetPlayers(players)) do
        if v ~= localPlayer and v.Character and v.Character.FindFirstChild(v.Character, "HumanoidRootPart") and v.Character.FindFirstChild(v.Character, "Humanoid") then
            table.insert(targets, v)
        end
    end
    return targets
end

local blasterModule = require(replicatedStorage.Shared.ReplicatedBlaster.Scripts.BlasterController)
local guiController
local old; old = hookfunction(blasterModule.shoot, newcclosure(function(p70, p71, p72, p73)
    if p70 then
        guiController = p70
    end
    return old(p70, p71, p72, p73)
end))

local GunModsBox = Tabs.Guns:AddLeftGroupbox("改枪", "sword")
GunModsBox:AddToggle("InfiniteAmmo", {
    Text = "无限子弹"
})
GunModsBox:AddToggle("NoRecoil", {
    Text = "无后座"
})
GunModsBox:AddToggle("FastGun", {
    Text = "射击速度"
})
GunModsBox:AddToggle("AlwaysHeadshot", {
    Text = "打身体改爆头"
})

local old; old = hookfunction(blasterModule.canShoot, newcclosure(function(...)
    local blaster = ({...})[1]
    if Toggles.InfiniteAmmo.Value and not unloaded then
        blaster.ammo = 100
        return true
    end
    return old(...)
end))
local old; old = hookfunction(blasterModule.recoil, newcclosure(function(...)
    if Toggles.NoRecoil.Value and not unloaded then
        return nil
    end
    return old(...)
end))
task.spawn(function()
    while not unloaded do
        if Toggles.FastGun.Value then
            local gun = getGun()
            if gun then gun:SetAttribute("rateOfFire", 20000) end
        end
        task.wait()
    end
end)
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    if not checkcaller() and self == replicatedStorage.Events.Shoot then
        local targets = args[5]
        for i, v in pairs(targets) do
            if Toggles.AlwaysHeadshot.Value then
                v[2] = true
                v[3] = false
            end
        end
    end
    return old(self, unpack(args))
end)

local SilentAimCircle = Drawing.new("Circle")
SilentAimCircle.Thickness = 2
SilentAimCircle.NumSides = 64
SilentAimCircle.Radius = 120
SilentAimCircle.Filled = false
SilentAimCircle.Color = Color3.fromRGB(255, 255, 255)
SilentAimCircle.Visible = false

local function getPlayersInFOV()
    local found = {}
    for _, root in pairs(getTargets()) do
        local screenPos, onScreen = workspace.CurrentCamera.worldToViewportPoint(workspace.CurrentCamera, root.Position)
        if onScreen then
            local screenVec = Vector2.new(screenPos.X, screenPos.Y)
            local dist = (screenVec - SilentAimCircle.Position).magnitude
            if dist <= SilentAimCircle.Radius then
                table.insert(found, root.Parent.Humanoid)
            end
        end
    end
    return found
end

local SilentAimBox = Tabs.SilentAim:AddLeftGroupbox("子弹追踪", "zap")
local SilentAimSettings = Tabs.SilentAim:AddRightGroupbox("配置", "settings")
SilentAimBox:AddToggle("SilentAim", {
    Text = "启用追踪",
    Tooltip = "...",
})
SilentAimBox:AddToggle("SilentAimCircle", {
    Text = "追踪圈圈",
})
SilentAimBox:AddSlider("SilentAimRadius", {
    Text = "圈圈大小",
    Default = 120,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Compact = false,
})
SilentAimBox:AddSlider("SilentAimSides", {
    Text = "边",
    Default = 64,
    Min = 1,
    Max = 64,
    Rounding = 0,
    Compact = false,
})
SilentAimBox:AddLabel("Circle Color"):AddColorPicker("SilentAimColor", {
    Default = Color3.new(1, 1, 1),
    Title = "圈圈颜色",
    Transparency = 0,
})
SilentAimSettings:AddDropdown("SilentAimPart", {
    Values = {"Head", "Root"},
    Default = 1,
    Text = "追踪部位",
})
SilentAimSettings:AddToggle("SilentAimTargetRandom", {
    Text = "随机部位",
})

game:GetService("RunService").RenderStepped:Connect(function()
    SilentAimCircle.Position = Vector2.new(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
    SilentAimCircle.Radius = Options.SilentAimRadius.Value
    SilentAimCircle.NumSides = Options.SilentAimSides.Value
    SilentAimCircle.Color = Options.SilentAimColor.Value
    if Toggles.SilentAim.Value then
        if Toggles.SilentAimCircle.Value then
            SilentAimCircle.Visible = true
        else
            SilentAimCircle.Visible = false
        end
    else
        SilentAimCircle.Visible = false
    end
end)

local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    if not checkcaller() and self == replicatedStorage.Events.Shoot then
        local targets = args[5]
        if Toggles.SilentAim.Value then
            for i, v in pairs(getPlayersInFOV()) do
                local isH = Toggles.SilentAimTargetRandom.Value and (math.random(1, 2) == 1) or (Options.SilentAimPart.Value == "Head")
                targets[tostring(i)] = {
                    v.Parent.Humanoid,
                    isH,
                    not isH,
                    0
                }
            end
        end
    end
    return old(self, unpack(args))
end)

local TracersBox = Tabs.ESP:AddLeftGroupbox("ESP 射线", "line-squiggle")
TracersBox:AddToggle("Tracers", {
    Text = "启用",
    Tooltip = "...",
})
TracersBox:AddDropdown("TracersPosition", {
	Values = {"顶部", "中间", "底部"},
	Default = 1, -- number index of the value / string
	Text = "射线位置",
})
TracersBox:AddLabel("Tracers Color"):AddColorPicker("TracersColor", {
    Text = "射线颜色",
    Default = Color3.fromRGB(255, 0, 0)
})

local BoxesBox = Tabs.ESP:AddLeftGroupbox("ESP 盒子", "boxes")
BoxesBox:AddToggle("Boxes", {
    Text = "启用盒子",
    Tooltip = "Draws boxes around the enemy",
})
BoxesBox:AddLabel("Boxes Color"):AddColorPicker("BoxesColor", {
    Text = "盒子颜色",
    Default = Color3.fromRGB(255, 0, 0)
})

local LeftGroupBox = Tabs.Player:AddLeftGroupbox("速度调节", "navigation")
LeftGroupBox:AddToggle("Speedhack", {
    Text = "启用速度",
    Tooltip = "...",
})
LeftGroupBox:AddSlider("SpeedValue", {
    Text = "调节速度",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
})

-- Speed
task.spawn(function ()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    while true do
        task.wait()
        if not Toggles.Speedhack.Value then continue end
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.MoveDirection ~= Vector3.zero then
            LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * Options.SpeedValue.Value * services.RunService.RenderStepped:Wait())
        end
    end
end)

do
    local function TracersESP(Player)
        local Line = Drawing.new("Line")
        Line.Visible = false
        Line.Thickness = 2
        Line.Transparency = 1
        services.RunService.RenderStepped:Connect(function()
            Line.Color = Options.TracersColor.Value
            if not Toggles.Tracers.Value then
                Line.Visible = false
                return
            end
            local Root = Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                local Vector, OnScreen = workspace.CurrentCamera:worldToViewportPoint(Root.Position)
                Line.Visible = OnScreen
                Line.To = Vector2.new(Vector.X, Vector.Y)
                local Y
                if Options.TracersPosition.Value == "底部" then
                    Y = workspace.CurrentCamera.ViewportSize.Y
                elseif Options.TracersPosition.Value == "中间" then
                    Y = workspace.CurrentCamera.ViewportSize.Y / 2
                elseif Options.TracersPosition.Value == "顶部" then
                    Y = 0
                end

                Line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, Y)
            else
                Line.Visible = false
            end
        end)
    end
    local function BoxESP(Player)
        local Outline = Drawing.new("Square")
        local Box = Drawing.new("Square")

        Outline.Visible = false
        Outline.Thickness = 3
        Outline.Color = Color3.fromRGB(0, 0, 0)
        Box.Visible = false
        Box.Thickness = 1

        services.RunService.RenderStepped:Connect(function()
            Box.Color = Options.BoxesColor.Value
            if not Toggles.Boxes.Value then
                Outline.Visible = false
                Box.Visible = false
                return
            end
            local Root = Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                local Vector, OnScreen = workspace.CurrentCamera:worldToViewportPoint(Root.Position)
                Box.Visible = OnScreen
                Outline.Visible = OnScreen
                pcall(function()
                    local HeadPos = workspace.CurrentCamera:worldToViewportPoint(Player.Character.Head.Position + Vector3.new(0, 0.5, 0))
                    local LegPos = workspace.CurrentCamera:worldToViewportPoint(Player.Character.Head.Position + Vector3.new(0, -3, 0))

                    Outline.Size = Vector2.new(1000 / Vector.Z, HeadPos.Y - LegPos.Y)
                    Outline.Position = Vector2.new(Vector.X - Outline.Size.X / 2, Vector.Y - Outline.Size.Y / 2)
                    Box.Size = Vector2.new(1000 / Vector.Z, HeadPos.Y - LegPos.Y)
                    Box.Position = Vector2.new(Vector.X - Box.Size.X / 2, Vector.Y - Box.Size.Y / 2)
                end)
            else
                Box.Visible = false
                Outline.Visible = false
            end
        end)
    end
    for i, v in pairs(getTargets2()) do
        if v ~= localPlayer then
            TracersESP(v)
            BoxESP(v)
        end
    end
    workspace.ServerBots.ChildAdded:Connect(function(v)
        task.wait(1)
        TracersESP({Character = v})
        BoxESP({Character = v})
    end)
    players.PlayerAdded:Connect(TracersESP)
    players.PlayerAdded:Connect(BoxESP)
end

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "打开键位窗口",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "自定义光标",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "通知位置",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "UI 大小",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("键位"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "窗口打开键位" })

MenuGroup:AddButton("销毁 UI", function()
    unloaded = true
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("NXP_Hub")
SaveManager:SetFolder("NXP_Hub/wgg")
SaveManager:SetSubFolder("wgg")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
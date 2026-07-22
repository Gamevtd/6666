local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local CharFolder = Workspace:WaitForChild("Character")
local WeaponHit = ReplicatedStorage:WaitForChild("WeaponsSystem"):WaitForChild("Network"):WaitForChild("WeaponHit")
local WeaponFired = ReplicatedStorage:WaitForChild("WeaponsSystem"):WaitForChild("Network"):WaitForChild("WeaponFired")

task.spawn(function()
    while task.wait(0.3) do
        local char = CharFolder:FindFirstChild(LocalPlayer.Name)
        if not char then continue end
        
        local weapon = char:FindFirstChildOfClass("Tool")
        if not weapon then continue end

        local isMelee = not weapon:FindFirstChild("AmmoCapacity", true)

        for _, obj in pairs(CharFolder:GetChildren()) do
            if obj:IsA("Model") and obj ~= char then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local head = obj:FindFirstChild("Head")
                
                if hum and head and hum.Health > 0 then
                    local player = Players:GetPlayerFromCharacter(obj)
                    if player and player.Team == LocalPlayer.Team and not player.Neutral then continue end

                    local pos = head.Position

                    if isMelee then
                        local args = {
                            [1] = weapon,
                            [2] = {
                                attackType = "Normal",
                                comboIndex = 1,
                                position = pos
                            }
                        }
                        WeaponFired:FireServer(unpack(args))
                    else
                        local args = {
                            [1] = weapon,
                            [2] = {
                                p = pos,
                                pid = 1,
                                part = head,
                                d = 1,
                                maxDist = math.huge,
                                h = hum,
                                m = Enum.Material.Snow,
                                n = Vector3.new(1, 0, 0),
                                t = tick() % 1,
                                sid = math.random(1, 10)
                            }
                        }
                        WeaponHit:FireServer(unpack(args))
                    end
                end
            end
        end
    end
end)
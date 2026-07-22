local Players = game:GetService("Players")
local stored = setmetatable({}, {__mode = "k"})

workspace.DescendantAdded:Connect(function(obj)
    if not obj:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(obj) then return end

    local hum
    hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = obj:FindFirstChild("AnimationController")
    end
    if not hum then return end

    local parts = {"Head", "HumanoidRootPart", "UpperTorso"}
    for _, name in ipairs(parts) do
        local p = obj:FindFirstChild(name)
        if p and p:IsA("BasePart") and not stored[p] then
            stored[p] = p.Size
            p.Size = p.Size * 4
            p.Transparency = 0.25
            p.CanCollide = false

            p.Destroying:Once(function()
                if stored[p] then
                    p.Size = stored[p]
                    stored[p] = nil
                end
            end)
        end
    end
end)

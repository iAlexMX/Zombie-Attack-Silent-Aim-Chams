local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local headName = "Head"
local aimbotEnabled = false
local ESPEnabled = false
local aimbotFOV = 110
local CoreGui = game:GetService("StarterGui")


local SoundService = game:GetService("SoundService")

local activateSound = Instance.new("Sound")
activateSound.SoundId = "rbxassetid://1584394759"
activateSound.Volume = 10
activateSound.Name = "ActivateSound"
activateSound.Parent = SoundService

local deactivateSound = Instance.new("Sound")
deactivateSound.SoundId = "rbxassetid://124018322190013"
deactivateSound.Volume = 10
deactivateSound.Name = "DeactivateSound"
deactivateSound.Parent = SoundService

local powerupActivateSound = Instance.new("Sound")
powerupActivateSound.SoundId = "rbxassetid://94104410894028"
powerupActivateSound.Volume = 10
powerupActivateSound.Name = "PowerupActivateSound"
powerupActivateSound.Parent = SoundService

local powerupDeactivateSound = Instance.new("Sound")
powerupDeactivateSound.SoundId = "rbxassetid://123916794869472"
powerupDeactivateSound.Volume = 10
powerupDeactivateSound.Name = "PowerupDeactivateSound"
powerupDeactivateSound.Parent = SoundService


local function showNotification(text)
    CoreGui:SetCore("SendNotification", {
        Title = "Aim/Chams",
        Text = text,
        Duration = 0.5
    })
end


local function createChams(target)
    if not target or target:FindFirstChild("Chams_ESP") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Chams_ESP"
    highlight.Adornee = target
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = target
end


local function updateChamsColor(target)
    local char = player.Character
    if not char or not target or not target:FindFirstChild(headName) then return end

    local origin = char:FindFirstChild(headName)
    if not origin then return end

    local head = target:FindFirstChild(headName)
    local direction = (head.Position - origin.Position).Unit * (head.Position - origin.Position).Magnitude

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {char}

    local result = workspace:Raycast(origin.Position, direction, params)

    local highlight = target:FindFirstChild("Chams_ESP")
    if highlight and highlight:IsA("Highlight") then
        if result and not result.Instance:IsDescendantOf(target) then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
        else
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
        end
    end
end


local function clearChams()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:FindFirstChild("Chams_ESP") then
            obj:FindFirstChild("Chams_ESP"):Destroy()
        end
    end
end


local function getClosestToCursor()
    local closestDist = math.huge
    local closestTarget = nil
    local character = player.Character
    local origin = character and character:FindFirstChild(headName) and character[headName].Position

    if not origin then return nil end

    for _, u in pairs(workspace:GetDescendants()) do
        if u:FindFirstChild(headName) and not u:FindFirstChild("Guns") and u.Parent.Name ~= "deadenemies" and u ~= character then
            local head = u[headName]
            local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(head.Position)
            if onScreen then
                local cursorDist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude

                local direction = (head.Position - origin).Unit * (head.Position - origin).Magnitude
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist

                local result = workspace:Raycast(origin, direction, rayParams)
                if result == nil or result.Instance:IsDescendantOf(u) then
                    if cursorDist < closestDist and cursorDist < aimbotFOV then
                        closestDist = cursorDist
                        closestTarget = u
                    end
                end
            end
        end
    end

    return closestTarget
end


local rawMeta = getrawmetatable(game)
local oldIndex = rawMeta.__index
setreadonly(rawMeta, false)

rawMeta.__index = newcclosure(function(self, key)
    if self == mouse and tostring(key) == "Hit" then
        if aimbotEnabled then
            local target = getClosestToCursor()
            return target and target:FindFirstChild(headName).CFrame or oldIndex(self, key)
        end
    end
    return oldIndex(self, key)
end)

setreadonly(rawMeta, true)


local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.V then
        aimbotEnabled = not aimbotEnabled
        ESPEnabled = aimbotEnabled

        if ESPEnabled then
            showNotification("ACTIVADO")
            activateSound:Play()

            task.delay(1.7, function()
                CoreGui:SetCore("SendNotification", {
                    Title = "Script",
                    Text = "by AlexScriptX",
                    Duration = 3
                })
            end)
        else
            showNotification("DESACTIVADO")
            deactivateSound:Play()
            clearChams()
        end
    end
end)


task.spawn(function()
    while true do
        if ESPEnabled then
            for _, u in pairs(workspace:GetDescendants()) do
                if u:FindFirstChild(headName) and not u:FindFirstChild("Guns") and u.Parent.Name ~= "deadenemies" and u ~= player.Character then
                    createChams(u)
                    updateChamsColor(u)
                end
            end
        end
        task.wait(0.3)
    end
end)

local player = game:GetService("Players").LocalPlayer
local uis = game:GetService("UserInputService")
local powerupsActive = false


local function collectPowerups()
    local powerups = workspace:FindFirstChild("Powerups")
    if powerups then
        for _, powerup in ipairs(powerups:GetChildren()) do
            if powerup:FindFirstChild("Part") then
                firetouchinterest(player.Character.HumanoidRootPart, powerup.Part, 0)
            end
        end
    end
end


uis.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
        powerupsActive = not powerupsActive
        
        if powerupsActive then
            powerupActivateSound:Play()
        else
            powerupDeactivateSound:Play()
        end

        game.StarterGui:SetCore("SendNotification", {
            Title = "Auto Powerups",
            Text = powerupsActive and "ACTIVADO" or "DESACTIVADO",
            Duration = 0.3
        })
    end
end)


while wait(0.1) do
    if powerupsActive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        collectPowerups()
    end
end

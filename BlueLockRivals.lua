local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local GameValues = ReplicatedStorage.GameValues
local SlideRemote = ReplicatedStorage.Packages.Knit.Services.BallService.RE.Slide
local ShootRemote = ReplicatedStorage.Packages.Knit.Services.BallService.RE.Shoot
local GoalsFolder = workspace.Goals
local AwayGoal, HomeGoal = GoalsFolder.Away, GoalsFolder.Home

local function IsInGame()
    return GameValues.State.Value == "Playing"
end

local function IsVisitor()
    return LocalPlayer.Team.Name == "Visitor"
end

local function JoinGame()
    if not IsVisitor() then return end
    for _, v in ipairs(ReplicatedStorage.Teams:GetDescendants()) do
        if v:IsA("ObjectValue") and v.Value == nil then
            local args = {string.sub(v.Parent.Name, 1, #v.Parent.Name - 4), v.Name}
            ReplicatedStorage.Packages.Knit.Services.TeamService.RE.Select:FireServer(unpack(args))
        end
    end
end

local function StealBall()
    if not IsInGame() then return end
    local LocalCharacter = LocalPlayer.Character
    local LocalHumanoidRootPart = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    local Football = workspace:FindFirstChild("Football")

    if LocalHumanoidRootPart and Football and Football.Char.Value ~= LocalPlayer.Character then
        LocalHumanoidRootPart.CFrame = Football.CFrame
    end

    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        if OtherPlayer ~= LocalPlayer and OtherPlayer.Team ~= LocalPlayer.Team then
            local OtherCharacter = OtherPlayer.Character
            local OtherFootball = OtherCharacter and OtherCharacter:FindFirstChild("Football")
            local OtherHRP = OtherCharacter and OtherCharacter:FindFirstChild("HumanoidRootPart")
            
            if OtherFootball and OtherHRP and LocalHumanoidRootPart then
                LocalHumanoidRootPart.CFrame = OtherFootball.CFrame
                SlideRemote:FireServer()
                break
            end
        end
    end
end

coroutine.resume(coroutine.create(function()
    RunService.RenderStepped:Connect(function()
        if not _G.START then return end
        pcall(function()
            JoinGame()
            if IsVisitor() and not IsInGame() then return end
            StealBall()
            
            local LocalCharacter = LocalPlayer.Character
            local PlayerFootball = LocalCharacter and LocalCharacter:FindFirstChild("Football")

            if PlayerFootball then
                ShootRemote:FireServer(60, nil, nil, Vector3.new(-0.6976264715194702, -0.3905344605445862, -0.6006664633750916))
            end

            local Football = workspace:FindFirstChild("Football")
            if Football and Football.Char.Value ~= LocalPlayer.Character then return end

            if Football:FindFirstChild("BodyVelocity") then
                Football.BodyVelocity:Destroy()
            end

            local Goal = LocalPlayer.Team.Name == "Away" and AwayGoal or HomeGoal
            local BV = Instance.new("BodyVelocity")
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BV.Parent = Football

            Football.CFrame = Goal.CFrame * CFrame.new(0, 14, math.random(-20, 20))

            task.delay(0.1, function()
                BV:Destroy()
            end)
        end)
    end)
end))

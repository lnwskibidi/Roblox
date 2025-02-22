local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local MapFolder = workspace:WaitForChild("map")
local AGoal = MapFolder:WaitForChild("Agoal")
local BGoal = MapFolder:WaitForChild("Bgoal")

local LocalPlayer = Players.LocalPlayer

local function IsInGame()
    local LocalCharacter = LocalPlayer.Character
    if not LocalCharacter then return end

    local StateFolder = LocalCharacter:FindFirstChild("state")
    if not StateFolder then return end

    local InGameValue = StateFolder:FindFirstChild("ingame")
    if not InGameValue then return end

    return InGameValue.Value
end

local function DisableCollisionBoxes()
    local MapFolder = workspace:FindFirstChild("map")
    if not MapFolder then return end

    local GkBarriar = MapFolder:FindFirstChild("gkbarriar")
    local AGoal = MapFolder:FindFirstChild("Agoal")
    local BGoal = MapFolder:FindFirstChild("Bgoal")

    if GkBarriar then
        local ABarriar = GkBarriar:FindFirstChild("A")
        local BBarriar = GkBarriar:FindFirstChild("B")

        if ABarriar then ABarriar.CanCollide = false end
        if BBarriar then BBarriar.CanCollide = false end
    end

    if AGoal then AGoal.CanCollide = false end
    if BGoal then BGoal.CanCollide = false end
end

local function StealBall()
    local LocalCharacter = LocalPlayer.Character
    local LocalHumanoidRootPart = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    local Football = workspace.Terrain:FindFirstChild("Ball")

    if LocalHumanoidRootPart and Football then
        LocalHumanoidRootPart.CFrame = CFrame.new(Football.Position.X, 0, Football.Position.Z)
    end
    
    for _, OtherPlayer in pairs(Players:GetPlayers()) do
        if OtherPlayer.Name ~= LocalPlayer.Name then
            local OtherCharacter = OtherPlayer.Character
            local OtherFootball = OtherCharacter and OtherCharacter:FindFirstChild("Ball")
            local OtherHumanoidRootPart = OtherCharacter and OtherCharacter:FindFirstChild("HumanoidRootPart")
            if OtherFootball and OtherHumanoidRootPart and LocalHumanoidRootPart then
                LocalHumanoidRootPart.CFrame = OtherFootball.CFrame
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            end
        end
    end
end

local function HasBall()
    local LocalCharacter = LocalPlayer.Character
    local Football = LocalCharacter and LocalCharacter:FindFirstChild("Ball")
    if Football then
        return true
    end
    return false
end

coroutine.resume(coroutine.create(function()
    RunService.RenderStepped:Connect(function()
        if not _G.AUTO_GOAL then return end
        pcall(function()
            if not IsInGame() == true then return end
            DisableCollisionBoxes()
            StealBall()
            if HasBall() == true then
                local LocalCharacter = LocalPlayer.Character
                local LocalRootPart = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
                local Goal = LocalPlayer.Team.Name == "A" and BGoal or AGoal

                if not LocalRootPart then return end
                LocalRootPart.CFrame = Goal.CFrame
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end)
    end)
end))
return function()
-- // Configurations
local SilentAimSettings = {


    -- \\ General
    Enabled         =      true,
    VisibleCheck    =      true,
    TargetPart      =      "Head",
    DownCheck       =      true,


    -- \\ Prediction
    Prediction      = {
        Enabled     =      true,
        Method      =      "AssemblyLinearVelocity",
        Options     = {"AssemblyLinearVelocity", "Velocity", "HumanoidState", "CFrameLerp", "CharacterController", "HumanoidMoveDirection", "SmoothVelocity"},
        X           =      0.7,
        Y           =      0.5,
        Z           =      0.6,
        TimeScale   =      0.7,
        DistanceScaling = true,
        MaxDistance =      1000,
        MinScale    =      0.4,
        MaxScale    =      0.7
    },


    -- \\ FOV Circle
    Visible         =      true,
    Filled          =      false,
    Radius          =      100,
    Color           =    Color3.fromRGB(98, 114, 164),
    Transparency    =      1,
    Thickness       =      1,
    ZIndex          =      999,
    NumSides        =      100,
    Rainbow         =      false,
    RainbowSpeed    =      0,




    -- \\ Raycast
    ExpectedArguments = {
        Raycast = {
            ArgCountRequired = 3,
            Args = {
                "Instance", "Vector3", "Vector3", "RaycastParams"
            }
        }
    }
}
-- ==============================================================





-- // Dependencies
local Players           =       game:GetService("Players")
local RunService        =       game:GetService("RunService")
local UserInputService  =       game:GetService("UserInputService")


local Camera                    =       workspace.CurrentCamera
local LocalPlayer               =       Players.LocalPlayer
local GetPlayers                =       Players.GetPlayers
local WorldToScreen             =       Camera.WorldToScreenPoint
local GetPartsObscuringTarget   =       Camera.GetPartsObscuringTarget
local FindFirstChild            =       game.FindFirstChild
local RenderStepped             =       RunService.RenderStepped
local GetMouseLocation          =       UserInputService.GetMouseLocation
local MatchingArgumentCount     =       0
local oldNamecall               =       nil
local ColorHue                  =       0
-- ======================================================================





-- // FOV Circle
local FOVCircle         =       Drawing.new("Circle")
FOVCircle.Thickness     =       SilentAimSettings.Thickness
FOVCircle.NumSides      =       SilentAimSettings.NumSides
FOVCircle.Radius        =       SilentAimSettings.Radius
FOVCircle.Filled        =       SilentAimSettings.Filled
FOVCircle.Visible       =       SilentAimSettings.Visible
FOVCircle.ZIndex        =       SilentAimSettings.ZIndex
FOVCircle.Color         =       SilentAimSettings.Color
FOVCircle.Transparency  =       SilentAimSettings.Transparency



coroutine.resume(coroutine.create(function()
    RenderStepped:Connect(function(DeltaTime)
        -- Update FOV Circle
        FOVCircle.Visible      =       SilentAimSettings.Visible
        FOVCircle.NumSides     =       SilentAimSettings.NumSides
        FOVCircle.Transparency =       SilentAimSettings.Transparency
        FOVCircle.Radius       =       SilentAimSettings.Radius
        FOVCircle.Filled       =       SilentAimSettings.Filled
        FOVCircle.Position     =       GetMouseLocation(UserInputService)

        if SilentAimSettings.Rainbow then
            FOVCircle.Color    =       Color3.fromHSV(ColorHue, 1, 1)
            ColorHue           =       (ColorHue + DeltaTime * SilentAimSettings.RainbowSpeed) % 1
        else
            FOVCircle.Color    =       SilentAimSettings.Color
        end
    end)
end))
-- ===============================================================================





-- // GetPositionOnScreen
local function GetPositionOnScreen(PositionVector)
    local ScreenPosition, IsOnScreen = WorldToScreen(Camera, PositionVector)
    return Vector2.new(ScreenPosition.X, ScreenPosition.Y), IsOnScreen
end
-- =========================================================================





-- // ValidateArguments
local function ValidateArguments(Arguments, RayMethodDefinition)
    if #Arguments < RayMethodDefinition.ArgCountRequired then
        return false
    end

    for ArgumentPosition, ArgumentValue in next, Arguments do
        if typeof(ArgumentValue) == RayMethodDefinition.Args[ArgumentPosition] then
            MatchingArgumentCount = MatchingArgumentCount + 1
        end
    end

    return MatchingArgumentCount >= RayMethodDefinition.ArgCountRequired
end
-- =================================================================================





-- // GetDirection
local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 9999
end
-- ==========================================





-- // GetMousePosition
local function getMousePosition()
    return GetMouseLocation(UserInputService)
end
-- ==========================================





-- // GetClosestPlayer
local function getClosestPlayer()
    local Closest
    local DistanceToMouse


    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end

        local Character = Player.Character
        if not Character then continue end


        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local TargetPart = FindFirstChild(Character, SilentAimSettings.TargetPart)
        if not TargetPart then
            TargetPart = HumanoidRootPart
        end


        if SilentAimSettings.VisibleCheck then
            local LocalPlayerCharacter = LocalPlayer.Character
            if not LocalPlayerCharacter then continue end

            local CastPoints = {TargetPart.Position, LocalPlayerCharacter, Character}
            local IgnoreList = {LocalPlayerCharacter, Character}
            local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)

            if ObscuringObjects > 0 then continue end
        end

        if SilentAimSettings.DownCheck then
            local State = FindFirstChild(Character, "State")
            local Down = State and FindFirstChild(State, "Down")
            if not Down or Down.Value then continue end
        end

        local ScreenPosition, OnScreen = GetPositionOnScreen(HumanoidRootPart.Position)

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if OnScreen and Distance <= (DistanceToMouse or SilentAimSettings.Radius or 9000) then
            Closest = TargetPart
            DistanceToMouse = Distance
        end
    end


    return Closest
end
-- ===================================================================================================





-- // Hooking
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]

    if self == workspace and not checkcaller() and SilentAimSettings.Enabled then
        if Method == "Raycast" then
            if ValidateArguments(Arguments, SilentAimSettings.ExpectedArguments.Raycast) then

                local A_Origin = Arguments[2]
                local HitPart = getClosestPlayer()

                if HitPart then
                    local PredictedPosition = HitPart.Position

                    if SilentAimSettings.Prediction.Enabled then
                        local Character = HitPart.Parent
                        local HumanoidRootPart = Character and FindFirstChild(Character, "HumanoidRootPart")
                        local Humanoid = Character and FindFirstChild(Character, "Humanoid")

                        local PredictionMethod = SilentAimSettings.Prediction.Method
                        local ScaleVector = Vector3.new(
                            SilentAimSettings.Prediction.X,
                            SilentAimSettings.Prediction.Y,
                            SilentAimSettings.Prediction.Z
                        )

                        local TimeScale = SilentAimSettings.Prediction.TimeScale
                        local Distance = 0

                        if HumanoidRootPart then
                            Distance = (HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude

                            if SilentAimSettings.Prediction.DistanceScaling then
                                local DistanceFactor = math.min(Distance / SilentAimSettings.Prediction.MaxDistance, 1)
                                TimeScale = SilentAimSettings.Prediction.MinScale +
                                    (SilentAimSettings.Prediction.MaxScale - SilentAimSettings.Prediction.MinScale) *
                                    DistanceFactor
                            end
                        end

                        local VelocityVector = Vector3.new(0, 0, 0)

                        if PredictionMethod == "AssemblyLinearVelocity" and HitPart.AssemblyLinearVelocity then
                            VelocityVector = HitPart.AssemblyLinearVelocity

                        elseif PredictionMethod == "Velocity" and HitPart.Velocity then
                            VelocityVector = HitPart.Velocity

                        elseif PredictionMethod == "HumanoidState" and Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
                            VelocityVector = Humanoid.MoveDirection * Humanoid.WalkSpeed

                        elseif PredictionMethod == "CFrameLerp" and HumanoidRootPart then
                            if not HumanoidRootPart.PreviousPositionData then
                                HumanoidRootPart.PreviousPositionData = {
                                    Positions = {},
                                    LastUpdate = tick()
                                }
                            end

                            local CurrentTime = tick()
                            local TimeDelta = CurrentTime - HumanoidRootPart.PreviousPositionData.LastUpdate

                            if TimeDelta > 0.015 then
                                table.insert(HumanoidRootPart.PreviousPositionData.Positions, {
                                    Position = HumanoidRootPart.Position,
                                    Timestamp = CurrentTime
                                })

                                if #HumanoidRootPart.PreviousPositionData.Positions > 5 then
                                    table.remove(HumanoidRootPart.PreviousPositionData.Positions, 1)
                                end

                                HumanoidRootPart.PreviousPositionData.LastUpdate = CurrentTime
                            end

                            if #HumanoidRootPart.PreviousPositionData.Positions >= 2 then
                                local NewestRecord = HumanoidRootPart.PreviousPositionData.Positions[#HumanoidRootPart.PreviousPositionData.Positions]
                                local OldestRecord = HumanoidRootPart.PreviousPositionData.Positions[1]

                                local PositionDelta = NewestRecord.Position - OldestRecord.Position
                                local TimeDiff = NewestRecord.Timestamp - OldestRecord.Timestamp

                                if TimeDiff > 0 then
                                    VelocityVector = PositionDelta / TimeDiff
                                end
                            end

                        elseif PredictionMethod == "CharacterController" and HumanoidRootPart then
                            if not HumanoidRootPart.ControllerHistory then
                                HumanoidRootPart.ControllerHistory = {
                                    Positions = {},
                                    Velocities = {},
                                    LastUpdate = tick()
                                }
                            end

                            local CurrentTime = tick()
                            local TimeDelta = CurrentTime - HumanoidRootPart.ControllerHistory.LastUpdate

                            if TimeDelta > 0.02 then
                                table.insert(HumanoidRootPart.ControllerHistory.Positions, HumanoidRootPart.Position)

                                if #HumanoidRootPart.ControllerHistory.Positions > 1 then
                                    local CurrentPos = HumanoidRootPart.ControllerHistory.Positions[#HumanoidRootPart.ControllerHistory.Positions]
                                    local PrevPos = HumanoidRootPart.ControllerHistory.Positions[#HumanoidRootPart.ControllerHistory.Positions - 1]
                                    local InstantVelocity = (CurrentPos - PrevPos) / TimeDelta

                                    table.insert(HumanoidRootPart.ControllerHistory.Velocities, InstantVelocity)
                                end

                                if #HumanoidRootPart.ControllerHistory.Positions > 4 then
                                    table.remove(HumanoidRootPart.ControllerHistory.Positions, 1)
                                end

                                if #HumanoidRootPart.ControllerHistory.Velocities > 4 then
                                    table.remove(HumanoidRootPart.ControllerHistory.Velocities, 1)
                                end

                                HumanoidRootPart.ControllerHistory.LastUpdate = CurrentTime
                            end

                            if #HumanoidRootPart.ControllerHistory.Velocities > 0 then
                                local WeightedVelocity = Vector3.new(0, 0, 0)
                                local TotalWeight = 0

                                for i, Velocity in ipairs(HumanoidRootPart.ControllerHistory.Velocities) do
                                    local Weight = i / #HumanoidRootPart.ControllerHistory.Velocities
                                    WeightedVelocity = WeightedVelocity + (Velocity * Weight)
                                    TotalWeight = TotalWeight + Weight
                                end

                                if TotalWeight > 0 then
                                    VelocityVector = WeightedVelocity / TotalWeight
                                end
                            end

                        elseif PredictionMethod == "HumanoidMoveDirection" and Humanoid then
                            if Humanoid.MoveDirection.Magnitude > 0 then
                                local SpeedMultiplier = 1

                                if Humanoid:GetState() == Enum.HumanoidStateType.Running then
                                    SpeedMultiplier = 1.0
                                elseif Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                                    SpeedMultiplier = 0.85
                                end

                                VelocityVector = Humanoid.MoveDirection * (Humanoid.WalkSpeed * SpeedMultiplier)
                            end

                        elseif PredictionMethod == "SmoothVelocity" then
                            if not Character.SmoothVelocityData then
                                Character.SmoothVelocityData = {
                                    CurrentVelocity = Vector3.new(0, 0, 0),
                                    SmoothFactor = 0.8,
                                    LastUpdate = tick()
                                }
                            end

                            local CurrentVelocity = Vector3.new(0, 0, 0)

                            if HitPart.AssemblyLinearVelocity then
                                CurrentVelocity = HitPart.AssemblyLinearVelocity
                            elseif HitPart.Velocity then
                                CurrentVelocity = HitPart.Velocity
                            elseif Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
                                CurrentVelocity = Humanoid.MoveDirection * (Humanoid.WalkSpeed or 16)
                            end

                            local Alpha = 1 - Character.SmoothVelocityData.SmoothFactor
                            Character.SmoothVelocityData.CurrentVelocity =
                                Character.SmoothVelocityData.CurrentVelocity * Character.SmoothVelocityData.SmoothFactor +
                                CurrentVelocity * Alpha

                            VelocityVector = Vector3.new(
                                Character.SmoothVelocityData.CurrentVelocity.X,
                                Character.SmoothVelocityData.CurrentVelocity.Y * 0.65,
                                Character.SmoothVelocityData.CurrentVelocity.Z
                            )

                            Character.SmoothVelocityData.LastUpdate = tick()
                        end

                        local GravityCompensation = 0.03
                        if Distance > 100 then
                            GravityCompensation = 0.05 + (Distance / 1000)
                        end

                        local FinalVelocity = Vector3.new(
                            VelocityVector.X * ScaleVector.X,
                            (VelocityVector.Y * ScaleVector.Y) + GravityCompensation,
                            VelocityVector.Z * ScaleVector.Z
                        ) * TimeScale

                        PredictedPosition = HitPart.Position + FinalVelocity
                    end

                    PredictedPosition = PredictedPosition + Vector3.new(0, 0.5, 0)

                    Arguments[3] = getDirection(A_Origin, PredictedPosition)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))
-- ==========================================================================================================

return SilentAimSettings
end

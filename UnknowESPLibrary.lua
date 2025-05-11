local RobloxESP = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

RobloxESP.Settings = {
    Enabled = true,
    
    PlayerESP = {
        Enabled = true,
        TeamCheck = true,
        TeamColor = true,
        Color = Color3.fromRGB(255, 0, 0),
        ShowFriends = true,
        FriendColor = Color3.fromRGB(0, 255, 0)
    },
    
    BoxESP = {
        Enabled = true,
        Thickness = 2,
        Filled = false,
        Transparency = 0.7
    },
    
    HealthESP = {
        Enabled = true,
        Position = "Left",
        Size = Vector2.new(2, 20),
        HealthyColor = Color3.fromRGB(0, 255, 0),
        DamagedColor = Color3.fromRGB(255, 255, 0),
        CriticalColor = Color3.fromRGB(255, 0, 0)
    },
    
    DistanceESP = {
        Enabled = true,
        Position = "Bottom",
        Unit = "Studs",
        RoundPrecision = 1,
        MaxDistance = 1000,
        Color = Color3.fromRGB(255, 255, 255)
    },
    
    NameESP = {
        Enabled = true,
        Position = "Top",
        ShowDisplayName = true,
        ShowDistance = true,
        Font = Drawing.Fonts.UI,
        Size = 18,
        Outline = true,
        Color = Color3.fromRGB(255, 255, 255)
    },
    
    ChamsESP = {
        Enabled = true,
        Transparency = 0.5,
        FillColor = Color3.fromRGB(255, 0, 0),
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0
    },
    
    SkeletonESP = {
        Enabled = true,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255)
    },
    
    TracersESP = {
        Enabled = true,
        Origin = "Bottom",
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255)
    }
}

RobloxESP.PlayerData = {}

local Utility = {}

function Utility.GetPlayerColor(player)
    local settings = RobloxESP.Settings.PlayerESP
    
    if settings.ShowFriends and LocalPlayer:IsFriendsWith(player.UserId) then
        return settings.FriendColor
    end
    
    if settings.TeamCheck and player.Team == LocalPlayer.Team then
        return nil
    end
    
    if settings.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    
    return settings.Color
end

function Utility.CalculateCorners(hrp)
    local size = Vector3.new(4, 5, 1)
    local cf = hrp.CFrame
    
    local corners = {
        TopLeft = cf * CFrame.new(-size.X/2, size.Y/2, 0),
        TopRight = cf * CFrame.new(size.X/2, size.Y/2, 0),
        BottomLeft = cf * CFrame.new(-size.X/2, -size.Y/2, 0),
        BottomRight = cf * CFrame.new(size.X/2, -size.Y/2, 0)
    }
    
    local screenCorners = {}
    for name, position in pairs(corners) do
        screenCorners[name] = Camera:WorldToViewportPoint(position.Position)
    end
    
    return screenCorners
end

function Utility.GetBoundingBox(corners)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, corner in pairs(corners) do
        minX = math.min(minX, corner.X)
        minY = math.min(minY, corner.Y)
        maxX = math.max(maxX, corner.X)
        maxY = math.max(maxY, corner.Y)
    end
    
    return {
        TopLeft = Vector2.new(minX, minY),
        TopRight = Vector2.new(maxX, minY),
        BottomLeft = Vector2.new(minX, maxY),
        BottomRight = Vector2.new(maxX, maxY),
        Size = Vector2.new(maxX - minX, maxY - minY)
    }
end

function Utility.GetPositionOnBox(box, position, offset)
    offset = offset or Vector2.new(0, 0)
    
    local positions = {
        Top = Vector2.new(box.TopLeft.X + box.Size.X / 2, box.TopLeft.Y) + Vector2.new(0, -5) + offset,
        Bottom = Vector2.new(box.BottomLeft.X + box.Size.X / 2, box.BottomLeft.Y) + Vector2.new(0, 5) + offset,
        Left = Vector2.new(box.TopLeft.X, box.TopLeft.Y + box.Size.Y / 2) + Vector2.new(-5, 0) + offset,
        Right = Vector2.new(box.TopRight.X, box.TopRight.Y + box.Size.Y / 2) + Vector2.new(5, 0) + offset
    }
    
    return positions[position] or positions.Top
end

function Utility.GetTracerOrigin()
    local setting = RobloxESP.Settings.TracersESP.Origin
    
    if setting == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif setting == "Center" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif setting == "Mouse" then
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        return Vector2.new(mouse.X, mouse.Y)
    else
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
end

function Utility.GetSkeletonPoints(player)
    local character = player.Character
    if not character then return {} end
    
    local joints = {
        Head = character:FindFirstChild("Head"),
        RootPart = character:FindFirstChild("HumanoidRootPart"),
        LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
        LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
        LeftHand = character:FindFirstChild("LeftHand"),
        RightUpperArm = character:FindFirstChild("RightUpperArm"),
        RightLowerArm = character:FindFirstChild("RightLowerArm"),
        RightHand = character:FindFirstChild("RightHand"),
        LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
        LeftFoot = character:FindFirstChild("LeftFoot"),
        RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
        RightFoot = character:FindFirstChild("RightFoot")
    }
    
    local points = {}
    for name, part in pairs(joints) do
        if part then
            local screenPos = Camera:WorldToViewportPoint(part.Position)
            points[name] = Vector2.new(screenPos.X, screenPos.Y)
        end
    end
    
    return points, joints
end

function RobloxESP.CreateDrawings(player)
    local data = {
        Player = player,
        Box = Drawing.new("Square"),
        BoxFill = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthBarBackground = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Chams = {},
        Skeleton = {}
    }
    
    for i = 1, 12 do
        table.insert(data.Skeleton, Drawing.new("Line"))
    end
    
    data.Box.Thickness = RobloxESP.Settings.BoxESP.Thickness
    data.Box.Filled = false
    data.Box.Transparency = 1
    data.Box.Visible = false
    
    data.BoxFill.Thickness = 1
    data.BoxFill.Filled = true
    data.BoxFill.Transparency = RobloxESP.Settings.BoxESP.Transparency
    data.BoxFill.Visible = false
    
    data.HealthBar.Thickness = 1
    data.HealthBar.Filled = true
    data.HealthBar.Transparency = 1
    data.HealthBar.Visible = false
    
    data.HealthBarBackground.Thickness = 1
    data.HealthBarBackground.Filled = true
    data.HealthBarBackground.Transparency = 0.5
    data.HealthBarBackground.Color = Color3.fromRGB(0, 0, 0)
    data.HealthBarBackground.Visible = false
    
    data.Name.Transparency = 1
    data.Name.Size = RobloxESP.Settings.NameESP.Size
    data.Name.Center = true
    data.Name.Outline = RobloxESP.Settings.NameESP.Outline
    data.Name.Font = RobloxESP.Settings.NameESP.Font
    data.Name.Visible = false
    
    data.Distance.Transparency = 1
    data.Distance.Size = RobloxESP.Settings.NameESP.Size - 2
    data.Distance.Center = true
    data.Distance.Outline = true
    data.Distance.Font = RobloxESP.Settings.NameESP.Font
    data.Distance.Visible = false
    
    data.Tracer.Thickness = RobloxESP.Settings.TracersESP.Thickness
    data.Tracer.Transparency = 1
    data.Tracer.Visible = false
    
    for _, line in ipairs(data.Skeleton) do
        line.Thickness = RobloxESP.Settings.SkeletonESP.Thickness
        line.Transparency = 1
        line.Visible = false
        line.Color = RobloxESP.Settings.SkeletonESP.Color
    end
    
    return data
end

function RobloxESP.RemoveDrawings(player)
    local data = RobloxESP.PlayerData[player]
    if not data then return end
    
    data.Box:Remove()
    data.BoxFill:Remove()
    data.HealthBar:Remove()
    data.HealthBarBackground:Remove()
    data.Name:Remove()
    data.Distance:Remove()
    data.Tracer:Remove()
    
    for _, chams in pairs(data.Chams) do
        if chams and chams.Handle then
            chams:Destroy()
        end
    end
    
    for _, line in ipairs(data.Skeleton) do
        line:Remove()
    end
    
    RobloxESP.PlayerData[player] = nil
end

function RobloxESP.UpdateESP()
    for player, data in pairs(RobloxESP.PlayerData) do
        if player == LocalPlayer then
            data.Box.Visible = false
            data.BoxFill.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBackground.Visible = false
            data.Name.Visible = false
            data.Distance.Visible = false
            data.Tracer.Visible = false
            
            for _, line in ipairs(data.Skeleton) do
                line.Visible = false
            end
            continue
        end
        
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
            data.Box.Visible = false
            data.BoxFill.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBackground.Visible = false
            data.Name.Visible = false
            data.Distance.Visible = false
            data.Tracer.Visible = false
            
            for _, line in ipairs(data.Skeleton) do
                line.Visible = false
            end
            continue
        end
        
        local playerColor = Utility.GetPlayerColor(player)
        if not playerColor then
            data.Box.Visible = false
            data.BoxFill.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBackground.Visible = false
            data.Name.Visible = false
            data.Distance.Visible = false
            data.Tracer.Visible = false
            
            for _, line in ipairs(data.Skeleton) do
                line.Visible = false
            end
            continue
        end
        
        local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        
        if not onScreen or distance > RobloxESP.Settings.DistanceESP.MaxDistance then
            data.Box.Visible = false
            data.BoxFill.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBackground.Visible = false
            data.Name.Visible = false
            data.Distance.Visible = false
            data.Tracer.Visible = false
            
            for _, line in ipairs(data.Skeleton) do
                line.Visible = false
            end
            continue
        end
        
        local screenCorners = Utility.CalculateCorners(rootPart)
        local box = Utility.GetBoundingBox(screenCorners)
        
        if RobloxESP.Settings.BoxESP.Enabled then
            data.Box.Visible = true
            data.Box.Color = playerColor
            data.Box.Size = box.Size
            data.Box.Position = box.TopLeft
            
            if RobloxESP.Settings.BoxESP.Filled then
                data.BoxFill.Visible = true
                data.BoxFill.Color = playerColor
                data.BoxFill.Size = box.Size
                data.BoxFill.Position = box.TopLeft
                data.BoxFill.Transparency = RobloxESP.Settings.BoxESP.Transparency
            else
                data.BoxFill.Visible = false
            end
        else
            data.Box.Visible = false
            data.BoxFill.Visible = false
        end
        
        if RobloxESP.Settings.HealthESP.Enabled then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barPosition = Utility.GetPositionOnBox(box, RobloxESP.Settings.HealthESP.Position)
            local barSize = RobloxESP.Settings.HealthESP.Size
            
            if RobloxESP.Settings.HealthESP.Position == "Left" or RobloxESP.Settings.HealthESP.Position == "Right" then
                barPosition = barPosition - Vector2.new(barSize.X / 2, 0)
                
                data.HealthBarBackground.Visible = true
                data.HealthBarBackground.Size = Vector2.new(barSize.X, box.Size.Y)
                data.HealthBarBackground.Position = Vector2.new(barPosition.X, box.TopLeft.Y)
                
                data.HealthBar.Visible = true
                data.HealthBar.Size = Vector2.new(barSize.X, box.Size.Y * healthPercent)
                data.HealthBar.Position = Vector2.new(barPosition.X, box.TopLeft.Y + box.Size.Y * (1 - healthPercent))
            else
                barPosition = barPosition - Vector2.new(0, barSize.Y / 2)
                
                data.HealthBarBackground.Visible = true
                data.HealthBarBackground.Size = Vector2.new(box.Size.X, barSize.Y)
                data.HealthBarBackground.Position = Vector2.new(box.TopLeft.X, barPosition.Y)
                
                data.HealthBar.Visible = true
                data.HealthBar.Size = Vector2.new(box.Size.X * healthPercent, barSize.Y)
                data.HealthBar.Position = Vector2.new(box.TopLeft.X, barPosition.Y)
            end
            
            if healthPercent > 0.5 then
                data.HealthBar.Color = RobloxESP.Settings.HealthESP.HealthyColor
            elseif healthPercent > 0.2 then
                data.HealthBar.Color = RobloxESP.Settings.HealthESP.DamagedColor
            else
                data.HealthBar.Color = RobloxESP.Settings.HealthESP.CriticalColor
            end
        else
            data.HealthBar.Visible = false
            data.HealthBarBackground.Visible = false
        end
        
        if RobloxESP.Settings.NameESP.Enabled then
            local namePosition = Utility.GetPositionOnBox(box, RobloxESP.Settings.NameESP.Position)
            local displayName = RobloxESP.Settings.NameESP.ShowDisplayName and player.DisplayName or player.Name
            
            data.Name.Visible = true
            data.Name.Position = namePosition
            data.Name.Text = displayName
            data.Name.Color = playerColor
        else
            data.Name.Visible = false
        end
        
        if RobloxESP.Settings.DistanceESP.Enabled then
            local distancePosition = Utility.GetPositionOnBox(box, RobloxESP.Settings.DistanceESP.Position)
            
            if RobloxESP.Settings.NameESP.Enabled and RobloxESP.Settings.DistanceESP.Position == RobloxESP.Settings.NameESP.Position then
                if RobloxESP.Settings.DistanceESP.Position == "Bottom" then
                    distancePosition = distancePosition + Vector2.new(0, 15)
                else
                    distancePosition = distancePosition - Vector2.new(0, 15)
                end
            end
            
            local displayDistance = math.floor(distance * 10^RobloxESP.Settings.DistanceESP.RoundPrecision) / 10^RobloxESP.Settings.DistanceESP.RoundPrecision
            
            data.Distance.Visible = true
            data.Distance.Position = distancePosition
            data.Distance.Text = tostring(displayDistance) .. " " .. RobloxESP.Settings.DistanceESP.Unit
            data.Distance.Color = RobloxESP.Settings.DistanceESP.Color
        else
            data.Distance.Visible = false
        end
        
        if RobloxESP.Settings.TracersESP.Enabled then
            local tracerOrigin = Utility.GetTracerOrigin()
            local tracerEnd = Vector2.new(vector.X, vector.Y)
            
            data.Tracer.Visible = true
            data.Tracer.From = tracerOrigin
            data.Tracer.To = tracerEnd
            data.Tracer.Color = playerColor
        else
            data.Tracer.Visible = false
        end
        
        if RobloxESP.Settings.SkeletonESP.Enabled then
            local skeletonPoints, joints = Utility.GetSkeletonPoints(player)
            local lineIndex = 1
            
            local connections = {
                {skeletonPoints.Head, skeletonPoints.RootPart},
                {skeletonPoints.RootPart, skeletonPoints.LeftUpperLeg},
                {skeletonPoints.LeftUpperLeg, skeletonPoints.LeftLowerLeg},
                {skeletonPoints.LeftLowerLeg, skeletonPoints.LeftFoot},
                {skeletonPoints.RootPart, skeletonPoints.RightUpperLeg},
                {skeletonPoints.RightUpperLeg, skeletonPoints.RightLowerLeg},
                {skeletonPoints.RightLowerLeg, skeletonPoints.RightFoot},
                {skeletonPoints.RootPart, skeletonPoints.LeftUpperArm},
                {skeletonPoints.LeftUpperArm, skeletonPoints.LeftLowerArm},
                {skeletonPoints.LeftLowerArm, skeletonPoints.LeftHand},
                {skeletonPoints.RootPart, skeletonPoints.RightUpperArm},
                {skeletonPoints.RightUpperArm, skeletonPoints.RightLowerArm},
                {skeletonPoints.RightLowerArm, skeletonPoints.RightHand}
            }
            
            for _, connection in ipairs(connections) do
                local from, to = connection[1], connection[2]
                if from and to then
                    local line = data.Skeleton[lineIndex]
                    line.Visible = true
                    line.From = from
                    line.To = to
                    line.Color = playerColor
                    lineIndex = lineIndex + 1
                end
            end
            
            for i = lineIndex, #data.Skeleton do
                data.Skeleton[i].Visible = false
            end
        else
            for _, line in ipairs(data.Skeleton) do
                line.Visible = false
            end
        end
        
        if RobloxESP.Settings.ChamsESP.Enabled then
            if not data.Chams.Active then
                data.Chams = {}
                data.Chams.Active = true
                
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = part
                        highlight.FillColor = RobloxESP.Settings.ChamsESP.FillColor
                        highlight.OutlineColor = RobloxESP.Settings.ChamsESP.OutlineColor
                        highlight.FillTransparency = RobloxESP.Settings.ChamsESP.Transparency
                        highlight.OutlineTransparency = RobloxESP.Settings.ChamsESP.OutlineTransparency
                        highlight.Parent = part
                        
                        data.Chams[part] = highlight
                    end
                end
            end
            
            for part, highlight in pairs(data.Chams) do
                if part and highlight and highlight.Parent then
                    highlight.FillColor = playerColor
                    highlight.FillTransparency = RobloxESP.Settings.ChamsESP.Transparency
                    highlight.OutlineTransparency = RobloxESP.Settings.ChamsESP.OutlineTransparency
                end
            end
        else
            if data.Chams.Active then
                for _, highlight in pairs(data.Chams) do
                    if highlight and highlight.Parent then
                        highlight:Destroy()
                    end
                end
                data.Chams = {}
            end
        end
    end
end

function RobloxESP.Init()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            RobloxESP.PlayerData[player] = RobloxESP.CreateDrawings(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        RobloxESP.PlayerData[player] = RobloxESP.CreateDrawings(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        RobloxESP.RemoveDrawings(player)
    end)
    
    RunService.RenderStepped:Connect(function()
        if RobloxESP.Settings.Enabled then
            RobloxESP.UpdateESP()
        else
            for _, data in pairs(RobloxESP.PlayerData) do
                data.Box.Visible = false
                data.BoxFill.Visible = false
                data.HealthBar.Visible = false
                data.HealthBarBackground.Visible = false
                data.Name.Visible = false
                data.Distance.Visible = false
                data.Tracer.Visible = false
                
                for _, line in ipairs(data.Skeleton) do
                    line.Visible = false
                end
            end
        end
    end)
end

function RobloxESP.ToggleESP(enabled)
    RobloxESP.Settings.Enabled = enabled == nil and not RobloxESP.Settings.Enabled or enabled
    return RobloxESP.Settings.Enabled
end

function RobloxESP.TogglePlayerESP(enabled)
    RobloxESP.Settings.PlayerESP.Enabled = enabled == nil and not RobloxESP.Settings.PlayerESP.Enabled or enabled
    return RobloxESP.Settings.PlayerESP.Enabled
end

function RobloxESP.ToggleBoxESP(enabled)
    RobloxESP.Settings.BoxESP.Enabled = enabled == nil and not RobloxESP.Settings.BoxESP.Enabled or enabled
    return RobloxESP.Settings.BoxESP.Enabled
end

function RobloxESP.ToggleHealthESP(enabled)
    RobloxESP.Settings.HealthESP.Enabled = enabled == nil and not RobloxESP.Settings.HealthESP.Enabled or enabled
    return RobloxESP.Settings.HealthESP.Enabled
end

function RobloxESP.ToggleDistanceESP(enabled)
    RobloxESP.Settings.DistanceESP.Enabled = enabled == nil and not RobloxESP.Settings.DistanceESP.Enabled or enabled
    return RobloxESP.Settings.DistanceESP.Enabled
end

function RobloxESP.ToggleNameESP(enabled)
    RobloxESP.Settings.NameESP.Enabled = enabled == nil and not RobloxESP.Settings.NameESP.Enabled or enabled
    return RobloxESP.Settings.NameESP.Enabled
end

function RobloxESP.ToggleChamsESP(enabled)
    RobloxESP.Settings.ChamsESP.Enabled = enabled == nil and not RobloxESP.Settings.ChamsESP.Enabled or enabled
    return RobloxESP.Settings.ChamsESP.Enabled
end

function RobloxESP.ToggleSkeletonESP(enabled)
    RobloxESP.Settings.SkeletonESP.Enabled = enabled == nil and not RobloxESP.Settings.SkeletonESP.Enabled or enabled
    return RobloxESP.Settings.SkeletonESP.Enabled
end

function RobloxESP.ToggleTracersESP(enabled)
    RobloxESP.Settings.TracersESP.Enabled = enabled == nil and not RobloxESP.Settings.TracersESP.Enabled or enabled
    return RobloxESP.Settings.TracersESP.Enabled
end

function RobloxESP.UpdatePlayerESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.PlayerESP[key] = value
    end
end

function RobloxESP.UpdateBoxESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.BoxESP[key] = value
    end
end

function RobloxESP.UpdateHealthESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.HealthESP[key] = value
    end
end

function RobloxESP.UpdateDistanceESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.DistanceESP[key] = value
    end
end

function RobloxESP.UpdateNameESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.NameESP[key] = value
    end
end

function RobloxESP.UpdateChamsESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.ChamsESP[key] = value
    end
end

function RobloxESP.UpdateSkeletonESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.SkeletonESP[key] = value
    end
end

function RobloxESP.UpdateTracersESP(options)
    for key, value in pairs(options) do
        RobloxESP.Settings.TracersESP[key] = value
    end
end

return RobloxESP

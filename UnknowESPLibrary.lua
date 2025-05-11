local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ESP = {
    Enabled = false,
    Settings = {
        RemoveOnDeath = false,
        MaxDistance = 300,
        MaxBoxSize = Vector3.new(15, 15, 0),
        DestroyOnRemove = false,
        TeamColors = false,
        TeamBased = false,
        BoxTopOffset = Vector3.new(0, 1, 0),
        
        Boxes = {
            Enabled = false,
            Color = Color3.new(1, 0, 1),
            Thickness = 1,
        },
        Names = {
            Distance = true,
            Health = true,
            Enabled = false,
            Resize = true,
            ResizeWeight = 0.05,
            Color = Color3.new(1, 1, 1),
            Size = 14,
            Font = 2,
            Center = true,
            Outline = true,
        },
        Tracers = {
            Enabled = false,
            Thickness = 0,
            Color = Color3.new(1, 0, 1),
            At = "Mouse", -- "Mouse", "Bottom", "Top", "Center"
        },
        Chams = {
            Enabled = false,
            Color = Color3.new(1, 0.4, 1),
            Transparency = 0.5,
            OutlineColor = Color3.new(1, 0, 1),
            OutlineTransparency = 0.8,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        },
        Skeleton = {
            Enabled = false,
            Color = Color3.new(1, 1, 1),
            Thickness = 1,
            Connections = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"},
            },
            R6Connections = {
                {"Head", "Torso"},
                {"Torso", "Right Arm"},
                {"Torso", "Left Arm"},
                {"Torso", "Right Leg"},
                {"Torso", "Left Leg"},
            }
        }
    },
    Objects = {}
}

-- Add functions to toggle features and update settings
function ESP:Toggle(enabled)
    self.Enabled = enabled
    
    -- If turning off, clear all drawings
    if not enabled then
        for _, object in pairs(self.Objects) do
            object:ClearDrawings()
        end
    end
end

function ESP:ToggleBox(enabled)
    self.Settings.Boxes.Enabled = enabled
end

function ESP:ToggleNames(enabled)
    self.Settings.Names.Enabled = enabled
end

function ESP:ToggleTracers(enabled)
    self.Settings.Tracers.Enabled = enabled
end

function ESP:ToggleChams(enabled)
    self.Settings.Chams.Enabled = enabled
    
    -- Apply changes to existing objects
    for _, object in pairs(self.Objects) do
        if object.Objects.Chams then
            if enabled then
                object:UpdateChams()
            else
                object.Objects.Chams.Enabled = false
            end
        elseif enabled then
            -- Create chams for existing objects that don't have them
            object.Objects.Chams = Instance.new("Highlight")
            object.Objects.Chams.FillColor = self.Settings.Chams.Color
            object.Objects.Chams.FillTransparency = self.Settings.Chams.Transparency
            object.Objects.Chams.OutlineColor = self.Settings.Chams.OutlineColor
            object.Objects.Chams.OutlineTransparency = self.Settings.Chams.OutlineTransparency
            object.Objects.Chams.DepthMode = self.Settings.Chams.DepthMode
            object.Objects.Chams.Adornee = object.Model
            object.Objects.Chams.Parent = game.CoreGui
        end
    end
end

function ESP:ToggleSkeleton(enabled)
    self.Settings.Skeleton.Enabled = enabled
    
    -- Apply changes to existing objects
    for _, object in pairs(self.Objects) do
        if enabled and next(object.Objects.Skeleton) == nil then
            -- Create skeleton lines for objects that don't have them
            local Humanoid = object.Model:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                local Connections = Humanoid.RigType == Enum.HumanoidRigType.R6 and self.Settings.Skeleton.R6Connections or self.Settings.Skeleton.Connections
                
                for _, Connection in ipairs(Connections) do
                    object.Objects.Skeleton[Connection[1] .. "-" .. Connection[2]] = Draw("Line", {
                        Thickness = self.Settings.Skeleton.Thickness,
                        Color = self.Settings.Skeleton.Color,
                        Visible = false
                    })
                end
            end
        end
    end
end

local function Draw(Type, Properties)
    local Object = Drawing.new(Type)
    
    for Property, Value in next, Properties or {} do
        Object[Property] = Value
    end
    
    return Object
end

function ESP:GetScreenPosition(Position)
    local Position = typeof(Position) ~= "CFrame" and Position or Position.Position
    local ScreenPos, IsOnScreen = workspace.CurrentCamera:WorldToViewportPoint(Position)
    
    return Vector2.new(ScreenPos.X, ScreenPos.Y), IsOnScreen
end

function ESP:GetDistance(Position)
    local Magnitude = (workspace.CurrentCamera.CFrame.Position - Position).Magnitude
    local Metric = Magnitude * 0.28
    
    return math.round(Metric)
end

function ESP:GetHealth(Model)
    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    
    if Humanoid then
        return Humanoid.Health, Humanoid.MaxHealth, (Humanoid.Health / Humanoid.MaxHealth) * 100
    end
    
    return 100, 100, 100
end

function ESP:GetPlayerFromCharacter(Model)
    return Players:GetPlayerFromCharacter(Model)
end

function ESP:GetTeam(Model)
    local Player = ESP:GetPlayerFromCharacter(Model)
    return Player and Player.Team or nil
end

function ESP:GetPlayerTeam(Player)
    return Player and Player.Team
end

function ESP:IsHostile(Model)
    local Player = ESP:GetPlayerFromCharacter(Model)
    local MyTeam = ESP:GetPlayerTeam(Players.LocalPlayer)
    local TheirTeam = ESP:GetPlayerTeam(Player)
    
    return (MyTeam ~= TheirTeam)
end

function ESP:GetTeamColor(Model)
    local Team
    
    if Model:IsA("Model") then
        Team = ESP:GetTeam(Model)
    elseif Model:IsA("Player") then
        Team = ESP:GetPlayerTeam(Model)
    end
    
    return Team and Team.TeamColor.Color or Color3.new(1, 0, 0)
end

function ESP:GetOffset(Model)
    local Humanoid = Model:FindFirstChild("Humanoid")
    
    if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6 then
        return CFrame.new(0, -1.75, 0)
    end
    
    return CFrame.new(0, 0, 0)
end

function ESP:CharacterAdded(Player)
    return Player.CharacterAdded
end

function ESP:GetCharacter(Player)
    return Player.Character
end

local function Validate(Child, Type, ClassName, ExpectedName)
    return not (Type or ClassName or ExpectedName) or (not ExpectedName or (ExpectedName and Child.Name == ExpectedName)) and (not ClassName or (ClassName and Child.ClassName == ClassName)) and (not Type or (Type and Child:IsA(Type)))
end

function ESP:AddListener(Model, Validator, Settings)
    local Descendants = Settings.Descendants
    local Type, ClassName, ExpectedName = Settings.Type, Settings.ClassName, Settings.ExpectedName
    local ExtraSettings = Settings.Custom or {}
    
    local function ValidCheck(Child)
        if typeof(Validator) == "function" and Validator(Child) or not Validator then
            if Validate(Child, Type, ClassName, ExpectedName) then
                ESP.Object:New(Child, ExtraSettings)
            end
        end
    end
    
    local Connection = Descendants and Model.DescendantAdded or Model.ChildAdded
    local ObjectsToCheck = Descendants and Model.GetDescendants or Model.GetChildren
    
    Connection:Connect(function(Child)
        task.spawn(ValidCheck, Child)
    end)
    
    for i, Child in next, ObjectsToCheck(Model) do
        task.spawn(ValidCheck, Child)
    end
end

local Object = {}
Object.__index = Object

ESP.Object = Object

local function Clone(Table)
    local Ret = {}
    
    for i,v in next, Table do
        if typeof(v) == "table" then
            v = Clone(v)
        end
        
        Ret[i] = v
    end
    
    return Ret
end

local function GetValue(Local, Global, Name)
    local GlobalVal = Global[Name]
    local LocalVal = Local[Name]
    
    return LocalVal or ((LocalVal == nil or typeof(LocalVal) ~= "boolean") and GlobalVal)
end

function Object:New(Model, ExtraInfo)
    if not Model then
        return
    end
    
    local Settings = ESP.Settings
    
    local NewObject = {
        Connections = {},
        RenderSettings = {
            Boxes = {},
            Tracers = {},
            Names = {},
            Chams = {},
            Skeleton = {}
        },
        GlobalSettings = Settings,
        Model = Model,
        Name = Model.Name,
        
        Objects = {
            Box = {
                Color = Settings.Boxes.Color,
                Thickness = Settings.Boxes.Thickness,
            },
            
            Name = {
                Color = Settings.Names.Color,
                Outline = Settings.Names.Outline,
                Text = Model.Name,
                Size = Settings.Names.Size,
                Font = Settings.Names.Font,
                Center = Settings.Names.Center,
            },
            
            Tracer = {
                Thickness = Settings.Tracers.Thickness,
                Color = Settings.Tracers.Color,
            },
            
            Chams = nil,
            
            Skeleton = {}
        },
    }
    
    for Property, Value in next, ExtraInfo or {} do
        if Property ~= "Settings" then
            NewObject[Property] = Value
        else
            for Name, Table in next, Value do
                for Property, Value in next, Table do
                    NewObject.RenderSettings[Name][Property] = Value
                end
            end
        end
    end
    
    NewObject = setmetatable(NewObject, Object)
    ESP.Objects[Model] = NewObject

    NewObject.Objects.Box = Draw("Quad", NewObject.Objects.Box)
    NewObject.Objects.Name = Draw("Text", NewObject.Objects.Name)
    NewObject.Objects.Tracer = Draw("Line", NewObject.Objects.Tracer)
    
    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    local SkeletonSettings = Settings.Skeleton
    
    if SkeletonSettings.Enabled then
        local Connections = Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6 and SkeletonSettings.R6Connections or SkeletonSettings.Connections
        
        for _, Connection in ipairs(Connections) do
            NewObject.Objects.Skeleton[Connection[1] .. "-" .. Connection[2]] = Draw("Line", {
                Thickness = SkeletonSettings.Thickness,
                Color = SkeletonSettings.Color,
                Visible = false
            })
        end
    end
    
    if Settings.Chams.Enabled then
        NewObject.Objects.Chams = Instance.new("Highlight")
        NewObject.Objects.Chams.FillColor = Settings.Chams.Color
        NewObject.Objects.Chams.FillTransparency = Settings.Chams.Transparency
        NewObject.Objects.Chams.OutlineColor = Settings.Chams.OutlineColor
        NewObject.Objects.Chams.OutlineTransparency = Settings.Chams.OutlineTransparency
        NewObject.Objects.Chams.DepthMode = Settings.Chams.DepthMode
        NewObject.Objects.Chams.Adornee = Model
        NewObject.Objects.Chams.Parent = game.CoreGui
    end
    
    NewObject.Connections.Destroying = Model.Destroying:Connect(function()
        NewObject:Destroy()
    end)
    
    NewObject.Connections.AncestryChanged = Model.AncestryChanged:Connect(function(Old, New)
        if not Model:IsDescendantOf(workspace) and NewObject.RenderSettings.DestroyOnRemove or NewObject.GlobalSettings.DestroyOnRemove then
            NewObject:Destroy()
        end
    end)
    
    if Humanoid then
        NewObject.Connections.Died = Humanoid.Died:Connect(function()
            if Settings.RemoveOnDeath then
                NewObject:Destroy()
            end
        end)
    end
    
    NewObject.Connections.Removing = Model.AncestryChanged:Connect(function()
        if NewObject.RenderSettings.DestroyOnRemove or NewObject.GlobalSettings.DestroyOnRemove then
            NewObject:Destroy()
        end
    end)
    
    return NewObject
end

function Object:GetQuad()
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local MaxSize = GetValue(RenderSettings, GlobalSettings, "MaxBoxSize")
    local BoxTopOffset = GetValue(RenderSettings, GlobalSettings, "BoxTopOffset")
    
    local Model = self.Model
    local Camera = workspace.CurrentCamera
    local Pivot = Model:GetPivot()
    
    -- Apply offset
    Pivot = Pivot * ESP:GetOffset(Model)
    
    -- Get the character size from bounding box
    local _, Size = Model:GetBoundingBox()
    
    -- Clamp the size based on MaxBoxSize
    local X, Y = math.clamp(Size.X, 1, MaxSize.X) / 2, math.clamp(Size.Y, 1, MaxSize.Y) / 2
    
    -- Get the position of the model on screen
    local Position, IsOnScreen = ESP:GetScreenPosition(Pivot.Position)
    
    -- Check if any part of the model is visible
    if not IsOnScreen then
        return false
    end
    
    -- Calculate the camera's viewing direction to the model
    local CameraPosition = Camera.CFrame.Position
    local LookVector = (Pivot.Position - CameraPosition).Unit
    
    -- Calculate camera-aligned right and up vectors
    local Right = Camera.CFrame.RightVector
    local Up = Camera.CFrame.UpVector
    
    -- Calculate the corners of the box in 3D space, aligned with the camera view
    local TopRight = Pivot.Position + (Right * X) + (Up * Y)
    local TopLeft = Pivot.Position - (Right * X) + (Up * Y)
    local BottomLeft = Pivot.Position - (Right * X) - (Up * Y)
    local BottomRight = Pivot.Position + (Right * X) - (Up * Y)
    
    -- Convert 3D positions to screen positions
    local TopRightPos, TopRightOnScreen = ESP:GetScreenPosition(TopRight)
    local TopLeftPos, TopLeftOnScreen = ESP:GetScreenPosition(TopLeft)
    local BottomLeftPos, BottomLeftOnScreen = ESP:GetScreenPosition(BottomLeft)
    local BottomRightPos, BottomRightOnScreen = ESP:GetScreenPosition(BottomRight)
    
    -- Calculate additional points for other features
    local BoxTop = ESP:GetScreenPosition(Pivot.Position + (Up * Y) + BoxTopOffset)
    local BoxBottom = ESP:GetScreenPosition(Pivot.Position - (Up * Y))
    
    -- Check if any corner is on screen
    if TopRightOnScreen or TopLeftOnScreen or BottomLeftOnScreen or BottomRightOnScreen then
        local Positions = {
            BoxBottom = BoxBottom,
            Pivot = Position,
            BoxTop = BoxTop,
            TopRight = TopRightPos,
            TopLeft = TopLeftPos,
            BottomLeft = BottomLeftPos,
            BottomRight = BottomRightPos,
        }
    
        return Positions, true
    end
    
    return false
end

function Object:DrawBox(Quad)
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local RenderBoxes = RenderSettings.Boxes
    local GlobalBoxes = GlobalSettings.Boxes
    
    local TeamColors = GetValue(RenderSettings, GlobalSettings, "TeamColors")
    local Thickness = GetValue(RenderBoxes, GlobalBoxes, "Thickness")
    local Color = GetValue(RenderBoxes, GlobalBoxes, "Color")

    local Properties = {
        Visible = true,
        Color = TeamColors and ESP:GetTeamColor(self.Model) or Color,
        Thickness = Thickness,
        PointA = Quad.TopRight,
        PointB = Quad.TopLeft,
        PointC = Quad.BottomLeft,
        PointD = Quad.BottomRight,
    }
    
    for Property, Value in next, Properties do
        self.Objects.Box[Property] = Value
    end
end

function Object:DrawName(Quad)
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local RenderNames = RenderSettings.Names
    local GlobalNames = GlobalSettings.Names
    
    local Settings = RenderNames or GlobalNames
    
    local ShowDistance = GetValue(RenderNames, GlobalNames, "Distance")
    local Size = GetValue(RenderNames, GlobalNames, "Size")
    local Resize = GetValue(RenderNames, GlobalNames, "Resize")
    local ResizeWeight = GetValue(RenderNames, GlobalNames, "ResizeWeight")
    local ShowHealth = GetValue(RenderNames, GlobalNames, "Health")
    local Font = GetValue(RenderNames, GlobalNames, "Font")
    local Center = GetValue(RenderNames, GlobalNames, "Center")
    local TeamColors = GetValue(RenderNames, GlobalNames, "TeamColors")
    local Color = GetValue(RenderNames, GlobalNames, "Color")
    local Outline = GetValue(RenderNames, GlobalNames, "Outline")
    
    local Distance = self.Model:GetPivot().Position
    
    local Properties = {
        Visible = true,
        Color = TeamColors and ESP:GetTeamColor(self.Model) or Color,
        Outline = Outline,
        Text = not (Size or ShowHealth) and self.Name or ("%s [%sm]%s"):format(self.Name, ShowDistance and tostring(ESP:GetDistance(Distance)) or "", ShowHealth and ("\n%d/%d (%d%%)"):format(ESP:GetHealth(self.Model)) or ""),
        Size = not Resize and Size or Size - math.clamp((ESP:GetDistance(Distance) * ResizeWeight), 1, Size * 0.75),
        Font = Font,
        Center = Center,
        Position = Quad.BoxTop,
    }

    for Property, Value in next, Properties do
        self.Objects.Name[Property] = Value
    end
end

function Object:DrawTracer(Quad)
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local RenderTracers = RenderSettings.Tracers
    local GlobalTracers = GlobalSettings.Tracers
    
    local TeamColors = GetValue(RenderTracers, GlobalTracers, "TeamColors")
    local Color = GetValue(RenderTracers, GlobalTracers, "Color")
    local Thickness = GetValue(RenderTracers, GlobalTracers, "Thickness")

    local At
    if ESP.Settings.Tracers.At == "Mouse" then
        At = UserInputService:GetMouseLocation()
    elseif ESP.Settings.Tracers.At == "Bottom" then
        At = workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 1)
    elseif ESP.Settings.Tracers.At == "Top" then
        At = workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0)
    elseif ESP.Settings.Tracers.At == "Center" then
        At = workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.5)
    else
        At = workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 1)
    end
    
    local Properties = {
        Visible = true,
        Color = TeamColors and ESP:GetTeamColor(self.Model) or Color,
        Thickness = Thickness,
        From = At,
        To = Quad.BoxBottom,
    }
    
    for Property, Value in next, Properties do
        self.Objects.Tracer[Property] = Value
    end
end

function Object:DrawSkeleton()
    local Model = self.Model
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local SkeletonSettings = GlobalSettings.Skeleton
    if not SkeletonSettings.Enabled then return end
    
    local TeamColors = GetValue(RenderSettings, GlobalSettings, "TeamColors")
    local Color = SkeletonSettings.Color
    
    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end
    
    local Connections = Humanoid.RigType == Enum.HumanoidRigType.R6 and SkeletonSettings.R6Connections or SkeletonSettings.Connections
    
    for _, Connection in ipairs(Connections) do
        local Part1Name, Part2Name = Connection[1], Connection[2]
        local Part1 = Model:FindFirstChild(Part1Name)
        local Part2 = Model:FindFirstChild(Part2Name)
        
        if Part1 and Part2 then
            local LineKey = Part1Name .. "-" .. Part2Name
            local Line = self.Objects.Skeleton[LineKey]
            
            if Line then
                local Pos1, OnScreen1 = ESP:GetScreenPosition(Part1.Position)
                local Pos2, OnScreen2 = ESP:GetScreenPosition(Part2.Position)
                
                if OnScreen1 or OnScreen2 then
                    Line.Visible = true
                    Line.From = Pos1
                    Line.To = Pos2
                    Line.Color = TeamColors and ESP:GetTeamColor(Model) or Color
                    Line.Thickness = SkeletonSettings.Thickness
                else
                    Line.Visible = false
                end
            end
        end
    end
end

function Object:UpdateChams()
    local Model = self.Model
    local Chams = self.Objects.Chams
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    if not Chams or not GlobalSettings.Chams.Enabled then return end
    
    local TeamColors = GetValue(RenderSettings, GlobalSettings, "TeamColors")
    local ChamsSettings = GlobalSettings.Chams
    
    Chams.FillColor = TeamColors and ESP:GetTeamColor(Model) or ChamsSettings.Color
    Chams.OutlineColor = TeamColors and ESP:GetTeamColor(Model) or ChamsSettings.OutlineColor
    Chams.Enabled = true
end

function Object:Destroy()
    ESP.Objects[self.Model] = nil
    self:ClearDrawings()
    
    for i, v in next, self.Objects do
        if i == "Chams" then
            if v and v.Parent then
                v:Destroy()
            end
        elseif i == "Skeleton" then
            for _, Line in pairs(v) do
                Line:Remove()
            end
        else
            v:Remove()
        end
    end
    
    for i, v in next, self.Connections do
        v:Disconnect()
    end
    
    table.clear(self.Objects)
end

function Object:ClearDrawings()
    for i, v in next, self.Objects do
        if i == "Chams" then
            if v then
                v.Enabled = false
            end
        elseif i == "Skeleton" then
            for _, Line in pairs(v) do
                Line.Visible = false
            end
        else
            v.Visible = false
        end
    end
end

function Object:Refresh()
    local Model = self.Model
    local Quad = self:GetQuad()
    local RenderSettings = self.RenderSettings
    local GlobalSettings = self.GlobalSettings
    
    local TeamBased = GetValue(RenderSettings, GlobalSettings, "TeamBased")
    local MaxDistance = GetValue(RenderSettings, GlobalSettings, "MaxDistance")
    local Boxes = GetValue(RenderSettings.Boxes, GlobalSettings.Boxes, "Enabled")
    local Names = GetValue(RenderSettings.Names, GlobalSettings.Names, "Enabled")
    local Tracers = GetValue(RenderSettings.Tracers, GlobalSettings.Tracers, "Enabled")
    local Chams = GetValue(RenderSettings.Chams, GlobalSettings.Chams, "Enabled")
    local Skeleton = GetValue(RenderSettings.Skeleton, GlobalSettings.Skeleton, "Enabled")
    
    if not ESP.Enabled then
        return self:ClearDrawings()
    end
    
    if not Model.Parent or not Model:IsDescendantOf(workspace) then
        return self:ClearDrawings()
    end
    
    if TeamBased and not ESP:IsHostile(Model) then
        return self:ClearDrawings()
    end
    
    if ESP:GetDistance(Model:GetPivot().Position) > MaxDistance then
        return self:ClearDrawings()
    end
    
    if Chams then
        self:UpdateChams()
    elseif self.Objects.Chams then
        self.Objects.Chams.Enabled = false
    end
    
    if Skeleton then
        self:DrawSkeleton()
    else
        for _, Line in pairs(self.Objects.Skeleton) do
            Line.Visible = false
        end
    end
    
    if not Quad then 
        if self.Objects.Box then self.Objects.Box.Visible = false end
        if self.Objects.Name then self.Objects.Name.Visible = false end
        if self.Objects.Tracer then self.Objects.Tracer.Visible = false end
        return
    end
    
    if Boxes then
        self:DrawBox(Quad)
    else
        self.Objects.Box.Visible = false
    end
    
    if Names then
        self:DrawName(Quad)
    else
        self.Objects.Name.Visible = false
    end
    
    if Tracers then
        self:DrawTracer(Quad)
    else
        self.Objects.Tracer.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    for i, Object in next, ESP.Objects do
        Object:Refresh()
    end
end)

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= Players.LocalPlayer and Player.Character then
        ESP.Object:New(Player.Character)
    end
    
    ESP:CharacterAdded(Player):Connect(function(Character)
        ESP.Object:New(Character)
    end)
end

Players.PlayerAdded:Connect(function(Player)
    ESP:CharacterAdded(Player):Connect(function(Character)
        ESP.Object:New(Character)
    end)
end)

return ESP

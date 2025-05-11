local RobloxESP = {}
RobloxESP.__index = RobloxESP

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local DrawingObjects = {}

function RobloxESP.new()
    local self = setmetatable({}, RobloxESP)

    self.Settings = {
        Enabled = false,
        TeamCheck = false,
        TeamColor = false,
        BoxEnabled = true,
        BoxColor = Color3.fromRGB(255, 0, 0),
        BoxTransparency = 1,
        BoxThickness = 1,
        BoxOutline = true,
        BoxOutlineColor = Color3.fromRGB(0, 0, 0),
        NameEnabled = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameOutline = true,
        NameFont = 2,
        NameSize = 13,
        DistanceEnabled = true,
        DistanceColor = Color3.fromRGB(255, 255, 255),
        DistanceOutline = true,
        DistanceFont = 2,
        DistanceSize = 13,
        HealthBarEnabled = true,
        HealthBarThickness = 1,
        HealthBarSide = "Left",
        TracerEnabled = false,
        TracerColor = Color3.fromRGB(255, 0, 0),
        TracerThickness = 1,
        TracerTransparency = 1,
        TracerFrom = "Bottom",
        MaxDistance = 1000,
        TargetsEnabled = {
            Players = true,
            NPCs = false,
            Objects = false
        },
        CustomObjects = {}
    }
    
    self.Connections = {}
    
    return self
end

function RobloxESP:Enable()
    self.Settings.Enabled = true
    self:ConnectESP()
    return self
end

function RobloxESP:Disable()
    self.Settings.Enabled = false
    self:DisconnectESP()
    return self
end

function RobloxESP:Toggle()
    if self.Settings.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self
end

function RobloxESP:SetSetting(SettingName, Value)
    if self.Settings[SettingName] ~= nil then
        self.Settings[SettingName] = Value
    end
    return self
end

function RobloxESP:GetSetting(SettingName)
    return self.Settings[SettingName]
end

function RobloxESP:ConnectESP()
    self:DisconnectESP()

    local RenderConnection = RunService.RenderStepped:Connect(function()
        if not self.Settings.Enabled then return end

        self:ClearDrawings()

        if self.Settings.TargetsEnabled.Players then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer then
                    self:DrawPlayerESP(Player)
                end
            end
        end

        if self.Settings.TargetsEnabled.Objects then
            for ObjectName, Object in pairs(self.Settings.CustomObjects) do
                self:DrawObjectESP(ObjectName, Object)
            end
        end
    end)

    table.insert(self.Connections, RenderConnection)
end

function RobloxESP:DisconnectESP()
    for _, Connection in pairs(self.Connections) do
        if Connection then Connection:Disconnect() end
    end
    self.Connections = {}
    self:ClearDrawings()
end

function RobloxESP:ClearDrawings()
    for _, Objects in pairs(DrawingObjects) do
        for _, Object in pairs(Objects) do
            if Object.Visible then
                Object.Visible = false
            end
        end
    end
end

function RobloxESP:GetDrawingObject(Id, Type)
    if not DrawingObjects[Id] then
        DrawingObjects[Id] = {}
    end

    if not DrawingObjects[Id][Type] then
        DrawingObjects[Id][Type] = Drawing.new(Type)
    end
    
    return DrawingObjects[Id][Type]
end

function RobloxESP:IsPlayerValid(Player)
    local Character = Player.Character
    if not Character then return false end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end

    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    
    local Distance = (HRP.Position - Camera.CFrame.Position).Magnitude
    if Distance > self.Settings.MaxDistance then return false end

    if self.Settings.TeamCheck and Player.Team == LocalPlayer.Team then return false end
    
    return true
end

function RobloxESP:GetPlayerColor(Player)
    if self.Settings.TeamColor and Player.Team then
        return Player.TeamColor.Color
    else
        return self.Settings.BoxColor
    end
end

function RobloxESP:CalculateBox(Character)
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return nil end
    
    local Head = Character:FindFirstChild("Head")
    if not Head then return nil end
    
    local Size = Vector3.new(4, 6, 1)
    local CFrame = HRP.CFrame

    local TopLeft = CFrame * CFrame.new(-Size.X/2, Size.Y/2, 0)
    local TopRight = CFrame * CFrame.new(Size.X/2, Size.Y/2, 0)
    local BottomLeft = CFrame * CFrame.new(-Size.X/2, -Size.Y/2, 0)
    local BottomRight = CFrame * CFrame.new(Size.X/2, -Size.Y/2, 0)

    local TopLeft2D, TopLeftVisible = Camera:WorldToViewportPoint(TopLeft.Position)
    local TopRight2D, TopRightVisible = Camera:WorldToViewportPoint(TopRight.Position)
    local BottomLeft2D, BottomLeftVisible = Camera:WorldToViewportPoint(BottomLeft.Position)
    local BottomRight2D, BottomRightVisible = Camera:WorldToViewportPoint(BottomRight.Position)

    if not (TopLeftVisible or TopRightVisible or BottomLeftVisible or BottomRightVisible) then
        return nil
    end

    return {
        TopLeft = Vector2.new(TopLeft2D.X, TopLeft2D.Y),
        TopRight = Vector2.new(TopRight2D.X, TopRight2D.Y),
        BottomLeft = Vector2.new(BottomLeft2D.X, BottomLeft2D.Y),
        BottomRight = Vector2.new(BottomRight2D.X, BottomRight2D.Y),
        Visible = true
    }
end

function RobloxESP:DrawPlayerESP(Player)
    if not self:IsPlayerValid(Player) then return end
    
    local Character = Player.Character
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")

    local Position, OnScreen = Camera:WorldToViewportPoint(HRP.Position)
    if not OnScreen then return end
    
    local Distance = (HRP.Position - Camera.CFrame.Position).Magnitude
    local DisplayName = Player.DisplayName or Player.Name
    local PlayerColor = self:GetPlayerColor(Player)

    local Box = self:CalculateBox(Character)
    if not Box then return end

    if self.Settings.BoxEnabled then
        local BoxQuad = self:GetDrawingObject(Player.UserId, "Quad")
        BoxQuad.Visible = true
        BoxQuad.PointA = Box.TopRight
        BoxQuad.PointB = Box.TopLeft
        BoxQuad.PointC = Box.BottomLeft
        BoxQuad.PointD = Box.BottomRight
        BoxQuad.Color = PlayerColor
        BoxQuad.Thickness = self.Settings.BoxThickness
        BoxQuad.Transparency = self.Settings.BoxTransparency
        BoxQuad.Filled = false
        
        if self.Settings.BoxOutline then
            local BoxOutline = self:GetDrawingObject(Player.UserId, "QuadOutline")
            BoxOutline.Visible = true
            BoxOutline.PointA = Box.TopRight
            BoxOutline.PointB = Box.TopLeft
            BoxOutline.PointC = Box.BottomLeft
            BoxOutline.PointD = Box.BottomRight
            BoxOutline.Color = self.Settings.BoxOutlineColor
            BoxOutline.Thickness = self.Settings.BoxThickness + 2
            BoxOutline.Transparency = self.Settings.BoxTransparency
            BoxOutline.Filled = false
        end
    end

    if self.Settings.NameEnabled then
        local NameText = self:GetDrawingObject(Player.UserId, "NameText")
        NameText.Visible = true
        NameText.Text = DisplayName
        NameText.Size = self.Settings.NameSize
        NameText.Center = true
        NameText.Outline = self.Settings.NameOutline
        NameText.OutlineColor = Color3.new(0, 0, 0)
        NameText.Color = self.Settings.NameColor
        NameText.Font = self.Settings.NameFont
        NameText.Position = Vector2.new(
            (Box.TopLeft.X + Box.TopRight.X) / 2,
            Box.TopLeft.Y - 18
        )
    end

    if self.Settings.DistanceEnabled then
        local DistanceText = self:GetDrawingObject(Player.UserId, "DistanceText")
        DistanceText.Visible = true
        DistanceText.Text = math.floor(Distance) .. " studs"
        DistanceText.Size = self.Settings.DistanceSize
        DistanceText.Center = true
        DistanceText.Outline = self.Settings.DistanceOutline
        DistanceText.OutlineColor = Color3.new(0, 0, 0)
        DistanceText.Color = self.Settings.DistanceColor
        DistanceText.Font = self.Settings.DistanceFont
        DistanceText.Position = Vector2.new(
            (Box.BottomLeft.X + Box.BottomRight.X) / 2,
            Box.BottomLeft.Y + 6
        )
    end

    if self.Settings.HealthBarEnabled and Humanoid then
        local BarHeight = Box.BottomLeft.Y - Box.TopLeft.Y
        local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
        local BarPosition, BarSize
        
        if self.Settings.HealthBarSide == "Left" then
            BarPosition = Vector2.new(Box.TopLeft.X - 7, Box.TopLeft.Y)
            BarSize = Vector2.new(3, BarHeight * HealthPercent)
        else
            BarPosition = Vector2.new(Box.TopRight.X + 4, Box.TopLeft.Y)
            BarSize = Vector2.new(3, BarHeight * HealthPercent)
        end

        local HealthBarOutline = self:GetDrawingObject(Player.UserId, "HealthBarOutline")
        HealthBarOutline.Visible = true
        HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
        HealthBarOutline.Filled = true
        HealthBarOutline.Thickness = 1
        HealthBarOutline.Transparency = 1
        HealthBarOutline.Size = Vector2.new(5, BarHeight + 2)
        HealthBarOutline.Position = Vector2.new(
            BarPosition.X - 1,
            BarPosition.Y - 1
        )

        local HealthBar = self:GetDrawingObject(Player.UserId, "HealthBar")
        HealthBar.Visible = true
        HealthBar.Color = Color3.fromRGB(
            255 * (1 - HealthPercent),
            255 * HealthPercent,
            0
        )
        HealthBar.Filled = true
        HealthBar.Thickness = self.Settings.HealthBarThickness
        HealthBar.Transparency = 1
        HealthBar.Size = BarSize
        HealthBar.Position = Vector2.new(
            BarPosition.X,
            BarPosition.Y + (BarHeight - BarSize.Y)
        )
    end

    if self.Settings.TracerEnabled then
        local TracerFrom
        if self.Settings.TracerFrom == "Bottom" then
            TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif self.Settings.TracerFrom == "Center" then
            TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif self.Settings.TracerFrom == "Mouse" then
            TracerFrom = Vector2.new(game:GetService("UserInputService"):GetMouseLocation().X, game:GetService("UserInputService"):GetMouseLocation().Y)
        end
        
        local Tracer = self:GetDrawingObject(Player.UserId, "Tracer")
        Tracer.Visible = true
        Tracer.Color = PlayerColor
        Tracer.Thickness = self.Settings.TracerThickness
        Tracer.Transparency = self.Settings.TracerTransparency
        Tracer.From = TracerFrom
        Tracer.To = Vector2.new((Box.BottomLeft.X + Box.BottomRight.X) / 2, Box.BottomLeft.Y)
    end
end

function RobloxESP:DrawObjectESP(ObjectName, Object)
    if not Object or not Object:IsA("BasePart") then return end
    
    local Position, OnScreen = Camera:WorldToViewportPoint(Object.Position)
    if not OnScreen then return end
    
    local Distance = (Object.Position - Camera.CFrame.Position).Magnitude
    if Distance > self.Settings.MaxDistance then return end

    if self.Settings.NameEnabled then
        local NameText = self:GetDrawingObject("Object_" .. ObjectName, "NameText")
        NameText.Visible = true
        NameText.Text = ObjectName
        NameText.Size = self.Settings.NameSize
        NameText.Center = true
        NameText.Outline = self.Settings.NameOutline
        NameText.OutlineColor = Color3.new(0, 0, 0)
        NameText.Color = self.Settings.NameColor
        NameText.Font = self.Settings.NameFont
        NameText.Position = Vector2.new(Position.X, Position.Y - 20)
    end
    
    if self.Settings.DistanceEnabled then
        local DistanceText = self:GetDrawingObject("Object_" .. ObjectName, "DistanceText")
        DistanceText.Visible = true
        DistanceText.Text = math.floor(Distance) .. " studs"
        DistanceText.Size = self.Settings.DistanceSize
        DistanceText.Center = true
        DistanceText.Outline = self.Settings.DistanceOutline
        DistanceText.OutlineColor = Color3.new(0, 0, 0)
        DistanceText.Color = self.Settings.DistanceColor
        DistanceText.Font = self.Settings.DistanceFont
        DistanceText.Position = Vector2.new(Position.X, Position.Y)
    end

    if self.Settings.TracerEnabled then
        local TracerFrom
        if self.Settings.TracerFrom == "Bottom" then
            TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif self.Settings.TracerFrom == "Center" then
            TracerFrom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif self.Settings.TracerFrom == "Mouse" then
            TracerFrom = Vector2.new(game:GetService("UserInputService"):GetMouseLocation().X, game:GetService("UserInputService"):GetMouseLocation().Y)
        end
        
        local Tracer = self:GetDrawingObject("Object_" .. ObjectName, "Tracer")
        Tracer.Visible = true
        Tracer.Color = self.Settings.TracerColor 
        Tracer.Thickness = self.Settings.TracerThickness
        Tracer.Transparency = self.Settings.TracerTransparency
        Tracer.From = TracerFrom
        Tracer.To = Vector2.new(Position.X, Position.Y)
    end
end

function RobloxESP:AddObjectESP(ObjectName, Object)
    if not Object then return self end
    self.Settings.CustomObjects[ObjectName] = Object
    return self
end

function RobloxESP:RemoveObjectESP(ObjectName)
    if self.Settings.CustomObjects[ObjectName] then
        self.Settings.CustomObjects[ObjectName] = nil
    end
    return self
end

function RobloxESP:Destroy()
    self:DisconnectESP()

    for Id, Objects in pairs(DrawingObjects) do
        for Type, Object in pairs(Objects) do
            Object:Remove()
            DrawingObjects[Id][Type] = nil
        end
        DrawingObjects[Id] = nil
    end

    self.Settings = nil
    self.Connections = nil
end

return RobloxESP

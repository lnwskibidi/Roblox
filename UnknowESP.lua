


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer


local Library = {}
Library.__index = Library


function Library.new()
    local self = setmetatable({}, Library)
    
    
    self.Objects = {}
    self.Connections = {}
    
    
    self.Settings = {
        Enabled = false,
        
        
        TeamCheck = false,
        TeamColor = false,
        MaxDistance = 2000,
        
        
        RefreshRate = 10, 
        OutlineThickness = 1,
        TextSize = 13,
        InfoOffset = 20,
        
        
        Players = {
            Enabled = true,
            
            Boxes = {
                Enabled = true,
                Color = Color3.fromRGB(255, 0, 0),
                Transparency = 1,
                Outline = true,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                OutlineTransparency = 1,
                FillColor = Color3.fromRGB(255, 0, 0),
                FillTransparency = 0.8,
                Filled = false
            },
            
            Names = {
                Enabled = true,
                Color = Color3.fromRGB(255, 255, 255),
                Transparency = 1,
                Outline = true,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                OutlineTransparency = 1,
                Font = 2, 
                Size = 13,
                ShowDisplayName = false,
                ShowDistance = true,
                Position = "Top" 
            },
            
            HealthBar = {
                Enabled = true,
                Color = Color3.fromRGB(0, 255, 0),
                Transparency = 1,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                OutlineTransparency = 1,
                Position = "Left", 
                ShowHealthText = false,
                HealthTextColor = Color3.fromRGB(255, 255, 255),
                HealthTextOutline = true,
                HealthTextOutlineColor = Color3.fromRGB(0, 0, 0),
                HealthTextSize = 13
            },
            
            Tracers = {
                Enabled = false,
                Color = Color3.fromRGB(255, 255, 255),
                Transparency = 1,
                Origin = "Bottom", 
                Outline = false,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                Thickness = 1
            },
            
            HeadDots = {
                Enabled = false,
                Color = Color3.fromRGB(255, 0, 0),
                Transparency = 1,
                Outline = true,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                OutlineTransparency = 1,
                Thickness = 1,
                Filled = true,
                Radius = 3
            },
            
            Skeletons = {
                Enabled = false,
                Color = Color3.fromRGB(255, 255, 255),
                Transparency = 1,
                Thickness = 1
            },
            
            Chams = {
                Enabled = false,
                Color = Color3.fromRGB(255, 0, 0),
                Transparency = 0.5,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                OutlineTransparency = 0.5
            },
            
            Arrow = {
                Enabled = false,
                Color = Color3.fromRGB(255, 0, 0),
                Transparency = 1,
                Filled = true,
                Size = 15,
                Radius = 150
            },
            
            Highlights = {
                Enabled = false,
                FillColor = Color3.fromRGB(255, 0, 0),
                FillTransparency = 0.5,
                OutlineColor = Color3.fromRGB(255, 0, 0),
                OutlineTransparency = 0
            }
        }
    }
    
    return self
end


function Library:Init()
    self:CreatePlayerConnections()
    
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            self:AddPlayer(Player)
        end
    end
    
    
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if self.Settings.Enabled then
            local currentTick = tick()
            
            
            if not self.LastUpdateTime or (currentTick - self.LastUpdateTime) >= (1 / self.Settings.RefreshRate) then
                self:UpdateESP()
                self.LastUpdateTime = currentTick
            end
        end
    end))
    
    return self
end


function Library:CreatePlayerConnections()
    
    table.insert(self.Connections, Players.PlayerAdded:Connect(function(Player)
        self:AddPlayer(Player)
    end))
    
    
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(Player)
        self:RemovePlayer(Player)
    end))
end


function Library:AddPlayer(Player)
    if Player == LocalPlayer then return end
    
    local PlayerESP = {
        Player = Player,
        Drawings = {},
        Connections = {}
    }
    
    
    self:CreatePlayerComponents(PlayerESP)
    
    
    table.insert(PlayerESP.Connections, Player.CharacterAdded:Connect(function(Character)
        PlayerESP.Character = Character
        self:UpdateCharacterConnections(PlayerESP)
    end))
    
    
    if Player.Character then
        PlayerESP.Character = Player.Character
        self:UpdateCharacterConnections(PlayerESP)
    end
    
    
    self.Objects[Player.Name] = PlayerESP
end


function Library:CreatePlayerComponents(PlayerESP)
    
    PlayerESP.Drawings.BoxOutline = Drawing.new("Square")
    PlayerESP.Drawings.Box = Drawing.new("Square")
    
    
    PlayerESP.Drawings.Name = Drawing.new("Text")
    PlayerESP.Drawings.Distance = Drawing.new("Text")
    
    
    PlayerESP.Drawings.HealthBarOutline = Drawing.new("Square")
    PlayerESP.Drawings.HealthBar = Drawing.new("Square")
    PlayerESP.Drawings.HealthText = Drawing.new("Text")
    
    
    PlayerESP.Drawings.Tracer = Drawing.new("Line")
    
    
    PlayerESP.Drawings.HeadDot = Drawing.new("Circle")
    PlayerESP.Drawings.HeadDotOutline = Drawing.new("Circle")
    
    
    PlayerESP.Drawings.Skeleton = {}
    
    
    self:ConfigureComponents(PlayerESP)
end


function Library:ConfigureComponents(PlayerESP)
    
    PlayerESP.Drawings.BoxOutline.Thickness = self.Settings.OutlineThickness
    PlayerESP.Drawings.BoxOutline.Filled = false
    PlayerESP.Drawings.BoxOutline.Visible = false
    PlayerESP.Drawings.BoxOutline.ZIndex = 1
    
    PlayerESP.Drawings.Box.Thickness = 1
    PlayerESP.Drawings.Box.Filled = false
    PlayerESP.Drawings.Box.Visible = false
    PlayerESP.Drawings.Box.ZIndex = 2
    
    
    PlayerESP.Drawings.Name.Size = self.Settings.Players.Names.Size
    PlayerESP.Drawings.Name.Center = true
    PlayerESP.Drawings.Name.Outline = self.Settings.Players.Names.Outline
    PlayerESP.Drawings.Name.Visible = false
    
    
    PlayerESP.Drawings.Distance.Size = self.Settings.Players.Names.Size
    PlayerESP.Drawings.Distance.Center = true
    PlayerESP.Drawings.Distance.Outline = self.Settings.Players.Names.Outline
    PlayerESP.Drawings.Distance.Visible = false
    
    
    PlayerESP.Drawings.HealthBarOutline.Thickness = 1
    PlayerESP.Drawings.HealthBarOutline.Filled = false
    PlayerESP.Drawings.HealthBarOutline.Visible = false
    
    PlayerESP.Drawings.HealthBar.Thickness = 1
    PlayerESP.Drawings.HealthBar.Filled = true
    PlayerESP.Drawings.HealthBar.Visible = false
    
    
    PlayerESP.Drawings.HealthText.Size = self.Settings.Players.HealthBar.HealthTextSize
    PlayerESP.Drawings.HealthText.Center = false
    PlayerESP.Drawings.HealthText.Outline = self.Settings.Players.HealthBar.HealthTextOutline
    PlayerESP.Drawings.HealthText.Visible = false
    
    
    PlayerESP.Drawings.Tracer.Thickness = self.Settings.Players.Tracers.Thickness
    PlayerESP.Drawings.Tracer.Visible = false
    
    
    PlayerESP.Drawings.HeadDotOutline.Thickness = 1
    PlayerESP.Drawings.HeadDotOutline.NumSides = 30
    PlayerESP.Drawings.HeadDotOutline.Visible = false
    
    PlayerESP.Drawings.HeadDot.Thickness = 1
    PlayerESP.Drawings.HeadDot.NumSides = 30
    PlayerESP.Drawings.HeadDot.Visible = false
    
    
    self:ApplySettings(PlayerESP)
end


function Library:ApplySettings(PlayerESP)
    
    PlayerESP.Drawings.Box.Color = self.Settings.Players.Boxes.Color
    PlayerESP.Drawings.Box.Transparency = self.Settings.Players.Boxes.Transparency
    PlayerESP.Drawings.Box.Filled = self.Settings.Players.Boxes.Filled
    
    if self.Settings.Players.Boxes.Filled then
        PlayerESP.Drawings.Box.Color = self.Settings.Players.Boxes.FillColor
        PlayerESP.Drawings.Box.Transparency = self.Settings.Players.Boxes.FillTransparency
    end
    
    PlayerESP.Drawings.BoxOutline.Color = self.Settings.Players.Boxes.OutlineColor
    PlayerESP.Drawings.BoxOutline.Transparency = self.Settings.Players.Boxes.OutlineTransparency
    
    
    PlayerESP.Drawings.Name.Color = self.Settings.Players.Names.Color
    PlayerESP.Drawings.Name.Transparency = self.Settings.Players.Names.Transparency
    PlayerESP.Drawings.Name.OutlineColor = self.Settings.Players.Names.OutlineColor
    PlayerESP.Drawings.Name.Font = self.Settings.Players.Names.Font
    PlayerESP.Drawings.Name.Size = self.Settings.Players.Names.Size
    
    
    PlayerESP.Drawings.Distance.Color = self.Settings.Players.Names.Color
    PlayerESP.Drawings.Distance.Transparency = self.Settings.Players.Names.Transparency
    PlayerESP.Drawings.Distance.OutlineColor = self.Settings.Players.Names.OutlineColor
    PlayerESP.Drawings.Distance.Font = self.Settings.Players.Names.Font
    PlayerESP.Drawings.Distance.Size = self.Settings.Players.Names.Size
    
    
    PlayerESP.Drawings.HealthBarOutline.Color = self.Settings.Players.HealthBar.OutlineColor
    PlayerESP.Drawings.HealthBarOutline.Transparency = self.Settings.Players.HealthBar.OutlineTransparency
    
    
    PlayerESP.Drawings.HealthText.Color = self.Settings.Players.HealthBar.HealthTextColor
    PlayerESP.Drawings.HealthText.OutlineColor = self.Settings.Players.HealthBar.HealthTextOutlineColor
    PlayerESP.Drawings.HealthText.Size = self.Settings.Players.HealthBar.HealthTextSize
    
    
    PlayerESP.Drawings.Tracer.Color = self.Settings.Players.Tracers.Color
    PlayerESP.Drawings.Tracer.Transparency = self.Settings.Players.Tracers.Transparency
    PlayerESP.Drawings.Tracer.Thickness = self.Settings.Players.Tracers.Thickness
    
    
    PlayerESP.Drawings.HeadDot.Color = self.Settings.Players.HeadDots.Color
    PlayerESP.Drawings.HeadDot.Transparency = self.Settings.Players.HeadDots.Transparency
    PlayerESP.Drawings.HeadDot.Thickness = self.Settings.Players.HeadDots.Thickness
    PlayerESP.Drawings.HeadDot.Filled = self.Settings.Players.HeadDots.Filled
    PlayerESP.Drawings.HeadDot.Radius = self.Settings.Players.HeadDots.Radius
    
    PlayerESP.Drawings.HeadDotOutline.Color = self.Settings.Players.HeadDots.OutlineColor
    PlayerESP.Drawings.HeadDotOutline.Transparency = self.Settings.Players.HeadDots.OutlineTransparency
    PlayerESP.Drawings.HeadDotOutline.Radius = self.Settings.Players.HeadDots.Radius + 1
    PlayerESP.Drawings.HeadDotOutline.Filled = false
end


function Library:UpdateCharacterConnections(PlayerESP)
    
    for _, Connection in pairs(PlayerESP.CharacterConnections or {}) do
        Connection:Disconnect()
    end
    
    PlayerESP.CharacterConnections = {}
    
    
    local Character = PlayerESP.Character
    if not Character then return end
    
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        table.insert(PlayerESP.CharacterConnections, Humanoid.Changed:Connect(function(Property)
            if Property == "Health" or Property == "MaxHealth" then
                self:UpdatePlayerESP(PlayerESP)
            end
        end))
    end
end


function Library:RemovePlayer(Player)
    local PlayerESP = self.Objects[Player.Name]
    if not PlayerESP then return end
    
    
    for _, Connection in pairs(PlayerESP.Connections) do
        Connection:Disconnect()
    end
    
    if PlayerESP.CharacterConnections then
        for _, Connection in pairs(PlayerESP.CharacterConnections) do
            Connection:Disconnect()
        end
    end
    
    
    for Name, Drawing in pairs(PlayerESP.Drawings) do
        if type(Drawing) == "table" then
            for _, SubDrawing in pairs(Drawing) do
                SubDrawing:Remove()
            end
        else
            Drawing:Remove()
        end
    end
    
    
    self.Objects[Player.Name] = nil
end


function Library:UpdateESP()
    if not self.Settings.Enabled or not self.Settings.Players.Enabled then
        self:HideAllESP()
        return
    end
    
    for _, PlayerESP in pairs(self.Objects) do
        self:UpdatePlayerESP(PlayerESP)
    end
end


function Library:UpdatePlayerESP(PlayerESP)
    
    if not self:IsPlayerValid(PlayerESP) then
        self:HidePlayerESP(PlayerESP)
        return
    end
    
    
    if self.Settings.TeamCheck and self:IsTeammate(PlayerESP.Player) then
        self:HidePlayerESP(PlayerESP)
        return
    end
    
    
    local Character = PlayerESP.Character
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Head = Character:FindFirstChild("Head")
    
    
    local Distance = (HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    if Distance > self.Settings.MaxDistance then
        self:HidePlayerESP(PlayerESP)
        return
    end
    
    
    local PlayerColor = self:GetPlayerColor(PlayerESP.Player)
    
    
    self:UpdateBoxESP(PlayerESP, PlayerColor)
    self:UpdateNameESP(PlayerESP, PlayerColor, Distance)
    self:UpdateHealthESP(PlayerESP, Humanoid)
    self:UpdateTracerESP(PlayerESP, PlayerColor)
    self:UpdateHeadDotESP(PlayerESP, PlayerColor, Head)
end


function Library:IsPlayerValid(PlayerESP)
    
    if not PlayerESP.Player or not PlayerESP.Player.Parent then
        return false
    end
    
    
    local Character = PlayerESP.Character
    if not Character or not Character.Parent then
        return false
    end
    
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if not HumanoidRootPart or not Humanoid then
        return false
    end
    
    
    if Humanoid.Health <= 0 then
        return false
    end
    
    return true
end


function Library:IsTeammate(Player)
    
    if Player.Team and LocalPlayer.Team then
        return Player.Team == LocalPlayer.Team
    elseif Player.TeamColor and LocalPlayer.TeamColor then
        return Player.TeamColor == LocalPlayer.TeamColor
    end
    
    return false
end


function Library:GetPlayerColor(Player)
    if self.Settings.TeamColor and Player.Team then
        return Player.TeamColor.Color
    end
    
    return self.Settings.Players.Boxes.Color
end


function Library:GetBoundingBox(Character)
    
    local Parts = {}
    for _, Part in pairs(Character:GetChildren()) do
        if Part:IsA("BasePart") then
            table.insert(Parts, Part)
        end
    end
    
    if #Parts == 0 then
        return nil, nil
    end
    
    
    local MinX, MinY, MinZ = math.huge, math.huge, math.huge
    local MaxX, MaxY, MaxZ = -math.huge, -math.huge, -math.huge
    
    for _, Part in ipairs(Parts) do
        local Size = Part.Size
        local CF = Part.CFrame
        
        local Corners = {
            CF * CFrame.new(-Size.X/2, -Size.Y/2, -Size.Z/2),
            CF * CFrame.new(-Size.X/2, -Size.Y/2, Size.Z/2),
            CF * CFrame.new(-Size.X/2, Size.Y/2, -Size.Z/2),
            CF * CFrame.new(-Size.X/2, Size.Y/2, Size.Z/2),
            CF * CFrame.new(Size.X/2, -Size.Y/2, -Size.Z/2),
            CF * CFrame.new(Size.X/2, -Size.Y/2, Size.Z/2),
            CF * CFrame.new(Size.X/2, Size.Y/2, -Size.Z/2),
            CF * CFrame.new(Size.X/2, Size.Y/2, Size.Z/2)
        }
        
        for _, Corner in ipairs(Corners) do
            local Pos = Corner.Position
            MinX = math.min(MinX, Pos.X)
            MinY = math.min(MinY, Pos.Y)
            MinZ = math.min(MinZ, Pos.Z)
            MaxX = math.max(MaxX, Pos.X)
            MaxY = math.max(MaxY, Pos.Y)
            MaxZ = math.max(MaxZ, Pos.Z)
        end
    end
    
    
    local ScreenPointMin = Camera:WorldToViewportPoint(Vector3.new(MinX, MinY, MinZ))
    local ScreenPointMax = Camera:WorldToViewportPoint(Vector3.new(MaxX, MaxY, MaxZ))
    
    
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    local _, OnScreen = Camera:WorldToViewportPoint(HRP.Position)
    if not OnScreen then
        return nil, nil
    end
    
    
    local BoxSize = Vector2.new(
        math.abs(ScreenPointMax.X - ScreenPointMin.X),
        math.abs(ScreenPointMax.Y - ScreenPointMin.Y)
    )
    
    local BoxPosition = Vector2.new(
        math.min(ScreenPointMin.X, ScreenPointMax.X),
        math.min(ScreenPointMin.Y, ScreenPointMax.Y)
    )
    
    return BoxSize, BoxPosition
end


function Library:UpdateBoxESP(PlayerESP, PlayerColor)
    if not self.Settings.Players.Boxes.Enabled then
        PlayerESP.Drawings.Box.Visible = false
        PlayerESP.Drawings.BoxOutline.Visible = false
        return
    end
    
    
    local BoxSize, BoxPosition = self:GetBoundingBox(PlayerESP.Character)
    if not BoxSize or not BoxPosition then
        PlayerESP.Drawings.Box.Visible = false
        PlayerESP.Drawings.BoxOutline.Visible = false
        return
    end
    
    
    PlayerESP.Drawings.Box.Size = BoxSize
    PlayerESP.Drawings.Box.Position = BoxPosition
    
    
    if self.Settings.TeamColor then
        PlayerESP.Drawings.Box.Color = PlayerColor
    else
        PlayerESP.Drawings.Box.Color = self.Settings.Players.Boxes.Color
    end
    
    PlayerESP.Drawings.Box.Visible = true
    
    
    if self.Settings.Players.Boxes.Outline then
        PlayerESP.Drawings.BoxOutline.Size = BoxSize
        PlayerESP.Drawings.BoxOutline.Position = BoxPosition
        PlayerESP.Drawings.BoxOutline.Visible = true
    else
        PlayerESP.Drawings.BoxOutline.Visible = false
    end
end


function Library:UpdateNameESP(PlayerESP, PlayerColor, Distance)
    if not self.Settings.Players.Names.Enabled then
        PlayerESP.Drawings.Name.Visible = false
        PlayerESP.Drawings.Distance.Visible = false
        return
    end
    
    
    local BoxSize, BoxPosition = self:GetBoundingBox(PlayerESP.Character)
    if not BoxSize or not BoxPosition then
        PlayerESP.Drawings.Name.Visible = false
        PlayerESP.Drawings.Distance.Visible = false
        return
    end
    
    
    local NameText = self.Settings.Players.Names.ShowDisplayName and 
                    PlayerESP.Player.DisplayName or 
                    PlayerESP.Player.Name
    
    
    local NamePosition
    if self.Settings.Players.Names.Position == "Top" then
        NamePosition = Vector2.new(
            BoxPosition.X + (BoxSize.X / 2),
            BoxPosition.Y - self.Settings.InfoOffset
        )
    else
        NamePosition = Vector2.new(
            BoxPosition.X + (BoxSize.X / 2),
            BoxPosition.Y + BoxSize.Y + self.Settings.InfoOffset/2
        )
    end
    
    
    PlayerESP.Drawings.Name.Text = NameText
    PlayerESP.Drawings.Name.Position = NamePosition
    
    
    if self.Settings.TeamColor then
        PlayerESP.Drawings.Name.Color = PlayerColor
    else
        PlayerESP.Drawings.Name.Color = self.Settings.Players.Names.Color
    end
    
    PlayerESP.Drawings.Name.Visible = true
    
    
    if self.Settings.Players.Names.ShowDistance then
        local DistanceText = math.floor(Distance) .. " studs"
        local DistancePosition = Vector2.new(
            BoxPosition.X + (BoxSize.X / 2),
            NamePosition.Y + self.Settings.Players.Names.Size + 2
        )
        
        PlayerESP.Drawings.Distance.Text = DistanceText
        PlayerESP.Drawings.Distance.Position = DistancePosition
        
        
        if self.Settings.TeamColor then
            PlayerESP.Drawings.Distance.Color = PlayerColor
        else
            PlayerESP.Drawings.Distance.Color = self.Settings.Players.Names.Color
        end
        
        PlayerESP.Drawings.Distance.Visible = true
    else
        PlayerESP.Drawings.Distance.Visible = false
    end
end


function Library:UpdateHealthESP(PlayerESP, Humanoid)
    if not self.Settings.Players.HealthBar.Enabled then
        PlayerESP.Drawings.HealthBarOutline.Visible = false
        PlayerESP.Drawings.HealthBar.Visible = false
        PlayerESP.Drawings.HealthText.Visible = false
        return
    end
    
    
    local BoxSize, BoxPosition = self:GetBoundingBox(PlayerESP.Character)
    if not BoxSize or not BoxPosition then
        PlayerESP.Drawings.HealthBarOutline.Visible = false
        PlayerESP.Drawings.HealthBar.Visible = false
        PlayerESP.Drawings.HealthText.Visible = false
        return
    end
    
    
    local HealthPercent = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
    
    
    local BarOutlineSize, BarOutlinePos, BarSize, BarPos, TextPos
    
    if self.Settings.Players.HealthBar.Position == "Left" then
        BarOutlineSize = Vector2.new(4, BoxSize.Y)
        BarOutlinePos = Vector2.new(BoxPosition.X - 8, BoxPosition.Y)
        
        BarSize = Vector2.new(2, BoxSize.Y * HealthPercent)
        BarPos = Vector2.new(BoxPosition.X - 7, BoxPosition.Y + BoxSize.Y * (1 - HealthPercent))
        
        TextPos = Vector2.new(BoxPosition.X - 20, BoxPosition.Y)
    elseif self.Settings.Players.HealthBar.Position == "Right" then
        BarOutlineSize = Vector2.new(4, BoxSize.Y)
        BarOutlinePos = Vector2.new(BoxPosition.X + BoxSize.X + 4, BoxPosition.Y)
        
        BarSize = Vector2.new(2, BoxSize.Y * HealthPercent)
        BarPos = Vector2.new(BoxPosition.X + BoxSize.X + 5, BoxPosition.Y + BoxSize.Y * (1 - HealthPercent))
        
        TextPos = Vector2.new(BoxPosition.X + BoxSize.X + 10, BoxPosition.Y)
    else 
        BarOutlineSize = Vector2.new(BoxSize.X, 4)
        BarOutlinePos = Vector2.new(BoxPosition.X, BoxPosition.Y + BoxSize.Y + 2)
        
        BarSize = Vector2.new(BoxSize.X * HealthPercent, 2)
        BarPos = Vector2.new(BoxPosition.X, BoxPosition.Y + BoxSize.Y + 3)
        
        TextPos = Vector2.new(BoxPosition.X, BoxPosition.Y + BoxSize.Y + 6)
    end
    
    
    PlayerESP.Drawings.HealthBarOutline.Size = BarOutlineSize
    PlayerESP.Drawings.HealthBarOutline.Position = BarOutlinePos
    PlayerESP.Drawings.HealthBarOutline.Visible = true
    
    
    PlayerESP.Drawings.HealthBar.Size = BarSize
    PlayerESP.Drawings.HealthBar.Position = BarPos
    
    
    local HealthColor = Color3.fromRGB(
        255 * (1 - HealthPercent),
        255 * HealthPercent,
        0
    )
    
    PlayerESP.Drawings.HealthBar.Color = HealthColor
    PlayerESP.Drawings.HealthBar.Visible = true
    
    
    if self.Settings.Players.HealthBar.ShowHealthText then
        local HealthText = math.floor(Humanoid.Health) .. "/" .. math.floor(Humanoid.MaxHealth)
        
        PlayerESP.Drawings.HealthText.Text = HealthText
        PlayerESP.Drawings.HealthText.Position = TextPos
        PlayerESP.Drawings.HealthText.Visible = true
    else
        PlayerESP.Drawings.HealthText.Visible = false
    end
end


function Library:UpdateTracerESP(PlayerESP, PlayerColor)
    if not self.Settings.Players.Tracers.Enabled then
        PlayerESP.Drawings.Tracer.Visible = false
        return
    end
    
    
    local HumanoidRootPart = PlayerESP.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then
        PlayerESP.Drawings.Tracer.Visible = false
        return
    end
    
    
    local RootPos, OnScreen = Camera:WorldToViewportPoint(HumanoidRootPart.Position)
    if not OnScreen then
        PlayerESP.Drawings.Tracer.Visible = false
        return
    end
    
    
    local Origin
    if self.Settings.Players.Tracers.Origin == "Mouse" then
        Origin = UserInputService:GetMouseLocation()
    elseif self.Settings.Players.Tracers.Origin == "Top" then
        Origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif self.Settings.Players.Tracers.Origin == "Bottom" then
        Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    else 
        Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    
    PlayerESP.Drawings.Tracer.From = Origin
    PlayerESP.Drawings.Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
    
    
    if self.Settings.TeamColor then
        PlayerESP.Drawings.Tracer.Color = PlayerColor
    else
        PlayerESP.Drawings.Tracer.Color = self.Settings.Players.Tracers.Color
    end
    
    PlayerESP.Drawings.Tracer.Visible = true
end


function Library:UpdateHeadDotESP(PlayerESP, PlayerColor, Head)
    if not self.Settings.Players.HeadDots.Enabled or not Head then
        PlayerESP.Drawings.HeadDot.Visible = false
        PlayerESP.Drawings.HeadDotOutline.Visible = false
        return
    end
    
    
    local HeadPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
    if not OnScreen then
        PlayerESP.Drawings.HeadDot.Visible = false
        PlayerESP.Drawings.HeadDotOutline.Visible = false
        return
    end
    
    
    PlayerESP.Drawings.HeadDot.Position = Vector2.new(HeadPos.X, HeadPos.Y)
    PlayerESP.Drawings.HeadDot.Radius = self.Settings.Players.HeadDots.Radius
    
    
    if self.Settings.TeamColor then
        PlayerESP.Drawings.HeadDot.Color = PlayerColor
    else
        PlayerESP.Drawings.HeadDot.Color = self.Settings.Players.HeadDots.Color
    end
    
    PlayerESP.Drawings.HeadDot.Visible = true
    
    
    if self.Settings.Players.HeadDots.Outline then
        PlayerESP.Drawings.HeadDotOutline.Position = Vector2.new(HeadPos.X, HeadPos.Y)
        PlayerESP.Drawings.HeadDotOutline.Radius = self.Settings.Players.HeadDots.Radius + 1
        PlayerESP.Drawings.HeadDotOutline.Visible = true
    else
        PlayerESP.Drawings.HeadDotOutline.Visible = false
    end
end


function Library:HidePlayerESP(PlayerESP)
    for Name, Drawing in pairs(PlayerESP.Drawings) do
        if type(Drawing) == "table" then
            for _, SubDrawing in pairs(Drawing) do
                SubDrawing.Visible = false
            end
        else
            Drawing.Visible = false
        end
    end
end


function Library:HideAllESP()
    for _, PlayerESP in pairs(self.Objects) do
        self:HidePlayerESP(PlayerESP)
    end
end


function Library:Toggle(Enabled)
    if Enabled ~= nil then
        self.Settings.Enabled = Enabled
    else
        self.Settings.Enabled = not self.Settings.Enabled
    end
    
    if not self.Settings.Enabled then
        self:HideAllESP()
    end
    
    return self.Settings.Enabled
end


function Library:SetSetting(Path, Value)
    local Settings = self.Settings
    local PathParts = string.split(Path, ".")
    
    for i = 1, #PathParts - 1 do
        Settings = Settings[PathParts[i]]
        if not Settings then
            return false
        end
    end
    
    Settings[PathParts[#PathParts]] = Value
    return true
end


function Library:GetSetting(Path)
    local Settings = self.Settings
    local PathParts = string.split(Path, ".")
    
    for i = 1, #PathParts do
        Settings = Settings[PathParts[i]]
        if not Settings then
            return nil
        end
    end
    
    return Settings
end


function Library:SetTheme(Theme)
    if Theme == "Default" then
        self.Settings.Players.Boxes.Color = Color3.fromRGB(255, 0, 0)
        self.Settings.Players.Boxes.OutlineColor = Color3.fromRGB(0, 0, 0)
        self.Settings.Players.Names.Color = Color3.fromRGB(255, 255, 255)
        self.Settings.Players.Names.OutlineColor = Color3.fromRGB(0, 0, 0)
        self.Settings.Players.Tracers.Color = Color3.fromRGB(255, 255, 255)
    elseif Theme == "Light" then
        self.Settings.Players.Boxes.Color = Color3.fromRGB(0, 0, 0)
        self.Settings.Players.Boxes.OutlineColor = Color3.fromRGB(255, 255, 255)
        self.Settings.Players.Names.Color = Color3.fromRGB(0, 0, 0)
        self.Settings.Players.Names.OutlineColor = Color3.fromRGB(255, 255, 255)
        self.Settings.Players.Tracers.Color = Color3.fromRGB(0, 0, 0)
    elseif Theme == "Rainbow" then
        
        self.Settings.RainbowEnabled = true
    else
        
        return false
    end
    
    return true
end


function Library:UpdateRainbowTheme()
    if not self.Settings.RainbowEnabled then
        return
    end
    
    
    local Time = tick() % 5 / 5
    local Color = Color3.fromHSV(Time, 1, 1)
    
    
    self.Settings.Players.Boxes.Color = Color
    self.Settings.Players.Names.Color = Color
    self.Settings.Players.Tracers.Color = Color
    self.Settings.Players.HeadDots.Color = Color
end


function Library:Destroy()
    
    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end
    
    
    for PlayerName, PlayerESP in pairs(self.Objects) do
        self:RemovePlayer(PlayerESP.Player)
    end
    
    self.Objects = {}
    self.Connections = {}
end


function Library:EnableBoxes(Enabled)
    self.Settings.Players.Boxes.Enabled = Enabled
end

function Library:EnableNames(Enabled)
    self.Settings.Players.Names.Enabled = Enabled
end

function Library:EnableTracers(Enabled)
    self.Settings.Players.Tracers.Enabled = Enabled
end

function Library:EnableHealthBars(Enabled)
    self.Settings.Players.HealthBar.Enabled = Enabled
end

function Library:EnableHeadDots(Enabled)
    self.Settings.Players.HeadDots.Enabled = Enabled
end

function Library:SetColor(Color)
    self.Settings.Players.Boxes.Color = Color
    self.Settings.Players.Names.Color = Color
    self.Settings.Players.Tracers.Color = Color
    self.Settings.Players.HeadDots.Color = Color
end

function Library:SetOutlineColor(Color)
    self.Settings.Players.Boxes.OutlineColor = Color
    self.Settings.Players.Names.OutlineColor = Color
    self.Settings.Players.HeadDots.OutlineColor = Color
end


return Library

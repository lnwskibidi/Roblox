--[[
    Customizable Roblox ESP Library
    Features:
    - Name ESP
    - Box ESP
    - Healthbar ESP
    - Distance ESP
    - Chams (Player highlighting)
    - Skeleton ESP
    - Tracer ESP
    
    Instructions:
    1. Execute this script in your exploit
    2. Use the ESP.toggle functions to enable/disable features
    3. Customize colors and settings as needed
--]]

local ESP = {
    Enabled = true,
    
    -- Feature toggles
    ShowName = true,
    ShowBox = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowChams = true,
    ShowSkeleton = true,
    ShowTracer = true,
    
    -- Customization
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    DistanceColor = Color3.fromRGB(255, 255, 255),
    ChamsColor = Color3.fromRGB(255, 0, 0),
    ChamsTransparency = 0.5,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 0, 0),
    
    -- Settings
    TextSize = 14,
    BoxThickness = 1,
    HealthbarThickness = 1,
    SkeletonThickness = 1,
    TracerThickness = 1,
    TracerOrigin = "Bottom", -- "Bottom", "Center", "Mouse"
    
    -- Private properties
    _players = {},
    _connections = {},
    _drawings = {}
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Check if drawing library is available (required for ESP)
local drawingSupported = pcall(function() return Drawing.new end)
if not drawingSupported then
    warn("ESP Library: Drawing API not available in your exploit!")
    return
end

-- Create container for ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_Elements"
espFolder.Parent = CoreGui

-- Utility functions
local function create(class, properties)
    local instance = Drawing.new(class)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function worldToScreen(position)
    local screenPosition, onScreen = Camera:WorldToScreenPoint(position)
    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen and screenPosition.Z > 0
end

local function getPlayerBoundingBox(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local size = character:GetExtentsSize()
    local cf = hrp.CFrame
    
    local topRight = cf * CFrame.new(size.X/2, size.Y/2, 0)
    local topLeft = cf * CFrame.new(-size.X/2, size.Y/2, 0)
    local bottomRight = cf * CFrame.new(size.X/2, -size.Y/2, 0)
    local bottomLeft = cf * CFrame.new(-size.X/2, -size.Y/2, 0)
    
    local corners = {
        topRight = worldToScreen(topRight.Position),
        topLeft = worldToScreen(topLeft.Position),
        bottomRight = worldToScreen(bottomRight.Position),
        bottomLeft = worldToScreen(bottomLeft.Position)
    }
    
    return corners
end

local function getLimbPositions(character)
    local limbs = {}
    
    -- Get key limb parts
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
    local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    local leftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
    local rightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    local leftForearm = character:FindFirstChild("LeftLowerArm")
    local rightForearm = character:FindFirstChild("RightLowerArm")
    local leftShin = character:FindFirstChild("LeftLowerLeg")
    local rightShin = character:FindFirstChild("RightLowerLeg")
    local leftFoot = character:FindFirstChild("LeftFoot")
    local rightFoot = character:FindFirstChild("RightFoot")
    
    -- Create connections list (R15/R6 compatible)
    local connections = {}
    
    if head and torso then
        table.insert(connections, {head, torso})
    end
    
    if torso then
        if leftArm then table.insert(connections, {torso, leftArm}) end
        if rightArm then table.insert(connections, {torso, rightArm}) end
        if leftLeg then table.insert(connections, {torso, leftLeg}) end
        if rightLeg then table.insert(connections, {torso, rightLeg}) end
    end
    
    if leftArm and leftForearm then table.insert(connections, {leftArm, leftForearm}) end
    if rightArm and rightForearm then table.insert(connections, {rightArm, rightForearm}) end
    if leftLeg and leftShin then table.insert(connections, {leftLeg, leftShin}) end
    if rightLeg and rightShin then table.insert(connections, {rightLeg, rightShin}) end
    if leftShin and leftFoot then table.insert(connections, {leftShin, leftFoot}) end
    if rightShin and rightFoot then table.insert(connections, {rightShin, rightFoot}) end
    
    -- Convert to screen positions
    for _, connection in ipairs(connections) do
        local part1, part2 = connection[1], connection[2]
        local pos1, onScreen1 = worldToScreen(part1.Position)
        local pos2, onScreen2 = worldToScreen(part2.Position)
        
        if onScreen1 and onScreen2 then
            table.insert(limbs, {pos1, pos2})
        end
    end
    
    return limbs
end

local function getDistance(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerPos then return 0 end
    
    return math.floor((hrp.Position - playerPos.Position).Magnitude)
end

local function getTracerOrigin()
    if ESP.TracerOrigin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif ESP.TracerOrigin == "Center" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif ESP.TracerOrigin == "Mouse" then
        return Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)
    end
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
end

local function createPlayerESP(player)
    if player == LocalPlayer then return end
    
    ESP._players[player] = {
        name = create("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            Size = ESP.TextSize,
            Color = ESP.NameColor,
            OutlineColor = Color3.new(0, 0, 0)
        }),
        box = {
            topLeft = create("Line", {
                Visible = false,
                Thickness = ESP.BoxThickness,
                Color = ESP.BoxColor
            }),
            topRight = create("Line", {
                Visible = false,
                Thickness = ESP.BoxThickness,
                Color = ESP.BoxColor
            }),
            bottomLeft = create("Line", {
                Visible = false,
                Thickness = ESP.BoxThickness,
                Color = ESP.BoxColor
            }),
            bottomRight = create("Line", {
                Visible = false,
                Thickness = ESP.BoxThickness,
                Color = ESP.BoxColor
            })
        },
        healthBg = create("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            Color = Color3.new(0, 0, 0),
            Transparency = 0.5
        }),
        healthBar = create("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            Color = ESP.HealthColor
        }),
        distance = create("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            Size = ESP.TextSize,
            Color = ESP.DistanceColor,
            OutlineColor = Color3.new(0, 0, 0)
        }),
        skeleton = {},
        tracer = create("Line", {
            Visible = false,
            Thickness = ESP.TracerThickness,
            Color = ESP.TracerColor
        }),
        chams = {}
    }
    
    -- Create skeleton lines
    for i = 1, 15 do
        table.insert(ESP._players[player].skeleton, create("Line", {
            Visible = false,
            Thickness = ESP.SkeletonThickness,
            Color = ESP.SkeletonColor
        }))
    end
    
    -- Track when player leaves
    ESP._connections[player] = player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            ESP:RemovePlayer(player)
        end
    end)
    
    -- Record created drawings
    for _, drawing in pairs(ESP._players[player]) do
        if type(drawing) ~= "table" then
            table.insert(ESP._drawings, drawing)
        elseif drawing ~= ESP._players[player].chams then
            for _, subDrawing in pairs(drawing) do
                table.insert(ESP._drawings, subDrawing)
            end
        end
    end
end

function ESP:GetHealth(player)
    local character = player.Character
    if not character then return 0, 100 end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0, 100 end
    
    return humanoid.Health, humanoid.MaxHealth
end

function ESP:ToggleESP(enabled)
    self.Enabled = enabled
end

function ESP:ToggleNameESP(enabled)
    self.ShowName = enabled
end

function ESP:ToggleBoxESP(enabled)
    self.ShowBox = enabled
end

function ESP:ToggleHealthESP(enabled)
    self.ShowHealth = enabled
end

function ESP:ToggleDistanceESP(enabled)
    self.ShowDistance = enabled
end

function ESP:ToggleChamsESP(enabled)
    self.ShowChams = enabled
    
    if not enabled then
        -- Remove all existing chams
        for player, esp in pairs(self._players) do
            for _, highlight in pairs(esp.chams) do
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end
            self._players[player].chams = {}
        end
    end
end

function ESP:ToggleSkeletonESP(enabled)
    self.ShowSkeleton = enabled
end

function ESP:ToggleTracerESP(enabled)
    self.ShowTracer = enabled
end

function ESP:SetColor(feature, color)
    if feature == "Box" then
        self.BoxColor = color
    elseif feature == "Name" then
        self.NameColor = color
    elseif feature == "Health" then
        self.HealthColor = color
    elseif feature == "Distance" then
        self.DistanceColor = color
    elseif feature == "Chams" then
        self.ChamsColor = color
    elseif feature == "Skeleton" then
        self.SkeletonColor = color
    elseif feature == "Tracer" then
        self.TracerColor = color
    end
end

function ESP:SetTracerOrigin(origin)
    if origin == "Bottom" or origin == "Center" or origin == "Mouse" then
        self.TracerOrigin = origin
    end
end

function ESP:RemovePlayer(player)
    local playerESP = self._players[player]
    if not playerESP then return end
    
    -- Remove all drawings
    for _, drawing in pairs(playerESP) do
        if type(drawing) ~= "table" then
            drawing:Remove()
        elseif drawing ~= playerESP.chams then
            for _, subDrawing in pairs(drawing) do
                subDrawing:Remove()
            end
        else
            for _, highlight in pairs(drawing) do
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end
        end
    end
    
    -- Disconnect player connection
    if self._connections[player] then
        self._connections[player]:Disconnect()
        self._connections[player] = nil
    end
    
    -- Remove player from ESP list
    self._players[player] = nil
end

function ESP:UpdateChams(player)
    if not self.ShowChams or not self.Enabled then return end
    
    local playerESP = self._players[player]
    if not playerESP then return end
    
    local character = player.Character
    if not character then return end
    
    -- Clear existing chams
    for _, highlight in pairs(playerESP.chams) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    playerESP.chams = {}
    
    -- Create new chams for each part
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = self.ChamsColor
            highlight.OutlineColor = self.ChamsColor
            highlight.FillTransparency = self.ChamsTransparency
            highlight.OutlineTransparency = 0.7
            highlight.Adornee = part
            highlight.Parent = espFolder
            
            table.insert(playerESP.chams, highlight)
        end
    end
end

-- Main ESP update function
function ESP:Update()
    if not self.Enabled then
        for _, esp in pairs(self._players) do
            for _, drawing in pairs(esp) do
                if type(drawing) ~= "table" then
                    drawing.Visible = false
                elseif drawing ~= esp.chams then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                end
            end
        end
        return
    end
    
    for player, esp in pairs(self._players) do
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChildOfClass("Humanoid") then
            -- Hide ESP if character isn't loaded
            for _, drawing in pairs(esp) do
                if type(drawing) ~= "table" then
                    drawing.Visible = false
                elseif drawing ~= esp.chams then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                end
            end
            continue
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        
        -- Check if player is on screen
        local pos, onScreen = worldToScreen(hrp.Position)
        if not onScreen then
            -- Hide ESP if player is off screen
            for _, drawing in pairs(esp) do
                if type(drawing) ~= "table" then
                    drawing.Visible = false
                elseif drawing ~= esp.chams then
                    for _, subDrawing in pairs(drawing) do
                        subDrawing.Visible = false
                    end
                end
            end
            continue
        end
        
        -- Update Chams (Highlight instances)
        if self.ShowChams then
            if #esp.chams == 0 then
                self:UpdateChams(player)
            end
        else
            for _, highlight in pairs(esp.chams) do
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end
            esp.chams = {}
        end
        
        -- Update Box ESP
        if self.ShowBox then
            local corners = getPlayerBoundingBox(character)
            if corners then
                -- Top Line
                esp.box.topLeft.From = corners.topLeft
                esp.box.topLeft.To = corners.topRight
                esp.box.topLeft.Color = self.BoxColor
                esp.box.topLeft.Thickness = self.BoxThickness
                esp.box.topLeft.Visible = true
                
                -- Right Line
                esp.box.topRight.From = corners.topRight
                esp.box.topRight.To = corners.bottomRight
                esp.box.topRight.Color = self.BoxColor
                esp.box.topRight.Thickness = self.BoxThickness
                esp.box.topRight.Visible = true
                
                -- Bottom Line
                esp.box.bottomLeft.From = corners.bottomLeft
                esp.box.bottomLeft.To = corners.bottomRight
                esp.box.bottomLeft.Color = self.BoxColor
                esp.box.bottomLeft.Thickness = self.BoxThickness
                esp.box.bottomLeft.Visible = true
                
                -- Left Line
                esp.box.bottomRight.From = corners.topLeft
                esp.box.bottomRight.To = corners.bottomLeft
                esp.box.bottomRight.Color = self.BoxColor
                esp.box.bottomRight.Thickness = self.BoxThickness
                esp.box.bottomRight.Visible = true
            else
                for _, line in pairs(esp.box) do
                    line.Visible = false
                end
            end
        else
            for _, line in pairs(esp.box) do
                line.Visible = false
            end
        end
        
        -- Update Name ESP
        if self.ShowName then
            local headPos
            if head then
                headPos, _ = worldToScreen(head.Position + Vector3.new(0, 1, 0))
            else
                headPos = pos - Vector2.new(0, 40)
            end
            
            esp.name.Position = headPos
            esp.name.Text = player.Name
            esp.name.Size = self.TextSize
            esp.name.Color = self.NameColor
            esp.name.Visible = true
        else
            esp.name.Visible = false
        end
        
        -- Update Health ESP
        if self.ShowHealth then
            local corners = getPlayerBoundingBox(character)
            if corners and humanoid then
                local health, maxHealth = humanoid.Health, humanoid.MaxHealth
                local healthPercentage = math.clamp(health / maxHealth, 0, 1)
                
                -- Position health bar to the left of the box
                local barPos = corners.topLeft - Vector2.new(8, 0)
                local barHeight = (corners.bottomLeft.Y - corners.topLeft.Y)
                
                -- Background
                esp.healthBg.Size = Vector2.new(4, barHeight)
                esp.healthBg.Position = barPos - Vector2.new(2, 0)
                esp.healthBg.Visible = true
                
                -- Health bar
                esp.healthBar.Size = Vector2.new(4, barHeight * healthPercentage)
                esp.healthBar.Position = Vector2.new(
                    barPos.X - 2,
                    barPos.Y + barHeight * (1 - healthPercentage)
                )
                
                -- Color gradient (green to red)
                esp.healthBar.Color = Color3.fromRGB(
                    255 * (1 - healthPercentage),
                    255 * healthPercentage,
                    0
                )
                
                esp.healthBar.Visible = true
            else
                esp.healthBg.Visible = false
                esp.healthBar.Visible = false
            end
        else
            esp.healthBg.Visible = false
            esp.healthBar.Visible = false
        end
        
        -- Update Distance ESP
        if self.ShowDistance then
            local corners = getPlayerBoundingBox(character)
            if corners then
                local distance = getDistance(character)
                esp.distance.Text = tostring(distance) .. "m"
                esp.distance.Position = Vector2.new(
                    (corners.bottomLeft.X + corners.bottomRight.X) / 2,
                    corners.bottomLeft.Y + 5
                )
                esp.distance.Size = self.TextSize
                esp.distance.Color = self.DistanceColor
                esp.distance.Visible = true
            else
                esp.distance.Visible = false
            end
        else
            esp.distance.Visible = false
        end
        
        -- Update Skeleton ESP
        if self.ShowSkeleton then
            local limbPositions = getLimbPositions(character)
            
            -- Hide all skeleton lines first
            for _, line in ipairs(esp.skeleton) do
                line.Visible = false
            end
            
            -- Update only the lines we need
            for i, limb in ipairs(limbPositions) do
                if i <= #esp.skeleton then
                    local line = esp.skeleton[i]
                    line.From = limb[1]
                    line.To = limb[2]
                    line.Color = self.SkeletonColor
                    line.Thickness = self.SkeletonThickness
                    line.Visible = true
                end
            end
        else
            for _, line in ipairs(esp.skeleton) do
                line.Visible = false
            end
        end
        
        -- Update Tracer ESP
        if self.ShowTracer then
            local tracerOrigin = getTracerOrigin()
            local targetPos
            
            if head then
                targetPos, _ = worldToScreen(head.Position)
            else
                targetPos = pos
            end
            
            esp.tracer.From = tracerOrigin
            esp.tracer.To = targetPos
            esp.tracer.Color = self.TracerColor
            esp.tracer.Thickness = self.TracerThickness
            esp.tracer.Visible = true
        else
            esp.tracer.Visible = false
        end
    end
end

-- Initialize ESP
function ESP:Init()
    -- Add ESP for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createPlayerESP(player)
        end
    end
    
    -- Add ESP for new players
    table.insert(ESP._connections, Players.PlayerAdded:Connect(function(player)
        createPlayerESP(player)
    end))
    
    -- Update ESP
    table.insert(ESP._connections, RunService.RenderStepped:Connect(function()
        ESP:Update()
    end))
    
    -- Clean up on script termination
    table.insert(ESP._connections, game.Close:Connect(function()
        ESP:Cleanup()
    end))
end

function ESP:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(self._connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    -- Remove all drawings
    for _, drawing in pairs(self._drawings) do
        drawing:Remove()
    end
    
    -- Remove all chams
    for _, esp in pairs(self._players) do
        for _, highlight in pairs(esp.chams) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
    end
    
    -- Remove ESP folder
    if espFolder and espFolder.Parent then
        espFolder:Destroy()
    end
    
    -- Clear tables
    self._players = {}
    self._connections = {}
    self._drawings = {}
end

-- API for users to control ESP features
local ESPController = {
    -- Toggle main ESP
    toggle = function(enabled)
        ESP:ToggleESP(enabled)
    end,
    
    -- Toggle individual features
    toggleName = function(enabled)
        ESP:ToggleNameESP(enabled)
    end,
    
    toggleBox = function(enabled)
        ESP:ToggleBoxESP(enabled)
    end,
    
    toggleHealth = function(enabled)
        ESP:ToggleHealthESP(enabled)
    end,
    
    toggleDistance = function(enabled)
        ESP:ToggleDistanceESP(enabled)
    end,
    
    toggleChams = function(enabled)
        ESP:ToggleChamsESP(enabled)
    end,
    
    toggleSkeleton = function(enabled)
        ESP:ToggleSkeletonESP(enabled)
    end,
    
    toggleTracer = function(enabled)
        ESP:ToggleTracerESP(enabled)
    end,
    
    -- Change colors
    setColor = function(feature, r, g, b)
        ESP:SetColor(feature, Color3.fromRGB(r, g, b))
    end,
    
    -- Change tracer origin
    setTracerOrigin = function(origin)
        ESP:SetTracerOrigin(origin)
    end,
    
    -- Access to ESP object for advanced customization
    getESP = function()
        return ESP
    end
}

-- Initialize ESP
ESP:Init()

-- Return the controller
return ESPController

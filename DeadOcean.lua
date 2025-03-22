repeat
    task.wait()
until game:IsLoaded()

_G.Configure = {
    KillAura = false
}

_G.Settings = {
    KillAuraRadius = 50,
    Notify = true
}

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lnwskibidi/Roblox/main/UserInterface.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local IrgonFolder = Workspace:WaitForChild("Irgon")
local EnemyFolder = Workspace:WaitForChild("Enemy")
local GhostPirateFolder = Workspace:WaitForChild("GhostPirate")

local Remote = ReplicatedStorage:WaitForChild("Remote")
local Event = Remote:WaitForChild("Event")
local Drag = Event:WaitForChild("Drag")
local Backpack = Event:WaitForChild("Backpack")
local Weapon = Event:WaitForChild("Weapon")
local SetNetworkOwner = Drag:WaitForChild("SetNetworkOwner")
local SetNetworkOwnerNil = Drag:WaitForChild("SetNetworkOwnerNil")
local StoreRemote = Backpack:WaitForChild("[C-S]TryPutInBackPack")
local DropRemote = Backpack:WaitForChild("[C-S]TryDropOutBackPack")
local WeaponSwingRemote = Weapon:WaitForChild("[S-C]WeaponSwing")

local NotifiedEnemies = {}

local function KillAura()
    local LocalCharacter = LocalPlayer.Character
    local LocalHumanoidRoot = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")

    if not LocalHumanoidRoot then return end

    local Radius = _G.Settings.KillAuraRadius
    local RaycastParams = OverlapParams.new()
    RaycastParams.FilterDescendantsInstances = {LocalCharacter}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local NearbyParts = Workspace:GetPartBoundsInRadius(LocalHumanoidRoot.Position, Radius, RaycastParams)

    for _, Part in ipairs(NearbyParts) do
        local Enemy = Part.Parent
        local EnemyHumanoid = Enemy and Enemy:FindFirstChild("Humanoid")
        local EnemyRoot = Enemy and Enemy:FindFirstChild("HumanoidRootPart")

        if EnemyHumanoid and EnemyHumanoid.Health > 0 and EnemyRoot and not Players:GetPlayerFromCharacter(Enemy) then
            local Arguments = {
                [1] = nil,
                [2] = "Saber",
                [3] = {
                    [1] = {
                        ["enemy"] = Enemy,
                        ["damage"] = math.huge
                    }
                }
            }
            WeaponSwingRemote:FireServer(unpack(Arguments))

            local EnemyID = Enemy:GetDebugId()
            local UniqueID = Enemy.Name .. "_" .. EnemyID

            if _G.Settings.Notify and not table.find(NotifiedEnemies, UniqueID) then
                Library:Notify(Enemy.Name .. " has been taken down!", 3)
                table.insert(NotifiedEnemies, UniqueID)
            end

            task.wait(0.1)
        end
    end
end


task.spawn(function()
    while true do 
        task.wait()
        if _G.Configure.KillAura then
            pcall(KillAura)
        end
    end
end)

-- ==================== USER INTERFACE ====================

local Window = Library:CreateWindow({
    Title = 'Dead Ocean ⁂',
    Center = true,
    AutoShow = true,
    TabPadding = 10,
    MenuFadeTime = 0.25
})

local Tabs = {
    Home = Window:AddTab('Home'),
    Preferences = Window:AddTab('Preferences')
}

-- ==================== HOME TAB - LEFT SIDE ====================
local HomeLeftGroup = Tabs.Home:AddLeftGroupbox('Features')

HomeLeftGroup:AddToggle("Kill Aura", {
    Text = "Kill Aura",
    Default = false,
    Tooltip = false,
    Callback = function(State)
        _G.Configure.KillAura = State
    end
})

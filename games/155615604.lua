local Library = loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/libraries/scoot/Library.lua"))()

local Window = Library:Window({
    Logo = getcustomasset("moonshine/images/moon.png"),
    FadeTime = 0.3,
})

Library.MenuKeybind = tostring(Enum.KeyCode.Delete)

local Watermark = Library:Watermark("moonshine | 155615604.lua")
local KeybindList = Library:KeybindList()

do
    local CombatPage = Window:Page({Name = "Combat", SubPages = true})
    local MovementPage = Window:Page({Name = "Movement", Columns = 2})
    local VisualsPage = Window:Page({Name = "Visuals", SubPages = true})
    local WorldPage = Window:Page({Name = "World", Columns = 2})
    local MiscPage = Window:Page({Name = "Misc", Columns = 2})
    local SettingsPage = Library:CreateSettingsPage(Window, Watermark, KeybindList)

    local FriendsCache = {}
    do
        local LP = game:GetService("Players").LocalPlayer
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= LP then
                task.spawn(function()
                    local ok, result = pcall(LP.IsFriendsWith, LP, p.UserId)
                    if ok then FriendsCache[p.Name] = result end
                end)
            end
        end
        game:GetService("Players").PlayerAdded:Connect(function(p)
            task.spawn(function()
                local ok, result = pcall(LP.IsFriendsWith, LP, p.UserId)
                if ok then FriendsCache[p.Name] = result end
            end)
        end)
        game:GetService("Players").PlayerRemoving:Connect(function(p)
            FriendsCache[p.Name] = nil
        end)
    end

    local RunService = game:GetService("RunService")
    local RenderCache = {}
    local NotificationShown = {}

    local function NewRender(Callback)
        local Connection = {
            Function = Callback,
        }
        local Index = #RenderCache + 1
        RenderCache[Index] = Connection
        Connection.Disconnect = function(self)
            if RenderCache[Index] then RenderCache[Index] = nil end
        end
        return Connection
    end

    RunService.RenderStepped:Connect(function(Delta)
        for _, Connection in RenderCache do
            Connection.Function(Delta)
        end
    end)

    do
        local GunModsSubPage = CombatPage:SubPage({Name = "Gun Mods", Columns = 2})

        do
            local LP = game:GetService("Players").LocalPlayer
            local OriginalValues = {}
            local GunModConnections = {}

            local function GetToolKey(tool)
                return tostring(tool) .. "_" .. tool:GetDebugId()
            end

            local function GetAllTools()
                local tools = {}
                for _, tool in pairs(LP.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then table.insert(tools, tool) end
                end
                local char = LP.Character
                if char then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") then table.insert(tools, tool) end
                    end
                end
                return tools
            end

            local function SaveOriginal(tool, attr)
                local key = GetToolKey(tool)
                if not OriginalValues[key] then OriginalValues[key] = {} end
                if OriginalValues[key][attr] == nil then
                    OriginalValues[key][attr] = tool:GetAttribute(attr)
                end
            end

            local function RestoreOriginal(tool, attr)
                local key = GetToolKey(tool)
                if OriginalValues[key] and OriginalValues[key][attr] ~= nil then
                    tool:SetAttribute(attr, OriginalValues[key][attr])
                    OriginalValues[key][attr] = nil
                    if not next(OriginalValues[key]) then OriginalValues[key] = nil end
                end
            end

            local function ApplyMod(tool, attr, value, flagGet)
                if not tool:IsA("Tool") then return end
                if tool:GetAttribute(attr) == nil then return end
                if flagGet() ~= true then return end
                SaveOriginal(tool, attr)
                tool:SetAttribute(attr, value)
            end

            local function RevertMod(attr)
                for _, tool in pairs(GetAllTools()) do
                    RestoreOriginal(tool, attr)
                end
            end

            local GunModFlags = {
                NoFireRate = false,
                NoSpread = false,
                ForceAutoFire = false,
            }

            local function ApplyAllMods(tool)
                ApplyMod(tool, "FireRate", 0, function() return GunModFlags.NoFireRate end)
                ApplyMod(tool, "SpreadRadius", 0, function() return GunModFlags.NoSpread end)
                ApplyMod(tool, "AutoFire", true, function() return GunModFlags.ForceAutoFire end)
            end

            local function ConnectContainer(container)
                local conn = container.ChildAdded:Connect(function(tool)
                    if tool:IsA("Tool") then
                        task.defer(ApplyAllMods, tool)
                    end
                end)
                table.insert(GunModConnections, conn)
            end

            ConnectContainer(LP.Backpack)
            if LP.Character then ConnectContainer(LP.Character) end
            local charConn = LP.CharacterAdded:Connect(function(char)
                ConnectContainer(char)
                task.defer(function()
                    for _, tool in pairs(GetAllTools()) do
                        ApplyAllMods(tool)
                    end
                end)
            end)
            table.insert(GunModConnections, charConn)

            local NoFireRate = GunModsSubPage:Section({Name = "No Fire Rate", Side = 1}) do
                NoFireRate:Toggle({
                    Name = "Enabled",
                    Flag = "NoFireRateEnabled",
                    Default = false,
                    Callback = function(state)
                        GunModFlags.NoFireRate = state
                        if state then
                            if not NotificationShown["NoFireRate"] then
                                NotificationShown["NoFireRate"] = true
                                Library:Notification("Warning.", "It is recommended to use 60 FPS or below unless you want your bullets to come instantly.", 5)
                            end
                            for _, tool in pairs(GetAllTools()) do
                                ApplyMod(tool, "FireRate", 0, function() return true end)
                            end
                        else
                            RevertMod("FireRate")
                        end
                    end
                })
            end

            local NoSpread = GunModsSubPage:Section({Name = "No Spread", Side = 2}) do
                NoSpread:Toggle({
                    Name = "Enabled",
                    Flag = "NoSpreadEnabled",
                    Default = false,
                    Callback = function(state)
                        GunModFlags.NoSpread = state
                        if state then
                            for _, tool in pairs(GetAllTools()) do
                                ApplyMod(tool, "SpreadRadius", 0, function() return true end)
                            end
                        else
                            RevertMod("SpreadRadius")
                        end
                    end
                })
            end

            local ForceAutoFire = GunModsSubPage:Section({Name = "Force Auto Fire", Side = 1}) do
                ForceAutoFire:Toggle({
                    Name = "Enabled",
                    Flag = "ForceAutoFireEnabled",
                    Default = false,
                    Callback = function(state)
                        GunModFlags.ForceAutoFire = state
                        if state then
                            for _, tool in pairs(GetAllTools()) do
                                ApplyMod(tool, "AutoFire", true, function() return true end)
                            end
                        else
                            RevertMod("AutoFire")
                        end
                    end
                })
            end
        end
    end

    do
        local AimbotSubPage = CombatPage:SubPage({Name = "Aimbot", Columns = 2})

        do
            local SilentAimSection = AimbotSubPage:Section({Name = "Silent Aim", Side = 1}) do
                local SilentAimState = {
                    Enabled = false,
                    FoVCircle = false,
                    Tracer = false,
                    Radius = 130,
                    Bone = "Head",
                    WallCheck = false,
                    Teams = {},
                    InmateTypes = {},
                    DeathCheck = true,
                    FriendCheck = false,
                    Whitelist = {}
                }

                local Camera = workspace.CurrentCamera
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local UserInputService = game:GetService("UserInputService")

                local GetPlayers = Players.GetPlayers
                local WorldToViewportPoint = Camera.WorldToViewportPoint
                local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
                local FindFirstChild = game.FindFirstChild
                local GetMouseLocation = UserInputService.GetMouseLocation

                SilentAimSection:Toggle({
                    Name = "Enabled",
                    Flag = "SilentAimEnabled",
                    Default = false,
                    Callback = function(v) SilentAimState.Enabled = v end
                })

                SilentAimSection:Toggle({
                    Name = "FoV Circle",
                    Flag = "SilentAimFoVEnabled",
                    Default = false,
                    Callback = function(v) SilentAimState.FoVCircle = v end
                })

                SilentAimSection:Toggle({
                    Name = "Tracer",
                    Flag = "SilentAimTracerEnabled",
                    Default = false,
                    Callback = function(v) SilentAimState.Tracer = v end
                })

                SilentAimSection:Slider({
                    Name = "Radius",
                    Flag = "SilentAimRadius",
                    Min = 1,
                    Suffix = "px",
                    Max = 500,
                    Default = 130,
                    Decimals = 1,
                    Callback = function(v) SilentAimState.Radius = v end
                })

                SilentAimSection:Dropdown({
                    Name = "Bone",
                    Flag = "SilentAimBone",
                    Default = "Head",
                    Multi = false,
                    Items = {"Head", "HumanoidRootPart"},
                    Callback = function(v) SilentAimState.Bone = v end
                })

                SilentAimSection:Toggle({
                    Name = "Wall Check",
                    Flag = "SilentAimWallCheck",
                    Default = false,
                    Callback = function(v) SilentAimState.WallCheck = v end
                })

                SilentAimSection:Dropdown({
                    Name = "Teams",
                    Flag = "SilentAimTeams",
                    Multi = true,
                    Items = {"Guards", "Inmates", "Criminals"},
                    Callback = function(v)
                        local set = {}
                        for _, name in pairs(v) do set[name] = true end
                        SilentAimState.Teams = set
                    end
                })

                SilentAimSection:Dropdown({
                    Name = "Inmate Types",
                    Flag = "SilentAimInmateTypes",
                    Multi = true,
                    Items = {"Regular", "Aggressive", "Arrestable"},
                    Callback = function(v)
                        local set = {}
                        for _, name in pairs(v) do set[name] = true end
                        SilentAimState.InmateTypes = set
                    end
                })

                SilentAimSection:Toggle({
                    Name = "Death Check",
                    Flag = "SilentAimDeathCheck",
                    Default = true,
                    Callback = function(v) SilentAimState.DeathCheck = v end
                })

                SilentAimSection:Toggle({
                    Name = "Friend Check",
                    Flag = "SilentAimFriendCheck",
                    Default = false,
                    Callback = function(v) SilentAimState.FriendCheck = v end
                }) do
                    local saPlayerNames = {}
                    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                        if p ~= game.Players.LocalPlayer then
                            table.insert(saPlayerNames, p.Name)
                        end
                    end

                    local SAWhitelistDropdown = SilentAimSection:Dropdown({
                        Name = "Whitelist",
                        Flag = "SilentAimWhitelist",
                        Multi = true,
                        Items = saPlayerNames,
                        Callback = function(v)
                            local set = {}
                            for _, name in pairs(v) do set[name] = true end
                            SilentAimState.Whitelist = set
                        end
                    })

                    game:GetService("Players").PlayerAdded:Connect(function(p)
                        SAWhitelistDropdown:Add(p.Name)
                    end)
                    game:GetService("Players").PlayerRemoving:Connect(function(p)
                        SAWhitelistDropdown:Remove(p.Name)
                    end)
                end do
                    local FoVCircle = Drawing.new("Circle")
                    FoVCircle.Thickness = 1
                    FoVCircle.NumSides = 100
                    FoVCircle.Filled = false
                    FoVCircle.Visible = false
                    FoVCircle.ZIndex = 999
                    FoVCircle.Transparency = 1

                    local Tracer = Drawing.new("Line")
                    Tracer.Thickness = 1
                    Tracer.Visible = false
                    Tracer.ZIndex = 999
                    Tracer.Transparency = 1

                    local ExpectedArguments = {
                        FindPartOnRayWithIgnoreList = {
                            ArgCountRequired = 3,
                            Args = {"Instance", "Ray", "table", "boolean", "boolean"}
                        },
                        FindPartOnRayWithWhitelist = {
                            ArgCountRequired = 3,
                            Args = {"Instance", "Ray", "table", "boolean"}
                        },
                        FindPartOnRay = {
                            ArgCountRequired = 2,
                            Args = {"Instance", "Ray", "Instance", "boolean", "boolean"}
                        },
                        Raycast = {
                            ArgCountRequired = 3,
                            Args = {"Instance", "Vector3", "Vector3", "RaycastParams"}
                        }
                    }

                    local function ValidateArguments(Args, RayMethod)
                        local Matches = 0
                        if #Args < RayMethod.ArgCountRequired then
                            return false
                        end
                        for Pos, Argument in next, Args do
                            if typeof(Argument) == RayMethod.Args[Pos] then
                                Matches = Matches + 1
                            end
                        end
                        return Matches >= RayMethod.ArgCountRequired
                    end

                    local function getDirection(Origin, Position)
                        return (Position - Origin).Unit * 1000
                    end

                    local function getMousePosition()
                        return GetMouseLocation(UserInputService)
                    end

                    local function GetInmateStatus(Character)
                        local humanoid = FindFirstChild(Character, "Humanoid")
                        if not humanoid then return "Regular" end
                        local displayName = humanoid.DisplayName
                        if string.sub(displayName, 1, 4) == "\xF0\x9F\x94\x97" then
                            return "Arrestable"
                        elseif string.sub(displayName, 1, 4) == "\xF0\x9F\x92\xA2" then
                            return "Aggressive"
                        end
                        return "Regular"
                    end

                    local function IsPlayerVisible(Player)
                        local PlayerCharacter = Player.Character
                        local LocalPlayerCharacter = LocalPlayer.Character
                        if not (PlayerCharacter and LocalPlayerCharacter) then return false end

                        local TargetPart = FindFirstChild(PlayerCharacter, SilentAimState.Bone) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
                        if not TargetPart then return false end

                        local ObscuringObjects = #GetPartsObscuringTarget(Camera, {TargetPart.Position}, {LocalPlayerCharacter, PlayerCharacter})
                        return ObscuringObjects == 0
                    end

                    local function getClosestPlayer()
                        local Closest = nil
                        local ClosestDist = nil
                        local MousePos = getMousePosition()
                        local BoneName = SilentAimState.Bone

                        for _, Player in next, GetPlayers(Players) do
                            if Player == LocalPlayer then continue end
                            if SilentAimState.Whitelist[Player.Name] then continue end
                            if SilentAimState.FriendCheck and FriendsCache[Player.Name] then continue end

                            local TeamName = Player.Team and Player.Team.Name or ""
                            if next(SilentAimState.Teams) and not SilentAimState.Teams[TeamName] then continue end

                            local Character = Player.Character
                            if not Character then continue end

                            if TeamName == "Inmates" and next(SilentAimState.InmateTypes) then
                                local Status = GetInmateStatus(Character)
                                if not SilentAimState.InmateTypes[Status] then continue end
                            end

                            local Humanoid = FindFirstChild(Character, "Humanoid")
                            if SilentAimState.DeathCheck and (not Humanoid or Humanoid.Health <= 0) then continue end

                            local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
                            if not HumanoidRootPart then continue end

                            if SilentAimState.WallCheck and not IsPlayerVisible(Player) then continue end

                            local ScreenPos, OnScreen = WorldToViewportPoint(Camera, HumanoidRootPart.Position)
                            if not OnScreen then continue end

                            local Distance = (MousePos - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                            if Distance <= (ClosestDist or SilentAimState.Radius) then
                                Closest = FindFirstChild(Character, BoneName) or HumanoidRootPart
                                ClosestDist = Distance
                            end
                        end

                        return Closest
                    end

                    NewRender(function()
                        Camera = workspace.CurrentCamera

                        if SilentAimState.Enabled and SilentAimState.FoVCircle then
                            FoVCircle.Position = getMousePosition()
                            FoVCircle.Radius = SilentAimState.Radius
                            FoVCircle.Color = Library.Theme.Accent
                            FoVCircle.Visible = true
                        else
                            FoVCircle.Visible = false
                        end

                        if SilentAimState.Enabled and SilentAimState.Tracer then
                            local Target = getClosestPlayer()
                            if Target then
                                local ScreenPos, OnScreen = WorldToViewportPoint(Camera, Target.Position)
                                if OnScreen then
                                    Tracer.From = getMousePosition()
                                    Tracer.To = Vector2.new(ScreenPos.X, ScreenPos.Y)
                                    Tracer.Color = Library.Theme.Accent
                                    Tracer.Visible = true
                                else
                                    Tracer.Visible = false
                                end
                            else
                                Tracer.Visible = false
                            end
                        else
                            Tracer.Visible = false
                        end
                    end)


                    local oldNamecall
                    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
                        local Method = getnamecallmethod()
                        local Arguments = {...}
                        local self = Arguments[1]

                        if SilentAimState.Enabled and self == workspace and not checkcaller() then
                            if Method == "FindPartOnRayWithIgnoreList" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                                    local HitPart = getClosestPlayer()
                                    if HitPart then
                                        local Origin = Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "FindPartOnRayWithWhitelist" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                                    local HitPart = getClosestPlayer()
                                    if HitPart then
                                        local Origin = Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "FindPartOnRay" or Method == "findPartOnRay" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                                    local HitPart = getClosestPlayer()
                                    if HitPart then
                                        local Origin = Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "Raycast" then
                                if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                                    local HitPart = getClosestPlayer()
                                    if HitPart then
                                        Arguments[3] = getDirection(Arguments[2], HitPart.Position)
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            end
                        end

                        return oldNamecall(...)
                    end))
                end
            end
        end
    end

    do
        do
            local NoclipSection = MovementPage:Section({Name = "Noclip", Side = 1}) do
                local NoclipEnabled = NoclipSection:Toggle({
                    Name = "Enabled",
                    Flag = "NoclipEnabled",
                    Default = false
                }) do
                    local Players = game:GetService("Players")
                    local LocalPlayer = Players.LocalPlayer
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")

                    local scriptsFolder = ReplicatedStorage:FindFirstChild("Scripts")
                    if scriptsFolder then
                        local CharacterCollision = scriptsFolder:FindFirstChild("CharacterCollision")
                        if CharacterCollision then
                            CharacterCollision:Destroy()
                        end
                    end

                    local function SetupNoclip(Character)
                        local Head = Character:WaitForChild("Head")
                        task.spawn(function()
                            for _, Connection in getconnections(Head:GetPropertyChangedSignal("CanCollide")) do
                                Connection:Disable()
                            end
                        end)
                    end

                    LocalPlayer.CharacterAdded:Connect(SetupNoclip)
                    if LocalPlayer.Character then
                        SetupNoclip(LocalPlayer.Character)
                    end

                    game.RunService.Stepped:Connect(function()
                        if NoclipEnabled:Get() == true then
                            local character = LocalPlayer.Character
                            if not character then return end
                            for _, part in pairs(character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                end
            end

            local InfJumpSection = MovementPage:Section({Name = "Infinite Jump", Side = 2}) do
                local InfJumpEnabled = InfJumpSection:Toggle({
                    Name = "Enabled",
                    Flag = "InfJumpEnabled",
                    Default = false
                }) do
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local UserInputService = game:GetService("UserInputService")
                    local infJumpConn = nil
                    local debounce = false

                    local function EnableInfJump()
                        if infJumpConn then return end
                        infJumpConn = UserInputService.JumpRequest:Connect(function()
                            if not debounce then
                                debounce = true
                                local character = LocalPlayer.Character
                                if character then
                                    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                                    if humanoid then
                                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                end
                                task.wait()
                                debounce = false
                            end
                        end)
                    end

                    local function DisableInfJump()
                        if infJumpConn then
                            infJumpConn:Disconnect()
                            infJumpConn = nil
                        end
                        debounce = false
                    end

                    NewRender(function()
                        if InfJumpEnabled:Get() == true then
                            EnableInfJump()
                        else
                            DisableInfJump()
                        end
                    end)
                end
            end
        end
    end
    
    do
        local ESPSubPage = VisualsPage:SubPage({Name = "ESP", Columns = 2})

        do
            local ESPFilterState = {
                Teams = {},
                InmateTypes = {},
                Whitelist = {},
                FriendCheck = false,
                WhitelistMode = "Hide ESP"
            }

            local function GetInmateStatusESP(Character)
                local humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return "Regular" end
                local displayName = humanoid.DisplayName
                if string.sub(displayName, 1, 4) == "\xF0\x9F\x94\x97" then
                    return "Arrestable"
                elseif string.sub(displayName, 1, 4) == "\xF0\x9F\x92\xA2" then
                    return "Aggressive"
                end
                return "Regular"
            end

            local function IsWhitelisted(Player)
                if ESPFilterState.Whitelist[Player.Name] then return true end
                if ESPFilterState.FriendCheck and FriendsCache[Player.Name] then return true end
                return false
            end

            local function ShouldShowPlayer(Player)
                if IsWhitelisted(Player) then
                    if ESPFilterState.WhitelistMode == "Hide ESP" then
                        return false
                    end
                end
                local TeamName = Player.Team and Player.Team.Name or ""
                if next(ESPFilterState.Teams) and not ESPFilterState.Teams[TeamName] then
                    return false
                end
                if TeamName == "Inmates" and next(ESPFilterState.InmateTypes) then
                    local Character = Player.Character
                    if Character then
                        local Status = GetInmateStatusESP(Character)
                        if not ESPFilterState.InmateTypes[Status] then
                            return false
                        end
                    end
                end
                return true
            end

            local function GetDisplayName(Character)
                local humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return Character.Name end
                local displayName = humanoid.DisplayName
                if string.sub(displayName, 1, 4) == "\xF0\x9F\x94\x97" then
                    return "[W] " .. Character.Name
                elseif string.sub(displayName, 1, 4) == "\xF0\x9F\x92\xA2" then
                    return "[A] " .. Character.Name
                end
                return Character.Name
            end

            local ESPFilters = ESPSubPage:Section({Name = "Filters", Side = 1}) do
                ESPFilters:Dropdown({
                    Name = "Teams",
                    Flag = "ESPFilterTeams",
                    Multi = true,
                    Items = {"Guards", "Inmates", "Criminals"},
                    Callback = function(v)
                        local set = {}
                        for _, name in pairs(v) do set[name] = true end
                        ESPFilterState.Teams = set
                    end
                })

                ESPFilters:Dropdown({
                    Name = "Inmate Types",
                    Flag = "ESPFilterInmateTypes",
                    Multi = true,
                    Items = {"Regular", "Aggressive", "Arrestable"},
                    Callback = function(v)
                        local set = {}
                        for _, name in pairs(v) do set[name] = true end
                        ESPFilterState.InmateTypes = set
                    end
                })

                ESPFilters:Toggle({
                    Name = "Friend Check",
                    Flag = "ESPFriendCheck",
                    Default = false,
                    Callback = function(v) ESPFilterState.FriendCheck = v end
                })

                local playerNames = {}
                for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= game.Players.LocalPlayer then
                        table.insert(playerNames, p.Name)
                    end
                end

                local WhitelistDropdown = ESPFilters:Dropdown({
                    Name = "Whitelist",
                    Flag = "ESPWhitelist",
                    Multi = true,
                    Items = playerNames,
                    Callback = function(v)
                        local set = {}
                        for _, name in pairs(v) do set[name] = true end
                        ESPFilterState.Whitelist = set
                    end
                })

                game:GetService("Players").PlayerAdded:Connect(function(p)
                    WhitelistDropdown:Add(p.Name)
                end)
                game:GetService("Players").PlayerRemoving:Connect(function(p)
                    WhitelistDropdown:Remove(p.Name)
                end)

                ESPFilters:Dropdown({
                    Name = "Whitelist Mode",
                    Flag = "ESPWhitelistMode",
                    Multi = false,
                    Default = "Hide ESP",
                    Items = {"Hide ESP", "Show Green"},
                    Callback = function(v) ESPFilterState.WhitelistMode = v end
                })
            end

            local NameESP = ESPSubPage:Section({Name = "Name ESP", Side = 1}) do
                local Enabled = NameESP:Toggle({
                    Name = "Enabled",
                    Flag = "NameESPEnabled",
                    Default = false
                })

                local TeamColor = NameESP:Toggle({
                    Name = "Team Color",
                    Flag = "NameESPTeamColor",
                    Default = true
                })

                local ShowSelf = NameESP:Toggle({
                    Name = "Show Self",
                    Flag = "NameESPShowSelf",
                    Default = false
                })
                
                local InmateStatus = NameESP:Toggle({
                    Name = "Inmate Status",
                    Flag = "NameESPInmateStatus",
                    Default = true
                })

                local Outline = NameESP:Toggle({
                    Name = "Outline",
                    Flag = "NameESPOutline",
                    Default = true
                }) do
                    local function Apply(Character)
                        if game.Players:GetPlayerFromCharacter(Character) then
                            local Player = game.Players:GetPlayerFromCharacter(Character)
                            local Text = Drawing.new("Text")
                            Text.Visible = false
                            Text.ZIndex = 3
                            Text.Size = 12
                            Text.Center = true
                            Text.OutlineColor = Color3.fromRGB(0, 0, 0)

                            local Render = NewRender(function()
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                                if onscreen then
                                    if not ShouldShowPlayer(Player) then
                                        Text.Visible = false
                                        return
                                    end
                                    Text.Position = Vector2.new(pos.X, pos.Y)
                                    if InmateStatus:Get() == true then
                                        Text.Text = GetDisplayName(Character)
                                    else
                                        Text.Text = Character.Name
                                    end
                                    if ShowSelf:Get() == true then
                                        Text.Visible = Enabled:Get()
                                    else
                                        if Character ~= game.Players.LocalPlayer.Character then
                                            Text.Visible = Enabled:Get()
                                        else
                                            Text.Visible = false
                                        end
                                    end
                                    if IsWhitelisted(Player) then
                                        Text.Color = Color3.fromRGB(0, 255, 0)
                                    elseif TeamColor:Get() == true then
                                        Text.Color = Player.TeamColor.Color
                                    else
                                        Text.Color = Library.Theme.Accent
                                    end
                                    Text.Outline = Outline:Get()
                                else
                                    Text.Visible = false
                                end
                            end)

                            Character.AncestryChanged:Connect(function(_, parent)
                                if parent then else
                                    Render:Disconnect()
                                    Text:Destroy()
                                    Text = nil
                                end
                            end)
                        end
                    end

                    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                        Apply(v.Character)

                        v.CharacterAdded:Connect(function()
                            Apply(v.Character)
                        end)
                    end

                    game:GetService("Players").PlayerAdded:Connect(function(v)
                        v.CharacterAdded:Connect(function()
                            Apply(v.Character)
                        end)
                    end)
                end
            end

            local BoxESP = ESPSubPage:Section({Name = "Box ESP", Side = 2}) do
                local Enabled = BoxESP:Toggle({
                    Name = "Enabled",
                    Flag = "BoxESPEnabled",
                    Default = false
                })

                local TeamColor = BoxESP:Toggle({
                    Name = "Team Color",
                    Flag = "BoxESPTeamColor",
                    Default = true
                })

                local ShowSelf = BoxESP:Toggle({
                    Name = "Show Self",
                    Flag = "BoxESPShowSelf",
                    Default = false
                })

                local Outline = BoxESP:Toggle({
                    Name = "Outline",
                    Flag = "BoxESPOutline",
                    Default = true
                }) do
                    local function Apply(Character)
                        if game.Players:GetPlayerFromCharacter(Character) then
                            local Player = game.Players:GetPlayerFromCharacter(Character)
                            local Box = Drawing.new("Square")
                            Box.Visible = false
                            Box.ZIndex = 2
                            local BoxOutline = Drawing.new("Square")
                            BoxOutline.Visible = false
                            BoxOutline.Thickness = 2
                            BoxOutline.ZIndex = 1
                            BoxOutline.Color = Color3.fromRGB(0, 0, 0)

                            local Render = NewRender(function()
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                                if onscreen then
                                    if not ShouldShowPlayer(Player) then
                                        Box.Visible = false
                                        BoxOutline.Visible = false
                                        return
                                    end
                                    local scale = 1 / (pos.Z * math.tan(math.rad(workspace.CurrentCamera.FieldOfView * 0.5)) * 2) * 1000
                                    local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
                                    local x, y = math.floor(pos.X), math.floor(pos.Y)
                                    local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))
                                    
                                    Box.Size = Vector2.new(width, height)
                                    Box.Position = Vector2.new(xPosition, yPosition)
                                    BoxOutline.Size = Vector2.new(width, height)
                                    BoxOutline.Position = Vector2.new(xPosition, yPosition)
                                    if ShowSelf:Get() == true then
                                        Box.Visible = Enabled:Get()
                                        if Box.Visible == true then BoxOutline.Visible = Outline:Get() else BoxOutline.Visible = false end
                                    else
                                        if Character ~= game.Players.LocalPlayer.Character then
                                            Box.Visible = Enabled:Get()
                                            if Box.Visible == true then BoxOutline.Visible = Outline:Get() else BoxOutline.Visible = false end
                                        else
                                            Box.Visible = false
                                            BoxOutline.Visible = false
                                        end
                                    end
                                    if IsWhitelisted(Player) then
                                        Box.Color = Color3.fromRGB(0, 255, 0)
                                    elseif TeamColor:Get() == true then
                                        Box.Color = Player.TeamColor.Color
                                    else
                                        Box.Color = Library.Theme.Accent
                                    end
                                else
                                    Box.Visible = false
                                    BoxOutline.Visible = false
                                end
                            end)

                            Character.AncestryChanged:Connect(function(_, parent)
                                if parent then else
                                    Render:Disconnect()
                                    Box:Destroy()
                                    BoxOutline:Destroy()
                                    Box = nil
                                    BoxOutline = nil
                                end
                            end)
                        end
                    end

                    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                        Apply(v.Character)

                        v.CharacterAdded:Connect(function()
                            Apply(v.Character)
                        end)
                    end

                    game:GetService("Players").PlayerAdded:Connect(function(v)
                        v.CharacterAdded:Connect(function()
                            Apply(v.Character)
                        end)
                    end)
                end
            end
        end
    end

    do
        local RemoveDoors = WorldPage:Section({Name = "Remove Doors", Side = 1}) do
            local Enabled = RemoveDoors:Toggle({
                Name = "Enabled",
                Flag = "RemoveDoorsEnabled",
                Default = false,
                Callback = function(callback)
                    if callback == true then
                        local TemporaryDoorFolder = Instance.new("Folder", game.Lighting)
                        TemporaryDoorFolder.Name = "TemporaryDoorFolder"
                        workspace.Doors.Parent = TemporaryDoorFolder
                    else
                        local TemporaryDoorFolder = game.Lighting.TemporaryDoorFolder
                        TemporaryDoorFolder.Doors.Parent = workspace
                        TemporaryDoorFolder:Destroy()
                    end
                end
            })
        end
    end

    do
        local RemoveJumpCooldown = MiscPage:Section({Name = "Remove Jump Cooldown", Side = 1}) do
            local Enabled = RemoveJumpCooldown:Toggle({
                Name = "Enabled",
                Flag = "RemoveJumpCooldownEnabled",
                Default = false
            }) do
                NewRender(function()
                    game.Players.LocalPlayer.Character.AntiJump.Disabled = Enabled:Get()
                end)
            end
        end
    end

    do
        local AntiInvisible = MiscPage:Section({Name = "Anti Invisible", Side = 2}) do
            local Enabled = AntiInvisible:Toggle({
                Name = "Enabled",
                Flag = "AntiInvisibleEnabled",
                Default = false
            }) do
                local FlaggedPlayers = {}

                local function ApplyHighlight(character)
                    if character:FindFirstChild("AntiInvisHighlight") then return end
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "AntiInvisHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineTransparency = 0
                    highlight.Parent = character
                end

                local function RemoveHighlight(character)
                    local highlight = character:FindFirstChild("AntiInvisHighlight")
                    if highlight then highlight:Destroy() end
                end

                local function CleanupPlayer(player)
                    FlaggedPlayers[player] = nil
                    if player.Character then
                        RemoveHighlight(player.Character)
                    end
                end

                NewRender(function()
                    if Enabled:Get() == true then
                        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                            if player == game.Players.LocalPlayer then continue end
                            local character = player.Character
                            if not character then continue end
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            if not humanoid then continue end

                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                    if track.Animation and track.Animation.AnimationId == "rbxassetid://215384594" then
                                        track:Stop(0)
                                        FlaggedPlayers[player] = true
                                    end
                                end
                            end

                            if FlaggedPlayers[player] then
                                ApplyHighlight(character)
                            end
                        end
                    else
                        for player, _ in pairs(FlaggedPlayers) do
                            CleanupPlayer(player)
                        end
                    end
                end)
            end
        end
    end

    do
        local AlwaysBackpack = MiscPage:Section({Name = "Always Backpack", Side = 1}) do
            local Enabled = AlwaysBackpack:Toggle({
                Name = "Enabled",
                Flag = "AlwaysBackpackEnabled",
                Default = false
            }) do
                local LP = game:GetService("Players").LocalPlayer
                LP:GetAttributeChangedSignal("BackpackEnabled"):Connect(function()
                    if Enabled:Get() == true and LP:GetAttribute("BackpackEnabled") == false then
                        LP:SetAttribute("BackpackEnabled", true)
                    end
                end)
            end
        end
    end

    do
        local AntiTase = MiscPage:Section({Name = "Anti Tase", Side = 2}) do
            local Enabled = AntiTase:Toggle({
                Name = "Enabled",
                Flag = "AntiTaseEnabled",
                Default = false
            }) do

                NewRender(function()
                    if Enabled:Get() ~= true then return end
                    local character = game.Players.LocalPlayer.Character
                    if not character then return end
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if not humanoid then return end
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if not animator then return end

                    local tazed = false
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        local animId = track.Animation and track.Animation.AnimationId or ""
                        if animId == "rbxassetid://279227693" or animId == "rbxassetid://279229192" then
                            track:Stop(0)
                            tazed = true
                        end
                    end

                    if tazed then
                        humanoid.WalkSpeed = 16
                        humanoid.JumpHeight = 5.5
                    end
                end)
            end
        end
    end

    do
        local ArrestAura = MiscPage:Section({Name = "Arrest Aura", Side = 1}) do
            local ArrestAuraWhitelist = {}
            local ArrestAuraFriendCheck = false

            local Enabled = ArrestAura:Toggle({
                Name = "Enabled",
                Flag = "ArrestAuraEnabled",
                Default = false
            })

            ArrestAura:Toggle({
                Name = "Friend Check",
                Flag = "ArrestAuraFriendCheck",
                Default = false,
                Callback = function(v) ArrestAuraFriendCheck = v end
            })

            local aaPlayerNames = {}
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game.Players.LocalPlayer then
                    table.insert(aaPlayerNames, p.Name)
                end
            end

            local AAWhitelistDropdown = ArrestAura:Dropdown({
                Name = "Whitelist",
                Flag = "ArrestAuraWhitelist",
                Multi = true,
                Items = aaPlayerNames,
                Callback = function(v)
                    local set = {}
                    for _, name in pairs(v) do set[name] = true end
                    ArrestAuraWhitelist = set
                end
            })

            game:GetService("Players").PlayerAdded:Connect(function(p)
                AAWhitelistDropdown:Add(p.Name)
            end)
            game:GetService("Players").PlayerRemoving:Connect(function(p)
                AAWhitelistDropdown:Remove(p.Name)
            end) do
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local ArrestRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ArrestPlayer")

                NewRender(function()
                    if Enabled:Get() ~= true then return end
                    local character = LocalPlayer.Character
                    if not character then return end
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end

                    for _, player in pairs(Players:GetPlayers()) do
                        if player == LocalPlayer then continue end
                        if ArrestAuraWhitelist[player.Name] then continue end
                        if ArrestAuraFriendCheck and FriendsCache[player.Name] then continue end
                        local targetChar = player.Character
                        if not targetChar then continue end
                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        if not targetRoot then continue end
                        if (rootPart.Position - targetRoot.Position).Magnitude <= 10 then
                            pcall(function()
                                ArrestRemote:InvokeServer(player, 1)
                            end)
                        end
                    end
                end)
            end
        end
    end

    do
        local FistAura = MiscPage:Section({Name = "Fist Aura", Side = 2}) do
            local FistAuraWhitelist = {}
            local FistAuraFriendCheck = false

            local Enabled = FistAura:Toggle({
                Name = "Enabled",
                Flag = "FistAuraEnabled",
                Default = false
            })

            FistAura:Toggle({
                Name = "Friend Check",
                Flag = "FistAuraFriendCheck",
                Default = false,
                Callback = function(v) FistAuraFriendCheck = v end
            })

            local faPlayerNames = {}
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game.Players.LocalPlayer then
                    table.insert(faPlayerNames, p.Name)
                end
            end

            local FAWhitelistDropdown = FistAura:Dropdown({
                Name = "Whitelist",
                Flag = "FistAuraWhitelist",
                Multi = true,
                Items = faPlayerNames,
                Callback = function(v)
                    local set = {}
                    for _, name in pairs(v) do set[name] = true end
                    FistAuraWhitelist = set
                end
            })

            game:GetService("Players").PlayerAdded:Connect(function(p)
                FAWhitelistDropdown:Add(p.Name)
            end)
            game:GetService("Players").PlayerRemoving:Connect(function(p)
                FAWhitelistDropdown:Remove(p.Name)
            end) do
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local MeleeRemote = game:GetService("ReplicatedStorage"):WaitForChild("meleeEvent")

                NewRender(function()
                    if Enabled:Get() ~= true then return end
                    local character = LocalPlayer.Character
                    if not character then return end
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end

                    for _, player in pairs(Players:GetPlayers()) do
                        if player == LocalPlayer then continue end
                        if FistAuraWhitelist[player.Name] then continue end
                        if FistAuraFriendCheck and FriendsCache[player.Name] then continue end
                        local targetChar = player.Character
                        if not targetChar then continue end
                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        if not targetRoot then continue end
                        if (rootPart.Position - targetRoot.Position).Magnitude <= 10 then
                            pcall(function()
                                MeleeRemote:FireServer(player, 1, 1)
                            end)
                        end
                    end
                end)
            end
        end
    end
end
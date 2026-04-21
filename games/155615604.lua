local Library = loadstring(game:HttpGet("https://github.com/catthatdrinkssprite/moonshine/raw/main/libraries/scoot/Library.lua"))()

local Window = Library:Window({
    Logo = getcustomasset("moonshine/images/moon.png"),
    FadeTime = 0.3,
})

Library.MenuKeybind = tostring(Enum.KeyCode.Delete)

local Watermark = Library:Watermark("moonshine | Prison Life")
local KeybindList = Library:KeybindList()

do
    local CombatPage = Window:Page({Name = "Combat", SubPages = true})
    local MovementPage = Window:Page({Name = "Movement", Columns = 2})
    local VisualsPage = Window:Page({Name = "Visuals", SubPages = true})
    local WorldPage = Window:Page({Name = "World", Columns = 2})
    local MiscPage = Window:Page({Name = "Misc", Columns = 2})
    local BlatantPage = Window:Page({Name = "Blatant", Columns = 2})
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

    local RagebotForcedTarget = nil
    local RagebotMuzzleOrigin = nil

    local RunService = game:GetService("RunService")
    local RenderCache = {}
    local NotificationShown = {}
    local CleanupCallbacks = {}
    local TrackedDrawings = {}

    local function RegisterCleanup(fn)
        table.insert(CleanupCallbacks, fn)
    end

    local function TrackDrawing(obj)
        table.insert(TrackedDrawings, obj)
        return obj
    end

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

    local MasterRenderConnection = RunService.RenderStepped:Connect(function(Delta)
        for _, Connection in RenderCache do
            Connection.Function(Delta)
        end
    end)
    RegisterCleanup(function()
        MasterRenderConnection:Disconnect()
    end)

    local PingWarningEnabled = false
    local PingThreshold = 0.3
    local LastPingWarning = 0
    local PingCooldown = 30

    do
        local LastFPS = 0
        local FrameCount = 0
        local LastFPSUpdate = os.clock()

        NewRender(function(Delta)
            FrameCount = FrameCount + 1
            local now = os.clock()
            if now - LastFPSUpdate >= 0.5 then
                LastFPS = math.floor(FrameCount / (now - LastFPSUpdate))
                FrameCount = 0
                LastFPSUpdate = now
            end

            local ping = game.Players.LocalPlayer:GetNetworkPing()
            local pingMs = math.floor(ping * 1000)
            Watermark:SetText(string.format("moonshine | Prison Life | %d FPS | %dms", LastFPS, pingMs))

            if PingWarningEnabled and ping >= PingThreshold and (now - LastPingWarning) >= PingCooldown then
                LastPingWarning = now
                Library:Notification("High Ping", string.format("Your ping is %dms — gameplay may be unplayable.", pingMs), 5)
            end
        end)
    end

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
                    ToolTip = {
                        Name = "No Fire Rate",
                        Description = "Sets weapon fire delay to zero — cap FPS to 60 or bullets arrive instantly"
                    },
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
                    ToolTip = {
                        Name = "No Spread",
                        Description = "Removes bullet spread for perfect accuracy on every shot"
                    },
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

            RegisterCleanup(function()
                for _, conn in pairs(GunModConnections) do conn:Disconnect() end
                for _, attr in pairs({"FireRate", "SpreadRadius", "AutoFire"}) do RevertMod(attr) end
            end)

            local ForceAutoFire = GunModsSubPage:Section({Name = "Force Auto Fire", Side = 1}) do
                ForceAutoFire:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Force Auto Fire",
                        Description = "Makes all weapons fully automatic — hold click to spray"
                    },
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
                    Triggerbot = false,
                    ArrestSafety = false,
                    FoVCircle = false,
                    FoVCircleColor = Library.Theme.Accent,
                    Tracer = false,
                    TracerColor = Library.Theme.Accent,
                    Radius = 130,
                    Bone = "Head",
                    WallCheck = false,
                    MuzzleLOS = false,
                    ForceFieldCheck = true,
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
                    ToolTip = {
                        Name = "Silent Aim",
                        Description = "Redirects bullet raycasts toward the closest valid target without moving your camera"
                    },
                    Flag = "SilentAimEnabled",
                    Default = SilentAimState.Enabled,
                    Callback = function(v) SilentAimState.Enabled = v end
                })

                SilentAimSection:Toggle({
                    Name = "Triggerbot",
                    ToolTip = {
                        Name = "Triggerbot",
                        Description = "Automatically fires when a valid target is within the FoV circle"
                    },
                    Flag = "SilentAimTriggerbot",
                    Default = SilentAimState.Triggerbot,
                    Callback = function(v) SilentAimState.Triggerbot = v end
                })

                SilentAimSection:Toggle({
                    Name = "Arrest Safety",
                    ToolTip = {
                        Name = "Arrest Safety",
                        Description = "Ignores arrestable inmates unless you are holding the Taser — killing them without cause is punishable"
                    },
                    Flag = "SilentAimArrestSafety",
                    Default = SilentAimState.ArrestSafety,
                    Callback = function(v) SilentAimState.ArrestSafety = v end
                })

                SilentAimSection:Toggle({
                    Name = "FoV Circle",
                    ToolTip = {
                        Name = "FoV Circle",
                        Description = "Shows a circle around your cursor representing the targeting radius"
                    },
                    Flag = "SilentAimFoVEnabled",
                    Default = SilentAimState.FoVCircle,
                    Callback = function(v) SilentAimState.FoVCircle = v end
                }):Colorpicker({
                    Name = "Color",
                    Flag = "SilentAimFoVColor",
                    Default = SilentAimState.FoVCircleColor,
                    Alpha = 0,
                    Callback = function(v) SilentAimState.FoVCircleColor = v end
                })

                SilentAimSection:Toggle({
                    Name = "Tracer",
                    ToolTip = {
                        Name = "Tracer",
                        Description = "Draws a line from your cursor to the current target"
                    },
                    Flag = "SilentAimTracerEnabled",
                    Default = SilentAimState.Tracer,
                    Callback = function(v) SilentAimState.Tracer = v end
                }):Colorpicker({
                    Name = "Color",
                    Flag = "SilentAimTracerColor",
                    Default = SilentAimState.TracerColor,
                    Alpha = 0,
                    Callback = function(v) SilentAimState.TracerColor = v end
                })

                SilentAimSection:Slider({
                    Name = "Radius",
                    Flag = "SilentAimRadius",
                    Min = 1,
                    Suffix = "px",
                    Max = 500,
                    Default = SilentAimState.Radius,
                    Decimals = 1,
                    Callback = function(v) SilentAimState.Radius = v end
                })

                SilentAimSection:Dropdown({
                    Name = "Bone",
                    Flag = "SilentAimBone",
                    Default = SilentAimState.Bone,
                    Multi = false,
                    Items = {"Head", "HumanoidRootPart"},
                    Callback = function(v) SilentAimState.Bone = v end
                })

                SilentAimSection:Toggle({
                    Name = "Wall Check",
                    ToolTip = {
                        Name = "Wall Check",
                        Description = "Skips targets obscured by walls from the camera's perspective"
                    },
                    Flag = "SilentAimWallCheck",
                    Default = SilentAimState.WallCheck,
                    Callback = function(v) SilentAimState.WallCheck = v end
                })

                SilentAimSection:Toggle({
                    Name = "Muzzle LOS",
                    ToolTip = {
                        Name = "Muzzle LOS",
                        Description = "Raycasts from the gun's muzzle to the target — skips targets that would waste bullets on walls"
                    },
                    Flag = "SilentAimMuzzleLOS",
                    Default = SilentAimState.MuzzleLOS,
                    Callback = function(v) SilentAimState.MuzzleLOS = v end
                })

                SilentAimSection:Toggle({
                    Name = "ForceField Check",
                    ToolTip = {
                        Name = "ForceField Check",
                        Description = "Skips targets with an active spawn ForceField"
                    },
                    Flag = "SilentAimForceFieldCheck",
                    Default = SilentAimState.ForceFieldCheck,
                    Callback = function(v) SilentAimState.ForceFieldCheck = v end
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
                    ToolTip = {
                        Name = "Death Check",
                        Description = "Skips dead players so you don't waste shots on corpses"
                    },
                    Flag = "SilentAimDeathCheck",
                    Default = SilentAimState.DeathCheck,
                    Callback = function(v) SilentAimState.DeathCheck = v end
                })

                SilentAimSection:Toggle({
                    Name = "Friend Check",
                    ToolTip = {
                        Name = "Friend Check",
                        Description = "Won't target players on your Roblox friends list"
                    },
                    Flag = "SilentAimFriendCheck",
                    Default = SilentAimState.FriendCheck,
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
                    local FoVCircle = TrackDrawing(Drawing.new("Circle"))
                    FoVCircle.Thickness = 1
                    FoVCircle.NumSides = 100
                    FoVCircle.Filled = false
                    FoVCircle.Visible = false
                    FoVCircle.ZIndex = 999
                    FoVCircle.Transparency = 1

                    local Tracer = TrackDrawing(Drawing.new("Line"))
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

                        return #GetPartsObscuringTarget(Camera, {TargetPart.Position}, {LocalPlayerCharacter, PlayerCharacter}) == 0
                    end

                    local SilentAimFrameCounter = 0
                    local CachedClosestResult = nil
                    local CachedClosestFrame = -1

                    local function getClosestPlayer()
                        if CachedClosestFrame == SilentAimFrameCounter then
                            return CachedClosestResult
                        end

                        local Closest = nil
                        local ClosestDist = nil
                        local MousePos = getMousePosition()
                        local BoneName = SilentAimState.Bone

                        local checkArrestSafety = SilentAimState.ArrestSafety
                        local checkMuzzleLOS = SilentAimState.MuzzleLOS
                        local LocalCharacter = LocalPlayer.Character
                        local holdingTaser = false
                        local muzzleOrigin = nil

                        if LocalCharacter then
                            local tool = LocalCharacter:FindFirstChildOfClass("Tool")
                            if tool then
                                if checkArrestSafety then
                                    holdingTaser = tool.Name == "Taser"
                                end
                                if checkMuzzleLOS then
                                    local muzzle = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
                                    if muzzle then muzzleOrigin = muzzle.Position end
                                end
                            end
                        end

                        local losParams
                        if muzzleOrigin then
                            losParams = RaycastParams.new()
                            losParams.FilterType = Enum.RaycastFilterType.Exclude
                        end

                        for _, Player in next, GetPlayers(Players) do
                            if Player == LocalPlayer then continue end
                            if SilentAimState.Whitelist[Player.Name] then continue end
                            if SilentAimState.FriendCheck and FriendsCache[Player.Name] then continue end

                            local TeamName = Player.Team and Player.Team.Name or ""
                            if next(SilentAimState.Teams) and not SilentAimState.Teams[TeamName] then continue end

                            local Character = Player.Character
                            if not Character then continue end

                            if TeamName == "Inmates" then
                                local needStatus = next(SilentAimState.InmateTypes) or (checkArrestSafety and not holdingTaser)
                                if needStatus then
                                    local Status = GetInmateStatus(Character)
                                    if next(SilentAimState.InmateTypes) and not SilentAimState.InmateTypes[Status] then continue end
                                    if checkArrestSafety and not holdingTaser and Status == "Arrestable" then continue end
                                end
                            end

                            local Humanoid = FindFirstChild(Character, "Humanoid")
                            if SilentAimState.DeathCheck and (not Humanoid or Humanoid.Health <= 0) then continue end
                            if SilentAimState.ForceFieldCheck and FindFirstChild(Character, "ForceField") then continue end

                            local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
                            if not HumanoidRootPart then continue end

                            if SilentAimState.WallCheck and not IsPlayerVisible(Player) then continue end

                            if muzzleOrigin then
                                local targetBone = FindFirstChild(Character, BoneName) or HumanoidRootPart
                                losParams.FilterDescendantsInstances = {LocalCharacter, Character}
                                if workspace:Raycast(muzzleOrigin, targetBone.Position - muzzleOrigin, losParams) then continue end
                            end

                            local ScreenPos, OnScreen = WorldToViewportPoint(Camera, HumanoidRootPart.Position)
                            if not OnScreen then continue end

                            local Distance = (MousePos - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                            if Distance <= (ClosestDist or SilentAimState.Radius) then
                                Closest = FindFirstChild(Character, BoneName) or HumanoidRootPart
                                ClosestDist = Distance
                            end
                        end

                        CachedClosestResult = Closest
                        CachedClosestFrame = SilentAimFrameCounter
                        return Closest
                    end

                    NewRender(function()
                        Camera = workspace.CurrentCamera
                        SilentAimFrameCounter = SilentAimFrameCounter + 1

                        if SilentAimState.Enabled and SilentAimState.FoVCircle then
                            FoVCircle.Position = getMousePosition()
                            FoVCircle.Radius = SilentAimState.Radius
                            FoVCircle.Color = SilentAimState.FoVCircleColor
                            FoVCircle.Visible = true
                        else
                            FoVCircle.Visible = false
                        end

                        local ClosestTarget = SilentAimState.Enabled and getClosestPlayer() or nil

                        if SilentAimState.Enabled and SilentAimState.Tracer then
                            if ClosestTarget then
                                local ScreenPos, OnScreen = WorldToViewportPoint(Camera, ClosestTarget.Position)
                                if OnScreen then
                                    Tracer.From = getMousePosition()
                                    Tracer.To = Vector2.new(ScreenPos.X, ScreenPos.Y)
                                    Tracer.Color = SilentAimState.TracerColor
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

                        if SilentAimState.Triggerbot and ClosestTarget then
                            local character = LocalPlayer.Character
                            if character then
                                local tool = character:FindFirstChildOfClass("Tool")
                                if tool then
                                    local handle = tool:FindFirstChild("Handle")
                                    if handle and handle:FindFirstChild("ShootSound") then
                                        mouse1click()
                                    end
                                end
                            end
                        end
                    end)


                    local oldNamecall
                    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
                        local Method = getnamecallmethod()
                        local Arguments = {...}
                        local self = Arguments[1]

                        if (SilentAimState.Enabled or RagebotForcedTarget) and self == workspace and not checkcaller() then
                            local rbTarget = RagebotForcedTarget
                            local rbOrigin = RagebotMuzzleOrigin

                            if Method == "FindPartOnRayWithIgnoreList" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                                    local HitPart = rbTarget or getClosestPlayer()
                                    if HitPart then
                                        local Origin = rbOrigin or Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "FindPartOnRayWithWhitelist" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                                    local HitPart = rbTarget or getClosestPlayer()
                                    if HitPart then
                                        local Origin = rbOrigin or Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "FindPartOnRay" or Method == "findPartOnRay" then
                                if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                                    local HitPart = rbTarget or getClosestPlayer()
                                    if HitPart then
                                        local Origin = rbOrigin or Arguments[2].Origin
                                        Arguments[2] = Ray.new(Origin, getDirection(Origin, HitPart.Position))
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            elseif Method == "Raycast" then
                                if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                                    local HitPart = rbTarget or getClosestPlayer()
                                    if HitPart then
                                        local Origin = rbOrigin or Arguments[2]
                                        Arguments[2] = Origin
                                        Arguments[3] = getDirection(Origin, HitPart.Position)
                                        return oldNamecall(unpack(Arguments))
                                    end
                                end
                            end
                        end

                        return oldNamecall(...)
                    end))

                    RegisterCleanup(function()
                        hookmetamethod(game, "__namecall", oldNamecall)
                    end)
                end
            end
        end
    end

    do
        local HitSoundsSubPage = CombatPage:SubPage({Name = "Hit Sounds", Columns = 2})

        do
            local SoundFiles = {
                ["rust.mp3"] = getcustomasset("moonshine/sounds/rust.mp3"),
                ["minecraft orb.mp3"] = getcustomasset("moonshine/sounds/minecraft orb.mp3"),
            }

            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local HealthConnections = {}
            local LastFireTime = 0
            local HIT_WINDOW = 0.35

            local HitSoundState = {
                Enabled = false,
                Volume = 1,
                Sound = "rust.mp3",
                MuteGunSound = false,
            }

            local KillSoundState = {
                Enabled = false,
                Volume = 1,
                Sound = "minecraft orb.mp3",
            }

            local function PlaySound(soundFile, volume)
                local id = SoundFiles[soundFile]
                if not id then return end
                local sound = Instance.new("Sound")
                sound.SoundId = id
                sound.Volume = volume
                sound.PlayOnRemove = true
                sound.Parent = workspace
                sound:Destroy()
            end

            local function PlayHitSound()
                PlaySound(HitSoundState.Sound, HitSoundState.Volume)
            end

            local function PlayKillSound()
                PlaySound(KillSoundState.Sound, KillSoundState.Volume)
            end

            local function MuteShootSound(tool)
                local handle = tool:FindFirstChild("Handle")
                if not handle then return end
                local shootSound = handle:FindFirstChild("ShootSound")
                if not shootSound or not shootSound:IsA("Sound") then return end
                if HitSoundState.MuteGunSound then
                    shootSound.Volume = 0
                end
            end

            local function HookTool(tool)
                if not tool:IsA("Tool") then return end
                tool.Activated:Connect(function()
                    LastFireTime = tick()
                    MuteShootSound(tool)
                end)
            end

            local function HookCharacter(character)
                for _, child in pairs(character:GetChildren()) do
                    HookTool(child)
                end
                character.ChildAdded:Connect(HookTool)
            end

            if LocalPlayer.Character then HookCharacter(LocalPlayer.Character) end
            LocalPlayer.CharacterAdded:Connect(HookCharacter)
            LocalPlayer.Backpack.ChildAdded:Connect(HookTool)
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                HookTool(tool)
            end

            local function TrackPlayer(player)
                if player == LocalPlayer then return end

                local function ConnectHealth(character)
                    local humanoid = character:WaitForChild("Humanoid", 5)
                    if not humanoid then return end
                    local lastHealth = humanoid.Health

                    if HealthConnections[player] then
                        HealthConnections[player]:Disconnect()
                    end

                    HealthConnections[player] = humanoid.HealthChanged:Connect(function(newHealth)
                        if (tick() - LastFireTime) <= HIT_WINDOW and newHealth < lastHealth then
                            if HitSoundState.Enabled then
                                PlayHitSound()
                            end
                            if KillSoundState.Enabled and newHealth <= 0 then
                                PlayKillSound()
                            end
                        end
                        lastHealth = newHealth
                    end)
                end

                if player.Character then
                    task.spawn(ConnectHealth, player.Character)
                end
                player.CharacterAdded:Connect(function(char)
                    task.spawn(ConnectHealth, char)
                end)
            end

            for _, player in pairs(Players:GetPlayers()) do
                TrackPlayer(player)
            end
            Players.PlayerAdded:Connect(TrackPlayer)
            Players.PlayerRemoving:Connect(function(player)
                if HealthConnections[player] then
                    HealthConnections[player]:Disconnect()
                    HealthConnections[player] = nil
                end
            end)

            RegisterCleanup(function()
                for player, conn in pairs(HealthConnections) do
                    conn:Disconnect()
                end
                local function RestoreAllSounds(container)
                    for _, tool in pairs(container:GetChildren()) do
                        if tool:IsA("Tool") then
                            local handle = tool:FindFirstChild("Handle")
                            if handle then
                                local s = handle:FindFirstChild("ShootSound")
                                if s and s:IsA("Sound") then s.Volume = 0.5 end
                            end
                        end
                    end
                end
                RestoreAllSounds(LocalPlayer.Backpack)
                if LocalPlayer.Character then RestoreAllSounds(LocalPlayer.Character) end
            end)

            local HitSoundsSection = HitSoundsSubPage:Section({Name = "Hit Sounds", Side = 1}) do
                HitSoundsSection:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Hit Sounds",
                        Description = "Plays a custom sound when your bullets damage a player"
                    },
                    Flag = "HitSoundsEnabled",
                    Default = false,
                    Callback = function(v) HitSoundState.Enabled = v end
                })

                HitSoundsSection:Toggle({
                    Name = "Mute Gun Sound",
                    ToolTip = {
                        Name = "Mute Gun Sound",
                        Description = "Silences the weapon's shoot sound effect"
                    },
                    Flag = "HitSoundsMuteGun",
                    Default = false,
                    Callback = function(v)
                        HitSoundState.MuteGunSound = v
                        local char = LocalPlayer.Character
                        if not v then
                            local function RestoreVolume(container)
                                for _, tool in pairs(container:GetChildren()) do
                                    if tool:IsA("Tool") then
                                        local handle = tool:FindFirstChild("Handle")
                                        if handle then
                                            local s = handle:FindFirstChild("ShootSound")
                                            if s and s:IsA("Sound") then s.Volume = 0.5 end
                                        end
                                    end
                                end
                            end
                            RestoreVolume(LocalPlayer.Backpack)
                            if char then RestoreVolume(char) end
                        end
                    end
                })

                HitSoundsSection:Slider({
                    Name = "Volume",
                    Flag = "HitSoundsVolume",
                    Min = 0,
                    Max = 3,
                    Default = 1,
                    Decimals = 1,
                    Callback = function(v) HitSoundState.Volume = v end
                })

                HitSoundsSection:Dropdown({
                    Name = "Sound",
                    Flag = "HitSoundsSound",
                    Default = "rust.mp3",
                    Multi = false,
                    Items = {"rust.mp3", "minecraft orb.mp3"},
                    Callback = function(v) HitSoundState.Sound = v end
                })

                HitSoundsSection:Button():Add("Preview", function()
                    PlayHitSound()
                end)
            end

            local KillSoundsSection = HitSoundsSubPage:Section({Name = "Kill Sounds", Side = 2}) do
                KillSoundsSection:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Kill Sounds",
                        Description = "Plays a custom sound when you eliminate a player"
                    },
                    Flag = "KillSoundsEnabled",
                    Default = false,
                    Callback = function(v) KillSoundState.Enabled = v end
                })

                KillSoundsSection:Slider({
                    Name = "Volume",
                    Flag = "KillSoundsVolume",
                    Min = 0,
                    Max = 3,
                    Default = 1,
                    Decimals = 1,
                    Callback = function(v) KillSoundState.Volume = v end
                })

                KillSoundsSection:Dropdown({
                    Name = "Sound",
                    Flag = "KillSoundsSound",
                    Default = "minecraft orb.mp3",
                    Multi = false,
                    Items = {"rust.mp3", "minecraft orb.mp3"},
                    Callback = function(v) KillSoundState.Sound = v end
                })

                KillSoundsSection:Button():Add("Preview", function()
                    PlayKillSound()
                end)
            end
        end
    end

    do
        do
            local NoclipSection = MovementPage:Section({Name = "Noclip", Side = 1}) do
                local NoclipEnabled = NoclipSection:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Noclip",
                        Description = "Walk through walls, floors, and all solid objects"
                    },
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
                    ToolTip = {
                        Name = "Infinite Jump",
                        Description = "Jump in mid-air without needing to touch the ground"
                    },
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
                local prefix = ""
                if Character:FindFirstChild("ForceField") then
                    prefix = "[FF] "
                end
                local displayName = humanoid.DisplayName
                if string.sub(displayName, 1, 4) == "\xF0\x9F\x94\x97" then
                    return prefix .. "[W] " .. Character.Name
                elseif string.sub(displayName, 1, 4) == "\xF0\x9F\x92\xA2" then
                    return prefix .. "[A] " .. Character.Name
                end
                return prefix .. Character.Name
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
                    ToolTip = {
                        Name = "Friend Check",
                        Description = "Applies whitelist behavior to players on your Roblox friends list"
                    },
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

            local NameESPState = {
                Enabled = false,
                TeamColor = true,
                Color = Library.Theme.Accent,
                ShowSelf = false,
                InmateStatus = true,
                Outline = true
            }
            
            local NameESP = ESPSubPage:Section({Name = "Name ESP", Side = 1}) do
                NameESP:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Name ESP",
                        Description = "Shows player names floating above their heads through walls"
                    },
                    Flag = "NameESPEnabled",
                    Default = NameESPState.Enabled,
                    Callback = function(callback)
                        NameESPState.Enabled = callback
                    end
                })

                NameESP:Toggle({
                    Name = "Team Color",
                    Flag = "NameESPTeamColor",
                    Default = NameESPState.TeamColor,
                    Callback = function(callback)
                        NameESPState.TeamColor = callback
                    end
                }):Colorpicker({
                    Name = "Color",
                    Flag = "NameESPColor",
                    Default = NameESPState.Color,
                    Alpha = 0,
                    Callback = function(callback)
                        NameESPState.Color = callback
                    end
                })

                NameESP:Toggle({
                    Name = "Show Self",
                    Flag = "NameESPShowSelf",
                    Default = NameESPState.ShowSelf,
                    Callback = function(callback)
                        NameESPState.ShowSelf = callback
                    end
                })
                
                NameESP:Toggle({
                    Name = "Inmate Status",
                    ToolTip = {
                        Name = "Inmate Status",
                        Description = "Prefixes names with [W] for wanted or [A] for aggressive inmates"
                    },
                    Flag = "NameESPInmateStatus",
                    Default = NameESPState.InmateStatus,
                    Callback = function(callback)
                        NameESPState.InmateStatus = callback
                    end
                })

                NameESP:Toggle({
                    Name = "Outline",
                    Flag = "NameESPOutline",
                    Default = NameESPState.Outline,
                    Callback = function(callback)
                        NameESPState.Outline = callback
                    end
                }) do
                    local function Apply(Character)
                        if game.Players:GetPlayerFromCharacter(Character) then
                            local Player = game.Players:GetPlayerFromCharacter(Character)
                            local Text = TrackDrawing(Drawing.new("Text"))
                            Text.Visible = false
                            Text.ZIndex = 3
                            Text.Size = 12
                            Text.Center = true
                            Text.OutlineColor = Color3.fromRGB(0, 0, 0)

                            local Render = NewRender(function()
                                local hrp = Character:FindFirstChild("HumanoidRootPart")
                                if not hrp then Text.Visible = false return end
                                local hum = Character:FindFirstChildOfClass("Humanoid")
                                if not hum or hum.Health <= 0 then Text.Visible = false return end
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                                if onscreen then
                                    if not ShouldShowPlayer(Player) then
                                        Text.Visible = false
                                        return
                                    end
                                    Text.Position = Vector2.new(pos.X, pos.Y)
                                    if NameESPState.InmateStatus == true then
                                        Text.Text = GetDisplayName(Character)
                                    else
                                        Text.Text = Character.Name
                                    end
                                    if NameESPState.ShowSelf == true then
                                        Text.Visible = NameESPState.Enabled
                                    else
                                        if Character ~= game.Players.LocalPlayer.Character then
                                            Text.Visible = NameESPState.Enabled
                                        else
                                            Text.Visible = false
                                        end
                                    end
                                    if IsWhitelisted(Player) then
                                        Text.Color = Color3.fromRGB(0, 255, 0)
                                    elseif NameESPState.TeamColor == true then
                                        Text.Color = Player.TeamColor.Color
                                    else
                                        Text.Color = NameESPState.Color
                                    end
                                    Text.Outline = NameESPState.Outline
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
                local BoxESPState = {
                    Enabled = false,
                    TeamColor = true,
                    Color = Library.Theme.Accent,
                    ShowSelf = false,
                    Outline = true
                }

                BoxESP:Toggle({
                    Name = "Enabled",
                    ToolTip = {
                        Name = "Box ESP",
                        Description = "Draws 2D bounding boxes around players visible through walls"
                    },
                    Flag = "BoxESPEnabled",
                    Default = BoxESPState.Enabled,
                    Callback = function(v) BoxESPState.Enabled = v end
                })

                BoxESP:Toggle({
                    Name = "Team Color",
                    Flag = "BoxESPTeamColor",
                    Default = BoxESPState.TeamColor,
                    Callback = function(v) BoxESPState.TeamColor = v end
                }):Colorpicker({
                    Name = "Color",
                    Flag = "BoxESPColor",
                    Default = BoxESPState.Color,
                    Callback = function(v) BoxESPState.Color = v end
                })

                BoxESP:Toggle({
                    Name = "Show Self",
                    Flag = "BoxESPShowSelf",
                    Default = BoxESPState.ShowSelf,
                    Callback = function(v) BoxESPState.ShowSelf = v end
                })

                BoxESP:Toggle({
                    Name = "Outline",
                    Flag = "BoxESPOutline",
                    Default = BoxESPState.Outline,
                    Callback = function(v) BoxESPState.Outline = v end
                }) do
                    local function Apply(Character)
                        if game.Players:GetPlayerFromCharacter(Character) then
                            local Player = game.Players:GetPlayerFromCharacter(Character)
                            local Box = TrackDrawing(Drawing.new("Square"))
                            Box.Visible = false
                            Box.ZIndex = 2
                            local BoxOutline = TrackDrawing(Drawing.new("Square"))
                            BoxOutline.Visible = false
                            BoxOutline.Thickness = 2
                            BoxOutline.ZIndex = 1
                            BoxOutline.Color = Color3.fromRGB(0, 0, 0)

                            local Render = NewRender(function()
                                local hrp = Character:FindFirstChild("HumanoidRootPart")
                                if not hrp then Box.Visible = false BoxOutline.Visible = false return end
                                local hum = Character:FindFirstChildOfClass("Humanoid")
                                if not hum or hum.Health <= 0 then Box.Visible = false BoxOutline.Visible = false return end
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
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
                                    if BoxESPState.ShowSelf == true then
                                        Box.Visible = BoxESPState.Enabled
                                        if Box.Visible == true then BoxOutline.Visible = BoxESPState.Outline else BoxOutline.Visible = false end
                                    else
                                        if Character ~= game.Players.LocalPlayer.Character then
                                            Box.Visible = BoxESPState.Enabled
                                            if Box.Visible == true then BoxOutline.Visible = BoxESPState.Outline else BoxOutline.Visible = false end
                                        else
                                            Box.Visible = false
                                            BoxOutline.Visible = false
                                        end
                                    end
                                    if IsWhitelisted(Player) then
                                        Box.Color = Color3.fromRGB(0, 255, 0)
                                    elseif BoxESPState.TeamColor == true then
                                        Box.Color = Player.TeamColor.Color
                                    else
                                        Box.Color = BoxESPState.Color
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
        local DoorStorage = game:GetService("Lighting")
        local StorageName = "MoonshineDoorStorage"

        local RemoveDoors = WorldPage:Section({Name = "Remove Doors", Side = 1}) do
            RemoveDoors:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Remove Doors",
                    Description = "Removes all doors from the map — purely visual, server still has them"
                },
                Flag = "RemoveDoorsEnabled",
                Default = false,
                Callback = function(enabled)
                    if enabled then
                        local Doors = workspace:FindFirstChild("Doors")
                        if not Doors then return end
                        local folder = Instance.new("Folder")
                        folder.Name = StorageName
                        folder.Parent = DoorStorage
                        Doors.Parent = folder
                    else
                        local folder = DoorStorage:FindFirstChild(StorageName)
                        if not folder then return end
                        local Doors = folder:FindFirstChild("Doors")
                        if Doors then Doors.Parent = workspace end
                        folder:Destroy()
                    end
                end
            })
        end

        RegisterCleanup(function()
            local folder = DoorStorage:FindFirstChild(StorageName)
            if folder then
                local Doors = folder:FindFirstChild("Doors")
                if Doors then Doors.Parent = workspace end
                folder:Destroy()
            end
        end)

        local BypassDoors = WorldPage:Section({Name = "Bypass Doors", Side = 1}) do
            local DummyFolder = nil

            BypassDoors:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Bypass Doors",
                    Description = "Replaces doors with passthrough parts — walk through any door as a guard"
                },
                Flag = "BypassDoorsEnabled",
                Default = false,
                Callback = function(enabled)
                    if enabled then
                        local Doors = workspace:FindFirstChild("Doors")
                        if not Doors then return end

                        DummyFolder = Instance.new("Folder")
                        DummyFolder.Name = "BypassDoorDummies"
                        DummyFolder.Parent = workspace

                        for _, child in pairs(Doors:GetChildren()) do
                            local cf, size
                            if child:IsA("Model") then
                                cf, size = child:GetBoundingBox()
                            elseif child:IsA("BasePart") then
                                cf = child.CFrame
                                size = child.Size
                            else
                                continue
                            end

                            local dummy = Instance.new("Part")
                            dummy.Name = child.Name
                            dummy.Size = size
                            dummy.CFrame = cf
                            dummy.Anchored = true
                            dummy.CanCollide = false
                            dummy.CanTouch = false
                            dummy.Transparency = 0.75
                            dummy.Material = Enum.Material.ForceField
                            dummy.Color = Color3.fromRGB(120, 180, 255)
                            dummy.Parent = DummyFolder
                        end

                        local folder = Instance.new("Folder")
                        folder.Name = StorageName
                        folder.Parent = DoorStorage
                        Doors.Parent = folder
                    else
                        local folder = DoorStorage:FindFirstChild(StorageName)
                        if folder then
                            local Doors = folder:FindFirstChild("Doors")
                            if Doors then Doors.Parent = workspace end
                            folder:Destroy()
                        end

                        if DummyFolder then
                            DummyFolder:Destroy()
                            DummyFolder = nil
                        end
                    end
                end
            })

            RegisterCleanup(function()
                if DummyFolder then
                    DummyFolder:Destroy()
                end
            end)
        end
    end

    do
        local PingWarning = MiscPage:Section({Name = "Ping Warning", Side = 2}) do
            PingWarning:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Ping Warning",
                    Description = "Notifies you when your ping exceeds 300ms"
                },
                Flag = "PingWarningEnabled",
                Default = false,
                Callback = function(v) PingWarningEnabled = v end
            })
        end
    end

    do
        local RemoveJumpCooldown = MiscPage:Section({Name = "Remove Jump Cooldown", Side = 1}) do
            local Enabled = RemoveJumpCooldown:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Remove Jump Cooldown",
                    Description = "Disables the forced delay between consecutive jumps"
                },
                Flag = "RemoveJumpCooldownEnabled",
                Default = false
            }) do
                NewRender(function()
                    local character = game.Players.LocalPlayer.Character
                    if not character then return end
                    local antiJump = character:FindFirstChild("AntiJump")
                    if not antiJump then return end
                    antiJump.Disabled = Enabled:Get()
                end)
            end
        end
    end

    do
        local AntiInvisible = MiscPage:Section({Name = "Anti Invisible", Side = 2}) do
            local Enabled = AntiInvisible:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Anti Invisible",
                    Description = "Detects the invisibility glitch and highlights offending players in red"
                },
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

                RegisterCleanup(function()
                    for player, _ in pairs(FlaggedPlayers) do
                        CleanupPlayer(player)
                    end
                end)
            end
        end
    end

    do
        local AlwaysBackpack = MiscPage:Section({Name = "Always Backpack", Side = 1}) do
            local Enabled = AlwaysBackpack:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Always Backpack",
                    Description = "Prevents the game from hiding your inventory toolbar"
                },
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
                ToolTip = {
                    Name = "Anti Tase",
                    Description = "Cancels the taser stun animation and restores your movement instantly"
                },
                Flag = "AntiTaseEnabled",
                Default = false
            }) do

                local PreTaseSpeed = 16
                local PreTaseJumpHeight = 5.5

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
                        humanoid.WalkSpeed = PreTaseSpeed
                        humanoid.JumpHeight = PreTaseJumpHeight
                    else
                        if humanoid.WalkSpeed > 0 then
                            PreTaseSpeed = humanoid.WalkSpeed
                        end
                        if humanoid.JumpHeight > 0 then
                            PreTaseJumpHeight = humanoid.JumpHeight
                        end
                    end
                end)
            end
        end
    end

    do
        local ArrestAura = MiscPage:Section({Name = "Arrest Aura", Side = 1}) do
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local ArrestRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ArrestPlayer")

            local AAState = {
                Enabled = false,
                FriendCheck = false,
                ShowRadius = false,
                ShowTarget = false,
                Radius = 10,
                Whitelist = {},
            }

            local function GetInmateStatusAA(character)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return "Regular" end
                local dn = humanoid.DisplayName
                if string.sub(dn, 1, 4) == "\xF0\x9F\x94\x97" then
                    return "Arrestable"
                elseif string.sub(dn, 1, 4) == "\xF0\x9F\x92\xA2" then
                    return "Aggressive"
                end
                return "Regular"
            end

            local function IsArrestable(player)
                local teamName = player.Team and player.Team.Name or ""
                if teamName == "Criminals" then return true end
                if teamName == "Inmates" then
                    local char = player.Character
                    if char then
                        local status = GetInmateStatusAA(char)
                        if status == "Arrestable" or status == "Aggressive" then
                            return true
                        end
                    end
                end
                return false
            end

            local CIRCLE_SEGMENTS = 40
            local RadiusLines = {}
            for i = 1, CIRCLE_SEGMENTS do
                local line = TrackDrawing(Drawing.new("Line"))
                line.Thickness = 1
                line.Visible = false
                line.ZIndex = 998
                line.Transparency = 0.6
                line.Color = Color3.fromRGB(255, 50, 50)
                RadiusLines[i] = line
            end

            local TargetLine = TrackDrawing(Drawing.new("Line"))
            TargetLine.Thickness = 1.5
            TargetLine.Visible = false
            TargetLine.ZIndex = 998
            TargetLine.Color = Color3.fromRGB(255, 50, 50)

            ArrestAura:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Arrest Aura",
                    Description = "Automatically arrests the closest criminal or wanted inmate within radius"
                },
                Flag = "ArrestAuraEnabled",
                Default = false,
                Callback = function(v)
                    AAState.Enabled = v
                    if not v then
                        for _, line in RadiusLines do line.Visible = false end
                        TargetLine.Visible = false
                    end
                end
            })

            ArrestAura:Slider({
                Name = "Radius",
                Flag = "ArrestAuraRadius",
                Min = 5,
                Max = 30,
                Default = 10,
                Suffix = " studs",
                Decimals = 1,
                Callback = function(v) AAState.Radius = v end
            })

            ArrestAura:Toggle({
                Name = "Show Radius",
                Flag = "ArrestAuraShowRadius",
                Default = false,
                Callback = function(v)
                    AAState.ShowRadius = v
                    if not v then
                        for _, line in RadiusLines do line.Visible = false end
                    end
                end
            })

            ArrestAura:Toggle({
                Name = "Show Target",
                Flag = "ArrestAuraShowTarget",
                Default = false,
                Callback = function(v)
                    AAState.ShowTarget = v
                    if not v then TargetLine.Visible = false end
                end
            })

            ArrestAura:Toggle({
                Name = "Friend Check",
                ToolTip = {
                    Name = "Friend Check",
                    Description = "Won't arrest players on your Roblox friends list"
                },
                Flag = "ArrestAuraFriendCheck",
                Default = false,
                Callback = function(v) AAState.FriendCheck = v end
            })

            local aaPlayerNames = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
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
                    AAState.Whitelist = set
                end
            })

            Players.PlayerAdded:Connect(function(p) AAWhitelistDropdown:Add(p.Name) end)
            Players.PlayerRemoving:Connect(function(p) AAWhitelistDropdown:Remove(p.Name) end)

            NewRender(function()
                if not AAState.Enabled then
                    for _, line in RadiusLines do line.Visible = false end
                    TargetLine.Visible = false
                    return
                end

                local character = LocalPlayer.Character
                if not character then return end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local Camera = workspace.CurrentCamera
                local feetY = rootPart.Position.Y - 3
                local center = Vector3.new(rootPart.Position.X, feetY, rootPart.Position.Z)

                if AAState.ShowRadius then
                    local angleStep = (2 * math.pi) / CIRCLE_SEGMENTS
                    local prevScreen = nil
                    local prevOnScreen = false

                    for i = 1, CIRCLE_SEGMENTS do
                        local angle = angleStep * i
                        local worldPoint = center + Vector3.new(math.cos(angle) * AAState.Radius, 0, math.sin(angle) * AAState.Radius)
                        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPoint)
                        local curScreen = Vector2.new(screenPos.X, screenPos.Y)

                        if i > 1 then
                            if onScreen and prevOnScreen then
                                RadiusLines[i - 1].From = prevScreen
                                RadiusLines[i - 1].To = curScreen
                                RadiusLines[i - 1].Visible = true
                            else
                                RadiusLines[i - 1].Visible = false
                            end
                        end

                        if i == CIRCLE_SEGMENTS then
                            local firstWorld = center + Vector3.new(math.cos(angleStep) * AAState.Radius, 0, math.sin(angleStep) * AAState.Radius)
                            local firstPos, firstOn = Camera:WorldToViewportPoint(firstWorld)
                            if onScreen and firstOn then
                                RadiusLines[CIRCLE_SEGMENTS].From = curScreen
                                RadiusLines[CIRCLE_SEGMENTS].To = Vector2.new(firstPos.X, firstPos.Y)
                                RadiusLines[CIRCLE_SEGMENTS].Visible = true
                            else
                                RadiusLines[CIRCLE_SEGMENTS].Visible = false
                            end
                        end

                        prevScreen = curScreen
                        prevOnScreen = onScreen
                    end
                else
                    for _, line in RadiusLines do line.Visible = false end
                end

                local closestPlayer = nil
                local closestDist = AAState.Radius

                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if AAState.Whitelist[player.Name] then continue end
                    if AAState.FriendCheck and FriendsCache[player.Name] then continue end
                    if not IsArrestable(player) then continue end
                    local targetChar = player.Character
                    if not targetChar then continue end
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if not targetRoot then continue end
                    local dist = (rootPart.Position - targetRoot.Position).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end

                if closestPlayer then
                    local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        pcall(function()
                            ArrestRemote:InvokeServer(closestPlayer, 1)
                        end)

                        if AAState.ShowTarget then
                            local targetFeetY = targetRoot.Position.Y - 3
                            local fromWorld = Vector3.new(rootPart.Position.X, feetY, rootPart.Position.Z)
                            local toWorld = Vector3.new(targetRoot.Position.X, targetFeetY, targetRoot.Position.Z)
                            local fromPos, fromOn = Camera:WorldToViewportPoint(fromWorld)
                            local toPos, toOn = Camera:WorldToViewportPoint(toWorld)
                            if fromOn and toOn then
                                TargetLine.From = Vector2.new(fromPos.X, fromPos.Y)
                                TargetLine.To = Vector2.new(toPos.X, toPos.Y)
                                TargetLine.Visible = true
                            else
                                TargetLine.Visible = false
                            end
                        else
                            TargetLine.Visible = false
                        end
                    end
                else
                    TargetLine.Visible = false
                end
            end)
        end
    end

    do
        local FistAura = MiscPage:Section({Name = "Fist Aura", Side = 2}) do
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local MeleeRemote = game:GetService("ReplicatedStorage"):WaitForChild("meleeEvent")

            local FAState = {
                Enabled = false,
                FriendCheck = false,
                ShowRadius = false,
                ShowTarget = false,
                Radius = 10,
                Teams = {},
                InmateTypes = {},
                Whitelist = {},
            }

            local function GetInmateStatusFA(character)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return "Regular" end
                local dn = humanoid.DisplayName
                if string.sub(dn, 1, 4) == "\xF0\x9F\x94\x97" then
                    return "Arrestable"
                elseif string.sub(dn, 1, 4) == "\xF0\x9F\x92\xA2" then
                    return "Aggressive"
                end
                return "Regular"
            end

            local function ShouldTarget(player)
                local teamName = player.Team and player.Team.Name or ""
                if next(FAState.Teams) and not FAState.Teams[teamName] then return false end
                if teamName == "Inmates" and next(FAState.InmateTypes) then
                    local char = player.Character
                    if char then
                        local status = GetInmateStatusFA(char)
                        if not FAState.InmateTypes[status] then return false end
                    end
                end
                return true
            end

            local FA_CIRCLE_SEGMENTS = 40
            local FARadiusLines = {}
            for i = 1, FA_CIRCLE_SEGMENTS do
                local line = TrackDrawing(Drawing.new("Line"))
                line.Thickness = 1
                line.Visible = false
                line.ZIndex = 997
                line.Transparency = 0.6
                line.Color = Color3.fromRGB(50, 150, 255)
                FARadiusLines[i] = line
            end

            local FATargetLine = TrackDrawing(Drawing.new("Line"))
            FATargetLine.Thickness = 1.5
            FATargetLine.Visible = false
            FATargetLine.ZIndex = 997
            FATargetLine.Color = Color3.fromRGB(50, 150, 255)

            FistAura:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Fist Aura",
                    Description = "Automatically punches the closest valid player within radius"
                },
                Flag = "FistAuraEnabled",
                Default = false,
                Callback = function(v)
                    FAState.Enabled = v
                    if not v then
                        for _, line in FARadiusLines do line.Visible = false end
                        FATargetLine.Visible = false
                    end
                end
            })

            FistAura:Slider({
                Name = "Radius",
                Flag = "FistAuraRadius",
                Min = 5,
                Max = 30,
                Default = 10,
                Suffix = " studs",
                Decimals = 1,
                Callback = function(v) FAState.Radius = v end
            })

            FistAura:Toggle({
                Name = "Show Radius",
                Flag = "FistAuraShowRadius",
                Default = false,
                Callback = function(v)
                    FAState.ShowRadius = v
                    if not v then
                        for _, line in FARadiusLines do line.Visible = false end
                    end
                end
            })

            FistAura:Toggle({
                Name = "Show Target",
                Flag = "FistAuraShowTarget",
                Default = false,
                Callback = function(v)
                    FAState.ShowTarget = v
                    if not v then FATargetLine.Visible = false end
                end
            })

            FistAura:Dropdown({
                Name = "Teams",
                Flag = "FistAuraTeams",
                Multi = true,
                Items = {"Guards", "Inmates", "Criminals"},
                Callback = function(v)
                    local set = {}
                    for _, name in pairs(v) do set[name] = true end
                    FAState.Teams = set
                end
            })

            FistAura:Dropdown({
                Name = "Inmate Types",
                Flag = "FistAuraInmateTypes",
                Multi = true,
                Items = {"Regular", "Aggressive", "Arrestable"},
                Callback = function(v)
                    local set = {}
                    for _, name in pairs(v) do set[name] = true end
                    FAState.InmateTypes = set
                end
            })

            FistAura:Toggle({
                Name = "Friend Check",
                ToolTip = {
                    Name = "Friend Check",
                    Description = "Won't punch players on your Roblox friends list"
                },
                Flag = "FistAuraFriendCheck",
                Default = false,
                Callback = function(v) FAState.FriendCheck = v end
            })

            local faPlayerNames = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
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
                    FAState.Whitelist = set
                end
            })

            Players.PlayerAdded:Connect(function(p) FAWhitelistDropdown:Add(p.Name) end)
            Players.PlayerRemoving:Connect(function(p) FAWhitelistDropdown:Remove(p.Name) end)

            NewRender(function()
                if not FAState.Enabled then
                    for _, line in FARadiusLines do line.Visible = false end
                    FATargetLine.Visible = false
                    return
                end

                local character = LocalPlayer.Character
                if not character then return end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local Camera = workspace.CurrentCamera
                local feetY = rootPart.Position.Y - 3
                local center = Vector3.new(rootPart.Position.X, feetY, rootPart.Position.Z)

                if FAState.ShowRadius then
                    local angleStep = (2 * math.pi) / FA_CIRCLE_SEGMENTS
                    local prevScreen = nil
                    local prevOnScreen = false

                    for i = 1, FA_CIRCLE_SEGMENTS do
                        local angle = angleStep * i
                        local worldPoint = center + Vector3.new(math.cos(angle) * FAState.Radius, 0, math.sin(angle) * FAState.Radius)
                        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPoint)
                        local curScreen = Vector2.new(screenPos.X, screenPos.Y)

                        if i > 1 then
                            if onScreen and prevOnScreen then
                                FARadiusLines[i - 1].From = prevScreen
                                FARadiusLines[i - 1].To = curScreen
                                FARadiusLines[i - 1].Visible = true
                            else
                                FARadiusLines[i - 1].Visible = false
                            end
                        end

                        if i == FA_CIRCLE_SEGMENTS then
                            local firstWorld = center + Vector3.new(math.cos(angleStep) * FAState.Radius, 0, math.sin(angleStep) * FAState.Radius)
                            local firstPos, firstOn = Camera:WorldToViewportPoint(firstWorld)
                            if onScreen and firstOn then
                                FARadiusLines[FA_CIRCLE_SEGMENTS].From = curScreen
                                FARadiusLines[FA_CIRCLE_SEGMENTS].To = Vector2.new(firstPos.X, firstPos.Y)
                                FARadiusLines[FA_CIRCLE_SEGMENTS].Visible = true
                            else
                                FARadiusLines[FA_CIRCLE_SEGMENTS].Visible = false
                            end
                        end

                        prevScreen = curScreen
                        prevOnScreen = onScreen
                    end
                else
                    for _, line in FARadiusLines do line.Visible = false end
                end

                local closestPlayer = nil
                local closestDist = FAState.Radius

                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if FAState.Whitelist[player.Name] then continue end
                    if FAState.FriendCheck and FriendsCache[player.Name] then continue end
                    if not ShouldTarget(player) then continue end
                    local targetChar = player.Character
                    if not targetChar then continue end
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if not targetRoot then continue end
                    local dist = (rootPart.Position - targetRoot.Position).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end

                if closestPlayer then
                    local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        pcall(function()
                            MeleeRemote:FireServer(closestPlayer, 1, 1)
                        end)

                        if FAState.ShowTarget then
                            local targetFeetY = targetRoot.Position.Y - 3
                            local fromWorld = Vector3.new(rootPart.Position.X, feetY, rootPart.Position.Z)
                            local toWorld = Vector3.new(targetRoot.Position.X, targetFeetY, targetRoot.Position.Z)
                            local fromPos, fromOn = Camera:WorldToViewportPoint(fromWorld)
                            local toPos, toOn = Camera:WorldToViewportPoint(toWorld)
                            if fromOn and toOn then
                                FATargetLine.From = Vector2.new(fromPos.X, fromPos.Y)
                                FATargetLine.To = Vector2.new(toPos.X, toPos.Y)
                                FATargetLine.Visible = true
                            else
                                FATargetLine.Visible = false
                            end
                        else
                            FATargetLine.Visible = false
                        end
                    end
                else
                    FATargetLine.Visible = false
                end
            end)
        end
    end

    do
        local AntiRiotShield = MiscPage:Section({Name = "Anti Riot Shield", Side = 1}) do
            local Enabled = AntiRiotShield:Toggle({
                Name = "Enabled",
                ToolTip = {
                    Name = "Anti Riot Shield",
                    Description = "Removes RiotShieldPart from all players' characters"
                },
                Flag = "AntiRiotShieldEnabled",
                Default = false
            }) do
                NewRender(function()
                    if Enabled:Get() ~= true then return end
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        local character = player.Character
                        if not character then continue end
                        local shield = character:FindFirstChild("RiotShieldPart")
                        if shield then
                            shield:Destroy()
                        end
                    end
                end)
            end
        end
    end

    do
        local RagebotSection = BlatantPage:Section({Name = "Ragebot (BETA)", Side = 1})
        local RagebotConfigSection = BlatantPage:Section({Name = "Ragebot Config", Side = 2})

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local RBState = {
            Enabled = false,
            AutoSwitch = true,
            AutoReload = true,
            TargetBone = "HumanoidRootPart",
            Teams = {},
            InmateTypes = {},
            DeathCheck = true,
            ForceFieldCheck = true,
            FriendCheck = false,
            Whitelist = {},
        }

        local RBLastFireTick = 0
        local RBSwitchCooldown = 0

        local function RBGetAllGuns()
            local guns = {}
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
                    table.insert(guns, tool)
                end
            end
            local char = LocalPlayer.Character
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
                        table.insert(guns, tool)
                    end
                end
            end
            return guns
        end

        local function RBGetEquippedGun()
            local char = LocalPlayer.Character
            if not char then return nil end
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
                    return tool
                end
            end
            return nil
        end

        local function RBGetMuzzlePosition(tool)
            local muzzle = tool:FindFirstChild("Muzzle")
            if muzzle and muzzle:IsA("BasePart") then return muzzle.Position end
            local handle = tool:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then return handle.Position end
            return nil
        end

        local function RBHasClearLOS(origin, targetPos, ignoreList)
            local direction = targetPos - origin
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = ignoreList
            local result = workspace:Raycast(origin, direction, params)
            return result == nil
        end

        local function RBGetInmateStatus(character)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return "Regular" end
            local dn = humanoid.DisplayName
            if string.sub(dn, 1, 4) == "\xF0\x9F\x94\x97" then return "Arrestable"
            elseif string.sub(dn, 1, 4) == "\xF0\x9F\x92\xA2" then return "Aggressive" end
            return "Regular"
        end

        local function RBFindBestTarget(muzzlePos, gun)
            local localChar = LocalPlayer.Character
            if not localChar then return nil end

            local range = gun:GetAttribute("Range") or 1000
            local bestTarget = nil
            local bestDist = math.huge

            for _, player in pairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                if RBState.Whitelist[player.Name] then continue end
                if RBState.FriendCheck and FriendsCache[player.Name] then continue end

                local teamName = player.Team and player.Team.Name or ""
                if next(RBState.Teams) and not RBState.Teams[teamName] then continue end

                local character = player.Character
                if not character then continue end

                if teamName == "Inmates" and next(RBState.InmateTypes) then
                    local status = RBGetInmateStatus(character)
                    if not RBState.InmateTypes[status] then continue end
                end

                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if RBState.DeathCheck and (not humanoid or humanoid.Health <= 0) then continue end
                if RBState.ForceFieldCheck and character:FindFirstChild("ForceField") then continue end

                local targetPart = character:FindFirstChild(RBState.TargetBone) or character:FindFirstChild("HumanoidRootPart")
                if not targetPart then continue end

                local dist = (muzzlePos - targetPart.Position).Magnitude
                if dist > range then continue end

                local clear = RBHasClearLOS(muzzlePos, targetPart.Position, {localChar, character})
                if clear and dist < bestDist then
                    bestDist = dist
                    bestTarget = targetPart
                end
            end

            return bestTarget
        end

        RagebotSection:Toggle({
            Name = "Enabled",
            ToolTip = {
                Name = "Ragebot",
                Description = "Fully automated combat — acquires targets, aims, and fires with no input needed"
            },
            Flag = "RagebotEnabled",
            Default = false,
            Callback = function(v)
                RBState.Enabled = v
                if not v then
                    RagebotForcedTarget = nil
                end
            end
        })

        RagebotSection:Toggle({
            Name = "Auto Switch",
            ToolTip = {
                Name = "Auto Switch",
                Description = "Automatically switches to another gun when the current one is empty"
            },
            Flag = "RagebotAutoSwitch",
            Default = true,
            Callback = function(v) RBState.AutoSwitch = v end
        })

        RagebotSection:Toggle({
            Name = "Auto Reload",
            ToolTip = {
                Name = "Auto Reload",
                Description = "Automatically reloads the current gun when the magazine is empty"
            },
            Flag = "RagebotAutoReload",
            Default = true,
            Callback = function(v) RBState.AutoReload = v end
        })

        RagebotSection:Dropdown({
            Name = "Target Bone",
            Flag = "RagebotTargetBone",
            Default = "HumanoidRootPart",
            Multi = false,
            Items = {"Head", "HumanoidRootPart"},
            Callback = function(v) RBState.TargetBone = v end
        })

        RagebotConfigSection:Dropdown({
            Name = "Teams",
            Flag = "RagebotTeams",
            Multi = true,
            Items = {"Guards", "Inmates", "Criminals"},
            Callback = function(v)
                local set = {}
                for _, name in pairs(v) do set[name] = true end
                RBState.Teams = set
            end
        })

        RagebotConfigSection:Dropdown({
            Name = "Inmate Types",
            Flag = "RagebotInmateTypes",
            Multi = true,
            Items = {"Regular", "Aggressive", "Arrestable"},
            Callback = function(v)
                local set = {}
                for _, name in pairs(v) do set[name] = true end
                RBState.InmateTypes = set
            end
        })

        RagebotConfigSection:Toggle({
            Name = "Death Check",
            ToolTip = {
                Name = "Death Check",
                Description = "Skips dead players so the ragebot doesn't waste ammo on corpses"
            },
            Flag = "RagebotDeathCheck",
            Default = true,
            Callback = function(v) RBState.DeathCheck = v end
        })

        RagebotConfigSection:Toggle({
            Name = "ForceField Check",
            ToolTip = {
                Name = "ForceField Check",
                Description = "Skips targets with an active spawn ForceField"
            },
            Flag = "RagebotForceFieldCheck",
            Default = true,
            Callback = function(v) RBState.ForceFieldCheck = v end
        })

        RagebotConfigSection:Toggle({
            Name = "Friend Check",
            ToolTip = {
                Name = "Friend Check",
                Description = "Won't target players on your Roblox friends list"
            },
            Flag = "RagebotFriendCheck",
            Default = false,
            Callback = function(v) RBState.FriendCheck = v end
        })

        local rbPlayerNames = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(rbPlayerNames, p.Name)
            end
        end

        local RBWhitelistDropdown = RagebotConfigSection:Dropdown({
            Name = "Whitelist",
            Flag = "RagebotWhitelist",
            Multi = true,
            Items = rbPlayerNames,
            Callback = function(v)
                local set = {}
                for _, name in pairs(v) do set[name] = true end
                RBState.Whitelist = set
            end
        })

        Players.PlayerAdded:Connect(function(p) RBWhitelistDropdown:Add(p.Name) end)
        Players.PlayerRemoving:Connect(function(p) RBWhitelistDropdown:Remove(p.Name) end)

        NewRender(function()
            if not RBState.Enabled then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end

            local character = LocalPlayer.Character
            if not character then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end

            local equippedGun = RBGetEquippedGun()
            local now = tick()

            if RBState.AutoSwitch and (now - RBSwitchCooldown) > 0.15 then
                if not equippedGun then
                    local guns = RBGetAllGuns()
                    for _, gun in pairs(guns) do
                        local ammo = gun:GetAttribute("CurrentAmmo") or 0
                        if ammo > 0 then
                            humanoid:EquipTool(gun)
                            RBSwitchCooldown = now
                            equippedGun = gun
                            break
                        end
                    end
                elseif (equippedGun:GetAttribute("CurrentAmmo") or 0) <= 0 then
                    local stored = equippedGun:GetAttribute("StoredAmmo") or 0
                    if RBState.AutoReload and stored > 0 and not equippedGun:GetAttribute("IsReloading") then
                        keypress(0x52)
                        task.defer(keyrelease, 0x52)
                        return
                    end

                    if stored <= 0 then
                        local guns = RBGetAllGuns()
                        for _, gun in pairs(guns) do
                            if gun == equippedGun then continue end
                            local ammo = gun:GetAttribute("CurrentAmmo") or 0
                            if ammo > 0 then
                                humanoid:EquipTool(gun)
                                RBSwitchCooldown = now
                                equippedGun = gun
                                break
                            end
                        end
                    end
                end
            end

            if not equippedGun then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end

            local ammo = equippedGun:GetAttribute("CurrentAmmo") or 0
            if ammo <= 0 then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end

            if equippedGun:GetAttribute("IsReloading") then
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
                return
            end

            local fireRate = equippedGun:GetAttribute("FireRate") or 0.1
            if (now - RBLastFireTick) < fireRate then return end

            local muzzlePos = RBGetMuzzlePosition(equippedGun)
            if not muzzlePos then return end

            local target = RBFindBestTarget(muzzlePos, equippedGun)
            if target then
                RagebotForcedTarget = target
                RagebotMuzzleOrigin = muzzlePos
                RBLastFireTick = now
                mouse1click()
            else
                RagebotForcedTarget = nil
                RagebotMuzzleOrigin = nil
            end
        end)
    end

    local OriginalUnload = Library.Unload
    Library.Unload = function(self)
        for i = #CleanupCallbacks, 1, -1 do
            pcall(CleanupCallbacks[i])
        end
        for _, drawing in ipairs(TrackedDrawings) do
            pcall(drawing.Remove, drawing)
        end
        CleanupCallbacks = {}
        TrackedDrawings = {}
        OriginalUnload(self)
    end
end
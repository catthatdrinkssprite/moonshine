local Library = loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/libraries/scoot/Library.lua"))()

local Window = Library:Window({
    Logo = getcustomasset("moonshineimages/moon.png"),
    FadeTime = 0.3,
})

local Watermark = Library:Watermark("moonshine | 155615604.lua")
local KeybindList = Library:KeybindList()

do
    local CombatPage = Window:Page({Name = "Combat", SubPages = true})
    local VisualsPage = Window:Page({Name = "Visuals", SubPages = true})
    local WorldPage = Window:Page({Name = "World", Columns = 2})
    local MiscPage = Window:Page({Name = "Misc", Columns = 2})
    local SettingsPage = Library:CreateSettingsPage(Window, Watermark, KeybindList)

    do
        local GunModsSubPage = CombatPage:SubPage({Name = "Gun Mods", Columns = 2})

        do
            local NoFireRate = GunModsSubPage:Section({Name = "No Fire Rate", Side = 1}) do
                local Enabled = NoFireRate:Toggle({
                    Name = "Enabled",
                    Flag = "NoFireRateEnabled",
                    Default = false,
                    Callback = function(callback)
                        if callback == true then
                            Library:Notification("Warning.", "It is recommended to use 60 FPS or below unless you want your bullets to come instantly.", 5)
                            Library:Notification("Notice.", "Mods will go away on new guns upon disabling.", 5)
                        end
                    end
                }) do
                    game.RunService.RenderStepped:Connect(function()
                        for _, tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                            if Enabled:Get() == true and tool:IsA("Tool") and tool:GetAttribute("FireRate") ~= nil then
                                tool:SetAttribute("FireRate", 0)
                            end
                        end
                    end)
                end
            end

            local NoSpread = GunModsSubPage:Section({Name = "No Spread", Side = 2}) do
                local Enabled = NoSpread:Toggle({
                    Name = "Enabled",
                    Flag = "NoSpreadEnabled",
                    Default = false,
                    Callback = function(callback)
                        if callback == true then
                            Library:Notification("Notice.", "Mods will go away on new guns upon disabling.", 5)
                        end
                    end
                }) do
                    game.RunService.RenderStepped:Connect(function()
                        for _, tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                            if Enabled:Get() == true and tool:IsA("Tool") and tool:GetAttribute("SpreadRadius") ~= nil then
                                tool:SetAttribute("SpreadRadius", 0)
                            end
                        end
                    end)
                end
            end

            local ForceAutoFire = GunModsSubPage:Section({Name = "Force Auto Fire", Side = 1}) do
                local Enabled = ForceAutoFire:Toggle({
                    Name = "Enabled",
                    Flag = "ForceAutoFireEnabled",
                    Default = false,
                    Callback = function(callback)
                        if callback == true then
                            Library:Notification("Notice.", "Mods will go away on new guns upon disabling.", 5)
                        end
                    end
                }) do
                    game.RunService.RenderStepped:Connect(function()
                        for _, tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                            if Enabled:Get() == true and tool:IsA("Tool") and tool:GetAttribute("AutoFire") ~= nil then
                                tool:SetAttribute("AutoFire", true)
                            end
                        end
                    end)
                end
            end
        end
    end

    do
        local AimbotSubPage = CombatPage:SubPage({Name = "Aimbot", Columns = 2})

        do
            local SilentAimSection = AimbotSubPage:Section({Name = "Silent Aim", Side = 1}) do
                local SilentAimEnabled = SilentAimSection:Toggle({
                    Name = "Enabled",
                    Flag = "SilentAimEnabled",
                    Default = false
                })

                local FoVCircleEnabled = SilentAimSection:Toggle({
                    Name = "FoV Circle",
                    Flag = "SilentAimFoVEnabled",
                    Default = false
                })

                local TracerEnabled = SilentAimSection:Toggle({
                    Name = "Tracer",
                    Flag = "SilentAimTracerEnabled",
                    Default = false
                })

                local Radius = SilentAimSection:Slider({
                    Name = "Radius",
                    Flag = "SilentAimRadius",
                    Min = 1,
                    Suffix = "px",
                    Max = 500,
                    Default = 130,
                    Decimals = 1
                })

                local Bone = SilentAimSection:Dropdown({
                    Name = "Bone",
                    Flag = "SilentAimBone",
                    Default = "Head",
                    Multi = false,
                    Items = {"Head", "HumanoidRootPart"}
                })

                local WallCheck = SilentAimSection:Toggle({
                    Name = "Wall Check",
                    Flag = "SilentAimWallCheck",
                    Default = false
                })

                local TeamCheck = SilentAimSection:Toggle({
                    Name = "Team Check",
                    Flag = "SilentAimTeamCheck",
                    Default = false
                })

                local DeathCheck = SilentAimSection:Toggle({
                    Name = "Death Check",
                    Flag = "SilentAimDeathCheck",
                    Default = true
                }) do
                    local Camera = workspace.CurrentCamera
                    local Players = game:GetService("Players")
                    local LocalPlayer = Players.LocalPlayer
                    local UserInputService = game:GetService("UserInputService")

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

                    local function getClosestPlayer()
                        local closestPart = nil
                        local closestDist = Radius:Get()
                        local mousePos = UserInputService:GetMouseLocation()
                        local boneName = Bone:Get()

                        for _, player in pairs(Players:GetPlayers()) do
                            if player == LocalPlayer then continue end

                            local character = player.Character
                            if not character then continue end

                            local humanoid = character:FindFirstChild("Humanoid")
                            if DeathCheck:Get() == true and (not humanoid or humanoid.Health <= 0) then continue end

                            if TeamCheck:Get() == true and player.Team == LocalPlayer.Team then continue end

                            local targetPart = character:FindFirstChild(boneName)
                            if not targetPart then continue end

                            if WallCheck:Get() == true then
                                local localChar = LocalPlayer.Character
                                if localChar then
                                    local parts = Camera:GetPartsObscuringTarget({targetPart.Position}, {localChar, character})
                                    if #parts > 0 then continue end
                                end
                            end

                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if not onScreen then continue end

                            local dist = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closestPart = targetPart
                            end
                        end

                        return closestPart
                    end

                    game.RunService.RenderStepped:Connect(function()
                        Camera = workspace.CurrentCamera
                        local mousePos = UserInputService:GetMouseLocation()

                        FoVCircle.Position = mousePos
                        FoVCircle.Radius = Radius:Get()
                        FoVCircle.Color = Library.Theme.Accent
                        FoVCircle.Visible = (SilentAimEnabled:Get() == true and FoVCircleEnabled:Get() == true)

                        if SilentAimEnabled:Get() == true and TracerEnabled:Get() == true then
                            local target = getClosestPlayer()
                            if target then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                                if onScreen then
                                    Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
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
                    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        local args = {...}

                        if not checkcaller() and self == workspace and SilentAimEnabled:Get() == true then
                            if method == "Raycast" then
                                local origin = args[1]
                                local target = getClosestPlayer()
                                if target then
                                    args[2] = (target.Position - origin).Unit * 1000
                                    return oldNamecall(self, unpack(args))
                                end
                            elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
                                local ray = args[1]
                                local target = getClosestPlayer()
                                if target then
                                    args[1] = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * 1000)
                                    return oldNamecall(self, unpack(args))
                                end
                            end
                        end

                        return oldNamecall(self, ...)
                    end))
                end
            end
        end
    end
    
    do
        local ESPSubPage = VisualsPage:SubPage({Name = "ESP", Columns = 2})

        do
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

                            local Render = game.RunService.RenderStepped:Connect(function()
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                                if onscreen then
                                    Text.Position = Vector2.new(pos.X, pos.Y)
                                    Text.Text = Character.Name
                                    if ShowSelf:Get() == true then
                                        Text.Visible = Enabled:Get()
                                    else
                                        if Character ~= game.Players.LocalPlayer.Character then
                                            Text.Visible = Enabled:Get()
                                        else
                                            Text.Visible = false
                                        end
                                    end
                                    if TeamColor:Get() == true then
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

                            local Render = game.RunService.RenderStepped:Connect(function()
                                local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                                if onscreen then
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
                                    if TeamColor:Get() == true then
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
        local CharacterSubPage = VisualsPage:SubPage({Name = "Character", Columns = 2})

        do
            local ForceFieldCharacter = CharacterSubPage:Section({Name = "Force Field Character", Side = 1}) do
                local Enabled = ForceFieldCharacter:Toggle({
                    Name = "Enabled",
                    Flag = "ForceFieldCharacterEnabled",
                    Default = false
                }) do
                    game.RunService.RenderStepped:Connect(function()
                        for _, limb in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                            if limb:IsA("BasePart") then
                                if Enabled:Get() == true then
                                    limb.Material = Enum.Material.ForceField
                                else
                                    limb.Material = Enum.Material.Plastic
                                end
                            end
                        end
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
                game.RunService.RenderStepped:Connect(function()
                    game.Players.LocalPlayer.Character.AntiJump.Disabled = Enabled:Get()
                end)
            end
        end
    end
end
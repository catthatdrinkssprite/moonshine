local Library = loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/libraries/scoot/Library.lua"))()

local Window = Library:Window({
    Logo = getcustomasset("moonshineimages/moon.png"),
    FadeTime = 0.3,
})

local Watermark = Library:Watermark("moonshine | 155615604.lua")
local KeybindList = Library:KeybindList()

do
    local VisualsPage = Window:Page({Name = "Visuals", SubPages = true})
    local SettingsPage = Library:CreateSettingsPage(Window, Watermark, KeybindList)

    do
        local ESPSubPage = VisualsPage:SubPage({Name = "ESP", Columns = 2})

        do
            local NameESP = ESPSubPage:Section({Name = "Name ESP", Side = 1}) do
                local Enabled = NameESP:Toggle({
                    Name = "Enabled",
                    Flag = "NameESPEnabled",
                    Default = false
                })

                local TeamColors = NameESP:Toggle({
                    Name = "Team Colors",
                    Flag = "NameESPTeamColors",
                    Default = true
                })

                local Color = Enabled:Colorpicker({
                    Name = "Color",
                    Flag = "NameESPColor",
                    Default = Library.Theme.Accent,
                    Alpha = 0
                })

                local function ApplyNameESP(Character)
                    if game:GetService("Players"):GetPlayerFromCharacter(Character) then
                        local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
                        local Text = Drawing.new("Text")
                        Text.Visible = false
                        Text.Size = 12
                        Text.Center = true
                        Text.Outline = true
                        Text.OutlineColor = Color3.fromRGB(0, 0, 0)

                        local Render = game:GetService("RunService").RenderStepped:Connect(function()
                            if TeamColors:Get() == true then
                                Text.Color = Player.TeamColor.Color
                            else
                                Text.Color = Color:Get()
                            end
                            
                            local pos, onscreen = workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                            if onscreen then
                                Text.Position = Vector2.new(pos.X, pos.Y)
                                Text.Text = Character.Name
                                Text.Visible = Enabled:Get()
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

                for _, v in pairs(workspace:GetChildren()) do
                    ApplyNameESP(v)
                end

                workspace.ChildAdded:Connect(ApplyNameESP)
            end
        end
    end
end
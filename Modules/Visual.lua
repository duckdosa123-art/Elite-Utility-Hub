-- Visuals.lua - Elite-Utility-Hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Tab Check
local Tab = _G.VisualTab
if not Tab then return warn("Elite-Hub: VisualTab not found!") end

-- [ ELITE GLOBAL SETTINGS ]
_G.ESPSettings = {
    Enabled = false,
    Box3D = false,
    Tracers = false,
    Names = false,
    Outline = false,
    LookLines = false,
    HealthBars = false,
    Distance = false,
    -- World
    Fullbright = false,
    NoFog = false,
    -- Local
    FOV = 70,
    VMTrans = 0,
    ThirdPerson = false,
    -- Aesthetic
    Rainbow = false,
    Crosshair = false,
    -- Colors
    BoxColor = Color3.fromRGB(200, 50, 50),
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    FillColor = Color3.fromRGB(200, 50, 50),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    CrossColor = Color3.fromRGB(0, 255, 0)
}

-- [ HELPER: 3D BOX MATH ]
local function GetBoxPoints(cframe, size)
    local x, y, z = size.X/2, size.Y/2, size.Z/2
    return {
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x,  y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x,  y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x, -y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x, -y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x,  y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x,  y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x, -y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x, -y, -z)).Position)
    }
end

-- [ RAINBOW ENGINE ]
task.spawn(function()
    while true do
        if _G.ESPSettings.Rainbow then
            local hue = tick() % 5 / 5
            local color = Color3.fromHSV(hue, 1, 1)
            _G.ESPSettings.BoxColor = color
            _G.ESPSettings.FillColor = color
            _G.ESPSettings.TracerColor = color
        end
        task.wait()
    end
end)

-- [ CROSSHAIR ENGINE ]
local CH_Vertical = Drawing.new("Line")
local CH_Horizontal = Drawing.new("Line")
RunService.RenderStepped:Connect(function()
    local enabled = _G.ESPSettings.Crosshair
    CH_Vertical.Visible = enabled
    CH_Horizontal.Visible = enabled
    if enabled then
        local center = Camera.ViewportSize / 2
        CH_Vertical.From = center - Vector2.new(0, 10)
        CH_Vertical.To = center + Vector2.new(0, 10)
        CH_Vertical.Color = _G.ESPSettings.CrossColor
        CH_Horizontal.From = center - Vector2.new(10, 0)
        CH_Horizontal.To = center + Vector2.new(10, 0)
        CH_Horizontal.Color = _G.ESPSettings.CrossColor
    end
end)

-- [ ESP ENGINE ]
local function CreateESP(Player)
    local Lines = {}
    for i = 1, 12 do Lines[i] = Drawing.new("Line") Lines[i].Thickness = 1 Lines[i].Visible = false end
    
    local Tracer = Drawing.new("Line")
    local LookLine = Drawing.new("Line")
    local HealthBar = Drawing.new("Line")
    local Name = Drawing.new("Text")

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            -- Outline Logic
            if _G.ESPSettings.Enabled and _G.ESPSettings.Outline and char then
                local highlight = char:FindFirstChild("EliteHighlight") or Instance.new("Highlight", char)
                highlight.Name = "EliteHighlight"
                highlight.FillColor = _G.ESPSettings.FillColor
                highlight.OutlineColor = _G.ESPSettings.OutlineColor
                highlight.FillTransparency = _G.ESPSettings.FillTrans
                highlight.OutlineTransparency = _G.ESPSettings.OutlineTrans
                highlight.Enabled = true
            elseif char and char:FindFirstChild("EliteHighlight") then
                char.EliteHighlight.Enabled = false
            end

            -- ESP Logic
            if _G.ESPSettings.Enabled and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    -- 3D Box
                    if _G.ESPSettings.Box3D then
                        local pts = GetBoxPoints(root.CFrame, Vector3.new(4, 5, 2))
                        local conn = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
                        for i, c in pairs(conn) do
                            Lines[i].From, Lines[i].To = Vector2.new(pts[c[1]].X, pts[c[1]].Y), Vector2.new(pts[c[2]].X, pts[c[2]].Y)
                            Lines[i].Color = _G.ESPSettings.BoxColor
                            Lines[i].Visible = true
                        end
                    else for i=1,12 do Lines[i].Visible = false end end

                    -- Look Line
                    if _G.ESPSettings.LookLines and head then
                        local startP = Camera:WorldToViewportPoint(head.Position)
                        local endP = Camera:WorldToViewportPoint(head.Position + (head.CFrame.LookVector * 5))
                        LookLine.From, LookLine.To = Vector2.new(startP.X, startP.Y), Vector2.new(endP.X, endP.Y)
                        LookLine.Color = Color3.new(1,1,1)
                        LookLine.Visible = true
                    else LookLine.Visible = false end

                    -- Health Bar
                    if _G.ESPSettings.HealthBars then
                        local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(2.5, 2.5, 0))
                        local top = Camera:WorldToViewportPoint(root.Position - Vector3.new(2.5, -2.5, 0))
                        local healthPerc = hum.Health / hum.MaxHealth
                        HealthBar.From = Vector2.new(bottom.X, bottom.Y)
                        HealthBar.To = Vector2.new(bottom.X, bottom.Y - ((bottom.Y - top.Y) * healthPerc))
                        HealthBar.Color = Color3.fromHSV(healthPerc * 0.3, 1, 1) -- Red to Green
                        HealthBar.Thickness = 2
                        HealthBar.Visible = true
                    else HealthBar.Visible = false end

                    -- Text (Name & Distance)
                    Name.Visible = _G.ESPSettings.Names
                    local dist = _G.ESPSettings.Distance and math.floor((root.Position - LP.Character.HumanoidRootPart.Position).Magnitude) or ""
                    Name.Text = Player.Name .. (dist ~= "" and " ["..dist.."s]" or "")
                    Name.Position = Vector2.new(pos.X, pos.Y - 45)
                    Name.Color = _G.ESPSettings.NameColor
                    Name.Center, Name.Outline = true, true
                else
                    for i=1,12 do Lines[i].Visible = false end
                    LookLine.Visible, HealthBar.Visible, Name.Visible = false, false, false
                end
            else
                for i=1,12 do Lines[i].Visible = false end
                LookLine.Visible, HealthBar.Visible, Name.Visible = false, false, false
                if not Player.Parent then Connection:Disconnect() end
            end
        end)
    end
    task.spawn(Update)
end

-- World & Local Handlers
RunService.RenderStepped:Connect(function()
    if _G.ESPSettings.Fullbright then Lighting.Ambient = Color3.new(1,1,1) Lighting.OutdoorAmbient = Color3.new(1,1,1) end
    if _G.ESPSettings.NoFog then Lighting.FogEnd = 1000000 end
    Camera.FieldOfView = _G.ESPSettings.FOV
    if _G.ESPSettings.ThirdPerson then LP.CameraMaxZoomDistance = 50 LP.CameraMinZoomDistance = 50 else LP.CameraMaxZoomDistance = 128 LP.CameraMinZoomDistance = 0.5 end
    
    -- Viewmodel
    for _, v in pairs(Camera:GetChildren()) do
        if v:IsA("Model") then
            for _, p in pairs(v:GetDescendants()) do
                if p:IsA("BasePart") then p.Transparency = _G.ESPSettings.VMTrans end
            end
        end
    end
end)

-- Init Players
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- [ UI CONSTRUCTION ]
Tab:CreateSection("Tactical ESP")
Tab:CreateToggle({Name = "Master Enable", Callback = function(V) _G.ESPSettings.Enabled = V end})
Tab:CreateToggle({Name = "3D Hitbox", Callback = function(V) _G.ESPSettings.Box3D = V end})
Tab:CreateToggle({Name = "Look Direction", Callback = function(V) _G.ESPSettings.LookLines = V end})
Tab:CreateToggle({Name = "Dynamic Health", Callback = function(V) _G.ESPSettings.HealthBars = V end})
Tab:CreateToggle({Name = "Distance", Callback = function(V) _G.ESPSettings.Distance = V end})

Tab:CreateSection("World Hacks")
Tab:CreateToggle({Name = "Fullbright", Callback = function(V) _G.ESPSettings.Fullbright = V end})
Tab:CreateToggle({Name = "No Fog", Callback = function(V) _G.ESPSettings.NoFog = V end})

Tab:CreateSection("Local Player")
Tab:CreateSlider({Name = "FOV Changer", Range = {70, 120}, Increment = 1, Callback = function(V) _G.ESPSettings.FOV = V end})
Tab:CreateSlider({Name = "Viewmodel Trans", Range = {0, 1}, Increment = 0.1, Callback = function(V) _G.ESPSettings.VMTrans = V end})
Tab:CreateToggle({Name = "Force Third Person", Callback = function(V) _G.ESPSettings.ThirdPerson = V end})

Tab:CreateSection("Aesthetic")
Tab:CreateToggle({Name = "Rainbow RGB Mode", Callback = function(V) _G.ESPSettings.Rainbow = V end})
Tab:CreateToggle({Name = "Center Crosshair", Callback = function(V) _G.ESPSettings.Crosshair = V end})
Tab:CreateColorPicker({Name = "Crosshair Color", Color = Color3.new(0,1,0), Callback = function(V) _G.ESPSettings.CrossColor = V end})

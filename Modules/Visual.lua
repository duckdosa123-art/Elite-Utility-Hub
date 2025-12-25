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
    Breadcrumbs = false,
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
    CrossColor = Color3.fromRGB(0, 255, 0),
    -- Transparencies
    FillTrans = 0.5,
    OutlineTrans = 0
    -- [ CACHE ORIGINAL LIGHTING ]
    local LightingDefaults = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
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
            local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            _G.ESPSettings.BoxColor = color
            _G.ESPSettings.FillColor = color
            _G.ESPSettings.TracerColor = color
        end
        task.wait()
    end
end)

-- [ CROSSHAIR ENGINE ]
local CH_V = Drawing.new("Line")
local CH_H = Drawing.new("Line")
RunService.RenderStepped:Connect(function()
    local enabled = _G.ESPSettings.Crosshair
    CH_V.Visible, CH_H.Visible = enabled, enabled
    if enabled then
        local center = Camera.ViewportSize / 2
        CH_V.From, CH_V.To = center - Vector2.new(0, 10), center + Vector2.new(0, 10)
        CH_H.From, CH_H.To = center - Vector2.new(10, 0), center + Vector2.new(10, 0)
        CH_V.Color, CH_H.Color = _G.ESPSettings.CrossColor, _G.ESPSettings.CrossColor
    end
end)

-- [ ESP ENGINE ]
local function CreateESP(Player)
    local Lines = {}
    for i = 1, 12 do Lines[i] = Drawing.new("Line") Lines[i].Thickness = 1 end
    
    local Tracer = Drawing.new("Line")
    local LookLine = Drawing.new("Line")
    local HealthBar = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
    -- Breadcrumbs (Trails)
    local BreadcrumbLines = {}
    local Positions = {}
    for i = 1, 10 do BreadcrumbLines[i] = Drawing.new("Line") BreadcrumbLines[i].Thickness = 1 end

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")

            -- Outline (Highlight) Logic
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

            -- Main ESP Graphics
            if _G.ESPSettings.Enabled and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                -- Breadcrumbs Logic (Trails)
                if _G.ESPSettings.Breadcrumbs then
                    table.insert(Positions, 1, root.Position)
                    if #Positions > 11 then table.remove(Positions) end
                    for i = 1, #Positions - 1 do
                        local p1, on1 = Camera:WorldToViewportPoint(Positions[i])
                        local p2, on2 = Camera:WorldToViewportPoint(Positions[i+1])
                        if on1 and on2 then
                            BreadcrumbLines[i].From = Vector2.new(p1.X, p1.Y)
                            BreadcrumbLines[i].To = Vector2.new(p2.X, p2.Y)
                            BreadcrumbLines[i].Color = _G.ESPSettings.BoxColor
                            BreadcrumbLines[i].Visible = true
                        else BreadcrumbLines[i].Visible = false end
                    end
                else for i=1,10 do BreadcrumbLines[i].Visible = false end end

                if onScreen then
                    -- 3D Box
                    if _G.ESPSettings.Box3D then
                        local pts = GetBoxPoints(root.CFrame, Vector3.new(4, 5, 2))
                        local conn = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
                        for i, c in pairs(conn) do
                            Lines[i].From, Lines[i].To = Vector2.new(pts[c[1]].X, pts[c[1]].Y), Vector2.new(pts[c[2]].X, pts[c[2]].Y)
                            Lines[i].Color, Lines[i].Visible = _G.ESPSettings.BoxColor, true
                        end
                    else for i=1,12 do Lines[i].Visible = false end end

                    -- Look Line
                    if _G.ESPSettings.LookLines and head then
                        local endP = Camera:WorldToViewportPoint(head.Position + (head.CFrame.LookVector * 6))
                        LookLine.From, LookLine.To = Vector2.new(pos.X, pos.Y - 20), Vector2.new(endP.X, endP.Y)
                        LookLine.Color, LookLine.Visible = Color3.new(1,1,1), true
                    else LookLine.Visible = false end

                    -- Dynamic Health Bar
                    if _G.ESPSettings.HealthBars then
                        local healthPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barColor = Color3.fromHSV(healthPerc * 0.3, 1, 1) -- Red to Green
                        HealthBar.From = Vector2.new(pos.X - 35, pos.Y + 30)
                        HealthBar.To = Vector2.new(pos.X - 35, pos.Y + 30 - (60 * healthPerc))
                        HealthBar.Color, HealthBar.Thickness, HealthBar.Visible = barColor, 3, true
                    else HealthBar.Visible = false end

                    -- Name/Distance Text
                    Name.Visible = _G.ESPSettings.Names
                    local distText = ""
                    
                    if _G.ESPSettings.Distance then
                        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local d = math.floor((root.Position - myRoot.Position).Magnitude)
                            distText = " [" .. tostring(d) .. " studs]"
                        end
                    end
                    
                    Name.Text = Player.Name .. distText
                    Name.Position = Vector2.new(pos.X, pos.Y - 55)
                    Name.Color, Name.Center, Name.Outline = _G.ESPSettings.NameColor, true, true
                else
                    for i=1,12 do Lines[i].Visible = false end
                    LookLine.Visible, HealthBar.Visible, Name.Visible = false, false, false
                end
            else
                for i=1,12 do Lines[i].Visible = false end
                for i=1,10 do BreadcrumbLines[i].Visible = false end
                LookLine.Visible, HealthBar.Visible, Name.Visible = false, false, false
                if not Player.Parent then Connection:Disconnect() end
            end
        end)
    end
    task.spawn(Update)
end

-- Init All Players
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- World/Local Update Logic (Fixed Toggles)
RunService.RenderStepped:Connect(function()
    -- Fullbright Toggle
    if _G.ESPSettings.Fullbright then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = LightingDefaults.Ambient
        Lighting.OutdoorAmbient = LightingDefaults.OutdoorAmbient
        Lighting.GlobalShadows = LightingDefaults.GlobalShadows
    end

    -- No Fog Toggle
    if _G.ESPSettings.NoFog then
        Lighting.FogEnd = 1e7
        Lighting.FogStart = 1e7
    else
        Lighting.FogEnd = LightingDefaults.FogEnd
        Lighting.FogStart = LightingDefaults.FogStart
    end

    -- Camera & Local Logic
    Camera.FieldOfView = _G.ESPSettings.FOV
    if _G.ESPSettings.ThirdPerson then 
        LP.CameraMaxZoomDistance = 30 
        LP.CameraMinZoomDistance = 30 
    else 
        LP.CameraMaxZoomDistance = 128 
        LP.CameraMinZoomDistance = 0.5 
    end
end)
    
    -- Viewmodel Transparency
    for _, v in pairs(Camera:GetChildren()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            for _, part in pairs(v:GetDescendants()) do
                if part:IsA("BasePart") then part.Transparency = _G.ESPSettings.VMTrans end
            end
        end
    end
end)

-- [ UI CONSTRUCTION ]
Tab:CreateSection("Tactical Combat")
Tab:CreateToggle({Name = "Master Enable", Callback = function(V) _G.ESPSettings.Enabled = V end})
Tab:CreateToggle({Name = "3D Box (Hitbox)", Callback = function(V) _G.ESPSettings.Box3D = V end})
Tab:CreateToggle({Name = "Look Direction Lines", Callback = function(V) _G.ESPSettings.LookLines = V end})
Tab:CreateToggle({Name = "Dynamic Health Bar", Callback = function(V) _G.ESPSettings.HealthBars = V end})
Tab:CreateToggle({Name = "Show Distance", Callback = function(V) _G.ESPSettings.Distance = V end})
Tab:CreateToggle({Name = "Breadcrumbs (Trails)", Callback = function(V) _G.ESPSettings.Breadcrumbs = V end})

Tab:CreateSection("Map & Environment")
Tab:CreateToggle({Name = "Fullbright (No Shadows)", Callback = function(V) _G.ESPSettings.Fullbright = V end})
Tab:CreateToggle({Name = "No Fog / Infinite Render", Callback = function(V) _G.ESPSettings.NoFog = V end})

Tab:CreateSection("Local Enhancements")
Tab:CreateSlider({Name = "FOV Changer", Range = {70, 120}, Increment = 1, CurrentValue = 70, Callback = function(V) _G.ESPSettings.FOV = V end})
Tab:CreateSlider({Name = "Viewmodel Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0, Callback = function(V) _G.ESPSettings.VMTrans = V end})
Tab:CreateToggle({Name = "Force Third Person", Callback = function(V) _G.ESPSettings.ThirdPerson = V end})

Tab:CreateSection("Elite Aesthetic")
Tab:CreateToggle({Name = "Cartoon Outline", Callback = function(V) _G.ESPSettings.Outline = V end})
Tab:CreateToggle({Name = "Rainbow RGB Mode", Callback = function(V) _G.ESPSettings.Rainbow = V end})
Tab:CreateToggle({Name = "Center Crosshair", Callback = function(V) _G.ESPSettings.Crosshair = V end})
Tab:CreateColorPicker({Name = "Crosshair Color", Color = Color3.new(0,1,0), Callback = function(V) _G.ESPSettings.CrossColor = V end})

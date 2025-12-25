-- Visual.lua - Elite-Utility-Hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Tab Check
local Tab = _G.VisualTab
if not Tab then return warn("Elite-Hub: VisualTab not found!") end

-- [ CACHE ORIGINAL LIGHTING ]
local LightingDefaults = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart
    MaxZoom = LP.CameraMaxZoomDistance,
    MinZoom = LP.CameraMinZoomDistance
}

-- [ ELITE GLOBAL SETTINGS ]
_G.ESPSettings = {
    Enabled = false,
    Box3D = false,
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
    NameColor = Color3.fromRGB(255, 255, 255),
    FillColor = Color3.fromRGB(200, 50, 50),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    CrossColor = Color3.fromRGB(0, 255, 0),
    FillTrans = 0.5,
    OutlineTrans = 0
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

-- [ ENGINE: RAINBOW ]
task.spawn(function()
    while true do
        if _G.ESPSettings.Rainbow then
            local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            _G.ESPSettings.BoxColor = color
            _G.ESPSettings.FillColor = color
        end
        task.wait()
    end
end)

-- [ ENGINE: CROSSHAIR ]
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

-- [ ELITE ESP ENGINE - FULLY FIXED ]
local function CreateESP(Player)
    -- Initialize Drawing Objects
    local Lines = {}
    for i = 1, 12 do Lines[i] = Drawing.new("Line") Lines[i].Thickness = 1 Lines[i].Visible = false end
    local LookLine = Drawing.new("Line")
    local HealthBar = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
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

            -- 1. Outline Feature (Highlight)
            if _G.ESPSettings.Enabled and _G.ESPSettings.Outline and char then
                local hl = char:FindFirstChild("EliteHighlight") or Instance.new("Highlight", char)
                hl.Name = "EliteHighlight"
                hl.FillColor, hl.OutlineColor = _G.ESPSettings.FillColor, _G.ESPSettings.OutlineColor
                hl.FillTransparency, hl.OutlineTransparency = _G.ESPSettings.FillTrans, _G.ESPSettings.OutlineTrans
                hl.Enabled = true
            elseif char and char:FindFirstChild("EliteHighlight") then
                char.EliteHighlight.Enabled = false
            end

            -- 2. Main ESP Logic
            if _G.ESPSettings.Enabled and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                -- Breadcrumbs (Trails)
                if _G.ESPSettings.Breadcrumbs then
                    table.insert(Positions, 1, root.Position)
                    if #Positions > 11 then table.remove(Positions) end
                    for i = 1, #Positions - 1 do
                        local p1, on1 = Camera:WorldToViewportPoint(Positions[i])
                        local p2, on2 = Camera:WorldToViewportPoint(Positions[i+1])
                        if on1 and on2 then
                            BreadcrumbLines[i].From, BreadcrumbLines[i].To = Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y)
                            BreadcrumbLines[i].Color, BreadcrumbLines[i].Visible = _G.ESPSettings.BoxColor, true
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

                    -- Look Direction Line
                    if _G.ESPSettings.LookLines and head then
                        local endP = Camera:WorldToViewportPoint(head.Position + (head.CFrame.LookVector * 6))
                        LookLine.From, LookLine.To = Vector2.new(pos.X, pos.Y), Vector2.new(endP.X, endP.Y)
                        LookLine.Color, LookLine.Visible = Color3.new(1,1,1), true
                    else LookLine.Visible = false end

                    -- Health Bar
                    if _G.ESPSettings.HealthBars then
                        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        HealthBar.From = Vector2.new(pos.X - 35, pos.Y + 30)
                        HealthBar.To = Vector2.new(pos.X - 35, pos.Y + 30 - (60 * hp))
                        HealthBar.Color, HealthBar.Thickness, HealthBar.Visible = Color3.fromHSV(hp * 0.3, 1, 1), 3, true
                    else HealthBar.Visible = false end

                    -- [ FIXED NAME & DISTANCE - HEAD POSITION ]
                    if (_G.ESPSettings.Names or _G.ESPSettings.Distance) and head then
                        local hVPP, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        if hOn then
                            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local dText = ""
                            if _G.ESPSettings.Distance and myRoot then
                                dText = "\n[" .. math.floor((root.Position - myRoot.Position).Magnitude) .. " studs]"
                            end
                            Name.Text = (_G.ESPSettings.Names and Player.Name or "") .. dText
                            Name.Position = Vector2.new(hVPP.X, hVPP.Y)
                            Name.Color, Name.Visible, Name.Center, Name.Outline = _G.ESPSettings.NameColor, true, true, true
                        else Name.Visible = false end
                    else Name.Visible = false end
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
-- [ WORLD UPDATE LOOP ]
RunService.RenderStepped:Connect(function()
    if _G.ESPSettings.Fullbright then
        Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = Color3.new(1,1,1), Color3.new(1,1,1), false
    else
        Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = LightingDefaults.Ambient, LightingDefaults.OutdoorAmbient, LightingDefaults.GlobalShadows
    end
    if _G.ESPSettings.NoFog then
        Lighting.FogEnd, Lighting.FogStart = 1e7, 1e7
    else
        Lighting.FogEnd, Lighting.FogStart = LightingDefaults.FogEnd, LightingDefaults.FogStart
    end
    Camera.FieldOfView = _G.ESPSettings.FOV
    -- Fixed Third Person Toggle
    -- Fixed Third Person Toggle
    if _G.ESPSettings.ThirdPerson then 
        LP.CameraMaxZoomDistance = 30 
        LP.CameraMinZoomDistance = 30 
    else 
        LP.CameraMaxZoomDistance = LightingDefaults.MaxZoom
        LP.CameraMinZoomDistance = LightingDefaults.MinZoom
    end
    
    -- Viewmodel Transparency
    for _, v in pairs(Camera:GetChildren()) do
        if v:IsA("Model") or v:IsA("BasePart") then
            for _, p in pairs(v:GetDescendants()) do 
                if p:IsA("BasePart") then p.Transparency = _G.ESPSettings.VMTrans end 
            end
        end
    end
end)

-- Initialize Players
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- [ UI CONSTRUCTION ]
Tab:CreateSection("Tactical Combat")
Tab:CreateToggle({Name = "Master Enable", CurrentValue = false, Flag = "V_M", Callback = function(V) _G.ESPSettings.Enabled = V end})
Tab:CreateToggle({Name = "3D Hitbox", CurrentValue = false, Flag = "V_3B", Callback = function(V) _G.ESPSettings.Box3D = V end})
Tab:CreateToggle({Name = "Look Direction", CurrentValue = false, Flag = "V_LD", Callback = function(V) _G.ESPSettings.LookLines = V end})
Tab:CreateToggle({Name = "Dynamic Health Bar", CurrentValue = false, Flag = "V_HB", Callback = function(V) _G.ESPSettings.HealthBars = V end})
Tab:CreateToggle({Name = "Show Distance", CurrentValue = false, Flag = "V_SD", Callback = function(V) _G.ESPSettings.Distance = V end})
Tab:CreateToggle({Name = "Breadcrumbs (Trails)", CurrentValue = false, Flag = "V_BC", Callback = function(V) _G.ESPSettings.Breadcrumbs = V end})

Tab:CreateSection("Map & Environment")
Tab:CreateToggle({Name = "Fullbright", CurrentValue = false, Flag = "V_FB", Callback = function(V) _G.ESPSettings.Fullbright = V end})
Tab:CreateToggle({Name = "No Fog", CurrentValue = false, Flag = "V_NF", Callback = function(V) _G.ESPSettings.NoFog = V end})

Tab:CreateSection("Local Enhancements")
Tab:CreateSlider({Name = "FOV Changer", Range = {70, 120}, Increment = 1, CurrentValue = 70, Flag = "V_FOV", Callback = function(V) _G.ESPSettings.FOV = V end})
Tab:CreateSlider({Name = "VM Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0, Flag = "V_VM", Callback = function(V) _G.ESPSettings.VMTrans = V end})
Tab:CreateToggle({Name = "Force Third Person", CurrentValue = false, Flag = "V_TP", Callback = function(V) _G.ESPSettings.ThirdPerson = V end})

Tab:CreateSection("Elite Aesthetic")
Tab:CreateToggle({Name = "Cartoon Outline", CurrentValue = false, Flag = "V_OL", Callback = function(V) _G.ESPSettings.Outline = V end})
Tab:CreateToggle({Name = "Rainbow RGB Mode", CurrentValue = false, Flag = "V_RB", Callback = function(V) _G.ESPSettings.Rainbow = V end})
Tab:CreateToggle({Name = "Center Crosshair", CurrentValue = false, Flag = "V_CH", Callback = function(V) _G.ESPSettings.Crosshair = V end})
Tab:CreateColorPicker({Name = "Crosshair Color", Color = Color3.new(0,1,0), Flag = "V_CHC", Callback = function(V) _G.ESPSettings.CrossColor = V end})

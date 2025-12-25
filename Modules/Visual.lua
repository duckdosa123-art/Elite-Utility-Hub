-- Visuals.lua - Elite-Utility-Hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global Tab Check
local Tab = _G.VisualTab
if not Tab then
    warn("Elite-Hub: VisualTab not found! Ensure Main.lua is updated.")
    return
end

-- [ ELITE ESP SETTINGS ]
_G.ESPSettings = {
    Enabled = false,
    Box3D = false,
    Tracers = false,
    Names = false,
    Outline = false,
    -- Colors
    BoxColor = Color3.fromRGB(200, 50, 50),
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    -- Outline (Chams) Settings
    FillColor = Color3.fromRGB(200, 50, 50),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    FillTrans = 0.5,
    OutlineTrans = 0
}

-- [ 3D BOX MATH ]
local function GetBoxPoints(cframe, size)
    local x, y, z = size.X/2, size.Y/2, size.Z/2
    local points = {
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x,  y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x,  y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x, -y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x, -y,  z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x,  y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x,  y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new(-x, -y, -z)).Position),
        Camera:WorldToViewportPoint((cframe * CFrame.new( x, -y, -z)).Position)
    }
    return points
end

-- [ ESP ENGINE ]
local function CreateESP(Player)
    local Lines = {}
    for i = 1, 12 do
        Lines[i] = Drawing.new("Line")
        Lines[i].Thickness = 1
        Lines[i].Visible = false
    end

    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            -- Outline Logic (Highlight)
            if _G.ESPSettings.Enabled and _G.ESPSettings.Outline and char then
                local highlight = char:FindFirstChild("EliteHighlight") or Instance.new("Highlight")
                highlight.Name = "EliteHighlight"
                highlight.Parent = char
                highlight.Enabled = true
                highlight.FillColor = _G.ESPSettings.FillColor
                highlight.OutlineColor = _G.ESPSettings.OutlineColor
                highlight.FillTransparency = _G.ESPSettings.FillTrans
                highlight.OutlineTransparency = _G.ESPSettings.OutlineTrans
            elseif char and char:FindFirstChild("EliteHighlight") then
                char.EliteHighlight.Enabled = false
            end

            -- 3D Box & Text Logic
            if _G.ESPSettings.Enabled and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    if _G.ESPSettings.Box3D then
                        local points = GetBoxPoints(root.CFrame, Vector3.new(4, 5, 2))
                        local connect = {{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
                        for i, c in pairs(connect) do
                            local p1, p2 = points[c[1]], points[c[2]]
                            Lines[i].From, Lines[i].To = Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y)
                            Lines[i].Color = _G.ESPSettings.BoxColor
                            Lines[i].Visible = true
                        end
                    else
                        for i=1,12 do Lines[i].Visible = false end
                    end

                    Tracer.Visible = _G.ESPSettings.Tracers
                    Tracer.Color = _G.ESPSettings.TracerColor
                    Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)

                    Name.Visible = _G.ESPSettings.Names
                    Name.Text = Player.Name
                    Name.Color = _G.ESPSettings.NameColor
                    Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    Name.Center, Name.Outline = true, true
                else
                    for i=1,12 do Lines[i].Visible = false end
                    Tracer.Visible, Name.Visible = false, false
                end
            else
                for i=1,12 do Lines[i].Visible = false end
                Tracer.Visible, Name.Visible = false, false
                if not Player.Parent then
                    for i=1,12 do Lines[i]:Remove() end
                    Tracer:Remove(); Name:Remove(); Connection:Disconnect()
                end
            end
        end)
    end
    task.spawn(Update)
end

-- Init
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- [ UI CONSTRUCTION ]
Tab:CreateSection("ESP Master")

Tab:CreateToggle({
   Name = "Enable Visual System",
   CurrentValue = false,
   Callback = function(Value) _G.ESPSettings.Enabled = Value end,
})

Tab:CreateSection("3D Hitbox Settings")

Tab:CreateToggle({
   Name = "3D Box (Hitbox)",
   CurrentValue = false,
   Callback = function(Value) _G.ESPSettings.Box3D = Value end,
})

Tab:CreateColorPicker({
    Name = "Box Border Color",
    Color = _G.ESPSettings.BoxColor,
    Callback = function(Value) _G.ESPSettings.BoxColor = Value end
})

Tab:CreateSection("Cartoon Outline")

Tab:CreateToggle({
   Name = "Elite Outline",
   CurrentValue = false,
   Callback = function(Value) _G.ESPSettings.Outline = Value end,
})

Tab:CreateColorPicker({
    Name = "Fill Color",
    Color = _G.ESPSettings.FillColor,
    Callback = function(Value) _G.ESPSettings.FillColor = Value end
})

Tab:CreateSlider({
   Name = "Fill Transparency",
   Range = {0, 1},
   Increment = 0.1,
   CurrentValue = 0.5,
   Callback = function(Value) _G.ESPSettings.FillTrans = Value end,
})

Tab:CreateColorPicker({
    Name = "Outline Border Color",
    Color = _G.ESPSettings.OutlineColor,
    Callback = function(Value) _G.ESPSettings.OutlineColor = Value end
})

Tab:CreateSection("Other Visuals")

Tab:CreateToggle({
   Name = "Show Tracers",
   CurrentValue = false,
   Callback = function(Value) _G.ESPSettings.Tracers = Value end,
})

Tab:CreateToggle({
   Name = "Show Names",
   CurrentValue = false,
   Callback = function(Value) _G.ESPSettings.Names = Value end,
})

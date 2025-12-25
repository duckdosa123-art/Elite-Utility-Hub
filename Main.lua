-- Visuals.lua - Elite-Utility-Hub
local Tab = _G.VisualTab
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ ELITE ESP SETTINGS ]
_G.ESPSettings = {
    Enabled = false,
    Box3D = false,
    Tracers = false,
    Names = false,
    Outline = false,
    
    -- Colors
    BoxColor = Color3.fromRGB(200, 50, 50), -- Gentle Elite Red
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    
    -- Outline Settings
    FillColor = Color3.fromRGB(200, 50, 50),
    OutlineColor = Color3.fromRGB(0, 0, 0), -- Cartoon Black Outline
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

-- [ ELITE ESP ENGINE ]
local function CreateESP(Player)
    -- Drawing Objects for 3D Box (12 lines)
    local Lines = {}
    for i = 1, 12 do
        Lines[i] = Drawing.new("Line")
        Lines[i].Thickness = 1
        Lines[i].Visible = false
    end

    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
    Tracer.Visible = false
    Name.Visible = false

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            -- Update Highlight (Outline Feature)
            local highlight = char and char:FindFirstChild("EliteHighlight")
            if _G.ESPSettings.Enabled and _G.ESPSettings.Outline and char then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "EliteHighlight"
                    highlight.Parent = char
                end
                highlight.Enabled = true
                highlight.FillColor = _G.ESPSettings.FillColor
                highlight.OutlineColor = _G.ESPSettings.OutlineColor
                highlight.FillTransparency = _G.ESPSettings.FillTrans
                highlight.OutlineTransparency = _G.ESPSettings.OutlineTrans
            elseif highlight then
                highlight.Enabled = false
            end

            -- Update Drawing ESP
            if _G.ESPSettings.Enabled and char and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    -- 3D Box Logic
                    if _G.ESPSettings.Box3D then
                        local size = Vector3.new(4, 5, 2) -- Standard Hitbox Size
                        local points = GetBoxPoints(root.CFrame, size)
                        
                        local connections = {
                            {1,2}, {2,4}, {4,3}, {3,1}, -- Front
                            {5,6}, {6,8}, {8,7}, {7,5}, -- Back
                            {1,5}, {2,6}, {3,7}, {4,8}  -- Connectors
                        }

                        for i, conn in pairs(connections) do
                            local p1, p2 = points[conn[1]], points[conn[2]]
                            Lines[i].From = Vector2.new(p1.X, p1.Y)
                            Lines[i].To = Vector2.new(p2.X, p2.Y)
                            Lines[i].Color = _G.ESPSettings.BoxColor
                            Lines[i].Visible = true
                        end
                    else
                        for i=1,12 do Lines[i].Visible = false end
                    end

                    -- Tracer Logic
                    Tracer.Visible = _G.ESPSettings.Tracers
                    Tracer.Color = _G.ESPSettings.TracerColor
                    Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)

                    -- Name Logic
                    Name.Visible = _G.ESPSettings.Names
                    Name.Color = _G.ESPSettings.NameColor
                    Name.Text = Player.Name
                    Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    Name.Outline = true
                    Name.Center = true
                else
                    for i=1,12 do Lines[i].Visible = false end
                    Tracer.Visible = false
                    Name.Visible = false
                end
            else
                for i=1,12 do Lines[i].Visible = false end
                Tracer.Visible = false
                Name.Visible = false
                
                if not Player.Parent then
                    for i=1,12 do Lines[i]:Remove() end
                    Tracer:Remove()
                    Name:Remove()
                    Connection:Disconnect()
                end
            end
        end)
    end
    task.spawn(Update)
end

-- Init
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then CreateESP(p) end end)

-- [ UI ELEMENTS ]
Tab:CreateSection("Elite ESP Master")

Tab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESP_Master",
   Callback = function(Value) _G.ESPSettings.Enabled = Value end,
})

Tab:CreateSection("3D Visuals")

Tab:CreateToggle({
   Name = "3D Box (Hitbox)",
   CurrentValue = false,
   Flag = "ESP_Box3D",
   Callback = function(Value) _G.ESPSettings.Box3D = Value end,
})

Tab:CreateColorPicker({
    Name = "Box Border Color",
    Color = _G.ESPSettings.BoxColor,
    Callback = function(Value) _G.ESPSettings.BoxColor = Value end
})

Tab:CreateSection("Outline (Chams)")

Tab:CreateToggle({
   Name = "Elite Outline",
   CurrentValue = false,
   Flag = "ESP_Outline",
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
    Name = "Cartoon Outline Color",
    Color = _G.ESPSettings.OutlineColor,
    Callback = function(Value) _G.ESPSettings.OutlineColor = Value end
})

Tab:CreateSlider({
   Name = "Outline Transparency",
   Range = {0, 1},
   Increment = 0.1,
   CurrentValue = 0,
   Callback = function(Value) _G.ESPSettings.OutlineTrans = Value end,
})

Tab:CreateSection("Extra")
Tab:CreateToggle({Name = "Show Tracers", CurrentValue = false, Callback = function(V) _G.ESPSettings.Tracers = V end})
Tab:CreateToggle({Name = "Show Names", CurrentValue = false, Callback = function(V) _G.ESPSettings.Names = V end})

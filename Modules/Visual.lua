-- Visuals.lua - Elite-Utility-Hub
local Tab = _G.VisualTab
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ ESP SETTINGS ]
_G.ESPSettings = {
    Enabled = false,
    Boxes = false,
    Tracers = false,
    Names = false,
    BoxColor = Color3.fromRGB(255, 0, 0),
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255)
}

-- [ ELITE ESP ENGINE ]
local function CreateESP(Player)
    local Box = Drawing.new("Square")
    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if _G.ESPSettings.Enabled and char and root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    -- Calculate sizing
                    local sizeY = (Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.6, 0)).Y)
                    local boxSize = Vector2.new(sizeY / 1.5, sizeY)
                    local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

                    -- Box Logic
                    Box.Visible = _G.ESPSettings.Boxes
                    Box.Color = _G.ESPSettings.BoxColor
                    Box.Size = boxSize
                    Box.Position = boxPos

                    -- Tracer Logic
                    Tracer.Visible = _G.ESPSettings.Tracers
                    Tracer.Color = _G.ESPSettings.TracerColor
                    Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y + (boxSize.Y / 2))

                    -- Name Logic
                    Name.Visible = _G.ESPSettings.Names
                    Name.Color = _G.ESPSettings.NameColor
                    Name.Text = Player.Name
                    Name.Position = Vector2.new(pos.X, pos.Y - (boxSize.Y / 2) - 20)
                    Name.Outline = true
                    Name.Center = true
                else
                    Box.Visible = false
                    Tracer.Visible = false
                    Name.Visible = false
                end
            else
                Box.Visible = false
                Tracer.Visible = false
                Name.Visible = false
                
                if not Player.Parent then
                    Box:Remove()
                    Tracer:Remove()
                    Name:Remove()
                    Connection:Disconnect()
                end
            end
        end)
    end
    task.spawn(Update)
end

-- Init for current and new players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LP then CreateESP(p) end
end)

-- [ UI ELEMENTS ]

Tab:CreateSection("Elite ESP Master")

Tab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESP_Master",
   Callback = function(Value) _G.ESPSettings.Enabled = Value end,
})

Tab:CreateSection("ESP Customization")

Tab:CreateToggle({
   Name = "Show Boxes",
   CurrentValue = false,
   Flag = "ESP_Box",
   Callback = function(Value) _G.ESPSettings.Boxes = Value end,
})

Tab:CreateColorPicker({
    Name = "Box Color",
    Color = _G.ESPSettings.BoxColor,
    Callback = function(Value) _G.ESPSettings.BoxColor = Value end
})

Tab:CreateToggle({
   Name = "Show Tracers",
   CurrentValue = false,
   Flag = "ESP_Tracer",
   Callback = function(Value) _G.ESPSettings.Tracers = Value end,
})

Tab:CreateColorPicker({
    Name = "Tracer Color",
    Color = _G.ESPSettings.TracerColor,
    Callback = function(Value) _G.ESPSettings.TracerColor = Value end
})

Tab:CreateToggle({
   Name = "Show Names",
   CurrentValue = false,
   Flag = "ESP_Name",
   Callback = function(Value) _G.ESPSettings.Names = Value end,
})

Tab:CreateColorPicker({
    Name = "Name Color",
    Color = _G.ESPSettings.NameColor,
    Callback = function(Value) _G.ESPSettings.NameColor = Value end
})

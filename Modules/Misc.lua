-- Misc.lua - Elite-Utility-Hub
local Tab = _G.MiscTab
local LP = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- [ ANTI-AFK LOGIC ]
local _aafk = false
task.spawn(function()
    LP.Idled:Connect(function()
        if _aafk then
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- [ UI ELEMENTS ]

Tab:CreateSection("Server Utilities")

Tab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
       TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
   end,
})

Tab:CreateButton({
   Name = "Server Hop",
   Callback = function()
       -- Basic Server Hop Logic
       local Http = game:GetService("HttpService")
       local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
       local _list = Http:JSONDecode(game:HttpGet(Api))
       if _list and _list.data then
           for _, v in pairs(_list.data) do
               if v.playing < v.maxPlayers and v.id ~= game.JobId then
                   TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
                   break
               end
           end
       end
   end,
})

Tab:CreateSection("Character Utilities")

Tab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      _aafk = Value
   end,
})

Tab:CreateButton({
   Name = "Respawn Character",
   Callback = function()
       local char = LP.Character
       if char then char:BreakJoints() end
   end,
})

-- [ ELITE FPS BOOSTER ]
local _fpsEnabled = false
local _boosterThread = 0 -- Thread Guard to prevent toggle overlap
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function ToggleEliteFPS(Value)
    _fpsEnabled = Value
    _boosterThread = _boosterThread + 1
    local currentThread = _boosterThread

    -- 1. Instant Global Changes (Shadows & Lighting)
    Lighting.GlobalShadows = not Value
    Lighting.Brightness = Value and 1 or 2
    Lighting.EnvironmentDiffuseScale = Value and 0 or 0.3
    Lighting.EnvironmentSpecularScale = Value and 0 or 0.3
    
    -- Toggle Post-Processing
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = not Value
        end
    end

    -- 2. Terrain Changes
    if Terrain then
        Terrain.WaterWaveSize = Value and 0 or 0.15
        Terrain.WaterWaveSpeed = Value and 0 or 8
        Terrain.WaterReflectance = Value and 0 or 1
        Terrain.WaterTransparency = Value and 0 or 1
    end

    -- 3. World Object Loop (Optimized & Guarded)
    task.spawn(function()
        local objects = workspace:GetDescendants()
        for i, v in pairs(objects) do
            -- Thread Guard Check: If user toggled again, kill this loop instantly
            if _boosterThread ~= currentThread then return end

            if v:IsA("BasePart") then
                v.CastShadow = not Value
                v.Material = Value and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = Value and 1 or 0
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = not Value
            end

            -- Yield every 300 items to keep mobile CPU usage low
            if i % 300 == 0 then task.wait() end
        end
    end)
end

-- [ UI ELEMENTS ]
Tab:CreateSection("Performance")

Tab:CreateToggle({
   Name = "Elite FPS Booster",
   CurrentValue = false,
   Flag = "EliteFPS",
   Callback = function(Value)
      ToggleEliteFPS(Value)
      Rayfield:Notify({
         Title = "Elite Hub",
         Content = Value and "Maximum FPS Mode Enabled" or "Graphics Restored to Standard",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

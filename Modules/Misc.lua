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

-- [ ELITE FPS BOOSTER LOGIC ]
local _fpsEnabled = false
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function ToggleFPSBooster(Value)
    _fpsEnabled = Value
    
    task.spawn(function()
        -- 1. Global Lighting & Shadows Restoration
        Lighting.GlobalShadows = not Value
        Lighting.Brightness = Value and 1 or 2
        Lighting.FogEnd = Value and 9e9 or 100000 -- Restores fog distance
        Lighting.EnvironmentDiffuseScale = Value and 0 or 0.3
        Lighting.EnvironmentSpecularScale = Value and 0 or 0.3
        
        -- 2. Post-Processing (Bloom, Blur, etc)
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = not Value
            end
        end

        -- 3. Terrain Quality
        if Terrain then
            Terrain.WaterWaveSize = Value and 0 or 0.15
            Terrain.WaterWaveSpeed = Value and 0 or 8
            Terrain.WaterReflectance = Value and 0 or 1
            Terrain.WaterTransparency = Value and 0 or 1
        end

        -- 4. The Loop (Optimized for Mobile)
        -- We removed the 'break' so that the loop always finishes resetting everything
        local descendants = workspace:GetDescendants()
        for i, v in pairs(descendants) do
            -- If the user toggles it AGAIN while this loop is running, stop this specific thread
            if _fpsEnabled ~= Value then return end 

            if v:IsA("BasePart") then
                v.Material = Value and Enum.Material.SmoothPlastic or Enum.Material.Plastic
                v.CastShadow = not Value
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = Value and 1 or 0
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = not Value
            end

            -- Yield every 250 items to keep mobile framerate stable during the switch
            if i % 250 == 0 then task.wait() end
        end
    end)
end

-- [ UI ELEMENTS ]
Tab:CreateSection("Performance")

Tab:CreateToggle({
   Name = "Elite Potato Mode (FPS)",
   CurrentValue = false,
   Flag = "FpsBooster",
   Callback = function(Value)
      ToggleFPSBooster(Value)
      Rayfield:Notify({
         Title = "FPS System",
         Content = Value and "Potato Mode Enabled: Visuals Simplified." or "Visuals Restored: Shadows & Textures On.",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

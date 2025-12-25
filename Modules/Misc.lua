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

-- [ FPS BOOSTER LOGIC ]
local function OptimizePerformance()
    task.spawn(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        -- Disable Shadows and Lighting Effects
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end

        -- Optimize Parts (Materials and Textures)
        for i, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
            
            -- Prevent lag while script is cleaning (Wait every 100 items)
            if i % 100 == 0 then task.wait() end
        end
    end)
end

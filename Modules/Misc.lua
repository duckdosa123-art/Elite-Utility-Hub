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

-- [ ELITE FPS BOOSTER SYSTEM ]
local _fpsEnabled = false
local _boosterThread = 0
local _originalCache = {} -- THE CACHE: Stores original game looks

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function ToggleEliteFPS(Value)
    _fpsEnabled = Value
    _boosterThread = _boosterThread + 1
    local currentThread = _boosterThread

    -- 1. HANDLE LIGHTING & TERRAIN
    if Value then
        -- Save Lighting originals
        _originalCache["Lighting"] = {
            GS = Lighting.GlobalShadows,
            BR = Lighting.Brightness,
            EDS = Lighting.EnvironmentDiffuseScale,
            ESS = Lighting.EnvironmentSpecularScale
        }
        -- Apply Potato Lighting
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    elseif _originalCache["Lighting"] then
        -- Restore Lighting
        local settings = _originalCache["Lighting"]
        Lighting.GlobalShadows = settings.GS
        Lighting.Brightness = settings.BR
        Lighting.EnvironmentDiffuseScale = settings.EDS
        Lighting.EnvironmentSpecularScale = settings.ESS
    end

    -- 2. HANDLE WORLD OBJECTS (THE HEAVY LIFTING)
    task.spawn(function()
        local objects = workspace:GetDescendants()
        for i, v in pairs(objects) do
            -- Thread Guard: Stop if toggle was flipped again
            if _boosterThread ~= currentThread then return end

            if Value then
                -- ENABLING: Save and change
                if v:IsA("BasePart") and not _originalCache[v] then
                    _originalCache[v] = {
                        Mat = v.Material,
                        SH = v.CastShadow,
                        TR = (v:IsA("Decal") or v:IsA("Texture")) and v.Transparency or nil
                    }
                    
                    v.CastShadow = false
                    v.Material = Enum.Material.SmoothPlastic
                elseif (v:IsA("Decal") or v:IsA("Texture")) then
                    if not _originalCache[v] then _originalCache[v] = {TR = v.Transparency} end
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    if not _originalCache[v] then _originalCache[v] = {EN = v.Enabled} end
                    v.Enabled = false
                end
            else
                -- DISABLING: Restore from cache
                local data = _originalCache[v]
                if data then
                    if v:IsA("BasePart") then
                        v.CastShadow = data.SH
                        v.Material = data.Mat
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = data.TR
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        v.Enabled = data.EN
                    end
                end
            end

            -- Yield to prevent mobile crashes (High speed: 500 items per frame)
            if i % 500 == 0 then task.wait() end
        end
        
        -- Clear cache on disable to save memory
        if not Value then _originalCache = {} end
    end)
end

-- [ UI ELEMENTS ]
-- Safety check to prevent "nil" callback error
if _G.MiscTab then
    local Tab = _G.MiscTab
    
    Tab:CreateSection("Performance")

    Tab:CreateToggle({
       Name = "Elite FPS Booster",
       CurrentValue = false,
       Flag = "EliteFPS",
       Callback = function(Value)
          -- Wrap in pcall to "God-Proof" the callback from errors
          local success, err = pcall(function()
              ToggleEliteFPS(Value)
          end)
          
          if not success then
              warn("Elite-Hub FPS Callback Error: " .. tostring(err))
          end

          Rayfield:Notify({
             Title = "Elite Hub",
             Content = Value and "Potato Mode: Visuals Cached & Simplified." or "Graphics Restored from Cache.",
             Duration = 3,
             Image = 4483362458,
          })
       end,
    })
else
    warn("Elite-Hub: Misc Tab not found, FPS Booster could not initialize.")
end

-- Misc.lua - Elite-Utility-Hub
local Tab = _G.MiscTab
local LP = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- [ STATES & VARIABLES ]
local _aafk = false
local _autoclick = false
local _cps = 10
local _antifling = false
local _chatlog = false

-- [ 1. DETECTIVE SUITE LOGIC ]
-- Chat Logger
game:GetService("LogService").MessageOut:Connect(function(Message, Type)
    if _chatlog and Type == Enum.MessageType.MessageOutput or Type == Enum.MessageType.MessageInfo then
        -- This prints game output and chat to the F9 console for mobile users
        print("[ELITE LOG]: " .. Message)
    end
end)

-- [ 2. SIMULATOR KING LOGIC ]
task.spawn(function()
    while true do
        if _autoclick then
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
        task.wait(1 / _cps)
    end
end)

-- [ 3. ELITE PROTECTION LOGIC ]
-- Anti-Fling: Monitors velocity to prevent player flinging
RunService.Heartbeat:Connect(function()
    if _antifling then
        local char = LP.Character
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if r then
            if r.AssemblyLinearVelocity.Magnitude > 150 or r.AssemblyAngularVelocity.Magnitude > 150 then
                r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                r.Velocity = Vector3.new(0,0,0) -- Legacy support
            end
        end
    end
end)

-- [ 4. PERFORMANCE & AFK LOGIC (Existing) ]
local _fpsEnabled = false
local _boosterThread = 0
local _originalCache = {}

local function ToggleEliteFPS(Value)
    _fpsEnabled = Value
    _boosterThread = _boosterThread + 1
    local currentThread = _boosterThread
    if Value then
        _originalCache["Lighting"] = {GS = Lighting.GlobalShadows, BR = Lighting.Brightness, EDS = Lighting.EnvironmentDiffuseScale, ESS = Lighting.EnvironmentSpecularScale}
        Lighting.GlobalShadows, Lighting.Brightness, Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = false, 1, 0, 0
    elseif _originalCache["Lighting"] then
        local s = _originalCache["Lighting"]
        Lighting.GlobalShadows, Lighting.Brightness, Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = s.GS, s.BR, s.EDS, s.ESS
    end
    task.spawn(function()
        local objects = workspace:GetDescendants()
        for i, v in pairs(objects) do
            if _boosterThread ~= currentThread then return end
            if Value then
                if v:IsA("BasePart") and not _originalCache[v] then
                    _originalCache[v] = {Mat = v.Material, SH = v.CastShadow}
                    v.CastShadow, v.Material = false, Enum.Material.SmoothPlastic
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    if not _originalCache[v] then _originalCache[v] = {TR = v.Transparency} end
                    v.Transparency = 1
                end
            else
                local data = _originalCache[v]
                if data then
                    if v:IsA("BasePart") then v.CastShadow, v.Material = data.SH, data.Mat
                    elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = data.TR end
                end
            end
            if i % 500 == 0 then task.wait() end
        end
        if not Value then _originalCache = {} end
    end)
end

-- Anti-AFK
LP.Idled:Connect(function()
    if _aafk then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- [ UI CONSTRUCTION ]
if _G.MiscTab then
    -- SERVER UTILITIES
    Tab:CreateSection("Detective Suite")
    
    Tab:CreateToggle({
        Name = "Chat Logger (F9 Console)",
        CurrentValue = false,
        Flag = "ChatLog",
        Callback = function(Value) _chatlog = Value end,
    })

    Tab:CreateButton({
        Name = "Audio Logger (Print IDs)",
        Callback = function()
            print("--- ELITE AUDIO LOG ---")
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("Sound") and v.Playing then
                    print("Name: " .. v.Name .. " | ID: " .. v.SoundId)
                end
            end
            Rayfield:Notify({Title = "Detective", Content = "Active Audio IDs printed to F9 Console.", Duration = 3})
        end,
    })

    Tab:CreateButton({
        Name = "Copy Server JobID",
        Callback = function()
            setclipboard(tostring(game.JobId))
            Rayfield:Notify({Title = "Server Info", Content = "JobID copied to clipboard!", Duration = 2})
        end,
    })

    Tab:CreateSection("Automation")
    
    Tab:CreateToggle({
        Name = "Universal Auto-Clicker",
        CurrentValue = false,
        Flag = "AutoClick",
        Callback = function(Value) _autoclick = Value end,
    })

    Tab:CreateSlider({
        Name = "Auto-Clicker Speed (CPS)",
        Range = {1, 50},
        Increment = 1,
        CurrentValue = 10,
        Flag = "CPS_Slider",
        Callback = function(Value) _cps = Value end,
    })

    Tab:CreateSection("Elite Protection")

    Tab:CreateToggle({
        Name = "Anti-Fling (Physics Guard)",
        CurrentValue = false,
        Flag = "AntiFling",
        Callback = function(Value) _antifling = Value end,
    })

    Tab:CreateSection("Character Utilities")

    Tab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = false,
        Flag = "AntiAFK",
        Callback = function(Value) _aafk = Value end,
    })

    Tab:CreateButton({
        Name = "Respawn Character",
        Callback = function()
            local char = LP.Character
            if char then char:BreakJoints() end
        end,
    })

    Tab:CreateSection("Performance & Battery")

    Tab:CreateToggle({
        Name = "Elite FPS Booster",
        CurrentValue = false,
        Flag = "EliteFPS",
        Callback = function(Value) ToggleEliteFPS(Value) end,
    })

    Tab:CreateSlider({
        Name = "FPS Cap (Battery Saver)",
        Range = {15, 240},
        Increment = 5,
        CurrentValue = 60,
        Flag = "FPSCap",
        Callback = function(Value)
            if setfpscap then setfpscap(Value) end
        end,
    })

    Tab:CreateSection("Server Utilities")
    
    Tab:CreateButton({
        Name = "Rejoin Server",
        Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end,
    })

    Tab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            local Http = game:GetService("HttpService")
            local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
            local success, result = pcall(function() return game:HttpGet(Api) end)
            if success then
                local _list = Http:JSONDecode(result)
                for _, v in pairs(_list.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
                        break
                    end
                end
            end
        end,
    })
end

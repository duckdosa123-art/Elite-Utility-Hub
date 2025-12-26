-- Misc.lua - Elite-Utility-Hub
local Tab = _G.MiscTab
local LP = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- [ PROTECTED NOTIFICATION HELPER ]
local function EliteNotify(title, content)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 3,
        Image = 4483362458,
    })
end

-- [ PROTECTED CALLBACK WRAPPER ]
local function SafeCallback(func)
    local success, err = pcall(func)
    if not success then
        warn("Elite-Hub Callback Error: " .. tostring(err))
    end
end

-- [ STATES ]
local _aafk = false
local _autoclick = false
local _cps = 10
local _antifling = false
local _chatlog = false

-- [ 1. DETECTIVE SUITE LOGIC ]
game:GetService("LogService").MessageOut:Connect(function(Message, Type)
    if _chatlog then
        print("[ELITE CHAT LOG]: " .. Message)
    end
end)

-- [ 2. SIMULATOR KING LOGIC ]
task.spawn(function()
    while true do
        if _autoclick then
            SafeCallback(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
        task.wait(1 / _cps)
    end
end)

-- [ 3. ELITE PROTECTION LOGIC ]
RunService.Heartbeat:Connect(function()
    if _antifling then
        local char = LP.Character
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if r then
            if r.AssemblyLinearVelocity.Magnitude > 150 or r.AssemblyAngularVelocity.Magnitude > 150 then
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

-- [ 4. FPS BOOSTER ENGINE ]
local _fpsEnabled = false
local _boosterThread = 0
local _originalCache = {}

local function ToggleEliteFPS(Value)
    _fpsEnabled = Value
    _boosterThread = _boosterThread + 1
    local currentThread = _boosterThread
    
    if Value then
        _originalCache["Lighting"] = {GS = Lighting.GlobalShadows, BR = Lighting.Brightness, EDS = Lighting.EnvironmentDiffuseScale}
        Lighting.GlobalShadows, Lighting.Brightness, Lighting.EnvironmentDiffuseScale = false, 1, 0
    elseif _originalCache["Lighting"] then
        local s = _originalCache["Lighting"]
        Lighting.GlobalShadows, Lighting.Brightness, Lighting.EnvironmentDiffuseScale = s.GS, s.BR, s.EDS
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
    end)
end

-- [ ANTI-AFK ENGINE ]
LP.Idled:Connect(function()
    if _aafk then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- [ UI CONSTRUCTION ]
if _G.MiscTab then
    Tab:CreateSection("Detective Suite")
    
    Tab:CreateToggle({
        Name = "Chat Logger (F9 Console)",
        CurrentValue = false,
        Flag = "ChatLog",
        Callback = function(Value) 
            _chatlog = Value 
            EliteNotify("Detective", Value and "Chat Logging Enabled" or "Chat Logging Disabled")
        end,
    })

    Tab:CreateButton({
        Name = "Audio Logger (Print IDs)",
        Callback = function()
            SafeCallback(function()
                print("--- ELITE AUDIO LOG ---")
                for _, v in pairs(game:GetDescendants()) do
                    if v:IsA("Sound") and v.Playing then
                        print("Audio: " .. v.Name .. " | ID: " .. v.SoundId)
                    end
                end
                EliteNotify("Detective", "Active Audio IDs printed to F9 Console.")
            end)
        end,
    })

    Tab:CreateButton({
        Name = "Copy Server JobID",
        Callback = function()
            SafeCallback(function()
                setclipboard(tostring(game.JobId))
                EliteNotify("Server Info", "JobID copied to clipboard!")
            end)
        end,
    })

    Tab:CreateSection("Automation")
    
    Tab:CreateToggle({
        Name = "Universal Auto-Clicker",
        CurrentValue = false,
        Flag = "AutoClick",
        Callback = function(Value) 
            _autoclick = Value 
            EliteNotify("Automation", Value and "Auto-Clicker Started" or "Auto-Clicker Stopped")
        end,
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
        Callback = function(Value) 
            _antifling = Value 
            EliteNotify("Protection", Value and "Physics Guard Active" or "Physics Guard Disabled")
        end,
    })

    Tab:CreateSection("Performance & Battery")

    Tab:CreateToggle({
        Name = "Elite FPS Booster",
        CurrentValue = false,
        Flag = "EliteFPS",
        Callback = function(Value) 
            SafeCallback(function() ToggleEliteFPS(Value) end)
            EliteNotify("Performance", Value and "Potato Mode: On" or "Performance: Restored")
        end,
    })

    Tab:CreateSlider({
        Name = "FPS Cap (Battery Saver)",
        Range = {15, 240},
        Increment = 5,
        CurrentValue = 60,
        Flag = "FPSCap",
        Callback = function(Value)
            SafeCallback(function() if setfpscap then setfpscap(Value) end end)
        end,
    })

    Tab:CreateSection("Server Utilities")
    
    Tab:CreateButton({
        Name = "Rejoin Server",
        Callback = function() 
            EliteNotify("Server", "Rejoining...")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
        end,
    })

    Tab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            SafeCallback(function()
                EliteNotify("Server", "Finding new server...")
                local Http = game:GetService("HttpService")
                local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
                local _list = Http:JSONDecode(game:HttpGet(Api))
                for _, v in pairs(_list.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP)
                        break
                    end
                end
            end)
        end,
    })
end

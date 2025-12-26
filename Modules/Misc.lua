-- Misc.lua - Elite-Utility-Hub
local Tab = _G.MiscTab
local LP = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

-- [ ELITE BRUTE-FORCE NOTIFICATION HELPER ]
local function BruteNotify(title, text)
    -- Rayfield Notify
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = 3,
        Image = 4483362458,
    })
    -- Roblox System Notify (Brute Force Confirmation)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- [ THE BRUTE-FORCE CALLBACK WRAPPER ]
-- This ensures Rayfield never sees a "delay", preventing the Callback Error
local function BruteExecute(name, func)
    task.spawn(function()
        local success, err = pcall(func)
        if success then
            BruteNotify("Elite Hub: Success", name .. " executed successfully!")
        else
            BruteNotify("Elite Hub: ERROR", name .. " failed: " .. tostring(err))
        end
    end)
end

-- [ STATES ]
local _aafk = false
local _autoclick = false
local _cps = 10
local _antifling = false
local _chatlog = false

-- [ 1. DETECTIVE SUITE LOGIC ]
game:GetService("LogService").MessageOut:Connect(function(Message, Type)
    if _chatlog then print("[ELITE CHAT LOG]: " .. Message) end
end)

-- [ 2. SIMULATOR KING LOGIC ]
task.spawn(function()
    while true do
        if _autoclick then
            pcall(function()
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
            BruteExecute("Chat Logger", function() _chatlog = Value end)
        end,
    })

    Tab:CreateButton({
        Name = "Audio Logger (Print IDs)",
        Callback = function()
            BruteExecute("Audio Logger", function()
                print("--- ELITE AUDIO LOG ---")
                for _, v in pairs(game:GetDescendants()) do
                    if v:IsA("Sound") and v.Playing then
                        print("Audio: " .. v.Name .. " | ID: " .. v.SoundId)
                    end
                end
            end)
        end,
    })

    Tab:CreateButton({
        Name = "Copy Server JobID",
        Callback = function()
            BruteExecute("JobID Copier", function()
                setclipboard(tostring(game.JobId))
            end)
        end,
    })

    Tab:CreateSection("Automation")
    
    Tab:CreateToggle({
        Name = "Universal Auto-Clicker",
        CurrentValue = false,
        Flag = "AutoClick",
        Callback = function(Value) 
            BruteExecute("Auto-Clicker", function() _autoclick = Value end)
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
        Name = "Anti-Fling Guard",
        CurrentValue = false,
        Flag = "AntiFling",
        Callback = function(Value) 
            BruteExecute("Anti-Fling", function() _antifling = Value end)
        end,
    })

    Tab:CreateSection("Performance & AFK")

    Tab:CreateToggle({
        Name = "Elite FPS Booster",
        CurrentValue = false,
        Flag = "EliteFPS",
        Callback = function(Value) 
            BruteExecute("FPS Booster", function() ToggleEliteFPS(Value) end)
        end,
    })

    Tab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = false,
        Flag = "AntiAFK",
        Callback = function(Value)
            BruteExecute("Anti-AFK", function() _aafk = Value end)
        end,
    })

    Tab:CreateSlider({
        Name = "FPS Cap (Battery Saver)",
        Range = {15, 240},
        Increment = 5,
        CurrentValue = 60,
        Flag = "FPSCap",
        Callback = function(Value)
            BruteExecute("FPS Cap", function() if setfpscap then setfpscap(Value) end end)
        end,
    })

    Tab:CreateSection("Server Utilities")
    
    Tab:CreateButton({
        Name = "Rejoin Server",
        Callback = function() 
            BruteExecute("Rejoin", function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) 
            end)
        end,
    })

    Tab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            BruteExecute("Server Hop", function()
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

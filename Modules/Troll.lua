-- [[ ELITE-UTILITY-HUB: TROLL MODULE (SMART-FLING EDITION) ]]
-- Variables Tab, LP, RunService, etc., are injected by Main.lua

local BeastState = "Idle"
local SelectedTarget = nil
local OG_Spot = nil

-- // THE BEAST PHYSICS ENGINE (WalkFling Logic) //
local function ApplyEliteWalkFling(Part)
    if not Part or not Part:IsA("BasePart") then return end
    local Hum = LP.Character:FindFirstChildOfClass("Humanoid")
    
    task.spawn(function()
        while BeastState ~= "Idle" and Part.Parent do
            local rotTick = tick() * 30
            local flingForce = 95000 
            
            Part.AssemblyLinearVelocity = Vector3.new(
                math.sin(rotTick) * flingForce, 
                28.5 + math.sin(tick() * 10), 
                math.cos(rotTick) * flingForce
            )
            Part.AssemblyAngularVelocity = Vector3.new(0, 95000, 0)

            -- Mobile Steering Support
            if Hum and Hum.MoveDirection.Magnitude > 0 then
                LP.Character:TranslateBy(Hum.MoveDirection * 0.4)
            end
            RunService.Heartbeat:Wait()
        end
        Part.AssemblyLinearVelocity = Vector3.zero
        Part.AssemblyAngularVelocity = Vector3.zero
        if Hum then Hum.PlatformStand = false end
    end)
end

-- // GHOST LOGIC //
local function SetGhost(state)
    local char = LP.Character
    if not char then return end
    local Hum = char:FindFirstChildOfClass("Humanoid")
    if Hum then Hum.PlatformStand = state end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not state
            if v.Name == "HumanoidRootPart" then v.CanTouch = true end
        end
    end
end

-- // PLAYER DISPLAYNAME LIST //
local function GetPlayerList()
    local tbl = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then 
            -- We use DisplayName but fallback to Name for accuracy
            table.insert(tbl, p.DisplayName .. " (@" .. p.Name .. ")") 
        end
    end
    return tbl
end

-- // UI SECTION //

Tab:CreateSection("Elite Smart-Fling")

-- 1. Selection Dropdown (DisplayNames)
local TargetDropdown = Tab:CreateDropdown({
    Name = "Select Victim (Display Names)",
    Options = GetPlayerList(),
    CurrentOption = {"None"},
    Callback = function(Option)
        local rawName = string.match(Option[1], "@(%w+)") -- Extracts actual name from "@Name"
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.Name == rawName then
                SelectedTarget = p
                _G.EliteLog("Locked onto: " .. p.DisplayName, "info")
                break
            end
        end
    end,
})

-- 2. Smart Fling Button (Replaced Toggle)
Tab:CreateButton({
    Name = "Elite Smart-Fling (Target)",
    Callback = function()
        if not SelectedTarget or not SelectedTarget.Character then 
            _G.EliteLog("Target not selected or not spawned!", "error") 
            return 
        end
        
        local targetHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        -- Save OG Spot and Start Fling
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        SetGhost(true)
        ApplyEliteWalkFling(LP.Character.HumanoidRootPart)
        _G.EliteLog("Launching Smart-Fling on " .. SelectedTarget.DisplayName, "info")

        task.spawn(function()
            local success = false
            local startTime = tick()

            while BeastState == "Fling" and (tick() - startTime < 10) do -- 10s timeout
                if not SelectedTarget or not SelectedTarget.Character or not targetHRP then break end
                
                -- Check if Target is Flung (High Speed, High Air, or Dead)
                local velocity = targetHRP.AssemblyLinearVelocity.Magnitude
                local humanoid = SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
                
                if velocity > 200 or (humanoid and humanoid.Health <= 0) then
                    success = true
                    _G.EliteLog("Target Successfully Flung!", "success")
                    break
                end

                -- Orbit Logic
                local angle = tick() * 25
                LP.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(math.cos(angle) * 1.5, 0, math.sin(angle) * 1.5)
                
                RunService.Heartbeat:Wait()
            end

            -- Automatically return to OG Spot
            BeastState = "Idle"
            SetGhost(false)
            if OG_Spot then
                LP.Character.HumanoidRootPart.CFrame = OG_Spot
                _G.EliteLog("Returned to OG Spot.", "success")
            end
        end)
    end,
})

Tab:CreateSection("Elite Fling Extras")

-- 3. Elite Fling All (Beast Mode)
Tab:CreateButton({
    Name = "Elite Fling All (Auto-Return)",
    Callback = function()
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        SetGhost(true)
        ApplyEliteWalkFling(LP.Character.HumanoidRootPart)
        
        task.spawn(function()
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = p.Character.HumanoidRootPart
                    local t = tick()
                    while tick() - t < 0.7 do -- Rapid-fire fling
                        LP.Character.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.angles(0, tick()*10, 0)
                        task.wait()
                    end
                end
            end
            BeastState = "Idle"
            SetGhost(false)
            LP.Character.HumanoidRootPart.CFrame = OG_Spot
            _G.EliteLog("Mass Fling Complete. Returned Home.", "success")
        end)
    end,
})

-- Auto-Refresh Dropdown with DisplayNames
task.spawn(function()
    while task.wait(10) do
        TargetDropdown:Refresh(GetPlayerList(), true)
    end
end)

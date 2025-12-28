-- [[ ELITE-UTILITY-HUB: TROLL MODULE (WALKFLING EDITION) ]]
-- Variables Tab, LP, RunService, etc., are injected by Main.lua

local BeastState = "Idle"
local SelectedTarget = nil
local OG_Spot = nil
local FlingAllRunning = false

-- // ELITE WALKFLING ENGINE //
-- Combines IY's WalkFling with Beast Physics for AC Bypass
local function ApplyEliteWalkFling(Part)
    if not Part or not Part:IsA("BasePart") then return end
    local Hum = LP.Character:FindFirstChildOfClass("Humanoid")
    
    task.spawn(function()
        while BeastState ~= "Idle" and Part.Parent do
            -- 1. Physics: The "WalkFling" Vector
            -- We rotate the velocity vector rapidly to maximize launch power
            local rotTick = tick() * 30
            local flingForce = 90000 -- Massive force like IY
            
            if BeastState == "Fling" or BeastState == "Void" then
                -- Anti-Cheat Bypass: Oscillating velocity vectors
                Part.AssemblyLinearVelocity = Vector3.new(
                    math.sin(rotTick) * flingForce, 
                    28.5 + math.sin(tick() * 10), -- Beast Netless Constant
                    math.cos(rotTick) * flingForce
                )
                Part.AssemblyAngularVelocity = Vector3.new(0, 95000, 0)
            end

            -- 2. Movement Logic (Mobile-First Steering)
            -- Allows you to "Walk" while flinging despite the massive velocity
            if Hum and Hum.MoveDirection.Magnitude > 0 then
                local moveDir = Hum.MoveDirection
                LP.Character:TranslateBy(moveDir * 0.4) -- Manual move offset
            end
            
            RunService.Heartbeat:Wait()
        end
        -- Cleanup
        Part.AssemblyLinearVelocity = Vector3.zero
        Part.AssemblyAngularVelocity = Vector3.zero
        if Hum then Hum.PlatformStand = false end
    end)
end

-- // GHOST LOGIC (Local Noclip) //
local function SetGhost(state)
    local char = LP.Character
    if not char then return end
    local Hum = char:FindFirstChildOfClass("Humanoid")
    
    if state then
        if Hum then Hum.PlatformStand = true end -- Required for clean WalkFling
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                -- Important: RootPart MUST have CanTouch = true to hit victims
                if v.Name == "HumanoidRootPart" then v.CanTouch = true end
            end
        end
    else
        if Hum then Hum.PlatformStand = false end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- // PLAYER LIST HELPER //
local function GetPlayerList()
    local tbl = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then table.insert(tbl, p.DisplayName) end
    end
    return tbl
end

-- // UI CONSTRUCTION //

Tab:CreateSection("Elite WalkFling (Bypass Engine)")

-- 1. Elite WalkFling (Main)
Tab:CreateToggle({
    Name = "Elite WalkFling (Main)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Fling"
            SetGhost(true)
            ApplyEliteWalkFling(LP.Character:FindFirstChild("HumanoidRootPart"))
            _G.EliteLog("WalkFling Active: Move into players to launch", "success")
        else
            BeastState = "Idle"
            SetGhost(false)
        end
    end,
})

-- 2. Victim Selection
local TargetDropdown = Tab:CreateDropdown({
    Name = "Select Victim",
    Options = GetPlayerList(),
    CurrentOption = {"None"},
    Callback = function(Option)
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.DisplayName == Option[1] then
                SelectedTarget = p
                _G.EliteLog("Target Set: " .. p.DisplayName, "info")
                break
            end
        end
    end,
})

-- 3. Elite Orbit WalkFling
Tab:CreateToggle({
    Name = "Elite Orbit WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            if not SelectedTarget or not SelectedTarget.Character then 
                _G.EliteLog("No valid target selected!", "error") 
                return 
            end
            
            OG_Spot = LP.Character.HumanoidRootPart.CFrame
            BeastState = "Fling"
            SetGhost(true)
            ApplyEliteWalkFling(LP.Character:FindFirstChild("HumanoidRootPart"))
            
            task.spawn(function()
                while BeastState == "Fling" and SelectedTarget and SelectedTarget.Character do
                    local tarHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
                    if tarHRP then
                        local angle = tick() * 25
                        -- Orbiting extremely close with WalkFling velocity
                        local pos = tarHRP.CFrame * CFrame.new(math.cos(angle) * 1.5, 0, math.sin(angle) * 1.5)
                        LP.Character.HumanoidRootPart.CFrame = pos
                    end
                    task.wait()
                end
                if OG_Spot then LP.Character.HumanoidRootPart.CFrame = OG_Spot end
            end)
        else
            BeastState = "Idle"
            SetGhost(false)
        end
    end,
})

-- 4. Elite Fling All (WalkFling Mode)
Tab:CreateButton({
    Name = "Elite Fling All (Beast)",
    Callback = function()
        if FlingAllRunning then return end
        FlingAllRunning = true
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        SetGhost(true)
        ApplyEliteWalkFling(LP.Character:FindFirstChild("HumanoidRootPart"))
        
        task.spawn(function()
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local tarHRP = p.Character.HumanoidRootPart
                    local startTime = tick()
                    while tick() - startTime < 0.8 do -- Faster kill time with WalkFling
                        local angle = tick() * 35
                        LP.Character.HumanoidRootPart.CFrame = tarHRP.CFrame * CFrame.new(math.cos(angle) * 1, 0, math.sin(angle) * 1)
                        task.wait()
                    end
                end
            end
            BeastState = "Idle"
            SetGhost(false)
            LP.Character.HumanoidRootPart.CFrame = OG_Spot
            FlingAllRunning = false
            _G.EliteLog("Elite Fling All Complete", "success")
        end)
    end,
})

-- Refresh Player List
task.spawn(function()
    while task.wait(10) do
        TargetDropdown:Refresh(GetPlayerList(), true)
    end
end)

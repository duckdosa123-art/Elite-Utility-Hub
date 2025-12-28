-- [[ ELITE-UTILITY-HUB: TROLL MODULE ]]
-- Variables Tab, LP, RunService, etc., are injected by Main.lua

local BeastState = "Idle"
local SelectedTarget = nil
local OG_Spot = nil
local FlingAllRunning = false

-- // THE BEAST PHYSICS ENGINE //
-- Uses High Angular Velocity + Vertical Jitter to bypass most Anti-Cheats
local function ApplyEliteBeastPhysics(Part)
    if not Part or not Part:IsA("BasePart") then return end
    
    task.spawn(function()
        while BeastState ~= "Idle" and Part.Parent do
            if BeastState == "Fling" or BeastState == "Void" then
                -- Spinning is harder for ACs to detect than linear speed
                Part.AssemblyAngularVelocity = Vector3.new(0, 75000, 0)
                -- Netless Jitter (Ownership Bypass)
                Part.AssemblyLinearVelocity = Vector3.new(0, 28.5 + math.sin(tick() * 8), 0)
            elseif BeastState == "Shield" then
                Part.AssemblyAngularVelocity = Vector3.new(0, 10000, 0)
                Part.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
            end
            RunService.Heartbeat:Wait()
        end
        Part.AssemblyAngularVelocity = Vector3.zero
        Part.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- // GHOST LOGIC (Local Noclip) //
local function SetGhost(state)
    local char = LP.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not state
            v.CanTouch = true -- Must be true to register fling hitboxes
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

Tab:CreateSection("Elite Fling (Beast Engine)")

-- 1. Elite Fling (Main)
Tab:CreateToggle({
    Name = "Elite Fling (Main)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Fling"
            SetGhost(true)
            ApplyEliteBeastPhysics(LP.Character:FindFirstChild("HumanoidRootPart"))
            _G.EliteLog("Fling Enabled: Touch players to launch", "success")
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

-- 3. Orbit Fling
Tab:CreateToggle({
    Name = "Elite Orbit Fling",
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
            ApplyEliteBeastPhysics(LP.Character:FindFirstChild("HumanoidRootPart"))
            
            task.spawn(function()
                while BeastState == "Fling" and SelectedTarget and SelectedTarget.Character do
                    local tarHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
                    if tarHRP then
                        local angle = tick() * 20
                        -- Orbiting 3 studs away to ensure contact without getting stuck
                        local pos = tarHRP.CFrame * CFrame.new(math.cos(angle) * 2.5, 0, math.sin(angle) * 2.5)
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

-- 4. Fling All
Tab:CreateButton({
    Name = "Elite Fling All",
    Callback = function()
        if FlingAllRunning then return end
        FlingAllRunning = true
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        SetGhost(true)
        ApplyEliteBeastPhysics(LP.Character:FindFirstChild("HumanoidRootPart"))
        
        task.spawn(function()
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    _G.EliteLog("Flinging: " .. p.DisplayName, "info")
                    local tarHRP = p.Character.HumanoidRootPart
                    local startTime = tick()
                    while tick() - startTime < 1.0 do -- 1 second per victim
                        local angle = tick() * 30
                        LP.Character.HumanoidRootPart.CFrame = tarHRP.CFrame * CFrame.new(math.cos(angle) * 1.5, 0, math.sin(angle) * 1.5)
                        task.wait()
                    end
                end
            end
            BeastState = "Idle"
            SetGhost(false)
            LP.Character.HumanoidRootPart.CFrame = OG_Spot
            FlingAllRunning = false
            _G.EliteLog("Fling All sequence finished", "success")
        end)
    end,
})

Tab:CreateSection("Elite Combat Trolls")

-- 5. Elite Void-Launch
Tab:CreateButton({
    Name = "Elite Void-Launch (Selected)",
    Callback = function()
        if not SelectedTarget or not SelectedTarget.Character then return end
        local voidDepth = workspace.FallenPartsDestroyHeight + 5
        BeastState = "Void"
        SetGhost(true)
        ApplyEliteBeastPhysics(LP.Character:FindFirstChild("HumanoidRootPart"))
        
        task.spawn(function()
            local tarHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
            if tarHRP then
                LP.Character.HumanoidRootPart.CFrame = tarHRP.CFrame
                task.wait(0.1)
                -- Apply massive downward velocity
                LP.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, voidDepth * 15, 0)
                task.wait(0.5)
            end
            BeastState = "Idle"
            SetGhost(false)
        end)
    end,
})

-- 6. Elite Defender (Anti-Touch)
Tab:CreateToggle({
    Name = "Elite Defender (Anti-Touch)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Shield"
            ApplyEliteBeastPhysics(LP.Character:FindFirstChild("HumanoidRootPart"))
            _G.EliteLog("Shield Active: Touchers will be flung", "success")
        else
            BeastState = "Idle"
        end
    end,
})

-- Auto-Refresh Victim List
task.spawn(function()
    while task.wait(10) do
        TargetDropdown:Refresh(GetPlayerList(), true)
    end
end)

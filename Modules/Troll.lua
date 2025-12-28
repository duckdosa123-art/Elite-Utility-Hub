local LP = _G.LP
local RS = game:GetService("RunService")
local TrollTab = _G.EliteTab -- Accessing the tab created in Main.lua

-- // BEAST ENGINE VARIABLES //
local BeastState = "Idle"
local SelectedTarget = nil
local OG_Spot = nil
local FlingAllRunning = false

-- // THE BEAST PHYSICS ENGINE (Anti-Cheat Bypass Edition) //
local function ApplyEliteBeastPhysics(Part)
    if not Part or not Part:IsA("BasePart") then return end
    
    task.spawn(function()
        while BeastState ~= "Idle" and Part.Parent do
            if BeastState == "Fling" or BeastState == "Void" then
                -- Rotational Force (Spin) - Harder for AC to detect than linear speed
                Part.AssemblyAngularVelocity = Vector3.new(0, 60000, 0)
                -- Netless Jitter (Bypass Ownership)
                Part.AssemblyLinearVelocity = Vector3.new(0, 28.5 + math.sin(tick() * 10), 0)
            elseif BeastState == "Shield" then
                Part.AssemblyAngularVelocity = Vector3.new(0, 8000, 0)
                Part.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
            end
            RS.Heartbeat:Wait()
        end
        -- Reset physics on stop
        Part.AssemblyAngularVelocity = Vector3.zero
        Part.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- // GHOST LOGIC //
local function SetGhost(state)
    local char = LP.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not state
            v.CanTouch = true -- Critical for Fling contact
        end
    end
end

-- // UI ELEMENTS //

TrollTab:CreateSection("Elite Fling (Beast Engine)")

-- 1. Elite Fling (Main)
TrollTab:CreateToggle({
    Name = "Elite Fling (Main)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Fling"
            SetGhost(true)
            ApplyEliteBeastPhysics(LP.Character.HumanoidRootPart)
            _G.EliteLog("Fling Enabled: Touch players to launch", "Info")
        else
            BeastState = "Idle"
            SetGhost(false)
        end
    end,
})

-- 2. Player Selection Dropdown
local function GetPlayerList()
    local tbl = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then table.insert(tbl, p.DisplayName) end
    end
    return tbl
end

local TargetDropdown = TrollTab:CreateDropdown({
    Name = "Select Target",
    Options = GetPlayerList(),
    CurrentOption = {"None"},
    Callback = function(Option)
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.DisplayName == Option[1] then
                SelectedTarget = p
                break
            end
        end
    end,
})

-- 3. Elite Orbit Fling
TrollTab:CreateToggle({
    Name = "Elite Orbit Fling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            if not SelectedTarget then 
                _G.EliteLog("No Target Selected!", "Error") 
                return 
            end
            
            OG_Spot = LP.Character.HumanoidRootPart.CFrame
            BeastState = "Fling"
            SetGhost(true)
            ApplyEliteBeastPhysics(LP.Character.HumanoidRootPart)
            
            task.spawn(function()
                while BeastState == "Fling" and SelectedTarget and SelectedTarget.Character do
                    local tarHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
                    if tarHRP then
                        local angle = tick() * 18
                        local pos = tarHRP.CFrame * CFrame.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
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

-- 4. Elite Fling All
TrollTab:CreateButton({
    Name = "Elite Fling All",
    Callback = function()
        if FlingAllRunning then return end
        FlingAllRunning = true
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        SetGhost(true)
        ApplyEliteBeastPhysics(LP.Character.HumanoidRootPart)
        
        task.spawn(function()
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    _G.EliteLog("Flinging: " .. p.DisplayName, "Info")
                    local tarHRP = p.Character.HumanoidRootPart
                    local start = tick()
                    while tick() - start < 1.2 do -- 1.2 seconds per victim
                        local angle = tick() * 25
                        LP.Character.HumanoidRootPart.CFrame = tarHRP.CFrame * CFrame.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
                        task.wait()
                    end
                end
            end
            BeastState = "Idle"
            SetGhost(false)
            LP.Character.HumanoidRootPart.CFrame = OG_Spot
            FlingAllRunning = false
            _G.EliteLog("Fling All Finished", "Success")
        end)
    end,
})

TrollTab:CreateSection("Elite Combat Trolls")

-- 5. Elite Void-Launch
TrollTab:CreateButton({
    Name = "Elite Void-Launch (Selected)",
    Callback = function()
        if not SelectedTarget then return end
        local voidDepth = workspace.FallenPartsDestroyHeight + 5
        BeastState = "Void"
        SetGhost(true)
        ApplyEliteBeastPhysics(LP.Character.HumanoidRootPart)
        
        task.spawn(function()
            local tarHRP = SelectedTarget.Character.HumanoidRootPart
            LP.Character.HumanoidRootPart.CFrame = tarHRP.CFrame
            task.wait(0.1)
            -- Apply downward force + jitter
            LP.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, voidDepth * 10, 0)
            task.wait(0.5)
            BeastState = "Idle"
            SetGhost(false)
        end)
    end,
})

-- 6. Elite Defender (Anti-Touch)
TrollTab:CreateToggle({
    Name = "Elite Defender (Anti-Touch)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Shield"
            ApplyEliteBeastPhysics(LP.Character.HumanoidRootPart)
        else
            BeastState = "Idle"
        end
    end,
})

-- Auto-Refresh Player List every 10 seconds
task.spawn(function()
    while task.wait(10) do
        TargetDropdown:Refresh(GetPlayerList(), true)
    end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TrollTab = _G.EliteTab -- Assuming Main.lua passes the Tab object
local LP = _G.LP
local RS = game:GetService("RunService")

-- // BEAST PHYSICS ENGINE (Bypass Specialized) //
local BeastState = "Idle" -- Idle, Fling, Shield, Void
local SelectedTarget = nil
local OG_Spot = nil

local function ApplyBeastPhysics(Part)
    if not Part or not Part:IsA("BasePart") then return end
    
    -- Anti-Cheat Bypass: Rapidly oscillating velocity to confuse server-side checks
    task.spawn(function()
        while BeastState ~= "Idle" and Part.Parent do
            if BeastState == "Fling" or BeastState == "Void" then
                -- Extreme rotational torque (The actual "Fling" force)
                Part.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
                -- Netless Jitter (Bypasses ownership resets)
                Part.AssemblyLinearVelocity = Vector3.new(0, 28.5 + math.sin(tick() * 10), 0)
            elseif BeastState == "Shield" then
                Part.AssemblyAngularVelocity = Vector3.new(0, 5000, 0)
                Part.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
            end
            RS.Heartbeat:Wait()
        end
        -- Cleanup
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
            v.CanTouch = true -- Must be true to register Fling contact
            v.CanQuery = not state
        end
    end
end

-- // TARGET LIST LOGIC //
local function GetPlayerNames()
    local names = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.DisplayName) end
    end
    return names
end

-- // UI SECTION //
local Section = TrollTab:CreateSection("Elite Fling Category")

-- 1. Elite Fling (Main)
TrollTab:CreateToggle({
    Name = "Elite Fling (Main)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Fling"
            SetGhost(true)
            ApplyBeastPhysics(LP.Character.HumanoidRootPart)
            _G.EliteLog("Fling Activated - Touch targets to launch", "Info")
        else
            BeastState = "Idle"
            SetGhost(false)
        end
    end,
})

-- 2. Target Dropdown
local TargetDropdown = TrollTab:CreateDropdown({
    Name = "Select Victim",
    Options = GetPlayerNames(),
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(Option)
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.DisplayName == Option[1] then
                SelectedTarget = p
                break
            end
        end
    end,
})

-- Refresh Dropdown
task.spawn(function()
    while task.wait(5) do
        TargetDropdown:Refresh(GetPlayerNames())
    end
end)

-- 3. Orbit Fling (Selected)
TrollTab:CreateToggle({
    Name = "Elite Orbit Fling",
    CurrentValue = false,
    Callback = function(Value)
        if Value and SelectedTarget then
            OG_Spot = LP.Character.HumanoidRootPart.CFrame
            BeastState = "Fling"
            _G.EliteLog("Orbiting: " .. SelectedTarget.DisplayName, "Info")
            
            task.spawn(function()
                while BeastState == "Fling" and SelectedTarget and SelectedTarget.Character do
                    local targetHRP = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        -- High speed orbit around target
                        local angle = tick() * 15 -- Rotation speed
                        local offset = Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
                        LP.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(offset)
                    end
                    task.wait()
                end
                -- Return to OG Spot
                if OG_Spot then LP.Character.HumanoidRootPart.CFrame = OG_Spot end
            end)
        else
            BeastState = "Idle"
        end
    end,
})

-- 4. Fling All
TrollTab:CreateButton({
    Name = "Elite Fling All",
    Callback = function()
        OG_Spot = LP.Character.HumanoidRootPart.CFrame
        BeastState = "Fling"
        _G.EliteLog("Initiating Fling All...", "Warn")

        task.spawn(function()
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = p.Character.HumanoidRootPart
                    -- Brief burst orbit to fling
                    local startTime = tick()
                    while tick() - startTime < 1.5 do -- 1.5 seconds per player
                        local angle = tick() * 25
                        LP.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(math.cos(angle)*2, 0, math.sin(angle)*2)
                        task.wait()
                    end
                end
            end
            BeastState = "Idle"
            LP.Character.HumanoidRootPart.CFrame = OG_Spot
            _G.EliteLog("Fling All Complete", "Success")
        end)
    end,
})

-- 5. Elite Void-Launch
TrollTab:CreateToggle({
    Name = "Elite Void-Launch",
    CurrentValue = false,
    Callback = function(Value)
        if Value and SelectedTarget then
            BeastState = "Void"
            local voidPos = workspace.FallenPartsDestroyHeight + 5
            task.spawn(function()
                if SelectedTarget.Character and SelectedTarget.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LP.Character.HumanoidRootPart
                    local targetHRP = SelectedTarget.Character.HumanoidRootPart
                    -- Force push towards void
                    hrp.CFrame = targetHRP.CFrame
                    LP.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, voidPos * 5, 0)
                end
                task.wait(0.5)
                BeastState = "Idle"
            end)
        end
    end,
})

-- 6. Elite Defender
TrollTab:CreateToggle({
    Name = "Elite Defender (Anti-Touch)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            BeastState = "Shield"
            _G.EliteLog("Shield Active", "Success")
            ApplyBeastPhysics(LP.Character.HumanoidRootPart)
        else
            BeastState = "Idle"
        end
    end,
})

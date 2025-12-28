-- WalkFling Logic for Elite-Utility-Hub (Reference-Based Perfection)
local WalkFlingEngine = {
    Active = false,
    Connections = {}
}

function WalkFlingEngine:Notify(text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Elite Utility",
        Text = text,
        Icon = "rbxassetid://6023426926",
        Duration = 3
    })
end

function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")
    if not HRP or not Hum then return end
    
    self.Active = true
    self:Notify("WalkFling Enabled")
    _G.EliteLog("WalkFling engine started", "success")

    -- 1. Godmode & Anti-Trip (Keeps you standing during hits)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. Stepped Noclip (Essential for Fling Accuracy)
    -- This allows you to walk through the target so every part of you touches them.
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 3. The Surgical Spike with Recoil Anchor
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active or hit:IsDescendantOf(Char) then return end
            
            local targetChar = hit.Parent
            if targetChar:FindFirstChild("Humanoid") then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    -- THE FIX: Save current state to prevent "Ascending to Heaven"
                    local oldVel = HRP.AssemblyLinearVelocity
                    local oldCFrame = HRP.CFrame
                    
                    -- Spike velocity to extreme levels
                    HRP.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
                    
                    -- Wait one physics frame for the impact to register
                    RunService.RenderStepped:Wait()
                    
                    -- Immediately restore position and velocity to cancel recoil
                    if HRP then
                        HRP.AssemblyLinearVelocity = oldVel
                        -- This line stops the "fling back" effect instantly
                        HRP.CFrame = oldCFrame 
                    end
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    
    -- Connect every part of the player for 100% accuracy
    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))
end

function WalkFlingEngine:Stop()
    if not self.Active then return end
    self.Active = false
    
    for _, conn in pairs(self.Connections) do 
        pcall(function() conn:Disconnect() end) 
    end
    self.Connections = {}
    
    local Hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if Hum then
        Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
    
    self:Notify("WalkFling Disabled")
    _G.EliteLog("WalkFling engine stopped", "info")
end

-- Elite Propeller Fling Engine
local TargetEngine = {
    Active = true, -- Set to true so loops run
    SelectedPlayer = nil,
    LoopActive = false,
    Connections = {},
    OriginalPos = nil,
    FlingingInProgress = false
}

-- 1. UTILITY: Notifications & Search
local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6023426926",
        Duration = 3
    })
end

local function GetPlayerList()
    local list = {}
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP then table.insert(list, v.DisplayName) end
    end
    return list
end

local function GetPlayerByShortName(name)
    if not name then return nil end
    name = name:lower()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP and (v.DisplayName:lower():sub(1, #name) == name or v.Name:lower():sub(1, #name) == name) then
            return v
        end
    end
    return nil
end

-- 2. CORE: The Propeller Spin-Fling
function TargetEngine:SpinFling(Target)
    if not Target or not Target.Character or self.FlingingInProgress then return end
    
    local TChar = Target.Character
    local THRP = TChar:FindFirstChild("HumanoidRootPart")
    local MyChar = LP.Character
    local MyHRP = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    local MyHum = MyChar and MyChar:FindFirstChild("Humanoid")
    
    if not THRP or not MyHRP or not MyHum then return end

    self.FlingingInProgress = true
    self.OriginalPos = MyHRP.CFrame
    _G.EliteLog("Flinging: " .. Target.DisplayName, "info")

    -- Setup Physics for Fling
    local oldMassless = {}
    for _, v in pairs(MyChar:GetDescendants()) do
        if v:IsA("BasePart") then
            oldMassless[v] = v.Massless
            v.Massless = true
            v.CanCollide = false
        end
    end

    -- The Propeller Loop
    local flingTime = 0
    repeat
        task.wait()
        flingTime = flingTime + 1
        
        -- TP directly into them and Spin physically
        if THRP and MyHRP then
            MyHRP.CFrame = THRP.CFrame * CFrame.Angles(0, math.rad(flingTime * 90), 0)
            MyHRP.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)
            MyHRP.AssemblyLinearVelocity = Vector3.new(500, 500, 500) 
        end
        
    until (THRP and THRP.AssemblyLinearVelocity.Magnitude > 150) or (flingTime > 35) or not Target.Parent or not self.Active

    -- Stop Spin & Cleanup
    if MyHRP then
        MyHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        MyHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        MyHRP.CFrame = self.OriginalPos
    end

    -- Restore collision and mass
    for part, wasMassless in pairs(oldMassless) do
        if part and part.Parent then
            part.Massless = wasMassless
        end
    end

    Notify("Elite Utility", Target.DisplayName .. " flinged!")
    self.FlingingInProgress = false
end

-- 3. PERMANENT PHYSICS OVERRIDE (Godmode/Noclip)
local function SetupFlingSafety()
    if #TargetEngine.Connections > 0 then return end -- Prevent duplicate connections/lag
    
    local Char = LP.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if not Hum then return end

    -- Heartbeat Godmode
    table.insert(TargetEngine.Connections, RunService.Heartbeat:Connect(function()
        if Hum and Hum.Parent then 
            Hum.Health = Hum.MaxHealth 
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end
    end))

    -- Stepped Noclip
    table.insert(TargetEngine.Connections, RunService.Stepped:Connect(function()
        if LP.Character then
            for _, v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end))
end

-- 4. UI INTEGRATION
Tab:CreateSection("Fling - Disable Fling Guard First!")

local PlayerDropdown = Tab:CreateDropdown({
    Name = "Selected: None",
    Options = GetPlayerList(),
    CurrentOption = {""},
    Callback = function(Option)
        TargetEngine.SelectedPlayer = GetPlayerByShortName(Option[1])
    end,
})

Tab:CreateSection("Advance Fling - Disable Fling Guard First!")

Tab:CreateInput({
    Name = "Search & Auto-Select",
    PlaceholderText = "Type start of name...",
    Callback = function(Text)
        if Text == "" then return end
        local found = GetPlayerByShortName(Text)
        if found then
            TargetEngine.SelectedPlayer = found
            PlayerDropdown:Set({found.DisplayName}) 
            _G.EliteLog("Found: " .. found.DisplayName, "success")
        end
    end,
})
local PlayerDropdown = Tab:CreateDropdown({
    Name = "Player List",
    Options = GetPlayerList(), -- Uses your function to get names
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "ElitePlayerList", 
    Callback = function(Option)
        -- Sets the target when you click a name in the list
        TargetEngine.SelectedPlayer = GetPlayerByShortName(Option[1])
    end,
})

Tab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerList())
    end,
})
Tab:CreateSection("")
Tab:CreateButton({
    Name = "Elite Fling Target",
    Callback = function()
        if TargetEngine.SelectedPlayer then
            SetupFlingSafety()
            task.spawn(function() TargetEngine:SpinFling(TargetEngine.SelectedPlayer) end)
        else
            Notify("Error", "No player selected!")
        end
    end,
})

Tab:CreateToggle({
    Name = "Loop Fling Target",
    CurrentValue = false,
    Callback = function(Value)
        TargetEngine.LoopActive = Value
        if Value then 
            SetupFlingSafety() 
            task.spawn(function()
                while TargetEngine.LoopActive do
                    if TargetEngine.SelectedPlayer then
                        TargetEngine:SpinFling(TargetEngine.SelectedPlayer)
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

Tab:CreateButton({
    Name = "Elite Fling All",
    Callback = function()
        SetupFlingSafety()
        Notify("Elite Utility", "Flinging all server...")
        task.spawn(function()
            local players = game.Players:GetPlayers()
            for _, p in pairs(players) do
                if p ~= LP and p.Character then
                    TargetEngine:SpinFling(p)
                    task.wait(0.2)
                end
            end
        end)
    end,
})
game.Players.PlayerAdded:Connect(RefreshEverything)
game.Players.PlayerRemoving:Connect(RefreshEverything)


-- =========================================================-Elite Troll Section –=========================================================================

-- Elite Troll Engine
local TrollEngine = {
    Target = nil,
    Connections = {},
    -- Feature States
    OrbitActive = false,
    MimicActive = false,
    GlitchActive = false,
    HeadSitActive = false,
    LagFakeActive = false,
    -- Settings
    OrbitSpeed = 5,
    OrbitDistance = 5,
    VoidPart = nil
}

-- 1. UTILITY: Troll-Specific Player Search
local function GetTrollPlayerList()
    local list = {}
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP then table.insert(list, v.DisplayName) end
    end
    return list
end

local function GetTrollTarget(name)
    if not name then return nil end
    name = name:lower()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP and (v.DisplayName:lower():find(name) or v.Name:lower():find(name)) then
            return v
        end
    end
    return nil
end

-- 2. THE UI SECTION (Dedicated List & Search)
Tab:CreateSection("Elite Troll Target")

local TrollDropdown = Tab:CreateDropdown({
    Name = "Troll Target: None",
    Options = GetTrollPlayerList(),
    CurrentOption = {""},
    Callback = function(Option)
        TrollEngine.Target = GetTrollTarget(Option[1])
    end,
})

Tab:CreateInput({
    Name = "Search Troll Target",
    PlaceholderText = "Type name...",
    Callback = function(Text)
        local found = GetTrollTarget(Text)
        if found then
            TrollEngine.Target = found
            TrollDropdown:Set({found.DisplayName})
        end
    end,
})

Tab:CreateButton({
    Name = "Refresh Troll List",
    Callback = function()
        TrollDropdown:Refresh(GetTrollPlayerList())
    end,
})

-- 3. ELITE FEATURES
Tab:CreateSection("Troll Features")

-- A. Elite Orbit (The Moon)
Tab:CreateToggle({
    Name = "Elite Orbit",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.OrbitActive = Value
        local angle = 0
        task.spawn(function()
            while TrollEngine.OrbitActive do
                if TrollEngine.Target and TrollEngine.Target.Character then
                    local HRP = LP.Character:FindFirstChild("HumanoidRootPart")
                    local THRP = TrollEngine.Target.Character:FindFirstChild("HumanoidRootPart")
                    if HRP and THRP then
                        angle = angle + TrollEngine.OrbitSpeed
                        HRP.CFrame = THRP.CFrame * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, TrollEngine.OrbitDistance)
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end,
})

-- B. Elite Mimic (The Shadow)
Tab:CreateToggle({
    Name = "Elite Mimic",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.MimicActive = Value
        
        -- Void Protection Part
        if Value then
            TrollEngine.VoidPart = Instance.new("Part", workspace)
            TrollEngine.VoidPart.Size = Vector3.new(10, 1, 10)
            TrollEngine.VoidPart.Transparency = 1
            TrollEngine.VoidPart.Anchored = true
        else
            if TrollEngine.VoidPart then TrollEngine.VoidPart:Destroy() end
        end

        task.spawn(function()
            while TrollEngine.MimicActive do
                if TrollEngine.Target and TrollEngine.Target.Character then
                    local Char = LP.Character
                    local TChar = TrollEngine.Target.Character
                    
                    if Char:FindFirstChild("HumanoidRootPart") and TChar:FindFirstChild("HumanoidRootPart") then
                        -- Mirror Position
                        Char.HumanoidRootPart.CFrame = TChar.HumanoidRootPart.CFrame
                        -- Mirror Jump
                        Char.Humanoid.Jump = TChar.Humanoid.Jump
                        -- Update Void Part Position
                        TrollEngine.VoidPart.CFrame = TChar.HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end,
})

-- C. Elite Glitcher (Animation Chaos)
Tab:CreateToggle({
    Name = "Elite Glitcher",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.GlitchActive = Value
        task.spawn(function()
            while TrollEngine.GlitchActive do
                local Char = LP.Character
                if Char then
                    for _, v in pairs(Char:GetDescendants()) do
                        if v:IsA("Motor6D") then
                            v.C0 = v.C0 * CFrame.Angles(math.rad(math.random(-30,30)), math.rad(math.random(-30,30)), math.rad(math.random(-30,30)))
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end,
})

-- D. Elite Head-Sitter
Tab:CreateToggle({
    Name = "Elite Head-Sitter",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.HeadSitActive = Value
        task.spawn(function()
            while TrollEngine.HeadSitActive do
                if TrollEngine.Target and TrollEngine.Target.Character then
                    local HRP = LP.Character:FindFirstChild("HumanoidRootPart")
                    local THRP = TrollEngine.Target.Character:FindFirstChild("HumanoidRootPart")
                    if HRP and THRP then
                        HRP.CFrame = THRP.CFrame * CFrame.new(0, 2, 0)
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end,
})

-- E. Elite Lag-Fake (Egor Style)
Tab:CreateToggle({
    Name = "Elite Lag-Fake",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.LagFakeActive = Value
        local lastPos = nil
        task.spawn(function()
            while TrollEngine.LagFakeActive do
                local HRP = LP.Character:FindFirstChild("HumanoidRootPart")
                if HRP then
                    -- Store pos, freeze, snap back (Egor style)
                    lastPos = HRP.CFrame
                    task.wait(0.2)
                    if TrollEngine.LagFakeActive then
                        HRP.Anchored = true
                        task.wait(0.1)
                        HRP.Anchored = false
                        HRP.CFrame = lastPos -- Snaps back to look like lag
                    end
                end
                task.wait(0.05)
            end
        end)
    end,
})

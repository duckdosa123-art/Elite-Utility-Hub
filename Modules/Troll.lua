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

-- Elite Targeting Physics Engine
local TargetEngine = {
    Active = false,
    LoopActive = false,
    SelectedPlayer = nil,
    OriginalPos = nil,
    Connections = {},
}

-- 1. UTILITY: Player Search & List Management
local function GetPlayerByShortName(name)
    name = name:lower()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP and (v.DisplayName:lower():sub(1, #name) == name or v.Name:lower():sub(1, #name) == name) then
            return v
        end
    end
    return nil
end

local function GetPlayerList()
    local list = {}
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP then table.insert(list, v.DisplayName) end
    end
    return list
end

-- 2. CORE: The Fling Execution (Fixed TP Logic)
function TargetEngine:Execute(Target)
    if not Target or not Target.Character then return end
    local TChar = Target.Character
    local THRP = TChar:FindFirstChild("HumanoidRootPart")
    local MyChar = LP.Character
    local MyHRP = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    local MyHum = MyChar and MyChar:FindFirstChild("Humanoid")

    if not THRP or not MyHRP or not MyHum then return end

    -- Save Position & Prep Physics
    self.OriginalPos = MyHRP.CFrame
    local oldVel = MyHRP.AssemblyLinearVelocity
    
    -- "Ghost Mode" Prep
    for _, v in pairs(MyChar:GetDescendants()) do
        if v:IsA("BasePart") then v.Massless = true end
    end

    -- TELEPORT & STRIKE
    -- We TP slightly behind and set massive velocity TOWARDS them
    local strikeCount = 0
    repeat
        task.wait()
        strikeCount = strikeCount + 1
        
        -- Lock to target position
        MyHRP.CFrame = THRP.CFrame * CFrame.new(0, 0, 1) 
        -- Spike velocity
        MyHRP.AssemblyLinearVelocity = Vector3.new(99999999, 99999999, 99999999)
        MyHRP.AssemblyAngularVelocity = Vector3.new(0, 99999999, 0)
        
    until strikeCount > 10 or (THRP.AssemblyLinearVelocity.Magnitude > 200) or not Target.Parent
    
    -- RETURN SAFETY
    MyHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    MyHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    MyHRP.CFrame = self.OriginalPos
    
    -- Cleanup Masses
    for _, v in pairs(MyChar:GetDescendants()) do
        if v:IsA("BasePart") then v.Massless = false end
    end
end

-- 3. PERMANENT GODMODE & NOCLIP (For Targeting)
local function EnableTargetPhysics()
    local Char = LP.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    if not Hum then return end

    -- Health Lock (For Natural Disaster/Killbricks)
    table.insert(TargetEngine.Connections, RunService.Heartbeat:Connect(function()
        if Hum then 
            Hum.Health = Hum.MaxHealth 
            if Hum:GetState() == Enum.HumanoidStateType.Dead then
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end))

    -- Collision Lock (For Fling Accuracy)
    table.insert(TargetEngine.Connections, RunService.Stepped:Connect(function()
        if Char then
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end))
end
-- Rayfield Toggle Integration
Tab:CreateSection("Fling - Disable Fling Guard First!")
Tab:CreateToggle({
    Name = "Elite WalkFling - NoClip",
    CurrentValue = false,
    Flag = "WalkFling",
    Callback = function(Value)
        if Value then
            task.spawn(function() WalkFlingEngine:Start() end)
        else
            WalkFlingEngine:Stop()
        end
    end,
})
Tab:CreateSection("Advance Fling - Disable Fling Guard First!")
local PlayerDropdown = Tab:CreateDropdown({
    Name = "Select Target",
    Options = GetPlayerList(),
    CurrentOption = {""},
    Callback = function(Option)
        TargetEngine.SelectedPlayer = GetPlayerByShortName(Option[1])
    end,
})

Tab:CreateInput({
    Name = "Quick Search Player",
    PlaceholderText = "Type half name...",
    Callback = function(Text)
        if Text == "" then return end
        local found = GetPlayerByShortName(Text)
        if found then
            TargetEngine.SelectedPlayer = found
            PlayerDropdown:Set({found.DisplayName}) -- Auto-select in UI
            _G.EliteLog("Auto-targeted: " .. found.DisplayName, "success")
        end
    end,
})

Tab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerList())
    end,
})

Tab:CreateButton({
    Name = "Fling Target",
    Callback = function()
        if TargetEngine.SelectedPlayer then
            EnableTargetPhysics() -- Ensure Godmode is active during TP
            TargetEngine:Execute(TargetEngine.SelectedPlayer)
            -- Clean up physics after one-time fling
            for _, v in pairs(TargetEngine.Connections) do v:Disconnect() end
        end
    end,
})

Tab:CreateToggle({
    Name = "Loop Fling Target",
    CurrentValue = false,
    Callback = function(Value)
        TargetEngine.LoopActive = Value
        if Value then EnableTargetPhysics() end
        task.spawn(function()
            while TargetEngine.LoopActive do
                if TargetEngine.SelectedPlayer then
                    TargetEngine:Execute(TargetEngine.SelectedPlayer)
                end
                task.wait(1)
            end
        end)
    end,
})

Tab:CreateButton({
    Name = "Fling All (Server Purge)",
    Callback = function()
        EnableTargetPhysics()
        _G.EliteLog("Purging server...", "warn")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                TargetEngine:Execute(p)
                task.wait(0.1)
            end
        end
        _G.EliteLog("Purge Complete", "success")
    end,
})

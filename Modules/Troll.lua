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

-- Elite Targeting & Physics Engine
local TargetEngine = {
    SelectedPlayer = nil,
    LoopActive = false,
    IsFlinging = false,
    OriginalPos = nil
}

-- Utility: Smart Name Search (Shortening)
local function GetPlayerByShortName(name)
    name = name:lower()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP and (v.DisplayName:lower():sub(1, #name) == name or v.Name:lower():sub(1, #name) == name) then
            return v
        end
    end
    return nil
end

-- The Verification Scanner: TP -> Hit -> Scan -> Return
function TargetEngine:Execute(Target)
    if not Target or not Target.Character then return end
    local TChar = Target.Character
    local THRP = TChar:FindFirstChild("HumanoidRootPart")
    local THum = TChar:FindFirstChild("Humanoid")
    local MyChar = LP.Character
    local MyHRP = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    
    if not THRP or not MyHRP or THum.Health <= 0 then return end

    self.IsFlinging = true
    self.OriginalPos = MyHRP.CFrame
    
    -- Set Massless to prevent physics drag during TP
    for _, v in pairs(MyChar:GetDescendants()) do
        if v:IsA("BasePart") then v.Massless = true end
    end

    -- 1. TP & Hit
    MyHRP.CFrame = THRP.CFrame * CFrame.new(0, 0, 1.5)
    MyHRP.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
    
    -- 2. THE SCAN: Wait until target's velocity spikes or they are far away
    local timeout = 0
    repeat
        task.wait()
        timeout = timeout + 1
        -- If target velocity is high or they are moved, the fling worked
    until (THRP.AssemblyLinearVelocity.Magnitude > 100) or timeout > 20 or not self.Active

    -- 3. RETURN
    MyHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    MyHRP.CFrame = self.OriginalPos
    
    -- Reset Physics
    for _, v in pairs(MyChar:GetDescendants()) do
        if v:IsA("BasePart") then v.Massless = false end
    end
    
    self.IsFlinging = false
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
local PlayerList = {}
local function RefreshList()
    PlayerList = {}
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP then table.insert(PlayerList, v.DisplayName) end
    end
end
RefreshList()

local TargetDropdown = Tab:CreateDropdown({
    Name = "Selected: None",
    Options = PlayerList,
    CurrentOption = {""},
    Callback = function(Option)
        TargetEngine.SelectedPlayer = GetPlayerByShortName(Option[1])
    end,
})

Tab:CreateInput({
    Name = "Search & Auto-Select",
    PlaceholderText = "Type part of name...",
    Callback = function(Text)
        if Text == "" then return end
        local found = GetPlayerByShortName(Text)
        if found then
            TargetEngine.SelectedPlayer = found
            TargetDropdown:Set({found.DisplayName}) -- Auto-updates dropdown
            _G.EliteLog("Auto-Selected: " .. found.DisplayName, "info")
        end
    end,
})

Tab:CreateButton({
    Name = "Fling Target",
    Callback = function()
        if TargetEngine.SelectedPlayer then
            TargetEngine:Execute(TargetEngine.SelectedPlayer)
        else
            Rayfield:Notify({Title = "Error", Content = "No target selected!", Duration = 2})
        end
    end,
})

Tab:CreateToggle({
    Name = "Loop Fling",
    CurrentValue = false,
    Callback = function(Value)
        TargetEngine.LoopActive = Value
        task.spawn(function()
            while TargetEngine.LoopActive do
                if TargetEngine.SelectedPlayer and not TargetEngine.IsFlinging then
                    -- Only fling if they are alive
                    local char = TargetEngine.SelectedPlayer.Character
                    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        TargetEngine:Execute(TargetEngine.SelectedPlayer)
                    end
                end
                task.wait(1.5)
            end
        end)
    end,
})

Tab:CreateButton({
    Name = "Fling All",
    Callback = function()
        _G.EliteLog("Starting Server Purge", "warn")
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= LP and v.Character then
                TargetEngine:Execute(v)
                task.wait(0.1)
            end
        end
    end,
})

-- Keep list updated
game.Players.PlayerAdded:Connect(function() RefreshList(); TargetDropdown:Refresh(PlayerList) end)
game.Players.PlayerRemoving:Connect(function() RefreshList(); TargetDropdown:Refresh(PlayerList) end)

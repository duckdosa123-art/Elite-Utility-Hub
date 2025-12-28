-- WalkFling Logic for Elite-Utility-Hub (Reference-Based Perfection)
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    TargetPlayer = nil,
    LoopFlinging = false,
    OriginalPos = nil
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
-- Utility: Save and Restore Position
function WalkFlingEngine:SavePos()
    local HRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if HRP then self.OriginalPos = HRP.CFrame end
end

function WalkFlingEngine:ReturnPos()
    local HRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if HRP and self.OriginalPos then HRP.CFrame = self.OriginalPos end
end

-- Core Fling Action (TP -> Spike -> Return)
function WalkFlingEngine:ExecuteFling(Target)
    if not Target or not Target.Character then return end
    local TargetHRP = Target.Character:FindFirstChild("HumanoidRootPart")
    local MyHRP = LP.Character:FindFirstChild("HumanoidRootPart")
    
    if TargetHRP and MyHRP then
        self:SavePos()
        
        -- TP to target (slightly offset to ensure Touch)
        MyHRP.CFrame = TargetHRP.CFrame * CFrame.new(0, 0, 1)
        
        -- The Surgical Spike (High velocity for 1 frame)
        MyHRP.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
        task.wait(0.1) -- Time for physics to register impact
        
        self:ReturnPos()
    end
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
local PlayerNames = {}
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= LP then table.insert(PlayerNames, p.DisplayName) end
end

local SearchBox = Tab:CreateInput({
    Name = "Search Player",
    PlaceholderText = "Type display name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local filtered = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.DisplayName:lower():find(Text:lower()) and p ~= LP then
                table.insert(filtered, p.DisplayName)
            end
        end
        -- Assuming your Dropdown variable is 'PlayerDropdown'
        PlayerDropdown:Refresh(filtered)
    end,
})

local PlayerDropdown = Tab:CreateDropdown({
    Name = "Select Target",
    Options = PlayerNames,
    CurrentOption = "",
    MultipleOptions = false,
    Flag = "FlingTarget",
    Callback = function(Option)
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.DisplayName == Option[1] then
                WalkFlingEngine.TargetPlayer = p
                break
            end
        end
    end,
})

Tab:CreateButton({
    Name = "Fling Selected",
    Callback = function()
        if WalkFlingEngine.TargetPlayer then
            WalkFlingEngine:ExecuteFling(WalkFlingEngine.TargetPlayer)
        end
    end,
})

Tab:CreateToggle({
    Name = "Loop Fling Selected",
    CurrentValue = false,
    Flag = "LoopFling",
    Callback = function(Value)
        WalkFlingEngine.LoopFlinging = Value
        task.spawn(function()
            while WalkFlingEngine.LoopFlinging do
                if WalkFlingEngine.TargetPlayer then
                    WalkFlingEngine:ExecuteFling(WalkFlingEngine.TargetPlayer)
                end
                task.wait(2) -- Wait for respawn/physics reset
            end
        end)
    end,
})

Tab:CreateButton({
    Name = "Fling All",
    Callback = function()
        self:SavePos()
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                WalkFlingEngine:ExecuteFling(p)
                task.wait(0.2)
            end
        end
        self:ReturnPos()
    end,
})

-- Auto-Update Player List when someone joins/leaves
game.Players.PlayerAdded:Connect(function()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.DisplayName) end
    end
    PlayerDropdown:Refresh(list)
end)

game.Players.PlayerRemoving:Connect(function()
    local list = {}
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.DisplayName) end
    end
    PlayerDropdown:Refresh(list)
end)

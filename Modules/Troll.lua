-- [[ ELITE-UTILITY-HUB: TROLL MODULE - NORMAL WALKFLING ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFlingEngine = {
    Active = false,
    Connections = {},
    Power = 9999999 -- Invisible Jitter Power
}

-- // THE INVISIBLE BRUTE FORCE ENGINE //
function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    _G.EliteLog("WalkFling: Invisible Power Active", "success")
    
    -- 1. GODMODE TACTIC (PRESERVED)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if Hum and Hum.Parent then
            Hum.Health = Hum.MaxHealth
            if Hum:GetState() == Enum.HumanoidStateType.Dead then
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
    table.insert(self.Connections, godmodeConn)
    
    -- 2. STABILIZED NOCLIP
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    -- 3. INVISIBLE JITTER PHYSICS (THE "NORMAL LOOK" FIX)
    -- We oscillate X and Z so fast the eye can't see it, but the Y stays grounded.
    local physicsConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP then return end
        
        local Force = WalkFlingEngine.Power
        -- High-frequency oscillation (tick * 100) makes the movement invisible
        local Jitter = math.sin(tick() * 100) 
        
        -- Y is locked to 28.5 (Grounded)
        -- Angular is 0 (No Spinning)
        HRP.AssemblyLinearVelocity = Vector3.new(Jitter * Force, 28.5, Jitter * Force)
        HRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    table.insert(self.Connections, physicsConn)
    
    -- 4. SPATIAL QUERY (ANY-TO-ANY DETECTION)
    local queryConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP then return end
        
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {Char}
        
        -- Detects victims in the "Kill Zone"
        local parts = workspace:GetPartBoundsInBox(HRP.CFrame, Vector3.new(5, 5, 5), overlapParams)
        
        for _, part in pairs(parts) do
            local vChar = part.Parent
            local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
            
            if vHum and vHum.Health > 0 then
                -- The Jitter physics above is already running.
                -- Overlapping hitboxes will trigger the launch.
                break 
            end
        end
    end)
    table.insert(self.Connections, queryConn)
end

function WalkFlingEngine:Stop()
    self.Active = false
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if HRP then
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
    end
    
    if Hum then
        pcall(function()
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
    
    if Char then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
    _G.EliteLog("WalkFling Engine Disabled", "info")
end

-- // UI SECTION //

Tab:CreateSection("Fling - Disable Fling Guard First!")

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Enabled! Normal Appearance & Grounded Physics.",
                Duration = 4,
            })
            _G.EliteLog("Elite WalkFling enabled (Stealth Mode)", "info")
            WalkFlingEngine:Start()
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Disabled!",
                Duration = 2,
            })
            _G.EliteLog("Elite WalkFling disabled", "info")
            WalkFlingEngine:Stop()
        end
    end,
})

-- Respawn Logic
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine.Active then WalkFlingEngine:Stop() end
end)

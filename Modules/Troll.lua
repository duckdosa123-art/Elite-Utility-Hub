-- [[ ELITE-UTILITY-HUB: TROLL MODULE - STABLE WALKFLING ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFlingEngine = {
    Active = false,
    Connections = {},
    Power = 99999999 -- The IY God Power
}

-- // ROBLOX NATIVE NOTIFICATION SYSTEM //
local function SendNativeNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6034281358",
        Duration = 4
    })
end

-- // THE STABLE BRUTE FORCE ENGINE //
function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    _G.EliteLog("WalkFling: Stable Physics Mode Active", "success")
    
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
    
    -- 2. STABILITY LOOP (The fix for self-flinging)
    -- This forces your Linear Velocity to stay low so you don't fly away
    local stabilityConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP then return end
        
        -- High Rotational Velocity (The Weapon)
        HRP.AssemblyAngularVelocity = Vector3.new(0, self.Power, 0)
        
        -- Locked Linear Velocity (The Shield)
        -- We only allow the Y-jitter for Netless, stopping all "Recoil" movement
        HRP.AssemblyLinearVelocity = Vector3.new(0, 28.5 + math.sin(tick() * 10), 0)
    end)
    table.insert(self.Connections, stabilityConn)
    
    -- 3. NOCLIP LOOP (Local Collision Disable)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    -- 4. ANY-TO-ANY DETECTION (Spatial Fix)
    local queryConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP then return end
        
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {Char}
        
        -- Check for victims in proximity
        local parts = workspace:GetPartBoundsInBox(HRP.CFrame, Vector3.new(4, 5, 4), overlapParams)
        
        for _, part in pairs(parts) do
            local vChar = part.Parent
            local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
            
            if vHum and vHum.Health > 0 then
                -- When touching, we add a tiny Linear "Kick" to the victim
                -- but because of our Stability Loop (Step 2), we stay grounded.
                HRP.AssemblyLinearVelocity = Vector3.new(self.Power, 28.5, self.Power)
                RunService.RenderStepped:Wait() -- Pulse only for 1 frame
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
    _G.EliteLog("WalkFling Disabled", "info")
end

-- // UI SECTION //

Tab:CreateSection("Fling - Disable Fling Guard First!")

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            SendNativeNotification("Elite WalkFling", "Enabled! You are now a stable kill-brick.")
            _G.EliteLog("Elite WalkFling enabled", "info")
            WalkFlingEngine:Start()
        else
            SendNativeNotification("Elite WalkFling", "Disabled!")
            _G.EliteLog("Elite WalkFling disabled", "info")
            WalkFlingEngine:Stop()
        end
    end,
})

-- Respawn Fix
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine.Active then WalkFlingEngine:Stop() end
end)

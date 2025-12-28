-- ============================================
-- ELITE WALKFLING - PHYSICS ENGINE
-- ============================================

local WalkFlingEngine = {}
WalkFlingEngine.Active = false
WalkFlingEngine.Connection = nil

-- Physics Configuration
local CONFIG = {
    POWER = 20000,              -- Fling power (similar to IY)
    ROTATION_SPEED = 9e9,       -- Angular velocity magnitude
    PLAYER_NETLESS_HEIGHT = 25, -- Keep network ownership
}

function WalkFlingEngine:Start()
    if self.Active then return end
    self.Active = true
    
    local Char = LP.Character
    if not Char then 
        _G.EliteLog("No character found", "error")
        return 
    end
    
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChild("Humanoid")
    
    if not HRP or not Hum then
        _G.EliteLog("Missing character components", "error")
        return
    end
    
    -- Store original collision states
    local originalStates = {}
    for _, part in pairs(Char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= HRP then
            originalStates[part] = part.CanCollide
        end
    end
    
    _G.EliteLog("WalkFling engine started", "success")
    
    -- Main physics loop
    self.Connection = RunService.Heartbeat:Connect(function()
        if not self.Active then
            self.Connection:Disconnect()
            
            -- Restore states
            for part, state in pairs(originalStates) do
                if part and part.Parent then
                    part.CanCollide = state
                end
            end
            
            if HRP and HRP.Parent then
                HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                HRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            
            _G.EliteLog("WalkFling engine stopped", "info")
            return
        end
        
        -- Character validation
        if not Char or not Char.Parent or not HRP or not HRP.Parent or not Hum or Hum.Health <= 0 then
            self:Stop()
            return
        end
        
        -- Ensure walking state (NOT PlatformStand)
        if Hum.PlatformStand then
            Hum.PlatformStand = false
        end
        
        -- Apply ghosting (CanCollide false for all except HRP)
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") and part ~= HRP then
                part.CanCollide = false
            end
        end
        
        -- Calculate oscillating spin direction
        local t = tick()
        local spinX = math.sin(t * 11)
        local spinY = math.cos(t * 13) 
        local spinZ = math.sin(t * 17)
        
        -- Apply linear velocity (maintains height for netless)
        HRP.AssemblyLinearVelocity = Vector3.new(
            spinX * CONFIG.POWER,
            CONFIG.PLAYER_NETLESS_HEIGHT,
            spinZ * CONFIG.POWER
        )
        
        -- Apply angular velocity (creates the fling effect)
        HRP.AssemblyAngularVelocity = Vector3.new(
            spinX * CONFIG.ROTATION_SPEED,
            spinY * CONFIG.ROTATION_SPEED,
            spinZ * CONFIG.ROTATION_SPEED
        )
    end)
end

function WalkFlingEngine:Stop()
    self.Active = false
end

function WalkFlingEngine:IsActive()
    return self.Active
end


-- ============================================
-- UI INTEGRATION
-- ============================================

local Toggle = Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Flag = "EliteWalkFling_Toggle",
    Callback = function(Value)
        if Value then
            -- Show notification
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Enabled!",
                Duration = 2,
            })
            
            -- Start engine
            WalkFlingEngine:Start()
        else
            -- Stop engine
            WalkFlingEngine:Stop()
            
            -- Show notification
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Disabled!",
                Duration = 2,
            })
        end
    end,
})

-- Cleanup on death/respawn
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine:IsActive() then
        WalkFlingEngine:Stop()
        Toggle:Set(false)
    end
end)

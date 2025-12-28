-- ============================================
-- ELITE WALKFLING - PHYSICS ENGINE (SEPARATED)
-- Based on Infinite Yield's walkfling method
-- ============================================

local WalkFlingEngine = {}
WalkFlingEngine.Active = false
WalkFlingEngine.Connections = {}
WalkFlingEngine.OriginalHealth = nil
WalkFlingEngine.OriginalMaxHealth = nil

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
    
    _G.EliteLog("WalkFling engine started", "success")
    
    -- Store original health values
    self.OriginalHealth = Hum.Health
    self.OriginalMaxHealth = Hum.MaxHealth
    
    -- Disable death
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum.BreakJointsOnDeath = false
    
    -- Keep health maxed (godmode)
    table.insert(self.Connections, RunService.Stepped:Connect(function()
        if not self.Active then return end
        Hum.Health = math.huge
        Hum.MaxHealth = math.huge
    end))
    
    -- Main fling loop
    HRP.CanCollide = false
    
    -- Enable jumping by setting FreeFalling state instead of Physics
    Hum:ChangeState(Enum.HumanoidStateType.Freefall)
    
    task.spawn(function()
        while self.Active and HRP and HRP.Parent do
            RunService.Heartbeat:Wait()
            
            -- Store current velocity
            local currentVel = HRP.Velocity
            
            -- Apply MASSIVE velocity spike
            HRP.Velocity = currentVel * 99999999 + Vector3.new(0, 99999999, 0)
            
            -- Wait ONE frame
            RunService.RenderStepped:Wait()
            
            -- Reset velocity back to normal
            HRP.Velocity = currentVel
            
            -- Small netless adjustment
            RunService.Stepped:Wait()
            HRP.Velocity = currentVel + Vector3.new(0, 0.1, 0)
        end
    end)
end

function WalkFlingEngine:Stop()
    self.Active = false
    
    -- Disconnect all connections
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
    
    -- Restore character state
    local Char = LP.Character
    if Char then
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        
        if Hum then
            -- Restore original health FIRST
            if self.OriginalMaxHealth and self.OriginalHealth then
                Hum.MaxHealth = self.OriginalMaxHealth
                task.wait(0.1)
                Hum.Health = self.OriginalHealth
            else
                -- Fallback to 100 if we don't have stored values
                Hum.MaxHealth = 100
                task.wait(0.1)
                Hum.Health = 100
            end
            
            -- Wait before changing states
            task.wait(0.2)
            
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum.BreakJointsOnDeath = true
            
            -- Return to normal state
            Hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        
        if HRP then
            HRP.CanCollide = true
            HRP.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    -- Reset stored values
    self.OriginalHealth = nil
    self.OriginalMaxHealth = nil
end

function WalkFlingEngine:IsActive()
    return self.Active
end


-- ============================================
-- UI INTEGRATION (SEPARATED)
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
                Text = "Enabled! If it doesn't work then disable Fling Guard",
                Duration = 4,
            })
            
            _G.EliteLog("Elite WalkFling enabled - Walk into players to fling them", "info")
            
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
            
            _G.EliteLog("Elite WalkFling disabled", "info")
        end
    end,
})

-- Cleanup on death/respawn
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine:IsActive() then
        WalkFlingEngine:Stop()
        Toggle:Set(false)
        _G.EliteLog("WalkFling disabled due to respawn", "warning")
    end
end)

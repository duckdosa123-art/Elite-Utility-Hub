-- ============================================
-- ELITE WALKFLING - PHYSICS ENGINE (IMPROVED)
-- High-performance touch-based fling system
-- ============================================

local WalkFlingEngine = {}
WalkFlingEngine.Active = false
WalkFlingEngine.Connections = {}
WalkFlingEngine.TouchCooldowns = {} -- Prevent spam on same target

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
    
    -- CRITICAL: Network ownership claim
    if HRP:IsGrounded() then
        HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    
    -- GODMODE - Prevent death completely
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    -- Continuous godmode loop
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if Hum and Hum.Parent then
            Hum.Health = Hum.MaxHealth
            -- Prevent any state changes
            if Hum:GetState() == Enum.HumanoidStateType.Dead then
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
    table.insert(self.Connections, godmodeConn)
    
    -- Enable collision for better touch detection
    HRP.CanCollide = true
    HRP.Massless = false -- Need mass for physics
    
    -- IMPROVED: Direct velocity manipulation on RenderStepped for instant response
    local flingConn = RunService.RenderStepped:Connect(function()
        if not self.Active then return end
        
        -- Get all touching parts this frame
        local touchingParts = HRP:GetTouchingParts()
        
        for _, hit in ipairs(touchingParts) do
            -- Check if we touched another player's character
            local otherChar = hit.Parent
            if otherChar and otherChar:FindFirstChild("Humanoid") and otherChar ~= Char then
                local otherHum = otherChar:FindFirstChild("Humanoid")
                local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
                
                -- Check cooldown to prevent multiple flings per second
                local targetId = otherChar.Name
                local lastFling = self.TouchCooldowns[targetId] or 0
                local currentTime = tick()
                
                if otherHum and otherHum.Health > 0 and otherHRP and (currentTime - lastFling) > 0.1 then
                    -- Set cooldown
                    self.TouchCooldowns[targetId] = currentTime
                    
                    -- Store BOTH velocities
                    local myVel = HRP.AssemblyLinearVelocity
                    local targetVel = otherHRP.AssemblyLinearVelocity
                    
                    -- Calculate fling direction (away from us)
                    local flingDir = (otherHRP.Position - HRP.Position).Unit
                    local flingPower = Vector3.new(flingDir.X * 1000, 99999999, flingDir.Z * 1000)
                    
                    -- INSTANT FLING: Apply to target
                    otherHRP.AssemblyLinearVelocity = flingPower
                    
                    -- CRITICAL: Counter-momentum to stay in place
                    HRP.AssemblyLinearVelocity = Vector3.new(myVel.X, 0, myVel.Z)
                    
                    -- Reset after ONE frame
                    task.defer(function()
                        if HRP and HRP.Parent then
                            HRP.AssemblyLinearVelocity = myVel
                        end
                    end)
                    
                    -- Ensure we stay alive
                    if Hum then
                        Hum.Health = Hum.MaxHealth
                    end
                    
                    _G.EliteLog("Flung: " .. targetId, "success")
                end
            end
        end
    end)
    table.insert(self.Connections, flingConn)
    
    -- BACKUP: Traditional touch detection for reliability
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            local otherChar = hit.Parent
            if otherChar and otherChar:FindFirstChild("Humanoid") and otherChar ~= Char then
                local otherHum = otherChar:FindFirstChild("Humanoid")
                local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
                
                -- Check cooldown
                local targetId = otherChar.Name
                local lastFling = self.TouchCooldowns[targetId] or 0
                local currentTime = tick()
                
                if otherHum and otherHum.Health > 0 and otherHRP and (currentTime - lastFling) > 0.1 then
                    self.TouchCooldowns[targetId] = currentTime
                    
                    -- Quick velocity spike
                    local myVel = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(0, 99999999, 0)
                    
                    task.wait()
                    
                    if HRP and HRP.Parent then
                        HRP.AssemblyLinearVelocity = myVel
                    end
                    
                    if Hum then
                        Hum.Health = Hum.MaxHealth
                    end
                end
            end
        end)
        
        table.insert(self.Connections, touchConn)
    end
    
    -- Setup touch on all character parts
    for _, part in pairs(Char:GetDescendants()) do
        setupTouch(part)
    end
    
    -- Handle new parts
    local childConn = Char.DescendantAdded:Connect(function(part)
        if self.Active then
            task.wait()
            setupTouch(part)
        end
    end)
    table.insert(self.Connections, childConn)
    
    -- Clear cooldowns periodically
    local cleanupConn = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        for id, time in pairs(self.TouchCooldowns) do
            if currentTime - time > 2 then
                self.TouchCooldowns[id] = nil
            end
        end
    end)
    table.insert(self.Connections, cleanupConn)
end

function WalkFlingEngine:Stop()
    self.Active = false
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")
    
    -- Disconnect all connections FIRST
    for _, conn in pairs(self.Connections) do
        if conn then 
            pcall(function() conn:Disconnect() end)
        end
    end
    self.Connections = {}
    
    -- Clear cooldowns
    self.TouchCooldowns = {}
    
    -- Small wait for physics to settle
    task.wait(0.1)
    
    -- Restore character state safely
    if HRP and HRP.Parent then
        pcall(function()
            HRP.CanCollide = true
            HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.Massless = false
        end)
    end
    
    if Hum and Hum.Parent then
        -- Re-enable states
        pcall(function()
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
        
        -- Ensure full health before re-enabling death
        task.wait(0.1)
        pcall(function()
            Hum.Health = Hum.MaxHealth
            task.wait()
            if Hum.Health <= 0 then
                Hum.Health = Hum.MaxHealth
            end
        end)
    end
    
    _G.EliteLog("WalkFling engine stopped", "info")
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
LP.CharacterAdded:Connect(function(char)
    if WalkFlingEngine:IsActive() then
        WalkFlingEngine:Stop()
        Toggle:Set(false)
        _G.EliteLog("WalkFling disabled due to respawn", "warning")
    end
    
    -- Wait for character to fully load
    task.wait(1)
    
    -- Clear any lingering cooldowns
    WalkFlingEngine.TouchCooldowns = {}
end)

-- ============================================
-- ELITE WALKFLING - PHYSICS ENGINE (SEPARATED)
-- Based on Infinite Yield's walkfling method
-- ============================================

local WalkFlingEngine = {}
WalkFlingEngine.Active = false
WalkFlingEngine.Connections = {}

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
    
    -- GODMODE - Prevent death completely while active
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if Hum and Hum.Parent then
            Hum.Health = Hum.MaxHealth
        end
    end)
    table.insert(self.Connections, godmodeConn)
    
    -- Main fling loop - ONLY when touching other players
    HRP.CanCollide = false
    
    -- Set up touch detection on all body parts
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            -- Check if we touched another player's character
            local otherChar = hit.Parent
            if otherChar and otherChar:FindFirstChild("Humanoid") and otherChar ~= Char then
                local otherHum = otherChar:FindFirstChild("Humanoid")
                local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
                
                if otherHum and otherHum.Health > 0 and otherHRP then
                    -- Store current velocity
                    local currentVel = HRP.Velocity
                    
                    -- Apply MASSIVE velocity spike
                    HRP.Velocity = Vector3.new(0, 99999999, 0)
                    
                    -- Wait ONE frame
                    RunService.RenderStepped:Wait()
                    
                    -- Reset velocity back to normal
                    HRP.Velocity = currentVel
                    
                    -- Ensure we stay alive
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
    
    -- Handle new parts being added
    local childConn = Char.DescendantAdded:Connect(function(part)
        if self.Active then
            setupTouch(part)
        end
    end)
    table.insert(self.Connections, childConn)
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
    
    -- Small wait for cleanup
    task.wait(0.05)
    
    -- Restore character state safely
    if HRP and HRP.Parent then
        HRP.CanCollide = true
        HRP.Velocity = Vector3.new(0, 0, 0)
        HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    
    if Hum and Hum.Parent then
        -- Re-enable death
        pcall(function()
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end)
        
        -- Ensure health is full
        task.wait(0.05)
        pcall(function()
            if Hum.Health <= 0 then
                Hum.Health = Hum.MaxHealth
            end
        end)
    end
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
en

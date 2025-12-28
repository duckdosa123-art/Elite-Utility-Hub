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
    
    -- Disconnect all connections FIRST
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
    
    -- Wait to ensure all connections are cleaned up
    task.wait(0.1)
    
    -- Restore character state
    local Char = LP.Character
    if Char then
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        
        if HRP then
            HRP.CanCollide = true
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        if Hum and Hum.Health > 0 then
            -- Restore original health values safely
            pcall(function()
                if self.OriginalMaxHealth and self.OriginalMaxHealth > 0 then
                    Hum.MaxHealth = self.OriginalMaxHealth
                end
                
                task.wait(0.05)
                
                if self.OriginalHealth and self.OriginalHealth > 0 then
                    Hum.Health = self.OriginalHealth
                end
            end)
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

-- Elite WalkFling - Extreme Performance Module
-- Designed for maximum fling power with anti-cheat evasion

local Toggle = Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Flag = "EliteWalkFling_Toggle",
    Callback = function(Value)
        if Value then
            -- Enable notification
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Elite WalkFling Enabled!",
                Duration = 3,
                Button1 = "OK"
            })
            _G.EliteLog("Elite WalkFling activated", "success")
            
            -- Spawn the fling loop
            task.spawn(function()
                local Char = LP.Character
                if not Char then return end
                
                local HRP = Char:FindFirstChild("HumanoidRootPart")
                local Humanoid = Char:FindFirstChild("Humanoid")
                
                if not HRP or not Humanoid then 
                    _G.EliteLog("Character components missing", "error")
                    return 
                end
                
                -- Store original CanCollide states
                local OriginalCollision = {}
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= HRP then
                        OriginalCollision[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
                
                -- Physics constants
                local FLING_MAGNITUDE = 999999
                local VERTICAL_CONSTANT = 28.5
                local NETLESS_JITTER = 0.3
                
                -- Main fling loop
                local Connection
                Connection = RunService.Heartbeat:Connect(function()
                    if not Toggle.CurrentValue then
                        Connection:Disconnect()
                        
                        -- Restore collision
                        for part, state in pairs(OriginalCollision) do
                            if part and part.Parent then
                                part.CanCollide = state
                            end
                        end
                        
                        -- Reset velocities
                        if HRP and HRP.Parent then
                            HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            HRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                        
                        _G.EliteLog("Elite WalkFling deactivated", "info")
                        return
                    end
                    
                    -- Validate character integrity
                    if not Char or not Char.Parent or not HRP or not HRP.Parent or not Humanoid or Humanoid.Health <= 0 then
                        Toggle:Set(false)
                        return
                    end
                    
                    -- Ensure normal walking state (NOT PlatformStand)
                    if Humanoid.PlatformStand then
                        Humanoid.PlatformStand = false
                    end
                    
                    -- Velocity Oscillation (Anti-Cheat Bypass)
                    -- Uses rapid vector shifts so server-side average appears normal
                    local time = tick()
                    local oscillation = math.sin(time * 100) -- Extremely fast oscillation
                    
                    -- Create oscillating velocity vector
                    local velocityDirection = Vector3.new(
                        math.sin(time * 50) * oscillation,
                        VERTICAL_CONSTANT + (math.sin(time * 30) * NETLESS_JITTER), -- Netless jitter
                        math.cos(time * 50) * oscillation
                    ).Unit
                    
                    -- Apply massive velocity with oscillation
                    HRP.AssemblyLinearVelocity = velocityDirection * FLING_MAGNITUDE
                    
                    -- Apply angular velocity for spin (increases fling power)
                    local angularOscillation = math.cos(time * 80)
                    HRP.AssemblyAngularVelocity = Vector3.new(
                        angularOscillation * FLING_MAGNITUDE * 0.5,
                        math.sin(time * 90) * FLING_MAGNITUDE * 0.5,
                        angularOscillation * FLING_MAGNITUDE * 0.5
                    )
                    
                    -- Maintain ghosting (no collision)
                    for _, part in pairs(Char:GetDescendants()) do
                        if part:IsA("BasePart") and part ~= HRP then
                            part.CanCollide = false
                        end
                    end
                end)
            end)
        else
            -- Disable is handled by the Heartbeat disconnect logic
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Elite WalkFling Disabled!",
                Duration = 2,
            })
        end
    end,
})

-- [[ ELITE-UTILITY-HUB: TROLL MODULE - FEATURE: WALKFLING ]]
-- Tab, LP, RunService are injected by Main.lua

local WalkFlingEnabled = false

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        WalkFlingEnabled = Value
        
        if Value then
            _G.EliteLog("Elite WalkFling Activated", "success")
            
            task.spawn(function()
                while WalkFlingEnabled do
                    local Char = LP.Character
                    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
                    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
                    
                    if HRP and Hum then
                        -- 1. THE BEAST SPIN (Angular Force)
                        -- High Y-velocity creates the centrifugal fling
                        HRP.AssemblyAngularVelocity = Vector3.new(0, 30000, 0)
                        
                        -- 2. NETLESS BYPASS (Linear Jitter)
                        -- 28.5 constant to maintain network ownership
                        HRP.AssemblyLinearVelocity = Vector3.new(0, 28.5 + math.sin(tick() * 15) * 2, 0)
                        
                        -- 3. GHOST LOGIC (Local Only)
                        -- Disable collision for limbs so they don't interfere with the fling
                        for _, v in pairs(Char:GetChildren()) do
                            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                                v.CanCollide = false
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
                
                -- // CLEANUP //
                local Char = LP.Character
                local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
                if HRP then
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    HRP.AssemblyLinearVelocity = Vector3.zero
                end
                -- Restore collisions
                if Char then
                    for _, v in pairs(Char:GetChildren()) do
                        if v:IsA("BasePart") then v.CanCollide = true end
                    end
                end
                _G.EliteLog("Elite WalkFling Deactivated", "info")
            end)
        end
    end,
})

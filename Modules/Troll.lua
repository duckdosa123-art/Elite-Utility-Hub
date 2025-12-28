-- [[ ELITE-UTILITY-HUB: TROLL MODULE - HARD-LOCKED WALKFLING ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFling = {
    Active = false,
    Connections = {},
    BaseY = 0,
    JumpOffset = 0,
    JumpVelocity = 0,
    Gravity = 196.2, -- Standard Roblox Gravity
    Power = 999999
}

-- // THE HARD-LOCKED ENGINE //
function WalkFling:Start()
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    self.BaseY = HRP.Position.Y -- STORE INITIAL STANDING Y
    self.JumpOffset = 0
    self.JumpVelocity = 0

    _G.EliteLog("WalkFling: Y-Locked Mode Online", "success")

    -- 1. GODMODE & JUMP PHYSICS LOGIC
    local physicsConn = RunService.Heartbeat:Connect(function(dt)
        if not self.Active or not HRP or not Hum then return end
        
        -- // CUSTOM JUMP LOGIC //
        -- If player jumps, give upward velocity to the offset
        if Hum.Jump and self.JumpOffset == 0 then
            self.JumpVelocity = Hum.JumpPower * 0.9 -- Initial Burst
        end
        
        -- Apply Jump Velocity to Offset
        if self.JumpOffset > 0 or self.JumpVelocity > 0 then
            self.JumpVelocity = self.JumpVelocity - (self.Gravity * dt) -- Pull down by gravity
            self.JumpOffset = self.JumpOffset + (self.JumpVelocity * dt)
            
            -- Hit the floor check
            if self.JumpOffset <= 0 then
                self.JumpOffset = 0
                self.JumpVelocity = 0
            end
        end

        -- // THE HARD Y-LOCK (USER SUGGESTION) //
        -- Forces your position to stay at the Stored Y + your custom Jump height
        local CurrentPos = HRP.Position
        HRP.CFrame = CFrame.new(CurrentPos.X, self.BaseY + self.JumpOffset, CurrentPos.Z) * HRP.CFrame.Rotation

        -- // THE FLING PHYSICS //
        -- Massive Spin (Weapon)
        HRP.AssemblyAngularVelocity = Vector3.new(0, self.Power, 0)
        
        -- Horizontal Jitter Only (Forces launch without creating "Lift")
        HRP.AssemblyLinearVelocity = Vector3.new(
            math.sin(tick() * 10) * self.Power, 
            -28.5, -- Extra downward pressure for Netless
            math.cos(tick() * 10) * self.Power
        )
        
        -- Maintain Health
        Hum.Health = Hum.MaxHealth
    end)
    table.insert(self.Connections, physicsConn)

    -- 2. NOCLIP LOOP (Crucial for the Y-Lock to feel smooth)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
end

function WalkFling:Stop()
    self.Active = false
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}

    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    if HRP then
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
    end
    
    if Char then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
    _G.EliteLog("WalkFling Engine Terminated", "info")
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
                Text = "Physics Active.",
                Duration = 4,
            })
            WalkFling:Start()
        else
            WalkFling:Stop()
        end
    end,
})

-- Respawn Logic
LP.CharacterAdded:Connect(function()
    if WalkFling.Active then WalkFling:Stop() end
end)

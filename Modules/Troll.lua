-- WalkFling Logic for Elite-Utility-Hub (Advanced Physics Version)
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    IsFlinging = false, -- Flag to detect the exact moment of impact
}

function WalkFlingEngine:Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6023426926",
        Duration = 3
    })
end

function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")
    if not HRP or not Hum then return end
    
    self.Active = true
    self:Notify("Elite Utility", "WalkFling Enabled")

    -- 1. Godmode & State Fixes
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
        -- Prevent tripping/falling over during flings
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. Surgical Spike (Lethal Touch)
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active or hit:IsDescendantOf(Char) then return end
            if hit.Parent:FindFirstChild("Humanoid") then
                self.IsFlinging = true -- Trigger the Recoil Dampener
                
                -- Spike velocity for physics impact
                local oldVel = HRP.AssemblyLinearVelocity
                HRP.AssemblyLinearVelocity = Vector3.new(95000000, 95000000, 95000000)
                
                RunService.RenderStepped:Wait()
                
                if HRP then HRP.AssemblyLinearVelocity = oldVel end
                task.delay(0.1, function() self.IsFlinging = false end)
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))

    -- 3. Noclip (Via Stepped for Physics overlap)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 4. Advanced Recoil Dampener (The "Safe" Y-Lock)
    local dampenerConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP or not Hum then return end
        
        local currentVel = HRP.AssemblyLinearVelocity
        
        -- Logic: If we are NOT intentionally jumping, but we have massive upward velocity...
        -- It's recoil. We kill the upward momentum but KEEP horizontal movement.
        if self.IsFlinging or Hum.FloorMaterial ~= Enum.Material.Air then
            if currentVel.Y > 50 then -- 50 is slightly higher than a standard jump
                HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
            end
        end
        
        -- Fall Safety: If falling, don't let recoil "bounce" us back up
        if Hum:GetState() == Enum.HumanoidStateType.Freefall then
            if currentVel.Y > 0 then -- If falling but moving UP (recoil)
                HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, -20, currentVel.Z)
            end
        end
    end)
    table.insert(self.Connections, dampenerConn)
end

function WalkFlingEngine:Stop()
    if not self.Active then return end
    self.Active = false
    
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}
    
    local Hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if Hum then
        Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
    
    self:Notify("Elite Utility", "WalkFling Disabled")
end
-- Rayfield Toggle Integration
Tab:CreateSection("Fling - Disable Fling Guard First!")
Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Flag = "WalkFling",
    Callback = function(Value)
        if Value then
            task.spawn(function() WalkFlingEngine:Start() end)
        else
            WalkFlingEngine:Stop()
        end
    end,
})

-- WalkFling Logic for Elite-Utility-Hub
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    Storage = {
        JumpPower = 50,
        JumpHeight = 7.2,
        Gravity = 196.2,
        Masses = {}
    }
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
    
    -- 1. SAVE: Capture original physics state
    self.Storage.JumpPower = Hum.JumpPower
    self.Storage.JumpHeight = Hum.JumpHeight
    self.Storage.Gravity = workspace.Gravity
    
    for _, part in pairs(Char:GetDescendants()) do
        if part:IsA("BasePart") then
            self.Storage.Masses[part] = part.Massless
            part.Massless = true -- Become a 'Ghost' to physics recoil
        end
    end
    
    self:Notify("Elite Utility", "WalkFling Enabled")

    -- 2. GODMODE & STATE LOCK
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local stateConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
        -- Prevent the 'trip' animation when hitting targets
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
    table.insert(self.Connections, stateConn)

    -- 3. THE FLING ENGINE (Angular + Linear Spike)
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active or hit:IsDescendantOf(Char) then return end
            local targetChar = hit.Parent
            if targetChar:FindFirstChild("Humanoid") then
                -- Apply massive Spin + Forward Velocity
                -- Spinning flings targets away; Linear velocity pushes them back.
                -- By combining them, the player stays stable.
                HRP.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)
                HRP.AssemblyLinearVelocity = Vector3.new(999999, 999999, 999999)
                
                RunService.RenderStepped:Wait()
                
                if HRP then
                    HRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    
    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))

    -- 4. DYNAMIC PHYSICS MAINTENANCE
    -- This allows jumping and falling to feel 100% normal while negating recoil.
    local physicsConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP or not Hum then return end
        
        local currentVel = HRP.AssemblyLinearVelocity
        
        -- Detect the "Heaven Spike" (Recoil)
        -- A normal jump never exceeds ~100 velocity. If we are over that, it's a glitch.
        local jumpCeiling = (Hum.UseJumpPower and Hum.JumpPower or 100) + 20
        
        if currentVel.Y > jumpCeiling then
            -- Reset only the Y velocity, maintaining X/Z walking momentum
            HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
        end
        
        -- Grounding Force: If walking, keep the player glued to the floor
        if Hum.FloorMaterial ~= Enum.Material.Air and not Hum.Jump then
            HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, -1, currentVel.Z)
        end
    end)
    table.insert(self.Connections, physicsConn)

    -- 5. NOCLIP (Stepped)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    table.insert(self.Connections, noclipConn)
end

function WalkFlingEngine:Stop()
    if not self.Active then return end
    self.Active = false
    
    -- Cleanup Connections
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}
    
    -- RESTORE: Put character back to normal
    local Char = LP.Character
    if Char then
        local Hum = Char:FindFirstChild("Humanoid")
        if Hum then 
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
        
        for part, wasMassless in pairs(self.Storage.Masses) do
            if part and part.Parent then
                part.Massless = wasMassless
            end
        end
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

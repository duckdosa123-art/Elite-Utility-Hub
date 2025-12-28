-- WalkFling Logic for Elite-Utility-Hub
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    BaseY = 0,
    JumpOffset = 0,
    IsJumping = false,
    JumpStart = 0
}

function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChild("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    self.BaseY = HRP.Position.Y
    self.JumpOffset = 0
    self.IsJumping = false
    
    -- Native Notification
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Elite Utility",
        Text = "Elite WalkFling Enabled",
        Icon = "rbxassetid://6023426926", -- Friend Request Icon
        Duration = 3
    })

    -- 1. Godmode & State Management
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
        if Hum:GetState() == Enum.HumanoidStateType.Dead then
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. Surgical Spike & Touch Listeners
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            local targetChar = hit.Parent
            if targetChar and targetChar:FindFirstChild("Humanoid") and targetChar ~= Char then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    -- The Surgical Spike: High velocity for one frame, then reset
                    local oldVel = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7) 
                    RunService.RenderStepped:Wait()
                    if HRP then HRP.AssemblyLinearVelocity = oldVel end
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end

    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))

    -- 3. Noclip (Stepped)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 4. Hard-Lock Y & Simulated Jump (Heartbeat)
    local physicsConn = RunService.Heartbeat:Connect(function(dt)
        if not self.Active or not HRP or not Hum then return end
        
        -- Jump Logic (Gravity Curve)
        local gravity = workspace.Gravity
        local jumpPower = Hum.JumpPower > 0 and Hum.JumpPower or 50
        
        if Hum.Jump and not self.IsJumping and Hum.FloorMaterial ~= Enum.Material.Air then
            self.IsJumping = true
            self.JumpStart = tick()
        end
        
        if self.IsJumping then
            local t = tick() - self.JumpStart
            -- Physics Formula: y = v0*t - 0.5*g*t^2
            self.JumpOffset = (jumpPower * t) - (0.5 * gravity * (t * t))
            
            if self.JumpOffset <= 0 then
                self.JumpOffset = 0
                self.IsJumping = false
            end
        else
            -- Keep BaseY updated to floor level when walking normally
            if Hum.FloorMaterial ~= Enum.Material.Air then
                self.BaseY = HRP.Position.Y
            end
        end

        -- Hard-Lock position to prevent recoil from spiking the player up
        local currentPos = HRP.Position
        HRP.CFrame = CFrame.new(currentPos.X, self.BaseY + self.JumpOffset, currentPos.Z) * HRP.CFrame.Rotation
    end)
    table.insert(self.Connections, physicsConn)
    
    _G.EliteLog("Elite WalkFling Active", "success")
end

function WalkFlingEngine:Stop()
    self.Active = false
    for _, conn in pairs(self.Connections) do 
        pcall(function() conn:Disconnect() end) 
    end
    self.Connections = {}
    
    local Hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if Hum then
        Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
    
    _G.EliteLog("Elite WalkFling Disabled", "info")
end

-- Rayfield Toggle Integration
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

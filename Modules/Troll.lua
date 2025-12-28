-- WalkFling Logic for Elite-Utility-Hub
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    BaseY = 0,
    JumpOffset = 0,
    IsJumping = false,
    JumpStart = 0
}

function WalkFlingEngine:Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6023426926", -- Friend Request Icon
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
    self.BaseY = HRP.Position.Y
    self.JumpOffset = 0
    self.IsJumping = false
    
    self:Notify("Elite Utility", "WalkFling Enabled")

    -- 1. State/Godmode Management
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
        if Hum:GetState() == Enum.HumanoidStateType.Dead then Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. Surgical Spike (Fling Logic)
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active or hit:IsDescendantOf(Char) then return end
            if hit.Parent:FindFirstChild("Humanoid") then
                local oldVel = HRP.AssemblyLinearVelocity
                -- Spike velocity to extreme levels for 1 frame
                HRP.AssemblyLinearVelocity = Vector3.new(99999999, 99999999, 99999999)
                RunService.RenderStepped:Wait()
                if HRP then HRP.AssemblyLinearVelocity = oldVel end
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))

    -- 3. Noclip (Prevents friction and getting stuck in parts)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 4. Dynamic Y-Lock & Simulated Physics
    local physicsConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP or not Hum then return end
        
        -- Floor Detection (Raycast)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {Char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local floorRay = workspace:Raycast(HRP.Position, Vector3.new(0, -20, 0), rayParams)
        local floorY = floorRay and floorRay.Position.Y + (Hum.HipHeight + (HRP.Size.Y/2)) or self.BaseY

        -- Simulated Jump Physics
        if Hum.Jump and not self.IsJumping and Hum.FloorMaterial ~= Enum.Material.Air then
            self.IsJumping = true
            self.JumpStart = tick()
        end

        if self.IsJumping then
            local t = tick() - self.JumpStart
            local jumpPower = Hum.JumpPower > 0 and Hum.JumpPower or 50
            self.JumpOffset = (jumpPower * t) - (0.5 * workspace.Gravity * (t * t))
            
            -- End jump when player falls back to floor height
            if self.JumpOffset <= 0 then
                self.JumpOffset = 0
                self.IsJumping = false
            end
        else
            -- Smoothly transition BaseY to match the floor (Fixes getting stuck in air)
            self.BaseY = floorY
        end

        -- Hard-Lock the Y-Axis to prevent recoil from lifting the player
        local currentPos = HRP.Position
        HRP.CFrame = CFrame.new(currentPos.X, self.BaseY + self.JumpOffset, currentPos.Z) * HRP.CFrame.Rotation
    end)
    table.insert(self.Connections, physicsConn)
end

function WalkFlingEngine:Stop()
    if not self.Active then return end
    self.Active = false
    
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}
    
    local Hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if Hum then Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    
    self:Notify("Elite Utility", "WalkFling Disabled")
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

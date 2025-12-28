-- WalkFling Logic for Elite-Utility-Hub (Dynamic Physics Ceiling Version)
local WalkFlingEngine = {
    Active = false,
    Connections = {},
    SafeLimit = 50, -- Will be calculated dynamically
}

function WalkFlingEngine:Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6023426926",
        Duration = 3
    })
end

-- Advanced Calculation to find the "Lethal Threshold"
function WalkFlingEngine:UpdateSafeLimit(Hum)
    local Gravity = workspace.Gravity
    local MaxVel = 0
    
    if Hum.UseJumpPower then
        MaxVel = Hum.JumpPower
    else
        -- If game uses JumpHeight, V = sqrt(2 * g * h)
        MaxVel = math.sqrt(2 * Gravity * Hum.JumpHeight)
    end
    
    -- Add a 15-stud buffer for slopes, elevators, or jump pads
    self.SafeLimit = MaxVel + 15
end

function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")
    if not HRP or not Hum then return end
    
    self.Active = true
    self:UpdateSafeLimit(Hum)
    self:Notify("Elite Utility", "WalkFling Enabled - NoClip")

    -- 1. Godmode & Anti-Trip
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not Hum then return end
        Hum.Health = Hum.MaxHealth
        -- Prevent the "stumble" effect when hitting people
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. Surgical Spike (Reactive Fling)
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active or hit:IsDescendantOf(Char) then return end
            if hit.Parent:FindFirstChild("Humanoid") then
                -- Store old velocity to restore after the frame
                local oldVel = HRP.AssemblyLinearVelocity
                -- Apply massive impulse
                HRP.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
                RunService.RenderStepped:Wait()
                if HRP then HRP.AssemblyLinearVelocity = oldVel end
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    for _, part in pairs(Char:GetDescendants()) do setupTouch(part) end
    table.insert(self.Connections, Char.DescendantAdded:Connect(setupTouch))

    -- 3. Noclip (Physics Passthrough)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, part in pairs(Char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 4. Dynamic Recoil Snatcher (The "Anti-Heaven" Logic)
    local snatcherConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP or not Hum then return end
        
        -- Refresh the limit in case the game changes Gravity or JumpPower mid-way
        self:UpdateSafeLimit(Hum)
        
        local currentVel = HRP.AssemblyLinearVelocity
        
        -- If our upward velocity (Y) is higher than a legal jump, it's recoil.
        -- We snip it back to 0 immediately to stay grounded.
        if currentVel.Y > self.SafeLimit then
            HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
        end
        
        -- Fall Safety: Don't let recoil bounce us back UP while we are falling
        if Hum:GetState() == Enum.HumanoidStateType.Freefall and currentVel.Y > 5 then
             HRP.AssemblyLinearVelocity = Vector3.new(currentVel.X, -5, currentVel.Z)
        end
    end)
    table.insert(self.Connections, snatcherConn)
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

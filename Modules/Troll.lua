-- [[ ELITE-UTILITY-HUB: TROLL MODULE - AUTHENTIC IY WALKFLING ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFling = {
    Active = false,
    Connections = {}
}

-- // THE AUTHENTIC IY ENGINE //
function WalkFling:Start()
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    self.Active = true

    -- 1. IY GODMODE & STATE LOCK
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

    -- 2. IY PHYSICS LOOP (Grounded Buzzsaw)
    -- This is the exact method IY uses: Negative Y to stay on floor + Massive Torque
    local physicsConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not HRP then return end
        
        -- THE WEAPON: Massive Spinning Torque
        HRP.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)
        
        -- THE SHIELD: Force character INTO the floor to prevent ascending
        -- We use -25.1 for Netless ownership and -1000 for Grounding
        HRP.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
    end)
    table.insert(self.Connections, physicsConn)

    -- 3. IY NOCLIP (Prevents you from tripping on victims)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    _G.EliteLog("Authentic WalkFling: Lethal", "success")
end

function WalkFling:Stop()
    self.Active = false
    for _, conn in pairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    self.Connections = {}

    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if HRP then
        HRP.AssemblyLinearVelocity = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
    end
    
    if Hum then
        pcall(function()
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
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
                Text = "Enabled! Authentic IY Physics Loaded.",
                Duration = 4,
            })
            _G.EliteLog("Elite WalkFling enabled", "info")
            WalkFling:Start()
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Disabled!",
                Duration = 2,
            })
            _G.EliteLog("Elite WalkFling disabled", "info")
            WalkFling:Stop()
        end
    end,
})

-- Respawn Logic
LP.CharacterAdded:Connect(function()
    if WalkFling.Active then WalkFling:Stop() end
end)

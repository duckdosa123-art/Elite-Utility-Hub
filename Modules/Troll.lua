-- [[ ELITE-UTILITY-HUB: TROLL MODULE - ACCURATE WALKFLING ]]
-- Variables Tab, LP, RunService are injected by Main.lua

local WalkFling = {
    Active = false,
    Connections = {},
    Power = 9999999 -- The IY-exact launch force
}

-- // THE SURGICAL STRIKE ENGINE //
function WalkFling:Start()
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end

    self.Active = true
    _G.EliteLog("WalkFling Engine: Noclip & Engine Active", "success")

    -- 1. GODMODE TACTIC (PRESERVED)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if Hum and Hum.Parent then
            Hum.Health = Hum.MaxHealth
            if Hum:GetState() == Enum.HumanoidStateType.Dead then
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
    table.insert(self.Connections, godmodeConn)

    -- 2. NORMAL NOCLIP LOOP (Crucial to prevent self-flinging)
    -- This runs every frame before physics to ensure you don't hit the floor/walls
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)

    -- 3. ACCURATE ANY-TO-ANY TOUCH DETECTION
    local function ConnectPart(part)
        if not part:IsA("BasePart") then return end
        
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            local victimChar = hit.Parent
            local victimHum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
            local victimHRP = victimChar and victimChar:FindFirstChild("HumanoidRootPart")

            -- Trigger only on other players
            if victimHum and victimHRP and victimChar ~= Char then
                local oldVel = HRP.AssemblyLinearVelocity
                
                -- The Pulse: Applies massive force to YOU, which transfers to THEM on touch
                -- Noclip prevents this force from launching you into the sky via floor friction
                HRP.AssemblyLinearVelocity = Vector3.new(self.Power, self.Power, self.Power)
                HRP.AssemblyAngularVelocity = Vector3.new(self.Power, self.Power, self.Power)
                
                task.wait(0.1) -- Pulse duration
                
                if HRP and HRP.Parent then
                    HRP.AssemblyLinearVelocity = oldVel
                    HRP.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end

    -- Connect all existing and future body parts
    for _, part in pairs(Char:GetDescendants()) do ConnectPart(part) end
    local childConn = Char.DescendantAdded:Connect(function(obj)
        if self.Active then ConnectPart(obj) end
    end)
    table.insert(self.Connections, childConn)
end

function WalkFling:Stop()
    self.Active = false
    
    -- Disconnect all loops and events
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}

    -- Restore Humanoid & Collision State Safely
    local Char = LP.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
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
    
    _G.EliteLog("WalkFling Engine: Terminated", "info")
end

-- // UI SECTION //
Tab:CreateSection("Main Fling - Disable Fling Guard First")
Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Enabled! Noclip and Surgical Strike Active.",
                Duration = 4,
            })
            
            _G.EliteLog("Elite WalkFling enabled - Noclip active", "info")
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

-- Handle Respawn
LP.CharacterAdded:Connect(function()
    if WalkFling.Active then
        WalkFling:Stop()
        _G.EliteLog("WalkFling reset due to respawn", "warn")
    end
end)

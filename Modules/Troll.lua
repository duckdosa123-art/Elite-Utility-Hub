-- [[ ELITE-UTILITY-HUB: TROLL MODULE - ACCURATE WALKFLING ]]
-- Variables Tab, LP, RunService are injected by Main.lua

local WalkFling = {
    Active = false,
    Connections = {},
    Power = 9999999 -- The IY-exact launch force
}

-- // ROBLOX NATIVE NOTIFICATION SYSTEM //
local function SendNativeNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6034281358", -- Friend Request Icon
        Duration = 4
    })
end

-- // THE SURGICAL STRIKE ENGINE //
function WalkFling:Start()
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end

    self.Active = true
    _G.EliteLog("WalkFling Engine: Active", "success")

    -- 1. GODMODE TACTIC (STRICT IMPLEMENTATION)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    
    local godmodeConn = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if Hum and Hum.Parent then
            Hum.Health = Hum.MaxHealth
            -- Prevent any state changes
            if Hum:GetState() == Enum.HumanoidStateType.Dead then
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
    table.insert(self.Connections, godmodeConn)

    -- // ACCURATE TOUCH DETECTION //
    local function ConnectPart(part)
        if not part:IsA("BasePart") then return end
        
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            local victimChar = hit.Parent
            local victimHum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
            local victimHRP = victimChar and victimChar:FindFirstChild("HumanoidRootPart")

            -- Accuracy Fix: If we touch ANY part of another player, launch instantly
            if victimHum and victimHRP and victimChar ~= Char then
                local oldVel = HRP.AssemblyLinearVelocity
                local oldRotVel = HRP.AssemblyAngularVelocity
                
                -- Instant Fling Pulse: Applied in all directions to catch running targets
                HRP.AssemblyLinearVelocity = Vector3.new(self.Power, self.Power, self.Power)
                HRP.AssemblyAngularVelocity = Vector3.new(self.Power, self.Power, self.Power)
                
                -- Accuracy Fix: We wait slightly longer (0.1s) to ensure server registers the hit
                task.wait(0.1)
                
                -- Reset to normal walking state
                if HRP and HRP.Parent then
                    HRP.AssemblyLinearVelocity = oldVel
                    HRP.AssemblyAngularVelocity = oldRotVel
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end

    -- Apply to all existing parts
    for _, part in pairs(Char:GetDescendants()) do
        ConnectPart(part)
    end

    -- Apply to any parts added later (tools/accessories)
    local childConn = Char.DescendantAdded:Connect(function(obj)
        if self.Active then ConnectPart(obj) end
    end)
    table.insert(self.Connections, childConn)
end

function WalkFling:Stop()
    self.Active = false
    
    -- Disconnect all connections
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}

    -- Restore Humanoid State Safely
    local Hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if Hum then 
        pcall(function() 
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) 
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
    
    _G.EliteLog("WalkFling Engine: Terminated", "info")
end

-- // UI INTEGRATION //
Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Enabled! If it doesn't work then disable Fling Guard",
                Duration = 4,
            })
            
            _G.EliteLog("Elite WalkFling enabled - Walk into players to fling them", "info")
            WalkFling:Start()
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Elite WalkFling",
                Text = "Disabled!",
                Duration = 2,
            })
            
            _G.EliteLog("Elite WalkFling disabled", "info"
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

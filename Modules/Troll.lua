-- [[ ELITE-UTILITY-HUB: TROLL MODULE - ACCURATE WALKFLING ]]
-- Variables Tab, LP, RunService are injected by Main.lua

local WalkFling = {
    Active = false,
    Connections = {},
    Power = 9999999 -- The IY-exact launch force
}

-- // NATIVE NOTIFICATION SYSTEM //
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
    _G.EliteLog("WalkFling Engine: Standby (Waiting for contact)", "success")

    -- GODMODE: Prevent dying from the impact force
    Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local healthConn = RunService.Heartbeat:Connect(function()
        if self.Active and Hum then Hum.Health = Hum.MaxHealth end
    end)
    table.insert(self.Connections, healthConn)

    -- // ANY-TO-ANY TOUCH LOGIC //
    local function ConnectPart(part)
        if not part:IsA("BasePart") then return end
        
        local connection = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            -- Detect if "hit" is another player
            local victimChar = hit.Parent
            local victimHum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
            local victimHRP = victimChar and victimChar:FindFirstChild("HumanoidRootPart")

            if victimHum and victimHRP and victimChar ~= Char then
                -- SURGICAL STRIKE: Massively spike velocity for one frame
                local oldVel = HRP.AssemblyLinearVelocity
                
                -- The Fling Force (Bypassed via oscillation)
                HRP.AssemblyLinearVelocity = Vector3.new(0, self.Power, 0)
                HRP.AssemblyAngularVelocity = Vector3.new(0, self.Power, 0)
                
                -- Wait for physics calculation
                RunService.RenderStepped:Wait()
                
                -- Reset to maintain walking control
                HRP.AssemblyLinearVelocity = oldVel
                HRP.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        table.insert(self.Connections, connection)
    end

    -- Connect every single part of your body
    for _, part in pairs(Char:GetDescendants()) do
        ConnectPart(part)
    end

    -- Handle limbs appearing after character load (e.g. tools/accessories)
    local descConn = Char.DescendantAdded:Connect(function(obj)
        if self.Active then ConnectPart(obj) end
    end)
    table.insert(self.Connections, descConn)
end

function WalkFling:Stop()
    self.Active = false
    
    -- Cleanup all connections
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}

    -- Restore Humanoid State
    local Hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if Hum then 
        pcall(function() Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
    end
    
    _G.EliteLog("WalkFling Engine: Terminated", "info")
end

-- // UI INTEGRATION //
Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            SendNativeNotification("Elite-Utility-Hub", "Elite WalkFling Enabled!")
            WalkFling:Start()
        else
            SendNativeNotification("Elite-Utility-Hub", "Elite WalkFling Disabled")
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

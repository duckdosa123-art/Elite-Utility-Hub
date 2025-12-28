-- [[ ELITE-UTILITY-HUB: TROLL MODULE ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFlingEngine = {
    Active = false,
    Connections = {}
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
function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then 
        _G.EliteLog("Character components missing", "error")
        return 
    end
    
    self.Active = true
    _G.EliteLog("WalkFling engine started", "success")
    
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
    
    -- 2. NOCLIP LOOP (Crucial to prevent self-flinging)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    -- 3. ANY-TO-ANY TOUCH DETECTION LOGIC
    local function setupTouch(part)
        if not part:IsA("BasePart") then return end
        
        local touchConn = part.Touched:Connect(function(hit)
            if not self.Active then return end
            
            -- Check if we touched another player's character
            local otherChar = hit.Parent
            local otherHum = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
            local otherHRP = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
            
            if otherHum and otherHRP and otherHum.Health > 0 and otherChar ~= Char then
                -- Store current velocity
                local currentVel = HRP.AssemblyLinearVelocity
                
                -- Apply MASSIVE velocity spike (Your specific logic)
                HRP.AssemblyLinearVelocity = Vector3.new(0, 99999999, 0)
                
                -- Wait ONE frame
                RunService.RenderStepped:Wait()
                
                -- Reset velocity back to normal
                if HRP and HRP.Parent then
                    HRP.AssemblyLinearVelocity = currentVel
                end
                
                -- Ensure we stay alive
                if Hum then
                    Hum.Health = Hum.MaxHealth
                end
            end
        end)
        table.insert(self.Connections, touchConn)
    end
    
    -- Setup touch on all character parts (current and future)
    for _, part in pairs(Char:GetDescendants()) do
        setupTouch(part)
    end
    
    local childConn = Char.DescendantAdded:Connect(function(part)
        if self.Active then
            setupTouch(part)
        end
    end)
    table.insert(self.Connections, childConn)
end

function WalkFlingEngine:Stop()
    self.Active = false
    
    -- Disconnect all connections FIRST
    for _, conn in pairs(self.Connections) do
        if conn then 
            pcall(function() conn:Disconnect() end)
        end
    end
    self.Connections = {}
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    task.wait(0.05)
    
    if HRP and HRP.Parent then
        HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    
    if Hum and Hum.Parent then
        pcall(function()
            Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
    
    _G.EliteLog("WalkFling engine stopped", "info")
end

-- // UI SECTION //

Tab:CreateSection("Fling - Disable Fling Guard First!")

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            SendNativeNotification("Elite WalkFling", "Enabled! If it doesn't work then disable Fling Guard")
            _G.EliteLog("Elite WalkFling enabled - Walk into players", "info")
            WalkFlingEngine:Start()
        else
            SendNativeNotification("Elite WalkFling", "Disabled!")
            _G.EliteLog("Elite WalkFling disabled", "info")
            WalkFlingEngine:Stop()
        end
    end,
})

-- Cleanup on respawn
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine.Active then
        WalkFlingEngine:Stop()
        _G.EliteLog("WalkFling reset due to respawn", "warn")
    end
end)

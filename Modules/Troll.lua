-- [[ ELITE-UTILITY-HUB: TROLL MODULE - TARGET-ONLY WALKFLING ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFlingEngine = {
    Active = false,
    Connections = {},
    Power = 99999999,
    Flinging = false 
}

-- // ROBLOX NATIVE NOTIFICATION SYSTEM //
local function SendNativeNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = "rbxassetid://6034281358",
        Duration = 4
    })
end

-- // THE TARGET-ONLY BRUTE FORCE ENGINE //
function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    _G.EliteLog("WalkFling: Targets Only Mode Active", "success")
    
    -- 1. GODMODE TACTIC (STRICT)
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
    
    -- 2. STABILIZED NOCLIP (Prevents Recoil)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    -- 3. SPATIAL QUERY (BRUTE FORCE DETECTION)
    local queryConn = RunService.Heartbeat:Connect(function()
        if not self.Active or self.Flinging or not HRP then return end
        
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {Char}
        
        -- Box check for victims
        local partsInBox = workspace:GetPartBoundsInBox(HRP.CFrame, Vector3.new(4, 6, 4), overlapParams)
        
        for _, part in pairs(partsInBox) do
            local victimChar = part.Parent
            local victimHum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
            
            if victimHum and victimHum.Health > 0 then
                self.Flinging = true 
                
                task.spawn(function()
                    -- Store current movement to keep it smooth
                    local currentMove = HRP.AssemblyLinearVelocity
                    
                    local startTime = tick()
                    while tick() - startTime < 0.15 do -- 0.15s aggressive pulse
                        if not HRP or not self.Active then break end
                        
                        -- THE FIX: We spike X and Z (horizontal) but lock Y to 28.5 (Netless)
                        -- This flings THEM sideways/away but keeps YOU on the ground
                        HRP.AssemblyLinearVelocity = Vector3.new(
                            self.Power * (math.random(0,1) == 0 and 1 or -1), 
                            28.5 + math.sin(tick() * 20), -- Stable height bypass
                            self.Power * (math.random(0,1) == 0 and 1 or -1)
                        )
                        
                        -- Massive spin for extra launch power
                        HRP.AssemblyAngularVelocity = Vector3.new(0, self.Power, 0)
                        
                        RunService.RenderStepped:Wait()
                    end
                    
                    -- Reset to normal movement instantly
                    if HRP then
                        HRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        HRP.AssemblyAngularVelocity = Vector3.zero
                    end
                    
                    task.wait(0.05)
                    self.Flinging = false
                end)
                break
            end
        end
    end)
    table.insert(self.Connections, queryConn)
end

function WalkFlingEngine:Stop()
    self.Active = false
    self.Flinging = false
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
    _G.EliteLog("WalkFling Terminated", "info")
end

-- // UI SECTION //
Tab:CreateSection("Fling - Disable Fling Guard First!")

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            SendNativeNotification("Elite WalkFling", "Enabled! Walk into targets to launch them!.")
            WalkFlingEngine:Start()
        else
            SendNativeNotification("Elite WalkFling", "Disabled!")
            WalkFlingEngine:Stop()
        end
    end,
})

LP.CharacterAdded:Connect(function()
    if WalkFlingEngine.Active then
        WalkFlingEngine:Stop()
    end
end)

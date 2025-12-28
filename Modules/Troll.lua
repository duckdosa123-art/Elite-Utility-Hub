-- [[ ELITE-UTILITY-HUB: TROLL MODULE - BRUTE FORCE EDITION ]]
-- Variables Tab, LP, RunService, Rayfield are injected by Main.lua

local WalkFlingEngine = {
    Active = false,
    Connections = {},
    Power = 99999999,
    Flinging = false -- Debounce for the pulse
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

-- // THE UNIVERSAL BRUTE FORCE ENGINE //
function WalkFlingEngine:Start()
    if self.Active then return end
    
    local Char = LP.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end
    
    self.Active = true
    _G.EliteLog("Universal WalkFling Engine: Online", "success")
    
    -- 1. GODMODE TACTIC (PRESERVED & STRICT)
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
    
    -- 2. STEPPED NOCLIP (Prevents self-fling and floor friction)
    local noclipConn = RunService.Stepped:Connect(function()
        if not self.Active or not Char then return end
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, noclipConn)
    
    -- 3. SPATIAL QUERY DETECTION (The Brute Force accuracy fix)
    -- This ignores lag and "Fling Guards" by checking for overlaps every frame
    local queryConn = RunService.Heartbeat:Connect(function()
        if not self.Active or self.Flinging or not HRP then return end
        
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {Char} -- Ignore yourself
        
        -- Checks for any parts in a 5x5x5 box around you
        local partsInBox = workspace:GetPartBoundsInBox(HRP.CFrame, Vector3.new(5, 6, 5), overlapParams)
        
        for _, part in pairs(partsInBox) do
            local victimChar = part.Parent
            local victimHum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
            
            if victimHum and victimHum.Health > 0 then
                self.Flinging = true -- Start pulse
                
                task.spawn(function()
                    local oldVel = HRP.AssemblyLinearVelocity
                    
                    -- EXTENDED OMNI-PULSE (Brute Force launch)
                    -- We apply random jitter to the massive force to bypass velocity caps
                    local startTime = tick()
                    while tick() - startTime < 0.15 do -- 0.15s duration pulse
                        if not HRP or not self.Active then break end
                        
                        HRP.AssemblyLinearVelocity = Vector3.new(
                            math.random(-self.Power, self.Power), 
                            self.Power, 
                            math.random(-self.Power, self.Power)
                        )
                        HRP.AssemblyAngularVelocity = Vector3.new(self.Power, self.Power, self.Power)
                        RunService.RenderStepped:Wait()
                    end
                    
                    -- Reset to normal
                    if HRP then
                        HRP.AssemblyLinearVelocity = oldVel
                        HRP.AssemblyAngularVelocity = Vector3.zero
                    end
                    
                    task.wait(0.1) -- Small cooldown before next detection
                    self.Flinging = false
                end)
                break -- Exit loop once a target is found and pulse starts
            end
        end
    end)
    table.insert(self.Connections, queryConn)
end

function WalkFlingEngine:Stop()
    self.Active = false
    self.Flinging = false
    
    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
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
    
    _G.EliteLog("WalkFling engine stopped", "info")
end

-- // UI SECTION //

Tab:CreateSection("Fling - Disable Fling Guard First!")

Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            SendNativeNotification("Elite WalkFling", "Enabled! Spatial Query & Omni-Pulse Active.")
            _G.EliteLog("Elite WalkFling enabled - Surgical strike online", "info")
            WalkFlingEngine:Start()
        else
            SendNativeNotification("Elite WalkFling", "Disabled!")
            _G.EliteLog("Elite WalkFling disabled", "info")
            WalkFlingEngine:Stop()
        end
    end,
})

-- Handle Respawn
LP.CharacterAdded:Connect(function()
    if WalkFlingEngine.Active then
        WalkFlingEngine:Stop()
        _G.EliteLog("WalkFling reset due to respawn", "warn")
    end
end)

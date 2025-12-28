-- [[ ELITE-UTILITY-HUB: TROLL MODULE - FEATURE: AUTHENTIC WALKFLING ]]
-- Tab, LP, RunService, Rayfield are injected by Main.lua

local FlingActive = false
local SG = game:GetService("StarterGui")

-- // ROBLOX NATIVE NOTIFICATION SYSTEM //
local function SendRobloxNotification(title, text)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Icon = "rbxassetid://6034281358", -- Friend Request / User Icon
            Duration = 5
        })
    end)
end

-- // THE CORE WALKFLING ENGINE (IY-EXACT) //
local function RunEliteWalkFling()
    local Char = LP.Character
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    
    if not HRP or not Hum then return end

    task.spawn(function()
        while FlingActive and HRP.Parent do
            -- IY PHYSICS LOGIC: Massive Velocity + Directional Shifting
            -- To bypass AC, we oscillate the massive force so the "Average" velocity is low
            local Time = tick() * 35 
            local Power = 999999 -- The IY "God" Force
            
            -- Rotational Linear Velocity (This is the secret to the WalkFling power)
            HRP.AssemblyLinearVelocity = Vector3.new(
                math.sin(Time) * Power, 
                28.5 + math.sin(tick() * 10), -- The Beast Netless Constant
                math.cos(Time) * Power
            )
            
            -- Angular Spin for extra launch distance
            HRP.AssemblyAngularVelocity = Vector3.new(0, Power, 0)
            
            -- NORMAL WALKING STATE PRESERVATION
            -- We prevent the character from falling over while keeping normal walking
            Hum.AutoRotate = true 
            
            -- GHOSTING (Local Only)
            for _, part in pairs(Char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
            
            RunService.Heartbeat:Wait()
        end
        
        -- // CLEANUP //
        if HRP then
            HRP.AssemblyLinearVelocity = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
        end
        if Char then
            for _, part in pairs(Char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
end

-- // UI COMPONENT //
Tab:CreateToggle({
    Name = "Elite WalkFling",
    CurrentValue = false,
    Callback = function(Value)
        FlingActive = Value
        
        if Value then
            -- Trigger Roblox-style notification
            SendRobloxNotification("Elite-Utility-Hub", "Elite WalkFling Enabled!")
            _G.EliteLog("WalkFling Activated: IY Physics Engine Loaded", "success")
            RunEliteWalkFling()
        else
            _G.EliteLog("WalkFling Deactivated", "info")
        end
    end,
})

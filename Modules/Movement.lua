local Tab = _G.MoveTab

-- Capture default values when the script first runs
local defaultWS = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character.Humanoid.WalkSpeed or 16
local defaultJP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") and game.Players.LocalPlayer.Character.Humanoid.JumpPower or 50

-- Speed Slider
local SpeedSlider = Tab:CreateSlider({
   Name = "Elite Speed",
   Range = {16, 250},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = defaultWS,
   Flag = "SpeedSlider",
   Callback = function(Value)
      if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
         game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
      end
   end,
})

-- Jump Slider
local JumpSlider = Tab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 500},
   Increment = 1,
   Suffix = "Power",
   CurrentValue = defaultJP,
   Flag = "JumpSlider",
   Callback = function(Value)
      if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
         game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
      end
   end,
})

-- Reset Button
Tab:CreateButton({
   Name = "Reset to Game Defaults",
   Callback = function()
       if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
           SpeedSlider:Set(defaultWS)
           JumpSlider:Set(defaultJP)
           Rayfield:Notify({Title = "Elite-Utility", Content = "Values Reset to Default!", Duration = 3})
       end
   end,
})

Tab:CreateSection("Movement Physics")

local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local InfJumpEnabled = false -- This tracks if the toggle is ON
local canJump = true         -- This is the cooldown debounce
local cooldown = 0.25 

-- The Event Listener (Always running, but checks if enabled)
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled and canJump then
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            canJump = false 
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(cooldown) 
            canJump = true 
        end
    end
end)

-- The Toggle for the UI
Tab:CreateToggle({
   Name = "Elite Inf-Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      InfJumpEnabled = Value -- This now correctly connects to the listener above
   end,
})

-- 4. Vertical Logic (Space = Up, Ctrl = Down)
            local vertical = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 
-- Movement.lua - Elite-Utility-Hub (IY Style Optimized)
local LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- States
local _f = false
local _s = 50
local bv, bg -- Body Movers

-- [CLEANUP FUNCTION] - Fixes the Jump Bug
local function CleanFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local r = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum
            elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = -1 end

            -- then
        hum.PlatformStand = false
        -- Force the humanoid back to a state that allows jumping
        hum:Change 5. Final Velocity Application
            if moveVec.Magnitude > 0 or vertical ~= 0 then
                bv.VelocityState(Enum.HumanoidStateType.Running) 
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping = (direction * _s) + Vector3.new(0, vertical * _s, 0)
            else
                bv.Velocity = Vector3.zero
            end

            -- Face where camera is looking (Standard IY, true)
    end
    if r then
        r.Velocity = Vector3.zero -- Stop momentum instantly
    end
end

-- [ELITE FLY ENGINE]
task.spawn(function()
    RunService)
            bg.CFrame = cam.CFrame
        else
            CleanFly()
        end
.RenderStepped:Connect(function()
        local char = LP.Character
        local r = char and    end)
end)

-- [UI ELEMENTS]
Tab:CreateToggle({
   Name = "Elite char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value")
        local cam = workspace.CurrentCamera

        if _f and r and hum and cam then
            )
      _f = Value
      if not Value then CleanFly() end
   end,
})

-- Create movers if they don't exist
            if not bv then
                bv = Instance.new("BodyVelocity")
Tab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 50                bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
                bv.Parent = r
            end
            if not bg then
                bg = Instance.new("Body,
   Flag = "FlySpeed",
   Callback = function(Value) _s = Value end,
})

Gyro")
                bg.MaxTorque = Vector3.new(1, 1, 1) *Tab:CreateButton({
   Name = "UP (one stud)",
   Callback = function()
       local math.huge
                bg.P = 9000
                bg.Parent = r
            end r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if r then r.CFrame = r.CFrame * CFrame.new(0, 1, 0) end


            -- Physics State
            hum.PlatformStand = true -- Prevents legs from "walking" in air

   end,
})

Tab:CreateButton({
   Name = "DOWN (one stud)",
   Callback            -- Control Logic (Fixes Directional Bug)
            local moveDir = hum.MoveDirection -- World Space = function()
       local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
 direction from Joystick/WASD
            local look = cam.CFrame.LookVector
            local right = cam.C       if r then r.CFrame = r.CFrame * CFrame.new(0, -1,Frame.RightVector
            
            -- Convert World MoveDirection to Camera Local Direction
            -- This ensures "Forward" on 0) end
   end,
})

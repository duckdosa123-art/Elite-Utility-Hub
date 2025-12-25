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

-- Movement.lua - Elite-Utility-Hub (IY Style - FIXED)
local LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- States
local _f = false
local _s = 50
local bv, bg -- Body Movers

-- [ELITE FLY ENGINE]
local function CleanFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        -- Fixes Jump Bug: Re-enables jump logic and resets state
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local char = LP.Character
        local r = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        if _f and r and hum and cam then
            -- Create movers if they don't exist
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
                bv.Parent = r
            end
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
                bg.P = 9000
                bg.Parent = r
            end

            -- Physics State
            hum.PlatformStand = true -- Prevents walking animations in air
            hum:ChangeState(Enum.HumanoidStateType.Physics)

            -- FIXED Directional Logic (Joystick & WASD)
            -- Convert world MoveDirection to Camera-Relative direction
            local moveDir = hum.MoveDirection
            local localDir = cam.CFrame:VectorToObjectSpace(moveDir)
            
            -- Vertical Movement (PC Support)
            local up = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
            local down = UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0
            local vertical = Vector3.new(0, (up - down) * _s, 0)

            -- Calculate velocity: Z is forward/back, X is left/right
            -- We multiply by -localDir.Z because -Z is forward in Roblox
            local velocity = (cam.CFrame.LookVector * (-localDir.Z * _s)) + (cam.CFrame.RightVector * (localDir.X * _s))
            
            -- Apply movement or hover perfectly still
            if moveDir.Magnitude > 0 or up ~= 0 or down ~= 0 then
                bv.Velocity = velocity + vertical
            else
                bv.Velocity = Vector3.zero
            end
            
            -- Align character with camera (IY Style)
            bg.CFrame = cam.CFrame 
        else
            -- Auto-cleanup if flight toggled off or character resets
            if bv or bg then CleanFly() end
        end
    end)
end)

-- [UI ELEMENTS]
Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      _f = Value
      if not Value then CleanFly() end
   end,
})

Tab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      _s = Value
   end,
})

Tab:CreateButton({
   Name = "UP (one stud)",
   Callback = function()
       local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if r then r.CFrame = r.CFrame * CFrame.new(0, 1, 0) end
   end,
})

Tab:CreateButton({
   Name = "DOWN (one stud)",
   Callback = function()
       local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if r then r.CFrame = r.CFrame * CFrame.new(0, -1, 0) end
   end,
})
-- ELITE NO CLIP
local _nc = false -- Noclip Toggle State

-- [ ELITE NOCLIP ENGINE ]
task.spawn(function()
    RunService.Stepped:Connect(function()
        if _nc then
            local char = LP.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

Tab:CreateToggle({
   Name = "Elite Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      _nc = Value
      if not Value then
          -- Optional: Force a character refresh of collisions when turned off
          local char = LP.Character
          if char then
              for _, part in pairs(char:GetDescendants()) do
                  if part:IsA("BasePart") then
                      part.CanCollide = true
                  end
              end
          end
      end
   end,
})

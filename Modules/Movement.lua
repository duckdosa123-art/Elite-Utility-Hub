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

-- ELITE SMOOTH FLY ENGINE
local RunService = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer

-- State Management
local isFlying = false
local flySpeed = 50
local flyConnection

-- FLIGHT SYSTEM CONFIGURATION
local FlyEnabled = false
local FlySpeed = 50
local BodyGyro = nil
local BodyVelocity = nil
local RunService = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer

-- THE ELITE FLY ENGINE
local function StartFlying()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    -- Clean up any old forces before starting
    if root:FindFirstChild("EliteGyro") then root.EliteGyro:Destroy() end
    if root:FindFirstChild("EliteVelocity") then root.EliteVelocity:Destroy() end

    -- Gyro keeps you upright and facing your camera direction
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "EliteGyro"
    BodyGyro.P = 9e4
    BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = root.CFrame
    BodyGyro.Parent = root

    -- Velocity handles the actual movement
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "EliteVelocity"
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Parent = root

    -- Main Flight Loop (Joystick Compatible)
    task.spawn(function()
        while FlyEnabled and char:Parent() do
            local camera = workspace.CurrentCamera
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and root then
                -- This is the "Infinite Yield" secret: using MoveDirection
                -- This makes it work perfectly with mobile joysticks
                local moveDir = humanoid.MoveDirection
                BodyVelocity.Velocity = moveDir * FlySpeed
                BodyGyro.CFrame = camera.CFrame
            end
            RunService.RenderStepped:Wait()
        end
        
        -- Cleanup when disabled
        if BodyGyro then BodyGyro:Destroy() end
        if BodyVelocity then BodyVelocity:Destroy() end
        if char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
    end)
end

-- RAYFIELD UI INTEGRATION
Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      FlyEnabled = Value
      if Value then
          StartFlying()
      else
          -- Safety Reset
          local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
          if root then
              root.AssemblyLinearVelocity = Vector3.zero
          end
      end
   end,
})

Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 500},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      FlySpeed = Value
   end,
})


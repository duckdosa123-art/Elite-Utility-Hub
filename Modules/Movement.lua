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

-- ELITE FLY SYSTEM (MOBILE & PC OPTIMIZED)
local flyEnabled = false
local flySpeed = 50
local RunService = game:GetService("RunService")
local LP = game.Players.LocalPlayer

-- The Physics Loop
RunService.RenderStepped:Connect(function()
    if not flyEnabled then return end
    
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and hum then
        local cam = workspace.CurrentCamera
        
        -- If player is using joystick/keys, move in that direction relative to camera
        if hum.MoveDirection.Magnitude > 0 then
            root.AssemblyLinearVelocity = hum.MoveDirection * flySpeed
        else
            -- If not moving, stay still in the air (anti-gravity)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Keep the character leveled and facing where the camera looks
        root.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
    end
end)

-- UI Toggle
Tab:CreateToggle({
   Name = "Elite Flight (Joystick Ready)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      
      -- Safety physics reset when turning off
      if not Value then
          local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
          if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
      end
   end,
})

-- UI Speed Slider
Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 500},
   Increment = 5,
   Suffix = "SPS",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      flySpeed = Value
   end,
})

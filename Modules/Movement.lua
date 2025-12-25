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

-- FLY
local LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- States
local _f = false      -- Flight Toggle
local _s = 50         -- Flight Speed

-- [FLIGHT ENGINE]
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if not _f then return end
        
        local char = LP.Character
        local r = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if r and hum then
            local dir = hum.MoveDirection -- Supports Joystick and WASD
            
            if dir.Magnitude > 0 then
                -- Move in direction of input
                r.AssemblyLinearVelocity = dir * _s
            else
                -- Hover perfectly still
                r.AssemblyLinearVelocity = Vector3.zero
            end
            
            -- Prevent gravity from pulling the character down while flying
            r.Velocity = Vector3.new(r.Velocity.X, 0, r.Velocity.Z)
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
      if not Value then
          local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
          if r then r.AssemblyLinearVelocity = Vector3.zero end 
      end
   end,
})

-- Sub-features (Simple Naming)
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

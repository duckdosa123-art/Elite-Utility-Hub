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

-- ELITE DIRECTIONAL FLIGHT SYSTEM
local flyEnabled = false
local flySpeed = 50
local verticalVelocity = 0 -- For the Up/Down buttons
local RunService = game:GetService("RunService")
local LP = game.Players.LocalPlayer

local bG -- BodyGyro to keep you upright

-- The Physics Loop
RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end
    
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and hum then
        local cam = workspace.CurrentCamera
        
        -- Directional Logic: Camera-relative movement
        -- This handles looking up/down to fly up/down
        local moveDir = hum.MoveDirection
        local flyVelocity = cam.CFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z)) * flySpeed
        
        -- Add Vertical Support (Up/Down buttons + Camera Tilt)
        local verticalInput = (moveDir.Z < 0 and cam.CFrame.LookVector.Y or 0) * flySpeed
        root.AssemblyLinearVelocity = flyVelocity + Vector3.new(0, verticalVelocity + verticalInput, 0)
        
        -- Keep character upright and stable
        if bG then bG.CFrame = cam.CFrame end
    end
end)

-- UI Toggle
Tab:CreateToggle({
   Name = "Elite Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      local char = LP.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      
      if Value and root then
          -- Add Gyro to keep you from spinning
          bG = Instance.new("BodyGyro")
          bG.P = 9e4
          bG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
          bG.CFrame = root.CFrame
          bG.Parent = root
      else
          if bG then bG:Destroy() end
          verticalVelocity = 0
          if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
      end
   end,
})

-- Flight Speed
Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 500},
   Increment = 5,
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value) flySpeed = Value end,
})

-- MOBILE HEIGHT CONTROLS
Tab:CreateButton({
   Name = "Ascend (Go Up)",
   Callback = function() verticalVelocity = flySpeed end,
})

Tab:CreateButton({
   Name = "Descend (Go Down)",
   Callback = function() verticalVelocity = -flySpeed end,
})

Tab:CreateButton({
   Name = "Level Out (Stop Up/Down)",
   Callback = function() verticalVelocity = 0 end,
})

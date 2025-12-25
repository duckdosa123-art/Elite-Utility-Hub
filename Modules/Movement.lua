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

-- ELITE DIRECTIONAL FLIGHT (FIXED CONTROLS)
local flyEnabled = false
local flySpeed = 50
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
        local moveDir = hum.MoveDirection
        
        -- FIXED LOGIC: Forward is now based on where the camera is actually pointing
        -- This uses the AssemblyLinearVelocity method from your source 
        if moveDir.Magnitude > 0 then
            root.AssemblyLinearVelocity = cam.CFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z)) * flySpeed
            -- This line specifically adds the "Look Up = Fly Up" logic
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + (cam.CFrame.LookVector * (moveDir.Z * -flySpeed))
        else
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        if bG then bG.CFrame = cam.CFrame end
    end
end)

-- UI Toggle
Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      local char = LP.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      
      if Value and root then
          bG = Instance.new("BodyGyro")
          bG.P = 9e4
          bG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
          bG.CFrame = root.CFrame
          bG.Parent = root
      else
          if bG then bG:Destroy() end
          if root then root.AssemblyLinearVelocity = Vector3.zero end [cite: 5]
      end
   end,
})

-- UP/DOWN INSTANT MOVEMENT
Tab:CreateButton({
   Name = "Up (1 Stud)",
   Callback = function()
       local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if root then
           root.CFrame = root.CFrame * CFrame.new(0, 1, 0)
       end
   end,
})

Tab:CreateButton({
   Name = "(1 Stud)",
   Callback = function()
       local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if root then
           root.CFrame = root.CFrame * CFrame.new(0, -1, 0)
       end
   end,
})

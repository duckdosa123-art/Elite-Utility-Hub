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

-- ELITE FLY SYSTEM
local flyEnabled = false
local flySpeed = 50
local runService = game:GetService("RunService")
local lp = game.Players.LocalPlayer

-- THE PHYSICS LOOP (Wrapped to prevent crashing)
task.spawn(function()
    runService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and hum then
            local cam = workspace.CurrentCamera
            local moveDir = hum.MoveDirection
            
            if moveDir.Magnitude > 0 then
                -- Direct camera-relative velocity
                local velocity = cam.CFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z)) * flySpeed
                -- Add verticality based on camera pitch
                local vertical = cam.CFrame.LookVector.Y * (moveDir.Z * -flySpeed)
                root.AssemblyLinearVelocity = velocity + Vector3.new(0, vertical, 0)
            else
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            
            -- Lock character rotation to camera
            root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z))
        end
    end)
end)

-- UI CONTROLS
Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      local char = lp.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
   end,
})

Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 500},
   Increment = 5,
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value) flySpeed = Value end,
})

Tab:CreateButton({
   Name = "UP (one stud)",
   Callback = function()
       local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
       if root then root.CFrame = root.CFrame * CFrame.new(0, 1, 0) end
   end,
})

Tab:CreateButton({
   Name = "DOWN (one stud)",
   Callback = function()
       local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
       if root then root.CFrame = root.CFrame * CFrame.new(0, -1, 0) end
   end,
})

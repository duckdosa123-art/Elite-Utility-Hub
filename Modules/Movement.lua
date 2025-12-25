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

-- THE ELITE FLY ENGINE (Mobile & PC Optimized)
local function UpdateFlight()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum then return end

    -- Create physics stabilizers if they don't exist
    local bv = root:FindFirstChild("EliteVelocity") or Instance.new("BodyVelocity", root)
    local bg = root:FindFirstChild("EliteGyro") or Instance.new("BodyGyro", root)
    
    bv.Name = "EliteVelocity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    bg.Name = "EliteGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = workspace.CurrentCamera.CFrame

    if isFlying then
        -- This part captures the Mobile Joystick or WASD input
        local dir = hum.MoveDirection
        local cam = workspace.CurrentCamera.CFrame
        
        -- Calculate movement relative to camera look direction
        if dir.Magnitude > 0 then
            bv.Velocity = dir * flySpeed
        else
            bv.Velocity = Vector3.new(0, 0.1, 0) -- Hover steady
        end
        
        -- Tilt the character slightly toward the camera view
        bg.CFrame = cam
    else
        -- Clean up physics when disabled
        bv:Destroy()
        bg:Destroy()
        if flyConnection then flyConnection:Disconnect() end
    end
end

-- RAYFIELD INTEGRATION
Tab:CreateToggle({
   Name = "Elite Flight (Logic by: sukuna_ryomen1.)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      isFlying = Value
      if isFlying then
          -- Start the physics loop
          flyConnection = RunService.Heartbeat:Connect(UpdateFlight)
      else
          UpdateFlight() -- Triggers the cleanup block
      end
   end,
})

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

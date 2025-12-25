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

-- FLY SCRIPT
local flyScriptURL = "https://obj.wearedevs.net/2/scripts/Fly.lua"
local LP = game:GetService("Players").LocalPlayer

Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      if Value then
          -- RUN THE SCRIPT
          loadstring(game:HttpGet(flyScriptURL))()
          Rayfield:Notify({Title = "Elite Hub", Content = "Fly Script Loaded!", Duration = 2})
      else
          -- KILL THE SCRIPT
          -- We find the GUI by the name defined in its source code 
          local flyGui = LP.PlayerGui:FindFirstChild("Elite_Project_v3")
          if flyGui then
              flyGui:Destroy()
          end
          
          -- Reset physics to stop any sliding 
          local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
          if root then 
              root.AssemblyLinearVelocity = Vector3.new(0,0,0) 
          end
          
          Rayfield:Notify({Title = "Elite Hub", Content = "Fly Script Disabled", Duration = 2})
      end
   end,
})

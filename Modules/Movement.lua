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
local flyEnabled = false
local flySpeed = 50
local runService = game:GetService("RunService")
local lp = game:GetService("Players").LocalPlayer

local function SetupFly(Value)
    flyEnabled = Value
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    if flyEnabled then
        -- Create physics movers for maximum smoothness
        local bg = Instance.new("BodyGyro", root) -- Keeps you upright
        bg.Name = "EliteFlyGyro"
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = root.CFrame

        local bv = Instance.new("BodyVelocity", root) -- Handles the actual movement
        bv.Name = "EliteFlyVel"
        bv.velocity = Vector3.new(0, 0.1, 0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

        -- The Render Loop
        task.spawn(function()
            while flyEnabled and char:Parent() do
                local camera = workspace.CurrentCamera
                -- This math makes the flight follow your camera view perfectly
                bv.velocity = camera.CFrame.LookVector * flySpeed
                bg.cframe = camera.CFrame
                runService.RenderStepped:Wait()
            end
            -- Cleanup when disabled
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
        end)
    else
        -- Force remove physics objects if they exist
        if root:FindFirstChild("EliteFlyGyro") then root.EliteFlyGyro:Destroy() end
        if root:FindFirstChild("EliteFlyVel") then root.EliteFlyVel:Destroy() end
    end
end

-- RAYFIELD UI INTEGRATION
Tab:CreateToggle({
   Name = "Elite Fly(Logic by: Mohii03",
   CurrentValue = false,
   Flag = "SmoothFly",
   Callback = function(Value)
      SetupFly(Value)
   end,
})

Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {0, 500},
   Increment = 5,
   Suffix = "SPS",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      flySpeed = Value
   end,
})

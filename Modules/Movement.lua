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

-- FLY LOGIC VARIABLES
local flyEnabled = false
local flySpeed = 50
local c = nil -- Connection variable

-- THE REFINED FLY ENGINE
local function ToggleFly(Value)
    flyEnabled = Value
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    if flyEnabled then
        -- Create a "BodyVelocity" to handle the floating physics
        local bv = Instance.new("BodyVelocity")
        bv.Name = "EliteFlyForce"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
        
        -- The loop that handles movement direction
        c = game:GetService("RunService").Heartbeat:Connect(function()
            if not flyEnabled or not char:Parent() then 
                bv:Destroy()
                c:Disconnect() 
                return 
            end
            
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new(0,0,0)
            
            -- Direction logic (works with mobile joysticks)
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                moveDir = hum.MoveDirection * flySpeed
                bv.Velocity = moveDir + Vector3.new(0, 1.5, 0) -- Added slight lift to stay level
            end
        end)
    else
        -- Clean up when turned off
        if root:FindFirstChild("EliteFlyForce") then
            root.EliteFlyForce:Destroy()
        end
        if c then c:Disconnect() end
    end
end

-- RAYFIELD UI TOGGLE
Tab:CreateToggle({
   Name = "Elite Flight (Discord Refined)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      ToggleFly(Value)
   end,
})

-- FLY SPEED SLIDER
Tab:CreateSlider({
   Name = "Flight Speed",
   Range = {10, 300},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      flySpeed = Value
   end,
})

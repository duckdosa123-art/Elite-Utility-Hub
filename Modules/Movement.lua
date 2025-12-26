-- Movement.lua - Elite-Utility-Hub
local LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Tab = _G.MoveTab

-- Capture default values
local char = LP.Character or LP.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local defaultWS = hum.WalkSpeed or 16
local defaultJP = hum.JumpPower or 50

-- States
local _f = false      -- Flight
local _s = 50         -- Flight Speed
local _nc = false     -- Noclip
local _ij = false     -- Inf Jump
local canJump = true  -- Jump Debounce
local bv, bg          -- Body Movers

-- [ 1. SPEED & JUMP SECTION ]
local SpeedSlider = Tab:CreateSlider({
   Name = "Elite Speed",
   Range = {16, 250},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = defaultWS,
   Flag = "SpeedSlider",
   Callback = function(Value)
      local h = LP.Character and LP.Character:FindFirstChild("Humanoid")
      if h then
         h.WalkSpeed = Value
         _G.EliteLog("WalkSpeed set to " .. Value, "info")
      end
   end,
})

local JumpSlider = Tab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 500},
   Increment = 1,
   Suffix = "Power",
   CurrentValue = defaultJP,
   Flag = "JumpSlider",
   Callback = function(Value)
      local h = LP.Character and LP.Character:FindFirstChild("Humanoid")
      if h then
         h.JumpPower = Value
         _G.EliteLog("JumpPower set to " .. Value, "info")
      end
   end,
})

Tab:CreateButton({
   Name = "Reset to Game Defaults",
   Callback = function()
       local h = LP.Character and LP.Character:FindFirstChild("Humanoid")
       if h then
           SpeedSlider:Set(defaultWS)
           JumpSlider:Set(defaultJP)
           _G.EliteLog("Movement stats reset to defaults", "success")
       end
   end,
})

Tab:CreateSection("Elite Flight System")

-- [ 2. FLIGHT ENGINE ]
local function CleanFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.PlatformStand = false
        h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        h:ChangeState(Enum.HumanoidStateType.Running)
    end
end

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        if _f and r and h and cam then
            if not bv then
                bv = Instance.new("BodyVelocity", r)
                bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
            end
            if not bg then
                bg = Instance.new("BodyGyro", r)
                bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
                bg.P = 9000
            end

            h.PlatformStand = true
            h:ChangeState(Enum.HumanoidStateType.Physics)

            local moveDir = h.MoveDirection
            local localDir = cam.CFrame:VectorToObjectSpace(moveDir)
            local up = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
            local down = UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0
            local vertical = Vector3.new(0, (up - down) * _s, 0)

            local velocity = (cam.CFrame.LookVector * (-localDir.Z * _s)) + (cam.CFrame.RightVector * (localDir.X * _s))
            bv.Velocity = (moveDir.Magnitude > 0 or up ~= 0 or down ~= 0) and velocity + vertical or Vector3.zero
            bg.CFrame = cam.CFrame 
        else
            if bv or bg then CleanFly() end
        end
    end)
end)

Tab:CreateToggle({
   Name = "Elite Flight",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      _f = Value
      _G.EliteLog("Flight: " .. (Value and "Enabled" or "Disabled"), Value and "success" or "warn")
      if not Value then CleanFly() end
   end,
})

Tab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      _s = Value
      _G.EliteLog("Flight Speed updated to " .. Value, "info")
   end,
})

Tab:CreateButton({
   Name = "UP (one stud)",
   Callback = function()
       local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if r then 
           r.CFrame = r.CFrame * CFrame.new(0, 1, 0) 
           _G.EliteLog("Position Adjusted: +1 Stud Up", "info")
       end
   end,
})

Tab:CreateButton({
   Name = "DOWN (one stud)",
   Callback = function()
       local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
       if r then 
           r.CFrame = r.CFrame * CFrame.new(0, -1, 0) 
           _G.EliteLog("Position Adjusted: -1 Stud Down", "info")
       end
   end,
})

Tab:CreateSection("Movement Physics")

-- [ 3. INF JUMP ENGINE ]
UIS.JumpRequest:Connect(function()
    if _ij and canJump then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then
            canJump = false 
            h:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.25) 
            canJump = true 
        end
    end
end)

Tab:CreateToggle({
   Name = "Elite Inf-Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      _ij = Value
      _G.EliteLog("Infinite Jump: " .. (Value and "Enabled" or "Disabled"), Value and "success" or "warn")
   end,
})

-- [ 4. NOCLIP ENGINE ]
task.spawn(function()
    RunService.Stepped:Connect(function()
        if _nc then
            local c = LP.Character
            if c then
                for _, part in pairs(c:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

Tab:CreateToggle({
   Name = "Elite Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      _nc = Value
      _G.EliteLog("Noclip: " .. (Value and "Enabled" or "Disabled"), Value and "success" or "warn")
      if not Value then
          local c = LP.Character
          if c then
              for _, p in pairs(c:GetDescendants()) do
                  if p:IsA("BasePart") then p.CanCollide = true end
              end
          end
      end
   end,
})
-- ELITE TP-WALK (CFrame Speed Bypass)
local TPWalkConnection
local TPWalkSpeed = 2

Tab:CreateSlider({
   Name = "Elite TP-Walk Speed",
   Range = {0, 10},
   Increment = 0.1,
   Suffix = "Mult",
   CurrentValue = 2,
   Callback = function(Value)
      TPWalkSpeed = Value
   end,
})

Tab:CreateToggle({
   Name = "Elite TP-Walk",
   CurrentValue = false,
   Callback = function(Value)
      _G.TPWalkEnabled = Value
      if TPWalkConnection then TPWalkConnection:Disconnect() end
      
      if Value then
         _G.EliteLog("TP-Walk Enabled (Bypass Mode)", "success")
         TPWalkConnection = game:GetService("RunService").PreSimulation:Connect(function()
            local Char = LP.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
            
            if Root and Hum and Hum.MoveDirection.Magnitude > 0 then
                -- Move the CFrame forward based on MoveDirection (Joystick compatible)
               Root.CFrame = Root.CFrame + (Hum.MoveDirection * (TPWalkSpeed / 10))
            end
         end)
      else
         _G.EliteLog("TP-Walk Disabled", "info")
      end
   end,
})

-- ELITE SPIDER (Surface Alignment & Wall Walk)
local SpiderConnection = nil
local StickyTrail = nil

Tab:CreateToggle({
   Name = "Elite Spider",
   CurrentValue = false,
   Callback = function(Value)
      _G.SpiderEnabled = Value
      
      -- Cleanup
      if SpiderConnection then SpiderConnection:Disconnect() end
      if StickyTrail then StickyTrail:Destroy() StickyTrail = nil end

      if Value then
         _G.EliteLog("Spider Mode: Surface Aligned", "success")
         
         -- Visual Effect: Sticky Trail
         StickyTrail = Instance.new("SelectionBox")
         StickyTrail.LineThickness = 0.05
         StickyTrail.SurfaceColor3 = Color3.fromRGB(0, 255, 150) -- Elite Teal
         StickyTrail.SurfaceTransparency = 0.8
         StickyTrail.Adornee = nil 
         StickyTrail.Parent = game:GetService("CoreGui")

         SpiderConnection = game:GetService("RunService").PreSimulation:Connect(function()
            local Char = LP.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
            
            if Root and Hum then
               local rayParams = RaycastParams.new()
               rayParams.FilterDescendantsInstances = {Char}
               rayParams.FilterType = Enum.RaycastFilterType.Exclude
               
               -- Check for wall directly in front
               local direction = Hum.MoveDirection.Magnitude > 0 and Hum.MoveDirection or Root.CFrame.LookVector
               local wallCheck = workspace:Raycast(Root.Position, direction * 2.5, rayParams)
               
               if wallCheck and wallCheck.Instance then
                  -- 1. ADHESION: Keep character stuck to wall
                  -- Counteract gravity and move UP based on walk direction
                  local climbSpeed = Hum.WalkSpeed * 0.8
                  Root.AssemblyLinearVelocity = Vector3.new(
                     Root.AssemblyLinearVelocity.X, 
                     climbSpeed, 
                     Root.AssemblyLinearVelocity.Z
                  )
                  
                  -- 2. ALIGNMENT (The "Cool" Part): Tilt body to the wall surface
                  -- We lerp the CFrame to look at the wall normal for a smooth crawl
                  local lookAtNormal = Root.Position + wallCheck.Normal
                  local targetCFrame = CFrame.lookAt(Root.Position, wallCheck.Position, wallCheck.Normal)
                  Root.CFrame = Root.CFrame:Lerp(targetCFrame, 0.15)
                  
                  -- 3. VISUAL PULSE
                  StickyTrail.Adornee = wallCheck.Instance
                  StickyTrail.Color3 = Color3.fromHSV(tick() % 5 / 5, 1, 1) -- Rainbow Pulse
               else
                  -- Reset if not hitting a wall
                  StickyTrail.Adornee = nil
               end
            end
         end)
      else
         _G.EliteLog("Spider Mode: Disabled", "info")
      end
   end,
})

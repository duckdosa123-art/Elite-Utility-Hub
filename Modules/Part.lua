-- PART CONTROL
Tab:CreateSection("Part Main")


-- [[ ELITE KILL-BRICK IMMUNITY V3: BRUTE-FORCE SENSOR ]]
local KillBrickLoop = nil
local CheckpointSafeTags = {"checkpoint", "spawn", "stage", "reset", "teleport", "pad", "flag", "win", "end"}

-- Helper: Brute-force toggle character touch
local function ToggleTouch(state)
    local char = LP.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = state
            end
        end
    end
end

Tab:CreateToggle({
   Name = "Elite Kill-Brick Immunity",
   CurrentValue = false,
   Callback = function(Value)
      _G.KillBrickEnabled = Value
      
      -- Cleanup
      if KillBrickLoop then KillBrickLoop:Disconnect() end
      
      if Value then
         _G.EliteLog("Immunity: Brute-Force Sensor Active", "success")
         
         -- Notifications
         local msg = "Kill-Brick Immunity: ENABLED"
         game:GetService("StarterGui"):SetCore("SendNotification", {
             Title = "Elite Hub",
             Text = msg,
             Duration = 3,
             Icon = "rbxassetid://4483362458"
         })

         -- START THE SENSOR LOOP
         KillBrickLoop = game:GetService("RunService").Heartbeat:Connect(function()
            if not _G.KillBrickEnabled then return end
            
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- 1. DEFINE THE SENSOR BOX (At player's feet)
            local sensorPos = root.Position - Vector3.new(0, 3, 0)
            local sensorSize = Vector3.new(4, 4, 4) -- Large enough to detect buried parts
            
            local params = OverlapParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Exclude

            -- 2. THE BRUTE-FORCE SCAN (Sees through everything)
            local nearbyParts = workspace:GetPartBoundsInBox(CFrame.new(sensorPos), sensorSize, params)
            
            local overCheckpoint = false
            for _, part in pairs(nearbyParts) do
               -- Check if it's a SpawnLocation or matches safe keywords
               if part:IsA("SpawnLocation") then
                  overCheckpoint = true
                  break
               end
               
               local name = part.Name:lower()
               for _, tag in pairs(CheckpointSafeTags) do
                  if name:find(tag) then
                     overCheckpoint = true
                     break
                  end
               end
               if overCheckpoint then break end
            end

            -- 3. STATE SWITCHING
            -- If we are touching a checkpoint, ENABLE touch. Otherwise, DISABLE it.
            if overCheckpoint then
               ToggleTouch(true)
            else
               ToggleTouch(false)
            end
            
            -- 4. FALLBACK: FireTouchInterest (Ensures 100% registration on executors that support it)
            if overCheckpoint and firetouchinterest then
               for _, part in pairs(nearbyParts) do
                  firetouchinterest(root, part, 0)
                  firetouchinterest(root, part, 1)
               end
            end
         end)
      else
         _G.EliteLog("Immunity: Disabled", "info")
         ToggleTouch(true)
         
         game:GetService("StarterGui"):SetCore("SendNotification", {
             Title = "Elite Hub",
             Text = "Kill-Brick Immunity: DISABLED",
             Duration = 3
         })
      end
   end,
})

Tab:CreateSection("Player Physics")
local _f = false      -- Flight
local _s = 50         -- Flight Speed
local _nc = false     -- Noclip

-- [ 1. FLIGHT ENGINE ]
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

-- [ 2. NOCLIP ENGINE ]
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

Tab:CreateSection("Detached Part Control")
-- [[ PART MODULE: ELITE CONTROL SWARM ]]
local Tab = _G.PartTab
local LP = _G.LP
local Camera = workspace.CurrentCamera
local OrbitParts = {}
local OrbitConn = nil

local ManipSettings = {
    Enabled = false,
    Radius = 10,
    Speed = 4,
    Distance = 15, -- How far the "bubble" is from your camera
    Height = 0,
    Power = 100,
    MaxParts = 80
}

-- [ ENGINE: NETWORK OWNERSHIP SCANNER ]
local function RefreshSwarm()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local newParts = {}
    local count = 0
    
    -- Scans for unanchored props to "claim"
    for _, v in pairs(workspace:GetDescendants()) do
        if count >= ManipSettings.MaxParts then break end
        if v:IsA("BasePart") and not v.Anchored then
            -- Ignore baseplates, terrain, and players
            local isPlayer = v:FindFirstAncestorOfClass("Model") and v:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid")
            if not isPlayer and v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                -- Local Ghosting (FE Safe)
                v.CanCollide = false
                v.CanQuery = false
                
                table.insert(newParts, v)
                count = count + 1
            end
        end
    end
    OrbitParts = newParts
end

Tab:CreateSection("Elite Swarm Controller")

Tab:CreateToggle({
   Name = "Elite Swarm Orbit",
   CurrentValue = false,
   Callback = function(Value)
      ManipSettings.Enabled = Value
      if OrbitConn then OrbitConn:Disconnect() end
      
      if Value then
          _G.EliteLog("Swarm Active: Camera Control Engaged", "success")
          RefreshSwarm()
          
          -- PRE-SIMULATION: Runs before physics, ensuring the parts "stick" to the target
          OrbitConn = game:GetService("RunService").PreSimulation:Connect(function()
              local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
              if not Root or not ManipSettings.Enabled then return end
              
              -- 1. CALCULATE THE CONTROL POINT (In front of Camera)
              local ControlPoint = Camera.CFrame.Position + (Camera.CFrame.LookVector * ManipSettings.Distance)
              
              local Time = tick()
              for i, part in pairs(OrbitParts) do
                  if part and part.Parent and not part.Anchored then
                      -- 2. CALCULATE CIRCULAR TARGET
                      local angle = (Time * ManipSettings.Speed) + (i * (math.pi * 2 / #OrbitParts))
                      local targetPos = ControlPoint + Vector3.new(
                          math.cos(angle) * ManipSettings.Radius,
                          ManipSettings.Height,
                          math.sin(angle) * ManipSettings.Radius
                      )
                      
                      -- 3. VELOCITY INJECTION (Network Ownership Claim)
                      local vec = (targetPos - part.Position)
                      local dist = vec.Magnitude
                      
                      -- Proportional velocity with a "Sticky" cap to prevent flinging
                      local drive = math.min(dist * 15, 120) 
                      part.AssemblyLinearVelocity = vec.Unit * drive
                      
                      -- Keep parts ghosted so they don't hit the player
                      part.CanCollide = false
                      part.CanQuery = false
                  else
                      table.remove(OrbitParts, i)
                  end
              end
          end)
          
          -- Background Watchdog
          task.spawn(function()
              while ManipSettings.Enabled do
                  task.wait(2)
                  if #OrbitParts < 5 then RefreshSwarm() end
              end
          end)
      else
          _G.EliteLog("Swarm Released", "info")
          for _, v in pairs(OrbitParts) do 
              if v and v.Parent then 
                  v.CanCollide = true 
                  v.CanQuery = true 
                  v.AssemblyLinearVelocity = Vector3.zero 
              end 
          end
          OrbitParts = {}
      end
   end,
})

Tab:CreateButton({
   Name = "Elite Launch Swarm (Forward)",
   Callback = function()
      if #OrbitParts == 0 then return end
      _G.EliteLog("Launching Swarm!", "success")
      
      local launchDir = Camera.CFrame.LookVector
      for _, part in pairs(OrbitParts) do
          if part and part.Parent then
              part.AssemblyLinearVelocity = launchDir * 250 -- Massive impulse
          end
      end
      -- Clear the table so they don't snap back immediately
      OrbitParts = {}
   end,
})

Tab:CreateSection("Swarm Customization")

Tab:CreateSlider({
   Name = "Control Distance",
   Range = {5, 100},
   Increment = 1,
   CurrentValue = 15,
   Callback = function(V) ManipSettings.Distance = V end,
})

Tab:CreateSlider({
   Name = "Swarm Radius",
   Range = {2, 50},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(V) ManipSettings.Radius = V end,
})

Tab:CreateSlider({
   Name = "Swarm Speed",
   Range = {1, 30},
   Increment = 1,
   CurrentValue = 4,
   Callback = function(V) ManipSettings.Speed = V end,
})

Tab:CreateButton({
   Name = "Force Re-Scan Props",
   Callback = function() 
       RefreshSwarm()
       _G.EliteLog("Captured " .. #OrbitParts .. " parts.", "info")
   end,
})

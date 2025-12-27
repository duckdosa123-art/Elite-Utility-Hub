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


Tab:CreateSection("Detached Part Control")
-- [[ PART MODULE: ELITE-UTILITY-HUB ]]
local OrbitParts = {}
local OrbitConn = nil

local ManipSettings = {
    Enabled = false,
    Radius = 12,
    Speed = 4,
    Height = 1,
    Bobbing = 2,
    MaxVelocity = 100, -- Capped for stability
    MaxParts = 100
}

-- [ ENGINE: UNIVERSAL SCANNER ]
local function RefreshManipParts()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local newPartList = {}
    local count = 0
    
    for _, v in pairs(workspace:GetDescendants()) do
        if count >= ManipSettings.MaxParts then break end
        
        if v:IsA("BasePart") and not v.Anchored then
            if v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                -- Strict Player Check
                local isPlayer = v:FindFirstAncestorOfClass("Model") and v:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid")
                
                if not isPlayer then
                    v.CanCollide = false
                    v.CanQuery = false 
                    table.insert(newPartList, v)
                    count = count + 1
                end
            end
        end
    end
    OrbitParts = newPartList
end

Tab:CreateSection("Prop Swarm Controller")

Tab:CreateToggle({
   Name = "Elite Part Orbit",
   CurrentValue = false,
   Callback = function(Value)
      ManipSettings.Enabled = Value
      if OrbitConn then OrbitConn:Disconnect() end
      
      if Value then
          _G.EliteLog("Prop Swarm Activated", "success")
          RefreshManipParts()
          
          OrbitConn = RunService.Heartbeat:Connect(function()
              local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
              if not Root or not ManipSettings.Enabled then return end
              
              local Time = tick()
              for i, part in pairs(OrbitParts) do
                  if part and part.Parent and not part.Anchored then
                      -- 1. CALCULATE TARGET POSITION
                      local angle = (Time * ManipSettings.Speed) + (i * (math.pi * 2 / #OrbitParts))
                      local bob = math.sin(Time * 2 + i) * ManipSettings.Bobbing
                      
                      local targetPos = Root.Position + Vector3.new(
                          math.cos(angle) * ManipSettings.Radius,
                          ManipSettings.Height + bob,
                          math.sin(angle) * ManipSettings.Radius
                      )
                      
                      -- 2. STICKY PHYSICS (Capped Velocity)
                      local distanceVector = (targetPos - part.Position)
                      local distance = distanceVector.Magnitude
                      local direction = distanceVector.Unit
                      
                      local speed = math.min(distance * 12, ManipSettings.MaxVelocity)
                      
                      if distance > 0.1 then
                          part.AssemblyLinearVelocity = direction * speed
                      else
                          part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                      end
                      
                      part.CanCollide = false
                  else
                      table.remove(OrbitParts, i)
                  end
              end
          end)
          
          -- Intelligent Watchdog
          task.spawn(function()
              while ManipSettings.Enabled do
                  if #OrbitParts < 5 then RefreshManipParts() end
                  task.wait(2)
              end
          end)
      else
          _G.EliteLog("Swarm Disengaged", "info")
          for _, v in pairs(OrbitParts) do 
              if v and v.Parent then 
                  v.CanCollide = true 
                  v.CanQuery = true 
                  v.AssemblyLinearVelocity = Vector3.new(0,0,0)
              end 
          end
          OrbitParts = {}
      end
   end,
})

Tab:CreateSlider({
   Name = "Orbit Radius",
   Range = {5, 100},
   Increment = 1,
   CurrentValue = 12,
   Callback = function(V) ManipSettings.Radius = V end,
})

Tab:CreateSlider({
   Name = "Orbit Speed",
   Range = {1, 25},
   Increment = 1,
   CurrentValue = 4,
   Callback = function(V) ManipSettings.Speed = V end,
})

Tab:CreateSlider({
   Name = "Stability (Power)",
   Range = {25, 250},
   Increment = 5,
   CurrentValue = 100,
   Callback = function(V) ManipSettings.MaxVelocity = V end,
})

Tab:CreateButton({
   Name = "Force Capture All Props",
   Callback = function() 
       RefreshManipParts()
       _G.EliteLog("Captured " .. #OrbitParts .. " props.", "info")
   end,
})

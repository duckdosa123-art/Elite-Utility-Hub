-- PART CONTROL
Tab:CreateSection("Part Main")


-- ELITE KILL-BRICK IMMUNITY V2 (Checkpoint Compatible)
local KillBrickConnection = nil
local CheckpointScanner = nil

-- List of keywords games usually use for checkpoints
local CheckpointNames = {"checkpoint", "spawn", "stage", "reset", "teleport", "pad", "flag"}

-- Helper: Disable touch on character parts
local function SetCharacterTouch(state)
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
      _G.KillBrickImmune = Value
      
      -- Cleanup old connections
      if KillBrickConnection then KillBrickConnection:Disconnect() end
      if CheckpointScanner then CheckpointScanner:Disconnect() end

      if Value then
         _G.EliteLog("Immunity Active: Auto-Checkpoint Engaged", "success")
         
         -- 1. Apply physical immunity
         task.spawn(function() SetCharacterTouch(false) end)
         
         -- 2. Persistent Respawn Logic
         KillBrickConnection = LP.CharacterAdded:Connect(function(char)
            task.wait(1)
            if _G.KillBrickImmune then SetCharacterTouch(false) end
         end)

         -- 3. THE CHECKPOINT SCANNER (The Fix)
         -- Scans the floor 10 studs below you for checkpoints
         CheckpointScanner = game:GetService("RunService").Heartbeat:Connect(function()
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local rayParam = RaycastParams.new()
            rayParam.FilterDescendantsInstances = {char}
            rayParam.FilterType = Enum.RaycastFilterType.Exclude

            local ray = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), rayParam)
            
            if ray and ray.Instance then
                local hit = ray.Instance
                local isCheckpoint = false

                -- Check if it's a real SpawnLocation or matches keywords
                if hit:IsA("SpawnLocation") then
                    isCheckpoint = true
                else
                    for _, name in pairs(CheckpointNames) do
                        if hit.Name:lower():find(name) then
                            isCheckpoint = true
                            break
                        end
                    end
                end

                -- If it's a checkpoint, force a "Touch" event via exploit API
                if isCheckpoint and firetouchinterest then
                    firetouchinterest(root, hit, 0) -- Touch began
                    task.wait()
                    firetouchinterest(root, hit, 1) -- Touch ended
                end
            end
         end)
         
         -- Notifications
         game:GetService("StarterGui"):SetCore("SendNotification", {
             Title = "Elite Hub",
             Text = "Immunity ON (Checkpoints OK)",
             Duration = 3
         })
      else
         -- Restore everything
         _G.EliteLog("Immunity Disabled", "info")
         SetCharacterTouch(true)
         game:GetService("StarterGui"):SetCore("SendNotification", {
             Title = "Elite Hub",
             Text = "Immunity OFF",
             Duration = 3
         })
      end
   end,
})


Tab:CreateSection("Part Control")
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

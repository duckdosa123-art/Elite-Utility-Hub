-- PART CONTROL
Tab:CreateSection("Part Control")


Tab:CreateToggle({
   Name = "Immune to Kill Bricks",
   CurrentValue = false,
   Callback = function(Value)
      local char = LP.Character
      if char then
          for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanTouch = not Value end end
      end
      _G.EliteLog("Kill Brick Immunity: "..tostring(Value), "info")
   end,
})
-- [[ ELITE PART MANIPULATOR V5: STICKY SWARM ]]
local OrbitParts = {}
local OrbitConn = nil

local ManipSettings = {
    Enabled = false,
    Radius = 15,
    Speed = 3,
    Height = 2,
    Bobbing = 0,
    MaxParts = 300 -- Massive increase to capture everything
}

-- [ ENGINE: HIGH-SPEED UNIVERSAL SCANNER ]
local function RefreshManipParts()
    local newPartList = {}
    local count = 0
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- We scan workspace directly for better performance
    for _, v in pairs(workspace:GetPartBoundsInRadius(root.Position, 300)) do -- 300 Stud range for network ownership
        if count >= ManipSettings.MaxParts then break end
        
        if v:IsA("BasePart") and not v.Anchored then
            -- FASTER PLAYER CHECK: Just check if the model has a humanoid
            local model = v.Parent
            local isPlayer = (model and model:FindFirstChildOfClass("Humanoid")) or (model and model.Parent and model.Parent:FindFirstChildOfClass("Humanoid"))
            
            if not isPlayer and v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                -- Setup Physics Properties
                v.CanCollide = false
                v.CanTouch = false
                v.CanQuery = false
                
                table.insert(newPartList, v)
                count = count + 1
            end
        end
    end
    OrbitParts = newPartList
end

Tab:CreateSection("Elite Part Manipulator")

Tab:CreateToggle({
   Name = "Elite Part Orbit",
   CurrentValue = false,
   Callback = function(Value)
      ManipSettings.Enabled = Value
      if OrbitConn then OrbitConn:Disconnect() end
      
      if Value then
          _G.EliteLog("Orbit Active: Swarm Mode Engaged", "success")
          RefreshManipParts()
          
          OrbitConn = game:GetService("RunService").Heartbeat:Connect(function()
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
                      
                      -- 2. STICKY PHYSICS (Damping Logic)
                      -- This calculates the distance and applies velocity relative to how far it is.
                      -- This stops the "flinging" because it slows down as it reaches the target.
                      local distVector = (targetPos - part.Position)
                      local magnitude = distVector.Magnitude
                      
                      -- Tug strength based on distance
                      local tugStrength = magnitude * 12
                      part.AssemblyLinearVelocity = distVector.Unit * tugStrength
                      
                      -- Zero out rotation to stop parts from spinning out of control
                      part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                      
                      -- Safety Guard (Ensures they stay ghosted to you)
                      part.CanCollide = false
                  else
                      table.remove(OrbitParts, i)
                  end
              end
          end)
          
          -- AGGRESSIVE WATCHDOG: Scans every 1 second
          task.spawn(function()
              while ManipSettings.Enabled do
                  RefreshManipParts()
                  task.wait(1)
              end
          end)
      else
          _G.EliteLog("Orbit Disengaged", "info")
          for _, v in pairs(OrbitParts) do 
              if v and v.Parent then 
                  v.CanCollide = true 
                  v.CanQuery = true 
                  v.AssemblyLinearVelocity = Vector3.new(0,0,0)
              end 
          end
      end
   end,
})

Tab:CreateSlider({
   Name = "Orbit Radius",
   Range = {5, 100},
   Increment = 1,
   CurrentValue = 15,
   Callback = function(V) ManipSettings.Radius = V end,
})

Tab:CreateSlider({
   Name = "Orbit Speed",
   Range = {1, 30},
   Increment = 1,
   CurrentValue = 3,
   Callback = function(V) ManipSettings.Speed = V end,
})

Tab:CreateSlider({
   Name = "Vertical Offset",
   Range = {-10, 30},
   Increment = 1,
   CurrentValue = 2,
   Callback = function(V) ManipSettings.Height = V end,
})

Tab:CreateSlider({
   Name = "Vertical Bobbing",
   Range = {0, 20},
   Increment = 1,
   CurrentValue = 0,
   Callback = function(V) ManipSettings.Bobbing = V end,
})

Tab:CreateButton({
   Name = "Force Re-Scan World",
   Callback = function() 
       RefreshManipParts()
       _G.EliteLog("Swarm Size: " .. #OrbitParts, "info")
   end,
})

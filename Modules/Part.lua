-- PART CONTROL
Tab:CreateSection("Part Main")


-- ELITE KILL-BRICK IMMUNITY (Persistent & Flexible)
local KillBrickConnection = nil

-- Helper function to set the state
local function SetKillBrickImmunity(state)
    local char = LP.Character or LP.CharacterAdded:Wait()
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanTouch = not state
            end
        end
    end
end

Tab:CreateToggle({
   Name = "Elite Kill-Brick Immunity",
   CurrentValue = false,
   Callback = function(Value)
      _G.KillBrickImmune = Value
      
      -- 1. Immediate Apply
      task.spawn(function()
          SetKillBrickImmunity(Value)
      end)
      
      -- 2. Persistence Logic (Re-applies on respawn)
      if KillBrickConnection then KillBrickConnection:Disconnect() end
      if Value then
          KillBrickConnection = LP.CharacterAdded:Connect(function()
              task.wait(1) -- Wait for character parts to load
              if _G.KillBrickImmune then
                  SetKillBrickImmunity(true)
              end
          end)
      end

      -- 3. Double-Layer Notifications
      local statusText = Value and "Enabled" or "Disabled"
      
      -- Rayfield Notify
      Rayfield:Notify({
         Title = "Elite Utility",
         Content = "Kill Brick Immunity: " .. statusText,
         Duration = 3,
         Image = 4483362458,
      })
      
      -- Roblox System Notification
      game:GetService("StarterGui"):SetCore("SendNotification", {
          Title = "Elite Hub",
          Text = "Kill Brick Immunity is now " .. statusText,
          Duration = 3,
          Icon = "rbxassetid://4483362458"
      })

      _G.EliteLog("Kill Brick Immunity: " .. statusText, Value and "success" or "info")
   end,
})
Tab:CreateSection("Part Control")
-- [[ ELITE PART MANIPULATOR V5: STICKY UNIVERSAL ORBIT ]]
local OrbitParts = {}
local OrbitConn = nil

local ManipSettings = {
    Enabled = false,
    Radius = 12,
    Speed = 4,
    Height = 1,
    Bobbing = 2,
    MaxVelocity = 100, -- Prevents parts from "launching" away
    MaxParts = 100
}

-- [ ENGINE: UNIVERSAL SCANNER ]
-- Optimized to find everything nearby that isn't a player
local function RefreshManipParts()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local newPartList = {}
    local count = 0
    
    -- We scan the workspace but filter aggressively for props
    for _, v in pairs(workspace:GetDescendants()) do
        if count >= ManipSettings.MaxParts then break end
        
        if v:IsA("BasePart") and not v.Anchored then
            -- Skip baseplate and terrain
            if v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                -- Player Check: Ensure it's not a character part
                local isPlayer = v:FindFirstAncestorOfClass("Model") and v:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid")
                
                if not isPlayer then
                    -- Setup Physics Properties
                    v.CanCollide = false
                    v.CanQuery = false -- Camera safe
                    
                    table.insert(newPartList, v)
                    count = count + 1
                end
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
          _G.EliteLog("Orbit: Sticky Physics Engaged", "success")
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
                      
                      -- 2. CAPPED VELOCITY LOGIC (Prevents Launching/Flinging)
                      local distanceVector = (targetPos - part.Position)
                      local distance = distanceVector.Magnitude
                      local direction = distanceVector.Unit
                      
                      -- Proportional speed: Fast when far, slow when close, but capped at MaxVelocity
                      local speed = math.min(distance * 12, ManipSettings.MaxVelocity)
                      
                      if distance > 0.1 then
                          part.AssemblyLinearVelocity = direction * speed
                      else
                          part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                      end
                      
                      -- Force collision off to prevent flinging YOUR character
                      part.CanCollide = false
                  else
                      table.remove(OrbitParts, i)
                  end
              end
          end)
          
          -- WATCHDOG: Intelligent Rescan (Doesn't wipe table every time)
          task.spawn(function()
              while ManipSettings.Enabled do
                  if #OrbitParts < 10 then -- Only deep-scan if we lost our swarm
                      RefreshManipParts()
                  end
                  task.wait(2)
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
   Name = "Vertical Height",
   Range = {-10, 20},
   Increment = 1,
   CurrentValue = 1,
   Callback = function(V) ManipSettings.Height = V end,
})

Tab:CreateSlider({
   Name = "Stability (Max Speed)",
   Range = {25, 250},
   Increment = 5,
   CurrentValue = 100,
   Callback = function(V) ManipSettings.MaxVelocity = V end,
})

Tab:CreateButton({
   Name = "Force Catch All Props",
   Callback = function() 
       RefreshManipParts()
       _G.EliteLog("Swarm Size: " .. #OrbitParts, "info")
   end,
})

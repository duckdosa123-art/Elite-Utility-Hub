-- PART CONTROL
Tab:CreateSection("KillBrick Manipulate")


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

-- Part.lua: Part Control Module (Swarm & Orbit)
local RunService = game:GetService("RunService")
local LP = _G.LP

-- Shared Configuration Variables
_G.ElitePartSpeed = 50
_G.ElitePartRange = 75
_G.EliteSwarmEnabled = false

-- Orbit Specific Variables
_G.EliteOrbitEnabled = false
_G.EliteOrbitRadius = 10
_G.EliteOrbitHeight = 2
_G.EliteOrbitSpeed = 3

-- UI Section: Configuration Sliders (Separated as requested)

Tab:CreateSection("Part Main")

Tab:CreateSlider({
    Name = "Part Speed",
    Range = {10, 250},
    Increment = 5,
    Suffix = "Studs/s",
    CurrentValue = 50,
    Callback = function(Value)
        _G.ElitePartSpeed = Value
    end,
})

Tab:CreateSlider({
    Name = "Part Control Range",
    Range = {20, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 75,
    Callback = function(Value)
        _G.ElitePartRange = Value
    end,
})

-- Feature 1: Universal Prop Swarm (Original Logic)
local SwarmToggle = Tab:CreateToggle({
    Name = "Elite Prop Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then
            _G.EliteOrbitEnabled = false -- Prevent conflict
            _G.EliteLog("Prop Swarm Activated", "Info")
            
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local Character = LP.Character
                    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
                    if HRP then
                        local targetPos = HRP.Position + Vector3.new(0, 5, 0)
                        for _, part in ipairs(workspace:GetDescendants()) do
                            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Character) then
                                local diff = targetPos - part.Position
                                local dist = diff.Magnitude
                                if dist <= _G.ElitePartRange then
                                    part.CanCollide = false -- Ghost Logic
                                    part.CanQuery = false
                                    part.AssemblyLinearVelocity = diff.Unit * math.min(dist * 15, _G.ElitePartSpeed)
                                    part.AssemblyAngularVelocity = Vector3.zero
                                end
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- Feature 2: Orbit Parts (New Feature)
Tab:CreateToggle({
    Name = "Elite Part Orbit",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteOrbitEnabled = Value
        if Value then
            _G.EliteSwarmEnabled = false -- Prevent conflict
            _G.EliteLog("Part Orbit Activated", "Info")
            
            task.spawn(function()
                local angle = 0
                while _G.EliteOrbitEnabled do
                    local Character = LP.Character
                    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
                    
                    if HRP then
                        -- Increment angle based on speed
                        angle = angle + (0.05 * _G.EliteOrbitSpeed)
                        
                        -- Calculate the target orbit point in the world
                        local offsetX = math.cos(angle) * _G.EliteOrbitRadius
                        local offsetZ = math.sin(angle) * _G.EliteOrbitRadius
                        local targetPos = HRP.Position + Vector3.new(offsetX, _G.EliteOrbitHeight, offsetZ)

                        for _, part in ipairs(workspace:GetDescendants()) do
                            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Character) then
                                local dist = (HRP.Position - part.Position).Magnitude
                                if dist <= _G.ElitePartRange then
                                    part.CanCollide = false -- Ghost Logic
                                    part.CanQuery = false
                                    
                                    local diff = targetPos - part.Position
                                    local moveDist = diff.Magnitude
                                    
                                    -- Physics-based orbit movement
                                    part.AssemblyLinearVelocity = diff.Unit * math.min(moveDist * 20, _G.ElitePartSpeed)
                                    part.AssemblyAngularVelocity = Vector3.new(0, 10, 0) -- Slight spin for "Elite" visual
                                end
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- Orbit Customization Sliders
Tab:CreateSlider({
    Name = "Orbit Radius",
    Range = {5, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 10,
    Callback = function(Value)
        _G.EliteOrbitRadius = Value
    end,
})

Tab:CreateSlider({
    Name = "Orbit Height",
    Range = {-10, 20},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 2,
    Callback = function(Value)
        _G.EliteOrbitHeight = Value
    end,
})

Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 3,
    Callback = function(Value)
        _G.EliteOrbitSpeed = Value
    end,
})

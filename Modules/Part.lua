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

Tab:CreateSection("PartManipulate")

-- Part.lua: Elite Part Control (Sticky Physics Edition)
local RunService = game:GetService("RunService")
local LP = _G.LP

-- Shared Configuration
_G.ElitePartSpeed = 100 -- Higher default for "Elite" feel
_G.ElitePartRange = 100
_G.EliteSwarmEnabled = false
_G.EliteOrbitEnabled = false

-- Orbit Specifics
_G.EliteOrbitRadius = 15
_G.EliteOrbitHeight = 4
_G.EliteOrbitSpeed = 3

-- Optimized "Sticky" Physics Core
local function ApplyElitePhysics(part, targetPos)
    local diff = targetPos - part.Position
    local dist = diff.Magnitude
    
    -- Ghost Logic: Anti-Lag, Anti-Camera, Anti-Damage
    part.CanCollide = false
    part.CanQuery = false 
    part.CanTouch = false
    
    -- Sticky Logic: The closer it is, the more it stabilizes. 
    -- The further it is, the faster it lunges.
    -- Multiplier of 25 ensures it fights gravity and stays in the air.
    local velMult = 25 
    part.AssemblyLinearVelocity = diff * velMult
    
    -- Anti-Void: If part is moving too slow vertically, boost it
    if part.AssemblyLinearVelocity.Y < 5 then
        part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + Vector3.new(0, 10, 0)
    end

    -- Stability
    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

-- Lag-Free Scanner
local function GetNearbyParts(hrp)
    local Params = OverlapParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LP.Character}
    
    local rawParts = workspace:GetPartBoundsInRadius(hrp.Position, _G.ElitePartRange, Params)
    local filtered = {}
    for _, p in ipairs(rawParts) do
        if p:IsA("BasePart") and not p.Anchored then
            local model = p:FindFirstAncestorOfClass("Model")
            if not (model and model:FindFirstChild("Humanoid")) then
                table.insert(filtered, p)
            end
        end
    end
    return filtered
end

-- UI
Tab:CreateSlider({
    Name = "Part Speed",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Force",
    CurrentValue = 100,
    Callback = function(Value) _G.ElitePartSpeed = Value end,
})

Tab:CreateSlider({
    Name = "Part Control Range",
    Range = {20, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 100,
    Callback = function(Value) _G.ElitePartRange = Value end,
})

-- FEATURE: SWARM
Tab:CreateToggle({
    Name = "Elite Prop Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then
            _G.EliteOrbitEnabled = false
            _G.EliteLog("Swarm: Sticky Mode Active", "Info")
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local parts = GetNearbyParts(hrp)
                        local target = hrp.Position + Vector3.new(0, 8, 0) -- Hover above head
                        for _, part in ipairs(parts) do
                            ApplyElitePhysics(part, target)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- FEATURE: ORBIT (Same "Sticky" logic as Swarm)
Tab:CreateToggle({
    Name = "Elite Part Orbit",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteOrbitEnabled = Value
        if Value then
            _G.EliteSwarmEnabled = false
            _G.EliteLog("Orbit: Sticky Mode Active", "Info")
            task.spawn(function()
                local angle = 0
                while _G.EliteOrbitEnabled do
                    angle = angle + (0.02 * _G.EliteOrbitSpeed)
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local parts = GetNearbyParts(hrp)
                        for i, part in ipairs(parts) do
                            -- Index-based distribution for clean circle
                            local pAngle = angle + (i * (math.pi * 2 / #parts))
                            local target = hrp.Position + Vector3.new(
                                math.cos(pAngle) * _G.EliteOrbitRadius,
                                _G.EliteOrbitHeight,
                                math.sin(pAngle) * _G.EliteOrbitRadius
                            )
                            ApplyElitePhysics(part, target)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- ORBIT CUSTOMIZATION
Tab:CreateSlider({
    Name = "Orbit Radius",
    Range = {5, 60},
    Increment = 2,
    Suffix = "Studs",
    CurrentValue = 15,
    Callback = function(Value) _G.EliteOrbitRadius = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Height",
    Range = {-10, 30},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 4,
    Callback = function(Value) _G.EliteOrbitHeight = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 3,
    Callback = function(Value) _G.EliteOrbitSpeed = Value end,
})

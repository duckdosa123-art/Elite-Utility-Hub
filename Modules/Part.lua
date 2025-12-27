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

-- Part.lua: Elite "Netless" Part Control
local RunService = game:GetService("RunService")
local LP = _G.LP

-- State Configuration
_G.ElitePartSpeed = 100
_G.ElitePartRange = 100
_G.EliteSwarmEnabled = false
_G.EliteOrbitEnabled = false

-- Orbit Customization
_G.EliteOrbitRadius = 15
_G.EliteOrbitHeight = 5
_G.EliteOrbitSpeed = 3

-- Core: Netless Claimer & Physics Stabilizer
-- This function mimics the logic found in top-tier part GUIs
local function ClaimAndMove(part, targetPos)
    if not part or not part.Parent then return end
    
    -- 1. Ghost Logic (Fixes Camera Zoom, Lag, and "Natural Disaster" Damage)
    part.CanCollide = false
    part.CanQuery = false -- Camera ignores these parts
    part.CanTouch = false -- Server won't register damage hits on you
    
    -- 2. Netless Ownership Hack
    -- Setting a constant slight upward velocity tricks the server into 
    -- giving your client physics authority (Network Ownership).
    local netlessVelocity = Vector3.new(0, 25.1, 0)
    
    -- 3. Proportional Force (Sticky Movement)
    -- We calculate the vector to the target and multiply it by a high-torque factor.
    local direction = targetPos - part.Position
    local distance = direction.Magnitude
    
    -- If the part is too far, we use "Snap" velocity to bring it back instantly
    -- If it's close, we use "Smooth" velocity to keep it sticky
    if distance > 2 then
        part.AssemblyLinearVelocity = (direction * 20) + netlessVelocity
    else
        -- High-frequency micro-adjustment to prevent "Falling into Void"
        part.AssemblyLinearVelocity = (direction * 45) + Vector3.new(0, 5, 0)
    end
    
    -- Prevent spinning/flinging
    part.AssemblyAngularVelocity = Vector3.zero
end

-- Optimization: Fast Spatial Scanner (Better than GetDescendants)
local function GetNearbyParts(hrp)
    local Params = OverlapParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LP.Character}
    
    -- Only scans physical objects in your immediate radius
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, _G.ElitePartRange, Params)
    local filtered = {}
    
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and not p.Anchored then
            -- Verify it's not another player's limb
            local model = p:FindFirstAncestorOfClass("Model")
            if not (model and model:FindFirstChild("Humanoid")) then
                table.insert(filtered, p)
            end
        end
    end
    return filtered
end

-- UI Controls
Tab:CreateSlider({
    Name = "Part Speed (Force)",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Pow",
    CurrentValue = 100,
    Callback = function(Value) _G.ElitePartSpeed = Value end,
})

Tab:CreateSlider({
    Name = "Part Control Range",
    Range = {25, 1000},
    Increment = 25,
    Suffix = "Studs",
    CurrentValue = 100,
    Callback = function(Value) _G.ElitePartRange = Value end,
})

-- Feature 1: Elite Prop Swarm
Tab:CreateToggle({
    Name = "Elite Prop Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then
            _G.EliteOrbitEnabled = false
            _G.EliteLog("Swarm: Netless Mode Engaged", "Info")
            
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local parts = GetNearbyParts(hrp)
                        -- Target: Spread slightly around a point above the player
                        local baseTarget = hrp.Position + Vector3.new(0, 10, 0)
                        
                        for i, part in ipairs(parts) do
                            -- Add a tiny bit of noise so they don't overlap (causes lag)
                            local noise = Vector3.new(math.sin(i), 0, math.cos(i)) * 2
                            ClaimAndMove(part, baseTarget + noise)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- Feature 2: Elite Part Orbit (The Fixed Version)
Tab:CreateToggle({
    Name = "Elite Part Orbit",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteOrbitEnabled = Value
        if Value then
            _G.EliteSwarmEnabled = false
            _G.EliteLog("Orbit: Netless Mode Engaged", "Info")
            
            task.spawn(function()
                local runtime = 0
                while _G.EliteOrbitEnabled do
                    runtime = runtime + (0.02 * _G.EliteOrbitSpeed)
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        local parts = GetNearbyParts(hrp)
                        local count = #parts
                        
                        for i, part in ipairs(parts) do
                            -- Math: Spread parts equally (360 degrees / part count)
                            local spacing = (math.pi * 2) / count
                            local angle = runtime + (i * spacing)
                            
                            local offset = Vector3.new(
                                math.cos(angle) * _G.EliteOrbitRadius,
                                _G.EliteOrbitHeight,
                                math.sin(angle) * _G.EliteOrbitRadius
                            )
                            
                            ClaimAndMove(part, hrp.Position + offset)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- Orbit Customization
Tab:CreateSlider({
    Name = "Orbit Radius",
    Range = {5, 100},
    Increment = 2,
    Suffix = "Studs",
    CurrentValue = 15,
    Callback = function(Value) _G.EliteOrbitRadius = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Height",
    Range = {-20, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 5,
    Callback = function(Value) _G.EliteOrbitHeight = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 3,
    Callback = function(Value) _G.EliteOrbitSpeed = Value end,
})

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

-- Part.lua: Optimized Part Control (Network Ownership Focus)
local RunService = game:GetService("RunService")
local LP = _G.LP

-- Shared Variables
_G.ElitePartSpeed = 50
_G.ElitePartRange = 75
_G.EliteSwarmEnabled = false
_G.EliteOrbitEnabled = false

-- Orbit Variables
_G.EliteOrbitRadius = 15
_G.EliteOrbitHeight = 3
_G.EliteOrbitSpeed = 2

-- Optimized Function to find and "Claim" parts
local function GetClaimedParts()
    local Character = LP.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return {} end

    local Params = OverlapParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {Character}

    -- GetPartBoundsInRadius is 100x faster than workspace:GetDescendants()
    local NearbyParts = workspace:GetPartBoundsInRadius(HRP.Position, _G.ElitePartRange, Params)
    local ValidParts = {}

    for _, part in ipairs(NearbyParts) do
        if part:IsA("BasePart") and not part.Anchored then
            -- Avoid player limbs (High performance check)
            if not part:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid") then
                table.insert(ValidParts, part)
                
                -- NETWORK OWNERSHIP CLAIM: 
                -- Setting these locally on unanchored parts forces the server 
                -- to hand physics control to YOU if no one else is closer.
                part.CanCollide = false
                part.CanQuery = false -- Camera won't hit them
                part.CanTouch = false -- Immune to "Natural Disaster" damage
                
                -- Stabilization
                if part.AssemblyAngularVelocity.Magnitude > 0 then
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
    return ValidParts, HRP
end

-- UI Setup
Tab:CreateSlider({
    Name = "Part Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = "Vel",
    CurrentValue = 50,
    Callback = function(Value) _G.ElitePartSpeed = Value end,
})

Tab:CreateSlider({
    Name = "Part Control Range",
    Range = {20, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 75,
    Callback = function(Value) _G.ElitePartRange = Value end,
})

-- FEATURE 1: SWARM
Tab:CreateToggle({
    Name = "Elite Prop Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then 
            _G.EliteOrbitEnabled = false 
            _G.EliteLog("Swarm Mode: Active", "Info")
            
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local parts, hrp = GetClaimedParts()
                    local targetPos = hrp.Position + Vector3.new(0, 7, 0)

                    for _, part in ipairs(parts) do
                        local diff = targetPos - part.Position
                        part.AssemblyLinearVelocity = diff.Unit * math.min(diff.Magnitude * 15, _G.ElitePartSpeed)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- FEATURE 2: ORBIT (Spread Out Logic)
Tab:CreateToggle({
    Name = "Elite Part Orbit",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteOrbitEnabled = Value
        if Value then 
            _G.EliteSwarmEnabled = false 
            _G.EliteLog("Orbit Mode: Active", "Info")
            
            task.spawn(function()
                local rot = 0
                while _G.EliteOrbitEnabled do
                    rot = rot + (0.02 * _G.EliteOrbitSpeed)
                    local parts, hrp = GetClaimedParts()
                    local total = #parts

                    for i, part in ipairs(parts) do
                        -- Mathematics for spreading parts evenly in a circle
                        local angle = rot + (i * (math.pi * 2 / total))
                        local targetPos = hrp.Position + Vector3.new(
                            math.cos(angle) * _G.EliteOrbitRadius,
                            _G.EliteOrbitHeight,
                            math.sin(angle) * _G.EliteOrbitRadius
                        )

                        local diff = targetPos - part.Position
                        part.AssemblyLinearVelocity = diff.Unit * math.min(diff.Magnitude * 20, _G.ElitePartSpeed)
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
    Range = {5, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 15,
    Callback = function(Value) _G.EliteOrbitRadius = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Height",
    Range = {-10, 20},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 3,
    Callback = function(Value) _G.EliteOrbitHeight = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Mult",
    CurrentValue = 2,
    Callback = function(Value) _G.EliteOrbitSpeed = Value end,
})

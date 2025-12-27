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

-- Part.lua: Elite Part Control (Anti-Void Edition)
local RunService = game:GetService("RunService")
local LP = _G.LP

-- State
_G.ElitePartSpeed = 100
_G.ElitePartRange = 150
_G.EliteSwarmEnabled = false
_G.EliteOrbitEnabled = false

-- Customization
_G.EliteOrbitRadius = 20
_G.EliteOrbitHeight = 5
_G.EliteOrbitSpeed = 4

-- The "Elite" Physics Engine
-- This function is the secret to stopping parts from falling into the void.
local function ForceMovePart(part, targetPos)
    if not part or not part.Parent then return end
    
    -- 1. GHOST LOGIC (Fixes Camera, Damage, and Player Physics)
    part.CanCollide = false
    part.CanTouch = false -- Fixes Natural Disaster Damage
    part.CanQuery = false -- Fixes Camera Zooming in/out
    
    -- 2. CALCULATION
    local currentPos = part.Position
    local direction = (targetPos - currentPos)
    local distance = direction.Magnitude
    
    -- 3. ANTI-GRAVITY VELOCITY
    -- We multiply distance by a high factor (35) and ADD a constant Y boost (25)
    -- This creates a "magnetic" pull that gravity cannot beat.
    local velocity = direction * 35 
    
    -- Apply the velocity directly to the Assembly
    part.AssemblyLinearVelocity = velocity + Vector3.new(0, 25, 0) 
    
    -- Stop it from spinning wildly (prevents flinging)
    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

-- Efficient Part Scanner
local function GetParts()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local found = {}
    -- We use a simple loop for reliability since "Lag Free" was a concern
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(char) then
            local dist = (v.Position - hrp.Position).Magnitude
            if dist <= _G.ElitePartRange then
                -- Ignore other players
                if not v:FindFirstAncestorOfClass("Model") or not v:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid") then
                    table.insert(found, v)
                end
            end
        end
    end
    return found, hrp
end

local function CleanupParts()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Scan one last time to reset everything in range
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored then
            local dist = (v.Position - hrp.Position).Magnitude
            if dist <= (_G.ElitePartRange + 50) then -- Slightly larger range for safety
                -- Reset Physics
                v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                v.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                -- Restore Collisions/Interaction
                v.CanCollide = true
                v.CanTouch = true
                v.CanQuery = true
            end
        end
    end
end

-- SWARM FEATURE (Fixed Disable)
Tab:CreateToggle({
    Name = "Elite Prop Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then
            _G.EliteOrbitEnabled = false
            _G.EliteLog("Swarm: Aggressive Physics Active", "Info")
            
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local parts, hrp = GetParts()
                    local target = hrp.Position + Vector3.new(0, 2, 0)
                    for _, part in ipairs(parts) do
                        ForceMovePart(part, target)
                    end
                    RunService.Heartbeat:Wait()
                end
                -- Cleanup when the 'while' loop breaks
                CleanupParts()
            end)
        else
            -- Ensure cleanup runs immediately on toggle off
            CleanupParts()
        end
    end,
})

-- ORBIT FEATURE (Fixed Disable)
Tab:CreateToggle({
    Name = "Elite Part Orbit",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteOrbitEnabled = Value
        if Value then
            _G.EliteSwarmEnabled = false
            _G.EliteLog("Orbit: Aggressive Physics Active", "Info")
            
            task.spawn(function()
                local angle = 0
                while _G.EliteOrbitEnabled do
                    angle = angle + (0.05 * _G.EliteOrbitSpeed)
                    local parts, hrp = GetParts()
                    local count = #parts
                    for i, part in ipairs(parts) do
                        local step = (math.pi * 2) / count
                        local pAngle = angle + (i * step)
                        local target = hrp.Position + Vector3.new(
                            math.cos(pAngle) * _G.EliteOrbitRadius,
                            _G.EliteOrbitHeight,
                            math.sin(pAngle) * _G.EliteOrbitRadius
                        )
                        ForceMovePart(part, target)
                    end
                    RunService.Heartbeat:Wait()
                end
                -- Cleanup when the 'while' loop breaks
                CleanupParts()
            end)
        else
            -- Ensure cleanup runs immediately on toggle off
            CleanupParts()
        end
    end,

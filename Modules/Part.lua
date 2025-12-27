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

Tab:CreateSection("Part Manipulate")

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
    local velocity = direction * (_G.ElitePartSpeed or 35) 
    
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
                   local targetHRP = _G.GetEliteTarget() or hrp -- Victim if targeted, else You
                    
                   if targetHRP and targetHRP.Parent then
                       -- No math needed, just a direct point on the victim
                       local target = targetHRP.Position + Vector3.new(0, 2, 0)
                        
                       for _, part in ipairs(parts) do
                           ForceMovePart(part, target)
                       end
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
                    local targetHRP = _G.GetEliteTarget() or hrp -- Victim if targeted, else You
                    
                    if targetHRP and targetHRP.Parent then
                        local count = #parts
                        for i, part in ipairs(parts) do
                            local step = (math.pi * 2) / count
                            local pAngle = angle + (i * step)
                            
                            -- THE MATH: Centered on targetHRP.Position instead of hrp.Position
                            local target = targetHRP.Position + Vector3.new(
                                math.cos(pAngle) * _G.EliteOrbitRadius,
                                _G.EliteOrbitHeight,
                                math.sin(pAngle) * _G.EliteOrbitRadius
                            )
                            
                            ForceMovePart(part, target)
                        end
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

-- Section: Customize Parts
Tab:CreateSection("Customize Control")

Tab:CreateSlider({
    Name = "Part Control Range",
    Range = {50, 2000},
    Increment = 50,
    Suffix = "Studs",
    CurrentValue = 150,
    Callback = function(Value)
        _G.ElitePartRange = Value
    end,
})

Tab:CreateSlider({
    Name = "Part Move Force (Speed)",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Power",
    CurrentValue = 35,
    Callback = function(Value)
        -- This directly controls the '35' multiplier in your ForceMovePart logic
        _G.ElitePartSpeed = Value
    end,
})

Tab:CreateSlider({
    Name = "Orbit Radius",
    Range = {5, 150},
    Increment = 5,
    Suffix = "Studs",
    CurrentValue = 20,
    Callback = function(Value)
        _G.EliteOrbitRadius = Value
    end,
})

Tab:CreateSlider({
    Name = "Orbit Height",
    Range = {-20, 100},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 5,
    Callback = function(Value)
        _G.EliteOrbitHeight = Value
    end,
})

Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 50},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 4,
    Callback = function(Value)
        _G.EliteOrbitSpeed = Value
    end,
})

-- Section: Elite Shapes (Ultra-Detail & Auto-Sizer Edition)
Tab:CreateSection("Elite Shapes")

_G.EliteShapeEnabled = false
_G.EliteCurrentShape = "Halo"

Tab:CreateDropdown({
    Name = "Select Elite Shape",
    Options = {"Halo", "Wings", "Shield", "Cross"},
    CurrentOption = {"Halo"},
    MultipleOptions = false,
    Callback = function(Option)
        _G.EliteCurrentShape = Option[1]
        _G.EliteLog("Shape Set: " .. Option[1], "Info")
    end,
})

Tab:CreateToggle({
    Name = "Elite Shapes: ENABLED",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteShapeEnabled = Value
        if Value then
            _G.EliteSwarmEnabled = false
            _G.EliteOrbitEnabled = false
            
            task.spawn(function()
                while _G.EliteShapeEnabled do
                    local parts, myHrp = GetParts()
                    local targetHRP = _G.GetEliteTarget() or myHrp
                    
                    if targetHRP and targetHRP.Parent and #parts > 0 then
                        local tCF = targetHRP.CFrame
                        local count = #parts
                        
                        -- Sort parts by size to put bigger parts in the back/base
                        table.sort(parts, function(a, b) 
                            return a.Size.Magnitude > b.Size.Magnitude 
                        end)

                        for i, part in ipairs(parts) do
                            local finalTarget = tCF.Position
                            
                            -- AUTO-SIZER LOGIC: Prevents big parts from clumping
                            -- We calculate a "Comfort Zone" based on the part's size
                            local pSize = part.Size.Magnitude
                            local spacing = math.clamp(pSize * 0.4, 1.5, 10)

                            if _G.EliteCurrentShape == "Halo" then
                                -- DOUBLE-RING NEON HALO
                                local ring = (i % 2 == 0) and 1 or 1.5
                                local angle = (i * (math.pi * 2 / count)) + (tick() * 3)
                                local radius = (4 + (spacing * 0.5)) * ring
                                finalTarget = (tCF * CFrame.new(math.cos(angle) * radius, 5 + (ring), math.sin(angle) * radius)).Position
                                
                            elseif _G.EliteCurrentShape == "Wings" then
                                -- THE MOST DETAILED WINGS (Triple-Layered Angelic)
                                local side = (i % 2 == 0) and 1 or -1
                                local halfIndex = math.floor(i / 2)
                                local layer = i % 3 -- 0: Primary, 1: Secondary, 2: Covert
                                
                                -- Spread math using Golden Ratio principles
                                local spread = (halfIndex * spacing * 0.6)
                                local curve = math.sin(halfIndex * 0.3) * 3
                                local height = math.cos(halfIndex * 0.2) * 5
                                
                                -- Flap physics (Speed increases at wing tips)
                                local flapSpeed = 4
                                local flapPower = (halfIndex * 0.5) + 1
                                local flap = math.sin(tick() * flapSpeed) * flapPower
                                
                                -- Layered Offset (Makes wings look "Thick" and 3D)
                                local depth = 1.5 + (layer * 0.8) + (side * flap)
                                
                                finalTarget = (tCF * CFrame.new(
                                    side * (2 + spread), -- How wide
                                    height + (layer * 1.5), -- How tall
                                    depth -- Flap depth
                                )).Position
                                
                            elseif _G.EliteCurrentShape == "Shield" then
                                -- HEX-DOME SHIELD (Auto-Adjusts for Wall pieces)
                                local rows = math.ceil(math.sqrt(count))
                                local r = i % rows
                                local c = math.floor(i / rows)
                                
                                finalTarget = (tCF * CFrame.new(
                                    (r - rows/2) * (spacing * 1.2),
                                    (c - rows/2) * (spacing * 1.2),
                                    -5 - (spacing * 0.5) -- Pushes shield further out if parts are huge
                                )).Position
                                
                            elseif _G.EliteCurrentShape == "Cross" then
                                -- JESUS CROSS (3D Thickened Latin Cross)
                                local verticalLimit = math.floor(count * 0.7)
                                if i <= verticalLimit then
                                    -- Vertical Post
                                    local p = (i * spacing * 0.8) - (verticalLimit * 0.3)
                                    finalTarget = (tCF * CFrame.new(0, p, 3)).Position
                                else
                                    -- Horizontal Crossbar (Positioned 75% up)
                                    local barIndex = i - verticalLimit
                                    local p = (barIndex * spacing * 0.8) - ((count - verticalLimit) * 0.4)
                                    finalTarget = (tCF * CFrame.new(p, verticalLimit * 0.4, 3)).Position
                                end
                            end
                            
                            ForceMovePart(part, finalTarget)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
                CleanupParts()
            end)
        else
            CleanupParts()
        end
    end,
})
-- Section: Elite Assassination
Tab:CreateSection("Elite Assassination")

_G.EliteTargetEnabled = false
_G.EliteTargetName = "" -- This will store the actual Username for physics logic

local PlayerDropdown = Tab:CreateDropdown({
    Name = "Select Victim",
    Options = {"Click Refresh..."},
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "VictimDropdown",
    Callback = function(Option)
        -- Option[1] will look like "DisplayName (@Username)"
        -- We extract the part inside the @ parentheses
        local chosen = Option[1]
        local username = chosen:match("@(%w+)")
        if username then
            _G.EliteTargetName = username
            _G.EliteLog("Victim Set To: " .. username, "Info")
        end
    end,
})

-- Optimized Refresh Function
local function RefreshPlayers()
    local pList = {}
    local Players = game:GetService("Players"):GetPlayers()
    
    for _, v in ipairs(Players) do
        if v ~= LP then
            -- Format: "Display Name (@Username)"
            local entry = v.DisplayName .. " (@" .. v.Name .. ")"
            table.insert(pList, entry)
        end
    end
    
    -- Rayfield Refresh Logic
    PlayerDropdown:Refresh(pList, true) 
    _G.EliteLog("Player List Refreshed", "Info")
end

Tab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        RefreshPlayers()
    end,
})

Tab:CreateToggle({
    Name = "Target: ENABLED",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteTargetEnabled = Value
        if Value then
            if _G.EliteTargetName == "" then
                _G.EliteLog("Please select a victim from the list!", "Error")
            else
                _G.EliteLog("Locking on: " .. _G.EliteTargetName, "Info")
            end
        else
            _G.EliteLog("Targeting Disabled", "Info")
        end
    end,
})

-- Logic to find the target's RootPart (Used by Swarm/Orbit)
_G.GetEliteTarget = function()
    if not _G.EliteTargetEnabled or _G.EliteTargetName == "" then return nil end
    local targetPlayer = game:GetService("Players"):FindFirstChild(_G.EliteTargetName)
    if targetPlayer and targetPlayer.Character then
        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = targetPlayer.Character:FindFirstChild("Humanoid")
        -- Only target if they are alive
        if hrp and hum and hum.Health > 0 then
            return hrp
        end
    end
    return nil
end

-- Force an initial refresh after a tiny delay to ensure UI is ready
task.delay(1, function()
    RefreshPlayers()
end)

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

-- Part.lua: Elite Prop Swarm Logic
local RunService = game:GetService("RunService")
local LP = _G.LP

-- Configuration Variables
_G.EliteSwarmEnabled = false
_G.EliteSwarmPower = 50 -- Max Velocity Cap
_G.EliteSwarmRadius = 100 -- Maximum distance to pull parts from

Tab:CreateToggle({
    Name = "Elite Swarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.EliteSwarmEnabled = Value
        if Value then
            _G.EliteLog("Prop Swarm Activated", "Info")
            
            task.spawn(function()
                while _G.EliteSwarmEnabled do
                    local Character = LP.Character
                    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
                    local Humanoid = Character and Character:FindFirstChild("Humanoid")

                    -- Safety: Nil-check character state
                    if HRP and Humanoid and Humanoid.Health > 0 then
                        -- Target position: slightly above the player's head for better visuals
                        local targetPos = HRP.Position + Vector3.new(0, 5, 0)

                        for _, part in ipairs(workspace:GetDescendants()) do
                            -- Mobile-Safe Filters: Must be a part, unanchored, and not part of any character
                            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Character) then
                                if not part:FindFirstAncestorOfClass("Model") or not part:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid") then
                                    
                                    local diff = targetPos - part.Position
                                    local dist = diff.Magnitude

                                    if dist <= _G.EliteSwarmRadius then
                                        -- Ghost Logic: Prevent local lag/camera stutter
                                        part.CanCollide = false
                                        part.CanQuery = false

                                        -- Capped Proportional Velocity: Sticky movement (math.min(dist * 15, Max))
                                        -- AssemblyLinearVelocity is FE-compatible for unanchored parts you have network ownership of
                                        local calcVelocity = diff.Unit * math.min(dist * 15, _G.EliteSwarmPower)
                                        part.AssemblyLinearVelocity = calcVelocity
                                        
                                        -- Stabilization: Stop parts from spinning wildly
                                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                    end
                                end
                            end
                        end
                    end
                    -- Performance: Use Heartbeat for physics-synced updates
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            _G.EliteLog("Swarm Deactivated", "Info")
        end
    end,
})

Tab:CreateSlider({
    Name = "Swarm Power",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Studs/s",
    CurrentValue = 50,
    Callback = function(Value)
        _G.EliteSwarmPower = Value
    end,
})

Tab:CreateSlider({
    Name = "Swarm Range",
    Range = {20, 300},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 75,
    Callback = function(Value)
        _G.EliteSwarmRadius = Value
    end,
})

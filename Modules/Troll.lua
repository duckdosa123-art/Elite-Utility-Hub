--==========================================================- Elite Help Section (COMPLETE & FIXED) -==========================================================================

-- [[ ELITE FLYING BRIDGE ENGINE ]]
_G.EliteFlySpeed = 10 -- Default Elite Speed
local FlyingBridgeActive = false
local bridge_bv = nil
local bridge_bg = nil
local original_joints = {}
local wasFlying = false

-- Function to lock limbs and fix First-Person Camera
local function SetBridgePose(active)
    local Char = LP.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if not Char or not Hum then return end

    if active then
        -- FIX: Disable AutoRotate to stop the First-Person spinning/shaking
        Hum.AutoRotate = false 
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("Motor6D") then
                original_joints[v] = v.C0
                if v.Name:find("Shoulder") or v.Name:find("Arm") then
                    v.C0 = v.C0 * CFrame.Angles(math.rad(90), 0, 0)
                elseif v.Name:find("Hip") or v.Name:find("Leg") then
                    v.C0 = v.C0 * CFrame.Angles(math.rad(-90), 0, 0)
                end
            end
        end
        Hum.PlatformStand = true
    else
        Hum.AutoRotate = true 
        for joint, c0 in pairs(original_joints) do
            if joint and joint.Parent then joint.C0 = c0 end
        end
        original_joints = {}
        Hum.PlatformStand = false
        Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

-- Main Physics Loop (Fly + Integrated Noclip)
task.spawn(function()
    game:GetService("RunService").RenderStepped:Connect(function()
        local Char = LP.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        local Cam = workspace.CurrentCamera
        local UIS = game:GetService("UserInputService")
        
        local speed = _G.EliteFlySpeed or 10

        if FlyingBridgeActive and Root and Hum and Cam then
            wasFlying = true -- Mark that we are currently using physics overrides
            if not bridge_bv then
                bridge_bv = Instance.new("BodyVelocity")
                bridge_bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
                bridge_bv.Parent = Root
            end
            if not bridge_bg then
                bridge_bg = Instance.new("BodyGyro")
                bridge_bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
                bridge_bg.P = 25000 
                bridge_bg.D = 500
                bridge_bg.Parent = Root
            end

            for _, part in pairs(Char:GetDescendants()) do
                if part:IsA("BasePart") then 
                    part.CanCollide = false 
                end
            end

            local moveDir = Hum.MoveDirection 
            local up = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
            local down = (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.ButtonL2)) and 1 or 0
            local vertical = Vector3.new(0, (up - down) * speed, 0)
            
            if moveDir.Magnitude > 0 or up ~= 0 or down ~= 0 then
                local worldMove = Cam.CFrame:VectorToWorldSpace(Cam.CFrame:VectorToObjectSpace(moveDir * speed))
                bridge_bv.Velocity = worldMove + vertical
            else
                bridge_bv.Velocity = Vector3.zero
            end

            local _, yRotation, _ = Cam.CFrame:ToEulerAnglesYXZ()
            bridge_bg.CFrame = CFrame.Angles(0, yRotation, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        else
            -- CLEANUP SECTION
            if bridge_bv then bridge_bv:Destroy() bridge_bv = nil end
            if bridge_bg then bridge_bg:Destroy() bridge_bg = nil end
            
            -- FIX: Only restore collisions ONCE when the feature is turned off
            if wasFlying then
                wasFlying = false -- Reset the gate
                if not _nc and Char then
                    for _, p in pairs(Char:GetDescendants()) do
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then 
                            -- We exclude HumanoidRootPart because it should usually stay non-collidable
                            -- and we don't spam this every frame anymore.
                            p.CanCollide = true 
                        end
                    end
                end
            end
        end
    end)
end)

local PassengerMagnetActive = false
local MagnetPlate = nil
local passengerOffsets = {} 

local function TogglePassengerMagnet(Value)
    PassengerMagnetActive = Value
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    
    if Value and Root then
        if MagnetPlate then MagnetPlate:Destroy() end 
        MagnetPlate = Instance.new("Part")
        MagnetPlate.Name = "EliteJitterZone"
        MagnetPlate.Transparency = 1 
        MagnetPlate.Size = Vector3.new(20, 10, 20)
        MagnetPlate.CanCollide = false 
        MagnetPlate.Massless = true
        MagnetPlate.Parent = Char
        
        local Weld = Instance.new("Weld")
        Weld.Part0 = Root
        Weld.Part1 = MagnetPlate
        Weld.C1 = CFrame.new(0, -2.5, 0) -- Positioned to catch all rig sizes
        Weld.Parent = MagnetPlate
        
        _G.EliteLog("Magnet: Physics Hijack Engaged", "success")
    else
        passengerOffsets = {}
        if MagnetPlate then MagnetPlate:Destroy() MagnetPlate = nil end
    end
end

-- [[ ELITE GOD-SYNC ENGINE - V7 JITTER-GLUE ]]
task.spawn(function()
    game:GetService("RunService").Heartbeat:Connect(function()
        if not PassengerMagnetActive or not MagnetPlate or not LP.Character then return end
        
        local MyChar = LP.Character
        local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
        local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
        if not MyRoot or not MyHum then return end

        -- IMMEDIATE TRIGGER: Check if we are moving
        local isMoving = MyHum.MoveDirection.Magnitude > 0
        local myVel = MyRoot.AssemblyLinearVelocity

        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                
                if pRoot and pHum then
                    local relPos = MagnetPlate.CFrame:PointToObjectSpace(pRoot.Position)
                    
                    -- Capture: 9 studs | Stay: 16 studs
                    if math.abs(relPos.X) < 9 and math.abs(relPos.Z) < 9 and math.abs(relPos.Y) < 6 or passengerOffsets[p.UserId] then
                        
                        -- 1. THE GLUE LOCK
                        if not passengerOffsets[p.UserId] then
                            passengerOffsets[p.UserId] = relPos
                        end

                        -- 2. THE JITTER (Physics Hijack)
                        -- Tiny, high-frequency vibration keeps their physics engine "awake"
                        local jitter = Vector3.new(
                            math.random(-100, 100)/2000, 
                            0.01, -- Slight upward lift to break friction
                            math.random(-100, 100)/2000
                        )

                        -- 3. THE INSTANT PULL
                        local targetWorldPos = MagnetPlate.CFrame:PointToWorldSpace(passengerOffsets[p.UserId])
                        local diff = (targetWorldPos - pRoot.Position)
                        
                        -- If we are moving, we apply a massive "Boost" to kill the delay
                        local movementBoost = isMoving and (MyHum.MoveDirection * 5) or Vector3.zero
                        local pullForce = diff * 50

                        -- 4. APPLY THE HIJACKED VELOCITY
                        -- Combined: Your Real Velocity + The Glue Pull + Jitter + Instant Move Boost
                        pRoot.AssemblyLinearVelocity = myVel + pullForce + jitter + movementBoost
                        pRoot.AssemblyAngularVelocity = MyRoot.AssemblyAngularVelocity

                        -- 5. THE ESCAPE-PROOF STATE
                        -- Force "Physics" state so their movement keys are ignored
                        if pHum:GetState() ~= Enum.HumanoidStateType.Physics then
                            pHum:ChangeState(Enum.HumanoidStateType.Physics)
                        end
                        
                        -- Infinite friction so they don't slide
                        pRoot.CustomPhysicalProperties = PhysicalProperties.new(100, 20, 0, 100, 100)
                        
                        -- 6. BREAK-OUT CHECK
                        if diff.Magnitude > 15 then -- If they get too far (lag), reset lock
                            passengerOffsets[p.UserId] = nil 
                        end
                    end
                end
            end
        end
    end)
end)
local TweenService = game:GetService("TweenService")
local function EliteVerticalTween(amount)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    local targetCF = Root.CFrame + Vector3.new(0, amount, 0)
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Linear)
    TweenService:Create(Root, info, {CFrame = targetCF}):Play()
end
-- UI INTEGRATION
Tab:CreateSection("Helpful Features")
Tab:CreateParagraph({
    Title = "⚠️ Note",
    Content = "The Flying Bridge only works if the game has 'Player Collisions' ENABLED!"
})
-- NoClip (from Movement.lua)
task.spawn(function()
    RunService.Stepped:Connect(function()
        if _nc then
            local c = LP.Character
            if c then
                for _, part in pairs(c:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

Tab:CreateToggle({
   Name = "Elite Flying Bridge",
   CurrentValue = false,
   Flag = "EliteFlyingBridge_Combined",
   Callback = function(Value)
      -- 1. STATE SYNC
      FlyingBridgeActive = Value
      
      local Char = LP.Character
      local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
      local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
      
      -- 2. PHYSICS PRE-SETTLE
      -- Clears any existing forces before the engines take over to prevent "launching"
      if HRP then
          HRP.AssemblyLinearVelocity = Vector3.zero
          HRP.AssemblyAngularVelocity = Vector3.zero
      end

      -- 3. ENGINE TRIGGER (Both Fly Bridge and Magnet)
      SetBridgePose(Value)          -- Triggers the Plank Pose & Collision Logic
      TogglePassengerMagnet(Value)   -- Triggers the God-Tier Projection Engine

      -- 4. STABILITY & LOGGING
      if Value then
          _G.EliteLog("Elite Flying Bridge: Fully Engaged", "success")
          -- Force state reset to ensure you don't trip during transition
          if Hum then
              task.wait(0.05)
              Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
          end
      else
          _G.EliteLog("Elite Flying Bridge: Disengaged", "info")
          if Hum then
              Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
          end
      end
   end,
})
Tab:CreateSlider({
   Name = "Bridge Flying Speed",
   Range = {0, 30},
   Increment = 1,
   Suffix = "SPS",
   CurrentValue = 10,
   Flag = "BridgeSpeed_Slider",
   Callback = function(Value)
      _G.EliteFlySpeed = Value -- Only update the global speed variable
      if Value > 25 then
          _G.EliteLog("Speed set to High-Velocity: " .. Value, "warn")
      end
   end,
})

Tab:CreateSection("Position The Bridge")

Tab:CreateButton({
   Name = "UP (one stud)",
   Callback = function()
       EliteVerticalTween(1)
       _G.EliteLog("Position: +1 Stud World-UP", "info")
   end,
})

Tab:CreateButton({
   Name = "DOWN (one stud)",
   Callback = function()
       EliteVerticalTween(-1)
       _G.EliteLog("Position: -1 Stud World-DOWN", "info")
   end,
})

local MoveUpActive = false
Tab:CreateToggle({
   Name = "Continuous UP",
   CurrentValue = false,
   Flag = "ContUp",
   Callback = function(Value)
      MoveUpActive = Value
      task.spawn(function()
          while MoveUpActive do
              local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
              if Root then
                  -- Adds to the Y axis every frame for smooth vertical rise
                  Root.CFrame = Root.CFrame + Vector3.new(0, 0.2, 0)
              end
              _G.RunService.Heartbeat:Wait()
          end
      end)
   end,
})

local MoveDownActive = false
Tab:CreateToggle({
   Name = "Continuous DOWN",
   CurrentValue = false,
   Flag = "ContDown",
   Callback = function(Value)
      MoveDownActive = Value
      task.spawn(function()
          while MoveDownActive do
              local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
              if Root then
                  -- Subtracts from the Y axis every frame for smooth descent
                  Root.CFrame = Root.CFrame + Vector3.new(0, -0.2, 0)
              end
              _G.RunService.Heartbeat:Wait()
          end
      end)
   end,
})
--=========================================================- Elite Troll Section –==========================================================================

-- Elite Troll Engine (Updated for Customization)
local TrollEngine = {
    Target = nil,
    Connections = {},
    -- Feature States
    OrbitActive = false,
    MimicActive = false,
    GlitchActive = false,
    HeadSitActive = false,
    LagFakeActive = false,
    -- Customization Values
    OrbitSpeed = 5,
    OrbitDistance = 5,
    OrbitHeight = 0,
    MimicDistance = 0,
    LagIntensity = 0.2, -- Delay in seconds
    LagFloat = 0, -- Upward offset during freeze
    OriginalJoints = {}, -- For Glitcher restoration
    VoidPart = nil
}


-- 1. UTILITY: Troll-Specific Player Search
local function GetTrollPlayerList()
    local list = {}
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP then table.insert(list, v.DisplayName) end
    end
    return list
end

local function GetTrollTarget(name)
    if not name then return nil end
    name = name:lower()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LP and (v.DisplayName:lower():find(name) or v.Name:lower():find(name)) then
            return v
        end
    end
    return nil
end

-- Troll Engine State Update
TrollEngine.PlatformTransparency = 0.8
TrollEngine.VoidPart = nil

-- 1. Helper: Platform & Godmode Controller
local function ManageTrollPlatform(State)
    if State then
        if not TrollEngine.VoidPart then
            TrollEngine.VoidPart = Instance.new("Part")
            TrollEngine.VoidPart.Name = "Elite_SafetyAnchor"
            TrollEngine.VoidPart.Size = Vector3.new(15, 1, 15) -- Large enough to catch you
            TrollEngine.VoidPart.Anchored = true
            TrollEngine.VoidPart.CanCollide = true
            TrollEngine.VoidPart.Material = Enum.Material.ForceField
            TrollEngine.VoidPart.Transparency = TrollEngine.PlatformTransparency
            TrollEngine.VoidPart.Parent = workspace
        end
    else
        if not TrollEngine.OrbitActive and not TrollEngine.MimicActive then
            if TrollEngine.VoidPart then 
                TrollEngine.VoidPart:Destroy() 
                TrollEngine.VoidPart = nil 
            end
        end
    end
end

-- Fall Damage & Health Lock (Godmode)
RunService.Heartbeat:Connect(function()
    if (TrollEngine.OrbitActive or TrollEngine.MimicActive) and LP.Character then
        local Hum = LP.Character:FindFirstChild("Humanoid")
        if Hum then
            Hum.Health = Hum.MaxHealth -- Lock Health
            -- Force State to Landed if falling to prevent fall damage scripts from triggering
            if Hum:GetState() == Enum.HumanoidStateType.Freefall then
                Hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
        end
    end
end)

-- 2. THE UI SECTION (Dedicated List & Search)
Tab:CreateSection("Elite Fun/Target")

local TrollDropdown = Tab:CreateDropdown({
    Name = "Target:",
    Options = GetTrollPlayerList(),
    CurrentOption = {""},
    Callback = function(Option)
        TrollEngine.Target = GetTrollTarget(Option[1])
    end,
})

Tab:CreateInput({
    Name = "Search Target",
    PlaceholderText = "Type name...",
    Callback = function(Text)
        local found = GetTrollTarget(Text)
        if found then
            TrollEngine.Target = found
            TrollDropdown:Set({found.DisplayName})
        end
    end,
})

Tab:CreateButton({
    Name = "Refresh List",
    Callback = function()
        TrollDropdown:Refresh(GetTrollPlayerList())
    end,
})

-- 3. ELITE FEATURES
Tab:CreateSection("Fun Features")

-- 1. ELITE ORBIT (Fixed Rotation & Safety)
Tab:CreateToggle({
    Name = "Elite Orbit",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.OrbitActive = Value
        ManageTrollPlatform(Value)
        local angle = 0
        
        task.spawn(function()
            while TrollEngine.OrbitActive do
                -- Crash-Proofing: Check if target still exists
                if not TrollEngine.Target or not TrollEngine.Target.Parent or not TrollEngine.Target.Character then
                    TrollEngine.OrbitActive = false
                    Rayfield:Notify({Title = "Orbit Stopped", Content = "Target left the server.", Duration = 3})
                    break
                end

                local char = LP.Character
                local HRP = char and char:FindFirstChild("HumanoidRootPart")
                local THRP = TrollEngine.Target.Character:FindFirstChild("HumanoidRootPart")

                if HRP and THRP then
                    angle = angle + (TrollEngine.OrbitSpeed or 2)
                    
                    -- FIX: Use CFrame.new(THRP.Position) so target turning doesn't affect orbit path
                    local centerPoint = CFrame.new(THRP.Position)
                    local orbitOffset = CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, TrollEngine.OrbitHeight or 0, TrollEngine.OrbitDistance or 5)
                    
                    -- Physics: Zero out velocity to prevent "flinging" or falling through floor on exit
                    HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    HRP.CFrame = centerPoint * orbitOffset
                    
                    -- Safety Platform: Follows exactly under the player
                    if TrollEngine.VoidPart then
                        TrollEngine.VoidPart.CFrame = HRP.CFrame * CFrame.new(0, -3.5, 0)
                    end
                end
                RunService.Heartbeat:Wait()
            end
            
            -- Exit Logic: Stop the character from falling into the void when orbit ends
            local char = LP.Character
            local HRP = char and char:FindFirstChild("HumanoidRootPart")
            if HRP then
                HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            ManageTrollPlatform(false)
        end)
    end,
})
Tab:CreateSlider({
    Name = "Orbit Speed",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value) TrollEngine.OrbitSpeed = Value end,
})

Tab:CreateSlider({
    Name = "Orbit Distance",
    Range = {2, 50},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value) TrollEngine.OrbitDistance = Value end,
})

-- 2. ELITE MIMIC (Void Safe)
-- 2. ELITE MIMIC (R6 Emote & Joint Sync)
TrollEngine.MimicTracks = {}

Tab:CreateToggle({
    Name = "Elite Mimic",
    CurrentValue = false,
    Flag = "EliteMimic_Toggle",
    Callback = function(Value)
        TrollEngine.MimicActive = Value
        ManageTrollPlatform(Value)
        
        local Char = LP.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        local MyAnimator = Hum and Hum:FindFirstChildOfClass("Animator")
        
        if Value and HRP and Hum then
            -- 1. SETUP: Physics & State
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then v.Massless = true end
            end
            
            Hum.PlatformStand = true
            Hum.AutoRotate = false

            -- 2. NOCLIP & JOINT SYNC (Stepped is best for Motor6Ds)
            local mimicConnection = RunService.Stepped:Connect(function()
                if not TrollEngine.MimicActive or not Char or not TrollEngine.Target then return end
                
                local TargetChar = TrollEngine.Target.Character
                if not TargetChar then return end

                -- Noclip
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                
                -- ELITE R6 SYNC: Copy Joint Rotations (The "Emote" logic)
                for _, motor in pairs(Char:GetDescendants()) do
                    if motor:IsA("Motor6D") then
                        local targetMotor = TargetChar:FindFirstChild(motor.Name, true)
                        if targetMotor and targetMotor:IsA("Motor6D") then
                            -- This forces your joints to match their emote pose exactly
                            motor.Transform = targetMotor.Transform
                        end
                    end
                end
            end)
            table.insert(TrollEngine.Connections, mimicConnection)

            task.spawn(function()
                while TrollEngine.MimicActive do
                    if not TrollEngine.Target or not TrollEngine.Target.Parent or not TrollEngine.Target.Character then
                        TrollEngine.MimicActive = false
                        Rayfield:Notify({Title = "Mimic Stopped", Content = "Target left the server.", Duration = 3})
                        break
                    end
                    local TargetChar = TrollEngine.Target and TrollEngine.Target.Character
                    local THum = TargetChar and TargetChar:FindFirstChildOfClass("Humanoid")
                    local THRP = TargetChar and TargetChar:FindFirstChild("HumanoidRootPart")
                    
                    if HRP and THRP and Hum and THum then
                        -- 3. POSITIONING
                        HRP.AssemblyLinearVelocity = Vector3.zero -- Prevents falling through floor
                        
                        if TrollEngine.MimicDistance == 0 then
                            HRP.CFrame = THRP.CFrame
                            Hum:ChangeState(Enum.HumanoidStateType.Physics)
                        else
                            local offsetPos = (THRP.CFrame * CFrame.new(0, 0, TrollEngine.MimicDistance)).Position
                            HRP.CFrame = CFrame.lookAt(offsetPos, THRP.Position)
                        end
                        
                        -- 4. SAFETY PLATFORM
                        if TrollEngine.VoidPart then
                            TrollEngine.VoidPart.CFrame = HRP.CFrame * CFrame.new(0, -3.5, 0)
                        end

                        -- 5. ANIMATION TRACK SYNC
                        local TAnimator = THum:FindFirstChildOfClass("Animator")
                        if TAnimator and MyAnimator then
                            local PlayingTracks = TAnimator:GetPlayingAnimationTracks()
                            for _, TTrack in pairs(PlayingTracks) do
                                local AnimID = TTrack.Animation.AnimationId
                                if not TrollEngine.MimicTracks[AnimID] then
                                    local NewAnim = Instance.new("Animation")
                                    NewAnim.AnimationId = AnimID
                                    local MyTrack = MyAnimator:LoadAnimation(NewAnim)
                                    MyTrack:Play()
                                    TrollEngine.MimicTracks[AnimID] = MyTrack
                                end
                                local MyTrack = TrollEngine.MimicTracks[AnimID]
                                MyTrack.TimePosition = TTrack.TimePosition
                                MyTrack:AdjustSpeed(TTrack.Speed)
                                MyTrack:AdjustWeight(TTrack.WeightCurrent)
                            end
                            -- Stop tracks the target stopped
                            for ID, MyTrack in pairs(TrollEngine.MimicTracks) do
                                local stillPlaying = false
                                for _, TTrack in pairs(PlayingTracks) do
                                    if TTrack.Animation.AnimationId == ID then stillPlaying = true break end
                                end
                                if not stillPlaying then 
                                    MyTrack:Stop() 
                                    TrollEngine.MimicTracks[ID] = nil 
                                end
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            -- CLEANUP
            TrollEngine.MimicActive = false
            for _, conn in pairs(TrollEngine.Connections) do pcall(function() conn:Disconnect() end) end
            TrollEngine.Connections = {}

            if Char then
                for _, v in pairs(Char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true v.Massless = false end
                end
            end
            
            if Hum then 
                Hum.PlatformStand = false
                Hum.AutoRotate = true
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
            end
            if HRP then HRP.AssemblyLinearVelocity = Vector3.zero end

            for _, Track in pairs(TrollEngine.MimicTracks) do pcall(function() Track:Stop() end) end
            TrollEngine.MimicTracks = {}
        end
    end,
})
Tab:CreateSlider({
    Name = "Mimic Distance Offset",
    Range = {-20, 20},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(Value) TrollEngine.MimicDistance = Value end,
})

-- Elite Head-Sitter State (Fixed Noclip Stick & Brute Force Reset)
TrollEngine.HeadSitJoints = {}

Tab:CreateToggle({
    Name = "Elite Head-Sitter",
    CurrentValue = false,
    Flag = "HeadSitter_Toggle",
    Callback = function(Value)
        TrollEngine.HeadSitActive = Value
        local Char = LP.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")
        
        if not HRP or not Hum then return end

        -- Helper: Find Nearest Ground (Safe Land)
        local function GetNearestGround()
            local rayParam = RaycastParams.new()
            rayParam.FilterDescendantsInstances = {Char, TrollEngine.Target and TrollEngine.Target.Character or Char}
            rayParam.FilterType = Enum.RaycastFilterType.Exclude
            
            local ray = workspace:Raycast(HRP.Position, Vector3.new(0, -500, 0), rayParam)
            if ray then return ray.Position + Vector3.new(0, 3, 0) end
            return HRP.Position + Vector3.new(0, 5, 0)
        end

        if Value then
            -- 1. SETUP: Massless & Joint Cache
            TrollEngine.HeadSitJoints = {}
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Massless = true 
                elseif v:IsA("Motor6D") and (v.Name:find("Shoulder") or v.Name:find("Arm")) then
                    TrollEngine.HeadSitJoints[v] = v.C0
                end
            end

            -- 2. TRIPLE-LAYER NOCLIP (Stops the Fling)
            local headSitNoclip = RunService.Stepped:Connect(function()
                if not TrollEngine.HeadSitActive or not Char then return end
                
                -- Noclip Local Character
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                        part.CanTouch = false -- ESSENTIAL: Stops physics repulsion
                        part.CanQuery = false -- Engine ignores existence
                    end
                end
                
                -- Noclip Target (Local client-side only to prevent bumps)
                if TrollEngine.Target and TrollEngine.Target.Character then
                    for _, part in pairs(TrollEngine.Target.Character:GetDescendants()) do
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                            part.CanTouch = false 
                        end
                    end
                end
            end)
            table.insert(TrollEngine.Connections, headSitNoclip)

            -- 3. MAIN LOOP: CFrame Lock & Animation
            task.spawn(function()
                while TrollEngine.HeadSitActive do
                    if not TrollEngine.Target or not TrollEngine.Target.Parent or not TrollEngine.Target.Character then
                        TrollEngine.HeadSitActive = false
                        Rayfield:Notify({Title = "Head-Sit Stopped", Content = "Target left the server.", Duration = 3})
                        break
                    end
                    local TargetChar = TrollEngine.Target and TrollEngine.Target.Character
                    local THRP = TargetChar and TargetChar:FindFirstChild("HumanoidRootPart")
                    local THead = TargetChar and TargetChar:FindFirstChild("Head")

                    if HRP and (THead or THRP) and Hum then
                        -- A. VELOCITY ANCHOR
                        HRP.AssemblyLinearVelocity = Vector3.zero
                        HRP.AssemblyAngularVelocity = Vector3.zero
                        
                        if Hum:GetState() == Enum.HumanoidStateType.Freefall then
                            Hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                        end

                        -- B. POSITIONING (Lock to Head if available, else Root)
                        local AttachPoint = THead or THRP
                        HRP.CFrame = AttachPoint.CFrame * CFrame.new(0, 1.6, 0.1)
                        
                        if not Hum.Sit then Hum.Sit = true end

                        -- C. ELITE FLAP ANIMATION
                        local t = tick() * 12
                        local flap = math.sin(t) * 0.7
                        for joint, originalC0 in pairs(TrollEngine.HeadSitJoints) do
                            if joint and joint.Parent then
                                local isLeft = joint.Name:find("Left")
                                joint.C0 = originalC0 * CFrame.Angles(0, 0, isLeft and (math.rad(80) + flap) or (-math.rad(80) - flap))
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)

        else
            -- 4. BRUTE FORCE CLEANUP & RESET
            TrollEngine.HeadSitActive = false
            
            for _, conn in pairs(TrollEngine.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            TrollEngine.Connections = {}

            -- Restore Character State
            if Char then
                for _, v in pairs(Char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true 
                        v.CanTouch = true
                        v.CanQuery = true
                        v.Massless = false
                    end
                end
            end
            
            -- Restore Target Collision
            if TrollEngine.Target and TrollEngine.Target.Character then
                for _, v in pairs(TrollEngine.Target.Character:GetDescendants()) do
                    if v:IsA("BasePart") then 
                        v.CanCollide = true 
                        v.CanTouch = true
                    end
                end
            end

            -- Reset Joints
            for joint, originalC0 in pairs(TrollEngine.HeadSitJoints) do
                if joint and joint.Parent then joint.C0 = originalC0 end
            end
            TrollEngine.HeadSitJoints = {}

            -- Safe Exit
            if Hum then 
                Hum.Sit = false 
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end

            -- Ensure we aren't stuck in a wall
            local landingSpot = GetNearestGround()
            HRP.CFrame = CFrame.new(landingSpot)
            HRP.AssemblyLinearVelocity = Vector3.zero

            _G.EliteLog("Head-Sitter Disengaged", "info")
        end
    end,
})
-- 4. ELITE LAG-FAKE (Slow-Mo & Float)
Tab:CreateToggle({
    Name = "Elite Lag-Fake",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.LagFakeActive = Value
        local HRP = LP.Character:FindFirstChild("HumanoidRootPart")
        task.spawn(function()
            while TrollEngine.LagFakeActive do
                if HRP then
                    local startPos = HRP.CFrame
                    task.wait(TrollEngine.LagIntensity)
                    HRP.Anchored = true
                    -- Floating effect during the lag freeze
                    HRP.CFrame = startPos * CFrame.new(0, TrollEngine.LagFloat, 0)
                    task.wait(0.1)
                    HRP.Anchored = false
                end
            end
        end)
    end,
})

Tab:CreateSlider({
    Name = "Lag Frequency (Seconds)",
    Range = {0.1, 1},
    Increment = 0.1,
    CurrentValue = 0.2,
    Callback = function(Value) TrollEngine.LagIntensity = Value end,
})

Tab:CreateSlider({
    Name = "Lag Float Height",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = 0,
    Callback = function(Value) TrollEngine.LagFloat = Value end,
})

-- [[ ELITE MARBLE - STABLE PHYSICS EDITION ]]
local MarblePart = nil
local MarbleColor = Color3.fromRGB(0, 255, 255)

-- 1. Color Customization
Tab:CreateColorPicker({
    Name = "Marble Color",
    Color = Color3.fromRGB(0, 255, 255),
    Callback = function(Value)
        MarbleColor = Value
        if MarblePart then MarblePart.Color = Value end
    end
})

-- 2. Marble Toggle
Tab:CreateToggle({
    Name = "Elite Marble",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.MarbleActive = Value
        local Char = LP.Character
        local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        
        -- Get the RootJoint (Works for R6 and R15)
        local RootJoint = Char and (Char:FindFirstChild("RootJoint", true) or Char:FindFirstChild("Root Hip", true))

        if Value and HRP and Hum and RootJoint then
            local groundOffset = Hum.HipHeight + (HRP.Size.Y / 2)
            local ballSize = 10
            local ballRadius = ballSize / 2

            -- 1. VISUALS: The "Juicy Shine"
            MarblePart = Instance.new("Part")
            MarblePart.Name = "EliteMarble"
            MarblePart.Shape = Enum.PartType.Ball
            MarblePart.Size = Vector3.new(ballSize, ballSize, ballSize)
            MarblePart.Transparency = 0.5
            MarblePart.Reflectance = 0.3 -- This adds the "Juicy" shine
            MarblePart.Color = MarbleColor
            MarblePart.Material = Enum.Material.Glass 
            MarblePart.Parent = workspace
            
            -- Physics: High density for smoothness
            MarblePart.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 100)
            
            local spawnPos = HRP.Position - Vector3.new(0, groundOffset, 0) + Vector3.new(0, ballRadius, 0)
            HRP.AssemblyLinearVelocity = Vector3.zero
            MarblePart.CFrame = CFrame.new(spawnPos)

            task.spawn(function()
                local originalC0 = RootJoint.C0
                
                while TrollEngine.MarbleActive and MarblePart and HRP do
                    -- 2. CAMERA FIX: Keep HRP rotation fixed (Upright)
                    -- This stops the wobble. The camera follows the HRP.
                    local moveDir = Hum.MoveDirection
                    local currentRot = HRP.CFrame - HRP.Position
                    HRP.CFrame = CFrame.new(MarblePart.Position) * currentRot
                    
                    -- 3. CHARACTER TUMBLE: Rotate the character's body inside the ball
                    -- We copy the Marble's rotation and apply it to the RootJoint
                    local ballRotation = MarblePart.CFrame - MarblePart.Position
                    RootJoint.Transform = ballRotation:Inverse() 

                    Hum.PlatformStand = true
                    for _, v in pairs(Char:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false v.Massless = true end
                    end

                    local currentVel = MarblePart.AssemblyLinearVelocity
                    
                    if moveDir.Magnitude > 0 then
                        -- 4. SPEED FIX: Start from 30
                        local targetVel = moveDir * 30 
                        local newVel = currentVel:Lerp(Vector3.new(targetVel.X, currentVel.Y, targetVel.Z), 0.1)
                        MarblePart.AssemblyLinearVelocity = newVel
                        
                        -- Rolling Torque
                        local torqueDir = Vector3.new(currentVel.Z, 0, -currentVel.X)
                        MarblePart.AssemblyAngularVelocity = torqueDir * 2.5
                    else
                        -- Coasting stop
                        MarblePart.AssemblyLinearVelocity = Vector3.new(currentVel.X * 0.98, currentVel.Y, currentVel.Z * 0.98)
                        MarblePart.AssemblyAngularVelocity = MarblePart.AssemblyAngularVelocity * 0.98
                    end

                    -- Jump Logic
                    if Hum.Jump and math.abs(currentVel.Y) < 0.2 then
                        MarblePart.AssemblyLinearVelocity = Vector3.new(currentVel.X, 35, currentVel.Z)
                    end

                    RunService.Heartbeat:Wait()
                end

                -- CLEANUP
                if MarblePart then MarblePart:Destroy() end
                if RootJoint then RootJoint.Transform = CFrame.new() end
                if Hum then Hum.PlatformStand = false Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                for _, v in pairs(Char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true v.Massless = false end
                end
            end)
        else
            TrollEngine.MarbleActive = false
        end
    end,
})
Tab:CreateSection("Safety Platform Settings")

Tab:CreateSlider({
    Name = "Platform Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(Value)
        TrollEngine.PlatformTransparency = Value
        if TrollEngine.VoidPart then
            TrollEngine.VoidPart.Transparency = Value
        end
    end,
})
-- Ensure Movement
task.spawn(EliteSanitizeMovement)

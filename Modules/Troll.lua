
--==========================================================- Elite Help Section -==========================================================================

-- [[ ELITE FLYING BRIDGE ENGINE ]]
_G.EliteFlySpeed = 16 -- Default Elite Speed
local FlyingBridgeActive = false
local bridge_bv = nil
local bridge_bg = nil
local original_joints = {}

-- Function to lock limbs into a "Stretched Plank" pose
local function SetBridgePose(active)
    local Char = LP.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if not Char or not Hum then return end

    if active then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("Motor6D") then
                original_joints[v] = v.C0
                -- Stretch arms forward and legs back
                if v.Name:find("Shoulder") then
                    v.C0 = v.C0 * CFrame.Angles(math.rad(90), 0, 0)
                elseif v.Name:find("Hip") then
                    v.C0 = v.C0 * CFrame.Angles(math.rad(-90), 0, 0)
                end
            end
        end
        Hum.PlatformStand = true
    else
        for joint, c0 in pairs(original_joints) do
            if joint and joint.Parent then joint.C0 = c0 end
        end
        original_joints = {}
        Hum.PlatformStand = false
        Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

-- Main Physics Loop
task.spawn(function()
    _G.RunService.RenderStepped:Connect(function()
        local Char = LP.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        local Cam = workspace.CurrentCamera
        local UIS = game:GetService("UserInputService")
        
        -- 1. Dynamic Speed Check
        local speed = _G.EliteFlySpeed or 16

        if FlyingBridgeActive and Root and Hum and Cam then
            -- 2. Initialize Physics Objects (Elite Setup)
            if not bridge_bv then
                bridge_bv = Instance.new("BodyVelocity")
                bridge_bv.Name = "EliteBridge_Velocity"
                bridge_bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
                bridge_bv.Parent = Root
            end
            if not bridge_bg then
                bridge_bg = Instance.new("BodyGyro")
                bridge_bg.Name = "EliteBridge_Gyro"
                bridge_bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
                bridge_bg.P = 25000 -- High power for platform stability
                bridge_bg.D = 500
                bridge_bg.Parent = Root
            end

            -- 3. Input Handling (Mobile & PC Friendly)
            local moveDir = Hum.MoveDirection -- Works for Joysticks and WASD
            local up = UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
            local down = (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.ButtonL2)) and 1 or 0
            
            -- 4. Directional Velocity (World-Space Translation)
            local vertical = Vector3.new(0, (up - down) * speed, 0)
            
            if moveDir.Magnitude > 0 or up ~= 0 or down ~= 0 then
                -- Calculations: Translate local movement to world space relative to camera
                local worldMove = Cam.CFrame:VectorToWorldSpace(Cam.CFrame:VectorToObjectSpace(moveDir * speed))
                bridge_bv.Velocity = worldMove + vertical
            else
                -- Full stop to prevent sliding when no input is given
                bridge_bv.Velocity = Vector3.zero
            end

            -- 5. ELITE ORIENTATION (Locked Horizontal Plank)
            local _, yRotation, _ = Cam.CFrame:ToEulerAnglesYXZ()
            -- Lock character pitch to -90 degrees (laying down) while allowing left/right look (yaw)
            bridge_bg.CFrame = CFrame.Angles(0, yRotation, 0) * CFrame.Angles(math.rad(-90), 0, 0)

            -- 6. Collision Enforcement (Helpful Troll Mode)
            -- We force collisions on so people can actually stand on your character
            for _, part in pairs(Char:GetDescendants()) do
                if part:IsA("BasePart") then 
                    part.CanCollide = true 
                end
            end
        else
            -- 7. Cleanup
            if bridge_bv then bridge_bv:Destroy() bridge_bv = nil end
            if bridge_bg then bridge_bg:Destroy() bridge_bg = nil end
        end
    end)
end)
local TweenService = game:GetService("TweenService")

-- Helper: World-Space Vertical Tween
local function EliteVerticalTween(amount)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    -- Using + Vector3.new ensures it moves on the Global Y Axis (UP)
    -- even if the character is laying down or rotated.
    local targetCF = Root.CFrame + Vector3.new(0, amount, 0)
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Linear)
    
    TweenService:Create(Root, info, {CFrame = targetCF}):Play()
end
local PassengerMagnetActive = false
local MagnetPlate = nil

local function TogglePassengerMagnet(Value)
    PassengerMagnetActive = Value
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    
    if Value and Root then
        if MagnetPlate then MagnetPlate:Destroy() end -- Cleanup existing
        
        MagnetPlate = Instance.new("Part")
        MagnetPlate.Name = "ElitePassengerMagnet"
        MagnetPlate.Transparency = 1
        MagnetPlate.Size = Vector3.new(6, 0.5, 9)
        
        -- FIX: Start with CanCollide FALSE to prevent the initial fling
        MagnetPlate.CanCollide = false 
        MagnetPlate.Massless = true
        MagnetPlate.CFrame = Root.CFrame * CFrame.new(0, 0.5, 0)
        
        -- ELITE PHYSICS
        MagnetPlate.CustomPhysicalProperties = PhysicalProperties.new(0.7, 5, 0, 100, 100)
        MagnetPlate.Parent = Char
        
        -- FIX: Create No-Collision BEFORE turning on collisions
        local NoCol = Instance.new("NoCollisionConstraint")
        NoCol.Part0 = MagnetPlate
        NoCol.Part1 = Root
        NoCol.Parent = MagnetPlate
        
        local Weld = Instance.new("WeldConstraint")
        Weld.Part0 = Root
        Weld.Part1 = MagnetPlate
        Weld.Parent = MagnetPlate
        
        -- Now it is safe to turn on collisions
        task.wait(0.1)
        if MagnetPlate then MagnetPlate.CanCollide = true end
        
        _G.EliteLog("Passenger Magnet: Safely Engaged", "success")
    else
        if MagnetPlate then MagnetPlate:Destroy() MagnetPlate = nil end
        _G.EliteLog("Passenger Magnet: Disengaged", "info")
    end
end

-- Ensure the plate stays active and aligned if the bridge is moving
task.spawn(function()
    _G.RunService.Heartbeat:Connect(function()
        if PassengerMagnetActive and MagnetPlate and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            MagnetPlate.CanCollide = true
            
            -- [[ FIX BUG 2: PASSENGER HOOKING ]]
            -- Manually sync nearby player velocity to your bridge velocity
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local pRoot = p.Character.HumanoidRootPart
                    local distance = (pRoot.Position - MagnetPlate.Position).Magnitude
                    
                    if distance < 7 then -- If they are standing on the magnet area
                        -- Forcibly set their velocity to match your bridge movement
                        pRoot.AssemblyLinearVelocity = (bridge_bv and bridge_bv.Velocity) or Vector3.zero
                    end
                end
            end
        end
    end)
end)
-- UI INTEGRATION (Place in Troll Tab)
Tab:CreateSection("Helpful Troll Features")
Tab:CreateParagraph({
    Title = "⚠️ Collaboration Note",
    Content = "The Flying Bridge only works if the game has 'Player Collisions' enabled. If you pass through players, this feature will only be visual."
})
Tab:CreateToggle({
   Name = "Elite Passenger Magnet",
   CurrentValue = true, -- Defaulted to ON
   Flag = "PassengerMagnet_Toggle",
   Callback = function(Value)
      TogglePassengerMagnet(Value)
   end,
})

-- Only activate the magnet once the character is stationary and grounded
task.spawn(function()
    repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    task.wait(2) -- Wait for character to settle
    
    -- Ensure we only activate if the user actually has the toggle set to true
    local configValue = true -- Or pull from your Rayfield flags
    if configValue then
        TogglePassengerMagnet(true)
    end
end)

Tab:CreateParagraph({
    Title = "🧲 Magnet Instructions",
    Content = "This is enabled by default to assist with 'Flying Bridge' stability. It creates a high-friction zone on your back so passengers don't slide off."
})
Tab:CreateSlider({
   Name = "Bridge Flying Speed",
   Range = {0, 300},
   Increment = 1,
   Suffix = "SPS (Studs Per Sec)",
   CurrentValue = 16,
   Flag = "BridgeSpeed_Slider", -- For config saving
   Callback = function(Value)
      _G.EliteFlySpeed = Value
      -- Optional: Log speed change if significant
      if Value > 150 and _G.EliteLog then
          _G.EliteLog("Speed set to High-Velocity: " .. Value, "warn")
      end
   end,
})
Tab:CreateToggle({
   Name = "Elite Flying Bridge",
   CurrentValue = false,
   Flag = "FlyingBridge_Toggle",
   Callback = function(Value)
      FlyingBridgeActive = Value
      SetBridgePose(Value)
      if Value then
          _G.EliteLog("Bridge Active: You are now a flat platform.", "success")
      end
   end,
})
Tab:CreateSection("Position Adjust (Smooth)")

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

-- Continuous Movement (The "Hold" Alternative)
Tab:CreateSection("Continuous Adjust (Hold Simulation)")

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
Tab:CreateSection("Elite Troll Target")

local TrollDropdown = Tab:CreateDropdown({
    Name = "Troll Target: None",
    Options = GetTrollPlayerList(),
    CurrentOption = {""},
    Callback = function(Option)
        TrollEngine.Target = GetTrollTarget(Option[1])
    end,
})

Tab:CreateInput({
    Name = "Search Troll Target",
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
    Name = "Refresh Troll List",
    Callback = function()
        TrollDropdown:Refresh(GetTrollPlayerList())
    end,
})

-- 3. ELITE FEATURES
Tab:CreateSection("Troll Features")

-- 1. ELITE ORBIT (Customizable)
Tab:CreateToggle({
    Name = "Elite Orbit",
    CurrentValue = false,
    Callback = function(Value)
        TrollEngine.OrbitActive = Value
        ManageTrollPlatform(Value)
        local angle = 0
        task.spawn(function()
            while TrollEngine.OrbitActive do
                if TrollEngine.Target and TrollEngine.Target.Character then
                    local HRP = LP.Character:FindFirstChild("HumanoidRootPart")
                    local THRP = TrollEngine.Target.Character:FindFirstChild("HumanoidRootPart")
                    if HRP and THRP then
                        angle = angle + TrollEngine.OrbitSpeed
                        local TargetPos = THRP.CFrame
                        -- Orbit Position
                        HRP.CFrame = TargetPos * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, TrollEngine.OrbitHeight, TrollEngine.OrbitDistance)
                        
                        -- Safety Part: Syncs to Target Y but stays under the PLAYER
                        if TrollEngine.VoidPart then
                            TrollEngine.VoidPart.CFrame = CFrame.new(HRP.Position.X, THRP.Position.Y - 3.5, HRP.Position.Z)
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end
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
            -- 1. SETUP: Ghost Physics State
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then v.Massless = true end
            end

            -- 2. TRIPLE-LAYER NOCLIP (Prevents the "Fling Away" effect)
            local mimicNoclip = RunService.Stepped:Connect(function()
                if not TrollEngine.MimicActive or not Char then return end
                
                -- Noclip Local Character (Disable Collision + Touch + Query)
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                        part.CanTouch = false -- Fixes the repulsion force
                        part.CanQuery = false -- Engine ignores part existence
                    end
                end
                
                -- Noclip Target locally so your client doesn't bump them
                if TrollEngine.Target and TrollEngine.Target.Character then
                    for _, part in pairs(TrollEngine.Target.Character:GetDescendants()) do
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                            part.CanTouch = false 
                        end
                    end
                end
            end)
            table.insert(TrollEngine.Connections, mimicNoclip)

            task.spawn(function()
                while TrollEngine.MimicActive do
                    local TargetChar = TrollEngine.Target and TrollEngine.Target.Character
                    local THum = TargetChar and TargetChar:FindFirstChildOfClass("Humanoid")
                    local THRP = TargetChar and TargetChar:FindFirstChild("HumanoidRootPart")
                    
                    if HRP and THRP and Hum and THum then
                        -- 3. ELITE POSITIONING (Frame-Perfect CFrame)
                        if TrollEngine.MimicDistance == 0 then
                            -- Offset by 0.05 to prevent Z-Fighting (flickering textures)
                            HRP.CFrame = THRP.CFrame * CFrame.new(0, 0, 0.05)
                        else
                            local offsetPos = (THRP.CFrame * CFrame.new(0, 0, TrollEngine.MimicDistance)).Position
                            HRP.CFrame = CFrame.lookAt(offsetPos, THRP.Position)
                        end
                        
                        -- 4. VELOCITY ANCHOR (Claims Network Ownership without drift)
                        HRP.AssemblyLinearVelocity = Vector3.zero
                        HRP.AssemblyAngularVelocity = Vector3.zero
                        
                        -- 5. SAFETY PLATFORM
                        if TrollEngine.VoidPart then
                            TrollEngine.VoidPart.CanCollide = (TrollEngine.MimicDistance ~= 0)
                            TrollEngine.VoidPart.CFrame = CFrame.new(HRP.Position.X, THRP.Position.Y - 3.5, HRP.Position.Z)
                        end

                        -- 6. ANIMATION MIRRORING
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
                            end
                            -- Stop tracks that the target stopped
                            for ID, MyTrack in pairs(TrollEngine.MimicTracks) do
                                local isStillPlaying = false
                                for _, TTrack in pairs(PlayingTracks) do
                                    if TTrack.Animation.AnimationId == ID then isStillPlaying = true break end
                                end
                                if not isStillPlaying then 
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
            -- 7. CLEANUP & RESTORATION
            TrollEngine.MimicActive = false
            
            for _, conn in pairs(TrollEngine.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            TrollEngine.Connections = {}

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
            
            -- Reset target collision locally
            if TrollEngine.Target and TrollEngine.Target.Character then
                for _, v in pairs(TrollEngine.Target.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true v.CanTouch = true end
                end
            end

            for _, Track in pairs(TrollEngine.MimicTracks) do pcall(function() Track:Stop() end) end
            TrollEngine.MimicTracks = {}
            
            if Hum then Hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            _G.EliteLog("Mimic Disengaged", "info")
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


Tab:CreateSection("Safety Platform Settings")

Tab:CreateSlider({
    Name = "Platform Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.8,
    Callback = function(Value)
        TrollEngine.PlatformTransparency = Value
        if TrollEngine.VoidPart then
            TrollEngine.VoidPart.Transparency = Value
        end
    end,
})

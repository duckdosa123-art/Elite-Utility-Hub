--==========================================================- Elite Help Section (COMPLETE & FIXED) -==========================================================================

-- [[ ELITE FLYING BRIDGE ENGINE ]]
_G.EliteFlySpeed = 10 -- Default Elite Speed
local FlyingBridgeActive = false
local bridge_bv = nil
local bridge_bg = nil
local original_joints = {}

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
    _G.RunService.RenderStepped:Connect(function()
        local Char = LP.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        local Cam = workspace.CurrentCamera
        local UIS = game:GetService("UserInputService")
        
        local speed = _G.EliteFlySpeed or 10

        if FlyingBridgeActive and Root and Hum and Cam then
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

            -- [[ ELITE NOCLIP INTEGRATION ]]
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
            if bridge_bv then bridge_bv:Destroy() bridge_bv = nil end
            if bridge_bg then bridge_bg:Destroy() bridge_bg = nil end
            
            -- Restore Noclip only if main toggle is off
            if not _nc and Char then
                for _, p in pairs(Char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
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

-- [[ ELITE PASSENGER MAGNET ENGINE (WORKING MODEL + INTEGRATED NOCLIP) ]]
local PassengerMagnetActive = false
local MagnetPlate = nil
local MagnetNoclipConn = nil

local function TogglePassengerMagnet(Value)
    PassengerMagnetActive = Value
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    
    if Value and Root then
        if MagnetPlate then MagnetPlate:Destroy() end 
        
        MagnetPlate = Instance.new("Part")
        MagnetPlate.Name = "ElitePassengerMagnet"
        MagnetPlate.Transparency = 1
        MagnetPlate.Size = Vector3.new(9, 0.6, 11)
        MagnetPlate.CanCollide = false 
        MagnetPlate.Massless = true
        MagnetPlate.CFrame = Root.CFrame * CFrame.new(0, 0.5, 0)
        
        -- WORKING MODEL PHYSICS
        MagnetPlate.CustomPhysicalProperties = PhysicalProperties.new(10, 10, 0, 10, 10)
        MagnetPlate.Parent = Char
        
        -- [[ INTEGRATED NOCLIP LOGIC ]]
        -- This uses your provided logic to noclip ONLY you from the magnet
        MagnetNoclipConn = RunService.Stepped:Connect(function()
            if not PassengerMagnetActive or not Char then 
                if MagnetNoclipConn then MagnetNoclipConn:Disconnect() end
                return 
            end
            
            for _, part in pairs(Char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "ElitePassengerMagnet" then
                    -- This disables YOUR collision so you don't shake against the plate
                    part.CanCollide = false
                end
            end
        end)
        
        local NoCol = Instance.new("NoCollisionConstraint")
        NoCol.Part0 = MagnetPlate
        NoCol.Part1 = Root
        NoCol.Parent = MagnetPlate
        
        local Weld = Instance.new("WeldConstraint")
        Weld.Part0 = Root
        Weld.Part1 = MagnetPlate
        Weld.Parent = MagnetPlate
        
        task.wait(0.1)
        if MagnetPlate then MagnetPlate.CanCollide = true end
        _G.EliteLog("Magnet: Noclip-Pull Engaged", "success")
    else
        if MagnetPlate then MagnetPlate:Destroy() MagnetPlate = nil end
        if MagnetNoclipConn then MagnetNoclipConn:Disconnect() end
        _G.EliteLog("Magnet: Disengaged", "info")
    end
end

-- Elite Jitter-Sync Loop (WORKING MODEL)
task.spawn(function()
    _G.RunService.Heartbeat:Connect(function()
        if PassengerMagnetActive and MagnetPlate and LP.Character then
            local bridgeVel = (bridge_bv and bridge_bv.Velocity) or Vector3.zero
            
            local jitter = Vector3.new(
                math.random(-1, 1) * 0.1,
                math.random(-1, 1) * 0.1,
                math.random(-1, 1) * 0.1
            )
            
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= LP and p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                    
                    if pRoot and pHum then
                        local distance = (pRoot.Position - MagnetPlate.Position).Magnitude
                        
                        if distance < 8.5 then
                            -- THE MAGNETIC LOCK
                            pRoot.AssemblyLinearVelocity = bridgeVel + jitter
                            pRoot.AssemblyAngularVelocity = Vector3.new(0, 5, 0)
                            
                            -- FLOOR ADHESION
                            if pRoot.Position.Y > MagnetPlate.Position.Y + 2 then
                                pRoot.AssemblyLinearVelocity = Vector3.new(bridgeVel.X, -20, bridgeVel.Z)
                            end
                            
                            -- R15 STABILITY
                            pHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            pHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                        end
                    end
                end
            end
        end
    end)
end)
-- UI INTEGRATION
Tab:CreateSection("Helpful Features")
Tab:CreateParagraph({
    Title = "⚠️ Note",
    Content = "The Flying Bridge only works if the game has 'Player Collisions' enabled."
})

Tab:CreateParagraph({
    Title = "🧲 Magnet Instructions",
    Content = "Enable NoClip before using the bridge to assist 'Flying Bridge' stability. It creates a high-friction zone on your back so passengers don't slide off."
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
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      _nc = Value
      _G.EliteLog("Noclip: " .. (Value and "Enabled" or "Disabled"), Value and "success" or "warn")
      if not Value then
          local c = LP.Character
          if c then
              for _, p in pairs(c:GetDescendants()) do
                  if p:IsA("BasePart") then p.CanCollide = true end
              end
          end
      end
   end,
})
Tab:CreateToggle({
   Name = "Elite Passenger Magnet",
   CurrentValue = true,
   Flag = "PassengerMagnet_Toggle",
   Callback = function(Value)
      -- 1. SETTLE PHYSICS: Clear existing jitter before changing state
      local Char = LP.Character
      local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
      local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
      
      if HRP then
          HRP.AssemblyLinearVelocity = Vector3.zero
          HRP.AssemblyAngularVelocity = Vector3.zero
      end

      -- 2. TRIGGER ENGINE
      TogglePassengerMagnet(Value)

      -- 3. THE STABILIZER: Force the Humanoid to "re-stand"
      -- This fixes the shaking by forcing the engine to re-calculate your balance
      if Hum then
          task.wait(0.05)
          Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
          _G.EliteLog("Magnet Stability Reset: " .. (Value and "Applied" or "Cleared"), "success")
      end
   end,
})
Tab:CreateToggle({
   Name = "Elite Flying Bridge",
   CurrentValue = false,
   Flag = "BridgeActive_Toggle",
   Callback = function(Value)
      FlyingBridgeActive = Value -- Sets it to true or false
      SetBridgePose(Value)       -- Triggers the plank animation correctly
      
      if Value then
          _G.EliteLog("Flying Bridge: Engaged", "success")
      else
          _G.EliteLog("Flying Bridge: Disengaged", "info")
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
            -- 1. SETUP: Ghost Physics & State Suppression
            for _, v in pairs(Char:GetDescendants()) do
                if v:IsA("BasePart") then v.Massless = true end
            end
            
            -- ELITE FIX: Kill the standing force to stop floating
            Hum.PlatformStand = true
            Hum.AutoRotate = false

            -- 2. TRIPLE-LAYER NOCLIP
            local mimicNoclip = RunService.Stepped:Connect(function()
                if not TrollEngine.MimicActive or not Char then return end
                for _, part in pairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                        part.CanTouch = false 
                        part.CanQuery = false 
                    end
                end
                
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
                        -- ELITE FIX: Sync HipHeight to prevent floating offset
                        Hum.HipHeight = THum.HipHeight
                        for _, Scale in pairs(THum:GetChildren()) do
                            if Scale:IsA("NumberValue") then -- Matches Height, Width, Depth, HeadScale
                                local MyScale = Hum:FindFirstChild(Scale.Name)
                                if MyScale then
                                    MyScale.Value = Scale.Value
                                end
                            end
                        end

                        -- 3. ELITE POSITIONING
                        if TrollEngine.MimicDistance == 0 then
                            -- Use exact CFrame; the PlatformStand handles the "floating" error
                            HRP.CFrame = THRP.CFrame
                            -- Force Physics state to prevent Humanoid from trying to "climb" the target
                            Hum:ChangeState(Enum.HumanoidStateType.Physics)
                        else
                            local offsetPos = (THRP.CFrame * CFrame.new(0, 0, TrollEngine.MimicDistance)).Position
                            HRP.CFrame = CFrame.lookAt(offsetPos, THRP.Position)
                        end
                        
                        -- 4. VELOCITY ANCHOR
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
            
            if Hum then 
                Hum.PlatformStand = false
                Hum.AutoRotate = true
                Hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
            end

            for _, Track in pairs(TrollEngine.MimicTracks) do pcall(function() Track:Stop() end) end
            TrollEngine.MimicTracks = {}
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

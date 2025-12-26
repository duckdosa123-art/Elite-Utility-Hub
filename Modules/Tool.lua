-- Tool.lua - Elite-Utility-Hub
local LP = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Mouse = LP:GetMouse()
local Tab = _G.ToolTab

-- [ 1. DYNAMIC UI & CROSSHAIR SETUP ]
local GravityGui = Instance.new("ScreenGui")
GravityGui.Name = "EliteGravGui"
GravityGui.Enabled = false
GravityGui.ResetOnSpawn = false
GravityGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GravityGui.Parent = LP:WaitForChild("PlayerGui")

local function CreateGravButton(name, pos, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 110, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = GravityGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

-- Buttons placed at Top-Center (Y=5) to keep vision clear
local ThrowBtn = CreateGravButton("THROW", UDim2.new(0.5, -115, 0, 5), Color3.fromRGB(200, 50, 50))
local StopBtn = CreateGravButton("STOP / DROP", UDim2.new(0.5, 5, 0, 5), Color3.fromRGB(50, 50, 50))

local Crosshair = Instance.new("Frame", GravityGui)
Crosshair.Size = UDim2.new(0, 4, 0, 4)
Crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
Crosshair.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Crosshair.BorderSizePixel = 0
Crosshair.Visible = false
Instance.new("UICorner", Crosshair).CornerRadius = UDim.new(1, 0)

local function CreateCHLine(size, pos)
    local f = Instance.new("Frame", GravityGui)
    f.Size = size; f.Position = pos; f.BackgroundColor3 = Color3.new(1, 1, 1)
    f.BorderSizePixel = 0; f.Visible = false; return f
end
local CH_V = CreateCHLine(UDim2.new(0, 2, 0, 20), UDim2.new(0.5, -1, 0.5, -10))
local CH_H = CreateCHLine(UDim2.new(0, 20, 0, 2), UDim2.new(0.5, -10, 0.5, -1))

-- [ 2. TELEKINESIS V6 PHYSICS ENGINE ]
_G.GrabDistance = 15
_G.GrabTransparency = 0.5
_G.OriginalTrans = 0

local grabbing = false
local grabPart = nil
local bp, bg, highlight

local function Release()
    grabbing = false
    if grabPart and grabPart:IsA("BasePart") then
        pcall(function() 
            grabPart.CustomPhysicalProperties = nil 
            grabPart.Transparency = _G.OriginalTrans 
        end)
    end
    if bp then bp:Destroy() bp = nil end
    if bg then bg:Destroy() bg = nil end
    if highlight then highlight:Destroy() highlight = nil end
    grabPart = nil
end

local function Throw()
    if grabPart and grabbing then
        local p = grabPart
        local look = workspace.CurrentCamera.CFrame.LookVector
        Release()
        p.AssemblyLinearVelocity = look * 350 
        _G.EliteLog("Object Launched via Telekinesis", "success")
    end
end

ThrowBtn.MouseButton1Click:Connect(Throw)
StopBtn.MouseButton1Click:Connect(Release)

local function TelekinesisLogic()
    if not grabbing then
        local target = Mouse.Target
        if target and target:IsA("BasePart") and not target.Anchored then
            grabbing = true
            grabPart = target
            _G.OriginalTrans = target.Transparency
            
            pcall(function() target.AssemblyLinearVelocity = Vector3.new(0, 1, 0) end)

            highlight = Instance.new("Highlight", grabPart)
            highlight.FillColor = Color3.fromRGB(200, 50, 50)
            
            bg = Instance.new("BodyGyro", grabPart)
            bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
            bg.P = 30000
            
            bp = Instance.new("BodyPosition", grabPart)
            bp.MaxForce = Vector3.new(1, 1, 1) * math.huge
            bp.P = 25000; bp.D = 600
            
            _G.EliteLog("Telekinesis Active: " .. grabPart.Name, "info")
            
            task.spawn(function()
                while grabbing and grabPart and grabPart.Parent do
                    local cam = workspace.CurrentCamera
                    if cam then
                        grabPart.Transparency = _G.GrabTransparency
                        -- OFFSET FIX: Moves part to the right so you can see forward
                        local holdPos = cam.CFrame.Position 
                            + (cam.CFrame.LookVector * _G.GrabDistance) 
                            + (cam.CFrame.RightVector * 5)
                            
                        bp.Position = holdPos
                        bg.CFrame = cam.CFrame
                    end
                    task.wait()
                end
                Release()
            end)
        else _G.EliteLog("Target unmovable", "warn") end
    else Release() end
end

-- [ 3. TACTICAL TOOLS LOGIC ]
local ActiveTools = {}
local function CreateTool(name, callback)
    local t = Instance.new("Tool")
    t.Name = "Elite: " .. name
    t.RequiresHandle = false
    t.Activated:Connect(function() pcall(callback) end)
    return t
end

-- [ 4. UI SECTIONS ]

-- ARCHITECT TOOLS (Mobile Optimized)
Tab:CreateSection("Architect Tools")

local BToolFolder = nil
local Mouse = LP:GetMouse()

-- Helper to create mobile-compatible tools
local function CreateMobileTool(name, color, callback)
    local tool = Instance.new("Tool")
    tool.Name = "Elite " .. name
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    
    -- Mobile users need visual feedback since there are no icons
    tool.Equipped:Connect(function()
        _G.EliteLog(name .. " Tool Equipped", "info")
    end)

    tool.Activated:Connect(function()
        local target = Mouse.Target
        if target and target.Parent and not target:IsA("Terrain") then
            callback(target)
        end
    end)
    
    return tool
end

Tab:CreateToggle({
   Name = "Elite BTools",
   CurrentValue = false,
   Callback = function(Value)
      task.spawn(function()
         local Backpack = LP:FindFirstChild("Backpack")
         local StarterGear = LP:FindFirstChild("StarterGear")
         
         -- Cleanup
         if BToolFolder then BToolFolder:Destroy() BToolFolder = nil end
         for _, v in pairs(LP.Backpack:GetChildren()) do 
            if v.Name:find("Elite ") then v:Destroy() end 
         end
         if StarterGear then
            for _, v in pairs(StarterGear:GetChildren()) do 
               if v.Name:find("Elite ") then v:Destroy() end 
            end
         end

         if Value then
            if not Backpack or not StarterGear then return end
            
            -- 1. DELETE TOOL
            local deleteTool = CreateMobileTool("Deleter", Color3.fromRGB(255,0,0), function(target)
                _G.EliteLog("Deleted: " .. target.Name, "info")
                target:Destroy()
            end)
            
            -- 2. CLONE TOOL
            local cloneTool = CreateMobileTool("Cloner", Color3.fromRGB(0,255,0), function(target)
                local cl = target:Clone()
                cl.Parent = target.Parent
                cl.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                _G.EliteLog("Cloned: " .. target.Name, "success")
            end)

            -- 3. MOVE (TP TO PLAYER) TOOL
            local moveTool = CreateMobileTool("Grabber", Color3.fromRGB(0,0,255), function(target)
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not target.Anchored then
                    target.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * 5)
                    _G.EliteLog("Moved: " .. target.Name, "info")
                else
                    _G.EliteLog("Cannot move anchored part", "error")
                end
            end)

            -- Parent to Backpack and StarterGear for death-persistence
            local tools = {deleteTool, cloneTool, moveTool}
            for _, t in pairs(tools) do
                t.Parent = Backpack
                t:Clone().Parent = StarterGear
            end

            _G.EliteLog("Mobile BTools Ready", "success")
         else
            _G.EliteLog("BTools Disabled", "info")
         end
      end)
   end,
})
Tab:CreateToggle({
   Name = "Local Deleter Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           ActiveTools["Deleter"] = CreateTool("Deleter", function()
               if Mouse.Target then 
                  _G.EliteLog("Deleted: "..Mouse.Target.Name, "info")
                  Mouse.Target.Transparency = 1; Mouse.Target.CanCollide = false 
               end
           end)
           ActiveTools["Deleter"].Parent = LP.Backpack
       elseif ActiveTools["Deleter"] then ActiveTools["Deleter"]:Destroy() end
   end,
})

-- TACTICAL
Tab:CreateSection("Tactical Movement")
Tab:CreateToggle({
   Name = "Click TP Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           ActiveTools["TP"] = CreateTool("TP Tool", function()
               local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
               if hrp then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0,3,0)) end
               _G.EliteLog("Click Teleport Executed", "success")
           end)
           ActiveTools["TP"].Parent = LP.Backpack
       elseif ActiveTools["TP"] then ActiveTools["TP"]:Destroy() end
   end,
})

-- CHAOS
Tab:CreateSection("Chaos & Physics")
Tab:CreateToggle({
   Name = "Elite Telekinesis (V6)",
   CurrentValue = false,
   Flag = "GravToggle",
   Callback = function(Value)
       if Value then
           local t = CreateTool("Telekinesis", TelekinesisLogic)
           t.Equipped:Connect(function() 
               GravityGui.Enabled = true; Crosshair.Visible = true; CH_V.Visible = true; CH_H.Visible = true 
           end)
           t.Unequipped:Connect(function() 
               GravityGui.Enabled = false; Crosshair.Visible = false; CH_V.Visible = false; CH_H.Visible = false; Release() 
           end)
           t.Parent = LP.Backpack
           ActiveTools["Grav"] = t
       else
           if ActiveTools["Grav"] then ActiveTools["Grav"]:Destroy() end
           GravityGui.Enabled = false; Crosshair.Visible = false; CH_V.Visible = false; CH_H.Visible = false; Release()
       end
   end,
})

Tab:CreateSlider({
   Name = "Telekinesis Distance",
   Range = {5, 100},
   Increment = 1,
   CurrentValue = 15,
   Callback = function(V) _G.GrabDistance = V end,
})

Tab:CreateSlider({
   Name = "Grab Transparency",
   Range = {0, 1},
   Increment = 0.1,
   CurrentValue = 0.5,
   Callback = function(V) _G.GrabTransparency = V end,
})

-- PART CONTROL
Tab:CreateSection("Part Control")


Tab:CreateToggle({
   Name = "Immune to Kill Bricks",
   CurrentValue = false,
   Callback = function(Value)
      local char = LP.Character
      if char then
          for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanTouch = not Value end end
      end
      _G.EliteLog("Kill Brick Immunity: "..tostring(Value), "info")
   end,
})
-- [ ELITE PROFESSIONAL PHYSICS ENGINE ]
Tab:CreateSection("Elite Part Control")

local _physicsDist = 60
local _maxPartVolume = 500 -- Parts bigger than this are ignored (prevents map-popping)
local _highlightColor = Color3.fromRGB(0, 255, 120)

-- Helper: Check if a part is actually a moveable prop
local function IsValidProp(v)
    if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(LP.Character) then
        local vol = v.Size.X * v.Size.Y * v.Size.Z
        if vol < _maxPartVolume and v.Transparency < 1 then
            return true
        end
    end
    return false
end

-- 1. Elite Pop Launcher (One-time Impulse)
Tab:CreateButton({
   Name = "Elite Pop Launcher",
   Callback = function()
       task.spawn(function()
           local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
           if not hrp then return end
           
           local count = 0
           for _, v in pairs(workspace:GetDescendants()) do
               if IsValidProp(v) then
                   local dist = (v.Position - hrp.Position).Magnitude
                   if dist < _physicsDist then
                       -- Apply a high-velocity punch to launch stationary parts
                       v.AssemblyLinearVelocity = Vector3.new(0, 60, 0) 
                       count = count + 1
                   end
               end
           end
           
           _G.EliteLog("Launched " .. count .. " stationary parts near you", "success")
           
           -- Optional: Official Roblox notification for confirmation
           game:GetService("StarterGui"):SetCore("SendNotification", {
               Title = "Elite Launcher",
               Text = "Popped " .. count .. " objects!",
               Duration = 3
           })
       end)
   end,
})
-- 2. Launch Nearby Parts (Toggle Loop)
local _launchNearby = false
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not _launchNearby then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, v in pairs(workspace:GetDescendants()) do
            if IsValidProp(v) then
                if (v.Position - hrp.Position).Magnitude < _physicsDist then
                    v.AssemblyLinearVelocity = Vector3.new(0, 120, 0)
                end
            end
        end
    end)
end)

Tab:CreateToggle({
   Name = "Launch Nearby Parts",
   CurrentValue = false,
   Callback = function(Value)
       _launchNearby = Value
       _G.EliteLog("Launch Nearby: " .. (Value and "Active" or "Disabled"), Value and "success" or "warn")
   end,
})

-- 3. Dynamic Highlight Moveable (Real-time Refresh)
local _highEnabled = false
task.spawn(function()
    while true do
        if _highEnabled then
            for _, v in pairs(workspace:GetDescendants()) do
                if not _highEnabled then break end
                if IsValidProp(v) then
                    if not v:FindFirstChild("EliteMoveHL") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EliteMoveHL"
                        hl.FillColor = _highlightColor
                        hl.OutlineColor = Color3.new(1,1,1)
                        hl.FillTransparency = 0.5
                        hl.Parent = v
                    end
                end
            end
        end
        task.wait(1.5) -- Refresh rate for new parts (Mobile Optimized)
    end
end)

Tab:CreateToggle({
   Name = "Highlight Moveable Parts",
   CurrentValue = false,
   Callback = function(Value)
       _highEnabled = Value
       if not Value then
           -- Immediate Cleanup
           for _, v in pairs(workspace:GetDescendants()) do
               if v:FindFirstChild("EliteMoveHL") then v.EliteMoveHL:Destroy() end
           end
       end
       _G.EliteLog("Movable Highlights: " .. (Value and "Enabled" or "Disabled"), "info")
   end,
})

-- [[ ELITE PART MANIPULATOR V2: ORBIT & THROW ]]
local Mouse = LP:GetMouse()
local OrbitParts = {}
local OrbitConn = nil

local ManipSettings = {
    Enabled = false,
    Radius = 12,
    Speed = 4,
    Height = 1,
    ThrowPower = 250,
    MaxParts = 50 -- Lag prevention
}

-- [ HELPER: GHOST MODE & SCAN ]
-- Makes parts non-collidable for YOU and invisible to your CAMERA
local function MakeGhost(part)
    if part:IsA("BasePart") then
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false -- Prevents camera from zooming in when part passes your face
        part.LocalTransparencyModifier = 0.5 -- Makes them ghost-like for you
    end
end

local function RefreshManipParts()
    OrbitParts = {}
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if count >= ManipSettings.MaxParts then break end
        if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(game.Players) then
            if v.Size.Magnitude < 40 and v.Name ~= "Baseplate" and v.Name ~= "Terrain" then
                MakeGhost(v)
                table.insert(OrbitParts, v)
                count = count + 1
            end
        end
    end
end

Tab:CreateSection("Elite Part Manipulator")

Tab:CreateToggle({
   Name = "Elite Part Orbit",
   CurrentValue = false,
   Callback = function(Value)
      ManipSettings.Enabled = Value
      if OrbitConn then OrbitConn:Disconnect() end
      
      if Value then
          _G.EliteLog("Orbit Active: You are now a Ghost", "success")
          RefreshManipParts()
          
          OrbitConn = game:GetService("RunService").Heartbeat:Connect(function()
              local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
              if not Root then return end
              
              local Time = tick() * ManipSettings.Speed
              for i, part in pairs(OrbitParts) do
                  if part and part.Parent and not part.Anchored then
                      -- 1. CALCULATE POSITION
                      local angle = Time + (i * (math.pi * 2 / #OrbitParts))
                      local targetPos = Root.Position + Vector3.new(
                          math.cos(angle) * ManipSettings.Radius,
                          ManipSettings.Height,
                          math.sin(angle) * ManipSettings.Radius
                      )
                      
                      -- 2. LAG-FREE PHYSICS TUG (FE Compatible)
                      local velocity = (targetPos - part.Position) * 15
                      part.AssemblyLinearVelocity = velocity + Vector3.new(0, 30, 0) -- Counter gravity
                      
                      -- 3. CONSTANT GHOST CHECK
                      part.CanCollide = false
                      part.CanQuery = false
                  else
                      table.remove(OrbitParts, i)
                  end
              end
          end)
          
          -- Auto-Refresh Watchdog
          task.spawn(function()
              while ManipSettings.Enabled do
                  task.wait(2)
                  if #OrbitParts < ManipSettings.MaxParts then RefreshManipParts() end
              end
          end)
      else
          _G.EliteLog("Orbit Released", "info")
          for _, v in pairs(OrbitParts) do if v and v.Parent then v.CanCollide = true v.CanQuery = true end end
      end
   end,
})

Tab:CreateButton({
   Name = "Elite Throw Parts (Crosshair)",
   Callback = function()
      if #OrbitParts == 0 then return _G.EliteLog("No parts to throw!", "error") end
      
      local target = Mouse.Hit.Position
      _G.EliteLog("Firing Projectiles!", "success")
      
      -- We take half the orbiting parts and "launch" them
      for i = 1, #OrbitParts do
          local part = OrbitParts[i]
          if part and part.Parent then
              task.spawn(function()
                  -- Calculate direction to crosshair
                  local dir = (target - part.Position).Unit
                  
                  -- Apply Massive Impulse
                  part.AssemblyLinearVelocity = dir * ManipSettings.ThrowPower
                  
                  -- Temporarily remove from orbit so it can fly away
                  local originalPart = part
                  table.remove(OrbitParts, i)
                  task.wait(1.5)
                  -- Part will be picked up by the Watchdog again later
              end)
          end
      end
   end,
})

Tab:CreateSlider({
   Name = "Orbit Radius",
   Range = {5, 50},
   Increment = 1,
   CurrentValue = 12,
   Callback = function(V) ManipSettings.Radius = V end,
})

Tab:CreateSlider({
   Name = "Orbit Speed",
   Range = {1, 20},
   Increment = 1,
   CurrentValue = 4,
   Callback = function(V)
      ManipSettings.Speed = V
   end,
})

Tab:CreateSlider({
   Name = "Throw Velocity",
   Range = {100, 500},
   Increment = 10,
   CurrentValue = 250,
   Callback = function(V) ManipSettings.ThrowPower = V end,
})

Tab:CreateButton({
   Name = "Force Re-Scan",
   Callback = function() RefreshManipParts() end,
})
-- [ AUTOMATION ]
Tab:CreateSection("Automation")

local autouseOn = false
Tab:CreateToggle({
   Name = "Auto-Use Held Tool",
   CurrentValue = false,
   Callback = function(Value)
       autouseOn = Value
       _G.EliteLog("Auto-Use: " .. (Value and "Started" or "Stopped"), "info")
       task.spawn(function()
           while autouseOn do
               local char = LP.Character
               local t = char and char:FindFirstChildOfClass("Tool")
               if t then t:Activate() end
               task.wait(0.1)
           end
       end)
   end,
})

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

local ThrowBtn = CreateGravButton("THROW", UDim2.new(0.5, -115, 0, 5), Color3.fromRGB(200, 50, 50))
local StopBtn = CreateGravButton("STOP / DROP", UDim2.new(0.5, 5, 0, 5), Color3.fromRGB(50, 50, 50))

local Crosshair = Instance.new("Frame", GravityGui)
Crosshair.Size = UDim2.new(0, 4, 0, 4)
Crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
Crosshair.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Crosshair.BorderSizePixel = 0
Instance.new("UICorner", Crosshair).CornerRadius = UDim.new(1, 0)

local function CreateCHLine(size, pos)
    local f = Instance.new("Frame", GravityGui)
    f.Size = size; f.Position = pos; f.BackgroundColor3 = Color3.new(1, 1, 1)
    f.BorderSizePixel = 0; return f
end
local CH_V = CreateCHLine(UDim2.new(0, 2, 0, 20), UDim2.new(0.5, -1, 0.5, -10))
local CH_H = CreateCHLine(UDim2.new(0, 20, 0, 2), UDim2.new(0.5, -10, 0.5, -1))

-- [ 2. TELEKINESIS V6 PHYSICS ENGINE ]
local grabbing = false
local grabPart = nil
local bp, bg, highlight
local grabDist = 15

local function Release()
    grabbing = false
    if grabPart and grabPart:IsA("BasePart") then
        pcall(function() grabPart.CustomPhysicalProperties = nil end)
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
            grabDist = (LP.Character.HumanoidRootPart.Position - target.Position).Magnitude
            
            pcall(function() target.AssemblyLinearVelocity = Vector3.new(0, 1, 0) end)

            highlight = Instance.new("Highlight", grabPart)
            highlight.FillColor = Color3.fromRGB(200, 50, 50)
            
            bg = Instance.new("BodyGyro", grabPart)
            bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
            bg.P = 30000
            
            bp = Instance.new("BodyPosition", grabPart)
            bp.MaxForce = Vector3.new(1, 1, 1) * math.huge
            bp.P = 25000; bp.D = 600
            
            _G.EliteLog("Telekinesis Active on: " .. grabPart.Name, "info")
            
            task.spawn(function()
                while grabbing and grabPart and grabPart.Parent do
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local cam = workspace.CurrentCamera
                    if hrp and cam then
                        bp.Position = cam.CFrame.Position + (cam.CFrame.LookVector * grabDist)
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

-- ARCHITECT
Tab:CreateSection("Architect Tools")
Tab:CreateToggle({
   Name = "Elite BTools",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          for i = 1, 4 do local hb = Instance.new("HopperBin", LP.Backpack); hb.BinType = i; table.insert(ActiveTools, hb) end
          _G.EliteLog("BTools Granted", "success")
      else for _, v in pairs(LP.Backpack:GetChildren()) do if v:IsA("HopperBin") then v:Destroy() end end end
   end,
})

Tab:CreateToggle({
   Name = "Local Deleter",
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

Tab:CreateToggle({
   Name = "Part Inspector",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           ActiveTools["Inspector"] = CreateTool("Inspector", function()
               if Mouse.Target then _G.EliteLog("Part: "..Mouse.Target.Name.." | Class: "..Mouse.Target.ClassName, "info") end
           end)
           ActiveTools["Inspector"].Parent = LP.Backpack
       elseif ActiveTools["Inspector"] then ActiveTools["Inspector"]:Destroy() end
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
           end)
           ActiveTools["TP"].Parent = LP.Backpack
       elseif ActiveTools["TP"] then ActiveTools["TP"]:Destroy() end
   end,
})

Tab:CreateToggle({
   Name = "Grapple Hook",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           ActiveTools["Grapple"] = CreateTool("Grapple", function()
               local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
               if hrp then
                   local bv = Instance.new("BodyVelocity", hrp)
                   bv.MaxForce = Vector3.new(1,1,1)*math.huge; bv.Velocity = (Mouse.Hit.Position - hrp.Position).Unit * 120
                   task.wait(0.5); bv:Destroy()
               end
           end)
           ActiveTools["Grapple"].Parent = LP.Backpack
       elseif ActiveTools["Grapple"] then ActiveTools["Grapple"]:Destroy() end
   end,
})

-- INTERACTION
Tab:CreateSection("Interaction")
local reachOn = false
Tab:CreateToggle({
   Name = "Infinite Reach",
   CurrentValue = false,
   Callback = function(Value)
       reachOn = Value
       _G.EliteLog("Reach: " .. (Value and "Enabled" or "Disabled"), "info")
       task.spawn(function()
           while reachOn do
               for _, v in pairs(game:GetDescendants()) do
                   if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then v.MaxActivationDistance = Value and 1000 or 32 end
               end
               task.wait(2)
           end
       end)
   end,
})

-- CHAOS
Tab:CreateSection("Physics & Fun")
Tab:CreateToggle({
   Name = "Elite Telekinesis (V6)",
   CurrentValue = false,
   Flag = "GravToggle",
   Callback = function(Value)
       if Value then
           local t = CreateTool("Telekinesis", TelekinesisLogic)
           t.Equipped:Connect(function() GravityGui.Enabled = true end)
           t.Unequipped:Connect(function() GravityGui.Enabled = false; Release() end)
           t.Parent = LP.Backpack
           ActiveTools["Grav"] = t
       else
           if ActiveTools["Grav"] then ActiveTools["Grav"]:Destroy() end
           GravityGui.Enabled = false; Release()
       end
   end,
})

Tab:CreateToggle({
   Name = "Local Fire Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           ActiveTools["Fire"] = CreateTool("Fire", function() if Mouse.Target then Instance.new("Fire", Mouse.Target) end end)
           ActiveTools["Fire"].Parent = LP.Backpack
       elseif ActiveTools["Fire"] then ActiveTools["Fire"]:Destroy() end
   end,
})

-- AUTOMATION
Tab:CreateSection("Automation")
local autouseOn = false
Tab:CreateToggle({
   Name = "Auto-Use Tool",
   CurrentValue = false,
   Callback = function(Value)
       autouseOn = Value
       task.spawn(function()
           while autouseOn do
               local t = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
               if t then t:Activate() end
               task.wait(0.1)
           end
       end)
   end,
})
-- SECTION: PART CONTROL
Tab:CreateSection("Part Control")

-- 1. Immune to Kill Bricks
local _kbImmune = false
Tab:CreateToggle({
   Name = "Immune to Kill Bricks",
   CurrentValue = false,
   Flag = "KillBrickImmune",
   Callback = function(Value)
      _kbImmune = Value
      _G.EliteLog("Kill Brick Immunity: " .. (Value and "Active" or "Disabled"), Value and "success" or "warn")
      
      -- Logic: Disables the character's ability to trigger "Touched" events
      local char = LP.Character
      if char then
          for _, p in pairs(char:GetDescendants()) do
              if p:IsA("BasePart") then
                  p.CanTouch = not Value
              end
          end
      end
   end,
})

-- 2. Detach Nearby Parts (Pops them up for Telekinesis)
Tab:CreateButton({
   Name = "Pop Nearby Parts",
   Callback = function()
       task.spawn(function()
           local count = 0
           local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
           if not hrp then return end
           
           for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("BasePart") and not v.Anchored and v.Parent ~= LP.Character then
                   local dist = (v.Position - hrp.Position).Magnitude
                   if dist < 50 then
                       count = count + 1
                       -- Apply a small upward pop to "wake up" the physics
                       v.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
                   end
               end
           end
           _G.EliteLog("Popped " .. count .. " nearby parts for Telekinesis", "success")
       end)
   end,
})

-- 3. Launch Parts in Space
Tab:CreateButton({
   Name = "Launch Parts into Space",
   Callback = function()
       task.spawn(function()
           local count = 0
           for _, v in pairs(workspace:GetDescendants()) do
               if v:IsA("BasePart") and not v.Anchored and v.Parent ~= LP.Character then
                   count = count + 1
                   -- Massive upward velocity
                   v.AssemblyLinearVelocity = Vector3.new(0, 1000, 0)
               end
           end
           _G.EliteLog("Launched " .. count .. " unanchored parts into orbit", "success")
       end)
   end,
})

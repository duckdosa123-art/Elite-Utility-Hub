-- Tool.lua - Elite-Utility-Hub
local LP = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Mouse = LP:GetMouse()
local Tab = _G.ToolTab

-- [ 1. DYNAMIC GRAVITY GUI & CROSSHAIR SETUP ]
local GravityGui = Instance.new("ScreenGui")
GravityGui.Name = "EliteGravGui"
GravityGui.Enabled = false
GravityGui.ResetOnSpawn = false
GravityGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GravityGui.Parent = LP:WaitForChild("PlayerGui")

-- Crosshair (Center Dot)
local Crosshair = Instance.new("Frame")
Crosshair.Name = "EliteCrosshair"
Crosshair.Size = UDim2.new(0, 4, 0, 4)
Crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
Crosshair.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Crosshair.BorderSizePixel = 0
Crosshair.Visible = false
Crosshair.Parent = GravityGui

local chCorner = Instance.new("UICorner")
chCorner.CornerRadius = UDim.new(1, 0)
chCorner.Parent = Crosshair

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
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

-- Moved to Top-Center to avoid Jump/Chat buttons
local ThrowBtn = CreateGravButton("THROW", UDim2.new(0.5, -115, 0, 5), Color3.fromRGB(200, 50, 50))
local StopBtn = CreateGravButton("STOP / DROP", UDim2.new(0.5, 5, 0, 5), Color3.fromRGB(50, 50, 50))

-- Aiming Crosshair
local CH_V = Instance.new("Frame", GravityGui)
CH_V.Size = UDim2.new(0, 2, 0, 20)
CH_V.Position = UDim2.new(0.5, -1, 0.5, -10)
CH_V.BackgroundColor3 = Color3.new(1, 1, 1)
CH_V.BorderSizePixel = 0

local CH_H = Instance.new("Frame", GravityGui)
CH_H.Size = UDim2.new(0, 20, 0, 2)
CH_H.Position = UDim2.new(0.5, -10, 0.5, -1)
CH_H.BackgroundColor3 = Color3.new(1, 1, 1)
CH_H.BorderSizePixel = 0

-- [ 2. GLOBAL TOOL VARIABLES ]
local ActiveTools = {}
local grabbing = false
local grabPart = nil
local bp, bg, highlight

-- [ REFINED GRAVITY GUN LOGIC ]
local function Release()
    grabbing = false
    if grabPart then
        -- Restore original properties
        pcall(function()
            if grabPart:IsA("BasePart") then
                grabPart.CustomPhysicalProperties = nil
                -- We don't reset NetworkOwner because we can't do that locally
            end
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
        -- Elite Brute Force Throw
        p.AssemblyLinearVelocity = look * 350 
        _G.EliteLog("Object Launched", "success")
    end
end

-- Re-connect buttons to new functions
ThrowBtn.MouseButton1Click:Connect(Throw)
StopBtn.MouseButton1Click:Connect(Release)

local function GravityGunLogic()
    if not grabbing then
        local target = Mouse.Target
        -- Elite Check: Part must exist and be unanchored
        if target and target:IsA("BasePart") and not target.Anchored then
            grabbing = true
            grabPart = target
            
            -- 1. CLAIM PHYSICS (Fixes the 'Stuck' bug)
            -- We try to set network ownership so the part responds only to us
            pcall(function()
                if settings().Physics.AllowSleep then
                    target.Velocity = Vector3.new(0, 1, 0) -- "Wake up" the part
                end
            end)

            -- 2. ENHANCED VISUALS
            highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(200, 50, 50)
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.Parent = grabPart
            
            -- 3. ELITE PHYSICS MOVERS
            bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
            bg.P = 30000 -- Increased for better control
            bg.Parent = grabPart
            
            bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1, 1, 1) * math.huge
            bp.P = 20000 -- Increased to lift heavy parts
            bp.D = 500   -- Dampening to stop "shaking"
            bp.Parent = grabPart
            
            _G.EliteLog("Grabbed: " .. grabPart.Name, "info")
            
            -- 4. THE ENGINE
            task.spawn(function()
                while grabbing and grabPart and grabPart.Parent do
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local cam = workspace.CurrentCamera
                    
                    if hrp and cam then
                        -- Hold part 15 studs in front of crosshair
                        local holdPos = cam.CFrame.Position + (cam.CFrame.LookVector * 15)
                        bp.Position = holdPos
                        bg.CFrame = cam.CFrame
                    end
                    task.wait()
                end
                Release()
            end)
        else
            _G.EliteLog("Part is Anchored or Invalid", "warn")
        end
    else
        Release()
    end
end
ThrowBtn.MouseButton1Click:Connect(Throw)
StopBtn.MouseButton1Click:Connect(Release)

local function GravityGunLogic()
    if not grabbing then
        local target = Mouse.Target
        if target and not target.Anchored then
            grabbing = true
            grabPart = target
            highlight = Instance.new("Highlight", grabPart)
            highlight.FillColor = Color3.fromRGB(200, 50, 50)
            bg = Instance.new("BodyGyro", grabPart)
            bg.MaxTorque = Vector3.new(1,1,1) * math.huge
            bp = Instance.new("BodyPosition", grabPart)
            bp.MaxForce = Vector3.new(1,1,1) * math.huge
            bp.P = 15000
            _G.EliteLog("Holding: " .. grabPart.Name, "info")
            task.spawn(function()
                while grabbing and grabPart and grabPart.Parent do
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        bp.Position = hrp.Position + (Mouse.Hit.LookVector * 15)
                        bg.CFrame = hrp.CFrame
                    end
                    task.wait()
                end
                Release()
            end)
        else _G.EliteLog("Target is anchored/unmovable", "warn") end
    else Release() end
end

-- Grapple Logic
local function GrappleLogic()
    local target = Mouse.Hit.Position
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1,1,1) * math.huge
        bv.Velocity = (target - hrp.Position).Unit * 120
        task.wait(0.5)
        bv:Destroy()
    end
end

-- [ 4. UI SECTIONS ]

-- ARCHITECT
Tab:CreateSection("Architect Tools")

Tab:CreateToggle({
   Name = "Elite BTools",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          for i = 1, 4 do
              local hb = Instance.new("HopperBin", LP.Backpack)
              hb.BinType = i
              table.insert(ActiveTools, hb)
          end
          _G.EliteLog("Classic BTools Granted", "success")
      else
          for _, v in pairs(LP.Backpack:GetChildren()) do if v:IsA("HopperBin") then v:Destroy() end end
      end
   end,
})

Tab:CreateToggle({
   Name = "Local Deleter Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local t = Instance.new("Tool", LP.Backpack)
           t.Name = "Elite: Deleter"
           t.RequiresHandle = false
           t.Activated:Connect(function()
               if Mouse.Target then 
                   _G.EliteLog("Locally Deleted: "..Mouse.Target.Name, "info")
                   Mouse.Target.Transparency = 1; Mouse.Target.CanCollide = false 
               end
           end)
           ActiveTools["Deleter"] = t
       elseif ActiveTools["Deleter"] then ActiveTools["Deleter"]:Destroy() end
   end,
})

Tab:CreateToggle({
   Name = "Part Inspector Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local t = Instance.new("Tool", LP.Backpack)
           t.Name = "Elite: Inspector"
           t.RequiresHandle = false
           t.Activated:Connect(function()
               if Mouse.Target then _G.EliteLog("Part: "..Mouse.Target.Name.." | Class: "..Mouse.Target.ClassName, "info") end
           end)
           ActiveTools["Inspector"] = t
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
           local t = Instance.new("Tool", LP.Backpack)
           t.Name = "Elite: TP Tool"
           t.RequiresHandle = false
           t.Activated:Connect(function()
               local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
               if hrp then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0,3,0)) end
               _G.EliteLog("Click Teleport Success", "success")
           end)
           ActiveTools["TP"] = t
       elseif ActiveTools["TP"] then ActiveTools["TP"]:Destroy() end
   end,
})

Tab:CreateToggle({
   Name = "Elite Grapple Hook",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local t = Instance.new("Tool", LP.Backpack)
           t.Name = "Elite: Grapple"
           t.RequiresHandle = false
           t.Activated:Connect(GrappleLogic)
           ActiveTools["Grapple"] = t
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
       _G.EliteLog("Inf Reach: " .. (Value and "Enabled" or "Disabled"), "info")
       task.spawn(function()
           while reachOn do
               for _, v in pairs(game:GetDescendants()) do
                   if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
                       v.MaxActivationDistance = Value and 1000 or 32
                   end
               end
               task.wait(2)
           end
       end)
   end,
})

-- CHAOS
Tab:CreateSection("Physics & Fun")

-- UPDATED GRAVITY GUN TOGGLE
Tab:CreateToggle({
   Name = "Elite Gravity Gun",
   CurrentValue = false,
   Flag = "GravToggle",
   Callback = function(Value)
       if Value then
           local tool = Instance.new("Tool", LP.Backpack)
           tool.Name = "Elite: Grav-Gun"
           tool.RequiresHandle = false
           
           tool.Equipped:Connect(function() 
               GravityGui.Enabled = true 
               Crosshair.Visible = true -- Show Crosshair
               _G.EliteLog("Grav-Gun Ready: Aim with center dot", "info")
           end)
           
           tool.Unequipped:Connect(function() 
               GravityGui.Enabled = false 
               Crosshair.Visible = false -- Hide Crosshair
               Release() 
           end)
           
           tool.Activated:Connect(GravityGunLogic)
           ActiveTools["Grav"] = tool
           _G.EliteLog("Gravity Gun Granted", "success")
       else
           if ActiveTools["Grav"] then ActiveTools["Grav"]:Destroy() end
           GravityGui.Enabled = false
           Crosshair.Visible = false
           Release()
           _G.EliteLog("Gravity Gun Removed", "warn")
       end
   end,
})
Tab:CreateToggle({
   Name = "Local Fire Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local t = Instance.new("Tool", LP.Backpack)
           t.Name = "Elite: Fire"
           t.RequiresHandle = false
           t.Activated:Connect(function() if Mouse.Target then Instance.new("Fire", Mouse.Target) end end)
           ActiveTools["Fire"] = t
       elseif ActiveTools["Fire"] then ActiveTools["Fire"]:Destroy() end
   end,
})

-- AUTOMATION
Tab:CreateSection("Automation")

local autouseOn = false
Tab:CreateToggle({
   Name = "Auto-Use Held Tool",
   CurrentValue = false,
   Callback = function(Value)
       autouseOn = Value
       _G.EliteLog("Auto-Use: " .. (Value and "Active" or "Inactive"), "info")
       task.spawn(function()
           while autouseOn do
               local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
               if tool then tool:Activate() end
               task.wait(0.1)
           end
       end)
   end,
})

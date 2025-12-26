-- Tool.lua - Elite-Utility-Hub
local LP = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Mouse = LP:GetMouse()
local Tab = _G.ToolTab

-- [ TOOL STORAGE ]
local ActiveTools = {}

-- [ HELPER: CREATE ELITE TOOL ]
local function CreateEliteTool(name, icon, callback)
    local tool = Instance.new("Tool")
    tool.Name = "Elite: " .. name
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ToolTip = "Elite-Utility-Hub Tool"
    
    tool.Activated:Connect(function()
        local success, err = pcall(callback)
        if not success then
            _G.EliteLog("Tool Error ("..name.."): "..tostring(err), "error")
        end
    end)
    
    return tool
end

-- [ ARCHITECT LOGIC ]
local function GiveBTools(Value)
    if Value then
        for i = 1, 4 do
            local hb = Instance.new("HopperBin")
            hb.BinType = i
            hb.Parent = LP.Backpack
            table.insert(ActiveTools, hb)
        end
        _G.EliteLog("Classic BTools Granted", "success")
    end
end

-- [ TACTICAL TP LOGIC ]
local function TeleportToMouse()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local target = Mouse.Hit.Position + Vector3.new(0, 3, 0)
        char.HumanoidRootPart.CFrame = CFrame.new(target)
        _G.EliteLog("Teleported to Mouse Position", "info")
    end
end

-- [ GRAVITY GUN LOGIC ]
local grabbing = false
local grabPart = nil
local function GravityGunLogic()
    if not grabbing then
        local target = Mouse.Target
        if target and not target.Anchored then
            grabbing = true
            grabPart = target
            local bg = Instance.new("BodyGyro", grabPart)
            local bp = Instance.new("BodyPosition", grabPart)
            bp.MaxForce = Vector3.new(1,1,1) * math.huge
            bp.P = 10000
            
            task.spawn(function()
                while grabbing and grabPart do
                    bp.Position = LP.Character.HumanoidRootPart.Position + (Mouse.Hit.LookVector * 15)
                    task.wait()
                end
                bg:Destroy()
                bp:Destroy()
            end)
        end
    else
        grabbing = false
        grabPart = nil
    end
end

-- [ UI CONSTRUCTION ]

-- 1. ARCHITECT SECTION
Tab:CreateSection("Architect Tools")

Tab:CreateToggle({
   Name = "Elite BTools",
   CurrentValue = false,
   Callback = function(Value)
       if Value then GiveBTools(true)
       else 
           for _, t in pairs(LP.Backpack:GetChildren()) do if t:IsA("HopperBin") then t:Destroy() end end
           _G.EliteLog("BTools Removed", "warn")
       end
   end,
})

Tab:CreateToggle({
   Name = "Local Deleter Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local tool = CreateEliteTool("Deleter", "", function()
               if Mouse.Target then 
                   _G.EliteLog("Locally Deleted: "..Mouse.Target.Name, "info")
                   Mouse.Target.Transparency = 1
                   Mouse.Target.CanCollide = false
               end
           end)
           tool.Parent = LP.Backpack
           ActiveTools["Deleter"] = tool
       else
           if ActiveTools["Deleter"] then ActiveTools["Deleter"]:Destroy() end
       end
   end,
})

-- 2. TACTICAL SECTION
Tab:CreateSection("Tactical Movement")

Tab:CreateToggle({
   Name = "Click TP Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local tool = CreateEliteTool("TP Tool", "", TeleportToMouse)
           tool.Parent = LP.Backpack
           ActiveTools["TP"] = tool
       else
           if ActiveTools["TP"] then ActiveTools["TP"]:Destroy() end
       end
   end,
})

-- 3. INTERACTION SECTION
Tab:CreateSection("Interaction Tools")

local reachEnabled = false
Tab:CreateToggle({
   Name = "Infinite Reach (Interaction)",
   CurrentValue = false,
   Callback = function(Value)
       reachEnabled = Value
       _G.EliteLog("Inf Reach: " .. (Value and "Enabled" or "Disabled"), "info")
       task.spawn(function()
           while reachEnabled do
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

-- 4. CHAOS SECTION
Tab:CreateSection("Physics & Fun")

Tab:CreateToggle({
   Name = "Gravity Gun",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local tool = CreateEliteTool("Gravity Gun", "", GravityGunLogic)
           tool.Parent = LP.Backpack
           ActiveTools["Grav"] = tool
       else
           if ActiveTools["Grav"] then ActiveTools["Grav"]:Destroy() end
       end
   end,
})

Tab:CreateToggle({
   Name = "Fire/Smoke Tool",
   CurrentValue = false,
   Callback = function(Value)
       if Value then
           local tool = CreateEliteTool("Effect Tool", "", function()
                if Mouse.Target then
                    local f = Instance.new("Fire", Mouse.Target)
                    f.Size = 5
                    _G.EliteLog("Applied Local Effect to "..Mouse.Target.Name, "info")
                end
           end)
           tool.Parent = LP.Backpack
           ActiveTools["Effect"] = tool
       else
           if ActiveTools["Effect"] then ActiveTools["Effect"]:Destroy() end
       end
   end,
})

-- 5. AUTOMATION SECTION
Tab:CreateSection("Server Utilities")

Tab:CreateToggle({
   Name = "Auto-Use Tool",
   CurrentValue = false,
   Callback = function(Value)
       _G.AutoUse = Value
       _G.EliteLog("Auto-Use "..(Value and "Enabled" or "Disabled"), "info")
       task.spawn(function()
           while _G.AutoUse do
               local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
               if tool then tool:Activate() end
               task.wait(0.1)
           end
       end)
   end,
})

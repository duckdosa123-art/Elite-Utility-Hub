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

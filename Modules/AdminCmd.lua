-- ELITE ADMIN COMMANDS (Force-Cleanup Enabled)
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LP:FindFirstChild("PlayerGui")

-- Helper function to wipe specific UI and reset character state
local function CleanAdminUI(names)
    task.spawn(function()
        -- 1. Destroy GUIs
        local targets = {CoreGui, PlayerGui}
        for _, parent in pairs(targets) do
            if parent then
                for _, child in pairs(parent:GetChildren()) do
                    for _, name in pairs(names) do
                        if child.Name:lower():find(name:lower()) then
                            child:Destroy()
                        end
                    end
                end
            end
        end
        
        -- 2. Reset Physics (Flushes active commands like Fly/Speed)
        local Hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if Hum then
            Hum.WalkSpeed = 16
            Hum.JumpPower = 50
            Hum.PlatformStand = false
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        _G.EliteLog("Admin Cleanup: State Reset", "info")
    end)
end

-- 1. INFINITE YIELD
Tab:CreateToggle({
   Name = "Infinite Yield",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading Infinite Yield...", "info")
          task.spawn(function()
              loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
          end)
      else
          CleanAdminUI({"InfiniteYield", "IY", "Cmdbar", "Notification"})
      end
   end,
})

-- 2. CMD-X
Tab:CreateToggle({
   Name = "CMD-X",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading CMD-X...", "info")
          task.spawn(function()
              loadstring(game:HttpGet('https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source', true))()
          end)
      else
          CleanAdminUI({"CMDX", "CMD-X"})
      end
   end,
})

-- 3. NAMELESS ADMIN
Tab:CreateToggle({
   Name = "Nameless Admin",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading Nameless...", "info")
          task.spawn(function()
              loadstring(game:HttpGet("https://raw.githubusercontent.com/Filter-90/Nameless-Admin/main/Source.lua"))()
          end)
      else
          CleanAdminUI({"NamelessAdmin", "AdminGui"})
      end
   end,
})

-- 4. DARK DEX V4
Tab:CreateToggle({
   Name = "Dark Dex V4",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading Dark Dex...", "info")
          task.spawn(function()
              loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDex.lua"))()
          end)
      else
          CleanAdminUI({"Dex", "DarkDex"})
      end
   end,
})

-- 5. SIMPLESPY
Tab:CreateToggle({
   Name = "SimpleSpy",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading SimpleSpy...", "info")
          task.spawn(function()
              loadstring(game:HttpGet("https://raw.githubusercontent.com/777777777777777777777777777777777777777/SimpleSpy/main/SimpleSpySource.lua"))()
          end)
      else
          CleanAdminUI({"SimpleSpy", "Spy"})
      end
   end,
})

-- 6. ADONIS BYPASS
Tab:CreateToggle({
   Name = "Adonis Bypass",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Applying Adonis Bypass...", "success")
          task.spawn(function()
              -- This is a standard universal bypass logic
              local old; old = hookmetamethod(game, "__namecall", function(self, ...)
                  local method = getnamecallmethod()
                  if method == "FireServer" and self.Name == "Adonis_Validation" then
                      return nil
                  end
                  return old(self, ...)
              end)
          end)
      else
          _G.EliteLog("Bypass cannot be safely undone without crash.", "error")
      end
   end,
})

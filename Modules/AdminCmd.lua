-- [[ ADMIN CMD MODULE: ELITE-UTILITY-HUB ]]
local Tab = _G.AdminTab
local LP = _G.LP
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LP:FindFirstChild("PlayerGui")

-- 1. ELITE BRUTE-FORCE DISABLER
-- This removes the UI and attempts to break the script's connection by destroying its container.
local function EliteBruteDisable(names)
    task.spawn(function()
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
        _G.EliteLog("Admin Brute-Forced Off", "warn")
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
          EliteBruteDisable({"InfiniteYield", "IY", "Cmdbar", "Notification"})
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
              loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source"))()
          end)
      else
          EliteBruteDisable({"CMDX", "CMD-X"})
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
              loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))()
          end)
      else
          EliteBruteDisable({"NamelessAdmin", "AdminGui"})
      end
   end,
})

-- 4. DARK DEX V4 (Corrected Bypassed Version)
Tab:CreateToggle({
   Name = "Dark Dex V4",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
          _G.EliteLog("Loading Dark Dex...", "info")
          task.spawn(function()
              -- Updated to the most reliable Bypassed V4 source
              loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDex.lua"))()
          end)
      else
          EliteBruteDisable({"Dex", "DarkDex"})
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
          EliteBruteDisable({"SimpleSpy", "Spy"})
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

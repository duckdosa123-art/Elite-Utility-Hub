-- [[ ADMIN CMD MODULE: ELITE-UTILITY-HUB ]]
local Tab = _G.AdminTab
local LP = _G.LP
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LP:FindFirstChild("PlayerGui")

-- 1. UTILITY: CLEAR ALL ADMIN UIs
-- This is useful since we are using buttons now.
Tab:CreateButton({
   Name = "Clear All Admin UIs",
   Callback = function()
      local names = {"InfiniteYield", "IY", "Cmdbar", "Notification", "CMDX", "CMD-X", "NamelessAdmin", "AdminGui", "Dex", "DarkDex", "SimpleSpy", "Spy"}
      task.spawn(function()
         local targets = {CoreGui, PlayerGui}
         for _, parent in pairs(targets) do
            if parent then
               for _, child in pairs(parent:GetChildren()) do
                  for _, name in pairs(names) do
                     if child.Name:lower():find(name:lower()) then child:Destroy() end
                  end
               end
            end
         end
         _G.EliteLog("Admin UIs Purged", "success")
      end)
   end,
})

Tab:CreateSection("Admin Scripts")

-- 1. INFINITE YIELD
Tab:CreateButton({
   Name = "Elite Infinite Yield",
   Callback = function()
      _G.EliteLog("Executing Infinite Yield...", "info")
      task.spawn(function()
         loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
      end)
   end,
})

-- 2. CMD-X
Tab:CreateButton({
   Name = "Elite CMD-X",
   Callback = function()
      _G.EliteLog("Executing CMD-X...", "info")
      task.spawn(function()
         loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source"))()
      end)
   end,
})

-- 3. NAMELESS ADMIN
Tab:CreateButton({
   Name = "Elite Nameless Admin",
   Callback = function()
      _G.EliteLog("Executing Nameless...", "info")
      task.spawn(function()
         loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))()
      end)
   end,
})

Tab:CreateSection("Developer Tools")

-- 4. DARK DEX V4 (Bypassed & Optimized)
Tab:CreateButton({
   Name = "Elite Dark Dex V4",
   Callback = function()
      _G.EliteLog("Executing Dark Dex...", "info")
      task.spawn(function()
         -- Using the Babyhamsta Bypassed source as it's the most stable for modern games
         loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDex.lua"))()
      end)
   end,
})

-- 5. SIMPLESPY V3 (Latest Stable)
Tab:CreateButton({
   Name = "Elite SimpleSpy",
   Callback = function()
      _G.EliteLog("Executing SimpleSpy...", "info")
      task.spawn(function()
         -- Corrected to the 2024/2025 maintained repository
         loadstring(game:HttpGet("https://raw.githubusercontent.com/777777777777777777777777777777777777777/SimpleSpy/main/SimpleSpySource.lua"))()
      end)
   end,
})

Tab:CreateSection("Bypasses")

-- 6. ADONIS BYPASS (Smart Hook)
Tab:CreateButton({
   Name = "Elite Adonis Bypass",
   Callback = function()
      _G.EliteLog("Injecting Adonis Bypass...", "success")
      task.spawn(function()
         -- Protection check to avoid double-hooking (prevents crashes)
         if _G.AdonisBypassed then 
            _G.EliteLog("Adonis already bypassed!", "warn")
            return 
         end
         
         local success, err = pcall(function()
            local old; old = hookmetamethod(game, "__namecall", function(self, ...)
               local method = getnamecallmethod()
               local args = {...}
               
               -- Block the specific validation remotes used by Adonis to flag players
               if method == "FireServer" and (self.Name == "Adonis_Validation" or self.Name == "\2\1\ADONIS_CHECK") then
                  return nil
               end
               
               return old(self, unpack(args))
            end)
         end)

         if success then
            _G.AdonisBypassed = true
            _G.EliteLog("Adonis Hook Successful", "success")
         else
            _G.EliteLog("Bypass Failed: Meta-Hook Error", "error")
         end
      end)
   end,
})

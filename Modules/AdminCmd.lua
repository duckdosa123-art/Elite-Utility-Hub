-- [[ ADMIN CMD MODULE: ELITE-UTILITY-HUB ]]
local Tab = _G.AdminTab
local LP = _G.LP
local CoreGui = game:GetService("CoreGui")
local PlayerGui = LP:FindFirstChild("PlayerGui")

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

-- 4. DARK DEX V4 (Updated Source)
Tab:CreateButton({
   Name = "Elite Dark Dex V4",
   Callback = function()
      _G.EliteLog("Executing Dark Dex...", "info")
      task.spawn(function()
         loadstring(game:HttpGet("https://raw.githubusercontent.com/memeenjoyer43/darkdex/refs/heads/main/script"))()
      end)
   end,
})

-- 5. SIMPLESPY (Updated Source)
Tab:CreateButton({
   Name = "Elite SimpleSpy",
   Callback = function()
      _G.EliteLog("Executing SimpleSpy...", "info")
      task.spawn(function()
         loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
      end)
   end,
})

Tab:CreateSection("Bypasses")

-- 6. ADONIS BYPASS (Advanced GC Hook)
Tab:CreateButton({
   Name = "Elite Adonis Bypass",
   Callback = function()
      _G.EliteLog("Injecting Adonis Anti-Crash...", "success")
      task.spawn(function()
         -- Load the adoniscries base bypass
         local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua"))()
            
            -- Brute-Force Hook bad functions via Garbage Collector
            local badFunctions = {"Crash", "HardCrash", "GPUCrash", "RAMCrash", "KillClient", "SetFPS"}
            
            for i, v in pairs(getgc()) do 
                if type(v) == "function" then
                    local info = debug.getinfo(v)
                    local functionName = info.name
                    
                    -- Detect and neutralize crash/lag functions from Adonis Core
                    if info.source:find('=.Core.Functions') and table.find(badFunctions, functionName) then
                        hookfunction(v, function()
                            _G.EliteLog("Blocked Adonis Attempt: " .. tostring(functionName), "warn")
                        end)
                    end
                end
            end
         end)

         if success then
            _G.EliteLog("Adonis Fully Neutralized", "success")
         else
            _G.EliteLog("Bypass Failed: " .. tostring(err), "error")
         end
      end)
   end,
})

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Elite-Utility-Hub",
   LoadingTitle = "Modular System Loading...",
   LoadingSubtitle = "by Ducky",
   Theme = "Default",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "EliteUtilHub",
      FileName = "MainConfig"
   }
})

-- 1. THE IMPROVED LOADER (Safety First)
local function LoadModule(FileName)
    local Repo = "https://raw.githubusercontent.com/duckdosa123-art/Elite-Utility-Hub/main/Modules/"
    local success, result = pcall(function()
        return game:HttpGet(Repo .. FileName)
    end)
    
    if success and result ~= "404: Not Found" then
        local func, err = loadstring(result)
        if func then
            return func()
        else
            warn("Elite-Hub: Syntax error in " .. FileName .. " | " .. tostring(err))
        end
    else
        warn("Elite-Hub: Could not find file on GitHub: " .. FileName)
        Rayfield:Notify({
            Title = "Module Error",
            Content = "Failed to load: " .. FileName .. ". Check GitHub path!",
            Duration = 5,
            Image = 4483362458,
        })
    end
end

-- 2. CREATE THE TABS
local MainTab = Window:CreateTab("Home", 4483362458) 
local MoveTab = Window:CreateTab("Movement", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local ToolTab = Window:createTab("Tools", 4483362458)
local LogTab = Window:CreateTab("Logs", 4483362458)
-- 3. CONNECT THE FILES (MUST be before LoadModule)
_G.MoveTab = MoveTab
_G.VisualTab = VisualTab
_G.MiscTab = MiscTab 
_G.ToolTab = ToolTab
_G.LogTab = LogTab

-- [ ELITE GLOBAL LOGGER ]
_G.EliteLogs = {} -- Stores all log strings
_G.EliteLog = function(msg, logType)
    local timestamp = os.date("%X") -- Gets current time (HH:MM:SS)
    local prefix = "⚪ INFO"
    
    if logType == "success" then prefix = "🟢 SUCCESS"
    elseif logType == "warn" then prefix = "🟡 WARN"
    elseif logType == "error" then prefix = "🔴 ERROR" end
    
    local formatted = string.format("[%s] %s: %s", timestamp, prefix, msg)
    table.insert(_G.EliteLogs, 1, formatted) -- Put newest log at top
    
    -- Limit to last 50 logs to prevent lag
    if #_G.EliteLogs > 50 then table.remove(_G.EliteLogs, 51) end
    
    -- Refresh the Log UI if the function exists
    if _G.UpdateLogUI then _G.UpdateLogUI() end
end

-- 4. RUN LOADER
LoadModule("Movement.lua")
LoadModule("Visual.lua")
LoadModule("Misc.lua") 
LoadModule("Tool.lua")
LoadModule("Log.lua")

_G.EliteLog("Elite-Utility-Hub Initialized", "success")

-- Welcome message
MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active. Modules Loaded."})

Rayfield:Notify({
   Title = "Hub Loaded!",
   Content = "All modules synced from GitHub.",
   Duration = 5,
   Image = 4483362458,
})

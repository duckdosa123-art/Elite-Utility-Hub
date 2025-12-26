local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield
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

-- 1. CREATE THE TABS
local MainTab = Window:CreateTab("Home", 4483362458) 
local MoveTab = Window:CreateTab("Movement", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local ToolTab = Window:CreateTab("Tools", 4483362458)
local AdminTab = Window:CreateTab("Admin and dev", 4483362458)
local LogTab = Window:CreateTab("Logs", 4483362458)

-- 2. EXPORT GLOBALS (The exact same way you had it)
_G.MainTab = MainTab
_G.MoveTab = MoveTab
_G.VisualTab = VisualTab
_G.MiscTab = MiscTab 
_G.ToolTab = ToolTab
_G.AdminTab = AdminTab
_G.LogTab = LogTab
_G.LP = game.Players.LocalPlayer

-- 3. ELITE GLOBAL LOGGER
_G.EliteLogs = {}
_G.EliteLog = function(msg, logType)
    local timestamp = os.date("%X")
    local prefix = (logType == "success" and "🟢 SUCCESS") or (logType == "warn" and "🟡 WARN") or (logType == "error" and "🔴 ERROR") or "⚪ INFO"
    table.insert(_G.EliteLogs, 1, string.format("[%s] %s: %s", timestamp, prefix, msg))
    if #_G.EliteLogs > 50 then table.remove(_G.EliteLogs, 51) end
    if _G.UpdateLogUI then _G.UpdateLogUI() end
end

-- 4. THE LOADER FUNCTION
local function LoadModule(FileName)
    local Repo = "https://raw.githubusercontent.com/duckdosa123-art/Elite-Utility-Hub/main/Modules/"
    local success, result = pcall(function()
        return game:HttpGet(Repo .. FileName)
    end)
    
    if success and result ~= "404: Not Found" then
        local func, err = loadstring(result)
        if func then
            task.spawn(func)
            return true
        else
            warn("Elite-Hub: Syntax error in " .. FileName .. " | " .. tostring(err))
        end
    else
        warn("Elite-Hub: Could not find file: " .. FileName)
    end
end

-- 5. RUN LOADER (In order)
LoadModule("Log.lua")
LoadModule("Movement.lua")
LoadModule("Visual.lua")
LoadModule("Misc.lua")
LoadModule("Tool.lua")
LoadModule("AdminCmd.lua")

_G.EliteLog("Elite-Utility-Hub Initialized", "success")

-- Welcome message
MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active. Modules Loaded."})

Rayfield:Notify({
   Title = "Hub Loaded!",
   Content = "All modules synced from GitHub.",
   Duration = 5,
   Image = 4483362458,
})

-- [[ ELITE-UTILITY-HUB: SMART LOADER (EXPANDED) ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 1. GLOBAL CONSTANTS
_G.LP = game:GetService("Players").LocalPlayer
_G.HttpService = game:GetService("HttpService")
_G.TeleportService = game:GetService("TeleportService")
_G.RunService = game:GetService("RunService")
_G.ActiveTools = {}

local Window = Rayfield:CreateWindow({
   Name = "Elite-Utility-Hub",
   LoadingTitle = "Modular System Loading...",
   LoadingSubtitle = "by Ducky",
   Theme = "Default",
   ConfigurationSaving = { Enabled = true, FolderName = "EliteUtilHub", FileName = "MainConfig" }
})

-- 2. CREATE TABS (Global Assignment)
_G.MainTab = Window:CreateTab("Home", 4483362458) 
_G.MoveTab = Window:CreateTab("Movement", 4483362458)
_G.VisualTab = Window:CreateTab("Visuals", 4483362458)
_G.MiscTab = Window:CreateTab("Misc", 4483362458)
_G.ToolTab = Window:CreateTab("Tools", 4483362458)
_G.FeTab = Window:CreateTab("FE Scripts", 4483362458) -- NEW
_G.TrollTab = Window:CreateTab("Troll", 4483362458)   -- NEW
_G.AdminTab = Window:CreateTab("Admin and dev", 4483362458)
_G.LogTab = Window:CreateTab("Logs", 4483362458)

-- 3. GLOBAL LOGGER
_G.EliteLogs = {} 
_G.EliteLog = function(msg, logType)
    local timestamp = os.date("%X")
    local prefix = (logType == "success" and "🟢 SUCCESS") or (logType == "warn" and "🟡 WARN") or (logType == "error" and "🔴 ERROR") or "⚪ INFO"
    table.insert(_G.EliteLogs, 1, string.format("[%s] %s: %s", timestamp, prefix, msg))
    if #_G.EliteLogs > 50 then table.remove(_G.EliteLogs, 51) end
    if _G.UpdateLogUI then _G.UpdateLogUI() end
end

-- 4. SMART INJECTION ENGINE
local ModuleMappings = {
    ["Movement.lua"] = "_G.MoveTab",
    ["Visual.lua"]   = "_G.VisualTab",
    ["Misc.lua"]     = "_G.MiscTab",
    ["Tool.lua"]     = "_G.ToolTab",
    ["Fescripts.lua"] = "_G.FeTab",    -- Mapped
    ["Troll.lua"]     = "_G.TrollTab",  -- Mapped
    ["AdminCmd.lua"] = "_G.AdminTab",
    ["Log.lua"]      = "_G.LogTab"
}

local function LoadModule(FileName)
    local Repo = "https://raw.githubusercontent.com/duckdosa123-art/Elite-Utility-Hub/main/Modules/"
    local success, result = pcall(function() return game:HttpGet(Repo .. FileName) end)
    
    if success and result ~= "404: Not Found" then
        local TabVar = ModuleMappings[FileName] or "_G.MainTab"
        
        -- Header Injects the local variables into the downloaded code
        local Header = string.format([[
            local Tab = %s;
            local LP = _G.LP;
            local ActiveTools = _G.ActiveTools;
            local TeleportService = _G.TeleportService;
            local RunService = _G.RunService;
            local HttpService = _G.HttpService;
            local Rayfield = _G.Rayfield;
        ]], TabVar)
        
        local FinalCode = Header .. result
        local func, err = loadstring(FinalCode)
        
        if func then
            task.spawn(function()
                local ok, runErr = pcall(func)
                if not ok then 
                    warn("Elite-Hub: Execution Error in " .. FileName .. " | " .. tostring(runErr))
                end
            end)
            return true
        else
            warn("Elite-Hub: Syntax Error in " .. FileName .. " | " .. tostring(err))
        end
    else
        warn("Elite-Hub: GitHub File Missing or 404: " .. FileName)
    end
    return false
end

-- 5. RUN LOADER (Sequential with Delays)
_G.Rayfield = Rayfield -- Export for modules
task.spawn(function()
    local modules = {
        "Log.lua", 
        "Movement.lua", 
        "Visual.lua", 
        "Misc.lua", 
        "Tool.lua", 
        "Fescripts.lua", -- Added to load sequence
        "Troll.lua",     -- Added to load sequence
        "AdminCmd.lua"
    }
    
    for _, moduleName in pairs(modules) do
        local ok = LoadModule(moduleName)
        if ok then
            task.wait(0.3) -- Delay for UI stability
        end
    end
    
    _G.EliteLog("Elite-Utility-Hub Fully Loaded", "success")
    _G.MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active."})
end)

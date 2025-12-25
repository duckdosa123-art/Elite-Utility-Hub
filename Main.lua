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

-- 1. THE LOADER FUNCTION
local function LoadModule(FileName)
    local Repo = "https://raw.githubusercontent.com/duckdosa123-art/Elite-Utility-Hub/main/Modules/"
    local success, result = pcall(function()
        return game:HttpGet(Repo .. FileName)
    end)
    
    if success then
        return loadstring(result)()
    else
        warn("Elite-Hub: Could not load " .. FileName)
    end
end

-- 2. CREATE THE TABS
local MainTab = Window:CreateTab("Home", 4483362458) 
local MoveTab = Window:CreateTab("Movement", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- 3. CONNECT THE FILES
_G.MoveTab = MoveTab
_G.VisualTab = VisualTab
_G.MiscTab = MiscTab -- Passed to Misc.lua

-- 4. RUN LOADER
LoadModule("Movement.lua")
LoadModule("Misc.lua") -- Now loading the Misc file

-- Welcome message
MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active. Modules Loaded."})

Rayfield:Notify({
   Title = "Hub Loaded!",
   Content = "All modules synced from GitHub.",
   Duration = 5,
   Image = 4483362458,
})

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
-- This allows us to pull code from your "Modules" folder
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
local MoveTab = Window:CreateTab("Movement", 4483362458) -- New tab for your movement file
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- 3. CONNECT THE FILES
-- We pass the Tab variables to the modules so they know where to put buttons
_G.MoveTab = MoveTab
_G.VisualTab = VisualTab
-G.MiscTab = MiscTab

-- This actually runs the code inside your Modules/Movement.lua
LoadModule("Movement.lua")
LoadModule("Misc.lua")

-- Welcome message
MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active. Modules Loaded."})

Rayfield:Notify({
   Title = "Hub Loaded!",
   Content = "All modules synced from GitHub.",
   Duration = 5,
   Image = 4483362458,
})

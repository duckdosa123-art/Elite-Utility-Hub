local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Elite-Utility-Hub",
   LoadingTitle = "UX Improvement Suite",
   LoadingSubtitle = "by Ducky",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "EliteUtilHub",
      FileName = "MainConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvite", 
      RememberJoins = true 
   }
})

-- Creating the Tabs
local MainTab = Window:CreateTab("Home", 4483362458) 
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Welcome message
MainTab:CreateParagraph({Title = "Welcome!", Content = "Elite-Utility-Hub is now active. Enjoy the optimized experience."})

Rayfield:Notify({
   Title = "Hub Loaded!",
   Content = "Successfully connected to GitHub.",
   Duration = 5,
   Image = 4483362458,
})

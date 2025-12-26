-- Log.lua - Elite-Utility-Hub
local Tab = _G.LogTab

-- Create the main console paragraph
local Console = Tab:CreateParagraph({
    Title = "Elite Hub Console Feed",
    Content = "Waiting for logs..."
})

-- The Refresh Function
_G.UpdateLogUI = function()
    local fullLog = table.concat(_G.EliteLogs, "\n")
    Console:Set({
        Title = "Elite Hub Console Feed",
        Content = fullLog
    })
end

-- UI Utilities for the Logs
Tab:CreateSection("Console Controls")

Tab:CreateButton({
    Name = "Clear Console",
    Callback = function()
        _G.EliteLogs = {}
        _G.EliteLog("Console Cleared", "info")
    end,
})

Tab:CreateButton({
    Name = "Copy All Logs",
    Callback = function()
        local fullLog = table.concat(_G.EliteLogs, "\n")
        setclipboard(fullLog)
        _G.EliteLog("Logs copied to clipboard", "success")
        
        -- Brute Force Roblox Notification
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Elite Logs",
            Text = "Full console history copied!",
            Duration = 3
        })
    end,
})

-- Initial Refresh
_G.UpdateLogUI()

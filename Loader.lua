-- Elite-Utility-Hub Bootstrapper
local github_url = "https://raw.githubusercontent.com/duckdosa123-art/Elite-Utility-Hub/main/Main.lua"

local success, result = pcall(function()
    return game:HttpGet(github_url)
end)

if success then
    loadstring(result)()
else
    warn("Elite-Utility-Hub failed to load: " .. tostring(result))
end

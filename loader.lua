repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local env = getgenv and getgenv() or _G
local repo = "https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/"
local uiUrl = "https://raw.githubusercontent.com/MMoonlights/UI/refs/heads/main/menus.lua"
local rootFolder = "FastSC-test"
local sourceCache = env.FastSCSourceCache or {}
env.FastSCSourceCache = sourceCache

local function localPath(path)
    return rootFolder .. "/" .. path
end

local function fetchUrl(url, key, ttl)
    local cached = sourceCache[key]
    local now = os.clock()
    if cached and now - cached.Time <= (ttl or 20) then
        return cached.Source
    end
    local lastError
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(result) == "string" and #result > 0 then
            sourceCache[key] = {Source = result, Time = now}
            return result
        end
        lastError = result
        if attempt < 3 then task.wait(0.2 * attempt) end
    end
    if cached and cached.Source then
        return cached.Source
    end
    error(lastError or ("Failed to fetch " .. url))
end

local function source(path)
    if isfile and readfile and isfile(localPath(path)) then
        return readfile(localPath(path))
    end
    return fetchUrl(repo .. path, "repo:" .. path, 15)
end

local function module(path)
    local chunk, errorMessage = loadstring(source(path), "@FastSC/" .. path)
    if not chunk then error(errorMessage) end
    return chunk()
end

local function loadUI()
    local ok, result = pcall(function()
        return loadstring(fetchUrl(uiUrl, "ui", 60), "@FastSC/UI")()
    end)
    if ok and result then return result end
    if isfile and readfile and isfile(localPath("vendor/menus.lua")) then
        local chunk, errorMessage = loadstring(readfile(localPath("vendor/menus.lua")), "@FastSC/UI")
        if not chunk then error(errorMessage) end
        return chunk()
    end
    error(result)
end

if env.FastSCState and env.FastSCState.Unload then
    pcall(env.FastSCState.Unload)
end

local Runtime = module("core/runtime.lua")
local Common = module("core/common.lua")
local Config = module("core/config.lua")
local Manifest = module("games/manifest.lua")
local Menu = loadUI()
local entry = Manifest.Find(game.PlaceId)
local scope = Runtime.new("root")

Config.Load()

local window = Menu:CreateWindow({
    Title = entry and ("FastSC  |  " .. entry.Name) or "FastSC  |  Unsupported",
    Size = Vector2.new(620, 450),
    ToggleKey = Enum.KeyCode.RightShift,
    Logo = "F",
})

local state = {
    Scope = scope,
    Window = window,
    Entry = entry,
    Config = Config,
}

function state.Unload()
    pcall(Config.Flush)
    if state.GameScope then pcall(function() state.GameScope:Destroy() end) end
    pcall(function() scope:Destroy() end)
    pcall(function() window:Destroy() end)
    if env.FastSCState == state then env.FastSCState = nil end
end

env.FastSCState = state

local function reload()
    state.Unload()
    sourceCache["repo:loader.lua"] = nil
    local chunk, errorMessage = loadstring(source("loader.lua"), "@FastSC/loader.lua")
    if not chunk then error(errorMessage) end
    chunk()
end

local home = window:CreateTab("Home", "F")
home:CreateSection("Session")
home:CreateLabel(entry and ("Detected: " .. entry.Name) or ("Unsupported PlaceId: " .. tostring(game.PlaceId)))
home:CreateLabel("PlaceId: " .. tostring(game.PlaceId))
home:CreateLabel("RightShift toggles the menu")
home:CreateButton("Reload FastSC", reload)
home:CreateButton("Unload", state.Unload)

local settings = window:CreateTab("Settings", "S")
settings:CreateSection("Loader")
settings:CreateToggle("Teleport reinject", Config.Get("TeleportReinject", true), function(value)
    Config.Set("TeleportReinject", value)
end)
settings:CreateButton("Clear source cache", function()
    table.clear(sourceCache)
    Common.Notify("FastSC", "Source cache cleared", 3)
end)
settings:CreateLabel("Remote sources use retry and a short cache; stale cached source is used only when fetching fails")

local queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue and Config.Get("TeleportReinject", true) then
    pcall(queue, 'loadstring(game:HttpGet("' .. repo .. 'loader.lua"))()')
end

if entry then
    local gameScope = Runtime.new(entry.Slug)
    state.GameScope = gameScope
    local context = {
        Window = window,
        Scope = gameScope,
        Runtime = Runtime,
        Common = Common,
        Config = Config,
        Entry = entry,
        Repo = repo,
        Reload = reload,
    }
    local ok, result = pcall(function()
        local gameModule = module("games/" .. entry.Slug .. "/script.lua")
        return gameModule(context)
    end)
    if not ok then
        Common.Notify("FastSC", "Module error: " .. tostring(result), 8)
        home:CreateLabel("Module error: " .. tostring(result))
    end
else
    home:CreateSection("Supported games")
    for _, gameEntry in ipairs(Manifest.Games) do
        home:CreateLabel(gameEntry.Name .. "  |  " .. table.concat(gameEntry.PlaceIds, ", "))
    end
end

return state

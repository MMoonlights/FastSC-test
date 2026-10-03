repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local env = getgenv and getgenv() or _G
local repo = "https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/"
local uiUrl = "https://raw.githubusercontent.com/MMoonlights/UI/refs/heads/main/menus.lua"
local rootFolder = "FastSC-test"

local function localPath(path)
    return rootFolder .. "/" .. path
end

local function source(path)
    if isfile and readfile and isfile(localPath(path)) then
        return readfile(localPath(path))
    end
    return game:HttpGet(repo .. path)
end

local function module(path)
    local chunk, errorMessage = loadstring(source(path), "@FastSC/" .. path)
    if not chunk then error(errorMessage) end
    return chunk()
end

local function loadUI()
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(uiUrl), "@FastSC/UI")()
    end)
    if ok and result then return result end
    if isfile and readfile and isfile(localPath("vendor/menus.lua")) then
        return loadstring(readfile(localPath("vendor/menus.lua")), "@FastSC/UI")()
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
}

function state.Unload()
    if state.GameScope then pcall(function() state.GameScope:Destroy() end) end
    pcall(function() scope:Destroy() end)
    pcall(function() window:Destroy() end)
    if env.FastSCState == state then env.FastSCState = nil end
end

env.FastSCState = state

local home = window:CreateTab("Home", "F")
home:CreateSection("Session")
home:CreateLabel(entry and ("Detected: " .. entry.Name) or ("Unsupported PlaceId: " .. tostring(game.PlaceId)))
home:CreateLabel("PlaceId: " .. tostring(game.PlaceId))
home:CreateLabel("RightShift toggles the menu")
home:CreateButton("Reload FastSC", function()
    state.Unload()
    loadstring(source("loader.lua"), "@FastSC/loader.lua")()
end)
home:CreateButton("Unload", function()
    state.Unload()
end)

local settings = window:CreateTab("Settings", "S")
settings:CreateSection("Loader")
settings:CreateToggle("Teleport reinject", Config.Get("TeleportReinject", true), function(value)
    Config.Set("TeleportReinject", value)
end)
settings:CreateLabel("The teleport queue is refreshed every run when the executor supports it")

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
        Reload = function()
            state.Unload()
            loadstring(source("loader.lua"), "@FastSC/loader.lua")()
        end,
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

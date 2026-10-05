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
    if cached and cached.Source then return cached.Source end
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
        return loadstring(fetchUrl(uiUrl, "ui:v3", 60), "@FastSC/UI")()
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
local Telemetry = module("core/telemetry.lua")
local Manifest = module("games/manifest.lua")
local Menu = loadUI()
local scope = Runtime.new("root")

Config.Load()
Telemetry.Init(Config)
env.FastSCFeatureEvent = function(name) Telemetry.Feature(name) end

local options = type(env.FastSCOptions) == "table" and env.FastSCOptions or {}
local autoExecute = options.AutoExecute
if autoExecute == nil then autoExecute = options.AutoPlace end
if autoExecute == nil then autoExecute = env.AutoExecute end
if autoExecute == nil then autoExecute = env.AutoPlace end
if autoExecute == nil then autoExecute = Config.Get("AutoExecute", Config.Get("AutoPlace", true)) end

local detectMethod = options.Detect or Config.Get("DetectMethod", "Auto")
local forcedSlug = options.Game or options.Slug
local themeName = Config.Get("Theme", "Crimson")
local menuKeyName = Config.Get("MenuKey", "RightShift")
local menuKey = Enum.KeyCode[menuKeyName] or Enum.KeyCode.RightShift

local teleportQueue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
local tpHandlerQueued = false
local tpHandlerCode = [=[
local enabled = true
pcall(function()
    if isfile and readfile and isfile("FastSC/config.json") then
        local raw = readfile("FastSC/config.json")
        local decoded = game:GetService("HttpService"):JSONDecode(raw)
        local global = type(decoded) == "table" and (decoded.Global or decoded) or nil
        if type(global) == "table" then
            local value = global.TPHandler
            if value == nil then value = global.TeleportReinject end
            if value == false then enabled = false end
        end
    end
end)
if enabled then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
end
]=]

local function queueTpHandler()
    if not teleportQueue or tpHandlerQueued then return teleportQueue ~= nil end
    local ok = pcall(teleportQueue, tpHandlerCode)
    if ok then tpHandlerQueued = true end
    return ok
end

Menu:SetTheme(themeName)

local detectedEntry, detectedBy = Manifest.Find(game.PlaceId, game.GameId, detectMethod)
local window = Menu:CreateWindow({
    Title = "FastSC",
    Size = Vector2.new(620, 450),
    ToggleKey = menuKey,
    Logo = "F",
    Theme = themeName,
})

local state = {
    Scope = scope,
    Window = window,
    Entry = nil,
    Mode = nil,
    DetectedEntry = detectedEntry,
    DetectedBy = detectedBy,
    Config = Config,
}

local function destroyGameScope()
    if state.GameScope then
        pcall(function() state.GameScope:Destroy() end)
        state.GameScope = nil
    end
end

function state.Unload()
    pcall(Config.Flush)
    destroyGameScope()
    pcall(function() scope:Destroy() end)
    pcall(function() window:Destroy() end)
    if env.FastSCState == state then env.FastSCState = nil end
    if env.FastSCFeatureEvent then env.FastSCFeatureEvent = nil end
end

env.FastSCState = state

local function reloadLoader()
    state.Unload()
    sourceCache["repo:loader.lua"] = nil
    local chunk, errorMessage = loadstring(source("loader.lua"), "@FastSC/loader.lua")
    if not chunk then error(errorMessage) end
    chunk()
end

local showChooser
local loadGame

local function createSettings(entry)
    local settings = window:CreateTab("Settings", "S")
    local feedbackText = ""
    local consent = Telemetry.GetConsent()

    settings:CreateSection("Interface")
    local activeKey = window:GetToggleKey()
    settings:CreateKeybind("Menu bind", activeKey, function(key)
        if key and key ~= activeKey then
            activeKey = key
            window:SetToggleKey(key)
            Config.Set("MenuKey", key.Name)
        end
    end)
    settings:CreateDropdown("Theme", Menu:GetThemes(), window:GetTheme(), function(value)
        Config.Set("Theme", value)
        window:SetTheme(value)
    end)

    settings:CreateSection("Startup")
    settings:CreateToggle("Auto Execute", Config.Get("AutoExecute", autoExecute), function(value)
        autoExecute = value
        Config.Set("AutoExecute", value)
    end)
    settings:CreateToggle("TP Handler", Config.Get("TPHandler", Config.Get("TeleportReinject", true)), function(value)
        Config.Set("TPHandler", value)
        if value then queueTpHandler() end
    end)

    settings:CreateSection("Privacy")
    local telemetryToggle
    telemetryToggle = settings:CreateToggle("Anonymous telemetry", consent == true, function(value)
        Telemetry.SetConsent(value)
        if value then
            Telemetry.Inject()
            Telemetry.Module(entry)
            Common.Notify("FastSC", "Anonymous telemetry enabled", 4)
        else
            Common.Notify("FastSC", "Anonymous telemetry disabled", 4)
        end
    end)
    if consent == nil then
        settings:CreateLabel("Telemetry is OFF until you choose. Sends executor, country, game/map and aggregate feature usage. No HWID, username or raw IP.")
        settings:CreateButton("Allow telemetry", function()
            Telemetry.SetConsent(true)
            telemetryToggle:Set(true)
        end)
        settings:CreateButton("Decline telemetry", function()
            Telemetry.SetConsent(false)
            telemetryToggle:Set(false)
        end)
    end

    settings:CreateSection("Feedback")
    settings:CreateInput("Feedback", "Write feedback...", function(value)
        feedbackText = tostring(value or "")
    end, true)
    settings:CreateButton("Send Feedback", function()
        task.spawn(function()
            local ok, message = Telemetry.Feedback(feedbackText)
            Common.Notify("FastSC", message, ok and 4 or 6)
        end)
    end)

    settings:CreateSection("Actions")
    settings:CreateButton("Choose game", function()
        showChooser()
    end)
    settings:CreateButton("Reload", function()
        loadGame(entry)
    end)
    settings:CreateButton("Unload", state.Unload)
end

loadGame = function(entry)
    destroyGameScope()
    window:ClearTabs()
    local effectiveMode = (entry.Slug == "piggy" or entry.Slug == "piggy-intercity") and "Rage" or "Default"
    state.Entry = entry
    state.Mode = effectiveMode
    Telemetry.SetEntry(entry)
    window:SetTitle("FastSC  |  " .. entry.Name)

    local gameScope = Runtime.new(entry.Slug)
    state.GameScope = gameScope
    local context = {
        Window = window,
        Scope = gameScope,
        Runtime = Runtime,
        Common = Common,
        Config = Config,
        Telemetry = Telemetry,
        Entry = entry,
        Mode = effectiveMode,
        Repo = repo,
        ReturnToChooser = function()
            showChooser()
        end,
        ReturnToModes = function()
            showChooser()
        end,
        Reload = function()
            loadGame(entry)
        end,
    }

    local ok, result = pcall(function()
        local gameModule = module("games/" .. entry.Slug .. "/script.lua")
        return gameModule(context)
    end)

    createSettings(entry)
    if Telemetry.IsEnabled() then Telemetry.Module(entry) end

    if not ok then
        local errorTab = window:CreateTab("Error", "!")
        errorTab:CreateSection("Module")
        errorTab:CreateLabel(tostring(result))
        Common.Notify("FastSC", "Module error: " .. tostring(result), 8)
    end
end

showChooser = function()
    destroyGameScope()
    window:ClearTabs()
    state.Entry = nil
    state.Mode = nil
    window:SetTitle("FastSC  |  Choose")

    local chooser = window:CreateTab("Choose", "F")
    chooser:CreateSection("Detected")
    chooser:CreateLabel("PlaceId: " .. tostring(game.PlaceId))
    chooser:CreateLabel("GameId / Universe: " .. tostring(game.GameId))
    chooser:CreateLabel(detectedEntry and ("Detected: " .. detectedEntry.Name .. " via " .. tostring(detectedBy)) or "Detected: unsupported")
    chooser:CreateSection("Games")
    for _, gameEntry in ipairs(Manifest.Games) do
        chooser:CreateButton(gameEntry.Name, function()
            loadGame(gameEntry)
        end)
    end
end

local initialEntry = forcedSlug and Manifest.Get(forcedSlug) or detectedEntry

if Telemetry.IsEnabled() then Telemetry.Inject() end

if autoExecute and initialEntry then
    loadGame(initialEntry)
else
    showChooser()
end

if Config.Get("TPHandler", Config.Get("TeleportReinject", true)) then
    queueTpHandler()
end

return state

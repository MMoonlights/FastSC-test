local Config = {}

local HttpService = game:GetService("HttpService")
local folder = "FastSC"
local file = folder .. "/config.json"
local version = 2
local data = {Version = version, Global = {}, Games = {}}
local dirty = false
local saveGeneration = 0

local function ensureFolder()
    if makefolder and isfolder and not isfolder(folder) then
        pcall(makefolder, folder)
    end
end

local function normalize(decoded)
    if type(decoded) ~= "table" then
        return {Version = version, Global = {}, Games = {}}
    end
    if type(decoded.Global) == "table" or type(decoded.Games) == "table" then
        decoded.Version = version
        decoded.Global = type(decoded.Global) == "table" and decoded.Global or {}
        decoded.Games = type(decoded.Games) == "table" and decoded.Games or {}
        return decoded
    end
    local migrated = {Version = version, Global = {}, Games = {}}
    for key, value in pairs(decoded) do
        if key ~= "Version" then
            migrated.Global[key] = value
        end
    end
    return migrated
end

function Config.Load()
    ensureFolder()
    if isfile and readfile and isfile(file) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(file))
        end)
        if ok then
            data = normalize(decoded)
        end
    end
    return data
end

function Config.Flush()
    if not dirty or not writefile then return false end
    ensureFolder()
    local ok = pcall(function()
        writefile(file, HttpService:JSONEncode(data))
    end)
    if ok then dirty = false end
    return ok
end

local function scheduleSave()
    dirty = true
    saveGeneration += 1
    local generation = saveGeneration
    task.delay(0.3, function()
        if generation == saveGeneration then
            Config.Flush()
        end
    end)
end

function Config.Get(key, default)
    local value = data.Global[key]
    if value == nil then return default end
    return value
end

function Config.Set(key, value)
    data.Global[key] = value
    scheduleSave()
    return value
end

function Config.GetGame(slug, key, default)
    local gameData = data.Games[slug]
    local value = gameData and gameData[key]
    if value == nil then return default end
    return value
end

function Config.SetGame(slug, key, value)
    local gameData = data.Games[slug]
    if not gameData then
        gameData = {}
        data.Games[slug] = gameData
    end
    gameData[key] = value
    scheduleSave()
    return value
end

function Config.ResetGame(slug)
    data.Games[slug] = nil
    scheduleSave()
end

function Config.All()
    return data
end

return Config

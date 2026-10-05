local Telemetry = {}

local HttpService = game:GetService("HttpService")
local endpoint = "https://webc-livid.vercel.app/api/fastsc"
local requestHttp = request or http_request or (syn and syn.request)
local config
local currentEntry
local currentMap = ""
local version = "2026.10.05"
local featureCooldown = {}

local function executorName()
    local ok, a, b = pcall(function()
        if identifyexecutor then return identifyexecutor() end
        if getexecutorname then return getexecutorname() end
        return "Unknown"
    end)
    if not ok then return "Unknown" end
    if b and tostring(b) ~= "" then
        return tostring(a) .. " " .. tostring(b)
    end
    return tostring(a or "Unknown")
end

local function post(path, payload)
    if not requestHttp then return false end
    local ok, result = pcall(requestHttp, {
        Url = endpoint .. path,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload),
    })
    return ok and result and tonumber(result.StatusCode) and result.StatusCode >= 200 and result.StatusCode < 300
end

local function enabled()
    return config and config.Get("TelemetryConsent", nil) == true
end

local function basePayload()
    return {
        executor = executorName(),
        game = currentEntry and currentEntry.Name or "Loader",
        slug = currentEntry and currentEntry.Slug or "",
        map = currentMap,
        version = version,
        placeId = tostring(game.PlaceId),
    }
end

function Telemetry.Init(Config)
    config = Config
end

function Telemetry.IsEnabled()
    return enabled()
end

function Telemetry.GetConsent()
    if not config then return nil end
    return config.Get("TelemetryConsent", nil)
end

function Telemetry.SetConsent(value)
    if not config then return end
    config.Set("TelemetryConsent", value == true)
end

function Telemetry.SetEntry(entry)
    currentEntry = entry
end

function Telemetry.SetMap(name)
    currentMap = tostring(name or "")
end

function Telemetry.Inject()
    if not enabled() then return end
    local payload = basePayload()
    payload.type = "inject"
    task.spawn(post, "/telemetry", payload)
end

function Telemetry.Module(entry, mapName)
    currentEntry = entry or currentEntry
    currentMap = tostring(mapName or currentMap or "")
    if not enabled() then return end
    local payload = basePayload()
    payload.type = "module"
    task.spawn(post, "/telemetry", payload)
end

function Telemetry.Feature(name)
    if not enabled() then return end
    name = tostring(name or ""):sub(1, 120)
    if name == "" then return end
    local now = os.clock()
    if featureCooldown[name] and now - featureCooldown[name] < 1.5 then return end
    featureCooldown[name] = now
    local payload = basePayload()
    payload.type = "feature"
    payload.feature = name
    task.spawn(post, "/telemetry", payload)
end

function Telemetry.Feedback(message)
    message = tostring(message or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #message < 2 then return false, "Feedback is too short" end
    if #message > 2000 then message = message:sub(1, 2000) end
    local payload = basePayload()
    payload.message = message
    local ok = post("/feedback", payload)
    return ok, ok and "Feedback sent" or "Failed to send feedback"
end

return Telemetry

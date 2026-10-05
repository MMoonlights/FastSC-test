local Telemetry = {}

local HttpService = game:GetService("HttpService")
local env = getgenv and getgenv() or _G
local endpoint = env.FastSCTelemetryEndpoint or "https://fastscript-mmoonlight.vercel.app/api"
local requestHttp = request or http_request or (syn and syn.request)
local config
local currentEntry
local currentMap = ""
local version = "2026.10.05"
local featureCooldown = {}
local sessionToken
local sessionUntil = 0

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

local function responseBody(result)
    if type(result) ~= "table" then return nil end
    return result.Body or result.body or result.ResponseBody
end

local function statusCode(result)
    if type(result) ~= "table" then return 0 end
    return tonumber(result.StatusCode or result.Status or result.status_code or result.status) or 0
end

local function getSession(force)
    if not requestHttp then return nil end
    if not force and sessionToken and os.clock() < sessionUntil then
        return sessionToken
    end

    local ok, result = pcall(requestHttp, {
        Url = endpoint .. "/session",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-FastSC-Client"] = "luau-1",
        },
        Body = "{}",
    })
    if not ok or statusCode(result) < 200 or statusCode(result) >= 300 then
        sessionToken = nil
        sessionUntil = 0
        return nil
    end

    local raw = responseBody(result)
    if type(raw) ~= "string" or raw == "" then return nil end

    local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not decodedOk or type(decoded) ~= "table" or type(decoded.token) ~= "string" then
        return nil
    end

    sessionToken = decoded.token
    local expiresIn = tonumber(decoded.expiresIn) or 900
    sessionUntil = os.clock() + math.max(30, expiresIn - 20)
    return sessionToken
end

local function post(path, payload, retry)
    if not requestHttp then return false end
    local token = getSession(false)
    if not token then return false end

    local ok, result = pcall(requestHttp, {
        Url = endpoint .. path,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. token,
            ["X-FastSC-Client"] = "luau-1",
        },
        Body = HttpService:JSONEncode(payload),
    })
    if not ok then return false end

    local status = statusCode(result)
    if (status == 401 or status == 403) and retry ~= false then
        sessionToken = nil
        sessionUntil = 0
        if getSession(true) then
            return post(path, payload, false)
        end
    end

    return status >= 200 and status < 300
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
    if value ~= true then
        sessionToken = nil
        sessionUntil = 0
    end
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

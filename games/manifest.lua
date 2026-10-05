local games = {
    {Name = "Da Hood", Slug = "da-hood", PlaceIds = {2788229376}, UniverseIds = {1008451066}, Modes = {"Default"}},
    {Name = "Piggy", Slug = "piggy", PlaceIds = {4623386862, 5661005779}, UniverseIds = {1516533665}, Modes = {"Default"}},
    {Name = "Piggy: Intercity", Slug = "piggy-intercity", PlaceIds = {86852362398411, 94110244708490}, UniverseIds = {10000918243, 10058633242}, Modes = {"Default"}},
    {Name = "Arsenal", Slug = "arsenal", PlaceIds = {286090429}, UniverseIds = {111958650}, Modes = {"Default"}},
    {Name = "Murder Mystery 2", Slug = "mm2", PlaceIds = {142823291}, UniverseIds = {66654135}, Modes = {"Default"}},
    {Name = "Build A Boat For Treasure", Slug = "babft", PlaceIds = {537413528}, UniverseIds = {210851291}, Modes = {"Default"}},
    {Name = "Legends of Speed", Slug = "legends-of-speed", PlaceIds = {3101667897}, UniverseIds = {1119466531}, Modes = {"Default"}},
    {Name = "Break In", Slug = "break-in", PlaceIds = {3851622790, 4620170611}, UniverseIds = {1318971886}, Modes = {"Default"}},
    {Name = "RIVALS", Slug = "rivals", PlaceIds = {17625359962}, UniverseIds = {6035872082}, Modes = {"Default"}},
    {Name = "Blade Ball", Slug = "blade-ball", PlaceIds = {13772394625, 16281300371}, UniverseIds = {4777817887}, Modes = {"Default"}},
    {Name = "Dead Rails", Slug = "dead-rails", PlaceIds = {70876832253163}, UniverseIds = {7018190066}, Modes = {"Default"}},
    {Name = "Ink Game", Slug = "ink-game", PlaceIds = {99567941238278, 125009265613167}, UniverseIds = {7008097940}, Modes = {"Default"}},
}

local byPlaceId = {}
local byUniverseId = {}
local bySlug = {}

for _, entry in ipairs(games) do
    bySlug[entry.Slug] = entry
    for _, placeId in ipairs(entry.PlaceIds) do
        byPlaceId[placeId] = entry
    end
    for _, universeId in ipairs(entry.UniverseIds or {}) do
        byUniverseId[universeId] = entry
    end
end

local Manifest = {
    Games = games,
    ByPlaceId = byPlaceId,
    ByUniverseId = byUniverseId,
    BySlug = bySlug,
}

function Manifest.Find(placeId, gameId, method)
    method = method or "Auto"
    if method == "PlaceId" then
        return byPlaceId[placeId], byPlaceId[placeId] and "PlaceId" or nil
    end
    if method == "GameId" or method == "Universe" then
        return byUniverseId[gameId], byUniverseId[gameId] and "GameId" or nil
    end
    local entry = byPlaceId[placeId]
    if entry then return entry, "PlaceId" end
    entry = byUniverseId[gameId]
    if entry then return entry, "GameId" end
    return nil
end

function Manifest.Get(slug)
    return bySlug[slug]
end

function Manifest.HasMode(entry, mode)
    return entry and table.find(entry.Modes or {"Default"}, mode) ~= nil
end

return Manifest

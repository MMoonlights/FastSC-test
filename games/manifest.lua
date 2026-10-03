local games = {
    {Name = "Da Hood", Slug = "da-hood", PlaceIds = {2788229376}},
    {Name = "Piggy", Slug = "piggy", PlaceIds = {4623386862, 5661005779}},
    {Name = "Arsenal", Slug = "arsenal", PlaceIds = {286090429}},
    {Name = "Murder Mystery 2", Slug = "mm2", PlaceIds = {142823291}},
    {Name = "Build A Boat For Treasure", Slug = "babft", PlaceIds = {537413528}},
    {Name = "Legends of Speed", Slug = "legends-of-speed", PlaceIds = {3101667897}},
    {Name = "Break In", Slug = "break-in", PlaceIds = {3851622790, 4620170611}},
    {Name = "RIVALS", Slug = "rivals", PlaceIds = {17625359962}},
    {Name = "Blade Ball", Slug = "blade-ball", PlaceIds = {13772394625, 16281300371}},
    {Name = "Dead Rails", Slug = "dead-rails", PlaceIds = {70876832253163}},
    {Name = "Ink Game", Slug = "ink-game", PlaceIds = {99567941238278, 125009265613167}},
}

local byPlaceId = {}
for _, entry in ipairs(games) do
    for _, placeId in ipairs(entry.PlaceIds) do
        byPlaceId[placeId] = entry
    end
end

local Manifest = {
    Games = games,
    ByPlaceId = byPlaceId,
}

function Manifest.Find(placeId)
    return byPlaceId[placeId]
end

return Manifest

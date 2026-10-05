export const supportedGames = [
  { name: "Da Hood", slug: "da-hood", placeIds: ["2788229376"], universeIds: ["1008451066"] },
  { name: "Piggy", slug: "piggy", placeIds: ["4623386862", "5661005779"], universeIds: ["1516533665"] },
  { name: "Piggy: Intercity", slug: "piggy-intercity", placeIds: ["86852362398411", "94110244708490"], universeIds: ["10000918243", "10058633242"] },
  { name: "Arsenal", slug: "arsenal", placeIds: ["286090429"], universeIds: ["111958650"] },
  { name: "Murder Mystery 2", slug: "mm2", placeIds: ["142823291"], universeIds: ["66654135"] },
  { name: "Build A Boat For Treasure", slug: "babft", placeIds: ["537413528"], universeIds: ["210851291"] },
  { name: "Legends of Speed", slug: "legends-of-speed", placeIds: ["3101667897"], universeIds: ["1119466531"] },
  { name: "Break In", slug: "break-in", placeIds: ["3851622790", "4620170611"], universeIds: ["1318971886"] },
  { name: "RIVALS", slug: "rivals", placeIds: ["17625359962"], universeIds: ["6035872082"] },
  { name: "Blade Ball", slug: "blade-ball", placeIds: ["13772394625", "16281300371"], universeIds: ["4777817887"] },
  { name: "Dead Rails", slug: "dead-rails", placeIds: ["70876832253163"], universeIds: ["7018190066"] },
  { name: "Ink Game", slug: "ink-game", placeIds: ["99567941238278", "125009265613167"], universeIds: ["7008097940"] },
];

const bySlug = new Map(supportedGames.map((game) => [game.slug, game]));
const byPlace = new Map();
for (const game of supportedGames) {
  for (const placeId of game.placeIds) byPlace.set(placeId, game);
}

export function findGame(value) {
  if (value === null || value === undefined) return null;
  const raw = String(value).trim();
  if (!raw) return null;
  const lower = raw.toLowerCase();
  if (bySlug.has(lower)) return bySlug.get(lower);
  if (byPlace.has(raw)) return byPlace.get(raw);
  return supportedGames.find((game) => game.name.toLowerCase() === lower) || null;
}

export function findGameByPlace(placeId) {
  return byPlace.get(String(placeId)) || null;
}

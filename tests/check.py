from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]

expected = [
    "loader.lua",
    "autoexec.lua",
    "core/runtime.lua",
    "core/common.lua",
    "core/config.lua",
    "games/manifest.lua",
    "games/da-hood/script.lua",
    "games/piggy/script.lua",
    "games/piggy-intercity/script.lua",
    "games/arsenal/script.lua",
    "games/mm2/script.lua",
    "games/babft/script.lua",
    "games/legends-of-speed/script.lua",
    "games/break-in/script.lua",
    "games/rivals/script.lua",
    "games/blade-ball/script.lua",
    "games/dead-rails/script.lua",
    "games/ink-game/script.lua",
]

texts = {}
for path in expected:
    target = root / path
    assert target.is_file(), path
    text = target.read_text(encoding="utf-8")
    texts[path] = text
    assert "--" not in text, f"comment found in {path}"
    assert not re.search(r"\b[uvp]\d{2,}\b", text), f"decompiler identifier in {path}"
    assert "saffT4frame" not in text, f"stale typo in {path}"

manifest = texts["games/manifest.lua"]
for place_id in [
    2788229376,
    4623386862,
    5661005779,
    86852362398411,
    94110244708490,
    286090429,
    142823291,
    537413528,
    3101667897,
    3851622790,
    4620170611,
    17625359962,
    13772394625,
    16281300371,
    70876832253163,
    99567941238278,
    125009265613167,
]:
    assert str(place_id) in manifest, place_id

for token in [
    "UniverseIds",
    "ByUniverseId",
    'Modes = {"Legit", "Rage"}',
    "10000918243",
    "1516533665",
    "function Manifest.Find(placeId, gameId, method)",
]:
    assert token in manifest, token

loader = texts["loader.lua"]
for token in [
    "queue_on_teleport",
    "MMoonlights/UI",
    "games/",
    "FastSCSourceCache",
    "Config.Flush",
    "FastSCOptions",
    "AutoPlace",
    "AutoMode",
    "game.GameId",
    "ClearTabs",
    "Return to choose game",
    "CreateKeybind",
    "Menu:GetThemes",
    "DetectMethod",
]:
    assert token in loader, token

runtime = texts["core/runtime.lua"]
for token in [
    "PropertyRestores",
    "task.cancel",
    "HookNamecall",
    "function Scope:Restore(",
]:
    assert token in runtime, token

common = texts["core/common.lua"]
assert "CreateDescendantCache" in common

config = texts["core/config.lua"]
for token in ["scheduleSave", "GetGame", "SetGame"]:
    assert token in config, token

piggy = texts["games/piggy/script.lua"]
for token in [
    'ctx.Mode or "Legit"',
    "ItemPickupScript",
    "Item ESP",
    "Auto Object / Full run",
    "Auto grab items",
    "Trap bypass",
    "Freeze Piggy / bots",
    'character:FindFirstChild("Enemy")',
    'workspace:FindFirstChild("PiggyNPC")',
    "RunService.PreSimulation",
    "if not godMode then return end",
    "setCharacterTouch(true)",
    "underPiggyFolder",
    "God mode",
    "displayNames",
    "signatureId",
    "itemDisplayName",
    "456878024",
    "16198309",
    "16884681",
    "524706126",
    "Objective Helper",
    "collectObjectives",
    "targetNames",
    "Current objective:",
    "Items needed:",
    "autoEscapeStep",
    "equipRequired",
    "activateObjective",
    "objectiveCooldowns",
    "disableEnemyTouchTransmitters",
    "restoreEnemyTouchTransmitters",
    "escapeTouchOverride",
    "isEscapeRelatedPart",
    "nearEscapeTrigger",
    "isWorldItem",
    "playerCharacterAncestor",
    'object:IsA("Tool")',
    "isAvailableWorldItem",
    "itemsById",
    "ancestorRequirementLocks",
    'scope:Loop("objectiveHelper", 0.1',
    "currentMapName",
    "House",
    "Station",
    "Gallery",
    "Forest",
    "School",
    "Hospital",
    "Metro",
    "Carnival",
    "City",
    "Mall",
    "Outpost",
    "Plant",
    "Alleys",
    "Store",
    "Refinery",
    "SafePlace",
    "Sewers",
    "Factory",
    "Port",
    "Ship",
    "Docks",
    "Temple",
    "Camp",
    "Lab",
    "runFreeInteractionStep",
    "solveCodePanel",
    "beginAutomationMove",
    "endAutomationMove",
    "AssemblyLinearVelocity",
    "AssemblyAngularVelocity",
    "scanner recovered",
    "zeroCharacterVelocity",
    "character:PivotTo",
    "readGlobalMapCode",
    "blockerPriority",
    "blockingObjectiveFor",
    "return ok and completed",
    "RemoteControl",
    "Mop",
    "ElevatorKey",
    "Presents",
    "Dreidel",
    "FencingSword",
    "RedEgg",
    "GreenEgg",
    "mapProfiles",
    'Present = {"RedEgg", "GreenEgg", "BlueEgg"}',
    'Factory = {',
    'scope:Loop("autoComplete", 0.05',
]:
    assert token in piggy, token

assert "scope:Connect(RunService.Heartbeat" not in piggy
assert "PathfindingService" not in piggy
assert "computeReachable" not in piggy
assert "reachabilityPending" not in piggy
assert "escapeTouchOverride" in piggy
assert "nearEscapeTrigger" in piggy
assert "isEscapeRelatedPart" in piggy
assert 'setCharacterTouch(false)' in piggy

intercity = texts["games/piggy-intercity/script.lua"]
for token in [
    'ctx.Mode or "Legit"',
    "Enemies ESP",
    "Lootcrates ESP",
    "Materials ESP",
    "Enemy hitbox",
]:
    assert token in intercity, token

assert "scope:Connect(RunService.Heartbeat" not in texts["games/arsenal/script.lua"]
assert "workspace:GetDescendants()" not in texts["games/mm2/script.lua"]
assert "workspace:GetDescendants()" not in texts["games/dead-rails/script.lua"]
assert "scope:Connect(RunService.Heartbeat" not in texts["games/ink-game/script.lua"]
assert 'scope:Loop("runtime", 0.05' in texts["games/ink-game/script.lua"]

print(f"ok: {len(expected)} lua files")

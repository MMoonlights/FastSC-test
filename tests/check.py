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

assert "UniverseIds" in manifest
assert "ByUniverseId" in manifest
assert 'Modes = {"Legit", "Rage"}' in manifest
assert "10000918243" in manifest
assert "1516533665" in manifest
assert "function Manifest.Find(placeId, gameId, method)" in manifest

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
assert "PropertyRestores" in runtime
assert "task.cancel" in runtime
assert "HookNamecall" in runtime
assert "function Scope:Restore(" in runtime

common = texts["core/common.lua"]
assert "CreateDescendantCache" in common

config = texts["core/config.lua"]
assert "scheduleSave" in config
assert "GetGame" in config
assert "SetGame" in config

piggy = texts["games/piggy/script.lua"]
for token in [
    'ctx.Mode or "Legit"',
    "ItemPickupScript",
    "Item ESP",
    "Auto complete objectives",
    "Auto grab items",
    "Trap bypass",
    "Freeze Piggy / bots",
]:
    assert token in piggy, token
assert "scope:Connect(RunService.Heartbeat" not in piggy

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

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

for path in expected:
    target = root / path
    assert target.is_file(), path
    text = target.read_text(encoding="utf-8")
    assert "--" not in text, f"comment found in {path}"
    assert not re.search(r"\b[uvp]\d{2,}\b", text), f"decompiler identifier in {path}"

manifest = (root / "games/manifest.lua").read_text(encoding="utf-8")
for place_id in [2788229376, 4623386862, 5661005779, 286090429, 142823291, 537413528, 3101667897, 3851622790, 4620170611, 17625359962, 13772394625, 16281300371, 70876832253163, 99567941238278, 125009265613167]:
    assert str(place_id) in manifest, place_id

loader = (root / "loader.lua").read_text(encoding="utf-8")
assert "queue_on_teleport" in loader
assert "MMoonlights/UI" in loader
assert "games/" in loader

print(f"ok: {len(expected)} lua files")

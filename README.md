# FastSC

FastSC is a modular Luau loader for supported Roblox games. It detects the current `PlaceId`, loads one game module, scopes feature connections for cleanup, and requeues itself after teleports when the executor supports teleport queuing.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
```

The repository must be public for unauthenticated `raw.githubusercontent.com` loading.

## Auto execute

Put `autoexec.lua` in the executor auto-execute directory. It prefers a local `FastSC-test/loader.lua` checkout and otherwise loads the GitHub version.

## UI

FastSC loads Moon UI from:

`https://raw.githubusercontent.com/MMoonlights/UI/refs/heads/main/menus.lua`

## Structure

- `loader.lua`
- `autoexec.lua`
- `core/runtime.lua`
- `core/common.lua`
- `core/config.lua`
- `games/manifest.lua`
- `games/da-hood/script.lua`
- `games/piggy/script.lua`
- `games/arsenal/script.lua`
- `games/mm2/script.lua`
- `games/babft/script.lua`
- `games/legends-of-speed/script.lua`
- `games/break-in/script.lua`
- `games/rivals/script.lua`
- `games/blade-ball/script.lua`
- `games/dead-rails/script.lua`
- `games/ink-game/script.lua`

## Supported places

| Game | PlaceId |
| --- | --- |
| Da Hood | `2788229376` |
| Piggy | `4623386862`, `5661005779` |
| Arsenal | `286090429` |
| Murder Mystery 2 | `142823291` |
| Build A Boat For Treasure | `537413528` |
| Legends of Speed | `3101667897` |
| Break In | `3851622790`, `4620170611` |
| RIVALS | `17625359962` |
| Blade Ball | `13772394625`, `16281300371` |
| Dead Rails | `70876832253163` |
| Ink Game | `99567941238278`, `125009265613167` |

## Validation

```bash
python tests/check.py
```

The check validates the module layout, selected `PlaceId` mappings, teleport reinjection, Moon UI loading, absence of code comments, and absence of decompiler-style numbered identifiers.

## License

MIT

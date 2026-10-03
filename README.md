# FastSC

FastSC is a modular Luau loader for supported Roblox games. It can detect a game by exact PlaceId or fall back to Roblox GameId / universe, shows a chooser when needed, loads one game mode at a time, scopes feature connections for cleanup, and requeues itself after teleports when the executor supports teleport queuing.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
```

The repository must be public for unauthenticated raw.githubusercontent.com loading.

## Loader options

```lua
getgenv().FastSCOptions = {
    AutoPlace = true,
    AutoMode = false,
    Detect = "Auto",
    Game = nil,
    Mode = nil,
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
```

`AutoPlace = true` selects the detected supported game automatically. `AutoPlace = false` always opens the game chooser.

`Detect = "Auto"` tries exact PlaceId first and then GameId / universe. It can also be set to `"PlaceId"` or `"GameId"`.

`AutoMode = false` opens the mode chooser when a game has multiple modes. `AutoMode = true` loads the forced or last selected mode.

`Game` can force a manifest slug such as `"piggy"`. `Mode` can force a mode such as `"Rage"`.

`getgenv().AutoPlace = false` is also supported as a simple compatibility override.

## Chooser and settings

Selecting a game replaces the chooser with its mode selector. Selecting a mode clears the chooser and loads only that mode.

Every loaded game receives a Settings tab with:

- menu keybind
- live theme switching
- AutoPlace
- detection strategy
- AutoMode
- teleport reinject
- Return to choose game
- Return to choose mode when available
- reload current
- reload loader
- unload

Themes currently available through Moon UI are Crimson, Purple, Ocean, Emerald, and Amber.

## Piggy

Classic Piggy is detected by its exact Book 1 / Book 2 places and by the classic Piggy universe, so additional places in the same universe can fall back through `game.GameId`.

Modes:

- Legit
- Rage

Legit includes item selection, item grabbing, item teleport, item / player / Piggy / trap ESP, fullbright and restricted movement controls.

Rage adds a generic objective completion loop, automatic item collection and interaction, trap bypass, local door bypass, bot freeze, higher movement limits and the same cached ESP/item engine.

## Piggy: Intercity

Piggy: Intercity is treated as its own experience rather than as a classic Piggy chapter. The full release and current demo are mapped separately from classic Piggy and also support Legit / Rage selection.

Current module includes:

- enemy ESP
- lootcrate ESP
- materials ESP
- resource teleports
- speed
- jump
- infinite jump
- noclip
- Rage enemy hitbox controls

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
- `games/piggy-intercity/script.lua`
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
| Piggy: Intercity | `86852362398411`, `94110244708490` |
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

GitHub Actions compiles every Lua file with Luau and runs structural, cleanup, performance, chooser, universe-detection and mode regression checks.

## License

MIT

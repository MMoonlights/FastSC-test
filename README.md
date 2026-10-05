# FastSC

FastSC is a modular Luau loader for supported Roblox games. It can detect a game by exact PlaceId or fall back to Roblox GameId / universe, shows a chooser when needed, loads one complete game module at a time, scopes feature connections for cleanup, and can requeue itself after teleports when the executor supports teleport queuing.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
```

The repository must be public for unauthenticated raw.githubusercontent.com loading.

## Loader options

```lua
getgenv().FastSCOptions = {
    AutoExecute = true,
    Detect = "Auto",
    Game = nil,
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/FastSC-test/main/loader.lua"))()
```

`AutoExecute = true` loads the detected supported game immediately. `AutoExecute = false` opens the game chooser.

`Detect = "Auto"` tries exact PlaceId first and then GameId / universe. It can also be set to `"PlaceId"` or `"GameId"`.

`Game` can force a manifest slug such as `"piggy"`.

The old `AutoPlace` option is still read as a compatibility fallback, but the UI and saved configuration use `Auto Execute`.

## Chooser and settings

Selecting a game loads its complete module directly. There is no Legit / Rage mode chooser.

Every loaded game receives a Settings tab with:

- menu keybind
- live theme switching
- Auto Execute
- TP Handler
- detection strategy
- Return to choose game
- reload current
- reload loader
- unload

`TP Handler` controls teleport reinjection and reads the saved setting again after teleport.

Themes currently available through Moon UI are Crimson, Purple, Ocean, Emerald, and Amber.

## Piggy

Classic Piggy is detected by its exact Book 1 / Book 2 places and by the classic Piggy universe, so additional places in the same universe can fall back through `game.GameId`.

Piggy now opens the full profile directly. There is no separate Legit / Rage chooser; automation, item controls, ESP, player controls and bypass controls are available from one loaded profile.

## Piggy: Intercity

Piggy: Intercity is treated as its own experience rather than as a classic Piggy chapter. The full release and current demo are mapped separately from classic Piggy and open the full profile directly.

Current module includes:

- enemy ESP
- lootcrate ESP
- materials ESP
- resource teleports
- speed
- jump
- infinite jump
- noclip
- enemy hitbox controls

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

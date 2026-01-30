# FPS Arena

A multiplayer first-person shooter game built with Metal and Objective-C for macOS.

## Features

- **LAN Multiplayer** - Host or join games on your local network
- **Single Player** - Fight against AI enemies
- **First to 10 Kills** - Competitive deathmatch gameplay
- **3-Second Respawn** - Quick respawns to keep the action going

## Requirements

- macOS (Apple Silicon or Intel)
- Xcode Command Line Tools

## Building

Compile the game with:

```bash
clang -fobjc-arc \
  -framework Cocoa -framework Metal -framework MetalKit -framework AVFoundation \
  GameMath.c Collision.c GameState.m SoundManager.m DoorSystem.m \
  WeaponSystem.m PickupSystem.m Enemy.m Combat.m GeometryBuilder.m \
  NetworkManager.m MultiplayerController.m LobbyView.m Renderer.m \
  InputView.m AppDelegate.m main.m \
  -o FPSGame
```

## Running

```bash
./FPSGame
```

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| Mouse | Look around |
| Left Click | Shoot |
| Space | Jump |
| E | Open/close doors |
| R | Reload weapon (when alive) / Restart (when dead) |
| 1 | Switch to Pistol |
| 2 | Switch to Shotgun |
| 3 | Switch to Assault Rifle |
| 4 | Switch to Rocket Launcher |
| Escape | Pause / Release mouse |

## Weapons

| Weapon | Damage | Fire Rate | Notes |
|--------|--------|-----------|-------|
| Pistol | 15 | Medium | Unlimited ammo, default weapon |
| Shotgun | 12x8 | Slow | 8 pellets with spread, 8 shells |
| Assault Rifle | 20 | Fast | 30 round magazine, 90 reserve |
| Rocket Launcher | 100 | Very Slow | Splash damage (50), 4 rockets |

## Multiplayer

### Hosting a Game
1. Select "Host Game" from the lobby
2. Share your IP address with the other player
3. Wait for them to connect
4. Click "Start Game" when both players are ready

### Joining a Game
1. Select "Join Game" from the lobby
2. Enter the host's IP address
3. Wait for the host to start the game

## Architecture

The game is built with a modular architecture:

- `GameState` - Singleton holding all mutable game state
- `WeaponSystem` - Multi-weapon system with ammo, reload, and spread
- `NetworkManager` - UDP/TCP networking for multiplayer
- `MultiplayerController` - Coordinates networking and game state
- `LobbyView` - Lobby UI for hosting/joining games
- `Renderer` - Metal-based rendering
- `Combat` - Shooting and damage system (uses WeaponSystem)
- `Enemy` - AI behavior for single player

## License

MIT

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
  Enemy.m Combat.m GeometryBuilder.m NetworkManager.m MultiplayerController.m \
  LobbyView.m Renderer.m InputView.m AppDelegate.m main.m \
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
| R | Restart (when dead in single player) |
| Escape | Pause / Release mouse |

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
- `NetworkManager` - UDP/TCP networking for multiplayer
- `MultiplayerController` - Coordinates networking and game state
- `LobbyView` - Lobby UI for hosting/joining games
- `Renderer` - Metal-based rendering
- `Combat` - Shooting and damage system
- `Enemy` - AI behavior for single player

## License

MIT

// MultiplayerController.m - Coordinates networking and game state for multiplayer
#import "MultiplayerController.h"
#import "NetworkManager.h"
#import "GameConfig.h"
#import "Combat.h"

@interface MultiplayerController () <NetworkManagerDelegate>
@end

@implementation MultiplayerController {
    NetworkManager *_networkManager;
    uint32_t _localSequence;
}

+ (instancetype)shared {
    static MultiplayerController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MultiplayerController alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _networkManager = [NetworkManager shared];
        _networkManager.delegate = self;
        _localSequence = 0;
        _isHost = NO;
        _isConnected = NO;
        _isInGame = NO;
    }
    return self;
}

- (void)hostGame {
    GameState *state = [GameState shared];
    state.isMultiplayer = YES;
    state.isHost = YES;
    state.localPlayerId = 1;

    [_networkManager startHostOnPort:NET_DEFAULT_PORT];
    _isHost = YES;

    NSLog(@"Hosting game on port %d", NET_DEFAULT_PORT);
}

- (void)joinGameAtHost:(NSString *)hostIP {
    GameState *state = [GameState shared];
    state.isMultiplayer = YES;
    state.isHost = NO;
    state.localPlayerId = 2;

    [_networkManager connectToHost:hostIP port:NET_DEFAULT_PORT];
    _isHost = NO;

    NSLog(@"Connecting to host at %@:%d", hostIP, NET_DEFAULT_PORT);
}

- (void)startGame {
    if (!_isHost) return;

    GameState *state = [GameState shared];
    [state resetForMultiplayer];
    _isInGame = YES;

    // Send game start packet to all clients
    [_networkManager sendGameStart];

    NSLog(@"Game started!");
}

- (void)clientStartGame {
    // Called on client when receiving game start from host
    GameState *state = [GameState shared];
    [state resetForMultiplayer];
    _isInGame = YES;
    _isConnected = YES;

    NSLog(@"Client game started!");
}

- (void)leaveGame {
    [_networkManager disconnect];

    GameState *state = [GameState shared];
    state.isMultiplayer = NO;
    state.isConnected = NO;

    _isHost = NO;
    _isConnected = NO;
    _isInGame = NO;
}

- (void)update {
    if (!_networkManager) return;

    GameState *state = [GameState shared];

    // Poll for incoming packets (delegate callbacks will be called)
    [_networkManager pollNetwork];

    // Update connection status
    _isConnected = (_networkManager.connectionState == ConnectionStateConnected ||
                    _networkManager.connectionState == ConnectionStateLobby ||
                    _networkManager.connectionState == ConnectionStateInGame);
    state.isConnected = _isConnected;

    // Handle respawn timers
    if (state.isMultiplayer && _isInGame) {
        if (state.localRespawnTimer > 0) {
            state.localRespawnTimer--;
            if (state.localRespawnTimer == 0) {
                [self doLocalRespawn];
            }
        }

        if (state.remoteRespawnTimer > 0) {
            state.remoteRespawnTimer--;
            if (state.remoteRespawnTimer == 0) {
                state.remotePlayerAlive = YES;
                state.remotePlayerHealth = PLAYER_MAX_HEALTH;
            }
        }

        // Check win condition
        [state checkWinCondition];
    }
}

#pragma mark - NetworkManagerDelegate

- (void)networkManager:(id)manager didReceiveStateUpdate:(PlayerNetState)netState fromPlayer:(uint32_t)playerId {
    GameState *state = [GameState shared];

    // Update remote player state
    state.remotePlayerPosX = netState.posX;
    state.remotePlayerPosY = netState.posY;
    state.remotePlayerPosZ = netState.posZ;
    state.remotePlayerCamYaw = netState.camYaw;
    state.remotePlayerCamPitch = netState.camPitch;
    state.remotePlayerHealth = netState.health;
    state.remotePlayerShooting = (netState.isShooting != 0);
}

- (void)networkManager:(id)manager didReceiveHit:(int)damage toPlayer:(uint32_t)playerId fromPlayer:(uint32_t)shooterId {
    GameState *state = [GameState shared];
    NSLog(@"didReceiveHit: %d damage, target:%u, shooter:%u, localId:%d", damage, playerId, shooterId, state.localPlayerId);

    // We got hit by remote player
    if (playerId == (uint32_t)state.localPlayerId) {
        NSLog(@"Applying %d damage to local player! Health: %d -> %d", damage, state.playerHealth, state.playerHealth - damage);
        state.playerHealth -= damage;
        state.damageCooldownTimer = 0;
        state.bloodLevel += 0.25f;
        if (state.bloodLevel > 1.0f) state.bloodLevel = 1.0f;
        state.bloodFlashTimer = 8;

        if (state.playerHealth <= 0) {
            state.playerHealth = 0;
            [self handleLocalDeath];
        }
    }
}

- (void)networkManager:(id)manager didReceiveKill:(uint32_t)victimId killedBy:(uint32_t)killerId {
    GameState *state = [GameState shared];

    if (victimId == (uint32_t)state.localPlayerId) {
        state.remotePlayerKills++;
    } else {
        state.localPlayerKills++;
    }
}

- (void)networkManager:(id)manager didReceiveRespawn:(uint32_t)playerId atPosition:(PlayerNetState)netState {
    GameState *state = [GameState shared];

    // Remote player respawned
    if (playerId != (uint32_t)state.localPlayerId) {
        state.remotePlayerAlive = YES;
        state.remotePlayerHealth = PLAYER_MAX_HEALTH;
        state.remotePlayerPosX = netState.posX;
        state.remotePlayerPosY = netState.posY;
        state.remotePlayerPosZ = netState.posZ;
    }
}

- (void)networkManager:(id)manager playerDidConnect:(RemotePlayer *)player {
    GameState *state = [GameState shared];
    _isConnected = YES;
    state.isConnected = YES;
    state.remotePlayerId = (int)player.playerId;
    NSLog(@"Player %u joined lobby", player.playerId);
}

- (void)networkManagerDidConnect:(id)manager withPlayerId:(uint32_t)playerId {
    GameState *state = [GameState shared];
    _isConnected = YES;
    state.isConnected = YES;
    state.localPlayerId = (int)playerId;
    NSLog(@"Connected with player ID %u", playerId);
}

- (void)networkManagerDidDisconnect:(id)manager {
    GameState *state = [GameState shared];
    _isConnected = NO;
    state.isConnected = NO;
    _isInGame = NO;
    NSLog(@"Disconnected");
}

- (void)networkManager:(id)manager playerDidDisconnect:(RemotePlayer *)player {
    GameState *state = [GameState shared];

    // Clear remote player state so they disappear
    if ((int)player.playerId == state.remotePlayerId) {
        state.remotePlayerAlive = NO;
        state.remotePlayerId = 0;
        NSLog(@"Remote player %u disconnected", player.playerId);
    }
}

#pragma mark - Sending State

- (void)sendLocalState:(float)posX posY:(float)posY posZ:(float)posZ
                camYaw:(float)camYaw camPitch:(float)camPitch
            isShooting:(BOOL)isShooting {
    if (!_isConnected || !_isInGame) return;

    GameState *state = [GameState shared];

    PlayerNetState netState = {0};
    netState.playerId = (uint32_t)state.localPlayerId;
    netState.posX = posX;
    netState.posY = posY;
    netState.posZ = posZ;
    netState.camYaw = camYaw;
    netState.camPitch = camPitch;
    netState.isShooting = isShooting ? 1 : 0;
    netState.health = state.playerHealth;

    [_networkManager sendStateUpdate:netState];
}

- (void)sendHitOnRemotePlayer:(int)damage {
    if (!_isConnected || !_isInGame) {
        NSLog(@"sendHitOnRemotePlayer: NOT sending - connected:%d inGame:%d", _isConnected, _isInGame);
        return;
    }

    GameState *state = [GameState shared];
    NSLog(@"sendHitOnRemotePlayer: Sending %d damage to player %d", damage, state.remotePlayerId);
    [_networkManager sendHit:damage toPlayer:(uint32_t)state.remotePlayerId];
}

- (void)handleLocalDeath {
    GameState *state = [GameState shared];

    // Send death notification (kill stats updated via didReceiveKill callback)
    [_networkManager sendKill:(uint32_t)state.localPlayerId];

    // Start respawn timer
    state.localRespawnTimer = RESPAWN_DELAY;
}

- (void)sendLocalPlayerDeath {
    [self handleLocalDeath];
}

- (void)requestRespawn {
    // Respawn is handled automatically by timer
}

- (void)doLocalRespawn {
    GameState *state = [GameState shared];

    // Get spawn point (alternate between points based on player ID)
    int spawnIndex = (state.localPlayerId - 1) % NUM_SPAWN_POINTS;
    SpawnPoint *spawnPt = [state getSpawnPoint:spawnIndex];
    if (!spawnPt) {
        // Fallback to spawn 0
        spawnPt = [state getSpawnPoint:0];
        if (!spawnPt) return;
    }

    // Reset player state
    state.playerHealth = PLAYER_MAX_HEALTH;
    state.playerArmor = 0;
    state.bloodLevel = 0;
    state.gameOver = NO;

    // Set respawn teleport position (Renderer will apply this)
    state.needsRespawnTeleport = YES;
    state.respawnX = spawnPt->x;
    state.respawnY = spawnPt->y;
    state.respawnZ = spawnPt->z;
    state.respawnYaw = spawnPt->yaw;

    NSLog(@"[RESPAWN] Respawning at (%.1f, %.1f, %.1f)", spawnPt->x, spawnPt->y, spawnPt->z);

    // Send respawn packet to other players
    PlayerNetState netState = {0};
    netState.playerId = (uint32_t)state.localPlayerId;
    netState.posX = spawnPt->x;
    netState.posY = spawnPt->y;
    netState.posZ = spawnPt->z;
    netState.health = PLAYER_MAX_HEALTH;

    [_networkManager sendRespawn:netState];
}

@end

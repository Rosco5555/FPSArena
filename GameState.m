// GameState.m - Global game state singleton implementation
#import "GameState.h"

@implementation GameState {
    // Single-player enemy arrays
    BOOL _enemyAliveStorage[NUM_ENEMIES];
    int _enemyHealthStorage[NUM_ENEMIES];
    float _enemyXStorage[NUM_ENEMIES];
    float _enemyYStorage[NUM_ENEMIES];
    float _enemyZStorage[NUM_ENEMIES];
    int _enemyFireTimerStorage[NUM_ENEMIES];

    // Multiplayer spawn points
    SpawnPoint _spawnPointsStorage[NUM_SPAWN_POINTS];
}

+ (instancetype)shared {
    static GameState *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GameState alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize spawn points (corners of the arena with appropriate facing directions)
        _spawnPointsStorage[0] = (SpawnPoint){
            .x = -ARENA_SIZE + 2.0f,
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = -ARENA_SIZE + 2.0f,
            .yaw = M_PI * 0.25f  // Face toward center (northeast)
        };
        _spawnPointsStorage[1] = (SpawnPoint){
            .x = ARENA_SIZE - 2.0f,
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = -ARENA_SIZE + 2.0f,
            .yaw = M_PI * 0.75f  // Face toward center (northwest)
        };
        _spawnPointsStorage[2] = (SpawnPoint){
            .x = ARENA_SIZE - 2.0f,
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = ARENA_SIZE - 2.0f,
            .yaw = M_PI * 1.25f  // Face toward center (southwest)
        };
        _spawnPointsStorage[3] = (SpawnPoint){
            .x = -ARENA_SIZE + 2.0f,
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = ARENA_SIZE - 2.0f,
            .yaw = M_PI * 1.75f  // Face toward center (southeast)
        };

        // Set default kill limit
        _killLimit = DEFAULT_KILL_LIMIT;

        [self resetGame];
    }
    return self;
}

// Accessors for enemy arrays (single-player mode)
- (BOOL *)enemyAlive { return _enemyAliveStorage; }
- (int *)enemyHealth { return _enemyHealthStorage; }
- (float *)enemyX { return _enemyXStorage; }
- (float *)enemyY { return _enemyYStorage; }
- (float *)enemyZ { return _enemyZStorage; }
- (int *)enemyFireTimer { return _enemyFireTimerStorage; }

// Accessor for spawn points
- (SpawnPoint *)spawnPoints { return _spawnPointsStorage; }

- (void)resetGame {
    // Player state
    _playerHealth = PLAYER_MAX_HEALTH;
    _gameOver = NO;
    _bloodLevel = 0.0f;
    _bloodFlashTimer = 0;
    _damageCooldownTimer = 0;
    _regenTickTimer = 0;
    _footstepTimer = 0;

    // Door state
    _doorOpen = NO;
    _doorAngle = 0.0f;
    _playerNearDoor = NO;

    // Enemy state (for single-player mode)
    for (int i = 0; i < NUM_ENEMIES; i++) {
        _enemyAliveStorage[i] = YES;
        _enemyHealthStorage[i] = ENEMY_MAX_HEALTH;
        _enemyXStorage[i] = ENEMY_START_X[i];
        _enemyYStorage[i] = ENEMY_START_Y[i];
        _enemyZStorage[i] = ENEMY_START_Z[i];
        _enemyFireTimerStorage[i] = 0;
    }

    // Combat state
    _muzzleFlashTimer = 0;
    _enemyMuzzleFlashTimer = 0;
    _enemyMuzzlePos = (simd_float3){0, 0, 0};
    _lastFiringEnemy = -1;

    // Reset multiplayer state to single-player defaults
    _isMultiplayer = NO;
    _isHost = NO;
    _isConnected = NO;
    _localPlayerId = 0;
    _remotePlayerId = 0;

    // Remote player state (inactive in single-player)
    _remotePlayerPosX = 0.0f;
    _remotePlayerPosY = 0.0f;
    _remotePlayerPosZ = 0.0f;
    _remotePlayerCamYaw = 0.0f;
    _remotePlayerCamPitch = 0.0f;
    _remotePlayerHealth = 0;
    _remotePlayerAlive = NO;

    // Scoring
    _localPlayerKills = 0;
    _remotePlayerKills = 0;
    // Note: killLimit is preserved (set in init or by caller)
    _gameWon = NO;
    _winnerId = -1;

    // Respawn timers
    _localRespawnTimer = 0;
    _remoteRespawnTimer = 0;
}

- (void)resetForMultiplayer {
    // Enable multiplayer mode
    _isMultiplayer = YES;
    _isConnected = NO;  // Will be set to YES when connection established
    _gameOver = NO;
    _gameWon = NO;
    _winnerId = -1;

    // Reset scores
    _localPlayerKills = 0;
    _remotePlayerKills = 0;

    // Reset local player state
    _playerHealth = PLAYER_MAX_HEALTH;
    _bloodLevel = 0.0f;
    _bloodFlashTimer = 0;
    _damageCooldownTimer = 0;
    _regenTickTimer = 0;
    _localRespawnTimer = 0;

    // Reset remote player state
    _remotePlayerHealth = PLAYER_MAX_HEALTH;
    _remotePlayerAlive = YES;
    _remoteRespawnTimer = 0;

    // Position players at different spawn points based on host status
    // Host gets spawn point 0, client gets spawn point 2 (opposite corners)
    SpawnPoint *localSpawn = [self getSpawnPoint:(_isHost ? 0 : 2)];
    SpawnPoint *remoteSpawn = [self getSpawnPoint:(_isHost ? 2 : 0)];

    if (localSpawn) {
        // Local player position will be set by resetPlayerWithPosX when game starts
        // Just store for reference
    }

    if (remoteSpawn) {
        _remotePlayerPosX = remoteSpawn->x;
        _remotePlayerPosY = remoteSpawn->y;
        _remotePlayerPosZ = remoteSpawn->z;
        _remotePlayerCamYaw = remoteSpawn->yaw;
        _remotePlayerCamPitch = 0.0f;
    }

    // Combat state
    _muzzleFlashTimer = 0;
    _enemyMuzzleFlashTimer = 0;
    _enemyMuzzlePos = (simd_float3){0, 0, 0};
    _lastFiringEnemy = -1;

    // Door state (reset for fair start)
    _doorOpen = NO;
    _doorAngle = 0.0f;
    _playerNearDoor = NO;

    // Disable AI enemies in multiplayer mode
    for (int i = 0; i < NUM_ENEMIES; i++) {
        _enemyAliveStorage[i] = NO;
        _enemyHealthStorage[i] = 0;
    }
}

- (SpawnPoint *)getSpawnPoint:(int)index {
    if (index < 0 || index >= NUM_SPAWN_POINTS) {
        return NULL;
    }
    return &_spawnPointsStorage[index];
}

- (BOOL)checkWinCondition {
    // Only check in multiplayer mode
    if (!_isMultiplayer) {
        return NO;
    }

    // Already won
    if (_gameWon) {
        return YES;
    }

    // Check if local player reached kill limit
    if (_localPlayerKills >= _killLimit) {
        _gameWon = YES;
        _winnerId = _localPlayerId;
        _gameOver = YES;
        return YES;
    }

    // Check if remote player reached kill limit
    if (_remotePlayerKills >= _killLimit) {
        _gameWon = YES;
        _winnerId = _remotePlayerId;
        _gameOver = YES;
        return YES;
    }

    return NO;
}

- (void)resetPlayerWithPosX:(float *)posX posY:(float *)posY posZ:(float *)posZ
                     camYaw:(float *)camYaw camPitch:(float *)camPitch
                  velocityX:(float *)velocityX velocityY:(float *)velocityY velocityZ:(float *)velocityZ
                   onGround:(BOOL *)onGround {

    if (_isMultiplayer) {
        // In multiplayer, use spawn points
        // Determine which spawn point to use based on host status
        int spawnIndex = _isHost ? 0 : 2;
        SpawnPoint *spawn = [self getSpawnPoint:spawnIndex];

        if (spawn) {
            *posX = spawn->x;
            *posY = spawn->y;
            *posZ = spawn->z;
            *camYaw = spawn->yaw;
        } else {
            // Fallback to default position
            *posX = PLAYER_START_X;
            *posY = FLOOR_Y + PLAYER_HEIGHT;
            *posZ = PLAYER_START_Z;
            *camYaw = M_PI;
        }
    } else {
        // Single-player: use original spawn position
        *posX = PLAYER_START_X;
        *posY = FLOOR_Y + PLAYER_HEIGHT;
        *posZ = PLAYER_START_Z;
        *camYaw = M_PI;
    }

    *camPitch = 0.0f;
    *velocityX = 0.0f;
    *velocityY = 0.0f;
    *velocityZ = 0.0f;
    *onGround = YES;
}

@end

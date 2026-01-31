// GameState.m - Global game state singleton implementation
#import "GameState.h"
#import "WeaponSystem.h"

@implementation GameState {
    // Single-player enemy arrays
    BOOL _enemyAliveStorage[NUM_ENEMIES];
    int _enemyHealthStorage[NUM_ENEMIES];
    float _enemyXStorage[NUM_ENEMIES];
    float _enemyYStorage[NUM_ENEMIES];
    float _enemyZStorage[NUM_ENEMIES];
    int _enemyFireTimerStorage[NUM_ENEMIES];
    int _enemyRespawnTimerStorage[NUM_ENEMIES];

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
        // Initialize spawn points in SAFE locations with cover nearby
        // All spawns face toward center of map where action is

        // Spawn 0: Inside command building (protected by walls on 3 sides)
        // Position near back wall, facing the door
        _spawnPointsStorage[0] = (SpawnPoint){
            .x = CMD_BUILDING_X,
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = CMD_BUILDING_Z - (CMD_BUILDING_DEPTH / 2.0f) + 1.5f,  // Near back wall
            .yaw = 0.0f  // Face south toward door/exit
        };

        // Spawn 1: Inside bunker (underground, fully protected)
        // Position in center of bunker room
        _spawnPointsStorage[1] = (SpawnPoint){
            .x = BUNKER_X,
            .y = BASEMENT_LEVEL + PLAYER_HEIGHT,  // Underground level
            .z = BUNKER_Z,
            .yaw = M_PI * 0.5f  // Face east toward stairs/exit
        };

        // Spawn 2: Behind cargo containers (east side, has cover nearby)
        // Position behind container cluster
        _spawnPointsStorage[2] = (SpawnPoint){
            .x = 12.0f,  // Behind containers on east side
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = -6.0f,
            .yaw = M_PI * 0.75f  // Face toward center (northwest)
        };

        // Spawn 3: On northeast guard tower platform (elevated, railings for cover)
        _spawnPointsStorage[3] = (SpawnPoint){
            .x = TOWER_OFFSET,
            .y = PLATFORM_LEVEL + PLAYER_HEIGHT,  // On tower platform
            .z = TOWER_OFFSET,
            .yaw = M_PI * 1.25f  // Face toward center (southwest)
        };

        // Spawn 4: Behind sandbag wall near west side (good cover position)
        _spawnPointsStorage[4] = (SpawnPoint){
            .x = -12.0f,  // West side behind sandbags
            .y = FLOOR_Y + PLAYER_HEIGHT,
            .z = 0.0f,
            .yaw = 0.0f  // Face east toward center
        };

        // Spawn 5: On southwest guard tower platform (elevated, opposite corner from spawn 3)
        _spawnPointsStorage[5] = (SpawnPoint){
            .x = -TOWER_OFFSET,
            .y = PLATFORM_LEVEL + PLAYER_HEIGHT,  // On tower platform
            .z = -TOWER_OFFSET,
            .yaw = M_PI * 0.25f  // Face toward center (northeast)
        };

        // Set default kill limit
        _killLimit = DEFAULT_KILL_LIMIT;

        // Default mouse sensitivity
        _mouseSensitivity = MOUSE_SENSITIVITY;

        // Default master volume
        _masterVolume = 1.0f;

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
- (int *)enemyRespawnTimer { return _enemyRespawnTimerStorage; }

// Accessor for spawn points
- (SpawnPoint *)spawnPoints { return _spawnPointsStorage; }

// Weapon system accessors (delegate to WeaponSystem singleton)
- (WeaponType)currentWeaponType {
    return [[WeaponSystem shared] getCurrentWeapon];
}

- (BOOL)isWeaponReloading {
    return [[WeaponSystem shared] isReloading];
}

- (void)resetGame {
    // Player state
    _playerHealth = PLAYER_MAX_HEALTH;
    _playerArmor = 0;
    _gameOver = NO;
    _isPaused = NO;
    _showPauseMenu = NO;
    _pauseMenuSelection = -1;
    _pickupNotificationTimer = 0;
    _pickupNotificationText = nil;
    _bloodLevel = 0.0f;
    _bloodFlashTimer = 0;
    _damageCooldownTimer = 0;
    _regenTickTimer = 0;
    _footstepTimer = 0;
    _spawnProtectionTimer = SPAWN_PROTECTION_TIME;  // 3 seconds of spawn protection
    _killCount = 0;

    // Weapon ownership (start with pistol only)
    _hasWeaponShotgun = NO;
    _hasWeaponAssaultRifle = NO;
    _hasWeaponRocketLauncher = NO;

    // Ammo counts
    _ammoSmall = 50;    // Starting pistol/rifle ammo
    _ammoHeavy = 0;     // No heavy ammo to start

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

    // Reset weapon system
    [[WeaponSystem shared] resetWeapons];

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
    _isPaused = NO;
    _gameWon = NO;
    _winnerId = -1;

    // Reset scores
    _localPlayerKills = 0;
    _remotePlayerKills = 0;

    // Reset local player state
    _playerHealth = PLAYER_MAX_HEALTH;
    _playerArmor = 0;
    _bloodLevel = 0.0f;
    _bloodFlashTimer = 0;
    _damageCooldownTimer = 0;
    _regenTickTimer = 0;
    _localRespawnTimer = 0;
    _spawnProtectionTimer = SPAWN_PROTECTION_TIME;  // 3 seconds of spawn protection

    // Reset weapon ownership
    _hasWeaponShotgun = NO;
    _hasWeaponAssaultRifle = NO;
    _hasWeaponRocketLauncher = NO;
    _ammoSmall = 50;
    _ammoHeavy = 0;

    // Reset remote player state
    _remotePlayerHealth = PLAYER_MAX_HEALTH;
    _remotePlayerAlive = YES;
    _remoteRespawnTimer = 0;

    // Position players at OPPOSITE spawn points - deterministic based on host/client
    // Spawn 0 (command building) and Spawn 2 (east cargo) are far apart
    // Host ALWAYS gets spawn 0, Client ALWAYS gets spawn 2
    int hostSpawnIndex = 0;   // Command building
    int clientSpawnIndex = 2; // East cargo (opposite side of map)

    int localSpawnIndex = _isHost ? hostSpawnIndex : clientSpawnIndex;
    int remoteSpawnIndex = _isHost ? clientSpawnIndex : hostSpawnIndex;

    SpawnPoint *localSpawn = [self getSpawnPoint:localSpawnIndex];
    SpawnPoint *remoteSpawn = [self getSpawnPoint:remoteSpawnIndex];

    if (remoteSpawn) {
        _remotePlayerPosX = remoteSpawn->x;
        _remotePlayerPosY = remoteSpawn->y;
        _remotePlayerPosZ = remoteSpawn->z;
        _remotePlayerCamYaw = remoteSpawn->yaw;
        _remotePlayerCamPitch = 0.0f;
    }

    // Store local spawn index for resetPlayerWithPosX to use
    _localSpawnIndex = localSpawnIndex;

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

    // Reset spawn protection timer
    _spawnProtectionTimer = SPAWN_PROTECTION_TIME;

    if (_isMultiplayer) {
        // In multiplayer, find spawn point furthest from remote player
        int bestSpawn = _localSpawnIndex;  // Default to assigned spawn
        float bestDistance = 0.0f;

        for (int i = 0; i < NUM_SPAWN_POINTS; i++) {
            SpawnPoint *spawn = [self getSpawnPoint:i];
            if (spawn) {
                float dx = spawn->x - _remotePlayerPosX;
                float dz = spawn->z - _remotePlayerPosZ;
                float dist = sqrtf(dx * dx + dz * dz);

                // Prefer spawn points far from remote player
                if (dist > bestDistance) {
                    bestDistance = dist;
                    bestSpawn = i;
                }
            }
        }

        SpawnPoint *spawn = [self getSpawnPoint:bestSpawn];

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
        // Single-player: randomly select from safe spawn points
        int spawnIndex = arc4random_uniform(NUM_SPAWN_POINTS);
        SpawnPoint *spawn = [self getSpawnPoint:spawnIndex];

        if (spawn) {
            *posX = spawn->x;
            *posY = spawn->y;
            *posZ = spawn->z;
            *camYaw = spawn->yaw;
        } else {
            // Fallback to spawn 0 (inside command building)
            *posX = CMD_BUILDING_X;
            *posY = FLOOR_Y + PLAYER_HEIGHT;
            *posZ = CMD_BUILDING_Z - (CMD_BUILDING_DEPTH / 2.0f) + 1.5f;
            *camYaw = 0.0f;
        }
    }

    *camPitch = 0.0f;
    *velocityX = 0.0f;
    *velocityY = 0.0f;
    *velocityZ = 0.0f;
    *onGround = YES;
}

@end

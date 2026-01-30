// GameState.h - Global game state singleton
#ifndef GAMESTATE_H
#define GAMESTATE_H

#import <Foundation/Foundation.h>
#import "GameConfig.h"
#import "GameTypes.h"
#import "WeaponSystem.h"

// Multiplayer constants
static const int RESPAWN_DELAY = 180;  // 3 seconds at 60fps
static const int DEFAULT_KILL_LIMIT = 10;
static const int NUM_SPAWN_POINTS = 6;

// Spawn protection constants
static const int SPAWN_PROTECTION_TIME = 180;  // 3 seconds at 60fps

// Spawn point structure
typedef struct {
    float x;
    float y;
    float z;
    float yaw;  // Initial facing direction
} SpawnPoint;

@interface GameState : NSObject

+ (instancetype)shared;

// Player state (local player in multiplayer)
@property (nonatomic) int playerHealth;
@property (nonatomic) int playerArmor;           // Armor points (reduces damage by 50%)
@property (nonatomic) BOOL gameOver;
@property (nonatomic) BOOL isPaused;
@property (nonatomic) float bloodLevel;
@property (nonatomic) int bloodFlashTimer;
@property (nonatomic) int damageCooldownTimer;
@property (nonatomic) int regenTickTimer;
@property (nonatomic) int footstepTimer;
@property (nonatomic) int spawnProtectionTimer;  // Counts down in frames, player invulnerable when > 0

// Weapon ownership flags (for pickups)
@property (nonatomic) BOOL hasWeaponShotgun;
@property (nonatomic) BOOL hasWeaponAssaultRifle;
@property (nonatomic) BOOL hasWeaponRocketLauncher;

// Ammo counts (legacy - WeaponSystem uses its own)
@property (nonatomic) int ammoSmall;              // Pistol/rifle ammo
@property (nonatomic) int ammoHeavy;              // Shotgun/rocket ammo

// Door state
@property (nonatomic) BOOL doorOpen;
@property (nonatomic) float doorAngle;
@property (nonatomic) BOOL playerNearDoor;

// Enemy state (C arrays for performance) - used in single-player mode
@property (nonatomic, readonly) BOOL *enemyAlive;
@property (nonatomic, readonly) int *enemyHealth;
@property (nonatomic, readonly) float *enemyX;
@property (nonatomic, readonly) float *enemyY;
@property (nonatomic, readonly) float *enemyZ;
@property (nonatomic, readonly) int *enemyFireTimer;
@property (nonatomic, readonly) int *enemyRespawnTimer;

// Combat state
@property (nonatomic) int muzzleFlashTimer;
@property (nonatomic) int enemyMuzzleFlashTimer;
@property (nonatomic) simd_float3 enemyMuzzlePos;
@property (nonatomic) int lastFiringEnemy;

// Weapon system state (reference to singleton's state)
@property (nonatomic, readonly) WeaponType currentWeaponType;
@property (nonatomic, readonly) BOOL isWeaponReloading;

// ============================================
// MULTIPLAYER STATE
// ============================================

// Multiplayer mode flags
@property (nonatomic) BOOL isMultiplayer;
@property (nonatomic) BOOL isHost;
@property (nonatomic) BOOL isConnected;

// Player identifiers
@property (nonatomic) int localPlayerId;
@property (nonatomic) int remotePlayerId;

// Remote player position
@property (nonatomic) float remotePlayerPosX;
@property (nonatomic) float remotePlayerPosY;
@property (nonatomic) float remotePlayerPosZ;

// Remote player camera orientation
@property (nonatomic) float remotePlayerCamYaw;
@property (nonatomic) float remotePlayerCamPitch;

// Remote player state
@property (nonatomic) int remotePlayerHealth;
@property (nonatomic) BOOL remotePlayerAlive;
@property (nonatomic) BOOL remotePlayerShooting;

// Scoring
@property (nonatomic) int localPlayerKills;
@property (nonatomic) int remotePlayerKills;
@property (nonatomic) int killLimit;
@property (nonatomic) BOOL gameWon;
@property (nonatomic) int winnerId;

// Respawn timers (counts down in frames)
@property (nonatomic) int localRespawnTimer;
@property (nonatomic) int remoteRespawnTimer;

// Respawn teleport (set by MultiplayerController, read by Renderer)
@property (nonatomic) BOOL needsRespawnTeleport;
@property (nonatomic) float respawnX;
@property (nonatomic) float respawnY;
@property (nonatomic) float respawnZ;
@property (nonatomic) float respawnYaw;

// Spawn points array (read-only access)
@property (nonatomic, readonly) SpawnPoint *spawnPoints;

// ============================================
// METHODS
// ============================================

// Reset all state for game restart (single-player)
- (void)resetGame;

// Reset state for new multiplayer match
- (void)resetForMultiplayer;

// Get spawn point by index (returns pointer to spawn point, or NULL if invalid index)
- (SpawnPoint *)getSpawnPoint:(int)index;

// Check if someone reached kill limit, sets gameWon and winnerId if so
// Returns YES if game has been won
- (BOOL)checkWinCondition;

// Reset player position and camera
- (void)resetPlayerWithPosX:(float *)posX posY:(float *)posY posZ:(float *)posZ
                     camYaw:(float *)camYaw camPitch:(float *)camPitch
                  velocityX:(float *)velocityX velocityY:(float *)velocityY velocityZ:(float *)velocityZ
                   onGround:(BOOL *)onGround;

@end

#endif // GAMESTATE_H

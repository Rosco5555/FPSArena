// Combat.h - Player shooting and damage (with multiplayer PvP support)
#ifndef COMBAT_H
#define COMBAT_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "GameConfig.h"
#import "GameTypes.h"

// Hit result types for processPlayerShooting
typedef enum {
    HitResultNone = 0,      // Hit nothing (or environment)
    HitResultEnemyAI,       // Hit an enemy AI
    HitResultRemotePlayer   // Hit a remote player (multiplayer)
} HitResultType;

// Extended hit result with details
typedef struct {
    HitResultType type;
    int hitEntityId;        // Enemy index or remote player ID
    float hitDistance;
    simd_float3 hitPoint;
} CombatHitResult;

// Player hitbox dimensions for PvP
static const float PLAYER_HITBOX_HEIGHT = 1.7f;   // Standing height
static const float PLAYER_HITBOX_WIDTH = 0.6f;    // Width/depth
static const float PLAYER_HITBOX_HALF_WIDTH = 0.3f;
static const float PLAYER_HITBOX_HALF_HEIGHT = 0.85f;

// PvP damage constants
static const int PVP_DAMAGE = 25;  // 4 hits to kill from 100 HP

// Process player shooting - returns hit result info
// In multiplayer mode, also checks for PvP hits
CombatHitResult processPlayerShooting(simd_float3 camPos, float camYaw, float camPitch);

// Check if a ray hits a remote player's hitbox
// Returns YES if shot hit remote player, sets hitDistance
BOOL checkPlayerHit(simd_float3 rayOrigin, simd_float3 rayDir,
                    simd_float3 targetPos, float *hitDistance);

// Update player health regeneration
void updateHealthRegeneration(void);

// Update muzzle flash and blood timers
void updateCombatTimers(void);

// Kill/death handling for multiplayer
void handlePlayerKill(int killerPlayerId, int victimPlayerId);
void respawnPlayer(int playerId);

// Apply damage from remote player hit
void applyDamageFromRemotePlayer(int damage);

#endif // COMBAT_H

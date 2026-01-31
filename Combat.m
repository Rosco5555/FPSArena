// Combat.m - Player shooting and damage implementation (with multiplayer PvP support)
#import "Combat.h"
#import "GameState.h"
#import "GameMath.h"
#import "Collision.h"
#import "CollisionWorld.h"
#import "DoorSystem.h"
#import "SoundManager.h"
#import "WeaponSystem.h"
#import "MultiplayerController.h"
#import <math.h>

// Helper function to check ray against environment (walls, doors, etc.)
// Returns the closest hit distance - uses CollisionWorld for consistency
static float checkEnvironmentHit(simd_float3 muzzle, simd_float3 dir, float maxRange) {
    // Use CollisionWorld's raycast for consistent hit detection
    CollisionWorld *collisionWorld = [CollisionWorld shared];
    RaycastResult result = [collisionWorld raycastFrom:muzzle
                                             direction:dir
                                           maxDistance:maxRange
                                             layerMask:CollisionLayerWorld];

    if (result.hit) {
        return result.distance;
    }

    // Also check the door (dynamic object not in CollisionWorld)
    simd_float3 doorMin, doorMax;
    getDoorAABB(&doorMin, &doorMax);
    RayHitResult doorHit = rayIntersectAABB(muzzle, dir, doorMin, doorMax);
    if (doorHit.hit && doorHit.t > 0 && doorHit.t < maxRange) {
        return doorHit.t;
    }

    return maxRange;
}

// Check if a ray hits a player hitbox at the given position
// Uses standing height ~1.7, width ~0.6
BOOL checkPlayerHit(simd_float3 rayOrigin, simd_float3 rayDir,
                    simd_float3 targetPos, float *hitDistance) {
    // Build AABB for player hitbox centered at targetPos
    // targetPos is assumed to be at the player's feet/ground level
    simd_float3 boxMin = {
        targetPos.x - PLAYER_HITBOX_HALF_WIDTH,
        targetPos.y,  // Bottom at feet
        targetPos.z - PLAYER_HITBOX_HALF_WIDTH
    };
    simd_float3 boxMax = {
        targetPos.x + PLAYER_HITBOX_HALF_WIDTH,
        targetPos.y + PLAYER_HITBOX_HEIGHT,  // Top at head
        targetPos.z + PLAYER_HITBOX_HALF_WIDTH
    };

    RayHitResult result = rayIntersectAABB(rayOrigin, rayDir, boxMin, boxMax);

    if (result.hit && result.t > 0) {
        if (hitDistance != NULL) {
            *hitDistance = result.t;
        }
        return YES;
    }

    return NO;
}

// Process a single projectile hit with given damage and range
CombatHitResult processProjectileHit(simd_float3 muzzle, simd_float3 dir, int damage, float range) {
    GameState *state = [GameState shared];

    CombatHitResult hitResult = {
        .type = HitResultNone,
        .hitEntityId = -1,
        .hitDistance = range,
        .hitPoint = simd_make_float3(0, 0, 0)
    };

    float maxDist = checkEnvironmentHit(muzzle, dir, range);

    // Check hit against enemies (AI)
    BOOL *enemyAlive = state.enemyAlive;
    int *enemyHealth = state.enemyHealth;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        if (enemyAlive[e]) {
            // Enemy hitbox dimensions to match rendered model
            // The enemy model is scaled by 1.4x and rotates to face the player
            // Model dimensions (scaled): X width ~0.98, Y height ~1.96 (-0.84 to +1.12), Z depth ~0.34
            // Since enemy rotates to face player, we use a symmetric XZ hitbox that covers all rotations
            // The gun extends to about 0.84 in the facing direction, so we use 0.6 radius to be generous
            float hitboxHalfWidth = 0.6f;   // Covers rotated model width (gun + body)
            float hitboxHalfDepth = 0.6f;   // Same as width since enemy rotates
            float hitboxBottom = -0.84f;    // Model feet (scaled)
            float hitboxTop = 1.12f;        // Model head (scaled)

            simd_float3 eMin = {enemyX[e] - hitboxHalfWidth, enemyY[e] + hitboxBottom, enemyZ[e] - hitboxHalfDepth};
            simd_float3 eMax = {enemyX[e] + hitboxHalfWidth, enemyY[e] + hitboxTop, enemyZ[e] + hitboxHalfDepth};
            RayHitResult eHit = rayIntersectAABB(muzzle, dir, eMin, eMax);
            if (eHit.hit && eHit.t < maxDist) {
                enemyHealth[e] -= damage;
                if (enemyHealth[e] <= 0) {
                    enemyAlive[e] = NO;
                    state.enemyRespawnTimer[e] = ENEMY_RESPAWN_DELAY;
                    if (!state.isMultiplayer) {
                        state.killCount++;
                    }
                }
                maxDist = eHit.t;

                hitResult.type = HitResultEnemyAI;
                hitResult.hitEntityId = e;
                hitResult.hitDistance = eHit.t;
                hitResult.hitPoint = muzzle + dir * eHit.t;
            }
        }
    }

    // Check hit against remote player in multiplayer mode
    if (state.isMultiplayer && state.remotePlayerAlive) {
        // remotePlayerPosY is at eye level, convert to feet level for hitbox
        simd_float3 remotePos = simd_make_float3(
            state.remotePlayerPosX,
            state.remotePlayerPosY - PLAYER_HEIGHT,  // Convert eye level to feet level
            state.remotePlayerPosZ
        );

        float playerHitDist = 0;
        if (checkPlayerHit(muzzle, dir, remotePos, &playerHitDist)) {
            if (playerHitDist < maxDist) {
                maxDist = playerHitDist;
                hitResult.type = HitResultRemotePlayer;
                hitResult.hitEntityId = state.remotePlayerId;
                hitResult.hitDistance = playerHitDist;
                hitResult.hitPoint = muzzle + dir * playerHitDist;
            }
        }
    }

    return hitResult;
}

// Apply splash damage at a point (for rocket launcher)
void applySplashDamage(simd_float3 hitPoint, float radius, int damage) {
    GameState *state = [GameState shared];

    // Check enemies in splash radius
    BOOL *enemyAlive = state.enemyAlive;
    int *enemyHealth = state.enemyHealth;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        if (enemyAlive[e]) {
            // Use enemy center of mass for splash damage calculation
            // The enemy model's vertical center is approximately 0.14 above enemyY (scaled model)
            simd_float3 enemyPos = simd_make_float3(enemyX[e], enemyY[e] + 0.14f, enemyZ[e]);
            float dist = simd_distance(hitPoint, enemyPos);
            if (dist < radius) {
                // Damage falls off with distance
                float falloff = 1.0f - (dist / radius);
                int splashDmg = (int)(damage * falloff);
                enemyHealth[e] -= splashDmg;
                if (enemyHealth[e] <= 0) {
                    enemyAlive[e] = NO;
                    state.enemyRespawnTimer[e] = ENEMY_RESPAWN_DELAY;
                    if (!state.isMultiplayer) {
                        state.killCount++;
                    }
                }
            }
        }
    }

    // Check remote player in splash radius (multiplayer)
    if (state.isMultiplayer && state.remotePlayerAlive) {
        // Use center of body for splash calculations (eye level - half height)
        simd_float3 remotePos = simd_make_float3(
            state.remotePlayerPosX,
            state.remotePlayerPosY - PLAYER_HEIGHT * 0.5f,
            state.remotePlayerPosZ
        );
        float dist = simd_distance(hitPoint, remotePos);
        if (dist < radius) {
            // Splash damage to remote player - send via network
            float falloff = 1.0f - (dist / radius);
            int splashDmg = (int)(damage * falloff);
            if (splashDmg > 0) {
                [[MultiplayerController shared] sendHitOnRemotePlayer:splashDmg];
            }
        }
    }
}

CombatHitResult processPlayerShooting(simd_float3 camPos, float camYaw, float camPitch) {
    GameState *state = [GameState shared];
    WeaponSystem *weaponSystem = [WeaponSystem shared];

    // Initialize result
    CombatHitResult hitResult = {
        .type = HitResultNone,
        .hitEntityId = -1,
        .hitDistance = FAR_PLANE,
        .hitPoint = simd_make_float3(0, 0, 0)
    };

    // Calculate shooting direction using camera basis
    CameraBasis shootBasis = computeCameraBasis(camYaw, camPitch);
    simd_float3 baseDir = shootBasis.forward;

    // Calculate muzzle position
    float gunOffsetX = 0.15f;
    float gunOffsetY = -0.12f;
    float gunOffsetZ = 0.3f + 0.25f;
    simd_float3 muzzle = camPos + shootBasis.right * gunOffsetX + shootBasis.up * gunOffsetY + shootBasis.forward * gunOffsetZ;

    // Try to fire using weapon system
    SpreadDirections spread;
    if (![weaponSystem fireCurrentWeapon:&spread withBaseDirection:baseDir]) {
        // Weapon couldn't fire (reloading, no ammo, etc.)
        return hitResult;
    }

    // Show muzzle flash
    state.muzzleFlashTimer = 2;

    // Get current weapon stats
    WeaponStats stats = [weaponSystem getCurrentWeaponStats];

    // Process each projectile
    for (int i = 0; i < spread.count; i++) {
        simd_float3 dir = spread.directions[i];

        CombatHitResult projHit = processProjectileHit(muzzle, dir, stats.damage, stats.range);

        // Track the closest/most important hit
        if (projHit.type != HitResultNone) {
            // Prefer remote player hits, then enemy hits
            if (hitResult.type == HitResultNone ||
                (projHit.type == HitResultRemotePlayer && hitResult.type != HitResultRemotePlayer) ||
                projHit.hitDistance < hitResult.hitDistance) {
                hitResult = projHit;
            }
        }

        // Handle splash damage for rocket launcher
        if (stats.splashRadius > 0 && projHit.hitDistance < stats.range) {
            simd_float3 splashPoint = muzzle + dir * projHit.hitDistance;
            applySplashDamage(splashPoint, stats.splashRadius, stats.splashDamage);
        }
    }

    return hitResult;
}

void updateHealthRegeneration(void) {
    GameState *state = [GameState shared];

    if (state.gameOver || state.playerHealth >= PLAYER_MAX_HEALTH) return;

    state.damageCooldownTimer++;
    if (state.damageCooldownTimer >= PLAYER_REGEN_DELAY) {
        state.regenTickTimer++;
        if (state.regenTickTimer >= PLAYER_REGEN_RATE) {
            state.regenTickTimer = 0;
            state.playerHealth++;
            if (state.bloodLevel > 0) {
                state.bloodLevel -= 0.02f;
                if (state.bloodLevel < 0) state.bloodLevel = 0;
            }
        }
    }
}

void updateCombatTimers(void) {
    GameState *state = [GameState shared];

    if (state.muzzleFlashTimer > 0) state.muzzleFlashTimer--;
    if (state.enemyMuzzleFlashTimer > 0) state.enemyMuzzleFlashTimer--;
    if (state.bloodFlashTimer > 0) state.bloodFlashTimer--;
    if (state.spawnProtectionTimer > 0) state.spawnProtectionTimer--;

    // Update weapon system timers (fire rate, reload)
    [[WeaponSystem shared] update];
}

// Apply damage when hit by a remote player
void applyDamageFromRemotePlayer(int damage) {
    GameState *state = [GameState shared];

    if (state.gameOver) return;

    // Check spawn protection - reduce damage by 90% if protected
    if (state.spawnProtectionTimer > 0) {
        damage = damage / 10;  // 90% damage reduction during spawn protection
        if (damage < 1) return;  // No damage if reduced to 0
    }

    // Apply armor damage reduction (50% reduction when armor > 0)
    int actualDamage = damage;
    if (state.playerArmor > 0) {
        // Armor absorbs half the damage
        int armorDamage = damage / 2;
        int healthDamage = damage - armorDamage;

        // Reduce armor
        state.playerArmor -= armorDamage;
        if (state.playerArmor < 0) {
            // Overflow damage goes to health
            healthDamage -= state.playerArmor;  // playerArmor is negative
            state.playerArmor = 0;
        }
        actualDamage = healthDamage;
    }

    // Apply damage to health
    state.playerHealth -= actualDamage;

    // Reset regeneration timer
    state.damageCooldownTimer = 0;
    state.regenTickTimer = 0;

    // Visual feedback
    state.bloodFlashTimer = 10;
    state.bloodLevel += 0.15f;
    if (state.bloodLevel > 1.0f) state.bloodLevel = 1.0f;

    // Check for death
    if (state.playerHealth <= 0) {
        state.playerHealth = 0;
        state.gameOver = YES;
    }
}

// Handle a player kill event (for stats tracking, UI updates, etc.)
void handlePlayerKill(int killerPlayerId, int victimPlayerId) {
    GameState *state = [GameState shared];

    // Update kill stats based on who got the kill
    if (killerPlayerId == state.localPlayerId) {
        // Local player got a kill
        state.localPlayerKills++;
    } else if (killerPlayerId == state.remotePlayerId) {
        // Remote player got a kill
        state.remotePlayerKills++;
    }

    // Handle death effects for victim
    if (victimPlayerId == state.localPlayerId) {
        // Local player died - start respawn timer
        state.gameOver = YES;
        state.localRespawnTimer = RESPAWN_DELAY;
    } else if (victimPlayerId == state.remotePlayerId) {
        // Remote player died - start their respawn timer
        state.remotePlayerAlive = NO;
        state.remoteRespawnTimer = RESPAWN_DELAY;
    }

    // Check win condition after kill
    [state checkWinCondition];
}

// Respawn a player after death
void respawnPlayer(int playerId) {
    GameState *state = [GameState shared];

    if (playerId == state.localPlayerId) {
        // Respawn local player
        state.playerHealth = PLAYER_MAX_HEALTH;
        state.gameOver = NO;
        state.bloodLevel = 0;
        state.bloodFlashTimer = 0;
        state.damageCooldownTimer = 0;
        state.regenTickTimer = 0;
        state.localRespawnTimer = 0;
        state.spawnProtectionTimer = SPAWN_PROTECTION_TIME;  // 3 seconds of spawn protection

        // Position reset is handled by the caller via resetPlayerWithPosX
        // which uses spawn points in multiplayer mode
    } else if (playerId == state.remotePlayerId) {
        // Remote player respawns - reset their state
        state.remotePlayerHealth = PLAYER_MAX_HEALTH;
        state.remotePlayerAlive = YES;
        state.remoteRespawnTimer = 0;

        // Remote player position is updated via network state sync
    }
}

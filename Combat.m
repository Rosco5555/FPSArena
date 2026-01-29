// Combat.m - Player shooting and damage implementation (with multiplayer PvP support)
#import "Combat.h"
#import "GameState.h"
#import "GameMath.h"
#import "Collision.h"
#import "DoorSystem.h"
#import "SoundManager.h"
#import <math.h>

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

CombatHitResult processPlayerShooting(simd_float3 camPos, float camYaw, float camPitch) {
    GameState *state = [GameState shared];

    // Initialize result
    CombatHitResult hitResult = {
        .type = HitResultNone,
        .hitEntityId = -1,
        .hitDistance = FAR_PLANE,
        .hitPoint = simd_make_float3(0, 0, 0)
    };

    // Calculate shooting direction using camera basis
    CameraBasis shootBasis = computeCameraBasis(camYaw, camPitch);
    simd_float3 dir = shootBasis.forward;

    // Calculate muzzle position
    float gunOffsetX = 0.15f;
    float gunOffsetY = -0.12f;
    float gunOffsetZ = 0.3f + 0.25f;
    simd_float3 muzzle = camPos + shootBasis.right * gunOffsetX + shootBasis.up * gunOffsetY + shootBasis.forward * gunOffsetZ;

    // Play sound and show flash
    state.muzzleFlashTimer = 2;
    [[SoundManager shared] playGunSound];

    // HITSCAN: find closest hit
    float maxDist = FAR_PLANE;

    // Check hit against house walls
    {
        float hw = HOUSE_WIDTH / 2.0f;
        float hd = HOUSE_DEPTH / 2.0f;
        float hx = HOUSE_X;
        float hz = HOUSE_Z;
        float fy = FLOOR_Y;
        float wh = HOUSE_WALL_HEIGHT;
        float wt = HOUSE_WALL_THICK;

        simd_float3 backMin = {hx - hw - wt, fy, hz - hd - wt};
        simd_float3 backMax = {hx + hw + wt, fy + wh, hz - hd};
        RayHitResult backHit = rayIntersectAABB(muzzle, dir, backMin, backMax);
        if (backHit.hit && backHit.t > 0 && backHit.t < maxDist) maxDist = backHit.t;

        simd_float3 leftMin = {hx - hw - wt, fy, hz - hd};
        simd_float3 leftMax = {hx - hw, fy + wh, hz + hd};
        RayHitResult leftHit = rayIntersectAABB(muzzle, dir, leftMin, leftMax);
        if (leftHit.hit && leftHit.t > 0 && leftHit.t < maxDist) maxDist = leftHit.t;

        simd_float3 rightMin = {hx + hw, fy, hz - hd};
        simd_float3 rightMax = {hx + hw + wt, fy + wh, hz + hd};
        RayHitResult rightHit = rayIntersectAABB(muzzle, dir, rightMin, rightMax);
        if (rightHit.hit && rightHit.t > 0 && rightHit.t < maxDist) maxDist = rightHit.t;

        float dw = DOOR_WIDTH / 2.0f;

        simd_float3 frontLeftMin = {hx - hw, fy, hz + hd};
        simd_float3 frontLeftMax = {hx - dw, fy + wh, hz + hd + wt};
        RayHitResult frontLeftHit = rayIntersectAABB(muzzle, dir, frontLeftMin, frontLeftMax);
        if (frontLeftHit.hit && frontLeftHit.t > 0 && frontLeftHit.t < maxDist) maxDist = frontLeftHit.t;

        simd_float3 frontRightMin = {hx + dw, fy, hz + hd};
        simd_float3 frontRightMax = {hx + hw, fy + wh, hz + hd + wt};
        RayHitResult frontRightHit = rayIntersectAABB(muzzle, dir, frontRightMin, frontRightMax);
        if (frontRightHit.hit && frontRightHit.t > 0 && frontRightHit.t < maxDist) maxDist = frontRightHit.t;

        simd_float3 aboveDoorMin = {hx - dw, fy + DOOR_HEIGHT, hz + hd};
        simd_float3 aboveDoorMax = {hx + dw, fy + wh, hz + hd + wt};
        RayHitResult aboveDoorHit = rayIntersectAABB(muzzle, dir, aboveDoorMin, aboveDoorMax);
        if (aboveDoorHit.hit && aboveDoorHit.t > 0 && aboveDoorHit.t < maxDist) maxDist = aboveDoorHit.t;

        simd_float3 doorMin, doorMax;
        getDoorAABB(&doorMin, &doorMax);
        RayHitResult doorHit = rayIntersectAABB(muzzle, dir, doorMin, doorMax);
        if (doorHit.hit && doorHit.t > 0 && doorHit.t < maxDist) maxDist = doorHit.t;
    }

    // Check hit against cover walls
    {
        float hw = WALL_WIDTH / 2.0f;
        float hh = WALL_HEIGHT / 2.0f;
        float hd = WALL_DEPTH / 2.0f;
        float w1y = FLOOR_Y + hh;
        float w2y = FLOOR_Y + hh;

        simd_float3 wall1Min = {WALL1_X - hw, w1y - hh, WALL1_Z - hd};
        simd_float3 wall1Max = {WALL1_X + hw, w1y + hh, WALL1_Z + hd};
        RayHitResult wall1Hit = rayIntersectAABB(muzzle, dir, wall1Min, wall1Max);
        if (wall1Hit.hit && wall1Hit.t < maxDist) maxDist = wall1Hit.t;

        simd_float3 wall2Min = {WALL2_X - hw, w2y - hh, WALL2_Z - hd};
        simd_float3 wall2Max = {WALL2_X + hw, w2y + hh, WALL2_Z + hd};
        RayHitResult wall2Hit = rayIntersectAABB(muzzle, dir, wall2Min, wall2Max);
        if (wall2Hit.hit && wall2Hit.t < maxDist) maxDist = wall2Hit.t;
    }

    // Check hit against enemies (AI)
    BOOL *enemyAlive = state.enemyAlive;
    int *enemyHealth = state.enemyHealth;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        if (enemyAlive[e]) {
            simd_float3 eMin = {enemyX[e] - 0.5f, enemyY[e] - 0.85f, enemyZ[e] - 0.2f};
            simd_float3 eMax = {enemyX[e] + 0.7f, enemyY[e] + 1.15f, enemyZ[e] + 0.2f};
            RayHitResult eHit = rayIntersectAABB(muzzle, dir, eMin, eMax);
            if (eHit.hit && eHit.t < maxDist) {
                enemyHealth[e] -= PLAYER_DAMAGE;
                if (enemyHealth[e] <= 0) enemyAlive[e] = NO;
                maxDist = eHit.t;

                // Record hit info
                hitResult.type = HitResultEnemyAI;
                hitResult.hitEntityId = e;
                hitResult.hitDistance = eHit.t;
                hitResult.hitPoint = muzzle + dir * eHit.t;
            }
        }
    }

    // Check hit against remote player in multiplayer mode
    if (state.isMultiplayer && state.remotePlayerAlive) {
        // Get remote player position
        simd_float3 remotePos = simd_make_float3(
            state.remotePlayerPosX,
            state.remotePlayerPosY,
            state.remotePlayerPosZ
        );

        float playerHitDist = 0;
        if (checkPlayerHit(muzzle, dir, remotePos, &playerHitDist)) {
            // Only count as hit if closer than any wall/environment hit
            if (playerHitDist < maxDist) {
                maxDist = playerHitDist;

                // Record hit info - remote player takes priority over AI if closer
                hitResult.type = HitResultRemotePlayer;
                hitResult.hitEntityId = state.remotePlayerId;
                hitResult.hitDistance = playerHitDist;
                hitResult.hitPoint = muzzle + dir * playerHitDist;

                // Note: Actual damage is applied via network message
                // The caller should send a hit notification to the server/remote player
            }
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
}

// Apply damage when hit by a remote player
void applyDamageFromRemotePlayer(int damage) {
    GameState *state = [GameState shared];

    if (state.gameOver) return;

    // Apply damage
    state.playerHealth -= damage;

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

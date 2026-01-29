// Enemy.m - Enemy AI and state implementation
#import "Enemy.h"
#import "Collision.h"
#import "DoorSystem.h"
#import "SoundManager.h"
#import <math.h>

BOOL checkEnemyLineOfSight(simd_float3 eMuzzle, simd_float3 eDir, float maxEnemyDist) {
    BOOL hasLineOfSight = YES;

    // Cover walls
    float cw = WALL_WIDTH / 2.0f;
    float cd = WALL_DEPTH / 2.0f;

    simd_float3 wall1Min = {WALL1_X - cw, FLOOR_Y, WALL1_Z - cd};
    simd_float3 wall1Max = {WALL1_X + cw, FLOOR_Y + WALL_HEIGHT, WALL1_Z + cd};
    RayHitResult wall1Hit = rayIntersectAABB(eMuzzle, eDir, wall1Min, wall1Max);
    if (wall1Hit.hit && wall1Hit.t > 0 && wall1Hit.t < maxEnemyDist) hasLineOfSight = NO;

    simd_float3 wall2Min = {WALL2_X - cw, FLOOR_Y, WALL2_Z - cd};
    simd_float3 wall2Max = {WALL2_X + cw, FLOOR_Y + WALL_HEIGHT, WALL2_Z + cd};
    RayHitResult wall2Hit = rayIntersectAABB(eMuzzle, eDir, wall2Min, wall2Max);
    if (wall2Hit.hit && wall2Hit.t > 0 && wall2Hit.t < maxEnemyDist) hasLineOfSight = NO;

    // House walls
    float hw = HOUSE_WIDTH / 2.0f;
    float hhd = HOUSE_DEPTH / 2.0f;
    float wt = HOUSE_WALL_THICK;
    float wh = HOUSE_WALL_HEIGHT;
    float dw = DOOR_WIDTH / 2.0f;

    // Back wall
    simd_float3 backMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hhd - wt};
    simd_float3 backMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z - hhd};
    RayHitResult backHit = rayIntersectAABB(eMuzzle, eDir, backMin, backMax);
    if (backHit.hit && backHit.t > 0 && backHit.t < maxEnemyDist) hasLineOfSight = NO;

    // Left wall
    simd_float3 leftMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hhd};
    simd_float3 leftMax = {HOUSE_X - hw, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult leftHit = rayIntersectAABB(eMuzzle, eDir, leftMin, leftMax);
    if (leftHit.hit && leftHit.t > 0 && leftHit.t < maxEnemyDist) hasLineOfSight = NO;

    // Right wall
    simd_float3 rightMin = {HOUSE_X + hw, FLOOR_Y, HOUSE_Z - hhd};
    simd_float3 rightMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult rightHit = rayIntersectAABB(eMuzzle, eDir, rightMin, rightMax);
    if (rightHit.hit && rightHit.t > 0 && rightHit.t < maxEnemyDist) hasLineOfSight = NO;

    // Front wall sections
    simd_float3 frontLeftMin = {HOUSE_X - hw, FLOOR_Y, HOUSE_Z + hhd};
    simd_float3 frontLeftMax = {HOUSE_X - dw, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult frontLeftHit = rayIntersectAABB(eMuzzle, eDir, frontLeftMin, frontLeftMax);
    if (frontLeftHit.hit && frontLeftHit.t > 0 && frontLeftHit.t < maxEnemyDist) hasLineOfSight = NO;

    simd_float3 frontRightMin = {HOUSE_X + dw, FLOOR_Y, HOUSE_Z + hhd};
    simd_float3 frontRightMax = {HOUSE_X + hw, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult frontRightHit = rayIntersectAABB(eMuzzle, eDir, frontRightMin, frontRightMax);
    if (frontRightHit.hit && frontRightHit.t > 0 && frontRightHit.t < maxEnemyDist) hasLineOfSight = NO;

    simd_float3 aboveDoorMin = {HOUSE_X - dw, FLOOR_Y + DOOR_HEIGHT, HOUSE_Z + hhd};
    simd_float3 aboveDoorMax = {HOUSE_X + dw, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult aboveDoorHit = rayIntersectAABB(eMuzzle, eDir, aboveDoorMin, aboveDoorMax);
    if (aboveDoorHit.hit && aboveDoorHit.t > 0 && aboveDoorHit.t < maxEnemyDist) hasLineOfSight = NO;

    // Door
    simd_float3 doorMin, doorMax;
    getDoorAABB(&doorMin, &doorMax);
    RayHitResult doorHit = rayIntersectAABB(eMuzzle, eDir, doorMin, doorMax);
    if (doorHit.hit && doorHit.t > 0 && doorHit.t < maxEnemyDist) hasLineOfSight = NO;

    return hasLineOfSight;
}

void updateEnemyAI(simd_float3 camPos, BOOL controlsActive) {
    GameState *state = [GameState shared];

    if (state.gameOver || !controlsActive) return;

    BOOL *enemyAlive = state.enemyAlive;
    int *enemyFireTimer = state.enemyFireTimer;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        if (!enemyAlive[e]) continue;

        enemyFireTimer[e]--;
        if (enemyFireTimer[e] <= 0) {
            enemyFireTimer[e] = ENEMY_FIRE_RATE_MIN + (rand() % ENEMY_FIRE_RATE_VAR);

            // Enemy gun muzzle position
            simd_float3 eMuzzle = {enemyX[e] + 0.5f, enemyY[e] + 0.28f, enemyZ[e]};

            // Aim at player center mass
            simd_float3 target = {camPos.x, camPos.y - 0.5f, camPos.z};

            // Calculate direction from muzzle to target
            simd_float3 delta = target - eMuzzle;
            float dist = simd_length(delta);

            if (dist > 0.1f && dist < 30.0f) {
                simd_float3 eDir = delta / dist;

                if (checkEnemyLineOfSight(eMuzzle, eDir, dist)) {
                    state.enemyMuzzlePos = eMuzzle;
                    state.enemyMuzzleFlashTimer = 4;
                    state.lastFiringEnemy = e;

                    // Play enemy gunshot with distance-based volume
                    float volume = 1.0f - (dist / 30.0f);
                    volume = fmaxf(0.1f, volume);
                    volume = volume * volume;
                    [[SoundManager shared] playEnemyGunSoundWithVolume:volume];

                    // Damage player
                    state.playerHealth -= ENEMY_DAMAGE;
                    state.damageCooldownTimer = 0;
                    state.bloodLevel += 0.25f;
                    if (state.bloodLevel > 1.0f) state.bloodLevel = 1.0f;
                    state.bloodFlashTimer = 8;

                    if (state.playerHealth <= 0) {
                        state.playerHealth = 0;
                        state.gameOver = YES;
                    }
                }
            }
        }
    }
}

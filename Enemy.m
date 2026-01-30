// Enemy.m - Enemy AI and state implementation
#import "Enemy.h"
#import "Collision.h"
#import "DoorSystem.h"
#import "SoundManager.h"
#import <math.h>

// Global bot AI state array
static BotAIState botAI[NUM_ENEMIES];

// Forward declarations for internal functions
static void updateBotBehavior(int e, simd_float3 camPos, float distToPlayer);
static void executeBotMovement(int e, simd_float3 camPos, float distToPlayer);
static void handleBotShooting(int e, simd_float3 camPos, float distToPlayer);
static simd_float3 getWaypointPosition(int index);
static simd_float3 getCoverPosition(int index);
static int findNearestCover(simd_float3 pos, simd_float3 playerPos);
static void applyBotPhysics(int e);
static BOOL canSeePlayer(int e, simd_float3 camPos);

// Check if a position is inside any spawn protection zone
static BOOL isInSpawnZone(float x, float z) {
    GameState *state = [GameState shared];
    SpawnPoint *spawnPoints = state.spawnPoints;

    for (int i = 0; i < NUM_SPAWN_POINTS; i++) {
        float dx = x - spawnPoints[i].x;
        float dz = z - spawnPoints[i].z;
        float dist = sqrtf(dx * dx + dz * dz);
        if (dist < SPAWN_PROTECTION_RADIUS) {
            return YES;
        }
    }
    return NO;
}

// Get direction to move away from nearest spawn zone
static simd_float3 getSpawnZoneAvoidanceDirection(float x, float z) {
    GameState *state = [GameState shared];
    SpawnPoint *spawnPoints = state.spawnPoints;

    float nearestDist = 999999.0f;
    int nearestSpawn = 0;

    for (int i = 0; i < NUM_SPAWN_POINTS; i++) {
        float dx = x - spawnPoints[i].x;
        float dz = z - spawnPoints[i].z;
        float dist = sqrtf(dx * dx + dz * dz);
        if (dist < nearestDist) {
            nearestDist = dist;
            nearestSpawn = i;
        }
    }

    // Direction away from nearest spawn point
    float dx = x - spawnPoints[nearestSpawn].x;
    float dz = z - spawnPoints[nearestSpawn].z;
    float len = sqrtf(dx * dx + dz * dz);
    if (len > 0.1f) {
        return (simd_float3){dx / len, 0, dz / len};
    }
    return (simd_float3){1, 0, 0};  // Default direction
}

// Move enemy away from spawn zone if too close
void enforceSpawnZoneExclusion(int e) {
    GameState *state = [GameState shared];
    float *enemyX = state.enemyX;
    float *enemyZ = state.enemyZ;

    if (isInSpawnZone(enemyX[e], enemyZ[e])) {
        simd_float3 avoidDir = getSpawnZoneAvoidanceDirection(enemyX[e], enemyZ[e]);
        // Push enemy out of spawn zone
        enemyX[e] += avoidDir.x * 0.15f;
        enemyZ[e] += avoidDir.z * 0.15f;
    }
}

// Initialize bot AI for all enemies
void initializeBotAI(void) {
    for (int e = 0; e < NUM_ENEMIES; e++) {
        int difficulty = ENEMY_DIFFICULTY[e];

        // Set stats based on difficulty
        botAI[e].stats.moveSpeed = BOT_MOVE_SPEED[difficulty];
        botAI[e].stats.accuracy = BOT_ACCURACY[difficulty];
        botAI[e].stats.reactionTime = BOT_REACTION_TIME[difficulty];
        botAI[e].stats.aggression = BOT_AGGRESSION[difficulty];

        // Initialize state
        botAI[e].behavior = BotBehaviorPatrol;
        botAI[e].currentWaypoint = e % NUM_WAYPOINTS;  // Start at different waypoints
        botAI[e].reactionTimer = 0;
        botAI[e].playerSpotted = NO;
        botAI[e].velocityX = 0.0f;
        botAI[e].velocityY = 0.0f;
        botAI[e].velocityZ = 0.0f;
        botAI[e].jumpCooldown = 0;
        botAI[e].strafeAngle = ((float)e / NUM_ENEMIES) * 2.0f * M_PI;
        botAI[e].strafeDirection = (e % 2 == 0) ? 1 : -1;
        botAI[e].coverTarget = -1;
        botAI[e].onGround = YES;

        // Initialize new rebalanced AI fields
        botAI[e].spottingTimer = 0;
        botAI[e].canShoot = NO;
        botAI[e].loseSightTimer = 0;

        // Staggered activation: only first few enemies active at start
        if (e < BOT_INITIAL_ACTIVE_COUNT) {
            botAI[e].isActive = YES;
            botAI[e].activationTimer = 0;
        } else {
            botAI[e].isActive = NO;
            // Stagger activation: each subsequent enemy activates 30 seconds after the previous
            botAI[e].activationTimer = (e - BOT_INITIAL_ACTIVE_COUNT + 1) * BOT_ACTIVATION_INTERVAL;
        }
    }
}

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

// Check if path is clear for movement
BOOL checkPathClear(simd_float3 start, simd_float3 end) {
    simd_float3 delta = end - start;
    float dist = simd_length(delta);
    if (dist < 0.1f) return YES;

    simd_float3 dir = delta / dist;
    return checkEnemyLineOfSight(start, dir, dist);
}

// Get distance to nearest obstacle
float getObstacleDistance(simd_float3 pos, simd_float3 dir) {
    float minDist = 100.0f;

    // Check cover walls
    float cw = WALL_WIDTH / 2.0f;
    float cd = WALL_DEPTH / 2.0f;

    simd_float3 wall1Min = {WALL1_X - cw, FLOOR_Y, WALL1_Z - cd};
    simd_float3 wall1Max = {WALL1_X + cw, FLOOR_Y + WALL_HEIGHT, WALL1_Z + cd};
    RayHitResult wall1Hit = rayIntersectAABB(pos, dir, wall1Min, wall1Max);
    if (wall1Hit.hit && wall1Hit.t > 0 && wall1Hit.t < minDist) minDist = wall1Hit.t;

    simd_float3 wall2Min = {WALL2_X - cw, FLOOR_Y, WALL2_Z - cd};
    simd_float3 wall2Max = {WALL2_X + cw, FLOOR_Y + WALL_HEIGHT, WALL2_Z + cd};
    RayHitResult wall2Hit = rayIntersectAABB(pos, dir, wall2Min, wall2Max);
    if (wall2Hit.hit && wall2Hit.t > 0 && wall2Hit.t < minDist) minDist = wall2Hit.t;

    // Check house walls
    float hw = HOUSE_WIDTH / 2.0f;
    float hhd = HOUSE_DEPTH / 2.0f;
    float wt = HOUSE_WALL_THICK;
    float wh = HOUSE_WALL_HEIGHT;

    simd_float3 backMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hhd - wt};
    simd_float3 backMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z - hhd};
    RayHitResult backHit = rayIntersectAABB(pos, dir, backMin, backMax);
    if (backHit.hit && backHit.t > 0 && backHit.t < minDist) minDist = backHit.t;

    simd_float3 leftMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hhd};
    simd_float3 leftMax = {HOUSE_X - hw, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult leftHit = rayIntersectAABB(pos, dir, leftMin, leftMax);
    if (leftHit.hit && leftHit.t > 0 && leftHit.t < minDist) minDist = leftHit.t;

    simd_float3 rightMin = {HOUSE_X + hw, FLOOR_Y, HOUSE_Z - hhd};
    simd_float3 rightMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z + hhd + wt};
    RayHitResult rightHit = rayIntersectAABB(pos, dir, rightMin, rightMax);
    if (rightHit.hit && rightHit.t > 0 && rightHit.t < minDist) minDist = rightHit.t;

    // Arena boundaries
    float botX = pos.x;
    float botZ = pos.z;
    if (dir.x > 0.01f) {
        float d = (ARENA_SIZE - botX) / dir.x;
        if (d > 0 && d < minDist) minDist = d;
    } else if (dir.x < -0.01f) {
        float d = (-ARENA_SIZE - botX) / dir.x;
        if (d > 0 && d < minDist) minDist = d;
    }
    if (dir.z > 0.01f) {
        float d = (ARENA_SIZE - botZ) / dir.z;
        if (d > 0 && d < minDist) minDist = d;
    } else if (dir.z < -0.01f) {
        float d = (-ARENA_SIZE - botZ) / dir.z;
        if (d > 0 && d < minDist) minDist = d;
    }

    return minDist;
}

// Get waypoint position by index
static simd_float3 getWaypointPosition(int index) {
    return (simd_float3){WAYPOINT_X[index], FLOOR_Y + 0.6f, WAYPOINT_Z[index]};
}

// Get cover position by index
static simd_float3 getCoverPosition(int index) {
    return (simd_float3){COVER_X[index], FLOOR_Y + 0.6f, COVER_Z[index]};
}

// Find nearest cover position that's away from player
static int findNearestCover(simd_float3 pos, simd_float3 playerPos) {
    int bestCover = 0;
    float bestScore = -999999.0f;

    for (int i = 0; i < NUM_COVER_POINTS; i++) {
        simd_float3 coverPos = getCoverPosition(i);
        float distToBot = simd_distance(pos, coverPos);
        float distToPlayer = simd_distance(playerPos, coverPos);

        // Score: prefer closer to bot, further from player
        float score = distToPlayer * 2.0f - distToBot;

        // Check if path to cover is clear
        if (checkPathClear(pos, coverPos) && score > bestScore) {
            bestScore = score;
            bestCover = i;
        }
    }

    return bestCover;
}

// Check if bot can see the player
static BOOL canSeePlayer(int e, simd_float3 camPos) {
    GameState *state = [GameState shared];

    simd_float3 botPos = {state.enemyX[e], state.enemyY[e] + 0.5f, state.enemyZ[e]};
    simd_float3 delta = camPos - botPos;
    float dist = simd_length(delta);

    if (dist < 0.1f || dist > BOT_DETECTION_RANGE) return NO;

    simd_float3 dir = delta / dist;
    return checkEnemyLineOfSight(botPos, dir, dist);
}

// Update bot behavior state machine
static void updateBotBehavior(int e, simd_float3 camPos, float distToPlayer) {
    GameState *state = [GameState shared];
    int *enemyHealth = state.enemyHealth;

    float healthPercent = (float)enemyHealth[e] / (float)ENEMY_MAX_HEALTH;

    // Check if player is within engagement distance AND visible
    BOOL withinEngagementRange = (distToPlayer <= BOT_ENGAGEMENT_DISTANCE);
    BOOL canSee = withinEngagementRange && canSeePlayer(e, camPos);

    // Update player spotted state with reaction time
    if (canSee && !botAI[e].playerSpotted) {
        botAI[e].reactionTimer++;
        botAI[e].loseSightTimer = 0;  // Reset lose sight timer when we can see player
        if (botAI[e].reactionTimer >= botAI[e].stats.reactionTime) {
            botAI[e].playerSpotted = YES;
        }
    } else if (!canSee) {
        // Lose track of player after losing sight for 3 seconds
        if (botAI[e].playerSpotted) {
            botAI[e].loseSightTimer++;
            if (botAI[e].loseSightTimer >= BOT_LOSE_SIGHT_TIMEOUT) {
                // Break off pursuit after 3 seconds of no sight
                botAI[e].playerSpotted = NO;
                botAI[e].reactionTimer = 0;
                botAI[e].spottingTimer = 0;
                botAI[e].canShoot = NO;
            }
        } else {
            // Not spotted yet, decay reaction timer
            if (botAI[e].reactionTimer > 0) {
                botAI[e].reactionTimer -= 2;  // Forget faster than notice
            }
        }
    }

    // Update spotting timer for shoot delay (bot must see player for 30+ frames before shooting)
    if (canSee && botAI[e].playerSpotted) {
        botAI[e].spottingTimer++;
        if (botAI[e].spottingTimer >= BOT_SPOTTING_DELAY) {
            botAI[e].canShoot = YES;
        }
    } else if (!canSee) {
        // Reset spotting timer when losing sight
        botAI[e].spottingTimer = 0;
        botAI[e].canShoot = NO;
    }

    // Health-based behavior changes (override combat behaviors)
    if (healthPercent <= BOT_RETREAT_HEALTH_THRESHOLD) {
        botAI[e].behavior = BotBehaviorRetreat;
        return;
    }

    if (healthPercent <= BOT_COVER_HEALTH_THRESHOLD && botAI[e].playerSpotted) {
        // Low aggression bots take cover, high aggression bots keep fighting
        if ((float)rand() / RAND_MAX > botAI[e].stats.aggression) {
            botAI[e].behavior = BotBehaviorTakeCover;
            if (botAI[e].coverTarget < 0) {
                simd_float3 botPos = {state.enemyX[e], state.enemyY[e], state.enemyZ[e]};
                botAI[e].coverTarget = findNearestCover(botPos, camPos);
            }
            return;
        }
    }

    // Combat behavior based on player visibility and distance
    if (botAI[e].playerSpotted) {
        // Chase-first behavior: bot must get close before shooting
        // When first spotting player, chase toward them before engaging in combat
        if (!botAI[e].canShoot) {
            // Haven't spotted long enough - chase toward player
            botAI[e].behavior = BotBehaviorChase;
        } else if (distToPlayer < BOT_STRAFE_RANGE) {
            botAI[e].behavior = BotBehaviorStrafe;
        } else if (distToPlayer < BOT_CHASE_RANGE) {
            botAI[e].behavior = BotBehaviorChase;
        } else {
            // Too far, patrol to get closer
            botAI[e].behavior = BotBehaviorPatrol;
        }
    } else {
        // No player spotted, patrol
        // Prefer patrol behavior longer before switching to chase
        botAI[e].behavior = BotBehaviorPatrol;
        botAI[e].coverTarget = -1;  // Reset cover target
    }
}

// Execute bot movement based on current behavior
static void executeBotMovement(int e, simd_float3 camPos, float distToPlayer) {
    GameState *state = [GameState shared];
    float *enemyX = state.enemyX;
    float *enemyZ = state.enemyZ;

    simd_float3 botPos = {enemyX[e], FLOOR_Y + 0.6f, enemyZ[e]};
    simd_float3 targetPos = botPos;
    float moveSpeed = botAI[e].stats.moveSpeed;

    switch (botAI[e].behavior) {
        case BotBehaviorPatrol: {
            // Move toward current waypoint
            targetPos = getWaypointPosition(botAI[e].currentWaypoint);
            float distToWaypoint = simd_distance(botPos, targetPos);

            // Reached waypoint, pick next one
            if (distToWaypoint < BOT_WAYPOINT_REACH_DIST) {
                botAI[e].currentWaypoint = (botAI[e].currentWaypoint + 1) % NUM_WAYPOINTS;
                targetPos = getWaypointPosition(botAI[e].currentWaypoint);
            }
            break;
        }

        case BotBehaviorChase: {
            // Move directly toward player
            targetPos = camPos;
            targetPos.y = FLOOR_Y + 0.6f;
            moveSpeed *= 1.2f;  // Slightly faster when chasing
            break;
        }

        case BotBehaviorStrafe: {
            // Circle-strafe around player
            botAI[e].strafeAngle += botAI[e].strafeDirection * 0.05f;
            float strafeRadius = 5.0f;
            targetPos.x = camPos.x + cosf(botAI[e].strafeAngle) * strafeRadius;
            targetPos.z = camPos.z + sinf(botAI[e].strafeAngle) * strafeRadius;
            targetPos.y = FLOOR_Y + 0.6f;

            // Occasionally change strafe direction
            if (rand() % 120 == 0) {
                botAI[e].strafeDirection *= -1;
            }
            break;
        }

        case BotBehaviorTakeCover: {
            // Move toward cover position
            if (botAI[e].coverTarget >= 0) {
                targetPos = getCoverPosition(botAI[e].coverTarget);
            }
            moveSpeed *= 1.3f;  // Move faster to cover
            break;
        }

        case BotBehaviorRetreat: {
            // Move away from player
            simd_float3 awayDir = botPos - camPos;
            awayDir.y = 0;
            float len = simd_length(awayDir);
            if (len > 0.1f) {
                awayDir = awayDir / len;
                targetPos = botPos + awayDir * 5.0f;
            }
            moveSpeed *= 1.4f;  // Run fast when retreating
            break;
        }
    }

    // Calculate desired movement direction
    simd_float3 moveDir = targetPos - botPos;
    moveDir.y = 0;  // Only move horizontally
    float moveDist = simd_length(moveDir);

    if (moveDist > 0.1f) {
        moveDir = moveDir / moveDist;

        // Check for obstacles ahead
        float obstacleDist = getObstacleDistance(botPos, moveDir);

        if (obstacleDist < 1.5f) {
            // Obstacle ahead, try to go around
            // Try turning left
            simd_float3 leftDir = {-moveDir.z, 0, moveDir.x};
            float leftDist = getObstacleDistance(botPos, leftDir);

            // Try turning right
            simd_float3 rightDir = {moveDir.z, 0, -moveDir.x};
            float rightDist = getObstacleDistance(botPos, rightDir);

            if (leftDist > rightDist && leftDist > 1.5f) {
                moveDir = leftDir;
            } else if (rightDist > 1.5f) {
                moveDir = rightDir;
            } else {
                // Stuck, try jumping
                if (botAI[e].onGround && botAI[e].jumpCooldown <= 0) {
                    botAI[e].velocityY = JUMP_VELOCITY * 0.8f;
                    botAI[e].onGround = NO;
                    botAI[e].jumpCooldown = BOT_JUMP_COOLDOWN;
                }
            }
        }

        // Apply acceleration toward target direction
        botAI[e].velocityX += moveDir.x * BOT_ACCELERATION;
        botAI[e].velocityZ += moveDir.z * BOT_ACCELERATION;

        // Clamp to max speed
        float currentSpeed = sqrtf(botAI[e].velocityX * botAI[e].velocityX +
                                   botAI[e].velocityZ * botAI[e].velocityZ);
        if (currentSpeed > moveSpeed) {
            float scale = moveSpeed / currentSpeed;
            botAI[e].velocityX *= scale;
            botAI[e].velocityZ *= scale;
        }
    }
}

// Apply physics to bot (gravity, friction, position updates)
static void applyBotPhysics(int e) {
    GameState *state = [GameState shared];
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    // Apply friction
    botAI[e].velocityX *= BOT_FRICTION;
    botAI[e].velocityZ *= BOT_FRICTION;

    // Apply gravity
    if (!botAI[e].onGround) {
        botAI[e].velocityY -= GRAVITY;
    }

    // Update position
    float newX = enemyX[e] + botAI[e].velocityX;
    float newY = enemyY[e] + botAI[e].velocityY;
    float newZ = enemyZ[e] + botAI[e].velocityZ;

    // Ground collision
    float groundY = FLOOR_Y + 0.6f;  // Enemy center height
    if (newY < groundY) {
        newY = groundY;
        botAI[e].velocityY = 0;
        botAI[e].onGround = YES;
    }

    // Update jump cooldown
    if (botAI[e].jumpCooldown > 0) {
        botAI[e].jumpCooldown--;
    }

    // Enemy collision radius (similar to player but for enemy center)
    float enemyRadius = 0.4f;
    float fy = FLOOR_Y;

    // Tower leg dimensions
    float ts = TOWER_SIZE / 2.0f;  // 1.5f half-size
    float legW = 0.3f;             // leg width from geometry

    // Constants for wall definitions
    float hw = CMD_BUILDING_WIDTH / 2.0f;
    float hd = CMD_BUILDING_DEPTH / 2.0f;
    float wt = CMD_WALL_THICK;
    float wh = CMD_BUILDING_HEIGHT;
    float dw = CMD_DOOR_WIDTH / 2.0f;
    float cw = WALL_WIDTH / 2.0f;
    float cd = WALL_DEPTH / 2.0f;

    // Comprehensive wall collision array matching Renderer.m player collision
    float walls[][6] = {
        // Command building walls (4 outer walls + doorway)
        {CMD_BUILDING_X - hw - wt, CMD_BUILDING_Z - hd - wt, CMD_BUILDING_X + hw + wt, CMD_BUILDING_Z - hd, fy, fy + wh},
        {CMD_BUILDING_X - hw - wt, CMD_BUILDING_Z - hd, CMD_BUILDING_X - hw, CMD_BUILDING_Z + hd + wt, fy, fy + wh},
        {CMD_BUILDING_X + hw, CMD_BUILDING_Z - hd, CMD_BUILDING_X + hw + wt, CMD_BUILDING_Z + hd + wt, fy, fy + wh},
        {CMD_BUILDING_X - hw, CMD_BUILDING_Z + hd, CMD_BUILDING_X - dw, CMD_BUILDING_Z + hd + wt, fy, fy + wh},
        {CMD_BUILDING_X + dw, CMD_BUILDING_Z + hd, CMD_BUILDING_X + hw, CMD_BUILDING_Z + hd + wt, fy, fy + wh},
        {CMD_BUILDING_X - dw, CMD_BUILDING_Z + hd, CMD_BUILDING_X + dw, CMD_BUILDING_Z + hd + wt, fy + CMD_DOOR_HEIGHT, fy + wh},
        // Legacy cover walls
        {WALL1_X - cw, WALL1_Z - cd, WALL1_X + cw, WALL1_Z + cd, fy, fy + WALL_HEIGHT},
        {WALL2_X - cw, WALL2_Z - cd, WALL2_X + cw, WALL2_Z + cd, fy, fy + WALL_HEIGHT},
        // Tower 1 (NE: 15,15) - 4 corner legs
        {TOWER_OFFSET - ts, TOWER_OFFSET - ts, TOWER_OFFSET - ts + legW, TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET + ts - legW, TOWER_OFFSET - ts, TOWER_OFFSET + ts, TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET - ts, TOWER_OFFSET + ts - legW, TOWER_OFFSET - ts + legW, TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET + ts - legW, TOWER_OFFSET + ts - legW, TOWER_OFFSET + ts, TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        // Tower 2 (NW: -15,15) - 4 corner legs
        {-TOWER_OFFSET - ts, TOWER_OFFSET - ts, -TOWER_OFFSET - ts + legW, TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET + ts - legW, TOWER_OFFSET - ts, -TOWER_OFFSET + ts, TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET - ts, TOWER_OFFSET + ts - legW, -TOWER_OFFSET - ts + legW, TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET + ts - legW, TOWER_OFFSET + ts - legW, -TOWER_OFFSET + ts, TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        // Tower 3 (SW: -15,-15) - 4 corner legs
        {-TOWER_OFFSET - ts, -TOWER_OFFSET - ts, -TOWER_OFFSET - ts + legW, -TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET + ts - legW, -TOWER_OFFSET - ts, -TOWER_OFFSET + ts, -TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET - ts, -TOWER_OFFSET + ts - legW, -TOWER_OFFSET - ts + legW, -TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        {-TOWER_OFFSET + ts - legW, -TOWER_OFFSET + ts - legW, -TOWER_OFFSET + ts, -TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        // Tower 4 (SE: 15,-15) - 4 corner legs
        {TOWER_OFFSET - ts, -TOWER_OFFSET - ts, TOWER_OFFSET - ts + legW, -TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET + ts - legW, -TOWER_OFFSET - ts, TOWER_OFFSET + ts, -TOWER_OFFSET - ts + legW, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET - ts, -TOWER_OFFSET + ts - legW, TOWER_OFFSET - ts + legW, -TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        {TOWER_OFFSET + ts - legW, -TOWER_OFFSET + ts - legW, TOWER_OFFSET + ts, -TOWER_OFFSET + ts, fy, PLATFORM_LEVEL},
        // Cargo containers (8 ground + 1 stacked)
        // Container 1: {8.0f, 4.0f, rotated=0}
        {8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, 8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 2: {8.5f, 6.5f, rotated=1}
        {8.5f - CONTAINER_WIDTH/2, 6.5f - CONTAINER_LENGTH/2, 8.5f + CONTAINER_WIDTH/2, 6.5f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 3: {-8.0f, 4.0f, rotated=0}
        {-8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 4: {-8.5f, 6.5f, rotated=1}
        {-8.5f - CONTAINER_WIDTH/2, 6.5f - CONTAINER_LENGTH/2, -8.5f + CONTAINER_WIDTH/2, 6.5f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 5: {6.0f, -8.0f, rotated=1}
        {6.0f - CONTAINER_WIDTH/2, -8.0f - CONTAINER_LENGTH/2, 6.0f + CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 6: {-6.0f, -8.0f, rotated=1}
        {-6.0f - CONTAINER_WIDTH/2, -8.0f - CONTAINER_LENGTH/2, -6.0f + CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 7: {0.0f, -12.0f, rotated=0}
        {0.0f - CONTAINER_LENGTH/2, -12.0f - CONTAINER_WIDTH/2, 0.0f + CONTAINER_LENGTH/2, -12.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
        // Container 8: {12.0f, 0.0f, rotated=1}
        {12.0f - CONTAINER_WIDTH/2, 0.0f - CONTAINER_LENGTH/2, 12.0f + CONTAINER_WIDTH/2, 0.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
        // Stacked container on top of container 1: {8.0f, 4.0f, rotated=0}
        {8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, 8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy + CONTAINER_HEIGHT, fy + CONTAINER_HEIGHT * 2},
        // Sandbag walls (10 positions)
        // Sandbag 1: {5.0f, 4.0f, rotated=0}
        {5.0f - SANDBAG_LENGTH/2, 4.0f - SANDBAG_THICK/2, 5.0f + SANDBAG_LENGTH/2, 4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 2: {-5.0f, 4.0f, rotated=0}
        {-5.0f - SANDBAG_LENGTH/2, 4.0f - SANDBAG_THICK/2, -5.0f + SANDBAG_LENGTH/2, 4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 3: {5.0f, -4.0f, rotated=0}
        {5.0f - SANDBAG_LENGTH/2, -4.0f - SANDBAG_THICK/2, 5.0f + SANDBAG_LENGTH/2, -4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 4: {-5.0f, -4.0f, rotated=0}
        {-5.0f - SANDBAG_LENGTH/2, -4.0f - SANDBAG_THICK/2, -5.0f + SANDBAG_LENGTH/2, -4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 5: {12.0f, 10.0f, rotated=1}
        {12.0f - SANDBAG_THICK/2, 10.0f - SANDBAG_LENGTH/2, 12.0f + SANDBAG_THICK/2, 10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 6: {-12.0f, 10.0f, rotated=1}
        {-12.0f - SANDBAG_THICK/2, 10.0f - SANDBAG_LENGTH/2, -12.0f + SANDBAG_THICK/2, 10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 7: {12.0f, -10.0f, rotated=1}
        {12.0f - SANDBAG_THICK/2, -10.0f - SANDBAG_LENGTH/2, 12.0f + SANDBAG_THICK/2, -10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 8: {-12.0f, -10.0f, rotated=1}
        {-12.0f - SANDBAG_THICK/2, -10.0f - SANDBAG_LENGTH/2, -12.0f + SANDBAG_THICK/2, -10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 9: {3.0f, 8.0f, rotated=1}
        {3.0f - SANDBAG_THICK/2, 8.0f - SANDBAG_LENGTH/2, 3.0f + SANDBAG_THICK/2, 8.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Sandbag 10: {-3.0f, 8.0f, rotated=1}
        {-3.0f - SANDBAG_THICK/2, 8.0f - SANDBAG_LENGTH/2, -3.0f + SANDBAG_THICK/2, 8.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
        // Arena boundary walls
        {-ARENA_SIZE - 0.5f, -ARENA_SIZE - 0.5f, -ARENA_SIZE, ARENA_SIZE + 0.5f, fy, fy + 10.0f},  // West wall
        {ARENA_SIZE, -ARENA_SIZE - 0.5f, ARENA_SIZE + 0.5f, ARENA_SIZE + 0.5f, fy, fy + 10.0f},    // East wall
        {-ARENA_SIZE - 0.5f, -ARENA_SIZE - 0.5f, ARENA_SIZE + 0.5f, -ARENA_SIZE, fy, fy + 10.0f},  // South wall
        {-ARENA_SIZE - 0.5f, ARENA_SIZE, ARENA_SIZE + 0.5f, ARENA_SIZE + 0.5f, fy, fy + 10.0f},    // North wall
        // Bunker entrance walls
        {BUNKER_X - BUNKER_STAIR_WIDTH/2 - 0.4f, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BUNKER_X - BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2, fy, fy + 1.0f},
        {BUNKER_X + BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BUNKER_X + BUNKER_STAIR_WIDTH/2 + 0.4f, BUNKER_Z + BUNKER_DEPTH/2, fy, fy + 1.0f},
    };
    int numWalls = 53;

    // Get enemy height for Y collision check
    float enemyFeetY = newY - 0.6f;  // Enemy is 1.2 units tall, center is 0.6 above feet
    float enemyHeadY = newY + 0.6f;

    // Check collision with all walls
    for (int i = 0; i < numWalls; i++) {
        float xMin = walls[i][0];
        float zMin = walls[i][1];
        float xMax = walls[i][2];
        float zMax = walls[i][3];
        float yMin = walls[i][4];
        float yMax = walls[i][5];

        // Check if enemy overlaps with wall (including radius)
        BOOL xOv = newX > xMin - enemyRadius && newX < xMax + enemyRadius;
        BOOL zOv = newZ > zMin - enemyRadius && newZ < zMax + enemyRadius;
        BOOL yOv = enemyFeetY < yMax && enemyHeadY > yMin;

        if (xOv && zOv && yOv) {
            // Calculate penetration depths from each side
            float penL = newX - (xMin - enemyRadius);
            float penR = (xMax + enemyRadius) - newX;
            float penN = newZ - (zMin - enemyRadius);
            float penF = (zMax + enemyRadius) - newZ;

            float minPenX = fminf(penL, penR);
            float minPenZ = fminf(penN, penF);

            // Push out along the axis with minimum penetration
            if (minPenX < minPenZ) {
                if (penL < penR) {
                    newX = xMin - enemyRadius;
                } else {
                    newX = xMax + enemyRadius;
                }
                botAI[e].velocityX = 0;
            } else {
                if (penN < penF) {
                    newZ = zMin - enemyRadius;
                } else {
                    newZ = zMax + enemyRadius;
                }
                botAI[e].velocityZ = 0;
            }
        }
    }

    // Also check door collision
    simd_float3 doorMin, doorMax;
    getDoorAABB(&doorMin, &doorMax);

    BOOL xOvDoor = newX > doorMin.x - enemyRadius && newX < doorMax.x + enemyRadius;
    BOOL zOvDoor = newZ > doorMin.z - enemyRadius && newZ < doorMax.z + enemyRadius;
    BOOL yOvDoor = enemyFeetY < doorMax.y && enemyHeadY > doorMin.y;

    if (xOvDoor && zOvDoor && yOvDoor) {
        float penL = newX - (doorMin.x - enemyRadius);
        float penR = (doorMax.x + enemyRadius) - newX;
        float penN = newZ - (doorMin.z - enemyRadius);
        float penF = (doorMax.z + enemyRadius) - newZ;

        float minPenX = fminf(penL, penR);
        float minPenZ = fminf(penN, penF);

        if (minPenX < minPenZ) {
            if (penL < penR) {
                newX = doorMin.x - enemyRadius;
            } else {
                newX = doorMax.x + enemyRadius;
            }
            botAI[e].velocityX = 0;
        } else {
            if (penN < penF) {
                newZ = doorMin.z - enemyRadius;
            } else {
                newZ = doorMax.z + enemyRadius;
            }
            botAI[e].velocityZ = 0;
        }
    }

    enemyX[e] = newX;
    enemyY[e] = newY;
    enemyZ[e] = newZ;
}

// Handle bot shooting
static void handleBotShooting(int e, simd_float3 camPos, float distToPlayer) {
    GameState *state = [GameState shared];
    int *enemyFireTimer = state.enemyFireTimer;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    // Only shoot if player is spotted and bot has completed spotting delay
    if (!botAI[e].playerSpotted) return;
    if (!botAI[e].canShoot) return;  // Must have spotted player for 30+ frames
    if (botAI[e].behavior == BotBehaviorPatrol) return;
    if (botAI[e].behavior == BotBehaviorRetreat) return;
    if (botAI[e].behavior == BotBehaviorChase) return;  // Chase first, then shoot

    // Don't engage beyond engagement distance
    if (distToPlayer > BOT_ENGAGEMENT_DISTANCE) return;

    enemyFireTimer[e]--;
    if (enemyFireTimer[e] <= 0) {
        // Reset fire timer with some randomness
        int baseRate = ENEMY_FIRE_RATE_MIN;
        // Harder bots shoot faster
        baseRate = (int)(baseRate * (2.0f - botAI[e].stats.aggression));
        enemyFireTimer[e] = baseRate + (rand() % ENEMY_FIRE_RATE_VAR);

        // Enemy gun muzzle position
        simd_float3 eMuzzle = {enemyX[e] + 0.5f, enemyY[e] + 0.28f, enemyZ[e]};

        // Aim at player center mass
        simd_float3 target = {camPos.x, camPos.y - 0.5f, camPos.z};

        // Calculate direction from muzzle to target
        simd_float3 delta = target - eMuzzle;
        float dist = simd_length(delta);

        if (dist > 0.1f && dist < 30.0f) {
            simd_float3 eDir = delta / dist;

            // Check line of sight before shooting
            if (checkEnemyLineOfSight(eMuzzle, eDir, dist)) {
                // Apply accuracy - add random spread based on bot accuracy
                float spread = (1.0f - botAI[e].stats.accuracy) * 0.3f;
                eDir.x += ((float)rand() / RAND_MAX - 0.5f) * spread;
                eDir.y += ((float)rand() / RAND_MAX - 0.5f) * spread;
                eDir.z += ((float)rand() / RAND_MAX - 0.5f) * spread;
                eDir = simd_normalize(eDir);

                // Check if shot would still hit player (accounting for accuracy)
                float hitChance = botAI[e].stats.accuracy;
                // Harder to hit at distance
                hitChance *= fmaxf(0.3f, 1.0f - (dist / 30.0f) * 0.5f);

                BOOL shotHits = ((float)rand() / RAND_MAX) < hitChance;

                state.enemyMuzzlePos = eMuzzle;
                state.enemyMuzzleFlashTimer = 4;
                state.lastFiringEnemy = e;

                // Play enemy gunshot with distance-based volume
                float volume = 1.0f - (dist / 30.0f);
                volume = fmaxf(0.1f, volume);
                volume = volume * volume;
                [[SoundManager shared] playEnemyGunSoundWithVolume:volume];

                // Only damage player if shot hits
                if (shotHits) {
                    int damage = ENEMY_DAMAGE;

                    // Check spawn protection - reduce damage by 90% if protected
                    if (state.spawnProtectionTimer > 0) {
                        damage = damage / 10;  // 90% damage reduction during spawn protection
                    }

                    // Skip if no damage after spawn protection
                    if (damage > 0) {
                        // Apply armor damage reduction (50% reduction when armor > 0)
                        if (state.playerArmor > 0) {
                            int armorDamage = damage / 2;
                            int healthDamage = damage - armorDamage;

                            state.playerArmor -= armorDamage;
                            if (state.playerArmor < 0) {
                                healthDamage -= state.playerArmor;
                                state.playerArmor = 0;
                            }
                            damage = healthDamage;
                        }

                        state.playerHealth -= damage;
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
}

void updateEnemyAI(simd_float3 camPos, BOOL controlsActive) {
    GameState *state = [GameState shared];

    if (state.gameOver || !controlsActive || state.isPaused) return;

    BOOL *enemyAlive = state.enemyAlive;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    int *enemyHealth = state.enemyHealth;
    int *enemyRespawnTimer = state.enemyRespawnTimer;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        // Handle enemy respawning
        if (!enemyAlive[e]) {
            if (enemyRespawnTimer[e] > 0) {
                enemyRespawnTimer[e]--;
                if (enemyRespawnTimer[e] == 0) {
                    // Respawn the enemy at their starting position
                    enemyAlive[e] = YES;
                    enemyHealth[e] = ENEMY_MAX_HEALTH;
                    enemyX[e] = ENEMY_START_X[e];
                    enemyY[e] = ENEMY_START_Y[e];
                    enemyZ[e] = ENEMY_START_Z[e];
                    botAI[e].velocityX = 0;
                    botAI[e].velocityY = 0;
                    botAI[e].velocityZ = 0;
                    botAI[e].playerSpotted = NO;
                    botAI[e].reactionTimer = 0;
                    botAI[e].spottingTimer = 0;
                    botAI[e].canShoot = NO;
                    botAI[e].onGround = YES;
                    botAI[e].isActive = YES;
                }
            }
            continue;
        }

        // Handle staggered activation - decrement timer and activate when ready
        if (!botAI[e].isActive) {
            if (botAI[e].activationTimer > 0) {
                botAI[e].activationTimer--;
            } else {
                botAI[e].isActive = YES;
            }
            continue;  // Skip AI update for inactive enemies
        }

        // Enforce spawn zone exclusion - enemies cannot enter spawn areas
        enforceSpawnZoneExclusion(e);

        // Calculate distance to player
        simd_float3 botPos = {enemyX[e], enemyY[e], enemyZ[e]};
        float distToPlayer = simd_distance(botPos, camPos);

        // Update behavior state
        updateBotBehavior(e, camPos, distToPlayer);

        // Execute movement based on behavior
        executeBotMovement(e, camPos, distToPlayer);

        // Apply physics
        applyBotPhysics(e);

        // Enforce spawn zone exclusion again after movement
        enforceSpawnZoneExclusion(e);

        // Handle shooting
        handleBotShooting(e, camPos, distToPlayer);
    }
}

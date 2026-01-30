// Enemy.h - Enemy AI and state
#ifndef ENEMY_H
#define ENEMY_H

#import <simd/simd.h>
#import "GameConfig.h"
#import "GameState.h"

// Bot behavior states
typedef enum {
    BotBehaviorPatrol = 0,    // Following waypoints around the map
    BotBehaviorChase,         // Actively pursuing player
    BotBehaviorStrafe,        // Circle-strafing while shooting
    BotBehaviorTakeCover,     // Moving to cover when low health
    BotBehaviorRetreat        // Running away when very low health
} BotBehavior;

// Bot stats structure
typedef struct {
    float moveSpeed;          // Movement speed (varies per difficulty)
    float accuracy;           // Accuracy (0.5 to 0.95)
    int reactionTime;         // Frames before reacting to player
    float aggression;         // How likely to chase vs take cover
} BotStats;

// Bot AI state structure
typedef struct {
    BotBehavior behavior;     // Current behavior state
    BotStats stats;           // Bot stats based on difficulty
    int currentWaypoint;      // Index of current patrol waypoint
    int reactionTimer;        // Countdown timer for reaction
    BOOL playerSpotted;       // Has the player been spotted
    float velocityX;          // Current velocity X
    float velocityY;          // Current velocity Y (for jumping)
    float velocityZ;          // Current velocity Z
    int jumpCooldown;         // Cooldown between jumps
    float strafeAngle;        // Current strafe angle around player
    int strafeDirection;      // 1 = clockwise, -1 = counter-clockwise
    int coverTarget;          // Index of target cover position
    BOOL onGround;            // Is the bot on the ground
    // New fields for rebalanced AI
    int spottingTimer;        // Frames player has been continuously visible
    BOOL canShoot;            // Has spotted player long enough to shoot
    int loseSightTimer;       // Frames since player was last seen
    BOOL isActive;            // Whether this enemy is currently active in the game
    int activationTimer;      // Timer until this enemy becomes active
} BotAIState;

// Initialize bot AI for all enemies
void initializeBotAI(void);

// Update enemy AI - handles movement, shooting, and behavior changes
void updateEnemyAI(simd_float3 camPos, BOOL controlsActive);

// Check line of sight from enemy muzzle to target
BOOL checkEnemyLineOfSight(simd_float3 eMuzzle, simd_float3 eDir, float maxDist);

// Check if there's a clear path between two points (for movement)
BOOL checkPathClear(simd_float3 start, simd_float3 end);

// Get distance to nearest obstacle in given direction
float getObstacleDistance(simd_float3 pos, simd_float3 dir);

// Enforce spawn zone exclusion - pushes enemy out of spawn protection zones
void enforceSpawnZoneExclusion(int enemyIndex);

#endif // ENEMY_H

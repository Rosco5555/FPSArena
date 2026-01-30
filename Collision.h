// Collision.h - Collision detection
#ifndef COLLISION_H
#define COLLISION_H

#import "GameTypes.h"
#import "GameConfig.h"

// Ray-AABB intersection test
RayHitResult rayIntersectAABB(simd_float3 rayOrigin, simd_float3 rayDir,
                              simd_float3 boxMin, simd_float3 boxMax);

// ============================================
// Collision System Types
// ============================================

// AABB structure for collision boxes
typedef struct {
    float minX, minY, minZ;
    float maxX, maxY, maxZ;
} CollisionAABB;

// Collision result from sweep test
typedef struct {
    bool hit;
    float tEntry;           // Time of entry (0-1 along movement)
    float tExit;            // Time of exit
    int hitAxis;            // 0=X, 1=Y, 2=Z, -1=none
    float hitNormal[3];     // Normal at hit point
    float penetration[3];   // Penetration depth on each axis
} SweepResult;

// Ground check result
typedef struct {
    bool onGround;
    float groundY;          // Y position of ground surface
    bool onPlatform;        // True if standing on elevated platform (not base floor)
} GroundCheckResult;

// ============================================
// Collision Detection Functions
// ============================================

// Check AABB vs AABB overlap
bool aabbOverlap(CollisionAABB a, CollisionAABB b);

// Get penetration depth between two overlapping AABBs
void aabbPenetration(CollisionAABB player, CollisionAABB obstacle,
                     float *penX, float *penY, float *penZ);

// Swept AABB collision - checks if moving AABB hits static AABB
SweepResult sweptAABB(CollisionAABB moving, float velX, float velY, float velZ,
                      CollisionAABB obstacle);

// Check if player (as AABB) is standing on top of a platform
// Returns true only if player's feet are at platform top and moving downward
bool isStandingOnPlatform(float playerFeetY, float playerVelY,
                          float platMinX, float platMinZ, float platMaxX, float platMaxZ,
                          float platTopY, float playerX, float playerZ, float tolerance);

// Ground raycast - check what's below the player
GroundCheckResult checkGroundBelow(float playerX, float playerFeetY, float playerZ,
                                   float playerVelY);

// Build player collision AABB from position (posY is eye level)
CollisionAABB makePlayerAABB(float posX, float posY, float posZ);

#endif // COLLISION_H

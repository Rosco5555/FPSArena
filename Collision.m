// Collision.m - Collision detection implementation
#import "Collision.h"
#import <math.h>

// Ray-AABB intersection using slab method
RayHitResult rayIntersectAABB(simd_float3 rayOrigin, simd_float3 rayDir,
                              simd_float3 boxMin, simd_float3 boxMax) {
    RayHitResult result = {NO, 0.0f};

    float tmin = -INFINITY;
    float tmax = INFINITY;

    // X axis
    if (fabsf(rayDir.x) > 0.0001f) {
        float t1 = (boxMin.x - rayOrigin.x) / rayDir.x;
        float t2 = (boxMax.x - rayOrigin.x) / rayDir.x;
        if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
        tmin = fmaxf(tmin, t1);
        tmax = fminf(tmax, t2);
    } else if (rayOrigin.x < boxMin.x || rayOrigin.x > boxMax.x) {
        return result;  // Ray parallel and outside
    }

    // Y axis
    if (fabsf(rayDir.y) > 0.0001f) {
        float t1 = (boxMin.y - rayOrigin.y) / rayDir.y;
        float t2 = (boxMax.y - rayOrigin.y) / rayDir.y;
        if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
        tmin = fmaxf(tmin, t1);
        tmax = fminf(tmax, t2);
    } else if (rayOrigin.y < boxMin.y || rayOrigin.y > boxMax.y) {
        return result;
    }

    // Z axis
    if (fabsf(rayDir.z) > 0.0001f) {
        float t1 = (boxMin.z - rayOrigin.z) / rayDir.z;
        float t2 = (boxMax.z - rayOrigin.z) / rayDir.z;
        if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
        tmin = fmaxf(tmin, t1);
        tmax = fminf(tmax, t2);
    } else if (rayOrigin.z < boxMin.z || rayOrigin.z > boxMax.z) {
        return result;
    }

    // Check for valid intersection
    if (tmin <= tmax && tmax > 0) {
        result.hit = YES;
        result.t = (tmin > 0) ? tmin : tmax;
    }

    return result;
}

// Check AABB vs AABB overlap
bool aabbOverlap(CollisionAABB a, CollisionAABB b) {
    return (a.minX <= b.maxX && a.maxX >= b.minX) &&
           (a.minY <= b.maxY && a.maxY >= b.minY) &&
           (a.minZ <= b.maxZ && a.maxZ >= b.minZ);
}

// Get penetration depth between two overlapping AABBs
void aabbPenetration(CollisionAABB player, CollisionAABB obstacle,
                     float *penX, float *penY, float *penZ) {
    float overlapMinX = fmaxf(player.minX, obstacle.minX);
    float overlapMaxX = fminf(player.maxX, obstacle.maxX);
    float overlapMinY = fmaxf(player.minY, obstacle.minY);
    float overlapMaxY = fminf(player.maxY, obstacle.maxY);
    float overlapMinZ = fmaxf(player.minZ, obstacle.minZ);
    float overlapMaxZ = fminf(player.maxZ, obstacle.maxZ);

    *penX = overlapMaxX - overlapMinX;
    *penY = overlapMaxY - overlapMinY;
    *penZ = overlapMaxZ - overlapMinZ;
}

// Swept AABB collision
SweepResult sweptAABB(CollisionAABB moving, float velX, float velY, float velZ,
                      CollisionAABB obstacle) {
    SweepResult result = {false, 1.0f, 1.0f, -1, {0, 0, 0}, {0, 0, 0}};

    // Expand obstacle by moving AABB half-sizes
    float hw = (moving.maxX - moving.minX) / 2.0f;
    float hh = (moving.maxY - moving.minY) / 2.0f;
    float hd = (moving.maxZ - moving.minZ) / 2.0f;

    CollisionAABB expanded = {
        obstacle.minX - hw, obstacle.minY - hh, obstacle.minZ - hd,
        obstacle.maxX + hw, obstacle.maxY + hh, obstacle.maxZ + hd
    };

    // Center of moving AABB
    float cx = (moving.minX + moving.maxX) / 2.0f;
    float cy = (moving.minY + moving.maxY) / 2.0f;
    float cz = (moving.minZ + moving.maxZ) / 2.0f;

    // Find entry and exit times for each axis
    float entryX, exitX, entryY, exitY, entryZ, exitZ;

    if (velX == 0.0f) {
        if (cx < expanded.minX || cx > expanded.maxX) return result;
        entryX = -INFINITY; exitX = INFINITY;
    } else {
        float t1 = (expanded.minX - cx) / velX;
        float t2 = (expanded.maxX - cx) / velX;
        entryX = fminf(t1, t2);
        exitX = fmaxf(t1, t2);
    }

    if (velY == 0.0f) {
        if (cy < expanded.minY || cy > expanded.maxY) return result;
        entryY = -INFINITY; exitY = INFINITY;
    } else {
        float t1 = (expanded.minY - cy) / velY;
        float t2 = (expanded.maxY - cy) / velY;
        entryY = fminf(t1, t2);
        exitY = fmaxf(t1, t2);
    }

    if (velZ == 0.0f) {
        if (cz < expanded.minZ || cz > expanded.maxZ) return result;
        entryZ = -INFINITY; exitZ = INFINITY;
    } else {
        float t1 = (expanded.minZ - cz) / velZ;
        float t2 = (expanded.maxZ - cz) / velZ;
        entryZ = fminf(t1, t2);
        exitZ = fmaxf(t1, t2);
    }

    float entryTime = fmaxf(fmaxf(entryX, entryY), entryZ);
    float exitTime = fminf(fminf(exitX, exitY), exitZ);

    // No collision
    if (entryTime > exitTime || entryTime > 1.0f || exitTime < 0.0f) {
        return result;
    }

    result.hit = true;
    result.tEntry = fmaxf(0.0f, entryTime);
    result.tExit = fminf(1.0f, exitTime);

    // Determine which axis was hit first
    if (entryX > entryY && entryX > entryZ) {
        result.hitAxis = 0;
        result.hitNormal[0] = (velX > 0) ? -1.0f : 1.0f;
    } else if (entryY > entryZ) {
        result.hitAxis = 1;
        result.hitNormal[1] = (velY > 0) ? -1.0f : 1.0f;
    } else {
        result.hitAxis = 2;
        result.hitNormal[2] = (velZ > 0) ? -1.0f : 1.0f;
    }

    return result;
}

// Check if player is standing on a platform
bool isStandingOnPlatform(float playerFeetY, float playerVelY,
                          float platMinX, float platMinZ, float platMaxX, float platMaxZ,
                          float platTopY, float playerX, float playerZ, float tolerance) {
    // Check horizontal bounds
    if (playerX < platMinX || playerX > platMaxX) return false;
    if (playerZ < platMinZ || playerZ > platMaxZ) return false;

    // Check if feet are at platform level (with tolerance) and not moving up fast
    float distAbove = playerFeetY - platTopY;
    return (distAbove >= -tolerance && distAbove <= tolerance && playerVelY <= 0.01f);
}

// Ground raycast
GroundCheckResult checkGroundBelow(float playerX, float playerFeetY, float playerZ,
                                   float playerVelY) {
    GroundCheckResult result = {false, FLOOR_Y, false};

    // Basic floor check
    if (playerFeetY <= FLOOR_Y + 0.1f) {
        result.onGround = true;
        result.groundY = FLOOR_Y;
        result.onPlatform = false;
    }

    return result;
}

// Build player AABB from eye position
CollisionAABB makePlayerAABB(float posX, float posY, float posZ) {
    CollisionAABB aabb;
    aabb.minX = posX - PLAYER_RADIUS;
    aabb.maxX = posX + PLAYER_RADIUS;
    aabb.minY = posY - PLAYER_HEIGHT;
    aabb.maxY = posY + 0.1f;  // Small margin above eyes
    aabb.minZ = posZ - PLAYER_RADIUS;
    aabb.maxZ = posZ + PLAYER_RADIUS;
    return aabb;
}

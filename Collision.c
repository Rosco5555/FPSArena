// Collision.c - Collision detection implementation
#import "Collision.h"
#import <math.h>

RayHitResult rayIntersectAABB(simd_float3 rayOrigin, simd_float3 rayDir,
                              simd_float3 boxMin, simd_float3 boxMax) {
    float tmin = -INFINITY, tmax = INFINITY;
    float rayO[3] = {rayOrigin.x, rayOrigin.y, rayOrigin.z};
    float rayD[3] = {rayDir.x, rayDir.y, rayDir.z};
    float bMin[3] = {boxMin.x, boxMin.y, boxMin.z};
    float bMax[3] = {boxMax.x, boxMax.y, boxMax.z};

    for (int axis = 0; axis < 3; axis++) {
        if (fabsf(rayD[axis]) > 0.0001f) {
            float t1 = (bMin[axis] - rayO[axis]) / rayD[axis];
            float t2 = (bMax[axis] - rayO[axis]) / rayD[axis];
            if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
            if (t1 > tmin) tmin = t1;
            if (t2 < tmax) tmax = t2;
        }
    }

    RayHitResult result;
    result.hit = (tmin <= tmax && tmax > 0);
    result.t = tmin > 0 ? tmin : tmax;
    return result;
}

// ============================================
// AABB Collision Functions
// ============================================

bool aabbOverlap(CollisionAABB a, CollisionAABB b) {
    return (a.minX <= b.maxX && a.maxX >= b.minX &&
            a.minY <= b.maxY && a.maxY >= b.minY &&
            a.minZ <= b.maxZ && a.maxZ >= b.minZ);
}

void aabbPenetration(CollisionAABB player, CollisionAABB obstacle,
                     float *penX, float *penY, float *penZ) {
    // Calculate penetration depth on each axis
    // Positive = push in positive direction, negative = push in negative direction
    float overlapLeft = player.maxX - obstacle.minX;   // How much player extends into left of obstacle
    float overlapRight = obstacle.maxX - player.minX;  // How much player extends into right of obstacle
    float overlapBottom = player.maxY - obstacle.minY;
    float overlapTop = obstacle.maxY - player.minY;
    float overlapBack = player.maxZ - obstacle.minZ;
    float overlapFront = obstacle.maxZ - player.minZ;

    // Choose smallest penetration direction for each axis
    *penX = (overlapLeft < overlapRight) ? -overlapLeft : overlapRight;
    *penY = (overlapBottom < overlapTop) ? -overlapBottom : overlapTop;
    *penZ = (overlapBack < overlapFront) ? -overlapBack : overlapFront;
}

SweepResult sweptAABB(CollisionAABB moving, float velX, float velY, float velZ,
                      CollisionAABB obstacle) {
    SweepResult result = {false, 1.0f, 1.0f, -1, {0, 0, 0}, {0, 0, 0}};

    // Minkowski sum - expand obstacle by moving box size
    CollisionAABB expanded;
    float halfW = (moving.maxX - moving.minX) / 2.0f;
    float halfH = (moving.maxY - moving.minY) / 2.0f;
    float halfD = (moving.maxZ - moving.minZ) / 2.0f;

    expanded.minX = obstacle.minX - halfW;
    expanded.maxX = obstacle.maxX + halfW;
    expanded.minY = obstacle.minY - halfH;
    expanded.maxY = obstacle.maxY + halfH;
    expanded.minZ = obstacle.minZ - halfD;
    expanded.maxZ = obstacle.maxZ + halfD;

    // Ray from center of moving box
    float centerX = (moving.minX + moving.maxX) / 2.0f;
    float centerY = (moving.minY + moving.maxY) / 2.0f;
    float centerZ = (moving.minZ + moving.maxZ) / 2.0f;

    // Entry and exit times for each axis
    float tEntryX, tEntryY, tEntryZ;
    float tExitX, tExitY, tExitZ;

    // X axis
    if (fabsf(velX) < 0.0001f) {
        if (centerX < expanded.minX || centerX > expanded.maxX) {
            return result; // No collision possible
        }
        tEntryX = -INFINITY;
        tExitX = INFINITY;
    } else {
        float invVelX = 1.0f / velX;
        tEntryX = (velX > 0 ? expanded.minX - centerX : expanded.maxX - centerX) * invVelX;
        tExitX = (velX > 0 ? expanded.maxX - centerX : expanded.minX - centerX) * invVelX;
    }

    // Y axis
    if (fabsf(velY) < 0.0001f) {
        if (centerY < expanded.minY || centerY > expanded.maxY) {
            return result;
        }
        tEntryY = -INFINITY;
        tExitY = INFINITY;
    } else {
        float invVelY = 1.0f / velY;
        tEntryY = (velY > 0 ? expanded.minY - centerY : expanded.maxY - centerY) * invVelY;
        tExitY = (velY > 0 ? expanded.maxY - centerY : expanded.minY - centerY) * invVelY;
    }

    // Z axis
    if (fabsf(velZ) < 0.0001f) {
        if (centerZ < expanded.minZ || centerZ > expanded.maxZ) {
            return result;
        }
        tEntryZ = -INFINITY;
        tExitZ = INFINITY;
    } else {
        float invVelZ = 1.0f / velZ;
        tEntryZ = (velZ > 0 ? expanded.minZ - centerZ : expanded.maxZ - centerZ) * invVelZ;
        tExitZ = (velZ > 0 ? expanded.maxZ - centerZ : expanded.minZ - centerZ) * invVelZ;
    }

    // Find latest entry time and earliest exit time
    float tEntry = fmaxf(fmaxf(tEntryX, tEntryY), tEntryZ);
    float tExit = fminf(fminf(tExitX, tExitY), tExitZ);

    // Check if there's a valid collision
    if (tEntry > tExit || tEntry > 1.0f || tExit < 0.0f) {
        return result;
    }

    result.hit = true;
    result.tEntry = fmaxf(0.0f, tEntry);
    result.tExit = fminf(1.0f, tExit);

    // Determine which axis we hit first
    if (tEntryX >= tEntryY && tEntryX >= tEntryZ) {
        result.hitAxis = 0;
        result.hitNormal[0] = velX > 0 ? -1.0f : 1.0f;
        result.hitNormal[1] = 0;
        result.hitNormal[2] = 0;
    } else if (tEntryY >= tEntryX && tEntryY >= tEntryZ) {
        result.hitAxis = 1;
        result.hitNormal[0] = 0;
        result.hitNormal[1] = velY > 0 ? -1.0f : 1.0f;
        result.hitNormal[2] = 0;
    } else {
        result.hitAxis = 2;
        result.hitNormal[0] = 0;
        result.hitNormal[1] = 0;
        result.hitNormal[2] = velZ > 0 ? -1.0f : 1.0f;
    }

    return result;
}

bool isStandingOnPlatform(float playerFeetY, float playerVelY,
                          float platMinX, float platMinZ, float platMaxX, float platMaxZ,
                          float platTopY, float playerX, float playerZ, float tolerance) {
    // Check horizontal bounds (with player radius)
    if (playerX < platMinX - PLAYER_RADIUS || playerX > platMaxX + PLAYER_RADIUS ||
        playerZ < platMinZ - PLAYER_RADIUS || playerZ > platMaxZ + PLAYER_RADIUS) {
        return false;
    }

    // Check if feet are at platform level (within tolerance) and falling or stationary
    float feetDist = playerFeetY - platTopY;
    if (feetDist >= -tolerance && feetDist <= tolerance && playerVelY <= 0.001f) {
        return true;
    }

    return false;
}

CollisionAABB makePlayerAABB(float posX, float posY, float posZ) {
    CollisionAABB box;
    box.minX = posX - PLAYER_RADIUS;
    box.maxX = posX + PLAYER_RADIUS;
    box.minY = posY - PLAYER_HEIGHT;  // posY is eye level
    box.maxY = posY + 0.1f;            // Small margin above eyes
    box.minZ = posZ - PLAYER_RADIUS;
    box.maxZ = posZ + PLAYER_RADIUS;
    return box;
}

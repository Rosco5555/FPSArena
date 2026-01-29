// Collision.h - Collision detection
#ifndef COLLISION_H
#define COLLISION_H

#import "GameTypes.h"

// Ray-AABB intersection test
RayHitResult rayIntersectAABB(simd_float3 rayOrigin, simd_float3 rayDir,
                              simd_float3 boxMin, simd_float3 boxMax);

#endif // COLLISION_H

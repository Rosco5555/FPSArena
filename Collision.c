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

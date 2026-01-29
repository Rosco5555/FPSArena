// GameTypes.h - Common types and structures
#ifndef GAMETYPES_H
#define GAMETYPES_H

#import <simd/simd.h>
#import <stdbool.h>

// Use bool for C compatibility, BOOL for Objective-C
#ifndef __OBJC__
typedef bool BOOL;
#define YES true
#define NO false
#endif

// Vertex structure for rendering
typedef struct {
    simd_float3 position;
    simd_float3 color;
} Vertex;

// Ray-AABB intersection result
typedef struct {
    BOOL hit;
    float t;  // distance to hit
} RayHitResult;

// Camera basis vectors
typedef struct {
    simd_float3 forward;
    simd_float3 right;
    simd_float3 up;
} CameraBasis;

// Identity matrix constant
static const simd_float4x4 IDENTITY_MATRIX = {{
    {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}
}};

#endif // GAMETYPES_H

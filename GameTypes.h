// GameTypes.h - Common types and structures
#ifndef GAMETYPES_H
#define GAMETYPES_H

#import <simd/simd.h>
#import <stdbool.h>

// For Objective-C, BOOL is already defined by the runtime
// For pure C, we need to define it
#ifdef __OBJC__
#import <objc/objc.h>  // Provides BOOL, YES, NO in Objective-C
#else
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

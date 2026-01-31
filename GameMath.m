// GameMath.m - Math utilities implementation
#import "GameMath.h"
#import <math.h>

CameraBasis computeCameraBasis(float yaw, float pitch) {
    CameraBasis basis;

    // Forward vector from yaw and pitch
    basis.forward = simd_make_float3(
        sinf(yaw) * cosf(pitch),
        sinf(pitch),
        -cosf(yaw) * cosf(pitch)
    );

    // Right vector (perpendicular to forward on XZ plane)
    basis.right = simd_make_float3(
        cosf(yaw),
        0.0f,
        sinf(yaw)
    );

    // Up vector (cross product of right and forward)
    basis.up = simd_cross(basis.right, basis.forward);

    return basis;
}

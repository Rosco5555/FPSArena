// GameMath.c - Math utilities implementation
#import "GameMath.h"
#import <math.h>

CameraBasis computeCameraBasis(float yaw, float pitch) {
    CameraBasis basis;
    basis.forward = (simd_float3){
        sinf(yaw) * cosf(pitch),
        sinf(pitch),
        -cosf(yaw) * cosf(pitch)
    };
    basis.right = (simd_float3){cosf(yaw), 0, sinf(yaw)};
    basis.up = simd_cross(basis.right, basis.forward);
    return basis;
}

// DoorSystem.m - Door AABB and animation implementation
#import "DoorSystem.h"
#import <math.h>

void getDoorAABB(simd_float3 *outMin, simd_float3 *outMax) {
    GameState *state = [GameState shared];
    float doorAngle = state.doorAngle;

    float hingeX = HOUSE_X - DOOR_WIDTH / 2.0f;
    float hingeZ = HOUSE_Z + HOUSE_DEPTH / 2.0f;
    float fy = FLOOR_Y;

    if (doorAngle < 45.0f) {
        // Closed position - door in doorframe
        *outMin = (simd_float3){hingeX, fy, hingeZ};
        *outMax = (simd_float3){hingeX + DOOR_WIDTH, fy + DOOR_HEIGHT, hingeZ + DOOR_THICK};
    } else {
        // Open position - door swung out perpendicular
        *outMin = (simd_float3){hingeX - DOOR_THICK, fy, hingeZ};
        *outMax = (simd_float3){hingeX, fy + DOOR_HEIGHT, hingeZ + DOOR_WIDTH};
    }
}

void updateDoorAnimation(void) {
    GameState *state = [GameState shared];

    if (state.doorOpen && state.doorAngle < 90.0f) {
        state.doorAngle += 4.0f;
        if (state.doorAngle > 90.0f) state.doorAngle = 90.0f;
    } else if (!state.doorOpen && state.doorAngle > 0.0f) {
        state.doorAngle -= 4.0f;
        if (state.doorAngle < 0.0f) state.doorAngle = 0.0f;
    }
}

BOOL checkPlayerNearDoor(simd_float3 camPos) {
    float doorCenterX = HOUSE_X;
    float doorCenterZ = HOUSE_Z + HOUSE_DEPTH / 2.0f;
    float dx = camPos.x - doorCenterX;
    float dz = camPos.z - doorCenterZ;
    float distToDoor = sqrtf(dx * dx + dz * dz);
    return (distToDoor < 2.5f);
}

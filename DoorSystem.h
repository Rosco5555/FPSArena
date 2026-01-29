// DoorSystem.h - Door AABB and animation
#ifndef DOORSYSTEM_H
#define DOORSYSTEM_H

#import <simd/simd.h>
#import "GameConfig.h"
#import "GameState.h"

// Get door AABB based on current angle
void getDoorAABB(simd_float3 *outMin, simd_float3 *outMax);

// Update door animation
void updateDoorAnimation(void);

// Check if player is near door
BOOL checkPlayerNearDoor(simd_float3 camPos);

#endif // DOORSYSTEM_H

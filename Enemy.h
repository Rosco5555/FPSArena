// Enemy.h - Enemy AI and state
#ifndef ENEMY_H
#define ENEMY_H

#import <simd/simd.h>
#import "GameConfig.h"
#import "GameState.h"

// Update enemy AI - handles shooting at player
void updateEnemyAI(simd_float3 camPos, BOOL controlsActive);

// Check line of sight from enemy muzzle to target
BOOL checkEnemyLineOfSight(simd_float3 eMuzzle, simd_float3 eDir, float maxDist);

#endif // ENEMY_H

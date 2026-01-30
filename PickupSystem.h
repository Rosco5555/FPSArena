// PickupSystem.h - Ammo, weapon, health, and armor pickup system
#ifndef PICKUPSYSTEM_H
#define PICKUPSYSTEM_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "GameConfig.h"

// Pickup types
typedef enum {
    PickupTypeHealthPack = 0,    // Restores 50 health
    PickupTypeAmmoSmall,         // Pistol/rifle ammo
    PickupTypeAmmoHeavy,         // Shotgun/rocket ammo
    PickupTypeShotgun,           // Gives shotgun if don't have
    PickupTypeAssaultRifle,      // Gives assault rifle
    PickupTypeRocketLauncher,    // Gives rocket launcher
    PickupTypeArmor              // Adds 50 armor (reduces damage by 50%)
} PickupType;

// Pickup constants
static const int MAX_PICKUPS = 15;
static const float PICKUP_RESPAWN_TIME = 30.0f * 60.0f;  // 30 seconds at 60fps = 1800 frames
static const float PICKUP_COLLECT_RADIUS = 1.0f;
static const float PICKUP_BOB_SPEED = 0.05f;
static const float PICKUP_BOB_HEIGHT = 0.15f;
static const float PICKUP_ROTATE_SPEED = 0.02f;

// Health/armor values
static const int HEALTH_PACK_AMOUNT = 50;
static const int ARMOR_PACK_AMOUNT = 50;
static const int MAX_ARMOR = 100;

// Ammo amounts
static const int AMMO_SMALL_AMOUNT = 30;
static const int AMMO_HEAVY_AMOUNT = 10;

// Pickup structure
typedef struct {
    PickupType type;
    float x, y, z;              // Base position
    BOOL isActive;              // Whether pickup can be collected
    float respawnTimer;         // Countdown until respawn
    float bobOffset;            // Current bob animation offset
    float rotationAngle;        // Current rotation angle
} Pickup;

// Pickup result structure (returned when collecting a pickup)
typedef struct {
    BOOL collected;
    PickupType type;
    int amount;                 // Amount of health/armor/ammo restored/given
} PickupResult;

@interface PickupSystem : NSObject

+ (instancetype)shared;

// Core methods
- (void)initializePickups;
- (void)updatePickups:(float)deltaTime;
- (PickupResult)checkPlayerPickup:(simd_float3)playerPosition;

// Pickup data access for rendering
- (int)getPickupCount;
- (Pickup *)getPickup:(int)index;

// Reset for new game
- (void)resetPickups;

@end

#endif // PICKUPSYSTEM_H

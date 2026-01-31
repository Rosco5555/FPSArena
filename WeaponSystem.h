// WeaponSystem.h - Multi-weapon system for FPS game
#ifndef WEAPONSYSTEM_H
#define WEAPONSYSTEM_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "GameConfig.h"

// Weapon type enumeration
typedef enum {
    WeaponTypePistol = 0,       // Default, unlimited ammo, medium fire rate
    WeaponTypeShotgun,          // Slow fire rate, spread pattern
    WeaponTypeAssaultRifle,     // Fast fire rate, large magazine
    WeaponTypeRocketLauncher,   // Slow, high damage + splash
    WeaponTypeCount             // Number of weapon types
} WeaponType;

// Maximum number of spread directions (for shotgun pellets)
#define MAX_SPREAD_DIRECTIONS 8

// Weapon statistics structure
typedef struct {
    int damage;                 // Damage per projectile/pellet
    int fireRate;               // Frames between shots (lower = faster)
    float spread;               // Spread angle in radians (0 = perfectly accurate)
    int projectileCount;        // Number of projectiles per shot (1 for most, 8 for shotgun)
    int magSize;                // Magazine size (0 = unlimited)
    int maxReserve;             // Maximum reserve ammo (0 = unlimited)
    int reloadTime;             // Frames to reload (60 frames = 1 second at 60fps)
    float range;                // Maximum effective range
    float splashRadius;         // Splash damage radius (0 = no splash)
    int splashDamage;           // Splash damage amount
} WeaponStats;

// Weapon state structure
typedef struct {
    WeaponType currentWeapon;
    int currentAmmo[WeaponTypeCount];   // Ammo in current magazine for each weapon
    int reserveAmmo[WeaponTypeCount];   // Reserve ammo for each weapon
    BOOL isReloading;
    int reloadTimer;                     // Frames remaining in reload
    int fireTimer;                       // Frames until can fire again
} WeaponState;

// Spread direction result (for shotgun and other spread weapons)
typedef struct {
    int count;                           // Number of directions
    simd_float3 directions[MAX_SPREAD_DIRECTIONS];
} SpreadDirections;

// Weapon system singleton
@interface WeaponSystem : NSObject

+ (instancetype)shared;

// Current weapon state
@property (nonatomic, readonly) WeaponState *weaponState;

// Switch to a specific weapon
- (BOOL)switchWeapon:(WeaponType)weaponType;

// Fire the current weapon - returns spread directions for multi-projectile weapons
// Returns YES if weapon fired successfully
- (BOOL)fireCurrentWeapon:(SpreadDirections *)outSpread
           withBaseDirection:(simd_float3)baseDir;

// Start reloading the current weapon
- (BOOL)reload;

// Update weapon timers (call once per frame)
- (void)update;

// Add ammo for a specific weapon type
- (void)addAmmo:(WeaponType)weaponType amount:(int)amount;

// Get stats for a specific weapon type
- (WeaponStats)getWeaponStats:(WeaponType)weaponType;

// Get stats for the current weapon
- (WeaponStats)getCurrentWeaponStats;

// Get the current weapon type
- (WeaponType)getCurrentWeapon;

// Check if current weapon can fire
- (BOOL)canFire;

// Check if current weapon needs reloading
- (BOOL)needsReload;

// Check if current weapon is reloading
- (BOOL)isReloading;

// Get ammo display string for HUD
- (NSString *)getAmmoDisplayString;

// Get current ammo in magazine
- (int)getCurrentAmmo;

// Get reserve ammo for current weapon
- (int)getReserveAmmo;

// Reset weapon state (for game restart)
- (void)resetWeapons;

// Get weapon name string
- (NSString *)getWeaponName:(WeaponType)weaponType;

@end

#endif // WEAPONSYSTEM_H

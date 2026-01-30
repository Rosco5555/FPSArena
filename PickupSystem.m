// PickupSystem.m - Pickup system implementation
#import "PickupSystem.h"
#import "GameState.h"
#import "WeaponSystem.h"
#import "SoundManager.h"
#import <math.h>

@implementation PickupSystem {
    Pickup _pickups[MAX_PICKUPS];
    int _pickupCount;
    float _globalTime;  // For bob animation sync
}

+ (instancetype)shared {
    static PickupSystem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PickupSystem alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pickupCount = 0;
        _globalTime = 0;
        [self initializePickups];
    }
    return self;
}

- (void)initializePickups {
    _pickupCount = 0;
    _globalTime = 0;

    // Spawn locations strategically placed around the map
    // Format: type, x, y (base), z

    // === HEALTH PICKUPS ===
    // Health in central building (inside house)
    [self addPickup:PickupTypeHealthPack atX:HOUSE_X y:FLOOR_Y + 0.3f z:HOUSE_Z];

    // Health near cover walls
    [self addPickup:PickupTypeHealthPack atX:WALL1_X + 1.5f y:FLOOR_Y + 0.3f z:WALL1_Z];

    // === AMMO PICKUPS ===
    // Small ammo scattered around
    [self addPickup:PickupTypeAmmoSmall atX:3.0f y:FLOOR_Y + 0.3f z:2.0f];
    [self addPickup:PickupTypeAmmoSmall atX:-3.0f y:FLOOR_Y + 0.3f z:4.0f];
    [self addPickup:PickupTypeAmmoSmall atX:0.0f y:FLOOR_Y + 0.3f z:6.0f];

    // Heavy ammo in more contested areas
    [self addPickup:PickupTypeAmmoHeavy atX:-ARENA_SIZE + 3.0f y:FLOOR_Y + 0.3f z:-ARENA_SIZE + 3.0f];
    [self addPickup:PickupTypeAmmoHeavy atX:ARENA_SIZE - 3.0f y:FLOOR_Y + 0.3f z:ARENA_SIZE - 3.0f];

    // === WEAPON PICKUPS ===
    // Shotgun - in risky location near edge of arena
    [self addPickup:PickupTypeShotgun atX:ARENA_SIZE - 2.0f y:FLOOR_Y + 0.5f z:0.0f];

    // Assault Rifle - near wall 2
    [self addPickup:PickupTypeAssaultRifle atX:WALL2_X - 2.0f y:FLOOR_Y + 0.5f z:WALL2_Z + 2.0f];

    // Rocket Launcher - most dangerous location (far corner)
    [self addPickup:PickupTypeRocketLauncher atX:-ARENA_SIZE + 2.0f y:FLOOR_Y + 0.5f z:ARENA_SIZE - 2.0f];

    // === ARMOR PICKUPS ===
    // Armor in exposed positions
    [self addPickup:PickupTypeArmor atX:WALL1_X - 2.0f y:FLOOR_Y + 0.3f z:WALL1_Z + 2.0f];
    [self addPickup:PickupTypeArmor atX:5.0f y:FLOOR_Y + 0.3f z:-5.0f];

    // Additional pickups for variety
    [self addPickup:PickupTypeHealthPack atX:-5.0f y:FLOOR_Y + 0.3f z:-3.0f];
    [self addPickup:PickupTypeAmmoSmall atX:6.0f y:FLOOR_Y + 0.3f z:5.0f];
}

- (void)addPickup:(PickupType)type atX:(float)x y:(float)y z:(float)z {
    if (_pickupCount >= MAX_PICKUPS) return;

    _pickups[_pickupCount].type = type;
    _pickups[_pickupCount].x = x;
    _pickups[_pickupCount].y = y;
    _pickups[_pickupCount].z = z;
    _pickups[_pickupCount].isActive = YES;
    _pickups[_pickupCount].respawnTimer = 0;
    _pickups[_pickupCount].bobOffset = 0;
    _pickups[_pickupCount].rotationAngle = (float)_pickupCount * 0.7f;  // Stagger initial rotations

    _pickupCount++;
}

- (void)updatePickups:(float)deltaTime {
    _globalTime += deltaTime;

    for (int i = 0; i < _pickupCount; i++) {
        // Update respawn timer for inactive pickups
        if (!_pickups[i].isActive) {
            _pickups[i].respawnTimer -= deltaTime;
            if (_pickups[i].respawnTimer <= 0) {
                _pickups[i].isActive = YES;
                _pickups[i].respawnTimer = 0;
            }
        }

        // Update bob animation (sinusoidal)
        _pickups[i].bobOffset = sinf(_globalTime * PICKUP_BOB_SPEED + i * 0.5f) * PICKUP_BOB_HEIGHT;

        // Update rotation
        _pickups[i].rotationAngle += PICKUP_ROTATE_SPEED;
        if (_pickups[i].rotationAngle > M_PI * 2.0f) {
            _pickups[i].rotationAngle -= M_PI * 2.0f;
        }
    }
}

- (PickupResult)checkPlayerPickup:(simd_float3)playerPosition {
    PickupResult result = {NO, PickupTypeHealthPack, 0};
    GameState *state = [GameState shared];

    for (int i = 0; i < _pickupCount; i++) {
        if (!_pickups[i].isActive) continue;

        // Calculate distance to pickup
        float dx = playerPosition.x - _pickups[i].x;
        float dy = playerPosition.y - (_pickups[i].y + _pickups[i].bobOffset);
        float dz = playerPosition.z - _pickups[i].z;
        float distSq = dx * dx + dy * dy + dz * dz;

        if (distSq < PICKUP_COLLECT_RADIUS * PICKUP_COLLECT_RADIUS) {
            // Check if player can actually use this pickup
            BOOL canCollect = [self canCollectPickup:&_pickups[i]];

            if (canCollect) {
                // Apply pickup effect
                result = [self applyPickup:&_pickups[i]];

                if (result.collected) {
                    // Deactivate and start respawn timer
                    _pickups[i].isActive = NO;
                    _pickups[i].respawnTimer = PICKUP_RESPAWN_TIME;

                    // Play pickup sound
                    [[SoundManager shared] playPickupSound];

                    return result;  // Only collect one pickup per frame
                }
            }
        }
    }

    return result;
}

- (BOOL)canCollectPickup:(Pickup *)pickup {
    GameState *state = [GameState shared];

    switch (pickup->type) {
        case PickupTypeHealthPack:
            return state.playerHealth < PLAYER_MAX_HEALTH;

        case PickupTypeArmor:
            return state.playerArmor < MAX_ARMOR;

        case PickupTypeAmmoSmall:
        case PickupTypeAmmoHeavy:
            return YES;  // Always can collect ammo

        case PickupTypeShotgun:
            return !state.hasWeaponShotgun;

        case PickupTypeAssaultRifle:
            return !state.hasWeaponAssaultRifle;

        case PickupTypeRocketLauncher:
            return !state.hasWeaponRocketLauncher;

        default:
            return YES;
    }
}

- (PickupResult)applyPickup:(Pickup *)pickup {
    PickupResult result = {NO, pickup->type, 0};
    GameState *state = [GameState shared];
    WeaponSystem *weapons = [WeaponSystem shared];

    switch (pickup->type) {
        case PickupTypeHealthPack: {
            int oldHealth = state.playerHealth;
            state.playerHealth += HEALTH_PACK_AMOUNT;
            if (state.playerHealth > PLAYER_MAX_HEALTH) {
                state.playerHealth = PLAYER_MAX_HEALTH;
            }
            result.collected = YES;
            result.amount = state.playerHealth - oldHealth;

            // Also reduce blood overlay when healing
            if (state.bloodLevel > 0) {
                state.bloodLevel -= 0.3f;
                if (state.bloodLevel < 0) state.bloodLevel = 0;
            }
            break;
        }

        case PickupTypeArmor: {
            int oldArmor = state.playerArmor;
            state.playerArmor += ARMOR_PACK_AMOUNT;
            if (state.playerArmor > MAX_ARMOR) {
                state.playerArmor = MAX_ARMOR;
            }
            result.collected = YES;
            result.amount = state.playerArmor - oldArmor;
            break;
        }

        case PickupTypeAmmoSmall:
            // Add ammo to both pistol and assault rifle via WeaponSystem
            [weapons addAmmo:WeaponTypePistol amount:AMMO_SMALL_AMOUNT];
            [weapons addAmmo:WeaponTypeAssaultRifle amount:AMMO_SMALL_AMOUNT];
            state.ammoSmall += AMMO_SMALL_AMOUNT;
            result.collected = YES;
            result.amount = AMMO_SMALL_AMOUNT;
            break;

        case PickupTypeAmmoHeavy:
            // Add ammo to both shotgun and rocket launcher via WeaponSystem
            [weapons addAmmo:WeaponTypeShotgun amount:AMMO_HEAVY_AMOUNT];
            [weapons addAmmo:WeaponTypeRocketLauncher amount:AMMO_HEAVY_AMOUNT];
            state.ammoHeavy += AMMO_HEAVY_AMOUNT;
            result.collected = YES;
            result.amount = AMMO_HEAVY_AMOUNT;
            break;

        case PickupTypeShotgun:
            state.hasWeaponShotgun = YES;
            // Give some ammo with weapon
            [weapons addAmmo:WeaponTypeShotgun amount:8];
            state.ammoHeavy += 8;
            result.collected = YES;
            result.amount = 1;
            break;

        case PickupTypeAssaultRifle:
            state.hasWeaponAssaultRifle = YES;
            // Give some ammo with weapon
            [weapons addAmmo:WeaponTypeAssaultRifle amount:50];
            state.ammoSmall += 50;
            result.collected = YES;
            result.amount = 1;
            break;

        case PickupTypeRocketLauncher:
            state.hasWeaponRocketLauncher = YES;
            // Give some rockets with weapon
            [weapons addAmmo:WeaponTypeRocketLauncher amount:5];
            state.ammoHeavy += 5;
            result.collected = YES;
            result.amount = 1;
            break;
    }

    return result;
}

- (int)getPickupCount {
    return _pickupCount;
}

- (Pickup *)getPickup:(int)index {
    if (index < 0 || index >= _pickupCount) return NULL;
    return &_pickups[index];
}

- (void)resetPickups {
    // Reactivate all pickups
    for (int i = 0; i < _pickupCount; i++) {
        _pickups[i].isActive = YES;
        _pickups[i].respawnTimer = 0;
    }
    _globalTime = 0;
}

@end

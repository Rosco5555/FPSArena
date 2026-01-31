// WeaponSystem.m - Multi-weapon system implementation
#import "WeaponSystem.h"
#import "SoundManager.h"
#import "GameState.h"
#import <math.h>

// Weapon statistics definitions
static const WeaponStats WEAPON_STATS[WeaponTypeCount] = {
    // Pistol: Default, unlimited ammo, medium fire rate, 15 damage
    {
        .damage = 15,
        .fireRate = 12,          // ~5 shots per second
        .spread = 0.0f,          // Perfectly accurate
        .projectileCount = 1,
        .magSize = 0,            // Unlimited (no magazine)
        .maxReserve = 0,         // Unlimited reserve
        .reloadTime = 0,         // No reload needed
        .range = FAR_PLANE,      // Full range
        .splashRadius = 0.0f,
        .splashDamage = 0
    },
    // Shotgun: Slow fire rate, 8 pellets x 12 damage, spread pattern, 8 shells max
    {
        .damage = 12,
        .fireRate = 45,          // ~1.3 shots per second
        .spread = 0.12f,         // ~7 degree spread cone
        .projectileCount = 8,    // 8 pellets
        .magSize = 8,            // 8 shells in tube
        .maxReserve = 0,         // Shells loaded directly into mag
        .reloadTime = 30,        // 0.5 sec per shell (simplified as full reload)
        .range = 15.0f,          // Short range effectiveness
        .splashRadius = 0.0f,
        .splashDamage = 0
    },
    // Assault Rifle: Fast fire rate, 20 damage, 30 rounds mag, 90 reserve
    {
        .damage = 20,
        .fireRate = 6,           // ~10 shots per second
        .spread = 0.02f,         // Slight spread
        .projectileCount = 1,
        .magSize = 30,
        .maxReserve = 90,
        .reloadTime = 90,        // 1.5 sec reload
        .range = FAR_PLANE,
        .splashRadius = 0.0f,
        .splashDamage = 0
    },
    // Rocket Launcher: Slow, 100 damage + splash, 4 rockets max
    {
        .damage = 100,
        .fireRate = 90,          // ~0.67 shots per second
        .spread = 0.0f,          // Perfectly accurate
        .projectileCount = 1,
        .magSize = 4,            // 4 rockets
        .maxReserve = 0,         // Rockets loaded directly
        .reloadTime = 120,       // 2 sec reload
        .range = FAR_PLANE,
        .splashRadius = 3.0f,    // 3 unit splash radius
        .splashDamage = 50       // 50 splash damage
    }
};

@implementation WeaponSystem {
    WeaponState _weaponState;
}

+ (instancetype)shared {
    static WeaponSystem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WeaponSystem alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetWeapons];
    }
    return self;
}

- (WeaponState *)weaponState {
    return &_weaponState;
}

- (void)resetWeapons {
    _weaponState.currentWeapon = WeaponTypePistol;
    _weaponState.isReloading = NO;
    _weaponState.reloadTimer = 0;
    _weaponState.fireTimer = 0;

    // Initialize ammo for each weapon
    for (int i = 0; i < WeaponTypeCount; i++) {
        WeaponStats stats = WEAPON_STATS[i];
        // Start with full magazine
        _weaponState.currentAmmo[i] = stats.magSize;  // 0 for unlimited
        // Start with full reserve
        _weaponState.reserveAmmo[i] = stats.maxReserve;
    }
}

- (BOOL)switchWeapon:(WeaponType)weaponType {
    if (weaponType < 0 || weaponType >= WeaponTypeCount) {
        return NO;
    }

    // Can't switch while reloading (optional: could cancel reload instead)
    if (_weaponState.isReloading) {
        return NO;
    }

    // Already using this weapon
    if (_weaponState.currentWeapon == weaponType) {
        return NO;
    }

    // Check if player owns this weapon
    GameState *state = [GameState shared];
    switch (weaponType) {
        case WeaponTypePistol:
            // Pistol is always available
            break;
        case WeaponTypeShotgun:
            if (!state.hasWeaponShotgun) return NO;
            break;
        case WeaponTypeAssaultRifle:
            if (!state.hasWeaponAssaultRifle) return NO;
            break;
        case WeaponTypeRocketLauncher:
            if (!state.hasWeaponRocketLauncher) return NO;
            break;
        default:
            return NO;
    }

    _weaponState.currentWeapon = weaponType;
    _weaponState.fireTimer = 0;  // Reset fire timer on switch

    return YES;
}

- (BOOL)canFire {
    if (_weaponState.isReloading) {
        return NO;
    }

    if (_weaponState.fireTimer > 0) {
        return NO;
    }

    WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];

    // Check if we have ammo (0 magSize means unlimited)
    if (stats.magSize > 0 && _weaponState.currentAmmo[_weaponState.currentWeapon] <= 0) {
        return NO;
    }

    return YES;
}

- (BOOL)needsReload {
    WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];

    // Unlimited ammo weapons never need reload
    if (stats.magSize == 0) {
        return NO;
    }

    // Check if magazine is empty or not full and has reserve
    int currentMag = _weaponState.currentAmmo[_weaponState.currentWeapon];
    int reserve = _weaponState.reserveAmmo[_weaponState.currentWeapon];

    // Need reload if mag is empty, or if mag is not full and we have reserve/can reload
    if (currentMag == 0) {
        return YES;
    }

    // For weapons with no reserve (shotgun, rocket), allow reload if not full
    if (stats.maxReserve == 0 && currentMag < stats.magSize) {
        return YES;
    }

    // For weapons with reserve, allow reload if not full and have reserve
    if (reserve > 0 && currentMag < stats.magSize) {
        return YES;
    }

    return NO;
}

- (BOOL)isReloading {
    return _weaponState.isReloading;
}

- (BOOL)fireCurrentWeapon:(SpreadDirections *)outSpread
           withBaseDirection:(simd_float3)baseDir {
    if (![self canFire]) {
        return NO;
    }

    WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];

    // Consume ammo (if not unlimited)
    if (stats.magSize > 0) {
        _weaponState.currentAmmo[_weaponState.currentWeapon]--;
    }

    // Set fire cooldown
    _weaponState.fireTimer = stats.fireRate;

    // Calculate spread directions
    if (outSpread != NULL) {
        outSpread->count = stats.projectileCount;

        // Normalize base direction
        float len = sqrtf(baseDir.x * baseDir.x + baseDir.y * baseDir.y + baseDir.z * baseDir.z);
        if (len > 0) {
            baseDir.x /= len;
            baseDir.y /= len;
            baseDir.z /= len;
        }

        for (int i = 0; i < stats.projectileCount && i < MAX_SPREAD_DIRECTIONS; i++) {
            if (stats.spread > 0 && stats.projectileCount > 1) {
                // Generate spread for shotgun pellets
                // Use a cone distribution around the base direction
                float angle = ((float)i / (float)stats.projectileCount) * 2.0f * M_PI;
                float spreadMagnitude = stats.spread * ((float)(arc4random() % 100) / 100.0f);

                // Calculate perpendicular vectors
                simd_float3 up = {0, 1, 0};
                if (fabsf(baseDir.y) > 0.9f) {
                    up = (simd_float3){1, 0, 0};
                }

                simd_float3 right = simd_cross(baseDir, up);
                right = simd_normalize(right);
                simd_float3 actualUp = simd_cross(right, baseDir);

                // Apply spread
                float offsetX = cosf(angle) * spreadMagnitude;
                float offsetY = sinf(angle) * spreadMagnitude;

                simd_float3 spreadDir = baseDir + right * offsetX + actualUp * offsetY;
                outSpread->directions[i] = simd_normalize(spreadDir);
            } else if (stats.spread > 0) {
                // Single projectile with spread (assault rifle)
                float spreadX = ((float)(arc4random() % 200) - 100.0f) / 100.0f * stats.spread;
                float spreadY = ((float)(arc4random() % 200) - 100.0f) / 100.0f * stats.spread;

                simd_float3 up = {0, 1, 0};
                if (fabsf(baseDir.y) > 0.9f) {
                    up = (simd_float3){1, 0, 0};
                }

                simd_float3 right = simd_cross(baseDir, up);
                right = simd_normalize(right);
                simd_float3 actualUp = simd_cross(right, baseDir);

                simd_float3 spreadDir = baseDir + right * spreadX + actualUp * spreadY;
                outSpread->directions[i] = simd_normalize(spreadDir);
            } else {
                // No spread - perfectly accurate
                outSpread->directions[i] = baseDir;
            }
        }
    }

    // Play appropriate sound
    [[SoundManager shared] playGunSound];

    return YES;
}

- (BOOL)reload {
    // Already reloading
    if (_weaponState.isReloading) {
        return NO;
    }

    WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];

    // Can't reload unlimited ammo weapons
    if (stats.magSize == 0) {
        return NO;
    }

    int currentMag = _weaponState.currentAmmo[_weaponState.currentWeapon];
    int reserve = _weaponState.reserveAmmo[_weaponState.currentWeapon];

    // Already full
    if (currentMag >= stats.magSize) {
        return NO;
    }

    // For weapons with reserve, check if we have any
    if (stats.maxReserve > 0 && reserve <= 0) {
        return NO;
    }

    // Start reloading
    _weaponState.isReloading = YES;
    _weaponState.reloadTimer = stats.reloadTime;

    return YES;
}

- (void)update {
    // Update fire timer
    if (_weaponState.fireTimer > 0) {
        _weaponState.fireTimer--;
    }

    // Update reload timer
    if (_weaponState.isReloading) {
        _weaponState.reloadTimer--;

        if (_weaponState.reloadTimer <= 0) {
            // Reload complete
            _weaponState.isReloading = NO;

            WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];
            int currentMag = _weaponState.currentAmmo[_weaponState.currentWeapon];
            int reserve = _weaponState.reserveAmmo[_weaponState.currentWeapon];
            int needed = stats.magSize - currentMag;

            if (stats.maxReserve > 0) {
                // Transfer ammo from reserve to magazine
                int toTransfer = (reserve < needed) ? reserve : needed;
                _weaponState.currentAmmo[_weaponState.currentWeapon] += toTransfer;
                _weaponState.reserveAmmo[_weaponState.currentWeapon] -= toTransfer;
            } else {
                // Weapons without reserve (shotgun, rocket) just refill
                _weaponState.currentAmmo[_weaponState.currentWeapon] = stats.magSize;
            }
        }
    } else {
        // Auto-reload when magazine is empty and we have more ammo
        WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];
        if (stats.magSize > 0) {  // Not unlimited ammo weapon
            int currentMag = _weaponState.currentAmmo[_weaponState.currentWeapon];
            if (currentMag == 0) {
                // Check if we have ammo to reload
                if (stats.maxReserve > 0) {
                    // Weapons with reserve - check reserve ammo
                    if (_weaponState.reserveAmmo[_weaponState.currentWeapon] > 0) {
                        [self reload];
                    }
                } else {
                    // Weapons without reserve (shotgun, rocket) - always can reload
                    [self reload];
                }
            }
        }
    }
}

- (void)addAmmo:(WeaponType)weaponType amount:(int)amount {
    if (weaponType < 0 || weaponType >= WeaponTypeCount) {
        return;
    }

    WeaponStats stats = WEAPON_STATS[weaponType];

    // Unlimited ammo weapons don't need ammo pickups
    if (stats.magSize == 0) {
        return;
    }

    if (stats.maxReserve > 0) {
        // Add to reserve
        _weaponState.reserveAmmo[weaponType] += amount;
        if (_weaponState.reserveAmmo[weaponType] > stats.maxReserve) {
            _weaponState.reserveAmmo[weaponType] = stats.maxReserve;
        }
    } else {
        // Add directly to magazine (for shotgun, rocket launcher)
        _weaponState.currentAmmo[weaponType] += amount;
        if (_weaponState.currentAmmo[weaponType] > stats.magSize) {
            _weaponState.currentAmmo[weaponType] = stats.magSize;
        }
    }
}

- (WeaponStats)getWeaponStats:(WeaponType)weaponType {
    if (weaponType < 0 || weaponType >= WeaponTypeCount) {
        return WEAPON_STATS[WeaponTypePistol];
    }
    return WEAPON_STATS[weaponType];
}

- (WeaponStats)getCurrentWeaponStats {
    return WEAPON_STATS[_weaponState.currentWeapon];
}

- (WeaponType)getCurrentWeapon {
    return _weaponState.currentWeapon;
}

- (NSString *)getAmmoDisplayString {
    WeaponStats stats = WEAPON_STATS[_weaponState.currentWeapon];
    int current = _weaponState.currentAmmo[_weaponState.currentWeapon];
    int reserve = _weaponState.reserveAmmo[_weaponState.currentWeapon];

    if (stats.magSize == 0) {
        // Unlimited ammo
        return @"INF";
    }

    if (stats.maxReserve > 0) {
        // Has reserve
        return [NSString stringWithFormat:@"%d / %d", current, reserve];
    }

    // No reserve (shotgun, rocket)
    return [NSString stringWithFormat:@"%d / %d", current, stats.magSize];
}

- (int)getCurrentAmmo {
    return _weaponState.currentAmmo[_weaponState.currentWeapon];
}

- (int)getReserveAmmo {
    return _weaponState.reserveAmmo[_weaponState.currentWeapon];
}

- (NSString *)getWeaponName:(WeaponType)weaponType {
    switch (weaponType) {
        case WeaponTypePistol:
            return @"Pistol";
        case WeaponTypeShotgun:
            return @"Shotgun";
        case WeaponTypeAssaultRifle:
            return @"Assault Rifle";
        case WeaponTypeRocketLauncher:
            return @"Rocket Launcher";
        default:
            return @"Unknown";
    }
}

@end

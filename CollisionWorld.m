// CollisionWorld.m - Abstract collision detection system implementation
#import "CollisionWorld.h"
#import <math.h>

@implementation CollisionWorld {
    CollisionShape _shapes[MAX_COLLISION_SHAPES];
    int _shapeCount;
    int _nextShapeId;
}

+ (instancetype)shared {
    static CollisionWorld *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CollisionWorld alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _shapeCount = 0;
        _nextShapeId = 1;
        [self buildMilitaryBaseCollision];
    }
    return self;
}

// ============================================
// SHAPE MANAGEMENT
// ============================================

- (int)addBoxWithMinX:(float)minX minY:(float)minY minZ:(float)minZ
                 maxX:(float)maxX maxY:(float)maxY maxZ:(float)maxZ
                 type:(CollisionShapeType)type
            walkable:(BOOL)walkable
               name:(const char *)name {
    if (_shapeCount >= MAX_COLLISION_SHAPES) return -1;

    CollisionShape shape = {0};
    shape.minX = minX;
    shape.minY = minY;
    shape.minZ = minZ;
    shape.maxX = maxX;
    shape.maxY = maxY;
    shape.maxZ = maxZ;
    shape.type = type;
    shape.layer = CollisionLayerWorld;
    shape.isWalkable = walkable;
    // Only walls block horizontal movement - platforms are for standing on (handled by ground detection)
    shape.blocksMovement = (type == CollisionShapeTypeWall);
    shape.blocksProjectiles = (type == CollisionShapeTypeWall || type == CollisionShapeTypePlatform);
    shape.isRamp = NO;
    shape.shapeId = _nextShapeId++;
    shape.debugName = name;

    _shapes[_shapeCount++] = shape;
    return shape.shapeId;
}

- (int)addRampWithMinX:(float)minX minZ:(float)minZ
                  maxX:(float)maxX maxZ:(float)maxZ
                startY:(float)startY endY:(float)endY
                  axis:(int)axis direction:(float)direction
                  name:(const char *)name {
    if (_shapeCount >= MAX_COLLISION_SHAPES) return -1;

    float minY = fminf(startY, endY);
    float maxY = fmaxf(startY, endY);

    CollisionShape shape = {0};
    shape.minX = minX;
    shape.minY = minY;
    shape.minZ = minZ;
    shape.maxX = maxX;
    shape.maxY = maxY;
    shape.maxZ = maxZ;
    shape.type = CollisionShapeTypeRamp;
    shape.layer = CollisionLayerWorld;
    shape.isWalkable = YES;
    shape.blocksMovement = YES;
    shape.blocksProjectiles = YES;
    shape.isRamp = YES;
    shape.rampStartY = startY;
    shape.rampEndY = endY;
    shape.rampAxis = axis;
    shape.rampDirection = direction;
    shape.shapeId = _nextShapeId++;
    shape.debugName = name;

    _shapes[_shapeCount++] = shape;
    return shape.shapeId;
}

- (int)addPlatformWithMinX:(float)minX minZ:(float)minZ
                      maxX:(float)maxX maxZ:(float)maxZ
                      topY:(float)topY thickness:(float)thickness
                      name:(const char *)name {
    return [self addBoxWithMinX:minX minY:topY - thickness minZ:minZ
                           maxX:maxX maxY:topY maxZ:maxZ
                           type:CollisionShapeTypePlatform
                      walkable:YES
                          name:name];
}

- (void)removeShape:(int)shapeId {
    for (int i = 0; i < _shapeCount; i++) {
        if (_shapes[i].shapeId == shapeId) {
            // Shift remaining shapes down
            for (int j = i; j < _shapeCount - 1; j++) {
                _shapes[j] = _shapes[j + 1];
            }
            _shapeCount--;
            return;
        }
    }
}

- (void)clearAllShapes {
    _shapeCount = 0;
}

- (CollisionShape *)getShape:(int)shapeId {
    for (int i = 0; i < _shapeCount; i++) {
        if (_shapes[i].shapeId == shapeId) {
            return &_shapes[i];
        }
    }
    return NULL;
}

- (int)getShapeCount {
    return _shapeCount;
}

// ============================================
// RAYCASTING
// ============================================

- (RaycastResult)raycastFrom:(simd_float3)origin
                   direction:(simd_float3)direction
                   maxDistance:(float)maxDistance
                   layerMask:(CollisionLayer)layerMask {
    RaycastResult result = {NO, maxDistance, {0,0,0}, {0,0,0}, -1, CollisionShapeTypeWall};

    // Normalize direction
    float len = sqrtf(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
    if (len < 0.0001f) return result;
    direction.x /= len;
    direction.y /= len;
    direction.z /= len;

    float closestT = maxDistance;

    for (int i = 0; i < _shapeCount; i++) {
        CollisionShape *shape = &_shapes[i];

        // Check layer mask
        if (!(shape->layer & layerMask)) continue;
        if (!shape->blocksProjectiles) continue;

        // Ray-AABB intersection (slab method)
        float tmin = -INFINITY, tmax = INFINITY;

        // X axis
        if (fabsf(direction.x) > 0.0001f) {
            float t1 = (shape->minX - origin.x) / direction.x;
            float t2 = (shape->maxX - origin.x) / direction.x;
            if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
            tmin = fmaxf(tmin, t1);
            tmax = fminf(tmax, t2);
        } else if (origin.x < shape->minX || origin.x > shape->maxX) {
            continue;
        }

        // Y axis
        if (fabsf(direction.y) > 0.0001f) {
            float t1 = (shape->minY - origin.y) / direction.y;
            float t2 = (shape->maxY - origin.y) / direction.y;
            if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
            tmin = fmaxf(tmin, t1);
            tmax = fminf(tmax, t2);
        } else if (origin.y < shape->minY || origin.y > shape->maxY) {
            continue;
        }

        // Z axis
        if (fabsf(direction.z) > 0.0001f) {
            float t1 = (shape->minZ - origin.z) / direction.z;
            float t2 = (shape->maxZ - origin.z) / direction.z;
            if (t1 > t2) { float tmp = t1; t1 = t2; t2 = tmp; }
            tmin = fmaxf(tmin, t1);
            tmax = fminf(tmax, t2);
        } else if (origin.z < shape->minZ || origin.z > shape->maxZ) {
            continue;
        }

        // Check if hit
        if (tmin <= tmax && tmax > 0 && tmin < closestT) {
            float hitT = tmin > 0 ? tmin : tmax;
            if (hitT < closestT && hitT > 0) {
                closestT = hitT;
                result.hit = YES;
                result.distance = hitT;
                result.hitPoint = (simd_float3){
                    origin.x + direction.x * hitT,
                    origin.y + direction.y * hitT,
                    origin.z + direction.z * hitT
                };
                result.shapeId = shape->shapeId;
                result.shapeType = shape->type;

                // Calculate hit normal (which face was hit)
                simd_float3 hitPt = result.hitPoint;
                float eps = 0.01f;
                if (fabsf(hitPt.x - shape->minX) < eps) result.hitNormal = (simd_float3){-1, 0, 0};
                else if (fabsf(hitPt.x - shape->maxX) < eps) result.hitNormal = (simd_float3){1, 0, 0};
                else if (fabsf(hitPt.y - shape->minY) < eps) result.hitNormal = (simd_float3){0, -1, 0};
                else if (fabsf(hitPt.y - shape->maxY) < eps) result.hitNormal = (simd_float3){0, 1, 0};
                else if (fabsf(hitPt.z - shape->minZ) < eps) result.hitNormal = (simd_float3){0, 0, -1};
                else result.hitNormal = (simd_float3){0, 0, 1};
            }
        }
    }

    return result;
}

// ============================================
// GROUND DETECTION
// ============================================

- (float)getRampYAt:(CollisionShape *)shape x:(float)x z:(float)z {
    if (!shape->isRamp) return shape->maxY;

    float progress;
    if (shape->rampAxis == 0) {
        // Ramp along X axis
        float rangeX = shape->maxX - shape->minX;
        if (rangeX < 0.001f) return shape->rampStartY;
        progress = (x - shape->minX) / rangeX;
        if (shape->rampDirection < 0) progress = 1.0f - progress;
    } else {
        // Ramp along Z axis
        float rangeZ = shape->maxZ - shape->minZ;
        if (rangeZ < 0.001f) return shape->rampStartY;
        progress = (z - shape->minZ) / rangeZ;
        if (shape->rampDirection < 0) progress = 1.0f - progress;
    }

    progress = fmaxf(0.0f, fminf(1.0f, progress));
    return shape->rampStartY + progress * (shape->rampEndY - shape->rampStartY);
}

- (GroundResult)checkGroundAt:(float)x y:(float)y z:(float)z
                   playerRadius:(float)radius
                   playerHeight:(float)height {
    GroundResult result = {NO, FLOOR_Y, NO, -1};

    float feetY = y - height;
    float bestGroundY = -1000.0f;
    int bestShapeId = -1;
    BOOL onRamp = NO;

    // Ground tolerance values
    float standingTolerance = 0.15f;  // How close feet must be to surface to stand
    float landingTolerance = 0.1f;    // Extra tolerance when falling

    for (int i = 0; i < _shapeCount; i++) {
        CollisionShape *shape = &_shapes[i];
        if (!shape->isWalkable) continue;

        // Check horizontal overlap (with player radius)
        BOOL xOverlap = (x + radius > shape->minX) && (x - radius < shape->maxX);
        BOOL zOverlap = (z + radius > shape->minZ) && (z - radius < shape->maxZ);

        if (!xOverlap || !zOverlap) continue;

        float surfaceY;
        if (shape->isRamp) {
            surfaceY = [self getRampYAt:shape x:x z:z];
        } else {
            surfaceY = shape->maxY;
        }

        // Check if player feet are at or just above the surface
        float distAbove = feetY - surfaceY;

        // Can stand if: feet are within tolerance of surface AND surface is higher than current best
        if (distAbove >= -landingTolerance && distAbove <= standingTolerance) {
            if (surfaceY > bestGroundY) {
                bestGroundY = surfaceY;
                bestShapeId = shape->shapeId;
                onRamp = shape->isRamp;
            }
        }
    }

    // Also check base floor
    if (feetY <= FLOOR_Y + standingTolerance && FLOOR_Y > bestGroundY) {
        bestGroundY = FLOOR_Y;
        bestShapeId = -1;
        onRamp = NO;
    }

    if (bestGroundY > -999.0f) {
        result.onGround = YES;
        result.groundY = bestGroundY;
        result.onRamp = onRamp;
        result.groundShapeId = bestShapeId;
    }

    return result;
}

// ============================================
// MOVEMENT COLLISION
// ============================================

- (MoveResult)movePlayerFrom:(simd_float3)position
                   velocity:(simd_float3)velocity
                   radius:(float)radius
                   height:(float)height {
    MoveResult result = {NO, {0, 0, 0}, velocity, -1};

    // Player AABB
    float playerMinX = position.x - radius;
    float playerMaxX = position.x + radius;
    float playerMinY = position.y - height;
    float playerMaxY = position.y + 0.1f;  // Small margin above eyes
    float playerMinZ = position.z - radius;
    float playerMaxZ = position.z + radius;

    simd_float3 pushOut = {0, 0, 0};

    for (int i = 0; i < _shapeCount; i++) {
        CollisionShape *shape = &_shapes[i];
        if (!shape->blocksMovement) continue;
        // Skip ramps - they're handled by ground detection, not wall collision
        if (shape->isRamp) continue;

        // Expand shape by player radius for collision
        float sMinX = shape->minX - radius;
        float sMaxX = shape->maxX + radius;
        float sMinY = shape->minY;
        float sMaxY = shape->maxY;
        float sMinZ = shape->minZ - radius;
        float sMaxZ = shape->maxZ + radius;

        // Check overlap
        BOOL xOv = position.x > sMinX && position.x < sMaxX;
        BOOL yOv = playerMinY < sMaxY && playerMaxY > sMinY;
        BOOL zOv = position.z > sMinZ && position.z < sMaxZ;

        if (xOv && yOv && zOv) {
            // Calculate penetration on each axis
            float penLeft = position.x - sMinX;
            float penRight = sMaxX - position.x;
            float penDown = playerMaxY - sMinY;
            float penUp = sMaxY - playerMinY;
            float penBack = position.z - sMinZ;
            float penFront = sMaxZ - position.z;

            float minPenX = fminf(penLeft, penRight);
            float minPenZ = fminf(penBack, penFront);
            float minPenY = fminf(penDown, penUp);

            // Choose smallest penetration axis to resolve
            if (minPenY < minPenX && minPenY < minPenZ) {
                // Resolve on Y axis
                if (penDown < penUp) {
                    pushOut.y -= penDown;
                    if (result.newVelocity.y > 0) result.newVelocity.y = 0;
                } else {
                    pushOut.y += penUp;
                    if (result.newVelocity.y < 0) result.newVelocity.y = 0;
                }
            } else if (minPenX < minPenZ) {
                // Resolve on X axis
                if (penLeft < penRight) {
                    pushOut.x -= penLeft;
                } else {
                    pushOut.x += penRight;
                }
                result.newVelocity.x = 0;
            } else {
                // Resolve on Z axis
                if (penBack < penFront) {
                    pushOut.z -= penBack;
                } else {
                    pushOut.z += penFront;
                }
                result.newVelocity.z = 0;
            }

            result.collided = YES;
            result.hitShapeId = shape->shapeId;
        }
    }

    result.pushOut = pushOut;
    return result;
}

// ============================================
// WORLD BUILDING
// ============================================

- (void)buildMilitaryBaseCollision {
    [self clearAllShapes];

    // ---- ARENA BOUNDARIES ----
    float arenaWall = 0.5f;
    [self addBoxWithMinX:-ARENA_SIZE - arenaWall minY:FLOOR_Y minZ:-ARENA_SIZE - arenaWall
                    maxX:-ARENA_SIZE maxY:FLOOR_Y + 10.0f maxZ:ARENA_SIZE + arenaWall
                    type:CollisionShapeTypeWall walkable:NO name:"arena_west"];
    [self addBoxWithMinX:ARENA_SIZE minY:FLOOR_Y minZ:-ARENA_SIZE - arenaWall
                    maxX:ARENA_SIZE + arenaWall maxY:FLOOR_Y + 10.0f maxZ:ARENA_SIZE + arenaWall
                    type:CollisionShapeTypeWall walkable:NO name:"arena_east"];
    [self addBoxWithMinX:-ARENA_SIZE - arenaWall minY:FLOOR_Y minZ:-ARENA_SIZE - arenaWall
                    maxX:ARENA_SIZE + arenaWall maxY:FLOOR_Y + 10.0f maxZ:-ARENA_SIZE
                    type:CollisionShapeTypeWall walkable:NO name:"arena_south"];
    [self addBoxWithMinX:-ARENA_SIZE - arenaWall minY:FLOOR_Y minZ:ARENA_SIZE
                    maxX:ARENA_SIZE + arenaWall maxY:FLOOR_Y + 10.0f maxZ:ARENA_SIZE + arenaWall
                    type:CollisionShapeTypeWall walkable:NO name:"arena_north"];

    // ---- COMMAND BUILDING ----
    float hw = CMD_BUILDING_WIDTH / 2.0f;
    float hd = CMD_BUILDING_DEPTH / 2.0f;
    float wt = CMD_WALL_THICK;
    float wh = CMD_BUILDING_HEIGHT;
    float dw = CMD_DOOR_WIDTH / 2.0f;

    // Command building walls
    [self addBoxWithMinX:CMD_BUILDING_X - hw - wt minY:FLOOR_Y minZ:CMD_BUILDING_Z - hd - wt
                    maxX:CMD_BUILDING_X + hw + wt maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z - hd
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_south"];
    [self addBoxWithMinX:CMD_BUILDING_X - hw - wt minY:FLOOR_Y minZ:CMD_BUILDING_Z - hd
                    maxX:CMD_BUILDING_X - hw maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z + hd + wt
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_west"];
    [self addBoxWithMinX:CMD_BUILDING_X + hw minY:FLOOR_Y minZ:CMD_BUILDING_Z - hd
                    maxX:CMD_BUILDING_X + hw + wt maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z + hd + wt
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_east"];
    // North wall with door opening
    [self addBoxWithMinX:CMD_BUILDING_X - hw minY:FLOOR_Y minZ:CMD_BUILDING_Z + hd
                    maxX:CMD_BUILDING_X - dw maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z + hd + wt
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_north_left"];
    [self addBoxWithMinX:CMD_BUILDING_X + dw minY:FLOOR_Y minZ:CMD_BUILDING_Z + hd
                    maxX:CMD_BUILDING_X + hw maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z + hd + wt
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_north_right"];
    [self addBoxWithMinX:CMD_BUILDING_X - dw minY:FLOOR_Y + CMD_DOOR_HEIGHT minZ:CMD_BUILDING_Z + hd
                    maxX:CMD_BUILDING_X + dw maxY:FLOOR_Y + wh maxZ:CMD_BUILDING_Z + hd + wt
                    type:CollisionShapeTypeWall walkable:NO name:"cmd_wall_above_door"];

    // Command building second floor
    float secondFloorY = FLOOR_Y + CMD_BUILDING_HEIGHT / 2.0f;
    float innerWall = CMD_WALL_THICK;
    float stairHoleW = 2.0f;  // Full width, but use half for hole
    float stairHoleD = 2.0f;  // Full depth, but use half for hole
    // Visual uses stairHoleD/2 for hole boundaries, so collision must match
    float holeHalfW = stairHoleW / 2.0f;  // = 1.0
    float holeHalfD = stairHoleD / 2.0f;  // = 1.0

    // Second floor platform (with stair hole matching visual geometry)
    // Left section
    [self addPlatformWithMinX:CMD_BUILDING_X - hw + innerWall minZ:CMD_BUILDING_Z - hd + innerWall
                         maxX:CMD_BUILDING_X - holeHalfW maxZ:CMD_BUILDING_Z + hd - innerWall
                         topY:secondFloorY thickness:0.2f name:"cmd_floor2_left"];
    // Right section
    [self addPlatformWithMinX:CMD_BUILDING_X + holeHalfW minZ:CMD_BUILDING_Z - hd + innerWall
                         maxX:CMD_BUILDING_X + hw - innerWall maxZ:CMD_BUILDING_Z + hd - innerWall
                         topY:secondFloorY thickness:0.2f name:"cmd_floor2_right"];
    // Back section
    [self addPlatformWithMinX:CMD_BUILDING_X - holeHalfW minZ:CMD_BUILDING_Z - hd + innerWall
                         maxX:CMD_BUILDING_X + holeHalfW maxZ:CMD_BUILDING_Z - holeHalfD
                         topY:secondFloorY thickness:0.2f name:"cmd_floor2_back"];
    // Front section
    [self addPlatformWithMinX:CMD_BUILDING_X - holeHalfW minZ:CMD_BUILDING_Z + holeHalfD
                         maxX:CMD_BUILDING_X + holeHalfW maxZ:CMD_BUILDING_Z + hd - innerWall
                         topY:secondFloorY thickness:0.2f name:"cmd_floor2_front"];

    // Command building stairs (6 steps) - match visual geometry
    int cmdNumSteps = 6;
    float cmdStepH = (secondFloorY - FLOOR_Y) / cmdNumSteps;
    float cmdStepD = stairHoleD / cmdNumSteps;  // Match visual: stairHoleD / numSteps
    float cmdStairX = CMD_BUILDING_X - holeHalfW + 0.1f;
    float cmdStairW = stairHoleW - 0.2f;  // Match visual: stairHoleW - 0.2

    for (int i = 0; i < cmdNumSteps; i++) {
        float stepTop = FLOOR_Y + (i + 1) * cmdStepH;
        float stepZStart = CMD_BUILDING_Z + holeHalfD - i * cmdStepD;  // Match visual
        float stepZEnd = stepZStart - cmdStepD;

        char stepName[32];
        snprintf(stepName, sizeof(stepName), "cmd_stair_%d", i);
        [self addPlatformWithMinX:cmdStairX minZ:stepZEnd
                             maxX:cmdStairX + cmdStairW maxZ:stepZStart
                             topY:stepTop thickness:cmdStepH name:stepName];
    }

    // ---- GUARD TOWERS ----
    float towerPositions[4][2] = {
        {TOWER_OFFSET, TOWER_OFFSET},
        {-TOWER_OFFSET, TOWER_OFFSET},
        {-TOWER_OFFSET, -TOWER_OFFSET},
        {TOWER_OFFSET, -TOWER_OFFSET}
    };
    float towerTs = TOWER_SIZE / 2.0f;
    float legW = 0.3f;

    for (int t = 0; t < 4; t++) {
        float tx = towerPositions[t][0];
        float tz = towerPositions[t][1];

        // Tower platform
        char platName[32];
        snprintf(platName, sizeof(platName), "tower_plat_%d", t);
        [self addPlatformWithMinX:tx - towerTs minZ:tz - towerTs
                             maxX:tx + towerTs maxZ:tz + towerTs
                             topY:PLATFORM_LEVEL thickness:CATWALK_THICK name:platName];

        // Tower legs (4 per tower)
        char legName[32];
        snprintf(legName, sizeof(legName), "tower_leg_%d_0", t);
        [self addBoxWithMinX:tx - towerTs minY:FLOOR_Y minZ:tz - towerTs
                        maxX:tx - towerTs + legW maxY:PLATFORM_LEVEL maxZ:tz - towerTs + legW
                        type:CollisionShapeTypeWall walkable:NO name:legName];
        snprintf(legName, sizeof(legName), "tower_leg_%d_1", t);
        [self addBoxWithMinX:tx + towerTs - legW minY:FLOOR_Y minZ:tz - towerTs
                        maxX:tx + towerTs maxY:PLATFORM_LEVEL maxZ:tz - towerTs + legW
                        type:CollisionShapeTypeWall walkable:NO name:legName];
        snprintf(legName, sizeof(legName), "tower_leg_%d_2", t);
        [self addBoxWithMinX:tx - towerTs minY:FLOOR_Y minZ:tz + towerTs - legW
                        maxX:tx - towerTs + legW maxY:PLATFORM_LEVEL maxZ:tz + towerTs
                        type:CollisionShapeTypeWall walkable:NO name:legName];
        snprintf(legName, sizeof(legName), "tower_leg_%d_3", t);
        [self addBoxWithMinX:tx + towerTs - legW minY:FLOOR_Y minZ:tz + towerTs - legW
                        maxX:tx + towerTs maxY:PLATFORM_LEVEL maxZ:tz + towerTs
                        type:CollisionShapeTypeWall walkable:NO name:legName];

        // Tower cross braces removed - they were blocking ramp access
        // Visual braces in GeometryBuilder are decorative only

        // Tower ramp - goes OUTWARD from arena center (away from catwalks)
        float rampDz = (tz > 0) ? 1.0f : -1.0f;  // Away from center on Z axis
        float rampStartZ = tz + rampDz * towerTs;  // Start at outer edge of tower
        float rampEndZ = rampStartZ + rampDz * RAMP_LENGTH;

        char rampName[32];
        snprintf(rampName, sizeof(rampName), "tower_ramp_%d", t);

        [self addRampWithMinX:tx - RAMP_WIDTH/2
                         minZ:fminf(rampStartZ, rampEndZ)
                         maxX:tx + RAMP_WIDTH/2
                         maxZ:fmaxf(rampStartZ, rampEndZ)
                       startY:PLATFORM_LEVEL endY:FLOOR_Y
                         axis:2 direction:rampDz
                         name:rampName];
    }

    // ---- CATWALKS ----
    float cwW = CATWALK_WIDTH / 2.0f;
    float cwTs = TOWER_SIZE / 2.0f;
    float railThick = 0.06f;

    // North catwalk (runs E-W at +Z)
    [self addPlatformWithMinX:-TOWER_OFFSET + cwTs minZ:TOWER_OFFSET - cwW
                         maxX:TOWER_OFFSET - cwTs maxZ:TOWER_OFFSET + cwW
                         topY:PLATFORM_LEVEL thickness:CATWALK_THICK name:"catwalk_north"];
    // North catwalk railings
    [self addBoxWithMinX:-TOWER_OFFSET + cwTs minY:PLATFORM_LEVEL minZ:TOWER_OFFSET + cwW - railThick
                    maxX:TOWER_OFFSET - cwTs maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET + cwW
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_north_rail_n"];
    [self addBoxWithMinX:-TOWER_OFFSET + cwTs minY:PLATFORM_LEVEL minZ:TOWER_OFFSET - cwW
                    maxX:TOWER_OFFSET - cwTs maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET - cwW + railThick
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_north_rail_s"];

    // South catwalk (runs E-W at -Z)
    [self addPlatformWithMinX:-TOWER_OFFSET + cwTs minZ:-TOWER_OFFSET - cwW
                         maxX:TOWER_OFFSET - cwTs maxZ:-TOWER_OFFSET + cwW
                         topY:PLATFORM_LEVEL thickness:CATWALK_THICK name:"catwalk_south"];
    // South catwalk railings
    [self addBoxWithMinX:-TOWER_OFFSET + cwTs minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET + cwW - railThick
                    maxX:TOWER_OFFSET - cwTs maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:-TOWER_OFFSET + cwW
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_south_rail_n"];
    [self addBoxWithMinX:-TOWER_OFFSET + cwTs minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET - cwW
                    maxX:TOWER_OFFSET - cwTs maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:-TOWER_OFFSET - cwW + railThick
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_south_rail_s"];

    // East catwalk (runs N-S at +X)
    [self addPlatformWithMinX:TOWER_OFFSET - cwW minZ:-TOWER_OFFSET + cwTs
                         maxX:TOWER_OFFSET + cwW maxZ:TOWER_OFFSET - cwTs
                         topY:PLATFORM_LEVEL thickness:CATWALK_THICK name:"catwalk_east"];
    // East catwalk railings
    [self addBoxWithMinX:TOWER_OFFSET + cwW - railThick minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET + cwTs
                    maxX:TOWER_OFFSET + cwW maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET - cwTs
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_east_rail_e"];
    [self addBoxWithMinX:TOWER_OFFSET - cwW minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET + cwTs
                    maxX:TOWER_OFFSET - cwW + railThick maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET - cwTs
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_east_rail_w"];

    // West catwalk (runs N-S at -X)
    [self addPlatformWithMinX:-TOWER_OFFSET - cwW minZ:-TOWER_OFFSET + cwTs
                         maxX:-TOWER_OFFSET + cwW maxZ:TOWER_OFFSET - cwTs
                         topY:PLATFORM_LEVEL thickness:CATWALK_THICK name:"catwalk_west"];
    // West catwalk railings
    [self addBoxWithMinX:-TOWER_OFFSET + cwW - railThick minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET + cwTs
                    maxX:-TOWER_OFFSET + cwW maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET - cwTs
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_west_rail_e"];
    [self addBoxWithMinX:-TOWER_OFFSET - cwW minY:PLATFORM_LEVEL minZ:-TOWER_OFFSET + cwTs
                    maxX:-TOWER_OFFSET - cwW + railThick maxY:PLATFORM_LEVEL + CATWALK_RAIL_HEIGHT maxZ:TOWER_OFFSET - cwTs
                    type:CollisionShapeTypeWall walkable:NO name:"catwalk_west_rail_w"];

    // ---- CARGO CONTAINERS ----
    // Positioned to not block tower ramp approaches
    struct { float x, z; int rotated; } containers[] = {
        {8.0f, 4.0f, 0}, {6.0f, 7.0f, 1}, {-8.0f, 4.0f, 0}, {-6.0f, 7.0f, 1},
        {6.0f, -8.0f, 1}, {-6.0f, -8.0f, 1}, {0.0f, -12.0f, 0}, {18.0f, 0.0f, 1}
    };

    for (int c = 0; c < 8; c++) {
        float cx = containers[c].x;
        float cz = containers[c].z;
        float cxl = containers[c].rotated ? CONTAINER_WIDTH/2 : CONTAINER_LENGTH/2;
        float czl = containers[c].rotated ? CONTAINER_LENGTH/2 : CONTAINER_WIDTH/2;

        char contName[32];
        snprintf(contName, sizeof(contName), "container_%d", c);

        // Container as solid wall that's also walkable on top
        [self addBoxWithMinX:cx - cxl minY:FLOOR_Y minZ:cz - czl
                        maxX:cx + cxl maxY:FLOOR_Y + CONTAINER_HEIGHT maxZ:cz + czl
                        type:CollisionShapeTypeWall walkable:YES name:contName];
    }

    // Stacked container
    [self addBoxWithMinX:8.0f - CONTAINER_LENGTH/2 minY:FLOOR_Y + CONTAINER_HEIGHT minZ:4.0f - CONTAINER_WIDTH/2
                    maxX:8.0f + CONTAINER_LENGTH/2 maxY:FLOOR_Y + CONTAINER_HEIGHT * 2 maxZ:4.0f + CONTAINER_WIDTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"container_stacked"];

    // ---- SANDBAG WALLS ----
    float sbTopY = FLOOR_Y + SANDBAG_HEIGHT;

    // Horizontal sandbags
    [self addBoxWithMinX:5.0f - SANDBAG_LENGTH/2 minY:FLOOR_Y minZ:4.0f - SANDBAG_THICK/2
                    maxX:5.0f + SANDBAG_LENGTH/2 maxY:sbTopY maxZ:4.0f + SANDBAG_THICK/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_0"];
    [self addBoxWithMinX:-5.0f - SANDBAG_LENGTH/2 minY:FLOOR_Y minZ:4.0f - SANDBAG_THICK/2
                    maxX:-5.0f + SANDBAG_LENGTH/2 maxY:sbTopY maxZ:4.0f + SANDBAG_THICK/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_1"];
    [self addBoxWithMinX:5.0f - SANDBAG_LENGTH/2 minY:FLOOR_Y minZ:-4.0f - SANDBAG_THICK/2
                    maxX:5.0f + SANDBAG_LENGTH/2 maxY:sbTopY maxZ:-4.0f + SANDBAG_THICK/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_2"];
    [self addBoxWithMinX:-5.0f - SANDBAG_LENGTH/2 minY:FLOOR_Y minZ:-4.0f - SANDBAG_THICK/2
                    maxX:-5.0f + SANDBAG_LENGTH/2 maxY:sbTopY maxZ:-4.0f + SANDBAG_THICK/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_3"];

    // Vertical sandbags
    [self addBoxWithMinX:12.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:10.0f - SANDBAG_LENGTH/2
                    maxX:12.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:10.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_4"];
    [self addBoxWithMinX:-12.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:10.0f - SANDBAG_LENGTH/2
                    maxX:-12.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:10.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_5"];
    [self addBoxWithMinX:12.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:-10.0f - SANDBAG_LENGTH/2
                    maxX:12.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:-10.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_6"];
    [self addBoxWithMinX:-12.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:-10.0f - SANDBAG_LENGTH/2
                    maxX:-12.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:-10.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_7"];
    [self addBoxWithMinX:3.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:8.0f - SANDBAG_LENGTH/2
                    maxX:3.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:8.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_8"];
    [self addBoxWithMinX:-3.0f - SANDBAG_THICK/2 minY:FLOOR_Y minZ:8.0f - SANDBAG_LENGTH/2
                    maxX:-3.0f + SANDBAG_THICK/2 maxY:sbTopY maxZ:8.0f + SANDBAG_LENGTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"sandbag_9"];

    // ---- LEGACY COVER WALLS ----
    float wallTopY = FLOOR_Y + WALL_HEIGHT;
    [self addBoxWithMinX:WALL1_X - WALL_WIDTH/2 minY:FLOOR_Y minZ:WALL1_Z - WALL_DEPTH/2
                    maxX:WALL1_X + WALL_WIDTH/2 maxY:wallTopY maxZ:WALL1_Z + WALL_DEPTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"cover_wall_1"];
    [self addBoxWithMinX:WALL2_X - WALL_WIDTH/2 minY:FLOOR_Y minZ:WALL2_Z - WALL_DEPTH/2
                    maxX:WALL2_X + WALL_WIDTH/2 maxY:wallTopY maxZ:WALL2_Z + WALL_DEPTH/2
                    type:CollisionShapeTypeWall walkable:YES name:"cover_wall_2"];

}

@end

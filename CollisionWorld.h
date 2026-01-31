// CollisionWorld.h - Abstract collision detection system
#ifndef COLLISIONWORLD_H
#define COLLISIONWORLD_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "GameConfig.h"

// ============================================
// COLLISION SHAPE TYPES
// ============================================

typedef enum {
    CollisionShapeTypeWall,         // Solid wall - blocks movement
    CollisionShapeTypePlatform,     // Can stand on top, blocks from sides
    CollisionShapeTypeRamp,         // Sloped surface
    CollisionShapeTypeFloor,        // Ground level surface
    CollisionShapeTypeTrigger,      // Non-solid, triggers events
} CollisionShapeType;

typedef enum {
    CollisionLayerWorld     = 1 << 0,   // Static world geometry
    CollisionLayerPlayer    = 1 << 1,   // Player collision
    CollisionLayerEnemy     = 1 << 2,   // Enemy collision
    CollisionLayerProjectile = 1 << 3,  // Bullets/rockets
    CollisionLayerPickup    = 1 << 4,   // Pickups
    CollisionLayerAll       = 0xFFFF
} CollisionLayer;

// ============================================
// COLLISION SHAPE STRUCTURE
// ============================================

typedef struct {
    // Bounds (axis-aligned bounding box)
    float minX, minY, minZ;
    float maxX, maxY, maxZ;

    // Shape properties
    CollisionShapeType type;
    CollisionLayer layer;

    // Surface properties
    BOOL isWalkable;            // Can player stand on top
    BOOL blocksMovement;        // Blocks horizontal movement
    BOOL blocksProjectiles;     // Blocks raycast shots

    // Ramp-specific properties
    BOOL isRamp;
    float rampStartY;           // Y at ramp start
    float rampEndY;             // Y at ramp end
    int rampAxis;               // 0=X, 2=Z - which axis the ramp slopes along
    float rampDirection;        // 1.0 or -1.0 for slope direction

    // Identification
    int shapeId;                // Unique ID for this shape
    const char *debugName;      // For debugging
} CollisionShape;

// ============================================
// COLLISION RESULTS
// ============================================

typedef struct {
    BOOL hit;
    float distance;             // Distance to hit point
    simd_float3 hitPoint;       // World position of hit
    simd_float3 hitNormal;      // Surface normal at hit
    int shapeId;                // ID of shape that was hit
    CollisionShapeType shapeType;
} RaycastResult;

typedef struct {
    BOOL onGround;
    float groundY;              // Y position of ground surface
    BOOL onRamp;                // Standing on a ramp
    int groundShapeId;          // ID of ground shape
} GroundResult;

typedef struct {
    BOOL collided;
    simd_float3 pushOut;        // Vector to push player out of collision
    simd_float3 newVelocity;    // Adjusted velocity after collision
    int hitShapeId;             // ID of shape collided with
} MoveResult;

// ============================================
// COLLISION WORLD SINGLETON
// ============================================

#define MAX_COLLISION_SHAPES 256

@interface CollisionWorld : NSObject

+ (instancetype)shared;

// Shape management
- (int)addBoxWithMinX:(float)minX minY:(float)minY minZ:(float)minZ
                 maxX:(float)maxX maxY:(float)maxY maxZ:(float)maxZ
                 type:(CollisionShapeType)type
            walkable:(BOOL)walkable
               name:(const char *)name;

- (int)addRampWithMinX:(float)minX minZ:(float)minZ
                  maxX:(float)maxX maxZ:(float)maxZ
                startY:(float)startY endY:(float)endY
                  axis:(int)axis direction:(float)direction
                  name:(const char *)name;

- (int)addPlatformWithMinX:(float)minX minZ:(float)minZ
                      maxX:(float)maxX maxZ:(float)maxZ
                      topY:(float)topY thickness:(float)thickness
                      name:(const char *)name;

- (void)removeShape:(int)shapeId;
- (void)clearAllShapes;

// Shape queries
- (CollisionShape *)getShape:(int)shapeId;
- (int)getShapeCount;

// Collision detection
- (RaycastResult)raycastFrom:(simd_float3)origin
                   direction:(simd_float3)direction
                   maxDistance:(float)maxDistance
                   layerMask:(CollisionLayer)layerMask;

- (GroundResult)checkGroundAt:(float)x y:(float)y z:(float)z
                   playerRadius:(float)radius
                   playerHeight:(float)height;

- (MoveResult)movePlayerFrom:(simd_float3)position
                   velocity:(simd_float3)velocity
                   radius:(float)radius
                   height:(float)height;

// World initialization
- (void)buildMilitaryBaseCollision;

@end

#endif // COLLISIONWORLD_H

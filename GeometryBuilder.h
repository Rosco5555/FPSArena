// GeometryBuilder.h - All vertex buffer creation
#ifndef GEOMETRYBUILDER_H
#define GEOMETRYBUILDER_H

#import <Metal/Metal.h>
#import "GameTypes.h"

@interface GeometryBuilder : NSObject

// ============================================
// MILITARY BASE MAP GEOMETRY
// ============================================

// Create command building (2-story central structure)
+ (id<MTLBuffer>)createCommandBuildingBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create guard tower (single tower with platform)
+ (id<MTLBuffer>)createGuardTowerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create catwalks connecting towers
+ (id<MTLBuffer>)createCatwalkBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create underground bunker area
+ (id<MTLBuffer>)createBunkerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create cargo containers for cover
+ (id<MTLBuffer>)createCargoContainersBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create sandbag walls for low cover
+ (id<MTLBuffer>)createSandbagBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create military base floor (concrete + dirt areas)
+ (id<MTLBuffer>)createMilitaryFloorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// ============================================
// LEGACY GEOMETRY (kept for compatibility)
// ============================================

// Create house geometry buffer
+ (id<MTLBuffer>)createHouseBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create door geometry buffer
+ (id<MTLBuffer>)createDoorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create floor geometry buffer
+ (id<MTLBuffer>)createFloorBufferWithDevice:(id<MTLDevice>)device;

// Create cover wall buffers
+ (id<MTLBuffer>)createWall1BufferWithDevice:(id<MTLDevice>)device;
+ (id<MTLBuffer>)createWall2BufferWithDevice:(id<MTLDevice>)device;

// ============================================
// CHARACTER & WEAPON GEOMETRY
// ============================================

// Create gun model buffer
+ (id<MTLBuffer>)createGunBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create enemy model buffer
+ (id<MTLBuffer>)createEnemyBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create remote player model buffer (blue team colors)
+ (id<MTLBuffer>)createRemotePlayerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create muzzle flash buffer
+ (id<MTLBuffer>)createMuzzleFlashBufferWithDevice:(id<MTLDevice>)device;

// ============================================
// UI GEOMETRY
// ============================================

// Create health bar buffers
+ (id<MTLBuffer>)createHealthBarBgBufferWithDevice:(id<MTLDevice>)device;
+ (id<MTLBuffer>)createHealthBarFgBufferWithDevice:(id<MTLDevice>)device;
+ (id<MTLBuffer>)createPlayerHpBgBufferWithDevice:(id<MTLDevice>)device;
+ (id<MTLBuffer>)createPlayerHpFgBufferWithDevice:(id<MTLDevice>)device;

// Create game over text buffer
+ (id<MTLBuffer>)createGameOverBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create crosshair buffer
+ (id<MTLBuffer>)createCrosshairBufferWithDevice:(id<MTLDevice>)device;

// Create E prompt buffer
+ (id<MTLBuffer>)createEPromptBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create paused text buffer
+ (id<MTLBuffer>)createPausedTextBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create background gradient buffer
+ (id<MTLBuffer>)createBackgroundBufferWithDevice:(id<MTLDevice>)device;

// Create wireframe box grid buffer
+ (id<MTLBuffer>)createBoxGridBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// ============================================
// PICKUP GEOMETRY
// ============================================

// Create health pack buffer (red cross box)
+ (id<MTLBuffer>)createHealthPackBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create ammo box buffer (green ammo crate)
+ (id<MTLBuffer>)createAmmoBoxBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create weapon pickup buffer (floating weapon model)
+ (id<MTLBuffer>)createWeaponPickupBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create armor buffer (blue shield)
+ (id<MTLBuffer>)createArmorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

@end

#endif // GEOMETRYBUILDER_H

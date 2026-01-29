// GeometryBuilder.h - All vertex buffer creation
#ifndef GEOMETRYBUILDER_H
#define GEOMETRYBUILDER_H

#import <Metal/Metal.h>
#import "GameTypes.h"

@interface GeometryBuilder : NSObject

// Create house geometry buffer
+ (id<MTLBuffer>)createHouseBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create door geometry buffer
+ (id<MTLBuffer>)createDoorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create floor geometry buffer
+ (id<MTLBuffer>)createFloorBufferWithDevice:(id<MTLDevice>)device;

// Create cover wall buffers
+ (id<MTLBuffer>)createWall1BufferWithDevice:(id<MTLDevice>)device;
+ (id<MTLBuffer>)createWall2BufferWithDevice:(id<MTLDevice>)device;

// Create gun model buffer
+ (id<MTLBuffer>)createGunBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create enemy model buffer
+ (id<MTLBuffer>)createEnemyBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create remote player model buffer (blue team colors)
+ (id<MTLBuffer>)createRemotePlayerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count;

// Create muzzle flash buffer
+ (id<MTLBuffer>)createMuzzleFlashBufferWithDevice:(id<MTLDevice>)device;

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

@end

#endif // GEOMETRYBUILDER_H

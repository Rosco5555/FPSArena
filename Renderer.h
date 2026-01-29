// Renderer.h - Metal renderer
#ifndef RENDERER_H
#define RENDERER_H

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "InputView.h"

@interface MetalRenderer : NSObject <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) DraggableMetalView *metalView;

- (instancetype)initWithDevice:(id<MTLDevice>)device view:(DraggableMetalView *)view;

@end

#endif // RENDERER_H

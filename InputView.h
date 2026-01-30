// InputView.h - Custom MTKView with input handling
#ifndef INPUTVIEW_H
#define INPUTVIEW_H

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "GameConfig.h"

@protocol InputViewDelegate <NSObject>
- (void)inputViewDidRequestMenu;
@end

@interface DraggableMetalView : MTKView

@property (nonatomic, weak) id<InputViewDelegate> inputDelegate;

@property (nonatomic) float camYaw;
@property (nonatomic) float camPitch;
@property (nonatomic) float posX;
@property (nonatomic) float posY;
@property (nonatomic) float posZ;
@property (nonatomic) NSPoint lastMouse;
@property (nonatomic) BOOL dragging;
@property (nonatomic) BOOL controlsActive;
@property (nonatomic) BOOL escapedLock;
@property (nonatomic) BOOL keyW;
@property (nonatomic) BOOL keyA;
@property (nonatomic) BOOL keyS;
@property (nonatomic) BOOL keyD;
@property (nonatomic) BOOL keyCrouch;
@property (nonatomic) float currentHeight;  // Interpolated height for smooth crouch transition
@property (nonatomic) BOOL wantsClick;
@property (nonatomic) BOOL mouseHeld;
@property (nonatomic) BOOL keyTab;
@property (nonatomic) int fireTimer;
@property (nonatomic) float velocityX;
@property (nonatomic) float velocityY;
@property (nonatomic) float velocityZ;
@property (nonatomic) BOOL onGround;
@property (nonatomic) float gunRecoil;

// Multiplayer: send local state to network
- (void)sendNetworkState;

@end

#endif // INPUTVIEW_H

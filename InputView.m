// InputView.m - Custom MTKView with input handling implementation
#import "InputView.h"
#import "GameState.h"
#import "SoundManager.h"
#import "MultiplayerController.h"
#import "WeaponSystem.h"

@implementation DraggableMetalView

- (BOOL)acceptsFirstResponder { return YES; }

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *area = [[NSTrackingArea alloc]
        initWithRect:self.bounds
        options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
        owner:self
        userInfo:nil];
    [self addTrackingArea:area];
}

- (void)mouseEntered:(NSEvent *)event {
    if (!_controlsActive && !_escapedLock) {
        _controlsActive = YES;
        CGAssociateMouseAndMouseCursorPosition(false);
        [NSCursor hide];
    }
}

- (void)mouseMoved:(NSEvent *)event {
    if (!_controlsActive) return;
    _camYaw += event.deltaX * MOUSE_SENSITIVITY;
    _camPitch -= event.deltaY * MOUSE_SENSITIVITY;
    if (_camPitch > 1.5) _camPitch = 1.5;
    if (_camPitch < -1.5) _camPitch = -1.5;
}

- (void)mouseDown:(NSEvent *)event {
    if (_controlsActive) {
        _wantsClick = YES;
        _mouseHeld = YES;
    }
    [self.window makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)event {
    _mouseHeld = NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

- (void)mouseDragged:(NSEvent *)event {
    [self mouseMoved:event];
}

- (void)keyDown:(NSEvent *)event {
    if (event.isARepeat) return;
    NSString *chars = [event charactersIgnoringModifiers];
    if ([chars length] == 0) return;
    unichar key = [chars characterAtIndex:0];

    GameState *state = [GameState shared];

    if (key == 27) {
        _controlsActive = NO;
        CGAssociateMouseAndMouseCursorPosition(true);
        [NSCursor unhide];
        if ([_inputDelegate respondsToSelector:@selector(inputViewDidRequestMenu)]) {
            [_inputDelegate inputViewDidRequestMenu];
        }
        return;
    }

    switch (key) {
        case 'w': _keyW = YES; break;
        case 'a': _keyA = YES; break;
        case 's': _keyS = YES; break;
        case 'd': _keyD = YES; break;
        case '\t': _keyTab = YES; break;
        case 'r':
            if (state.gameOver && !state.gameWon) {
                // Game over - R key respawns/restarts
                if (state.isMultiplayer) {
                    // In multiplayer, respawn is handled automatically by timer
                    // But pressing R can trigger manual respawn request
                    [[MultiplayerController shared] requestRespawn];
                } else {
                    // Single player: reset game state
                    [state resetGame];

                    // Reset player position and camera
                    [state resetPlayerWithPosX:&_posX posY:&_posY posZ:&_posZ
                                        camYaw:&_camYaw camPitch:&_camPitch
                                     velocityX:&_velocityX velocityY:&_velocityY velocityZ:&_velocityZ
                                      onGround:&_onGround];
                }
            } else if (!state.gameOver) {
                // Not dead - R key reloads weapon
                [[WeaponSystem shared] reload];
            }
            break;
        case ' ':
            if (_onGround) {
                _velocityY = JUMP_VELOCITY;
                _onGround = NO;
            }
            break;
        case 'e':
            if (state.playerNearDoor && !state.gameOver) {
                state.doorOpen = !state.doorOpen;
                [[SoundManager shared] playDoorSound];
            }
            break;
        // Weapon switching with number keys 1-4
        case '1':
            if (!state.gameOver) {
                [[WeaponSystem shared] switchWeapon:WeaponTypePistol];
            }
            break;
        case '2':
            if (!state.gameOver) {
                [[WeaponSystem shared] switchWeapon:WeaponTypeShotgun];
            }
            break;
        case '3':
            if (!state.gameOver) {
                [[WeaponSystem shared] switchWeapon:WeaponTypeAssaultRifle];
            }
            break;
        case '4':
            if (!state.gameOver) {
                [[WeaponSystem shared] switchWeapon:WeaponTypeRocketLauncher];
            }
            break;
    }
}

- (void)keyUp:(NSEvent *)event {
    NSString *chars = [event charactersIgnoringModifiers];
    if ([chars length] == 0) return;
    unichar key = [chars characterAtIndex:0];
    switch (key) {
        case 'w': _keyW = NO; break;
        case 'a': _keyA = NO; break;
        case 's': _keyS = NO; break;
        case 'd': _keyD = NO; break;
        case '\t': _keyTab = NO; break;
    }
}

- (void)flagsChanged:(NSEvent *)event {
    // Control key for crouching
    _keyCrouch = (event.modifierFlags & NSEventModifierFlagControl) != 0;
}

- (void)sendNetworkState {
    GameState *state = [GameState shared];
    if (!state.isMultiplayer) return;

    // Update multiplayer controller (polls packets, handles respawns)
    [[MultiplayerController shared] update];

    // Send our current state to the remote player
    BOOL isShooting = _wantsClick || _mouseHeld;
    [[MultiplayerController shared] sendLocalState:_posX posY:_posY posZ:_posZ
                                            camYaw:_camYaw camPitch:_camPitch
                                        isShooting:isShooting];
}

@end

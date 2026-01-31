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
    GameState *state = [GameState shared];

    // Handle pause menu hover detection
    if (state.showPauseMenu) {
        NSPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
        NSSize size = self.bounds.size;

        // Convert to normalized coordinates (-1 to 1)
        float nx = (loc.x / size.width) * 2.0f - 1.0f;
        float ny = (loc.y / size.height) * 2.0f - 1.0f;

        // Menu layout constants (MUST match Renderer.m)
        float itemHeight = 0.09f;
        float menuTop = 0.28f;
        float itemSpacing = 0.115f;
        float itemLeft = -0.46f;
        float itemRight = 0.46f;

        state.pauseMenuSelection = -1;  // Default to no selection

        if (nx >= itemLeft && nx <= itemRight) {
            for (int i = 0; i < 4; i++) {
                float itemTop = menuTop - i * itemSpacing;
                float itemBottom = itemTop - itemHeight;
                if (ny <= itemTop && ny >= itemBottom) {
                    state.pauseMenuSelection = i;
                    break;
                }
            }
        }
        return;
    }

    if (!_controlsActive) return;
    float sensitivity = state.mouseSensitivity;
    _camYaw += event.deltaX * sensitivity;
    _camPitch -= event.deltaY * sensitivity;
    if (_camPitch > 1.5) _camPitch = 1.5;
    if (_camPitch < -1.5) _camPitch = -1.5;
}

- (void)mouseDown:(NSEvent *)event {
    GameState *state = [GameState shared];

    // Handle pause menu clicks
    if (state.showPauseMenu) {
        NSPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
        NSSize size = self.bounds.size;

        // Convert to normalized coordinates (-1 to 1)
        float nx = (loc.x / size.width) * 2.0f - 1.0f;
        float ny = (loc.y / size.height) * 2.0f - 1.0f;

        // Menu layout constants (MUST match Renderer.m)
        float itemHeight = 0.09f;
        float menuTop = 0.28f;
        float itemSpacing = 0.115f;
        float itemLeft = -0.46f;
        float itemRight = 0.46f;

        // Slider layout (MUST match Renderer.m)
        float sliderLeft = -0.38f;
        float sliderRight = 0.38f;

        // Calculate slider Y positions (matching Renderer.m formula)
        float sens_itemTop = menuTop - 1 * itemSpacing;
        float sens_itemBottom = sens_itemTop - itemHeight;
        float sliderY1 = sens_itemBottom + itemHeight * 0.22f;  // Sensitivity slider

        float vol_itemTop = menuTop - 2 * itemSpacing;
        float vol_itemBottom = vol_itemTop - itemHeight;
        float sliderY2 = vol_itemBottom + itemHeight * 0.22f;   // Volume slider

        // Generous hit area for sliders
        float sliderHitHeight = 0.05f;

        // Check if clicking on sensitivity slider area
        if (nx >= sliderLeft - 0.02f && nx <= sliderRight + 0.02f &&
            ny >= sliderY1 - sliderHitHeight && ny <= sliderY1 + sliderHitHeight) {
            float t = (nx - sliderLeft) / (sliderRight - sliderLeft);
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            state.mouseSensitivity = 0.001f + t * (0.02f - 0.001f);
            return;
        }

        // Check if clicking on volume slider area
        if (nx >= sliderLeft - 0.02f && nx <= sliderRight + 0.02f &&
            ny >= sliderY2 - sliderHitHeight && ny <= sliderY2 + sliderHitHeight) {
            float t = (nx - sliderLeft) / (sliderRight - sliderLeft);
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            state.masterVolume = t;
            [[SoundManager shared] setMasterVolume:t];
            return;
        }

        // Check menu item clicks
        if (nx >= itemLeft && nx <= itemRight) {
            for (int i = 0; i < 4; i++) {
                float itemTop = menuTop - i * itemSpacing;
                float itemBottom = itemTop - itemHeight;
                if (ny <= itemTop && ny >= itemBottom) {
                    switch (i) {
                        case 0:  // Resume
                            state.showPauseMenu = NO;
                            state.isPaused = NO;
                            state.pauseMenuSelection = -1;
                            _controlsActive = YES;
                            _escapedLock = NO;
                            CGAssociateMouseAndMouseCursorPosition(false);
                            [NSCursor hide];
                            break;
                        case 1:  // Sensitivity (handled by slider above)
                            break;
                        case 2:  // Volume (handled by slider above)
                            break;
                        case 3:  // Main Menu
                            state.showPauseMenu = NO;
                            state.isPaused = NO;
                            _controlsActive = NO;
                            CGAssociateMouseAndMouseCursorPosition(true);
                            [NSCursor unhide];
                            if ([_inputDelegate respondsToSelector:@selector(inputViewDidRequestMenu)]) {
                                [_inputDelegate inputViewDidRequestMenu];
                            }
                            break;
                    }
                    return;
                }
            }
        }
        return;
    }

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
    GameState *state = [GameState shared];

    // Handle slider dragging in pause menu
    if (state.showPauseMenu) {
        NSPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
        NSSize size = self.bounds.size;

        // Convert to normalized coordinates (-1 to 1)
        float nx = (loc.x / size.width) * 2.0f - 1.0f;
        float ny = (loc.y / size.height) * 2.0f - 1.0f;

        // Menu layout constants (MUST match Renderer.m)
        float itemHeight = 0.09f;
        float menuTop = 0.28f;
        float itemSpacing = 0.115f;

        // Slider layout (MUST match Renderer.m)
        float sliderLeft = -0.38f;
        float sliderRight = 0.38f;

        // Calculate slider Y positions
        float sens_itemTop = menuTop - 1 * itemSpacing;
        float sens_itemBottom = sens_itemTop - itemHeight;
        float sliderY1 = sens_itemBottom + itemHeight * 0.22f;

        float vol_itemTop = menuTop - 2 * itemSpacing;
        float vol_itemBottom = vol_itemTop - itemHeight;
        float sliderY2 = vol_itemBottom + itemHeight * 0.22f;

        // Generous hit area for dragging
        float sliderHitHeight = 0.08f;

        // Check if dragging sensitivity slider
        if (ny >= sliderY1 - sliderHitHeight && ny <= sliderY1 + sliderHitHeight) {
            float t = (nx - sliderLeft) / (sliderRight - sliderLeft);
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            state.mouseSensitivity = 0.001f + t * (0.02f - 0.001f);
            return;
        }

        // Check if dragging volume slider
        if (ny >= sliderY2 - sliderHitHeight && ny <= sliderY2 + sliderHitHeight) {
            float t = (nx - sliderLeft) / (sliderRight - sliderLeft);
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            state.masterVolume = t;
            [[SoundManager shared] setMasterVolume:t];
            return;
        }
        return;
    }

    [self mouseMoved:event];
}

- (void)keyDown:(NSEvent *)event {
    if (event.isARepeat) return;
    NSString *chars = [event charactersIgnoringModifiers];
    if ([chars length] == 0) return;
    unichar key = [chars characterAtIndex:0];

    GameState *state = [GameState shared];

    if (key == 27) {
        if (state.gameOver) {
            // If game is over, ESC returns to main menu
            _controlsActive = NO;
            CGAssociateMouseAndMouseCursorPosition(true);
            [NSCursor unhide];
            if ([_inputDelegate respondsToSelector:@selector(inputViewDidRequestMenu)]) {
                [_inputDelegate inputViewDidRequestMenu];
            }
            return;
        }

        // Toggle pause menu
        if (state.showPauseMenu) {
            // Close pause menu and resume game
            state.showPauseMenu = NO;
            state.isPaused = NO;
            state.pauseMenuSelection = -1;
            _controlsActive = YES;
            _escapedLock = NO;
            CGAssociateMouseAndMouseCursorPosition(false);
            [NSCursor hide];
        } else {
            // Open pause menu
            state.showPauseMenu = YES;
            state.isPaused = YES;
            state.pauseMenuSelection = -1;
            _controlsActive = NO;
            _escapedLock = YES;
            CGAssociateMouseAndMouseCursorPosition(true);
            [NSCursor unhide];
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
            _keySpace = YES;
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
        // Sensitivity adjustment with [ and ]
        case '[':
            state.mouseSensitivity -= 0.001f;
            if (state.mouseSensitivity < 0.001f) state.mouseSensitivity = 0.001f;
            NSLog(@"Sensitivity: %.3f", state.mouseSensitivity);
            break;
        case ']':
            state.mouseSensitivity += 0.001f;
            if (state.mouseSensitivity > 0.02f) state.mouseSensitivity = 0.02f;
            NSLog(@"Sensitivity: %.3f", state.mouseSensitivity);
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
        case ' ': _keySpace = NO; break;
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

// main.m - Entry point with lobby support
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "InputView.h"
#import "Renderer.h"
#import "AppDelegate.h"
#import "LobbyView.h"
#import "MultiplayerController.h"
#import "GameState.h"
#import "Enemy.h"
#import "PickupSystem.h"
#import "NetworkManager.h"

// Game controller that manages lobby and game transitions
@interface GameController : NSObject <LobbyDelegate, NetworkManagerDelegate, InputViewDelegate>
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) LobbyView *lobbyView;
@property (nonatomic, strong) DraggableMetalView *metalView;
@property (nonatomic, strong) MetalRenderer *renderer;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) NSTimer *networkPollTimer;
- (void)showLobby;
- (void)startGameWithMultiplayer:(BOOL)multiplayer;
- (void)pollNetworkInLobby;
@end

@implementation GameController

- (instancetype)initWithWindow:(NSWindow *)window device:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        _window = window;
        _device = device;
    }
    return self;
}

- (void)showLobby {
    // Remove game view if present
    if (_metalView) {
        [_metalView removeFromSuperview];
        _metalView = nil;
        _renderer = nil;
    }

    // Create and show lobby
    _lobbyView = [[LobbyView alloc] initWithFrame:_window.contentView.bounds];
    _lobbyView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _lobbyView.delegate = self;
    [_window.contentView addSubview:_lobbyView];
    [_window setTitle:@"FPS Game - Lobby"];

    // Show cursor for lobby
    CGAssociateMouseAndMouseCursorPosition(true);
    [NSCursor unhide];

    // Start network polling timer for lobby (needed for connection handshake)
    if (!_networkPollTimer) {
        _networkPollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                                             target:self
                                                           selector:@selector(pollNetworkInLobby)
                                                           userInfo:nil
                                                            repeats:YES];
    }
}

- (void)pollNetworkInLobby {
    [[NetworkManager shared] pollNetwork];
}

- (void)startGameWithMultiplayer:(BOOL)multiplayer {
    // Stop lobby network polling timer
    if (_networkPollTimer) {
        [_networkPollTimer invalidate];
        _networkPollTimer = nil;
    }

    // Remove lobby
    if (_lobbyView) {
        [_lobbyView removeFromSuperview];
        _lobbyView = nil;
    }

    // Reset game state
    GameState *state = [GameState shared];
    if (multiplayer) {
        [state resetForMultiplayer];
    } else {
        [state resetGame];
        // Initialize bot AI for single player mode
        initializeBotAI();
    }

    // Reset pickups for new game
    [[PickupSystem shared] resetPickups];

    // Create game view
    _metalView = [[DraggableMetalView alloc] initWithFrame:_window.contentView.bounds device:_device];
    _metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    _metalView.preferredFramesPerSecond = 60;

    _renderer = [[MetalRenderer alloc] initWithDevice:_device view:_metalView];
    _metalView.delegate = _renderer;
    _metalView.inputDelegate = self;

    [_window.contentView addSubview:_metalView];
    [_window makeFirstResponder:_metalView];
    [_window setTitle:multiplayer ? @"FPS Game - Multiplayer" : @"FPS Game"];
}

#pragma mark - LobbyDelegate

- (void)lobbyDidSelectSinglePlayer {
    [self startGameWithMultiplayer:NO];
}

- (void)lobbyDidStartHosting {
    [[MultiplayerController shared] hostGame];
}

- (void)lobbyDidConnectToHost:(NSString *)hostIP {
    [[NetworkManager shared] stopLANDiscovery];
    [[MultiplayerController shared] joinGameAtHost:hostIP];
}

- (void)lobbyDidStartGame {
    [self startGameWithMultiplayer:YES];
    [[MultiplayerController shared] startGame];
}

- (void)lobbyDidCancel {
    [[MultiplayerController shared] leaveGame];
    [[NetworkManager shared] stopLANDiscovery];
    [_lobbyView setState:LobbyStateMainMenu];
}

- (void)lobbyNeedsDiscovery {
    [NetworkManager shared].delegate = self;
    [[NetworkManager shared] startLANDiscovery];
}

#pragma mark - NetworkManagerDelegate

- (void)networkManager:(id)manager didDiscoverHost:(DiscoveredHost *)host {
    [_lobbyView addDiscoveredHost:host.address];
}

- (void)networkManagerDidConnect:(id)manager withPlayerId:(uint32_t)playerId {
    [_lobbyView transitionToState:LobbyStateConnected];
    [_lobbyView setPlayerReady:2 ready:YES];
}

- (void)networkManager:(id)manager playerDidConnect:(RemotePlayer *)player {
    [_lobbyView transitionToState:LobbyStateConnected];
    [_lobbyView setPlayerReady:1 ready:YES];
    [_lobbyView setPlayerReady:2 ready:YES];
}

- (void)networkManagerDidDisconnect:(id)manager {
    [_lobbyView transitionToState:LobbyStateMainMenu];
}

#pragma mark - InputViewDelegate

- (void)inputViewDidRequestMenu {
    [[MultiplayerController shared] leaveGame];
    [self showLobby];
}

@end

int main(int argc, const char *argv[]) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(200, 200, 800, 600)
        styleMask:NSWindowStyleMaskTitled
               | NSWindowStyleMaskClosable
               | NSWindowStyleMaskMiniaturizable
               | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered
        defer:NO];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    // Create game controller and show lobby
    GameController *gameController = [[GameController alloc] initWithWindow:window device:device];

    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:appDelegate];
    [window setDelegate:appDelegate];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    // Show lobby on startup
    [gameController showLobby];

    [NSApp run];

    return 0;
}

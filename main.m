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
    NSLog(@"[LOBBY] Starting host...");
    [[MultiplayerController shared] hostGame];
    [NetworkManager shared].delegate = self;  // Set delegate AFTER to avoid being overwritten
    NSLog(@"[LOBBY] Host started, waiting for players");
}

- (void)lobbyDidConnectToHost:(NSString *)hostIP {
    NSLog(@"[LOBBY] Connecting to host: %@", hostIP);
    [[NetworkManager shared] stopLANDiscovery];
    [[MultiplayerController shared] joinGameAtHost:hostIP];
    [NetworkManager shared].delegate = self;  // Set delegate AFTER to avoid being overwritten
}

- (void)lobbyDidStartGame {
    NSLog(@"[LOBBY] Starting multiplayer game!");
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
    NSLog(@"[NETWORK] Discovered host: %@", host.address);
    [_lobbyView addDiscoveredHost:host.address];
}

- (void)networkManagerDidConnect:(id)manager withPlayerId:(uint32_t)playerId {
    NSLog(@"[NETWORK] Connected to host! Assigned player ID: %u", playerId);
    [_lobbyView transitionToState:LobbyStateConnected];
    [_lobbyView setPlayerReady:2 ready:YES];
}

- (void)networkManager:(id)manager playerDidConnect:(RemotePlayer *)player {
    NSLog(@"[NETWORK] Player connected! Player ID: %u, Name: %@", player.playerId, player.playerName);
    [_lobbyView transitionToState:LobbyStateConnected];
    [_lobbyView setPlayerReady:1 ready:YES];
    [_lobbyView setPlayerReady:2 ready:YES];
}

- (void)networkManagerDidDisconnect:(id)manager {
    NSLog(@"[NETWORK] Disconnected from server");
    [_lobbyView transitionToState:LobbyStateMainMenu];
}

- (void)networkManager:(id)manager didReceiveGameStart:(uint32_t)hostPlayerId {
    NSLog(@"[NETWORK] Received game start signal from host!");
    // Client starts the game when host sends game start
    [[MultiplayerController shared] clientStartGame];
    [self startGameWithMultiplayer:YES];
}

- (void)networkManager:(id)manager didReceiveStateUpdate:(PlayerNetState)state fromPlayer:(uint32_t)playerId {
    // Forward state updates to GameState for rendering remote player
    GameState *gameState = [GameState shared];
    gameState.remotePlayerPosX = state.posX;
    gameState.remotePlayerPosY = state.posY;
    gameState.remotePlayerPosZ = state.posZ;
    gameState.remotePlayerCamYaw = state.camYaw;
    gameState.remotePlayerCamPitch = state.camPitch;
    gameState.remotePlayerHealth = state.health;
    gameState.remotePlayerShooting = (state.isShooting != 0);
    gameState.remotePlayerAlive = YES;
}

#pragma mark - InputViewDelegate

- (void)inputViewDidRequestMenu {
    [[MultiplayerController shared] leaveGame];
    [self showLobby];
}

@end

// Debug log file path
static NSString *kLogFilePath = @"/tmp/fpsgame_debug.log";

void setupDebugLogging(void) {
    // Clear old log file
    [@"" writeToFile:kLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // Redirect stderr to log file (NSLog uses stderr)
    freopen([kLogFilePath UTF8String], "a", stderr);

    // Open Terminal window to tail the log
    NSString *script = [NSString stringWithFormat:
        @"tell application \"Terminal\"\n"
        @"    activate\n"
        @"    do script \"tail -f %@\"\n"
        @"end tell", kLogFilePath];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    [appleScript executeAndReturnError:nil];

    NSLog(@"=== FPS Arena Debug Log ===");
    NSLog(@"Game starting...");
}

int main(int argc, const char *argv[]) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Setup debug logging with separate terminal window
    setupDebugLogging();

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

// LobbyView.h - Multiplayer lobby UI
#ifndef LOBBYVIEW_H
#define LOBBYVIEW_H

#import <Cocoa/Cocoa.h>

// Lobby states
typedef NS_ENUM(NSInteger, LobbyState) {
    LobbyStateMainMenu,
    LobbyStateHosting,
    LobbyStateJoining,
    LobbyStateConnected
};

// Delegate protocol for lobby events
@protocol LobbyDelegate <NSObject>
- (void)lobbyDidSelectSinglePlayer;
- (void)lobbyDidStartHosting;
- (void)lobbyDidConnectToHost:(NSString *)hostIP;
- (void)lobbyDidStartGame;
- (void)lobbyDidCancel;
@end

@interface LobbyView : NSView

@property (nonatomic, weak) id<LobbyDelegate> delegate;
@property (nonatomic, assign) LobbyState state;
@property (nonatomic, assign) BOOL isHost;

// Host information
@property (nonatomic, copy) NSString *hostIPAddress;

// List of discovered hosts (array of NSString IP addresses)
@property (nonatomic, strong) NSMutableArray<NSString *> *discoveredHosts;

// Connection status
@property (nonatomic, assign) BOOL playerOneReady;
@property (nonatomic, assign) BOOL playerTwoReady;

// Update the lobby state
- (void)transitionToState:(LobbyState)newState;

// Add a discovered host to the list
- (void)addDiscoveredHost:(NSString *)hostIP;

// Clear discovered hosts
- (void)clearDiscoveredHosts;

// Set player ready status
- (void)setPlayerReady:(int)playerNumber ready:(BOOL)ready;

// Get the local IP address
- (NSString *)getLocalIPAddress;

@end

#endif // LOBBYVIEW_H

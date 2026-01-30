// MultiplayerController.h - Coordinates networking and game state for multiplayer
#ifndef MULTIPLAYERCONTROLLER_H
#define MULTIPLAYERCONTROLLER_H

#import <Foundation/Foundation.h>
#import "GameState.h"

@class NetworkManager;

@interface MultiplayerController : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) BOOL isHost;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) BOOL isInGame;

// Lobby actions
- (void)hostGame;
- (void)joinGameAtHost:(NSString *)hostIP;
- (void)startGame;  // Host only
- (void)clientStartGame;  // Client only - called when receiving game start
- (void)leaveGame;

// Called every frame to sync network state
- (void)update;

// Send local player state to remote
- (void)sendLocalState:(float)posX posY:(float)posY posZ:(float)posZ
                camYaw:(float)camYaw camPitch:(float)camPitch
            isShooting:(BOOL)isShooting;

// Called when local player shoots and hits remote player
- (void)sendHitOnRemotePlayer:(int)damage;

// Called when local player dies
- (void)sendLocalPlayerDeath;

// Handle respawn
- (void)requestRespawn;

@end

#endif // MULTIPLAYERCONTROLLER_H

// NetworkManager.h - Core networking singleton for LAN multiplayer
#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#import <Foundation/Foundation.h>

// Network configuration
static const uint16_t NET_DEFAULT_PORT = 7777;
static const uint16_t NET_DISCOVERY_PORT = 7778;
static const int NET_MAX_PLAYERS = 8;
static const int NET_MAX_PACKET_SIZE = 512;
static const double NET_STATE_UPDATE_INTERVAL = 1.0 / 60.0;  // 60 Hz
static const double NET_DISCOVERY_INTERVAL = 1.0;  // 1 Hz for discovery broadcasts

// Packet types
typedef NS_ENUM(uint8_t, PacketType) {
    PacketTypeStateUpdate = 0,  // Player position/rotation (UDP, unreliable)
    PacketTypeShoot = 1,        // Player fired weapon (TCP, reliable)
    PacketTypeHit = 2,          // Player was hit (TCP, reliable)
    PacketTypeKill = 3,         // Player was killed (TCP, reliable)
    PacketTypeRespawn = 4,      // Player respawned (TCP, reliable)
    PacketTypeLobby = 5,        // Lobby management (TCP, reliable)
    PacketTypeDiscovery = 6,    // LAN discovery broadcast
    PacketTypeDiscoveryResponse = 7,  // Response to discovery
    PacketTypeConnect = 8,      // Client connection request
    PacketTypeConnectAccept = 9,  // Host accepts connection
    PacketTypeDisconnect = 10,  // Player disconnecting
    PacketTypePing = 11,        // Ping for latency measurement
    PacketTypePong = 12,        // Pong response
    PacketTypeGameStart = 13    // Host signals game start
};

// Network mode
typedef NS_ENUM(NSInteger, NetworkMode) {
    NetworkModeNone = 0,
    NetworkModeHost,
    NetworkModeClient
};

// Connection state
typedef NS_ENUM(NSInteger, ConnectionState) {
    ConnectionStateDisconnected = 0,
    ConnectionStateConnecting,
    ConnectionStateConnected,
    ConnectionStateLobby,
    ConnectionStateInGame
};

// Player network state - packed for efficient transmission
#pragma pack(push, 1)
typedef struct {
    uint32_t playerId;
    float posX, posY, posZ;
    float camYaw, camPitch;
    uint8_t isShooting;
    int32_t health;
} PlayerNetState;

// Game packet structure
typedef struct {
    uint8_t packetType;
    uint32_t sequence;
    PlayerNetState player;
} GamePacket;

// Discovery packet for LAN broadcast
typedef struct {
    uint8_t packetType;
    char serverName[32];
    uint8_t currentPlayers;
    uint8_t maxPlayers;
    uint16_t port;
} DiscoveryPacket;

// Connection packet for handshake
typedef struct {
    uint8_t packetType;
    uint32_t playerId;
    char playerName[32];
} ConnectionPacket;
#pragma pack(pop)

// Discovered host info
@interface DiscoveredHost : NSObject
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *serverName;
@property (nonatomic) uint16_t port;
@property (nonatomic) uint8_t currentPlayers;
@property (nonatomic) uint8_t maxPlayers;
@property (nonatomic) NSTimeInterval lastSeen;
@end

// Remote player info
@interface RemotePlayer : NSObject
@property (nonatomic) uint32_t playerId;
@property (nonatomic, copy) NSString *playerName;
@property (nonatomic, copy) NSString *address;
@property (nonatomic) int tcpSocket;
@property (nonatomic) uint16_t udpPort;  // Discovered from first UDP packet
@property (nonatomic) PlayerNetState lastState;
@property (nonatomic) uint32_t lastSequence;
@property (nonatomic) NSTimeInterval lastPacketTime;
@property (nonatomic) ConnectionState connectionState;
@end

// Delegate protocol for network events
@protocol NetworkManagerDelegate <NSObject>
@optional
- (void)networkManager:(id)manager didDiscoverHost:(DiscoveredHost *)host;
- (void)networkManager:(id)manager playerDidConnect:(RemotePlayer *)player;
- (void)networkManager:(id)manager playerDidDisconnect:(RemotePlayer *)player;
- (void)networkManager:(id)manager didReceiveStateUpdate:(PlayerNetState)state fromPlayer:(uint32_t)playerId;
- (void)networkManager:(id)manager didReceiveShoot:(PlayerNetState)state fromPlayer:(uint32_t)playerId;
- (void)networkManager:(id)manager didReceiveHit:(int)damage toPlayer:(uint32_t)playerId fromPlayer:(uint32_t)shooterId;
- (void)networkManager:(id)manager didReceiveKill:(uint32_t)victimId killedBy:(uint32_t)killerId;
- (void)networkManager:(id)manager didReceiveRespawn:(uint32_t)playerId atPosition:(PlayerNetState)state;
- (void)networkManager:(id)manager didReceiveGameStart:(uint32_t)hostPlayerId;
- (void)networkManagerDidConnect:(id)manager withPlayerId:(uint32_t)playerId;
- (void)networkManagerDidDisconnect:(id)manager;
- (void)networkManager:(id)manager didFailWithError:(NSError *)error;
@end

// Main NetworkManager class
@interface NetworkManager : NSObject

+ (instancetype)shared;

// Properties
@property (nonatomic, weak) id<NetworkManagerDelegate> delegate;
@property (nonatomic, readonly) NetworkMode mode;
@property (nonatomic, readonly) ConnectionState connectionState;
@property (nonatomic, readonly) uint32_t localPlayerId;
@property (nonatomic, copy) NSString *playerName;
@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, readonly) NSArray<RemotePlayer *> *connectedPlayers;
@property (nonatomic, readonly) NSArray<DiscoveredHost *> *discoveredHosts;

// Host mode
- (BOOL)startHostOnPort:(uint16_t)port;
- (BOOL)startHostOnPort:(uint16_t)port withName:(NSString *)name;
- (void)stopHost;

// Client mode
- (BOOL)connectToHost:(NSString *)address port:(uint16_t)port;
- (void)disconnect;

// LAN Discovery
- (void)startLANDiscovery;
- (void)stopLANDiscovery;
- (void)broadcastLANDiscovery;

// Sending data
- (void)sendStateUpdate:(PlayerNetState)state;
- (void)sendShoot:(PlayerNetState)state;
- (void)sendHit:(int)damage toPlayer:(uint32_t)playerId;
- (void)sendKill:(uint32_t)victimId;
- (void)sendRespawn:(PlayerNetState)state;
- (void)sendGameStart;
- (void)sendReliableMessage:(NSData *)data withType:(PacketType)type;

// Polling (call from game loop)
- (void)pollNetwork;

// Utility
- (NSTimeInterval)pingToPlayer:(uint32_t)playerId;
- (void)sendPing;

@end

#endif // NETWORKMANAGER_H

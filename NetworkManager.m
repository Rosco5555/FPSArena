// NetworkManager.m - Core networking implementation for LAN multiplayer
#import "NetworkManager.h"

#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <ifaddrs.h>
#include <net/if.h>

// Magic number for packet validation
static const uint32_t NET_MAGIC = 0x46505347;  // "FPSG"

// Internal packet header
#pragma pack(push, 1)
typedef struct {
    uint32_t magic;
    uint16_t length;
} PacketHeader;
#pragma pack(pop)

@implementation DiscoveredHost
@end

@implementation RemotePlayer
@end

@interface NetworkManager () {
    // UDP sockets
    int _udpSocket;
    int _discoverySocket;

    // TCP sockets
    int _tcpListenSocket;
    int _tcpClientSocket;  // For client mode connection to host

    // Network state
    uint32_t _sendSequence;
    struct sockaddr_in _hostAddress;

    // Buffers
    uint8_t _recvBuffer[NET_MAX_PACKET_SIZE];
    uint8_t _sendBuffer[NET_MAX_PACKET_SIZE];

    // Discovery state
    BOOL _isDiscovering;
    NSTimeInterval _lastDiscoveryBroadcast;

    // Timing
    NSTimeInterval _lastStateUpdate;
    NSMutableDictionary<NSNumber *, NSNumber *> *_pingTimes;
    NSMutableDictionary<NSNumber *, NSNumber *> *_pingSendTimes;
}

@property (nonatomic, readwrite) NetworkMode mode;
@property (nonatomic, readwrite) ConnectionState connectionState;
@property (nonatomic, readwrite) uint32_t localPlayerId;
@property (nonatomic, strong) NSMutableArray<RemotePlayer *> *mutableConnectedPlayers;
@property (nonatomic, strong) NSMutableArray<DiscoveredHost *> *mutableDiscoveredHosts;

@end

@implementation NetworkManager

#pragma mark - Singleton

+ (instancetype)shared {
    static NetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _udpSocket = -1;
        _discoverySocket = -1;
        _tcpListenSocket = -1;
        _tcpClientSocket = -1;
        _sendSequence = 0;
        _mode = NetworkModeNone;
        _connectionState = ConnectionStateDisconnected;
        _localPlayerId = 0;
        _playerName = @"Player";
        _serverName = @"FPS Server";
        _mutableConnectedPlayers = [NSMutableArray array];
        _mutableDiscoveredHosts = [NSMutableArray array];
        _pingTimes = [NSMutableDictionary dictionary];
        _pingSendTimes = [NSMutableDictionary dictionary];
        _isDiscovering = NO;
        _lastDiscoveryBroadcast = 0;
        _lastStateUpdate = 0;
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

#pragma mark - Properties

- (NSArray<RemotePlayer *> *)connectedPlayers {
    return [_mutableConnectedPlayers copy];
}

- (NSArray<DiscoveredHost *> *)discoveredHosts {
    return [_mutableDiscoveredHosts copy];
}

#pragma mark - Socket Utilities

- (BOOL)setSocketNonBlocking:(int)sock {
    int flags = fcntl(sock, F_GETFL, 0);
    if (flags < 0) return NO;
    return fcntl(sock, F_SETFL, flags | O_NONBLOCK) >= 0;
}

- (BOOL)setSocketReuseAddr:(int)sock {
    int opt = 1;
    return setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) >= 0;
}

- (BOOL)setSocketBroadcast:(int)sock {
    int opt = 1;
    return setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &opt, sizeof(opt)) >= 0;
}

- (BOOL)setTCPNoDelay:(int)sock {
    int opt = 1;
    return setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &opt, sizeof(opt)) >= 0;
}

- (int)createUDPSocket {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0) {
        NSLog(@"NetworkManager: Failed to create UDP socket: %s", strerror(errno));
        return -1;
    }

    [self setSocketNonBlocking:sock];
    [self setSocketReuseAddr:sock];

    return sock;
}

- (int)createTCPSocket {
    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock < 0) {
        NSLog(@"NetworkManager: Failed to create TCP socket: %s", strerror(errno));
        return -1;
    }

    [self setSocketNonBlocking:sock];
    [self setSocketReuseAddr:sock];
    [self setTCPNoDelay:sock];

    return sock;
}

- (BOOL)bindSocket:(int)sock toPort:(uint16_t)port {
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        NSLog(@"NetworkManager: Failed to bind socket to port %d: %s", port, strerror(errno));
        return NO;
    }
    return YES;
}

#pragma mark - Host Mode

- (BOOL)startHostOnPort:(uint16_t)port {
    return [self startHostOnPort:port withName:_serverName];
}

- (BOOL)startHostOnPort:(uint16_t)port withName:(NSString *)name {
    if (_mode != NetworkModeNone) {
        NSLog(@"NetworkManager: Already running in mode %ld", (long)_mode);
        return NO;
    }

    _serverName = [name copy];

    // Create UDP socket for game state updates
    _udpSocket = [self createUDPSocket];
    if (_udpSocket < 0) return NO;

    if (![self bindSocket:_udpSocket toPort:port]) {
        close(_udpSocket);
        _udpSocket = -1;
        return NO;
    }

    // Create TCP socket for reliable messages
    _tcpListenSocket = [self createTCPSocket];
    if (_tcpListenSocket < 0) {
        close(_udpSocket);
        _udpSocket = -1;
        return NO;
    }

    if (![self bindSocket:_tcpListenSocket toPort:port]) {
        close(_udpSocket);
        close(_tcpListenSocket);
        _udpSocket = -1;
        _tcpListenSocket = -1;
        return NO;
    }

    if (listen(_tcpListenSocket, NET_MAX_PLAYERS) < 0) {
        NSLog(@"NetworkManager: Failed to listen on TCP socket: %s", strerror(errno));
        close(_udpSocket);
        close(_tcpListenSocket);
        _udpSocket = -1;
        _tcpListenSocket = -1;
        return NO;
    }

    // Create discovery socket for responding to broadcasts
    _discoverySocket = [self createUDPSocket];
    if (_discoverySocket < 0) {
        close(_udpSocket);
        close(_tcpListenSocket);
        _udpSocket = -1;
        _tcpListenSocket = -1;
        return NO;
    }

    [self setSocketBroadcast:_discoverySocket];

    if (![self bindSocket:_discoverySocket toPort:NET_DISCOVERY_PORT]) {
        close(_udpSocket);
        close(_tcpListenSocket);
        close(_discoverySocket);
        _udpSocket = -1;
        _tcpListenSocket = -1;
        _discoverySocket = -1;
        return NO;
    }

    _mode = NetworkModeHost;
    _connectionState = ConnectionStateLobby;
    _localPlayerId = 1;  // Host is always player 1

    NSLog(@"NetworkManager: Host started on port %d", port);
    return YES;
}

- (void)stopHost {
    if (_mode != NetworkModeHost) return;

    // Notify all connected players
    for (RemotePlayer *player in _mutableConnectedPlayers) {
        [self sendDisconnectToPlayer:player];
    }

    [self cleanup];
    NSLog(@"NetworkManager: Host stopped");
}

#pragma mark - Client Mode

- (BOOL)connectToHost:(NSString *)address port:(uint16_t)port {
    if (_mode != NetworkModeNone) {
        NSLog(@"NetworkManager: Already running in mode %ld", (long)_mode);
        return NO;
    }

    // Create UDP socket for game state updates
    _udpSocket = [self createUDPSocket];
    if (_udpSocket < 0) return NO;

    // Bind to any available port
    if (![self bindSocket:_udpSocket toPort:0]) {
        close(_udpSocket);
        _udpSocket = -1;
        return NO;
    }

    // Create TCP socket for reliable connection
    _tcpClientSocket = [self createTCPSocket];
    if (_tcpClientSocket < 0) {
        close(_udpSocket);
        _udpSocket = -1;
        return NO;
    }

    // Set up host address
    memset(&_hostAddress, 0, sizeof(_hostAddress));
    _hostAddress.sin_family = AF_INET;
    _hostAddress.sin_port = htons(port);

    if (inet_pton(AF_INET, [address UTF8String], &_hostAddress.sin_addr) <= 0) {
        NSLog(@"NetworkManager: Invalid address: %@", address);
        close(_udpSocket);
        close(_tcpClientSocket);
        _udpSocket = -1;
        _tcpClientSocket = -1;
        return NO;
    }

    // Start non-blocking connect
    int result = connect(_tcpClientSocket, (struct sockaddr *)&_hostAddress, sizeof(_hostAddress));
    if (result < 0 && errno != EINPROGRESS) {
        NSLog(@"NetworkManager: Failed to connect: %s", strerror(errno));
        close(_udpSocket);
        close(_tcpClientSocket);
        _udpSocket = -1;
        _tcpClientSocket = -1;
        return NO;
    }

    _mode = NetworkModeClient;
    _connectionState = ConnectionStateConnecting;

    NSLog(@"NetworkManager: Connecting to %@:%d", address, port);
    return YES;
}

- (void)disconnect {
    if (_mode == NetworkModeNone) return;

    if (_mode == NetworkModeClient && _tcpClientSocket >= 0) {
        // Send disconnect packet
        ConnectionPacket packet;
        memset(&packet, 0, sizeof(packet));
        packet.packetType = PacketTypeDisconnect;
        packet.playerId = _localPlayerId;
        [self sendTCPData:&packet length:sizeof(packet) toSocket:_tcpClientSocket];
    }

    [self cleanup];

    if ([_delegate respondsToSelector:@selector(networkManagerDidDisconnect:)]) {
        [_delegate networkManagerDidDisconnect:self];
    }

    NSLog(@"NetworkManager: Disconnected");
}

#pragma mark - LAN Discovery

- (void)startLANDiscovery {
    if (_isDiscovering) return;

    if (_discoverySocket < 0) {
        _discoverySocket = [self createUDPSocket];
        if (_discoverySocket < 0) return;
        [self setSocketBroadcast:_discoverySocket];
    }

    _isDiscovering = YES;
    [_mutableDiscoveredHosts removeAllObjects];
    _lastDiscoveryBroadcast = 0;  // Force immediate broadcast

    NSLog(@"NetworkManager: Started LAN discovery");
}

- (void)stopLANDiscovery {
    _isDiscovering = NO;

    if (_mode == NetworkModeNone && _discoverySocket >= 0) {
        close(_discoverySocket);
        _discoverySocket = -1;
    }

    NSLog(@"NetworkManager: Stopped LAN discovery");
}

- (void)broadcastLANDiscovery {
    if (_discoverySocket < 0) return;

    DiscoveryPacket packet;
    memset(&packet, 0, sizeof(packet));
    packet.packetType = PacketTypeDiscovery;

    // Broadcast to 255.255.255.255 on discovery port
    struct sockaddr_in broadcastAddr;
    memset(&broadcastAddr, 0, sizeof(broadcastAddr));
    broadcastAddr.sin_family = AF_INET;
    broadcastAddr.sin_addr.s_addr = INADDR_BROADCAST;
    broadcastAddr.sin_port = htons(NET_DISCOVERY_PORT);

    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(sizeof(DiscoveryPacket));

    // Build complete packet with header
    memcpy(_sendBuffer, &header, sizeof(header));
    memcpy(_sendBuffer + sizeof(header), &packet, sizeof(packet));

    ssize_t sent = sendto(_discoverySocket, _sendBuffer, sizeof(header) + sizeof(packet), 0,
                          (struct sockaddr *)&broadcastAddr, sizeof(broadcastAddr));

    if (sent < 0) {
        NSLog(@"NetworkManager: Discovery broadcast failed: %s", strerror(errno));
    }

    _lastDiscoveryBroadcast = [NSDate timeIntervalSinceReferenceDate];
}

- (void)handleDiscoveryPacket:(DiscoveryPacket *)packet fromAddress:(struct sockaddr_in *)addr {
    if (_mode == NetworkModeHost) {
        // Respond to discovery request
        DiscoveryPacket response;
        memset(&response, 0, sizeof(response));
        response.packetType = PacketTypeDiscoveryResponse;
        strncpy(response.serverName, [_serverName UTF8String], sizeof(response.serverName) - 1);
        response.currentPlayers = (uint8_t)_mutableConnectedPlayers.count + 1;  // +1 for host
        response.maxPlayers = NET_MAX_PLAYERS;
        response.port = NET_DEFAULT_PORT;

        // Get actual bound port
        struct sockaddr_in localAddr;
        socklen_t addrLen = sizeof(localAddr);
        if (getsockname(_udpSocket, (struct sockaddr *)&localAddr, &addrLen) == 0) {
            response.port = ntohs(localAddr.sin_port);
        }

        PacketHeader header;
        header.magic = htonl(NET_MAGIC);
        header.length = htons(sizeof(response));

        memcpy(_sendBuffer, &header, sizeof(header));
        memcpy(_sendBuffer + sizeof(header), &response, sizeof(response));

        // Send response to requester
        addr->sin_port = htons(NET_DISCOVERY_PORT);
        sendto(_discoverySocket, _sendBuffer, sizeof(header) + sizeof(response), 0,
               (struct sockaddr *)addr, sizeof(*addr));
    }
}

- (void)handleDiscoveryResponse:(DiscoveryPacket *)packet fromAddress:(struct sockaddr_in *)addr {
    if (!_isDiscovering) return;

    char addrStr[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &addr->sin_addr, addrStr, sizeof(addrStr));
    NSString *address = [NSString stringWithUTF8String:addrStr];

    // Check if we already have this host
    DiscoveredHost *existing = nil;
    for (DiscoveredHost *host in _mutableDiscoveredHosts) {
        if ([host.address isEqualToString:address] && host.port == packet->port) {
            existing = host;
            break;
        }
    }

    if (existing) {
        // Update existing entry
        existing.serverName = [NSString stringWithUTF8String:packet->serverName];
        existing.currentPlayers = packet->currentPlayers;
        existing.maxPlayers = packet->maxPlayers;
        existing.lastSeen = [NSDate timeIntervalSinceReferenceDate];
    } else {
        // Add new host
        DiscoveredHost *host = [[DiscoveredHost alloc] init];
        host.address = address;
        host.serverName = [NSString stringWithUTF8String:packet->serverName];
        host.port = packet->port;
        host.currentPlayers = packet->currentPlayers;
        host.maxPlayers = packet->maxPlayers;
        host.lastSeen = [NSDate timeIntervalSinceReferenceDate];

        [_mutableDiscoveredHosts addObject:host];

        if ([_delegate respondsToSelector:@selector(networkManager:didDiscoverHost:)]) {
            [_delegate networkManager:self didDiscoverHost:host];
        }
    }
}

#pragma mark - Sending Data

- (void)sendStateUpdate:(PlayerNetState)state {
    if (_mode == NetworkModeNone) return;

    GamePacket packet;
    packet.packetType = PacketTypeStateUpdate;
    packet.sequence = ++_sendSequence;
    packet.player = state;
    packet.player.playerId = _localPlayerId;

    [self sendUDPPacket:&packet length:sizeof(packet)];
}

- (void)sendShoot:(PlayerNetState)state {
    if (_mode == NetworkModeNone) return;

    GamePacket packet;
    packet.packetType = PacketTypeShoot;
    packet.sequence = ++_sendSequence;
    packet.player = state;
    packet.player.playerId = _localPlayerId;
    packet.player.isShooting = 1;

    [self sendReliableGamePacket:&packet];
}

- (void)sendHit:(int)damage toPlayer:(uint32_t)playerId {
    if (_mode == NetworkModeNone) return;

    GamePacket packet;
    memset(&packet, 0, sizeof(packet));
    packet.packetType = PacketTypeHit;
    packet.sequence = ++_sendSequence;
    packet.player.playerId = playerId;
    packet.player.health = damage;  // Using health field to transmit damage amount

    [self sendReliableGamePacket:&packet];
}

- (void)sendKill:(uint32_t)victimId {
    if (_mode == NetworkModeNone) return;

    GamePacket packet;
    memset(&packet, 0, sizeof(packet));
    packet.packetType = PacketTypeKill;
    packet.sequence = ++_sendSequence;
    packet.player.playerId = victimId;

    [self sendReliableGamePacket:&packet];
}

- (void)sendRespawn:(PlayerNetState)state {
    if (_mode == NetworkModeNone) return;

    GamePacket packet;
    packet.packetType = PacketTypeRespawn;
    packet.sequence = ++_sendSequence;
    packet.player = state;
    packet.player.playerId = _localPlayerId;

    [self sendReliableGamePacket:&packet];
}

- (void)sendReliableMessage:(NSData *)data withType:(PacketType)type {
    if (_mode == NetworkModeNone || data.length > NET_MAX_PACKET_SIZE - sizeof(PacketHeader) - 1) {
        return;
    }

    uint8_t buffer[NET_MAX_PACKET_SIZE];
    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(data.length + 1);

    memcpy(buffer, &header, sizeof(header));
    buffer[sizeof(header)] = type;
    memcpy(buffer + sizeof(header) + 1, data.bytes, data.length);

    if (_mode == NetworkModeHost) {
        // Send to all connected clients
        for (RemotePlayer *player in _mutableConnectedPlayers) {
            if (player.tcpSocket >= 0) {
                send(player.tcpSocket, buffer, sizeof(header) + 1 + data.length, 0);
            }
        }
    } else {
        // Send to host
        if (_tcpClientSocket >= 0) {
            send(_tcpClientSocket, buffer, sizeof(header) + 1 + data.length, 0);
        }
    }
}

- (void)sendUDPPacket:(void *)packet length:(size_t)length {
    if (_udpSocket < 0) return;

    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(length);

    memcpy(_sendBuffer, &header, sizeof(header));
    memcpy(_sendBuffer + sizeof(header), packet, length);

    size_t totalLength = sizeof(header) + length;

    if (_mode == NetworkModeHost) {
        // Broadcast to all connected clients via their addresses
        for (RemotePlayer *player in _mutableConnectedPlayers) {
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_family = AF_INET;
            inet_pton(AF_INET, [player.address UTF8String], &addr.sin_addr);
            addr.sin_port = htons(NET_DEFAULT_PORT + player.playerId);  // Each client uses unique port

            sendto(_udpSocket, _sendBuffer, totalLength, 0,
                   (struct sockaddr *)&addr, sizeof(addr));
        }
    } else {
        // Send to host
        sendto(_udpSocket, _sendBuffer, totalLength, 0,
               (struct sockaddr *)&_hostAddress, sizeof(_hostAddress));
    }
}

- (void)sendReliableGamePacket:(GamePacket *)packet {
    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(sizeof(GamePacket));

    memcpy(_sendBuffer, &header, sizeof(header));
    memcpy(_sendBuffer + sizeof(header), packet, sizeof(GamePacket));

    size_t totalLength = sizeof(header) + sizeof(GamePacket);

    if (_mode == NetworkModeHost) {
        for (RemotePlayer *player in _mutableConnectedPlayers) {
            if (player.tcpSocket >= 0) {
                send(player.tcpSocket, _sendBuffer, totalLength, 0);
            }
        }
    } else {
        if (_tcpClientSocket >= 0) {
            send(_tcpClientSocket, _sendBuffer, totalLength, 0);
        }
    }
}

- (void)sendTCPData:(void *)data length:(size_t)length toSocket:(int)sock {
    if (sock < 0) return;

    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(length);

    memcpy(_sendBuffer, &header, sizeof(header));
    memcpy(_sendBuffer + sizeof(header), data, length);

    send(sock, _sendBuffer, sizeof(header) + length, 0);
}

- (void)sendDisconnectToPlayer:(RemotePlayer *)player {
    if (player.tcpSocket < 0) return;

    ConnectionPacket packet;
    memset(&packet, 0, sizeof(packet));
    packet.packetType = PacketTypeDisconnect;
    packet.playerId = _localPlayerId;

    [self sendTCPData:&packet length:sizeof(packet) toSocket:player.tcpSocket];
}

#pragma mark - Polling

- (void)pollNetwork {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    // Handle discovery broadcasts if discovering
    if (_isDiscovering && now - _lastDiscoveryBroadcast >= NET_DISCOVERY_INTERVAL) {
        [self broadcastLANDiscovery];
    }

    // Poll based on mode
    switch (_mode) {
        case NetworkModeHost:
            [self pollHostNetwork];
            break;
        case NetworkModeClient:
            [self pollClientNetwork];
            break;
        case NetworkModeNone:
            // Still poll discovery socket if discovering
            if (_isDiscovering) {
                [self pollDiscoverySocket];
            }
            break;
    }
}

- (void)pollHostNetwork {
    // Accept new TCP connections
    [self acceptNewConnections];

    // Poll TCP sockets from connected players
    for (RemotePlayer *player in [_mutableConnectedPlayers copy]) {
        [self pollTCPSocket:player.tcpSocket forPlayer:player];
    }

    // Poll UDP socket for state updates
    [self pollUDPSocket];

    // Poll discovery socket
    [self pollDiscoverySocket];

    // Clean up stale connections
    [self cleanupStaleConnections];
}

- (void)pollClientNetwork {
    // Check if connection completed
    if (_connectionState == ConnectionStateConnecting) {
        [self checkConnectionProgress];
    }

    // Poll TCP socket
    if (_tcpClientSocket >= 0) {
        [self pollTCPSocket:_tcpClientSocket forPlayer:nil];
    }

    // Poll UDP socket
    [self pollUDPSocket];
}

- (void)pollDiscoverySocket {
    if (_discoverySocket < 0) return;

    struct sockaddr_in senderAddr;
    socklen_t addrLen = sizeof(senderAddr);

    ssize_t received = recvfrom(_discoverySocket, _recvBuffer, NET_MAX_PACKET_SIZE, 0,
                                 (struct sockaddr *)&senderAddr, &addrLen);

    while (received > 0) {
        if (received >= (ssize_t)sizeof(PacketHeader)) {
            PacketHeader *header = (PacketHeader *)_recvBuffer;

            if (ntohl(header->magic) == NET_MAGIC) {
                uint16_t length = ntohs(header->length);
                uint8_t *payload = _recvBuffer + sizeof(PacketHeader);

                if (received >= (ssize_t)(sizeof(PacketHeader) + length) && length >= 1) {
                    uint8_t packetType = payload[0];

                    if (packetType == PacketTypeDiscovery) {
                        [self handleDiscoveryPacket:(DiscoveryPacket *)payload fromAddress:&senderAddr];
                    } else if (packetType == PacketTypeDiscoveryResponse) {
                        [self handleDiscoveryResponse:(DiscoveryPacket *)payload fromAddress:&senderAddr];
                    }
                }
            }
        }

        received = recvfrom(_discoverySocket, _recvBuffer, NET_MAX_PACKET_SIZE, 0,
                           (struct sockaddr *)&senderAddr, &addrLen);
    }
}

- (void)acceptNewConnections {
    if (_tcpListenSocket < 0) return;

    struct sockaddr_in clientAddr;
    socklen_t addrLen = sizeof(clientAddr);

    int clientSocket = accept(_tcpListenSocket, (struct sockaddr *)&clientAddr, &addrLen);

    while (clientSocket >= 0) {
        [self setSocketNonBlocking:clientSocket];
        [self setTCPNoDelay:clientSocket];

        char addrStr[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &clientAddr.sin_addr, addrStr, sizeof(addrStr));

        // Create new remote player
        RemotePlayer *player = [[RemotePlayer alloc] init];
        player.playerId = (uint32_t)(_mutableConnectedPlayers.count + 2);  // Host is 1, clients start at 2
        player.address = [NSString stringWithUTF8String:addrStr];
        player.tcpSocket = clientSocket;
        player.connectionState = ConnectionStateConnecting;
        player.lastPacketTime = [NSDate timeIntervalSinceReferenceDate];

        [_mutableConnectedPlayers addObject:player];

        // Send connection accepted packet
        ConnectionPacket response;
        memset(&response, 0, sizeof(response));
        response.packetType = PacketTypeConnectAccept;
        response.playerId = player.playerId;
        strncpy(response.playerName, [_serverName UTF8String], sizeof(response.playerName) - 1);

        [self sendTCPData:&response length:sizeof(response) toSocket:clientSocket];

        NSLog(@"NetworkManager: New connection from %s, assigned player ID %u", addrStr, player.playerId);

        clientSocket = accept(_tcpListenSocket, (struct sockaddr *)&clientAddr, &addrLen);
    }
}

- (void)pollTCPSocket:(int)sock forPlayer:(RemotePlayer *)player {
    if (sock < 0) return;

    ssize_t received = recv(sock, _recvBuffer, NET_MAX_PACKET_SIZE, 0);

    while (received > 0) {
        if (received >= (ssize_t)sizeof(PacketHeader)) {
            PacketHeader *header = (PacketHeader *)_recvBuffer;

            if (ntohl(header->magic) == NET_MAGIC) {
                uint16_t length = ntohs(header->length);
                uint8_t *payload = _recvBuffer + sizeof(PacketHeader);

                if (received >= (ssize_t)(sizeof(PacketHeader) + length)) {
                    [self handleTCPPacket:payload length:length fromPlayer:player socket:sock];

                    if (player) {
                        player.lastPacketTime = [NSDate timeIntervalSinceReferenceDate];
                    }
                }
            }
        }

        received = recv(sock, _recvBuffer, NET_MAX_PACKET_SIZE, 0);
    }

    // Check for disconnect
    if (received == 0 || (received < 0 && errno != EAGAIN && errno != EWOULDBLOCK)) {
        if (_mode == NetworkModeHost && player) {
            [self handlePlayerDisconnect:player];
        } else if (_mode == NetworkModeClient) {
            [self handleHostDisconnect];
        }
    }
}

- (void)pollUDPSocket {
    if (_udpSocket < 0) return;

    struct sockaddr_in senderAddr;
    socklen_t addrLen = sizeof(senderAddr);

    ssize_t received = recvfrom(_udpSocket, _recvBuffer, NET_MAX_PACKET_SIZE, 0,
                                 (struct sockaddr *)&senderAddr, &addrLen);

    while (received > 0) {
        if (received >= (ssize_t)sizeof(PacketHeader)) {
            PacketHeader *header = (PacketHeader *)_recvBuffer;

            if (ntohl(header->magic) == NET_MAGIC) {
                uint16_t length = ntohs(header->length);
                uint8_t *payload = _recvBuffer + sizeof(PacketHeader);

                if (received >= (ssize_t)(sizeof(PacketHeader) + length) && length >= sizeof(GamePacket)) {
                    GamePacket *packet = (GamePacket *)payload;
                    [self handleUDPGamePacket:packet fromAddress:&senderAddr];
                }
            }
        }

        received = recvfrom(_udpSocket, _recvBuffer, NET_MAX_PACKET_SIZE, 0,
                           (struct sockaddr *)&senderAddr, &addrLen);
    }
}

- (void)checkConnectionProgress {
    if (_tcpClientSocket < 0) return;

    fd_set writeSet;
    FD_ZERO(&writeSet);
    FD_SET(_tcpClientSocket, &writeSet);

    struct timeval timeout = {0, 0};  // Non-blocking check

    int result = select(_tcpClientSocket + 1, NULL, &writeSet, NULL, &timeout);

    if (result > 0) {
        // Check if connection succeeded
        int error = 0;
        socklen_t len = sizeof(error);
        getsockopt(_tcpClientSocket, SOL_SOCKET, SO_ERROR, &error, &len);

        if (error == 0) {
            // Connection succeeded, send connect packet
            ConnectionPacket packet;
            memset(&packet, 0, sizeof(packet));
            packet.packetType = PacketTypeConnect;
            strncpy(packet.playerName, [_playerName UTF8String], sizeof(packet.playerName) - 1);

            [self sendTCPData:&packet length:sizeof(packet) toSocket:_tcpClientSocket];

            NSLog(@"NetworkManager: TCP connection established, waiting for accept");
        } else {
            NSLog(@"NetworkManager: Connection failed: %s", strerror(error));
            [self handleConnectionFailure:[NSError errorWithDomain:@"NetworkManager"
                                                             code:error
                                                         userInfo:@{NSLocalizedDescriptionKey: @(strerror(error))}]];
        }
    }
}

#pragma mark - Packet Handling

- (void)handleTCPPacket:(uint8_t *)data length:(uint16_t)length fromPlayer:(RemotePlayer *)player socket:(int)sock {
    if (length < 1) return;

    uint8_t packetType = data[0];

    switch (packetType) {
        case PacketTypeConnect:
            if (_mode == NetworkModeHost && length >= sizeof(ConnectionPacket)) {
                ConnectionPacket *packet = (ConnectionPacket *)data;
                if (player) {
                    player.playerName = [NSString stringWithUTF8String:packet->playerName];
                    player.connectionState = ConnectionStateConnected;

                    NSLog(@"NetworkManager: Player '%@' connected with ID %u", player.playerName, player.playerId);

                    if ([_delegate respondsToSelector:@selector(networkManager:playerDidConnect:)]) {
                        [_delegate networkManager:self playerDidConnect:player];
                    }
                }
            }
            break;

        case PacketTypeConnectAccept:
            if (_mode == NetworkModeClient && length >= sizeof(ConnectionPacket)) {
                ConnectionPacket *packet = (ConnectionPacket *)data;
                _localPlayerId = packet->playerId;
                _connectionState = ConnectionStateConnected;

                NSLog(@"NetworkManager: Connected to server, assigned player ID %u", _localPlayerId);

                if ([_delegate respondsToSelector:@selector(networkManagerDidConnect:withPlayerId:)]) {
                    [_delegate networkManagerDidConnect:self withPlayerId:_localPlayerId];
                }
            }
            break;

        case PacketTypeDisconnect:
            if (_mode == NetworkModeHost && player) {
                [self handlePlayerDisconnect:player];
            } else if (_mode == NetworkModeClient) {
                [self handleHostDisconnect];
            }
            break;

        case PacketTypePing:
            [self handlePingFromSocket:sock];
            break;

        case PacketTypePong:
            if (length >= sizeof(uint32_t) + 1) {
                uint32_t playerId;
                memcpy(&playerId, data + 1, sizeof(playerId));
                [self handlePongFromPlayer:playerId];
            }
            break;

        default:
            if (length >= sizeof(GamePacket)) {
                GamePacket *packet = (GamePacket *)data;
                [self handleReliableGamePacket:packet fromPlayer:player];
            }
            break;
    }
}

- (void)handleUDPGamePacket:(GamePacket *)packet fromAddress:(struct sockaddr_in *)addr {
    if (packet->packetType != PacketTypeStateUpdate) return;

    uint32_t playerId = packet->player.playerId;

    // Update the player's state
    if (_mode == NetworkModeHost) {
        // Find the player
        for (RemotePlayer *player in _mutableConnectedPlayers) {
            if (player.playerId == playerId) {
                // Only accept newer packets (handle sequence wrap-around)
                int32_t seqDiff = (int32_t)(packet->sequence - player.lastSequence);
                if (seqDiff > 0 || seqDiff < -1000000) {
                    player.lastSequence = packet->sequence;
                    player.lastState = packet->player;
                    player.lastPacketTime = [NSDate timeIntervalSinceReferenceDate];

                    if ([_delegate respondsToSelector:@selector(networkManager:didReceiveStateUpdate:fromPlayer:)]) {
                        [_delegate networkManager:self didReceiveStateUpdate:packet->player fromPlayer:playerId];
                    }

                    // Relay to other clients
                    [self relayStateUpdateToOtherPlayers:packet exceptPlayer:playerId];
                }
                break;
            }
        }
    } else {
        // Client received state from another player (relayed by host)
        if ([_delegate respondsToSelector:@selector(networkManager:didReceiveStateUpdate:fromPlayer:)]) {
            [_delegate networkManager:self didReceiveStateUpdate:packet->player fromPlayer:playerId];
        }
    }
}

- (void)handleReliableGamePacket:(GamePacket *)packet fromPlayer:(RemotePlayer *)player {
    uint32_t playerId = packet->player.playerId;

    switch (packet->packetType) {
        case PacketTypeShoot:
            if ([_delegate respondsToSelector:@selector(networkManager:didReceiveShoot:fromPlayer:)]) {
                [_delegate networkManager:self didReceiveShoot:packet->player fromPlayer:playerId];
            }
            if (_mode == NetworkModeHost) {
                [self relayReliablePacketToOtherPlayers:packet exceptPlayer:playerId];
            }
            break;

        case PacketTypeHit: {
            int damage = packet->player.health;
            uint32_t targetId = packet->player.playerId;
            uint32_t shooterId = player ? player.playerId : 0;

            if ([_delegate respondsToSelector:@selector(networkManager:didReceiveHit:toPlayer:fromPlayer:)]) {
                [_delegate networkManager:self didReceiveHit:damage toPlayer:targetId fromPlayer:shooterId];
            }
            if (_mode == NetworkModeHost) {
                [self relayReliablePacketToOtherPlayers:packet exceptPlayer:shooterId];
            }
            break;
        }

        case PacketTypeKill: {
            uint32_t victimId = packet->player.playerId;
            uint32_t killerId = player ? player.playerId : _localPlayerId;

            if ([_delegate respondsToSelector:@selector(networkManager:didReceiveKill:killedBy:)]) {
                [_delegate networkManager:self didReceiveKill:victimId killedBy:killerId];
            }
            if (_mode == NetworkModeHost) {
                [self relayReliablePacketToOtherPlayers:packet exceptPlayer:killerId];
            }
            break;
        }

        case PacketTypeRespawn:
            if ([_delegate respondsToSelector:@selector(networkManager:didReceiveRespawn:atPosition:)]) {
                [_delegate networkManager:self didReceiveRespawn:playerId atPosition:packet->player];
            }
            if (_mode == NetworkModeHost) {
                [self relayReliablePacketToOtherPlayers:packet exceptPlayer:playerId];
            }
            break;

        default:
            break;
    }
}

- (void)relayStateUpdateToOtherPlayers:(GamePacket *)packet exceptPlayer:(uint32_t)excludeId {
    for (RemotePlayer *player in _mutableConnectedPlayers) {
        if (player.playerId != excludeId) {
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_family = AF_INET;
            inet_pton(AF_INET, [player.address UTF8String], &addr.sin_addr);
            addr.sin_port = htons(NET_DEFAULT_PORT + player.playerId);

            PacketHeader header;
            header.magic = htonl(NET_MAGIC);
            header.length = htons(sizeof(GamePacket));

            memcpy(_sendBuffer, &header, sizeof(header));
            memcpy(_sendBuffer + sizeof(header), packet, sizeof(GamePacket));

            sendto(_udpSocket, _sendBuffer, sizeof(header) + sizeof(GamePacket), 0,
                   (struct sockaddr *)&addr, sizeof(addr));
        }
    }
}

- (void)relayReliablePacketToOtherPlayers:(GamePacket *)packet exceptPlayer:(uint32_t)excludeId {
    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(sizeof(GamePacket));

    memcpy(_sendBuffer, &header, sizeof(header));
    memcpy(_sendBuffer + sizeof(header), packet, sizeof(GamePacket));

    for (RemotePlayer *player in _mutableConnectedPlayers) {
        if (player.playerId != excludeId && player.tcpSocket >= 0) {
            send(player.tcpSocket, _sendBuffer, sizeof(header) + sizeof(GamePacket), 0);
        }
    }
}

#pragma mark - Connection Management

- (void)handlePlayerDisconnect:(RemotePlayer *)player {
    NSLog(@"NetworkManager: Player %u (%@) disconnected", player.playerId, player.playerName);

    if (player.tcpSocket >= 0) {
        close(player.tcpSocket);
        player.tcpSocket = -1;
    }

    [_mutableConnectedPlayers removeObject:player];

    if ([_delegate respondsToSelector:@selector(networkManager:playerDidDisconnect:)]) {
        [_delegate networkManager:self playerDidDisconnect:player];
    }

    // Notify other players
    GamePacket packet;
    memset(&packet, 0, sizeof(packet));
    packet.packetType = PacketTypeDisconnect;
    packet.player.playerId = player.playerId;
    [self relayReliablePacketToOtherPlayers:&packet exceptPlayer:player.playerId];
}

- (void)handleHostDisconnect {
    NSLog(@"NetworkManager: Host disconnected");
    [self cleanup];

    if ([_delegate respondsToSelector:@selector(networkManagerDidDisconnect:)]) {
        [_delegate networkManagerDidDisconnect:self];
    }
}

- (void)handleConnectionFailure:(NSError *)error {
    [self cleanup];

    if ([_delegate respondsToSelector:@selector(networkManager:didFailWithError:)]) {
        [_delegate networkManager:self didFailWithError:error];
    }
}

- (void)cleanupStaleConnections {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeout = 10.0;  // 10 second timeout

    for (RemotePlayer *player in [_mutableConnectedPlayers copy]) {
        if (now - player.lastPacketTime > timeout) {
            NSLog(@"NetworkManager: Player %u timed out", player.playerId);
            [self handlePlayerDisconnect:player];
        }
    }

    // Also clean up old discovered hosts
    for (DiscoveredHost *host in [_mutableDiscoveredHosts copy]) {
        if (now - host.lastSeen > 5.0) {
            [_mutableDiscoveredHosts removeObject:host];
        }
    }
}

#pragma mark - Ping/Pong

- (void)sendPing {
    if (_mode == NetworkModeNone) return;

    uint8_t buffer[sizeof(PacketHeader) + 1 + sizeof(uint32_t)];
    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(1 + sizeof(uint32_t));

    memcpy(buffer, &header, sizeof(header));
    buffer[sizeof(header)] = PacketTypePing;
    memcpy(buffer + sizeof(header) + 1, &_localPlayerId, sizeof(_localPlayerId));

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    if (_mode == NetworkModeHost) {
        for (RemotePlayer *player in _mutableConnectedPlayers) {
            if (player.tcpSocket >= 0) {
                send(player.tcpSocket, buffer, sizeof(buffer), 0);
                _pingSendTimes[@(player.playerId)] = @(now);
            }
        }
    } else {
        if (_tcpClientSocket >= 0) {
            send(_tcpClientSocket, buffer, sizeof(buffer), 0);
            _pingSendTimes[@(1)] = @(now);  // Ping to host (ID 1)
        }
    }
}

- (void)handlePingFromSocket:(int)sock {
    uint8_t buffer[sizeof(PacketHeader) + 1 + sizeof(uint32_t)];
    PacketHeader header;
    header.magic = htonl(NET_MAGIC);
    header.length = htons(1 + sizeof(uint32_t));

    memcpy(buffer, &header, sizeof(header));
    buffer[sizeof(header)] = PacketTypePong;
    memcpy(buffer + sizeof(header) + 1, &_localPlayerId, sizeof(_localPlayerId));

    send(sock, buffer, sizeof(buffer), 0);
}

- (void)handlePongFromPlayer:(uint32_t)playerId {
    NSNumber *sendTime = _pingSendTimes[@(playerId)];
    if (sendTime) {
        NSTimeInterval ping = [NSDate timeIntervalSinceReferenceDate] - sendTime.doubleValue;
        _pingTimes[@(playerId)] = @(ping * 1000.0);  // Convert to milliseconds
        [_pingSendTimes removeObjectForKey:@(playerId)];
    }
}

- (NSTimeInterval)pingToPlayer:(uint32_t)playerId {
    NSNumber *ping = _pingTimes[@(playerId)];
    return ping ? ping.doubleValue : -1.0;
}

#pragma mark - Cleanup

- (void)cleanup {
    if (_udpSocket >= 0) {
        close(_udpSocket);
        _udpSocket = -1;
    }

    if (_discoverySocket >= 0) {
        close(_discoverySocket);
        _discoverySocket = -1;
    }

    if (_tcpListenSocket >= 0) {
        close(_tcpListenSocket);
        _tcpListenSocket = -1;
    }

    if (_tcpClientSocket >= 0) {
        close(_tcpClientSocket);
        _tcpClientSocket = -1;
    }

    for (RemotePlayer *player in _mutableConnectedPlayers) {
        if (player.tcpSocket >= 0) {
            close(player.tcpSocket);
            player.tcpSocket = -1;
        }
    }

    [_mutableConnectedPlayers removeAllObjects];
    [_mutableDiscoveredHosts removeAllObjects];
    [_pingTimes removeAllObjects];
    [_pingSendTimes removeAllObjects];

    _mode = NetworkModeNone;
    _connectionState = ConnectionStateDisconnected;
    _localPlayerId = 0;
    _sendSequence = 0;
    _isDiscovering = NO;
}

@end

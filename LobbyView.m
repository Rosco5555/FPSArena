// LobbyView.m - Multiplayer lobby UI implementation
#import "LobbyView.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

// UI Constants
static const CGFloat kButtonWidth = 200.0;
static const CGFloat kButtonHeight = 40.0;
static const CGFloat kButtonSpacing = 20.0;
static const CGFloat kTitleFontSize = 36.0;
static const CGFloat kButtonFontSize = 18.0;
static const CGFloat kStatusFontSize = 16.0;
static const CGFloat kHostListItemHeight = 35.0;

// Colors
#define kBackgroundColor [NSColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0]
#define kButtonColor [NSColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:1.0]
#define kButtonHoverColor [NSColor colorWithRed:0.3 green:0.3 blue:0.35 alpha:1.0]
#define kTextColor [NSColor whiteColor]
#define kAccentColor [NSColor colorWithRed:1.0 green:0.85 blue:0.0 alpha:1.0]
#define kReadyColor [NSColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0]

@interface LobbyView ()
@property (nonatomic, assign) NSInteger hoveredButtonIndex;
@property (nonatomic, assign) NSInteger hoveredHostIndex;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@end

@implementation LobbyView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _state = LobbyStateMainMenu;
        _isHost = NO;
        _discoveredHosts = [NSMutableArray array];
        _hoveredButtonIndex = -1;
        _hoveredHostIndex = -1;
        _playerOneReady = NO;
        _playerTwoReady = NO;
        _hostIPAddress = [self getLocalIPAddress];
    }
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.trackingArea) {
        [self removeTrackingArea:self.trackingArea];
    }
    self.trackingArea = [[NSTrackingArea alloc]
        initWithRect:self.bounds
        options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
        owner:self
        userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

#pragma mark - Public Methods

- (void)transitionToState:(LobbyState)newState {
    _state = newState;
    _hoveredButtonIndex = -1;
    _hoveredHostIndex = -1;
    [self setNeedsDisplay:YES];
}

- (void)addDiscoveredHost:(NSString *)hostIP {
    if (![_discoveredHosts containsObject:hostIP]) {
        [_discoveredHosts addObject:hostIP];
        [self setNeedsDisplay:YES];
    }
}

- (void)clearDiscoveredHosts {
    [_discoveredHosts removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)setPlayerReady:(int)playerNumber ready:(BOOL)ready {
    if (playerNumber == 1) {
        _playerOneReady = ready;
    } else if (playerNumber == 2) {
        _playerTwoReady = ready;
    }
    [self setNeedsDisplay:YES];
}

- (NSString *)getLocalIPAddress {
    NSString *address = @"127.0.0.1";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                NSString *ifName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                // Look for en0 (WiFi) or en1 (Ethernet) interfaces
                if ([ifName isEqualToString:@"en0"] || [ifName isEqualToString:@"en1"]) {
                    address = [NSString stringWithUTF8String:
                        inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Draw background
    [kBackgroundColor setFill];
    NSRectFill(dirtyRect);

    switch (_state) {
        case LobbyStateMainMenu:
            [self drawMainMenu];
            break;
        case LobbyStateHosting:
            [self drawHostingState];
            break;
        case LobbyStateJoining:
            [self drawJoiningState];
            break;
        case LobbyStateConnected:
            [self drawConnectedState];
            break;
    }
}

- (void)drawMainMenu {
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    // Draw title
    [self drawText:@"FPS ARENA"
            atPoint:NSMakePoint(centerX, centerY + 150)
           fontSize:kTitleFontSize
              color:kAccentColor
           centered:YES];

    // Draw subtitle
    [self drawText:@"MULTIPLAYER"
            atPoint:NSMakePoint(centerX, centerY + 100)
           fontSize:kStatusFontSize
              color:kTextColor
           centered:YES];

    // Draw buttons
    CGFloat buttonY = centerY + 30;

    [self drawButton:@"HOST GAME"
              atRect:NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 0)];

    buttonY -= (kButtonHeight + kButtonSpacing);
    [self drawButton:@"JOIN GAME"
              atRect:NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 1)];

    buttonY -= (kButtonHeight + kButtonSpacing);
    [self drawButton:@"SINGLE PLAYER"
              atRect:NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 2)];
}

- (void)drawHostingState {
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    // Draw title
    [self drawText:@"HOSTING GAME"
            atPoint:NSMakePoint(centerX, centerY + 120)
           fontSize:kTitleFontSize
              color:kAccentColor
           centered:YES];

    // Draw status
    [self drawText:@"Waiting for player..."
            atPoint:NSMakePoint(centerX, centerY + 50)
           fontSize:kStatusFontSize
              color:kTextColor
           centered:YES];

    // Draw IP address
    NSString *ipText = [NSString stringWithFormat:@"Your IP: %@", _hostIPAddress];
    [self drawText:ipText
            atPoint:NSMakePoint(centerX, centerY)
           fontSize:kStatusFontSize
              color:kAccentColor
           centered:YES];

    // Draw cancel button
    [self drawButton:@"CANCEL"
              atRect:NSMakeRect(centerX - kButtonWidth/2, centerY - 100, kButtonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 0)];
}

- (void)drawJoiningState {
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    // Draw title
    [self drawText:@"JOIN GAME"
            atPoint:NSMakePoint(centerX, centerY + 150)
           fontSize:kTitleFontSize
              color:kAccentColor
           centered:YES];

    // Draw status
    [self drawText:@"Scanning for games..."
            atPoint:NSMakePoint(centerX, centerY + 100)
           fontSize:kStatusFontSize
              color:kTextColor
           centered:YES];

    // Draw host list
    CGFloat listStartY = centerY + 50;
    if (_discoveredHosts.count == 0) {
        [self drawText:@"No games found"
                atPoint:NSMakePoint(centerX, listStartY)
               fontSize:kStatusFontSize
                  color:[NSColor grayColor]
               centered:YES];
    } else {
        for (NSUInteger i = 0; i < _discoveredHosts.count; i++) {
            CGFloat itemY = listStartY - (i * kHostListItemHeight);
            NSRect itemRect = NSMakeRect(centerX - kButtonWidth/2, itemY, kButtonWidth, kHostListItemHeight - 5);

            BOOL isHovered = (_hoveredHostIndex == (NSInteger)i);
            [self drawButton:_discoveredHosts[i]
                      atRect:itemRect
                     hovered:isHovered];
        }
    }

    // Draw buttons at bottom
    CGFloat buttonY = centerY - 120;
    CGFloat buttonWidth = 90;

    [self drawButton:@"REFRESH"
              atRect:NSMakeRect(centerX - buttonWidth - 10, buttonY, buttonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 0)];

    [self drawButton:@"BACK"
              atRect:NSMakeRect(centerX + 10, buttonY, buttonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 1)];
}

- (void)drawConnectedState {
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    // Draw title
    [self drawText:@"GAME LOBBY"
            atPoint:NSMakePoint(centerX, centerY + 150)
           fontSize:kTitleFontSize
              color:kAccentColor
           centered:YES];

    // Draw player status
    CGFloat playerY = centerY + 70;

    // Player 1 (Host)
    NSString *p1Status = _playerOneReady ? @"READY" : @"NOT READY";
    NSColor *p1Color = _playerOneReady ? kReadyColor : kTextColor;
    [self drawText:@"Player 1 (Host)"
            atPoint:NSMakePoint(centerX, playerY)
           fontSize:kStatusFontSize
              color:kTextColor
           centered:YES];
    [self drawText:p1Status
            atPoint:NSMakePoint(centerX, playerY - 25)
           fontSize:kStatusFontSize
              color:p1Color
           centered:YES];

    // Player 2 (Client)
    playerY -= 80;
    NSString *p2Status = _playerTwoReady ? @"READY" : @"NOT READY";
    NSColor *p2Color = _playerTwoReady ? kReadyColor : kTextColor;
    [self drawText:@"Player 2"
            atPoint:NSMakePoint(centerX, playerY)
           fontSize:kStatusFontSize
              color:kTextColor
           centered:YES];
    [self drawText:p2Status
            atPoint:NSMakePoint(centerX, playerY - 25)
           fontSize:kStatusFontSize
              color:p2Color
           centered:YES];

    // Draw action area
    CGFloat buttonY = centerY - 100;

    if (_isHost) {
        // Host sees START GAME button (only enabled when both ready)
        BOOL canStart = _playerOneReady && _playerTwoReady;
        if (canStart) {
            [self drawButton:@"START GAME"
                      atRect:NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight)
                     hovered:(_hoveredButtonIndex == 0)];
        } else {
            [self drawText:@"Waiting for players to ready up..."
                    atPoint:NSMakePoint(centerX, buttonY + kButtonHeight/2)
                   fontSize:kStatusFontSize
                      color:[NSColor grayColor]
                   centered:YES];
        }
    } else {
        // Client sees waiting message
        [self drawText:@"Waiting for host to start..."
                atPoint:NSMakePoint(centerX, buttonY + kButtonHeight/2)
               fontSize:kStatusFontSize
                  color:kTextColor
               centered:YES];
    }

    // Cancel button
    [self drawButton:@"LEAVE"
              atRect:NSMakeRect(centerX - kButtonWidth/2, buttonY - 60, kButtonWidth, kButtonHeight)
             hovered:(_hoveredButtonIndex == 1)];
}

#pragma mark - Drawing Helpers

- (void)drawButton:(NSString *)title atRect:(NSRect)rect hovered:(BOOL)hovered {
    // Draw button background
    NSColor *bgColor = hovered ? kButtonHoverColor : kButtonColor;
    [bgColor setFill];
    NSRectFill(rect);

    // Draw button border
    [kAccentColor setStroke];
    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:rect];
    [borderPath setLineWidth:hovered ? 2.0 : 1.0];
    [borderPath stroke];

    // Draw button text
    NSColor *textColor = hovered ? kAccentColor : kTextColor;
    [self drawText:title
            atPoint:NSMakePoint(NSMidX(rect), NSMidY(rect))
           fontSize:kButtonFontSize
              color:textColor
           centered:YES];
}

- (void)drawText:(NSString *)text atPoint:(NSPoint)point fontSize:(CGFloat)fontSize color:(NSColor *)color centered:(BOOL)centered {
    NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:fontSize];
    if (!font) {
        font = [NSFont boldSystemFontOfSize:fontSize];
    }

    NSDictionary *attrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color
    };

    NSSize textSize = [text sizeWithAttributes:attrs];
    NSPoint drawPoint = point;

    if (centered) {
        drawPoint.x -= textSize.width / 2;
        drawPoint.y -= textSize.height / 2;
    }

    [text drawAtPoint:drawPoint withAttributes:attrs];
}

#pragma mark - Hit Testing

- (NSInteger)buttonIndexAtPoint:(NSPoint)point {
    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);

    switch (_state) {
        case LobbyStateMainMenu: {
            CGFloat buttonY = centerY + 30;
            for (int i = 0; i < 3; i++) {
                NSRect buttonRect = NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight);
                if (NSPointInRect(point, buttonRect)) {
                    return i;
                }
                buttonY -= (kButtonHeight + kButtonSpacing);
            }
            break;
        }
        case LobbyStateHosting: {
            NSRect cancelRect = NSMakeRect(centerX - kButtonWidth/2, centerY - 100, kButtonWidth, kButtonHeight);
            if (NSPointInRect(point, cancelRect)) {
                return 0;
            }
            break;
        }
        case LobbyStateJoining: {
            CGFloat buttonY = centerY - 120;
            CGFloat buttonWidth = 90;

            NSRect refreshRect = NSMakeRect(centerX - buttonWidth - 10, buttonY, buttonWidth, kButtonHeight);
            if (NSPointInRect(point, refreshRect)) {
                return 0;
            }

            NSRect backRect = NSMakeRect(centerX + 10, buttonY, buttonWidth, kButtonHeight);
            if (NSPointInRect(point, backRect)) {
                return 1;
            }
            break;
        }
        case LobbyStateConnected: {
            CGFloat buttonY = centerY - 100;

            if (_isHost && _playerOneReady && _playerTwoReady) {
                NSRect startRect = NSMakeRect(centerX - kButtonWidth/2, buttonY, kButtonWidth, kButtonHeight);
                if (NSPointInRect(point, startRect)) {
                    return 0;
                }
            }

            NSRect leaveRect = NSMakeRect(centerX - kButtonWidth/2, buttonY - 60, kButtonWidth, kButtonHeight);
            if (NSPointInRect(point, leaveRect)) {
                return 1;
            }
            break;
        }
    }

    return -1;
}

- (NSInteger)hostIndexAtPoint:(NSPoint)point {
    if (_state != LobbyStateJoining || _discoveredHosts.count == 0) {
        return -1;
    }

    CGFloat centerX = NSMidX(self.bounds);
    CGFloat centerY = NSMidY(self.bounds);
    CGFloat listStartY = centerY + 50;

    for (NSUInteger i = 0; i < _discoveredHosts.count; i++) {
        CGFloat itemY = listStartY - (i * kHostListItemHeight);
        NSRect itemRect = NSMakeRect(centerX - kButtonWidth/2, itemY, kButtonWidth, kHostListItemHeight - 5);
        if (NSPointInRect(point, itemRect)) {
            return (NSInteger)i;
        }
    }

    return -1;
}

#pragma mark - Mouse Events

- (void)mouseMoved:(NSEvent *)event {
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];

    NSInteger oldButtonIndex = _hoveredButtonIndex;
    NSInteger oldHostIndex = _hoveredHostIndex;

    _hoveredButtonIndex = [self buttonIndexAtPoint:location];
    _hoveredHostIndex = [self hostIndexAtPoint:location];

    if (_hoveredButtonIndex != oldButtonIndex || _hoveredHostIndex != oldHostIndex) {
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];

    // Check host list first (joining state)
    NSInteger hostIndex = [self hostIndexAtPoint:location];
    if (hostIndex >= 0 && hostIndex < (NSInteger)_discoveredHosts.count) {
        NSString *hostIP = _discoveredHosts[hostIndex];
        if ([_delegate respondsToSelector:@selector(lobbyDidConnectToHost:)]) {
            [_delegate lobbyDidConnectToHost:hostIP];
        }
        return;
    }

    // Check buttons
    NSInteger buttonIndex = [self buttonIndexAtPoint:location];
    if (buttonIndex < 0) return;

    switch (_state) {
        case LobbyStateMainMenu:
            switch (buttonIndex) {
                case 0: // HOST GAME
                    _isHost = YES;
                    if ([_delegate respondsToSelector:@selector(lobbyDidStartHosting)]) {
                        [_delegate lobbyDidStartHosting];
                    }
                    [self transitionToState:LobbyStateHosting];
                    break;
                case 1: // JOIN GAME
                    _isHost = NO;
                    [self transitionToState:LobbyStateJoining];
                    if ([_delegate respondsToSelector:@selector(lobbyNeedsDiscovery)]) {
                        [_delegate lobbyNeedsDiscovery];
                    }
                    break;
                case 2: // SINGLE PLAYER
                    if ([_delegate respondsToSelector:@selector(lobbyDidSelectSinglePlayer)]) {
                        [_delegate lobbyDidSelectSinglePlayer];
                    }
                    break;
            }
            break;

        case LobbyStateHosting:
            if (buttonIndex == 0) { // CANCEL
                if ([_delegate respondsToSelector:@selector(lobbyDidCancel)]) {
                    [_delegate lobbyDidCancel];
                }
                [self transitionToState:LobbyStateMainMenu];
            }
            break;

        case LobbyStateJoining:
            switch (buttonIndex) {
                case 0: // REFRESH
                    [self clearDiscoveredHosts];
                    if ([_delegate respondsToSelector:@selector(lobbyNeedsDiscovery)]) {
                        [_delegate lobbyNeedsDiscovery];
                    }
                    break;
                case 1: // BACK
                    [self transitionToState:LobbyStateMainMenu];
                    break;
            }
            break;

        case LobbyStateConnected:
            if (buttonIndex == 0 && _isHost) { // START GAME
                if ([_delegate respondsToSelector:@selector(lobbyDidStartGame)]) {
                    [_delegate lobbyDidStartGame];
                }
            } else if (buttonIndex == 1) { // LEAVE
                if ([_delegate respondsToSelector:@selector(lobbyDidCancel)]) {
                    [_delegate lobbyDidCancel];
                }
                [self transitionToState:LobbyStateMainMenu];
            }
            break;
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self mouseMoved:event];
}

- (void)mouseExited:(NSEvent *)event {
    _hoveredButtonIndex = -1;
    _hoveredHostIndex = -1;
    [self setNeedsDisplay:YES];
}

@end

// AppDelegate.m - App lifecycle implementation
#import "AppDelegate.h"

@implementation AppDelegate

- (void)windowWillClose:(NSNotification *)notification {
    CGAssociateMouseAndMouseCursorPosition(true);
    [NSCursor unhide];
    [NSApp terminate:self];
}

@end

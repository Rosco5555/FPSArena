// AppDelegate.m - App lifecycle implementation
#import "AppDelegate.h"

// External function from main.m
extern void closeDebugTerminal(void);

@implementation AppDelegate

- (void)windowWillClose:(NSNotification *)notification {
    CGAssociateMouseAndMouseCursorPosition(true);
    [NSCursor unhide];
    closeDebugTerminal();
    [NSApp terminate:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    closeDebugTerminal();
}

@end

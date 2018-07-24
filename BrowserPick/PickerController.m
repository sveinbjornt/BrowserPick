//
//  SelectionWindowController.m
//  BrowserPick
//
//  Created by Sveinbjorn Thordarson on 25/07/2018.
//  Copyright © 2018 Sveinbjorn Thordarson. All rights reserved.
//

#import "PickerController.h"

@interface PickerController ()
{
    NSURL *url;
}
@end

@implementation PickerController

+ (NSWindow *)pickerWindow {
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,0,0)
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:YES
                                                   screen:[NSScreen mainScreen]];
    [win setTitlebarAppearsTransparent:YES];
    [win setTitle:@"Browser Picker"];
    
    return win;
}

#pragma mark -

//- (void)windowDidLoad {
//    [super windowDidLoad];
//}

- (void)setURL:(NSURL *)theURL {
    url = theURL;
}

- (void)setAppOptions:(NSArray<NSBundle *> *)appBundles {
    
    NSMutableArray<NSBundle *> *apps = [appBundles mutableCopy];
//    [apps addObject:apps[0]];
    
    
    NSUInteger numWide = 0;
    NSUInteger numHigh = 1;
    
    NSUInteger numItems = [apps count];
    
    if (numItems <= 3) {
        numWide = numItems;
    } else {
        if ((numItems % 3) == 0) {
            numWide = 3;
            numHigh = (numItems / 3);
        }
        else if ((numItems % 2) == 0) {
            numWide = 2;
            numHigh = (numItems / 2);
        }
        else {
            numWide = 3;
            numHigh = (numItems / 3) + 1;
        }
    }
    
    // Set window size
    CGFloat buttonWidth = 160.f;
    CGFloat buttonHeight = 160.f;
    CGFloat buttonPadding = 20.f;
    
    CGFloat windowWidth = (2 * buttonPadding) + (numWide * buttonWidth) + ((numWide-1) * buttonPadding);
    CGFloat windowHeight = (2 * buttonPadding) + (numHigh * buttonHeight) + ((numHigh-1) * buttonPadding) + (buttonPadding/2);
    
    NSRect oldFrame = self.window.frame;
    NSRect frame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y, windowWidth, windowHeight);
    [self.window setFrame:frame display:NO];
    [self.window center];
    
    NSUInteger x = 0;
    NSUInteger y = 0;
    
    for (NSBundle *bundle in apps) {
        
        NSString *name = [[bundle infoDictionary] objectForKey:@"CFBundleName"];
        NSString *displayTitle = [NSString stringWithFormat:@"%@ (%@)", name];
        NSString *path = [bundle bundlePath];
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [icon setSize:NSMakeSize(128, 128)];
        
        NSUInteger xpt = buttonPadding + (x * buttonWidth) + (x * buttonPadding);
        NSUInteger ypt = buttonPadding + (y * buttonWidth) + (y * buttonPadding);
        
        NSRect rect = NSMakeRect(xpt, ypt, buttonWidth, buttonHeight);
        
        NSLog(@"%@", NSStringFromRect(rect));
        
        NSButton *button = [[NSButton alloc] initWithFrame:rect];
        [button setButtonType:NSButtonTypeMomentaryPushIn];
        [button setBezelStyle:NSBezelStyleShadowlessSquare];
        [button setImagePosition:NSImageAbove];
        [button setImageScaling:NSImageScaleProportionallyDown];
        [button setTitle:displayTitle];
        [button setImage:icon];
        [button setToolTip:path];
        [button setAction:@selector(browserButtonClicked:)];
        [button setTarget:self];
        
        [self.window.contentView addSubview:button];
        
        if (x == numWide-1) {
            y += 1;
            x = 0;
        } else {
            x += 1;
        }
        
    }
}

#pragma mark -

- (IBAction)browserButtonClicked:(id)sender {
    //NSLog([sender toolTip]);
    
    [[NSWorkspace sharedWorkspace] openURLs:@[url]
                       withApplicationAtURL:[NSURL fileURLWithPath:[sender toolTip]]
                                    options:0
                              configuration:@{}
                                      error:nil];
    [self.window close];
}

@end

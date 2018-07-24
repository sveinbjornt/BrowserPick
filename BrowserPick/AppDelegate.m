//
//  AppDelegate.m
//  BrowserPick
//
//  Created by Sveinbjorn Thordarson on 24/07/2018.
//  Copyright © 2018 Sveinbjorn Thordarson. All rights reserved.
//

#import "AppDelegate.h"
#import "PickerController.h"
#import "PrefsController.h"

#define COMMON_BROWSERS @[  @"Safari", @"Firefox", @"Chrome", @"Chromium", @"Yandex",\
                            @"Vivaldi", @"Opera", @"Tor", @"OmniWeb", @"Brave", @"Maxthon"]

#ifdef DEBUG
    #define DebugLog(...) NSLog(__VA_ARGS__)
#else
    #define DebugLog(...)
#endif

@interface AppDelegate ()
{
    PickerController *selectionController;
    PrefsController *prefsController;
}
@end

@implementation AppDelegate

+ (void)initialize {
    // register the dictionary of defaults
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // First launch
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Browsers"] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[self installedBrowsers] forKey:@"Browsers"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Get HTTP handlers

+ (NSArray *)installedHttpHandlers {
    
    NSArray *httpApps = (NSArray *)CFBridgingRelease(LSCopyAllHandlersForURLScheme(CFSTR("http")));
    NSArray *httpsApps = (NSArray *)CFBridgingRelease(LSCopyAllHandlersForURLScheme(CFSTR("https")));
    
    if (!httpsApps && !httpsApps) {
        return @[];
    }
    
    NSMutableSet *set = [NSMutableSet setWithArray:httpApps];
    [set addObjectsFromArray:httpsApps];
    
    return [set allObjects];
}

+ (NSArray *)installedBrowsers {
    NSMutableArray *apps = [NSMutableArray arrayWithArray:[self installedHttpHandlers]];
    
    DebugLog(@"HTTP handlers:\n%@", [apps description]);
    
    // Filter out apps that probably aren't browsers
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
        NSString *app = obj;
        for (NSString *browserName in COMMON_BROWSERS) {
            if ([[app lowercaseString] rangeOfString:[browserName lowercaseString]].location != NSNotFound) {
                
                NSArray *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef _Nonnull)(app), NULL));
                if (urls == nil || [urls count] == 0) {
                    return NO;
                }
                
                return YES;
            }
        }
        return NO;
    }];
    
    [apps filterUsingPredicate:p];
    
    DebugLog(@"Browsers found:\n%@", [apps description]);
    
    return apps;
}

+ (NSArray<NSBundle *> *)installedBrowserBundles {
    NSMutableArray *appBundles = [NSMutableArray array];
    
    for (NSString *identifier in [self installedBrowsers]) {
        
        // Find URL to app with identifier
        CFErrorRef cfErr;
        NSArray *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef _Nonnull)(identifier), &cfErr));
        if (urls == nil || [urls count] == 0) {
            NSError *nsErr = (__bridge NSError *)cfErr;
            DebugLog(@"Error: %@\n", [nsErr description]);
            continue;
        }
        
        NSBundle *bundle = [NSBundle bundleWithURL:urls[0]];
        if (bundle) {
            [appBundles addObject:bundle];
        } else {
            NSLog(@"Unable to get app bundle for identifier %@", identifier);
        }
    }
    
    return appBundles;
}

#pragma mark - NSApplicationDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Register ourselves as a URL handler for http
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(getUrl:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [self showPickerWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"Received open URL event for URL %@", [url description]);
    
    BOOL down = NO;
    
//    CGEventFlags theFlags;
//    theFlags = CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState);
//    if(0x7a & theFlags){
//        down = YES;
//    }

    if (CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState,3)) {
        down = YES;
    }
    
    if (down) {
        NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.apple.Safari"];
        [[NSWorkspace sharedWorkspace] openURLs:@[url]
                           withApplicationAtURL:appURL
                                        options:0
                                  configuration:@{}
                                          error:nil];
    } else {
        [self showPickerWindowForURL:url];
    }
}

#pragma mark - Window controllers

- (IBAction)showPickerWindowForURL:(NSURL *)url {
    if (selectionController == nil) {
        selectionController = [[PickerController alloc] initWithWindow:[PickerController pickerWindow]];
    }
    
    [selectionController setURL:url];
    [selectionController setAppOptions:[AppDelegate installedBrowserBundles]];
    [selectionController showWindow:self];
}

- (IBAction)showPrefs:(id)sender {
    if (prefsController == nil) {
        prefsController = [[PrefsController alloc] initWithWindowNibName:@"PrefsWindow"];
    }
    [prefsController showWindow:self];
}

#pragma mark -

- (IBAction)openDonations:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sveinbjorn.org/donations"]];
}

- (IBAction)openWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://sveinbjorn.org/browserpick"]];
}

- (IBAction)openGitHubWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/sveinbjornt/BrowserPick"]];
}

@end

//
//  PrefsController.m
//  BrowserPick
//
//  Created by Sveinbjorn Thordarson on 28/07/2018.
//  Copyright © 2018 Sveinbjorn Thordarson. All rights reserved.
//

#import "PrefsController.h"
#import "Alerts.h"

@interface PrefsController ()
{
    IBOutlet NSTableView *tableView;
    NSMutableArray *browsers;
}
@end

@implementation PrefsController

#pragma mark - NSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Put application icon in window title bar
    [[self window] setRepresentedURL:[NSURL URLWithString:@""]];
    [[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:[NSApp applicationIconImage]];
        
    // Configure table view
    [tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(rowDoubleClicked:)];
    [tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    // Load info for browsers saved in defaults
    browsers = [NSMutableArray array];
    NSArray *browserIdentifiers = [[NSUserDefaults standardUserDefaults] objectForKey:@"Browsers"];
    
    for (NSString *identifier in browserIdentifiers) {
        
        // Find URL to app with identifier
        CFErrorRef cfErr;
        NSArray *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef _Nonnull)(identifier), &cfErr));
//        if (urls == nil || [urls count] == 0) {
//            DebugLog(@"Error: %@\n", [(__bridge NSError *)cfErr description]);
//            continue;
//        }
//
        NSBundle *bundle = [NSBundle bundleWithURL:urls[0]];
//        if (bundle) {
//            [appBundles addObject:bundle];
//        } else {
//            NSLog(@"Unable to get app bundle for identifier %@", identifier);
//        }
        
        NSDictionary *browserInfo = @{  @"name": [[bundle infoDictionary] objectForKey:@"CFBundleName"],
                                        @"icon": [[NSWorkspace sharedWorkspace] iconForFile:[bundle bundlePath]],
                                      
                                      };
        
        [browsers addObject:browserInfo];
    }
    
    
    
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu {
    // Prevent popup menu when window icon/title is cmd-clicked
    return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
    // Prevent dragging of title bar icon
    return NO;
}

#pragma mark -

- (IBAction)apply:(id)sender {
    
}

- (IBAction)restoreDefaults:(id)sender {
    
}

#pragma mark -

- (IBAction)addHandler:(id)sender {
    
    // Create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setAllowedFileTypes:@[(NSString *)kUTTypeApplicationBundle]];
    
    // Set Applications folder as default directory
    NSArray *applicationFolderPaths = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask];
    if ([applicationFolderPaths count]) {
        [oPanel setDirectoryURL:applicationFolderPaths[0]];
    }
    
    NSURL *appURL;
    
    // Run panel
    if ([oPanel runModal] == NSModalResponseOK) {
        appURL = [oPanel URLs][0];
    } else {
        return;
    }
    
    // add browser app
    [self addBrowserApp:[appURL path]];
}

- (IBAction)removeHandler:(id)sender {
    
}

#pragma mark -

- (IBAction)addAllHandlers:(id)sender {
    
}

- (IBAction)addAllBrowsers:(id)sender {
    
}

#pragma mark -

- (BOOL)addBrowserApp:(NSString *)appPath {
   
    NSURL *appURL = [NSURL fileURLWithPath:appPath];
    
    // Load bundle
    NSBundle *appBundle = [[NSBundle alloc] initWithURL:appURL];
    if (!appBundle) {
        return NO;
    }
    
    // Check for URL types supported by app
    NSArray *urlTypes = [appBundle infoDictionary][@"CFBundleURLTypes"];
    BOOL isHttpHandler = NO;
    
    for (NSDictionary *type in urlTypes) {
        NSArray *schemes = type[@"CFBundleURLSchemes"];
        if ([schemes containsObject:@"http"] || [schemes containsObject:@"https"]) {
            isHttpHandler = YES;
        }
    }
    
    if (!isHttpHandler) {
        NSString *name = [appBundle infoDictionary][@"CFBundleName"];
        [Alerts alert:@"Invalid App"
        subTextFormat:@"The application “%@” is not an HTTP handler.", name];
        return NO;
    }

    return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [browsers count];
}

- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
//    if (row < 0 || row >= [results count]) {
//        return nil;
//    }
    
    NSTableCellView *cellView;
    
    NSDictionary *info = browsers[row];
    
    cellView = [tv makeViewWithIdentifier:@"App" owner:self];
    cellView.textField.stringValue = info[@"name"];
    cellView.imageView.objectValue = info[@"icon"];
//    if ([[tc identifier] isEqualToString:@"Items"]) {
//    } else if ([[tc identifier] isEqualToString:@"Kind"]) {
//    } else if ([[tc identifier] isEqualToString:@"Date Modified"]) {
//    } else if ([[tc identifier] isEqualToString:@"Size"]) {
//    }
    
    return cellView;
}

#pragma mark -

- (void)rowDoubleClicked:(id)object {
    NSInteger row = [tableView clickedRow];
    //    if (row < 0 || row >= [results count]) {
    //        return;
    //    }
    
    //    SearchItem *item = results[row];
    BOOL cmdKeyDown = (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask);
    
    //    if (cmdKeyDown) {
    //        [item showInFinder];
    //    } else {
    //        [item open];
    //    }
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [tableView selectedRow];
//    if (selectedRow >= 0 && selectedRow < [results count] && [results count]) {
//    } else {
//    }
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedFiles = [pboard propertyListForType:NSFilenamesPboardType];
    NSMutableArray *acceptedFiles = [NSMutableArray array];
    
    for (NSString *path in draggedFiles) {
        
        // Only accept apps
        NSString *fileType = [[NSWorkspace sharedWorkspace] typeOfFile:path error:nil];
        if ([[NSWorkspace sharedWorkspace] type:fileType conformsToType:@"com.apple.application"]) {
            [acceptedFiles addObject:path];
        }
    }
    
    NSUInteger addedApps = 0;
    for (NSString *appPath in acceptedFiles) {
        addedApps += [self addBrowserApp:appPath];
    }
    
    return (addedApps != 0);
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    return NSDragOperationLink;
}

@end

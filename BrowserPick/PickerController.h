//
//  SelectionWindowController.h
//  BrowserPick
//
//  Created by Sveinbjorn Thordarson on 25/07/2018.
//  Copyright © 2018 Sveinbjorn Thordarson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PickerController : NSWindowController

+ (NSWindow *)pickerWindow;

- (void)setAppOptions:(NSArray<NSBundle *> *)appBundles;
- (void)setURL:(NSURL *)url;

@end

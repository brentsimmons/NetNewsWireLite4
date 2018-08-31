//
//  NNWSubscribeProgressWindowController.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWSubscribeProgressWindowController : NSWindowController {
@private
	IBOutlet NSTextField *_messageTextField;
	IBOutlet NSProgressIndicator *_progressIndicator;
}

+ (void)preloadWindow;
+ (void)runWindowWithBackgroundWindow:(NSWindow *)aBackgroundWindow;
+ (void)setMessage:(NSString *)message;
+ (void)closeWindow;

@end

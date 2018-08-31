//
//  NNWSubscribeProgressWindowController.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWSubscribeProgressWindowController.h"


@interface NNWSubscribeProgressWindowController ()

@property (nonatomic, strong) NSWindow *backgroundWindow;
- (void)setMessage:(NSString *)s;
- (void)closeWindow;
@end

@implementation NNWSubscribeProgressWindowController

@synthesize backgroundWindow;


#pragma mark Class Methods

static NNWSubscribeProgressWindowController *gWindowController = nil;

+ (void)preloadWindow {
    if (!gWindowController)
        gWindowController = [[self alloc] init];
    [gWindowController window];
}


+ (void)runWindowWithBackgroundWindow:(NSWindow *)aBackgroundWindow {
    if (!gWindowController)
        gWindowController = [[self alloc] init];
    gWindowController.backgroundWindow = aBackgroundWindow;
    [gWindowController showWindow:self];
}


+ (void)setMessage:(NSString *)message {
    [gWindowController setMessage:message];
}


+ (void)closeWindow {
    [gWindowController closeWindow];
}

#pragma mark Init

- (id)init {
    return [self initWithWindowNibName:@"SubscribeProgressWindow"];
}


#pragma mark Dealloc



#pragma mark NSWindowController

- (void)_centerWindowInFrontOfBackgroundWindow {
    /*A little higher than centered, sort of like -[NSWindow center]*/
    if (self.backgroundWindow == nil) {
        [[self window] center];
        return;
    }
    NSRect rBackgroundWindow = [self.backgroundWindow frame];
    NSPoint centerPoint = NSMakePoint(NSMidX(rBackgroundWindow), NSMidY(rBackgroundWindow));
    NSRect rFeedbackRect = [[self window] frame];
    NSPoint topLeftPoint = centerPoint;
    topLeftPoint.x -= (NSWidth(rFeedbackRect) / 2);
    topLeftPoint.y += (NSHeight(rFeedbackRect) / 2);
    topLeftPoint.y += 100; /*Raise a little bit*/
    topLeftPoint.y += NSHeight(rFeedbackRect);
    if (topLeftPoint.y < (NSHeight(rFeedbackRect) * 2)) /*Just make sure it's not hidden below screen*/
        topLeftPoint.y = NSHeight(rFeedbackRect) * 2;
    [[self window] setFrameTopLeftPoint:topLeftPoint];
}


- (void)windowDidLoad {
    [_messageTextField setStringValue:NSLocalizedStringFromTable(@"Finding feed…", @"Subscribing", @"Subscribe progress window")];
}


- (void)showWindow:(id)sender {
//    [self window];
    if (![self rs_isOpen])
        [self _centerWindowInFrontOfBackgroundWindow];
    [_messageTextField setStringValue:NSLocalizedStringFromTable(@"Finding feed…", @"Subscribing", @"Subscribe progress window")];
    [_progressIndicator startAnimation:self];
    [super showWindow:sender];
}


- (void)closeWindow {
    if (![self isWindowLoaded])
        return;
    [_progressIndicator stopAnimation:self];
    [_messageTextField setStringValue:@""];
    [[self window] close];
}


#pragma mark Message

- (void)setMessage:(NSString *)s {
    [_messageTextField setStringValue:s];
}


@end

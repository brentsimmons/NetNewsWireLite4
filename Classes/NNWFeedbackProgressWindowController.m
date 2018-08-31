//
//  NNWFeedbackProgressWindowController.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFeedbackProgressWindowController.h"


@interface NNWFeedbackProgressWindowController ()

@property (nonatomic, assign) BOOL showingSuccessMessage;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSString *title;

- (void)closeWindow;
- (void)fadeoutWindow;

@end


@implementation NNWFeedbackProgressWindowController

@synthesize image;
@synthesize imageView;
@synthesize progressIndicator;
@synthesize showingSuccessMessage;
@synthesize title;
@synthesize titleTextField;


#pragma mark Class Methods

static NNWFeedbackProgressWindowController *gWindowController = nil;

+ (void)runWindowWithTitle:(NSString *)aTitle image:(NSImage *)anImage {
    if (!gWindowController)
        gWindowController = [[self alloc] init];
    gWindowController.image = anImage;
    gWindowController.title = aTitle;
    gWindowController.showingSuccessMessage = NO;
    [gWindowController showWindow:self];
}


+ (void)runWindowWithSuccessMessage:(NSString *)aSuccessMessage image:(NSImage *)anImage {
    if (!gWindowController)
        gWindowController = [[self alloc] init];
    gWindowController.image = anImage;
    gWindowController.title = aSuccessMessage;
    gWindowController.showingSuccessMessage = YES;
    [gWindowController showWindow:self];
    [gWindowController performSelector:@selector(fadeoutWindow) withObject:nil afterDelay:0.75f];
}


+ (void)closeWindow {
    [gWindowController closeWindow];
}


#pragma mark Init

- (id)init {
    return [self initWithWindowNibName:@"FeedbackProgress"];
}


#pragma mark Dealloc



#pragma mark NSWindowController

- (void)windowDidLoad {
    [self.imageView setImage:self.image];
    [self.titleTextField setStringValue:self.title ? self.title : @""];
    //[[self window] setReleasedWhenClosed:NO];
}


- (void)centerWindowInFrontOfNewsreaderWindow {
    /*A little higher than centered, sort of like -[NSWindow center]*/
    NSWindow *newsreaderWindow = [NSApp mainWindow];
    NSRect rNewsreaderWindow = [newsreaderWindow frame];
    //rNewsreaderWindow.origin = [newsreaderWindow convertBaseToScreen:rNewsreaderWindow.origin];
    NSPoint centerPoint = NSMakePoint(NSMidX(rNewsreaderWindow), NSMidY(rNewsreaderWindow));
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


- (void)showWindow:(id)sender {
    [[self window] setTitle:@""];
    [self.imageView setImage:self.image];
    [self.titleTextField setStringValue:self.title ? self.title : @""];
    [self.titleTextField setNeedsDisplay:YES];
    if (self.showingSuccessMessage)
        [self.progressIndicator stopAnimation:self];
    else
        [self.progressIndicator startAnimation:self];
    if (![self rs_isOpen]) {
        [[self window] setAlphaValue:0.0f];
        [self centerWindowInFrontOfNewsreaderWindow];
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.2f];
        [[[self window] animator] setAlphaValue:1.0f];
        [NSAnimationContext endGrouping];    
    }
    [super showWindow:sender];
}


- (void)fadeoutWindow {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.2f];
    [[[self window] animator] setAlphaValue:0.0f];
    [NSAnimationContext endGrouping];        
    [self performSelector:@selector(closeWindow) withObject:nil afterDelay:0.3f];
}


- (void)closeWindow {
    if (![self isWindowLoaded])
        return;
    self.showingSuccessMessage = NO;
    [self.progressIndicator stopAnimation:self];
    [self.imageView setImage:nil];
    self.image = nil;
    [self.titleTextField setStringValue:@""];
    [[self window] close];
}


@end


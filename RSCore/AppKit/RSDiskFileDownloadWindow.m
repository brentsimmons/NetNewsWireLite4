/*
	  RSDiskFileDownloadWindow.m
	  NetNewsWire

	  Created by Brent Simmons on 12/16/04.
	  Copyright 2004 Ranchero Software. All rights reserved.
*/


#import "RSDiskFileDownloadWindow.h"


@implementation RSDiskFileDownloadWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	[self setContentBorderThickness:25.0 forEdge:NSMinYEdge];
	return self;
}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen];
	[self setContentBorderThickness:25.0 forEdge:NSMinYEdge];
	return self;
}


- (BOOL)acceptsMouseMovedEvents {
	return YES;
	}


- (BOOL)ignoresMouseEvents {
	return NO;
	}
	
	
- (NSView *)fileDownloadView {
	
	NSArray *subs = [[self contentView] subviews];
	NSInteger i;
	NSInteger ct = [subs count];
	
	for (i = 0; i < ct; i++) {
		NSView *oneView = [subs rs_safeObjectAtIndex:i];
		if ([oneView isKindOfClass:[NSScrollView class]])
			return [(NSScrollView *)oneView documentView];
		}
	return nil;
	}
	
	
- (void)keyDown:(NSEvent *)event {
	
	NSString *s = [event characters];
	if (!RSIsEmpty(s)) {
		unichar ch = [s characterAtIndex:0];
		if (ch == NSUpArrowFunctionKey || ch == NSDownArrowFunctionKey) {			
			NSView *fileDownloadView = [self fileDownloadView];
			if (fileDownloadView != nil) {
				[fileDownloadView keyDown:event];
				return;
				}
			}
		}
	[super keyDown:event];
	}
		
	
@end

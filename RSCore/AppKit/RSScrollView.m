//
//  RSScrollView.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSScrollView.h"


@implementation RSScrollView

@synthesize showHorizontalScrollbarWhenNeeded;

- (void)setShowHorizontalScrollbarWhenNeeded:(BOOL)flag {
	if (flag != showHorizontalScrollbarWhenNeeded)
		[self setNeedsDisplay:YES];
	showHorizontalScrollbarWhenNeeded = flag;	
}


- (void)reflectScrolledClipView:(NSClipView *)clipView {
	if (clipView == [self contentView] && self.showHorizontalScrollbarWhenNeeded) {		
		BOOL horizontalScrollBarShowing = [self hasHorizontalScroller];
		BOOL shouldShowHorizontalScrollBar = ([self frame].size.width < [[self documentView] bounds].size.width);
		if (shouldShowHorizontalScrollBar != horizontalScrollBarShowing) {
			NSUInteger origResizeStyle = 0;
			BOOL documentViewIsTableView = [[self documentView] isKindOfClass:[NSTableView class]];
			if (documentViewIsTableView) {
				origResizeStyle = [[self documentView] columnAutoresizingStyle];
				[[self documentView] setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
			}
			[self setHasHorizontalScroller:shouldShowHorizontalScrollBar];
			if (documentViewIsTableView)
				[[self documentView] setColumnAutoresizingStyle:origResizeStyle];
			[self setNeedsDisplay:YES];
		}
	}	
	[super reflectScrolledClipView:clipView];
}


@end

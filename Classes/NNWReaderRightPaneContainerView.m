//
//  NNWReaderRightPaneContainerView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWReaderRightPaneContainerView.h"


@implementation NNWReaderRightPaneContainerView

@synthesize contentViewController;


#pragma mark Dealloc

- (void)dealloc {
	[contentViewController release];
	[super dealloc];
}


#pragma mark Accessors

- (void)setContentViewController:(NSViewController *)aViewController {
	[[contentViewController view] removeFromSuperview];
	contentViewController = aViewController;
	[self addSubview:[contentViewController view]];
	[contentViewController setNextResponder:[[contentViewController view] nextResponder]];
	[[contentViewController view] setNextResponder:contentViewController];
	[self resizeSubviewsWithOldSize:NSZeroSize];
}


#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSRect rBounds = [self bounds];
	for (NSView *oneSubview in [self subviews])
		[oneSubview setFrame:rBounds];
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)dirtyRect {
	RSCGRectFillWithWhite(dirtyRect);
}


@end

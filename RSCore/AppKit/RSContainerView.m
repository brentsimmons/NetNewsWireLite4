//
//  RSContainerView.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/9/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSContainerView.h"


@interface RSContainerView ()
@property (nonatomic, retain) NSView *childView;
@end


@implementation RSContainerView

@synthesize childViewController;
@synthesize childView;
@synthesize viewController;
@synthesize backgroundColor;


- (void)dealloc {
	[childViewController release];
	if ([childView isDescendantOf:self])
		[childView removeFromSuperview];
	[childView release];
	viewController = nil;
	[backgroundColor release];
	[super dealloc];
}


- (void)setChildViewController:(NSViewController *)aViewController {
	if (aViewController == self.childViewController)
		return;
	childViewController = [aViewController retain];
	self.childView = [aViewController view];
	/*Patch the responder chain so that it looks like this: selfview < childViewController < childView.*/
	[self.childView setNextResponder:aViewController];
	[aViewController setNextResponder:self];
}


- (void)setChildView:(NSView *)aView {
	if (aView == self.childView)
		return;
	[self.childView removeFromSuperview];
	childView = [aView retain];
	[self addSubview:childView];
	[childView setFrame:[self bounds]];
	[childView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
}


- (void)setBackgroundColor:(NSColor *)aColor {
	[backgroundColor autorelease];
	backgroundColor = [aColor retain];
	[self setNeedsDisplay:YES];
}


- (BOOL)autoresizesSubviews {
	return YES;
}


- (void)resizeSubviewsWithOldSize:(NSSize)s {
	[self.childView setFrame:[self bounds]];
}


- (BOOL)isOpaque {
	return YES; //since child view covers this view completely
}


- (void)drawRect:(NSRect)dirtyRect {
	if (self.backgroundColor == nil)
		[[NSColor whiteColor] set];
	else
		[self.backgroundColor set];
	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}



@end

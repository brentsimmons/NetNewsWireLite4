//
//  NNWAddFeedsContainerView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsContainerView.h"


@implementation NNWAddFeedsContainerView

#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSRect rBounds = [self bounds];
	for (NSView *oneView in [self subviews]) {
		CGRect rView = [oneView frame];
		rView = CGRectCenteredInRect(rView, rBounds);
		[oneView setFrame:rView];
	}
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	
	
	static NSColor *backgroundTextureColor = nil;
	if (backgroundTextureColor == nil)
		backgroundTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"verylightgraypattern"]] retain];
	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, NSMaxY([self bounds]))];
	[backgroundTextureColor set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
//
//	[[NSColor colorWithDeviceWhite:1.0 alpha:0.3] set];
//	NSRectFill(r);

	
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect rBounds = NSIntegralRect([self bounds]);
	NSPoint topLeft = NSMakePoint(NSMinX(rBounds), NSMaxY(rBounds));
	topLeft.y = topLeft.y + 0.5f;
	NSPoint topRight = NSMakePoint(NSMaxX(rBounds), NSMaxY(rBounds));
	topRight.y = topRight.y + 0.5f;
	[p moveToPoint:topLeft];
	[p lineToPoint:topRight];
	[[NSColor blackColor] set];
	[self rs_setShadowWithBlurRadius:18.0f color:[NSColor blackColor] offset:NSMakeSize(0, -3)];
	[p stroke];
	[NSGraphicsContext restoreGraphicsState];
	
}

@end

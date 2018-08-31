//
//  NNWMainWindowFloatingShadowView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWMainWindowFloatingShadowView.h"


@implementation NNWMainWindowFloatingShadowView

- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect rBounds = NSIntegralRect([self bounds]);
	NSPoint topLeft = NSMakePoint(NSMinX(rBounds), NSMaxY(rBounds));
	topLeft.y = topLeft.y - 0.5f;
	NSPoint topRight = NSMakePoint(NSMaxX(rBounds), NSMaxY(rBounds));
	topRight.y = topRight.y - 0.5f;
	[p moveToPoint:topLeft];
	[p lineToPoint:topRight];
	[[NSColor colorWithDeviceWhite:0.0f alpha:0.75f] set];
	[self rs_setShadowWithBlurRadius:5.0f color:[NSColor colorWithDeviceWhite:0.0f alpha:0.39f] offset:NSMakeSize(0, -1)];
	[p stroke];
	[NSGraphicsContext restoreGraphicsState];
}


@end

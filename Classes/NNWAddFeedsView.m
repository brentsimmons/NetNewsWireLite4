//
//  NNWAddFeedsView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsView.h"


@implementation NNWAddFeedsView


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	
	[[NSColor windowBackgroundColor] set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
	
//	static NSColor *backgroundTextureColor = nil;
//	if (backgroundTextureColor == nil)
//		backgroundTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"bluepattern"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, NSMaxY([self bounds]))];
//	[backgroundTextureColor set];
//	NSRectFillUsingOperation(r, NSCompositeSourceOver);
//
//	[NSGraphicsContext saveGraphicsState];
//	NSBezierPath *p = [NSBezierPath bezierPath];
//	[p setLineWidth:1.0f];
//	NSRect rBounds = NSIntegralRect([self bounds]);
//	NSPoint topLeft = NSMakePoint(NSMinX(rBounds), NSMaxY(rBounds));
//	topLeft.y = topLeft.y - 0.5f;
//	NSPoint topRight = NSMakePoint(NSMaxX(rBounds), NSMaxY(rBounds));
//	topRight.y = topRight.y - 0.5f;
//	[p moveToPoint:topLeft];
//	[p lineToPoint:topRight];
//	[[NSColor colorWithDeviceWhite:1.0f alpha:0.25f] set];
//	[self rs_setShadowWithBlurRadius:8.0f color:[NSColor colorWithDeviceWhite:0.0f alpha:0.99f] offset:NSMakeSize(0, -3)];
//	[p stroke];
//	[NSGraphicsContext restoreGraphicsState];

}


@end
